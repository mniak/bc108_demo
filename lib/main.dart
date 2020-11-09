import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_demo/bytes_builder.dart';
import 'package:bluetooth_demo/crc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'bytes.dart';

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
  final _devices = Set<BluetoothDevice>();
  final _bondedDevices = Set<BluetoothDevice>();
  BluetoothState _state = BluetoothState.UNKNOWN;
  StreamSubscription<BluetoothDiscoveryResult> _discoverySubscription;
  BluetoothConnection _connection;

  _MyHomePageState() {
    _bluetoothStateCallback((event) {
      setState(() {
        this._state = event;
      });
    });
  }

  void _bluetoothStateCallback(Function(BluetoothState) callback) {
    FlutterBluetoothSerial.instance.state.then((state) {
      callback(state);
    });
    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      callback(state);
    });
  }

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

  bool _canRefreshDiscovered = true;
  void _refreshDiscovered() async {
    setState(() {
      _canRefreshDiscovered = false;
    });
    setState(() {
      _devices.clear();
    });
    FlutterBluetoothSerial.instance.startDiscovery().listen((event) {
      _devices.add(event.device);
    });
    setState(() {
      _canRefreshDiscovered = true;
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
          StatefulBuilder(
            builder: (ctx, snap) {
              return ListTile(
                title: Text('Connection State'),
                subtitle: Text(_state.toString()),
              );
            },
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: Text('Discovered Devices')),
                RaisedButton(
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      Text(' Refresh'),
                    ],
                  ),
                  onPressed: !_canRefreshDiscovered ? null : _refreshDiscovered,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (ctx, idx) {
                return ListTile(
                  title: Text('device 01'),
                  subtitle: Text('strength 01'),
                );
              },
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
                  onTap: () async {
                    print('tapped into ${device.name}');
                    if (_connection != null) await _connection.close();
                    final connection =
                        await BluetoothConnection.toAddress(device.address)
                            .timeout(Duration(seconds: 5));
                    setState(() {
                      _connection = connection;
                    });
                    _refreshBonded();
                  },
                );
              },
            ),
          ),
          Divider(),
          ButtonBar(
            children: [
              RaisedButton(
                child: Text('Transmit Data'),
                onPressed: () {
                  final data = _buildData
                  _connection.output.add(data);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
