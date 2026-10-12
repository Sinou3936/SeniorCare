import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seniorcare/models/medicine.dart';
import 'package:seniorcare/widgets/medicine_name_picker.dart';

void main() {
  Widget host({String? name, required ValueChanged<MedicineNameItem> onSelected}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MedicineNamePicker(name: name, onSelected: onSelected),
        ),
      ),
    );
  }

  group('MedicineNamePicker', () {
    testWidgets('입력칸 없이 카테고리 버튼 8개만 보인다', (tester) async {
      await tester.pumpWidget(host(onSelected: (_) {}));

      expect(find.byType(TextField), findsNothing);
      expect(find.text('아래에서 약을 골라주세요'), findsOneWidget);
      for (final c in medicineNameCategories) {
        expect(find.text(c.label), findsOneWidget);
      }
      expect(medicineNameCategories.length, 8);
      // 카테고리를 열기 전에는 세부 버튼이 없다
      expect(find.text('혈압약'), findsNothing);
    });

    testWidgets('카테고리 → 세부 버튼 선택 시 이름이 전달된다', (tester) async {
      MedicineNameItem? picked;
      await tester.pumpWidget(host(onSelected: (i) => picked = i));

      await tester.tap(find.text('혈압·심장약'));
      await tester.pump();
      expect(find.text('혈압약'), findsOneWidget);
      expect(find.text('심장 관련 약'), findsOneWidget);

      await tester.tap(find.text('혈압약'));
      expect(picked?.name, '혈압약');
      expect(picked?.type, MedicineType.oral);
    });

    testWidgets('외용약은 바르는약으로, 영양제는 먹는약으로 정해진다', (tester) async {
      MedicineNameItem? picked;
      await tester.pumpWidget(host(onSelected: (i) => picked = i));

      await tester.tap(find.text('외용약·영양제'));
      await tester.pump();

      await tester.tap(find.text('연고'));
      expect(picked?.type, MedicineType.topical);
      await tester.tap(find.text('비타민·영양제'));
      expect(picked?.type, MedicineType.oral);
    });

    testWidgets('이미 고른 이름이면 해당 카테고리가 열린 채로 시작한다', (tester) async {
      await tester.pumpWidget(host(name: '진통제', onSelected: (_) {}));

      expect(find.text('관절약'), findsOneWidget);
      expect(find.text('소염제'), findsOneWidget);
      expect(find.text('진통제'), findsNWidgets(2)); // 선택 표시칸 + 세부 버튼
    });

    testWidgets('목록에 없는 옛 이름은 그대로 표시만 하고 카테고리는 닫혀 있다', (tester) async {
      await tester.pumpWidget(host(name: '타이레놀', onSelected: (_) {}));

      expect(find.text('타이레놀'), findsOneWidget);
      expect(find.text('혈압약'), findsNothing);
    });

    test('세부 이름은 중복 없이 유일하다', () {
      final names = [
        for (final c in medicineNameCategories) ...c.items.map((i) => i.name),
      ];
      expect(names.toSet().length, names.length);
    });
  });
}
