import 'package:flutter/material.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/screens/cattle/cattle_detail_screen.dart';
import 'package:union_ganadera_app/screens/cattle/register_cattle_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/bovino_service.dart';

class CattleListScreen extends StatefulWidget {
  const CattleListScreen({super.key});

  @override
  State<CattleListScreen> createState() => _CattleListScreenState();
}

class _CattleListScreenState extends State<CattleListScreen> {
  final ApiClient _apiClient = ApiClient();
  late final BovinoService _bovinoService;
  List<Bovino> _bovinos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bovinoService = BovinoService(_apiClient);
    _loadBovinos();
  }

  Future<void> _loadBovinos() async {
    setState(() => _isLoading = true);
    try {
      final bovinos = await _bovinoService.getBovinos();
      if (mounted) {
        setState(() {
          _bovinos = bovinos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  List<Bovino> get _filteredBovinos {
    if (_searchQuery.isEmpty) return _bovinos;
    return _bovinos.where((bovino) {
      return (bovino.areteBarcode?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false) ||
          (bovino.areteRfid?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false) ||
          (bovino.razaDominante?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ganado'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por arete o raza...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredBovinos.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No tienes ganado registrado'
                          : 'No se encontraron resultados',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadBovinos,
                child: ListView.builder(
                  itemCount: _filteredBovinos.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final bovino = _filteredBovinos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade700,
                          child: Icon(
                            bovino.sexo == 'M' ? Icons.male : Icons.female,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          bovino.areteBarcode ??
                              bovino.areteRfid ??
                              'Sin arete',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bovino.razaDominante != null)
                              Text('Raza: ${bovino.razaDominante}'),
                            if (bovino.pesoActual != null)
                              Text('Peso: ${bovino.pesoActual} kg'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CattleDetailScreen(bovino: bovino),
                            ),
                          ).then((_) => _loadBovinos());
                        },
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterCattleScreen()),
          ).then((_) => _loadBovinos());
        },
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Ganado'),
      ),
    );
  }
}
