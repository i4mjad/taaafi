### Goal
Introduce extensible attachments for community posts with initial types: image, poll, and support group invitation. Creation is Plus-only; viewing is allowed for everyone (with type-specific actions possibly gated).

### Constraints and principles
- Extensibility first: adding new types without breaking existing ones.
- Backward compatible: old posts unaffected.
- Small, indexable post documents; keep heavy payloads in storage/subcollections.
- Strong client-side UX + server-side enforcement (rules).
- Clear Plus gating in UI and security rules.

### Current state (relevant)
- Post storage: no attachments fields in `forumPosts`.
- DTO: `PostFormData` contains `attachmentUrls` and validation hooks; not wired end-to-end.
- Attachment model: `PostAttachment` exists with type, URL, metadata, etc., but is not integrated.
- Composer: `NewPostScreen` builds `PostFormData` without attachments.
- Rendering: `PostContentWidget` and `ThreadsPostCard` render title/body; no attachment surface.
- Gating: `checkFeatureAccess` and Plus subscription services exist and are used for post creation.

### Data and schema plan
- Post document changes:
  - Add a compact field: attachmentsSummary (array of small objects with id, type, displayName, thumbnailUrl, minimal metadata). Bounded by a small maximum per post (e.g., 3).
  - Add attachmentTypes (array of strings) for quick filtering/badging and indexes.
  - Keep body/title unchanged.
- Attachment storage:
  - For light types (poll, group invite): store as small objects either embedded in attachmentsSummary payload or in a `forumPosts/{postId}/attachments/{attachmentId}` subcollection. Prefer subcollection to avoid bloating the post document and to support future expansion.
  - For images: store files in Cloud Storage; attachment record stores storage path, download URL, dimensions, size, and a server-generated thumbnail URL.
- Versioning:
  - Each attachment carries a schemaVersion and a type. Unknown types are ignored by the client but kept in storage for forward-compat.
- Indexing:
  - Add Firestore index for queries on attachmentTypes if needed (e.g., listing posts with polls).

### Attachment types v1
- Image:
  - Payload: storage path, url, width/height, size, thumbnailUrl, content hash.
  - Limits: max items per post, max file size, accepted formats.
- Poll:
  - Payload: question, options (2–6), multipleChoice flag, closesAt (optional), results summary (redundant counters), and owner CP id.
  - Votes are records in a `pollVotes` subcollection under the post to avoid concurrent counter issues; maintain aggregated counts in the poll doc; enforce one vote per CP (security rules).
  - Editing: disallow edits after first vote; allow closing.
- Support group invitation:
  - Payload: target groupId, display snapshot (name, capacity, memberCount, gender), joinMethod, plusOnly flag, optional joinCode token or deep link.
  - Action button opens group detail/join flow; enforce gender, capacity, cooldown, and Plus checks via existing groups services.

### Client architecture
- Attachment registry:
  - A central registry mapping type → serializer/deserializer, validator, composer UI, and renderer widget. New types register themselves without touching core flows.
- Composer changes (`NewPostScreen` and providers):
  - Attachments tray: buttons for Add Image, Add Poll, Invite to Group.
  - Show active attachments as chips/cards with remove/edit actions.
  - Plus gating: the tray and actions are visible but gated; clicking when not Plus opens a premium CTA; if user upgrades, enable in-session.
  - Validation: per-type validation + global constraints (max attachments, mixed-type rules such as one poll per post and one group invite per post).
  - Submission: create post first, then upload attachments (images to storage), then create attachment docs in subcollection, finally write attachmentsSummary to post doc. Use an atomic pattern: write post with a pendingAttachments flag; once all attachments are created, write a finalize flag and summary. This avoids large single writes and allows robust retries.
- Rendering:
  - Post list (`ThreadsPostCard`): read attachmentsSummary to show a compact preview (e.g., image thumbnail grid, poll badge with counts, group invite card header).
  - Post detail (`PostContentWidget` + a new attachment renderer): render full attachment components by fetching subcollection docs. Lazy-load images and poll results.
  - Deep links: tapping a group invite navigates to the group detail/join surface. Tapping a poll opens voting UI if open, otherwise results.
- Error handling:
  - Resilient uploads with retry and cancellation; show per-attachment error states.
  - If any attachment fails, allow post to publish with partial attachments or prompt to retry; ensure consistency (e.g., don’t show poll badge if poll creation failed).

### Plus gating
- UI gating:
  - Guard the attachments tray via `checkFeatureAccess` with a new feature key (e.g., postAttachments).
  - Specific sub-features can be individually gated (e.g., polls vs. group invites) via dedicated feature keys to roll out gradually.
- Server-side gating:
  - Firestore rules: only Plus users may write to attachments subcollections and attachmentsSummary fields. Everyone can read.
  - Poll votes: allowed for all users; optionally restrict to authenticated CPs.
  - Group invite acceptance: separate from attachments; groups services already enforce Plus and gender constraints as needed.

### Validation and moderation
- Client validation:
  - Extend the existing post validation service to validate attachments per type and total counts.
- Security:
  - Firestore rules validate allowed attachment types, sizes (via metadata), and that the creator matches the post author.
  - Poll votes rules ensure one vote per CP per poll.
- Moderation:
  - Provide admin capability to remove an attachment or entire post; removing an attachment updates attachmentsSummary.
  - Image moderation pipeline (optional for v1): basic MIME/size checks now, image scanning later.

### Analytics and telemetry
- Track: startedAttachmentFlow, addedImage, createdPoll, invitedToGroup, votePoll, joinedGroupFromInvite, attachmentUploadFailed, attachmentRendered.
- Correlate to Plus conversion events from the CTA.

### Performance and UX
- Keep post list lean using attachmentsSummary only; load detailed attachments on demand in post detail to minimize reads.
- Thumbnails for images; pre-generate via Cloud Function or client-side before upload.
- Pagination unaffected; attachments are lazy.

### Backward compatibility and migration
- Existing posts: no changes required.
- `attachmentUrls` in form data: deprecated in favor of typed attachments; continue to support reading it as image attachments for a short transition window if it’s used anywhere.

### Admin/ops
- Update admin schema docs to add attachments and poll subcollections.
- Admin panel: display, remove attachments; show poll statistics and close polls.

### Phased rollout
- Phase 1: image attachments only (Plus-gated), with attachmentsSummary and subcollection writes; post list previews; detail renders.
- Phase 2: support group invitations; integrate with groups join flows and constraints.
- Phase 3: polls; voting subcollection, real-time updates, closing logic.
- Phase 4: security-hardening, image moderation, and extended feature flags.

### Testing
- Unit tests: serialization/deserialization, validators, attachment registry.
- Integration tests: composer add/remove flows, submit with retries, rendering in list/detail, group invite join, poll voting.
- Rules tests: Plus-only writes, poll vote constraints.

### Risks and mitigations
- Large post document size: mitigate by keeping attachmentsSummary small and moving payloads to subcollections.
- Partial failures: finalize step and idempotent attachment creation with retries.
- Abuse of polls or invites: rate limit attachment creation per user and per type; add admin tools to disable features rapidly via remote config.

- I have a clear plan for adding attachments with an attachment registry, attachments subcollection, and a compact summary on posts, with Plus gating on creation and full read access for all. I’ll apply this in the post composer, repository/service layer, rendering, rules, and analytics in phases to limit risk.

- Key edits you’ll see:
  - Add attachmentsSummary and attachmentTypes to post docs; create `forumPosts/{postId}/attachments/*` and `pollVotes` subcollections.
  - Integrate a typed attachment registry.
  - Wire composer to create and manage attachments; finalize writes.
  - Enforce Plus-only creation with UI guard and security rules.
  - Render previews in `ThreadsPostCard` and full content in post detail.