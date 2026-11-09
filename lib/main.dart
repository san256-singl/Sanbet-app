import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String API_BASE = "https://sanbet-backend.onrender.com";

void main() {
  runApp(SanbetApp());
}

class SanbetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sanbet Africa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF0B3D2E),
        scaffoldBackgroundColor: Color(0xFFF5F5F0),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0B3D2E)),
        useMaterial3: true,
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
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0B3D2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 80, color: Colors.amber),
            SizedBox(height: 16),
            Text('SANBET AFRICA', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            Text('Bet Smart. Win Big.', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLogin = true;
  String msg = '';
  bool loading = false;

  Future<void> doAuth() async {
    setState(() { loading = true; msg = ''; });
    final url = Uri.parse('$API_BASE/api/auth/${isLogin ? "login" : "register"}');
    try {
      final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'phone': phoneCtrl.text.trim(), 'password': passCtrl.text.trim()}));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('phone', phoneCtrl.text.trim());
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        setState(() { msg = data['error'] ?? 'Failed'; });
      }
    } catch (e) {
      setState(() { msg = 'Cannot connect to server. Try again.'; });
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.sports_soccer, size: 60, color: Color(0xFF0B3D2E)),
            SizedBox(height: 12),
            Text(isLogin ? 'Welcome Back' : 'Create Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone e.g 0701234567', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: 'Password / PIN', border: OutlineInputBorder())),
            SizedBox(height: 16),
            if (msg.isNotEmpty) Text(msg, style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: loading ? null : doAuth,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0B3D2E), padding: EdgeInsets.symmetric(vertical: 16)),
              child: Text(loading ? 'Please wait...' : (isLogin ? 'LOGIN' : 'REGISTER'), style: TextStyle(color: Colors.white)),
            ),
            TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "No account? Register" : "Have account? Login")),
          ],
        ),
      ),
    );
  }
}
