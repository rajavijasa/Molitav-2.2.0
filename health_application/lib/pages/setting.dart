import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../connection/bluetooth.dart';
import 'package:restart_app/restart_app.dart';
import '../function/permission.dart'; // Import the permission handling file

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 226, 242, 255),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 165, 220, 244),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Consumer<BluetoothProvider>(
              builder: (context, bluetoothProvider, child) {
                return Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Paired Device',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        bluetoothProvider.pairedDevice != null
                            ? bluetoothProvider.pairedDevice!.name ??
                                'Unknown Device'
                            : 'No device paired',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            height: 70,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 165, 220, 244),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Restart App',
                    style: TextStyle(fontSize: 24),
                  ),
                  IconButton(
                    icon: SvgPicture.asset('assets/icons/restart.svg'),
                    onPressed: () {
                      Restart.restartApp();
                    },
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Devices',
                  style: TextStyle(fontSize: 32),
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/plus_2.svg',
                    height: 30,
                    width: 30,
                  ),
                  onPressed: () async {
                    // Check and request permissions
                    await requestPermissions();

                    bool isPermissionGranted = await checkPermissions();

                    if (isPermissionGranted) {
                      // Start Bluetooth device scanning
                      context.read<BluetoothProvider>().startScan();
                    } else {
                      // Show a warning if the necessary permissions are not granted
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Permissions are required to scan, discover, and connect to devices.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<BluetoothProvider>(
              builder: (context, bluetoothProvider, child) {
                if (bluetoothProvider.scanning) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (bluetoothProvider.discoveredDevices.isEmpty) {
                  return const Center(
                    child: Text(
                      'No devices found',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: bluetoothProvider.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = bluetoothProvider.discoveredDevices[index];
                      return ListTile(
                        title: Text(
                          device.name ?? device.address.toString(),
                          style: const TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(device.address.toString()),
                        onTap: () async {
                          try {
                            await bluetoothProvider.pairDevice(device);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Paired with ${device.name ?? device.address}',
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to pair: $e'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
