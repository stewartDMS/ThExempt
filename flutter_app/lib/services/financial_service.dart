import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membership_tier_model.dart';
import '../models/user_membership_model.dart';
import '../models/credit_balance_model.dart';
import '../models/credit_transaction_model.dart';
import '../models/project_investment_model.dart';
import '../models/project_contribution_model.dart';
import '../models/project_equity_model.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

class FinancialService {
  static final _supabase = Supabase.instance.client;

  // ── Membership ─────────────────────────────────────────────────────────────

  static Future<List<MembershipTier>> getMembershipTiers() async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('membership_tiers')
              .select()
              .eq('is_active', true)
              .order('sort_order')
              .timeout(const Duration(seconds: 10));
          return response
              .map((json) => MembershipTier.fromJson(json))
              .toList();
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  static Future<UserMembership?> getUserMembership(String userId) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('user_memberships')
              .select('*, membership_tiers(name, slug)')
              .eq('user_id', userId)
              .eq('status', 'active')
              .maybeSingle()
              .timeout(const Duration(seconds: 10));
          if (response == null) return null;
          return UserMembership.fromJson(response);
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  // ── Credits ────────────────────────────────────────────────────────────────

  static Future<CreditBalance?> getCreditBalance(String userId) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('credit_balances')
              .select()
              .eq('user_id', userId)
              .maybeSingle()
              .timeout(const Duration(seconds: 10));
          if (response == null) return null;
          return CreditBalance.fromJson(response);
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  static Future<List<CreditTransaction>> getCreditTransactions(
    String userId, {
    int limit = 50,
  }) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('credit_transactions')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(limit)
              .timeout(const Duration(seconds: 10));
          return response
              .map((json) => CreditTransaction.fromJson(json))
              .toList();
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  // ── Investments ────────────────────────────────────────────────────────────

  static Future<List<ProjectInvestment>> getProjectInvestments(
    String projectId,
  ) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('project_investments')
              .select('*, profiles(username, avatar_url)')
              .eq('project_id', projectId)
              .order('created_at', ascending: false)
              .timeout(const Duration(seconds: 10));
          return response
              .map((json) => ProjectInvestment.fromJson(json))
              .toList();
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  static Future<ProjectInvestment?> getUserInvestment(
    String projectId,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('project_investments')
              .select('*, profiles(username, avatar_url)')
              .eq('project_id', projectId)
              .eq('user_id', userId)
              .maybeSingle()
              .timeout(const Duration(seconds: 10));
          if (response == null) return null;
          return ProjectInvestment.fromJson(response);
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  static Future<void> investInProject(
    String projectId,
    int creditsAmount, {
    String? message,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');
      await _supabase
          .from('project_investments')
          .upsert(
            {
              'project_id': projectId,
              'user_id': userId,
              'credits_amount': creditsAmount,
              if (message != null && message.isNotEmpty) 'message': message,
            },
            onConflict: 'project_id,user_id',
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  // ── Contributions ──────────────────────────────────────────────────────────

  static Future<List<ProjectContribution>> getProjectContributions(
    String projectId,
  ) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('project_contributions')
              .select('*, profiles(username, avatar_url)')
              .eq('project_id', projectId)
              .order('created_at', ascending: false)
              .timeout(const Duration(seconds: 10));
          return response
              .map((json) => ProjectContribution.fromJson(json))
              .toList();
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  static Future<void> addContribution(
    String projectId,
    String contributionType,
    String description, {
    int amount = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');
      await _supabase
          .from('project_contributions')
          .insert({
            'project_id': projectId,
            'user_id': userId,
            'contribution_type': contributionType,
            'description': description,
            'amount': amount,
          })
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }

  // ── Equity ─────────────────────────────────────────────────────────────────

  static Future<List<ProjectEquity>> getProjectEquity(
    String projectId,
  ) async {
    try {
      return await RetryHelper.retryWithBackoff(
        operation: () async {
          final response = await _supabase
              .from('project_equity')
              .select('*, profiles(username, avatar_url)')
              .eq('project_id', projectId)
              .order('granted_at', ascending: false)
              .timeout(const Duration(seconds: 10));
          return response
              .map((json) => ProjectEquity.fromJson(json))
              .toList();
        },
      );
    } catch (e) {
      final appError = ErrorHandler.handleError(e);
      ErrorHandler.log(appError);
      throw appError;
    }
  }
}
