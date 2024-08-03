import 'dart:io';

class Logger {
  final String filePath;

  Logger(this.filePath);

  void log(String message) async {
    final file = File(filePath);
    final now = DateTime.now();
    final logMessage = '${now.toIso8601String()} - $message\n';

    // Print to console
    print(logMessage);

    // Append to log file
    await file.writeAsString(logMessage, mode: FileMode.append);
  }

  void logRequest(HttpRequest request) {
    final message = 'Request: ${request.method} ${request.uri.path}';
    log(message);
  }

  void logResponse(HttpResponse response) {
    final message = 'Response: ${response.statusCode}';
    log(message);
  }
}