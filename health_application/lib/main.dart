import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:molitav/pages/home.dart';
import 'package:molitav/pages/setting.dart';
import 'package:molitav/pages/data.dart';
import 'package:provider/provider.dart';
import 'connection/bluetooth.dart';

void main() => runApp(const HealthApp());

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
      ],
      child: const MaterialApp(
        home: MainPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo/LogoMolitavBackground.png',
              fit: BoxFit.contain,
              height: 95,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: const Text('MOLITAV'),
            )
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 30, 110, 176),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 26),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.28),
            blurRadius: 10.0,
            offset: const Offset(0.0, 0.0),
          )
        ]),
        child: NavigationBar(
          backgroundColor: const Color.fromARGB(255, 226, 242, 255),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: currentPageIndex,
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Colors.transparent,
          destinations: <Widget>[
            NavigationDestination(
              selectedIcon: SvgPicture.asset(
                'assets/icons/dashboard.svg',
                width: 40,
                height: 40,
              ),
              icon: SvgPicture.asset(
                'assets/icons/dashboard_outline.svg',
                width: 40,
                height: 40,
              ),
              label: 'Dashboard',
            ),

            NavigationDestination(
              selectedIcon: SvgPicture.asset(
                'assets/icons/data-record.svg',
                width: 50,
                height: 50,
              ),
              icon: SvgPicture.asset(
                'assets/icons/data-record_outline.svg',
                width: 50,
                height: 50,
              ),
              label: 'Data Record',
            ),

            NavigationDestination(
              selectedIcon: SvgPicture.asset(
                'assets/icons/device.svg',
                width: 40,
                height: 40,
              ),
              icon: SvgPicture.asset(
                'assets/icons/device_outline.svg',
                width: 40,
                height: 40,
              ),
              label: 'Device',
            ),
          ],
        ),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    switch (currentPageIndex) {
      case 0:
        return const Homepage();
      case 1:
        return const DataPage();
      case 2:
        return const SettingsPage();
      default:
        return const Homepage();
    }
  }
}
