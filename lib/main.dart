import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_file_sync/src/config/AppRouter.dart';
import 'package:smart_file_sync/src/config/DarkTheme.dart';
import 'package:smart_file_sync/src/files/download/FileDownloader.dart';
import 'package:smart_file_sync/src/files/transfer/FileChunked.dart';
import 'package:smart_file_sync/src/files/transfer/FileTransfer.dart';
import 'package:smart_file_sync/src/peer/PeerApi.dart';
import 'package:smart_file_sync/src/security/AppSecurity.dart';
import 'package:smart_file_sync/src/services/LocalStorage.dart';
import 'package:smart_file_sync/src/services/NetworkChecker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key}) {
    AppSecurity.instance.init();
    NetworkChecker.instance.init();
    AppRouter.instance.setNetworkListener();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SFS',
      theme: DarkTheme.instance.getTheme(context),
      routerConfig: AppRouter.instance.router,
    );
  }
}
//
// class SelectUsername extends StatefulWidget {
//   const SelectUsername({super.key});
//
//   @override
//   State<SelectUsername> createState() => _SelectUsernameState();
// }
//
// class _SelectUsernameState extends State<SelectUsername> {
//
//   String? username;
//   final controller = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration.zero, () async {
//       String? username = await LocalStorage.instance.get('username');
//       if (username != null) {
//         setState(() {
//           this.username = username;
//         });
//       }
//     },);
//   }
//
//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return username == null ? Scaffold(
//       appBar: AppBar(
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 const Color(0xffad6610),
//                 Theme.of(context).colorScheme.secondary,
//               ],
//               begin: Alignment.centerLeft,
//               end: Alignment.centerRight,
//             ),
//           ),
//         ),
//         title: const Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//                 Icons.wifi
//             ),
//             Padding(
//               padding: EdgeInsets.only(left: 10),
//               child: Text('SFS - Username', style: TextStyle(color: Colors.white),),
//             )
//           ],
//         ),
//       ),
//       body: Center(
//         child: FractionallySizedBox(
//           heightFactor: 0.2,
//           widthFactor: 0.9,
//           child: Container(
//             padding: const EdgeInsets.all(15),
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   const Color(0xffad6610),
//                   Theme.of(context).colorScheme.secondary,
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   flex: 10,
//                   child: TextField(
//                     controller: controller,
//                     decoration: InputDecoration(
//                       labelText: 'Username',
//                       errorText: (controller.text.isEmpty ? 'Fill Username' : null),
//                       labelStyle:MaterialStateTextStyle.resolveWith((states) {
//                         return const TextStyle(color: Colors.white, letterSpacing: 1.1);
//                       }),
//                       floatingLabelStyle: MaterialStateTextStyle.resolveWith((states) {
//                         return const TextStyle(color: Colors.white, letterSpacing: 1.1);
//                       }),
//                       enabledBorder: const UnderlineInputBorder(
//                           borderSide: BorderSide(
//                             color: Colors.white,
//                           )
//                       ),
//                       focusedBorder: const UnderlineInputBorder(
//                           borderSide: BorderSide(
//                             color: Colors.white,
//                           )
//                       ),
//                     ),
//                     textInputAction: TextInputAction.go,
//                     onSubmitted: (value) {
//                       setState(() {
//                         if (controller.text.isNotEmpty) {
//                           username = controller.text;
//                           LocalStorage.instance.set('username', username!);
//                         }
//                       });
//                     },
//                     onChanged: (value) => setState(() { }),
//                   ),
//                 ),
//                 Expanded(
//                   flex: 1,
//                   child: IconButton(
//                       onPressed: () {
//                         setState(() {
//                           if (controller.text.isNotEmpty) {
//                             username = controller.text;
//                             LocalStorage.instance.set('username', username!);
//                           }
//                         });
//                       },
//                       icon: const Icon(
//                         Icons.send,
//                       )
//                   ),
//                 )
//               ],
//             )),
//           ),
//       ),
//     ) : MainPage(
//       username: username!,
//     );
//   }
// }
//
//
// class MainPage extends StatefulWidget {
//   const MainPage({
//     required this.username,
//     super.key,
//   });
//
//   final String username;
//
//   @override
//   State<MainPage> createState() => _MainPageState();
// }
//
// class _MainPageState extends State<MainPage> {
//
//   PeerApi? peerApi;
//   FileTransfer? fileTransfer;
//
//   List<String> messages = []; // ['{"username": "User", "message": "123", "time": "00:00"}'];
//
//   String? connectDescription;
//   String connectionState = 'Closed';
//   bool showConnectData = false;
//   double progress = 0, lastProgress = 0;
//   bool readingFile = false;
//
//   final connectStringController = TextEditingController();
//   final messageController = TextEditingController();
//   final messageFocus = FocusNode();
//   final scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     createPeer();
//   }
//
//   @override
//   void dispose() {
//     connectStringController.dispose();
//     messageController.dispose();
//     messageFocus.dispose();
//     scrollController.dispose();
//     if (peerApi != null) {
//       peerApi!.close();
//     }
//     super.dispose();
//   }
//
//   void createPeer() {
//     peerApi = PeerApi(
//       onIceDescription: (iceDescription) {
//         setState(() {
//           connectDescription = iceDescription;
//         });
//
//         if (connectDescription != null) {
//             Clipboard.setData(ClipboardData(text: connectDescription!))
//                 .onError((error, stackTrace) {
//                   debugPrint('Clipboard failed -> $connectDescription');
//                 });
//         } else {
//           debugPrint('Failed to get Connect Description');
//         }
//       },
//       onMessage: (message) {
//         setState(() {
//           messages.add(message);
//           scrollController.animateTo(messages.length * 45,
//             duration: const Duration(milliseconds: 100),
//             curve: Curves.ease,
//           );
//         });
//         debugPrint(' > :: $message');
//       },
//     );
//
//     fileTransfer = FileTransfer(
//       peerApi: peerApi!,
//       onReceivedInfo: (fileInfo) => onReceivedInfo(fileInfo),
//       onProgress: (progress) => onProgress(progress),
//     );
//
//     setState(() { });
//   }
//
//   void onReceivedInfo (FileChunked fileInfo) async {
//     bool fileAccepted = false;
//     await showDialog<String>(
//         context: context,
//         builder: (BuildContext context) => AcceptDialog(
//           fileName: fileInfo.fileName,
//           onSelected: (value) {
//             fileAccepted = value;
//           },
//         )
//     );
//
//     if (fileTransfer != null && fileAccepted) {
//       fileTransfer!.acceptFile().then((value) => receivedFile(value));
//     } else if (fileTransfer != null && !fileAccepted) {
//       fileTransfer!.rejectFile();
//     }
//   }
//
//   void receivedFile(FileChunked? fileChunked) {
//     if (fileChunked == null) {
//       debugPrint('Chunked File is null');
//       return;
//     }
//     var bytes = fileChunked.fileBytes;
//     debugPrint('N[${fileChunked.fileName}] FS[${fileChunked.fileSize}] BS[${bytes.length}]');
//
//     FileDownloader.instance.downloadFile(fileChunked);
//   }
//
//   void onProgress(double progress) {
//     this.progress = progress;
//     setState(() { });
//   }
//
//   void createOffer() {
//     if (peerApi == null) return;
//     peerApi!.createOffer();
//   }
//
//   void createAnswer() {
//     if (peerApi == null) return;
//     peerApi!.createAnswer();
//   }
//
//   void connect() {
//     if (peerApi == null) return;
//     peerApi!.connect(connectStringController.text);
//
//     Map<String, dynamic> decoded = jsonDecode(connectStringController.text);
//     if (decoded['type'] == 'offer') {
//       createAnswer();
//     }
//   }
//
//   void send() {
//     if (messageController.text == '') return;
//
//     String message = messageController.text;
//
//     debugPrint('Trying send > $message');
//     peerApi!.sendMessage(message);
//
//     setState(() {
//       messageController.text = '';
//       messageFocus.requestFocus();
//     });
//   }
//
//   Future<void> sendFile() async {
//     setState(() {
//       readingFile = true;
//     });
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         withReadStream: true,
//       );
//
//       if (result != null && result.files.isNotEmpty) {
//         String fileName = result.files.first.name;
//         List<int> fileBytes = [];
//
//         debugPrint('File Read Started');
//         await for (List<int> bytes in result.files.first.readStream!) {
//           fileBytes.addAll(bytes);
//         }
//         debugPrint('File Read Completed');
//
//         if (fileTransfer == null) {
//           debugPrint('Cannot Send File: FileTransfer is null');
//           return;
//         }
//
//         await fileTransfer!.sendFile(
//           fileName: fileName,
//           fileBytes: fileBytes,
//         );
//         debugPrint('File Sent');
//       }
//     } finally {
//       setState(() {
//         readingFile = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.secondary,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 const Color(0xffad6610),
//                 Theme.of(context).colorScheme.secondary,
//               ],
//               begin: Alignment.centerLeft,
//               end: Alignment.centerRight,
//             ),
//           ),
//         ),
//         title: const Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.wifi,
//               color: Colors.white,
//             ),
//             Padding(
//               padding: EdgeInsets.only(left: 10),
//               child: Text('SFS - Chat', style: TextStyle(color: Colors.white),),
//             )
//           ],
//         ),
//         actions: [
//           IconButton(
//             onPressed: () {
//               setState(() {
//                 showConnectData = !showConnectData;
//               });
//             },
//             icon: Icon(showConnectData ? Icons.remove : Icons.add, color: Colors.white,),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Align(
//               alignment: Alignment.topCenter,
//               child: false ? Container() :
//               LinearProgressIndicator(
//                 minHeight: 5,
//                 value: progress,
//                 color: !(fileTransfer?.neededResendMissing ?? true) ? Colors.green : Colors.orange,
//                 backgroundColor: Theme.of(context).colorScheme.primary,
//               ),
//             ),
//             Center(
//               child: FractionallySizedBox(
//                 heightFactor: 0.75,
//                 widthFactor: 0.9,
//                 child: Container(
//                   padding: const EdgeInsets.all(15),
//                   alignment: Alignment.center,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         const Color(0xffad6610),
//                         Theme.of(context).colorScheme.secondary,
//                       ],
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                     ),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: <Widget>[
//                       Expanded(
//                         child: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(10),
//                             color: Theme.of(context).colorScheme.background,
//                           ),
//                           child: ListView.builder(
//                             controller: scrollController,
//                             shrinkWrap: true,
//                             itemCount: messages.length,
//                             itemBuilder: (context, index) {
//                               Map<String,dynamic> message = jsonDecode(messages[index]);
//                               String user = message['username'] ?? '';
//
//                               return Container(
//                                 width: 400,
//                                 alignment: Alignment.centerLeft,
//                                 margin: const EdgeInsets.all(5),
//                                 padding: const EdgeInsets.all(7),
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(10),
//                                   color: peerApi!.userId == user ? const Color(0xffad6610) : const Color(0xFF1e1f22),
//                                 ),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.max,
//                                   children: [
//                                     Expanded(
//                                       flex: 5,
//                                       child: Align(
//                                         alignment: Alignment.centerLeft,
//                                         child: Row(
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: [
//                                             Text(
//                                               user,
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 10,),
//                                             Flexible(
//                                               child: Text(
//                                                 message['message'],
//                                                 softWrap: true,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: Align(
//                                         alignment: Alignment.centerRight,
//                                         child: Text(message['time']),
//                                       ),
//                                     )
//                                   ],
//                                 ),
//                               );
//                             }
//                           ),
//                         ),
//                       ),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             flex: 10,
//                             child: TextField(
//                               controller: messageController,
//                               focusNode: messageFocus,
//                               decoration: InputDecoration(
//                                 labelText: 'Message Text',
//
//                                 labelStyle:MaterialStateTextStyle.resolveWith((states) {
//                                     return const TextStyle(color: Colors.white, letterSpacing: 1.1);
//                                 }),
//                                 floatingLabelStyle: MaterialStateTextStyle.resolveWith((states) {
//                                     return const TextStyle(color: Colors.white, letterSpacing: 1.1);
//                                 }),
//                                 enabledBorder: const UnderlineInputBorder(
//                                     borderSide: BorderSide(
//                                       color: Colors.white,
//                                     )
//                                 ),
//                                 focusedBorder: const UnderlineInputBorder(
//                                     borderSide: BorderSide(
//                                       color: Colors.white,
//                                     )
//                                 ),
//                               ),
//                               textInputAction: TextInputAction.go,
//                               onSubmitted: (value) {
//                                 send();
//                               },
//                             ),
//                           ),
//                           Expanded(
//                             flex: 1,
//                             child: IconButton(
//                               onPressed: () {
//                                 send();
//                               },
//                               icon: const Icon(
//                                 Icons.send,
//                                 color: Colors.white,
//                               )
//                             ),
//                           )
//                         ],
//                       ),
//                       (connectionState != 'Connected' || showConnectData) ? Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           TextField(
//                             controller: connectStringController,
//                             decoration: InputDecoration(
//                               labelText: 'Connect Data',
//                               labelStyle:MaterialStateTextStyle.resolveWith((states) {
//                                 return const TextStyle(color: Colors.white, letterSpacing: 1.1);
//                               }),
//                               floatingLabelStyle: MaterialStateTextStyle.resolveWith((states) {
//                                 return const TextStyle(color: Colors.white, letterSpacing: 1.1);
//                               }),
//                               enabledBorder: const UnderlineInputBorder(
//                                   borderSide: BorderSide(
//                                     color: Colors.white,
//                                   )
//                               ),
//                               focusedBorder: const UnderlineInputBorder(
//                                   borderSide: BorderSide(
//                                     color: Colors.white,
//                                   )
//                               ),
//                             ),
//                             textInputAction: TextInputAction.go,
//                             onSubmitted: (value) {
//                               connect();
//                             },
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: ElevatedButton(
//                                 onPressed: connect, child: const Text('Connect')),
//                           ),
//                           Text(connectionState,
//                             style: TextStyle(
//                               color: getConnectionStateColor(),
//                             ),
//                           ),
//                         ],
//                       ) : Container(),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: Row(
//         mainAxisAlignment: MainAxisAlignment.end,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           (connectionState != 'Connected' || showConnectData) ? Padding(
//             padding: const EdgeInsets.all(2),
//             child: FloatingActionButton(
//               heroTag: 1,
//               onPressed: createOffer,
//               tooltip: 'Invite',
//               child: const Icon(Icons.arrow_forward),
//             ),
//           ) : const SizedBox(width: 0, height: 0,),
//           Padding(
//             padding: const EdgeInsets.all(2),
//             child: FloatingActionButton(
//               heroTag: 2,
//               onPressed: !readingFile ? sendFile : null,
//               tooltip: 'File',
//               child: !readingFile ? const Icon(Icons.file_upload) : const CircularProgressIndicator(),
//             ),
//           ),
//         ],
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
//
//   Color getConnectionStateColor() {
//     switch(connectionState) {
//       case 'Connected':
//         return Colors.lightGreen;
//       case 'Connecting':
//       return Colors.green;
//       case 'Closed':
//       return Colors.red;
//       case 'Failed':
//       return Colors.orangeAccent;
//       case 'Disconected':
//         return Colors.red.shade700;
//       default:
//         return Colors.purple;
//     }
//   }
// }
//
// class AcceptDialog extends AlertDialog {
//   const AcceptDialog({
//     required this.fileName,
//     required this.onSelected,
//     super.key
//   });
//
//   final String fileName;
//   final Function(bool value) onSelected;
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text('Accept file - $fileName'),
//       content: const Text('Are you want accept file'),
//       actions: <Widget>[
//         TextButton(
//           onPressed: () {
//             onSelected(false);
//             Navigator.pop(context);
//           },
//           child: const Text('Cancel'),
//         ),
//         TextButton(
//           onPressed: () {
//             onSelected(true);
//             Navigator.pop(context);
//           },
//           child: const Text('OK'),
//         ),
//       ],
//     );
//   }
// }
