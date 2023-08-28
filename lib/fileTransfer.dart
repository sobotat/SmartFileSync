
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smart_file_sync/fileChunked.dart';
import 'package:smart_file_sync/fileReceiverHandler.dart';
import 'package:smart_file_sync/fileSenderHandler.dart';
import 'package:smart_file_sync/messageHandler.dart';
import 'package:smart_file_sync/peerApi.dart';

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
    );

    updateHandler(false);
  }

  Future<FileChunked?> acceptFile() {
    if (messageHandler is! FileReceiverHandler) return Future(() => null);
    var handler = messageHandler as FileReceiverHandler;
    return handler.acceptFile();
  }

  void rejectFile() {
    if (messageHandler is! FileReceiverHandler) return;
    var handler = messageHandler as FileReceiverHandler;
    handler.rejectFile();
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