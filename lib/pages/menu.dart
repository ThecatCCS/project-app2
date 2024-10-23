import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ฟังก์ชันสำหรับซื้อสินค้า โดยบันทึกข้อมูล order พร้อมหมายเลขโทรศัพท์และพิกัด
  void purchaseItem(Map<String, dynamic> item) async {
    // สมมติว่าเก็บพิกัดผู้ซื้อและผู้ขายไว้ใน Firebase แล้ว
    final buyerLocationSnapshot = await _database.child('users/$phoneNumber/location').get();
    final sellerLocationSnapshot = await _database.child('users/${item['phoneNumber']}/location').get();

    // ถ้ามีข้อมูลพิกัดใน Firebase ให้ดึงข้อมูลออกมา
    String buyerLocation = buyerLocationSnapshot.exists ? buyerLocationSnapshot.value.toString() : "ไม่ทราบตำแหน่งผู้ซื้อ";
    String sellerLocation = sellerLocationSnapshot.exists ? sellerLocationSnapshot.value.toString() : "ไม่ทราบตำแหน่งผู้ขาย";

    final orderRef = _database.child('orders').push();
    Map<String, dynamic> orderData = {
      'buyer': phoneNumber, // หมายเลขโทรศัพท์ผู้ซื้อ
      'seller': item['phoneNumber'], // หมายเลขโทรศัพท์ผู้ขาย
      'name': item['name'], // ชื่อสินค้า
      'quantity': item['quantity'], // จำนวน
      'description': item['description'], // รายละเอียดสินค้า
      'imageUrl': item['imageUrl'], // URL รูปภาพสินค้า
      'status': 'รอไรเดอร์รับงาน', // สถานะคำสั่งซื้อเริ่มต้น
      'buyerLocation': buyerLocation, // พิกัดผู้ซื้อ
      'sellerLocation': sellerLocation // พิกัดผู้ขาย
    };

    await orderRef.set(orderData);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("ซื้อสินค้า ${item['name']} สำเร็จแล้ว!"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Filter the menu items based on the search query
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
                        searchQuery = value; // Update search query on change
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

          // Menu List
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length, // Use the filtered list length
              itemBuilder: (context, index) {
                final item = filteredItems[index]; // Get the current item
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
                                maxLines: 1, // Limit to 1 line
                                overflow: TextOverflow.ellipsis, // Add ellipsis if overflow
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  SizedBox(width: 5),
                                  Text('${item['rating']}'),
                                  SizedBox(width: 10),
                                  // Limit the description to 1 line and add ellipsis
                                  Expanded(
                                    child: Text(
                                      item['description'],
                                      maxLines: 1, // Limit to 1 line
                                      overflow: TextOverflow.ellipsis, // Add ellipsis if overflow
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Shopping cart and quantity controls
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.shopping_cart),
                              onPressed: () {
                                purchaseItem(item); // เรียกฟังก์ชันสำหรับซื้อสินค้า
                              },
                            ),
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
