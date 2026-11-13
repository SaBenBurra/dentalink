import 'package:dentigo/core/error/app_failures.dart';
import 'package:dentigo/data/models/app_config.dart';
import 'package:dentigo/data/providers/repository_providers.dart';
import 'package:dentigo/data/repositories/app_config_repository.dart';
import 'package:dentigo/providers/app_version_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRepo implements AppConfigRepository {
  _FakeRepo(this.result);

  final Future<AppConfig?> Function() result;
  String? platform;

  @override
  Future<AppConfig?> fetch(String platform) {
    this.platform = platform;
    return result();
  }
}

const _config = AppConfig(
  minSupportedVersion: '1.2.0',
  latestVersion: '1.10.0',
  storeUrl: 'https://example.com',
);

void main() {
  // appResumeProvider AppLifecycleListener kurar.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('compareVersions', () {
    test('eşit, büyük, küçük', () {
      expect(compareVersions('1.2.3', '1.2.3'), 0);
      expect(compareVersions('1.2.4', '1.2.3'), greaterThan(0));
      expect(compareVersions('0.9.9', '1.0.0'), lessThan(0));
    });

    test('sayısal: 1.10 > 1.9', () {
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
    });

    test('bozuk girdi null', () {
      for (final bad in ['', '1.2', '1.2.3.4', '1.x.0', '1.2.3+4', '1.-1.0']) {
        expect(compareVersions(bad, '1.0.0'), isNull, reason: bad);
      }
    });
  });

  group('resolveVersionStatus', () {
    test('üç durum', () {
      expect(
        resolveVersionStatus('1.1.9', _config),
        AppVersionStatus.updateRequired,
      );
      expect(
        resolveVersionStatus('1.2.0', _config),
        AppVersionStatus.updateAvailable,
      );
      expect(
        resolveVersionStatus('1.10.0', _config),
        AppVersionStatus.upToDate,
      );
    });

    test('ayar yok ya da sürüm bozuk → güncel', () {
      expect(resolveVersionStatus('0.0.1', null), AppVersionStatus.upToDate);
      expect(resolveVersionStatus('dev', _config), AppVersionStatus.upToDate);
    });
  });

  group('versionCheckProvider', () {
    ProviderContainer container(_FakeRepo repo, {String version = '1.0.0'}) {
      final c = ProviderContainer(
        overrides: [
          appConfigRepositoryProvider.overrideWithValue(repo),
          currentAppVersionProvider.overrideWith((ref) async => version),
          appPlatformProvider.overrideWithValue('ios'),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('platformun ayarıyla durumu hesaplar', () async {
      final repo = _FakeRepo(() async => _config);
      final c = container(repo);
      final check = await c.read(versionCheckProvider.future);
      expect(repo.platform, 'ios');
      expect(check.status, AppVersionStatus.updateRequired);
      expect(c.read(appVersionStatusProvider), AppVersionStatus.updateRequired);
    });

    test('okuma hatası kilitlemez', () async {
      final c = container(_FakeRepo(() async => throw const NetworkFailure()));
      final check = await c.read(versionCheckProvider.future);
      expect(check.status, AppVersionStatus.upToDate);
      expect(check.config, isNull);
    });

    test('satır yoksa güncel', () async {
      final c = container(_FakeRepo(() async => null));
      expect(
        (await c.read(versionCheckProvider.future)).status,
        AppVersionStatus.upToDate,
      );
    });
  });

  test('banner kapatma o sürüm için kalıcı', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() {
      final c = ProviderContainer(
        overrides: [
          dismissedUpdateProvider.overrideWith(
            () => DismissedUpdateNotifier(prefs),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    final first = make();
    expect(first.read(dismissedUpdateProvider), isNull);
    first.read(dismissedUpdateProvider.notifier).dismiss('1.10.0');
    expect(make().read(dismissedUpdateProvider), '1.10.0');
  });
}
