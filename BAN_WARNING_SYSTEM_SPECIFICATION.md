# Ban & Warning System Specification

## Overview

This document outlines the complete ban and warning system architecture for the Ta'aafi Platform. The system provides comprehensive user moderation capabilities with device tracking for ban evasion prevention.

## Data Structures

### Ban Interface

```typescript
interface Ban {
  id?: string;
  userId: string;
  type: 'user_ban' | 'device_ban' | 'feature_ban';
  /**
   * For 'user_ban' and 'device_ban', scope is always 'app_wide'.
   * For 'feature_ban', scope is always 'feature_specific'.
   * The admin cannot select scope for user or device bans.
   */
  scope: 'app_wide' | 'feature_specific';
  reason: string;
  description?: string;
  severity: 'temporary' | 'permanent';
  issuedBy: string; // Admin UID
  issuedAt: Timestamp | Date;
  expiresAt?: Timestamp | Date | null; // null for permanent bans
  isActive: boolean;
  
  // Feature-specific restrictions
  restrictedFeatures?: string[]; // Array of feature unique names
  
  // Device bans (not currently used in restrictedDevices, but available)
  restrictedDevices?: string[];
  
  // Device tracking for all ban types
  deviceIds?: string[]; // User's device IDs at time of ban
  
  // Related content reference
  relatedContent?: {
    type: 'user' | 'report' | 'post' | 'comment' | 'message' | 'group' | 'other';
    id: string;
    title?: string;
    metadata?: { [key: string]: any };
  };
}
```

### Warning Interface

```typescript
interface Warning {
  id?: string;
  userId: string;
  type: 'content_violation' | 'inappropriate_behavior' | 'spam' | 'harassment' | 'other';
  reason: string;
  description?: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  issuedBy: string; // Admin UID
  issuedAt: Timestamp | Date;
  isActive: boolean;
  
  // Device tracking
  deviceIds?: string[]; // User's device IDs at time of warning
  
  // Related content reference
  relatedContent?: {
    type: 'user' | 'report' | 'post' | 'comment' | 'message' | 'group' | 'other';
    id: string;
    title?: string;
    metadata?: { [key: string]: any };
  };
  
  // Report linkage
  reportId?: string; // Link to user report if applicable
}
```

## Ban Types & Logic

### 1. User Ban
- **Scope**: Always `app_wide` (system-wide, auto-set)
- **Purpose**: Complete platform access restriction for the user account
- **Use Case**: General user violations, account-level bans
- **Note**: The admin cannot select a feature-specific user ban. User bans are always system-wide.

### 2. Feature Ban
- **Scope**: Always `feature_specific` (auto-set)
- **Purpose**: Restrict access to specific platform features only
- **Use Case**: Feature-specific violations (e.g., messaging abuse, posting restrictions)

### 3. Device Ban
- **Scope**: Always `app_wide` (auto-set)
- **Purpose**: Block specific devices from accessing the platform
- **Use Case**: Ban evasion prevention, device-level violations
- **Note**: The admin cannot select a feature-specific device ban. Device bans are always system-wide.

## Warning Types

### Warning Categories
- `content_violation`: Content policy violations
- `inappropriate_behavior`: Behavioral issues
- `spam`: Spam or excessive posting
- `harassment`: Harassment or bullying
- `other`: Other violations

### Severity Levels
- `low`: Minor violations
- `medium`: Moderate violations
- `high`: Serious violations
- `critical`: Severe violations requiring immediate attention

## Device Tracking System

### Purpose
Track device IDs to prevent ban evasion through new account creation.

### Implementation
1. **Capture Device IDs**: Store user's device IDs when issuing bans/warnings
2. **Cross-Reference**: Check for existing violations on the same devices
3. **Alert System**: Warn admins of potential ban evasion attempts

### Device History Query
```typescript
// Query bans with matching device IDs
const bansQuery = query(
  collection(db, 'bans'),
  where('deviceIds', 'array-contains-any', userDeviceIds.slice(0, 10))
);

// Query warnings with matching device IDs  
const warningsQuery = query(
  collection(db, 'warnings'),
  where('deviceIds', 'array-contains-any', userDeviceIds.slice(0, 10))
);
```

### Device History Display
- **Current User Violations**: Blue background with "👤 This User" label
- **Other User Violations**: White background with abbreviated User ID
- **Information Shown**: User ID, status (active/inactive), reason, date
- **Limit**: Show up to 3 violations, with "show more" indicator

## Validation Rules

### Ban Validation
```typescript
// Reason is always required
if (!reason.trim()) throw new Error('Reason is required');

// Feature bans require at least one feature
if (type === 'feature_ban' && restrictedFeatures.length === 0) {
  throw new Error('At least one feature must be selected');
}

// User bans and device bans are always app-wide; scope is not selectable.
// Temporary bans require expiration date and time
if (severity === 'temporary') {
  if (!expiresDate) throw new Error('Date is required for temporary bans');
  if (!expiresTime.trim()) throw new Error('Time is required for temporary bans');
}
```

### Warning Validation
```typescript
// Reason is always required
if (!reason.trim()) throw new Error('Reason is required');
```

## Firebase Collections

### Collection Structure
```
/bans/{banId}
/warnings/{warningId}
/features/{featureId} // For feature restrictions
/usersReports/{reportId} // For report linkage
```

### Security Rules Example
```javascript
// Bans collection - admin only
match /bans/{banId} {
  allow read, write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'moderator'];
}

// Warnings collection - admin only
match /warnings/{warningId} {
  allow read, write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'moderator'];
}
```

## Ban Expiration Logic

### Checking Expiration
```typescript
const isBanExpired = (ban: Ban): boolean => {
  if (!ban.expiresAt) return false; // Permanent bans never expire
  const expiryDate = convertTimestamp(ban.expiresAt);
  return expiryDate < new Date();
};
```

### Active Ban Filtering
```typescript
const activeBans = bans.filter(ban => ban.isActive && !isBanExpired(ban));
const expiredBans = bans.filter(ban => isBanExpired(ban));
```

## UI/UX Guidelines

### Ban Creation Flow
1. **Select Ban Type**: User/Feature/Device
2. **Auto-set Scope**: Based on ban type selection
   - **User Ban**: Automatically app-wide (system-wide, not selectable)
   - **Feature Ban**: Automatically feature-specific
   - **Device Ban**: Automatically app-wide (not selectable)
3. **Configure Details**: Reason, description, severity
4. **Feature Selection**: Only shown for feature bans
5. **Set Duration**: Temporary (with date/time) or permanent
6. **Device History Alert**: Show if violations found on user's devices
7. **Confirmation**: Review and create ban

### Device History Alert Design
```
⚠️ Device History Alert
Previous violations found on devices associated with this user:

Previous Bans (2):
👤 This User - Active - Spam violation - Dec 15, 2023
    User ID: ab12cd34... - Inactive - Content violation - Dec 10, 2023

Recommendation: Consider escalating this warning to a ban based on device history.
```

### Warning Creation Flow
1. **Select Warning Type**: Content/Behavior/Spam/Harassment/Other
2. **Set Severity**: Low/Medium/High/Critical
3. **Configure Details**: Reason, description
4. **Link Content**: Optional related content/report reference
5. **Device History Alert**: Show if violations found on user's devices
6. **Confirmation**: Review and create warning

## Admin Interface Requirements

### Ban Management Card
- Display active, expired, and total ban counts
- Table view with ban details, status badges, and actions
- Create ban dialog with all configuration options
- Revoke ban functionality
- Device history alerts during creation

### Warning Management Card  
- Display active, inactive, and total warning counts
- Table view with warning details, severity badges, and actions
- Create warning dialog with all configuration options
- Device history alerts during creation

### Required Permissions
- `admin`: Full ban/warning management
- `moderator`: Limited ban/warning management (if applicable)

## Error Handling

### Common Error Scenarios
```typescript
// Network errors
catch (error) {
  if (error.code === 'unavailable') {
    showError('Network connection lost. Please try again.');
  } else if (error.code === 'permission-denied') {
    showError('Access denied. You do not have permission to perform this action.');
  } else {
    showError('An unexpected error occurred. Please contact support.');
  }
}
```

### Validation Error Messages
- English and Arabic translations required
- Clear, actionable error messages
- Field-specific validation feedback

## Translation Keys

### Required Translation Sections
```json
{
  "modules": {
    "userManagement": {
      "bans": { /* Ban-related translations */ },
      "warnings": { /* Warning-related translations */ }
    }
  }
}
```

### Key Translation Areas
- Ban/warning types and severities
- Form labels and placeholders
- Error messages
- Device history alerts
- Success/failure messages
- Status badges

## Performance Considerations

### Firestore Limitations
- `array-contains-any` queries limited to 10 items
- Device ID arrays should be sliced: `deviceIds.slice(0, 10)`
- Use composite indexes for complex queries

### Recommended Indexes
```
Collection: bans
- userId (Ascending)
- isActive (Ascending) 
- issuedAt (Descending)

Collection: warnings  
- userId (Ascending)
- isActive (Ascending)
- issuedAt (Descending)

Collection: bans
- deviceIds (Array)

Collection: warnings
- deviceIds (Array)
```

## Implementation Checklist

### Backend (Flutter)
- [ ] Create Ban and Warning data models
- [ ] Implement Firestore collections and security rules
- [ ] Add device tracking functionality
- [ ] Create ban/warning service classes
- [ ] Implement device history checking
- [ ] Add validation logic
- [ ] Handle ban expiration logic

### UI Components
- [ ] Ban management interface
- [ ] Warning management interface  
- [ ] Device history alert component
- [ ] Form validation and error handling
- [ ] Status badges and indicators
- [ ] Date/time pickers for ban expiration

### Translations
- [ ] English translations
- [ ] Arabic translations
- [ ] RTL support for Arabic interface
- [ ] Error message translations

### Testing
- [ ] Unit tests for ban/warning logic
- [ ] Integration tests for Firestore operations
- [ ] UI tests for admin interfaces
- [ ] Device tracking functionality tests

## Future Enhancements

### Potential Additions
1. **Appeal System**: Allow users to appeal bans/warnings
2. **Escalation Rules**: Automatic escalation based on violation history
3. **Bulk Actions**: Batch ban/warning operations
4. **Analytics**: Ban/warning statistics and trends
5. **IP Tracking**: Additional tracking beyond device IDs
6. **Scheduled Bans**: Time-delayed ban activation
7. **Ban Templates**: Pre-configured ban settings for common violations

---

*This specification should be reviewed and updated as the system evolves.* 