import 'package:flutter/material.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/screens/cattle/cattle_detail_screen.dart';
import 'package:union_ganadera_app/screens/cattle/register_cattle_screen.dart';
import 'package:union_ganadera_app/screens/events/register_event_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/bovino_service.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

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
      appBar: ModernAppBar(
        title:
            _isSelectionMode
                ? '${_selectedBovinoIds.length} seleccionados'
                : 'Mi Ganado',
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
                      icon: const Icon(Icons.event_note_outlined),
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
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por arete o raza...',
                prefixIcon: const Icon(Icons.search_rounded),
                fillColor: Colors.white.withOpacity(0.18),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIconColor: Colors.white70,
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredBovinos.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadBovinos,
                child: ListView.builder(
                  itemCount: _filteredBovinos.length,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  itemBuilder: (context, index) {
                    final bovino = _filteredBovinos[index];
                    final isSelected = _selectedBovinoIds.contains(bovino.id);
                    final cs = Theme.of(context).colorScheme;
                    return Card(
                      color:
                          isSelected
                              ? cs.secondaryContainer
                              : cs.surfaceContainerLow,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
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
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedBovinoIds.add(bovino.id);
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              if (_isSelectionMode)
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedBovinoIds.add(bovino.id);
                                      } else {
                                        _selectedBovinoIds.remove(bovino.id);
                                      }
                                    });
                                  },
                                )
                              else
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    bovino.sexo == 'M'
                                        ? Icons.male_rounded
                                        : Icons.female_rounded,
                                    color: cs.onPrimaryContainer,
                                    size: 26,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bovino.nombre ??
                                          bovino.areteBarcode ??
                                          bovino.areteRfid ??
                                          'Sin identificación',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        if (bovino.areteBarcode != null)
                                          _Chip(
                                            icon: Icons.qr_code_2_outlined,
                                            label: bovino.areteBarcode!,
                                          ),
                                        if (bovino.razaDominante != null)
                                          _Chip(
                                            icon: Icons.pets_outlined,
                                            label: bovino.razaDominante!,
                                          ),
                                        if (bovino.pesoActual != null)
                                          _Chip(
                                            icon: Icons.monitor_weight_outlined,
                                            label: '${bovino.pesoActual} kg',
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (!_isSelectionMode)
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: cs.onSurfaceVariant,
                                ),
                            ],
                          ),
                        ),
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
                  FloatingActionButton.small(
                    heroTag: 'select_multiple',
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedBovinoIds.clear();
                      });
                    },
                    tooltip: 'Selección múltiple',
                    child: const Icon(Icons.checklist_rounded),
                  ),
                  const SizedBox(height: 10),
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
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Registrar Ganado'),
                  ),
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets_outlined,
                size: 52,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty
                  ? 'Sin ganado registrado'
                  : 'Sin resultados para "$_searchQuery"',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Usa el botón de abajo para registrar tu primera res.'
                  : 'Intenta con otro término de búsqueda.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
