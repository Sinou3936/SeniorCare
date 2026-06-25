import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';
import '../../services/inquiry_service.dart';

/// 보호자 문의 폼 — 카테고리 + 내용 작성 후 서버(Cloud Function)로 이메일 발송.
class FamilyInquiryScreen extends StatefulWidget {
  const FamilyInquiryScreen({super.key});

  @override
  State<FamilyInquiryScreen> createState() => _FamilyInquiryScreenState();
}

class _FamilyInquiryScreenState extends State<FamilyInquiryScreen> {
  static const _categories = ['오류/버그', '기능 제안', '사용 문의', '기타'];
  String _category = _categories.first;
  final _contentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _contentController.text.trim();
    if (content.isEmpty || _sending) return;
    if (!await ensureOnline(context,
        message: '문의를 보내려면\nWi-Fi나 데이터 연결이 필요해요.')) {
      return;
    }
    if (!mounted) return;
    setState(() => _sending = true);
    try {
      await InquiryService.send(category: _category, content: content);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('문의가 접수됐어요',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          content: const Text('소중한 의견 감사합니다.',
              style: TextStyle(fontSize: 17, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('전송에 실패했어요. 잠시 후 다시 시도해주세요.',
              style: TextStyle(fontSize: 16)),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8896A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('문의하기',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('어떤 내용인가요?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((c) {
                final selected = c == _category;
                return ChoiceChip(
                  label: Text(c, style: const TextStyle(fontSize: 16)),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: const Color(0xFFE8896A),
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF555555),
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: selected
                            ? const Color(0xFFE8896A)
                            : const Color(0xFFDDDDDD)),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            const Text('내용',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 8,
              minLines: 6,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: InputDecoration(
                hintText: '문의 내용을 자세히 적어주세요',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8896A)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8896A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('보내기',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
