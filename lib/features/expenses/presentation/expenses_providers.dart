import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/expenses_repository.dart';
import '../data/receipt_ocr_service.dart';
import '../domain/expense.dart';

final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
  final service = MobileReceiptOcrService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(appDatabaseProvider));
});

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expensesRepositoryProvider).watchExpenses();
});
