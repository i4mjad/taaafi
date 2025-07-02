# Firebase Troubleshooting Guide - Ban & Features Loading Issues

## Current Issue
The ban management page is showing loading errors for both the `bans` and `features` collections. This document helps resolve these Firebase connectivity and permission issues.

## Symptoms
- Error: "فشل في تحميل البيانات" (Failed to load data)
- Red error: `modules.userManagement.bans.errors.loadingFailed`
- Yellow warning: `modules.features.appFeatures.errors.loadingFailed`
- "لا يوجد حظر" (No bans) displayed

## Common Causes & Solutions

### 1. Firestore Security Rules

**Issue**: Firestore security rules prevent read/write access to collections.

**Solution**: Deploy the security rules provided in `firestore.rules`:

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase project (if not done)
firebase init firestore

# Deploy security rules
firebase deploy --only firestore:rules
```

**Check Current Rules**:
1. Go to Firebase Console → Firestore Database → Rules
2. Ensure rules allow read/write access to `bans`, `warnings`, `features` collections

### 2. Missing Collections

**Issue**: Collections don't exist in Firestore yet.

**Solution**: Create collections manually:

1. Go to Firebase Console → Firestore Database → Data
2. Create collections:
   - `features` (for app features)
   - `bans` (for user bans)
   - `warnings` (for user warnings)

**Sample Feature Document**:
```json
{
  "uniqueName": "direct_messaging",
  "nameEn": "Direct Messaging",
  "nameAr": "الرسائل المباشرة",
  "descriptionEn": "Send private messages to other users",
  "descriptionAr": "إرسال رسائل خاصة للمستخدمين الآخرين",
  "category": "communication",
  "iconName": "message-circle",
  "isActive": true,
  "isBannable": true,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### 3. Missing Firestore Indexes

**Issue**: Composite queries require custom indexes.

**Solution**: The code has been updated to use simpler queries, but if you need the original complex queries:

1. Check Firebase Console → Firestore Database → Indexes
2. Create composite indexes for:
   - Collection: `bans`, Fields: `userId` (Ascending), `issuedAt` (Descending)
   - Collection: `features`, Fields: `isActive` (Ascending), `isBannable` (Ascending), `category` (Ascending)

### 4. Authentication Issues

**Issue**: User not authenticated or missing permissions.

**Solution**: 
1. Ensure user is logged in
2. Check browser console for authentication errors
3. Verify Firebase Auth configuration

### 5. Network/Configuration Issues

**Issue**: Firebase configuration or network connectivity problems.

**Solution**:
1. Check `src/lib/firebase.ts` configuration
2. Verify Firebase project ID and API keys
3. Check browser network tab for failed requests

## Debugging Steps

### 1. Check Browser Console
Open browser developer tools (F12) and check console for detailed error messages:

```javascript
// Look for errors like:
// "Missing or insufficient permissions"
// "The query requires an index"
// "Network error"
```

### 2. Test Firebase Connection
Add this test code temporarily to check Firebase connectivity:

```javascript
import { collection, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';

// Test basic connectivity
async function testFirebase() {
  try {
    const snapshot = await getDocs(collection(db, 'features'));
    console.log('Firebase connection successful:', snapshot.size, 'documents');
  } catch (error) {
    console.error('Firebase connection failed:', error);
  }
}

testFirebase();
```

### 3. Check Firestore Rules Simulator
1. Go to Firebase Console → Firestore Database → Rules
2. Use the Rules Simulator to test read/write permissions
3. Test with your user authentication

## Quick Fixes

### Immediate Solution (Development Only)
Deploy the provided `firestore.rules` file:

```bash
firebase deploy --only firestore:rules
```

This allows unrestricted access for development. **Do not use in production**.

### Create Sample Data
Use the App Features page to create some sample features:

1. Go to Features → App Features
2. Click "Create Feature"
3. Add a few sample features
4. Ensure `isActive: true` and `isBannable: true`

### Verify Collections
Check Firebase Console that these collections exist:
- `features` (with sample documents)
- `bans` (can be empty initially)
- `warnings` (can be empty initially)

## Production Considerations

### Secure Firestore Rules
Replace the development rules with proper authentication:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can read/write
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Or more specific rules for each collection
    match /features/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.token.admin == true; // Only admins can modify
    }
  }
}
```

### Indexes for Performance
For production, create proper indexes:

```yaml
# firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "bans",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "issuedAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "features",
      "queryScope": "COLLECTION", 
      "fields": [
        {"fieldPath": "isActive", "order": "ASCENDING"},
        {"fieldPath": "isBannable", "order": "ASCENDING"},
        {"fieldPath": "category", "order": "ASCENDING"}
      ]
    }
  ]
}
```

## Support

If issues persist:
1. Check Firebase Console for service status
2. Verify billing account is active
3. Check Firebase quota limits
4. Review Firebase project settings

The updated code includes detailed error logging in the browser console to help identify the specific issue. 