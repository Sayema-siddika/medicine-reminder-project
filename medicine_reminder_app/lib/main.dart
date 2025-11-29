import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/medication_provider.dart';
import 'screens/splash_screen.dart'; // We will create this
import 'screens/login_screen.dart';  // We will create this
import 'screens/home_screen.dart';   // We will create this
import 'services/notification_service.dart';

void main() async {
  // 1. Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize the Notification System
  await NotificationService.initialize();
  
  // 3. Run the App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider lets us inject multiple state managers at the root
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
      ],
      child: MaterialApp(
        title: 'Medicine Reminder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // Use Google Fonts for a modern look
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        // The "AuthWrapper" decides which screen to show
        home: const AuthWrapper(),
      ),
    );
  }
}

// This widget listens to the AuthProvider
// If logged in -> Go Home
// If not logged in -> Go Login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Try to load saved token when app starts
    Future.microtask(() => 
      context.read<AuthProvider>().loadSavedAuth()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}