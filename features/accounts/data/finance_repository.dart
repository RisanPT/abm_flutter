import 'package:abm_madrasa/core/network/dio_client.dart';
import 'package:abm_madrasa/core/network/paged_result.dart';
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

  /// Server-paginated fee summaries for the accounts directory. Search + class
  /// filter run on the backend so only the current page is materialized.
  Future<PagedResult<AccountSummary>> getStudentSummariesPage({
    String? instituteId,
    String? search,
    String? classroom,
    String? status, // 'pending' | 'paid' | null/'all'
    required int page,
    int limit = 25,
  }) async {
    try {
      final response = await _dio.get('/accounts/students', queryParameters: {
        'instituteId': instituteId,
        'search': search,
        'classroom': classroom,
        if (status != null && status != 'all') 'status': status,
        'page': page,
        'limit': limit,
      }..removeWhere((_, v) => v == null || v == '' || v == 'All'));
      return PagedResult<AccountSummary>.fromJson(
        response.data as Map<String, dynamic>,
        AccountSummary.fromJson,
      );
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
    List<String>? monthLabels, // pay multiple months
    String? allocate, // 'oldest' to clear arrears oldest-first
  }) async {
    try {
      final response = await _dio.post(
        '/accounts/student/$studentId/pay',
        data: {
          'amount': amount,
          if (items != null && items.isNotEmpty) 'items': items,
          if (monthLabels != null && monthLabels.isNotEmpty)
            'monthLabels': monthLabels
          else
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
        monthsCount: (data['monthsCount'] as num?)?.toInt(),
      );
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<MultiMonthPreview> previewMonths({
    required String studentId,
    required List<String> monthLabels,
  }) async {
    try {
      final response = await _dio.post(
        '/accounts/student/$studentId/preview-months',
        data: {'monthLabels': monthLabels},
      );
      return MultiMonthPreview.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to preview months: $e');
    }
  }

  // ── Family / sibling combined fee collection ───────────────────────────────

  /// Parents with their children + each family's total balance. `search` matches
  /// child name/ID or guardian name/contact/Iqama; empty search browses real
  /// sibling groups (2+ children).
  Future<List<FamilySummary>> getFamilies({
    String? instituteId,
    String? search,
    String? classroom,
  }) async {
    try {
      final response = await _dio.get('/accounts/families', queryParameters: {
        'instituteId': instituteId,
        'search': search,
        'classroom': classroom,
      }..removeWhere((_, v) => v == null || v == '' || v == 'All'));
      final data = Map<String, dynamic>.from(response.data as Map);
      return ((data['families'] as List?) ?? [])
          .map((e) => FamilySummary.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw Exception('Failed to load families: $e');
    }
  }

  Future<PagedResult<FamilySummary>> getFamiliesPage({
    String? instituteId,
    String? search,
    String? classroom,
    String? status,
    required int page,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get('/accounts/families', queryParameters: {
        'instituteId': instituteId,
        'search': search,
        'classroom': classroom,
        if (status != null && status != 'all') 'status': status,
        'page': page,
        'limit': limit,
      }..removeWhere((_, v) => v == null || v == '' || v == 'All'));
      return PagedResult<FamilySummary>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        (json) => FamilySummary.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } catch (e) {
      throw Exception('Failed to load families page: $e');
    }
  }

  Future<FamilyDetail> getFamilyDetail(String key, {String? instituteId}) async {
    try {
      final response = await _dio.get('/accounts/family/detail', queryParameters: {
        'key': key,
        'instituteId': instituteId,
      }..removeWhere((_, v) => v == null || v == ''));
      return FamilyDetail.fromJson(Map<String, dynamic>.from(response.data as Map));
    } catch (e) {
      throw Exception('Failed to load family: $e');
    }
  }

  /// Collect for several children in one go — the backend records one shared
  /// receipt covering the whole family. Each allocation is
  /// `{studentId, amount, monthLabel?, items?}`.
  Future<FamilyReceipt> payFamily({
    required List<Map<String, dynamic>> allocations,
    String? allocate,
  }) async {
    try {
      final response = await _dio.post('/accounts/family/pay', data: {
        'allocations': allocations,
        'allocate': ?allocate,
      });
      return FamilyReceipt.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Failed to record family payment')
          : 'Failed to record family payment');
    }
  }

  /// Parent-login (one per family) management. `key` is the family key.
  Future<FamilyLoginStatus> getFamilyLogin(String key) async {
    try {
      final r = await _dio.get('/accounts/family/login', queryParameters: {'key': key});
      return FamilyLoginStatus.fromJson(Map<String, dynamic>.from(r.data));
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Failed to load parent login')
          : 'Failed to load parent login');
    }
  }

  Future<FamilyLoginStatus> setFamilyLogin(
    String key, {
    String? username,
    String? password,
    bool enabled = true,
    bool? phoneLogin,
  }) async {
    try {
      final r = await _dio.post('/accounts/family/login', data: {
        'key': key,
        if (username != null && username.isNotEmpty) 'username': username,
        if (password != null && password.isNotEmpty) 'password': password,
        'enabled': enabled,
        'phoneLogin': ?phoneLogin,
      });
      return FamilyLoginStatus.fromJson(Map<String, dynamic>.from(r.data));
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Failed to save parent login')
          : 'Failed to save parent login');
    }
  }

  Future<void> deleteFamilyLogin(String key) async {
    try {
      await _dio.delete('/accounts/family/login', queryParameters: {'key': key});
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Failed to remove parent login')
          : 'Failed to remove parent login');
    }
  }

  /// Bulk-enable (or disable) passwordless phone login for every family in the
  /// institute at once.
  Future<BulkPhoneLoginResult> enablePhoneLoginForAll({bool disable = false}) async {
    try {
      final r = await _dio.post('/accounts/families/enable-phone-login',
          data: {if (disable) 'disable': true});
      return BulkPhoneLoginResult.fromJson(Map<String, dynamic>.from(r.data));
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Failed to update phone logins')
          : 'Failed to update phone logins');
    }
  }

  Future<void> recalculateFees(String studentId) async {
    try {
      await _dio.post('/accounts/student/$studentId/recalculate');
    } catch (e) {
      throw Exception('Failed to recalculate fees: $e');
    }
  }

  /// Add a manual/ad-hoc charge (e.g. a Books Fee) as a line item on the given
  /// month(s). It raises each month's due and is then collected via the normal
  /// pay flow. Returns the list of month labels the charge was applied to.
  Future<List<String>> addCharge(
    String studentId, {
    required String title,
    required double amount,
    required List<String> monthLabels,
  }) async {
    try {
      final response = await _dio.post(
        '/accounts/student/$studentId/add-charge',
        data: {'title': title, 'amount': amount, 'monthLabels': monthLabels},
      );
      final applied = (response.data['applied'] as List?)?.cast<String>() ?? const [];
      return applied;
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Failed to add charge')
          : 'Failed to add charge');
    }
  }

  /// Add a charge (e.g. a Books Fee) to EVERY active student in a class/grade,
  /// across the given months.
  Future<ClassChargeResult> chargeClass({
    required String grade,
    required String title,
    required double amount,
    required List<String> monthLabels,
  }) async {
    try {
      final r = await _dio.post('/accounts/class/charge', data: {
        'grade': grade,
        'title': title,
        'amount': amount,
        'monthLabels': monthLabels,
      });
      return ClassChargeResult.fromJson(Map<String, dynamic>.from(r.data));
    } on DioException catch (e) {
      throw Exception(e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Failed to charge class')
          : 'Failed to charge class');
    }
  }

  Future<List<FeeStructureModel>> getFeeStructures({String? instituteId}) async {
    try {
      final response = await _dio.get(
        '/fee-structures',
        queryParameters: instituteId != null ? {'instituteId': instituteId} : null,
      );
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
    bool? siblingDiscountEnabled,
    int? siblingDiscountFromChild,
    double? siblingDiscountAmount,
  }) async {
    try {
      final r = await _dio.put('/institutes/$instituteId/fee-config', data: {
        'feesStartMonth': feesStartMonth?.toIso8601String(),
        'waivedMonths': waivedMonths,
        'vacationPeriods': vacationPeriods.map((v) => v.toJson()).toList(),
        if (siblingDiscountEnabled != null)
          'siblingDiscount': {
            'enabled': siblingDiscountEnabled,
            'fromChild': siblingDiscountFromChild ?? 3,
            'amount': siblingDiscountAmount ?? 0,
          },
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
    this.siblingDiscountEnabled = false,
    this.siblingDiscountFromChild = 3,
    this.siblingDiscountAmount = 0,
  });
  final DateTime? feesStartMonth;
  final List<String> waivedMonths;
  final List<VacationPeriod> vacationPeriods;
  // Automatic multi-child rule: the Nth+ child in a family gets `amount` off
  // tuition. A student's manual discount overrides this.
  final bool siblingDiscountEnabled;
  final int siblingDiscountFromChild;
  final double siblingDiscountAmount;

  factory InstituteFeeConfig.fromJson(Map<String, dynamic> j) {
    final sd = Map<String, dynamic>.from(j['siblingDiscount'] as Map? ?? {});
    return InstituteFeeConfig(
      feesStartMonth: j['feesStartMonth'] != null ? DateTime.tryParse(j['feesStartMonth'].toString()) : null,
      waivedMonths: ((j['waivedMonths'] as List?) ?? []).map((e) => e.toString()).toList(),
      vacationPeriods: ((j['vacationPeriods'] as List?) ?? [])
          .map((e) => VacationPeriod.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      siblingDiscountEnabled: sd['enabled'] == true,
      siblingDiscountFromChild: (sd['fromChild'] as num?)?.toInt() ?? 3,
      siblingDiscountAmount: (sd['amount'] as num?)?.toDouble() ?? 0,
    );
  }
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
    this.receiptNumber,
    this.paidOn,
    this.lineItems = const [],
  });
  final String monthLabel, status;
  final num totalDue, totalPaid, balance;
  final bool waived, isCurrent, isPast;
  final String? receiptNumber;
  final DateTime? paidOn;
  final List<dynamic> lineItems;

  factory LedgerMonth.fromJson(Map<String, dynamic> j) => LedgerMonth(
        monthLabel: (j['monthLabel'] ?? '').toString(),
        totalDue: (j['totalDue'] ?? 0) as num,
        totalPaid: (j['totalPaid'] ?? 0) as num,
        balance: (j['balance'] ?? 0) as num,
        status: (j['status'] ?? 'Pending').toString(),
        waived: j['waived'] == true,
        isCurrent: j['isCurrent'] == true,
        isPast: j['isPast'] == true,
        receiptNumber: j['receiptNumber'] as String?,
        paidOn: j['paidOn'] != null ? DateTime.tryParse(j['paidOn'].toString()) : null,
        lineItems: (j['lineItems'] as List?) ?? (j['payments'] as List?) ?? const [],
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

class FamilyLoginStatus {
  const FamilyLoginStatus({
    required this.hasLogin,
    this.username,
    required this.enabled,
    this.phoneLoginEnabled = false,
  });
  final bool hasLogin;
  final String? username;
  final bool enabled;
  final bool phoneLoginEnabled;

  factory FamilyLoginStatus.fromJson(Map<String, dynamic> j) => FamilyLoginStatus(
        hasLogin: j['hasLogin'] == true,
        username: j['username'] as String?,
        enabled: j['enabled'] == true,
        phoneLoginEnabled: j['phoneLoginEnabled'] == true,
      );
}

class BulkPhoneLoginResult {
  const BulkPhoneLoginResult({
    this.totalFamilies = 0,
    this.created = 0,
    this.enabled = 0,
    this.activeTotal = 0,
    this.skippedCount = 0,
    this.disabled = 0,
  });
  final int totalFamilies, created, enabled, activeTotal, skippedCount, disabled;

  factory BulkPhoneLoginResult.fromJson(Map<String, dynamic> j) => BulkPhoneLoginResult(
        totalFamilies: (j['totalFamilies'] as num?)?.toInt() ?? 0,
        created: (j['created'] as num?)?.toInt() ?? 0,
        enabled: (j['enabled'] as num?)?.toInt() ?? 0,
        activeTotal: (j['activeTotal'] as num?)?.toInt() ?? 0,
        skippedCount: (j['skippedCount'] as num?)?.toInt() ?? 0,
        disabled: (j['disabled'] as num?)?.toInt() ?? 0,
      );
}

class ClassChargeResult {
  const ClassChargeResult({
    this.grade = '',
    this.title = '',
    this.amount = 0,
    this.studentsInClass = 0,
    this.charged = 0,
    this.monthsCount = 0,
  });
  final String grade, title;
  final num amount;
  final int studentsInClass, charged, monthsCount;

  factory ClassChargeResult.fromJson(Map<String, dynamic> j) => ClassChargeResult(
        grade: (j['grade'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        amount: (j['amount'] ?? 0) as num,
        studentsInClass: (j['studentsInClass'] as num?)?.toInt() ?? 0,
        charged: (j['charged'] as num?)?.toInt() ?? 0,
        monthsCount: (j['monthsCount'] as num?)?.toInt() ?? 0,
      );
}
