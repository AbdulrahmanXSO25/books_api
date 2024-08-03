import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:books_api/book.dart';
import 'package:books_api/logger.dart';

void main() {
  late HttpServer server;
  final logger = Logger('test_server.log');

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5001);
    server.listen((HttpRequest request) async {
      logger.logRequest(request);

      if (request.uri.path == '/books' && request.method == 'GET') {
        await _handleGetBooks(request, logger);
      } else {
        _handleNotFound(request, logger);
      }
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
    final logFile = File('test_server.log');
    if (await logFile.exists()) {
      await logFile.delete();
    }
  });

  test('GET /books returns a list of books', () async {
    // Arrange
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:5001/books'));

    // Act
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final List<dynamic> jsonData = jsonDecode(responseBody);

    // Assert
    expect(response.statusCode, HttpStatus.ok);
    expect(jsonData, isA<List>());
    expect(jsonData.length, 10);
    expect(jsonData[0]['title'], 'To Kill a Mockingbird');
  });
}

Future<void> _handleGetBooks(HttpRequest request, Logger logger) async {
  try {
    final file = File('data/books.json');
    final List<dynamic> jsonData = jsonDecode(await file.readAsString());
    final List<Book> books = jsonData.map((json) => Book.fromJson(json)).toList();

    final response = request.response;
    final body = jsonEncode(books.map((book) => book.toJson()).toList());

    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(body);

    logger.logResponse(response);
  } catch (e) {
    final response = request.response;
    final body = 'Error reading books.json';

    response
      ..statusCode = HttpStatus.internalServerError
      ..write(body);

    logger.logResponse(response);
  } finally {
    await request.response.close();
  }
}

void _handleNotFound(HttpRequest request, Logger logger) async {
  final response = request.response;
  final body = 'Not Found';

  response
    ..statusCode = HttpStatus.notFound
    ..write(body);

  logger.logResponse(response);

  await request.response.close();
}