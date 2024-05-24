import { Injectable } from '@angular/core';
import {AngularFireAuth} from "@angular/fire/compat/auth";
import { GoogleAuthProvider } from "firebase/auth";
import {first} from "rxjs";
import {Router} from "@angular/router";

@Injectable({
  providedIn: 'root'
})
export class AuthService {



  constructor(private afAuth: AngularFireAuth, private router: Router) {

  }

  //TODO: uncomment this after implementing the auth with email
  // login(email: string, password: string) {
  //   this.afAuth.signInWithEmailAndPassword(email, password)
  //     .then(() => {
  //       // Login successful
  //       console.log("Logged in successfully!");
  //     })
  //     .catch((error) => {
  //       // An error occurred
  //     });
  // }

  loginWithGoogle() {
    this.afAuth.signInWithPopup(new GoogleAuthProvider())
      .then(googleResponse => {
        // Successfully logged in
        console.log(googleResponse);
        // Add your logic here

      }).catch(err => {
      // Login error
      console.log(err);
    });
  }

  async logout() {
    await this.afAuth.signOut();
    this.router.navigate(['/login']);
    localStorage.clear(); // Clearing local storage on logout
  }

  async isAdmin(): Promise<boolean> {
    const user = await this.afAuth.authState.pipe(first()).toPromise();
    if (user) {
      const tokenResult = await user.getIdTokenResult();
      return tokenResult.claims['role'] === 'admin';
    }
    return false;
  }

  // get isAuthenticated(): boolean {
  //   return this.afAuth.currentUser !== null;
  // }
}
