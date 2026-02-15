
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDPwjeJa0WvPGPETHap7cBywuXFx1CZVXk",
    authDomain: "budget-tracker-46865.firebaseapp.com",
    projectId: "budget-tracker-46865",
    storageBucket: "budget-tracker-46865.firebasestorage.app",
    messagingSenderId: "1081457953835",
    appId: "1:1081457953835:web:429fe1611a2abd168aee6e",
    measurementId: "G-HVVZW9BNL2"
  );
}