class TableConfig {
  TableConfig({
    required this.name,
    required this.id,
    List<String>? filter,
    this.n = 5,
  }) : filter = filter ?? [];

  String name;
  String id;
  List<String> filter;
  int n;

  factory TableConfig.fromJson(Map<String, dynamic> json) => TableConfig(
    name: json['name'] as String,
    id: json['id'] as String,
    n: (json['n'] as num?)?.toInt() ?? 5,
    filter: ((json['filter'] as List?) ?? const [])
        .whereType<String>()
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
    'filter': filter,
    'n': n,
  };
}
