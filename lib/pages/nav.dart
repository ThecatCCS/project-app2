import 'package:firebase_image_upload/pages/cart.dart';
import 'package:firebase_image_upload/pages/menu.dart';
import 'package:firebase_image_upload/pages/order.dart';
import 'package:firebase_image_upload/pages/profile.dart';
import 'package:firebase_image_upload/pages/rider/orderstatus.dart';
import 'package:firebase_image_upload/pages/rider/riderOrder.dart';
import 'package:firebase_image_upload/pages/rider/riderprofile.dart';
import 'package:flutter/material.dart';


class NavPage extends StatefulWidget {
  final String userType; // รับค่า userType

  NavPage({required this.userType}); // กำหนดค่า userType ผ่าน constructor

  @override
  _NavPageState createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> {
  int _selectedIndex = 0;

  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    print('User type: ${widget.userType}'); // ตรวจสอบค่า userType
    // เช็ค userType เพื่อแสดงหน้าและไอคอนต่างกัน
    if (widget.userType == 'user') {
      print('Loading customer pages');
      try {
        // ตรวจสอบว่าแต่ละหน้าได้รับการสร้างอย่างถูกต้องหรือไม่
        _pages = [
          MenuPage(),  // หน้าที่ 1
          OrderPage(), // หน้าที่ 2
          CartPage(),  // หน้าที่ 3
          ProfilePage(), // หน้าที่ 4
        ];

        _navItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '', // ลบ label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: '', // ลบ label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: '', // ลบ label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '', // ลบ label
          ),
        ];
      } catch (e) {
        print('Error loading customer pages: $e');
      }
    } else if (widget.userType == 'rider') {
      print('Loading rider pages');
      try {
        _pages = [
          RiderorderPage(),  // หน้าที่ 1
          OrderstatusPage(), // หน้าที่ 2
          RiderProfilePage(), // หน้าที่ 3
        ];

        _navItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '', // ลบ label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: '', // ลบ label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '', // ลบ label
          ),
        ];
      } catch (e) {
        print('Error loading rider pages: $e');
      }
    } else {
      // ถ้า userType ไม่ถูกต้อง
      _pages = [
        Center(child: Text('Invalid user type')),
      ];
      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.error),
          label: 'Error',
        ),
      ];
    }
    print('Nav items length: ${_navItems.length}');
    print('Pages length: ${_pages.length}');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // อัปเดต index ของหน้าที่เลือก
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.isNotEmpty
          ? _pages[_selectedIndex] // แสดงหน้าเลือกตาม userType
          : Center(child: Text('No pages available')),
      bottomNavigationBar: _navItems.isNotEmpty
          ? Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: BottomNavigationBar(
                backgroundColor: const Color.fromARGB(255, 75, 161, 72), // เปลี่ยนสีพื้นหลังเป็นสีเขียว
                items: _navItems, // แสดงไอคอนตาม userType
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.white, // สีไอคอนและตัวหนังสือเมื่อเลือก
                unselectedItemColor: Colors.black, // สีไอคอนและตัวหนังสือเมื่อไม่เลือก
                onTap: _onItemTapped, // ฟังก์ชันที่ถูกเรียกเมื่อกดไอคอน
                type: BottomNavigationBarType.fixed, // ชนิดของ BottomNavigationBar
                selectedFontSize: 0, // ลบขนาดฟอนต์ของข้อความที่เลือก
                unselectedFontSize: 0, // ลบขนาดฟอนต์ของข้อความที่ไม่เลือก
              ),
            )
          : null, // กรณี _navItems ไม่มีค่า
    );
  }
}
