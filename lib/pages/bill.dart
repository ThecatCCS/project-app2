import 'package:firebase_image_upload/pages/nav.dart';
import 'package:flutter/material.dart';


class BillPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // สีพื้นหลัง
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ไอคอนเครื่องหมายถูก
            Container(
              margin: EdgeInsets.only(bottom: 80),
              child: Icon(
                Icons.check_circle,
                size: 200,
                color: Colors.white, // สีไอคอน
              ),
            ),
            // ข้อความสำคัญ
            Text(
              'สั่งซื้อสินค้าสำเร็จ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            // ข้อมูลการสั่งซื้อ
            _buildOrderDetail('ชื่อสินค้า', 'Sandwich'),
            _buildOrderDetail('จำนวน', 'x10'),
            _buildOrderDetail('ชื่อผู้สั่ง', 'kawee'),
            _buildOrderDetail('สถานที่ส่ง', '65/12 ท่าขอนยาง'),
            SizedBox(height: 120),
            // ปุ่มกลับไปหน้าหมายเลขการสั่งซื้อ
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NavPage(userType: 'customer',)),
                      ); // กลับไปหน้าก่อนหน้า
              },
              child: Text('กลับไปหน้ารายการสินค้า',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.green,// สีข้อความของปุ่ม
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // มุมโค้ง
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
