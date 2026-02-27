import 'package:flutter/material.dart';
import 'package:front_end/screens/auth/login_screen.dart';
import 'package:front_end/data/services/auth_service.dart';
import '../../ui/pages/fundraiser/fundraiser_dashboard_page.dart';
import '../contributor/contributor_dashboard.dart';

class LoginOptionsPage extends StatelessWidget {
  const LoginOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(
                height: 60.0,
              ),
              Image.asset(
                'assets/icon/ascent_icon.png',
                height: 100,
              ),
              const SizedBox(
                height: 40,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                label: const Text("Continue with Email"),
                icon: const Icon(Icons.email),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                label: const Text("Continue With Google"),
                icon: Image.asset(
                  'assets/icon/google_icon.png',
                  width: 24,
                  height: 24,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final authService = AuthService();
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final result = await authService.login('test@ascentfin.com', 'password123');
                    final role = result['role'] ?? 'fundraiser';

                    if (context.mounted) {
                      Navigator.pop(context);
                      if (role == 'fundraiser') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const FundraiserDashboardPage()),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ContributorDashboard()),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Bypass login failed: $e")),
                      );
                    }
                  }
                },
                label: const Text("Continue with SSO"),
                icon: const Icon(Icons.key),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final authService = AuthService();
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await authService.login('victor@test.com', 'password123');
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ContributorDashboard()),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ContributorDashboard()),
                      );
                    }
                  }
                },
                label: const Text("Bypass as Contributor"),
                icon: const Icon(Icons.person_outline),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Terms and Conditions',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
