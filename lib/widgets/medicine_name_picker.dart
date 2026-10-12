import 'package:flutter/material.dart';
import '../models/medicine.dart';

/// 선택 가능한 약 이름 한 개. 고르면 약 종류(먹는약/바르는약)도 같이 정해진다.
class MedicineNameItem {
  final String name;
  final MedicineType type;
  const MedicineNameItem(this.name, {this.type = MedicineType.oral});
}

class MedicineNameCategory {
  final String label;
  final List<MedicineNameItem> items;
  const MedicineNameCategory(this.label, this.items);
}

/// 약 이름 카테고리 — 입력칸 없이 버튼으로만 이름을 정한다(시니어 타이핑 부담·잘못된 값 방지).
/// 목록에 없는 약은 '그 외 약'으로 등록한다.
const List<MedicineNameCategory> medicineNameCategories = [
  MedicineNameCategory('혈압·심장약', [
    MedicineNameItem('혈압약'),
    MedicineNameItem('심장 관련 약'),
  ]),
  MedicineNameCategory('당뇨·콜레스테롤약', [
    MedicineNameItem('당뇨약'),
    MedicineNameItem('고지혈증약'),
  ]),
  MedicineNameCategory('관절·통증약', [
    MedicineNameItem('관절약'),
    MedicineNameItem('진통제'),
    MedicineNameItem('소염제'),
  ]),
  MedicineNameCategory('위장·소화약', [
    MedicineNameItem('위장약'),
    MedicineNameItem('소화제'),
    MedicineNameItem('변비약'),
  ]),
  MedicineNameCategory('감기·호흡기약', [
    MedicineNameItem('감기약'),
    MedicineNameItem('기침약'),
    MedicineNameItem('알레르기약'),
  ]),
  MedicineNameCategory('정신건강·수면 관련 약', [
    MedicineNameItem('수면 관련 약'),
    MedicineNameItem('불안·우울 관련 약'),
  ]),
  MedicineNameCategory('기타 질환 관련 약', [
    MedicineNameItem('갑상선약'),
    MedicineNameItem('그 외 약'),
  ]),
  MedicineNameCategory('외용약·영양제', [
    MedicineNameItem('연고', type: MedicineType.topical),
    MedicineNameItem('파스', type: MedicineType.topical),
    MedicineNameItem('안약', type: MedicineType.topical),
    MedicineNameItem('비타민·영양제'),
  ]),
];

/// 약 이름 선택 — 카테고리 버튼 → 세부 버튼 2단계.
/// [name] 이 목록에 없는 옛 이름(직접 입력으로 등록된 약)이면 그대로 표시만 하고,
/// 다른 버튼을 고르면 바뀐다.
class MedicineNamePicker extends StatefulWidget {
  final String? name;
  final ValueChanged<MedicineNameItem> onSelected;

  const MedicineNamePicker({
    super.key,
    required this.name,
    required this.onSelected,
  });

  @override
  State<MedicineNamePicker> createState() => _MedicineNamePickerState();
}

class _MedicineNamePickerState extends State<MedicineNamePicker> {
  static const _coral = Color(0xFFE8896A);
  int? _openIndex;

  @override
  void initState() {
    super.initState();
    final i = medicineNameCategories
        .indexWhere((c) => c.items.any((it) => it.name == widget.name));
    _openIndex = i < 0 ? null : i;
  }

  Widget _categoryButton(int index) {
    final category = medicineNameCategories[index];
    final open = _openIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _openIndex = open ? null : index),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: open ? _coral.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: open ? _coral : const Color(0xFFE0E0E0),
            width: 2,
          ),
        ),
        child: Text(
          category.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: open ? _coral : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  Widget _itemChip(MedicineNameItem item) {
    final selected = widget.name == item.name;
    return GestureDetector(
      onTap: () => widget.onSelected(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _coral : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _coral, width: 2),
        ),
        child: Text(
          item.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : _coral,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasName = widget.name != null && widget.name!.isNotEmpty;
    final rows = <Widget>[];
    for (var i = 0; i < medicineNameCategories.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: _categoryButton(i)),
          const SizedBox(width: 12),
          Expanded(
            child: i + 1 < medicineNameCategories.length
                ? _categoryButton(i + 1)
                : const SizedBox.shrink(),
          ),
        ],
      ));
      rows.add(const SizedBox(height: 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasName ? _coral : const Color(0xFFE0E0E0),
              width: 2,
            ),
          ),
          child: Text(
            hasName ? widget.name! : '아래에서 약을 골라주세요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: hasName ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...rows,
        if (_openIndex != null) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in medicineNameCategories[_openIndex!].items)
                _itemChip(item),
            ],
          ),
        ],
      ],
    );
  }
}
