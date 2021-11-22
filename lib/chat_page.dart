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
  _ChatPage createState() => _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static const clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  bool isMotorOn = false;
  bool isLightOn = false;

  late Timer timer;

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
        if (mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occurred');
      print(error);
    });
  }

  Duration timerInterval = const Duration(seconds: 1);
  int timerCount = 0;

  void stopTimer() {
    timer.cancel();
    timerCount = 0;
  }

  void tick(_) {
    setState(() {
      timerCount++;
      // timerCount = timerCount + 20;
    });
    print(timerCount);
  }

  void startTimer() {
    timer = Timer.periodic(timerInterval, tick);
  }

  String getTimeText() {
    String getParsedTime(String time) {
      if (time.length <= 1) return "0$time";
      return time;
    }

    int min = timerCount ~/ 60;
    int sec = timerCount % 60;

    String parsedTime =
        getParsedTime(min.toString()) + " : " + getParsedTime(sec.toString());

    return parsedTime;
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
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
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
          toolbarHeight: 100,
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
              ? Text(
                  'Connecting chat to ' + serverName + '...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ubuntu(),
                )
              : isConnected
                  ? Text(
                      'Connected with Motor\n' + serverName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
                    )
                  : Text(
                      'Chat log with ' + serverName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ubuntu(),
                    ))),
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
                  const SizedBox(width: 10, height: 10),
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
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 200,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  primary: isMotorOn == true
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                onPressed: isConnected && isMotorOn != true
                                    ? () => _sendMessage('1')
                                    : () => _sendMessage('0'),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      isMotorOn == true
                                          // ? 'Off\nRunning Time: $timerCount sec'
                                          ? 'off'
                                          : 'On',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.ubuntu(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10, height: 10),
                                    isMotorOn == true
                                        ? Text(
                                            getTimeText(),
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.ubuntu(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : Container(),
                                  ],
                                )),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10, height: 10),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7.0),
                          color: Colors.grey[200],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 200,
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: isLightOn == true
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  onPressed: isConnected && isLightOn != true
                                      ? () => _sendMessage('2')
                                      : () => _sendMessage('3'),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        isLightOn == true
                                            // ? 'Off\nRunning Time: $timerCount sec'
                                            ? 'Light off'
                                            : 'Light On',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.ubuntu(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )),
                            ),
                            Icon(
                              isLightOn != true
                                  ? Icons.lightbulb_outline
                                  : Icons.lightbulb,
                              size: 70,
                              color: isLightOn == true
                                  ? Colors.pink
                                  : Colors.white,
                            ),
                            // Text(
                            //   isLightOn == true
                            //       ? 'Light\nCurrently\nOn'
                            //       : 'Light\nCurrently\nOff',
                            //   textAlign: TextAlign.center,
                            //   style: GoogleFonts.ubuntu(
                            //     fontSize: 26,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            const SizedBox(width: 10, height: 10),
                          ],
                        ),
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
    int timerCacktcesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        timerCacktcesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - timerCacktcesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    timerCacktcesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        timerCacktcesCounter++;
      } else {
        if (timerCacktcesCounter > 0) {
          timerCacktcesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is  line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            timerCacktcesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - timerCacktcesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (timerCacktcesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - timerCacktcesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.isNotEmpty) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
          if (text == '1') {
            isMotorOn = true;
            startTimer();
          } else if (text == '0') {
            isMotorOn = false;
            stopTimer();
          } else if (text == '2') {
            isLightOn = true;
          } else if (text == '3') {
            isLightOn = false;
          }
        });

        Future.delayed(const Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
