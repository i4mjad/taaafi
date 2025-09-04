'use client';

import { useState, useEffect } from 'react';
import { useCollection, useDocument } from 'react-firebase-hooks/firestore';
import { collection, query, where, doc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/auth/AuthProvider';
import { Group } from '@/types/community';

export interface GroupMembership {
  id: string;
  groupId: string;
  cpId: string;
  role: 'admin' | 'member';
  isActive: boolean;
  joinedAt: Date;
  leftAt?: Date;
  pointsTotal: number;
}

export const useGroupAdmin = (groupId: string) => {
  const { user } = useAuth();
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  // Get current user's community profile ID (assuming it matches user.uid for now)
  const cpId = user?.uid;

  // Query user's membership in this group
  const [membershipSnapshot, membershipLoading, membershipError] = useCollection(
    cpId ? query(
      collection(db, 'group_memberships'),
      where('groupId', '==', groupId),
      where('cpId', '==', cpId),
      where('isActive', '==', true)
    ) : undefined
  );

  useEffect(() => {
    if (membershipLoading) {
      setLoading(true);
      return;
    }

    if (membershipError) {
      console.error('Error checking admin status:', membershipError);
      setIsAdmin(false);
      setLoading(false);
      return;
    }

    if (!membershipSnapshot || membershipSnapshot.empty) {
      setIsAdmin(false);
      setLoading(false);
      return;
    }

    // Check if user has admin role
    const membership = membershipSnapshot.docs[0];
    const membershipData = membership.data() as GroupMembership;
    setIsAdmin(membershipData.role === 'admin');
    setLoading(false);
  }, [membershipSnapshot, membershipLoading, membershipError]);

  return { isAdmin, loading, error: membershipError };
};

export const useGroupMembers = (groupId: string) => {
  const [membersSnapshot, loading, error] = useCollection(
    query(
      collection(db, 'group_memberships'),
      where('groupId', '==', groupId),
      where('isActive', '==', true)
    )
  );

  const members = membersSnapshot?.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
    joinedAt: doc.data().joinedAt?.toDate() || new Date(),
    leftAt: doc.data().leftAt?.toDate(),
  })) as GroupMembership[] || [];

  return { members, loading, error };
};

export const useGroup = (groupId: string) => {
  const [groupSnapshot, loading, error] = useDocument(doc(db, 'groups', groupId));

  const group: Group | null = groupSnapshot?.exists() ? {
    id: groupSnapshot.id,
    ...groupSnapshot.data(),
    createdAt: groupSnapshot.data()?.createdAt?.toDate() || new Date(),
    updatedAt: groupSnapshot.data()?.updatedAt?.toDate(),
  } as Group : null;

  return { group, loading, error };
};
