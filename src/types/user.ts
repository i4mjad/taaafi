import { UserRole } from './auth';

export interface UserProfile {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  role: UserRole;
  status: 'active' | 'inactive' | 'suspended'; // Note: Ban strategy not yet implemented
  createdAt: Date;
  updatedAt: Date;
  lastLoginAt?: Date;
  metadata: {
    loginCount: number;
    lastIpAddress?: string;
    userAgent?: string;
  };
}

export interface CreateUserRequest {
  email: string;
  displayName?: string;
  role: UserRole;
  sendInvitation?: boolean;
}

export interface UpdateUserRequest {
  displayName?: string;
  role?: UserRole;
  status?: 'active' | 'inactive' | 'suspended';
}

export interface UserFilters {
  role?: UserRole;
  status?: 'active' | 'inactive' | 'suspended';
  search?: string;
  dateRange?: {
    from: Date;
    to: Date;
  };
} 