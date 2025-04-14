import 'package:blindmate/views/UIComponents/crystal_box.dart';
import 'package:blindmate/views/UIComponents/custom_button.dart';
import 'package:blindmate/views/screens/redeem_reward_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/dataModels/user_model.dart';

class DoMissionScreen extends StatefulWidget {
final UserModel user;

  const DoMissionScreen({super.key, required this.user});

  @override
  _DoMissionScreenState createState() => _DoMissionScreenState();

  static Future<UserModel?> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return null;
  }
}

class _DoMissionScreenState extends State<DoMissionScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await DoMissionScreen.fetchUserData();
    setState(() {
      _currentUser = user;
    });
  }

  // Widget _buildMissionField(String missionName) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Text(
  //       //   "Ongoing Mission Progress",
  //       //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //       // ),
  //       Text(
  //         missionName,
  //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //       ),
  //       SizedBox(height: 8),
  //       Container(
  //         height: 20,
  //         decoration: BoxDecoration(
  //           color: Color(0xFF8FC3D3),
  //           borderRadius: BorderRadius.circular(20.0),
  //           border: Border.all(color: Color.fromRGBO(237, 233, 247, 0.69), width: 1.0),
  //         ),
  //       )
  //     ],
  //   );
  // }

  Widget _buildMissionField(String missionName) {
    return Container(
      padding: EdgeInsets.all(12.0),
      margin: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD9D9D9),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            missionName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Color(0xFF8FC3D3),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: Color.fromRGBO(237, 233, 247, 0.69),
                width: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(
          top: 40.0,
          left: 16.0,
          right: 16.0,
          bottom: 16.0,
        ),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 48),
            buildCrystalBox('111'),
            SizedBox(height: 24),

            Center(
              child: Column(
                children: [
                  Text(
                    "Current Mission",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "No mission selected currently",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            SizedBox(height: 60),

            Text(
              "Daily Mission",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 20),
            _buildMissionField('Mission 1'),
            SizedBox(height: 25),
            // _buildMissionField('Mission 2'),
            // SizedBox(height: 20),
            // _buildMissionField('Mission 3'),
            CustomButton(text: "reward", onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RedeemRewardScreen(user: widget.user)),
    );
  },)
          ],
        ),
      ),
    );
  }
}
