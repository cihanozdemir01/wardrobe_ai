import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class AppUpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isUpdateAvailable;

  AppUpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isUpdateAvailable,
  });
}

class UpdateService {
  // CONFIGURATION: Set your GitHub username and repository name here
  static const String githubUser = 'cihanozdemir01'; 
  static const String githubRepo = 'wardrobe_ai';
  
  // Current version of the app installed locally
  static const String currentVersion = 'v1.1.2';

  /// Checks if a newer release is available on GitHub
  static Future<AppUpdateInfo> checkForUpdates({String? token}) async {
    try {
      final url = 'https://api.github.com/repos/$githubUser/$githubRepo/releases/latest';
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestTag = data['tag_name'] as String? ?? 'v1.0.0';
        final body = data['body'] as String? ?? '';
        
        // Find APK asset
        String downloadUrl = '';
        final assets = data['assets'] as List? ?? [];
        if (assets.isNotEmpty) {
          final apkAsset = assets.firstWhere(
            (a) => (a['name'] as String).endsWith('.apk'),
            orElse: () => assets.first,
          );
          downloadUrl = apkAsset['browser_download_url'] ?? '';
        }

        final updateAvailable = _isNewerVersion(latestTag, currentVersion);

        return AppUpdateInfo(
          latestVersion: latestTag,
          downloadUrl: downloadUrl,
          releaseNotes: body,
          isUpdateAvailable: updateAvailable,
        );
      } else {
        throw Exception('GitHub API returned status code ${response.statusCode}');
      }
    } catch (e) {
      // Fallback on error (no connection, repo doesn't exist yet, rate limits, etc.)
      return AppUpdateInfo(
        latestVersion: currentVersion,
        downloadUrl: '',
        releaseNotes: '',
        isUpdateAvailable: false,
      );
    }
  }

  /// Compares two semver version tags (e.g., v1.0.2 vs v1.0.0)
  static bool _isNewerVersion(String latest, String current) {
    try {
      final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');

      final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = max(latestParts.length, currentParts.length);
      for (int i = 0; i < maxLen; i++) {
        final latestPart = i < latestParts.length ? latestParts[i] : 0;
        final currentPart = i < currentParts.length ? currentParts[i] : 0;

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
      return false;
    } catch (e) {
      // Simple string fallback on parsing errors
      return latest != current;
    }
  }
}
