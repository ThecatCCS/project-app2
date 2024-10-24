import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart'; // For Firebase Database

class OrderChatPage extends StatefulWidget {
  final String orderId; // Order ID to track the order details
  const OrderChatPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderChatPageState createState() => _OrderChatPageState();
}

class _OrderChatPageState extends State<OrderChatPage> {
  LatLng? _shopLocation; // Shop location
  LatLng? _currentLocation; // User's current location
  LatLng? _riderLocation; // Rider's real-time location
  String status = ''; // Shipment status
  String? sellerName = ''; // Seller's name
  String? sellerPhone = ''; // Seller's phone number
  String? sellerImageUrl = ''; // Seller's image URL
  String? riderName = ''; // Rider's name
  String? riderPhone = ''; // Rider's phone number
  String? riderImageUrl = ''; // Rider's image URL
  String? riderVehicleNumber = ''; // Rider's vehicle number
  String? productName = ''; // Product name
  String? productDescription = ''; // Product description
  int? productQuantity; // Product quantity
  String? productImageUrl; // Product image
  String? imageUrl1;
  String? imageUrl2;
  String? imageUrl3;
  bool isDelivering = false; // To check if status is "กำลังจัดส่ง"

  final DatabaseReference _database =
      FirebaseDatabase.instance.ref(); // Firebase reference

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchOrderDetails();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _fetchOrderDetails() async {
    final snapshot = await _database.child('orders/${widget.orderId}').get();
    if (snapshot.exists) {
      Map<String, dynamic> orderData =
          Map<String, dynamic>.from(snapshot.value as Map);

      String sellerPhone = orderData['seller'] ?? 'Unknown';
      final sellerSnapshot = await _database.child('users/$sellerPhone').get();
      if (sellerSnapshot.exists) {
        Map<String, dynamic> sellerData =
            Map<String, dynamic>.from(sellerSnapshot.value as Map);

        setState(() {
          sellerName = sellerData['name'] ?? 'Unknown Seller';
          this.sellerPhone = sellerPhone;
          sellerImageUrl = sellerData['imageUrl'];

          riderName = orderData['riderName'] ?? 'No Rider Yet';
          riderPhone = orderData['riderPhone'] ?? '';

          if (riderPhone != null && riderPhone!.isNotEmpty) {
            final riderSnapshot = _database.child('users/$riderPhone').get();
            riderSnapshot.then((snapshot) {
              if (snapshot.exists) {
                Map<String, dynamic> riderData =
                    Map<String, dynamic>.from(snapshot.value as Map);
                setState(() {
                  riderImageUrl = riderData['imageUrl'];
                  riderVehicleNumber = riderData['vehicleNumber'];
                });
              }
            });
          }

          productName = orderData['name'];
          productDescription = orderData['description'];
          productQuantity = orderData['quantity'];
          productImageUrl = orderData['imageUrl'];

          _shopLocation = LatLng(orderData['sellerLocation']['latitude'],
              orderData['sellerLocation']['longitude']);
          status = orderData['status'] ?? 'Unknown Status';
          imageUrl1 = orderData['imageUrl1'];
          imageUrl2 = orderData['imageUrl2'];
          imageUrl3 = orderData['imageUrl3'];

          if (status == 'กำลังจัดส่ง') {
            isDelivering = true;
            _listenForRiderLocation();
          }
        });
      }
    }
  }

  void _listenForRiderLocation() {
    _database
        .child('orders/${widget.orderId}/riderLocation')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        Map<String, dynamic> locationData =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _riderLocation =
              LatLng(locationData['latitude'], locationData['longitude']);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order & Shipment Details'),
        backgroundColor: Color.fromARGB(255, 75, 161, 72),
      ),
      body: Column(
        children: [
          _buildMap(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('สถานะปัจจุบัน: $status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: _buildStatusAndImages()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 250,
      child: _currentLocation == null ||
              (_shopLocation == null && _riderLocation == null)
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                center: _currentLocation,
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _currentLocation!,
                      builder: (ctx) => Icon(Icons.location_pin,
                          color: Colors.blue, size: 40),
                    ),
                    if (isDelivering && _riderLocation != null)
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _riderLocation!,
                        builder: (ctx) => Icon(Icons.delivery_dining,
                            color: Colors.orange, size: 40),
                      )
                    else if (_shopLocation != null)
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _shopLocation!,
                        builder: (ctx) =>
                            Icon(Icons.store, color: Colors.green, size: 40),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatusAndImages() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รายละเอียดคนขาย',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            if (sellerName != null)
              _buildContactInfo('ผู้ขาย', sellerName, sellerPhone),
            if (sellerImageUrl != null && sellerImageUrl!.isNotEmpty)
              _buildImageCard(sellerImageUrl!),
            SizedBox(height: 20),
            if (riderName != null &&
                riderName!.isNotEmpty &&
                riderPhone != null &&
                riderPhone!.isNotEmpty)
              _buildRiderInfo(),
            _buildProductDetails(),
            if (imageUrl1 != null && imageUrl1!.isNotEmpty)
              _buildStatusImage('รอไรเดอร์รับงาน', imageUrl1),
            if (imageUrl2 != null && imageUrl2!.isNotEmpty)
              _buildStatusImage('กำลังจัดส่ง', imageUrl2),
            if (imageUrl3 != null && imageUrl3!.isNotEmpty)
              _buildStatusImage('จัดส่งสำเร็จ', imageUrl3),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(String role, String? name, String? phone) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$role: $name', style: TextStyle(fontSize: 16)),
            Text('โทร: $phone', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('รายละเอียดสินค้า',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            SizedBox(height: 10),
            if (productName != null)
              Text('ชื่อสินค้า: $productName', style: TextStyle(fontSize: 16)),
            if (productDescription != null)
              Text('รายละเอียด: $productDescription',
                  style: TextStyle(fontSize: 16)),
            if (productQuantity != null)
              Text('จำนวน: $productQuantity', style: TextStyle(fontSize: 16)),
            if (productImageUrl != null) _buildImageCard(productImageUrl!),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Image.network(imageUrl,
          height: 150, width: double.infinity, fit: BoxFit.cover),
    );
  }

  Widget _buildRiderInfo() {
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ข้อมูลไรเดอร์',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('ชื่อ: $riderName', style: TextStyle(fontSize: 16)),
            Text('โทร: $riderPhone', style: TextStyle(fontSize: 16)),
            if (riderVehicleNumber != null)
              Text('หมายเลขรถ: $riderVehicleNumber',
                  style: TextStyle(fontSize: 16)),
            if (riderImageUrl != null) _buildImageCard(riderImageUrl!),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusImage(String label, String? imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        _buildImageCard(imageUrl!),
      ],
    );
  }
}
