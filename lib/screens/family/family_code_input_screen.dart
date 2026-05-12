import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../services/prefs_service.dart';
import 'family_main_screen.dart';

class FamilyCodeInputScreen extends StatefulWidget {
  const FamilyCodeInputScreen({super.key});

  @override
  State<FamilyCodeInputScreen> createState() => _FamilyCodeInputScreenState();
}

class _FamilyCodeInputScreenState extends State<FamilyCodeInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _code => _controller.text.toUpperCase();
  bool get _isFull => _code.length == 6;

  Future<void> _connect() async {
    if (!_isFull) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final seniorUid = await FirestoreService.verifySeniorCode(_code);

    if (!mounted) return;

    if (seniorUid == 'expired') {
      setState(() {
        _isLoading = false;
        _errorMessage = '만료된 코드예요. 부모님께 새 코드를 요청하세요.';
        _controller.clear();
      });
      _focusNode.requestFocus();
    } else if (seniorUid != null) {
      await FirestoreService.linkToSenior(seniorUid);
      await PrefsService.saveMode('family');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FamilyMainScreen()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = '코드를 찾을 수 없어요. 다시 확인해주세요.';
        _controller.clear();
      });
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A90D9),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                const Text(
                  '부모님 코드를\n입력해주세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '부모님 앱의 "내 코드" 화면에서\n6자리 코드를 확인하세요',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 17, height: 1.5),
                ),
                const SizedBox(height: 48),

                // 숨겨진 TextField (실제 입력 처리)
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 1,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      maxLength: 6,
                      keyboardType: TextInputType.visiblePassword,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (v) {
                        setState(() => _errorMessage = null);
                      },
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                // 6개 시각적 박스
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) {
                    final char = i < _code.length ? _code[i] : '';
                    final isCurrent = i == _code.length && _focusNode.hasFocus;
                    return _CodeBox(char: char, isCurrent: isCurrent);
                  }),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isFull && !_isLoading ? _connect : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF4A90D9))
                        : Text(
                            '연결하기',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _isFull
                                  ? const Color(0xFF4A90D9)
                                  : const Color(0xFF4A90D9)
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    '코드는 부모님 앱 → 내 코드 에서 확인할 수 있어요',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String char;
  final bool isCurrent;

  const _CodeBox({required this.char, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? Colors.white
              : Colors.white.withValues(alpha: 0.0),
          width: 2.5,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: char.isEmpty
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF4A90D9)
                    : const Color(0xFFCCCCCC),
                shape: BoxShape.circle,
              ),
            )
          : Text(
              char,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
    );
  }
}
