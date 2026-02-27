import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';

class BasicInfoStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController cr12Controller;
  final TextEditingController phoneController;
  final bool isFundraiser;
  final bool obscurePassword;
  final bool agreedToTerms;
  final bool agreedToPrivacy;
  final VoidCallback onToggleRole;
  final VoidCallback onToggleVisibility;
  final ValueChanged<bool?> onAgreedToTermsChanged;
  final ValueChanged<bool?> onAgreedToPrivacyChanged;
  final String selectedCountryCode;
  final ValueChanged<String?> onCountryCodeChanged;
  final VoidCallback onNext;

  const BasicInfoStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.cr12Controller,
    required this.phoneController,
    required this.isFundraiser,
    required this.obscurePassword,
    required this.agreedToTerms,
    required this.agreedToPrivacy,
    required this.onToggleRole,
    required this.onToggleVisibility,
    required this.onAgreedToTermsChanged,
    required this.onAgreedToPrivacyChanged,
    required this.selectedCountryCode,
    required this.onCountryCodeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text('SIGN UP', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            _buildInputLabel('I am a:'),
            const SizedBox(height: 8),
            _buildRoleToggle(),
            const SizedBox(height: 30),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey<bool>(isFundraiser),
                children: [
                  _buildInputLabel(isFundraiser ? 'Company Name:' : 'Username:'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (val) => isFundraiser 
                        ? Validators.validateRequired(val, 'Company Name')
                        : Validators.validateUsername(val),
                    decoration: _buildInputDecoration(hint: isFundraiser ? 'Enter company name' : 'Enter a unique username'),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputLabel(isFundraiser ? 'Company Email:' : 'Email Address:'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validators.validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(hint: 'example@domain.com'),
                  ),
                  const SizedBox(height: 20),

                  _buildInputLabel(isFundraiser ? 'CR12 Number:' : 'Phone Number:'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: isFundraiser ? cr12Controller : phoneController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (val) => isFundraiser ? Validators.validateRequired(val, 'CR12 Number') : Validators.validatePhone(val),
                    keyboardType: isFundraiser ? TextInputType.text : TextInputType.phone,
                    decoration: _buildInputDecoration(
                      hint: isFundraiser ? 'Enter registration number' : '7XXXXXXXX',
                      prefix: !isFundraiser ? _buildCountryCodeDropdown() : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildInputLabel('Password:'),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              obscureText: obscurePassword,
              validator: Validators.validatePassword,
              decoration: _buildInputDecoration(hint: 'Min 8 characters', isPassword: true),
            ),
            const SizedBox(height: 20),

            _buildInputLabel('Confirm Password:'),
            const SizedBox(height: 8),
            TextFormField(
              controller: confirmPasswordController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              obscureText: obscurePassword,
              validator: (val) => Validators.validateConfirmPassword(val, passwordController.text),
              decoration: _buildInputDecoration(hint: 'Repeat password', isPassword: true),
            ),
            const SizedBox(height: 30),

            _buildCheckbox(
              value: agreedToTerms,
              label: 'I have read and understood the terms and conditions',
              onChanged: onAgreedToTermsChanged,
            ),
            _buildCheckbox(
              value: agreedToPrivacy,
              label: 'I have read and understood the data security policy',
              onChanged: onAgreedToPrivacyChanged,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Next', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildLoginLink(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: _buildToggleOption('Contributor', !isFundraiser, onToggleRole)),
          Expanded(child: _buildToggleOption('Fundraiser', isFundraiser, onToggleRole)),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)));
  }

  Widget _buildCheckbox({required bool value, required String label, required ValueChanged<bool?> onChanged}) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      ],
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? '),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
        ),
      ],
    );
  }

  Widget _buildCountryCodeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCountryCode,
          items: [
            DropdownMenuItem(value: '+254', child: Text('🇰🇪 +254', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
            DropdownMenuItem(value: '+256', child: Text('🇺🇬 +256', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
            DropdownMenuItem(value: '+255', child: Text('🇹🇿 +255', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
            DropdownMenuItem(value: '+250', child: Text('🇷🇼 +250', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          ],
          onChanged: onCountryCodeChanged,
          style: const TextStyle(color: AppColors.textPrimary),
          icon: const Icon(Icons.arrow_drop_down, size: 20),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hint, bool isPassword = false, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: onToggleVisibility,
            )
          : null,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}
