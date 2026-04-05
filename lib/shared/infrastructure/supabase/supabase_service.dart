import 'package:dio/dio.dart';
import 'package:keep_track/core/di/disposable.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/features/auth/data/services/auth_service.dart';

/// Compatibility shim — replaces Supabase-backed SupabaseService.
///
/// Screens that previously used [client.rpc()] now have their calls translated
/// to NestJS REST endpoints transparently.  New code should use [AuthService]
/// and the feature repositories directly instead of this class.
class SupabaseService implements Disposable {
  final AuthService _authService;
  late final _RpcClient _rpcClient;

  SupabaseService(this._authService) {
    _rpcClient = _RpcClient(ApiClient.instance);
  }

  /// Compatibility constructor used in DI (no Supabase client needed anymore).
  factory SupabaseService.fromClient(dynamic _) {
    throw UnsupportedError(
      'SupabaseService.fromClient is no longer supported. '
      'Register SupabaseService via SupabaseService(authService) in DI.',
    );
  }

  /// The current user's ID, sourced from AuthService.
  String? get userId => _authService.currentUser?.id;

  /// Thin RPC/query client. Returns dynamic so legacy Supabase call chains
  /// on dead-code datasource files compile without type errors.
  dynamic get client => _rpcClient;

  @override
  Future<void> dispose() async {}
}

/// Translates legacy Supabase `client.rpc(name, params: {...})` calls to
/// NestJS REST endpoints via Dio.
class _RpcClient {
  final Dio _dio;
  _RpcClient(this._dio);

  /// Call a named "RPC function" — maps to a NestJS endpoint.
  Future<dynamic> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final p = params ?? {};
    switch (functionName) {
      case 'create_debt_payment_transaction':
        return _createTransaction({
          'accountId': p['p_account_id'],
          'financeCategoryId': p['p_finance_category_id'],
          'amount': p['p_amount'],
          'type': p['p_type'],
          'description': p['p_description'],
          'date': p['p_date'],
          if (p['p_notes'] != null) 'notes': p['p_notes'],
          'debtId': p['p_debt_id'],
          if (p['p_fee'] != null) 'fee': p['p_fee'],
        });

      case 'create_goal_payment_transaction':
        return _createTransaction({
          'accountId': p['p_account_id'],
          'financeCategoryId': p['p_finance_category_id'],
          'amount': p['p_amount'],
          'type': p['p_type'] ?? 'expense',
          'description': p['p_description'],
          'date': p['p_date'],
          if (p['p_notes'] != null) 'notes': p['p_notes'],
          'goalId': p['p_goal_id'],
          if (p['p_fee'] != null) 'fee': p['p_fee'],
        });

      case 'create_planned_payment_transaction':
        return _createTransaction({
          'accountId': p['p_account_id'],
          'financeCategoryId': p['p_finance_category_id'],
          'amount': p['p_amount'],
          'type': p['p_type'] ?? 'expense',
          'description': p['p_description'],
          'date': p['p_date'],
          if (p['p_notes'] != null) 'notes': p['p_notes'],
          'plannedPaymentId': p['p_planned_payment_id'],
          if (p['p_fee'] != null) 'fee': p['p_fee'],
          if (p['p_fee_description'] != null)
            'feeDescription': p['p_fee_description'],
        });

      case 'skip_planned_payment':
        // Advance the next payment date without creating a transaction
        return _dio.post(
          '/planned-payments/${p['p_planned_payment_id']}/skip',
        );

      default:
        throw UnsupportedError('RPC "$functionName" has no REST mapping');
    }
  }

  Future<dynamic> _createTransaction(Map<String, dynamic> body) async {
    final res = await _dio.post('/transactions', data: body);
    return res.data;
  }
}
