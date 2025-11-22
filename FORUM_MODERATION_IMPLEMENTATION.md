# Forum Content Moderation Implementation

This document describes the implementation of AI-powered moderation for forum posts and comments, following the same patterns as direct message moderation.

## Overview

The forum moderation system integrates AI analysis results from Cloud Functions and provides admin tools to review, approve, block, or hide content based on moderation status and confidence levels.

## Data Structure

### ForumPost & Comment Moderation Field

Both `forumPosts` and `comments` collections now include a `moderation` field with the following structure:

```typescript
interface ForumPostModeration | CommentModeration {
  status: 'approved' | 'manual_review' | 'blocked';
  reason?: string;  // Localized string from cloud function
  ai?: {
    reason: string;
    violationType?: string;
    severity?: 'low' | 'medium' | 'high';
    confidence?: number;  // 0-1
    detectedContent?: string[];
    culturalContext?: string;
  };
  finalDecision?: {
    action: string;
    reason: string;
    violationType?: string;
    confidence: number;
  };
  customRules?: Array<{
    type: string;
    severity: 'low' | 'medium' | 'high';
    confidence: number;
    reason: string;
  }>;
  analysisAt?: Date;
}
```

### Visibility Rules

- **High Confidence (≥0.85)**: Content is automatically hidden (`isHidden = true`) until manually reviewed
- **Low Confidence (<0.85)**: Content remains visible but flagged for manual review
- **Pipeline Errors**: Content is hidden with `status = 'manual_review'`

## UI Components

### 1. ForumModerationBadge
**Location**: `/src/components/forum/ForumModerationBadge.tsx`

Displays the moderation status with appropriate color coding:
- ✅ **Approved**: Green badge
- ⚠️ **Manual Review**: Yellow badge
- ❌ **Blocked**: Red badge
- **Pending**: No badge (no moderation data yet)

### 2. ModerationDetailPanel
**Location**: `/src/components/forum/ModerationDetailPanel.tsx`

Comprehensive panel showing:
- Current moderation status
- Visibility state (hidden/visible)
- Final decision with confidence indicator
- AI analysis (expandable accordion)
  - Violation type
  - Severity level
  - Confidence score
  - Detected content
  - Cultural context
- Custom rules (expandable accordion)
- Analysis timestamp

### 3. ForumModerationActions
**Location**: `/src/components/forum/ForumModerationActions.tsx`

Quick action buttons for moderators:
- **Approve**: Sets status to 'approved' and unhides content
- **Block**: Sets status to 'blocked' and hides content
- **Hide/Unhide**: Toggles visibility without changing moderation status

Each action requires a reason (mandatory for block/hide actions).

## Admin Portal Integration

### Posts Management
**File**: `/src/app/[lang]/community/forum/components/ForumPostsManagement.tsx`

**Features Added**:
1. **Moderation Status Filter**: Dropdown to filter by moderation status
2. **Status Column**: Shows moderation badge and high-confidence indicator (shield icon)
3. **Filtered Posts**: Posts are filtered based on moderation status

### Comments Management
**File**: `/src/app/[lang]/community/forum/components/ForumCommentsManagement.tsx`

**Features Added**:
1. **Moderation Status Filter**: Dropdown to filter by moderation status
2. **Status Column**: Shows moderation badge and high-confidence indicator
3. **Filtered Comments**: Comments are filtered based on moderation status

### Post Detail View
**File**: `/src/app/[lang]/community/forum/components/PostDetailContent.tsx`

**Features Added**:
1. **Moderation Detail Panel**: Shows complete AI analysis in sidebar
2. **Quick Moderation Actions**: Sidebar card with approve/block/hide buttons
3. **Comment Badges**: Comments show high-confidence indicator when applicable
4. **Visual Indicators**: Hidden/blocked content is visually distinct

## Workflow

### For Moderators

1. **View Pending Content**:
   - Filter by "Manual Review" or "Blocked" status
   - Posts/comments with high confidence (≥85%) are automatically hidden

2. **Review Content**:
   - Click on post/comment to view details
   - Check moderation panel for AI analysis
   - Review confidence score, violation type, and detected content

3. **Take Action**:
   - **Approve**: Content is safe, make it visible
   - **Block**: Content violates rules, keep it hidden
   - **Hide**: Temporarily hide without changing moderation status

4. **Provide Reason**:
   - Required for block/hide actions
   - Optional for approve actions
   - Helps track moderation decisions

### Automatic Behavior

1. **Cloud Function Analysis**:
   - Posts and comments are analyzed on creation
   - AI detects violations and assigns confidence scores
   - Custom rules are evaluated

2. **Auto-Hide Logic**:
   - If `confidence ≥ 0.85` → `isHidden = true` + `status = 'manual_review'`
   - If `confidence < 0.85` → `isHidden = false` + `status = 'manual_review'`
   - If approved by AI → `status = 'approved'`

3. **Error Handling**:
   - Pipeline errors set `status = 'manual_review'` + `isHidden = true`
   - Localized error message stored in `moderation.reason`

## Translation Support

Both English and Arabic translations have been added for:
- Moderation status labels
- Filter labels
- Action buttons
- Dialog titles and descriptions
- Error messages
- AI analysis fields

**Translation Keys**: 
- English: `modules.community.forum.moderation.*`
- Arabic: `modules.community.forum.moderation.*`

## Integration with Existing Systems

### ModerationActionDialog
The existing `ModerationActionDialog` component is still used for:
- Warning/banning users
- Complex moderation workflows
- Accessing full user history

### New Quick Actions
The new `ForumModerationActions` component provides:
- Faster moderation for simple cases
- Direct status updates
- Content visibility toggle
- Required for the new AI moderation workflow

## Best Practices

1. **Review High-Confidence Flags**: Prioritize posts/comments with confidence ≥85%
2. **Check Context**: Use AI cultural context to understand regional sensitivities
3. **Document Decisions**: Always provide clear reasons for moderation actions
4. **Monitor Patterns**: Track violation types to identify systemic issues
5. **Update Custom Rules**: Adjust rules based on moderation feedback

## Future Enhancements

Potential improvements:
- Bulk moderation actions for similar violations
- Moderation history/audit log
- Appeal system for blocked content
- Moderator performance dashboard
- AI model training feedback loop
- Automated notification to content authors

## Technical Notes

- Uses `react-firebase-hooks` for real-time Firestore updates
- Moderation data is stored directly in post/comment documents (no separate queue)
- Confidence threshold (0.85) is hardcoded but can be made configurable
- All moderation actions update `updatedAt` timestamp
- Components follow existing design patterns from DM moderation

## Testing

To test the moderation system:
1. Navigate to Forum → Posts or Comments tab
2. Use moderation status filter to view flagged content
3. Click on a post/comment to view moderation details
4. Use quick actions or moderation dialog to take actions
5. Verify content visibility changes based on actions
6. Check that reasons are stored correctly

## Support

For questions or issues:
- Review existing DM moderation implementation for patterns
- Check Cloud Functions for moderation logic
- Verify Firestore security rules allow moderation updates
- Ensure admin users have proper permissions

