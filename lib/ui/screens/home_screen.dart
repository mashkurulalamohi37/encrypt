import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isConnected = false;
  String _status = "Initializing Tor...";

  @override
  void initState() {
    super.initState();
    _connectTor();
  }

  Future<void> _connectTor() async {
    // Simulate Tor connection logic
    // In production, this would bind the SocksProxy
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isConnected = true;
      _status = "Connected to Tor (Anon).";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ZeroCost Messenger"),
        backgroundColor: Colors.grey[900],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isConnected ? Icons.lock : Icons.lock_open,
              size: 80,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            if (_isConnected)
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text("Start Chat"),
                onPressed: () {
                  // Navigate to chat list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
