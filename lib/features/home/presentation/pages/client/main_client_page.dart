import 'package:flutter/material.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
import 'package:francomalishipp/core/theme/app_color.dart';
import 'home_page.dart';
import 'reception_envoi_page.dart';
import 'suivi_page.dart';
import 'notifications_page.dart';

class MainClientPage extends StatefulWidget {
  final User? user;
  const MainClientPage({super.key, this.user});

  @override
  State<MainClientPage> createState() => _MainClientPageState();
}

class _MainClientPageState extends State<MainClientPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(user: widget.user),
      ReceptionEnvoiPage(user: widget.user),
      SuiviPage(user: widget.user),
      NotificationsPage(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColor.kWhite,
        selectedItemColor: AppColor.kPrimary,
        unselectedItemColor: AppColor.kGrayscale40,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Reçu/Envoyé',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Suivi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}