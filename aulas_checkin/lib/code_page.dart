import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class AulaPage extends StatefulWidget {
  const AulaPage({super.key});

  @override
  _AulaPageState createState() => _AulaPageState();
}

class _AulaPageState extends State<AulaPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String token = _codeController.text.trim();
    final String url =
        'https://test.sbxmiaulaempresarial.com/api/check-token/$token';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true) {
          final String idInstance = data['instance']['idInstance'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(idInstance: idInstance),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Código inválido. Intenta de nuevo.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error en el servidor. Intenta más tarde.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error en la conexión. Revisa tu internet.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _onCodeChanged(String value) {
    setState(() {
      _isButtonEnabled = value.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/Logo_MiAula_Checkin.png',
                height: 130,
              ),
              const SizedBox(height: 20),
              const Text(
                'Código del Aula',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Introduce el código para poder ingresar al aula',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Código',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                  ),
                  onChanged: _onCodeChanged,
                ),
              ),
              const SizedBox(height: 30),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed:
                      _isButtonEnabled && !_isLoading ? _verifyCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3355FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Enviar',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
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
    );
  }
}
