### Community Attachments – Sequenced Task List, File-Level Steps, and Acceptance Criteria

Scope: Add extensible attachments to community posts (images, poll, support group invite) with Plus-only creation, viewable by all. One attachment type per post. Enforce limits: up to 4 images (JPEG/PNG, ≤5MB each), 1 poll (2–4 options, 100 chars each; question 100 chars; single/multi select; vote changes allowed; voters see results immediately; non‑voters after close), 1 group invite (specific group, issuer must be member; reuse group’s general join code; expiry; auto‑revoke if inviter leaves group). Images are client-cropped/compressed to 512px max dimension and thumbnails generated client-side. Notifications are push only.

---

## 0) Prerequisites and Alignment

- Confirm Plus gating provider exists: `hasActiveSubscriptionProvider` in `lib/features/plus/data/notifiers/subscription_notifier.g.dart`.
- Confirm feature ban utilities: `lib/features/account/presentation/widgets/feature_access_guard.dart` (guards, checkers, snackbars).
- Confirm analytics facade exists: `lib/core/monitoring/analytics_facade.dart` and clients.
- Confirm localization access via `AppLocalizations` and theming via `AppTheme.of(context)`.

Acceptance criteria
- The above modules compile and can be imported where referenced.
- Team aligned that attachments creation is Plus-only; viewing available to all.

---

## 1) Data Model: Post Document and Attachments Subcollection

Summary: Keep post docs lean via `attachmentsSummary` and `attachmentTypes`, store full attachment payloads in subcollection, and use `pendingAttachments`/`attachmentsFinalizedAt` to support a reliable multi-step creation.

Files to update
- `lib/features/community/data/repositories/forum_repository.dart` (add support to set new post flags and summaries)
- `lib/features/community/domain/services/forum_service.dart` (orchestrate multi-step finalize)
- `docs/admin_panel_schema.md` (append new fields and collections)

State/Fields to add (no code here; implement in repository/service)
- Post doc additions (`forumPosts`):
  - `attachmentsSummary`: array of compact descriptors (id, type, thumbnailUrl, minimal metadata like question/groupName)
  - `attachmentTypes`: array of strings (e.g., ["image"]) for quick filtering/badging
  - `pendingAttachments`: boolean
  - `attachmentsFinalizedAt`: timestamp
- Subcollection: `forumPosts/{postId}/attachments/{attachmentId}` with common fields (id, type, schemaVersion, createdAt, createdByCpId, status)
  - Image attachment: storagePath, downloadUrl, width, height, sizeBytes, thumbnailUrl, contentHash
  - Poll attachment: question, options (2–4), selectionMode (single|multi), closesAt?, ownerCpId, aggregates (totalVotes, optionCounts), isClosed
  - Group invite: inviterCpId, groupId, groupSnapshot (name, gender, capacity, memberCount, joinMethod, plusOnly), inviteJoinCode (general), expiresAt, status
- Storage paths: `community_posts/{postId}/images/{timestamp}_{rand}.jpg` (+ `thumbnails/`)

Acceptance criteria
- Creating a post with attachments writes `pendingAttachments=true` first and sets `attachmentsSummary`/`attachmentTypes`/`attachmentsFinalizedAt` at finalize.
- Post doc size remains small; attachment details live in subcollection.
- Summary accurately mirrors subdocs; unknown types are ignored safely by the client.

---

## 2) Composer UX (Threads-like) and Providers

Summary: Add typed attachments state, trays and flows for images, poll, and invite. Enforce one attachment type per post and per-type limits. Non‑Plus shows upsell.

Files to update
- `lib/features/community/presentation/providers/forum_providers.dart` (introduce `postAttachmentsProvider` typed state; deprecate `attachmentUrlsProvider` usage)
- `lib/features/community/presentation/forum/new_post_screen.dart` (tray UI; attach flows; integrate Plus gating and validation; submission pipeline)
- `lib/core/shared_widgets/premium_blur_overlay.dart` (apply over tray for non‑Plus)
- `lib/core/shared_widgets/premium_cta_button.dart` (upsell action)
- `lib/core/shared_widgets/action_modal.dart` (use for poll/create/invite modals)
- `lib/core/shared_widgets/snackbar.dart` (error/success toasts)
- `lib/features/account/presentation/widgets/feature_access_guard.dart` (wrap taps to show ban messaging when needed)

Composer behavior
- One attachment type per post; disable/grey other actions when one is active and show tooltip string.
- Images: pick up to 4 JPEG/PNG files; enforce ≤5MB each; HEIC converted to JPEG client-side; crop/compress to 512px max dimension; show thumbnails; removal allowed.
- Poll: form validates question (≤100), 2–4 options (≤100 each), single/multi toggle, optional close time.
- Group invite: show only groups where current CP is an active member; reuse group’s general join code; set expiry.
- Non‑Plus: tray gated by `hasActiveSubscriptionProvider`; overlay and CTA shown; cannot attach.

Acceptance criteria
- For non‑Plus account, tapping tray actions shows overlay + upsell; cannot proceed.
- For Plus account, per-type limits and validations are enforced; flows are localized and themed.
- `postAttachmentsProvider` reliably holds exactly one type and expected payload (images list, poll config, or invite data).

---

## 3) Submission Pipeline and Finalization

Summary: Reliable, idempotent multi-step: create post → upload/create attachments/subdocs → finalize post with summary.

Files to update
- `lib/features/community/domain/services/forum_service.dart` (extend `createPost` to orchestrate finalize)
- `lib/features/community/data/repositories/forum_repository.dart` (helpers to write subdocs and finalize post)

Flow requirements
- Step 1: Create post with `pendingAttachments=true` if there are attachments.
- Step 2: Based on selected type:
  - Images: upload compressed images + thumbnails; write image subdocs and build summary entries
  - Poll: write poll subdoc with aggregates initialized
  - Invite: write invite subdoc with group snapshot and expiry
- Step 3: Update post with `attachmentsSummary`, `attachmentTypes`, `pendingAttachments=false`, `attachmentsFinalizedAt`.
- Idempotency: Re-running finalize after a partial failure must not duplicate subdocs or summary entries (check by `attachmentId`).

Acceptance criteria
- Network failures during attachments creation can be retried; final state remains consistent and clean.
- Posts without attachments skip the finalize path cleanly.

---

## 4) Rendering: List and Detail

Summary: Use `attachmentsSummary` for cheap previews in lists and load full subdocs in detail. Attachments render below body.

Files to update
- `lib/features/community/presentation/widgets/threads_post_card.dart` (compact previews per type)
- `lib/features/community/presentation/widgets/post_content_widget.dart` (insert attachments section below body; delegate to per-type renderers)

Rendering rules
- Lists: thumbnails grid for images; small poll badge with question excerpt; invite card with group name and Plus-only badge if applicable.
- Detail: full image grid (tappable viewer), poll voting/results per rules, invite join button with bottom-sheet reasons if blocked.
- Moderation: if an attachment is removed, show a small “Attachment removed” placeholder.

Acceptance criteria
- List previews appear consistently and do not cause layout jumps or jank.
- Detail view loads subdocs lazily; correct visibility for poll results; join reasons show when blocked (gender/capacity/cooldown/plus-only).

---

## 5) Plus Gating and Feature Bans

Files to update
- `lib/features/community/presentation/forum/new_post_screen.dart` (gate tray and actions)
- `lib/features/account/presentation/widgets/feature_access_guard.dart` (use Smart/Quick/modal guards as appropriate)

Rules
- Creation is Plus-only: guard via `hasActiveSubscriptionProvider` and optionally `FeatureAccessGuard` for ban UX.
- Viewing allowed for all.
- Maintain per-type ban keys (e.g., `community_post_attachments`, `community_post_poll`, `community_post_group_invite`) for ban messaging only.

Acceptance criteria
- Non‑Plus cannot attach; Plus can. Ban messaging appears when configured.

---

## 6) Notifications (Push only)

Files to update
- `functions/src/index.ts` (or equivalent functions modules) – add triggers for:
  - Poll created (optional audience), poll closed, and notify poll author on vote
  - Group invite created (optional audience) and notify invite creator when a user joins via that invite

Acceptance criteria
- Poll author receives vote notifications; closing notifications fire.
- Invite creator receives join notifications attributable to the invite.

---

## 7) Analytics Instrumentation

Files to update
- `lib/core/monitoring/analytics_facade.dart` and relevant clients to add events
- Call sites in composer flows, submission pipeline, and renderers

Events
- `startedAttachmentFlow`, `addedImage`, `createdPoll`, `invitedToGroup`, `votePoll`, `joinedGroupFromInvite`, `attachmentUploadFailed`, `attachmentRendered`.
  - Include: attachmentType, counts/sizes, finalize latency, isPlusUser, rejection reasons.

Acceptance criteria
- Events are emitted at the defined points and visible in configured analytics backends.

---

## 8) Cloud Functions: Ops and Maintenance

Files to update
- `functions/src/index.ts` (or structured modules) to implement:
  - Post delete cascade: remove attachment subdocs and Storage files
  - Poll vote aggregation: on vote writes, recompute option counts and total votes
  - Group invite maintenance: on inviter membership removal, expire all invites to that group; scheduled job to expire by `expiresAt`

Acceptance criteria
- Deleting a post removes attachments and Storage assets.
- Poll aggregates update promptly and match votes.
- Invites auto-expire when inviter leaves group and when past expiry.

---

## 9) Security Rules (Conceptual – implement in Firebase rules)

Rules
- Only the post author (via `authorCPId`) whose `communityProfiles/{cpId}.isPlusUser == true` can write attachments for that post.
- Everyone can read attachments and summaries.
- Poll votes: one vote doc per CP; updates allowed (change vote).
- Group invite creation: allowed only if inviter is a current member of target group.

Acceptance criteria
- Rules tests demonstrate allowed/denied behaviors per above.

---

## 10) Localization

Files to update
- `lib/i18n/en_translations.dart`
- `lib/i18n/ar_translations.dart`

Keys (add both languages)
- Composer and errors: new‑attachment, attachments‑plus‑only, attachments‑type‑already‑selected, attachments‑limit‑reached, image‑format‑not‑allowed, image‑too‑large, image‑processing‑failed
- Poll: poll, poll‑question, poll‑options, poll‑single‑select, poll‑multi‑select, poll‑close‑at, poll‑closed, poll‑vote, poll‑change‑vote, poll‑results‑hidden‑until‑vote, poll‑results‑hidden‑until‑close
- Group invite: group‑invite, group‑invite‑expired, group‑invite‑revoked, group‑invite‑join, group‑invite‑plus‑only, group‑invite‑member‑left
- Join rejections: join‑blocked‑gender, join‑blocked‑capacity, join‑blocked‑cooldown, join‑blocked‑plus‑only
- Moderation: attachment‑removed
- Upsell: upgrade‑to‑plus, plus‑features‑attachments
- Generic: finalizing‑attachments, attachments‑failed‑retry, post‑creation‑restricted, feature‑access‑restricted

Acceptance criteria
- All UI strings used by the new flows resolve in both English and Arabic via `AppLocalizations.translate`.

---

## 11) Theming and Shared Widgets

Guidelines
- Use `AppTheme.of(context)` colors and `TextStyles` to match current design.
- Reuse shared widgets:
  - `premium_blur_overlay.dart` for non‑Plus overlay
  - `premium_cta_button.dart` for upsell
  - `action_modal.dart` for poll/invite flows
  - `snackbar.dart` for feedback
  - `container.dart` for consistent cards

Acceptance criteria
- Visuals match existing components; light/dark themes respected.

---

## 12) Admin/Backoffice Operational Instructions

Admin actions (for your admin panel/agent)
- Locate a post → view attachments → remove a specific attachment → verify post shows “Attachment removed” placeholder and summary updates.
- Polls: force close; export/inspect aggregated results.
- Invites: revoke; verify invite cards reflect revoked/expired.
- Search attachments by type/status/postId/cpId; perform bulk revoke/remove; audit log is updated.

Acceptance criteria
- Admin operations reflect immediately in mobile clients and data stays consistent.

---

## 13) Testing Plan (Manual + Automated)

Unit tests
- Validate per-type limits and constraints (images, poll, invite).
- Registry serialization/deserialization between summary and subdocs.
- Finalization idempotency: retry does not duplicate attachments.

Integration tests
- Composer: non‑Plus shows overlay/CTA; Plus can add attachments; limits enforced; HEIC converted; thumbnails shown.
- Post creation: images/poll/invite finalize correctly; summaries present.
- Poll: vote/change vote; visibility rules; author/admin close early.
- Invite: join succeeds when allowed; blocked reasons shown in bottom sheet.
- Moderation: removing attachment shows placeholder and updates summary.
- Notifications: poll create/close and author vote notifications; invite → creator join notifications.
- Analytics: defined events fire with parameters.

Security rules tests
- Author Plus can attach to own post; others denied. Poll vote single doc per CP; updates allowed. Invite creation requires membership.

Cloud Functions tests
- Post delete cascade; vote aggregation; inviter-leaves expiration; scheduled expiry.

Acceptance criteria
- All above tests pass on CI and in manual runs.

---

## 14) Rollout Checklist

- Smoke test on both platforms with Plus and non‑Plus users.
- Validate localization strings in English and Arabic.
- Verify analytics dashboards receive events.
- Confirm notifications delivered for poll/joins.
- Review security rules in production simulator before rollout.

Acceptance criteria
- No regressions in posting/commenting; app store build passes QA with the new flows.

---

## 15) Risks and Mitigations

- Partial upload failures → multi-step finalize + idempotent retries.
- Post doc bloat → summary only; heavy data in subcollection.
- Abuse/spam → per-type feature ban support (no rate limit for now by decision).
- Invite staleness → inviter-leaves auto-expire and scheduled expiry.

---

## 16) Success Criteria

- Plus users can attach images, polls, or invites (one type per post) within specified limits.
- Non‑Plus users see upsell and cannot attach.
- Lists show compact previews; detail shows full content below body.
- Poll and invite behaviors (visibility, join checks, expiry) match the product requirements.
- Admins can remove attachments, close polls, and revoke invites; clients reflect changes promptly.

