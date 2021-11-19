import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';

class BluetoothDeviceListEntry extends ListTile {
  BluetoothDeviceListEntry({
    Key? key,
    required BluetoothDevice device,
    int? rssi,
    GestureTapCallback? onTap,
    GestureLongPressCallback? onLongPress,
    bool enabled = true,
  }) : super(
          key: key,
          onTap: onTap,
          onLongPress: onLongPress,
          enabled: enabled,
          leading: const Icon(
              Icons.devices), // @TODO . !BluetoothClass! class aware icon
          title: Text(
            device.name ?? "",
            style: GoogleFonts.ubuntu(),
          ),
          subtitle: Text(
            device.address.toString(),
            style: GoogleFonts.ubuntu(),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              device.address.toString().contains('98:D3:31:FB:17:49')
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.check_circle,
                          color: Colors.green, size: 30),
                    )
                  : Container(),
              rssi != null
                  ? Container(
                      margin: const EdgeInsets.all(8.0),
                      child: DefaultTextStyle(
                        style: _computeTextStyle(rssi),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(rssi.toString(), style: GoogleFonts.ubuntu()),
                            Text('dBm', style: GoogleFonts.ubuntu()),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: 0, height: 0),
              device.isConnected
                  ? const Icon(Icons.import_export)
                  : const SizedBox(width: 0, height: 0),
              device.isBonded
                  ? const Icon(Icons.link)
                  : const SizedBox(width: 0, height: 0),
            ],
          ),
        );

  static TextStyle _computeTextStyle(int rssi) {
    /**/ if (rssi >= -35) {
      return GoogleFonts.ubuntu(color: Colors.greenAccent[700]);
    } else if (rssi >= -45) {
      return GoogleFonts.ubuntu(
          color: Color.lerp(
              Colors.greenAccent[700], Colors.lightGreen, -(rssi + 35) / 10));
    } else if (rssi >= -55) {
      return GoogleFonts.ubuntu(
          color: Color.lerp(
              Colors.lightGreen, Colors.lime[600], -(rssi + 45) / 10));
    } else if (rssi >= -65) {
      return TextStyle(
          color: Color.lerp(Colors.lime[600], Colors.amber, -(rssi + 55) / 10));
    } else if (rssi >= -75) {
      return GoogleFonts.ubuntu(
          color: Color.lerp(
              Colors.amber, Colors.deepOrangeAccent, -(rssi + 65) / 10));
    } else if (rssi >= -85) {
      return GoogleFonts.ubuntu(
          color: Color.lerp(
              Colors.deepOrangeAccent, Colors.redAccent, -(rssi + 75) / 10));
    } else {
      return GoogleFonts.ubuntu(color: Colors.redAccent);
    }
  }
}
