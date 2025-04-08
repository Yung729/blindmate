import '../../models/dataModels/bottle_note_model.dart';
import 'package:flutter/material.dart';

class BottleNoteState extends ChangeNotifier {
  List<BottleNote> _notes = [];
  BottleNote? _pickedNote;

  List<BottleNote> get notes => _notes;
  BottleNote? get pickedNote => _pickedNote;

  void setNotes(List<BottleNote> notes) {
    _notes = notes;
    notifyListeners();
  }

  void setPickedNote(BottleNote? note) {
    _pickedNote = note;
    notifyListeners();
  }

  void clearPickedNote() {
    _pickedNote = null;
    notifyListeners();
  }
}
