import 'package:aulas_checkin/config_page.dart';
import 'package:aulas_checkin/detail_page.dart';
import 'package:aulas_checkin/events_page.dart';
import 'package:aulas_checkin/login_page.dart';
import 'package:aulas_checkin/scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ActivitiesPage extends StatefulWidget {
  final String idInstance;
  final int idEvent;
  final int idOrganizer;
  const ActivitiesPage(
      {super.key,
      required this.idInstance,
      required this.idEvent,
      required this.idOrganizer});

  @override
  _ActivitiesPage createState() => _ActivitiesPage();
}

class _ActivitiesPage extends State<ActivitiesPage>
    with SingleTickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSearching = false;
  List<dynamic> filteredActivities = [];
  late TabController _tabController;
  int _selectedIndex = 1;
  late Stream<List<dynamic>> activitiesStream;
  List<dynamic> activities = [];
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0.0;

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
              idInstance: widget.idInstance,
              idOrganizer: widget.idOrganizer,
            ),
          ),
        );
      } else if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MainView(
                    idInstance: widget.idInstance,
                    idOrganizer: widget.idOrganizer,
                  )),
        );
      }
    }
  }

  void filterActivities() {
    setState(() {
      final query = searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        filteredActivities = activities.where((activity) {
          final activityName = activity['name']?.toLowerCase() ?? '';
          return activityName.contains(query);
        }).toList();
      } else {
        filteredActivities = activities;
      }
    });
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Sin fecha';
    }

    try {
      DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.day} ${_getMonth(parsedDate.month)}';
    } catch (e) {
      return 'Sin fecha';
    }
  }

  String _getMonth(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];
    return months[month - 1];
  }

  @override
  void initState() {
    super.initState();
    activitiesStream = fetchActivitiesStream(widget.idEvent);
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: _selectedIndex);

    _scrollController.addListener(() {
      _scrollPosition = _scrollController.position.pixels;
    });

    _tabController.addListener(() {
      _onItemTapped(_tabController.index);
    });

    searchController.addListener(() {
      filterActivities();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollPosition > 0.0) {
        _scrollController.jumpTo(_scrollPosition);
      }
    });
  }

  Future<void> cacheActivities(int idEvent, List<dynamic> activities) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String activitiesJson = json.encode(activities);
    await prefs.setString('cachedActivities_$idEvent', activitiesJson);
  }

  Future<List<dynamic>> getCachedActivities(int idEvent) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? activitiesJson = prefs.getString('cachedActivities_$idEvent');
    if (activitiesJson != null) {
      return json.decode(activitiesJson);
    }
    return [];
  }

  Stream<List<dynamic>> fetchActivitiesStream(int idEvent) async* {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      List<dynamic> cachedActivities = await getCachedActivities(idEvent);
      if (cachedActivities.isNotEmpty) {
        activities = cachedActivities;
        filteredActivities = activities;
        yield activities;
      } else {
        yield [];
      }
    } else {
      try {
        final response = await http.get(
          Uri.parse(
              'https://test.sbxmiaulaempresarial.com/api/get-activities/$idEvent'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> newData = data['activities'];

          if (newData != activities) {
            activities = newData;
            filteredActivities = activities;
            await cacheActivities(idEvent, activities);
            yield activities;
          }
        } else {
          List<dynamic> cachedActivities = await getCachedActivities(idEvent);
          if (cachedActivities.isNotEmpty) {
            activities = cachedActivities;
            filteredActivities = activities;
            yield activities;
          } else {
            throw Exception('Failed to load activities');
          }
        }
      } catch (e) {
        List<dynamic> cachedActivities = await getCachedActivities(idEvent);
        if (cachedActivities.isNotEmpty) {
          activities = cachedActivities;
          filteredActivities = activities;
          yield activities;
        } else {
          yield [];
        }
      }
    }
  }

  String _shortenEventName(String name) {
    if (name.length > 20) {
      return '${name.substring(0, 20)}...';
    } else {
      return name;
    }
  }

  Widget buildActivityCard(dynamic activity) {
    return FutureBuilder(
        future: Connectivity().checkConnectivity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            String imageUrl;
            if (snapshot.data == ConnectivityResult.none) {
              imageUrl = 'assets/images/no_images.png';
            } else {
              imageUrl = activity['featured_img'] ??
                  'https://ceroa.iconofact.com/logo/imagen-no-disponible.jpg';
            }
            return GFCard(
              boxFit: BoxFit.cover,
              showImage: true,
              color: Colors.white,
              elevation: 8.0,
              content: Column(
                children: [
                  imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: MediaQuery.of(context).size.height * 0.2,
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Image.asset('assets/images/no_images.png'),
                        )
                      : Image.asset(
                          imageUrl,
                          height: MediaQuery.of(context).size.height * 0.2,
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.cover,
                        ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.grey,
                              size: 12.0,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatDate(
                                  activity['start_time'] ?? 'Sin  fecha'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(
                                  idInstance: widget.idInstance,
                                  idOrganizer: widget.idOrganizer,
                                  type: 3,
                                  id: activity['idActivity'],
                                ),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Icon(
                                Icons.remove_red_eye,
                                color: Colors.blue,
                                size: 12.0,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Ver detalle',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Row(
                      children: [
                        Text(
                          _shortenEventName(
                              activity['name'] ?? 'Nombre no disponible'),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRScannerPage(
                              idInstance: widget.idInstance,
                              eventName: activity['name'],
                              idActivity: activity['idActivity'],
                              fromActivities: 2,
                              idEvent: widget.idEvent,
                              idActivity_type_event: 0,
                              idOrganizer: widget.idOrganizer,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 8.0,
                        backgroundColor: const Color(0xFF3355FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                      ),
                      child: const Text(
                        'Check-in',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 250,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRScannerPage(
                              idInstance: widget.idInstance,
                              eventName: activity['name'],
                              idActivity: activity['idActivity'],
                              fromActivities: 2,
                              idEvent: widget.idEvent,
                              idActivity_type_event: 0,
                              idOrganizer: widget.idOrganizer,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFA2ADB5),
                          width: 2.0,
                        ),
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFFA2ADB5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                      ),
                      child: const Text(
                        'Check-out',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Widget buildNoActivitiesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/no_activities.png',
            height: 150,
          ),
          const SizedBox(height: 20),
          const Text(
            'No se han encontrado actividades en este evento',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Espere a que el organizador agregue las actividades del evento',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchFocusNode.dispose();
    searchController.dispose();
    super.dispose();
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
        title: Row(
          children: [
            if (isSearching)
              Expanded(
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Nombre de la actividad',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              )
            else
              const Expanded(
                child: Text(
                  'Check-in: Actividades',
                  style: TextStyle(
                    color: Color(0xFF3254FC),
                    fontSize: 17,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.search),
              color: Colors.grey,
              onPressed: () {
                setState(() {
                  isSearching = true;
                  searchFocusNode.requestFocus();
                });
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: activitiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return buildNoActivitiesView();
          } else {
            return ListView.builder(
              controller: _scrollController,
              itemCount: filteredActivities.length,
              itemBuilder: (context, index) {
                final activity = filteredActivities[index];
                return buildActivityCard(activity);
              },
            );
          }
        },
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
