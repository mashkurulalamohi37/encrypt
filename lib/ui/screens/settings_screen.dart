import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/security/biometric_auth_service.dart';
import '../../core/security/panic_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final secureStorage = Provider.of<SecureStorageService>(context, listen: false);
    
    final available = await _biometricAuth.canCheckBiometrics();
    final enabled = await secureStorage.read('biometric_lock_enabled');
    
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled == 'true';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    if (value) {
      // User is trying to enable biometric lock
      try {
        // First, check what biometrics are available
        final availableBiometrics = await _biometricAuth.getAvailableBiometrics();
        print('Available biometrics on device: $availableBiometrics');
        
        if (availableBiometrics.isEmpty) {
          // No biometrics enrolled
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No biometrics enrolled. Please set up fingerprint or face unlock in your phone settings first.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 4),
                backgroundColor: AppTheme.cardDark,
              ),
            );
          }
          return;
        }
        
        final authenticated = await _biometricAuth.authenticate(
          reason: 'Authenticate to enable biometric lock',
        );
        
        if (!authenticated) {
          // Authentication was cancelled or failed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Authentication cancelled. Please try again and complete the biometric scan.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: AppTheme.cardDark,
                action: SnackBarAction(
                  label: 'RETRY',
                  textColor: AppTheme.primaryTeal,
                  onPressed: () {
                    // Trigger the toggle again
                    _toggleBiometric(true);
                  },
                ),
              ),
            );
          }
          return; // Don't enable if authentication failed
        }
      } catch (e) {
        // Error during authentication
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Error: $e'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: AppTheme.cardDark,
            ),
          );
        }
        return; // Don't enable if there was an error
      }
    }

    // Save the setting
    try {
      final secureStorage = Provider.of<SecureStorageService>(context, listen: false);
      await secureStorage.write('biometric_lock_enabled', value.toString());
      
      setState(() {
        _biometricEnabled = value;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  value ? Icons.check_circle : Icons.info,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(width: 12),
                Text(value ? 'Biometric lock enabled' : 'Biometric lock disabled'),
              ],
            ),
            duration: const Duration(milliseconds: 2000),
            backgroundColor: AppTheme.cardDark,
          ),
        );
      }
    } catch (e) {
      // Error saving setting
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to save setting: $e'),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppTheme.cardDark,
          ),
        );
      }
    }
  }

  Future<void> _confirmPanic() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(
              "PANIC BUTTON",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This will permanently delete:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _DangerItem(text: "All encryption keys"),
            _DangerItem(text: "All messages and chats"),
            _DangerItem(text: "All app data"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This action cannot be undone!",
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "DELETE EVERYTHING",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final panicService = Provider.of<PanicService>(context, listen: false);
      await panicService.triggerPanic();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Settings'),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Security Section
                  _SectionHeader(
                    icon: Icons.security,
                    title: 'SECURITY',
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: 12),
                  
                  _SettingsCard(
                    child: SwitchListTile(
                      value: _biometricEnabled,
                      onChanged: _biometricAvailable ? _toggleBiometric : null,
                      activeColor: AppTheme.primaryTeal,
                      title: const Text(
                        'Biometric Lock',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _biometricAvailable
                            ? 'Require fingerprint/face to unlock app'
                            : 'Biometric authentication not available',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: _biometricAvailable
                              ? AppTheme.lightGradient
                              : null,
                          color: _biometricAvailable ? null : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fingerprint,
                          color: _biometricAvailable ? AppTheme.primaryTeal : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Danger Zone
                  _SectionHeader(
                    icon: Icons.warning_rounded,
                    title: 'DANGER ZONE',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  
                  _SettingsCard(
                    borderColor: Colors.red.withOpacity(0.3),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_forever, color: Colors.red),
                      ),
                      title: const Text(
                        'Panic Button',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      subtitle: Text(
                        'Permanently delete all data',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                      onTap: _confirmPanic,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // About Section
                  _SectionHeader(
                    icon: Icons.info_outline,
                    title: 'ABOUT',
                    color: AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: 12),
                  
                  _SettingsCard(
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.info_outline,
                          title: 'Version',
                          subtitle: '1.0.0',
                        ),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        _InfoTile(
                          icon: Icons.lock_outline,
                          title: 'Encryption',
                          subtitle: 'Signal Protocol (E2EE)',
                        ),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        _InfoTile(
                          icon: Icons.shield_outlined,
                          title: 'Network',
                          subtitle: 'Tor Hidden Service (Anonymous)',
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Footer
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                            child: const Icon(
                              Icons.lock,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Zero-Cost, End-to-End Encrypted,\nAnonymous Messenger',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _SettingsCard({
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: AppTheme.lightGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryTeal),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _DangerItem extends StatelessWidget {
  final String text;

  const _DangerItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.close, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
