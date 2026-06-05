@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'test_env.dart';

void main() {
  test('server is reachable', () async {
    final response = await http.get(Uri.parse(TestEnv.baseUrl));
    expect(response.statusCode, anyOf(200, 302, 401));
  });
}
