import 'stop_ref.dart';

class TableConfig {
  TableConfig({
    required this.name,
    required this.id,
    List<StopRef>? filter,
    this.n = 5,
  }) : filter = filter ?? [];

  String name;
  String id;
  List<StopRef> filter;
  int n;

  factory TableConfig.fromJson(Map<String, dynamic> json) => TableConfig(
    name: json['name'] as String,
    id: json['id'] as String,
    n: (json['n'] as num?)?.toInt() ?? 5,
    filter: ((json['filter'] as List?) ?? const [])
        .map((e) => StopRef.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
    'filter': filter.map((e) => e.toJson()).toList(),
    'n': n,
  };
}
