import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<Map<String, dynamic>> menuItems = [];
  String phoneNumber = ''; // เก็บหมายเลขโทรศัพท์ของผู้ใช้
  DatabaseReference _database = FirebaseDatabase.instance.ref();
  String searchQuery = ''; // ตัวแปรสำหรับเก็บข้อมูลที่ต้องการค้นหา

  @override
  void initState() {
    super.initState();
    loadPhoneNumber();
  }

  // ดึงหมายเลขโทรศัพท์จาก SharedPreferences
  void loadPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phone') ?? ''; // ดึงหมายเลขโทรศัพท์
    });
    fetchMenuItems(); // เมื่อดึงหมายเลขโทรศัพท์แล้วให้ดึงเมนู
  }

  // ดึงข้อมูลเมนูจาก Firebase
  void fetchMenuItems() async {
    final snapshot = await _database.child('menuItems').get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> fetchedItems = [];
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        Map<String, dynamic> menuItem = Map<String, dynamic>.from(value);
        // ไม่แสดงเมนูของผู้ใช้เอง
        if (menuItem['phoneNumber'] != phoneNumber) {
          fetchedItems.add(menuItem);
        }
      });
      setState(() {
        menuItems = fetchedItems;
      });
    }
  }

  // ฟังก์ชันเพิ่มจำนวนสินค้า
  void increaseQuantity(int index) {
    setState(() {
      menuItems[index]['quantity']++;
    });
  }

  // ฟังก์ชันลดจำนวนสินค้า
  void decreaseQuantity(int index) {
    if (menuItems[index]['quantity'] > 1) {
      setState(() {
        menuItems[index]['quantity']--;
      });
    }
  }

  // ฟังก์ชันสำหรับการซื้อสินค้า
  void addToCart(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('เพิ่ม ${item['name']} ในตะกร้าแล้ว!'),
    ));
  }

  // ฟังก์ชันสำหรับนำไปสู่หน้ารายละเอียดเมนู
  void goToMenuDetail(Map<String, dynamic> item) async {
    final sellerSnapshot = await _database.child('users/${item['phoneNumber']}').get();
    if (sellerSnapshot.exists) {
      Map<String, dynamic> sellerData = Map<String, dynamic>.from(sellerSnapshot.value as Map);
      LatLng sellerLocation = LatLng(
        sellerData['location']['latitude'],
        sellerData['location']['longitude'],
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenuDetailPage(
            item: item,
            sellerData: sellerData,
            sellerLocation: sellerLocation,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // กรองเมนูตามคำค้นหา
    List<Map<String, dynamic>> filteredItems = menuItems
        .where((item) =>
            item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            item['description']
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('เมนูอาหาร'),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(5),
            margin: EdgeInsets.only(top: 10, left: 10, right: 10),
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
                        searchQuery = value; // อัปเดตการค้นหาเมื่อเปลี่ยนแปลง
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ค้นหาเมนู',
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

          // รายการเมนู
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length, // จำนวนเมนูที่กรองแล้ว
              itemBuilder: (context, index) {
                final item = filteredItems[index]; // ดึงรายการเมนูแต่ละอัน
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
                        // Textual content
                        Expanded(
                          child: Column(
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
                              Text(
                                item['description'],
                                maxLines: 1, // จำกัดให้แสดง 1 บรรทัด
                                overflow: TextOverflow.ellipsis, // แสดง ellipsis ถ้าเกิน
                              ),
                            ],
                          ),
                        ),
                        // Quantity and Cart controls
                        Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  iconSize: 15,
                                  onPressed: () {
                                    decreaseQuantity(index); // เรียกฟังก์ชันลดจำนวน
                                  },
                                ),
                                Text('${item['quantity']}'),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  iconSize: 15,
                                  onPressed: () {
                                    increaseQuantity(index); // เรียกฟังก์ชันเพิ่มจำนวน
                                  },
                                ),
                              ],
                            ),
                            // เพิ่มไอคอนใหม่สำหรับดูรายละเอียดสินค้า
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.shopping_cart),
                                  onPressed: () {
                                    addToCart(item); // เรียกฟังก์ชันเพิ่มสินค้าไปยังตะกร้า
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.info),
                                  onPressed: () {
                                    goToMenuDetail(item); // ไปยังหน้ารายละเอียดสินค้า
                                  },
                                ),
                              ],
                            ),
                          ],
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

// หน้าแสดงรายละเอียดของเมนู
class MenuDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> sellerData;
  final LatLng sellerLocation;

  MenuDetailPage({
    required this.item,
    required this.sellerData,
    required this.sellerLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              item['imageUrl'],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text(
              'ชื่อเมนู: ${item['name']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'รายละเอียด: ${item['description']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'หมายเลขโทรศัพท์ผู้ขาย: ${item['phoneNumber']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'ชื่อผู้ขาย: ${sellerData['name']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            // แสดงแผนที่พร้อมหมากตำแหน่งของผู้ขาย
            Container(
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  center: sellerLocation,
                  zoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: sellerLocation,
                        builder: (ctx) => Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
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
  }
}
