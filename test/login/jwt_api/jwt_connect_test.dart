import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/error_list.dart';
import 'package:gestione_negozio_abbigliamento/login/jwt_api/jwt_connect.dart';
import 'package:http/http.dart' as http;

class _NotFoundJwtClient extends http.BaseClient {
  final requests = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request) requests.add(request.body);
    return http.StreamedResponse(const Stream<List<int>>.empty(), 404);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JwtConnect', () {
    late Map<String, String> secureStorage;

    setUp(() async {
      secureStorage = <String, String>{};
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        secureStorage,
      );
      await JwtConnect().disconnect();
    });

    tearDown(() {
      JwtConnect().setHttpClientForTesting(http.Client());
    });

    test(
      'fails before sending credentials when JWT endpoint is missing',
      () async {
        final client = _NotFoundJwtClient();
        JwtConnect().setHttpClientForTesting(client);

        await expectLater(
          JwtConnect().connect(
            siteUrl: 'https://example.test',
            username: 'admin',
            password: 'secret',
          ),
          throwsA(isA<InvalidCredentialsException>()),
        );

        expect(client.requests, isNotEmpty);
        expect(client.requests.any((body) => body.contains('admin')), isFalse);
        expect(client.requests.any((body) => body.contains('secret')), isFalse);
      },
    );
  });
}
