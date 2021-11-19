import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';

import 'background_collecting_task.dart';
import 'chat_page.dart';
import 'select_bonded_device_page.dart';

// import './helpers/LineChart.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer? _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask? _collectingTask;

  bool _autoAcceptPairingRequests = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name!;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1.0,
        toolbarHeight: 100, // Set this height
        flexibleSpace: Container(
          color: const Color(0xff303a52),
          child: Center(
            child: Text(
              '\nFlutter Bluetooth',
              style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(100.0),
      //   child: AppBar(
      //     toolbarHeight: 120, // Set this height
      //     flexibleSpace: Container(
      //       color: Colors.orange,
      //       child: Column(
      //         mainAxisAlignment: MainAxisAlignment.center,
      //         crossAxisAlignment: CrossAxisAlignment.center,
      //         children: [
      //           Text('1'),
      //           Text('2'),
      //           Text('3'),
      //           Text('4'),
      //         ],
      //       ),
      //     ),
      //   ),
      //   // child: AppBar(
      //   //   // backgroundColor: Color(0xff303a52),
      //   //   centerTitle: true,
      //   //   elevation: 0.0,
      //   //   title: Text(
      //   //     '\nTurn Motor On',
      //   //     style: GoogleFonts.ubuntu(
      //   //       fontWeight: FontWeight.bold,
      //   //     ),
      //   //   ),
      //   // ),
      // ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            children: <Widget>[
              ListTile(
                  title: Text(
                'General',
                style: GoogleFonts.ubuntu(),
              )),
              SwitchListTile(
                title: Text(
                  'Enable Bluetooth',
                  style: GoogleFonts.ubuntu(),
                ),
                value: _bluetoothState.isEnabled,
                onChanged: (bool value) {
                  // Do the request and update with the true value then
                  future() async {
                    // async lambda seems to not working
                    if (value) {
                      await FlutterBluetoothSerial.instance.requestEnable();
                    } else {
                      await FlutterBluetoothSerial.instance.requestDisable();
                    }
                  }

                  future().then((_) {
                    setState(() {});
                  });
                },
              ),
              ListTile(
                title: Text(
                  'Bluetooth status',
                  style: GoogleFonts.ubuntu(),
                ),
                subtitle: Text(_bluetoothState.toString()),
                trailing: ElevatedButton(
                  child: Text(
                    'Settings',
                    style: GoogleFonts.ubuntu(),
                  ),
                  onPressed: () {
                    FlutterBluetoothSerial.instance.openSettings();
                  },
                ),
              ),
              // ListTile(
              //   title: const Text('Local adapter address'),
              //   subtitle: Text(_address),
              // ),
              // ListTile(
              //   title: const Text('Local adapter name'),
              //   subtitle: Text(_name),
              //   onLongPress: null,
              // ),
              // ListTile(
              //   title: _discoverableTimeoutSecondsLeft == 0
              //       ? const Text("Discoverable")
              //       : Text(
              //           "Discoverable for ${_discoverableTimeoutSecondsLeft}s"),
              //   subtitle: const Text("PsychoX-Luna"),
              //   trailing: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Checkbox(
              //         value: _discoverableTimeoutSecondsLeft != 0,
              //         onChanged: null,
              //       ),
              //       IconButton(
              //         icon: const Icon(Icons.edit),
              //         onPressed: null,
              //       ),
              //       IconButton(
              //         icon: const Icon(Icons.refresh),
              //         onPressed: () async {
              //           print('Discoverable requested');
              //           final int timeout = (await FlutterBluetoothSerial.instance
              //               .requestDiscoverable(60))!;
              //           if (timeout < 0) {
              //             print('Discoverable mode denied');
              //           } else {
              //             print(
              //                 'Discoverable mode acquired for $timeout seconds');
              //           }
              //           setState(() {
              //             _discoverableTimeoutTimer?.cancel();
              //             _discoverableTimeoutSecondsLeft = timeout;
              //             _discoverableTimeoutTimer =
              //                 Timer.periodic(Duration(seconds: 1), (Timer timer) {
              //               setState(() {
              //                 if (_discoverableTimeoutSecondsLeft < 0) {
              //                   FlutterBluetoothSerial.instance.isDiscoverable
              //                       .then((isDiscoverable) {
              //                     if (isDiscoverable ?? false) {
              //                       print(
              //                           "Discoverable after timeout... might be infinity timeout :F");
              //                       _discoverableTimeoutSecondsLeft += 1;
              //                     }
              //                   });
              //                   timer.cancel();
              //                   _discoverableTimeoutSecondsLeft = 0;
              //                 } else {
              //                   _discoverableTimeoutSecondsLeft -= 1;
              //                 }
              //               });
              //             });
              //           });
              //         },
              //       )
              //     ],
              //   ),
              // ),
              const Divider(),
              ListTile(
                  title: Text(
                'Connect to Blutooth Device',
                style: GoogleFonts.ubuntu(),
              )),

              // SwitchListTile(
              //   title: const Text('Auto-try specific pin when pairing'),
              //   subtitle: const Text('Pin 1234'),
              //   value: _autoAcceptPairingRequests,
              //   onChanged: (bool value) {
              //     setState(() {
              //       _autoAcceptPairingRequests = value;
              //     });
              //     if (value) {
              //       FlutterBluetoothSerial.instance.setPairingRequestHandler(
              //           (BluetoothPairingRequest request) {
              //         print("Trying to auto-pair with Pin 1234");
              //         if (request.pairingVariant == PairingVariant.Pin) {
              //           return Future.value("1234");
              //         }
              //         return Future.value(null);
              //       });
              //     } else {
              //       FlutterBluetoothSerial.instance
              //           .setPairingRequestHandler(null);
              //     }
              //   },
              // ),
              // ListTile(
              //   title: ElevatedButton(
              //       child: const Text('Explore discovered devices'),
              //       onPressed: () async {
              //         final BluetoothDevice? selectedDevice =
              //             await Navigator.of(context).push(
              //           MaterialPageRoute(
              //             builder: (context) {
              //               return DiscoveryPage();
              //             },
              //           ),
              //         );

              //         if (selectedDevice != null) {
              //           print('Discovery -> selected ' + selectedDevice.address);
              //         } else {
              //           print('Discovery -> no device selected');
              //         }
              //       }),
              // ),

              // ListTile(title: const Text('Multiple connections example')),
              // ListTile(
              //   title: ElevatedButton(
              //     child: ((_collectingTask?.inProgress ?? false)
              //         ? const Text('Disconnect and stop background collecting')
              //         : const Text('Connect to start background collecting')),
              //     onPressed: () async {
              //       if (_collectingTask?.inProgress ?? false) {
              //         await _collectingTask!.cancel();
              //         setState(() {
              //           /* Update for `_collectingTask.inProgress` */
              //         });
              //       } else {
              //         final BluetoothDevice? selectedDevice =
              //             await Navigator.of(context).push(
              //           MaterialPageRoute(
              //             builder: (context) {
              //               return SelectBondedDevicePage(
              //                   checkAvailability: false);
              //             },
              //           ),
              //         );

              //         if (selectedDevice != null) {
              //           await _startBackgroundTask(context, selectedDevice);
              //           setState(() {
              //             /* Update for `_collectingTask.inProgress` */
              //           });
              //         }
              //       }
              //     },
              //   ),
              // ),
              // ListTile(
              //   title: ElevatedButton(
              //     child: const Text('View background collected data'),
              //     onPressed: (_collectingTask != null)
              //         ? () {
              //             Navigator.of(context).push(
              //               MaterialPageRoute(
              //                 builder: (context) {
              //                   return ScopedModel<BackgroundCollectingTask>(
              //                     model: _collectingTask!,
              //                     child: BackgroundCollectedPage(),
              //                   );
              //                 },
              //               ),
              //             );
              //           }
              //         : null,
              //   ),
              // ),
            ],
          ),
          SizedBox(
            height: 200,
            width: 320,
            child: Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: const Color(0xff775ada),
                  shadowColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 10,
                ),
                child: Text(
                  'Tap to\nConnect to Motor\n"HC-05"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ubuntuMono(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  final BluetoothDevice? selectedDevice =
                      await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return const SelectBondedDevicePage(
                            checkAvailability: false);
                      },
                    ),
                  );

                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);
                    _startChat(context, selectedDevice);
                  } else {
                    print('Connect -> no device selected');
                  }
                },
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const ClipOval(
                child: FlutterLogo(
                  size: 34,
                ),
              ),
              const SizedBox(width: 10, height: 10),
              Text(
                'Build with Flutter',
                style: GoogleFonts.ubuntu(
                    fontSize: 12, color: Colors.black.withOpacity(0.8)),
              ),
              const SizedBox(width: 10, height: 8),
              Text(
                '@ m o n z i m',
                style: GoogleFonts.ubuntu(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 10, height: 10),
            ],
          ),
        ],
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }

  Future<void> _startBackgroundTask(
    BuildContext context,
    BluetoothDevice server,
  ) async {
    try {
      _collectingTask = await BackgroundCollectingTask.connect(server);
      await _collectingTask!.start();
    } catch (ex) {
      _collectingTask?.cancel();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occurred while connecting'),
            content: Text(ex.toString()),
            actions: <Widget>[
              TextButton(
                child: const Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
