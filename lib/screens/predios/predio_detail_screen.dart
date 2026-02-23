import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/models/document_file.dart';
import 'package:union_ganadera_app/models/predio.dart';
import 'package:union_ganadera_app/screens/cattle/cattle_detail_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/bovino_service.dart';
import 'package:union_ganadera_app/services/predio_service.dart';
import 'package:union_ganadera_app/utils/file_picker_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class PredioDetailScreen extends StatefulWidget {
  final Predio predio;

  const PredioDetailScreen({super.key, required this.predio});

  @override
  State<PredioDetailScreen> createState() => _PredioDetailScreenState();
}

class _PredioDetailScreenState extends State<PredioDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  late final BovinoService _bovinoService;
  late final PredioService _predioService;
  final MapController _mapController = MapController();

  // Increased height to accommodate document section
  static const double _panelHeight = 290.0;

  DocumentFile? _predioDoc;
  bool _isLoadingDoc = false;
  bool _isUploadingDoc = false;

  @override
  void initState() {
    super.initState();
    _bovinoService = BovinoService(_apiClient);
    _predioService = PredioService(_apiClient);
    _loadDoc();
  }

  Future<void> _loadDoc() async {
    setState(() => _isLoadingDoc = true);
    try {
      final doc = await _predioService.getDocument(widget.predio.id);
      if (mounted) setState(() => _predioDoc = doc);
    } catch (_) {
      // non-fatal — doc section simply shows "sin documento"
    } finally {
      if (mounted) setState(() => _isLoadingDoc = false);
    }
  }

  Future<void> _uploadDoc() async {
    final File? file = await FilePickerSheet.show(context);
    if (file == null) return;
    setState(() => _isUploadingDoc = true);
    try {
      final doc = await _predioService.uploadDocument(
        predioId: widget.predio.id,
        file: file,
      );
      if (mounted) {
        setState(() => _predioDoc = doc);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento subido correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDoc = false);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  bool get _hasLocation =>
      widget.predio.latitud != null && widget.predio.longitud != null;

  LatLng get _predioLatLng =>
      _hasLocation
          ? LatLng(widget.predio.latitud!, widget.predio.longitud!)
          : const LatLng(19.4326, -99.1332); // CDMX fallback

  void _showBovinos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder:
          (ctx) => _BovinosSheet(
            predio: widget.predio,
            bovinoService: _bovinoService,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.predio.claveCatastral ?? 'Detalle del Predio',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Full-screen map ───────────────────────────────────────────
          if (_hasLocation)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _predioLatLng,
                initialZoom: 14.0,
                minZoom: 4.0,
                maxZoom: 19.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.union_ganadera_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _predioLatLng,
                      width: 28,
                      height: 28,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            // No GPS — show placeholder background
            Container(
              color: cs.surfaceContainerHighest,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_rounded,
                      size: 72,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin coordenadas GPS',
                      style: TextStyle(
                        fontSize: 16,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Edita el predio para agregar ubicación.',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── FAB above the details panel ───────────────────────────────
          Positioned(
            bottom: _panelHeight + safeBottom + 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'predio_bovinos_fab',
              onPressed: _showBovinos,
              icon: const Icon(Icons.pets_rounded),
              label: const Text('Ver Ganado'),
              elevation: 4,
            ),
          ),

          // ── Details panel ─────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _DetailsPanel(
              predio: widget.predio,
              panelHeight: _panelHeight,
              safeBottom: safeBottom,
              doc: _predioDoc,
              isLoadingDoc: _isLoadingDoc,
              isUploadingDoc: _isUploadingDoc,
              onUploadDoc: _uploadDoc,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Details Panel
// ─────────────────────────────────────────────────────────────────────────────
class _DetailsPanel extends StatelessWidget {
  final Predio predio;
  final double panelHeight;
  final double safeBottom;
  final DocumentFile? doc;
  final bool isLoadingDoc;
  final bool isUploadingDoc;
  final VoidCallback onUploadDoc;

  const _DetailsPanel({
    required this.predio,
    required this.panelHeight,
    required this.safeBottom,
    required this.doc,
    required this.isLoadingDoc,
    required this.isUploadingDoc,
    required this.onUploadDoc,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(minHeight: panelHeight + safeBottom),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + safeBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Title row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.landscape_rounded,
                  color: cs.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      predio.claveCatastral ?? 'Sin clave catastral',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (predio.superficieTotal != null)
                      Text(
                        '${predio.superficieTotal!.toStringAsFixed(1)} hectáreas',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // GPS chips row
          if (predio.latitud != null && predio.longitud != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.my_location_rounded,
                  label: 'Lat',
                  value: predio.latitud!.toStringAsFixed(6),
                ),
                _InfoChip(
                  icon: Icons.explore_rounded,
                  label: 'Long',
                  value: predio.longitud!.toStringAsFixed(6),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  Icons.location_off_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Sin coordenadas registradas',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),

          // ── Document section ────────────────────────────────────────
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child:
                    isLoadingDoc
                        ? Text(
                          'Verificando documento…',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                        : doc != null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 15,
                                  color: Colors.green.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Documento subido',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        doc!.authored
                                            ? cs.secondaryContainer
                                            : cs.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    doc!.authored ? 'Autorizado' : 'Pendiente',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          doc!.authored
                                              ? cs.onSecondaryContainer
                                              : cs.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              doc!.originalFilename,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                        : Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 15,
                              color: cs.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sin documento',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
              ),
              if (!isLoadingDoc) ...[
                if (doc?.downloadUrl != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    tooltip: 'Ver documento',
                    color: cs.primary,
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final uri = Uri.tryParse(doc!.downloadUrl!);
                      if (uri != null) await launchUrl(uri);
                    },
                  ),
                IconButton(
                  icon:
                      isUploadingDoc
                          ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                          : Icon(
                            doc != null
                                ? Icons.upload_file_rounded
                                : Icons.upload_outlined,
                            size: 18,
                          ),
                  tooltip:
                      doc != null ? 'Reemplazar documento' : 'Subir documento',
                  color: cs.primary,
                  visualDensity: VisualDensity.compact,
                  onPressed: isUploadingDoc ? null : onUploadDoc,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bovinos Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _BovinosSheet extends StatefulWidget {
  final Predio predio;
  final BovinoService bovinoService;

  const _BovinosSheet({required this.predio, required this.bovinoService});

  @override
  State<_BovinosSheet> createState() => _BovinosSheetState();
}

class _BovinosSheetState extends State<_BovinosSheet> {
  List<Bovino> _bovinos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBovinos();
  }

  Future<void> _loadBovinos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bovinos = await widget.bovinoService.getBovinosByPredio(
        widget.predio.id,
      );
      if (mounted) {
        setState(() {
          _bovinos = bovinos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.pets_rounded, color: cs.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ganado en este predio',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? _buildError()
                        : _bovinos.isEmpty
                        ? _buildEmpty(cs)
                        : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          itemCount: _bovinos.length,
                          itemBuilder: (context, index) {
                            return _BovinoTile(
                              bovino: _bovinos[index],
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CattleDetailScreen(
                                          bovino: _bovinos[index],
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets_outlined, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Sin ganado registrado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra bovinos y asígnalos a este predio.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadBovinos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bovino Tile
// ─────────────────────────────────────────────────────────────────────────────
class _BovinoTile extends StatelessWidget {
  final Bovino bovino;
  final VoidCallback onTap;

  const _BovinoTile({required this.bovino, required this.onTap});

  Color _statusColor(String status, ColorScheme cs) {
    switch (status.toLowerCase()) {
      case 'activo':
        return cs.secondary;
      case 'vendido':
        return cs.tertiary;
      case 'muerto':
        return cs.error;
      case 'enfermo':
      case 'en tratamiento':
        return Colors.orange;
      default:
        return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = bovino.nombre ?? bovino.areteBarcode ?? 'Sin identificación';
    final subtitle = [
      if (bovino.razaDominante != null) bovino.razaDominante!,
      if (bovino.sexo != null) bovino.sexo == 'M' ? 'Macho' : 'Hembra',
      if (bovino.pesoActual != null)
        '${bovino.pesoActual!.toStringAsFixed(0)} kg',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar / nose photo
              ClipOval(
                child:
                    bovino.narizUrl != null
                        ? Image.network(
                          bovino.narizUrl!,
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => _iconAvatar(cs, bovino.sexo),
                        )
                        : _iconAvatar(cs, bovino.sexo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    if (bovino.areteBarcode != null)
                      Text(
                        bovino.areteBarcode!,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        bovino.status,
                        cs,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bovino.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(bovino.status, cs),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconAvatar(ColorScheme cs, String? sexo) {
    return Container(
      width: 46,
      height: 46,
      color: cs.primaryContainer,
      child: Icon(
        sexo == 'M' ? Icons.male_rounded : Icons.female_rounded,
        color: cs.onPrimaryContainer,
        size: 24,
      ),
    );
  }
}
