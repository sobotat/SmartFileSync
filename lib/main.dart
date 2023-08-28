import 'dart:convert';
import 'dart:html';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_file_sync/peerApi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SFS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade200),
        useMaterial3: true,
      ),
      home: const SelectUsername(),
    );
  }
}

class SelectUsername extends StatefulWidget {
  const SelectUsername({super.key});

  @override
  State<SelectUsername> createState() => _SelectUsernameState();
}

class _SelectUsernameState extends State<SelectUsername> {

  String? username;
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return username == null ? Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                Icons.wifi
            ),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text('SFS - Username'),
            )
          ],
        ),
      ),
      body: Center(
        child: FractionallySizedBox(
          heightFactor: 0.2,
          widthFactor: 0.9,
          child: Container(
            padding: const EdgeInsets.all(15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan.shade200,
                  Colors.blueAccent.shade200,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: (controller.text.isEmpty ? 'Fill Username' : null),
                    ),
                    textInputAction: TextInputAction.go,
                    onSubmitted: (value) {
                      setState(() {
                        if (controller.text.isNotEmpty) {
                          username = controller.text;
                        }
                      });
                    },
                    onChanged: (value) => setState(() { }),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: IconButton(
                      onPressed: () {
                        setState(() {
                          if (controller.text.isNotEmpty) {
                            username = controller.text;
                          }
                        });
                      },
                      icon: const Icon(
                        Icons.send,
                      )
                  ),
                )
              ],
            )),
          ),
      ),
    ) : MainPage(
      username: username!,
    );
  }
}


class MainPage extends StatefulWidget {
  const MainPage({
    required this.username,
    super.key,
  });

  final String username;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  PeerApi? peerApi;
  List<String> messages = [];
  String? description;
  final connectStringController = TextEditingController();
  final messageController = TextEditingController();
  final messageFocus = FocusNode();
  final scrollController = ScrollController();
  int index = 0;
  String connectionState = 'Closed';
  bool showConnectData = false;

  bool fileAccepted = false;
  List<List<int>> fileBuffer = [];
  int fileReceived = 0;

  @override
  void initState() {
    super.initState();
    createPeer();
  }

  @override
  void dispose() {
    connectStringController.dispose();
    messageController.dispose();
    messageFocus.dispose();
    scrollController.dispose();
    if (peerApi != null) {
      peerApi!.close();
    }
    super.dispose();
  }

  void createPeer() {
    peerApi = PeerApi(userId: widget.username,
      onIceDescription: (iceDescription) {
        setState(() {
          description = iceDescription;
        });
        Clipboard.setData(ClipboardData(text: description ?? ''));
      },
      onMessage: (message) {
        setState(() {
          messages.add(message);
          scrollController.animateTo(messages.length * 45,
            duration: const Duration(milliseconds: 100),
            curve: Curves.ease,
          );
        });
        debugPrint(' > :: $message');
      },
      onData: (data) async {
        Map<String, dynamic> decoded = jsonDecode(data);
        String fileName = decoded['fileName'];

        if (decoded['index'] == 0) {
          fileReceived = 0;
          fileAccepted = false;
          fileBuffer = [];
          await showDialog<String>(
              context: context,
              builder: (BuildContext context) =>
                  AcceptDialog(
                    fileName: fileName,
                    onSelected: (value) {
                      fileAccepted = value;
                    },
                  )
          );

          if (!fileAccepted) {
            debugPrint('File not accepted');
            return;
          }
        }

        List<int> bytes = (decoded['data'] as List<dynamic>).map((e) => e as int).toList();
        if (fileBuffer.length < decoded['maxIndex']){
          while (fileBuffer.length < decoded['maxIndex']) {
            fileBuffer.add([]);
          }
        }
        fileBuffer[decoded['index']] = bytes;
        debugPrint('File Progress [${decoded['index'] + 1}/${decoded['maxIndex']}]');

        fileReceived += 1;
        debugPrint('Received $fileReceived');
        if (fileReceived == decoded['maxIndex'] && fileAccepted) {
          final List<int> buffer = [];
          for (List<int> item in fileBuffer) {
            buffer.addAll(item);
          }

          final anchor = AnchorElement(
              href: "data:application/octet-stream;charset=utf-16le;base64,${base64Encode(buffer)}")
            ..setAttribute("download", decoded['fileName'])
            ..click();
        }
      },
      onConnected: () { setState(() {
        connectionState = 'Connected';
      }); },
      onConnecting: () { setState(() {
        connectionState = 'Connecting';
      }); },
      onClosed: () { setState(() {
        connectionState = 'Closed';
      }); },
      onDisconected: () { setState(() {
        connectionState = 'Disconected';
      }); },
      onFailed: () { setState(() {
        connectionState = 'Failed';
      }); },
    );
    setState(() { });
  }

  void createOffer() {
    if (peerApi == null) return;
    peerApi!.createOffer();
  }

  void createAnswer() {
    if (peerApi == null) return;
    peerApi!.createAnswer();
  }

  void connect() {
    if (peerApi == null) return;
    peerApi!.connect(connectStringController.text);

    Map<String, dynamic> decoded = jsonDecode(connectStringController.text);
    if (decoded['type'] == 'offer') {
      createAnswer();
    }
  }

  void send() {
    List<String> tmpData = [
      'Hello',
      'Test',
      'Something',
      'IDK',
      'Peer',
      'WTF',
    ];

    String message = messageController.text == '' ? tmpData[index] : messageController.text;

    debugPrint('Trying send > $message');
    peerApi!.sendMessage(message);

    index += 1;
    if (index >= tmpData.length) index = 0;

    setState(() {
      messageController.text = '';
      messageFocus.requestFocus();
    });
  }

  Future<void> sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final fileBytes = result.files.first.bytes;
      final fileName = result.files.first.name;

      int index = 0;
      final int maxIndex = (fileBytes!.length / 15000).ceil();
      while(index < maxIndex) {
        List<int> sendBytes = [];

        int chunkSize = 15000;
        int startIndex = index * chunkSize;
        int endIndex = (index + 1) * chunkSize;

        for(int i = startIndex; i < endIndex; i++) {
          if (i > fileBytes.length - 1) break;
          sendBytes.add(fileBytes[i]);
        }

        peerApi!.sendData(jsonEncode({
          'fileName': fileName,
          'index': index,
          'maxIndex': maxIndex,
          'data': sendBytes,
        }));

        index += 1;
        debugPrint('Send [$index/$maxIndex]');
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
    debugPrint('File Send');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi
            ),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text('SFS - Chat'),
            )
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                showConnectData = !showConnectData;
              });
            },
            icon: Icon(showConnectData ? Icons.remove : Icons.add),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: FractionallySizedBox(
              heightFactor: 0.75,
              widthFactor: 0.9,
              child: Container(
                padding: const EdgeInsets.all(15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyan.shade200,
                      Colors.blueAccent.shade200,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[100],
                        ),
                        child: ListView.builder(
                          controller: scrollController,
                          shrinkWrap: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            Map<String,dynamic> message = jsonDecode(messages[index]);
                            String user = message['username'] ?? '';

                            return Container(
                              width: 400,
                              alignment: Alignment.centerLeft,
                              margin: const EdgeInsets.all(5),
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: peerApi!.userId == user ? Colors.cyan[100] : Colors.grey[400],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            user,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 10,),
                                          Flexible(
                                            child: Text(
                                              message['message'],
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(message['time']),
                                    ),
                                  )
                                ],
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 10,
                          child: TextField(
                            controller: messageController,
                            focusNode: messageFocus,
                            decoration: const InputDecoration(
                              labelText: 'Message Text',
                            ),
                            textInputAction: TextInputAction.go,
                            onSubmitted: (value) {
                              send();
                            },
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            onPressed: () {
                              send();
                            },
                            icon: const Icon(
                              Icons.send,
                            )
                          ),
                        )
                      ],
                    ),
                    (connectionState != 'Connected' || showConnectData) ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: connectStringController,
                          decoration: const InputDecoration(
                            labelText: 'Connect Data',
                          ),
                          textInputAction: TextInputAction.go,
                          onSubmitted: (value) {
                            connect();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                              onPressed: connect, child: const Text('Connect')),
                        ),
                        Text(connectionState,
                          style: TextStyle(
                            color: getConnectionStateColor(),
                          ),
                        ),
                      ],
                    ) : Container(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(2),
            child: FloatingActionButton(
              heroTag: 1,
              onPressed: createOffer,
              tooltip: 'Invite',
              child: const Icon(Icons.arrow_forward),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(2),
            child: FloatingActionButton(
              heroTag: 2,
              onPressed: sendFile,
              tooltip: 'File',
              child: const Icon(Icons.file_upload),
            ),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Color getConnectionStateColor() {
    switch(connectionState) {
      case 'Connected':
        return Colors.lightGreen;
      case 'Connecting':
      return Colors.green;
      case 'Closed':
      return Colors.red;
      case 'Failed':
      return Colors.orangeAccent;
      case 'Disconected':
        return Colors.red.shade700;
      default:
        return Colors.purple;
    }
  }
}

class AcceptDialog extends AlertDialog {
  const AcceptDialog({
    required this.fileName,
    required this.onSelected,
    super.key
  });

  final String fileName;
  final Function(bool value) onSelected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Accept file - $fileName'),
      content: const Text('Are you want accept file'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            onSelected(false);
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onSelected(true);
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
