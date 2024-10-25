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
  String? buyerName = ''; // Buyer's name
  String? buyerPhone = ''; // Buyer's phone number
  String? buyerImageUrl = ''; // Buyer's image URL 
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

  final DatabaseReference _database = FirebaseDatabase.instance.ref(); // Firebase reference

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchOrderDetails();
  }

  // Function to get the current location of the user
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  // Fetch order details including status and images from Firebase
  // Fetch order details including status and images from Firebase
Future<void> _fetchOrderDetails() async {
  final snapshot = await _database.child('orders/${widget.orderId}').get();
  if (snapshot.exists) {
    Map<String, dynamic> orderData = Map<String, dynamic>.from(snapshot.value as Map);
    
    String buyerPhone = orderData['buyer'] ?? 'Unknown'; 
    
    // ดึงข้อมูลผู้ซื้อจาก users
    final buyerSnapshot = await _database.child('users/$buyerPhone').get();
    if (buyerSnapshot.exists) {
      Map<String, dynamic> buyerData = Map<String, dynamic>.from(buyerSnapshot.value as Map);
      
      setState(() {
        buyerName = buyerData['name'] ?? 'Unknown Buyer'; 
        this.buyerPhone = buyerPhone; 
        buyerImageUrl = buyerData['imageUrl'];

        // Rider details
        riderName = orderData['riderName'] ?? 'No Rider Yet';
        riderPhone = orderData['riderPhone'] ?? '';

        // ดึงข้อมูลไรเดอร์จาก users ถ้ามี
        if (riderPhone != null && riderPhone!.isNotEmpty) {
          final riderSnapshot = _database.child('users/$riderPhone').get();
          riderSnapshot.then((snapshot) {
            if (snapshot.exists) {
              Map<String, dynamic> riderData = Map<String, dynamic>.from(snapshot.value as Map);
              setState(() {
                riderImageUrl = riderData['imageUrl'];
                riderVehicleNumber = riderData['vehicleNumber'];
              });
            }
          });
        }

        // Product details
        productName = orderData['name'];
        productDescription = orderData['description'];
        productQuantity = orderData['quantity'];
        productImageUrl = orderData['imageUrl'];

        // Shipment status and images
        _shopLocation = LatLng(orderData['sellerLocation']['latitude'], orderData['sellerLocation']['longitude']);
        status = orderData['status'] ?? 'Unknown Status';
        imageUrl1 = orderData['imageUrl1'];
        imageUrl2 = orderData['imageUrl2'];
        imageUrl3 = orderData['imageUrl3'];

        // Check if the status is "กำลังจัดส่ง"
        if (status == 'กำลังจัดส่ง') {
          isDelivering = true;
          _listenForRiderLocation();
        } else if (status == 'จัดส่งสำเร็จ') {
          isDelivering = false;
          _riderLocation = null; // Remove rider marker
          _stopListeningForRiderLocation();
        }
      });
    }
  }
}


  // ฟังการเปลี่ยนแปลงตำแหน่งไรเดอร์แบบเรียลไทม์
  void _listenForRiderLocation() {
  _database.child('orders/${widget.orderId}/riderLocation').onValue.listen((event) {
    if (event.snapshot.exists) {
      Map<String, dynamic> locationData = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _riderLocation = LatLng(locationData['latitude'], locationData['longitude']);
      });
    }
  });
}
void _stopListeningForRiderLocation() {
  _database.child('orders/${widget.orderId}/riderLocation').onValue.drain();
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
          _buildMap(),  // Display map
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Current Status: $status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          Expanded(child: _buildStatusAndImages()),  // Make the status scrollable
        ],
      ),
    );
  }

  // Build the Map widget
  // Build the Map widget
Widget _buildMap() {
  return Container(
    height: 300,
    child: _currentLocation == null || (_shopLocation == null && _riderLocation == null)
        ? Center(child: CircularProgressIndicator())
        : FlutterMap(
            options: MapOptions(
              center: _currentLocation,
              zoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  // User's current location
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: _currentLocation!,
                    builder: (ctx) => Icon(Icons.location_pin, color: Colors.blue, size: 40),
                  ),
                  // Rider's location (only if delivering)
                  if (isDelivering && _riderLocation != null)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _riderLocation!,
                      builder: (ctx) => Icon(Icons.delivery_dining, color: Colors.orange, size: 40),
                    ),
                  // Shop location
                  if (_shopLocation != null)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _shopLocation!,
                      builder: (ctx) => Icon(Icons.store, color: Colors.green, size: 40),
                    ),
                ],
              ),
            ],
          ),
  );
}


  // Build the status and images consecutively
  Widget _buildStatusAndImages() {
    return SingleChildScrollView(  
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Buyer Information'),
            _buildContactInfo(buyerName, buyerPhone, buyerImageUrl),
            Divider(),

            // Display rider details in every status (if data exists)
            if (riderName != null && riderName!.isNotEmpty && riderPhone != null && riderPhone!.isNotEmpty) 
              Column(
                children: [
                  _buildSectionHeader('Rider Information'),
                  _buildRiderInfo(),
                  Divider(),
                ],
              ),

            // Display product details
            _buildSectionHeader('Product Details'),
            _buildProductDetails(),
            Divider(),

            // Display each status and the corresponding image if available
            _buildStatusImage('รอไรเดอร์รับงาน', imageUrl1),
            _buildStatusImage('กำลังจัดส่ง', imageUrl2),
            _buildStatusImage('จัดส่งสำเร็จ', imageUrl3),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the image associated with a status
  Widget _buildStatusImage(String label, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(); // ไม่แสดงถ้าไม่มีรูปภาพ
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  // Helper widget to display contact information
  Widget _buildContactInfo(String? name, String? phone, String? imageUrl) {
    return Row(
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(imageUrl),
          ),
        SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อผู้ซื้อ: $name', style: TextStyle(fontSize: 16)),
            Text('เบอร์โทร: $phone', style: TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }

  // Helper widget to display product details
  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (productName != null) Text('สินค้าที่ซื้อ: $productName', style: TextStyle(fontSize: 16)),
        if (productDescription != null) Text('รายละเอียด: $productDescription', style: TextStyle(fontSize: 16)),
        if (productQuantity != null) Text('จำนวน: $productQuantity', style: TextStyle(fontSize: 16)),
        if (productImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(productImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
          ),
        SizedBox(height: 20),
      ],
    );
  }

  // Helper widget to build the rider's information
  Widget _buildRiderInfo() {
    return Row(
      children: [
        if (riderImageUrl != null && riderImageUrl!.isNotEmpty)
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(riderImageUrl!),
          ),
        SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rider Name: $riderName', style: TextStyle(fontSize: 16)),
            Text('Rider Phone: $riderPhone', style: TextStyle(fontSize: 16)),
            if (riderVehicleNumber != null && riderVehicleNumber!.isNotEmpty)
              Text('Vehicle Number: $riderVehicleNumber', style: TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }

  // Helper widget to create section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
    );
  }
}
