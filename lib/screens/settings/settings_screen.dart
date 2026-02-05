import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/meter_service.dart';
import '../../services/customer_api_service.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _customerCount = 0;
  bool _isLoadingCustomerCount = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerCount();
  }

  Future<void> _loadCustomerCount() async {
    final count = await CustomerApiService.instance.getLocalCustomerCount();
    setState(() {
      _customerCount = count;
      _isLoadingCustomerCount = false;
    });
  }

  Future<void> _syncCustomers(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Customer Data'),
        content: const Text(
          'This will download the last 5000 customers from the server to your device for offline use. '
          'This may take a few minutes.\n\n'
          'If you search for a customer not in the offline list, the app will search online automatically.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Start Sync'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SyncProgressDialog(),
    );

    try {
      final result = await CustomerApiService.instance.syncCustomersInBatches(
        batchSize: 100,
        onProgress: (synced, total) {
          // Update progress in dialog
        },
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog

        if (result.success) {
          await _loadCustomerCount(); // Refresh count

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _syncReadings(BuildContext context) async {
    final meterService = Provider.of<MeterService>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing readings...'),
        duration: Duration(seconds: 1),
      ),
    );

    await meterService.syncReadings();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${meterService.unsyncedReadings.length} readings synced successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final meterService = Provider.of<MeterService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (user?.fullName ?? user?.username ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? user?.username ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Total Readings',
                          value: '${meterService.readings.length}',
                          icon: Icons.electric_meter,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatBox(
                          label: 'Unsynced',
                          value: '${meterService.unsyncedReadings.length}',
                          icon: Icons.sync_disabled,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StatBox(
                    label: 'Customers (Offline)',
                    value: _isLoadingCustomerCount ? '...' : '$_customerCount',
                    icon: Icons.people,
                    color: AppTheme.secondaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Admin Section (only for admins)
            if (authService.isAdmin)
              _SettingsSection(
                title: 'Administration',
                children: [
                  _SettingsTile(
                    icon: Icons.dashboard,
                    title: 'Admin Dashboard',
                    subtitle: 'View reports and analytics',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

            // Settings options
            _SettingsSection(
              title: 'Account',
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'View and edit your profile',
                  onTap: () {
                    // Navigate to profile screen
                  },
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () {
                    // Navigate to change password screen
                  },
                ),
              ],
            ),

            _SettingsSection(
              title: 'Data',
              children: [
                _SettingsTile(
                  icon: Icons.sync,
                  title: 'Sync Readings',
                  subtitle: '${meterService.unsyncedReadings.length} unsynced readings',
                  onTap: () => _syncReadings(context),
                ),
                _SettingsTile(
                  icon: Icons.cloud_download,
                  title: 'Sync Customer Data',
                  subtitle: '$_customerCount of last 5000 customers offline',
                  onTap: () => _syncCustomers(context),
                ),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Export Data',
                  subtitle: 'Export all readings to CSV',
                  onTap: () {
                    // Export functionality
                  },
                ),
              ],
            ),

            _SettingsSection(
              title: 'App',
              children: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Meter OCR',
                      applicationVersion: '1.0.0',
                      applicationIcon: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.electric_meter_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      children: [
                        const Text('Smart Meter Reading Solution with OCR'),
                        const SizedBox(height: 8),
                        const Text('Offline capable with SQLite database'),
                      ],
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {
                    // Open privacy policy
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}

class _SyncProgressDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Syncing last 5000 customers...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloading for offline use. This may take a few minutes.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
