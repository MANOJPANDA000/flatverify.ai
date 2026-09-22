import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/account/session_controller.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'flatverify_session_test_',
    );
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'new app session restores guest access and preserves all saved reports',
    () async {
      final first = SessionController();
      await first.initialize();
      await first.reports.add({'auditName': 'Temporary'});
      final account = await Hive.openBox('account_test_reports');
      await account.add({'auditName': 'Permanent'});
      final legacy = await Hive.openBox('local_audits');
      await legacy.add({'auditName': 'Previous app'});
      await first.enterGuest();
      expect(
        first.reports.length,
        1,
      ); // Navigation/background does not clear it.
      await Hive.close();
      final second = SessionController();
      await second.initialize();
      expect(second.reports.length, 1);
      expect(second.entered, isTrue);
      expect((await Hive.openBox('account_test_reports')).length, 1);
      expect((await Hive.openBox('local_audits')).length, 1);
    },
  );

  test('guest transfer keeps data and does not duplicate on retry', () async {
    final guest = await Hive.openBox('guest');
    final account = await Hive.openBox('account');
    final data = {
      'auditName': 'Room report',
      'timestamp': '2026-09-18T12:00:00',
    };
    await guest.put(0, data);
    await SessionController.transferGuestReports(guest, account);
    expect(guest, isEmpty);
    expect(account.values.single['auditName'], 'Room report');
    await guest.put(0, data); // Simulate a retry after interrupted cleanup.
    await SessionController.transferGuestReports(guest, account);
    expect(account.length, 1);
    final otherAccount = await Hive.openBox('other_account');
    expect(otherAccount, isEmpty);
  });
}
