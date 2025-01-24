import 'package:aulas_checkin/config_page.dart';
import 'package:aulas_checkin/login_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'scanner_page.dart';
import 'detail_page.dart';
import 'activities_page.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dart:async';

class MainView extends StatefulWidget {
  final String idInstance;
  final int idOrganizer;
  final bool shouldRefreshDetail;

  const MainView({
    super.key,
    required this.idInstance,
    required this.idOrganizer,
    this.shouldRefreshDetail = false,
  });

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Stream<List<dynamic>> eventsStream;
  bool isSearching = false;
  List<dynamic> allEvents = [];
  List<dynamic> filteredEvents = [];
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  late TabController _tabController;
  int _selectedIndex = 1;
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0.0;
  Timer? _inactivityTimer;
  final int inactivityDuration = 30 * 60;

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
                  )),
        );
      }
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer =
        Timer(Duration(seconds: inactivityDuration), _handleInactivity);
  }

  void _handleInactivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => LoginPage(idInstance: widget.idInstance)),
      (Route<dynamic> route) => false,
    );
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

  String _shortenEventName(String name) {
    if (name.length > 20) {
      return '${name.substring(0, 20)}...';
    } else {
      return name;
    }
  }

  Widget buildUniqueActivityCard(dynamic event) {
    return FutureBuilder(
        future: Connectivity().checkConnectivity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            String imageUrl;
            if (snapshot.data == ConnectivityResult.none) {
              imageUrl = 'assets/images/no_images.png';
            } else {
              imageUrl = event['featured_img'] ??
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
                              _formatDate(event['start_date'] ?? 'Sin  fecha'),
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
                                  type: 2,
                                  id: event['idActivity_type_event'],
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
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 12.0,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event['totalUsers'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
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
                              event['name'] ?? 'Nombre no disponible'),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ' (${event['typeEvent'] ?? 'No especificado'})',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            fontSize: 9,
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
                              eventName: event['name'],
                              idActivity_type_event:
                                  event['idActivity_type_event'],
                              idOrganizer: widget.idOrganizer,
                              fromActivities: 1,
                              idActivity: 0,
                              idEvent: 0,
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
                              eventName: event['name'],
                              idActivity_type_event:
                                  event['idActivity_type_event'],
                              fromActivities: 1,
                              idOrganizer: widget.idOrganizer,
                              idActivity: 0,
                              idEvent: 0,
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

  Widget buildMultiActivityCard(dynamic event) {
    return FutureBuilder(
        future: Connectivity().checkConnectivity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            String imageUrl;
            if (snapshot.data == ConnectivityResult.none) {
              imageUrl = 'assets/images/no_images.png';
            } else {
              imageUrl = event['featured_img'] ??
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
                              _formatDate(event['start_date'] ?? 'Sin fecha'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 12.0,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event['totalUsers'] ?? 0}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
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
                              event['name'] ?? 'Nombre no disponible'),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ' (${event['typeEvent'] ?? 'No especificado'})',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            fontSize: 9,
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
                            builder: (context) => ActivitiesPage(
                                idInstance: widget.idInstance,
                                idEvent: event['idEvent'],
                                idOrganizer: widget.idOrganizer),
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
                        'Ver actividades',
                        style: TextStyle(
                          fontSize: 16,
                        ),
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

  Future<void> cacheEvents(List<dynamic> events) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String eventsJson = json.encode(events);
    await prefs.setString('cachedEvents', eventsJson);
  }

  Future<List<dynamic>> getCachedEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? eventsJson = prefs.getString('cachedEvents');
    if (eventsJson != null) {
      return json.decode(eventsJson);
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    eventsStream = fetchEventsStream(widget.idInstance);
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: _selectedIndex);

    _tabController.addListener(() {
      _onItemTapped(_tabController.index);
    });

    _scrollController.addListener(() {
      _scrollPosition = _scrollController.position.pixels;

      _resetInactivityTimer();
    });

    searchController.addListener(() {
      filterEvents();
    });

    if (widget.shouldRefreshDetail) {
      _fetchEventsAndDetails();
    }

    _resetInactivityTimer();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _fetchEventsAndDetails() async {
    setState(() {
      eventsStream = fetchEventsStream(widget.idInstance);
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _scrollController.removeListener(_resetInactivityTimer);
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetInactivityTimer();
    }
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

  Stream<List<dynamic>> fetchEventsStream(String idInstance) async* {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      List<dynamic> cachedEvents = await getCachedEvents();
      if (cachedEvents.isNotEmpty) {
        allEvents = cachedEvents;
        filteredEvents = allEvents;
        yield allEvents;
      } else {
        yield [];
      }
    } else {
      try {
        final response = await http.get(
          Uri.parse(
              'https://test.sbxmiaulaempresarial.com/api/get-events/$idInstance'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> newData = data['allEvents'];

          if (newData != allEvents) {
            allEvents = newData;
            filteredEvents = allEvents;
            await cacheEvents(allEvents);
            yield allEvents;
          }
        } else {
          List<dynamic> cachedEvents = await getCachedEvents();
          if (cachedEvents.isNotEmpty) {
            allEvents = cachedEvents;
            filteredEvents = allEvents;
            yield allEvents;
          } else {
            throw Exception('Failed to load events');
          }
        }
      } catch (e) {
        List<dynamic> cachedEvents = await getCachedEvents();
        if (cachedEvents.isNotEmpty) {
          allEvents = cachedEvents;
          filteredEvents = allEvents;
          yield allEvents;
        } else {
          yield [];
        }
      }
    }
  }

  void filterEvents() {
    setState(() {
      final query = searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        filteredEvents = allEvents.where((event) {
          final eventName = event['name']?.toLowerCase() ?? '';
          return eventName.contains(query);
        }).toList();
      } else {
        filteredEvents = allEvents;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) => _resetInactivityTimer(),
      onTap: () {
        _resetInactivityTimer();
        if (isSearching) {
          setState(() {
            isSearching = false;
            searchController.clear();
            searchFocusNode.unfocus();
          });
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          title: Row(
            children: [
              if (isSearching)
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Nombre del evento',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                )
              else
                const Expanded(
                  child: Text(
                    'Check-in Eventos',
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
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<dynamic>>(
                stream: eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No events available.'));
                  } else {
                    final eventsToDisplay = filteredEvents;

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: eventsToDisplay.length,
                      itemBuilder: (context, index) {
                        final event = eventsToDisplay[index];
                        if (event['isActivity'] == true) {
                          return buildUniqueActivityCard(event);
                        } else {
                          return buildMultiActivityCard(event);
                        }
                      },
                    );
                  }
                },
              ),
            ),
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
