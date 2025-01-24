import 'package:aulas_checkin/activities_page.dart';
import 'package:flutter/material.dart';

import 'events_page.dart';

class CheckInSuccessPage extends StatefulWidget {
  final String idInstance;
  final String userName;
  final String userEmail;
  final String eventName;
  final int idOrganizer;
  final int id;
  final fromActivities;
  const CheckInSuccessPage(
      {super.key,
      required this.idInstance,
      required this.eventName,
      required this.userEmail,
      required this.userName,
      required this.id,
      required this.fromActivities,
      required this.idOrganizer});

  @override
  _CheckInSuccessPage createState() => _CheckInSuccessPage();
}

class _CheckInSuccessPage extends State<CheckInSuccessPage>
    with SingleTickerProviderStateMixin {
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _onWillPop() async {
    if (widget.fromActivities == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainView(
            idInstance: widget.idInstance,
            idOrganizer: widget.idOrganizer,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } else if (widget.fromActivities == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => ActivitiesPage(
            idInstance: widget.idInstance,
            idEvent: widget.id,
            idOrganizer: widget.idOrganizer,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _onWillPop,
          ),
          title: Text(
            widget.eventName,
            style: const TextStyle(
              color: Color(0xFF3254FC),
              fontSize: 17,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/gifs/checkMark.gif',
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Error al cargar el GIF');
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check Reliazado de Forma Exitosa',
                      style: TextStyle(
                        color: Color(0xFF1A67E2),
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.userEmail,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.eventName,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 31, 60, 206),
                            ),
                            child: const Text(
                              "Seguir escaneando",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainView(
                                      idInstance: widget.idInstance,
                                      idOrganizer: widget.idOrganizer),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                            ),
                            child: const Text(
                              "Regresar al inicio",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Powered by Mi Aula Empresarial © 2023',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
