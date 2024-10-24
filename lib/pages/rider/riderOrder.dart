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
  String riderName = ''; // เก็บชื่อไรเดอร์
  final DatabaseReference _database = FirebaseDatabase.instance.ref(); // Firebase reference
  String searchQuery = ''; // Holds the search query

  @override
  void initState() {
    super.initState();
    loadRiderDetails(); // โหลดข้อมูลไรเดอร์จาก Realtime Database
    fetchOrders(); // ดึงรายการ orders ที่มีสถานะเป็น "รอไรเดอร์รับงาน"
  }

  // ฟังก์ชันดึงข้อมูลเบอร์โทรศัพท์และชื่อไรเดอร์จาก Realtime Database
// ดึงข้อมูลเบอร์โทรศัพท์และชื่อไรเดอร์จาก Firebase Realtime Database (users node)
void loadRiderDetails() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  phoneNumber = prefs.getString('phone') ?? '';

  if (phoneNumber.isNotEmpty) {
    final snapshot = await _database
        .child('users')
        .orderByChild('phone')
        .equalTo(phoneNumber)
        .limitToFirst(1)
        .get();

    if (snapshot.exists) {
      // Ensure data is retrieved properly and handle null cases
      Map<String, dynamic> userData = Map<String, dynamic>.from((snapshot.value as Map).values.first);

      setState(() {
        riderName = userData['name'] ?? ''; // Default to empty string if null
        phoneNumber = userData['phone'] ?? ''; // Default to empty string if null
      });

      if (riderName.isEmpty || phoneNumber.isEmpty) {
        // Handle case where either riderName or phoneNumber is empty
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ข้อมูลไรเดอร์ไม่สมบูรณ์')),
        );
        print('Error: Rider name or phone number is empty');
      } else {
        print('Phone Number: $phoneNumber');
        print('Rider Name: $riderName');
      }
    } else {
      print('Error: No rider data found');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่พบข้อมูลไรเดอร์ในระบบ')),
      );
    }
  } else {
    print('Error: No phone number provided');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ไม่พบเบอร์โทรศัพท์ กรุณาลองอีกครั้ง')),
    );
  }
}




  // ฟังก์ชันดึงข้อมูล orders จาก Firebase เฉพาะที่มีสถานะเป็น "รอไรเดอร์รับงาน"
  void fetchOrders() async {
    final snapshot = await _database.child('orders').get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> pendingOrders = [];
      List<Map<String, dynamic>> availableOrders = [];
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

      data.forEach((key, value) {
        Map<String, dynamic> order = Map<String, dynamic>.from(value);

        // ตรวจสอบว่ามีงานที่ยังไม่เสร็จสำหรับไรเดอร์คนนี้หรือไม่
        if (order['status'] != "จัดส่งสำเร็จ" && order['riderPhone'] == phoneNumber) {
          order['id'] = key; // เก็บ key ของ order ที่ยังไม่เสร็จ
          pendingOrders.add(order);
        } 
        // ถ้าไม่มีงานค้าง ก็จะเป็นงานที่ไรเดอร์สามารถรับได้ตามปกติ
        else if (order['status'] == "รอไรเดอร์รับงาน") {
          order['id'] = key; // เก็บ key ของ order ที่สามารถรับได้
          availableOrders.add(order);
        }
      });

      setState(() {
        orders = pendingOrders.isNotEmpty ? pendingOrders : availableOrders;
      });

      // ถ้ามีงานค้างอยู่ ให้ไปยังหน้า ReceiveOrderPage โดยอัตโนมัติ
      if (pendingOrders.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiveOrderPage(orderId: pendingOrders[0]['id']), // ส่ง orderId ที่ยังไม่เสร็จ
          ),
        );
      }
    }
  }

  // ฟิลเตอร์รายการ order ตาม search query
  List<Map<String, dynamic>> getFilteredOrders() {
    return orders.where((item) =>
        item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
        item['description'].toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  // Widget สำหรับแสดงช่องค้นหา
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
                  searchQuery = value; // อัปเดต search query
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
    // ใช้ฟังก์ชันกรอง orders ที่ตรงกับ searchQuery
    List<Map<String, dynamic>> filteredOrders = getFilteredOrders();

    return Scaffold(
      body: Column(
        children: [
          buildSearchBar(), // เพิ่มช่องค้นหา
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
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0), // กำหนดขอบมน
                            child: Image.network(
                              order['imageUrl'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 10),
                          // Textual content
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
                                      size: 36.0, // ขนาดของไอคอน
                                      color: const Color.fromARGB(255, 209, 167, 0), // สีของไอคอน
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

  // แสดง Dialog ยืนยันการรับงาน
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
                      // อัปเดตสถานะออเดอร์และบันทึกเบอร์และชื่อไรเดอร์
                      _updateOrderStatus(order['id']);
                      Navigator.of(context).pop();
                      // ไปที่หน้า ReceiveOrderPage พร้อมส่ง orderId ไปด้วย
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

  // ฟังก์ชันอัปเดตสถานะออเดอร์ใน Firebase
// ฟังก์ชันอัปเดตสถานะออเดอร์ใน Firebase
void _updateOrderStatus(String orderId) async {
  try {
    // ตรวจสอบค่าก่อนอัปเดตใน Firebase
    if (riderName.isEmpty || phoneNumber.isEmpty) {
      throw Exception('Rider name or phone number is empty');
    }

    print('Updating order with riderName: $riderName and riderPhone: $phoneNumber');

    await _database.child('orders/$orderId').update({
      'status': 'กำลังไปรับอาหาร', // เปลี่ยนสถานะเป็น "กำลังดำเนินการ"
      'riderPhone': phoneNumber, // เพิ่มเบอร์โทรศัพท์ไรเดอร์
      'riderName': riderName, // เพิ่มชื่อไรเดอร์
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('รับงานสำเร็จ!')),
    );

    // Refresh the orders after the update
    fetchOrders();
  } catch (e) {
    print('Error updating order: $e'); // แสดง error message ถ้ามีข้อผิดพลาด
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
    );
  }
}



  // แสดง Dialog รายละเอียดงาน (แบบเต็มหน้าจอ)
  void _showJobDetailsDialog(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // Add null checks for storeLocation, customerLocation, and riderLocation
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
            bottom: MediaQuery.of(context).viewInsets.bottom, // ให้เลื่อนขึ้นตามคีย์บอร์ด
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

                      // รูปเมนู
                      if (order['imageUrl'] != null)
                        Image.network(order['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                      SizedBox(height: 20),

                      // ชื่อเมนู
                      Text(
                        'ชื่อเมนู: ${order['name']}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),

                      // รายละเอียด
                      Text(
                        'รายละเอียด: ${order['description']}',
                        style: TextStyle(fontSize: 16),
                      ),
                

                      // จำนวน
                      Text(
                        'จำนวน: ${order['quantity']}',
                        style: TextStyle(fontSize: 16),
                      ),
                  

                      // ข้อมูลผู้ซื้อและผู้ขาย
                      Text(
                        'เบอร์ผู้ซื้อ: ${order['buyer']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'เบอร์ผู้ขาย: ${order['seller']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 20),

                      // Map ที่มี marker 3 จุด: ร้านค้า, ไรเดอร์, ลูกค้า
                      if (storeLocation != null || customerLocation != null || riderLocation != null)
                        Container(
                          height: 300,
                          child: FlutterMap(
                            options: MapOptions(
                              center: storeLocation ?? customerLocation ?? LatLng(0, 0), // Default center
                              zoom: 13.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  // ร้านค้า
                                  if (storeLocation != null)
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: storeLocation,
                                      builder: (ctx) => Icon(Icons.store, color: Colors.green, size: 40),
                                    ),
                                  // ลูกค้า
                                  if (customerLocation != null)
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: customerLocation,
                                      builder: (ctx) => Icon(Icons.home, color: Colors.blue, size: 40),
                                    ),
                                  // ไรเดอร์
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

                      // ปุ่มปิด dialog
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
