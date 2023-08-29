
import 'dart:async';
import 'dart:convert';

import 'package:smart_file_sync/files/transfer/FileTransfer.dart';
import 'package:smart_file_sync/peer/MessageHandler.dart';
import 'package:smart_file_sync/peer/PeerApi.dart';

class FileSenderHandler extends MessageHandler {

  FileSenderHandler({
    required PeerApi peerApi,
    required FileTransfer fileTransfer,
  }) : _fileTransfer = fileTransfer, _peerApi = peerApi;

  final PeerApi _peerApi;
  final FileTransfer _fileTransfer;

  bool isSendingFile = false;
  List<List<int>> _chunkedBytes = [];
  Completer<void>? _completer;

  @override
  void handleMessage(String message) {
    var decoded = jsonDecode(message);
    print(decoded.toString());

    switch(decoded['type']) {
      case 'FileAccepted':
        _fileAccepted();
        break;
      case 'FileRejected':
        _fileRejected();
        break;
      case 'FileReceived':
        _fileReceived();
    }
  }

  Future<void> sendFile({
    required String fileName,
    required int fileSize,
    required int chunkCount,
    required List<List<int>> chunkedBytes,
  }) {
    isSendingFile = true;
    this._chunkedBytes = chunkedBytes;

    _peerApi.sendData(jsonEncode({
      'type':'FileInfo',
      'fileName': fileName,
      'fileSize': fileSize,
      'chunkCount': chunkCount
    }));

    _completer = Completer<void>();
    return _completer!.future;
  }

  Future<void> _fileAccepted() async {
    int index = 0;
    for (List<int> chunk in _chunkedBytes) {
      _peerApi.sendData(jsonEncode({
        'type':'FileData',
        'chunkIndex': index,
        'chunk': chunk
      }));

      index += 1;

      if(_fileTransfer.onProgress != null) {
        _fileTransfer.onProgress!(index / _chunkedBytes.length);
      }

      await Future.delayed(const Duration(milliseconds: 5));
    }

    await Future.delayed(const Duration(milliseconds: 15));
    _fileSendComplete();
  }

  void _fileSendComplete(){
    _peerApi.sendData(jsonEncode({
      'type': 'FileSendComplete'
    }));
  }

  void _fileRejected() {
    if (_completer != null) {
      _completer!.completeError(Exception('Receiver Rejected File'));
    }
    _resetSender();
  }

  void _fileReceived() {
    if (_completer != null) {
      _completer!.complete();
    }
    _resetSender();
  }

  void _resetSender() {
    _completer = null;
    isSendingFile = false;
    _chunkedBytes = [];
  }
}