import 'package:flutter/material.dart';
import 'events_page.dart';

class CheckOutSuccessPage extends StatefulWidget {
  final String idInstance;
  final int idOrganizer;
  const CheckOutSuccessPage({super.key, required this.idInstance, required this.idOrganizer});

  @override
  _CheckOutSuccessPage createState() => _CheckOutSuccessPage();
}

class _CheckOutSuccessPage extends State<CheckOutSuccessPage>
    with SingleTickerProviderStateMixin {
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
  }


  Future<bool> _onWillPop() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => MainView(idInstance: widget.idInstance, idOrganizer: widget.idOrganizer)),
      (Route<dynamic> route) => false,
    );
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
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => MainView(idInstance: widget.idInstance, idOrganizer: widget.idOrganizer),
                ),
                (Route<dynamic> route) => false,
              );
            },
          ),
          title: const Text(
            'Nombre del Evento',
            style: TextStyle(
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
                      'Check out Exitoso',
                      style: TextStyle(
                        color: Color(0xFF1A67E2),
                        fontSize: 30,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Marco Antonio Alviter Rodríguez',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'malviter@tdminternacional.com',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Nombre de la actividad',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'Powered by Mi Aula Empresarial © 2023',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                    fontSize: 8,
                  ),
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
