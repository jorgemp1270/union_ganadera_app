import 'package:flutter/material.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/screens/cattle/cattle_detail_screen.dart';
import 'package:union_ganadera_app/screens/cattle/register_cattle_screen.dart';
import 'package:union_ganadera_app/screens/events/register_event_screen.dart';
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
  Set<String> _selectedBovinoIds = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;
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
        title: Text(
          _isSelectionMode
              ? '${_selectedBovinoIds.length} seleccionados'
              : 'Mi Ganado',
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        leading:
            _isSelectionMode
                ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedBovinoIds.clear();
                    });
                  },
                )
                : null,
        actions:
            _isSelectionMode
                ? [
                  if (_selectedBovinoIds.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.event),
                      tooltip: 'Registrar Evento',
                      onPressed: () {
                        final selectedBovinos =
                            _bovinos
                                .where((b) => _selectedBovinoIds.contains(b.id))
                                .toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RegisterEventScreen(
                                  bovinos: selectedBovinos,
                                ),
                          ),
                        ).then((_) {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedBovinoIds.clear();
                          });
                        });
                      },
                    ),
                ]
                : null,
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
                    final isSelected = _selectedBovinoIds.contains(bovino.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isSelected ? Colors.green.shade50 : null,
                      child: ListTile(
                        leading:
                            _isSelectionMode
                                ? Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedBovinoIds.add(bovino.id);
                                      } else {
                                        _selectedBovinoIds.remove(bovino.id);
                                      }
                                    });
                                  },
                                  activeColor: Colors.green.shade700,
                                )
                                : CircleAvatar(
                                  backgroundColor: Colors.green.shade700,
                                  child: Icon(
                                    bovino.sexo == 'M'
                                        ? Icons.male
                                        : Icons.female,
                                    color: Colors.white,
                                  ),
                                ),
                        title: Text(
                          bovino.nombre ??
                              bovino.areteBarcode ??
                              bovino.areteRfid ??
                              'Sin identificación',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bovino.areteBarcode != null)
                              Text('Arete: ${bovino.areteBarcode}'),
                            if (bovino.razaDominante != null)
                              Text('Raza: ${bovino.razaDominante}'),
                            if (bovino.pesoActual != null)
                              Text('Peso: ${bovino.pesoActual} kg'),
                          ],
                        ),
                        trailing:
                            _isSelectionMode
                                ? null
                                : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedBovinoIds.remove(bovino.id);
                              } else {
                                _selectedBovinoIds.add(bovino.id);
                              }
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CattleDetailScreen(bovino: bovino),
                              ),
                            ).then((_) => _loadBovinos());
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton:
          _isSelectionMode
              ? null
              : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'select_multiple',
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedBovinoIds.clear();
                      });
                    },
                    backgroundColor: Colors.orange.shade700,
                    icon: const Icon(Icons.checklist, color: Colors.white),
                    label: const Text('Selección Múltiple'),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'register_cattle',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterCattleScreen(),
                        ),
                      ).then((_) => _loadBovinos());
                    },
                    backgroundColor: Colors.green.shade700,
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Ganado'),
                  ),
                ],
              ),
    );
  }
}
