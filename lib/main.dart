import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 =================================');
  print('🚀 --------- APP INICIADA ----------');
  print('🚀 =================================');
  
  await FirebaseService.initialize();
  runApp(const WoofToGoApp());
}

// CLASE GLOBAL PARA GESTIONAR EL CARRITO
class CartManager {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Map<String, dynamic>> _items = [];
  
  List<Map<String, dynamic>> get items => _items;
  
  int get itemCount => _items.length;
  
  double get total {
    return _items.fold(0.0, (sum, item) {
      final price = double.parse(item['price'].toString().replaceAll('\$', '').replaceAll(',', ''));
      final quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }
  
  void addItem(Map<String, dynamic> product) {
    final existingIndex = _items.indexWhere((item) => item['name'] == product['name']);
    
    if (existingIndex >= 0) {
      _items[existingIndex]['quantity'] = (_items[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      _items.add({...product, 'quantity': 1});
    }
  }
  
  void removeItem(int index) {
    _items.removeAt(index);
  }
  
  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
    } else {
      _items[index]['quantity'] = quantity;
    }
  }
  
  void clear() {
    _items.clear();
  }
}

class WoofToGoApp extends StatefulWidget {
  const WoofToGoApp({Key? key}) : super(key: key);

  @override
  State<WoofToGoApp> createState() => _WoofToGoAppState();
}

class _WoofToGoAppState extends State<WoofToGoApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void setTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Woof to Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[800],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: AuthWrapper(setTheme: setTheme), // PASA LA FUNCIÓN
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Function(ThemeMode) setTheme; // AGREGAR ESTO
  
  const AuthWrapper({Key? key, required this.setTheme}) : super(key: key); // AGREGAR ESTO

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        } else if (snapshot.hasData) {
          return HomePage(setTheme: setTheme); // PASA LA FUNCIÓN
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Woof to Go',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PÁGINA DE LOGIN
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseService.loginUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[50],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://drive.google.com/uc?export=view&id=1eGGxxJJMqabsEhakvQZA0Y0JkcissBYv',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.pets, size: 80, color: Colors.blue[700]);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Woof to Go',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Tu compañero de paseos',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 16)),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Correo de recuperación enviado')),
                    );
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// PÁGINA DE REGISTRO
class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await FirebaseService.registerUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Usuario ${user!.email} creado EXITOSAMENTE'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      String errorMessage = 'Error desconocido';
      
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Este email ya está registrado';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'La contraseña es muy débil (mínimo 6 caracteres)';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Email inválido';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Error de conexión a internet';
      } else {
        errorMessage = e.toString();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=600',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.blue[100],
                          child: const Icon(Icons.pets, size: 80),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Registrarse', style: TextStyle(fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// PÁGINA PRINCIPAL CON NAVEGACIÓN
class HomePage extends StatefulWidget {
  final Function(ThemeMode) setTheme; // AGREGAR ESTO
  
  const HomePage({Key? key, required this.setTheme}) : super(key: key); // AGREGAR ESTO

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = []; // INICIALIZAR VACÍO

  @override
  void initState() {
    super.initState();
    // INICIALIZAR PÁGINAS CON LA FUNCIÓN setTheme
    _pages.addAll([
      const HomeTab(),
      const PetsPage(),
      const MarketplacePage(),
      const BookingsPage(),
      ProfilePage(setTheme: widget.setTheme), // PASA LA FUNCIÓN
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Mascotas'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Tienda'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Reservas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

// TAB DE INICIO
class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Woof to Go'),
        actions: [
          IconButton(
            icon: Icon(
              user != null ? Icons.cloud_done : Icons.cloud_off,
              color: user != null ? Colors.green : Colors.red,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    user != null 
                      ? '✅ Firebase CONECTADO\nUsuario: ${user.email}'
                      : '❌ Firebase DESCONECTADO',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800',
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.blue[200],
                          child: const Center(child: Icon(Icons.pets, size: 60)),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Bienvenido! 👋',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Encuentra el mejor cuidado para tu mascota',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Servicios',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildServiceCard(
              context,
              'Reservar Paseo',
              'Encuentra paseadores cerca de ti',
              Icons.directions_walk,
              Colors.blue,
              'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=200',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalkBookingPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildServiceCard(
              context,
              'Tienda de Mascotas',
              'Alimentos, juguetes y más',
              Icons.store,
              Colors.orange,
              'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=200',
              () {
                final homeState = context.findAncestorStateOfType<_HomePageState>();
                homeState?.setState(() {
                  homeState._selectedIndex = 2;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              '🎉 Promociones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.green[700], size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '20% OFF en tu primer paseo\nCódigo: PRIMERPASEO',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, String imageUrl, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 70,
                      height: 70,
                      color: color.withOpacity(0.2),
                      child: Icon(icon, color: color, size: 32),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// PÁGINA DE MASCOTAS
class PetsPage extends StatefulWidget {
  const PetsPage({Key? key}) : super(key: key);

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  final List<Map<String, dynamic>> _pets = [
    {
      'id': '1',
      'name': 'Rocky',
      'breed': 'Golden Retriever',
      'age': '3 años',
      'size': 'Grande',
      'image': 'https://images.unsplash.com/photo-1633722715463-d30f4f325e24?w=200'
    },
    {
      'id': '2',
      'name': 'Luna',
      'breed': 'Husky',
      'age': '2 años',
      'size': 'Mediano',
      'image': 'https://images.unsplash.com/photo-1568572933382-74d440642117?w=200'
    },
  ];

  void _showAddPetDialog(BuildContext context) {
    final nameController = TextEditingController();
    final breedController = TextEditingController();
    final ageController = TextEditingController();
    String selectedSize = 'Mediano';
    File? selectedImage;
    String? imageUrl;

    final sizes = ['Pequeño', 'Mediano', 'Grande'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 700),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pets, color: Colors.blue[700], size: 28),
                          const SizedBox(width: 8),
                          const Text(
                            'Agregar Mascota',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 800,
                              maxHeight: 800,
                              imageQuality: 85,
                            );

                            if (pickedFile != null) {
                              setDialogState(() {
                                selectedImage = File(pickedFile.path);
                                imageUrl = pickedFile.path;
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue[50],
                                  border: Border.all(
                                    color: Colors.blue[300]!,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: selectedImage != null
                                      ? Image.file(
                                          selectedImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.pets,
                                          size: 60,
                                          color: Colors.blue[300],
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[700],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para agregar foto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de la mascota *',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: breedController,
                        decoration: InputDecoration(
                          labelText: 'Raza *',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: ageController,
                        decoration: InputDecoration(
                          labelText: 'Edad (ej: 2 años)',
                          prefixIcon: const Icon(Icons.cake),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Tamaño *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: DropdownButton<String>(
                          value: selectedSize,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: sizes.map((size) {
                            IconData icon;
                            Color color;
                            
                            switch (size) {
                              case 'Pequeño':
                                icon = Icons.pets;
                                color = Colors.green;
                                break;
                              case 'Mediano':
                                icon = Icons.pets;
                                color = Colors.orange;
                                break;
                              case 'Grande':
                                icon = Icons.pets;
                                color = Colors.red;
                                break;
                              default:
                                icon = Icons.pets;
                                color = Colors.grey;
                            }

                            return DropdownMenuItem(
                              value: size,
                              child: Row(
                                children: [
                                  Icon(icon, color: color, size: 20),
                                  const SizedBox(width: 8),
                                  Text(size),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedSize = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (nameController.text.isEmpty ||
                                    breedController.text.isEmpty ||
                                    ageController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('⚠️ Por favor completa todos los campos obligatorios'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  _pets.add({
                                    'id': DateTime.now().toString(),
                                    'name': nameController.text,
                                    'breed': breedController.text,
                                    'age': ageController.text,
                                    'size': selectedSize,
                                    'image': imageUrl ?? 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=200',
                                    'isLocal': selectedImage != null,
                                    'localPath': selectedImage?.path,
                                  });
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ ${nameController.text} agregado exitosamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Agregar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _deletePet(int index) {
    final petName = _pets[index]['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Eliminar Mascota'),
          ],
        ),
        content: Text('¿Estás seguro de eliminar a $petName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pets.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$petName eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color _getSizeColor(String size) {
    switch (size) {
      case 'Pequeño':
        return Colors.green;
      case 'Mediano':
        return Colors.orange;
      case 'Grande':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSizeIcon(String size) {
    switch (size) {
      case 'Pequeño':
        return Icons.pets;
      case 'Mediano':
        return Icons.pets;
      case 'Grande':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mascotas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _showAddPetDialog(context),
            tooltip: 'Agregar mascota',
          ),
        ],
      ),
      body: _pets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes mascotas registradas',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón + para agregar una',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPetDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Primera Mascota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pets.length,
              itemBuilder: (context, index) {
                final pet = _pets[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getSizeColor(pet['size']),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getSizeColor(pet['size']).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: pet['isLocal'] == true && pet['localPath'] != null
                                ? Image.file(
                                    File(pet['localPath']),
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    pet['image'] ?? 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=200',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.pets,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pet['breed'],
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.cake,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pet['age'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSizeColor(pet['size']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getSizeColor(pet['size']),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getSizeIcon(pet['size']),
                                      size: 14,
                                      color: _getSizeColor(pet['size']),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pet['size'],
                                      style: TextStyle(
                                        color: _getSizeColor(pet['size']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deletePet(index),
                          tooltip: 'Eliminar mascota',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================
// WIDGET PARA MOSTRAR MAPA EN EL PERFIL
// ============================================

class WalkerMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String walkerName;
  final String address;

  const WalkerMapWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.walkerName,
    required this.address,
  }) : super(key: key);

  @override
  State<WalkerMapWidget> createState() => _WalkerMapWidgetState();
}

class _WalkerMapWidgetState extends State<WalkerMapWidget> {
  GoogleMapController? _mapController;
  Position? _userPosition;
  double? _distanceKm;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          widget.latitude,
          widget.longitude,
        );

        setState(() {
          _userPosition = position;
          _distanceKm = distanceInMeters / 1000;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _openInGoogleMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text(
                'Punto de Encuentro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.address,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),

        if (_distanceKm != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.directions_walk, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  'A ${_distanceKm! < 1 ? "${(_distanceKm! * 1000).toStringAsFixed(0)} m" : "${_distanceKm!.toStringAsFixed(1)} km"} de tu ubicación',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        Container(
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('walker'),
                  position: LatLng(widget.latitude, widget.longitude),
                  infoWindow: InfoWindow(
                    title: widget.walkerName,
                    snippet: widget.address,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
                if (_userPosition != null)
                  Marker(
                    markerId: const MarkerId('user'),
                    position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                    infoWindow: const InfoWindow(title: 'Tu ubicación'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  ),
              },
              polylines: _userPosition != null
                  ? {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: [
                          LatLng(_userPosition!.latitude, _userPosition!.longitude),
                          LatLng(widget.latitude, widget.longitude),
                        ],
                        color: Colors.blue,
                        width: 3,
                      ),
                    }
                  : {},
              onMapCreated: (controller) {
                _mapController = controller;
                
                if (_userPosition != null) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    controller.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        LatLngBounds(
                          southwest: LatLng(
                            _userPosition!.latitude < widget.latitude
                                ? _userPosition!.latitude
                                : widget.latitude,
                            _userPosition!.longitude < widget.longitude
                                ? _userPosition!.longitude
                                : widget.longitude,
                          ),
                          northeast: LatLng(
                            _userPosition!.latitude > widget.latitude
                                ? _userPosition!.latitude
                                : widget.latitude,
                            _userPosition!.longitude > widget.longitude
                                ? _userPosition!.longitude
                                : widget.longitude,
                          ),
                        ),
                        100,
                      ),
                    );
                  });
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: _openInGoogleMaps,
            icon: const Icon(Icons.map),
            label: const Text('Abrir en Google Maps'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// PÁGINA DE RESERVA DE PASEOS (ACTUALIZADA)
class WalkBookingPage extends StatefulWidget {
  const WalkBookingPage({Key? key}) : super(key: key);

  @override
  State<WalkBookingPage> createState() => _WalkBookingPageState();
}

class _WalkBookingPageState extends State<WalkBookingPage> {
  DateTime selectedDate = DateTime.now();

  // LISTA COMPLETA DE 20 PASEADORES
  final List<Map<String, dynamic>> walkersHuancayo = [
    {
      'name': 'Carlos Ramírez',
      'rating': 4.8,
      'price': 20.0,
      'experience': '5 años',
      'description': 'Paseador con 5 años de experiencia. Amante de los perros grandes.',
      'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'latitude': -12.0657, // Parque Constitución, Huancayo Centro
      'longitude': -75.2048,
      'address': 'Parque Constitución, Huancayo Centro',
    },
    {
      'name': 'María López',
      'rating': 4.9,
      'price': 25.0,
      'experience': '7 años',
      'description': 'Especialista en cachorros y perros con mucha energía.',
      'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'latitude': -12.0423, // Parque Túpac Amaru, El Tambo
      'longitude': -75.2127,
      'address': 'Parque Túpac Amaru, El Tambo',
    },
      {
    'name': 'Juan Torres',
    'rating': 4.5,
    'price': 18.0,
    'experience': '3 años',
    'description': 'Paseos tranquilos para perros mayores o con movilidad reducida.',
    'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    'latitude': -12.0895, // Plaza Huamanmarca, Chilca
    'longitude': -75.2156,
    'address': 'Plaza Huamanmarca, Chilca',
  },
  {
    'name': 'Ana Gutiérrez',
    'rating': 4.9,
    'price': 28.0,
    'experience': '6 años',
    'description': 'Entrenadora profesional. Especializada en razas grandes y comportamiento.',
    'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    'latitude': -12.0512, // Parque Identidad Wanka
    'longitude': -75.2089,
    'address': 'Parque Identidad Wanka, Huancayo',
  },
  {
    'name': 'Roberto Sánchez',
    'rating': 4.7,
    'price': 22.0,
    'experience': '4 años',
    'description': 'Paseos energéticos y dinámicos. Ideal para perros activos.',
    'image': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
    'latitude': -12.0789, // Parque de la Identidad, San Carlos
    'longitude': -75.1987,
    'address': 'Parque de la Identidad, San Carlos',
  },
  {
    'name': 'Patricia Flores',
    'rating': 5.0,
    'price': 30.0,
    'experience': '8 años',
    'description': 'Veterinaria con experiencia en cuidado especial. Paseos premium.',
    'image': 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200',
    'latitude': -12.0621, // Real Plaza Huancayo
    'longitude': -75.2101,
    'address': 'Zona Real Plaza, Huancayo',
  },
  {
    'name': 'Diego Mendoza',
    'rating': 4.6,
    'price': 19.0,
    'experience': '3 años',
    'description': 'Estudiante de veterinaria. Flexible con horarios y muy paciente.',
    'image': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=200',
    'latitude': -12.0456, // Universidad Continental
    'longitude': -75.1998,
    'address': 'Zona Universidad Continental, El Tambo',
  },
  {
    'name': 'Laura Castillo',
    'rating': 4.8,
    'price': 24.0,
    'experience': '5 años',
    'description': 'Especialista en razas pequeñas y perros ancianos. Muy cuidadosa.',
    'image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
    'latitude': -12.0734, // Av. Ferrocarril
    'longitude': -75.2056,
    'address': 'Av. Ferrocarril, Huancayo',
  },
  {
    'name': 'Fernando Rojas',
    'rating': 4.4,
    'price': 17.0,
    'experience': '2 años',
    'description': 'Paseador principiante con mucho entusiasmo. Tarifas económicas.',
    'image': 'https://images.unsplash.com/photo-1463453091185-61582044d556?w=200',
    'latitude': -12.0923, // Chilca Sur
    'longitude': -75.2234,
    'address': 'Urbanización Los Andes, Chilca',
  },
  {
    'name': 'Sofía Vargas',
    'rating': 4.9,
    'price': 26.0,
    'experience': '6 años',
    'description': 'Entrenadora certificada. Manejo de múltiples perros simultáneamente.',
    'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    'latitude': -12.0578, // Calle Real
    'longitude': -75.2112,
    'address': 'Calle Real, Centro de Huancayo',
  },
  {
    'name': 'Miguel Herrera',
    'rating': 4.7,
    'price': 21.0,
    'experience': '4 años',
    'description': 'Ex policía canino. Experiencia en seguridad y obediencia.',
    'image': 'https://images.unsplash.com/photo-1503443207922-dff7d543fd0e?w=200',
    'latitude': -12.0389, // San Agustín de Cajas
    'longitude': -75.2178,
    'address': 'San Agustín de Cajas',
  },
  {
    'name': 'Valentina Cruz',
    'rating': 4.8,
    'price': 23.0,
    'experience': '5 años',
    'description': 'Paseos nocturnos disponibles. Perfecta para dueños con horarios complejos.',
    'image': 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=200',
    'latitude': -12.0698, // Plaza Huamanmarca
    'longitude': -75.1989,
    'address': 'Plaza Huamanmarca, Huancayo',
  },
  {
    'name': 'Andrés Morales',
    'rating': 4.5,
    'price': 20.0,
    'experience': '3 años',
    'description': 'Running con perros. Ideal para razas que necesitan mucho ejercicio.',
    'image': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200',
    'latitude': -12.0812, // Parque Lineal, Chilca
    'longitude': -75.2089,
    'address': 'Parque Lineal, Chilca',
  },
  {
    'name': 'Camila Ríos',
    'rating': 5.0,
    'price': 32.0,
    'experience': '9 años',
    'description': 'Experta en comportamiento canino. Rehabilitación de perros rescatados.',
    'image': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
    'latitude': -12.0545, // Av. Giráldez
    'longitude': -75.2134,
    'address': 'Av. Giráldez, Huancayo Centro',
  },
  {
    'name': 'Gabriel Paredes',
    'rating': 4.6,
    'price': 19.0,
    'experience': '3 años',
    'description': 'Servicios de fotografía incluidos. Captura momentos especiales del paseo.',
    'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    'latitude': -12.0467, // Parque Infantil, El Tambo
    'longitude': -75.2045,
    'address': 'Parque Infantil, El Tambo',
  },
  {
    'name': 'Isabella Núñez',
    'rating': 4.9,
    'price': 27.0,
    'experience': '7 años',
    'description': 'Bilingüe (español/inglés). Experiencia con razas exóticas.',
    'image': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200',
    'latitude': -12.0634, // Mercado Mayorista
    'longitude': -75.2167,
    'address': 'Zona Comercial, Huancayo',
  },
  {
    'name': 'Ricardo Vega',
    'rating': 4.4,
    'price': 18.0,
    'experience': '2 años',
    'description': 'Estudiante universitario. Horarios flexibles, fines de semana disponible.',
    'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
    'latitude': -12.0856, // Av. Mariscal Castilla, Chilca
    'longitude': -75.2198,
    'address': 'Av. Mariscal Castilla, Chilca',
  },
  {
    'name': 'Daniela Ortiz',
    'rating': 4.8,
    'price': 25.0,
    'experience': '5 años',
    'description': 'Grooming básico incluido. Revisa salud general durante el paseo.',
    'image': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
    'latitude': -12.0701, // Estadio Huancayo
    'longitude': -75.2023,
    'address': 'Zona Estadio Huancayo',
  },
  {
    'name': 'Javier Campos',
    'rating': 4.7,
    'price': 22.0,
    'experience': '4 años',
    'description': 'Especialista en socialización. Paseos grupales con otros perros.',
    'image': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',
    'latitude': -12.0512, // Parque La Libertad
    'longitude': -75.2156,
    'address': 'Parque La Libertad, El Tambo',
  },
  {
    'name': 'Natalia Romero',
    'rating': 4.9,
    'price': 29.0,
    'experience': '8 años',
    'description': 'Certificada en primeros auxilios caninos. Seguro de responsabilidad incluido.',
    'image': 'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?w=200',
    'latitude': -12.0589, // Torre Torre (zona baja)
    'longitude': -75.1967,
    'address': 'Zona Torre Torre, Huancayo',
  },
  ];

  // MÉTODO PARA MOSTRAR DETALLES DEL PASEADOR Y RESERVAR
  void _showWalkerDetailDialog(BuildContext context, Map<String, dynamic> walker) {
    String selectedPet = 'Rocky';
    String selectedTime = '09:00';
    String selectedDuration = '1 hora';

    final pets = ['Rocky', 'Luna', 'Max', 'Bella'];
    final durations = ['30 minutos', '1 hora', '1.5 horas', '2 horas'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 700),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TÍTULO
                        Row(
                          children: [
                            const Icon(Icons.directions_walk, size: 28, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Perfil del Paseador',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // INFO DEL PASEADOR
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  walker['image'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return CircleAvatar(
                                      radius: 30,
                                      child: Text(walker['name'][0]),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      walker['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        Text(' ${walker['rating']} • S/. ${walker['price'].toStringAsFixed(1)}/h'),
                                      ],
                                    ),
                                    Text(
                                      walker['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // MAPA DE UBICACIÓN
                        WalkerMapWidget(
                          latitude: walker['latitude'],
                          longitude: walker['longitude'],
                          walkerName: walker['name'],
                          address: walker['address'],
                        ),
                        const SizedBox(height: 20),

                        // SELECTOR DE MASCOTA
                        const Text(
                          'Mascota',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: selectedPet,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: pets.map((pet) {
                              return DropdownMenuItem(
                                value: pet,
                                child: Text(pet),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPet = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // SELECTOR DE HORA
                        const Text(
                          'Hora (HH:mm)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: TextEditingController(text: selectedTime),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            selectedTime = value;
                          },
                        ),
                        const SizedBox(height: 16),

                        // SELECTOR DE DURACIÓN
                        const Text(
                          'Duración',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: selectedDuration,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: durations.map((duration) {
                              return DropdownMenuItem(
                                value: duration,
                                child: Text(duration),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDuration = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // BOTONES
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    // Crear datos de la reserva
                                    final bookingData = {
                                      'walkerName': walker['name'],
                                      'walkerImage': walker['image'],
                                      'walkerRating': walker['rating'],
                                      'walkerExperience': walker['experience'],
                                      'walkerPrice': walker['price'],
                                      'walkerAddress': walker['address'],
                                      'petName': selectedPet,
                                      'date': selectedDate.toIso8601String(),
                                      'time': selectedTime,
                                      'duration': selectedDuration,
                                      'totalPrice': _calculateTotalPrice(walker['price'], selectedDuration),
                                    };

                                    // Guardar en Firebase
                                    final success = await FirebaseService.saveBooking(bookingData);

                                    if (success) {
                                      Navigator.pop(context);
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '✅ Paseo reservado con ${walker['name']}\n'
                                            'Mascota: $selectedPet\n'
                                            'Hora: $selectedTime\n'
                                            'Duración: $selectedDuration\n'
                                            'Reserva guardada en tu historial'
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 5),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('❌ Error al guardar la reserva'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('❌ Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 108, 0, 197),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                  minimumSize: const Size.fromHeight(50), // ← Altura mínima fija
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Confirmar Reserva',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // MÉTODO PARA CALCULAR PRECIO TOTAL
  double _calculateTotalPrice(double pricePerHour, String duration) {
    final durationMap = {
      '30 minutos': 0.5,
      '1 hora': 1.0,
      '1.5 horas': 1.5,
      '2 horas': 2.0,
    };
    return pricePerHour * (durationMap[duration] ?? 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservar Paseo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SELECTOR DE FECHA
            const Text(
              'Selecciona la fecha del paseo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Paseadores disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // LISTA DE PASEADORES
            ...walkersHuancayo.map((walker) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        walker['image'],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return CircleAvatar(
                            radius: 35,
                            child: Text(
                              walker['name'][0],
                              style: const TextStyle(fontSize: 24)
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            walker['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(' ${walker['rating']} • ${walker['experience']}'),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'S/. ${walker['price'].toStringAsFixed(1)}/h',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showWalkerDetailDialog(context, walker);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reservar'),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// PÁGINA DEL MARKETPLACE CON CARRITO
class MarketplacePage extends StatefulWidget {
  const MarketplacePage({Key? key}) : super(key: key);

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final CartManager _cartManager = CartManager();

  @override
  Widget build(BuildContext context) {
    final products = [
      // ALIMENTOS
      {
        'name': 'Alimento para Adulto állkjoy',
        'price': '45.00',
        'category': 'Alimento',
        'image': 'https://drive.google.com/uc?export=view&id=1ekZ2BcC8uxZQxPWtDigZ2sr-0nDboagx'
      },
            {
        'name': 'Alimento con verduras y pollo',
        'price': '12.00',
        'category': 'Alimento',
        'image': 'https://drive.google.com/uc?export=view&id=1QArwVWXjfJFPg4Zi02YQR3BWy0lVhScW'
      },
      {
        'name': 'Pedigri para Adulto',
        'price': '28.00',
        'category': 'Alimento',
        'image': 'https://drive.google.com/uc?export=view&id=1ESNljj8LFZN0qywQkt-JqEUyMo9LclNR'
      },
      {
        'name': 'Alimento Cesar para Cachorros',
        'price': '28.00',
        'category': 'Alimento',
        'image': 'https://drive.google.com/uc?export=view&id=1Uqcwm5585gpwx2WBw1U_NvSbY_4OArJd'
      },
      {
        'name': 'Comida Húmeda para Cachorros',
        'price': '28.00',
        'category': 'Alimento',
        'image': 'https://drive.google.com/uc?export=view&id=1kbXXnaM9yBLO07mV1yi-i300vgYA74C8'
      },
      {
        'name': 'Purina MOIST & MEATY',
        'price': '28.00',
        'category': 'Alimento',
        'image': 'https://drive.google.com/uc?export=view&id=1-bA1NOYsXOfXX_muRVhj37bJB_jEY0xn'
      },
      {
        'name': 'Mio Cane adulto para razas Pequeñas',
        'price': '28.00',
        'category': 'Alimento',
        'image': 'https://drive.google.com/uc?export=view&id=1Lx33mukHrN8XRQu6IaX7UHtI5FILC0Di'
      },
      {
        'name': 'Purina Pro Plan para Adultos',
        'price': '28.00',
        'category': 'Alimento',
        'image': 'https://drive.google.com/uc?export=view&id=1pdO9O4EDmPhSrvXrR8WXGK8fZUiyUFFE'
      },
      {
        'name': 'Snacks de pechuga de pollo',
        'price': '28.00',
        'category': 'Alimento',
        'image': 'https://drive.google.com/uc?export=view&id=1VYXBjzcQNnaVhvAu3u4EMQC_a5tzNXPj'
      },
      // JUGUETES
      {
        'name': 'Pelota Interactiva con Luces',
        'price': '40.00',
        'category': 'Juguete',
        'image': 'https://drive.google.com/uc?export=view&id=1z9GyszQd40g5Vs1Jx9-Ju739EmjDsF1I'
      },
      {
        'name': 'Pelota interacctiva de goma con Sonido',
        'price': '30.00',
        'category': 'Juguete',
        'image': 'https://drive.google.com/uc?export=view&id=1Rqp01pF6cFk6037Mq9D4nCrHkizbbKNV'
      },
      {
        'name': 'Soga con mordedera para perros',
        'price': '20.00',
        'category': 'Juguete',
        'image': 'https://drive.google.com/uc?export=view&id=17lvr-i8z3BoUBC16IusFd7JiFZzzk0SD'
      },
      {
        'name': 'Soga corta con mordedera para perros',
        'price': '15.00',
        'category': 'Juguete',
        'image': 'https://drive.google.com/uc?export=view&id=10sSDsPGT7B2gnAcRgAEBXy67B3EIG2Ko'
      },
      {
        'name': 'Peluche con diseño de perro',
        'price': '20.00',
        'category': 'Juguete',
        'image': 'https://drive.google.com/uc?export=view&id=1zlz_I_1-ohCjWB76V_FAc8M7ZX26vf3T'
      },
      {
        'name': 'Pollo de hule para perros',
        'price': '15.00',
        'category': 'Juguete',
        'image': 'https://drive.google.com/uc?export=view&id=1DASMrqXdEYIlToa_Ci2Hhm3ZIB1n2C-o'
      },
      {
        'name': 'Hueso de carne seca comestible',
        'price': '30.00',
        'category': 'Juguete',
        'image': 'https://drive.google.com/uc?export=view&id=10M74u9rcHY9W8_aVBWRsq6KchVtZzTM7'
      },
      {
        'name': 'Mordedero con diseño de zanahoria',
        'price': '15.00',
        'category': 'Juguete',
        'image': 'https://drive.google.com/uc?export=view&id=1VhnAF26AnOD4AHiz0SjUYSBtkiEz8vJi'
      },
      {
        'name': 'Juguete con forma de hueso',
        'price': '10.00',
        'category': 'Juguete',
        'image': 'https://drive.google.com/uc?export=view&id=1XUUSx9-_pNSKyGD_lzeOhpoJu8RQlOhr'
      },
      // ACCESORIOS
      {
        'name': 'Arnes Ajustable',
        'price': '20.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1Y0l5EtcHk5BEGbja89OqwRIMQi5pv2ve'
      },
      {
        'name': 'Arnes para perro Adulto',
        'price': '25.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1M7qvObkYJ7XFaYTjkBD1L1gnuO3nRxoT'
      },
      {
        'name': 'Arnés de Paseo Ajustable',
        'price': '20.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1qTQTUX5ptGKy47uHuE7BidOWmsgYwoCX'
      },
      {
        'name': 'Casa para Perro Exterior',
        'price': '120.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=15n4pvnnSoXSArj75ce3HeQsef6YVzq8F'
      },
      {
        'name': 'Correa Reflectante',
        'price': '30.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=18KYKePR9IB56MP1K6MvpPXDhKLl81o57'
      },
      {
        'name': 'Correa Retraible Larga',
        'price': '25.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1UeYMLzLoL3TG6GgitN_BOYsrUawDMl8u'
      },
      {
        'name': 'Correa Retraible Corta',
        'price': '20.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1fO68Mc5zLll2zVG9njhUmYJQ9luRoE5W'
      },
      {
        'name': 'Correa retraible de Colores',
        'price': '20.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1kmPxHOINwWLvyIiTZD5i7PWLLEMt8ZjW'
      },
      {
        'name': 'Correa con bosal para perros',
        'price': '35.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1Y7-IoJP4wMy4FZ5WqG0hBjfmoe6kcyP6'
      },
      {
        'name': 'Plato doble para Perros con soporte',
        'price': '40.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=11oPs8rTkmi0ZYj2ivE_GTuzqbiCay26E'
      },
      {
        'name': 'Plato doble para Perros',
        'price': '30.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=13e7XFHhOgW4IU7Kujl_TEyjsK5_8gWBi'
      },
      {
        'name': 'Plato de aluminio para perro adulto',
        'price': '20.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1GzVs03J6BYVlWGynFfhpPdyyuCoNrgSN'
      },
      {
        'name': 'Plato de 8 onzas para perro',
        'price': '60.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1f8OIlXENC2uXZuRY6y5BXvbyCTA9PsTc'
      },
      {
        'name': 'Ropa termica para perros pequeños',
        'price': '60.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1nYswkB6rC8yCAGKBQA1kT97tQ_F2tbrL'
      },
      {
        'name': 'Vestido para perro Hembra',
        'price': '30.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=163LqMdBikbIZ40X1MqiNKCAqyUPBxfKm'
      },
      {
        'name': 'Abrigo para perro Macho',
        'price': '50.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1AbDOiusG5J7k7bqcJB_ToWJ9ZN-7Rdd0'
      },
      {
        'name': 'Abrigo ajustable',
        'price': '70.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=10kKePAdF58baZpe8UEEJx-__y4Myzsjb'
      },
      {
        'name': 'Abrigo ajustable con cuello alto para perro',
        'price': '90.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1nfQtQ4bh-QB2PUDyAJh8F60TZ0hrq7em'
      },
      {
        'name': 'Ropa impermeable para perros',
        'price': '150.00',
        'category': 'Accesorio',
        'image': 'https://drive.google.com/uc?export=view&id=1SEYBrJwpBAN_ei-VLBCGyTYFNWv6T78c'
      },

    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(
                        onUpdate: () => setState(() {}),
                      ),
                    ),
                  );
                },
              ),
              if (_cartManager.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_cartManager.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      product['image']!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['category']!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product['price']!}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _cartManager.addItem(product);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product['name']} agregado al carrito'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 32),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Agregar', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// PÁGINA DEL CARRITO
class CartPage extends StatefulWidget {
  final VoidCallback onUpdate;
  
  const CartPage({Key? key, required this.onUpdate}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartManager _cartManager = CartManager();

  void _showCheckoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compra Simulada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              '¡Compra realizada con éxito!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${_cartManager.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '(Esta es una simulación, no se realizó ningún cargo real)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _cartManager.clear();
              widget.onUpdate();
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Compra completada. Carrito vaciado.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
      ),
      body: _cartManager.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu carrito está vacío',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartManager.items[index];
                      final price = double.parse(item['price'].toString().replaceAll('\$', '').replaceAll(',', ''));
                      final quantity = item['quantity'] ?? 1;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['image'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.shopping_bag),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      item['category'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${(price * quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            _cartManager.updateQuantity(index, quantity - 1);
                                            widget.onUpdate();
                                          });
                                        },
                                      ),
                                      Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          setState(() {
                                            _cartManager.updateQuantity(index, quantity + 1);
                                            widget.onUpdate();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _cartManager.removeItem(index);
                                        widget.onUpdate();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_cartManager.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          _showCheckoutDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Finalizar Compra',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// PÁGINA DE RESERVAS (MEJORADA CON HISTORIAL)
class BookingsPage extends StatefulWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final user = FirebaseService.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        setState(() {
          _bookings = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Usuario no autenticado';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar reservas: $e';
        _isLoading = false;
      });
    }
  }

  void _showCancelDialog(BuildContext context, String bookingId, String walkerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: Text('¿Estás seguro de cancelar el paseo con $walkerName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({
                      'status': 'Cancelado',
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                
                Navigator.pop(context);
                _loadBookings();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Reserva con $walkerName cancelada'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error al cancelar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    final activeBookings = _bookings.where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      return status != 'cancelado' && 
             status != 'cancelada' &&
             !status.contains('cancel');
    }).toList();

    final cancelledBookings = _bookings.where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      return status == 'cancelado' || 
             status == 'cancelada' ||
             status.contains('cancel');
    }).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.blue[700], size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Historial Completo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TabBar(
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.event_available, size: 18),
                                      const SizedBox(width: 4),
                                      Text('Activas (${activeBookings.length})'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cancel, size: 18),
                                      const SizedBox(width: 4),
                                      Text('Canceladas (${cancelledBookings.length})'),
                                    ],
                                  ),
                                ),
                              ],
                              labelColor: Colors.blue[700],
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.blue[700],
                              indicatorSize: TabBarIndicatorSize.tab,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildBookingsList(activeBookings, false),
                                _buildBookingsList(cancelledBookings, true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings, bool isCancelled) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCancelled ? Icons.cancel_outlined : Icons.event_available,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isCancelled 
                  ? 'No hay reservas canceladas'
                  : 'No hay reservas activas',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              isCancelled
                  ? 'Las reservas que canceles aparecerán aquí'
                  : 'Agenda tu primera reserva desde el botón +',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        booking['walkerImage'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return CircleAvatar(
                            radius: 25,
                            backgroundColor: isCancelled ? Colors.grey : Colors.blue,
                            child: Icon(
                              Icons.directions_walk,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paseo con ${booking['walkerName']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isCancelled ? Colors.grey : Colors.black,
                              decoration: isCancelled ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mascota: ${booking['petName']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_formatDateString(booking['date'])} - ${booking['time']} • ${booking['duration']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'S/. ${booking['totalPrice']?.toStringAsFixed(2) ?? booking['walkerPrice']?.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isCancelled ? Colors.grey : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        booking['status'] ?? 'Pendiente',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: _getStatusColor(booking['status'] ?? 'Pendiente'),
                    ),
                  ],
                ),
                if (!isCancelled && (booking['status'] == 'Confirmado' || booking['status'] == 'Pendiente'))
                  const SizedBox(height: 8),
                if (!isCancelled && (booking['status'] == 'Confirmado' || booking['status'] == 'Pendiente'))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _showCancelDialog(context, booking['id'], booking['walkerName']);
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                        label: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          _showBookingDetails(context, booking);
                        },
                        icon: const Icon(Icons.info, color: Colors.blue, size: 18),
                        label: const Text(
                          'Detalles',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    
    if (statusLower.contains('confirmado') || statusLower.contains('activo')) {
      return Colors.green;
    } else if (statusLower.contains('pendiente')) {
      return Colors.orange;
    } else if (statusLower.contains('cancelado') || statusLower.contains('cancelada')) {
      return Colors.red;
    } else if (statusLower.contains('completado')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Reserva'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Paseador:', booking['walkerName']),
              _buildDetailRow('Mascota:', booking['petName']),
              _buildDetailRow('Fecha:', _formatDateString(booking['date'])),
              _buildDetailRow('Hora:', booking['time']),
              _buildDetailRow('Duración:', booking['duration']),
              _buildDetailRow('Punto de encuentro:', booking['walkerAddress'] ?? 'No especificado'),
              _buildDetailRow('Precio por hora:', 'S/. ${booking['walkerPrice']?.toStringAsFixed(2)}'),
              _buildDetailRow('Precio total:', 'S/. ${booking['totalPrice']?.toStringAsFixed(2) ?? booking['walkerPrice']?.toStringAsFixed(2)}'),
              _buildDetailRow('Estado:', booking['status'] ?? 'Pendiente'),
              if (booking['walkerExperience'] != null)
                _buildDetailRow('Experiencia:', booking['walkerExperience']),
              if (booking['walkerRating'] != null)
                _buildDetailRow('Calificación:', '⭐ ${booking['walkerRating']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBookings = _bookings.where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      return status != 'cancelado' && 
             status != 'cancelada' &&
             !status.contains('cancel');
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showHistoryDialog(context);
            },
            tooltip: 'Ver historial completo',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalkBookingPage()),
              );
            },
            tooltip: 'Nueva reserva',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : activeBookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes reservas activas',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Agenda tu primer paseo desde el botón +',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WalkBookingPage()),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Primera Reserva'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadBookings();
                        return;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activeBookings.length,
                        itemBuilder: (context, index) {
                          final booking = activeBookings[index];
                          final bookingId = booking['id'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          booking['walkerImage'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const CircleAvatar(
                                              radius: 30,
                                              child: Icon(Icons.directions_walk, size: 30),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Paseo con ${booking['walkerName']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Mascota: ${booking['petName']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '${_formatDateString(booking['date'])} - ${booking['time']} • ${booking['duration']}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'S/. ${booking['totalPrice']?.toStringAsFixed(2) ?? booking['walkerPrice']?.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          booking['status'] ?? 'Pendiente',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: _getStatusColor(booking['status'] ?? 'Pendiente'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (booking['status'] == 'Confirmado' || booking['status'] == 'Pendiente')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            _showCancelDialog(context, bookingId, booking['walkerName']);
                                          },
                                          icon: const Icon(Icons.cancel, color: Colors.red),
                                          label: const Text(
                                            'Cancelar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () {
                                            _showBookingDetails(context, booking);
                                          },
                                          icon: const Icon(Icons.info, color: Colors.blue),
                                          label: const Text(
                                            'Detalles',
                                            style: TextStyle(color: Colors.blue),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// NUEVAS PÁGINAS IMPLEMENTADAS

// PÁGINA DE HISTORIAL COMBINADO
class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSegment = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 0 ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Reservas',
                            style: TextStyle(
                              color: _selectedSegment == 0 ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSegment = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedSegment == 1 ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Compras',
                            style: TextStyle(
                              color: _selectedSegment == 1 ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _selectedSegment == 0 ? _buildBookingsHistory() : _buildPurchasesHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getUserBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No tienes historial de reservas',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index].data() as Map<String, dynamic>;
            final bookingId = bookings[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      color: _getStatusColor(booking['status'] ?? 'Pendiente'),
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paseo con ${booking['walkerName']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDateString(booking['date'])} - ${booking['time']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Mascota: ${booking['petName']} • ${booking['duration']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'S/. ${booking['totalPrice']?.toStringAsFixed(2) ?? booking['walkerPrice']?.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        booking['status'] ?? 'Pendiente',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: _getStatusColor(booking['status'] ?? 'Pendiente'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPurchasesHistory() {
    // Simulación de historial de compras - en una app real esto vendría de Firestore
    final purchases = [
      {
        'date': '2024-01-15',
        'items': ['Alimento para Adulto', 'Pelota Interactiva'],
        'total': 85.00,
        'status': 'Completado'
      },
      {
        'date': '2024-01-10',
        'items': ['Arnés Ajustable', 'Correa Reflectante'],
        'total': 50.00,
        'status': 'Completado'
      },
    ];

    if (purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No tienes historial de compras',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        final items = purchase['items'] as List<String>;
        final total = purchase['total'] as double;
        final date = purchase['date'] as String;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  color: Colors.green,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compra - ${_formatPurchaseDate(date)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Productos: ${items.join(', ')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Total: S/. ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: const Text(
                    'Completado',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('completado')) return Colors.green;
    if (statusLower.contains('cancelado')) return Colors.red;
    if (statusLower.contains('pendiente')) return Colors.orange;
    return Colors.grey;
  }

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPurchaseDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// PÁGINA DE CALIFICACIONES
class RatingsPage extends StatefulWidget {
  const RatingsPage({Key? key}) : super(key: key);

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  final List<Map<String, dynamic>> _completedBookings = [
    {
      'walkerName': 'Carlos Ramírez',
      'walkerImage': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      'date': '2024-01-15',
      'petName': 'Rocky',
      'rated': false,
    },
    {
      'walkerName': 'María López',
      'walkerImage': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'date': '2024-01-10',
      'petName': 'Luna',
      'rated': true,
      'rating': 5,
      'comment': 'Excelente servicio, muy profesional'
    },
  ];

  void _showRatingDialog(int index) {
    double rating = 5.0;
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Calificar Paseador'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿Cómo calificas a ${_completedBookings[index]['walkerName']}?',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            rating = i.toDouble();
                          });
                        },
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: i <= rating ? Colors.amber : Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comentario (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _completedBookings[index]['rated'] = true;
                    _completedBookings[index]['rating'] = rating;
                    _completedBookings[index]['comment'] = commentController.text;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Calificación enviada!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Enviar Calificación'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Calificaciones'),
      ),
      body: _completedBookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes paseos completados para calificar',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _completedBookings.length,
              itemBuilder: (context, index) {
                final booking = _completedBookings[index];
                final isRated = booking['rated'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            booking['walkerImage'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const CircleAvatar(
                                radius: 25,
                                child: Icon(Icons.person),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['walkerName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mascota: ${booking['petName']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Fecha: ${_formatDateString(booking['date'])}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (isRated) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    for (int i = 0; i < 5; i++)
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: i < booking['rating'] ? Colors.amber : Colors.grey,
                                      ),
                                  ],
                                ),
                                if (booking['comment'] != null && booking['comment'].isNotEmpty)
                                  Text(
                                    '"${booking['comment']}"',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ],
                          ),
                        ),
                        if (!isRated)
                          ElevatedButton(
                            onPressed: () => _showRatingDialog(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Calificar'),
                          )
                        else
                          const Chip(
                            label: Text(
                              'Calificado',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.green,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// PÁGINA DE SOPORTE
class SupportPage extends StatelessWidget {
  const SupportPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Necesitas ayuda?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estamos aquí para ayudarte con cualquier problema o duda que tengas.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _buildSupportCard(
              Icons.help_outline,
              'Preguntas Frecuentes',
              'Encuentra respuestas a las preguntas más comunes',
              () {
                _showFaqDialog(context);
              },
            ),
            const SizedBox(height: 16),
            _buildSupportCard(
              Icons.contact_support,
              'Contactar Soporte',
              'Escríbenos directamente a nuestro equipo',
              () {
                _contactSupport(context);
              },
            ),
            const SizedBox(height: 16),
            _buildSupportCard(
              Icons.bug_report,
              'Reportar un Problema',
              'Informa sobre errores o problemas técnicos',
              () {
                _reportProblem(context);
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Información de Contacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📧 Correo Electrónico:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _launchEmail(context), // PASA EL CONTEXT
                      child: Text(
                        'soporte@wooftogo.com',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🕒 Horario de Atención:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Lunes a Viernes: 9:00 AM - 6:00 PM'),
                    const Text('Sábados: 9:00 AM - 1:00 PM'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preguntas Frecuentes'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFaqItem(
                '¿Cómo cancelo una reserva?',
                'Puedes cancelar una reserva desde la sección "Mis Reservas" seleccionando la reserva y haciendo clic en "Cancelar".'
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                '¿Qué métodos de pago aceptan?',
                'Aceptamos tarjetas de crédito/débito y PayPal. Próximamente agregaremos más métodos de pago.'
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                '¿Puedo cambiar la mascota para un paseo?',
                'Sí, puedes gestionar tus mascotas desde la sección "Mascotas" y seleccionar la mascota al hacer una reserva.'
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                '¿Qué hago si el paseador no llega?',
                'Contacta inmediatamente a soporte al correo soporte@wooftogo.com o a través de esta sección.'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contactar Soporte'),
        content: const Text(
          'Para contactar a nuestro equipo de soporte, envíanos un correo a soporte@wooftogo.com con tu consulta. Te responderemos en un plazo máximo de 24 horas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail(context); // PASA EL CONTEXT
            },
            child: const Text('Enviar Correo'),
          ),
        ],
      ),
    );
  }

  void _reportProblem(BuildContext context) {
    TextEditingController problemController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Problema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe el problema que encontraste:'),
            const SizedBox(height: 16),
            TextField(
              controller: problemController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Describe el problema...',
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (problemController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Problema reportado. Te contactaremos pronto.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Enviar Reporte'),
          ),
        ],
      ),
    );
  }

  void _launchEmail(BuildContext context) async { // AGREGA EL PARÁMETRO
    final email = 'soporte@wooftogo.com';
    final subject = 'Soporte - Woof to Go';
    final body = 'Hola equipo de Woof to Go,\n\nNecesito ayuda con:';

    final url = 'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Si no se puede lanzar el email, mostrar un snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la aplicación de correo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// PÁGINA DE CONFIGURACIÓN
class SettingsPage extends StatefulWidget {
  final Function(ThemeMode) setTheme; // AGREGAR ESTO
  
  const SettingsPage({Key? key, required this.setTheme}) : super(key: key); // AGREGAR ESTO

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedTheme = 'Claro';
  final List<String> _themes = ['Claro', 'Oscuro', 'Automático'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final userData = await FirebaseService.getUserData();
    if (userData != null) {
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _emailController.text = FirebaseService.currentUser?.email ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferencias',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tema de la aplicación',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedTheme,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _themes.map((theme) {
                          return DropdownMenuItem(
                            value: theme,
                            child: Text(theme),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTheme = value!;
                          });
                          if (value == 'Claro') {
                            widget.setTheme(ThemeMode.light);
                          } else if (value == 'Oscuro') {
                            widget.setTheme(ThemeMode.dark);
                          } else {
                            widget.setTheme(ThemeMode.system);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mi Ubicación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dirección principal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: 'Ingresa tu dirección principal',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Usar ubicación actual'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mis Datos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Guardar Cambios'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final address = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
          
          setState(() {
            _addressController.text = address;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ubicación obtenida exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error obteniendo ubicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveSettings() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Aquí guardarías los datos en Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

// PÁGINA DE PERFIL ACTUALIZADA
class ProfilePage extends StatefulWidget {
  final Function(ThemeMode) setTheme; // AGREGAR ESTO
  
  const ProfilePage({Key? key, required this.setTheme}) : super(key: key); // AGREGAR ESTO

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  String? _profileImageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _profileImageUrl = pickedFile.path;
      });
    }
  }

  Widget _buildProfileAvatar(String userName) {
  final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
  
  if (_profileImage != null) {
    return ClipOval(
      child: Image.file(
        _profileImage!,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
      ),
    );
  }

  return ClipOval(
    child: Container(
      width: 120,
      height: 120,
      color: Colors.blue,
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontSize: 48,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Mi Perfil')),
    body: FutureBuilder<Map<String, dynamic>?>(
      future: FirebaseService.getUserData(),
      builder: (context, snapshot) {
        final user = FirebaseService.currentUser;
        final userData = snapshot.data;
        final userName = userData?['name'] ?? 'Usuario';
        final userEmail = user?.email ?? 'correo@ejemplo.com';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  _buildProfileAvatar(userName), // PASA EL NOMBRE
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                userName, // NOMBRE DEL USUARIO
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                userEmail, // EMAIL DEL USUARIO
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('Historial'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryPage()),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text('Mis calificaciones'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RatingsPage()),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('Soporte'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SupportPage()),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Configuración'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage(setTheme: widget.setTheme)),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseService.logout();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  }
}