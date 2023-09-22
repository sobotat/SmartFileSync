
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:smart_file_sync/src/config/AppData.dart';
import 'package:smart_file_sync/src/files/download/FileDownloader.dart';
import 'package:smart_file_sync/src/files/transfer/FileChunked.dart';
import 'package:smart_file_sync/src/files/transfer/FileTransfer.dart';
import 'package:smart_file_sync/ui/assets/Button.dart';
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
      onProgress: (progress) {
        if (context.mounted) {
          setState(() {
            this.progress = progress;
          });
        }
      },
      onReceivedInfo: (fileInfo) {
        fileTransfer.acceptFile().then((value) => receivedFile(value));
      },
    );
  }

  @override
  void dispose() {
    fileTransfer.dispose();
    super.dispose();
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

    if(!context.mounted) return;
    Toast.makeToast(text: 'File Downloaded', context: context,
      duration: ToastDuration.large,
      icon: Icons.file_download
    );
  }

  Future<void> sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withReadStream: true,
    );

    if (result != null && result.files.isNotEmpty) {
      String fileName = result.files.first.name;
      List<int> fileBytes = [];

      debugPrint('File Read Started');
      await for (List<int> bytes in result.files.first.readStream!) {
        fileBytes.addAll(bytes);
      }
      debugPrint('File Read Completed');

      await fileTransfer.sendFile(
        fileName: fileName,
        fileBytes: fileBytes,
      );
      debugPrint('File Sent');
      if(!context.mounted) return;
      Toast.makeToast(text: 'File Send', context: context,
          duration: ToastDuration.large,
          icon: Icons.file_upload
      );
    }
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
                color: fileTransfer.neededResendMissing ? Colors.green : Colors.orange,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            Center(
              child: Button(
                text: 'Send File',
                onClick: (context) => sendFile(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
