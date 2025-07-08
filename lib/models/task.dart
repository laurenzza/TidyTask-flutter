class Task {
  final int? id;
  final String title;
  final String? description;
  final bool isDone;
  final DateTime? deadline;

  Task({
    this.id,
    required this.title,
    this.description,
    this.isDone = false,
    this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone ? 1 : 0,
      'deadline': deadline?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isDone: map['isDone'] == 1,
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'])
          : null,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? isDone,
    DateTime? deadline,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      deadline: deadline ?? this.deadline,
    );
  }
}
