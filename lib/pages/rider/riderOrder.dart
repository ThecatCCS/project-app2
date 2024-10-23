import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_image_upload/pages/rider/receiveOrder.dart';

class RiderorderPage extends StatefulWidget {
  @override
  _RiderorderPageState createState() => _RiderorderPageState();
}

class _RiderorderPageState extends State<RiderorderPage> {
  List<Map<String, dynamic>> orders = [];
  String phoneNumber = ''; // เก็บหมายเลขโทรศัพท์ไรเดอร์
  String riderName = ''; // เก็บชื่อไรเดอร์
  final DatabaseReference _database =
      FirebaseDatabase.instance.ref(); // Firebase reference
  String searchQuery = ''; // Holds the search query

  @override
  void initState() {
    super.initState();
    loadRiderDetails(); // โหลดข้อมูลไรเดอร์
    fetchOrders(); // ดึงรายการ orders ที่มีสถานะเป็น "รอไรเดอร์รับงาน"
  }

  // ดึงข้อมูลเบอร์โทรศัพท์และชื่อไรเดอร์จาก SharedPreferences
  void loadRiderDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phone') ?? ''; // ดึงหมายเลขโทรศัพท์ไรเดอร์
      riderName = prefs.getString('name') ?? ''; // ดึงชื่อไรเดอร์
    });
  }

  // ฟังก์ชันดึงข้อมูล orders จาก Firebase เฉพาะที่มีสถานะเป็น "รอไรเดอร์รับงาน"
  void fetchOrders() async {
    final snapshot = await _database.child('orders').get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> fetchedOrders = [];
      Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        Map<String, dynamic> order = Map<String, dynamic>.from(value);
        // แสดงเฉพาะ orders ที่สถานะเป็น "รอไรเดอร์รับงาน"
        if (order['status'] == "รอไรเดอร์รับงาน") {
          order['id'] = key; // เก็บ key ของ order
          fetchedOrders.add(order);
        }
      });
      setState(() {
        orders = fetchedOrders; // เก็บรายการ orders ที่ดึงมา
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ฟิลเตอร์รายการ order ตาม search query
    List<Map<String, dynamic>> filteredOrders = orders
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
          ),

          // Order List
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
                          borderRadius:
                              BorderRadius.circular(8.0), // กำหนดขอบมน
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    color: const Color.fromARGB(
                                        255, 209, 167, 0), // สีของไอคอน
                                  ),
                                ],
                              ),
                              SizedBox(height: 30),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _showConfirmationDialog(context, order),
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
                                    onTap: () =>
                                        _showJobDetailsDialog(context, order),
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
                        builder: (context) => ReceiveOrderPage(orderId: order['id']), // ส่ง orderId
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
  void _updateOrderStatus(String orderId) async {
    try {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // แสดง Dialog รายละเอียดงาน
  void _showJobDetailsDialog(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green, // สีของขอบ
                width: 2.0, // ความหนาของขอบ
              ),
              borderRadius: BorderRadius.circular(5), // มุมมนของกรอบ
            ),
            padding: EdgeInsets.all(5), // เพิ่ม padding ภายในกรอบ
            child: Text(
              '${order['name']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16, // ขนาดตัวอักษร
              ),
            ),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0), // กำหนดขอบมน
                child: Image.network(
                  order['imageUrl'],
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(
                width: 30,
              ),
              Container(
                padding: EdgeInsets.all(10), // เพิ่ม padding ภายในกรอบ
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green, // สีของขอบ
                    width: 2.0, // ความหนาของขอบ
                  ),
                  borderRadius: BorderRadius.circular(5), // มุมมนของกรอบ
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ผู้ส่ง: ${order['seller']}'),
                    SizedBox(
                        height: 5), // ใช้ height เพื่อเพิ่มช่องว่างในแนวตั้ง
                    Text('ที่อยู่: ${order['sellerLocation']}'),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green, // สีพื้นหลังปุ่ม
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10), // padding ปุ่ม
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // ขอบมนปุ่ม
                      ),
                    ),
                    child: Text(
                      'ปิด',
                      style: TextStyle(
                        color: Colors.white, // สีตัวอักษร
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
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
}
