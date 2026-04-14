import 'package:flutter/material.dart';

import '../services/sos_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/incident_review_sheet.dart';

class ResponderDashboardPage extends StatefulWidget {
  const ResponderDashboardPage({
    super.key,
    required this.sosApiService,
    this.initialResponderId = '',
  });

  final SosApiService sosApiService;
  final String initialResponderId;

  @override
  State<ResponderDashboardPage> createState() => _ResponderDashboardPageState();
}

class _ResponderDashboardPageState extends State<ResponderDashboardPage> {
  late final TextEditingController _responderIdController;
  List<IncidentSummary> _incidents = const [];
  bool _isLoading = true;
  String? _error;
  String? _assigningIncidentId;
  bool _isReleasing = false;

  @override
  void initState() {
    super.initState();
    _responderIdController = TextEditingController(
      text: widget.initialResponderId,
    );
    _loadIncidents();
  }

  @override
  void dispose() {
    _responderIdController.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final incidents = await widget.sosApiService.fetchActiveIncidents();

      if (!mounted) {
        return;
      }

      setState(() {
        _incidents = incidents;
        _isLoading = false;
      });
    } on SosApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Unable to load active incidents right now.';
        _isLoading = false;
      });
    }
  }

  Future<void> _assignToIncident(IncidentSummary incident) async {
    final responderId = _responderIdController.text.trim();
    if (responderId.isEmpty) {
      _showSnackBar('Enter a responder ID before assigning yourself.');
      return;
    }

    setState(() {
      _assigningIncidentId = incident.id;
    });

    try {
      final result = await widget.sosApiService.assignResponder(
        responderId: responderId,
        incidentId: incident.id,
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Responder ${result.responderId} assigned to incident ${incident.id.substring(0, 8)}.',
      );
      await _loadIncidents();
    } on SosApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _assigningIncidentId = null;
      });
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _assigningIncidentId = null;
      });
      _showSnackBar('Unable to assign this responder right now.');
    }
  }

  Future<void> _releaseResponder() async {
    final responderId = _responderIdController.text.trim();
    if (responderId.isEmpty) {
      _showSnackBar('Enter a responder ID before releasing the unit.');
      return;
    }

    setState(() {
      _isReleasing = true;
    });

    try {
      final result = await widget.sosApiService.releaseResponder(responderId);

      if (!mounted) {
        return;
      }

      _showSnackBar('Responder ${result.responderId} is now available again.');
      await _loadIncidents();
    } on SosApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isReleasing = false;
      });
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isReleasing = false;
      });
      _showSnackBar('Unable to release this responder right now.');
    }
  }

  Future<void> _openIncidentReview(IncidentSummary incident) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF0C1016),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: IncidentReviewSheet(
          sosApiService: widget.sosApiService,
          incident: incident,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF101521), AppTheme.background],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.accentRed,
            onRefresh: _loadIncidents,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                      label: const Text('Back'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadIncidents,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Responder Dispatch',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use a live responder ID to claim or release incidents from the backend.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121821),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Responder ID',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _responderIdController,
                        decoration: const InputDecoration(
                          hintText: 'Enter live responder ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: _isReleasing ? null : _releaseResponder,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: _isReleasing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Release Responder'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Active Incidents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (_isLoading && _incidents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentRed,
                      ),
                    ),
                  )
                else if (_error != null)
                  _ResponderMessageCard(message: _error!)
                else if (_incidents.isEmpty)
                  const _ResponderMessageCard(
                    message:
                        'No active incidents are waiting for assignment right now.',
                  )
                else
                  ..._incidents.map(
                    (incident) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ResponderIncidentCard(
                        incident: incident,
                        busy: _assigningIncidentId == incident.id,
                        onReview: () => _openIncidentReview(incident),
                        onAssign: () => _assignToIncident(incident),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponderIncidentCard extends StatelessWidget {
  const _ResponderIncidentCard({
    required this.incident,
    required this.busy,
    required this.onReview,
    required this.onAssign,
  });

  final IncidentSummary incident;
  final bool busy;
  final VoidCallback onReview;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${incident.type.toUpperCase()} | ${incident.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ResponderPill(
                label: incident.priority,
                color: _responderPriorityColor(incident.priority),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${incident.reporterCount} reporter(s)',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Lat ${incident.latitude.toStringAsFixed(5)} | Lng ${incident.longitude.toStringAsFixed(5)}',
            style: const TextStyle(color: Color(0xFFD8D4DD), fontSize: 14),
          ),
          if (incident.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reported ${_responderDate(incident.createdAt!)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Inspect'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAssign,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Assign Me'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponderMessageCard extends StatelessWidget {
  const _ResponderMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

class _ResponderPill extends StatelessWidget {
  const _ResponderPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _responderPriorityColor(String priority) {
  switch (priority.toUpperCase()) {
    case 'CRITICAL':
      return const Color(0xFFFF5A5A);
    case 'HIGH':
      return const Color(0xFFFFA13D);
    case 'MEDIUM':
      return const Color(0xFF4F8FFF);
    default:
      return AppTheme.success;
  }
}

String _responderDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month ${local.year} $hour:$minute';
}
