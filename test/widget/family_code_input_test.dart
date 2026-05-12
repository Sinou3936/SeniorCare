import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/screens/family/family_code_input_screen.dart';

void main() {
  group('FamilyCodeInputScreen — 코드 입력 (버그 수정 검증)', () {
    Widget buildScreen() => const MaterialApp(
          home: FamilyCodeInputScreen(),
        );

    testWidgets('초기 렌더링: 뒤로가기, 안내 텍스트, 연결 버튼 표시', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('부모님 코드를\n입력해주세요'), findsOneWidget);
      expect(find.text('연결하기'), findsOneWidget);
    });

    testWidgets('초기 상태: 연결하기 버튼 비활성화', (tester) async {
      await tester.pumpWidget(buildScreen());

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull); // 6자리 미입력 → 비활성
    });

    testWidgets('6자리 입력하면 6개 문자 모두 표시', (tester) async {
      await tester.pumpWidget(buildScreen());

      // 숨겨진 TextField에 6자리 입력
      await tester.enterText(find.byType(TextField), 'ABC123');
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('소문자 입력 → 대문자로 자동 변환', (tester) async {
      await tester.pumpWidget(buildScreen());

      await tester.enterText(find.byType(TextField), 'abc123');
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('3자리만 입력하면 연결 버튼 여전히 비활성화', (tester) async {
      await tester.pumpWidget(buildScreen());

      await tester.enterText(find.byType(TextField), 'ABC');
      await tester.pump();

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('6자리 입력하면 연결 버튼 활성화', (tester) async {
      await tester.pumpWidget(buildScreen());

      await tester.enterText(find.byType(TextField), 'ABC123');
      await tester.pump();

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('7자리 이상 입력해도 6자리까지만 표시', (tester) async {
      await tester.pumpWidget(buildScreen());

      await tester.enterText(find.byType(TextField), 'ABCDEFG');
      await tester.pump();

      // G는 잘려야 함
      expect(find.text('G'), findsNothing);
      expect(find.text('F'), findsOneWidget);
    });
  });
}
