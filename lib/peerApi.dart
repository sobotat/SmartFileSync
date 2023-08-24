import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class PeerApi {

  Function(String message)? onMessage;
  Function(String data)? onData;
  Function(String? iceDescription) onIceDescription;
  Function()? onConnected;
  Function()? onConnecting;
  Function()? onClosed;
  Function()? onDisconected;
  Function()? onFailed;

  RTCPeerConnection? _connection;
  RTCDataChannel? _messageChannel;
  RTCDataChannel? _dataChannel;
  bool isInit = false;
  String userId;

  PeerApi({
    required this.userId,
    required this.onIceDescription,
    this.onMessage,
    this.onData,
    this.onConnected,
    this.onConnecting,
    this.onClosed,
    this.onDisconected,
    this.onFailed
  }){
    init();
  }

  Future<void> init() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': 'stun:stun1.l.google.com:19302'
        },
        {
          'urls': 'stun:stun2.l.google.com:19302'
        },
        {
          'urls': 'stun:stun3.l.google.com:19302'
        },
        {
          'urls': 'stun:stun4.l.google.com:19302'
        },
      ],
    };

    _connection = await createPeerConnection(configuration);

    if (_connection != null) {
      _connection!.onDataChannel = (channel) {
        switch (channel.label) {
          case 'message':
            _messageChannel = channel;
            _messageChannel!.onMessage = (data) {
              if (onMessage != null) {
                onMessage!(data.text);
              }
            };
            break;
          case 'data':
            _dataChannel = channel;
            _dataChannel!.onMessage = (data) {
              if (onData != null) {
                onData!(data.text);
              }
            };
            break;
        }
        debugPrint("Data Chanel Opened [${_messageChannel!.label}]");
      };

      _connection!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          if (onClosed != null) onClosed!();
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
          if (onConnecting != null) onConnecting!();
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          if (onConnected != null) onConnected!();
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          if (onFailed != null) onFailed!();
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          if (onDisconected != null) onDisconected!();
        }
      };

      _connection!.onIceCandidate = (candidate) {
        _connection!.addCandidate(candidate);
        _connection!.getLocalDescription().then((description) {
          if (description != null) {
            onIceDescription(jsonEncode(description.toMap()));
          } else {
            debugPrint('Local Description is Null');
          }
        });
      };

      debugPrint("PeerConnection Created");
    } else {
      debugPrint("Something went wrong with init of PeerConnection");
    }

    isInit = true;
  }

  Future<String?> createOffer() async {
    if (!isInit || _connection == null) return null;

    if (_messageChannel == null) {
      RTCDataChannelInit messageChannelInit = RTCDataChannelInit();
      _messageChannel = await _connection!.createDataChannel("message", messageChannelInit);
      _messageChannel!.onMessage = (data) {
        if (onMessage != null) {
          onMessage!(data.text);
        }
      };
    }
    if (_dataChannel == null) {
      RTCDataChannelInit dataChannelInit = RTCDataChannelInit();
      _dataChannel = await _connection!.createDataChannel("data", dataChannelInit);
      _dataChannel!.onMessage = (data) {
        if (onData != null) {
          onData!(data.text);
        }
      };
    }

    RTCSessionDescription offer = await _connection!.createOffer();
    _connection!.setLocalDescription(offer).then((value) => debugPrint("Local Description Set with Offer"));

    return jsonEncode(offer.toMap());
  }

  Future<String?> createAnswer() async {
    if (!isInit || _connection == null) return null;

    RTCSessionDescription answer = await _connection!.createAnswer();
    _connection!.setLocalDescription(answer).then((value) => debugPrint("Local Description Set with Answer"));

    return jsonEncode(answer.toMap());
  }

  void connect(String? description) {
    if (!isInit || _connection == null) {
      debugPrint("Not Init");
      return;
    }
    if (description == null) {
      debugPrint("Invalid Connect Description");
      return;
    }
    debugPrint("Connect Description: $description");
    Map<String, dynamic> decoded = jsonDecode(description);

    _connection!.setRemoteDescription(RTCSessionDescription(decoded["sdp"], decoded["type"]));
  }

  void sendMessage(String message) {
    final state = _connection?.connectionState ?? RTCIceConnectionState.RTCIceConnectionStateFailed;
    if (!isInit || _connection == null || state != RTCIceConnectionState.RTCIceConnectionStateConnected) {
      debugPrint("Not Init");
      return;
    }
    if (_messageChannel == null) {
      debugPrint("Message Chanel is null");
      return;
    }

    DateTime dateTime = DateTime.now();

    String jsonEncoded = jsonEncode({
      'username': userId,
      'message': message,
      'time': '${dateTime.hour}:${dateTime.minute}'
    });

    _messageChannel!.send(RTCDataChannelMessage(jsonEncoded));
    if(onMessage != null) {
      onMessage!(jsonEncoded);
    }
  }

  void sendData(String data) {
    final state = _connection?.connectionState ?? RTCIceConnectionState.RTCIceConnectionStateFailed;
    if (!isInit || _connection == null || state != RTCIceConnectionState.RTCIceConnectionStateConnected) {
      debugPrint("Not Init");
      return;
    }
    if (_dataChannel == null) {
      debugPrint("Data Chanel is null");
      return;
    }

    _dataChannel!.send(RTCDataChannelMessage(data));
  }

  void close() {
    if (_messageChannel != null) {
      _messageChannel!.close();
      _messageChannel = null;
    }

    if (_dataChannel != null) {
      _dataChannel!.close();
      _dataChannel = null;
    }

    if (_connection != null) {
      _connection!.close();
      _connection = null;
    }
  }
}