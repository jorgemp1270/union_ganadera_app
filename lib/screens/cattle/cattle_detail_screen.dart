import 'package:flutter/material.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/models/evento.dart';
import 'package:union_ganadera_app/screens/events/register_event_screen.dart';
import 'package:union_ganadera_app/screens/cattle/edit_cattle_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/bovino_service.dart';
import 'package:union_ganadera_app/services/evento_service.dart';
import 'package:intl/intl.dart';
import 'package:union_ganadera_app/utils/modern_app_bar.dart';

class CattleDetailScreen extends StatefulWidget {
  final Bovino bovino;

  const CattleDetailScreen({super.key, required this.bovino});

  @override
  State<CattleDetailScreen> createState() => _CattleDetailScreenState();
}

class _CattleDetailScreenState extends State<CattleDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  late final EventoService _eventoService;
  late final BovinoService _bovinoService;
  Map<EventType, List<Evento>> _eventosByType = {};
  bool _isLoadingEventos = true;
  Bovino? _madre;
  Bovino? _padre;
  bool _madreCrossOwner = false;
  bool _padreCrossOwner = false;

  @override
  void initState() {
    super.initState();
    _eventoService = EventoService(_apiClient);
    _bovinoService = BovinoService(_apiClient);
    _loadEventos();
    _loadParents();
  }

  Future<void> _loadParents() async {
    final madreId = widget.bovino.madreId;
    final padreId = widget.bovino.padreId;
    if (madreId != null) {
      try {
        final m = await _bovinoService.getBovino(madreId);
        if (mounted) setState(() => _madre = m);
      } catch (_) {
        // 403 cross-ownership or deleted — fall back to embedded projection
        if (mounted) setState(() => _madreCrossOwner = true);
      }
    }
    if (padreId != null) {
      try {
        final p = await _bovinoService.getBovino(padreId);
        if (mounted) setState(() => _padre = p);
      } catch (_) {
        if (mounted) setState(() => _padreCrossOwner = true);
      }
    }
  }

  Future<void> _loadEventos() async {
    setState(() => _isLoadingEventos = true);
    try {
      final Map<EventType, List<Evento>> eventosByType = {};
      for (final eventType in EventType.values) {
        try {
          final eventos = await _eventoService.getEventosByType(
            eventType,
            widget.bovino.id,
          );
          if (eventos.isNotEmpty) {
            eventosByType[eventType] = eventos;
          }
        } catch (e) {
          continue;
        }
      }
      if (mounted) {
        setState(() {
          _eventosByType = eventosByType;
          _isLoadingEventos = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEventos = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
        return Colors.green.shade600;
      case 'vendido':
        return Colors.blue.shade600;
      case 'muerto':
        return Colors.grey.shade600;
      case 'enfermo':
      case 'en tratamiento':
        return Colors.orange.shade700;
      case 'en cuarentena':
        return Colors.red.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  Color _eventColor(EventType type) {
    switch (type) {
      case EventType.peso:
        return Colors.indigo;
      case EventType.dieta:
        return Colors.orange;
      case EventType.vacunacion:
        return Colors.teal;
      case EventType.desparasitacion:
        return Colors.purple;
      case EventType.laboratorio:
        return Colors.blue;
      case EventType.compraventa:
        return Colors.green;
      case EventType.traslado:
        return Colors.cyan;
      case EventType.enfermedad:
        return Colors.red;
      case EventType.tratamiento:
        return Colors.deepOrange;
    }
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.peso:
        return Icons.monitor_weight_outlined;
      case EventType.dieta:
        return Icons.restaurant_outlined;
      case EventType.vacunacion:
        return Icons.vaccines_outlined;
      case EventType.desparasitacion:
        return Icons.medication_outlined;
      case EventType.laboratorio:
        return Icons.science_outlined;
      case EventType.compraventa:
        return Icons.sell_outlined;
      case EventType.traslado:
        return Icons.local_shipping_outlined;
      case EventType.enfermedad:
        return Icons.sick_outlined;
      case EventType.tratamiento:
        return Icons.healing_outlined;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isMale = widget.bovino.sexo == 'M';
    final statusColor = _statusColor(widget.bovino.status);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: ModernAppBar(
        title:
            widget.bovino.nombre ??
            widget.bovino.areteBarcode ??
            'Detalle del Ganado',
        backgroundColor: Colors.green.shade700,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditCattleScreen(bovino: widget.bovino),
            ),
          );
          if (result == true && mounted) Navigator.pop(context);
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Editar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero Header ──────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green.shade800, Colors.green.shade500],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    // Avatar circle
                    Container(
                      width: 96,
                      height: 96,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2.5,
                        ),
                      ),
                      child:
                          widget.bovino.narizUrl != null
                              ? Image.network(
                                widget.bovino.narizUrl!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Icon(
                                      isMale
                                          ? Icons.male_rounded
                                          : Icons.female_rounded,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                              )
                              : Icon(
                                isMale
                                    ? Icons.male_rounded
                                    : Icons.female_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                    ),
                    const SizedBox(height: 14),
                    // Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.bovino.nombre ??
                            widget.bovino.areteBarcode ??
                            widget.bovino.areteRfid ??
                            'Sin identificación',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (widget.bovino.razaDominante != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.bovino.razaDominante!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Status chip
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.circle, size: 10, color: statusColor),
                      ),
                      label: Text(
                        widget.bovino.status.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: statusColor.withOpacity(0.35),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Curved bottom edge
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info Sections ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.badge_outlined,
                      title: 'Identificación',
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    // Nariz photo full-width card
                    if (widget.bovino.narizUrl != null)
                      _NarizPhotoCard(
                        narizUrl: widget.bovino.narizUrl!,
                        colorScheme: colorScheme,
                      ),
                    if (widget.bovino.narizUrl != null)
                      const SizedBox(height: 10),
                    _buildInfoCards([
                      if (widget.bovino.folio != null)
                        _InfoCardData(
                          icon: Icons.tag_rounded,
                          label: 'Folio',
                          value: widget.bovino.folio!,
                          highlighted: true,
                        ),
                      if (widget.bovino.areteBarcode != null)
                        _InfoCardData(
                          icon: Icons.qr_code_2_outlined,
                          label: 'Arete Barcode',
                          value: widget.bovino.areteBarcode!,
                        ),
                      if (widget.bovino.areteRfid != null)
                        _InfoCardData(
                          icon: Icons.nfc_outlined,
                          label: 'Arete RFID',
                          value: widget.bovino.areteRfid!,
                        ),
                    ], colorScheme),

                    const SizedBox(height: 20),
                    _SectionHeader(
                      icon: Icons.info_outline_rounded,
                      title: 'Información General',
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCards([
                      _InfoCardData(
                        icon:
                            isMale ? Icons.male_rounded : Icons.female_rounded,
                        label: 'Sexo',
                        value: isMale ? 'Macho' : 'Hembra',
                      ),
                      if (widget.bovino.fechaNac != null)
                        _InfoCardData(
                          icon: Icons.cake_outlined,
                          label: 'Fecha Nacimiento',
                          value: dateFormat.format(widget.bovino.fechaNac!),
                        ),
                      if (widget.bovino.proposito != null)
                        _InfoCardData(
                          icon: Icons.work_outline_rounded,
                          label: 'Propósito',
                          value: widget.bovino.proposito!,
                        ),
                    ], colorScheme),

                    const SizedBox(height: 20),
                    _SectionHeader(
                      icon: Icons.monitor_weight_outlined,
                      title: 'Datos de Peso',
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCards([
                      if (widget.bovino.pesoNac != null)
                        _InfoCardData(
                          icon: Icons.child_care_outlined,
                          label: 'Peso Nacimiento',
                          value: '${widget.bovino.pesoNac} kg',
                        ),
                      if (widget.bovino.pesoActual != null)
                        _InfoCardData(
                          icon: Icons.monitor_weight_outlined,
                          label: 'Peso Actual',
                          value: '${widget.bovino.pesoActual} kg',
                          highlighted: true,
                        ),
                    ], colorScheme),

                    // ── Genealogía ────────────────────────────────────────
                    if (widget.bovino.madreId != null ||
                        widget.bovino.padreId != null) ...[
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.account_tree_outlined,
                        title: 'Genealogía',
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      if (widget.bovino.madreId != null)
                        _ParentCard(
                          label: 'Madre',
                          icon: Icons.female_rounded,
                          bovino: _madre,
                          projection: widget.bovino.madreProjection,
                          crossOwner: _madreCrossOwner,
                          bovinoId: widget.bovino.madreId!,
                          colorScheme: colorScheme,
                          onTap:
                              _madre != null
                                  ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => CattleDetailScreen(
                                            bovino: _madre!,
                                          ),
                                    ),
                                  )
                                  : null,
                        ),
                      if (widget.bovino.madreId != null &&
                          widget.bovino.padreId != null)
                        const SizedBox(height: 10),
                      if (widget.bovino.padreId != null)
                        _ParentCard(
                          label: 'Padre',
                          icon: Icons.male_rounded,
                          bovino: _padre,
                          projection: widget.bovino.padreProjection,
                          crossOwner: _padreCrossOwner,
                          bovinoId: widget.bovino.padreId!,
                          colorScheme: colorScheme,
                          onTap:
                              _padre != null
                                  ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => CattleDetailScreen(
                                            bovino: _padre!,
                                          ),
                                    ),
                                  )
                                  : null,
                        ),
                    ],

                    // ── Evento Section Header ─────────────────────────────
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _SectionHeader(
                            icon: Icons.history_outlined,
                            title: 'Historial de Eventos',
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => RegisterEventScreen(
                                      bovinos: [widget.bovino],
                                    ),
                              ),
                            ).then((_) => _loadEventos());
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nuevo Evento'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green.shade800,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Event List ────────────────────────────────────────
                    if (_isLoadingEventos)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    else if (_eventosByType.isEmpty)
                      _EmptyEvents()
                    else
                      ..._eventosByType.entries.map((entry) {
                        return _EventTypeCard(
                          eventType: entry.key,
                          eventos: entry.value,
                          dateFormat: dateFormat,
                          color: _eventColor(entry.key),
                          icon: _getEventIcon(entry.key),
                          buildDetails: _buildEventDetails,
                        );
                      }),

                    // Bottom padding above FAB
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info Cards ─────────────────────────────────────────────────────────────

  Widget _buildInfoCards(List<_InfoCardData> items, ColorScheme colorScheme) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              items.map((item) {
                final bool hi = item.highlighted;
                return SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          hi
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          hi
                              ? Border.all(
                                color: colorScheme.primary.withOpacity(0.4),
                                width: 1.5,
                              )
                              : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 17,
                              color:
                                  hi
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      hi
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color:
                                hi
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  // ── Event Detail Builder ───────────────────────────────────────────────────

  Widget _buildEventDetails(Evento evento) {
    TextStyle style = const TextStyle(fontSize: 12.5, color: Colors.black54);
    if (evento is PesoEvento) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nuevo peso: ${evento.pesoNuevo} kg', style: style),
          if (evento.pesoAnterior != null)
            Text('Peso anterior: ${evento.pesoAnterior} kg', style: style),
        ],
      );
    } else if (evento is DietaEvento) {
      return Text('Alimento: ${evento.alimento}', style: style);
    } else if (evento is VacunacionEvento) {
      return Text(
        'Vacuna: ${evento.tipo}  ·  Lote: ${evento.lote}',
        style: style,
      );
    } else if (evento is CompraventaEvento) {
      return Text(
        'Comprador: ${evento.compradorCurp}  ·  Vendedor: ${evento.vendedorCurp}',
        style: style,
      );
    } else if (evento is DesparasitacionEvento) {
      return Text(
        'Medicamento: ${evento.medicamento}  ·  Dosis: ${evento.dosis}',
        style: style,
      );
    } else if (evento is LaboratorioEvento) {
      return Text('Tipo: ${evento.tipo}', style: style);
    } else if (evento is EnfermedadEvento) {
      return Text('Tipo: ${evento.tipo}', style: style);
    } else if (evento is TratamientoEvento) {
      // Look up the linked enfermedad event from already-loaded data
      EnfermedadEvento? linkedEnf;
      if (evento.enfermedadId != null) {
        for (final e
            in (_eventosByType[EventType.enfermedad] ?? [])
                .whereType<EnfermedadEvento>()) {
          if (e.enfermedadId == evento.enfermedadId) {
            linkedEnf = e;
            break;
          }
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medicamento: ${evento.medicamento}  ·  Dosis: ${evento.dosis}',
            style: style,
          ),
          Text('Período: ${evento.periodo}', style: style),
          if (linkedEnf != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.biotech_rounded,
                        size: 13,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Enfermedad: ${linkedEnf.tipo}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Detectada: ${DateFormat('dd/MM/yyyy').format(linkedEnf.fecha)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  if (linkedEnf.observaciones != null &&
                      linkedEnf.observaciones!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      linkedEnf.observaciones!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (evento.enfermedadId != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 13,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vinculado a enfermedad',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Supporting widgets & data classes
// ────────────────────────────────────────────────────────────────────────────

class _ParentCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Bovino? bovino;

  /// Minimal projection embedded in the child bovino's detail response.
  /// Always available even when [crossOwner] is true.
  final BovinoPublicProjection? projection;

  /// True when the full bovino record is inaccessible (cross-owner after sale).
  final bool crossOwner;
  final String bovinoId;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _ParentCard({
    required this.label,
    required this.icon,
    required this.bovino,
    required this.bovinoId,
    required this.colorScheme,
    this.projection,
    this.crossOwner = false,
    this.onTap,
  });

  String get _displayName {
    if (bovino != null) {
      return bovino!.nombre ??
          bovino!.areteBarcode ??
          bovino!.areteRfid ??
          bovino!.folio ??
          bovinoId.substring(0, 8);
    }
    if (projection != null) {
      return projection!.displayName;
    }
    return bovinoId.substring(0, 8);
  }

  String? get _subtitle {
    if (bovino != null) return bovino!.razaDominante;
    if (projection != null) return projection!.razaDominante;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool loaded = bovino != null || crossOwner;
    return InkWell(
      onTap: crossOwner ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              crossOwner
                  ? colorScheme.surfaceContainerHighest.withOpacity(0.7)
                  : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border:
              crossOwner
                  ? Border.all(color: colorScheme.outlineVariant, width: 1)
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    crossOwner
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color:
                    crossOwner
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  loaded
                      ? Text(
                        _displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              crossOwner
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                        ),
                      )
                      : Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cargando...',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  if (_subtitle != null && loaded)
                    Text(
                      _subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (crossOwner)
              Tooltip(
                message: 'Progenitor de otro propietario',
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              )
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin eventos registrados',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Usa el botón "Nuevo Evento" para agregar uno.',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EventTypeCard extends StatefulWidget {
  final EventType eventType;
  final List<Evento> eventos;
  final DateFormat dateFormat;
  final Color color;
  final IconData icon;
  final Widget Function(Evento) buildDetails;

  const _EventTypeCard({
    required this.eventType,
    required this.eventos,
    required this.dateFormat,
    required this.color,
    required this.icon,
    required this.buildDetails,
  });

  @override
  State<_EventTypeCard> createState() => _EventTypeCardState();
}

class _EventTypeCardState extends State<_EventTypeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.color.withOpacity(0.08);
    final iconBg = widget.color.withOpacity(0.14);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ── Category header row ───────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, size: 22, color: widget.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.eventType.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: widget.color.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            '${widget.eventos.length} '
                            '${widget.eventos.length == 1 ? 'evento' : 'eventos'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.color.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.color.withOpacity(0.7),
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded event list ───────────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildEventList(),
              crossFadeState:
                  _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList() {
    return Column(
      children:
          widget.eventos.asMap().entries.map((entry) {
            final int idx = entry.key;
            final Evento evento = entry.value;
            final bool isLast = idx == widget.eventos.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timeline column
                  SizedBox(
                    width: 52,
                    child: Column(
                      children: [
                        // dot
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 14),
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        // line
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: widget.color.withOpacity(0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: 12,
                        top: 8,
                        bottom: isLast ? 16 : 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.dateFormat.format(evento.fecha),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: widget.color,
                                ),
                              ),
                            ],
                          ),
                          widget.buildDetails(evento),
                          if (evento.observaciones != null &&
                              evento.observaciones!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              evento.observaciones!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _InfoCardData {
  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  _InfoCardData({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// Nariz photo card — shown in identification section when nariz_url is present
// ────────────────────────────────────────────────────────────────────────────

class _NarizPhotoCard extends StatelessWidget {
  final String narizUrl;
  final ColorScheme colorScheme;

  const _NarizPhotoCard({required this.narizUrl, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: Container(
        height: 180,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              narizUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value:
                        progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder:
                  (_, __, ___) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No se pudo cargar la imagen',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
            // Label overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fingerprint, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Foto Biom\u00e9trica \u2014 toca para ampliar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: const Text('Foto Biom\u00e9trica'),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(
                    narizUrl,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
