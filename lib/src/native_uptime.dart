import 'dart:ffi';
import 'dart:io';

typedef _NativeUptime = Int64 Function();
typedef _DartUptime = int Function();

class UptimeFFI {
  late final _DartUptime _getUptime;

  UptimeFFI() {
    final dylib = _loadLibrary();
    _getUptime = dylib
        .lookup<NativeFunction<_NativeUptime>>('getUptimeMillis')
        .asFunction();
  }

  int getUptimeMillis() => _getUptime();

  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libuptime.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }
}
