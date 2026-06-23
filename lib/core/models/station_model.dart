class StationModel {
  const StationModel({required this.id, required this.name});

  final String id;
  final String name;

  factory StationModel.fromJson(Map<String, dynamic> json) => StationModel(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}
