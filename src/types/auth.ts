export type UserRole = 'admin' | 'moderator' | 'user';

export interface User {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  role: UserRole;
  createdAt: Date;
  lastLoginAt?: Date;
  isActive: boolean;
}

export interface AuthContextType {
  user: User | null;
  loading: boolean;
  signInWithEmail: (email: string, password: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  signInWithApple: () => Promise<void>;
  signOut: () => Promise<void>;
  hasRole: (roles: UserRole[]) => boolean;
}

export interface SessionTimeout {
  lastActivity: number;
  timeoutDuration: number; // in milliseconds
} 