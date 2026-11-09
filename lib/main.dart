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
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double balance = 0;
  List matches = [];
  Map<String, Map<String, dynamic>> slip = {};
  String phone = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    phone = prefs.getString('phone') ?? '';
    try {
      final res = await http.get(Uri.parse('$API_BASE/api/matches'), headers: {'Authorization': 'Bearer $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          matches = data['matches'] ?? [];
          balance = (data['balance'] ?? 0).toDouble();
        });
      }
    } catch (e) {}
  }

  double get totalOdds {
    double o = 1;
    slip.forEach((_, v) { o *= (v['odd'] as num).toDouble(); });
    return o;
  }

  void addToSlip(dynamic m, String pick, double odd) {
    setState(() {
      slip['${m['id']}'] = {'match': m, 'pick': pick, 'odd': odd};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0B3D2E),
        title: Text('SANBET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Center(child: Padding(padding: EdgeInsets.only(right: 12), child: Text('UGX ${balance.toStringAsFixed(0)}', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)))),
          IconButton(icon: Icon(Icons.refresh, color: Colors.white), onPressed: loadData),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.amber,
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance: UGX ${balance.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DepositScreen(onDone: loadData))), child: Text('DEPOSIT')),
                    SizedBox(width: 8),
                    ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WithdrawScreen(onDone: loadData))), child: Text('WITHDRAW')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? Center(child: Text('No matches yet. Pull to refresh.'))
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (_, i) {
                      final m = matches[i];
                      return Card(
                        margin: EdgeInsets.all(8),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${m['league'] ?? ''} • ${m['time'] ?? ''}', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              SizedBox(height: 6),
                              Text('${m['home']} vs ${m['away']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  _oddBtn(m, '1', (m['odd1'] ?? 1.0).toDouble(), m['home']),
                                  SizedBox(width: 6),
                                  _oddBtn(m, 'X', (m['oddX'] ?? 1.0).toDouble(), 'Draw'),
                                  SizedBox(width: 6),
                                  _oddBtn(m, '2', (m['odd2'] ?? 1.0).toDouble(), m['away']),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (slip.isNotEmpty)
            Container(
              color: Color(0xFF0B3D2E),
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: Text('${slip.length} selections • Odds ${totalOdds.toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BetSlipScreen(slip: slip, totalOdds: totalOdds, onDone: () { setState(() => slip.clear()); loadData(); }))),
                    child: Text('BET SLIP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
class BetSlipScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> slip;
  final double totalOdds;
  final VoidCallback onDone;
  BetSlipScreen({required this.slip, required this.totalOdds, required this.onDone});
  @override
  _BetSlipScreenState createState() => _BetSlipScreenState();
}

class _BetSlipScreenState extends State<BetSlipScreen> {
  final stakeCtrl = TextEditingController(text: '1000');
  String msg = '';
  bool loading = false;

  Future<void> placeBet() async {
    setState(() { loading = true; msg = ''; });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.post(
        Uri.parse('$API_BASE/api/bets/place'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'stake': double.tryParse(stakeCtrl.text) ?? 0,
          'totalOdds': widget.totalOdds,
          'selections': widget.slip.values.map((e) => {'match': '${e['match']['home']} vs ${e['match']['away']}', 'pick': e['pick'], 'odd': e['odd']}).toList(),
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        widget.onDone();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bet placed! Good luck')));
      } else {
        setState(() { msg = data['error'] ?? 'Failed'; });
      }
    } catch (e) {
      setState(() { msg = 'Cannot connect to server'; });
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    double stake = double.tryParse(stakeCtrl.text) ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text('Bet Slip'), backgroundColor: Color(0xFF0B3D2E), foregroundColor: Colors.white),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ...widget.slip.values.map((e) => ListTile(title: Text('${e['match']['home']} vs ${e['match']['away']}'), subtitle: Text('Pick: ${e['pick']}'), trailing: Text('${e['odd']}'))).toList(),
            Divider(),
            TextField(controller: stakeCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Stake UGX', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
            SizedBox(height: 12),
            Text('Total Odds: ${widget.totalOdds.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Possible Win: UGX ${(stake * widget.totalOdds).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
            SizedBox(height: 12),
            if (msg.isNotEmpty) Text(msg, style: TextStyle(color: Colors.red)),
            SizedBox(height: 12),
            ElevatedButton(onPressed: loading ? null : placeBet, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0B3D2E), minimumSize: Size(double.infinity, 50)), child: Text(loading ? 'Placing...' : 'PLACE BET', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class DepositScreen extends StatefulWidget {
  final VoidCallback onDone;
  DepositScreen({required this.onDone});
  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final amtCtrl = TextEditingController(text: '5000');
  String msg = '';
  bool loading = false;

  Future<void> deposit() async {
    setState(() { loading = true; msg = ''; });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final phone = prefs.getString('phone') ?? '';
    try {
      final res = await http.post(Uri.parse('$API_BASE/api/wallet/deposit'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'amount': double.tryParse(amtCtrl.text) ?? 0, 'phone': phone}));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() { msg = 'Deposit request sent! Check your phone for MTN/Airtel prompt.'; });
        widget.onDone();
      } else {
        setState(() { msg = data['error'] ?? 'Failed'; });
      }
    } catch (e) {
      setState(() { msg = 'Cannot connect'; });
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Deposit'), backgroundColor: Color(0xFF0B3D2E), foregroundColor: Colors.white),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Deposit via Mobile Money', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount UGX', border: OutlineInputBorder())),
            SizedBox(height: 16),
            if (msg.isNotEmpty) Text(msg, textAlign: TextAlign.center),
            SizedBox(height: 12),
            ElevatedButton(onPressed: loading ? null : deposit, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0B3D2E), minimumSize: Size(double.infinity, 50)), child: Text(loading ? 'Please wait...' : 'DEPOSIT', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class WithdrawScreen extends StatefulWidget {
  final VoidCallback onDone;
  WithdrawScreen({required this.onDone});
  @override
  _WithdrawScreenState createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final amtCtrl = TextEditingController(text: '5000');
  final phoneCtrl = TextEditingController();
  String msg = '';
  bool loading = false;

  Future<void> withdraw() async {
    setState(() { loading = true; msg = ''; });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.post(Uri.parse('$API_BASE/api/wallet/withdraw'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'amount': double.tryParse(amtCtrl.text) ?? 0, 'phone': phoneCtrl.text.trim()}));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() { msg = 'Withdraw request sent! You will receive money soon.'; });
        widget.onDone();
      } else {
        setState(() { msg = data['error'] ?? 'Failed'; });
      }
    } catch (e) {
      setState(() { msg = 'Cannot connect'; });
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Withdraw'), backgroundColor: Color(0xFF0B3D2E), foregroundColor: Colors.white),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Withdraw to Mobile Money', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount UGX', border: OutlineInputBorder())),
            SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone to receive e.g 0701234567', border: OutlineInputBorder())),
            SizedBox(height: 16),
            if (msg.isNotEmpty) Text(msg, textAlign: TextAlign.center),
            SizedBox(height: 12),
            ElevatedButton(onPressed: loading ? null : withdraw, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0B3D2E), minimumSize: Size(double.infinity, 50)), child: Text(loading ? 'Please wait...' : 'WITHDRAW', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
  Widget _oddBtn(dynamic m, String label, double odd, String pickName) {
    bool selected = slip['${m['id']}']?['pick'] == pickName;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: selected ? Colors.amber : Colors.grey[200]),
        onPressed: () => addToSlip(m, pickName, odd),
        child: Text('$label\n$odd', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
