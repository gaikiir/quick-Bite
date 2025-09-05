import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/auth/login.dart';
import 'package:quick_bite/screens/provider/theme_provider.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _locationEnabled = true;

  void _showEditProfileDialog(String currentValue, String field) async {
    final controller = TextEditingController(text: currentValue);
    final theme = Theme.of(context);

    // Show loading indicator
    void showLoading() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    // Hide loading indicator
    void hideLoading() {
      Navigator.pop(context);
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${field.capitalize()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter your ${field.toLowerCase()}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: field == 'email'
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              textCapitalization: field == 'name'
                  ? TextCapitalization.words
                  : TextCapitalization.none,
            ),
            const SizedBox(height: 16),
            Text(
              field == 'email'
                  ? 'You\'ll need to verify your new email address'
                  : 'This will update your profile information',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty && newValue != currentValue) {
                Navigator.pop(context, newValue);
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      showLoading();
      try {
        if (field == 'name') {
          await user?.updateDisplayName(result);
        } else if (field == 'email') {
          // First reauthenticate the user
          if (user != null) {
            try {
              final credential = EmailAuthProvider.credential(
                email: user!.email!,
                password:
                    "current-password", // You should implement a way to get the current password
              );
              await user!.reauthenticateWithCredential(credential);
              await user!.verifyBeforeUpdateEmail(result);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Verification email sent. Please check your inbox.',
                    ),
                  ),
                );
              }
            } catch (e) {
              throw Exception(
                'Please reauthenticate before changing your email',
              );
            }
          }
        }
        setState(() {}); // Refresh the UI
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update ${field.toLowerCase()}: ${e.toString()}',
              ),
            ),
          );
        }
      } finally {
        if (mounted) hideLoading();
      }
    }
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final String name = user?.displayName ?? 'Fai zur Rehman';
    final String email = user?.email ?? 'fai.zur@example.com';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            name[0].toUpperCase(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                // TODO: Implement image picker
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        InkWell(
                          onTap: () => _showEditProfileDialog(name, 'name'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _showEditProfileDialog(email, 'email'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PROFILE Section
            _buildSection(
              title: 'PROFILE',
              children: [
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: 'Account details',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildProfileOption(
                  icon: Icons.description_outlined,
                  title: 'Documents',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildToggleOption(
                  icon: Icons.location_on_outlined,
                  title: 'Turn your location',
                  subtitle: 'This will improve lots of things',
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
              ],
            ),

            // BANK DETAIL Section
            _buildSection(
              title: 'BANK DETAIL',
              children: [
                _buildProfileOption(
                  icon: Icons.account_balance_outlined,
                  title: 'Bank Account',
                  onTap: () {},
                ),
              ],
            ),

            // SETTINGS Section
            _buildSection(
              title: 'SETTINGS',
              children: [
                _buildToggleOption(
                  icon: themeProvider.isDarkTheme
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  title: 'Theme Mode',
                  subtitle: themeProvider.isDarkTheme
                      ? 'Switch to Light Mode'
                      : 'Switch to Dark Mode',
                  value: themeProvider.isDarkTheme,
                  onChanged: (value) => themeProvider.setDarkTheme(value),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirmLogout,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onError,
                    backgroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Log Out',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onError,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: theme.iconTheme.color,
      ),
      onTap: onTap,
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
    );
  }

  void _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }
}
