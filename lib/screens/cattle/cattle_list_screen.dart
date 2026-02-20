import 'package:flutter/material.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/models/predio.dart';
import 'package:union_ganadera_app/screens/cattle/cattle_detail_screen.dart';
import 'package:union_ganadera_app/screens/cattle/register_cattle_screen.dart';
import 'package:union_ganadera_app/screens/events/register_event_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/bovino_service.dart';
import 'package:union_ganadera_app/services/predio_service.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class CattleListScreen extends StatefulWidget {
  const CattleListScreen({super.key});

  @override
  State<CattleListScreen> createState() => _CattleListScreenState();
}

class _CattleListScreenState extends State<CattleListScreen> {
  final ApiClient _apiClient = ApiClient();
  late final BovinoService _bovinoService;
  late final PredioService _predioService;
  List<Bovino> _bovinos = [];
  final Set<String> _selectedBovinoIds = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _bovinoService = BovinoService(_apiClient);
    _predioService = PredioService(_apiClient);
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar:
          _isSelectionMode
              ? AppBar(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedBovinoIds.clear();
                    });
                  },
                ),
                title: Text(
                  '${_selectedBovinoIds.length} seleccionados',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                actions:
                    _selectedBovinoIds.isNotEmpty
                        ? [
                          IconButton(
                            icon: const Icon(Icons.location_on_outlined),
                            tooltip: 'Asignar a Predio',
                            onPressed: _showAssignPredioSheet,
                          ),
                          IconButton(
                            icon: const Icon(Icons.event_note_outlined),
                            tooltip: 'Registrar Evento',
                            onPressed: () {
                              final selectedBovinos =
                                  _bovinos
                                      .where(
                                        (b) =>
                                            _selectedBovinoIds.contains(b.id),
                                      )
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
                          const SizedBox(width: 4),
                        ]
                        : null,
              )
              : ModernAppBar(
                title: 'Mi Ganado',
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Builder(
                      builder: (context) {
                        final cs = Theme.of(context).colorScheme;
                        return TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar por arete o raza...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                            fillColor: cs.surfaceContainerHigh,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle: TextStyle(color: cs.onSurfaceVariant),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                          style: TextStyle(color: cs.onSurface),
                          onChanged:
                              (value) => setState(() => _searchQuery = value),
                        );
                      },
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
                                      runSpacing: 4,
                                      children: [
                                        _StatusChip(status: bovino.status),
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

  Future<void> _showAssignPredioSheet() async {
    final List<Predio> predios;
    try {
      predios = await _predioService.getPredios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar predios: $e')));
      }
      return;
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Asignar ${_selectedBovinoIds.length} bovino(s) a un predio',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (predios.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No tienes predios registrados',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: predios.length,
                    itemBuilder: (ctx, index) {
                      final predio = predios[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.landscape_rounded,
                            color: cs.onPrimaryContainer,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          predio.claveCatastral ?? 'Sin clave catastral',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle:
                            predio.superficieTotal != null
                                ? Text(
                                  '${predio.superficieTotal!.toStringAsFixed(1)} ha',
                                )
                                : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _assignBovinosToPredio(predio.id);
                        },
                      );
                    },
                  ),
                ),
              ListTile(
                leading: Icon(Icons.block_rounded, color: cs.onSurfaceVariant),
                title: Text(
                  'Sin predio (desasignar)',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _assignBovinosToPredio(null);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _assignBovinosToPredio(String? predioId) async {
    final ids = _selectedBovinoIds.toList();
    try {
      await Future.wait(
        ids.map(
          (id) => _bovinoService.updateBovino(id, {'predio_id': predioId}),
        ),
      );
      if (mounted) {
        final label =
            predioId != null
                ? 'Asignados al predio'
                : 'Desasignados del predio';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label (${ids.length} bovino(s))'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedBovinoIds.clear();
        });
        await _loadBovinos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _bgColor() {
    switch (status.toLowerCase()) {
      case 'activo':
        return Colors.green.shade100;
      case 'en tratamiento':
        return Colors.orange.shade100;
      case 'muerto':
        return Colors.red.shade100;
      case 'inactivo':
        return Colors.grey.shade200;
      default:
        return Colors.blueGrey.shade50;
    }
  }

  Color _fgColor() {
    switch (status.toLowerCase()) {
      case 'activo':
        return Colors.green.shade800;
      case 'en tratamiento':
        return Colors.orange.shade800;
      case 'muerto':
        return Colors.red.shade800;
      case 'inactivo':
        return Colors.grey.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  IconData _icon() {
    switch (status.toLowerCase()) {
      case 'activo':
        return Icons.check_circle_outline_rounded;
      case 'en tratamiento':
        return Icons.medical_services_outlined;
      case 'muerto':
        return Icons.cancel_outlined;
      case 'inactivo':
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 12, color: _fgColor()),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11.5,
              color: _fgColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
