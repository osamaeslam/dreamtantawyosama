import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import 'visits_dashboard_screen.dart';

class VisitsScreen extends StatelessWidget {
  final AppUser currentUser;
  const VisitsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return const _VisitsRedirector();
  }
}

class _VisitsRedirector extends StatefulWidget {
  const _VisitsRedirector({super.key});

  @override
  State<_VisitsRedirector> createState() => _VisitsRedirectorState();
}

class _VisitsRedirectorState extends State<_VisitsRedirector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VisitsDashboardScreen(currentUser: currentUser ?? AppUser(
            id: '',
            name: '',
            username: '',
            role: 'sales_rep',
            branchName: '',
            phone: '',
          )),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white70),
      ),
    );
  }
}
}
