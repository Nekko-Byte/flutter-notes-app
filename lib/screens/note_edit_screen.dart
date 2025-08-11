import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteEditScreen extends StatefulWidget {
  final Note? note;

  const NoteEditScreen({Key? key, this.note}) : super(key: key);

  @override
  _NoteEditScreenState createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedDate = widget.note?.date ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveNote() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите заголовок')),
      );
      return;
    }

    final updatedNote = Note(
      id: widget.note?.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      date: _selectedDate,
    );

    Navigator.of(context).pop(updatedNote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Создать заметку' : 'Редактировать заметку'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Заголовок'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Содержание'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Дата: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selectDate,
                  child: const Text('Выбрать дату'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Время: ${_selectedTime.format(context)}'),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selectTime,
                  child: const Text('Выбрать время'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
