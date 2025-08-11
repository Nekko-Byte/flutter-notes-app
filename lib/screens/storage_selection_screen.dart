import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageSelectionScreen extends StatefulWidget {
  @override
  _StorageSelectionScreenState createState() => _StorageSelectionScreenState();
}

class _StorageSelectionScreenState extends State<StorageSelectionScreen> {
  String? _selectedStorage;

  static const String storageKey = 'storage_method';

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedStorage = prefs.getString(storageKey);
    });
  }

  Future<void> _saveSelection(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, value);
    setState(() {
      _selectedStorage = value;
    });
    // Можно тут же переходить к списку заметок, передавая выбранный метод
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выберите способ хранения'),
      ),
      body: Column(
        children: [
          RadioListTile<String>(
            title: Text('SQLite (База данных)'),
            value: 'sqlite',
            groupValue: _selectedStorage,
            onChanged: (value) {
              if (value != null) _saveSelection(value);
            },
          ),
          RadioListTile<String>(
            title: Text('Файловое хранилище'),
            value: 'file',
            groupValue: _selectedStorage,
            onChanged: (value) {
              if (value != null) _saveSelection(value);
            },
          ),
          if (_selectedStorage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  // Навигация в NotesListScreen, передавая выбранный метод хранения
                  Navigator.pushReplacementNamed(context, '/notes', arguments: _selectedStorage);
                },
                child: Text('Продолжить'),
              ),
            )
        ],
      ),
    );
  }
}
