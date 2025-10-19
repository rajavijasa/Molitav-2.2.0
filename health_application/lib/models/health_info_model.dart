import 'package:flutter/material.dart';

const celsiusSymbol = '\u{2103}';

class HealthInfoModel {
  String name;
  String iconPath;
  String data;
  String unit;
  Color boxColor;
  Color iconColor; //for icon place holder color, not the icon color

  HealthInfoModel(
      {required this.name,
      required this.iconPath,
      required this.data,
      required this.unit,
      required this.boxColor,
      required this.iconColor});

  static List<HealthInfoModel> getHealthInfo() {
    List<HealthInfoModel> healthInfo = [];

    healthInfo.add(HealthInfoModel(
        name: 'Heart Rate',
        iconPath: 'assets/icons/pulse.svg',
        data: 'N/A',
        unit: 'bpm',
        boxColor: const Color.fromARGB(255, 70, 133, 188),
        iconColor: const Color.fromARGB(255, 177, 87, 78)));

    healthInfo.add(HealthInfoModel(
        name: 'SPO2',
        iconPath: 'assets/icons/blood.svg',
        data: 'N/A',
        unit: '%',
        boxColor: const Color.fromARGB(255, 70, 133, 188),
        iconColor: const Color.fromARGB(255, 119, 177, 78)));

    healthInfo.add(HealthInfoModel(
        name: 'Body Temperature',
        iconPath: 'assets/icons/temp.svg',
        data: 'N/A',
        unit: celsiusSymbol,
        boxColor: const Color.fromARGB(255, 70, 133, 188),
        iconColor: const Color.fromARGB(255, 207, 63, 63)));

    healthInfo.add(HealthInfoModel(
        name: 'Skin Temperature',
        iconPath: 'assets/icons/temp.svg',
        data: 'N/A',
        unit: celsiusSymbol,
        boxColor: const Color.fromARGB(255, 70, 133, 188),
        iconColor: const Color.fromARGB(255, 211, 165, 76)));

    healthInfo.add(HealthInfoModel(
        name: 'Respiration',
        iconPath: 'assets/icons/lung.svg',
        data: 'N/A',
        unit: 'bpm',
        boxColor: const Color.fromARGB(255, 70, 133, 188),
        iconColor: const Color.fromARGB(255, 28, 193, 127)));

    healthInfo.add(HealthInfoModel(
        name: 'Cholesterol',
        iconPath: 'assets/icons/kolesterol.svg',
        data: 'N/A',
        unit: 'mg/dL',
        boxColor: const Color.fromARGB(255, 70, 133, 188),
        iconColor: const Color.fromRGBO(23, 216, 191, 1)));

    return healthInfo;
  }

  void updateData(String newData) {
    if (name == 'Cholesterol') {
      // Ganti koma dengan titik untuk parsing yang benar
      final parsableData = newData.replaceAll(',', '.');
      final value = double.tryParse(parsableData);
      if (value != null) {
        // Jika parsing berhasil, bulatkan dan ubah ke string
        data = value.round().toString();
      } else {
        // Jika parsing gagal, gunakan data asli sebagai fallback
        data = newData;
      }
    } else {
      // Untuk tipe data lain, pertahankan perilaku asli
      data = newData;
    }
  }
}