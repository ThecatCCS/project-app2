import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin {
  String searchQuery = ''; // Holds the search query
  String phoneNumber = ''; // ใช้สำหรับเก็บหมายเลขโทรศัพท์จาก SharedPreferences
  late TabController _tabController;
  final DatabaseReference _database = FirebaseDatabase.instance.ref(); // Firebase reference
  List<Map<String, dynamic>> menuItems = []; // เมนูอาหารที่ดึงมาแสดง
  List<Map<String, dynamic>> orders = []; // Order items
  File? _imageFile; // เก็บรูปภาพที่ถ่าย

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadPhoneNumber(); // โหลดหมายเลขโทรศัพท์จาก SharedPreferences
  }

  // ดึงหมายเลขโทรศัพท์จาก SharedPreferences
  void loadPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phone') ?? ''; // ดึงหมายเลขโทรศัพท์
    });
    if (phoneNumber.isNotEmpty) {
      fetchMenuItems(); // ดึงเมนูอาหารถ้าได้หมายเลขโทรศัพท์มา
      fetchOrders(); // ดึงข้อมูลออเดอร์สำหรับผู้ใช้
    }
  }

  // ฟังก์ชันดึงข้อมูลเมนูอาหารจาก Firebase (menuItems แยกจาก users)
// ฟังก์ชันดึงข้อมูลเมนูอาหารจาก Firebase (menuItems แยกจาก users)
void fetchMenuItems() async {
  final snapshot = await _database.child('menuItems').get();
  if (snapshot.exists) {
    List<Map<String, dynamic>> fetchedItems = [];
    Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
    data.forEach((key, value) {
      Map<String, dynamic> item = Map<String, dynamic>.from(value);
      item['id'] = key; // เพิ่ม key จาก Firebase ให้กับเมนู
      // แสดงเมนูเฉพาะที่มีหมายเลขโทรศัพท์ตรงกับผู้ใช้
      if (item['phoneNumber'] == phoneNumber) {
        fetchedItems.add(item);
      }
    });
    setState(() {
      menuItems = fetchedItems; // เก็บรายการเมนูที่ดึงมา
    });
  }
}

  // ฟังก์ชันดึงข้อมูลออเดอร์จาก Firebase
  void fetchOrders() async {
    final snapshot = await _database.child('orders').get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> fetchedOrders = [];
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        Map<String, dynamic> order = Map<String, dynamic>.from(value);
        // Show orders only where the current user is the seller
        if (order['seller'] == phoneNumber) {
          fetchedOrders.add(order);
        }
      });
      setState(() {
        orders = fetchedOrders; // Store the matching orders
      });
    }
  }

  // ฟังก์ชันเพิ่มเมนูอาหาร (เพิ่มใน menuItems ใหม่)
  void addMenuItem(Map<String, dynamic> newItem) async {
    await _database.child('menuItems').push().set(newItem);
    fetchMenuItems(); // Refresh list after adding
  }

  // ฟังก์ชันลบเมนูอาหาร
  // ฟังก์ชันลบเมนูอาหาร
void deleteMenuItem(String menuItemId) async {
  try {
    // ลบข้อมูลจาก Firebase
    await _database.child('menuItems/$menuItemId').remove();
    
    // รีเฟรชรายการเมนูหลังจากลบสำเร็จ
    setState(() {
      menuItems.removeWhere((item) => item['id'] == menuItemId);
    });

    // แสดงข้อความแจ้งเตือนเมื่อทำการลบสำเร็จ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เมนูลบสำเร็จ!')),
    );
  } catch (e) {
    // ถ้ามีข้อผิดพลาดเกิดขึ้นให้แสดงข้อความแจ้งเตือน
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาดในการลบเมนู: $e')),
    );
  }
}

  // ฟังก์ชันอัปโหลดรูปภาพไปยัง Firebase Storage
  Future<String> uploadImageToFirebase(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('menuImages/$fileName');
    UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL(); // คืน URL ของรูปภาพ
  }

  // ฟังก์ชันเลือกรูปภาพจากกล้อง
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      _imageFile = File(pickedFile!.path);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'อาหาร'), // Food
            Tab(text: 'ออเดอร์'), // Order
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // เปิดหน้าต่างเพิ่มเมนูอาหาร
              showAddMenuDialog(context);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildFoodList(),
          buildOrderSummary(),
        ],
      ),
    );
  }

  Widget buildFoodList() {
    // Filter the menu items based on the search query
    List<Map<String, dynamic>> filteredItems = menuItems
        .where((item) =>
            item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            item['description']
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();

    return Column(
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
        Expanded(
          child: ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.network(
                            item['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(item['description']),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // ลบเมนูอาหารตาม id ของ Firebase
                              deleteMenuItem(item['id']); 
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, // Background color
                            ),
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
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
    );
  }

  // สร้างส่วนของออเดอร์ที่แสดงเฉพาะออเดอร์ที่ผู้ใช้เป็นผู้ขาย
  Widget buildOrderSummary() {
    if (orders.isEmpty) {
      return Center(child: Text('ไม่มีออเดอร์ที่เกี่ยวข้อง'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Rounded corners
          ),
          elevation: 5, // Add elevation to give a raised effect
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order['name'], // Product name
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 75, 161, 72),
                      ),
                    ),
                    Icon(
                      Icons.fastfood, // Icon representing the product
                      color: Colors.orangeAccent,
                      size: 30,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'จำนวน: ${order['quantity']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'สถานะ: ${order['status']}',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(
                      'ผู้ซื้อ: ${order['buyer']}',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.store, color: Colors.grey),
                    SizedBox(width: 5),
                    Text(
                      'ผู้ขาย: ${order['seller']}',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Icon(Icons.location_pin, color: Colors.redAccent),
                    SizedBox(width: 5),
                    Text(
                      'ตำแหน่งผู้ซื้อ: ${order['buyerLocation']}', // Display as string
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.store_mall_directory, color: Colors.redAccent),
                    SizedBox(width: 5),
                    Text(
                      'ตำแหน่งผู้ขาย: ${order['sellerLocation']}', // Display as string
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Functionality to track or update order status
                      },
                      icon: Icon(Icons.delivery_dining, color: Colors.white),
                      label: Text('ติดตามการจัดส่ง'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 75, 161, 72),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ฟังก์ชันแสดงหน้าต่างเพิ่มเมนูอาหาร
  void showAddMenuDialog(BuildContext context) {
    String name = '';
    String description = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('เพิ่มเมนูใหม่'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'ชื่อเมนู'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: InputDecoration(hintText: 'รายละเอียด'),
                onChanged: (value) => description = value,
              ),
              ElevatedButton(
                onPressed: pickImage, // ฟังก์ชันถ่ายรูป
                child: Text('ถ่ายรูปอาหาร'),
              ),
              if (_imageFile != null)
                Image.file(
                  _imageFile!,
                  width: 100,
                  height: 100,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                if (_imageFile != null) {
                  String imageUrl = await uploadImageToFirebase(_imageFile!); // อัปโหลดรูปและรับ URL
                  Map<String, dynamic> newItem = {
                    'name': name,
                    'description': description,
                    'imageUrl': imageUrl,
                    'quantity': 1,
                    'phoneNumber': phoneNumber // เก็บหมายเลขโทรศัพท์ผู้สร้างเมนู
                  };
                  addMenuItem(newItem); // เพิ่มเมนูอาหาร
                  Navigator.of(context).pop();
                }
              },
              child: Text('เพิ่มเมนู'),
            ),
          ],
        );
      },
    );
  }
}
