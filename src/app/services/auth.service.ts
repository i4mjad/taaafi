import { Injectable } from '@angular/core';
import {AngularFireAuth} from "@angular/fire/compat/auth";
import { GoogleAuthProvider } from "firebase/auth";




@Injectable({
  providedIn: 'root'
})
export class AuthService {

  constructor(private afAuth: AngularFireAuth) { }

  login(email: string, password: string) {
    this.afAuth.signInWithEmailAndPassword(email, password)
      .then(() => {
        // Login successful
        console.log("Logged in successfully!");
      })
      .catch((error) => {
        // An error occurred
      });


  }

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

  get isAuthenticated(): boolean {
    return this.afAuth.currentUser !== null;
  }
}
