import 'package:flutter/material.dart';

import '../services/sos_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/incident_review_sheet.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.sosApiService,
  });

  final SosApiService sosApiService;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminStats? _stats;
  List<IncidentSummary> _incidents = const [];
  bool _isLoading = true;
  String? _error;
  String? _resolvingIncidentId;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await widget.sosApiService.fetchAdminStats();
      final incidents = await widget.sosApiService.fetchLiveIncidents();

      if (!mounted) {
        return;
      }

      setState(() {
        _stats = stats;
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
        _error = 'Unable to load the admin dashboard right now.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveIncident(IncidentSummary incident) async {
    setState(() {
      _resolvingIncidentId = incident.id;
    });

    try {
      final result = await widget.sosApiService.resolveIncident(incident.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));

      await _loadDashboard();
    } on SosApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resolvingIncidentId = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _resolvingIncidentId = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to resolve this incident.')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1118),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.accentRed,
            onRefresh: _loadDashboard,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      label: const Text('Back'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadDashboard,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Admin Control Room',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Live backend data from the emergency operations API.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading && _stats == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.accentRed),
                    ),
                  )
                else if (_error != null)
                  _MessageCard(
                    title: 'Dashboard unavailable',
                    message: _error!,
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Active',
                          value: '${_stats?.active ?? 0}',
                          color: const Color(0xFFFF7A7A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Working',
                          value: '${_stats?.working ?? 0}',
                          color: const Color(0xFF57A2FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Resolved',
                          value: '${_stats?.resolved ?? 0}',
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Live Incidents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_incidents.isEmpty)
                    const _MessageCard(
                      title: 'No unresolved incidents',
                      message: 'The live incident queue is currently clear.',
                    )
                  else
                    ..._incidents.map(
                      (incident) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _IncidentCard(
                          incident: incident,
                          actionLabel: 'Resolve',
                          actionBusy: _resolvingIncidentId == incident.id,
                          actionColor: AppTheme.accentRed,
                          onReview: () => _openIncidentReview(incident),
                          onAction: () => _resolveIncident(incident),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.actionLabel,
    required this.actionBusy,
    required this.actionColor,
    required this.onReview,
    required this.onAction,
  });

  final IncidentSummary incident;
  final String actionLabel;
  final bool actionBusy;
  final Color actionColor;
  final VoidCallback onReview;
  final VoidCallback onAction;

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
              _Pill(
                label: incident.priority,
                color: _incidentPriorityColor(incident.priority),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${incident.reporterCount} reporter(s) | ${_displayStatus(incident.status)}',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lat ${incident.latitude.toStringAsFixed(5)} | Lng ${incident.longitude.toStringAsFixed(5)}',
            style: const TextStyle(
              color: Color(0xFFD8D4DD),
              fontSize: 14,
            ),
          ),
          if (incident.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Created ${_compactDate(incident.createdAt!)}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
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
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Review'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: actionBusy ? null : onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: actionColor,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: actionBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
  });

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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.message,
  });

  final String title;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

Color _incidentPriorityColor(String priority) {
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

String _displayStatus(String status) {
  switch (status) {
    case 'in-progress':
      return 'In Progress';
    case 'resolved':
      return 'Resolved';
    default:
      return 'Active';
  }
}

String _compactDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month ${local.year} $hour:$minute';
}
