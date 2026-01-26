import 'package:flutter/material.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/models/evento.dart';
import 'package:union_ganadera_app/screens/events/register_event_screen.dart';
import 'package:union_ganadera_app/screens/cattle/edit_cattle_screen.dart';
import 'package:union_ganadera_app/services/api_client.dart';
import 'package:union_ganadera_app/services/evento_service.dart';
import 'package:intl/intl.dart';

class CattleDetailScreen extends StatefulWidget {
  final Bovino bovino;

  const CattleDetailScreen({super.key, required this.bovino});

  @override
  State<CattleDetailScreen> createState() => _CattleDetailScreenState();
}

class _CattleDetailScreenState extends State<CattleDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  late final EventoService _eventoService;
  Map<EventType, List<Evento>> _eventosByType = {};
  Set<EventType> _expandedTypes = {};
  bool _isLoadingEventos = true;

  @override
  void initState() {
    super.initState();
    _eventoService = EventoService(_apiClient);
    _loadEventos();
  }

  Future<void> _loadEventos() async {
    setState(() => _isLoadingEventos = true);
    try {
      // Load events for each type
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
          // Skip types that have no events or error
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
      if (mounted) {
        setState(() => _isLoadingEventos = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bovino.areteBarcode ?? 'Detalle del Ganado'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditCattleScreen(bovino: widget.bovino),
            ),
          );
          if (result == true) {
            // Reload the bovino data if edit was successful
            // For now, just pop back to refresh from the list
            if (!mounted) return;
            Navigator.pop(context);
          }
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade700, Colors.green.shade500],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    widget.bovino.sexo == 'M' ? Icons.male : Icons.female,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.bovino.nombre ??
                        widget.bovino.areteBarcode ??
                        widget.bovino.areteRfid ??
                        'Sin identificación',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.bovino.razaDominante != null)
                    Text(
                      widget.bovino.razaDominante!,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.bovino.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Information Grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Identificación',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoGrid([
                    if (widget.bovino.areteBarcode != null)
                      _InfoGridItem(
                        icon: Icons.qr_code,
                        label: 'Arete Barcode',
                        value: widget.bovino.areteBarcode!,
                      ),
                    if (widget.bovino.areteRfid != null)
                      _InfoGridItem(
                        icon: Icons.nfc,
                        label: 'Arete RFID',
                        value: widget.bovino.areteRfid!,
                      ),
                  ]),
                  const SizedBox(height: 24),
                  const Text(
                    'Información General',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoGrid([
                    _InfoGridItem(
                      icon:
                          widget.bovino.sexo == 'M' ? Icons.male : Icons.female,
                      label: 'Sexo',
                      value: widget.bovino.sexo == 'M' ? 'Macho' : 'Hembra',
                    ),
                    if (widget.bovino.fechaNac != null)
                      _InfoGridItem(
                        icon: Icons.cake,
                        label: 'Fecha Nacimiento',
                        value: dateFormat.format(widget.bovino.fechaNac!),
                      ),
                    if (widget.bovino.proposito != null)
                      _InfoGridItem(
                        icon: Icons.work_outline,
                        label: 'Propósito',
                        value: widget.bovino.proposito!,
                      ),
                  ]),
                  const SizedBox(height: 24),
                  const Text(
                    'Datos de Peso',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoGrid([
                    if (widget.bovino.pesoNac != null)
                      _InfoGridItem(
                        icon: Icons.baby_changing_station,
                        label: 'Peso Nacimiento',
                        value: '${widget.bovino.pesoNac} kg',
                      ),
                    if (widget.bovino.pesoActual != null)
                      _InfoGridItem(
                        icon: Icons.monitor_weight,
                        label: 'Peso Actual',
                        value: '${widget.bovino.pesoActual} kg',
                        highlighted: true,
                      ),
                  ]),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Historial de Eventos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
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
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo Evento'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingEventos)
                    const Center(child: CircularProgressIndicator())
                  else if (_eventosByType.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No hay eventos registrados'),
                      ),
                    )
                  else
                    ..._eventosByType.entries.map((entry) {
                      final eventType = entry.key;
                      final eventos = entry.value;
                      final isExpanded = _expandedTypes.contains(eventType);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                _getEventIcon(eventType),
                                color: Colors.green.shade700,
                              ),
                              title: Text(
                                eventType.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('${eventos.length} eventos'),
                              trailing: IconButton(
                                icon: Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedTypes.remove(eventType);
                                    } else {
                                      _expandedTypes.add(eventType);
                                    }
                                  });
                                },
                              ),
                            ),
                            if (isExpanded)
                              ...eventos.map((evento) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.only(
                                    left: 72,
                                    right: 16,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  title: Text(
                                    dateFormat.format(evento.fecha),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (evento.observaciones != null &&
                                          evento.observaciones!.isNotEmpty)
                                        Text(evento.observaciones!),
                                      _buildEventDetails(evento),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.peso:
        return Icons.monitor_weight;
      case EventType.dieta:
        return Icons.restaurant;
      case EventType.vacunacion:
        return Icons.vaccines;
      case EventType.desparasitacion:
        return Icons.medication;
      case EventType.laboratorio:
        return Icons.science;
      case EventType.compraventa:
        return Icons.sell;
      case EventType.traslado:
        return Icons.local_shipping;
      case EventType.enfermedad:
        return Icons.sick;
      case EventType.tratamiento:
        return Icons.healing;
    }
  }

  Widget _buildEventDetails(Evento evento) {
    if (evento is PesoEvento) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peso Nuevo: ${evento.pesoNuevo} kg',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (evento.pesoAnterior != null)
            Text(
              'Peso Anterior: ${evento.pesoAnterior} kg',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      );
    } else if (evento is DietaEvento) {
      return Text(
        'Alimento: ${evento.alimento}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (evento is VacunacionEvento) {
      return Text(
        'Tipo: ${evento.tipo} | Lote: ${evento.lote}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (evento is CompraventaEvento) {
      return Text(
        'Comprador: ${evento.compradorCurp} | Vendedor: ${evento.vendedorCurp}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (evento is DesparasitacionEvento) {
      return Text(
        'Medicamento: ${evento.medicamento} | Dosis: ${evento.dosis}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (evento is LaboratorioEvento) {
      return Text(
        'Tipo: ${evento.tipo}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (evento is EnfermedadEvento) {
      return Text(
        'Tipo: ${evento.tipo}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else if (evento is TratamientoEvento) {
      return Text(
        'Medicamento: ${evento.medicamento} | Per\u00edodo: ${evento.periodo}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInfoGrid(List<_InfoGridItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children:
          items.map((item) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    item.highlighted
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      item.highlighted
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                  width: item.highlighted ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 18,
                        color:
                            item.highlighted
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          item.highlighted
                              ? Colors.green.shade700
                              : Colors.grey.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _InfoGridItem {
  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  _InfoGridItem({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });
}
