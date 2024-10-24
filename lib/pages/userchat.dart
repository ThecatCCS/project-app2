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
  Future<void> _fetchOrderDetails() async {
  final snapshot = await _database.child('orders/${widget.orderId}').get();
  if (snapshot.exists) {
    Map<String, dynamic> orderData = Map<String, dynamic>.from(snapshot.value as Map);
    
    // ใช้ sellerPhone เป็นตัวเก็บข้อมูลที่ดึงมาจาก orderData
    String sellerPhone = orderData['seller'] ?? 'Unknown'; 
    
    // ดึงข้อมูลผู้ขายจาก users
    final sellerSnapshot = await _database.child('users/$sellerPhone').get();
    if (sellerSnapshot.exists) {
      Map<String, dynamic> sellerData = Map<String, dynamic>.from(sellerSnapshot.value as Map);
      
      setState(() async {
        // ดึงข้อมูลของผู้ขาย
        sellerName = sellerData['name'] ?? 'Unknown Seller'; // ชื่อผู้ขายจาก users
        this.sellerPhone = sellerPhone; // เบอร์โทรผู้ขาย
        sellerImageUrl = sellerData['imageUrl']; // รูปภาพของผู้ขาย

        // Rider details
        riderName = orderData['riderName'] ?? 'No Rider Yet';
        riderPhone = orderData['riderPhone'] ?? '';

        // **เพิ่มโค้ดเพื่อดึงข้อมูลไรเดอร์จาก users**
        if (riderPhone != null && riderPhone!.isNotEmpty) {
          // ดึงข้อมูลผู้ส่ง (ไรเดอร์) จาก users โดยใช้ riderPhone
          final riderSnapshot = await _database.child('users/$riderPhone').get();
          if (riderSnapshot.exists) {
            Map<String, dynamic> riderData = Map<String, dynamic>.from(riderSnapshot.value as Map);
            
            setState(() {
              riderImageUrl = riderData['imageUrl']; // รูปภาพของไรเดอร์
              riderVehicleNumber = riderData['vehicleNumber']; // หมายเลขป้ายทะเบียนรถของไรเดอร์
            });
          } else {
            print('Rider not found in users.');
          }
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

        // Check if the status is "กำลังจัดส่ง" (Delivering)
        if (status == 'กำลังจัดส่ง') {
          isDelivering = true;
          _listenForRiderLocation(); // Start real-time location updates for the rider
        }
      });
    } else {
      print('Seller not found in users.');
    }
  } else {
    print('Order not found or has no data.');
  }
}


  // Listen for rider's real-time location updates from Firebase
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
          Expanded(child: _buildStatusAndImages()),  // Make the status scrollable
        ],
      ),
    );
  }

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
                    // Marker for user's current location
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _currentLocation!,
                      builder: (ctx) => Icon(Icons.location_pin, color: Colors.blue, size: 40),
                    ),
                    // If the rider is delivering, show the rider's real-time location; otherwise, show the shop's location
                    if (isDelivering && _riderLocation != null)
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _riderLocation!,
                        builder: (ctx) => Icon(Icons.delivery_dining, color: Colors.orange, size: 40),
                      )
                    else if (_shopLocation != null)
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
    return SingleChildScrollView(  // Make content scrollable to avoid overflow
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display seller details
            if (sellerName != null) _buildContactInfo('Seller', sellerName, sellerPhone),
            if (sellerImageUrl != null && sellerImageUrl!.isNotEmpty) 
              Image.network(sellerImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),

            SizedBox(height: 20),

            // Display rider details in every status (if data exists)
            if (riderName != null && riderName!.isNotEmpty && riderPhone != null && riderPhone!.isNotEmpty)
              _buildRiderInfo(),

            // Display product details
            _buildProductDetails(),

            // Display each status and the corresponding image
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        imageUrl != null
            ? Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover)
            : Text('No image available for this status.'),
        SizedBox(height: 20),
      ],
    );
  }

  // Helper widget to display contact information
  Widget _buildContactInfo(String role, String? name, String? phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$role Name: $name', style: TextStyle(fontSize: 16)),
        Text('$role Phone: $phone', style: TextStyle(fontSize: 16)),
        SizedBox(height: 10),
      ],
    );
  }

  // Helper widget to display product details
  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        if (productName != null) Text('Name: $productName', style: TextStyle(fontSize: 16)),
        if (productDescription != null) Text('Description: $productDescription', style: TextStyle(fontSize: 16)),
        if (productQuantity != null) Text('Quantity: $productQuantity', style: TextStyle(fontSize: 16)),
        if (productImageUrl != null)
          Image.network(productImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
        SizedBox(height: 20),
      ],
    );
  }

  // Helper widget to build the rider's information
  Widget _buildRiderInfo() {
    if (riderName != null && riderName!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rider Name: $riderName', style: TextStyle(fontSize: 16)),
          Text('Rider Phone: $riderPhone', style: TextStyle(fontSize: 16)),
          if (riderVehicleNumber != null && riderVehicleNumber!.isNotEmpty)
            Text('Vehicle Number: $riderVehicleNumber', style: TextStyle(fontSize: 16)),
          if (riderImageUrl != null)
            Image.network(riderImageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
          SizedBox(height: 10),
        ],
      );
    } else {
      return Container(); // ไม่แสดงถ้าไม่มีข้อมูลไรเดอร์
    }
  }
}
