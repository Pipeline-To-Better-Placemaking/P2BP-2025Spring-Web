import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For persistence storage

class HomePageState extends ChangeNotifier {
  String _currentPage = "Home"; // Default page should be "Home"
  bool _isLoggedIn = false;

  String get currentPage => _currentPage;
  bool get isLoggedIn => _isLoggedIn;

  // Load the page and login state from SharedPreferences
  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _currentPage = prefs.getString('currentPage') ?? "Home"; // Ensure default is "Home"
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    notifyListeners(); // Notify listeners to rebuild the UI
  }

  // Update the current page and persist it
  Future<void> updatePage(String newPage) async {
    final prefs = await SharedPreferences.getInstance();
    _currentPage = newPage;
    await prefs.setString('currentPage', newPage); // Save the new page
    notifyListeners();
  }

  // Set the login status and persist it
  Future<void> setLoggedIn(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = status;
    await prefs.setBool('isLoggedIn', status); // Save the login status
    notifyListeners();
  }

  // Check if the user is logged in and persist the state
  Future<void> checkUserAuth() async {
    // Simulate Firebase Auth check
    bool loggedIn = false; // Replace this with actual auth check logic
    if (loggedIn) {
      await setLoggedIn(true);
    } else {
      await setLoggedIn(false);
    }
  }
}
