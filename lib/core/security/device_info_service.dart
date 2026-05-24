import 'dart:developer' as developer;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'secure_storage_service.dart';

/// Obtém/persiste o `device_id` enviado ao backend no header `X-Device-Id`.
///
/// Estratégia: UUID v4 gerado UMA vez, salvo em SecureStorage. Em iOS o
/// Keychain sobrevive a reinstalações; em Android com `encryptedSharedPreferences`
/// reseta no uninstall — comportamento aceitável para nosso caso.
class DeviceInfoService {
  DeviceInfoService(this._storage);

  final SecureStorageService _storage;

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.readDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _storage.saveDeviceId(id);
    return id;
  }

  Future<String> describeDevice() async {
    final info = DeviceInfoPlugin();
    try {
      final android = await info.androidInfo;
      return 'Android ${android.version.release} · ${android.manufacturer} ${android.model}';
    } catch (e, st) {
      developer.log('androidInfo falhou', name: 'DeviceInfoService', error: e, stackTrace: st);
      try {
        final ios = await info.iosInfo;
        return 'iOS ${ios.systemVersion} · ${ios.utsname.machine}';
      } catch (e2, st2) {
        developer.log('iosInfo falhou', name: 'DeviceInfoService', error: e2, stackTrace: st2);
        return 'unknown-device';
      }
    }
  }
}
