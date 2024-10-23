import 'package:flutter/material.dart';

class CustomerLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // จำกัดขนาด Column ให้เล็กที่สุดเท่าที่จะสามารถทำได้
      children: [
        const SizedBox(height: 30),
        // Text type user
        Container(
  width: double.infinity,
  height: 40,
  color: Color.fromARGB(255, 75, 161, 72), // เปลี่ยนจาก backgroundColor เป็น color
  child: Center(
    child: Text(
      'Type : User',
      style: TextStyle(
        fontSize: 20,
        color: Colors.white,
      ),
      // ปรับขนาดตัวอักษรและความหนา
    ),
  ),
),
        const SizedBox(height: 10),
        // Address Tile
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // ปรับขนาด padding ภายใน ListTile
          leading: Icon(Icons.home, size: 30, color: Color.fromARGB(255, 75, 161, 72)), // ปรับขนาดไอคอน
          title: Text(
            "Address",
            style: TextStyle(fontSize: 16), // ปรับขนาดตัวอักษร
          ),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color.fromARGB(255, 75, 161, 72)),
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // Coordinates Tile
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          title: Row(
            children: [
              Icon(Icons.location_on, size: 30, color: Color.fromARGB(255, 75, 161, 72)),
              Text(
                "   Coordinates",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8), // ระยะห่างระหว่างข้อความและไอคอน
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // จัดข้อความให้อยู่ทางซ้าย
            children: [
              const SizedBox(height: 8), // ระยะห่างระหว่างข้อความและรูปภาพ
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  "https://via.placeholder.com/150",
                  height: 200, // ปรับความสูงของรูปภาพ
                  width: double.infinity, // ปรับความกว้างของรูปภาพ
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color.fromARGB(255, 75, 161, 72)),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
