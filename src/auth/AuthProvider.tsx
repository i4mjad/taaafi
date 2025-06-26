'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { AuthContextType, User, UserRole } from '@/types/auth';
import AuthService from '@/services/AuthService';
import UserRepository from '@/repositories/UserRepository';
import { auth } from '@/lib/firebase';
import { useAuthState } from 'react-firebase-hooks/auth';
import { User as FirebaseUser } from 'firebase/auth';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: React.ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  const [firebaseUser, firebaseLoading] = useAuthState(auth);

  // Convert firebase user -> app user
  const convertUser = async (firebaseUser: FirebaseUser | null) => {
    if (!firebaseUser) {
      setUser(null);
      return;
    }

    try {
      const profile = await UserRepository.findById(firebaseUser.uid);

      if (profile) {
        setUser(profile);
      } else {
        setUser(null);
      }
    } catch (error) {
      console.error('AuthProvider: unable to fetch user profile', error);
      setUser(null);
    }
  };

  // Subscribe to auth changes
  useEffect(() => {
    if (firebaseLoading) return;

    (async () => {
      await convertUser(firebaseUser as FirebaseUser | null);
      setLoading(false);
    })();
  }, [firebaseUser, firebaseLoading]);

  // Exposed actions
  const signInWithEmail = async (email: string, password: string) => {
    setLoading(true);
    try {
      const u = await AuthService.signInWithEmail(email, password);
      setUser(u);
    } finally {
      setLoading(false);
    }
  };

  const signInWithGoogle = async () => {
    setLoading(true);
    try {
      const u = await AuthService.signInWithGoogle();
      setUser(u);
    } finally {
      setLoading(false);
    }
  };

  const signInWithApple = async () => {
    setLoading(true);
    try {
      const u = await AuthService.signInWithApple();
      setUser(u);
    } finally {
      setLoading(false);
    }
  };

  const signOut = async () => {
    setLoading(true);
    try {
      await AuthService.signOut();
      setUser(null);
    } finally {
      setLoading(false);
    }
  };

  const hasRole = (roles: UserRole[]) => (user ? roles.includes(user.role) : false);

  const value: AuthContextType = {
    user,
    loading,
    signInWithEmail,
    signInWithGoogle,
    signInWithApple,
    signOut,
    hasRole,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
} 