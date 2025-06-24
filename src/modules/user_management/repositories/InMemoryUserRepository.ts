import { IUserRepository } from './IUserRepository';
import { UserProfile, CreateUserRequest, UpdateUserRequest, UserFilters } from '@/types/user';

// Mock users data - moved inline to avoid import issues
const mockUsers: UserProfile[] = [
  {
    uid: 'admin_1',
    email: 'admin@taafi.platform',
    displayName: 'Ahmad Al-Admin',
    role: 'admin',
    status: 'active',
    createdAt: new Date('2024-01-15T10:00:00Z'),
    updatedAt: new Date('2024-01-20T14:30:00Z'),
    lastLoginAt: new Date('2024-01-20T14:30:00Z'),
    metadata: {
      loginCount: 25,
      lastIpAddress: '192.168.1.100',
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
    },
  },
  // Add other mock users here...
];

export class InMemoryUserRepository implements IUserRepository {
  private users: UserProfile[] = [...mockUsers];

  async create(userData: CreateUserRequest): Promise<UserProfile> {
    const newUser: UserProfile = {
      uid: `user_${Date.now()}`,
      email: userData.email,
      displayName: userData.displayName,
      role: userData.role,
      status: 'active',
      createdAt: new Date(),
      updatedAt: new Date(),
      metadata: {
        loginCount: 0,
      },
    };

    this.users.push(newUser);
    return newUser;
  }

  async findById(uid: string): Promise<UserProfile | null> {
    return this.users.find(user => user.uid === uid) || null;
  }

  async findByEmail(email: string): Promise<UserProfile | null> {
    return this.users.find(user => user.email === email) || null;
  }

  async findAll(filters?: UserFilters): Promise<UserProfile[]> {
    let filteredUsers = [...this.users];

    if (filters?.role) {
      filteredUsers = filteredUsers.filter(user => user.role === filters.role);
    }

    if (filters?.status) {
      filteredUsers = filteredUsers.filter(user => user.status === filters.status);
    }

    if (filters?.search) {
      const searchLower = filters.search.toLowerCase();
      filteredUsers = filteredUsers.filter(user =>
        user.email.toLowerCase().includes(searchLower) ||
        user.displayName?.toLowerCase().includes(searchLower)
      );
    }

    if (filters?.dateRange) {
      filteredUsers = filteredUsers.filter(user =>
        user.createdAt >= filters.dateRange!.from &&
        user.createdAt <= filters.dateRange!.to
      );
    }

    return filteredUsers;
  }

  async findByRole(role: string): Promise<UserProfile[]> {
    return this.users.filter(user => user.role === role);
  }

  async update(uid: string, userData: UpdateUserRequest): Promise<UserProfile> {
    const userIndex = this.users.findIndex(user => user.uid === uid);
    if (userIndex === -1) {
      throw new Error('User not found');
    }

    this.users[userIndex] = {
      ...this.users[userIndex],
      ...userData,
      updatedAt: new Date(),
    };

    return this.users[userIndex];
  }

  async updateStatus(uid: string, status: 'active' | 'inactive' | 'suspended'): Promise<void> {
    const user = await this.findById(uid);
    if (!user) {
      throw new Error('User not found');
    }

    await this.update(uid, { status });
  }

  async updateLastLogin(uid: string): Promise<void> {
    const userIndex = this.users.findIndex(user => user.uid === uid);
    if (userIndex !== -1) {
      this.users[userIndex].lastLoginAt = new Date();
      this.users[userIndex].metadata.loginCount += 1;
      this.users[userIndex].updatedAt = new Date();
    }
  }

  async delete(uid: string): Promise<void> {
    const userIndex = this.users.findIndex(user => user.uid === uid);
    if (userIndex !== -1) {
      this.users.splice(userIndex, 1);
    }
  }

  async softDelete(uid: string): Promise<void> {
    await this.updateStatus(uid, 'inactive');
  }

  async count(filters?: UserFilters): Promise<number> {
    const users = await this.findAll(filters);
    return users.length;
  }

  async exists(uid: string): Promise<boolean> {
    return this.users.some(user => user.uid === uid);
  }

  async search(query: string): Promise<UserProfile[]> {
    return this.findAll({ search: query });
  }
} 