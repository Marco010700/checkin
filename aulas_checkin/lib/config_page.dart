import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'events_page.dart';
import 'login_page.dart';

class ConfigPage extends StatefulWidget {
  final String idInstance;
  final int idOrganizer;
  const ConfigPage(
      {super.key, required this.idInstance, required this.idOrganizer});

  @override
  _ConfigPage createState() => _ConfigPage();
}

class _ConfigPage extends State<ConfigPage>
    with SingleTickerProviderStateMixin {
  bool isSearching = false;
  late TabController _tabController;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> pendingCheckIns = [];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: _selectedIndex);
    _tabController.addListener(() {
      _onItemTapped(_tabController.index);
    });
    loadPendingCheckIns();
  }

  Future<void> loadPendingCheckIns() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pendingCheckInsJson =
        prefs.getStringList('pendingCheckIns') ?? [];
    setState(() {
      pendingCheckIns = pendingCheckInsJson
          .map((e) => Map<String, dynamic>.from(json.decode(e)))
          .toList();
    });
  }

  Future<void> syncCheckIns() async {
    await loadPendingCheckIns();
    if (pendingCheckIns.isNotEmpty) {
      List<String> successfulCheckIns = [];

      for (var checkIn in pendingCheckIns) {
        Map<String, dynamic> body;

        if (checkIn['idActivity_type_event'] != null &&
            checkIn['idActivity_type_event'] != 0) {
          body = {
            'userIds': [checkIn['idUser']],
            'idActivity_type_event': checkIn['idActivity_type_event'],
            'idOrganizer': widget.idOrganizer,
          };
        } else {
          body = {
            'userIds': [checkIn['idUser']],
            'idEvent': checkIn['idEvent'] ?? 0,
            'idActivity': checkIn['idActivity'] ?? 0,
            'idOrganizer': widget.idOrganizer,
          };
        }

        final response = await http.post(
          Uri.parse(
              'https://test.sbxmiaulaempresarial.com/api/multiple-check-in'),
          body: json.encode(body),
          headers: {'Content-Type': 'application/json'},
        );

        print("Response status code: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['status']) {
            successfulCheckIns.add(json.encode(checkIn));
          } else {
            print(
                "Check-in failed: ${responseData['message'] ?? 'Unknown error'}");
          }
        } else {
          print("Server error: ${response.statusCode}");
        }
      }

      if (successfulCheckIns.isNotEmpty) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        pendingCheckIns.removeWhere(
            (checkIn) => successfulCheckIns.contains(json.encode(checkIn)));
        await prefs.setStringList('pendingCheckIns',
            pendingCheckIns.map((e) => json.encode(e)).toList());
      }

      setState(() {});
    }
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPage(idInstance: widget.idInstance)),
        (Route<dynamic> route) => false,
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfigPage(
                idInstance: widget.idInstance, idOrganizer: widget.idOrganizer),
          ),
        );
      } else if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MainView(
                  idInstance: widget.idInstance,
                  idOrganizer: widget.idOrganizer,
                  shouldRefreshDetail: true,)),
                  
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => MainView(
              idInstance: widget.idInstance, idOrganizer: widget.idOrganizer, shouldRefreshDetail: true,)),
      (Route<dynamic> route) => false,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Configuración",
          style: TextStyle(
            color: Color(0xFF3254FC),
            fontSize: 17,
            fontFamily: 'Roboto',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () async {
              await syncCheckIns();
              // Refresh the UI
              setState(() {});
            },
          ),
        ],
      ),
      body: pendingCheckIns.isNotEmpty
          ? ListView.builder(
              itemCount: pendingCheckIns.length,
              itemBuilder: (context, index) {
                final checkIn = pendingCheckIns[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/images/MiAulaEmpresarial.png'),
                  ),
                  title: Text(checkIn['userName'] ?? 'Usuario'),
                  subtitle: Text(checkIn['eventName'] ?? 'Evento/Actividad'),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/MiAulaEmpresarial.png',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No hay check-ins pendientes.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: GFTabBar(
          controller: _tabController,
          length: 3,
          tabBarColor: Colors.white,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              icon: Icon(Icons.access_time),
            ),
            Tab(
              icon: Icon(Icons.home),
            ),
            Tab(
              icon: Icon(Icons.logout),
            ),
          ],
        ),
      ),
    );
  }
}
