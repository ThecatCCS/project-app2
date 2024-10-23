import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class ReceiveOrderPage extends StatefulWidget {
  final String orderId;
  ReceiveOrderPage({required this.orderId});

  @override
  _ReceiveOrderPageState createState() => _ReceiveOrderPageState();
}

class _ReceiveOrderPageState extends State<ReceiveOrderPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String currentStatus = 'กำลังไปรับอาหาร'; // เริ่มจากสถานะนี้
  Position? riderPosition;
  LatLng? restaurantLocation;
  LatLng? customerLocation;
  late StreamSubscription<Position> positionStream;

  @override
  void initState() {
    super.initState();
    _startListeningToLocation(); // เริ่มการอัปเดตตำแหน่งแบบเรียลไทม์
    _fetchOrderDetails(); // รับรายละเอียดออเดอร์ เช่น ตำแหน่งร้านและลูกค้า
  }

  @override
  void dispose() {
    // ยกเลิกการสตรีมตำแหน่งเมื่อไม่ใช้งาน
    positionStream.cancel();
    super.dispose();
  }

  // ฟังก์ชันเริ่มสตรีมตำแหน่งไรเดอร์แบบเรียลไทม์
  void _startListeningToLocation() {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // อัปเดตเมื่อมีการเปลี่ยนแปลงตำแหน่งมากกว่า 10 เมตร
    );

    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      setState(() {
        riderPosition = position; // อัปเดตตำแหน่งใน UI
      });
      _updateRiderLocation(position); // อัปเดตตำแหน่งใน Firebase
    });
  }

  // อัปเดตตำแหน่งไรเดอร์ใน Firebase
  void _updateRiderLocation(Position position) async {
    await _database.child('orders/${widget.orderId}').update({
      'riderLocation': {'latitude': position.latitude, 'longitude': position.longitude},
    });
  }

  // ดึงข้อมูลตำแหน่งของร้านอาหารและลูกค้าจาก Firebase
  Future<void> _fetchOrderDetails() async {
    final snapshot = await _database.child('orders/${widget.orderId}').get();
    if (snapshot.exists) {
      final orderData = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        restaurantLocation = _parseLatLng(orderData['sellerLocation']);
        customerLocation = _parseLatLng(orderData['buyerLocation']);
      });
    }
  }

  // ฟังก์ชันแปลงตำแหน่งจาก Firebase เป็น LatLng
  LatLng _parseLatLng(dynamic locationData) {
    if (locationData is String) {
      final parts = locationData.replaceAll(RegExp(r'[^\d.,-]'), '').split(',');
      final latitude = double.parse(parts[0]);
      final longitude = double.parse(parts[1]);
      return LatLng(latitude, longitude);
    } else if (locationData is Map) {
      return LatLng(
        locationData['latitude'] ?? 0.0,
        locationData['longitude'] ?? 0.0,
      );
    } else {
      return LatLng(0.0, 0.0); // Default fallback
    }
  }

  // ฟังก์ชันยกเลิกออเดอร์
  void _cancelOrder() async {
    await _database.child('orders/${widget.orderId}').update({
      'status': 'รอไรเดอร์รับงาน',
      'riderPhone': null,
      'riderName': null,
    });
    Navigator.pop(context); // กลับไปหน้ารายการออเดอร์
  }

  // ฟังก์ชันเปลี่ยนสถานะและตำแหน่ง
  void _changeOrderStatus() async {
    String newStatus;
    if (currentStatus == 'กำลังไปรับอาหาร') {
      newStatus = 'ไรเดอร์กำลังจัดส่ง';
      // เปลี่ยนไปยังตำแหน่งของลูกค้าเมื่อสถานะเป็น "กำลังจัดส่ง"
      setState(() {
        currentStatus = newStatus;
        _updateRiderLocation(riderPosition!); // อัปเดตตำแหน่งไรเดอร์แบบเรียลไทม์
      });
    } else if (currentStatus == 'ไรเดอร์กำลังจัดส่ง') {
      newStatus = 'จัดส่งสำเร็จ';
      Navigator.pop(context); // เมื่อจัดส่งสำเร็จ กลับไปหน้ารายการออเดอร์
    } else {
      return;
    }

    await _database.child('orders/${widget.orderId}').update({
      'status': newStatus,
    });

    setState(() {
      currentStatus = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการออเดอร์'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // แสดงตำแหน่งร้านอาหารหรือลูกค้าตามสถานะ
          Expanded(
            child: restaurantLocation == null || riderPosition == null
                ? Center(child: CircularProgressIndicator())
                : FlutterMap(
                    options: MapOptions(
                      center: currentStatus == 'กำลังไปรับอาหาร'
                          ? restaurantLocation
                          : customerLocation,
                      zoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: currentStatus == 'กำลังไปรับอาหาร'
                                ? restaurantLocation!
                                : customerLocation!,
                            builder: (ctx) => Icon(Icons.location_pin,
                                color: Colors.red, size: 40),
                          ),
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(
                              riderPosition!.latitude,
                              riderPosition!.longitude,
                            ),
                            builder: (ctx) => Icon(Icons.location_pin,
                                color: Colors.blue, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // ข้อมูลผู้ส่งและผู้รับ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    CircleAvatar(radius: 30, child: Icon(Icons.person)),
                    SizedBox(height: 8),
                    Text('ร้านอาหาร'),
                  ],
                ),
                Icon(Icons.arrow_forward),
                Column(
                  children: [
                    CircleAvatar(radius: 30, child: Icon(Icons.person)),
                    SizedBox(height: 8),
                    Text('ลูกค้า'),
                  ],
                ),
              ],
            ),
          ),
          // สถานะและปุ่มการจัดการ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('สถานะ: $currentStatus', style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _cancelOrder,
                      child: Text('ยกเลิกออร์เดอร์'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: _changeOrderStatus,
                      child: Text('เปลี่ยนสถานะ'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
