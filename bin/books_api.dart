import 'dart:convert';
import 'dart:io';
import 'package:books_api/book.dart';
import 'package:books_api/logger.dart';

void main() async {
  final logger = Logger('server.log');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5001);
  print('Server listening on port ${server.port}');

  await for (HttpRequest request in server) {
    logger.logRequest(request);

    if (request.uri.path == '/books' && request.method == 'GET') {
      await _handleGetBooks(request, logger);
    } else {
      _handleNotFound(request, logger);
    }
  }
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
