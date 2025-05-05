import 'package:cloud_firestore/cloud_firestore.dart';

class MissionModel {
  final String id;
  final String title;
  final String description;
  final String type; // "time" or "action"
  final String category; // "chat", "post", or "note"
  final String difficulty; // "easy", "medium", "hard"
  final Requirement requirements;
  final Reward rewards;
  final bool status;
  final bool finished;
  final String assignedUser;
  final int progress;
  final Timestamp createdAt;

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.difficulty,
    required this.requirements,
    required this.rewards,
    this.status = false,
    this.finished = false,
    required this.assignedUser,
    this.progress = 0,
    required this.createdAt,
  });

  factory MissionModel.fromMap(Map<String, dynamic> map, String id) {
    var createdAtValue = map['createdAt'];
    Timestamp createdAt;
    
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue;
    } else if (createdAtValue is DateTime) {
      createdAt = Timestamp.fromDate(createdAtValue);
    } else if (createdAtValue == null) {
      print("Warning: createdAt is null for mission $id, using current timestamp");
      createdAt = Timestamp.now();
    } else {
      print("Warning: unexpected createdAt type for mission $id: ${createdAtValue.runtimeType}");
      createdAt = Timestamp.now();
    }
    
    return MissionModel(
      id: id,
      title: map['title'] ?? 'Untitled Mission',
      description: map['description'] ?? 'No description',
      type: map['type'] ?? 'action',
      category: map['category'] ?? 'misc',
      difficulty: map['difficulty'] ?? 'easy',
      requirements: map['requirements'] != null 
          ? Requirement.fromMap(map['requirements']) 
          : Requirement(metric: 'count', target: 1),
      rewards: map['rewards'] != null 
          ? Reward.fromMap(map['rewards']) 
          : Reward(xp: 10),
      status: map['status'] ?? true,
      finished: map['finished'] ?? false,
      assignedUser: map['assignedUser'] ?? '',
      progress: map['progress'] ?? 0,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'difficulty': difficulty,
      'requirements': requirements.toMap(),
      'rewards': rewards.toMap(),
      'status': status,
      'finished': finished,
      'assignedUser': assignedUser,
      'progress': progress,
      'createdAt': createdAt,
    };
  }

  /// Fetch a mission from Firestore by its ID
  static Future<MissionModel?> fetchById(String id) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('mission')
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        return MissionModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      } else {
        return null; // Return null if the document doesn't exist
      }
    } catch (e) {
      print('Error fetching mission by ID: $e');
      return null;
    }
  }

  /// Fetch all missions from Firebase
  static Future<List<MissionModel>> fetchAll({int limit = 3}) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('mission')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => MissionModel.fromMap(doc.data(), doc.id)) // Map docs to MissionModel
          .toList();
    } catch (e) {
      print('Error fetching missions: $e');
      return [];
    }
  }
}

class Requirement {
  final String metric;
  final int target;
  final int? timeLimit;

  Requirement({
    required this.metric,
    required this.target,
    this.timeLimit,
  });

  factory Requirement.fromMap(Map<String, dynamic> map) {
    return Requirement(
      metric: map['metric'],
      target: map['target'],
      timeLimit: map['timeLimit'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'metric': metric,
      'target': target,
      'timeLimit': timeLimit,
    };
  }
}

class Reward {
  final int xp;

  Reward({required this.xp});

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(xp: map['xp']);
  }

  Map<String, dynamic> toMap() {
    return {'xp': xp};
  }
}
