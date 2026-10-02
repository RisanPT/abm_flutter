import 'dart:io';

import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/backup/data/backup_repository.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// IT-Admin data backup: exports every collection as one JSON file, and runs
/// automatically once a month (when this month's backup hasn't been taken yet).
class DataBackupScreen extends ConsumerStatefulWidget {
  const DataBackupScreen({super.key});

  @override
  ConsumerState<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends ConsumerState<DataBackupScreen> {
  bool _busy = false;
  bool _autoChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoBackup());
  }

  // Monthly-automatic: the first time an IT Admin opens this screen in a new
  // month, the backup downloads on its own.
  Future<void> _maybeAutoBackup() async {
    if (_autoChecked) return;
    _autoChecked = true;
    try {
      final status = await ref.read(backupRepositoryProvider).getStatus();
      if (mounted && status.needsMonthlyBackup) {
        await _runBackup(auto: true);
      }
    } catch (_) {
      // Silent — the manual button and status card still work.
    }
  }

  Future<void> _runBackup({bool auto = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final successColor = context.colors.green;
    try {
      final repo = ref.read(backupRepositoryProvider);
      final overview = await repo.getSchemas();
      final json = await repo.exportAllJson();

      final month = DateFormat('MMMM_yyyy').format(DateTime.now());
      final fname = 'madrasa_backup_$month.json';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fname');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: fname)],
        subject: 'Anas Bin Malik Madrasa — data backup ($month)',
      );

      await repo.markMonthly(records: overview.totalRecords, collections: overview.schemas.length);
      ref.invalidate(backupStatusProvider);

      messenger.showSnackBar(SnackBar(
        content: Text(auto
            ? 'Monthly backup ready — ${overview.totalRecords} records across ${overview.schemas.length} collections.'
            : 'Backup ready — ${overview.totalRecords} records across ${overview.schemas.length} collections.'),
        backgroundColor: successColor,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusAsync = ref.watch(backupStatusProvider);
    final schemasAsync = ref.watch(backupSchemasProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: ListView(
        children: [
          ABMPageHeader(
            title: 'Data Backup',
            subtitle: 'Export every record as JSON · runs automatically each month',
            height: context.isMobile ? 170 : 190,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                statusAsync.when(
                  data: (s) => _StatusCard(status: s),
                  loading: () => const _StatusSkeleton(),
                  error: (e, _) => AbmErrorView(
                    message: friendlyErrorMessage(e),
                    onRetry: () => ref.invalidate(backupStatusProvider),
                  ),
                ),
                const Gap(16),
                ABMButton(
                  text: _busy ? 'Preparing backup…' : 'Download full backup (JSON)',
                  icon: LucideIcons.download,
                  isLoading: _busy,
                  onPressed: () => _runBackup(),
                ),
                const Gap(8),
                Text(
                  'The backup is a single JSON file containing every collection. '
                  'Save it somewhere safe (Files, Drive, email).',
                  style: context.typography.bodySmall.copyWith(color: colors.textSecondary),
                ),
                const Gap(24),
                Text('What gets backed up', style: context.typography.h4),
                const Gap(12),
                schemasAsync.when(
                  data: (o) => _SchemaList(overview: o),
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                  error: (e, _) => AbmErrorView(
                    message: friendlyErrorMessage(e),
                    onRetry: () => ref.invalidate(backupSchemasProvider),
                  ),
                ),
                const Gap(32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final BackupStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final due = status.needsMonthlyBackup;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.databaseBackup, color: colors.primary, size: 22),
              const Gap(10),
              Expanded(child: Text('This month · ${status.currentMonth}', style: t.bodyLargeSemiBold)),
              AbmStatusPill(
                label: due ? 'Backup due' : 'Backed up',
                color: due ? colors.warning : colors.green,
                icon: due ? LucideIcons.clock : LucideIcons.check,
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Icon(LucideIcons.history, size: 15, color: colors.textSecondary),
              const Gap(8),
              Expanded(
                child: Text(
                  status.lastMonth == null
                      ? 'No previous backup on record.'
                      : 'Last backup: ${status.lastMonth}'
                          '${status.lastAt != null ? ' · ${DateFormat('dd MMM, h:mm a').format(status.lastAt!.toLocal())}' : ''}'
                          '${status.lastRecords > 0 ? ' · ${status.lastRecords} records' : ''}',
                  style: t.bodySmall.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SchemaList extends StatelessWidget {
  const _SchemaList({required this.overview});
  final BackupOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Group schemas by category.
    final byCategory = <String, List<BackupSchemaInfo>>{};
    for (final s in overview.schemas) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${overview.totalRecords} records · ${overview.schemas.length} collections',
            style: context.typography.bodyMediumSemiBold.copyWith(color: colors.primary)),
        const Gap(12),
        for (final entry in byCategory.entries) ...[
          AbmSectionCard(
            title: entry.key,
            icon: LucideIcons.folder,
            child: Column(
              children: [
                for (final s in entry.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(s.name, style: context.typography.bodyMedium)),
                        Text('${s.count}',
                            style: context.typography.bodyMediumSemiBold.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),
        ],
      ],
    );
  }
}

class _StatusSkeleton extends StatelessWidget {
  const _StatusSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        height: 96,
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
}
