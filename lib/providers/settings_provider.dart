import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  String _apiUrl = AppConstants.defaultApiUrl;
  String _selectedModel = AppConstants.defaultModel;
  bool _isConnected = false;
  bool _isCheckingConnection = false;

  String get apiUrl => _apiUrl;
  String get selectedModel => _selectedModel;
  bool get isConnected => _isConnected;
  bool get isCheckingConnection => _isCheckingConnection;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _apiUrl = await _storageService.getApiUrl();
    _selectedModel = await _storageService.getSelectedModel();
    notifyListeners();
    checkConnection();
  }

  Future<void> updateApiUrl(String url) async {
    _apiUrl = url;
    await _storageService.saveApiUrl(url);
    notifyListeners();
    checkConnection();
  }

  Future<void> updateModel(String model) async {
    _selectedModel = model;
    await _storageService.saveSelectedModel(model);
    notifyListeners();
  }

  Future<bool> checkConnection() async {
    _isCheckingConnection = true;
    notifyListeners();

    _isConnected = await _apiService.checkHealth(_apiUrl);
    _isCheckingConnection = false;
    notifyListeners();
    return _isConnected;
  }
}
