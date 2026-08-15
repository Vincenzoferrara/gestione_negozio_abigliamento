import 'package:flutter_test/flutter_test.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/query_mgws/mgws_availability.dart';

class _FakeMgwsAvailabilityChecker implements MgwsAvailabilityChecker {
  _FakeMgwsAvailabilityChecker({required this.result, this.error});

  final bool result;
  final Object? error;
  var calls = 0;

  @override
  Future<bool> check() async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  group('MgwsAvailability', () {
    test('stores the checker result when refreshed', () async {
      final checker = _FakeMgwsAvailabilityChecker(result: true);
      final availability = MgwsAvailability(checker: checker);

      final result = await availability.refresh();

      expect(result, isTrue);
      expect(availability.isAvailable, isTrue);
      expect(checker.calls, 1);
    });

    test('stores false when the checker reports unavailable', () async {
      final checker = _FakeMgwsAvailabilityChecker(result: false);
      final availability = MgwsAvailability(checker: checker);

      final result = await availability.refresh();

      expect(result, isFalse);
      expect(availability.isAvailable, isFalse);
    });

    test(
      'returns false and clears availability when checking throws',
      () async {
        final checker = _FakeMgwsAvailabilityChecker(
          result: true,
          error: StateError('endpoint missing'),
        );
        final availability = MgwsAvailability(checker: checker);

        final result = await availability.refresh();

        expect(result, isFalse);
        expect(availability.isAvailable, isFalse);
      },
    );

    test('clears a previously available state explicitly', () async {
      final availability = MgwsAvailability(
        checker: _FakeMgwsAvailabilityChecker(result: true),
      );
      await availability.refresh();

      availability.markUnavailable();

      expect(availability.isAvailable, isFalse);
    });
  });
}
