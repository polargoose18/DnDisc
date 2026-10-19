import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _SetEnvNative = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _SetEnv = int Function(Pointer<Utf8>, Pointer<Utf8>, int);
typedef _UnsetEnvNative = Int32 Function(Pointer<Utf8>);
typedef _UnsetEnv = int Function(Pointer<Utf8>);

/// Sets (or with null removes) a variable of this process, so native
/// libraries loaded later read it (`Platform.environment` is read-only).
/// POSIX only.
void setProcessEnvironment(String name, String? value) {
  final lib = DynamicLibrary.process();
  final key = name.toNativeUtf8();
  try {
    if (value == null) {
      lib.lookupFunction<_UnsetEnvNative, _UnsetEnv>('unsetenv')(key);
    } else {
      final val = value.toNativeUtf8();
      try {
        lib.lookupFunction<_SetEnvNative, _SetEnv>('setenv')(key, val, 1);
      } finally {
        malloc.free(val);
      }
    }
  } finally {
    malloc.free(key);
  }
}
