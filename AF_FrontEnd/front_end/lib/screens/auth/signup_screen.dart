import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import './widgets/basic_info_step.dart';
import './widgets/otp_verification_step.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Controllers: Step 1
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController(); // Company Name or Full Name
  final _cr12Controller = TextEditingController(); // Fundraiser only
  final _phoneController = TextEditingController(); // Contributor only

  // Controllers: Step 2 (OTP)
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isFundraiser = false;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _cr12Controller.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms || !_agreedToPrivacy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please agree to the Terms and Privacy Policy')),
        );
        return;
      }
      
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    setState(() => _currentStep = 0);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleFinalSignup() async {
    String otp = _otpControllers.map((e) => e.text).join();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 4-digit code')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful! Welcome to Ascent.')),
      );
      Navigator.pop(context);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
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
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              BasicInfoStep(
                formKey: _formKey,
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                cr12Controller: _cr12Controller,
                phoneController: _phoneController,
                isFundraiser: _isFundraiser,
                obscurePassword: _obscurePassword,
                agreedToTerms: _agreedToTerms,
                agreedToPrivacy: _agreedToPrivacy,
                onToggleRole: () => setState(() => _isFundraiser = !_isFundraiser),
                onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                onAgreedToTermsChanged: (val) => setState(() => _agreedToTerms = val!),
                onAgreedToPrivacyChanged: (val) => setState(() => _agreedToPrivacy = val!),
                onNext: _nextStep,
              ),
              OtpVerificationStep(
                otpControllers: _otpControllers,
                otpFocusNodes: _otpFocusNodes,
                email: _emailController.text,
                isLoading: authProvider.isLoading,
                onSignup: _handleFinalSignup,
              ),
            ],
          );
        }
      ),
    );
  }
}
