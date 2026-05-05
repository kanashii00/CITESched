import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // Login first to get a session token
  print('Attempting to call getDashboardStats...');

  try {
    // Call the endpoint directly
    final response = await http.post(
      Uri.parse('http://localhost:8083/admin'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: '{"method":"getDashboardStats","params":{}}',
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  } catch (e, stack) {
    print('Error: $e');
    print('Stack: $stack');
  }

  exit(0);
}