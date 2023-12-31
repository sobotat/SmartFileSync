import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class PeerApi {

  Function(String message)? onMessage;
  Function(String data)? onData;
  Function(String? iceDescription) onIceDescription;
  Function(String state)? onStateChanged;

  RTCPeerConnection? _connection;
  RTCDataChannel? _messageChannel;
  RTCDataChannel? _dataChannel;
  bool isInit = false;

  PeerApi({
    required this.onIceDescription,
    this.onMessage,
    this.onData,
    this.onStateChanged
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
        debugPrint("Data Chanel Opened [${channel.label}]");
      };

      _connection!.onConnectionState = (state) {
        if(onStateChanged == null) return;
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          onStateChanged!('Closed');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
          onStateChanged!('Connecting');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          onStateChanged!('Connected');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          onStateChanged!('Failed');
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          onStateChanged!('Disconnected');
        }
      };

      _connection!.onIceCandidate = (candidate) async {
        try {
          final description = await _connection!.getRemoteDescription()
              .onError((error, stackTrace) => throw Exception('Failed to get RemoteDescription'));
          if (description != null) {
            _connection!.addCandidate(candidate);
          }
        } on Exception catch (e) {
          debugPrint('Failed to add Candidate > $e');
        }
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
    debugPrint("Init Done");
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
    if (!isInit || _connection == null) {
      debugPrint("Not Init");
      return;
    }
    if (_connection!.connectionState != null && _connection!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      debugPrint("PeerState is not Connected");
      return;
    }
    if (_messageChannel == null) {
      debugPrint("Message Chanel is null");
      return;
    }

    DateTime dateTime = DateTime.now();

    String jsonEncoded = jsonEncode({
      'message': message,
      'time': '${dateTime.hour}:${dateTime.minute}'
    });

    _messageChannel!.send(RTCDataChannelMessage(jsonEncoded));
    if(onMessage != null) {
      onMessage!(jsonEncoded);
    }
  }

  void sendData(String data) {
    if (!isInit || _connection == null) {
      debugPrint("Not Init");
      return;
    }
    if (_connection!.connectionState != null && _connection!.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      debugPrint("PeerState is not Connected : ${_connection!.connectionState}");
      return;
    }
    if (_dataChannel == null) {
      debugPrint("Data Chanel is null");
      return;
    }
    _dataChannel!.send(RTCDataChannelMessage(data));
  }

  int getMessageChannelBufferedAmount() {
    if (_messageChannel == null) return 0;
    return _messageChannel!.bufferedAmount ?? 0;
  }

  int getDataChannelBufferedAmount() {
    if (_dataChannel == null) return 0;
    return _dataChannel!.bufferedAmount ?? 0;
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