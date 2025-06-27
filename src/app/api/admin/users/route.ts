import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

// Initialize Firebase Admin SDK
if (!getApps().length) {
  const serviceAccount = {
    projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
    privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
  };

  if (!serviceAccount.projectId || !serviceAccount.privateKey || !serviceAccount.clientEmail) {
    console.warn('Firebase Admin SDK credentials not found in environment variables. Please set FIREBASE_ADMIN_PROJECT_ID, FIREBASE_ADMIN_PRIVATE_KEY, and FIREBASE_ADMIN_CLIENT_EMAIL');
  } else {
    initializeApp({
      credential: cert(serviceAccount),
    });
  }
}

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '50');
    const search = searchParams.get('search') || '';
    const role = searchParams.get('role') || '';
    const status = searchParams.get('status') || '';
    const provider = searchParams.get('provider') || '';

    // Check if Firebase Admin is initialized
    const apps = getApps();
    
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const auth = getAuth();
    const firestore = getFirestore();

    // Helper function to convert provider ID to user-friendly display name
    const getProviderDisplayName = (providerId: string): string => {
      switch (providerId) {
        case 'google.com': return 'Google';
        case 'apple.com': return 'Apple';
        case 'facebook.com': return 'Facebook';
        case 'twitter.com': return 'Twitter';
        case 'github.com': return 'GitHub';
        case 'microsoft.com':
        case 'hotmail.com': return 'Microsoft';
        case 'yahoo.com': return 'Yahoo';
        case 'password': return 'Email';
        case 'playgames.google.com': return 'Google Play Games';
        case 'gc.apple.com': return 'Apple Game Center';
        default: 
          return providerId.replace('.com', '').replace(/\./g, ' ').split(' ')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1))
            .join(' ');
      }
    };

    // Optimization: Use Firebase's getUsers() for email-specific searches
    if (search && search.includes('@')) {
      try {
        const getUsersResult = await auth.getUsers([
          { email: search.trim() }
        ]);
        
        if (getUsersResult.users.length > 0) {
          const user = getUsersResult.users[0];
          const customClaims = user.customClaims || {};
          
          const transformedUser = {
            uid: user.uid,
            email: user.email || '',
            displayName: user.displayName || null,
            photoURL: user.photoURL || null,
            role: customClaims.role || 'user',
            status: user.disabled ? 'suspended' : 'active',
            createdAt: new Date(user.metadata.creationTime),
            updatedAt: new Date(user.metadata.lastRefreshTime || user.metadata.creationTime),
            lastLoginAt: user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime) : null,
            emailVerified: user.emailVerified,
            provider: getProviderDisplayName(user.providerData?.[0]?.providerId || 'password'),
            metadata: {
              loginCount: 0,
              lastIpAddress: null,
              userAgent: null,
            },
          };

          return NextResponse.json({
            users: [transformedUser],
            pagination: {
              page: 1,
              limit,
              total: 1,
              totalPages: 1,
              hasNext: false,
              hasPrev: false,
            }
          });
        } else {
          return NextResponse.json({
            users: [],
            pagination: {
              page: 1,
              limit,
              total: 0,
              totalPages: 0,
              hasNext: false,
              hasPrev: false,
            }
          });
        }
      } catch (emailSearchError) {
        // Fall through to full search below
      }
    }

    // Get users from Firebase Auth using official pagination pattern
    const FIREBASE_MAX_BATCH = 1000;
    const batchSize = search ? FIREBASE_MAX_BATCH : Math.min(500, limit * 10);
    
    const listUsersResult = await auth.listUsers(batchSize);
    let allUsers = listUsersResult.users;

    // Fetch additional pages if needed
    let nextPageToken = listUsersResult.pageToken;
    let totalFetched = allUsers.length;
    const maxFetch = search ? FIREBASE_MAX_BATCH * 2 : (page * limit + limit * 5);
    
    while (nextPageToken && totalFetched < maxFetch) {
      const nextBatch = await auth.listUsers(batchSize, nextPageToken);
      allUsers = allUsers.concat(nextBatch.users);
      totalFetched = allUsers.length;
      nextPageToken = nextBatch.pageToken;
      
      if (totalFetched >= FIREBASE_MAX_BATCH * 2) {
        break;
      }
    }



    // Transform Firebase users to our format (without Firestore data first)  
    let transformedUsers = allUsers.map(user => {
      const customClaims = user.customClaims || {};
      
      // Extract primary provider from providerData
      const getProvider = (providerData: any[]) => {
        if (!providerData || providerData.length === 0) return 'Email';
        
        // Provider priority: Social logins > Email/Password > Gaming platforms
        const providerPriority = [
          'google.com', 
          'apple.com', 
          'facebook.com', 
          'microsoft.com',
          'hotmail.com',
          'twitter.com',
          'github.com',
          'yahoo.com',
          'password',
          'playgames.google.com',
          'gc.apple.com'
        ];
        
        // Find the highest priority provider
        for (const priority of providerPriority) {
          const provider = providerData.find(p => p.providerId === priority);
          if (provider) {
            return getProviderDisplayName(provider.providerId);
          }
        }
        
        // Return the first provider if none match priority
        const firstProvider = providerData[0];
        return getProviderDisplayName(firstProvider.providerId);
      };


      
      return {
        uid: user.uid,
        email: user.email || '',
        displayName: user.displayName || null,
        photoURL: user.photoURL || null,
        role: customClaims.role || 'user',
        status: user.disabled ? 'suspended' : 'active',
        createdAt: new Date(user.metadata.creationTime),
        updatedAt: new Date(user.metadata.lastRefreshTime || user.metadata.creationTime),
        lastLoginAt: user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime) : null,
        emailVerified: user.emailVerified,
        provider: getProvider(user.providerData),
        metadata: {
          loginCount: 0,
          lastIpAddress: null,
          userAgent: null,
        },
      };
    });

    // Apply search filter
    if (search) {
      const searchLower = search.toLowerCase().trim();
      transformedUsers = transformedUsers.filter(user => {
        const emailMatch = user.email.toLowerCase().includes(searchLower);
        const nameMatch = user.displayName && user.displayName.toLowerCase().includes(searchLower);
        const uidMatch = user.uid.toLowerCase().includes(searchLower);
        
        return emailMatch || nameMatch || uidMatch;
      });
    }

    if (role) {
      transformedUsers = transformedUsers.filter(user => user.role === role);
    }

    if (status) {
      transformedUsers = transformedUsers.filter(user => user.status === status);
    }

    if (provider) {
      transformedUsers = transformedUsers.filter(user => user.provider === provider);
    }

    // Sort by creation date (newest first)
    transformedUsers.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

    // Apply pagination
    const total = transformedUsers.length;
    const totalPages = Math.ceil(total / limit);
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + limit;
    const paginatedUsers = transformedUsers.slice(startIndex, endIndex);

    // Fetch Firestore profiles for paginated users
    const userProfiles = new Map();
    try {
      const userIds = paginatedUsers.map(user => user.uid);
      const profilePromises = userIds.map(uid => 
        firestore.collection('users').doc(uid).get()
      );
      
      const profileSnapshots = await Promise.all(profilePromises);
      profileSnapshots.forEach((snapshot, index) => {
        if (snapshot.exists) {
          userProfiles.set(userIds[index], snapshot.data());
        }
      });
    } catch (firestoreError) {
      // Silently handle Firestore errors and continue without profiles
    }

    // Enhance paginated users with Firestore data
    const enhancedUsers = paginatedUsers.map(user => {
      const profile = userProfiles.get(user.uid) || {};
      return {
        ...user,
        displayName: user.displayName || profile.displayName || null,
        photoURL: user.photoURL || profile.photoURL || null,
        role: user.role || profile.role || 'user',
        status: user.status === 'suspended' ? 'suspended' : (profile.status || 'active'),
        provider: user.provider, // Keep provider from Firebase Auth, don't override with Firestore
        metadata: {
          loginCount: profile.metadata?.loginCount || 0,
          lastIpAddress: profile.metadata?.lastIpAddress || null,
          userAgent: profile.metadata?.userAgent || null,
        },
      };
    });

    return NextResponse.json({
      users: enhancedUsers,
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNext: endIndex < total,
        hasPrev: page > 1,
      },
    });
  } catch (error) {
    return NextResponse.json(
      { 
        error: 'Failed to fetch users',
        details: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const { userIds } = await request.json();
    
    if (!Array.isArray(userIds) || userIds.length === 0) {
      return NextResponse.json(
        { error: 'User IDs array is required' },
        { status: 400 }
      );
    }

    const auth = getAuth();
    const firestore = getFirestore();
    
    let deletedCount = 0;
    const errors: string[] = [];

    // Delete users one by one (Firebase Admin doesn't support batch delete)
    for (const uid of userIds) {
      try {
        // Delete from Firebase Auth
        await auth.deleteUser(uid);
        
        // Delete from Firestore (if user document exists)
        try {
          await firestore.collection('users').doc(uid).delete();
        } catch (firestoreError) {
          console.warn(`Could not delete Firestore document for user ${uid}:`, firestoreError);
        }
        
        deletedCount++;
      } catch (error: any) {
        console.error(`Error deleting user ${uid}:`, error);
        errors.push(`Failed to delete user ${uid}: ${error.message}`);
      }
    }

    if (errors.length > 0 && deletedCount === 0) {
      return NextResponse.json(
        { error: 'Failed to delete any users', details: errors },
        { status: 500 }
      );
    }
    
    return NextResponse.json({ 
      success: true, 
      message: `Successfully deleted ${deletedCount} out of ${userIds.length} users`,
      deletedCount,
      errors: errors.length > 0 ? errors : undefined
    });
  } catch (error) {
    console.error('Error deleting users:', error);
    return NextResponse.json(
      { error: 'Failed to delete users' },
      { status: 500 }
    );
  }
} 