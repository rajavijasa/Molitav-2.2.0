import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/health_info_model.dart';

class BluetoothProvider extends ChangeNotifier {
  BluetoothDevice? _pairedDevice;
  final List<BluetoothDevice> _discoveredDevices = [];
  bool _scanning = false;
  String _timer = '0';
  final List<HealthInfoModel> _healthInfo = HealthInfoModel.getHealthInfo();
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;

  BluetoothDevice? get pairedDevice => _pairedDevice;
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  bool get scanning => _scanning;
  String get timer => _timer;
  List<HealthInfoModel> get healthInfo => _healthInfo;

  Future<void> startScan() async {
    _discoveredDevices.clear();
    _scanning = true;
    notifyListeners();

    _bluetooth.startDiscovery().listen((result) {
      final device = result.device;
      if (!_discoveredDevices.any((d) => d.address == device.address)) {
        _discoveredDevices.add(device);
      }
      notifyListeners();
    }).onDone(() {
      _scanning = false;
      notifyListeners();
    });
  }

  Future<void> pairDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _pairedDevice = device;
      _connection!.input!.listen(_onDataReceived).onDone(() {
        _pairedDevice = null;
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to pair device: $e');
    }
  }

  void _onDataReceived(Uint8List data) {
    String receivedData = String.fromCharCodes(data);
    _parseData(receivedData);
  }

  void _parseData(String data) {
    Map<String, String> dataMap = {};
    List<String> lines = data.split('\n');
    for (String line in lines) {
      if (line.isNotEmpty) {
        List<String> parts = line.split('\t');
        if (parts.length == 2) {
          dataMap[parts[0]] = parts[1];
        }
      }
    }

    if (dataMap.isNotEmpty) {
      _healthInfo[0].updateData(dataMap["BPM"] ?? _healthInfo[0].data);
      _healthInfo[1].updateData(dataMap["SPO2"] ?? _healthInfo[1].data);
      _healthInfo[2].updateData(dataMap["TBody"] ?? _healthInfo[2].data);
      _healthInfo[3].updateData(dataMap["TSkin"] ?? _healthInfo[3].data);
      _healthInfo[4].updateData(dataMap["RR"] ?? _healthInfo[4].data);
      _healthInfo[5].updateData(dataMap["Kolesterol"] ?? _healthInfo[5].data);
      _timer = dataMap["Timer"] ?? _timer;

      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> fetchData() async {
    if (_pairedDevice != null) {
      _listenToData();
    }
  }

  void _listenToData() {
    if (_connection != null && _connection!.isConnected) {
      _connection!.input!.listen(_onDataReceived).onDone(() {
        _pairedDevice = null;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}