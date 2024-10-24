import 'package:firebase_image_upload/pages/orderdetail.dart';
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

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  String phoneNumber = '';
  String orderSearchQuery = ''; // For filtering orders by phone number
  late TabController _tabController;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> orders = [];
  File? _menuImageFile;
  File? _orderImageFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadPhoneNumber();
  }

  void loadPhoneNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phone') ?? '';
    });
    if (phoneNumber.isNotEmpty) {
      fetchMenuItems();
      fetchOrders();
    }
  }

  void fetchMenuItems() async {
    final snapshot = await _database.child('menuItems').get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> fetchedItems = [];
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        Map<String, dynamic> item = Map<String, dynamic>.from(value);
        item['id'] = key;
        if (item['phoneNumber'] == phoneNumber) {
          fetchedItems.add(item);
        }
      });
      setState(() {
        menuItems = fetchedItems;
      });
    }
  }

  void fetchOrders() async {
    final snapshot = await _database.child('orders').get();
    if (snapshot.exists) {
      List<Map<String, dynamic>> fetchedOrders = [];
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        Map<String, dynamic> order = Map<String, dynamic>.from(value);
        order['id'] = key;
        if (order['seller'] == phoneNumber) {
          fetchedOrders.add(order);
        }
      });
      setState(() {
        orders = fetchedOrders;
      });
    }
  }

  Future<String> uploadMenuImageToFirebase(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('menuImages/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception("Failed to upload menu image: $e");
    }
  }

  Future<void> pickMenuImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      _menuImageFile = File(pickedFile!.path);
    });
  }

  void deleteMenuItem(String id) async {
    await _database.child('menuItems/$id').remove();
    fetchMenuItems();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เมนูลบเรียบร้อยแล้ว!')),
    );
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
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'อาหาร'),
            Tab(text: 'ออเดอร์'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
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
    List<Map<String, dynamic>> filteredItems = menuItems
        .where((item) =>
            item['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            item['description'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
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
                      searchQuery = value;
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
                              deleteMenuItem(item['id']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
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

 Widget buildOrderSummary() {
  List<Map<String, dynamic>> filteredOrders = orders
      .where((order) =>
          order['buyer'].toLowerCase().contains(orderSearchQuery.toLowerCase()))
      .toList();

  if (filteredOrders.isEmpty) {
    return Center(child: Text('ไม่มีออเดอร์ที่เกี่ยวข้อง'));
  }

  return Column(
    children: [
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
                    orderSearchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ค้นหาออเดอร์ตามเบอร์โทร',
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
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order['name'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 75, 161, 72),
                          ),
                        ),
                        Icon(
                          Icons.fastfood,
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
                        Icon(Icons.phone, color: Colors.grey),
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

                    // ปุ่มสำหรับเปลี่ยนสถานะและอัพโหลดรูป เมื่อสถานะคือ "กำลังทำอาหาร"
                    if (order['status'] == 'กำลังทำอาหาร') ...[
                      ElevatedButton.icon(
                        onPressed: () async {
                          await pickNewImage();
                          if (_orderImageFile != null) {
                            updateOrderStatus(order['id'], 'รอไรเดอร์รับงาน');
                          }
                        },
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        label: Text('อัพโหลดรูปและเปลี่ยนสถานะ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 75, 161, 72),
                        ),
                      ),
                    ],

                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderChatPage(orderId: order['id']),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 75, 161, 72),
                      ),
                      child: Text('ดูรายละเอียด'),
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
                onPressed: pickMenuImage,
                child: Text('ถ่ายรูปอาหาร'),
              ),
              if (_menuImageFile != null)
                Image.file(
                  _menuImageFile!,
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
                if (_menuImageFile != null) {
                  String imageUrl = await uploadMenuImageToFirebase(_menuImageFile!);
                  Map<String, dynamic> newItem = {
                    'name': name,
                    'description': description,
                    'imageUrl': imageUrl,
                    'quantity': 1,
                    'phoneNumber': phoneNumber
                  };
                  addMenuItem(newItem);
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

  void addMenuItem(Map<String, dynamic> newItem) async {
    try {
      await _database.child('menuItems').push().set(newItem);
      fetchMenuItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่มเมนูสำเร็จ!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่มเมนู: $e')),
      );
    }
  }
  void updateOrderStatus(String orderId, String newStatus) async {
  try {
    String? imageUrl;

    // Upload a new image if one has been selected
    if (_orderImageFile != null) {
      imageUrl = await uploadNewImageToFirebase(_orderImageFile!);
    }

    // Update the order status and imageUrl in the Firebase database
    await _database.child('orders/$orderId').update({
      'status': newStatus,
      if (imageUrl != null) 'imageUrl1': imageUrl, // Update imageUrl if it exists
    });

    // Fetch updated orders list to refresh UI
    fetchOrders();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('สถานะออเดอร์อัพเดตสำเร็จ!')),
    );
  } catch (e) {
    // Show error message if something goes wrong
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
    );
    print('Error updating order status: $e');
  }
}
// Upload image to Firebase and return its download URL
Future<String> uploadNewImageToFirebase(File imageFile) async {
  try {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference firebaseStorageRef = FirebaseStorage.instance.ref().child('orderImages/$fileName');
    UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    throw Exception("Failed to upload order image: $e");
  }
}
// Pick a new image for order status
Future<void> pickNewImage() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
  if (pickedFile != null) {
    setState(() {
      _orderImageFile = File(pickedFile.path);
    });
  }
}

}
