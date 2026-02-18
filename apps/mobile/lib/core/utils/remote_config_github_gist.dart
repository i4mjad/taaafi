import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_app_3/core/network/dio_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_github_gist.g.dart';

class RemoteConfigGistData {
  RemoteConfigGistData({required this.requiredVersion});
  final String requiredVersion;

  factory RemoteConfigGistData.fromJson(Map<String, dynamic> json) {
    final requiredVersion = json['config']?['required_version'];
    if (requiredVersion == null) {
      throw FormatException('required_version not found in JSON: $json');
    }
    return RemoteConfigGistData(requiredVersion: requiredVersion);
  }
}

/// An API client class for fetching a remote config JSON from a GitHub gist
class RemoteConfigGistClient {
  const RemoteConfigGistClient({required this.dio});
  final Dio dio;

  /// Fetch the remote config JSON
  Future<RemoteConfigGistData> fetchRemoteConfig() async {
    const owner = 'i4mjad';
    final gistId = "fa7c8029ff0dfbaf262f330eddb8aa35";
    final fileName = 'taaafi_platform_remote_config.json';
    final url =
        'https://gist.githubusercontent.com/$owner/$gistId/raw/$fileName';
    final response = await dio.get(url);
    final jsonData = jsonDecode(response.data);
    var remoteConfigGistData = RemoteConfigGistData.fromJson(jsonData);
    print(remoteConfigGistData.requiredVersion);
    return remoteConfigGistData;
  }
}

@Riverpod(keepAlive: true)
RemoteConfigGistClient remoteConfigGistClient(Ref ref) {
  final dio = ref.watch(dioProvider);
  return RemoteConfigGistClient(dio: dio);
}
