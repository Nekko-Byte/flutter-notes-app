class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime date;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    // id может быть int или String
    final rawId = map['id'];
    int? id;
    if (rawId is int) id = rawId;
    else if (rawId is String) id = int.tryParse(rawId);

    // дата может быть DateTime, int (ms) или String (ISO)
    final rawDate = map['date'];
    DateTime parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Note(
      id: id,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      date: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'content': content,
      // сохраняем ISO-строкой (универсально для sqlite и json)
      'date': date.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? date,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
    );
  }
}
