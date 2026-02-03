import 'package:flutter/material.dart';
import 'package:front_end/screens/auth/login_screen.dart';
import '../fundraiser/fundraiser_dashboard.dart';
import '../contributor/contributor_dashboard.dart';

class LoginOptionsPage extends StatelessWidget {
  const LoginOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(
                height: 350.0,
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
                label: Text("Continue with Email"),
                icon: Icon(Icons.email),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                label: Text("Continue With Google"),
                icon: Image.asset(
                  'assets/icon/google_icon.png',
                  width: 24,
                  height: 24,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 20),
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
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Select Dashboard",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(Icons.person, color: Colors.blue),
                            title: const Text("Contributor Dashboard"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ContributorDashboard()),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.campaign, color: Colors.orangeAccent),
                            title: const Text("Fundraiser Dashboard"),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const FundraiserDashboard()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                label: const Text("Continue with SSO"),
                icon: const Icon(Icons.key),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Terms and Conditions',
                      style: TextStyle(color: Colors.blueGrey),
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
