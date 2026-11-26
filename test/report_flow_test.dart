import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_the_health/core/database/pending_report_queue.dart';
import 'package:what_the_health/features/report_submission/models/outbreak_report.dart';
import 'package:what_the_health/features/report_submission/repository/mock_report_repository.dart';
import 'package:what_the_health/features/report_submission/viewmodel/report_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ReportViewModel> makeVm() async {
    final vm = ReportViewModel(MockReportRepository());
    await vm.onLogin('u1');
    return vm;
  }

  void fillForm(ReportViewModel vm) {
    vm.setDisease('Dengue Fever');
    vm.latitude = 2.2964;
    vm.longitude = 111.8917;
  }

  test('submitting without a disease or location is rejected', () async {
    final vm = await makeVm();
    final ok = await vm.submitReport(userId: 'u1', symptoms: 'fever and headache');
    expect(ok, isFalse);
    expect(vm.errorMessage, isNotNull);
    expect(vm.reports, isEmpty);
  });

  test('a submitted report is pending and creates a "submitted" audit entry', () async {
    final vm = await makeVm();
    fillForm(vm);
    final ok = await vm.submitReport(userId: 'u1', symptoms: 'fever and headache');

    expect(ok, isTrue);
    expect(vm.pendingReports.length, 1);
    expect(vm.approvedReports, isEmpty);
    expect(vm.auditLogs.map((l) => l.action), ['submitted']);
    expect(vm.selectedDisease, isNull); // form was reset
  });

  test('approving moves the report to verified and is audited', () async {
    final vm = await makeVm();
    fillForm(vm);
    await vm.submitReport(userId: 'u1', symptoms: 'fever and headache');

    final id = vm.pendingReports.first.id;
    await vm.reviewReport(reportId: id, officerId: 'o1', approve: true, reason: 'confirmed');

    expect(vm.pendingReports, isEmpty);
    expect(vm.approvedReports.length, 1);
    expect(vm.approvedReports.first.status, ReportStatus.approved);
    expect(vm.auditLogs.map((l) => l.action), ['submitted', 'approved']);
    expect(vm.auditLogs.last.performedBy, 'o1');
    expect(vm.approvedByDisease, {'Dengue Fever': 1});
  });

  test('clear() removes all data (used on logout)', () async {
    final vm = await makeVm();
    fillForm(vm);
    await vm.submitReport(userId: 'u1', symptoms: 'fever and headache');
    vm.clear();

    expect(vm.reports, isEmpty);
    expect(vm.auditLogs, isEmpty);
    expect(vm.pendingCount, 0);
  });

  test('offline queue stores per user, caps at 5, and removes items', () async {
    final q = PendingReportQueue();
    PendingReport make(String id, String user) => PendingReport(
      id: id,
      userId: user,
      disease: 'Dengue Fever',
      symptoms: 'fever and headache',
      latitude: 2.29,
      longitude: 111.83,
      isAnonymous: false,
    );

    for (var i = 0; i < 5; i++) {
      expect(await q.add(make('a$i', 'u1')), isTrue);
    }
    expect(await q.add(make('a5', 'u1')), isFalse); // sixth is refused
    expect(await q.add(make('b0', 'u2')), isTrue); // other user is unaffected
    expect((await q.forUser('u1')).length, 5);

    await q.remove('a0');
    expect((await q.forUser('u1')).length, 4);
  });

  test('an OutbreakReport survives a JSON round trip', () {
    final r = OutbreakReport(
      id: 'r1',
      userId: 'u1',
      disease: 'Tuberculosis (TB)',
      symptoms: 'cough for three weeks',
      latitude: 2.29,
      longitude: 111.83,
      locationName: 'Sibu',
      isAnonymous: true,
      createdAt: DateTime.utc(2026, 11, 26, 8, 30),
    );
    final back = OutbreakReport.fromJson(r.toJson());

    expect(back.id, 'r1');
    expect(back.disease, 'Tuberculosis (TB)');
    expect(back.isAnonymous, isTrue);
    expect(back.status, ReportStatus.pending);
    expect(back.createdAt, r.createdAt);
  });
}