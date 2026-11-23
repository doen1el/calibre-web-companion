import 'package:calibre_web_companion/core/utils/sandbox_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const current =
      '/private/var/mobile/Containers/Data/Application/'
      'AAAAAAAA-1111-2222-3333-444444444444';

  tearDown(() => SandboxPath.containerRoot = null);

  test('moves a path from an old container into the current one', () {
    SandboxPath.containerRoot = current;
    expect(
      SandboxPath.rebase(
        '/var/mobile/Containers/Data/Application/'
        'BBBBBBBB-5555-6666-7777-888888888888/Documents/Book - Author.epub',
      ),
      '$current/Documents/Book - Author.epub',
    );
  });

  test('keeps paths that are already current or not in a container', () {
    SandboxPath.containerRoot = current;
    expect(
      SandboxPath.rebase('$current/Documents/a.epub'),
      '$current/Documents/a.epub',
    );
    expect(
      SandboxPath.rebase('content://com.android/tree/x'),
      'content://com.android/tree/x',
    );
    expect(SandboxPath.rebase(''), '');
  });

  test('does nothing when not initialised (Android)', () {
    const path =
        '/var/mobile/Containers/Data/Application/'
        'BBBBBBBB-5555-6666-7777-888888888888/Documents/a.epub';
    expect(SandboxPath.rebase(path), path);
  });
}
