import { Injectable } from '@angular/core';
import { AngularFireAuth } from '@angular/fire/compat/auth';
import { AngularFirestore } from '@angular/fire/compat/firestore';
import { Router } from '@angular/router';
import firebase from 'firebase/compat/app';
import { from, Observable, of, switchMap } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';
import { User } from '../models/auth.model';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  constructor(
    private afAuth: AngularFireAuth,
    private firestore: AngularFirestore,
    private router: Router
  ) {
    // Subscribe to auth state changes and handle automatic redirection
    this.afAuth.authState
      .pipe(
        tap((user) => {
          if (user) {
            this.checkUserRole(user.uid).subscribe();
          }
        })
      )
      .subscribe();
  }

  googleSignIn() {
    const provider = new firebase.auth.GoogleAuthProvider();
    return from(this.afAuth.signInWithPopup(provider)).pipe(
      switchMap((result: firebase.auth.UserCredential) => {
        if (result.user) {
          return this.checkAdminRole(result.user.uid);
        } else {
          console.error('No user data available');
          return of(false);
        }
      }),
      catchError((error) => {
        console.error('Authentication failed:', error);
        return of(null);
      })
    );
  }
  checkAdminRole(userId: string): Observable<boolean> {
    return this.firestore
      .doc<any>(`users/${userId}`)
      .valueChanges()
      .pipe(
        map((user) => user && user.role === 'admin'),
        catchError((err) => {
          console.error('Error fetching user data:', err);
          return of(false);
        })
      );
  }

  logout() {
    return from(this.afAuth.signOut()).pipe(
      tap(() => {
        this.router.navigate(['/']);
        localStorage.clear(); // Clearing local storage on logout
      }),
      catchError((error) => {
        console.error('Logout failed:', error);
        return of(null);
      })
    );
  }

  checkUserRole(userId: string) {
    console.log("this is called");

    return this.firestore
      .doc<User>(`users/${userId}`)
      .valueChanges()
      .pipe(
        tap((user) => {
          if (user && user.role === 'admin') {
            // this.router.navigate(['/dashboard']);
          } else {
            this.handleAccessDenied();
          }
        }),
        catchError((err) => {
          console.error('Error fetching user data:', err);
          return of(null);
        })
      );
  }

  isAdmin(userId: string) {
    return this.firestore
      .doc<User>(`users/${userId}`)
      .valueChanges()
      .pipe(
        map((user) => user && user.role === 'admin'),
        catchError((err) => {
          console.error('Error checking admin status:', err);
          return of(false);
        })
      );
  }

  private handleAccessDenied() {
    this.router.navigate(['/forbidden-access']);
    this.logout();
    console.warn('Access denied: Only admins can proceed.');
  }
  streamAuthState(): Observable<firebase.User | null> {
    return this.afAuth.authState;
  }
}
