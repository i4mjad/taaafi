import { db } from '@/lib/firebase';
import { doc, getDoc } from 'firebase/firestore';
import { User } from '@/types/auth';

class UserRepository {
  async findById(uid: string): Promise<User | null> {
    try {
      const userSnap = await getDoc(doc(db, 'users', uid));
      if (!userSnap.exists()) return null;
      const data = userSnap.data() as any;

      const user: User = {
        uid,
        email: data.email,
        displayName: data.displayName,
        photoURL: data.photoURL,
        role: data.role,
        createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : new Date(),
        lastLoginAt: data.lastLoginAt?.toDate ? data.lastLoginAt.toDate() : undefined,
        isActive: data.isActive ?? true,
      };
      return user;
    } catch (error) {
      console.error('UserRepository.findById error', error);
      return null;
    }
  }
}

export default new UserRepository(); 