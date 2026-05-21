import 'package:keep_track/features/finance/modules/planned_payment/data/datasources/planned_payment_datasource.dart';
import 'package:keep_track/features/finance/modules/planned_payment/data/models/planned_payment_model.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/payment_enums.dart';

final _payments = <PlannedPaymentModel>[
  PlannedPaymentModel(
    id: 'pp-electricity',
    name: 'Electricity Bill',
    payee: 'TNB',
    amount: 130,
    category: PaymentCategory.utilities,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime(2026, 6, 18),
    lastPaymentDate: DateTime(2026, 5, 18),
    status: PaymentStatus.active,
  ),
  PlannedPaymentModel(
    id: 'pp-internet',
    name: 'Internet',
    payee: 'Unifi',
    amount: 99,
    category: PaymentCategory.utilities,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime(2026, 6, 10),
    lastPaymentDate: DateTime(2026, 5, 10),
    status: PaymentStatus.active,
  ),
  PlannedPaymentModel(
    id: 'pp-insurance',
    name: 'Car Insurance',
    payee: 'AIA',
    amount: 180,
    category: PaymentCategory.insurance,
    frequency: PaymentFrequency.quarterly,
    nextPaymentDate: DateTime(2026, 8, 1),
    lastPaymentDate: DateTime(2026, 5, 1),
    status: PaymentStatus.active,
  ),
  PlannedPaymentModel(
    id: 'pp-phone',
    name: 'Phone Plan',
    payee: 'Maxis',
    amount: 88,
    category: PaymentCategory.bills,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime(2026, 6, 5),
    lastPaymentDate: DateTime(2026, 5, 5),
    status: PaymentStatus.active,
  ),
];

class PlannedPaymentDataSourceMock implements PlannedPaymentDataSource {
  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPayments() async => _payments;

  @override
  Future<PlannedPaymentModel?> fetchPlannedPaymentById(String id) async =>
      _payments.where((p) => p.id == id).firstOrNull;

  @override
  Future<PlannedPaymentModel> createPlannedPayment(PlannedPaymentModel payment) async => payment;

  @override
  Future<PlannedPaymentModel> updatePlannedPayment(PlannedPaymentModel payment) async => payment;

  @override
  Future<void> deletePlannedPayment(String id) async {}

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByStatus(String status) async =>
      _payments.where((p) => p.status.name == status).toList();

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByCategory(String category) async =>
      _payments.where((p) => p.category.name == category).toList();

  @override
  Future<List<PlannedPaymentModel>> fetchUpcomingPayments() async {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 7));
    return _payments.where((p) => p.nextPaymentDate.isAfter(now) && p.nextPaymentDate.isBefore(cutoff)).toList();
  }
}
