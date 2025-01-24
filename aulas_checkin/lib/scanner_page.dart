import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'checkin_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class QRScannerPage extends StatefulWidget {
  final String idInstance;
  final String eventName;
  final int idActivity_type_event;
  final int idEvent;
  final int idActivity;
  final int idOrganizer;
  final int fromActivities;
  const QRScannerPage(
      {super.key,
      required this.idInstance,
      required this.eventName,
      required this.idActivity_type_event,
      required this.idEvent,
      required this.idActivity,
      required this.fromActivities,
      required this.idOrganizer});

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String scanResult = "No se ha escaneado ningún código";
  List<Map<String, dynamic>> pendingCheckIns = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scanQRCode();
    });
  }

  Future<void> scanQRCode() async {
    try {
      var result = await BarcodeScanner.scan();

      if (result.rawContent.isNotEmpty) {
        final qrData = json.decode(result.rawContent);
        if (qrData.containsKey('idUser') &&
            qrData['idUser'] is String &&
            qrData.containsKey('first_name') &&
            qrData['first_name'] is String &&
            qrData.containsKey('last_name') &&
            qrData['last_name'] is String &&
            qrData.containsKey('email') &&
            qrData['email'] is String) {
          String formattedEmail =
              qrData['email'].replaceAll('[]', '@').replaceAll(',', '.');
          String userName = "${qrData['first_name']} ${qrData['last_name']}";

          if (widget.fromActivities == 1) {
            await performCheckIn(
                qrData['idUser'] ?? '0', widget.idOrganizer, 0, userName);
          } else if (widget.fromActivities == 2) {
            await performCheckIn(
                qrData['idUser'] ?? '0', widget.idOrganizer, 0, userName);
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckInSuccessPage(
                idInstance: widget.idInstance,
                idOrganizer: widget.idOrganizer,
                userName: userName,
                userEmail: formattedEmail,
                eventName: widget.eventName,
                id: widget.fromActivities == 1
                    ? widget.idActivity_type_event
                    : widget.idEvent,
                fromActivities: widget.fromActivities,
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Código QR no válido'),
                content: const Text('Por favor escanea un QR válido.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cerrar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        setState(() {
          showErrorView('No se detectó ningún código QR');
        });
      }
    } catch (e) {
      setState(() {
        showErrorView(
            'UPS, ocurrió un problema con el escaneo, por favor intentalo más tarde');
      });
    }
  }

  void showErrorView(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Image.asset('assets/images/error.png'),
                ),
                const SizedBox(height: 20),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> performCheckIn(
      String idUser, int id, int idOrganizer, String userName) async {
    Map<String, dynamic>? body;

    if (widget.fromActivities == 1) {
      body = {
        'userIds': [idUser],
        'idActivity_type_event': widget.idActivity_type_event,
        'idOrganizer': widget.idOrganizer,
      };
    } else if (widget.fromActivities == 2) {
      body = {
        'userIds': [idUser],
        'idEvent': widget.idEvent,
        'idActivity': widget.idActivity,
        'idOrganizer': widget.idOrganizer,
      };
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://test.sbxmiaulaempresarial.com/api/multiple-check-in'),
        body: json.encode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (!responseData['status']) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error en el Check-in'),
                content: const Text('Hubo un error al realizar el check-in.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cerrar'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error del Servidor'),
              content: const Text('No se pudo realizar el check-in.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cerrar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      await cachePendingCheckIn(body!, userName, widget.eventName);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Check-in en espera'),
            content: const Text(
                'No hay conexión a internet. El check-in se guardará y se enviará cuando haya conexión.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> cachePendingCheckIn(Map<String, dynamic> checkInData,
      String userName, String eventName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pendingCheckIns = prefs.getStringList('pendingCheckIns') ?? [];

    checkInData['userName'] = userName;
    checkInData['eventName'] = eventName;

    checkInData['userIds'] = [checkInData['idUser']];

    pendingCheckIns.add(json.encode(checkInData));
    await prefs.setStringList('pendingCheckIns', pendingCheckIns);
  }

  Future<List<Map<String, dynamic>>> getPendingCheckIns() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pendingCheckInsJson =
        prefs.getStringList('pendingCheckIns') ?? [];
    return pendingCheckInsJson
        .map((e) => Map<String, dynamic>.from(json.decode(e)))
        .toList();
  }

  Future<void> syncPendingCheckIns() async {
    List<Map<String, dynamic>> pendingCheckIns = await getPendingCheckIns();
    if (pendingCheckIns.isNotEmpty) {
      for (var checkIn in pendingCheckIns) {
        final response = await http.post(
          Uri.parse(
              'https://test.sbxmiaulaempresarial.com/api/multiple-check-in'),
          body: json.encode(checkIn),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['status']) {
            pendingCheckIns.remove(checkIn);
          }
        }
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> updatedCheckIns =
          pendingCheckIns.map((e) => json.encode(e)).toList();
      await prefs.setStringList('pendingCheckIns', updatedCheckIns);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "Primeros pasos del aula",
            style: TextStyle(
              color: Color(0xFF3254FC),
              fontSize: 17,
              fontFamily: 'Roboto',
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Escaneando QR',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Image.asset(
                      'assets/images/qr_placeholder.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: FloatingActionButton(
                      onPressed: scanQRCode,
                      backgroundColor: const Color.fromARGB(255, 28, 90, 224),
                      elevation: 8.0,
                      shape: const CircleBorder(),
                      child: const Icon(
                        Icons.search,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
