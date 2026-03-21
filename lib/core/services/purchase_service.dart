import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../database/hive_service.dart';

/// 買い切り課金管理サービス
/// 商品ID: com.focusgym.unlock_all（300円・Non-Consumable）
/// 初回起動から14日間は無料トライアル。以降は購入が必要。
class PurchaseService extends ChangeNotifier {
  static const String kProductId = 'com.focusgym.unlock_all';
  static const int trialDays = 14;

  static PurchaseService? _instance;
  static PurchaseService get instance => _instance ??= PurchaseService._();
  PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  String? _lastError;
  String? get lastError => _lastError;

  /// 購入済みか
  bool get isPurchased =>
      HiveService.instance.getSetting(HiveService.keyIsPurchased, defaultValue: false) as bool;

  /// トライアル期間中か
  bool get isInTrial {
    final startStr = HiveService.instance.getSetting(HiveService.keyTrialStartDate, defaultValue: '') as String;
    if (startStr.isEmpty) return true;
    final start = DateTime.tryParse(startStr);
    if (start == null) return true;
    return DateTime.now().difference(start).inDays < trialDays;
  }

  /// トライアル残り日数
  int get trialRemainingDays {
    final startStr = HiveService.instance.getSetting(HiveService.keyTrialStartDate, defaultValue: '') as String;
    if (startStr.isEmpty) return trialDays;
    final start = DateTime.tryParse(startStr);
    if (start == null) return trialDays;
    final elapsed = DateTime.now().difference(start).inDays;
    return (trialDays - elapsed).clamp(0, trialDays);
  }

  /// すべての機能が使えるか（購入済み OR トライアル中）
  bool get isUnlocked => isPurchased || isInTrial;

  /// 初回起動日を記録（main.dart の初期化時に呼ぶ）
  Future<void> recordTrialStartIfNeeded() async {
    final existing = HiveService.instance.getSetting(HiveService.keyTrialStartDate, defaultValue: '') as String;
    if (existing.isEmpty) {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await HiveService.instance.saveSetting(HiveService.keyTrialStartDate, today);
    }
  }

  /// 購入ストリームを開始（main.dart で呼ぶ）
  void initialize() {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (e) {
        debugPrint('PurchaseService error: $e');
        _isPurchasing = false;
        _lastError = '購入処理中にエラーが発生しました';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// 300円買い切り購入
  Future<void> purchase() async {
    _isPurchasing = true;
    _lastError = null;
    notifyListeners();

    final available = await _iap.isAvailable();
    if (!available) {
      _isPurchasing = false;
      _lastError = 'ストアに接続できませんでした';
      notifyListeners();
      return;
    }

    final response = await _iap.queryProductDetails({kProductId});
    if (response.productDetails.isEmpty) {
      _isPurchasing = false;
      _lastError = '商品情報を取得できませんでした';
      notifyListeners();
      return;
    }

    final param = PurchaseParam(productDetails: response.productDetails.first);
    _iap.buyNonConsumable(purchaseParam: param);
    // 以降は _onPurchaseUpdated で処理
  }

  /// 購入の復元
  Future<void> restorePurchases() async {
    _isPurchasing = true;
    _lastError = null;
    notifyListeners();
    await _iap.restorePurchases();
    // 結果は _onPurchaseUpdated で処理される
    // 何も復元されなかった場合のタイムアウト処理
    await Future.delayed(const Duration(seconds: 3));
    if (_isPurchasing) {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != kProductId) continue;

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await HiveService.instance.saveSetting(HiveService.keyIsPurchased, true);
        _isPurchasing = false;
        _lastError = null;
        notifyListeners();
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        _isPurchasing = false;
        _lastError = null;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
        _isPurchasing = false;
        _lastError = '購入に失敗しました。もう一度お試しください';
        notifyListeners();
      }
    }
  }
}
