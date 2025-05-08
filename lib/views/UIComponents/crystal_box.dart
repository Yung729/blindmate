import 'package:flutter/material.dart';

Widget buildCrystalBox(String text) {
    return Align(
      alignment: Alignment.topRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image.asset('assets/crystal.png', height: 50), // Add your crystal image asset here
          SizedBox(width: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xB3D3D8DA),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Color(0XFF53B4D2), width: 2.0),
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }