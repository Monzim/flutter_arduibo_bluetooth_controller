import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  bool isMotorOn = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: GoogleFonts.ubuntuMono(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color: _message.whom == clientID
                    ? Colors.redAccent.withOpacity(0.8)
                    : Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          actions: [
            isConnected != true
                ? Icon(
                    Icons.bluetooth_disabled,
                    color: Colors.red.withOpacity(0.8),
                  )
                : Icon(
                    Icons.bluetooth_connected,
                    color: Colors.green.withOpacity(0.8),
                  ),
            // Container(
            //   width: 25,
            //   height: 25,
            //   color: isMotorOn != true ? Colors.red : Colors.green,
            // )
          ],
          title: (isConnecting
              ? Text('Connecting chat to ' + serverName + '...')
              : isConnected
                  ? Text(
                      'Live with motor ' + serverName,
                      style: GoogleFonts.ubuntu(),
                    )
                  : Text('Chat log with ' + serverName))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Flexible(
              flex: 2,
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: list),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isMotorOn == true
                        ? 'Motor : Currently On'
                        : 'Motor : Currently Off',
                    style: GoogleFonts.ubuntu(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10, height: 10),
                  ClipOval(
                      child: Container(
                    width: 25,
                    height: 25,
                    color: isMotorOn != true ? Colors.red : Colors.green,
                  ))
                ],
              ),
            ),
            Flexible(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 200,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: isMotorOn == true
                                  ? Colors.green
                                  : Colors.green,
                            ),
                            onPressed: isConnected && isMotorOn != true
                                ? () => _sendMessage('1')
                                : null,
                            child: Text(
                              'On',
                              style: GoogleFonts.ubuntu(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                      ),
                    ),
                    SizedBox(width: 10, height: 10),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 200,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: isMotorOn == true
                                  ? Colors.red
                                  : Colors.red[900],
                            ),
                            onPressed: isConnected && isMotorOn == true
                                ? () => _sendMessage('0')
                                : null,
                            child: Text(
                              'Off',
                              style: GoogleFonts.ubuntu(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Row(
            //   children: <Widget>[
            //     Flexible(
            //       child: Container(
            //         margin: const EdgeInsets.only(left: 16.0),
            //         child: TextField(
            //           style: const TextStyle(fontSize: 15.0),
            //           controller: textEditingController,
            //           decoration: InputDecoration.collapsed(
            //             hintText: isConnecting
            //                 ? 'Wait until connected...'
            //                 : isConnected
            //                     ? 'Type 0 off / 1 on your message...'
            //                     : 'Chat got disconnected',
            //             hintStyle: const TextStyle(color: Colors.grey),
            //           ),
            //           enabled: isConnected,
            //         ),
            //       ),
            //     ),
            //     Container(
            //       margin: const EdgeInsets.all(8.0),
            //       child: IconButton(
            //           icon: const Icon(Icons.send),
            //           onPressed: isConnected
            //               ? () => _sendMessage(textEditingController.text)
            //               : null),
            //     ),
            //   ],
            // )
          ],
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
          if (text == '1') {
            isMotorOn = true;
          } else if (text == '0') {
            isMotorOn = false;
          }
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
