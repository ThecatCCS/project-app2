import 'package:flutter/material.dart';

class RiderLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize:
          MainAxisSize.min, // ทำให้ Column เล็กที่สุดเท่าที่จะเป็นไปได้
      children: [
        const SizedBox(height: 30),
        // Text type user
        Container(
          width: double.infinity,
          height: 40,
          color: Color.fromARGB(
              255, 75, 161, 72), // เปลี่ยนจาก backgroundColor เป็น color
          child: Center(
            child: Text(
              'Type : Rider',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
              // ปรับขนาดตัวอักษรและความหนา
            ),
          ),
        ),
        // Car Registration Tile
        ListTile(
          contentPadding: EdgeInsets.symmetric(
              horizontal: 10, vertical: 5), // ลดขนาด padding ภายใน
          leading: Icon(Icons.directions_car,
              size: 30,
              color: Color.fromARGB(255, 75, 161, 72)), // ปรับขนาดไอคอน
          title: Text(
            "Car Registration",
            style: TextStyle(fontSize: 16), // ลดขนาดตัวอักษร
          ),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color.fromARGB(255, 75, 161, 72)),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 10), // ลดระยะห่างระหว่าง widgets
        // Upload Section
        Container(
          height: 150, // ลดขนาดความสูงของ Container
          width: double.infinity, // ให้ Container ใช้ความกว้างเต็มที่
          decoration: BoxDecoration(
            border: Border.all(color: Color.fromARGB(255, 75, 161, 72)),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[300], // สีพื้นหลังของ Container
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file,
                    size: 40, color: Colors.grey), // ลดขนาดไอคอน
                const SizedBox(
                    height: 5), // ลดขนาดระยะห่างระหว่างไอคอนและข้อความ
                Text(
                  "Upload",
                  style: TextStyle(
                    fontSize: 16, // ลดขนาดตัวอักษร
                    color: Color.fromARGB(255, 75, 161, 72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
