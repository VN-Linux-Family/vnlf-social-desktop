# Automatic check-in integration

This binding is isolated and is not yet installed in the app. Create one
`AutomaticModalTracker` for the router lifetime, and pass a **different**
`tracker.observer()` to `GoRouter.observers` and every `ShellRoute.observers`
(including any additional navigator that can display a popup). Construct the
router and its root `GlobalKey<NavigatorState>` together. Dispose the tracker
after the router and binding are disposed. Observers must be installed before
routes are pushed; an unobserved navigator cannot be inferred by the binding.
Recreate the tracker if a navigator is replaced without removing its routes.

Wrap the router child in `AutomaticCheckInBinding`, providing the root key,
tracker, `apiClientProvider`, and `sessionStorageProvider`. Set `live` only
when both the actual HTTP transport is live and offline features are disabled;
fixture or offline configuration must pass false. Supply an owner only from a
successful, current server session response, and pass null for loading, error,
logout, or an empty identity. `confirmation` is null whenever the session is
unconfirmed; use a stable object for a confirmed session, replacing it only
after a new successful server confirmation. Do not reuse a confirmation object
after `ApiClient.invalidateSession()`. Rebuild the binding synchronously when
these inputs change, and initialize/listen to session state before binding.
The client invalidation listener independently tears down the old binding and
requires a fresh confirmation before it can restart.

Provide `onViewActivity` as a synchronous router action to `/activity`. The
binding checks the captured session immediately before invoking it; navigation
code should still obey the application's ordinary auth guard. Do not make the
callback retain a stale owner or schedule an unguarded later navigation.

The shared tracker covers `PopupRoute` instances, including dialogs and modal
bottom sheets. Any custom modal that is not a `PopupRoute` needs a corresponding
integration mechanism before enabling automatic check-in. The one-minute timer
only checks for a Vietnam-local day change; it does not poll the server. Failed
or uncertain writes are left to the existing durable reconciliation flow. The
binding must be verified with the repository's Flutter checks and synthetic
widget tests before enabling it; no live check-in was performed here.
