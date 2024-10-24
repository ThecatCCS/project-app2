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
                return GestureDetector(
                  onTap: () {
                    // เมื่อกดที่รายการออเดอร์ นำทางไปยังหน้า OrderDetailsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsPage(order: item), // ส่งข้อมูลออเดอร์ไปที่หน้าแสดงรายละเอียด
                      ),
                    );
                  },
                  child: Card(
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

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  String? sellerName;
  String? sellerPhone;
  String? sellerImageUrl;
  String? sellerAddress;

  String? buyerName;
  String? buyerPhone;
  String? buyerImageUrl;
  String? buyerAddress;

  final DatabaseReference _database = FirebaseDatabase.instance.ref(); // Firebase reference
  bool isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    fetchSellerAndBuyerDetails();
  }

  Future<void> fetchSellerAndBuyerDetails() async {
    final sellerPhone = widget.order['seller'];
    final buyerPhone = widget.order['buyer'];

    if (sellerPhone != null && sellerPhone.isNotEmpty) {
      final sellerSnapshot = await _database.child('users/$sellerPhone').get();
      if (sellerSnapshot.exists) {
        Map<String, dynamic> sellerData = Map<String, dynamic>.from(sellerSnapshot.value as Map);
        setState(() {
          sellerName = sellerData['name'];
          this.sellerPhone = sellerPhone;
          sellerImageUrl = sellerData['imageUrl'];
          sellerAddress = sellerData['address'];
          isLoading = false; // Stop loading when data is fetched
        });
      } else {
        print('Seller data not found for phone: $sellerPhone');
        setState(() => isLoading = false); // Stop loading
      }
    }

    if (buyerPhone != null && buyerPhone.isNotEmpty) {
      final buyerSnapshot = await _database.child('users/$buyerPhone').get();
      if (buyerSnapshot.exists) {
        Map<String, dynamic> buyerData = Map<String, dynamic>.from(buyerSnapshot.value as Map);
        setState(() {
          buyerName = buyerData['name'];
          this.buyerPhone = buyerPhone;
          buyerImageUrl = buyerData['imageUrl'];
          buyerAddress = buyerData['address'];
          isLoading = false; // Stop loading when data is fetched
        });
      } else {
        print('Buyer data not found for phone: $buyerPhone');
        setState(() => isLoading = false); // Stop loading
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดออเดอร์'),
        backgroundColor: Color.fromARGB(255, 75, 161, 72),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu image
                  if (widget.order['imageUrl'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(widget.order['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                  SizedBox(height: 20),

                  // Menu name
                  _buildMenuInfo(),
                  SizedBox(height: 20),

                  // Seller information
                  _buildUserInfoCard('ข้อมูลผู้ขาย', sellerImageUrl, sellerName, sellerPhone, sellerAddress),
                  SizedBox(height: 20),

                  // Buyer information
                  _buildUserInfoCard('ข้อมูลผู้ซื้อ', buyerImageUrl, buyerName, buyerPhone, buyerAddress),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ชื่อเมนู: ${widget.order['name']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'รายละเอียด: ${widget.order['description']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'จำนวน: ${widget.order['quantity']}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(String title, String? imageUrl, String? name, String? phone, String? address) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (imageUrl != null)
                  ClipOval(
                    child: Image.network(
                      imageUrl,
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('ชื่อ: ${name ?? 'ไม่ระบุ'}', style: TextStyle(fontSize: 16)),
                      Text('เบอร์: ${phone ?? 'ไม่ระบุ'}', style: TextStyle(fontSize: 16)),
                      Text('ที่อยู่: ${address ?? 'ไม่ระบุ'}', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}