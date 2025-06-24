import { UserProfile, CreateUserRequest, UpdateUserRequest, UserFilters } from '@/types/user';

export interface IUserRepository {
  // Create operations
  create(userData: CreateUserRequest): Promise<UserProfile>;
  
  // Read operations
  findById(uid: string): Promise<UserProfile | null>;
  findByEmail(email: string): Promise<UserProfile | null>;
  findAll(filters?: UserFilters): Promise<UserProfile[]>;
  findByRole(role: string): Promise<UserProfile[]>;
  
  // Update operations
  update(uid: string, userData: UpdateUserRequest): Promise<UserProfile>;
  updateStatus(uid: string, status: 'active' | 'inactive' | 'suspended'): Promise<void>;
  updateLastLogin(uid: string): Promise<void>;
  
  // Delete operations
  delete(uid: string): Promise<void>;
  softDelete(uid: string): Promise<void>;
  
  // Utility operations
  count(filters?: UserFilters): Promise<number>;
  exists(uid: string): Promise<boolean>;
  search(query: string): Promise<UserProfile[]>;
} 