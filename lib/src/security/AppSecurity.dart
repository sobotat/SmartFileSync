import 'package:flutter/cupertino.dart';

class AppSecurity extends ChangeNotifier {

  static final AppSecurity instance = AppSecurity();

  bool _isInit = false;
  bool get isInit => _isInit;
  bool _logged = false;

  Future<void> init() async {
    if (_isInit) {
      return;
    }

    _isInit = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password, {bool? rememberMe}) async {
    _logged = true;
    return _logged;
  }

  Future<void> logout() async {
    _logged = false;
    notifyListeners();
  }

  bool isLoggedIn(){
    return _logged;
  }
}