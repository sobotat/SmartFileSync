
import 'package:smart_file_sync/src/peer/PeerApi.dart';

class AppData {

  static AppData instance = AppData._();
  AppData._();

  PeerApi? peerApi;

  bool isPair() {
    return peerApi != null;
  }
}