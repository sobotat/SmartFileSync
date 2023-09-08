
import 'dart:convert';
import 'dart:html';

import 'package:smart_file_sync/src/files/download/FileDownloader.dart';
import 'package:smart_file_sync/src/files/transfer/FileChunked.dart';

class WebFileDownloader extends FileDownloader {
  @override
  void downloadFile(FileChunked fileChunked) {
    var bytes = fileChunked.fileBytes;
    final anchor = AnchorElement(
        href: "data:application/octet-stream;charset=utf-16le;base64,${base64Encode(bytes)}")
      ..setAttribute("download", fileChunked.fileName)
      ..click();
  }
}

FileDownloader getPlatformFileDownloader() => WebFileDownloader();