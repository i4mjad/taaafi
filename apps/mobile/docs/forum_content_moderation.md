## Forum Content Moderation Data

This note captures the Firestore document structure that the new `moderateForumPost` and `moderateComment` functions produce and outlines how the admin portal (Next.js) should evolve to consume these signals.

### `forumPosts/{postId}`
- **Core fields**: `authorCpId`, `postId`, `title`, `body`, `category`, `createdAt`, `updatedAt`, `isDeleted`, `isHidden`, engagement counters.
- **Moderation block (`moderation` map)**:
  - `status`: `'approved' | 'manual_review' | 'blocked'`.
  - `reason`: localized string written by the cloud function (localized to author locale).
  - `ai`: raw OpenAI output (`reason`, `violationType`, `severity`, `confidence`, `detectedContent`, `culturalContext`).
  - `finalDecision`: `{ action, reason, violationType, confidence }` describing the synthesized result that determined `status`.
  - `customRules`: array of custom detections `{ type, severity, confidence, reason }`.
  - `analysisAt`: server timestamp of the last moderation pass.
- **Visibility rules**:
  - When `moderation.status === 'manual_review'` **and** `finalDecision.confidence >= 0.85`, the document now sets `isHidden = true`. This hides the post from clients until a moderator resolves it.
  - Any pipeline or critical error also forces `isHidden = true` with `status = 'manual_review'` and `reason = LOCALIZED_MESSAGES.system_error`.

### `comments/{commentId}`
- **Core fields**: `authorCpId`, `postId`, `body`, `parentFor`, `parentId`, `createdAt`, `updatedAt`, `isDeleted`, `isHidden`, engagement counters.
- **Moderation block**: identical schema to `forumPosts`.
- **Visibility rules**:
  - Same 0.85 confidence threshold—high-confidence manual reviews are hidden (`isHidden = true`), while lower-confidence cases remain visible but annotated.
  - Pipeline failures also hide the comment.

### Confidence Threshold Recap
- `confidence >= 0.85`: hide automatically until resolved.
- `confidence < 0.85`: remain visible but flagged for manual review.
- This is inverted from the original group-update logic; ensure any admin workflows assume the new rule for posts/comments.

## Next.js Admin Portal Guidance

- **Target Views**: Forum posts list/detail and comments management views.
- **Primary tasks for the AI agent**:
  1. Fetch `isHidden` and the full `moderation` map when querying both collections. Ensure Firestore queries include these fields (no projection in Firestore, but do not strip them client-side).
  2. Surface moderation status chips (e.g., `approved`, `manual review`, `blocked`) with confidence + violation info. Show localized reason plus AI metadata on demand (accordion/drawer).
  3. Provide actions similar to message moderation (approve, block, hide/unhide). Mirror the workflows that already exist for direct-message moderation; the code can be found by inspecting the admin portal repo via MCP (look for the DM moderation page/components).
  4. When displaying content, visually differentiate `isHidden` items (e.g., gray text, “Hidden until review” banner) and allow admins to toggle visibility once a decision is made.
  5. Record moderator actions back to Firestore (`moderation.status`, `moderation.reason`, `isHidden`) so the mobile clients stay in sync.

- **How to proceed**:
  - Use MCP to open the relevant Next.js files (start where the posts and comments tables are rendered). Follow existing patterns from the DM moderation implementation (search for “messages moderation” in the admin portal repo).
  - Confirm that server-side API routes or Firestore hooks have access to the extra fields; extend them if missing.
  - Add filters/sorting on `moderation.status` and `isHidden` to let moderators focus on pending work.
  - Reuse any shared moderation UI primitives (badges, decision drawers) to keep UX consistent.

This guide should give the AI agent enough structure to implement UI changes confidently and to understand the Firestore documents it is reading/writing.

