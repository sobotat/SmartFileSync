
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:smart_file_sync/src/files/download/FileDownloader.dart';
import 'package:smart_file_sync/src/files/transfer/FileChunked.dart';

class NativeFileDownloader extends FileDownloader {

  @override
  Future<void> downloadFile(FileChunked fileChunked) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Save File'
    );

    if (selectedDirectory == null) throw Exception('Did not get Directory');

    await File('$selectedDirectory/${fileChunked.fileName}').writeAsBytes(fileChunked.fileBytes);
  }

}

FileDownloader getPlatformFileDownloader() => NativeFileDownloader();