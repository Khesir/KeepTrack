import 'package:keep_track/features/finance/modules/debt/data/datasources/debt_datasource.dart';
import 'package:keep_track/features/finance/modules/debt/data/models/debt_model.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';

final _debts = <DebtModel>[
  DebtModel(
    id: 'debt-alice',
    type: DebtType.lending,
    personName: 'Alice',
    description: 'Lent for medical expenses',
    originalAmount: 500,
    remainingAmount: 300,
    startDate: DateTime(2026, 5, 5),
    dueDate: DateTime(2026, 7, 31),
    status: DebtStatus.active,
    monthlyPaymentAmount: 100,
    nextPaymentDate: DateTime(2026, 6, 5),
    paymentFrequency: PaymentFrequency.monthly,
  ),
  DebtModel(
    id: 'debt-car-loan',
    type: DebtType.borrowing,
    personName: 'Bank',
    description: 'Car loan — Toyota Vios',
    originalAmount: 15000,
    remainingAmount: 11500,
    startDate: DateTime(2024, 1, 1),
    dueDate: DateTime(2028, 1, 1),
    status: DebtStatus.active,
    monthlyPaymentAmount: 350,
    nextPaymentDate: DateTime(2026, 6, 1),
    paymentFrequency: PaymentFrequency.monthly,
  ),
  DebtModel(
    id: 'debt-bob',
    type: DebtType.lending,
    personName: 'Bob',
    description: 'Covered dinner tab',
    originalAmount: 120,
    remainingAmount: 0,
    startDate: DateTime(2026, 4, 10),
    status: DebtStatus.settled,
    monthlyPaymentAmount: 0,
    paymentFrequency: PaymentFrequency.monthly,
  ),
];

class DebtDataSourceMock implements DebtDataSource {
  @override
  Future<List<DebtModel>> fetchDebts({String? budgetProfileId}) async => _debts;

  @override
  Future<DebtModel?> fetchDebtById(String id) async =>
      _debts.where((d) => d.id == id).firstOrNull;

  @override
  Future<DebtModel> createDebt(DebtModel debt) async => debt;

  @override
  Future<DebtModel> updateDebt(DebtModel debt) async => debt;

  @override
  Future<void> deleteDebt(String id) async {}

  @override
  Future<List<DebtModel>> fetchDebtsByType(String type) async =>
      _debts.where((d) => d.type.name == type).toList();

  @override
  Future<List<DebtModel>> fetchDebtsByStatus(String status) async =>
      _debts.where((d) => d.status.name == status).toList();

  @override
  Future<DebtModel> payDebt(String id, {required double amount, double? fee}) async {
    final debt = _debts.firstWhere((d) => d.id == id);
    return DebtModel(
      id: debt.id, type: debt.type, personName: debt.personName,
      description: debt.description, originalAmount: debt.originalAmount,
      remainingAmount: (debt.remainingAmount - amount).clamp(0, double.infinity),
      startDate: debt.startDate, status: debt.status,
      monthlyPaymentAmount: debt.monthlyPaymentAmount,
      paymentFrequency: debt.paymentFrequency,
    );
  }
}
