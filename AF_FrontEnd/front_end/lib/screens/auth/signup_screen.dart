import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
<<<<<<< HEAD
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  String _selectedRole = 'contributor'; // Default role
  bool _obscurePassword = true;
=======
  
  // Common Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Role-Specific Controllers
  final _nameController = TextEditingController(); // Company Name or Full Name
  final _cr12Controller = TextEditingController(); // Fundraiser only
  final _phoneController = TextEditingController(); // Contributor only

  bool _isFundraiser = false; // Toggle state
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _cr12Controller.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
<<<<<<< HEAD
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        profileData: {
          'username': _usernameController.text.trim(),
        },
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful! Please Login.')),
        );
        Navigator.pop(context); // Go back to login
=======
      if (!_agreedToTerms || !_agreedToPrivacy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the Terms and Privacy Policy')),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final Map<String, dynamic> profileData = {
        'name': _nameController.text.trim(),
      };

      if (_isFundraiser) {
        profileData['cr12_number'] = _cr12Controller.text.trim();
      } else {
        profileData['phone_number'] = _phoneController.text.trim();
      }

      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _isFundraiser ? 'fundraiser' : 'contributor',
        profileData: profileData,
      );

      if (success && mounted) {
        // As per wireframe, we navigate to the next step (e.g., OTP)
        // For now, we show success and go back to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Step 1 Complete! Verification required.')),
        );
        Navigator.pop(context);
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
      } else if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'SIGN UP',
                      style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),

<<<<<<< HEAD
                    // Role Selection
                    _buildInputLabel('I am a:'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleButton('contributor', 'Contributor'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRoleButton('fundraiser', 'Fundraiser'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Username Field
                    _buildInputLabel('Username:'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      validator: (value) => Validators.validateRequired(value, 'Username'),
                      decoration: _buildInputDecoration(hint: 'Enter your preferred username'),
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    _buildInputLabel('Email:'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      validator: Validators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(hint: 'Example: john@mail.com'),
=======
                    // Role Selection Toggle
                    _buildInputLabel('I am a:'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleOption(
                              label: 'Contributor',
                              isSelected: !_isFundraiser,
                              onTap: () => setState(() => _isFundraiser = false),
                            ),
                          ),
                          Expanded(
                            child: _buildToggleOption(
                              label: 'Fundraiser',
                              isSelected: _isFundraiser,
                              onTap: () => setState(() => _isFundraiser = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Dynamic Fields based on Role
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey<bool>(_isFundraiser),
                        children: [
                          // Name Field
                          _buildInputLabel(_isFundraiser ? 'Company Name:' : 'Full Name:'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            validator: (val) => Validators.validateRequired(val, _isFundraiser ? 'Company Name' : 'Full Name'),
                            decoration: _buildInputDecoration(hint: _isFundraiser ? 'e.g. Ascent Tech Ltd' : 'e.g. John Doe'),
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          _buildInputLabel(_isFundraiser ? 'Company Email:' : 'Personal Email:'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            validator: Validators.validateEmail,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration(hint: 'example@domain.com'),
                          ),
                          const SizedBox(height: 20),

                          // Unique Field (CR12 vs Phone)
                          _buildInputLabel(_isFundraiser ? 'CR12 Number:' : 'Phone Number:'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _isFundraiser ? _cr12Controller : _phoneController,
                            validator: (val) => _isFundraiser 
                                ? Validators.validateRequired(val, 'CR12 Number')
                                : Validators.validatePhone(val),
                            keyboardType: _isFundraiser ? TextInputType.text : TextInputType.phone,
                            decoration: _buildInputDecoration(hint: _isFundraiser ? 'Enter registration number' : '07XXXXXXXX'),
                          ),
                        ],
                      ),
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
                    ),
                    const SizedBox(height: 20),

                    // Password Field
<<<<<<< HEAD
                    _buildInputLabel('Password:'),
=======
                    _buildInputLabel('Create Password:'),
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
<<<<<<< HEAD
                      decoration: _buildInputDecoration(
                        hint: 'Min 8 characters',
                        isPassword: true,
                      ),
=======
                      decoration: _buildInputDecoration(hint: 'At least 8 characters', isPassword: true),
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password Field
                    _buildInputLabel('Confirm Password:'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
<<<<<<< HEAD
                      decoration: _buildInputDecoration(
                        hint: 'Repeat your password',
                        isPassword: true,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Toggle Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
=======
                      decoration: _buildInputDecoration(hint: 'Repeat password', isPassword: true),
                    ),
                    const SizedBox(height: 30),

                    // Legal Checkboxes
                    _buildCheckbox(
                      value: _agreedToTerms,
                      label: 'I have read and understood the terms and conditions',
                      onChanged: (val) => setState(() => _agreedToTerms = val!),
                    ),
                    _buildCheckbox(
                      value: _agreedToPrivacy,
                      label: 'I have read and understood the data security policy',
                      onChanged: (val) => setState(() => _agreedToPrivacy = val!),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (authProvider.isLoading) ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isFundraiser ? 'Next' : 'Create Account',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Login',
                            style: TextStyle(
<<<<<<< HEAD
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
=======
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold, 
                              decoration: TextDecoration.underline
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
                            ),
                          ),
                        ),
                      ],
                    ),
<<<<<<< HEAD
                    const SizedBox(height: 30),
=======
                    const SizedBox(height: 40),
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildRoleButton(String role, String label) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
=======
  Widget _buildToggleOption({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
<<<<<<< HEAD
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
=======
              color: isSelected ? Colors.white : AppColors.textSecondary,
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
<<<<<<< HEAD
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
=======
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hint, bool isPassword = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
<<<<<<< HEAD
      suffixIcon: isPassword 
        ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          )
        : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
=======
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _buildCheckbox({required bool value, required String label, required ValueChanged<bool?> onChanged}) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
>>>>>>> eb746ab (feat: Refactor authentication flow with role-based signup and integrate an AuthProvider, while deleting old authentication and documentation files.)
    );
  }
}
