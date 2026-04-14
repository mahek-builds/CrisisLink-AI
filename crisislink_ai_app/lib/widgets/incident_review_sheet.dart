import 'package:flutter/material.dart';

import '../services/sos_api_service.dart';
import '../theme/app_theme.dart';

class IncidentReviewSheet extends StatelessWidget {
  const IncidentReviewSheet({
    super.key,
    required this.sosApiService,
    required this.incident,
  });

  final SosApiService sosApiService;
  final IncidentSummary incident;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: FutureBuilder<_IncidentReviewData>(
          future: _loadReviewData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentRed),
              );
            }

            if (snapshot.hasError) {
              return _ReviewState(
                title: 'Unable to load incident details',
                description: snapshot.error is SosApiException
                    ? (snapshot.error! as SosApiException).message
                    : 'Please try again in a moment.',
              );
            }

            final data = snapshot.data!;
            final analysis = data.analysis;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A5E69),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Incident ${incident.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _Badge(
                        label: incident.priority,
                        color: _priorityColor(incident.priority),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_prettyType(incident.type)} | ${_prettyStatus(incident.status)} | ${incident.reporterCount} reporter(s)',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Panel(
                    title: 'Coordinates',
                    child: Text(
                      'Lat ${incident.latitude.toStringAsFixed(5)} | Lng ${incident.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Reports',
                    child: data.details.reports.isEmpty
                        ? const Text(
                            'No report records were returned for this incident yet.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          )
                        : Column(
                            children: data.details.reports
                                .map(
                                  (report) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.fiber_manual_record,
                                          size: 10,
                                          color: AppTheme.accentRed,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${report.reportType} from ${report.phoneNumber}${report.createdAt == null ? '' : ' at ${_formatDateTime(report.createdAt!)}'}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'AI Analysis',
                    child: analysis == null
                        ? const Text(
                            'AI analysis is not available for this incident yet.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _MiniStat(
                                    label: 'Priority',
                                    value: analysis.predictedPriority,
                                  ),
                                  _MiniStat(
                                    label: 'Units',
                                    value: analysis.requiredUnits.toString(),
                                  ),
                                  _MiniStat(
                                    label: 'Team',
                                    value: analysis.teamType,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                analysis.actionPlan,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                analysis.isSuspicious
                                    ? 'Fraud check flagged this incident: ${analysis.fraudReason}'
                                    : 'Fraud check: clear',
                                style: TextStyle(
                                  color: analysis.isSuspicious
                                      ? const Color(0xFFFFB454)
                                      : AppTheme.success,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (analysis.equipment.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: analysis.equipment
                                      .map((item) => _Badge(
                                            label: item,
                                            color: const Color(0xFF2D4C9D),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<_IncidentReviewData> _loadReviewData() async {
    final details = await sosApiService.fetchIncidentDetails(incident.id);

    IncidentAnalysis? analysis;
    try {
      analysis = await sosApiService.analyzeIncident(incident.id);
    } on SosApiException catch (error) {
      if (error.statusCode != 400) {
        rethrow;
      }
    }

    return _IncidentReviewData(
      details: details,
      analysis: analysis,
    );
  }
}

class _IncidentReviewData {
  const _IncidentReviewData({
    required this.details,
    required this.analysis,
  });

  final IncidentDetailsResponse details;
  final IncidentAnalysis? analysis;
}

class _ReviewState extends StatelessWidget {
  const _ReviewState({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12161D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
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
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month ${local.year} $hour:$minute';
}

Color _priorityColor(String priority) {
  switch (priority.toUpperCase()) {
    case 'CRITICAL':
      return const Color(0xFFFF5A5A);
    case 'HIGH':
      return const Color(0xFFFF9A3D);
    case 'MEDIUM':
      return const Color(0xFF4B92FF);
    default:
      return AppTheme.success;
  }
}

String _prettyType(String type) {
  switch (type.toLowerCase()) {
    case 'med':
    case 'medical':
      return 'Medical';
    case 'police':
      return 'Police';
    case 'fire':
      return 'Fire';
    default:
      return type;
  }
}

String _prettyStatus(String status) {
  switch (status.toLowerCase()) {
    case 'in-progress':
      return 'In Progress';
    case 'resolved':
      return 'Resolved';
    default:
      return 'Active';
  }
}
