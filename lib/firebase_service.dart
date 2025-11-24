import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_web_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inicializar Firebase
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Para WEB
      await Firebase.initializeApp(
        options: FirebaseWebConfig.firebaseOptions,
      );
    } else {
      // Para MÓVIL
      await Firebase.initializeApp();
    }
    print('✅ Firebase inicializado para: ${kIsWeb ? 'WEB' : 'MÓVIL'}');
  }

  // Registro de usuario
  static Future<User?> registerUser(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Guardar información adicional en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential.user;
    } catch (e) {
      throw e;
    }
  }

  // Inicio de sesión
  static Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw e;
    }
  }

  // Cerrar sesión
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Obtener usuario actual
  static User? get currentUser => _auth.currentUser;

  // Stream para escuchar cambios de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Guardar mascota en Firestore
  static Future<void> addPet(Map<String, dynamic> petData) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).collection('pets').add({
        ...petData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Obtener mascotas del usuario
  static Stream<QuerySnapshot> getPets() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .snapshots();
    }
    return const Stream.empty();
  }

  // GUARDAR RESERVA - MÉTODO CORREGIDO
  static Future<bool> saveBooking(Map<String, dynamic> bookingData) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('bookings').add({
          ...bookingData,
          'userId': user.uid,
          'userEmail': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Confirmado',
        });
        print('✅ Reserva guardada exitosamente para usuario: ${user.uid}');
        return true;
      } else {
        print('❌ Usuario no autenticado');
        return false;
      }
    } catch (e) {
      print('❌ Error guardando reserva: $e');
      return false;
    }
  }

  // OBTENER RESERVAS DEL USUARIO - MÉTODO CORREGIDO
  static Stream<QuerySnapshot> getUserBookings() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return _firestore
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots();
      }
      print('⚠️ Usuario no autenticado, retornando stream vacío');
      return const Stream.empty();
    } catch (e) {
      print('❌ Error en getUserBookings: $e');
      return const Stream.empty();
    }
  }

  // Obtener información del usuario
  static Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }
  
}