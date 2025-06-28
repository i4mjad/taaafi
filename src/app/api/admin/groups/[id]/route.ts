import { NextRequest, NextResponse } from 'next/server';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// Initialize Firebase Admin SDK
if (!getApps().length) {
  const serviceAccount = {
    projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
    privateKey: process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
  };

  if (!serviceAccount.projectId || !serviceAccount.privateKey || !serviceAccount.clientEmail) {
    console.warn('Firebase Admin SDK credentials not found in environment variables');
  } else {
    initializeApp({
      credential: cert(serviceAccount),
    });
  }
}

interface GroupUpdateData {
  name?: string;
  nameAr?: string;
  description?: string;
  descriptionAr?: string;
  isActive?: boolean;
}

// GET specific group
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
): Promise<NextResponse> {
  try {
    const { id } = params;

    // Check if Firebase Admin is initialized
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const firestore = getFirestore();

    // Get the group
    const groupDoc = await firestore.collection('usersMessagingGroups').doc(id).get();
    
    if (!groupDoc.exists) {
      return NextResponse.json(
        { error: 'Group not found' },
        { status: 404 }
      );
    }

    const group = {
      id: groupDoc.id,
      ...groupDoc.data(),
    };

    return NextResponse.json({
      success: true,
      group,
    });

  } catch (error: any) {
    console.error('Error fetching group:', error);
    
    return NextResponse.json(
      { error: `Failed to fetch group: ${error.message}` },
      { status: 500 }
    );
  }
}

// PUT update group
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
): Promise<NextResponse> {
  try {
    const { id } = params;
    const body = await request.json();
    const { name, nameAr, description = '', descriptionAr = '', isActive }: GroupUpdateData = body;

    // Validate required fields
    if (!name || !nameAr) {
      return NextResponse.json(
        { error: 'Name (English) and Name (Arabic) are required' },
        { status: 400 }
      );
    }

    // Check if Firebase Admin is initialized
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const firestore = getFirestore();

    // Check if group exists
    const groupDoc = await firestore.collection('usersMessagingGroups').doc(id).get();
    
    if (!groupDoc.exists) {
      return NextResponse.json(
        { error: 'Group not found' },
        { status: 404 }
      );
    }

    // Update group data
    const updateData = {
      name,
      nameAr,
      description,
      descriptionAr,
      updatedAt: new Date(),
      ...(typeof isActive === 'boolean' && { isActive }),
    };

    await groupDoc.ref.update(updateData);

    // Get updated group data
    const updatedDoc = await groupDoc.ref.get();
    const updatedGroup = {
      id: updatedDoc.id,
      ...updatedDoc.data(),
    };

    console.log('Group updated successfully:', {
      id,
      name,
      nameAr,
    });

    return NextResponse.json({
      success: true,
      message: 'Group updated successfully',
      group: updatedGroup,
    });

  } catch (error: any) {
    console.error('Error updating group:', error);
    
    return NextResponse.json(
      { error: `Failed to update group: ${error.message}` },
      { status: 500 }
    );
  }
}

// DELETE group
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
): Promise<NextResponse> {
  try {
    const { id } = params;

    // Check if Firebase Admin is initialized
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const firestore = getFirestore();

    // Check if group exists
    const groupDoc = await firestore.collection('usersMessagingGroups').doc(id).get();
    
    if (!groupDoc.exists) {
      return NextResponse.json(
        { error: 'Group not found' },
        { status: 404 }
      );
    }

    const groupData = groupDoc.data();

    // TODO: Consider unsubscribing all users from the FCM topic before deletion
    // This would require getting all user memberships and calling Firebase messaging API
    // For now, we'll just delete the group document

    // Delete all user memberships for this group
    const userMembershipsQuery = await firestore
      .collection('userGroupMemberships')
      .where('groups', 'array-contains-any', [{ groupId: id }])
      .get();

    const batch = firestore.batch();

    // Update each user's membership document to remove this group
    userMembershipsQuery.docs.forEach(doc => {
      const userData = doc.data();
      const updatedGroups = userData.groups.filter((g: any) => g.groupId !== id);
      
      batch.update(doc.ref, {
        groups: updatedGroups,
        updatedAt: new Date(),
      });
    });

    // Delete the group document
    batch.delete(groupDoc.ref);

    // Execute batch operations
    await batch.commit();

    console.log('Group deleted successfully:', {
      id,
      topicId: groupData?.topicId,
      memberCount: groupData?.memberCount,
    });

    return NextResponse.json({
      success: true,
      message: 'Group deleted successfully',
      deletedGroup: {
        id,
        name: groupData?.name,
        topicId: groupData?.topicId,
      },
    });

  } catch (error: any) {
    console.error('Error deleting group:', error);
    
    return NextResponse.json(
      { error: `Failed to delete group: ${error.message}` },
      { status: 500 }
    );
  }
} 