import 'dart:async';
import 'dart:typed_data';
import 'package:bc108/bc108.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Exemplo de Bluetooth'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _bondedDevices = Set<BluetoothDevice>();
  final _console = StringBuffer();
  BluetoothConnection _connection;

  _MyHomePageState();

  bool _canRefreshBonded = true;
  void _refreshBonded() async {
    setState(() {
      _canRefreshBonded = false;
    });
    final bonded = await FlutterBluetoothSerial.instance
        .getBondedDevices()
        .timeout(Duration(seconds: 15));
    setState(() {
      _canRefreshBonded = true;
    });
    setState(() {
      _bondedDevices.clear();
      _bondedDevices.addAll(bonded);
    });
  }

  Pinpad _pinpad;

  void _connect(BluetoothDevice device) async {
    print('tapped into ${device.name}');
    if (_connection != null) await _connection.close();
    final connection = await BluetoothConnection.toAddress(device.address)
        .timeout(Duration(seconds: 5));
    setState(() {
      _connection = connection;
      _console.clear();
    });

    final input = connection.input.asBroadcastStream();
    // input.listen((bytes) {
    //   setState(() {
    //     _console.writeln(
    //         "Pinpad->Checkout: ${bytes.map((b) => b.charRepresentation).join()}");
    //   });
    // });
    final stream = input.flatMap((x) => Stream.fromIterable(x));

    // ignore: close_sinks
    final newController = StreamController<int>();
    final newOutputStream = newController.stream
        .bufferTime(Duration(milliseconds: 15))
        .map((x) => Uint8List.fromList(x));
    connection.output.addStream(newOutputStream);
    // ignore: close_sinks
    final sink = newController.sink;

    if (_pinpad != null) _pinpad.done();
    _pinpad = Pinpad.fromStreamAndSink(stream, sink);
    _pinpad.notifications.listen((message) {
      setState(() {
        _console.writeln("📩 $message");
      });
    });

    _refreshBonded();
  }

  int _convertTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final result = 100000000 * date.day +
        1000000 * date.month +
        100 * date.year +
        (timestamp ~/ 864000) % 100;
    return result;
  }

  void _transmitData() async {
    setState(() {
      _console.clear();
    });

    if (_pinpad == null) {
      setState(() {
        _console.writeln("⚠ Pinpad is null ⚠");
      });
      return;
    }

    // await _pinpad.display(DisplayRequest("Quer Atualizar?", "  Press. Entra"));
    // setState(() {
    //   _console.writeln("📺 Confirmando se quer atualizar");
    // });

    // final getKey = await _pinpad.getKey();
    // setState(() {
    //   _console.writeln("Get key: ${getKey.status}");
    // });
    // if (getKey.status == Status.PP_OK) {
    //   final records = [
    //     "1030109A00000000300050203              02VISA VALE REFEIC030084008300000769862001017264853000970018000123E0E0C06000F0F00122D84000A8000010000000D84004F800000003E80020000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1030209A00000000305076010              01ELO CREDITO     030084008300000769862001017264853000970018000123E0E0C06000F0F00122D84000A8000010000000D84004F800000000000000000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1030309A00000000305076020              02ELO DEBITO      030084008300000769862001017264853000970018000123E0E0C07000F0F00122D84000A8000010000000D84004F800000000000000000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1030407A0000000031010                  01CREDITO         030083008400000769862001017264853000970018000123E0F0C87000F0F00122D84000A8000010000000D84004F800000000000020000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3DC4000A8000010000000DC4004F800",
    //     "1030507A0000000032010                  02ELECTRON        030083008400000769862001017264853000970018000123E0F0C87000F0F00122D84000A8000010000000D84004F800000000000020000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3DC4000A8000010000000DC4004F800",
    //     "1030607A0000000041010                  01MASTERCARD CREDI030002000200000769862001017264853000970018000123E0F8E8F000F0A00122FC50ACA0000000000000FC50ACF800000000000040000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3FC508C88000000000000FC508C8800",
    //     "1030708A000000004101001                02MASTERCARD CREDI030002000000000769862001017264853000970018000123E0F8F8FF00F0F00122FCF8FCF8F00000000000FCF8FCF8F0000000000040000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1030807A0000000041012                  02MASTERCARD DEBIT030002000000000769862001017264853000970018000123E0F8E8F000F0F00122FC50ACA0000000000000FC50ACF800000000000040000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1030907A0000000043060                  02MAESTRO         030002000000000769862001017264853000970018000123E0F8E8F000F0F00122FC50ACA0000000000000FC50ACF800000000000040000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3FC500C88000000800000FC500C8800",
    //     "1031006A00000002501                    01AMEX            030001000000000769862001017264853000970018000123E0F0C8600000000122DC50FC98000010000000DC00FC980000000000006000005DD000004B0000003E80000000000000000000000000000000000000000000009F37040000000000000000000000000000000000Y1Z1Y3Z3DC50FC98000010000000DC00FC9800",
    //     "1031107A0000000651010                  01CREDITO         030200000000000769862001017264853000970018000123E0F8E0FF00F0F3FF22FC6024A8000010000000FC60ACF800000000000000000271100001388000013880000000000000000000000000000000000000000000009F37040000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1031207A0000001523010                  01CREDITO         030001000000000769862001017264853000970018000123E0E0C06000F0F00122DC000020000010000000FCE09CF800000000000020000753100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1031307A0000004591010                  01CREDITO         030003000000000769862001017264853000970018000123E040804000D0F00122F87088E8000000000000FCF8FCE800000000000000000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1031407A0000004941010                  01CREDITO ELO     030084008300000769862001017264853000970018000123E0D0C86000F0F00122FC408480000010000000FC6084900000000000002FFFFFFFF00001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1031507A0000004942010                  02DEBITO ELO      030084008300000769862001017264853000970018000123E0C0C07000F0F00122D84000A8000810000000D84004F80000000000002FFFFFFFF00001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1031607A0000004945030                  02AUTO            030002000000000769862001017264853000970018000123E0F8E8F000F0F00122FC50ACA0000000000000FC50ACF800000000000000000753100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1031707A000000555B110                  02BANESCARD       030003000000000769862001017264853000970018000123E040806000F0F00122F87088E8000000000000F8F8FCE800000000000000000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1031807A000000555B120                  01BANESCARD       030003000000000769862001017264853000970018000123E040804000F0F00122F87088E8000000000000FCF8FCE800000000000000000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1031907A0000005895001                  01POLICARD FROTA  030003000000000769862001017264853000970018000123E040804000F0F00122BCF8FCF8F02000000000DCF8FCF8F0000000000000000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1032007A0000005576028                  02AUTO            030002000000000769862001017264853000970018000123E0E0C06000F0F00122F850ACF8000000000000F850ACF800000000000000000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //     "1032107A0000005894001                  01POLICARD CREDITO030003000000000769862001017264853000970018000123E040804000F0F00122BCF8FCF8F02000000000DCF8FCF8F0000000000000000271100001388000013880000000000000000000000000000000000000000000000000000000000000000000000000000000000000Y1Z1Y3Z3000000000000000000000000000000",
    //   ];

    //   final TIMESTAMP = _convertTimestamp(1568389140018);

    //   final open = await _pinpad.open();
    //   setState(() {
    //     _console.writeln("Open: ${open.status}");
    //   });

    //   final loadInit =
    //       await _pinpad.tableLoadInit(TableLoadInitRequest(3, TIMESTAMP));
    //   setState(() {
    //     _console.writeln("▶ Load init status: ${loadInit.status}");
    //   });

    //   for (var rec in records) {
    //     final loadRec = await _pinpad.tableLoadRec(TableLoadRecRequest([rec]));
    //     if (loadRec.status == Status.PP_OK) {
    //       setState(() {
    //         _console.write(".");
    //       });
    //     } else {
    //       setState(() {
    //         _console.writeln("\n🎈 Load rec status: ${loadRec.status}");
    //       });
    //     }
    //   }

    //   final loadEnd = await _pinpad.tableLoadEnd();
    //   setState(() {
    //     _console.writeln("\n🛑 Load end status: ${loadEnd.status}");
    //   });
    // }

    final timestamp = await _pinpad.getTimestamp(GetTimestampRequest(3));
    setState(() {
      _console.writeln("🕓 Timestamp: ${timestamp.status}");
    });

    // final display2 = await _pinpad.display(
    //     DisplayRequest("Tabs Atualizadas!", "TS: ${timestamp.data.timestamp}"));
    // setState(() {
    //   _console.writeln("📺 Display: ${display2.status}");
    // });

    final amount = 3;
    final getCard = await _pinpad.getCard(GetCardRequest()
      ..acquirer = 3
      ..amount = amount
      ..datetime = DateTime.now()
      ..timestamp = timestamp.data.timestamp);
    setState(() {
      _console.writeln(
          "Get card: ${getCard.status} ${getCard.data.cardHolderName} ${getCard.data.pan}");
    });

    final goOnChip = await _pinpad.goOnChip(GoOnChipRequest()
      ..amount = amount
      ..requireOnlineAuthorization = true
      ..requirePin = true
      ..encryptionMode = EncryptionMode.Dukpt3Des
      ..keyIndex = 1
      ..tags = ["9F27", "9F26", "95", "9B", "9F34", "9F10"]
      ..optionalTags = ["5F20", "5F28"]);

    final authMethod = () {
      if (goOnChip.data.pinValidatedOffline) return "OfflineAuthentication";

      if (!goOnChip.data.pinValidatedOffline &&
          !goOnChip.data.pinCapturedForOnlineValidation)
        return "OfflineAuthentication";

      if (!goOnChip.data.pinValidatedOffline &&
          goOnChip.data.pinCapturedForOnlineValidation)
        return "OnlineAuthentication";
    }();

    setState(() {
      _console.writeln(
          "Go on chip: ${goOnChip.data.decision} ${goOnChip.data.tags.raw} $authMethod");
    });

    TlvMap tags = TlvMap.fromMap({
      "91": BinaryData.fromHex("330D56C80029FC3A"),
    });

    final finishChip = await _pinpad.finishChip(FinishChipRequest()
      ..status = CommunicationStatus.Successful
      ..issuerType = IssuerType.EmvFullGrade
      ..authorizationResponseCode = "00"
      ..tags = tags
      ..requiredTagsList = []);
    setState(() {
      _console.writeln("Finish chip: ${finishChip.status}");
    });

    final removeCard = await _pinpad
        .removeCard(RemoveCardRequest("Por favor", " remova o cartao"));
    setState(() {
      _console.writeln("Remove card: ${removeCard.status}");
    });

    final close = await _pinpad.close(CloseRequest("Pinpad", "Fechado"));
    setState(() {
      _console.writeln("Close: ${close.status}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(4),
              width: double.infinity,
              color: Colors.black87,
              child: SingleChildScrollView(
                child: Text(
                  _console.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: Text('Paired Devices')),
                RaisedButton(
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      Text(' Refresh'),
                    ],
                  ),
                  onPressed: !_canRefreshBonded ? null : _refreshBonded,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _bondedDevices.length,
              itemBuilder: (ctx, idx) {
                final device = _bondedDevices.elementAt(idx);
                return ListTile(
                  title: Text(
                    device.name,
                    style: TextStyle(
                        fontWeight: device.isConnected && _connection != null
                            ? FontWeight.bold
                            : FontWeight.normal),
                  ),
                  subtitle: Text(device.address),
                  onTap: () => _connect(device),
                );
              },
            ),
          ),
          Divider(),
          ButtonBar(
            children: [
              RaisedButton(
                child: Text('Transmit Data'),
                onPressed: _transmitData,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
