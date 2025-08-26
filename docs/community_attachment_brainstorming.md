### Community Attachments Implementation Playbook (for AI agent)

#### Scope and decisions
- Attachments allowed only on posts (not comments) at launch.
- One attachment type per post. Limits:
  - Images: up to 4 (JPEG/PNG only, 5MB each)
  - Poll: 1 per post (2–4 options; question and options ≤100 chars; single/multi selectable; voters can change vote; results shown immediately to voters; shown to non‑voters only after poll closes; author/admin can close early)
  - Group invite: 1 per post; specific existing group; invite issuer must be a current member; reuse group general join code; has expiry; auto‑revoke all invites if inviter leaves the group; join logic enforces gender/capacity/cooldown at click time
- Creation gated to Plus users. Viewing available to all. Feature‑level ban support required (ban, not feature flag).
- Images: client‑side crop/compress; HEIC → JPEG; target max dimension 512px; client‑side thumbnail generation.

### Data model and storage

- Post document (collection: `forumPosts`):
  - New fields:
    - `attachmentsSummary`: array of small objects per attachment containing: `id`, `type`, `thumbnailUrl` (if any), and minimal display metadata (e.g., `title` for poll/question, `groupName` for invite); cap to the effective limits per type.
    - `attachmentTypes`: array of strings listing the present types (e.g., ["image"] or ["poll"]).
    - `pendingAttachments`: boolean; `attachmentsFinalizedAt`: timestamp (for reliable multi‑step creation).
  - Keep `title`/`body`/`category` unchanged.

- Attachments subcollection per post: `forumPosts/{postId}/attachments`
  - Common fields: `id` (attachment id), `type` ("image" | "poll" | "group_invite"), `schemaVersion`, `createdAt`, `createdByCpId`, `status` ("active"|"expired"|"revoked"|"deleted").
  - Image attachment: `storagePath`, `downloadUrl`, `width`, `height`, `sizeBytes`, `thumbnailUrl`, `contentHash`.
  - Poll attachment:
    - Static: `question`, `options` (array of objects containing `id` and `text`), `selectionMode` ("single"|"multi"), `closesAt` (optional), `ownerCpId`.
    - Aggregates: `totalVotes`, `optionCounts` (array of counts), `isClosed`.
    - Votes subcollection: `forumPosts/{postId}/pollVotes/{cpId}` with voter’s current selections.
  - Group invite attachment:
    - `inviterCpId`, `groupId`, `groupSnapshot` (name, gender, capacity, memberCount, joinMethod, plusOnly), `inviteJoinCode` (group’s general code/deep link), `expiresAt`, `status`.

- Storage layout
  - Bucket path: `community_posts/{postId}/images/{timestamp}_{rand}.jpg`
  - Client generates thumbnails and uploads them under `.../thumbnails/...`.

- Identifiers
  - `attachmentId` derived from postId + timestamp + random suffix. `attachmentsSummary[].id` must match the subdoc id.

### Client architecture and providers

- Providers (augment existing in `lib/features/community/presentation/providers/forum_providers.dart`):
  - Replace or supersede `attachmentUrlsProvider` with a typed `postAttachmentsProvider` holding:
    - attachmentType selected (one of image|poll|group_invite), and a typed payload list (images up to 4, poll definition, or group invite definition).
  - Continue using `postCreationProvider` for submission, extended to handle multi‑step finalize.
  - Use `hasActiveSubscriptionProvider` (from `lib/features/plus/data/notifiers/subscription_notifier.g.dart`) for Plus gating. Use `feature_access_guard` for ban checks to show the right UI feedback.

- Services/repository flow
  - `ForumService.createPost` remains the entry point; after creating the core post document (with `pendingAttachments = true` if attachments selected), perform:
    1) For images: upload files (client‑compressed), create attachment subdocs, build `attachmentsSummary`.
    2) For poll: create poll attachment doc; initialize aggregates.
    3) For group invite: create invite attachment doc with group snapshot, join code, and expiry.
  - Finalize by updating post: `attachmentsSummary`, `attachmentTypes`, `pendingAttachments = false`, `attachmentsFinalizedAt = now`.
  - Ensure idempotency: if retrying after partial failure, re‑check existing subdocs by id and reconcile `attachmentsSummary`.

- Attachment registry pattern
  - Central registry maps `type` to:
    - validator (limits and per‑type business rules),
    - composer widget builder,
    - renderer for list and detail,
    - serializer/deserializer for subdocs and summary entries.
  - Registry isolation allows adding new types later without touching core flows.

### Composer UX (Threads‑style)

- Entry surface: `NewPostScreen` tray beneath the text field (or floating bar above keyboard):
  - Actions: Add Images, Create Poll, Invite to Group.
  - When non‑Plus users tap any action:
    - Use `hasActiveSubscriptionProvider` to check; if false, render a `premium_blur_overlay` over the tray and show an upsell via `premium_cta_button`.
    - Optionally wrap tap with `FeatureAccessGuard` for ban UX and snackbars.
  - Enforce single attachment type per post: if a type is already selected, the other actions are disabled/greyed out with tooltip text.
  - Attachments preview:
    - Images: 2x2 grid thumbnails (size ~72dp; 8dp spacing; rounded corners 8dp).
    - Poll: small card with question (1 line, ellipsized), chips for options (no interaction here), a “Poll” badge.
    - Invite: card with group avatar/initial, name (1 line), gender badge, capacity snapshot, “Invite” badge; Plus‑only group indicated with a small Plus icon/badge.

- Image flow:
  - Picker: allow selecting up to 4 images; enforce format (JPEG/PNG) and size (≤5MB).
  - Crop & compress: present crop UI; compress to target 512px max dimension; convert HEIC to JPEG.
  - Show thumbnails; allow removal.

- Poll flow:
  - Form: question (≤100 chars), options list (2 to 4 entries), toggle for single/multi select, optional close date/time.
  - Real‑time validation; show character counters.

- Group invite flow:
  - Group selector shows only groups where current CP is an active member; single pick.
  - Populate snapshot details; show computed expiry; indicate Plus‑only group if applicable.

### Rendering (list + detail)

- Post list (`lib/features/community/presentation/widgets/threads_post_card.dart`):
  - Below body, render compact attachment preview based on `attachmentsSummary`:
    - Images: thumbnail grid (lazy images).
    - Poll: small pill/badge row with icon and question excerpt.
    - Invite: small card row with group name and status.
  - Keep existing layout, typography via `TextStyles` and colors via `AppTheme`.

- Post detail (`lib/features/community/presentation/widgets/post_content_widget.dart`):
  - Render attachments below the body.
  - Full attachment widgets:
    - Images: responsive grid with pinch‑to‑zoom on tap (open viewer).
    - Poll: vote UI (single/multi); voters see live results; non‑voters see results only after close; allow changing vote; show close banner if closed.
    - Invite: “Join group” button; on tap, run join checks; show bottom sheet reasons if blocked (gender, capacity, cooldown, plus‑only).
  - If an attachment was moderated and removed, show a small “Attachment removed” placeholder.

### Gating and bans

- Plus creation:
  - Gate composer actions by `hasActiveSubscriptionProvider`. For non‑Plus, blur overlay and CTA. Keep viewing accessible to all.
- Feature‑level ban:
  - Use `FeatureAccessGuard` helpers with distinct names (e.g., `community_post_attachments`, `community_post_poll`, `community_post_group_invite`) for ban messaging only (default allow).
- Security enforcement (conceptual rules):
  - Only the post author (via `authorCPId`) whose `communityProfiles/{cpId}.isPlusUser == true` can write attachments for their post.
  - Poll votes: 1 vote doc per CP; updates allowed (overwrites selection).
  - Group invite create: only if inviter is a current member of the target group.
  - Everyone can read attachments.

### Notifications

- Push notifications only:
  - Poll: created (contextual, if you notify followers), closed (to commenters or followers, per your policy), and to poll author when someone votes.
  - Group invite: created (contextual) and to invite creator when a user joins via that invite’s context; attribution via attachment id or deep link params.
  - No batching/rate‑limit per your direction.

### Analytics

- Instrument via analytics layer:
  - startedAttachmentFlow, addedImage(count, sizes), createdPoll(type, optionsCount, closesAt set?), invitedToGroup(groupId, plusOnly), votePoll(postId, pollId, choiceCount), joinedGroupFromInvite(postId, inviteId), attachmentUploadFailed(type, reason), attachmentRendered(type, surface=list|detail).
  - Include `isPlusUser`, `attachmentType`, `finalizeLatencyMs`, and join rejection reasons (gender/capacity/cooldown/plusOnly).

### Admin and moderation

- Admin panel capabilities (operational flows):
  - Locate a post and list attachments; remove individual attachments; post updates its `attachmentsSummary`.
  - Polls: force close; view aggregated results.
  - Invites: revoke; show inviter and attribution metrics (joins).
  - Global search across attachments by type/status/postId/cpId; bulk revoke/remove; audit trail.

### Cloud Functions (ops)

- Post delete: cascade delete subcollection docs and Storage files.
- Poll votes: on write, recompute aggregates and store to poll attachment doc.
- Invite maintenance:
  - On CP membership change (inviter leaves a group), expire all their invites for that group.
  - Scheduled job to expire invites past `expiresAt`.

### Localization

Add keys in `lib/i18n/en_translations.dart` and `lib/i18n/ar_translations.dart`:
- Attachment composer and errors:
  - new‑attachment, attachments‑plus‑only, attachments‑type‑already‑selected, attachments‑limit‑reached, image‑format‑not‑allowed, image‑too‑large, image‑processing‑failed
- Poll:
  - poll, poll‑question, poll‑options, poll‑single‑select, poll‑multi‑select, poll‑close‑at, poll‑closed, poll‑vote, poll‑change‑vote, poll‑results‑hidden‑until‑vote, poll‑results‑hidden‑until‑close
- Group invite:
  - group‑invite, group‑invite‑expired, group‑invite‑revoked, group‑invite‑join, group‑invite‑plus‑only, group‑invite‑member‑left
- Join rejections (bottom sheet reasons):
  - join‑blocked‑gender, join‑blocked‑capacity, join‑blocked‑cooldown, join‑blocked‑plus‑only
- Moderation placeholder:
  - attachment‑removed
- Upsell:
  - upgrade‑to‑plus, plus‑features‑attachments
- Generic:
  - finalizing‑attachments, attachments‑failed‑retry, post‑creation‑restricted, feature‑access‑restricted

Provide Arabic equivalents consistent with your tone and existing keys.

### Theming and shared widgets

- Use `AppTheme.of(context)` colors and `TextStyles` to match current visuals.
- Shared widgets:
  - `lib/core/shared_widgets/premium_blur_overlay.dart`: overlay the composer attachments tray when non‑Plus.
  - `lib/core/shared_widgets/premium_cta_button.dart`: CTA in upsell modal/sheet.
  - `lib/core/shared_widgets/action_modal.dart`: poll creation and invite selection flows.
  - `lib/core/shared_widgets/snackbar.dart`: show errors and success toasts.
  - `lib/core/shared_widgets/container.dart`: cards and list tiles container styling to keep consistent radii and padding.

### Testing plan

- Unit tests (Dart):
  - Attachment validation per type (limits, formats, sizes).
  - Poll rules: options bounds; single vs multi; close time handling.
  - Attachments registry: serialization/deserialization to/from summary and subdocs.
  - Post finalize logic: pending → finalized; idempotent retries (re‑running creation preserves consistent state).
  - Join logic mapping: invite status derivation (active/expired/revoked) given inviter membership, expiresAt, and group snapshot.

- Integration tests (app):
  - Composer:
    - Non‑Plus user sees blur overlay + upsell; cannot add attachments.
    - Plus user can add 1–4 images; over 4 blocked; >5MB blocked; HEIC converted; thumbnails visible.
    - Poll creation validates character limits, options count; multi‑select toggle; optional close time.
    - Invite flow lists only user’s current group; invite created; expiry honored.
  - Post creation:
    - With images: post creates, thumbnails in list, full images in detail; finalize completes and `attachmentsSummary` present.
    - With poll: voters can vote; can change vote; non‑voters can’t see results until close; author can close early.
    - With invite: join succeeds if allowed; otherwise proper bottom sheet reason shown.
  - Moderation:
    - Remove attachment → placeholder appears; summary updates; detail hides content.
  - Notifications:
    - Poll created/closed notifications received; author receives vote notifications.
    - Invite creator receives join notifications.
  - Analytics:
    - Verify key events fire with expected parameters.

- Security rules tests:
  - Only Plus post author can create attachments for their post.
  - Everyone can read.
  - Poll vote write: 1 doc per CP; updates allowed; others rejected.
  - Invite creation: only when inviter is a member of target group.

- Cloud Functions tests:
  - Post delete triggers cleanup (subdocs + Storage).
  - Vote aggregation updates counts.
  - Inviter leaves group → all invites to that group by inviter expire.
  - Scheduled expiry marks overdue invites as expired.

### Delivery checklist (no code, actions sequence)

- Data:
  - Add post fields: `attachmentsSummary`, `attachmentTypes`, `pendingAttachments`, `attachmentsFinalizedAt`.
  - Create attachments subcollection and pollVotes.
  - Define Storage paths and naming.
- Client:
  - Implement typed `postAttachmentsProvider`, one attachment type per post.
  - Update composer UI (tray, previews, forms) with non‑Plus UX overlay and CTA.
  - Submission pipeline: post → attachments → finalize, with retries and idempotency.
  - List/detail rendering using summary previews and full renderers.
  - Moderation placeholder UI.
- Gating:
  - Wire `hasActiveSubscriptionProvider` for Plus creation checks.
  - Add ban keys and wrap relevant taps in `FeatureAccessGuard`/`SmartFeatureGuard`.
- Ops:
  - Implement Cloud Functions for cleanup, poll aggregation, and invite maintenance.
- Notifications:
  - Add triggers for poll create/close/vote and invite → join.
- Analytics:
  - Emit all agreed events with attachment attribution.
- Localization:
  - Add keys and translations in both English and Arabic.
- Docs/admin:
  - Update admin panel instructions for list/remove, close poll, revoke invite, and audit.

### What you gain with `attachmentsSummary` + subcollection
- Minimal post doc size and fast feed reads.
- Lazy load heavy data in detail.
- Flexible for future attachment types.
- Easier moderation and cleanup.