import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class BackendService {
  final String baseUrl;

  BackendService({String? baseUrl}) : baseUrl = baseUrl ?? AuthsignalConfig.backendUrl;

  Future<TokenResponse?> getRegistrationToken(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/registration-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TokenResponse(
          token: data['token'],
          state: data['state'],
          message: data['message'],
        );
      } else {
        print('Failed to get registration token: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Backend connection error: $e');
      print('Make sure your backend is running at: $baseUrl');
      return null;
    }
  }

  Future<ChallengeTokenResponse?> getChallengeToken({
    required String userId,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/challenge-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChallengeTokenResponse(
          token: data['token'],
          state: data['state'],
          challengeId: data['challengeId'],
          message: data['message'],
        );
      } else {
        print('Failed to get challenge token: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Backend connection error: $e');
      print('Make sure your backend is running at: $baseUrl');
      return null;
    }
  }

  Future<ValidationResponse?> validateToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ValidationResponse(
          isValid: data['isValid'] ?? false,
          state: data['state'],
          userId: data['userId'],
        );
      }
      return null;
    } catch (e) {
      print('Validation error: $e');
      return null;
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class TokenResponse {
  final String token;
  final String? state;
  final String? message;

  TokenResponse({
    required this.token,
    this.state,
    this.message,
  });
}

class ChallengeTokenResponse {
  final String token;
  final String? state;
  final String? challengeId;
  final String? message;

  ChallengeTokenResponse({
    required this.token,
    this.state,
    this.challengeId,
    this.message,
  });
}

class ValidationResponse {
  final bool isValid;
  final String? state;
  final String? userId;

  ValidationResponse({
    required this.isValid,
    this.state,
    this.userId,
  });
}

