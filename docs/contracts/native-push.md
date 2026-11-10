# Native push notifications

Status, 2026-11-09: the app can read, show and register Web Push
notifications, but nothing can receive them yet. The server only accepts
browser push endpoints, and the app has no push service on the device. This
page lists what each side needs. Source references are to the website
repository (`vnlf-social`).

## What the server sends today

- Protocol: W3C Web Push with VAPID (RFC 8030, RFC 8291 `aes128gcm`,
  RFC 8292), through the npm `web-push` package (`apps/worker/src/push.ts`).
- Endpoints: `validPushEndpoint` in `apps/api/src/modules/push.ts` accepts
  only `https:` URLs of at most 2048 characters, with no port, credentials or
  fragment, on `fcm.googleapis.com`, `updates.push.services.mozilla.com`,
  `web.push.apple.com` or `*.notify.windows.com`. Anything else is
  `400 PUSH_ENDPOINT_INVALID`.
- Keys: `p256dh` is an uncompressed P-256 point (65 bytes starting with
  `0x04`) and `auth` is 16 bytes, both base64url.
- Body, from `pushCopy`:

  ```json
  {"title": "VNLF Social", "body": "…", "url": "/messages/<id>",
   "tag": "dm:<id>", "urgent": false, "requireInteraction": true}
  ```

  | Kind | `url` | `tag` | `urgent` | `requireInteraction` |
  | --- | --- | --- | --- | --- |
  | Mention or reply in comments | `/a/<slug>?comment=<commentId>` | `mention:<notificationId>`, `reply:<notificationId>` | no | no |
  | Direct message | `/messages/<conversationId>` | `dm:<conversationId>` | no | yes |
  | Message request | `/messages` | `request:<conversationId>` | no | yes |
  | Mention in a channel | `/channels/<slug>` | `channel:<channelId>` | no | no |
  | Account or security change | `/help` or `/settings/security` | `account:<userId>` | yes | yes |

  `TTL` is one hour; urgency is `high` for account changes, `normal`
  otherwise.

## What the app has

All under `lib/src/features/notifications/`:

- `PushMessage.decode` reads a decrypted body the way `push-sw.js` does: the
  `/notifications` page and the `vnlf-notification` tag when missing, and
  nothing at all for a body that is not a JSON object or a path off the site.
- `PushMessagePresenter` shows it. It skips all but urgent messages while the
  app is in front, gives every tag a stable notification id so a newer
  message replaces the older one, keeps `requireInteraction` messages on
  screen on Linux, and opens the matching app screen on tap. Pages without a
  screen in the app (such as `/help`) open on the website.
- `LivePushSubscriptionsRepository` makes the website's four calls:
  `GET /api/v1/push/config`, `GET`, `POST` and `DELETE`
  `/api/v1/push/subscriptions`. The `POST` is never retried.
- `PushRegistration` follows `push-settings.tsx` step by step, with a
  `PushDistributor` in place of the browser's `PushManager`.

Still missing in the app: a `PushDistributor` implementation and the
"Thông báo trên thiết bị" switch in Settings.

## Server change

A UnifiedPush endpoint is a Web Push endpoint: it takes the same VAPID
headers and the same RFC 8291 encrypted body. So VAPID, encryption, the body
above and the delivery limits work unchanged, and the cleanup after `404` or
`410` works wherever the distributor's server answers that way for a dropped
endpoint. Only `validPushEndpoint` has to accept the distributors' hosts. The
worker then posts to those URLs, so pick one of these:

1. A list of known distributor hosts (for example `ntfy.sh`), extendable
   from the server's config for self-hosted ones.
2. Any `https:` host, checked when sending as well: refuse addresses that
   resolve to private, loopback or link-local ranges, and keep the timeouts
   short. Without that check, an account can make the worker call internal
   services.

## App side (2026-11-10)

The owner approved the `unifiedpush` package on 2026-11-10.

1. `unifiedpush` resolves to 6.1.0 (Apache-2.0, published by
   unifiedpush.org, Android only). 6.2.0 also pulls `unifiedpush_linux`,
   whose `window_manager ^0.5.1` conflicts with the app's 0.6. The connector
   brings Tink for Java while `flutter_secure_storage` brings Tink for
   Android, so `android/app/build.gradle.kts` substitutes `tink-android`
   1.18.0 for both.
2. `UnifiedPushDistributor` is the `PushDistributor`: `register(vapid:)`
   with the server key; the endpoint from `onNewEndpoint` (its URL and
   `pubKeySet`) becomes the `WebPushSubscription`, kept in secure storage
   with the key it was made for. A missing distributor, an endpoint without
   keys and a 30-second silence raise `PushDistributorUnavailable`;
   `onRegistrationFailed` raises `PushRegistrationRefused` with its reason.
3. Messages: the connector decrypts each one; a body it could decrypt goes
   to `PushMessage.decode` and `PushMessagePresenter`. While the app runs,
   `PushServiceBinding` takes them. With the app closed, the connector
   starts `main` headless with `--unifiedpush-bg`, which only shows the
   notification. A tap that starts the app is read from the plugin's launch
   details.
4. A replaced endpoint, the counterpart of `pushsubscriptionchange`: the
   distributor records the endpoint the server still has. Once a member is
   signed in, `PushRegistration.replace` posts the new one and deletes the
   old one, once per launch or replacement, never retried.
5. Still to do: the "Thông báo trên thiết bị" switch in Settings
   (`PushSettings`, `PushPermissionPrompt`, the per-account "turned off on
   this device" flag and the one-week "Để sau" snooze).

## Checks

- Before the server change: `POST /api/v1/push/subscriptions` with a
  distributor endpoint answers `400 PUSH_ENDPOINT_INVALID`, and Settings
  shows that registration failed.
- After it: on the test account with a distributor installed, a direct
  message from a second test account shows a notification while the app is
  closed, and the tap opens the conversation. Delete the test messages
  afterwards.
