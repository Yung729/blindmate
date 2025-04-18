import 'package:blindmate/models/dataModels/reply_model.dart';
import 'package:blindmate/models/dataModels/bottle_note_model.dart';
import 'package:flutter/material.dart';

class BottleNoteState extends ChangeNotifier {
  List<BottleNote> _notes = [];
  List<Reply> _replies = [];
  BottleNote? _pickedNote;
  String? _lastNoteStatus;

  List<BottleNote> get notes => _notes;
  BottleNote? get pickedNote => _pickedNote;
  List<Reply> get replies => _replies;
  String? get lastNoteStatus => _lastNoteStatus;

  void setNotes(List<BottleNote> notes) {
    _notes = notes;
    notifyListeners();
  }

  void setPickedNote(BottleNote? note) {
    _pickedNote = note;
    notifyListeners();
  }

  void setReplies(List<Reply> replies) {
    _replies = replies;
    notifyListeners();
  }

  void setLastNoteStatus(String status) {
    _lastNoteStatus = status;
    notifyListeners();
  }

  void clearPickedNote() {
    _pickedNote = null;
    notifyListeners();
  }

  void clear() {
    _notes = [];
    _replies = [];
    _pickedNote = null;
    _lastNoteStatus = '';
    notifyListeners();
  }
}
