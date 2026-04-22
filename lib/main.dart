import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';       // add Hive Flutter
import 'package:hive/hive.dart';                       // add Hive core
import 'package:mad2_etr_silva/components/colors.dart';
import 'package:mad2_etr_silva/firebase_options.dart';
import 'package:mad2_etr_silva/screens/home/home_screen.dart';
import 'package:mad2_etr_silva/screens/user/user_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pet.dart';                                      // import your Pet model with Hive annotations

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before Firebase
  await Hive.initFlutter();
  Hive.registerAdapter(PetAdapter());                 // Register your Pet adapter
  await Hive.openBox('petsBox');                       // Open the Hive box for pets

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(FurGetMeNotApp());
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
}

class FurGetMeNotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: AppColors.cream,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Wait for the splash animation (optional, keep your 5 seconds or reduce)
    await Future.delayed(Duration(seconds: 3));

    if (isLoggedIn) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => UserLoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 300,
              height: 300,
            ),
            SizedBox(height: 10),
            SpinKitRipple(color: Color(0xffb5ca92), size: 100),
          ],
        ),
      ),
    );
  }
}
