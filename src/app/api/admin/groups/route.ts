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

interface GroupData {
  name: string;
  nameAr: string;
  description?: string;
  descriptionAr?: string;
  topicId: string;
}

export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const body = await request.json();
    const { name, nameAr, description = '', descriptionAr = '', topicId }: GroupData = body;

    // Validate required fields
    if (!name || !nameAr || !topicId) {
      return NextResponse.json(
        { error: 'Name (English), Name (Arabic), and Topic ID are required' },
        { status: 400 }
      );
    }

    // Validate topic ID format
    if (!/^[a-zA-Z0-9_-]+$/.test(topicId)) {
      return NextResponse.json(
        { error: 'Topic ID can only contain letters, numbers, underscores, and hyphens' },
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

    // Check if topic ID already exists
    const existingGroup = await firestore
      .collection('usersMessagingGroups')
      .where('topicId', '==', topicId)
      .get();

    if (!existingGroup.empty) {
      return NextResponse.json(
        { error: 'A group with this Topic ID already exists' },
        { status: 409 }
      );
    }

    // Create new group
    const groupData = {
      name,
      nameAr,
      description,
      descriptionAr,
      topicId,
      createdAt: new Date(),
      updatedAt: new Date(),
      isActive: true,
      memberCount: 0, // Initially 0 members
    };

    const docRef = await firestore.collection('usersMessagingGroups').add(groupData);

    const createdGroup = {
      id: docRef.id,
      ...groupData,
    };

    console.log('Messaging group created successfully:', {
      id: docRef.id,
      name,
      topicId,
    });

    return NextResponse.json({
      success: true,
      message: 'Group created successfully',
      group: createdGroup,
    });

  } catch (error: any) {
    console.error('Error creating messaging group:', error);
    
    return NextResponse.json(
      { error: `Failed to create group: ${error.message}` },
      { status: 500 }
    );
  }
}

export async function GET(request: NextRequest): Promise<NextResponse> {
  try {
    // Check if Firebase Admin is initialized
    const apps = getApps();
    if (apps.length === 0) {
      return NextResponse.json(
        { error: 'Firebase Admin SDK not configured. Please check environment variables.' },
        { status: 500 }
      );
    }

    const firestore = getFirestore();

    // Get all groups, ordered by creation date
    const groupsSnapshot = await firestore
      .collection('usersMessagingGroups')
      .orderBy('createdAt', 'desc')
      .get();

    const groups = groupsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));

    return NextResponse.json({
      success: true,
      groups,
      count: groups.length,
    });

  } catch (error: any) {
    console.error('Error fetching messaging groups:', error);
    
    return NextResponse.json(
      { error: `Failed to fetch groups: ${error.message}` },
      { status: 500 }
    );
  }
} 