// Stub implementation of File and Platform for web platform
class File {
  final String path;
  File(this.path);

  bool existsSync() => false;
  Future<bool> exists() async => false;
  Future<int> length() async => 0;
  Future<List<int>> readAsBytes() async => [];
  Future<void> writeAsString(String contents) async {}
  Future<void> writeAsBytes(List<int> bytes) async {}
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
}

