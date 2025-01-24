import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'events_page.dart';
import 'login_page.dart';
import 'config_page.dart';

class DetailPage extends StatefulWidget {
  final String idInstance;
  final int type;
  final int id;
  final int idOrganizer;
  const DetailPage(
      {super.key,
      required this.idInstance,
      required this.type,
      required this.id,
      required this.idOrganizer});

  @override
  _DetailPage createState() => _DetailPage();
}

class _DetailPage extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  bool isSearching = false;
  late TabController _tabController;
  int _selectedIndex = 1;
  String searchQuery = "";
  List<Map<String, String>> users = [];
  List<Map<String, String>> filteredUsers = [];
  bool isLoading = true;
  bool hasCacheData = false;

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
            builder: (context) => ConfigPage(idInstance: widget.idInstance, idOrganizer: widget.idOrganizer, ),
          ),
        );
      } else if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MainView(idInstance: widget.idInstance, idOrganizer: widget.idOrganizer)),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();

    _tabController =
        TabController(length: 3, vsync: this, initialIndex: _selectedIndex);

    _tabController.addListener(() {
      _onItemTapped(_tabController.index);
    });
  }

  @override
  void didUpdateWidget(covariant DetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _fetchUsers();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        // Si no hay conexión, obtener los usuarios del caché
        List<Map<String, String>> cachedUsers = await getCachedUsers(widget.id);
        if (cachedUsers.isNotEmpty) {
          setState(() {
            users = cachedUsers;
            filteredUsers = users;
            isLoading = false;
            hasCacheData = true;  // Indicador de que hay datos cacheados
          });
        } else {
          setState(() {
            isLoading = false;
            hasCacheData = false; // No hay datos cacheados
          });
        }
      } else {
        // Si hay conexión, hacer la solicitud HTTP y cachear los usuarios
        final response = await http.get(Uri.parse(
            'https://test.sbxmiaulaempresarial.com/api/get-users/activity/${widget.type}/${widget.id}'));

        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);

          setState(() {
            users = data.map<Map<String, String>>((user) {
              return {
                "name": "${user['first_name']} ${user['last_name']}",
                "email": user['email'],
                "profile_pic": user['profile_pic'] ?? '',
              };
            }).toList();
            filteredUsers = users;
            isLoading = false;
            hasCacheData = true; // Datos obtenidos de la API y cacheados
          });

          // Guardar los usuarios en caché
          await cacheUsers(widget.id, users);
        } else {
          print("Error al obtener usuarios: ${response.statusCode}");
          setState(() {
            isLoading = false;
          });
          throw Exception('Error al obtener usuarios');
        }
      }
    } catch (error) {
      print('Error al obtener los usuarios: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> cacheUsers(int idActivity, List<Map<String, String>> users) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String usersJson = json.encode(users);
    await prefs.setString('cachedUsers_$idActivity', usersJson);
  }

  Future<List<Map<String, String>>> getCachedUsers(int idActivity) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usersJson = prefs.getString('cachedUsers_$idActivity');
    if (usersJson != null) {
      return List<Map<String, String>>.from(json.decode(usersJson));
    }
    return [];
  }

  void _filterUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = users
          .where((user) =>
              user["name"]!.toLowerCase().contains(query.toLowerCase()) ||
              user["email"]!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context);
    return false;
  }

  Widget buildNoUsersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no_users.jpg',
            height: 150,
          ),
          const SizedBox(height: 20),
          Text(
            hasCacheData
                ? 'No se encontraron usuarios registrados en este evento.'
                : widget.type == 2
                    ? 'Aún no hay usuarios registrados en este evento'
                    : 'Aún no hay usuarios registrados en esta actividad',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
            'Check-in: Lista de usuarios',
            style: TextStyle(
              color: Color(0xFF3254FC),
              fontSize: 17,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar usuarios...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                onChanged: (query) => _filterUsers(query),
              ),
            ),
            Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredUsers.isEmpty
                        ? buildNoUsersView()
                        : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              return GFListTile(
                                avatar: GFAvatar(
                                  backgroundImage: filteredUsers[index]
                                                  ["profile_pic"] !=
                                              null &&
                                          filteredUsers[index]["profile_pic"]!
                                              .isNotEmpty
                                      ? NetworkImage(
                                          filteredUsers[index]["profile_pic"]!)
                                      : null,
                                  backgroundColor: Colors.white,
                                  shape: GFAvatarShape.circle,
                                  size: 40,
                                  child: filteredUsers[index]["profile_pic"] ==
                                              null ||
                                          filteredUsers[index]["profile_pic"]!
                                              .isEmpty
                                      ? Image.asset('assets/images/user.png')
                                      : null,
                                ),
                                title: Text(
                                  filteredUsers[index]["name"]!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                subTitle: Text(
                                  filteredUsers[index]["email"]!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              );
                            },
                          )),
          ],
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
      ),
    );
  }
}