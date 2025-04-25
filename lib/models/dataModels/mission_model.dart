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
  final bool selected;
  final bool finished;
  final String assignedUser;
  final int progress;

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.difficulty,
    required this.requirements,
    required this.rewards,
    this.selected = false,
    this.finished = false,
    required this.assignedUser,
    this.progress = 0,
  });

  factory MissionModel.fromMap(Map<String, dynamic> map, String id) {
    return MissionModel(
      id: id,
      title: map['title'],
      description: map['description'],
      type: map['type'],
      category: map['category'],
      difficulty: map['difficulty'],
      requirements: Requirement.fromMap(map['requirements']),
      rewards: Reward.fromMap(map['rewards']),
      selected: map['selected'] ?? false,
      finished: map['finished'] ?? false,
      assignedUser: map['assignedUser'] ?? '',
      progress: map['progress'] ?? 0,
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
      'selected': selected,
      'finished': finished,
      'assignedUser': assignedUser,
      'progress': progress,
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
