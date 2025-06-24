import { auth } from '@/lib/firebase';
import { signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider, OAuthProvider, UserCredential, signOut as firebaseSignOut, User as FirebaseUser } from 'firebase/auth';
import UserRepository from '@/repositories/UserRepository';
import { User } from '@/types/auth';

class AuthService {
  // Sign in with email & password
  async signInWithEmail(email: string, password: string): Promise<User> {
    const credential: UserCredential = await signInWithEmailAndPassword(auth, email, password);
    // Fetch additional user data (role, etc.)
    const user = await this._buildUser(credential.user);
    return user;
  }

  // Sign in with Google
  async signInWithGoogle(): Promise<User> {
    const provider = new GoogleAuthProvider();
    const credential: UserCredential = await signInWithPopup(auth, provider);
    const user = await this._buildUser(credential.user);
    return user;
  }

  // Sign in with Apple (OAuth)
  async signInWithApple(): Promise<User> {
    const provider = new OAuthProvider('apple.com');
    const credential: UserCredential = await signInWithPopup(auth, provider);
    const user = await this._buildUser(credential.user);
    return user;
  }

  // Sign out current user
  async signOut(): Promise<void> {
    await firebaseSignOut(auth);
  }

  // Build extended User object by merging Firebase user with Firestore profile
  private async _buildUser(firebaseUser: FirebaseUser): Promise<User> {
    // Fetch profile from repository
    const profile = await UserRepository.findById(firebaseUser.uid);

    if (!profile) {
      // If no profile document found, treat as unauthorised
      throw new Error('User profile not found or lacks required permissions');
    }

    return {
      uid: firebaseUser.uid,
      email: firebaseUser.email || profile.email,
      displayName: firebaseUser.displayName || profile.displayName,
      photoURL: firebaseUser.photoURL || profile.photoURL,
      role: profile.role,
      createdAt: profile.createdAt,
      lastLoginAt: profile.lastLoginAt,
      isActive: profile.isActive,
    };
  }
}

export default new AuthService(); 