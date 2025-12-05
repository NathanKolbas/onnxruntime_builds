import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// --- Linux / macOS Implementation (dladdr) ---
final class DlInfo extends Struct {
  external Pointer<Utf8> dli_fname; // Pathname of shared object
  external Pointer<Void> dli_fbase;
  external Pointer<Char> dli_sname;
  external Pointer<Void> dli_saddr;
}

@Native<Int32 Function(Pointer<Void>, Pointer<DlInfo>)>(symbol: 'dladdr')
external int _dladdr(Pointer<Void> addr, Pointer<DlInfo> info);

String? _getLibraryPathPosix(Pointer<Void> symbolAddress) {
  return using((arena) {
    final info = arena<DlInfo>();
    final result = _dladdr(symbolAddress, info);
    if (result == 0) return null;
    return info.ref.dli_fname.toDartString();
  });
}

// --- Windows Implementation (GetModuleHandleEx + GetModuleFileName) ---
// Constants for Windows API
const int GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS = 0x00000004;
const int GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT = 0x00000002;
const int MAX_PATH = 260; // A common value for max path length on Windows

@Native<Int32 Function(Uint32, Pointer<Void>, Pointer<IntPtr>)>(symbol: 'GetModuleHandleExW', isLeaf: true)
external int _GetModuleHandleEx(int dwFlags, Pointer<Void> lpModuleName, Pointer<IntPtr> phModule);

@Native<Int32 Function(IntPtr, Pointer<Utf16>, Int32)>(symbol: 'GetModuleFileNameW', isLeaf: true)
external int _GetModuleFileName(int hModule, Pointer<Utf16> lpFilename, int nSize);

String? _getLibraryPathWindows(Pointer<Void> symbolAddress) {
  return using((arena) {
    final phModule = arena<IntPtr>();
    // Get handle to the module that contains our function address
    final success = _GetModuleHandleEx(
      GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
      symbolAddress,
      phModule,
    );

    if (success == 0) return null;

    // Get the filename from the handle
    final buffer = arena.allocate<Uint16>(MAX_PATH).cast<Utf16>();
    final length = _GetModuleFileName(phModule.value, buffer, 1024);
    if (length == 0) return null;

    return buffer.toDartString();
  });
}

/// Main helper function
String getPathForSymbol(Pointer<NativeFunction> symbolAddress) {
  if (Platform.isWindows) {
    return _getLibraryPathWindows(symbolAddress.cast()) ?? '';
  } else {
    return _getLibraryPathPosix(symbolAddress.cast()) ?? '';
  }
}
