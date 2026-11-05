import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/shared/presentation/author_mapper.dart';

void main() {
  testWidgets('pixel flair stays one 16px image without cropping its artwork', (
    tester,
  ) async {
    final mapped = presentAuthor(
      const Author(
        username: 'fixture',
        displayName: 'Tiếng Việt: ặ ữ ờ ẫ ệ',
        style: AuthorStyle(
          icon: {
            'url': 'https://example.invalid/flair.webp',
            'name': 'Penguin',
            'pixelArt': true,
          },
        ),
      ),
    );
    final author = AuthorData(
      id: mapped.id,
      username: mapped.username,
      displayName: mapped.displayName,
      style: mapped.style,
      loadNetworkAvatar: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: VnlfTheme.light(),
        home: Scaffold(body: VnlfAuthorNameRow(author: author)),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.width, 16);
    expect(image.height, 16);
    expect(image.filterQuality, FilterQuality.none);
    expect(find.byIcon(Icons.terminal_rounded), findsNothing);
    expect(
      find.ancestor(of: find.byType(Image), matching: find.byType(ClipRRect)),
      findsNothing,
    );
  });

  testWidgets('nameplate gradients are clipped to text in both themes', (
    tester,
  ) async {
    final author = presentAuthor(
      const Author(
        username: 'fixture',
        displayName: 'Nguyễn An',
        style: AuthorStyle(
          nameplate: {
            'id': 'tint',
            'name': {'light': '#002eff', 'dark': '#568aff'},
            'name2': {'light': '#007b05', 'dark': '#3dff3d'},
          },
        ),
      ),
    );
    for (final theme in [VnlfTheme.light(), VnlfTheme.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: VnlfAuthorNameRow(author: author)),
        ),
      );
      expect(
        find.ancestor(
          of: find.text('Nguyễn An'),
          matching: find.byType(ShaderMask),
        ),
        findsOneWidget,
      );
    }
    expect(author.style.nameGradientLight, const [
      Color(0xff002eff),
      Color(0xff007b05),
    ]);
    expect(author.style.nameGradientDark, const [
      Color(0xff568aff),
      Color(0xff3dff3d),
    ]);
  });
}
