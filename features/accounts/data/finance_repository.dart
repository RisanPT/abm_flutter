import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/features/accounts/domain/account_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AccountRepository(dio);
});

class AccountRepository {
  AccountRepository(this._dio);

  final Dio _dio;

  Future<List<AccountSummary>> getStudentSummaries({String? instituteId}) async {
    try {
      final response = await _dio.get(
        '/accounts/students',
        queryParameters: instituteId != null ? {'instituteId': instituteId} : null,
      );
      final data = response.data as List<dynamic>;
      return data
          .map((item) => AccountSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch account summaries: $e');
    }
  }

  Future<StudentAccountDetails> getStudentAccountDetails(String studentId) async {
    try {
      final response = await _dio.get('/accounts/student/$studentId');
      return StudentAccountDetails.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch account details: $e');
    }
  }

  Future<ReceiptHistoryItem> processPayment({
    required String studentId,
    required double amount,
    List<String>? items,
    String? monthLabel, // pay a specific month
    String? allocate, // 'oldest' to clear arrears oldest-first
  }) async {
    try {
      final response = await _dio.post(
        '/accounts/student/$studentId/pay',
        data: {
          'amount': amount,
          if (items != null && items.isNotEmpty) 'items': items,
          'monthLabel': ?monthLabel,
          'allocate': ?allocate,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return ReceiptHistoryItem(
        id: (data['id'] as String?) ?? '',
        monthLabel: (data['monthLabel'] as String?) ?? '',
        totalDue: (data['totalDue'] as num?)?.toDouble() ?? 0,
        totalPaid: (data['totalPaid'] as num?)?.toDouble() ?? 0,
        status: (data['status'] as String?) ?? 'Paid',
        lineItems: ((data['lineItems'] as List?) ?? [])
            .map((item) => AccountLineItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        receiptNumber: data['receiptNumber'] as String?,
        paidOn: data['paidOn'] != null
            ? DateTime.tryParse(data['paidOn'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<void> recalculateFees(String studentId) async {
    try {
      await _dio.post('/accounts/student/$studentId/recalculate');
    } catch (e) {
      throw Exception('Failed to recalculate fees: $e');
    }
  }

  Future<List<FeeStructureModel>> getFeeStructures() async {
    try {
      final response = await _dio.get('/fee-structures');
      final data = response.data as List<dynamic>;
      return data.map((item) => FeeStructureModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to fetch fee structures: $e');
    }
  }

  Future<FeeStructureModel> createFeeStructure(FeeStructureModel model) async {
    try {
      final response = await _dio.post('/fee-structures', data: model.toJson());
      return FeeStructureModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create fee structure: $e');
    }
  }

  Future<FeeStructureModel> updateFeeStructure(FeeStructureModel model) async {
    try {
      final response = await _dio.put('/fee-structures/${model.id}', data: model.toJson());
      return FeeStructureModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update fee structure: $e');
    }
  }

  Future<void> deleteFeeStructure(String id) async {
    try {
      await _dio.delete('/fee-structures/$id');
    } catch (e) {
      throw Exception('Failed to delete fee structure: $e');
    }
  }

  Future<FeeLedger> getLedger(String studentId) async {
    try {
      final response = await _dio.get('/accounts/student/$studentId/ledger');
      return FeeLedger.fromJson(Map<String, dynamic>.from(response.data));
    } catch (e) {
      throw Exception('Failed to load ledger: $e');
    }
  }

  Future<void> waiveMonth(String studentId, String monthLabel, bool waived) async {
    try {
      await _dio.post('/accounts/student/$studentId/waive-month',
          data: {'monthLabel': monthLabel, 'waived': waived});
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map ? (e.response?.data['message'] ?? 'Failed') : 'Failed to update month');
    }
  }

  Future<InstituteFeeConfig> getInstituteFeeConfig(String instituteId) async {
    final r = await _dio.get('/institutes/$instituteId/fee-config');
    return InstituteFeeConfig.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<InstituteFeeConfig> setInstituteFeeConfig(
    String instituteId, {
    DateTime? feesStartMonth,
    required List<String> waivedMonths,
    required List<VacationPeriod> vacationPeriods,
  }) async {
    try {
      final r = await _dio.put('/institutes/$instituteId/fee-config', data: {
        'feesStartMonth': feesStartMonth?.toIso8601String(),
        'waivedMonths': waivedMonths,
        'vacationPeriods': vacationPeriods.map((v) => v.toJson()).toList(),
      });
      return InstituteFeeConfig.fromJson(Map<String, dynamic>.from(r.data));
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map ? (e.response?.data['message'] ?? 'Failed') : 'Failed to save fee config');
    }
  }
}

class VacationPeriod {
  const VacationPeriod({required this.name, required this.from, required this.to});
  final String name;
  final DateTime from;
  final DateTime to;

  factory VacationPeriod.fromJson(Map<String, dynamic> j) => VacationPeriod(
        name: j['name'] ?? 'Vacation',
        from: DateTime.parse(j['from'].toString()),
        to: DateTime.parse(j['to'].toString()),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      };
}

class InstituteFeeConfig {
  const InstituteFeeConfig({
    this.feesStartMonth, 
    required this.waivedMonths,
    required this.vacationPeriods,
  });
  final DateTime? feesStartMonth;
  final List<String> waivedMonths;
  final List<VacationPeriod> vacationPeriods;

  factory InstituteFeeConfig.fromJson(Map<String, dynamic> j) => InstituteFeeConfig(
        feesStartMonth: j['feesStartMonth'] != null ? DateTime.tryParse(j['feesStartMonth'].toString()) : null,
        waivedMonths: ((j['waivedMonths'] as List?) ?? []).map((e) => e.toString()).toList(),
        vacationPeriods: ((j['vacationPeriods'] as List?) ?? [])
            .map((e) => VacationPeriod.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

// ── Ledger models ────────────────────────────────────────────────────────────

class LedgerMonth {
  const LedgerMonth({
    required this.monthLabel,
    required this.totalDue,
    required this.totalPaid,
    required this.balance,
    required this.status,
    required this.waived,
    required this.isCurrent,
    required this.isPast,
  });
  final String monthLabel, status;
  final num totalDue, totalPaid, balance;
  final bool waived, isCurrent, isPast;

  factory LedgerMonth.fromJson(Map<String, dynamic> j) => LedgerMonth(
        monthLabel: (j['monthLabel'] ?? '').toString(),
        totalDue: (j['totalDue'] ?? 0) as num,
        totalPaid: (j['totalPaid'] ?? 0) as num,
        balance: (j['balance'] ?? 0) as num,
        status: (j['status'] ?? 'Pending').toString(),
        waived: j['waived'] == true,
        isCurrent: j['isCurrent'] == true,
        isPast: j['isPast'] == true,
      );
}

class FeeLedger {
  const FeeLedger({
    required this.months,
    required this.arrears,
    required this.currentDue,
    required this.advanceBalance,
    required this.totalOutstanding,
  });
  final List<LedgerMonth> months;
  final num arrears, currentDue, advanceBalance, totalOutstanding;

  factory FeeLedger.fromJson(Map<String, dynamic> j) => FeeLedger(
        months: ((j['months'] as List?) ?? [])
            .map((e) => LedgerMonth.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        arrears: (j['arrears'] ?? 0) as num,
        currentDue: (j['currentDue'] ?? 0) as num,
        advanceBalance: (j['advanceBalance'] ?? 0) as num,
        totalOutstanding: (j['totalOutstanding'] ?? 0) as num,
      );
}
