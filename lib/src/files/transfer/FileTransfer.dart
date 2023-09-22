
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_file_sync/src/files/transfer/FileChunked.dart';
import 'package:smart_file_sync/src/files/transfer/FileReceiverHandler.dart';
import 'package:smart_file_sync/src/files/transfer/FileSenderHandler.dart';
import 'package:smart_file_sync/src/peer/MessageHandler.dart';
import 'package:smart_file_sync/src/peer/PeerApi.dart';

class FileTransfer {

  FileTransfer({
    required this.peerApi,
    required this.onReceivedInfo,
    this.onProgress,
  }) {
    updateHandler(false);
  }

  PeerApi peerApi;
  late MessageHandler messageHandler;
  Function(FileChunked fileInfo) onReceivedInfo;
  Function(double progress)? onProgress;
  bool neededResendMissing = false;

  Future<void> sendFile({
    required String fileName,
    required List<int> fileBytes,
  }) async {

    updateHandler(true);
    if (messageHandler is! FileSenderHandler) return;
    FileSenderHandler handler = messageHandler as FileSenderHandler;

    if (handler.isSendingFile) {
      debugPrint('Already sending file');
      return;
    }

    List<List<int>> chunkedBytes = await _chunkData(fileBytes, 15000)
        .onError((error, stackTrace) {
          throw Exception('File Chunking Failed by: $error');
        });

    debugPrint('File Chunked to ${chunkedBytes.length} Chunks');

    await handler.sendFile(
      fileName: fileName,
      fileSize: fileBytes.length,
      chunkCount: chunkedBytes.length,
      chunkedBytes: chunkedBytes,
    ).onError((error, stackTrace) {
      updateHandler(false);
      if(error != null) throw error;
    });

    updateHandler(false);
  }

  Future<FileChunked?> acceptFile() {
    neededResendMissing = false;
    if (messageHandler is! FileReceiverHandler) return Future(() => null);
    var handler = messageHandler as FileReceiverHandler;
    return handler.acceptFile();
  }

  void rejectFile() {
    neededResendMissing = false;
    if (messageHandler is! FileReceiverHandler) return;
    var handler = messageHandler as FileReceiverHandler;
    handler.rejectFile();
  }

  void dispose() {
    cancelFileTransfer();
  }

  void cancelFileTransfer() {
    String message = jsonEncode({
      'type': 'FileCanceled',
    });
    peerApi.sendData(message);
    messageHandler.handleMessage(message);
  }

  Future<List<List<int>>> _chunkData(List<int> fileBytes, int chunkSize) {
    return Future<List<List<int>>>(() {
      int index = 0;
      int maxIndex = (fileBytes.length / 15000).ceil();
      List<List<int>> out = [];

      while(index < maxIndex) {
        List<int> chunkBytes = [];

        int startIndex = index * chunkSize;
        int endIndex = (index + 1) * chunkSize;

        for(int i = startIndex; i < endIndex; i++) {
          if (i > fileBytes.length - 1) break;
          chunkBytes.add(fileBytes[i]);
        }

        index += 1;
        out.add(chunkBytes);
      }

      return out;
    });
  }

  void updateHandler(bool isSendingFile) {
    neededResendMissing = false;
    messageHandler = isSendingFile
      ? FileSenderHandler(
      peerApi: peerApi,
      fileTransfer: this,
    ) : FileReceiverHandler(
      peerApi: peerApi,
      fileTransfer: this,
    );
    peerApi.onData = (data) => messageHandler.handleMessage(data);
  }
}

class FileCanceledException implements Exception {

}

class FileRejectedException implements Exception {

}