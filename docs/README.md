# VNLF Social Documentation Index

This directory contains developer guides, build/release documentation, API & UI contracts, Architecture Decision Records (ADRs), implementation plans, and verification/audit reports.

## Root Governance & Specifications
- [`../README.md`](../README.md) — Project overview, supported platforms, and quickstart
- [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — Contribution rules, layer boundaries, and PR checklist
- [`../AGENTS.md`](../AGENTS.md) — Operating rules for AI coding agents and contributors
- [`../PLAN.md`](../PLAN.md) — Architectural master plan and verification status
- [`../API_NOTES.md`](../API_NOTES.md) — Confirmed server REST & WebSocket contract reference
- [`../DESIGN_REFERENCE.md`](../DESIGN_REFERENCE.md) — Design tokens, layout tiers, and website parity reference

## Guides & Governance (`docs/`)
- [`DEVELOPMENT.md`](DEVELOPMENT.md) — Complete developer guide (setup, architecture, adding features, testing, troubleshooting)
- [`BUILD_AND_RELEASE.md`](BUILD_AND_RELEASE.md) — CI/CD matrix, local build-slot guard, Android signing, and release publishing
- [`ASSETS.md`](ASSETS.md) — Third-party font, icon, and brand asset license ledger
- [`UI_FIELD_MAP.md`](UI_FIELD_MAP.md) — Design system component to server API field mapping
- [`release-signing.md`](release-signing.md) — Android release signing policy and keystore security

## Contracts (`docs/contracts/`)
- [`contracts/community-realtime-events.md`](contracts/community-realtime-events.md) — `/ws/community` WebSocket envelope and event specifications
- [`contracts/direct_messages.md`](contracts/direct_messages.md) — Direct messaging REST & realtime contract notes

## Architecture Decision Records (`docs/decisions/`)
- [`decisions/0001-native-windows-video.md`](decisions/0001-native-windows-video.md) — ADR-0001: Windows Media Foundation native video backend (`video_player_win`)

## Implementation Plans (`docs/plans/`)
- [`plans/2026-11-06-community-realtime.md`](plans/2026-11-06-community-realtime.md) — Community realtime WebSocket implementation plan
- [`plans/2026-11-06-messaging-integration.md`](plans/2026-11-06-messaging-integration.md) — Channels & direct messaging integration plan
- [`plans/2026-11-06-shared-polls.md`](plans/2026-11-06-shared-polls.md) — Shared polls authoring and voting plan

## Audits & Verification Reports (`docs/` & `docs/reports/`)
- [`ux-ui-audit-2026-11-08.md`](ux-ui-audit-2026-11-08.md) — Comprehensive UX/UI, contrast, responsive & accessibility audit
- [`source-parity-audit.md`](source-parity-audit.md) — Upstream contract & feature parity review
- [`production-audit.md`](production-audit.md) — Production reliability & contract verification audit
- [`composer-contract-review.md`](composer-contract-review.md) — Native rich composer contract review
- [`ci-cost-audit-2026-11-06.md`](ci-cost-audit-2026-11-06.md) — CI matrix timing and runner allowance audit
- [`reports/codex-handoff-verification.md`](reports/codex-handoff-verification.md) — Profile, theme persistence & logout verification report
- [`reports/community-native-verification.md`](reports/community-native-verification.md) — Community channels, voice & search verification report
- [`reports/native-screens-verification.md`](reports/native-screens-verification.md) — Native thread, profile, settings & discover route verification
- [`reports/feed-leaderboard-projects-verification.md`](reports/feed-leaderboard-projects-verification.md) — Feed pagination, leaderboard & projects verification
- [`visual-audit/2026-11-06/README.md`](visual-audit/2026-11-06/README.md) & [`visual-audit/2026-11-08/README.md`](visual-audit/2026-11-08/README.md) — Synthetic Linux visual audit captures
