import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:vendor_distance_app/models/vendor.dart';
import 'package:vendor_distance_app/widgets/vendor_sheet.dart';

const String APPS_SCRIPT_URL = 'https://script.google.com/macros/s/AKfycbzDApNHkK-OLiXHZTkxl7RcDh_J3frdUuOuXlX-l2iVZt2HMoFXr4KjZ5bJl2lSsu6HuA/exec';

Future<void> main() async {
  runApp(const DistanceApp());
}

class DistanceApp extends StatelessWidget {
  const DistanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Vendor Distance App",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo.shade200),
        useMaterial3: true,
      ),
      home: Scaffold(body: Center(child: const HomePage())),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _userMarker;
  List<Vendor> _vendors = [];
  bool _isLoading = true;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchVendors();
  }

  void _resetVendorDetails() {
    _vendors = _vendors.map((v) => v.copyWith(isNearby: false)).toList();
  }

  Future<void> _showVendorDetails(Vendor vendor) async {
    if (_userMarker == null) return;

    Vendor vendorWithData = vendor;

    if (vendor.distance == null) {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        builder: (context) =>
            const Center(heightFactor: 4, child: CircularProgressIndicator()),
      );

      try {
        final url =
            APPS_SCRIPT_URL +
            '?lat1=${_userMarker!.latitude}&lon1=${_userMarker!.longitude}' +
            '&lat2=${vendor.latitude}&lon2=${vendor.longitude}';

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          vendorWithData = vendor.copyWith(
            distance: data['distance'] as String?,
            duration: data['duration'] as String?,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load locations.'),
            ),
          );
        }
      } finally {
        if (mounted) Navigator.of(context).pop();
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          VendorBottomSheet(vendor: vendorWithData, userMarker: _userMarker!),
    );
  }

  Future<void> _geocodeAddress(String address) async {
    if (address.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isGeocoding = true;
    });

    final url = APPS_SCRIPT_URL;
    final requestBody = jsonEncode({
      'addresses': [address],
    });

    try {
      final response = await http.post(Uri.parse(url), body: requestBody);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coordinates = data[address] as List<dynamic>?;

        if (coordinates != null) {
          final lat = coordinates[0] as double;
          final lon = coordinates[1] as double;
          final newLocation = LatLng(lat, lon);

          setState(() {
            _userMarker = newLocation;
            _resetVendorDetails();
          });

          _mapController.move(_userMarker!, 15.0);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location not found. Please try again.'),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Geocoding Failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occured. Please check your connection.'),
          ),
        );
      }
    } finally {
      setState(() {
        _isGeocoding = false;
      });
    }
  }

  Future<void> _findNearbyVendors() async {
    if (_userMarker == null) return;

    const double searchRadiusKm = 10.0;
    final Distance distance = Distance();

    setState(() {
      _isLoading = true;
    });

    _resetVendorDetails();

    List<Vendor> nearbyVendors = _vendors.where((vendor) {
      final vendorLocation = LatLng(vendor.latitude, vendor.longitude);
      final double km = distance.as(
        LengthUnit.Kilometer,
        _userMarker!,
        vendorLocation,
      );

      return km <= searchRadiusKm;
    }).toList();

    if (nearbyVendors.isEmpty && _vendors.isNotEmpty) {
      List<Map<String, dynamic>> vendorsWithDistances = _vendors.map((vendor) {
        final vendorLocation = LatLng(vendor.latitude, vendor.longitude);
        final double km = distance.as(
          LengthUnit.Kilometer,
          _userMarker!,
          vendorLocation,
        );
        return {"vendor": vendor, "distance": km};
      }).toList();

      vendorsWithDistances.sort(
        (a, b) => a['distance'].compareTo(b['distance']),
      );

      nearbyVendors = vendorsWithDistances
          .take(5)
          .map((e) => e['vendor'] as Vendor)
          .toList();
    }

    final Set<int> vendorsToProcess = nearbyVendors.map((v) => v.id).toSet();
    final updatedVendors = await Future.wait(
      _vendors.map((vendor) async {
        final isNearby = vendorsToProcess.contains(vendor.id);

        if (!isNearby) {
          return vendor.copyWith(
            isNearby: false,
            distance: null,
            duration: null,
          );
        }

        try {
          final url =
              APPS_SCRIPT_URL +
              '?lat1=${_userMarker!.latitude}&lon1=${_userMarker!.longitude}' +
              '&lat2=${vendor.latitude}&lon2=${vendor.longitude}';

          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return vendor.copyWith(
              isNearby: true,
              distance: data['distance'] as String?,
              duration: data['duration'] as String?,
            );
          }
        } catch (e) {
          print('Failed to fetch distance for ${vendor.name}: $e');
        }

        return vendor.copyWith(
          isNearby: isNearby,
          distance: null,
          duration: null,
        );
      }),
    );

    updatedVendors.sort((a, b) {
      if (a.isNearby && !b.isNearby) return -1;
      if (!a.isNearby && b.isNearby) return 1;
      if (!a.isNearby && !b.isNearby) return 0;

      final double distA =
          double.tryParse(a.distance?.split(' ')[0] ?? '0') ?? 0;
      final double distB =
          double.tryParse(b.distance?.split(' ')[0] ?? '0') ?? 0;

      return distA.compareTo(distB);
    });

    setState(() {
      _vendors = updatedVendors;
      _isLoading = false;
    });
  }

  Future<void> _fetchVendors() async {
    final String? url = APPS_SCRIPT_URL;

    if (url == null) {
      print('Could not find the APPS_SCRIPT_URL in .env file');
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _vendors = jsonList
              .map((json) => Vendor.fromJson(json as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print('Failed to load vendors: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userMarker = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_userMarker!, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final nearbyVendors = _vendors.where((v) => v.isNearby).toList();

    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search for a location...",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              border: InputBorder.none,
              suffixIcon: _isGeocoding
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        _geocodeAddress(_searchController.text);
                      },
                    ),
            ),
            onSubmitted: (value) {
              _geocodeAddress(_searchController.text);
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _determinePosition,
              heroTag: 'location_button',
              child: const Icon(Icons.my_location),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              onPressed: _findNearbyVendors,
              heroTag: 'find_button',
              label: const Text('Find Nearby'),
              icon: const Icon(Icons.search),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _userMarker ??
                        const LatLng(
                          17.3850,
                          78.4867,
                        ), // Starting point: Hyderabad
                    initialZoom: 9.2,

                    onLongPress: (tapPosition, latLng) {
                      setState(() {
                        _userMarker = latLng;
                        _resetVendorDetails();
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'User marker moved. Press "Find Nearby" to search from here',
                          ),
                          duration: Duration(seconds: 5),
                        ),
                      );
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.vendor_distance_app',
                    ),
                    if (_userMarker != null)
                      PolylineLayer(
                        polylines: _vendors
                            .where((vendor) => vendor.isNearby)
                            .expand((vendor) {
                              final points = [
                                _userMarker!,
                                LatLng(vendor.latitude, vendor.longitude),
                              ];
                              return [
                                Polyline(
                                  points: points,
                                  strokeWidth: 7.0,
                                  color: Colors.lightGreen.withAlpha(75),
                                ),
                                Polyline(
                                  points: points,
                                  strokeWidth: 3.0,
                                  color: Colors.green.shade700,
                                ),
                              ];
                            })
                            .toList(),
                      ),

                    if (_userMarker != null)
                      MarkerLayer(
                        markers: _vendors
                            .where((v) => v.isNearby && v.distance != null)
                            .map((vendor) {
                              final vendorLocation = LatLng(
                                vendor.latitude,
                                vendor.longitude,
                              );

                              final midPoint = LatLng(
                                (_userMarker!.latitude +
                                        vendorLocation.latitude) /
                                    2,
                                (_userMarker!.longitude +
                                        vendorLocation.longitude) /
                                    2,
                              );

                              return Marker(
                                point: midPoint,
                                width: 120,
                                height: 50,
                                child: _DistanceLabel(vendor: vendor),
                              );
                            })
                            .toList(),
                      ),
                    MarkerLayer(
                      markers: _vendors.map((vendor) {
                        return Marker(
                          point: LatLng(vendor.latitude, vendor.longitude),
                          width: 300,
                          height: 100,
                          child: _VendorMarker(
                            vendor: vendor,
                            onTap: () => _showVendorDetails(vendor),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_userMarker != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userMarker!,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.person_pin_circle,
                              size: 60,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
          if (nearbyVendors.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: nearbyVendors.length,
                  itemBuilder: (context, index) {
                    final vendor = nearbyVendors[index];
                    return SizedBox(
                      width: 300,
                      child: _VendorListCard(
                        vendor: vendor,
                        onTap: () {
                          final location = LatLng(
                            vendor.latitude,
                            vendor.longitude,
                          );
                          _mapController.move(location, 16.0);
                          _showVendorDetails(vendor);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VendorMarker extends StatelessWidget {
  const _VendorMarker({required this.vendor, required this.onTap});

  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              vendor.name,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 5),
          Icon(
            Icons.location_pin,
            size: vendor.isNearby ? 50 : 40,
            color: vendor.isNearby
                ? Colors.green.shade700
                : Colors.red.shade700,
          ),
        ],
      ),
    );
  }
}

class _DistanceLabel extends StatelessWidget {
  const _DistanceLabel({required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            vendor.distance!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(vendor.duration!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _VendorListCard extends StatelessWidget {
  const _VendorListCard({required this.vendor, required this.onTap});
  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendor.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vendor.distance ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    vendor.duration ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
