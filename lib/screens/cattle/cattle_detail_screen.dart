import 'package:flutter/material.dart';
import 'package:union_ganadera_app/models/bovino.dart';
import 'package:union_ganadera_app/models/evento.dart';
import 'package:union_ganadera_app/screens/events/register_event_screen.dart';
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.green.shade50,
              child: Column(
                children: [
                  Icon(
                    widget.bovino.sexo == 'M' ? Icons.male : Icons.female,
                    size: 80,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.bovino.areteBarcode ?? widget.bovino.areteRfid ?? 'Sin identificación',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.bovino.razaDominante != null)
                    Text(
                      widget.bovino.razaDominante!,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información General',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Arete Barcode', widget.bovino.areteBarcode),
                  _buildInfoRow('Arete RFID', widget.bovino.areteRfid),
                  _buildInfoRow('Sexo', widget.bovino.sexo == 'M' ? 'Macho' : 'Hembra'),
                  _buildInfoRow('Fecha de Nacimiento',
                    widget.bovino.fechaNac != null
                      ? dateFormat.format(widget.bovino.fechaNac!)
                      : null),
                  _buildInfoRow('Peso Nacimiento',
                    widget.bovino.pesoNac != null
                      ? '${widget.bovino.pesoNac} kg'
                      : null),
                  _buildInfoRow('Peso Actual',
                    widget.bovino.pesoActual != null
                      ? '${widget.bovino.pesoActual} kg'
                      : null),
                  _buildInfoRow('Propósito', widget.bovino.proposito),
                  _buildInfoRow('Estado', widget.bovino.status),
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
                              builder: (_) => RegisterEventScreen(
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
      return Text(
        'Peso: ${evento.pesoNuevo} kg',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
