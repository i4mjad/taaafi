import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: "AIzaSyDTqyzIxVboEDvW3g5S_zCnGK0smR-jqg8",
  authDomain: "rebootapp-37a30.firebaseapp.com",
  databaseURL: "https://rebootapp-37a30.firebaseio.com",
  projectId: "rebootapp-37a30",
  storageBucket: "rebootapp-37a30.appspot.com",
  messagingSenderId: "364568176835",
  appId: "1:364568176835:web:169cbadb6e2a85ffe31a76",
  measurementId: "G-E3PBLR6YFF"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const firestore = db; // Alternative export name for consistency 