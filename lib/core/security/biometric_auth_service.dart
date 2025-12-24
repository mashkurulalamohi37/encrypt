import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Authenticate user with biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to access your encrypted messages',
  }) async {
    try {
      print('BiometricAuth: Starting authentication...');
      
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      print('BiometricAuth: canCheckBiometrics = $canAuthenticateWithBiometrics');
      
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      print('BiometricAuth: isDeviceSupported = $isDeviceSupported');
      
      final bool canAuthenticate = canAuthenticateWithBiometrics || isDeviceSupported;
      print('BiometricAuth: canAuthenticate = $canAuthenticate');

      if (!canAuthenticate) {
        print('BiometricAuth: Device does not support biometric authentication');
        return false;
      }

      // Get available biometrics for debugging
      final availableBiometrics = await _auth.getAvailableBiometrics();
      print('BiometricAuth: Available biometrics: $availableBiometrics');

      print('BiometricAuth: Calling authenticate with reason: $reason');
      final result = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/Pattern as fallback
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );
      
      print('BiometricAuth: Authentication result = $result');
      return result;
    } on PlatformException catch (e) {
      print('BiometricAuth: PlatformException - Code: ${e.code}, Message: ${e.message}');
      print('BiometricAuth: Full error: $e');
      
      // Handle specific error codes
      if (e.code == 'NotAvailable') {
        print('BiometricAuth: Biometric authentication is not available on this device');
      } else if (e.code == 'NotEnrolled') {
        print('BiometricAuth: No biometrics enrolled on this device');
      } else if (e.code == 'LockedOut') {
        print('BiometricAuth: Too many failed attempts, locked out');
      } else if (e.code == 'PermanentlyLockedOut') {
        print('BiometricAuth: Permanently locked out');
      }
      
      return false;
    } catch (e) {
      print('BiometricAuth: Unexpected error: $e');
      return false;
    }
  }

  /// Stop authentication (if in progress)
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      print('Error stopping authentication: $e');
    }
  }
}
