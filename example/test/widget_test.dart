// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:identity_verification_flutter_example/main.dart';

void main() {
  testWidgets('Example app shows H5 face verify UI', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // 页面标题（对齐 Flutter 模板的 AppBar title）
    expect(find.text('Plugin example app'), findsOneWidget);

    // 默认状态文案「未拉起」+ 两个操作按钮
    expect(find.text('未拉起'), findsOneWidget);
    expect(find.text('拉起 H5 刷脸'), findsOneWidget);
    expect(find.text('关闭 H5 刷脸'), findsOneWidget);
  });
}
