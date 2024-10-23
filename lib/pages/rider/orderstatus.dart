import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderstatusPage extends StatefulWidget {
  @override
  _OrderstatusPageState createState() => _OrderstatusPageState();
}

class _OrderstatusPageState extends State<OrderstatusPage> {
  List<Map<String, dynamic>> orders = []; // รายการออเดอร์
  String phoneNumber = ''; // ใช้เก็บเบอร์ไรเดอร์
  final DatabaseReference _database = FirebaseDatabase.instance.ref(); // Firebase reference
  String searchQuery = ''; // ใช้สำหรับค้นหา

  @override
  void initState() {
    super.initState();
    loadPhoneNumber(); // โหลดหมายเลขโทรศัพท์จาก SharedPreferences
  }

  // ฟังก์ชันโหลดหมายเลขโทรศัพท์จาก SharedPreferences
  void loadPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phone') ?? ''; // โหลดเบอร์ไรเดอร์
    });
    fetchOrders(); // ดึงข้อมูลออเดอร์จาก Firebase
  }

  // ฟังก์ชันดึงข้อมูลออเดอร์จาก Firebase เฉพาะสถานะ "จัดส่งสำเร็จ" ของไรเดอร์นี้
  void fetchOrders() async {
    final snapshot = await _database.child('orders').get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> fetchedOrders = [];
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        Map<String, dynamic> order = Map<String, dynamic>.from(value);
        // แสดงเฉพาะออเดอร์ที่สถานะเป็น "จัดส่งสำเร็จ" และเป็นของไรเดอร์นี้
        if (order['status'] == "จัดส่งสำเร็จ" && order['riderPhone'] == phoneNumber) {
          order['id'] = key; // เก็บ key ของออเดอร์
          fetchedOrders.add(order);
        }
      });
      setState(() {
        orders = fetchedOrders; // เก็บรายการออเดอร์ที่ดึงมา
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ฟิลเตอร์รายการออเดอร์ตามคำค้นหา
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
                        searchQuery = value; // อัปเดตคำค้นหา
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
          ),

          // Order List
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length, // ใช้รายการที่ฟิลเตอร์แล้ว
              itemBuilder: (context, index) {
                final item = filteredItems[index]; // ออเดอร์ที่ฟิลเตอร์แล้ว
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image
                        Image.network(
                          item['imageUrl'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(width: 10),
                        // ข้อมูลข้อความ
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1, // จำกัดให้แสดง 1 บรรทัด
                                overflow: TextOverflow.ellipsis, // แสดง ellipsis ถ้าเกิน
                              ),
                              SizedBox(height: 4), // ระยะห่างระหว่างข้อความ
                              Text(
                                'จัดส่งสำเร็จ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ไอคอนแสดงสถานะ
                        Icon(
                          Icons.check_circle, // ไอคอนติ๊ก
                          color: Colors.green, // สีของไอคอน
                          size: 24, // ขนาดของไอคอน
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
}
