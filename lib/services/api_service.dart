import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/mission.dart';
import '../models/user_mission.dart';
import '../models/voucher.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ---------------------------------------------------------------------------
  // Autentikasi (Register, Login, Logout)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phoneNumber,
    required String birthDate,
  }) async {
    final url = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      url,
      headers: await _getHeaders(includeAuth: false),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'phone_number': phoneNumber,
        'birth_date': birthDate,
      }),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 201) {
      await _saveToken(responseData['access_token']);
      return {'success': true, 'message': responseData['message'], 'user_id': responseData['user']['id']};
    } else {
      return {'success': false, 'data': responseData};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    // REVISI: Periksa apakah body respons kosong atau tidak valid sebelum decode
    if (response.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server.'};
    }

    try {
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveToken(responseData['access_token']);
        return {'success': true, 'message': responseData['message'], 'user_id': responseData['user']['id']};
      } else {
        // REVISI: Mengembalikan seluruh responseData untuk error
        return {'success': false, 'data': responseData};
      }
    } on FormatException catch (e) {
      print('Error decoding JSON for login: $e, Response body: ${response.body}');
      return {'success': false, 'message': 'Invalid response format from server.'};
    } catch (e) {
      print('Unexpected error during login response processing: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  Future<bool> logout() async {
    final url = Uri.parse('$_baseUrl/logout');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      await _deleteToken();
      return true;
    } else {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Data Pengguna (User)
  // ---------------------------------------------------------------------------

  Future<User> getUserData(int userId) async {
    final url = Uri.parse('$_baseUrl/user');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load user data: ${response.body}');
    }
  }

  // REVISI: Mengembalikan List<UserMission>
  Future<List<UserMission>> getMissions() async {
    final url = Uri.parse('$_baseUrl/missions/active');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> userMissionData = data['missions'];
      return userMissionData.map((json) => UserMission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load active missions: ${response.body}');
    }
  }

  Future<List<UserMission>> getUserMissionsByStatus(int userId, List<String> statuses) async {
    // Bangun URL dengan parameter query untuk statuses
    final Map<String, dynamic> queryParams = {
      'statuses[]': statuses, // Kirim sebagai array parameter
    };
    final url = Uri.parse('$_baseUrl/user-missions-history/$userId').replace(queryParameters: queryParams);

    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> userMissionData = data['user_missions'];
      return userMissionData.map((json) => UserMission.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load user missions history: ${response.body}');
    }
  }

  Future<bool> submitMissionProof({
    required int userMissionId,
    required String proofUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/missions/$userMissionId/submit-proof');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'proof_url': proofUrl,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to submit proof: ${response.body}');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Voucher
  // ---------------------------------------------------------------------------

  Future<List<Voucher>> fetchVouchers() async {
    final url = Uri.parse('$_baseUrl/vouchers');
    final response = await http.get(
      url,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> voucherData = data['vouchers'];
      return voucherData.map((json) => Voucher.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load vouchers: ${response.body}');
    }
  }

  Future<bool> exchangeVoucher({
    required int voucherId,
  }) async {
    final url = Uri.parse('$_baseUrl/vouchers/exchange');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'voucher_id': voucherId,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('Failed to exchange voucher: ${response.body}');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Reward (Tukar Uang)
  // ---------------------------------------------------------------------------

  Future<bool> submitReward({
    required String phone,
    required String email,
    required int balance,
  }) async {
    final url = Uri.parse('$_baseUrl/rewards/exchange');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode({
        'phone': phone,
        'email': email,
        'amount': balance,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('Failed to submit reward: ${response.body}');
      return false;
    }
  }
}

