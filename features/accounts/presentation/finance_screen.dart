import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/accounts/data/finance_repository.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:abm_madrasa/features/accounts/presentation/finance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? selectedStudentId;
  bool _processingPayment = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final summariesAsync = ref.watch(accountSummariesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: summariesAsync.when(
        data: (summaries) {
          final filtered = summaries.where((summary) {
            final query = _query.trim().toLowerCase();
            if (query.isEmpty) return true;
            return summary.fullName.toLowerCase().contains(query) ||
                summary.admissionNumber.toLowerCase().contains(query);
          }).toList();

          selectedStudentId ??= filtered.isNotEmpty ? filtered.first.studentId : null;
          if (selectedStudentId != null &&
              !filtered.any((item) => item.studentId == selectedStudentId)) {
            selectedStudentId = filtered.isNotEmpty ? filtered.first.studentId : null;
          }

          return Row(
            children: [
              if (!context.isMobile)
                SizedBox(
                  width: 360,
                  child: _buildSidebar(context, filtered),
                ),
              Expanded(
                child: selectedStudentId == null
                    ? _buildEmptyState(context)
                    : _AccountDetailsPanel(
                        studentId: selectedStudentId!,
                        processingPayment: _processingPayment,
                        onProcessPayment: _handlePayment,
                        onBack: () => setState(() => selectedStudentId = null),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: context.isMobile
          ? FloatingActionButton(
              onPressed: () => _showStudentSelector(context),
              backgroundColor: colors.primary,
              child: const Icon(LucideIcons.users, color: Colors.white),
            )
          : null,
    );
  }

  Future<void> _handlePayment(String studentId, double amount) async {
    setState(() => _processingPayment = true);
    try {
      await ref.read(accountRepositoryProvider).processPayment(
            studentId: studentId,
            amount: amount,
          );
      ref.invalidate(accountSummariesProvider);
      ref.invalidate(studentAccountDetailsProvider(studentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment processed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingPayment = false);
    }
  }

  Widget _buildSidebar(BuildContext context, List<AccountSummary> summaries) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Accounts', style: typography.h3.copyWith(color: colors.primary)),
                const Gap(16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  style: typography.bodyMedium.copyWith(color: const Color(0xFF163D32)),
                  decoration: InputDecoration(
                    hintText: 'Search student by name or ID...',
                    hintStyle: typography.bodyMedium.copyWith(color: const Color(0xFF77817C)),
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    filled: true,
                    fillColor: colors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                final isSelected = summary.studentId == selectedStudentId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => setState(() => selectedStudentId = summary.studentId),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary.withValues(alpha: 0.08) : colors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? colors.primary.withValues(alpha: 0.22) : colors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFDCE7E0),
                            backgroundImage: summary.photoUrl != null && summary.photoUrl!.isNotEmpty
                                ? NetworkImage(summary.photoUrl!)
                                : null,
                            child: summary.photoUrl == null || summary.photoUrl!.isEmpty
                                ? Text(
                                    summary.fullName[0].toUpperCase(),
                                    style: typography.bodyMediumSemiBold.copyWith(color: const Color(0xFF163D32)),
                                  )
                                : null,
                          ),
                          const Gap(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  summary.fullName,
                                  style: typography.bodyMediumSemiBold.copyWith(
                                    color: const Color(0xFF163D32),
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  '${summary.classroom} • ${summary.admissionNumber}',
                                  style: typography.bodySmall.copyWith(color: const Color(0xFF6F7A75)),
                                ),
                              ],
                            ),
                          ),
                          _StatusChip(status: summary.status),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.indianRupee, size: 64, color: colors.textSecondary.withValues(alpha: 0.3)),
          const Gap(16),
          Text(
            'Select a student to manage accounts',
            style: context.typography.bodyLargeMedium.copyWith(color: const Color(0xFF6F7A75)),
          ),
        ],
      ),
    );
  }

  void _showStudentSelector(BuildContext context) {
    final summariesAsync = ref.read(accountSummariesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: summariesAsync.when(
          data: (summaries) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: summary.photoUrl != null && summary.photoUrl!.isNotEmpty
                      ? NetworkImage(summary.photoUrl!)
                      : null,
                  child: summary.photoUrl == null || summary.photoUrl!.isEmpty
                      ? Text(summary.fullName[0].toUpperCase())
                      : null,
                ),
                title: Text(summary.fullName),
                subtitle: Text(summary.admissionNumber),
                trailing: _StatusChip(status: summary.status),
                onTap: () {
                  setState(() => selectedStudentId = summary.studentId);
                  Navigator.pop(context);
                },
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _AccountDetailsPanel extends ConsumerStatefulWidget {
  const _AccountDetailsPanel({
    required this.studentId,
    required this.processingPayment,
    required this.onProcessPayment,
    required this.onBack,
  });

  final String studentId;
  final bool processingPayment;
  final Future<void> Function(String studentId, double amount) onProcessPayment;
  final VoidCallback onBack;

  @override
  ConsumerState<_AccountDetailsPanel> createState() => _AccountDetailsPanelState();
}

class _AccountDetailsPanelState extends ConsumerState<_AccountDetailsPanel> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(studentAccountDetailsProvider(widget.studentId));

    return detailsAsync.when(
      data: (details) {
        _amountController.text = details.balance.toStringAsFixed(0);
        final typography = context.typography;
        final colors = context.colors;

        return SingleChildScrollView(
          padding: EdgeInsets.all(context.isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (context.isMobile)
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: widget.onBack,
                    ),
                  Text('Fee Collection', style: typography.h2.copyWith(color: colors.primary)),
                ],
              ),
              const Gap(24),
              _StudentAccountHeader(details: details),
              const Gap(24),
              if (context.isMobile)
                Column(
                  children: [
                    _CurrentDueCard(details: details, amountController: _amountController, processingPayment: widget.processingPayment, onProcessPayment: widget.onProcessPayment),
                    const Gap(16),
                    _HistoryCard(details: details),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _CurrentDueCard(
                        details: details,
                        amountController: _amountController,
                        processingPayment: widget.processingPayment,
                        onProcessPayment: widget.onProcessPayment,
                      ),
                    ),
                    const Gap(20),
                    Expanded(
                      flex: 4,
                      child: _HistoryCard(details: details),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _StudentAccountHeader extends StatelessWidget {
  const _StudentAccountHeader({required this.details});
  final StudentAccountDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFDCE7E0),
            backgroundImage: details.summary.photoUrl != null && details.summary.photoUrl!.isNotEmpty
                ? NetworkImage(details.summary.photoUrl!)
                : null,
            child: details.summary.photoUrl == null || details.summary.photoUrl!.isEmpty
                ? Text(
                    details.summary.fullName[0].toUpperCase(),
                    style: typography.h3.copyWith(color: const Color(0xFF163D32)),
                  )
                : null,
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(details.summary.fullName, style: typography.h3.copyWith(color: const Color(0xFF163D32))),
                const Gap(4),
                Text(
                  '${details.summary.admissionNumber} • ${details.summary.classroom} • Guardian: ${details.summary.guardianName}',
                  style: typography.bodyMedium.copyWith(color: const Color(0xFF6F7A75)),
                ),
              ],
            ),
          ),
          _StatusChip(status: details.status),
        ],
      ),
    );
  }
}

class _CurrentDueCard extends StatelessWidget {
  const _CurrentDueCard({
    required this.details,
    required this.amountController,
    required this.processingPayment,
    required this.onProcessPayment,
  });

  final StudentAccountDetails details;
  final TextEditingController amountController;
  final bool processingPayment;
  final Future<void> Function(String studentId, double amount) onProcessPayment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Dues (${details.monthLabel})', style: typography.h4.copyWith(color: const Color(0xFF163D32))),
          const Gap(16),
          ...details.lineItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.title, style: typography.bodyMedium.copyWith(color: const Color(0xFF6F7A75))),
                  ),
                  Text('₹${item.amount.toStringAsFixed(0)}', style: typography.bodyMediumSemiBold.copyWith(color: const Color(0xFF163D32))),
                ],
              ),
            ),
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(child: Text('Balance', style: typography.bodyLargeSemiBold.copyWith(color: const Color(0xFF163D32)))),
              Text('₹${details.balance.toStringAsFixed(0)}', style: typography.h3.copyWith(color: colors.primary)),
            ],
          ),
          const Gap(20),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: typography.bodyLarge.copyWith(color: const Color(0xFF163D32)),
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              labelStyle: typography.bodyMedium.copyWith(color: const Color(0xFF6F7A75)),
              filled: true,
              fillColor: colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: processingPayment
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid amount')),
                        );
                        return;
                      }
                      await onProcessPayment(details.summary.studentId, amount);
                    },
              child: Text(processingPayment ? 'Processing...' : 'Process Payment'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.details});
  final StudentAccountDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fee History', style: typography.h4.copyWith(color: const Color(0xFF163D32))),
          const Gap(16),
          if (details.history.isEmpty)
            Text('No payment history found', style: typography.bodyMedium.copyWith(color: const Color(0xFF6F7A75)))
          else
            ...details.history.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.monthLabel, style: typography.bodyMediumSemiBold.copyWith(color: const Color(0xFF163D32))),
                          if (item.paidOn != null)
                            Text(
                              DateFormat('dd MMM yyyy').format(item.paidOn!),
                              style: typography.bodySmall.copyWith(color: const Color(0xFF6F7A75)),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${item.totalPaid.toStringAsFixed(0)}',
                      style: typography.bodyMediumSemiBold.copyWith(color: const Color(0xFF163D32)),
                    ),
                    const Gap(10),
                    _StatusChip(status: item.status),
                    if (item.status == 'Paid') ...[
                      const Gap(8),
                      IconButton(
                        icon: const Icon(LucideIcons.receipt, size: 20),
                        onPressed: () => _showReceiptDialog(context, details, item),
                        tooltip: 'View Receipt',
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, StudentAccountDetails details, ReceiptHistoryItem historyItem) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReceiptContent(details: details, historyItem: historyItem),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _printReceipt(details, historyItem),
                    icon: const Icon(LucideIcons.printer, size: 18),
                    label: const Text('Print Receipt'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printReceipt(StudentAccountDetails details, ReceiptHistoryItem item) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('ANAS BIN MALIK CENTRE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.Center(child: pw.Text('FEE PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 12))),
              pw.Divider(),
              pw.Text('Receipt No: ${item.receiptNumber ?? 'N/A'}'),
              pw.Text('Date: ${item.paidOn != null ? DateFormat('dd MMM yyyy').format(item.paidOn!) : 'N/A'}'),
              pw.Text('Month: ${item.monthLabel}'),
              pw.Divider(),
              pw.Text('Student: ${details.summary.fullName}'),
              pw.Text('Admission No: ${details.summary.admissionNumber}'),
              pw.Text('Class: ${details.summary.classroom}'),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Due'),
                  pw.Text('Rs. ${item.totalDue.toStringAsFixed(0)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Paid'),
                  pw.Text('Rs. ${item.totalPaid.toStringAsFixed(0)}'),
                ],
              ),
              pw.Divider(),
              pw.Text('Status: PAID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Center(child: pw.Text('Thank you!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}

class _ReceiptContent extends StatelessWidget {
  const _ReceiptContent({required this.details, required this.historyItem});
  final StudentAccountDetails details;
  final ReceiptHistoryItem historyItem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.checkCircle2, color: colors.primary, size: 32),
          ),
          const Gap(16),
          Text('Payment Successful', style: typography.h3.copyWith(color: colors.primary)),
          const Gap(8),
          Text(
            'Receipt #${historyItem.receiptNumber ?? 'N/A'}',
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const Gap(24),
          const Divider(),
          const Gap(24),
          _ReceiptRow(label: 'Student Name', value: details.summary.fullName),
          _ReceiptRow(label: 'Admission No', value: details.summary.admissionNumber),
          _ReceiptRow(label: 'Fee Month', value: historyItem.monthLabel),
          _ReceiptRow(label: 'Payment Date', value: historyItem.paidOn != null ? DateFormat('dd MMM yyyy HH:mm').format(historyItem.paidOn!) : 'N/A'),
          const Gap(16),
          const Divider(),
          const Gap(16),
          _ReceiptRow(label: 'Total Amount', value: '₹${historyItem.totalDue.toStringAsFixed(0)}'),
          _ReceiptRow(label: 'Paid Amount', value: '₹${historyItem.totalPaid.toStringAsFixed(0)}', isBold: true),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value, this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typography.bodyMedium.copyWith(color: context.colors.textSecondary)),
          Text(
            value,
            style: isBold ? typography.bodyLargeSemiBold.copyWith(color: context.colors.primary) : typography.bodyMediumSemiBold,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isPaid = normalized == 'paid';
    final isPartial = normalized == 'partially paid';
    final color = isPaid
        ? Colors.green
        : isPartial
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
