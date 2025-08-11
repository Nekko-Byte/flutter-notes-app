import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

class NotesFileStorage {
  static const String _fileName = 'notes.json';

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_fileName';
    return File(path);
  }

  // Читает все заметки (возвращает пустой список, если файла нет или parse упал)
  static Future<List<Note>> readAllNotes() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final content = await f.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) {
        if (e is Map<String, dynamic>) return Note.fromMap(e);
        return Note.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Записать весь список в файл
  static Future<void> writeAllNotes(List<Note> notes) async {
    final f = await _file();
    final jsonList = notes.map((n) => n.toMap()).toList();
    await f.writeAsString(jsonEncode(jsonList));
  }

  // Создать новую заметку: присвоить id и вернуть заметку с id
  static Future<Note> create(Note note) async {
    final all = await readAllNotes();
    final newId = DateTime.now().millisecondsSinceEpoch;
    final newNote = note.copyWith(id: newId);
    all.add(newNote);
    await writeAllNotes(all);
    return newNote;
  }

  // Обновить существующую заметку (по id)
  static Future<void> update(Note note) async {
    if (note.id == null) return;
    final all = await readAllNotes();
    final idx = all.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      all[idx] = note;
      await writeAllNotes(all);
    }
  }

  // Удалить заметку по id
  static Future<void> delete(int id) async {
    final all = await readAllNotes();
    all.removeWhere((n) => n.id == id);
    await writeAllNotes(all);
  }
}
