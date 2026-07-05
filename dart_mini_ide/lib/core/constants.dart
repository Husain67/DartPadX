class AppConstants {
  static const String appName = 'DartMini';

  static const String defaultMainContent = '''
void main() {
  print('Welcome to DartMini IDE!');

  // Try writing some code here
  final list = [1, 2, 3, 4, 5];
  final sum = list.fold(0, (prev, element) => prev + element);

  print('Sum of list is \$sum');
}
''';

  static const String hiveFileBox = 'dartmini_files';
  static const String hivePresetBox = 'dartmini_presets';

  static const String defaultOneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String defaultOneCompilerKey = String.fromEnvironment('API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');
  static const String rapidApiHost = 'onecompiler-apis.p.rapidapi.com';

  static const Map<String, String> defaultHeaders = {
    'X-RapidAPI-Key': defaultOneCompilerKey,
    'X-RapidAPI-Host': rapidApiHost,
    'Content-Type': 'application/json',
  };
}
