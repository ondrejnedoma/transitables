class StopRef {
  const StopRef({required this.id, required this.name});

  final String id;
  final String name;

  factory StopRef.fromJson(Map<String, dynamic> json) =>
      StopRef(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
