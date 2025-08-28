### Community Attachments – Cloud Functions Summary

- Poll aggregation (on vote write)
  - Path: `forumPosts/{postId}/pollVotes/{cpId}`
  - Trigger: on create
  - Behavior: Recomputes `totalVotes` and `optionCounts` and updates the poll attachment under `forumPosts/{postId}/attachments/{pollId}`.
  - Notes: Assumes one poll attachment per post; uses option ids to map to counts; idempotent via full recompute.

- Invite maintenance
  - On inviter leaves group
    - Path: `group_memberships/{membershipId}`
    - Trigger: on update (isActive: true → false)
    - Behavior: Revokes all `group_invite` attachments created by that inviter for the same `groupId` by setting `status = 'revoked'`.
  - Scheduled expiry
    - Schedule: every 60 minutes
    - Behavior: Scans posts with `group_invite` attachments and sets `status = 'expired'` for any invite whose `expiresAt` is in the past.

- Post delete cascade
  - Path: `forumPosts/{postId}`
  - Trigger: on delete
  - Behavior: Deletes all `attachments` subdocs and Storage files under `community_posts/{postId}/`.

- Implementation details
  - File: `functions/src/index.ts`
  - Exports: `onPollVoteWrite`, `onMembershipUpdateExpireInvites`, `scheduledExpireInvites`, `onPostDeleteCascade`.
  - Dependencies: `firebase-admin`, `firebase-functions`.
  - Regions: `us-central1`.

- Next steps
  - Add push notifications for poll create/close and invite joins (optional per product policy).
  - Consider indexing or denormalizing invites for more efficient queries.
  - Add unit tests in an emulator suite.



