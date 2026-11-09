import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repoRoot = Directory.current;

  group('Project layout and governance contracts', () {
    test('required governance and developer guide documents exist', () {
      const requiredDocs = <String>[
        'README.md',
        'CONTRIBUTING.md',
        'AGENTS.md',
        'PLAN.md',
        'API_NOTES.md',
        'DESIGN_REFERENCE.md',
        'analysis_options.yaml',
        'docs/README.md',
        'docs/DEVELOPMENT.md',
        'docs/BUILD_AND_RELEASE.md',
        'docs/ASSETS.md',
        'docs/UI_FIELD_MAP.md',
        'docs/release-signing.md',
      ];

      for (final relativePath in requiredDocs) {
        final file = File('${repoRoot.path}/$relativePath');
        expect(
          file.existsSync(),
          isTrue,
          reason:
              'Missing required governance/documentation file: $relativePath',
        );
        expect(
          file.readAsStringSync().trim(),
          isNotEmpty,
          reason: 'Documentation file must not be empty: $relativePath',
        );
      }
    });

    test('root directory contains only canonical markdown files', () {
      const allowedRootMarkdown = <String>{
        'README.md',
        'CONTRIBUTING.md',
        'AGENTS.md',
        'PLAN.md',
        'API_NOTES.md',
        'DESIGN_REFERENCE.md',
      };

      final rootMarkdown = repoRoot
          .listSync(followLinks: false)
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.toLowerCase().endsWith('.md'))
          .toSet();

      expect(rootMarkdown, equals(allowedRootMarkdown));
    });

    test(
      'lib/ and test/ contain no stray markdown reports or secret files',
      () {
        const forbiddenExtensions = <String>[
          '.md',
          '.keystore',
          '.jks',
          '.har',
        ];
        const forbiddenNames = <String>{'key.properties', '.env'};

        for (final rootName in const <String>['lib', 'test']) {
          final dir = Directory('${repoRoot.path}/$rootName');
          for (final entity in dir.listSync(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is! File) continue;
            final name = entity.uri.pathSegments.last;
            final lower = name.toLowerCase();
            expect(
              forbiddenNames.contains(lower) || lower.startsWith('.env.'),
              isFalse,
              reason: 'Forbidden file in $rootName/: ${entity.path}',
            );
            for (final ext in forbiddenExtensions) {
              expect(
                lower.endsWith(ext),
                isFalse,
                reason:
                    'Disallowed *$ext file inside $rootName/: ${entity.path}',
              );
            }
          }
        }
      },
    );

    test('test/features/ groups all tests into feature slice directories', () {
      final featuresTestDir = Directory('${repoRoot.path}/test/features');
      final looseFiles = featuresTestDir
          .listSync(followLinks: false)
          .whereType<File>()
          .map((f) => f.path)
          .toList();

      expect(
        looseFiles,
        isEmpty,
        reason: 'All feature tests under test/features/ must live inside a test/features/<slice>/ subdirectory.',
      );
    });
  });

  group('Clean Architecture layer import boundaries', () {
    final libRoot = Directory('${repoRoot.path}/lib');
    final srcRoot = Directory('${repoRoot.path}/lib/src');
    final directivePattern = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );

    const forbiddenUiPackages = <String>{
      'package:flutter/material.dart',
      'package:flutter/widgets.dart',
      'package:flutter/cupertino.dart',
    };

    List<String>? resolveSrcParts(File sourceFile, String uriText) {
      if (uriText.startsWith('dart:')) return null;
      if (uriText.startsWith('package:')) {
        const prefix = 'package:vnlfsocialapp/';
        if (!uriText.startsWith(prefix)) return null;
        final rel = uriText.substring(prefix.length);
        if (!rel.startsWith('src/')) return null;
        return rel.substring('src/'.length).split('/');
      }
      final resolvedUri = sourceFile.parent.uri.resolve(uriText);
      final resolvedPath = File.fromUri(resolvedUri).path;
      final srcPrefix = '${srcRoot.path}/';
      if (!resolvedPath.startsWith(srcPrefix)) return null;
      final rel = resolvedPath.substring(srcPrefix.length);
      return rel.split('/');
    }

    test('domain, data, design_system, and core layers respect import rules', () {
      final violations = <String>[];
      final dartFiles =
          srcRoot
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      expect(libRoot.existsSync(), isTrue);
      expect(dartFiles, isNotEmpty);

      for (final file in dartFiles) {
        final relPath = file.path.substring('${srcRoot.path}/'.length);
        final parts = relPath.split('/');
        final source = file.readAsStringSync();

        for (final match in directivePattern.allMatches(source)) {
          final uri = match.group(1)!;
          final targetParts = resolveSrcParts(file, uri);

          // 1. Domain layer purity
          if (parts.contains('domain')) {
            if (forbiddenUiPackages.contains(uri)) {
              violations.add('Domain UI import in $relPath -> $uri');
            }
            if (targetParts != null) {
              if (targetParts.contains('presentation') ||
                  targetParts.contains('data') ||
                  const <String>{
                    'app',
                    'design_system',
                    'gallery',
                  }.contains(targetParts.first)) {
                violations.add(
                  'Domain boundary violation in $relPath -> ${targetParts.join("/")}',
                );
              }
            }
          }

          // 2. Data layer isolation from presentation & design_system
          if (parts.contains('data')) {
            if (forbiddenUiPackages.contains(uri)) {
              violations.add('Data UI import in $relPath -> $uri');
            }
            if (targetParts != null) {
              if (targetParts.contains('presentation') ||
                  const <String>{
                    'app',
                    'design_system',
                    'gallery',
                  }.contains(targetParts.first)) {
                violations.add(
                  'Data boundary violation in $relPath -> ${targetParts.join("/")}',
                );
              }
            }
          }

          // 3. Design system isolation from features, data, app, and gallery
          if (parts.first == 'design_system' && targetParts != null) {
            if (const <String>{
              'features',
              'data',
              'app',
              'gallery',
            }.contains(targetParts.first)) {
              violations.add(
                'Design system violation in $relPath -> ${targetParts.join("/")}',
              );
            }
          }

          // 4. Core infrastructure isolation from features, app, and gallery
          if (parts.first == 'core' && targetParts != null) {
            if (const <String>{
              'features',
              'app',
              'gallery',
            }.contains(targetParts.first)) {
              violations.add(
                'Core layer violation in $relPath -> ${targetParts.join("/")}',
              );
            }
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });
}
