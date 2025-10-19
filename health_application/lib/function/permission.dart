import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  const bluetoothScanPermission = Permission.bluetoothScan;
  const bluetoothConnectPermission = Permission.bluetoothConnect;
  const bluetoothAdvertisePermission = Permission.bluetoothAdvertise;
  const locationPermission = Permission.locationWhenInUse;

  // Request Bluetooth Scan Permission
  if (await bluetoothScanPermission.isDenied) {
    final result = await bluetoothScanPermission.request();
    if (!result.isGranted) {
      // Permission not granted, inform the user
      return;
    }
  }

  // Request Bluetooth Connect Permission
  if (await bluetoothConnectPermission.isDenied) {
    final result = await bluetoothConnectPermission.request();
    if (!result.isGranted) {
      // Permission not granted, inform the user
      return;
    }
  }

  // Request Bluetooth Advertise Permission
  if (await bluetoothAdvertisePermission.isDenied) {
    final result = await bluetoothAdvertisePermission.request();
    if (!result.isGranted) {
      // Permission not granted, inform the user
      return;
    }
  }

  // Request Location Permission
  if (await locationPermission.isDenied) {
    final result = await locationPermission.request();
    if (!result.isGranted) {
      // Permission not granted, inform the user
      return;
    }
  }
}

Future<bool> checkPermissions() async {
  final bluetoothScanStatus = await Permission.bluetoothScan.status;
  final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
  final locationStatus = await Permission.locationWhenInUse.status;

  return bluetoothScanStatus.isGranted &&
      bluetoothConnectStatus.isGranted &&
      locationStatus.isGranted;
}
