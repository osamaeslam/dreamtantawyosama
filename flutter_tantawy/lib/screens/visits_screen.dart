import 'package:flutter/material.dart';
import '../models/models.dart';
import 'visits_dashboard_screen.dart';

class VisitsScreen extends StatelessWidget {
  final AppUser currentUser;
  const VisitsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return _VisitsRedirector(currentUser: currentUser);
  }
}

class _VisitsRedirector extends StatefulWidget {
  final AppUser currentUser;
  const _VisitsRedirector({super.key, required this.currentUser});

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
          builder: (context) => VisitsDashboardScreen(currentUser: widget.currentUser),
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
