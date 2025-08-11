import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../db/notes_database.dart'; // SQLite
import '../db/notes_file_storage.dart'; // Файловое хранение
import 'note_edit_screen.dart';

class NotesListScreen extends StatefulWidget {
  @override
  _NotesListScreenState createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Note> notes = [];
  String searchQuery = '';
  late String storageMethod; // 'sqlite' или 'file'
  bool _isLoading = true;

  // Фильтры
  bool filterByTitle = true;
  bool filterByContent = true;
  bool filterByDate = false;
  DateTime? filterDate;

  @override
  void initState() {
    super.initState();
    _loadStorageMethodAndNotes();
  }

  Future<void> _loadStorageMethodAndNotes() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    storageMethod = prefs.getString('storage_method') ?? 'sqlite';
    await _loadNotes();
    setState(() => _isLoading = false);
  }

  Future<void> _loadNotes() async {
    List<Note> all = [];
    if (storageMethod == 'sqlite') {
      all = await NotesDatabase.instance.readAllNotes();
    } else {
      all = await NotesFileStorage.readAllNotes();
    }
    // упорядочим по дате (свежие сверху)
    all.sort((a, b) => b.date.compareTo(a.date));
    setState(() => notes = all);
  }

  // Получить дату без времени (для сравнения)
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Формат dd.MM.yyyy HH:mm для текстового поиска
  String _dateTimeString(Note n) {
    final dt = n.date;
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  // Комбинированная фильтрация: сначала применяем фильтр по дате (если включён),
  // затем — текстовый поиск по заголовку/содержимому/дате/времени
  List<Note> get filteredNotes {
    List<Note> cur = List.from(notes);

    if (filterByDate && filterDate != null) {
      final f = _dateOnly(filterDate!);
      cur = cur.where((n) => _dateOnly(n.date) == f).toList();
    }

    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return cur;

    return cur.where((n) {
      final title = n.title.toLowerCase();
      final content = n.content.toLowerCase();
      final dateStr = _dateTimeString(n).toLowerCase();

      bool match = false;
      if (filterByTitle && title.contains(q)) match = true;
      if (filterByContent && content.contains(q)) match = true;
      if (dateStr.contains(q)) match = true; // поддерживает поиск dd.mm.yyyy и hh:mm

      return match;
    }).toList();
  }

  Future<void> _addOrEditNote({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditScreen(note: note)),
    );

    if (result != null && result is Note) {
      if (storageMethod == 'sqlite') {
        if (note != null) {
          await NotesDatabase.instance.update(result);
        } else {
          final created = await NotesDatabase.instance.create(result);
          // created содержит id из БД
        }
      } else {
        if (note != null) {
          await NotesFileStorage.update(result);
        } else {
          await NotesFileStorage.create(result);
        }
      }
      await _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить заметку?'),
        content: Text('Вы уверены, что хотите удалить заметку "${note.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Удалить')),
        ],
      ),
    );

    if (confirmed != true) return;

    if (storageMethod == 'sqlite') {
      if (note.id != null) await NotesDatabase.instance.delete(note.id!);
    } else {
      if (note.id != null) {
        await NotesFileStorage.delete(note.id!);
      } else {
        // НАДЁЖНО: если id вдруг нет, удалим конкретный объект
        notes.remove(note);
        await NotesFileStorage.writeAllNotes(notes);
      }
    }
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Заметки')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск (заголовок, содержание, dd.MM.yyyy или HH:mm)...',
              hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black45),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            style:
            TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
            cursorColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            onChanged: (v) => setState(() => searchQuery = v),
          ),
        ),
        // можно показать маленький текст с текущим storageMethod
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(18),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              'Хранилище: ${storageMethod == 'sqlite' ? 'SQLite' : 'Файл'}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text('Заголовок'),
                        selected: filterByTitle,
                        onSelected: (v) => setState(() => filterByTitle = v),
                      ),
                      FilterChip(
                        label: Text('Содержание'),
                        selected: filterByContent,
                        onSelected: (v) => setState(() => filterByContent = v),
                      ),
                      FilterChip(
                        label: Text(filterByDate && filterDate != null
                            ? 'Дата: ${filterDate!.day.toString().padLeft(2, '0')}.${filterDate!.month.toString().padLeft(2, '0')}.${filterDate!.year}'
                            : 'Фильтр по дате'),
                        selected: filterByDate,
                        onSelected: (v) async {
                          if (v) {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: filterDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() {
                              filterDate = picked;
                              filterByDate = true;
                            });
                          } else {
                            setState(() {
                              filterByDate = false;
                              filterDate = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (filterByDate)
                  IconButton(
                    icon: Icon(Icons.clear),
                    tooltip: 'Сбросить фильтр по дате',
                    onPressed: () => setState(() {
                      filterByDate = false;
                      filterDate = null;
                    }),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(child: Text('Нет заметок'))
                : ListView.builder(
              itemCount: filteredNotes.length,
              itemBuilder: (context, i) {
                final n = filteredNotes[i];
                return ListTile(
                  title: Text(n.title),
                  subtitle: Text('${_dateOnly(n.date).toLocal().toString().split(' ')[0]} ${n.date.hour.toString().padLeft(2,'0')}:${n.date.minute.toString().padLeft(2,'0')}'),
                  onTap: () => _addOrEditNote(note: n),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteNote(n),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _addOrEditNote(),
      ),
    );
  }
}
