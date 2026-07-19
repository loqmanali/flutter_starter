import 'package:api_kit/api_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging_kit/logging_kit.dart';
import 'package:storage_kit/storage_kit.dart';
import 'package:widget_kit/widget_kit.dart';

void main() {
  test('every kit is importable and its core symbols resolve', () {
    expect(WidgetKitTokens.spaceMd, 16);
    expect(WidgetKitBreakpoints.compact, 600);
    expect(AppLogLevel.values, contains(AppLogLevel.info));
    expect(StorageType.values.isNotEmpty, isTrue);
    expect(
      ErrorMapper.mapExceptionToFailure(const NotFoundException('missing')),
      isA<NotFoundFailure>(),
    );
  });
}
