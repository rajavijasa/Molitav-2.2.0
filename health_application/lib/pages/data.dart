import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:molitav/connection/bluetooth.dart';
import 'package:molitav/models/health_info_model.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

// Global data storage untuk menyimpan data grafik
class GraphDataStorage {
  static final Map<String, List<double>> _dataStorage = {};
  static final Map<String, List<DateTime>> _timestampStorage = {};
  static final Map<String, double> _lastValues = {};

  static List<double> getData(String key) {
    return _dataStorage[key] ?? [];
  }

  static List<DateTime> getTimestamps(String key) {
    return _timestampStorage[key] ?? [];
  }

  static void addData(String key, double value, [DateTime? timestamp]) {
    final now = timestamp ?? DateTime.now(); // Gunakan timestamp yang diberikan, atau buat baru

    // Logika baru: Langsung tambahkan data. Keputusan *kapan* menambahkan
    // sudah dibuat oleh fungsi _updateAllGraphData.
    _dataStorage.putIfAbsent(key, () => []).add(value);
    _timestampStorage.putIfAbsent(key, () => []).add(now);
    _lastValues[key] = value; // Selalu update nilai terakhir yang *disimpan*

    // --- PERUBAHAN LOGIKA PEMBERSIHAN DATA ---
    // Gunakan 'now' dari timestamp yang konsisten
    final oneHourAgo = now.subtract(const Duration(minutes: 60)); 
    // Hapus data lama, TAPI sisakan satu titik sebagai "anchor" di luar batas kiri.
    // Kita periksa titik KEDUA. Jika titik kedua sudah terlalu tua, maka titik pertama aman untuk dihapus.
    while (_timestampStorage[key] != null && // Tambahkan null check
        _timestampStorage[key]!.length > 1 &&
        _timestampStorage[key]![1].isBefore(oneHourAgo)) {
      _timestampStorage[key]!.removeAt(0);
      _dataStorage[key]!.removeAt(0);
    }
    // --- AKHIR DARI PERUBAHAN ---
  }

  static void clearData(String key) {
    _dataStorage[key]?.clear();
    _timestampStorage[key]?.clear();
    _lastValues.remove(key);
  }

  // Method untuk mendapatkan nilai terakhir
  static double? getLastValue(String key) {
    return _lastValues[key];
  }
}

// Global timer untuk update semua grafik
class GlobalGraphUpdater {
  static Timer? _globalTimer;
  static final Set<VoidCallback> _updateCallbacks = {};
  
  static void addUpdateCallback(VoidCallback callback) {
    _updateCallbacks.add(callback);
    _startTimerIfNeeded();
  }
  
  static void removeUpdateCallback(VoidCallback callback) {
    _updateCallbacks.remove(callback);
    if (_updateCallbacks.isEmpty) {
      _globalTimer?.cancel();
      _globalTimer = null;
    }
  }
  
  static void _startTimerIfNeeded() {
    if (_globalTimer == null && _updateCallbacks.isNotEmpty) {
      _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        for (final callback in _updateCallbacks) {
          callback();
        }
      });
    }
  }
  
  static void dispose() {
    _globalTimer?.cancel();
    _globalTimer = null;
    _updateCallbacks.clear();
  }
}

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  Timer? _dataUpdateTimer;
  // DateTime? _connectionTime;

  @override
  void initState() {
    super.initState();
    
    // Timer untuk mengumpulkan dan menyimpan semua data secara bersamaan
    _dataUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateAllGraphData();
    });
  }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    super.dispose();
  }

  void _updateAllGraphData() {
    final bluetoothProvider =
        Provider.of<BluetoothProvider>(context, listen: false);

    // Hanya update data grafik jika ada perangkat yang terhubung
    if (bluetoothProvider.pairedDevice != null) {
      final parameters = [
        'Heart Rate',
        'SPO2',
        'Body Temperature',
        'Skin Temperature',
        'Respiration',
        'Cholesterol'
      ];

      // 1. Kumpulkan semua nilai saat ini ke dalam map
      final Map<String, double> currentValues = {};
      for (final param in parameters) {
        currentValues[param] = getCurrentValue(param, bluetoothProvider);
      }

      // 2. Cek apakah ada *satu saja* nilai yang berubah dari yang terakhir disimpan
      bool anyValueChanged = false;
      for (final param in parameters) {
        final lastValue = GraphDataStorage.getLastValue(param);
        final currentValue = currentValues[param]!;

        // Jika belum ada data (lastValue == null) ATAU nilainya berubah
        if (lastValue == null || lastValue != currentValue) {
          anyValueChanged = true;
          break; // Cukup satu perubahan terdeteksi
        }
      }

      // 3. Jika ada perubahan, simpan SEMUA nilai saat ini dengan timestamp yang SAMA
      if (anyValueChanged) {
        final now = DateTime.now(); // Buat satu timestamp untuk semua
        for (final param in parameters) {
          final value = currentValues[param]!;
          // Panggil addData dengan timestamp yang konsisten
          GraphDataStorage.addData(param, value, now);
        }
      }
    }
  }

  double getCurrentValue(String key, BluetoothProvider provider) {
    final HealthInfoModel? healthInfo = provider.healthInfo.firstWhereOrNull(
      (info) => info.name == key,
    );
    // Parse data dari provider jika ada dan bukan 'N/A'
    if (healthInfo != null && healthInfo.data != 'N/A') {
      return double.tryParse(healthInfo.data.replaceAll(',', '.')) ?? 0.0;
    }
    // Jika tidak, kembalikan 0.0 untuk grafik
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);

    // Helper to get data, prefers provider data
    String getData(String key, String unit) {
      final HealthInfoModel? healthInfo = bluetoothProvider.healthInfo.firstWhereOrNull(
        (info) => info.name == key,
      );
      // Tampilkan data dari provider jika ada dan bukan 'N/A'
      if (healthInfo != null && healthInfo.data != 'N/A') {
        return '${healthInfo.data} $unit';
      }
      // Jika tidak, tampilkan 'N/A'
      return 'N/A';
    }

    // Helper untuk mendapatkan status Body Temperature
    String getBodyTempStatus() {
      final bodyTempValue = getCurrentValue('Body Temperature', bluetoothProvider);
      if (bodyTempValue == 0.0) return 'Belum Diperiksa';
      if (bodyTempValue >= 40) return 'Hyperthermia';
      if (bodyTempValue >= 37.5) return 'Demam';
      if (bodyTempValue < 36) return 'Hypothermia';
      return 'Normal';
    }

    final bodyTempStatus = getBodyTempStatus();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 226, 242, 255),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          HealthDataCard(
            title: 'Heart Rate',
            value: getData('Heart Rate', 'bpm'),
            iconPath: 'assets/icons/pulse.svg',
            iconColor: const Color(0xFFE55A5A),
            minY: 30,
            maxY: 240,
            currentValue: getCurrentValue('Heart Rate', bluetoothProvider),
          ),
          const SizedBox(height: 16),
          HealthDataCard(
            title: 'SPO2',
            value: getData('SPO2', '%'),
            iconPath: 'assets/icons/blood.svg',
            iconColor: const Color(0xFF69C354),
            minY: 0,
            maxY: 100,
            currentValue: getCurrentValue('SPO2', bluetoothProvider),
          ),
          const SizedBox(height: 16),
          HealthDataCard(
            title: 'Body Temperature',
            value: getData('Body Temperature', '°C'),
            iconPath: 'assets/icons/temp.svg',
            iconColor: const Color(0xFFE55A5A),
            minY: 35,
            maxY: 42,
            currentValue: getCurrentValue('Body Temperature', bluetoothProvider),
          ),
          const SizedBox(height: 16),
          HealthDataCard(
            title: 'Skin Temperature',
            value: getData('Skin Temperature', '°C'),
            iconPath: 'assets/icons/temp.svg',
            iconColor: const Color(0xFFF39C12),
            minY: 31,
            maxY: 39,
            currentValue: getCurrentValue('Skin Temperature', bluetoothProvider),
            overrideStatus: bodyTempStatus, // Menggunakan status dari Body Temperature
          ),
          const SizedBox(height: 16),
          HealthDataCard(
            title: 'Respiration',
            value: getData('Respiration', 'rpm'),
            iconPath: 'assets/icons/lung.svg',
            iconColor: const Color(0xFF48C9B0),
            minY: 0,
            maxY: 60,
            currentValue: getCurrentValue('Respiration', bluetoothProvider),
          ),
          const SizedBox(height: 16),
          HealthDataCard(
            title: 'Cholesterol',
            value: getData('Cholesterol', 'mg/dL'),
            iconPath: 'assets/icons/kolesterol.svg',
            iconColor: const Color.fromARGB(255, 12, 208, 162),
            minY: 100,
            maxY: 400,
            currentValue: getCurrentValue('Cholesterol', bluetoothProvider),
          ),
        ],
      ),
    );
  }
}

class HealthDataCard extends StatefulWidget {
  final String title;
  final String value;
  final String iconPath;
  final Color iconColor;
  final double minY;
  final double maxY;
  final double currentValue;
  final String? overrideStatus; // Parameter baru

  const HealthDataCard({
    super.key,
    required this.title,
    required this.value,
    required this.iconPath,
    required this.iconColor,
    required this.minY,
    required this.maxY,
    required this.currentValue,
    this.overrideStatus, // Tambahkan di constructor
  });

  @override
  State<HealthDataCard> createState() => _HealthDataCardState();
}

class _HealthDataCardState extends State<HealthDataCard> {
  DateTime _currentTime = DateTime.now();
  late VoidCallback _updateCallback;

  @override
  void initState() {
    super.initState();
    
    // Callback untuk update dari GlobalGraphUpdater
    _updateCallback = () {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    };
    
    // Daftarkan ke global updater
    GlobalGraphUpdater.addUpdateCallback(_updateCallback);
  }

  @override
  void dispose() {
    // Hapus dari global updater
    GlobalGraphUpdater.removeUpdateCallback(_updateCallback);
    super.dispose();
  }

  String _getCondition(String title, double val) {
    // Jika ada status pengganti, gunakan itu
    if (widget.overrideStatus != null) {
      return widget.overrideStatus!;
    }

    // Periksa apakah nilai adalah 0.0 (default untuk data 'N/A')
    if (val == 0.0) return 'Belum Diperiksa';

    switch (title) {
      case 'SPO2':
        if (val < 67) return 'Cyanosis';
        if (val < 90) return 'Hipoksia';
        if (val < 95) return 'Hipoksemia';
        return 'Normal';
      case 'Body Temperature':
        if (val >= 40) return 'Hyperthermia';
        if (val > 38) return 'Demam';
        if (val < 36) return 'Hypothermia';
        return 'Normal';
      case 'Heart Rate':
        if (val < 40) return 'Bradikardia Berat';
        if (val < 60) return 'Bradikardia';
        if (val > 180) return 'Takikardia Sangat Berat';
        if (val > 150) return 'Takikardia Berat';
        if (val > 120) return 'Takikardia Sedang';
        if (val > 100) return 'Takikardia Ringan';
        return 'Normal';
      case 'Respiration':
        if (val == 0) return 'Apnea';
        if (val < 8) return 'Bradipnea Berat';
        if (val < 12) return 'Bradipnea';
        if (val > 60) return 'Not Defined';     
        if (val > 40) return 'Hyperventilasi (Respirasi Berat)';
        if (val > 30) return 'Takipnea Berat';
        if (val >= 25) return 'Takipnea Sedang';
        if (val > 20) return 'Takipnea Ringan';        
        return 'Normal';
      case 'Cholesterol':
        if (val < 120) return 'Sangat Rendah';
        if (val < 160) return 'Rendah';
        if (val >= 300) return 'Sangat Tinggi (Severe Hypercholesterolemia)';
        if (val >= 240) return 'Tinggi (Hypercholesterolemia)';
        if (val >= 200) return 'Batas Tinggi';
        return 'Normal';
      default:
        return '';
    }
  }

  // Format waktu dalam HH:MM:SS
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  void _showDataPointPopup(BuildContext context, double value, DateTime timestamp) {
    final condition = _getCondition(widget.title, value);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nilai: ${value.toStringAsFixed(1)}'),
              Text('Status: $condition'),
              Text('Waktu: ${_formatTime(timestamp)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final condition = _getCondition(widget.title, widget.currentValue);

    // Menghitung waktu 5 menit yang lalu (bukan 1 jam)
    final oneHourAgo = _currentTime.subtract(const Duration(minutes: 60));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.iconColor,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  widget.iconPath,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    if (condition.isNotEmpty)
                      Text(condition, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              // Tampilkan nilai dari bluetooth
              Text(widget.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 110,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTapDown: (TapDownDetails details) {
                      final data = GraphDataStorage.getData(widget.title);
                      final timestamps = GraphDataStorage.getTimestamps(widget.title);
                      
                      if (data.isNotEmpty && timestamps.isNotEmpty) {
                        final RenderBox renderBox = context.findRenderObject() as RenderBox;
                        final localPosition = renderBox.globalToLocal(details.globalPosition);
                        
                        // Hitung posisi relatif dalam area grafik
                        final graphWidth = renderBox.size.width - 8 - 30; // Kurangi padding dan y-axis labels
                        final relativeX = (localPosition.dx / graphWidth).clamp(0.0, 1.0);
                        
                        // Cari data point terdekat
                        final now = DateTime.now();
                        final oneHourAgo = now.subtract(const Duration(minutes: 60));
                        final totalDuration = now.difference(oneHourAgo).inMilliseconds;
                        
                        int closestIndex = 0;
                        double minDistance = double.infinity;
                        
                        for (int i = 0; i < timestamps.length; i++) {
                          final timeDiff = timestamps[i].difference(oneHourAgo).inMilliseconds;
                          final pointX = (timeDiff / totalDuration);
                          final distance = (pointX - relativeX).abs();
                          
                          if (distance < minDistance) {
                            minDistance = distance;
                            closestIndex = i;
                          }
                        }
                        
                        if (minDistance < 0.05) { // Toleransi 5% untuk tap
                          _showDataPointPopup(context, data[closestIndex], timestamps[closestIndex]);
                        }
                      }
                    },
                    child: CustomPaint(
                      painter: GraphPainter(
                        minY: widget.minY,
                        maxY: widget.maxY,
                        historicalData: GraphDataStorage.getData(widget.title),
                        timestamps: GraphDataStorage.getTimestamps(widget.title),
                        color: widget.iconColor,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(widget.maxY.toStringAsFixed(0), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(widget.minY.toStringAsFixed(0), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTime(oneHourAgo), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(_formatTime(_currentTime), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final double minY;
  final double maxY;
  final List<double> historicalData;
  final List<DateTime> timestamps;
  final Color color;

  GraphPainter({
    required this.minY,
    required this.maxY,
    required this.historicalData,
    required this.timestamps,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Area below the graph
    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Background grid for easier reading
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;
    
    // Paint untuk titik data dengan ukuran yang lebih besar
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = i * (size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Draw vertical grid lines
    for (int i = 0; i <= 4; i++) {
      final x = i * (size.width / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (historicalData.isEmpty || timestamps.isEmpty) return;

    List<Offset> dataPoints = [];

    // Hitung rentang waktu 5 menit untuk positioning yang akurat
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(minutes: 60));
    final totalDuration = now.difference(oneHourAgo).inMilliseconds;

    // Kumpulkan semua data points yang valid dengan positioning akurat berdasarkan timestamp
    for (int i = 0; i < historicalData.length; i++) {
      final value = historicalData[i];
      final timestamp = timestamps[i];

      if (value > 0.0 && !value.isNaN) {
        // --- PERUBAHAN DIMULAI DI SINI ---
        // Hitung posisi X berdasarkan timestamp relatif dalam rentang 5 menit
        final timeDiff = timestamp.difference(oneHourAgo).inMilliseconds;
        // HAPUS .clamp() agar titik bisa dihitung di luar batas kiri (x < 0)
        final x = (timeDiff / totalDuration) * size.width;
        // --- AKHIR DARI PERUBAHAN ---

        final clampedValue = value.clamp(minY, maxY);
        final yDenominator = (maxY - minY);
        final double y = size.height - ((clampedValue - minY) / yDenominator.clamp(0.1, double.infinity)) * size.height;

        dataPoints.add(Offset(x, y));
      }
    }

    // Gambar garis dan area jika ada data points
    if (dataPoints.isNotEmpty) {
      Path linePath = Path();
      Path fillPath = Path();
      
      // Mulai path untuk garis dan area
      linePath.moveTo(dataPoints[0].dx, dataPoints[0].dy);
      fillPath.moveTo(dataPoints[0].dx, size.height);
      fillPath.lineTo(dataPoints[0].dx, dataPoints[0].dy);

      // Jika hanya ada satu data point, perpanjang garis sampai waktu sekarang
      if (dataPoints.length == 1) {
        final point = dataPoints[0];
        final currentX = size.width; // Garis sampai ujung kanan (waktu sekarang)
        linePath.lineTo(currentX, point.dy);
        fillPath.lineTo(currentX, point.dy);
        fillPath.lineTo(currentX, size.height);
      } else {
        // Gambar garis smooth yang menghubungkan semua points
        for (int i = 1; i < dataPoints.length; i++) {
          final currentPoint = dataPoints[i];
          final prevPoint = dataPoints[i - 1];
          
          // Titik kontrol adalah titik tengah antara titik sebelumnya dan sekarang
          final controlX = (prevPoint.dx + currentPoint.dx) / 2;
          
          // Gambar kurva ke titik saat ini menggunakan titik kontrol
          linePath.quadraticBezierTo(controlX, prevPoint.dy, currentPoint.dx, currentPoint.dy);
          fillPath.quadraticBezierTo(controlX, prevPoint.dy, currentPoint.dx, currentPoint.dy);
        }
        
        // Perpanjang garis dari titik terakhir sampai waktu sekarang (ujung kanan)
        final lastPoint = dataPoints.last;
        final currentX = size.width;
        linePath.lineTo(currentX, lastPoint.dy);
        fillPath.lineTo(currentX, lastPoint.dy);
        fillPath.lineTo(currentX, size.height);
      }
      
      fillPath.close();
      
      // Gambar area fill dan garis
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(linePath, paint);
    }

    // Gambar titik data dengan ukuran yang konsisten dan terlihat jelas
    for (final point in dataPoints) {
      // Gambar titik dengan radius 5 untuk visibilitas yang lebih baik
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(point, 5, pointBorderPaint);
    }

    // Draw axis lines
    final axisPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.historicalData != historicalData ||
        oldDelegate.timestamps != timestamps ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY;
  }
}