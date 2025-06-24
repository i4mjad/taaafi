'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, AuthContextType, UserRole, SessionTimeout } from '@/types/auth';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minutes in milliseconds

interface AuthProviderProps {
  children: React.ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [sessionTimeout, setSessionTimeout] = useState<SessionTimeout>({
    lastActivity: Date.now(),
    timeoutDuration: SESSION_TIMEOUT,
  });

  // Session timeout handler
  useEffect(() => {
    const checkSession = () => {
      const now = Date.now();
      const timeSinceLastActivity = now - sessionTimeout.lastActivity;

      if (timeSinceLastActivity > sessionTimeout.timeoutDuration && user) {
        handleSignOut();
      }
    };

    const interval = setInterval(checkSession, 60000); // Check every minute
    
    // Update last activity on user interaction
    const updateActivity = () => {
      setSessionTimeout(prev => ({ ...prev, lastActivity: Date.now() }));
    };

    const events = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'];
    events.forEach(event => {
      document.addEventListener(event, updateActivity, true);
    });

    return () => {
      clearInterval(interval);
      events.forEach(event => {
        document.removeEventListener(event, updateActivity, true);
      });
    };
  }, [sessionTimeout, user]);

  // Initialize auth state
  useEffect(() => {
    // Simulate Firebase auth check
    // In a real implementation, this would be:
    // const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => { ... });
    
    const initializeAuth = async () => {
      try {
        // Check if there's a stored user session (for development)
        const storedUser = localStorage.getItem('ta3afi_dev_user');
        if (storedUser) {
          const userData = JSON.parse(storedUser);
          setUser(userData);
        }
      } catch (error) {
        console.error('Error initializing auth:', error);
      } finally {
        setLoading(false);
      }
    };

    initializeAuth();
  }, []);

  const signInWithEmail = async (email: string, password: string): Promise<void> => {
    try {
      setLoading(true);
      
      // TODO: Replace with actual Firebase authentication
      // const { signInWithEmailAndPassword } = await import('firebase/auth');
      // const userCredential = await signInWithEmailAndPassword(auth, email, password);
      
      // For development, simulate successful login for admin users
      if (email.includes('admin') || email.includes('moderator')) {
        const mockUser: User = {
          uid: `dev_${Date.now()}`,
          email: email,
          displayName: email.split('@')[0],
          role: email.includes('admin') ? 'admin' : 'moderator',
          createdAt: new Date(),
          isActive: true,
        };
        
        // Store in localStorage for development
        localStorage.setItem('ta3afi_dev_user', JSON.stringify(mockUser));
        setUser(mockUser);
        setSessionTimeout(prev => ({ ...prev, lastActivity: Date.now() }));
      } else {
        throw new Error('Access denied: insufficient permissions');
      }
    } catch (error) {
      console.error('Error signing in:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const signInWithGoogle = async (): Promise<void> => {
    try {
      setLoading(true);
      
      // TODO: Implement Firebase Google sign in
      // const { GoogleAuthProvider, signInWithPopup } = await import('firebase/auth');
      // const provider = new GoogleAuthProvider();
      // await signInWithPopup(auth, provider);
      
      // For development, simulate Google sign in
      const mockUser: User = {
        uid: `google_dev_${Date.now()}`,
        email: 'admin@taafi.platform',
        displayName: 'Google Admin',
        role: 'admin',
        createdAt: new Date(),
        isActive: true,
      };
      
      localStorage.setItem('ta3afi_dev_user', JSON.stringify(mockUser));
      setUser(mockUser);
      setSessionTimeout(prev => ({ ...prev, lastActivity: Date.now() }));
    } catch (error) {
      console.error('Error signing in with Google:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const signInWithApple = async (): Promise<void> => {
    try {
      setLoading(true);
      
      // TODO: Implement Firebase Apple sign in
      // const { OAuthProvider, signInWithPopup } = await import('firebase/auth');
      // const provider = new OAuthProvider('apple.com');
      // await signInWithPopup(auth, provider);
      
      // For development, simulate Apple sign in
      const mockUser: User = {
        uid: `apple_dev_${Date.now()}`,
        email: 'admin@taafi.platform',
        displayName: 'Apple Admin',
        role: 'admin',
        createdAt: new Date(),
        isActive: true,
      };
      
      localStorage.setItem('ta3afi_dev_user', JSON.stringify(mockUser));
      setUser(mockUser);
      setSessionTimeout(prev => ({ ...prev, lastActivity: Date.now() }));
    } catch (error) {
      console.error('Error signing in with Apple:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const handleSignOut = async (): Promise<void> => {
    try {
      // TODO: Replace with Firebase sign out
      // await firebaseSignOut(auth);
      
      // For development, clear localStorage
      localStorage.removeItem('ta3afi_dev_user');
      setUser(null);
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const hasRole = (roles: UserRole[]): boolean => {
    return user ? roles.includes(user.role) : false;
  };

  const value: AuthContextType = {
    user,
    loading,
    signInWithEmail,
    signInWithGoogle,
    signInWithApple,
    signOut: handleSignOut,
    hasRole,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
} 