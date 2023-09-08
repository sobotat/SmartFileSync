import 'package:smart_file_sync/src/files/download/FileDownloaderLocator.dart'
  if (dart.library.html) 'package:smart_file_sync/src/files/download/WebFileDownloader.dart'
  if (dart.library.io) 'package:smart_file_sync/src/files/download/NativeFileDownloader.dart';
import 'package:smart_file_sync/src/files/transfer/FileChunked.dart';

abstract class FileDownloader {

  static FileDownloader instance = getPlatformFileDownloader();

  void downloadFile(FileChunked fileChunked);
}