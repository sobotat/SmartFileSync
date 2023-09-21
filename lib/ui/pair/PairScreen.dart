import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_file_sync/src/config/AppData.dart';
import 'package:smart_file_sync/src/config/AppRouter.dart';
import 'package:smart_file_sync/src/peer/PeerApi.dart';
import 'package:smart_file_sync/ui/assets/Button.dart';

class PairScreen extends StatefulWidget {
  const PairScreen({super.key});

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {

  TextEditingController controller = TextEditingController();

  String? connectDescription;
  String connectionState = 'Closed';
  late PeerApi peerApi;


  @override
  void initState() {
    super.initState();
    peerApi = PeerApi(
      onIceDescription: (iceDescription) {
        if (!context.mounted) {
          debugPrint('Ice: $iceDescription');
          return;
        }

        setState(() {
          connectDescription = iceDescription;
        });

        if (connectDescription != null) {
          Clipboard.setData(ClipboardData(text: connectDescription!))
              .onError((error, stackTrace) {
            debugPrint('Clipboard failed -> $connectDescription');
          });
        } else {
          debugPrint('Failed to get Connect Description');
        }
      },
      onStateChanged: (state) {
        if(context.mounted) {
          setState(() {
            connectionState = state;
          });
        }
        if(state == 'Connected') {
          debugPrint('Pair Success');

          AppData.instance.peerApi = peerApi;
          AppRouter.instance.router.goNamed('/');
        }else if (['Failed', 'Disconnected', 'Closed'].contains(state)) {
          AppData.instance.peerApi = null;
          AppRouter.instance.router.goNamed('pair');
        }
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void createOffer() {
    if (peerApi == null) return;
    peerApi!.createOffer();
  }

  void connect(BuildContext context) {
    if (peerApi == null) return;
    peerApi!.connect(controller.text);

    Map<String, dynamic> decoded = jsonDecode(controller.text);
    if (decoded['type'] == 'offer') {
      peerApi!.createAnswer();
    }
  }

  void reset() {

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10)
            ),
            padding: EdgeInsets.all(10),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pair', style: TextStyle(fontSize: 45),),
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 10),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Data',
                    ),
                    textInputAction: TextInputAction.go,
                    onSubmitted: (value) {
                      connect(context);
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                Button(
                  text: controller.text.isEmpty ? 'Copy Connect Data' : 'Pair',
                  maxWidth: double.infinity,
                  onClick: (context) => controller.text.isEmpty ? createOffer() : connect(context),
                ),
                Text(connectionState,
                  style: TextStyle(
                    color: getConnectionStateColor(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
