import 'package:flutter_test/flutter_test.dart';
import 'package:fq4_flutter/poc/infrastructure/poc_definition.dart';
import 'package:fq4_flutter/poc/infrastructure/poc_logger.dart';

void main() {
  group('PocLogger', () {
    late PocLogger logger;

    setUp(() {
      logger = PocLogger();
    });

    test('starts empty', () {
      expect(logger.entries, isEmpty);
      expect(logger.length, 0);
      expect(logger.hasErrors, false);
      expect(logger.firstError, isNull);
    });

    test('convenience methods add entries with correct severity', () {
      logger.debug(LogSystem.combat, 'debug msg');
      logger.info(LogSystem.ai, 'info msg');
      logger.warn(LogSystem.render, 'warn msg');
      logger.error(LogSystem.physics, 'error msg');

      expect(logger.length, 4);
      expect(logger.entries[0].severity, LogSeverity.debug);
      expect(logger.entries[1].severity, LogSeverity.info);
      expect(logger.entries[2].severity, LogSeverity.warn);
      expect(logger.entries[3].severity, LogSeverity.error);
    });

    test('entries preserve system', () {
      logger.info(LogSystem.combat, 'combat log');
      logger.info(LogSystem.ai, 'ai log');
      expect(logger.entries[0].system, LogSystem.combat);
      expect(logger.entries[1].system, LogSystem.ai);
    });

    test('entries preserve message and detail', () {
      logger.error(LogSystem.combat, 'error msg', detail: 'stack trace');
      expect(logger.entries[0].message, 'error msg');
      expect(logger.entries[0].detail, 'stack trace');
    });

    test('entries preserve data', () {
      logger.info(LogSystem.combat, 'msg', data: {'key': 42});
      expect(logger.entries[0].data, {'key': 42});
    });

    test('bySeverity filters correctly', () {
      logger.debug(LogSystem.combat, 'd1');
      logger.info(LogSystem.combat, 'i1');
      logger.debug(LogSystem.ai, 'd2');
      logger.warn(LogSystem.combat, 'w1');

      final debugs = logger.bySeverity(LogSeverity.debug);
      expect(debugs.length, 2);
      expect(debugs[0].message, 'd1');
      expect(debugs[1].message, 'd2');
    });

    test('bySystem filters correctly', () {
      logger.info(LogSystem.combat, 'c1');
      logger.info(LogSystem.ai, 'a1');
      logger.warn(LogSystem.combat, 'c2');

      final combat = logger.bySystem(LogSystem.combat);
      expect(combat.length, 2);
    });

    test('filter with both severity and system', () {
      logger.debug(LogSystem.combat, 'd-c');
      logger.info(LogSystem.combat, 'i-c');
      logger.info(LogSystem.ai, 'i-a');
      logger.warn(LogSystem.combat, 'w-c');

      final filtered = logger.filter(
        severities: {LogSeverity.info},
        systems: {LogSystem.combat},
      );
      expect(filtered.length, 1);
      expect(filtered[0].message, 'i-c');
    });

    test('filter with null filters returns all', () {
      logger.info(LogSystem.combat, 'msg1');
      logger.warn(LogSystem.ai, 'msg2');
      final all = logger.filter();
      expect(all.length, 2);
    });

    test('hasErrors detects error severity', () {
      logger.info(LogSystem.combat, 'info');
      expect(logger.hasErrors, false);

      logger.error(LogSystem.combat, 'error');
      expect(logger.hasErrors, true);
    });

    test('hasErrors detects critical severity', () {
      logger.log(LogSeverity.critical, LogSystem.combat, 'critical');
      expect(logger.hasErrors, true);
    });

    test('firstError returns first error entry', () {
      logger.info(LogSystem.combat, 'info');
      logger.error(LogSystem.combat, 'first error');
      logger.error(LogSystem.ai, 'second error');

      final first = logger.firstError;
      expect(first, isNotNull);
      expect(first!.message, 'first error');
    });

    test('maxEntries enforces limit', () {
      final smallLogger = PocLogger(maxEntries: 5);
      for (int i = 0; i < 10; i++) {
        smallLogger.info(LogSystem.combat, 'msg $i');
      }
      expect(smallLogger.length, 5);
      expect(smallLogger.entries.first.message, 'msg 5');
      expect(smallLogger.entries.last.message, 'msg 9');
    });

    test('clear removes all entries', () {
      logger.info(LogSystem.combat, 'msg');
      logger.warn(LogSystem.ai, 'warn');
      logger.clear();
      expect(logger.length, 0);
      expect(logger.entries, isEmpty);
    });

    test('onLogAdded callback fires for each entry', () {
      final added = <PocLogEntry>[];
      logger.onLogAdded = (entry) => added.add(entry);

      logger.info(LogSystem.combat, 'msg1');
      logger.warn(LogSystem.ai, 'msg2');

      expect(added.length, 2);
      expect(added[0].message, 'msg1');
      expect(added[1].message, 'msg2');
    });

    test('entries list is unmodifiable', () {
      logger.info(LogSystem.combat, 'msg');
      expect(() => logger.entries.add(PocLogEntry(
        severity: LogSeverity.info,
        system: LogSystem.combat,
        message: 'injected',
      )), throwsUnsupportedError);
    });
  });

  group('PocLogEntry', () {
    test('formatted output includes timestamp, severity, system, message', () {
      final entry = PocLogEntry(
        timestamp: DateTime(2026, 1, 15, 14, 30, 45, 123),
        severity: LogSeverity.warn,
        system: LogSystem.combat,
        message: 'test message',
      );
      final formatted = entry.formatted;
      expect(formatted, contains('14:30:45.123'));
      expect(formatted, contains('WARN'));
      expect(formatted, contains('[combat]'));
      expect(formatted, contains('test message'));
    });
  });
}
