
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
  bool isCanceled = false;
  late FileTransfer fileTransfer;

  @override
  void initState() {
    super.initState();
    fileTransfer = FileTransfer(
      peerApi: AppData.instance.peerApi!,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            this.progress = progress;
          });
        }
      },
      onReceivedInfo: (fileInfo) {
        isCanceled = false;
        fileTransfer.acceptFile()
            .then((value) => receivedFile(value))
            .onError((error, stackTrace) {
              _handleFileException(error);
            });
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

    if(!mounted) return;
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

      isCanceled = false;

      debugPrint('File Read Started');
      await for (List<int> bytes in result.files.first.readStream!) {
        fileBytes.addAll(bytes);
      }
      debugPrint('File Read Completed');

      await fileTransfer.sendFile(
        fileName: fileName,
        fileBytes: fileBytes,
      ).onError((error, stackTrace) {
        _handleFileException(error);
      });

      if (isCanceled) return;

      debugPrint('File Sent');
      if(!mounted) return;
      Toast.makeToast(text: 'File Sent', context: context,
          duration: ToastDuration.large,
          icon: Icons.file_upload
      );
    }
  }

  void _handleFileException(Object? error) {
    if(error == null) return;
    if(error is FileCanceledException) {
      debugPrint('File was Canceled');
      if (mounted) {
        setState(() {
          isCanceled = true;
        });

        Toast.makeToast(text: 'File Canceled', context: context,
            duration: ToastDuration.large,
            icon: Icons.highlight_off_sharp
        );
      }
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
                color: isCanceled ? Colors.red : (fileTransfer.neededResendMissing ? Colors.green : Colors.orange),
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
