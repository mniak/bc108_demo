import 'dart:async';
import 'dart:typed_data';
import 'package:bc108/datalink/write/command_factory.dart';
import 'package:rxdart/rxdart.dart';

import 'package:bc108/datalink/operator.dart';
import 'package:bc108/datalink/read/reader.dart';
import 'package:bc108/datalink/utils/bytes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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

  Operator _operator;

  void _connect(BluetoothDevice device) async {
    print('tapped into ${device.name}');
    if (_connection != null) await _connection.close();
    final connection = await BluetoothConnection.toAddress(device.address)
        .timeout(Duration(seconds: 5));
    setState(() {
      _connection = connection;
      _console.clear();
    });
    // final input = _connection.input.asBroadcastStream();
    // input.listen((bytes) {
    //   final sb = StringBuffer();
    //   sb.write('RECV: ');
    //   bytes.forEach((b) {
    //     sb.write(b.charRepresentation);
    //   });
    //   sb.writeln();
    //   setState(() {
    //     _console.write(sb.toString());
    //   });
    // });

    final stream =
        connection.input.flatMap((x) => Stream.fromIterable(x)).asEventReader();
    // ignore: close_sinks
    final newController = StreamController<int>();
    final newOutputStream = newController.stream
        .bufferTime(Duration(milliseconds: 15))
        .map((x) => Uint8List.fromList(x));
    connection.output.addStream(newOutputStream);
    // ignore: close_sinks
    final sink = newController.sink;

    if (_operator != null) _operator.close();
    _operator = Operator.fromStreamAndSink(stream, sink);

    _refreshBonded();
  }

  void _transmitData() async {
    setState(() {
      _console.clear();
    });
    if (_operator == null) {
      setState(() {
        _console.writeln("⚠ Operator is null ⚠");
      });
      return;
    }

    final cf = CommandFactory();
    setState(() {
      _console.writeln("▶ Sending PP_GetInfo(00)");
    });
    final result = await _operator.execute(cf.getInfo(0));
    if (result.aborted) {
      setState(() {
        _console.writeln("🛑 Aborted: ${result.abortMessage}");
      });
    } else if (result.timeout) {
      setState(() {
        _console.writeln("⌛ Timeout");
      });
    } else if (result.isDataResult) {
      setState(() {
        _console.writeln("🎲 Data: ${result.data}");
      });
    } else {
      _console.writeln("⁉ Invalid result");
    }
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
