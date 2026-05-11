import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';

class SeniorMyCodeScreen extends StatefulWidget {
  const SeniorMyCodeScreen({super.key});

  @override
  State<SeniorMyCodeScreen> createState() => _SeniorMyCodeScreenState();
}

class _SeniorMyCodeScreenState extends State<SeniorMyCodeScreen> {
  late Future<({String code, bool isExpired})> _codeFuture;

  @override
  void initState() {
    super.initState();
    _codeFuture = FirestoreService.getSeniorCode();
  }

  Future<void> _confirmRegenerate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('코드 재생성',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        content: const Text(
          '새 코드를 발급하면\n기존 코드는 사용할 수 없어요.\n\n보호자에게 새 코드를 다시 알려줘야 해요.',
          style: TextStyle(fontSize: 18, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('재생성',
                style: TextStyle(fontSize: 18, color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _codeFuture = FirestoreService.regenerateSeniorCode();
      });
    }
  }

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
      body: FutureBuilder<({String code, bool isExpired})>(
        future: _codeFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
            );
          }
          if (snap.hasError) {
            return const Center(child: Text('코드를 불러올 수 없어요'));
          }
          final result = snap.data!;
          return _CodeBody(
            code: result.code,
            isExpired: result.isExpired,
            onRegenerate: _confirmRegenerate,
          );
        },
      ),
    );
  }
}

class _CodeBody extends StatelessWidget {
  final String code;
  final bool isExpired;
  final VoidCallback onRegenerate;

  const _CodeBody({
    required this.code,
    required this.isExpired,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                Icon(
                  Icons.qr_code_rounded,
                  size: 64,
                  color: isExpired ? const Color(0xFFCCCCCC) : const Color(0xFF4A90D9),
                ),
                const SizedBox(height: 16),
                Text(
                  isExpired ? '코드가 만료됐어요' : '자녀에게 이 코드를 알려주세요',
                  style: TextStyle(
                    fontSize: 18,
                    color: isExpired ? const Color(0xFFE53935) : const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? const Color(0xFFF5F5F5)
                        : const Color(0xFF4A90D9).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpired
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF4A90D9).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: code
                        .split('')
                        .map((ch) => _CodeChar(char: ch, expired: isExpired))
                        .toList(),
                  ),
                ),
                if (!isExpired) ...[
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
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
                ] else ...[
                  const SizedBox(height: 16),
                  const Text(
                    '아래 버튼으로 새 코드를 발급받으세요',
                    style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!isExpired)
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('카카오톡 공유 기능은 준비 중이에요',
                          style: TextStyle(fontSize: 16)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.chat_bubble_rounded,
                    color: Color(0xFF3A1D1D), size: 28),
                label: const Text(
                  '카카오톡으로 공유',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A1D1D)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: onRegenerate,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isExpired
                      ? const Color(0xFFE53935)
                      : const Color(0xFF7C3AED),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: Icon(Icons.refresh_rounded,
                  color: isExpired
                      ? const Color(0xFFE53935)
                      : const Color(0xFF7C3AED),
                  size: 24),
              label: Text(
                isExpired ? '새 코드 발급' : '코드 재생성',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isExpired
                      ? const Color(0xFFE53935)
                      : const Color(0xFF7C3AED),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isExpired ? '코드는 발급 후 1시간 동안 유효해요' : '코드는 언제든지 이 화면에서 확인할 수 있어요',
            style: const TextStyle(fontSize: 15, color: Color(0xFF999999)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CodeChar extends StatelessWidget {
  final String char;
  final bool expired;
  const _CodeChar({required this.char, this.expired = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 38,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: expired ? const Color(0xFFCCCCCC) : const Color(0xFF4A90D9),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: expired ? const Color(0xFFCCCCCC) : const Color(0xFF4A90D9),
          ),
        ),
      ),
    );
  }
}
