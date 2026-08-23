import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class NetworkService {
  static Future<bool> isConnected() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<bool> checkAndWarn(BuildContext context) async {
    final connected = await isConnected();
    if (!connected) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF141414),
            title: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.orange),
                const SizedBox(width: 8),
                Text('No Internet', style: TextStyle(color: Theme.of(context).primaryColor)),
              ],
            ),
            content: const Text(
              'Please turn on your internet connection to use this AI feature.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        );
      }
      return false;
    }
    return true;
  }
}
