import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_transaction_app/core/theme.dart';
import 'package:sms_transaction_app/core/tokens.dart';

void main() {
  group('Design system', () {
    test('dark theme is built without throwing', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('AppTheming extension is registered on dark theme', () {
      final theme = AppTheme.darkTheme;
      final theming = theme.extension<AppTheming>();
      expect(theming, isNotNull);
      expect(theming!.canvas, equals(AppColors.canvas));
      expect(theming.success, equals(AppColors.success));
    });

    test('confidence badge color tokens are non-null', () {
      expect(AppColors.success, isNotNull);
      expect(AppColors.warning, isNotNull);
      expect(AppColors.danger, isNotNull);
    });
  });
}
