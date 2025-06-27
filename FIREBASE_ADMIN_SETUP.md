# Firebase Admin SDK Setup Guide

## Prerequisites

Your user management system is now configured to use **real Firebase Admin SDK** instead of mock data. To enable this functionality, you need to set up Firebase Admin SDK credentials.

## Step 1: Install Firebase Admin SDK

```bash
npm install firebase-admin
```

## Step 2: Get Firebase Service Account Credentials

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon) → **Service Accounts**
4. Click **"Generate new private key"**
5. Download the JSON file and keep it secure

## Step 3: Configure Environment Variables

Create a `.env.local` file in your project root with the following variables:

```env
# Firebase Admin SDK Configuration
FIREBASE_ADMIN_PROJECT_ID=your-project-id
FIREBASE_ADMIN_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com
FIREBASE_ADMIN_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"
```

**Important Notes:**
- Copy the values from your downloaded JSON file
- For `FIREBASE_PRIVATE_KEY`, keep the `\n` characters as literal `\n` in the string
- Never commit the `.env.local` file to version control

## Step 4: Restart Your Development Server

```bash
npm run dev
```

## What's Now Working

With Firebase Admin SDK configured, your user management system will:

✅ **List Real Users**: Fetch actual users from Firebase Auth  
✅ **User Details**: Display real user information and metadata  
✅ **Delete Users**: Remove users from both Firebase Auth and Firestore  
✅ **Ban/Unban Users**: Update user disabled status in Firebase Auth  
✅ **Search & Filter**: Real-time search through your actual user base  
✅ **Pagination**: Efficient pagination through large user lists  

## User Data Sources

The system intelligently combines data from two sources:

1. **Firebase Auth**: Core user data (email, creation date, login times, etc.)
2. **Firestore 'users' collection**: Additional profile data (roles, metadata, etc.)

If a user doesn't have a Firestore document, the system will still display their Firebase Auth data with sensible defaults.

## Troubleshooting

### Error: "Firebase Admin SDK credentials not found"
- Check that all environment variables are set correctly in `.env.local`
- Restart your development server after adding environment variables

### Error: "Permission denied"
- Ensure your service account has the necessary permissions
- The downloaded service account should have admin privileges by default

### Users not showing up
- Check that users exist in your Firebase Auth
- Verify the project ID matches your Firebase project

## Security Notes

- Never expose your private key in client-side code
- Keep your service account JSON file secure
- Consider using different service accounts for development and production
- The `.env.local` file is ignored by Git by default - keep it that way! 