import 'package:flutter/material.dart';
import 'package:union_ganadera_app/models/user.dart';
import 'package:union_ganadera_app/screens/cattle/cattle_list_screen.dart';
import 'package:union_ganadera_app/screens/events/vet_event_screen.dart';
import 'package:union_ganadera_app/screens/predios/predios_screen.dart';
import 'package:union_ganadera_app/screens/profile/profile_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ApiClient _apiClient = ApiClient();
  late final AuthService _authService;
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiClient);
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Widget> _getScreens() {
    if (_currentUser?.rol == 'veterinario') {
      return const [
        CattleListScreen(),
        PrediosScreen(),
        VetEventScreen(),
        ProfileScreen(),
      ];
    } else {
      return const [CattleListScreen(), PrediosScreen(), ProfileScreen()];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final isVet = _currentUser?.rol == 'veterinario';

    final destinations =
        isVet
            ? const [
              NavigationDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets),
                label: 'Ganado',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Predios',
              ),
              NavigationDestination(
                icon: Icon(Icons.medical_services_outlined),
                selectedIcon: Icon(Icons.medical_services),
                label: 'Vet.',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ]
            : const [
              NavigationDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets),
                label: 'Ganado',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Predios',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ];

    return Scaffold(
      body: _getScreens()[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: destinations,
      ),
    );
  }
}
