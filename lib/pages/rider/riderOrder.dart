import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_image_upload/pages/rider/receiveOrder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderorderPage extends StatefulWidget {
  @override
  _RiderorderPageState createState() => _RiderorderPageState();
}

class _RiderorderPageState extends State<RiderorderPage> {
  List<Map<String, dynamic>> orders = [];
  String phoneNumber = ''; // เก็บหมายเลขโทรศัพท์ไรเดอร์
  final DatabaseReference _database = FirebaseDatabase.instance.ref(); // Firebase reference
  String searchQuery = ''; // Holds the search query

  @override
  void initState() {
    super.initState();
    loadRiderPhone(); // Load rider's phone number from SharedPreferences
    fetchOrders(); // Fetch orders that are "รอไรเดอร์รับงาน"
  }

  // Load rider's phone number from SharedPreferences
  void loadRiderPhone() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString('phone') ?? ''; // Retrieve rider's phone number from login

    print('Phone Number: $phoneNumber');

    if (phoneNumber.isEmpty) {
      print('Error: No phone number provided');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่พบเบอร์โทรศัพท์ กรุณาลองอีกครั้ง')),
      );
    }
  }

  // Fetch orders from Firebase that are either pending for this rider or available for assignment
  void fetchOrders() async {
    try {
      final snapshot = await _database.child('orders').get();
      if (snapshot.exists) {
        List<Map<String, dynamic>> pendingOrders = [];
        List<Map<String, dynamic>> availableOrders = [];
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

        data.forEach((key, value) {
          Map<String, dynamic> order = Map<String, dynamic>.from(value);

          // Show orders for the logged-in rider or orders that are available for assignment
          if (order['status'] != "จัดส่งสำเร็จ" && order['riderPhone'] == phoneNumber) {
            order['id'] = key;
            pendingOrders.add(order);
          } else if (order['status'] == "รอไรเดอร์รับงาน") {
            order['id'] = key;
            availableOrders.add(order);
          }
        });

        setState(() {
          // Display pending orders first, if any, otherwise show available orders
          orders = pendingOrders.isNotEmpty ? pendingOrders : availableOrders;
        });

        if (pendingOrders.isNotEmpty) {
          // If pending orders exist, navigate to ReceiveOrderPage automatically
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiveOrderPage(orderId: pendingOrders[0]['id']),
            ),
          );
        }
      } else {
        print("No orders found in Firebase");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบรายการคำสั่งซื้อในระบบ')),
        );
      }
    } catch (e) {
      print('Error fetching orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // Filter orders based on search query
  List<Map<String, dynamic>> getFilteredOrders() {
    return orders.where((item) =>
        item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
        item['description'].toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  // Search bar widget
  Widget buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(5),
      margin: EdgeInsets.only(top: 30, left: 10, right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Color.fromARGB(255, 75, 161, 72),
          width: 3,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'ค้นหา',
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(left: 15),
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(Icons.search, color: Color.fromARGB(255, 75, 161, 72)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredOrders = getFilteredOrders();

    return Scaffold(
      body: Column(
        children: [
          buildSearchBar(),
          if (orders.isEmpty)
            Center(
              child: Text(
                'ไม่มีงานค้าง',
                style: TextStyle(fontSize: 18),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              order['imageUrl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      order['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Icon(
                                      Icons.access_time,
                                      size: 36.0,
                                      color: const Color.fromARGB(255, 209, 167, 0),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showConfirmationDialog(context, order),
                                      child: Text(
                                        'กดรับงาน',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                            color: Colors.green,
                                            decorationColor: Colors.green),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showJobDetailsDialog(context, order),
                                      child: Text(
                                        'ดูรายละเอียดงาน',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                            color: Colors.green,
                                            decorationColor: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Confirmation dialog for accepting an order
  void _showConfirmationDialog(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'คุณยืนยันที่จะรับออเดอร์หรือไม่',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: TextButton(
                    child: Text(
                      'ยกเลิก',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SizedBox(width: 30),
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: TextButton(
                    child: Text(
                      'ยืนยัน',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      _updateOrderStatus(order['id']);
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceiveOrderPage(orderId: order['id']),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Update the status of the order in Firebase
  void _updateOrderStatus(String orderId) async {
    try {
      if (phoneNumber.isEmpty) {
        throw Exception('Rider phone number is empty');
      }

      print('Updating order with riderPhone: $phoneNumber');

      await _database.child('orders/$orderId').update({
        'status': 'กำลังไปรับอาหาร',
        'riderPhone': phoneNumber, // Only update phone number
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('รับงานสำเร็จ!')),
      );

      fetchOrders(); // Refresh the orders after the update
    } catch (e) {
      print('Error updating order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // Show job details in a dialog
  void _showJobDetailsDialog(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        LatLng? storeLocation;
        if (order['sellerLocation'] != null && order['sellerLocation']['latitude'] != null && order['sellerLocation']['longitude'] != null) {
          storeLocation = LatLng(order['sellerLocation']['latitude'], order['sellerLocation']['longitude']);
        }

        LatLng? customerLocation;
        if (order['buyerLocation'] != null && order['buyerLocation']['latitude'] != null && order['buyerLocation']['longitude'] != null) {
          customerLocation = LatLng(order['buyerLocation']['latitude'], order['buyerLocation']['longitude']);
        }

        LatLng? riderLocation;
        if (order['riderLocation'] != null && order['riderLocation']['latitude'] != null && order['riderLocation']['longitude'] != null) {
          riderLocation = LatLng(order['riderLocation']['latitude'], order['riderLocation']['longitude']);
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.95,
            minChildSize: 0.7,
            builder: (_, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ' ',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      if (order['imageUrl'] != null)
                        Image.network(order['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                      SizedBox(height: 20),
                      Text(
                        'ชื่อเมนู: ${order['name']}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'รายละเอียด: ${order['description']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'จำนวน: ${order['quantity']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'เบอร์ผู้ซื้อ: ${order['buyer']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'เบอร์ผู้ขาย: ${order['seller']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),
                      if (storeLocation != null || customerLocation != null || riderLocation != null)
                        Container(
                          height: 300,
                          child: FlutterMap(
                            options: MapOptions(
                              center: storeLocation ?? customerLocation ?? LatLng(0, 0),
                              zoom: 13.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  if (storeLocation != null)
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: storeLocation,
                                      builder: (ctx) => Icon(Icons.store, color: Colors.green, size: 40),
                                    ),
                                  if (customerLocation != null)
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: customerLocation,
                                      builder: (ctx) => Icon(Icons.home, color: Colors.blue, size: 40),
                                    ),
                                  if (riderLocation != null)
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: riderLocation,
                                      builder: (ctx) => Icon(Icons.delivery_dining, color: Colors.orange, size: 40),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text('ปิดหน้าต่าง', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
