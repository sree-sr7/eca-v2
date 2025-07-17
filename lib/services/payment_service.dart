import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../database/db_helper.dart';

class PaymentService {
  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  late Razorpay _razorpay;
  final DBHelper _dbHelper = DBHelper();

  // Completer to handle async payment completion
  Completer<Map<String, dynamic>>? _paymentCompleter;

  PaymentService._internal() {
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete({
        'success': true,
        'transactionId': response.paymentId ?? 'RP${DateTime.now().millisecondsSinceEpoch}',
        'orderId': response.orderId,
        'signature': response.signature,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Completed',
        'paymentMethod': 'Razorpay',
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete({
        'success': false,
        'code': response.code.toString(),
        'message': response.message ?? 'Payment failed',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Failed',
        'paymentMethod': 'Razorpay',
      });
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
    print("External Wallet Selected: ${response.walletName}");

    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete({
        'success': true,
        'transactionId': 'EW${DateTime.now().millisecondsSinceEpoch}',
        'walletName': response.walletName,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Completed',
        'paymentMethod': response.walletName ?? 'External Wallet',
      });
    }
  }

  // Process payment with Razorpay
  Future<Map<String, dynamic>> processRazorpayPayment({
    required double amount,
    required String description,
    required String userEmail,
    required String userPhone,
    required String userName,
  }) async {
    _paymentCompleter = Completer<Map<String, dynamic>>();

    // Razorpay accepts amount in paise (1 INR = 100 paise)
    final amountInPaise = (amount * 100).toInt();

    var options = {
      'key': '***REMOVED***',  // Replace with your actual Razorpay key
      'amount': amountInPaise,
      'name': 'Elderly Care App',
      'description': description,
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
        'name': userName
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
      return _paymentCompleter!.future;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Failed',
        'paymentMethod': 'Razorpay',
      };
    }
  }

  // Save payment record to the database
  Future<int> savePaymentRecord({
    required int userId,
    required int careplanId,
    required double amount,
    required String transactionId,
    required String paymentMethod,
    String status = 'Paid',
  }) async {
    return await _dbHelper.insertPayment(
      userId: userId,
      careplanId: careplanId,
      amount: amount,
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      status: status,
      paidAt: DateTime.now().toIso8601String(),
    );
  }

  // Function to fetch payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(int userId) async {
    return await _dbHelper.getPayments(userId);
  }

  void dispose() {
    _razorpay.clear();
  }
}