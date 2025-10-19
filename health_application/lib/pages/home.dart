import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:molitav/function/timer.dart';
import 'package:provider/provider.dart';
import '../connection/bluetooth.dart';
import '../models/health_info_model.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<HealthInfoModel> healthInfo = [];

  @override
  void initState() {
    super.initState();
    _getInitialInfo();
  }

  void _getInitialInfo() {
    healthInfo = HealthInfoModel.getHealthInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 226, 242, 255),
      body: Consumer<BluetoothProvider>(
        builder: (context, bluetoothProvider, child) {
          return ListView(
            children: [
              _healthInfo(bluetoothProvider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {},
          backgroundColor: const Color(0xFFA5DCF4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: const TimerWidget()),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Column _healthInfo(BluetoothProvider bluetoothProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        healthInfo.length,
        (index) {
          return Container(
            margin: const EdgeInsets.only(top: 16, left: 20, right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            height: 120,
            decoration: BoxDecoration(
              color: healthInfo[index].boxColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: healthInfo[index].iconColor,
                  ),
                  child: SvgPicture.asset(
                    healthInfo[index].iconPath,
                    height: 40,
                    width: 40,
                    //change icon color
                    colorFilter: const ColorFilter.mode(
                      Color.fromARGB(255, 224, 224, 224),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      healthInfo[index].name,
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Color.fromARGB(255, 200, 200, 200),
                        fontSize: 20,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          bluetoothProvider.healthInfo[index].data,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Color.fromARGB(255, 224, 224, 224),
                            fontSize: 36,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          healthInfo[index].unit,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Color.fromARGB(255, 224, 224, 224),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
