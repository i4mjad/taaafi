
# Screen ↔ Collection Integration (Revision C)

| Screen | Reads | Writes |
|--------|-------|--------|
| ForumHome | forumCategories, forumPosts | — |
| PostDetail | forumPosts/{id}, comments, votes | comments, votes |
| Reply | — | forumPosts/{id}/comments |
| GroupChat | supportGroups/{id}/messages | messages |
| GlobalChallenges | globalChallenges, tasks, progress | progress |
| Profile Settings | users/{uid} | referralCode |
