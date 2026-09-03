class Task {
  final String data;
  final String name;
  final int number;
  final bool done;

  Task({required this.data, required this.name, required this.number, required this.done});

  factory Task.fromJson(Map<dynamic, dynamic> json) {
    return Task(
      data: json['data'],
      name: json['name'],
      number: json['number'],
      done: json['done'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'name': name,
      'number': number,
      'done': done,
    };
  }
}

class User {
  final String password;
  final Map<String, Task> tasks;

  User({required this.password, required this.tasks});

  factory User.fromJson(Map<dynamic, dynamic> json) {
    var tasksFromJson = json['tasks'] as Map<dynamic, dynamic>;
    Map<String, Task> tasksMap = tasksFromJson.map((key, value) => MapEntry(key, Task.fromJson(value)));

    return User(
      password: json['password'],
      tasks: tasksMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'tasks': tasks.map((key, task) => MapEntry(key, task.toJson())),
    };
  }
}
