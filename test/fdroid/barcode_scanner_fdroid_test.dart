import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lo scanner usa ZXing FOSS e non mobile_scanner/ML Kit', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final scanner = File(
      'lib/reuse_class/barcode/barcode_scanner.dart',
    ).readAsStringSync();

    expect(pubspec, contains('flutter_zxing:'));
    expect(pubspec, isNot(contains('mobile_scanner:')));
    expect(scanner, contains('package:flutter_zxing/flutter_zxing.dart'));
    expect(
      scanner,
      isNot(contains('package:mobile_scanner/mobile_scanner.dart')),
    );
    expect(scanner, isNot(contains('MobileScanner')));
  });

  test('ads_connector resta commentato e non entra nella build F-Droid', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final adsCode = File(
      'lib/dashboard/ads_dashboard.code.dart',
    ).readAsStringSync();

    expect(pubspec, contains('# ads_connector:'));
    expect(
      pubspec,
      isNot(contains(RegExp(r'^\s+ads_connector:', multiLine: true))),
    );
    expect(adsCode, contains('ADS_CONNECTOR_DISABLED_FOR_FDROID'));
    expect(
      adsCode,
      isNot(
        contains(
          RegExp(
            r'''^import\s+["']package:ads_connector/ads_connector\.dart["'];''',
            multiLine: true,
          ),
        ),
      ),
    );
  });
}
