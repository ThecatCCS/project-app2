import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_image_upload/pages/userchat.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Map<String, dynamic>> orders = [];
  String phoneNumber = ''; // หมายเลขโทรศัพท์ของผู้ซื้อ
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String searchQuery = ''; // Holds the search query

  @override
  void initState() {
    super.initState();
    loadPhoneNumber(); // โหลดหมายเลขโทรศัพท์จาก SharedPreferences
  }

  // ฟังก์ชันโหลดหมายเลขโทรศัพท์จาก SharedPreferences
  void loadPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phone') ?? ''; // ดึงหมายเลขโทรศัพท์
    });
    fetchOrders(); // ดึงข้อมูล order ของผู้ซื้อ
  }

  // ฟังก์ชันดึงข้อมูล order ของผู้ซื้อจาก Firebase
  void fetchOrders() async {
    final snapshot = await _database.child('orders').get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> fetchedOrders = [];
      Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        Map<String, dynamic> order = Map<String, dynamic>.from(value);
        // Assuming 'key' is the orderId in Firebase
        order['id'] = key;
         // Attach the key as the orderId to the order
        fetchedOrders.add(order);
      });
      setState(() {
        orders = fetchedOrders;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ค้นหาข้อมูล order ตาม search query
    List<Map<String, dynamic>> filteredItems = orders
        .where((item) =>
            item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            item['description']
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Container(
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
                        searchQuery = value; // อัปเดตข้อมูลการค้นหา
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search',
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
          ),

          // แสดงรายการ order
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length, // ใช้ข้อมูลที่ค้นหาแล้ว
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                Color statusColor;

                // ตั้งค่าสีตามสถานะ
                switch (item['status']) {
                  case 'นำส่งสินค้าแล้ว':
                    statusColor = Colors.green;
                    break;
                  case 'กำลังจัดส่ง':
                    statusColor = const Color.fromARGB(255, 228, 211, 54);
                    break;
                  case 'รับสินค้าและกำลังเดินทาง':
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = Colors.black;
                }

                return GestureDetector(
                  onTap: () {
                    if (item['id'] != null) {
                      print('Navigating with Order ID: ${item['id']}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OrderChatPage(orderId: item['id']),
                        ),
                      );
                    } else {
                      print('Error: Order ID is null.');
                      String orderId = item['id'] ?? 'defaultOrderId';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderChatPage(orderId: orderId),
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image
                          Image.network(
                            item['imageUrl'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          // Textual content
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Text(
                                          'x${item['quantity']} item',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 10),
                                      ],
                                    ),
                                    Text(
                                      'Status: ${item['status']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                // แสดงไอคอนสถานะ
                                if (item['status'] == 'นำส่งสินค้าแล้ว')
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                else
                                  Icon(
                                    Icons.share_location,
                                    color: Colors.green,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}
