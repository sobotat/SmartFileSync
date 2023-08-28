
import 'dart:async';
import 'dart:convert';
import 'package:smart_file_sync/fileChunked.dart';
import 'package:smart_file_sync/fileTransfer.dart';
import 'package:smart_file_sync/messageHandler.dart';
import 'package:smart_file_sync/peerApi.dart';

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

    switch(decoded['type']){
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

  void rejectedFile() {
    print('File Rejected');
    _peerApi.sendData(jsonEncode({
      'type': 'FileRejected',
    }));
    isReceivingFile = false;
    _fileChunked = null;
  }

  void _receivedNewFileInfo(Map<String, dynamic> info) {
    print('File Info: $info');
    _fileChunked = FileChunked(
      fileName: info['fileName'],
      fileSize: info['fileSize'],
      chunkCount: info['chunkCount'],
    );

    //TODO: make UI accept
    acceptFile().then((value) {
      var bytes = value.fileBytes;
      print('N${value.fileName} FS${value.fileSize} BS${bytes.length}');
    });
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
  }

  void _receivedFileSendComplete() {
    if (_fileChunked == null) return;

    List<int> missing = _fileChunked!.checkForMissingChunks();

    if (missing.isNotEmpty) {
      //TODO: implement missing resent and remove _sendFileReceived
      _sendFileReceived();
      _completer!.completeError(Exception('Missing Chunks $missing'));
      return;
    }
    _sendFileReceived();
    _completer!.complete(_fileChunked);
  }

  void _sendFileReceived(){
    _peerApi.sendData(jsonEncode({
      'type': 'FileReceived',
    }));
  }

  void _resetReceiver() {
    _completer = null;
    isReceivingFile = false;
    _fileChunked = null;
  }

  // void rec(String data) {
  //   Map<String, dynamic> decoded = jsonDecode(data);
  //   String fileName = decoded['fileName'];
  //
  //   if (decoded['index'] == 0) {
  //     fileReceived = 0;
  //     fileAccepted = false;
  //     fileBuffer = [];
  //     await showDialog<String>(
  //         context: context,
  //         builder: (BuildContext context) => AcceptDialog(
  //               fileName: fileName,
  //               onSelected: (value) {
  //                 fileAccepted = value;
  //               },
  //             ));
  //
  //     if (!fileAccepted) {
  //       debugPrint('File not accepted');
  //       return;
  //     }
  //   }
  //
  //   List<int> bytes =
  //       (decoded['data'] as List<dynamic>).map((e) => e as int).toList();
  //   if (fileBuffer.length < decoded['maxIndex']) {
  //     while (fileBuffer.length < decoded['maxIndex']) {
  //       fileBuffer.add([]);
  //     }
  //   }
  //   fileBuffer[decoded['index']] = bytes;
  //   debugPrint(
  //       'File Progress [${decoded['index'] + 1}/${decoded['maxIndex']}]');
  //
  //   fileReceived += 1;
  //   debugPrint('Received $fileReceived');
  //   if (fileReceived == decoded['maxIndex'] && fileAccepted) {
  //     final List<int> buffer = [];
  //     for (List<int> item in fileBuffer) {
  //       buffer.addAll(item);
  //     }
  //
  //     final anchor = AnchorElement(
  //         href:
  //             "data:application/octet-stream;charset=utf-16le;base64,${base64Encode(buffer)}")
  //       ..setAttribute("download", decoded['fileName'])
  //       ..click();
  //   }
  // }
}