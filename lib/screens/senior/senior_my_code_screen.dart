import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeniorMyCodeScreen extends StatelessWidget {
  // Firebase 연동 전 더미 코드
  static const _code = 'A3K9X2';

  const SeniorMyCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90D9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '내 코드',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_rounded,
                    size: 64,
                    color: Color(0xFF4A90D9),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '자녀에게 이 코드를 알려주세요',
                    style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // 코드 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _code.split('').map((ch) => _CodeChar(char: ch)).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 복사 버튼
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: _code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('코드가 복사됐어요!', style: TextStyle(fontSize: 16)),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFF4A90D9)),
                    label: const Text(
                      '코드 복사',
                      style: TextStyle(fontSize: 18, color: Color(0xFF4A90D9)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 카카오톡 공유 버튼
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: 카카오톡 공유
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('카카오톡 공유 기능은 준비 중이에요', style: TextStyle(fontSize: 16)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF3A1D1D), size: 28),
                label: const Text(
                  '카카오톡으로 공유',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A1D1D),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '코드는 언제든지 이 화면에서 확인할 수 있어요',
              style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeChar extends StatelessWidget {
  final String char;
  const _CodeChar({required this.char});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 38,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4A90D9), width: 1.5),
      ),
      child: Center(
        child: Text(
          char,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A90D9),
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
