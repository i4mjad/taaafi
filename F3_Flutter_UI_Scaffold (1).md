
# Flutter UI Scaffold (Revision C)

## Route map
| Path | Widget |
|------|--------|
| /community/forum | `ForumHomeScreen` |
| /community/forum/post/:postId | `PostDetailScreen` |
| /community/forum/new | `NewPostScreen` |
| /community/groups | `GroupListScreen` |
| /community/groups/:groupId | `GroupDetailScreen` |
| /community/groups/:groupId/chat | `GroupChatScreen` |
| /community/challenges | `GlobalChallengeListScreen` |
| /community/profile | `CommunityProfileSettingsScreen` |

### Widget changes
* Thread widgets renamed **Post** widgets.
* Reply composer attaches hidden `parentFor` & `parentId`.
* Referral code field under **Account Settings**.
