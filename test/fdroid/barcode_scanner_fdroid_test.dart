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
}
