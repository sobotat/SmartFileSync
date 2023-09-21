
import 'package:flutter/material.dart';
import 'package:smart_file_sync/src/config/AppData.dart';
import 'package:smart_file_sync/src/files/download/FileDownloader.dart';
import 'package:smart_file_sync/src/files/transfer/FileChunked.dart';
import 'package:smart_file_sync/src/files/transfer/FileTransfer.dart';
import 'package:smart_file_sync/ui/assets/Toast.dart';

class SendFileScreen extends StatefulWidget {
  const SendFileScreen({super.key});

  @override
  State<SendFileScreen> createState() => _SendFileScreenState();
}

class _SendFileScreenState extends State<SendFileScreen> {

  double progress = 0;
  late FileTransfer fileTransfer;

  @override
  void initState() {
    super.initState();
    fileTransfer = FileTransfer(
      peerApi: AppData.instance.peerApi!,
      onProgress: (progress) => progress,
      onReceivedInfo: (fileInfo) {
        fileTransfer!.acceptFile().then((value) => receivedFile(value));
      },
    );
  }

  void receivedFile(FileChunked? fileChunked) {
    if (fileChunked == null) {
      debugPrint('Chunked File is null');
      Toast.makeToast(text: 'Failed to Download file', context: context,
        textColor: Colors.red,
        icon: Icons.error,
        iconColor: Colors.red
      );
      return;
    }
    var bytes = fileChunked.fileBytes;
    debugPrint('N[${fileChunked.fileName}] FS[${fileChunked.fileSize}] BS[${bytes.length}]');

    FileDownloader.instance.downloadFile(fileChunked);

    Toast.makeToast(text: 'File Downloaded', context: context,
      duration: ToastDuration.large,
      icon: Icons.file_download
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                minHeight: 5,
                value: progress,
                color: !(fileTransfer?.neededResendMissing ?? true) ? Colors.green : Colors.orange,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            )
          ],
        ),
      ),
    );
  }
}
