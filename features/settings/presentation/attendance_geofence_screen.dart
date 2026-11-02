import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/timetable/data/planner_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Admin: location-restricted teacher attendance. Teachers can only mark their
/// self check-in when inside the perimeter set here.
class AttendanceGeofenceScreen extends ConsumerStatefulWidget {
  const AttendanceGeofenceScreen({super.key});

  @override
  ConsumerState<AttendanceGeofenceScreen> createState() => _AttendanceGeofenceScreenState();
}

class _AttendanceGeofenceScreenState extends ConsumerState<AttendanceGeofenceScreen> {
  final _mapsCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController(text: '200');
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  double? _lat, _lng;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mapsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final id = ref.read(selectedInstituteProvider).id;
      final cfg = await ref.read(plannerRepositoryProvider).getAttendanceGeofence(id);
      if (!mounted) return;
      setState(() {
        _enabled = cfg['enabled'] == true;
        _lat = (cfg['latitude'] as num?)?.toDouble();
        _lng = (cfg['longitude'] as num?)?.toDouble();
        _radiusCtrl.text = '${(cfg['radiusMeters'] as num?)?.toInt() ?? 200}';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: error ? Colors.red.shade600 : null),
      );

  Future<void> _save() async {
    final radius = int.tryParse(_radiusCtrl.text.trim());
    final manualLat = double.tryParse(_latCtrl.text.trim());
    final manualLng = double.tryParse(_lngCtrl.text.trim());
    final link = _mapsCtrl.text.trim();

    setState(() => _saving = true);
    try {
      final id = ref.read(selectedInstituteProvider).id;
      final res = await ref.read(plannerRepositoryProvider).setAttendanceGeofence(
            id,
            enabled: _enabled,
            latitude: manualLat,
            longitude: manualLng,
            radiusMeters: radius,
            mapsLink: link.isEmpty ? null : link,
          );
      if (!mounted) return;
      setState(() {
        _lat = (res['latitude'] as num?)?.toDouble();
        _lng = (res['longitude'] as num?)?.toDouble();
        _enabled = res['enabled'] == true;
        _radiusCtrl.text = '${(res['radiusMeters'] as num?)?.toInt() ?? 200}';
        _mapsCtrl.clear();
        _latCtrl.clear();
        _lngCtrl.clear();
        _saving = false;
      });
      _snack('Attendance location saved');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack(friendlyErrorMessage(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = context.typography;
    final hasLocation = _lat != null && _lng != null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Attendance Location')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 18, color: colors.primary),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          'When on, teachers can only mark their attendance while inside the perimeter you set here.',
                          style: t.bodySmall.copyWith(color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                SwitchListTile(
                  value: _enabled,
                  onChanged: _saving ? null : (v) => setState(() => _enabled = v),
                  contentPadding: EdgeInsets.zero,
                  title: Text('Restrict attendance to the madrasa location',
                      style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasLocation ? colors.green.withValues(alpha: 0.08) : colors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(hasLocation ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                          size: 16, color: hasLocation ? colors.green : colors.warning),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          hasLocation
                              ? 'Location set: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}'
                              : 'No location set yet — paste a Google Maps link or enter coordinates below.',
                          style: t.bodySmall.copyWith(color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                Text('Set the location', style: t.bodyMediumSemiBold.copyWith(color: colors.textPrimary)),
                const Gap(10),
                TextField(
                  controller: _mapsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Google Maps link',
                    hintText: 'https://maps.app.goo.gl/…',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: const Icon(LucideIcons.link, size: 18),
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.clipboard, size: 18),
                      tooltip: 'Paste',
                      onPressed: () async {
                        final d = await Clipboard.getData(Clipboard.kTextPlain);
                        if (d?.text != null) setState(() => _mapsCtrl.text = d!.text!.trim());
                      },
                    ),
                  ),
                ),
                const Gap(6),
                Text('Paste the location the office shared on Google Maps; we read its coordinates automatically.',
                    style: t.bodySmall.copyWith(color: colors.textSecondary)),
                const Gap(14),
                Row(
                  children: [
                    Expanded(child: Divider(color: colors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or enter manually', style: t.bodySmall.copyWith(color: colors.textSecondary)),
                    ),
                    Expanded(child: Divider(color: colors.border)),
                  ],
                ),
                const Gap(14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: TextField(
                        controller: _lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                TextField(
                  controller: _radiusCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Allowed radius (metres)',
                    helperText: 'How far from the point a teacher may be (20–5000 m).',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(LucideIcons.circleDot, size: 18),
                  ),
                ),
                const Gap(24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.save, size: 18),
                    label: Text(_saving ? 'Saving…' : 'Save'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
    );
  }
}
