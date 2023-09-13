
import 'dart:async';
import 'dart:convert';
import 'package:smart_file_sync/src/files/transfer/FileChunked.dart';
import 'package:smart_file_sync/src/files/transfer/FileTransfer.dart';
import 'package:smart_file_sync/src/peer/MessageHandler.dart';
import 'package:smart_file_sync/src/peer/PeerApi.dart';

class FileReceiverHandler extends MessageHandler {

  FileReceiverHandler({
    required PeerApi peerApi,
    required FileTransfer fileTransfer,
  }) : _peerApi = peerApi, _fileTransfer = fileTransfer;

  final PeerApi _peerApi;
  final FileTransfer _fileTransfer;

  bool isReceivingFile = false;
  FileChunked? _fileChunked;
  Completer<FileChunked>? _completer;

  @override
  void handleMessage(String message) {
    var decoded = jsonDecode(message);

    switch(decoded['type']) {
      case 'FileInfo':
        _receivedNewFileInfo(decoded);
        break;
      case 'FileData':
        _receivedFileData(decoded);
        break;
      case 'FileSendComplete':
        _receivedFileSendComplete();
        break;
    }
  }

  Future<FileChunked> acceptFile() {
    print('File Accepted');
    _peerApi.sendData(jsonEncode({
      'type': 'FileAccepted',
    }));
    isReceivingFile = true;

    _completer = Completer<FileChunked>();
    return _completer!.future;
  }

  void rejectFile() {
    print('File Rejected');
    _peerApi.sendData(jsonEncode({
      'type': 'FileRejected',
    }));
    _resetReceiver();
  }

  void _receivedNewFileInfo(Map<String, dynamic> info) {
    print('File Info: $info');
    _fileChunked = FileChunked(
      fileName: info['fileName'],
      fileSize: info['fileSize'],
      chunkCount: info['chunkCount'],
    );

    _fileTransfer.onReceivedInfo(_fileChunked!);
  }

  void _receivedFileData(Map<String, dynamic> data) {
    if (_fileChunked == null) {
      throw Exception('Error Received Data: Dont received file info');
    }

    print('File Data: ${data['chunkIndex']}');
    List<int> chunk = [];
    for (dynamic item in data['chunk']) {
      chunk.add(int.parse(item.toString()));
    }

    _fileChunked!.addChunk(
      index: data['chunkIndex'],
      chunk: chunk,
    );

    if(_fileTransfer.onProgress != null) {
      _fileTransfer.onProgress!(_fileChunked!.addedChunks / _fileChunked!.chunkCount);
    }
  }

  void _receivedFileSendComplete() {
    if (_fileChunked == null) return;

    List<int> missing = _fileChunked!.checkForMissingChunks();

    if (missing.isNotEmpty) {
      _peerApi.sendData(jsonEncode({
        'type': 'FileMissingBytes',
        'missing': missing,
      }));
      _fileTransfer.neededResendMissing = true;
      return;
    }

    _completer!.complete(_fileChunked);
    _sendFileReceived();
  }

  void _sendFileReceived(){
    _peerApi.sendData(jsonEncode({
      'type': 'FileReceived',
    }));
    _resetReceiver();
  }

  void _resetReceiver() {
    _completer = null;
    isReceivingFile = false;
    _fileChunked = null;
  }
}