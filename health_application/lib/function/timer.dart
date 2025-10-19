import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../connection/bluetooth.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bluetoothProvider, child) {
        int remainingTime = int.tryParse(bluetoothProvider.timer) ?? 0;
        if (remainingTime <= 0) {
          remainingTime = 0;
        }
        return Container(
          padding: const EdgeInsets.all(10),
          child: Text(
            '$remainingTime',
            style: const TextStyle(fontSize: 24, color: Colors.black),
          ),
        );
      },
    );
  }
}
