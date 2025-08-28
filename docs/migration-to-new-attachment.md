# Cursor Mission: Post Attachments v1

## 0) Project guardrails

* [x] Use **Firebase Functions (Node 20, TypeScript)**.
* [x] Firestore in **Native mode**, regional + **strongly consistent reads** where possible.
* [x] Enforce **idempotency** on all CFs; use server timestamps only.
* [x] Keep any single Firestore doc **< 1 MB**; cap attachment counts.

---

## 1) Firestore data model (collections, fields)

### 1.1 `forumPosts/{postId}` (document)

* [x] Fields (all server-maintained unless noted):

  * `authorId: string`
  * `createdAt: serverTimestamp`
  * `updatedAt: serverTimestamp`
  * `pendingAttachments: boolean` (default `true` if attachments are expected; else `false`)
  * `expectedAttachmentsCount: number` (0 if none)
  * `attachmentsFinalizedAt: serverTimestamp | null`
  * `attachmentsSummaryById: map<string, { type: 'image'|'poll'|'group_invite', thumbPath?: string, w?: number, h?: number, options?: number, isClosed?: boolean }>`
  * `attachmentsOrder: string[]` (for deterministic rendering)
  * `attachmentTypes: string[]` (`['image','poll',...]` unique)
  * `hasAttachments: boolean`
  * `attachmentCount: number`
  * `attachmentsPreview: string | null` (single tiny image URL or null)
  * `attachmentsVersion: number` (schema version, start with `1`)
  * `attachmentsComputedAt: serverTimestamp`
  * (other post fields: title/body, visibility, etc.)

### 1.2 Subcollection: `forumPosts/{postId}/attachments/{attachmentId}`

* [x] Common fields:

  * `type: 'image' | 'poll' | 'group_invite'`
  * `status: 'active' | 'flagged' | 'removed'`
  * `createdAt, updatedAt: serverTimestamp`
* [x] **Image** attachment:

  * `originalPath: string` (e.g., `images/{postId}/{attachmentId}/original.jpg`)
  * `thumbPath: string`
  * `w: number, h: number, mime: string, size: number`
  * `fileHash: string` (sha256 for idempotency)
* [x] **Poll** attachment (`{pollId}`):

  * `question: string`
  * `options: [{id: string, text: string, order: number}]` (max 6)
  * `selectionMode: 'single' | 'multiple'`
  * `isClosed: boolean`
  * `totalVotes: number` (display)
  * `optionCounts: map<optionId, number>` (display)
  * (Optional scaling) `shards: number` (e.g., 10)
* [x] **Group invite** attachment:

  * `inviterCpId: string`
  * `groupSnapshot: { id, name, memberCount, ... }`
  * `inviteCodeHash: string` (bcrypt/sha256; **never store raw code**)
  * `expiresAt: timestamp`
  * `revoked: boolean`

### 1.3 Votes subcollection (under the poll attachment)

* [x] Path: `forumPosts/{postId}/attachments/{pollId}/votes/{cpId}`

  * `selectedOptionIds: string[]`
  * `votedAt: serverTimestamp`

### 1.4 (Optional scaling) Poll shard counters

* [x] Path: `forumPosts/{postId}/attachments/{pollId}/counters/{shardId}`

  * `totalVotes: number`
  * `optionCounts: map<optionId, number>`

---

## 2) Cloud Storage paths

* [x] Images:

  * `images/{postId}/{attachmentId}/original.jpg`
  * `images/{postId}/{attachmentId}/thumb.jpg`

---

## 3) Cloud Functions (TypeScript)

> Create `functions/src/attachments/` with modules below. Ensure **idempotency**: check current state before mutating.

### 3.1 `generateImageThumbnails` (Storage trigger)

* [x] Trigger: on **finalize** for `images/{postId}/{attachmentId}/original.*`.
* [x] Steps:

  * If `thumb.jpg` exists → **return** (idempotent).
  * Generate thumbnail (e.g., 320px max edge) with **sharp**.
  * Save to `thumb.jpg`.
  * Update attachment doc with `thumbPath, w, h, mime, size`.
  * **No client writes** to these fields.

### 3.2 `onAttachmentWriteComputeSummary` (Firestore trigger)

* [x] Trigger: on **create/update/delete** of `forumPosts/{postId}/attachments/{attachmentId}`.
* [x] Steps:

  * Load all attachments **lightweight** (fields needed for summary only).
  * Recompute:

    * `attachmentsSummaryById` (map),
    * `attachmentsOrder`,
    * `attachmentTypes`,
    * `hasAttachments`,
    * `attachmentCount`,
    * `attachmentsPreview` (first `thumbPath` if any).
  * Write to `forumPosts/{postId}` with merge.
  * Set `attachmentsComputedAt=serverTimestamp()`.

### 3.3 `finalizePostIfComplete` (Firestore trigger)

* [x] Trigger: on **create/update** of either:

  * `forumPosts/{postId}/attachments/*`, or
  * `forumPosts/{postId}`.
* [x] Steps:

  * If `pendingAttachments==true` and `attachmentCount == expectedAttachmentsCount`:

    * Set `pendingAttachments=false`, `attachmentsFinalizedAt=serverTimestamp()`.
  * **Do nothing** if already false (idempotent).

### 3.4 `onPollVoteWriteUpdateCounters` (Firestore trigger)

* [x] Trigger: on **create/update** of `.../votes/{cpId}`.
* [x] Steps:

  * Read poll attachment (`selectionMode`, `options`, `isClosed`).
  * Validate option IDs belong to poll.
  * If shards **disabled**:

    * Use **transaction** to:

      * Adjust `totalVotes` and `optionCounts` using delta between **new** and **old** selection.
  * If shards **enabled**:

    * Randomly pick `shardId`, **increment** counters atomically in that shard doc.
    * Optionally (or scheduled) fold shards into display fields on the poll attachment.
  * Notify poll author (FCM) if needed (non-blocking; try/catch).

### 3.5 `foldShardCounters` (optional, Pub/Sub schedule)

* [ ] Every **1 minute** (or 5): read all shard docs for open polls with recent votes, sum, write to poll doc.

### 3.6 `onPostDeleteCascade` (Firestore trigger)

* [x] Trigger: on **delete** `forumPosts/{postId}`.
* [x] Steps:

  * Paginated/batched delete of subcollection `attachments/*` (+ nested `votes/*`, `counters/*`).
  * Delete Storage folder `images/{postId}/**`.
  * Revoke active invites (set `revoked=true`).

### 3.7 Invite maintenance

* [ ] `onInviterMembershipRemoval` (Firestore trigger on your membership source): set `revoked=true` for matching attachment invites.
* [ ] `expireInvitesJob` (Pub/Sub schedule hourly): set `revoked=true` where `expiresAt < now && !revoked`.

### 3.8 Housekeeping jobs (Pub/Sub schedule)

* [ ] `cleanupOrphanAttachments`: remove attachment docs whose Storage object missing (and vice versa).
* [x] `cleanupStuckPosts` (e.g., every 6h): posts with `pendingAttachments==true` and `updatedAt < now-30m`: set `expectedAttachmentsCount=attachmentCount`, then finalize.

---

## 4) Security Rules (Firestore & Storage)

### 4.1 Helpers

* [x] Implement rules functions:

  * `isPostAuthor(postId)`: load post doc, compare `authorId`.
  * `isPlusUser(uid)`: from **custom claims** OR `/memberships/{uid}` doc.
  * `validAttachmentType(type)`: in `['image','poll','group_invite']`.
  * `pollOpen(postId, pollId)`: !attachment.isClosed
  * `validVoteSelection(request, pollDoc)`: IDs ⊆ options & respect `selectionMode`.

### 4.2 `forumPosts/{postId}`

* [x] Allow **create** by authenticated user.
* [x] Allow **update** by author **but** **block** changes to:

  * `attachmentsSummaryById`, `attachmentsOrder`, `attachmentTypes`,
  * `pendingAttachments`, `attachmentsFinalizedAt`,
  * `attachmentCount`, `hasAttachments`, `attachmentsPreview`,
  * `attachmentsComputedAt`, `attachmentsVersion`.
* [x] Allow **read** to public (or according to visibility).

### 4.3 `forumPosts/{postId}/attachments/{attachmentId}`

* [x] **create**: only post author **and** `isPlusUser(uid)` **and** `validAttachmentType(type)`.
* [x] **update/delete**: author or moderator.
* [x] **read**: public (unless your visibility model restricts it).

### 4.4 Poll votes `.../attachments/{pollId}/votes/{cpId}`

* [x] **create/update**: `request.auth.uid == cpId` and `pollOpen` and `validVoteSelection`.
* [x] **read**: only voter reads own vote (privacy).

### 4.5 Storage rules

* [x] Allow **write** to `images/{postId}/{attachmentId}/original.*` only if:

  * user is post author, plus member, and `attachmentId` follows your **stable** pattern `${postId}-${uuidOrHash}`.
* [x] Thumbnails **write** only by service account (via CF).

---

## 5) Client changes (minimal, robust)

### 5.1 Create post (client)

* [x] Create `forumPosts/{postId}` with:

  * `pendingAttachments = (files.length > 0 || hasPoll || hasInvite)`
  * `expectedAttachmentsCount = computedCount`
  * `createdAt = serverTimestamp()`
* [x] **Do not** write any summary fields.

### 5.2 Add attachments (client)

* [x] For **images**:

  * Compute `fileHash` (sha256) client-side; set **stable** `attachmentId = ${postId}-${fileHash.slice(0,12)}`.
  * Create attachment doc (type=image, status=active, fileHash).
  * Upload to Storage `original.*` **after** doc create (or vice versa but ensure idempotency).
  * Let CF generate thumbnail and update doc; summary auto-computed by CF.
* [x] For **poll**:

  * Create single poll attachment `{pollId = poll_${postId}}` with fields above.
* [x] For **invite**:

  * Generate random `inviteCode` client-side; send **only hash** (`inviteCodeHash`) to Firestore.
  * Never put raw code into `attachmentsSummaryById`.

### 5.3 Finalization

* [x] Client does **nothing**. CF handles flipping `pendingAttachments=false` when counts match.

### 5.4 Rendering

* [x] **List**: read from `attachmentsSummaryById`, `attachmentsOrder`, `attachmentsPreview`.
* [x] **Detail**: lazy-load `attachments/*` for full content.
* [x] **Poll voting**: write to `.../votes/{cpId}`; display aggregates from poll doc.

---

## 6) Indexes

* [x] Composite:

  * `forumPosts`: `pendingAttachments` (asc), `createdAt` (desc)
  * `forumPosts`: `attachmentTypes` (array-contains), `createdAt` (desc)
* [x] Single-field:

  * `createdAt` (descending)
  * `attachmentsFinalizedAt` (descending)
* [ ] Verify via emulator and deploy.

---

## 7) Limits & constants

* [x] `MAX_IMAGES_PER_POST = 4`
* [x] `MAX_POLL_OPTIONS = 6`
* [x] `THUMB_EDGE_PX = 320`
* [x] `POLL_SHARDS = 0` (start at 0; enable later if needed)
* [ ] Reject oversized images early (client & CF).

---

## 8) Housekeeping & schedulers

* [ ] `expireInvitesJob`: `functions.pubsub.schedule('every 60 minutes')`.
* [x] `cleanupStuckPosts`: `functions.pubsub.schedule('every 6 hours')`.
* [ ] `cleanupOrphanAttachments`: `functions.pubsub.schedule('every 24 hours')`.
* [ ] (Optional) `foldShardCounters`: `functions.pubsub.schedule('every 1 minutes')`.

---

## 9) Telemetry & moderation hooks

* [x] Add `status` (`active|flagged|removed`) on both posts & attachments.
* [ ] Centralize **Audit Log** collection for CFs: `auditLogs/{autoId}` with event, actor, target, delta, ts.
* [x] CFs emit structured logs; attach `postId`, `attachmentId`, `pollId`.

---

## 10) Packages & setup commands

* [x] `cd functions && npm i firebase-admin firebase-functions sharp`
* [x] `npm i -D @types/sharp typescript`
* [ ] Ensure `esbuild`/`tsup` bundling if needed for sharp.
* [x] Set Node runtime: `"engines": { "node": "20" }` in `functions/package.json`.

---

## 11) Acceptance tests (Emulator Suite)

* [ ] **Create post w/0 attachments** → `pendingAttachments=false`, `attachmentCount=0`, finalized.
* [ ] **Create post + 2 images** → upload; CF sets summary; auto-finalize when `count==2`.
* [ ] **Duplicate image retry** (same file) → same `attachmentId` → **no double count**.
* [ ] **Poll vote**:

  * first vote increments counts; update vote changes deltas correctly; invalid options rejected by rules.
* [ ] **Invite**:

  * `inviteCodeHash` stored; summary has no raw code; `expiresAt` passes; job marks `revoked`.
* [ ] **Deletion**: deleting post removes subcollections and Storage.
* [ ] **Security**:

  * Non-author cannot write attachments.
  * Non-plus author blocked from attachment creation.
  * User reads only **their** `votes/{cpId}`.

---

## 12) Code skeletons to create (paths)

* [x] `functions/src/attachments/storage.generateImageThumbnails.ts`
* [x] `functions/src/attachments/firestore.onAttachmentWriteComputeSummary.ts`
* [x] `functions/src/attachments/firestore.finalizePostIfComplete.ts`
* [x] `functions/src/polls/firestore.onPollVoteWriteUpdateCounters.ts`
* [ ] `functions/src/polls/pubsub.foldShardCounters.ts` (optional)
* [x] `functions/src/posts/firestore.onPostDeleteCascade.ts`
* [ ] `functions/src/invites/firestore.onInviterMembershipRemoval.ts`
* [ ] `functions/src/invites/pubsub.expireInvitesJob.ts`
* [ ] `functions/src/ops/pubsub.cleanupOrphanAttachments.ts`
* [x] `functions/src/ops/pubsub.cleanupStuckPosts.ts`
* [ ] `functions/src/lib/firestore.ts` (helpers: getPost, getPoll, batchedDelete, etc.)
* [x] `functions/src/lib/security.ts` (shared validation helpers)
* [ ] `functions/src/lib/ids.ts` (stable `attachmentId` logic)
* [x] `functions/src/index.ts` (export all triggers)

---

## 13) Implementation notes (critical)

* [x] **Stable IDs**: `attachmentId = ${postId}-${first12(fileHash)}`; validate format in Storage rules.
* [x] **Idempotency**: every CF checks current values before incrementing/finalizing.
* [x] **Map vs Array**: summary uses **map** to avoid full-array rewrites.
* [x] **Server timestamps** only; never trust client time.
* [x] **Plus gate**: prefer **custom claims**; provide fallback membership doc.
* [x] **Privacy**: votes readable only by the voter; aggregates on poll doc for others.

