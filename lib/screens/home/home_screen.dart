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
      // Veterinarian screens - includes normal user screens plus vet events
      return const [
        CattleListScreen(),
        PrediosScreen(),
        VetEventScreen(),
        ProfileScreen(),
      ];
    } else {
      // Regular user screens
      return const [CattleListScreen(), PrediosScreen(), ProfileScreen()];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isVet = _currentUser?.rol == 'veterinario';
    final primaryColor = isVet ? Colors.blue.shade700 : Colors.green.shade700;

    return Scaffold(
      body: _getScreens()[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withOpacity(0.2),
        surfaceTintColor: Colors.white,
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations:
            isVet
                ? [
                  NavigationDestination(
                    icon: Icon(
                      Icons.pets_outlined,
                      color: Colors.grey.shade600,
                    ),
                    selectedIcon: Icon(Icons.pets, color: primaryColor),
                    label: 'Ganado',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey.shade600,
                    ),
                    selectedIcon: Icon(Icons.location_on, color: primaryColor),
                    label: 'Predios',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.medical_services_outlined,
                      color: Colors.grey.shade600,
                    ),
                    selectedIcon: Icon(
                      Icons.medical_services,
                      color: primaryColor,
                    ),
                    label: 'Eventos Vet.',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.person_outline,
                      color: Colors.grey.shade600,
                    ),
                    selectedIcon: Icon(Icons.person, color: primaryColor),
                    label: 'Perfil',
                  ),
                ]
                : [
                  NavigationDestination(
                    icon: Icon(
                      Icons.pets_outlined,
                      color: Colors.grey.shade600,
                    ),
                    selectedIcon: Icon(Icons.pets, color: primaryColor),
                    label: 'Ganado',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey.shade600,
                    ),
                    selectedIcon: Icon(Icons.location_on, color: primaryColor),
                    label: 'Predios',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.person_outline,
                      color: Colors.grey.shade600,
                    ),
                    selectedIcon: Icon(Icons.person, color: primaryColor),
                    label: 'Perfil',
                  ),
                ],
      ),
    );
  }
}
