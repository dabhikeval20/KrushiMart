import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          _buildSection('App Settings'),
          _buildToggleTile(
            Icons.notifications_active_outlined,
            'Notifications',
            'Get alerts for new products and messages',
            _notificationsEnabled,
            (v) => setState(() => _notificationsEnabled = v),
          ),
          _buildToggleTile(
            Icons.dark_mode_outlined,
            'Dark Mode',
            'Switch between light and dark themes',
            _darkModeEnabled,
            (v) => setState(() => _darkModeEnabled = v),
          ),
          _buildSelectionTile(
            Icons.language_outlined,
            'App Language',
            _language,
            () {},
          ),
          const SizedBox(height: 24),
          _buildSection('Account'),
          _buildActionTile(Icons.lock_outline, 'Change Password', () {}),
          _buildActionTile(Icons.verified_user_outlined, 'Verification Status', () {}),
          _buildActionTile(Icons.delete_forever_outlined, 'Deactivate Account', () {}, isDanger: true),
          const SizedBox(height: 24),
          _buildSection('Support'),
          _buildActionTile(Icons.help_outline, 'Help Center', () {}),
          _buildActionTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
          _buildActionTile(Icons.info_outline, 'App Version', () {}, subtitle: 'v1.0.4'),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Designed for Farmers with ❤️',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSelectionTile(IconData icon, String title, String value, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap, {String? subtitle, bool isDanger = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isDanger ? Colors.red[50] : Colors.grey[100], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: isDanger ? Colors.red : Colors.black87, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDanger ? Colors.red : Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
