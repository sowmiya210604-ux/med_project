import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) '../../../core/utils/file_stub.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    print('🔵 ProfileScreen: initState called');
    // Fetch latest profile data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        // Only fetch if we don't have current user data
        if (authProvider.currentUser == null) {
          print('🔵 ProfileScreen: Fetching profile data...');
          _fetchProfileData();
        } else {
          print('🔵 ProfileScreen: User data already exists, skipping fetch');
        }
      }
    });
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingProfile = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.fetchProfile();

    if (mounted) {
      setState(() {
        _isLoadingProfile = false;
      });

      if (!success) {
        // If profile fetch failed and user was logged out,
        // the auth guard will handle redirection
        if (authProvider.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'Failed to load profile',
              ),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _fetchProfileData,
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null && mounted) {
        final authProvider = context.read<AuthProvider>();
        final success = await authProvider.updateProfileImage(image.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Profile photo updated successfully'
                    : 'Failed to update profile photo',
              ),
              backgroundColor: success ? AppColors.success : AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Profile Photo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.camera_alt, color: AppColors.primary),
                  ),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library,
                        color: AppColors.secondary),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete, color: AppColors.error),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeProfileImage() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.updateProfileImage('');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Profile photo removed successfully'
                  : 'Failed to remove profile photo',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 ProfileScreen: build() called');
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Profile',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;

              // Show loading indicator while fetching profile
              if (_isLoadingProfile || authProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // Show error state if no user data
              if (user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No user data available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchProfileData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _fetchProfileData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Profile Header
                      _buildProfileHeader(context, user.name, user.email),

                      const SizedBox(height: 24),

                      // Personal Information
                      _buildSection(
                        context,
                        'Personal Information',
                        [
                          _buildInfoTile(
                            context,
                            'Full Name',
                            user.name,
                            Icons.person,
                          ),
                          _buildInfoTile(
                            context,
                            'Email',
                            user.email,
                            Icons.email,
                          ),
                          _buildInfoTile(
                            context,
                            'Phone',
                            user.phone,
                            Icons.phone,
                          ),
                          if (user.dateOfBirth != null)
                            _buildInfoTile(
                              context,
                              'Date of Birth',
                              '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}',
                              Icons.cake,
                            ),
                          if (user.gender != null)
                            _buildInfoTile(
                              context,
                              'Gender',
                              user.gender!,
                              Icons.wc,
                            ),
                          if (user.bloodGroup != null)
                            _buildInfoTile(
                              context,
                              'Blood Group',
                              user.bloodGroup!,
                              Icons.bloodtype,
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Settings
                      _buildSection(
                        context,
                        'Settings',
                        [
                          _buildActionTile(
                            context,
                            'Edit Profile',
                            Icons.edit,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionTile(
                            context,
                            'Notifications',
                            Icons.notifications,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionTile(
                            context,
                            'Privacy & Security',
                            Icons.security,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacySecurityScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionTile(
                            context,
                            'Help & Support',
                            Icons.help,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HelpSupportScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // About
                      _buildSection(
                        context,
                        'About',
                        [
                          _buildActionTile(
                            context,
                            'Terms of Service',
                            Icons.description,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TermsOfServiceScreen(),
                                ),
                              );
                            },
                          ),
                          _buildActionTile(
                            context,
                            'Privacy Policy',
                            Icons.policy,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                          _buildInfoTile(
                            context,
                            'App Version',
                            '1.0.0',
                            Icons.info,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Logout Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirm =
                                await _showLogoutConfirmation(context);
                            if (confirm && context.mounted) {
                              await authProvider.logout();
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
                            }
                          },
                          icon:
                              const Icon(Icons.logout, color: AppColors.error),
                          label: const Text(
                            'Logout',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String email,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final profileImage =
                          authProvider.currentUser?.profileImage;

                      // Handle different platforms
                      ImageProvider? imageProvider;
                      bool hasImage = false;

                      if (profileImage != null && profileImage.isNotEmpty) {
                        if (kIsWeb) {
                          // On web, use NetworkImage with the file path
                          imageProvider = NetworkImage(profileImage);
                          hasImage = true;
                        } else {
                          try {
                            // On mobile, use FileImage - wrap in try-catch for web compatibility
                            final file = File(profileImage);
                            if (file.existsSync()) {
                              imageProvider = FileImage(file as dynamic);
                              hasImage = true;
                            }
                          } catch (e) {
                            // Fallback to network image if File operations fail
                            imageProvider = NetworkImage(profileImage);
                            hasImage = true;
                          }
                        }
                      }

                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.secondary,
                        backgroundImage: imageProvider,
                        child: !hasImage
                            ? Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
