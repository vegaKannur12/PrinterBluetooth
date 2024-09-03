import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
// import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  bool connected = false;
  List availableBluetoothDevices = [];

  Future<void> getBluetooth() async {
    final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
    print("Print $bluetooths");
    setState(() {
      availableBluetoothDevices = bluetooths!;
    });
  }

  Future<void> setConnect(String mac) async {
    print("MAC = $mac");   // DC:0D:30:6E:A2:EE
    final String? result = await BluetoothThermalPrinter.connect(mac);
    print("state conneected $result");
    if (result == "true") {
      setState(() {
        connected = true;
      });
    }
  }

  Future<void> printTicket() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await getTicket();
      // final result = await BluetoothThermalPrinter.writeBytes(bytes);
      var list = Uint8List.fromList(utf8.encode(bytes[0].toString()));
      final result =
          await BluetoothThermalPrinter.writeText(list[0].toString());
      print("Print success $result");
    } else {
      //Hadnle Not Connected Senario
    }
  }

  Future<void> printGraphics() async {
    String? isConnected = await BluetoothThermalPrinter.connectionStatus;
    if (isConnected == "true") {
      List<int> bytes = await getGraphicsTicket();
      final result = await BluetoothThermalPrinter.writeBytes(bytes);
      print("Print $result");
    } else {
      //Hadnle Not Connected Senario
    }
  }

  Future<List<int>> getGraphicsTicket() async {
    List<int> bytes = [];

    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    // Print QR Code using native function
    bytes += generator.qrcode('example.com');

    bytes += generator.hr();
    // Print Barcode using native function
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    bytes += generator.barcode(Barcode.upcA(barData));

    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> getTicket() async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.setStyles(PosStyles(
      align: PosAlign.left,
      height: PosTextSize.size1,
      width: PosTextSize.size1,
      fontType: PosFontType.fontB,
    ));
    bytes += generator.text("Hello 3,2");
    bytes += generator.text("hellooo");
    // bytes += generator.text("SIZE 3,2"
    // "DIRECTION 1,0"
    // "GAP 0,0\n"
    // "REFERENCE 0,0"
    // "OFFSET 0mm"
    // "SET PEEL OFF"
    // "SET CUTTER OFF"
    // "SET PARTIAL_CUTTER OFF"
    // "SET TEAR ON"
    // "CLS"
    // "TEXT 10,100, \"ROMAN.TTF\",0,1,1,\"        MALINCINSI      \""
    // "TEXT 10,120, \"ROMAN.TTF\",0,1,1,\"        MALINCINSI      \""
    // "TEXT 10,150, \"ROMAN.TTF\",0,1,1,\"     KDV: %18    \""
    // "TEXT 10,200, \"ROMAN.TTF\",0,3,2,\"     12.79    \""
    // "BARCODE 328,386,\"128M\",102,0,180,3,6,\"!10512345678\""
    // "TEXT 328, 250, \"ROMAN.TTF\",0,1,1,\"12345678\""
    // "PRINT 1,1",
    //     // styles: PosStyles(
    //     //   align: PosAlign.center,
    //     //   height: PosTextSize.size2,
    //     //   width: PosTextSize.size2,
    //     // ),
    //     // linesAfter: 1
    //     );

    bytes += generator.cut();
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth Thermal Printer Demo'),
        ),
        body: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Search Paired Bluetooth"),
              TextButton(
                onPressed: () {
                  this.getBluetooth();
                },
                child: Text("Search"),
              ),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: availableBluetoothDevices.length > 0
                      ? availableBluetoothDevices.length
                      : 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        String select = availableBluetoothDevices[index];
                        List list = select.split("#");
                        // String name = list[0];
                        String mac = list[1];
                        this.setConnect(mac);
                      },
                      title: Text('${availableBluetoothDevices[index]}'),
                      subtitle: Text("Click to connect"),
                    );
                  },
                ),
              ),
              SizedBox(
                height: 30,
              ),
              TextButton(
                onPressed: connected ? this.printGraphics : null,
                child: Text("Print"),
              ),
              TextButton(
                onPressed: connected ? this.printTicket : null,
                child: Text("Print Ticket"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
