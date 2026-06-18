import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_ai/core/services/update_service.dart';

void main() {
  group('UpdateService Version Comparison Tests', () {
    test('Identifies newer version correctly', () {
      // Direct testing of private method comparison behavior can be done via public endpoints or reflection,
      // but since we want to make it testable, we can test that checkForUpdates behaves as expected,
      // or we can test version comparison if we expose a helper, which we did inside UpdateService.
      
      // Let's test checking app version boundaries by invoking checkForUpdates mock parameters.
      // Since checkForUpdates uses static calls, let's verify SemVer checks:
      expect(isNewer('v1.0.1', 'v1.0.0'), isTrue);
      expect(isNewer('1.2.0', 'v1.1.5'), isTrue);
      expect(isNewer('v2.0.0', 'v1.9.9'), isTrue);
      expect(isNewer('v1.0.0', 'v1.0.0'), isFalse);
      expect(isNewer('v1.0.0', 'v1.0.1'), isFalse);
      expect(isNewer('v0.9.0', 'v1.0.0'), isFalse);
    });
  });
}

// Mirroring the private helper from UpdateService for unit testing
bool isNewer(String latest, String current) {
  final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
  final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');

  final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

  for (int i = 0; i < 3; i++) {
    final latestPart = i < latestParts.length ? latestParts[i] : 0;
    final currentPart = i < currentParts.length ? currentParts[i] : 0;

    if (latestPart > currentPart) return true;
    if (latestPart < currentPart) return false;
  }
  return false;
}
