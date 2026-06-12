import 'package:hive/hive.dart';

class ResponseMapping {
  @HiveField(0)
  final String stdoutPath;

  @HiveField(1)
  final String stderrPath;

  @HiveField(2)
  final String errorPath;

  @HiveField(3)
  final String timePath;

  @HiveField(4)
  final String memoryPath;

  ResponseMapping({
    required this.stdoutPath,
    required this.stderrPath,
    required this.errorPath,
    required this.timePath,
    required this.memoryPath,
  });

  ResponseMapping copyWith({
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? timePath,
    String? memoryPath,
  }) {
    return ResponseMapping(
      stdoutPath: stdoutPath ?? this.stdoutPath,
      stderrPath: stderrPath ?? this.stderrPath,
      errorPath: errorPath ?? this.errorPath,
      timePath: timePath ?? this.timePath,
      memoryPath: memoryPath ?? this.memoryPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stdoutPath': stdoutPath,
      'stderrPath': stderrPath,
      'errorPath': errorPath,
      'timePath': timePath,
      'memoryPath': memoryPath,
    };
  }

  factory ResponseMapping.fromJson(Map<String, dynamic> json) {
    return ResponseMapping(
      stdoutPath: json['stdoutPath'] ?? '',
      stderrPath: json['stderrPath'] ?? '',
      errorPath: json['errorPath'] ?? '',
      timePath: json['timePath'] ?? '',
      memoryPath: json['memoryPath'] ?? '',
    );
  }
}

class ResponseMappingAdapter extends TypeAdapter<ResponseMapping> {
  @override
  final int typeId = 2;

  @override
  ResponseMapping read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResponseMapping(
      stdoutPath: fields[0] as String,
      stderrPath: fields[1] as String,
      errorPath: fields[2] as String,
      timePath: fields[3] as String,
      memoryPath: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ResponseMapping obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.stdoutPath)
      ..writeByte(1)
      ..write(obj.stderrPath)
      ..writeByte(2)
      ..write(obj.errorPath)
      ..writeByte(3)
      ..write(obj.timePath)
      ..writeByte(4)
      ..write(obj.memoryPath);
  }
}
