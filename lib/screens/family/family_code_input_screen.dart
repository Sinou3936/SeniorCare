import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/connectivity_service.dart';
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
    // 코드 검증은 서버 조회 — 오프라인이면 무한 로딩 대신 안내
    if (!await ensureOnline(context,
        message: '가족 연결은 부모님 코드를 서버에서 확인해야 해서\nWi-Fi나 데이터 연결이 필요해요.')) {
      return;
    }
    if (!mounted) return;
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
      await PrefsService.saveLinkedSeniorUid(seniorUid);
      await PrefsService.saveMode('family');
      if (!mounted) return;
      // 이전 스택(모드선택·코드입력) 전부 제거 → 가족 메인을 루트로.
      // (코드입력은 push로 띄워 뒤로가기가 모드선택으로 가지만, 연결 성공 후엔
      //  가족 메인이 루트여야 뒤로가기가 앱 종료로 동작)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FamilyMainScreen()),
        (route) => false,
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
      backgroundColor: const Color(0xFFE8896A),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // 키보드를 시스템 버튼으로 내리면 FocusNode는 포커스를 유지해
            // requestFocus()가 무시됨 → 이미 포커스면 키보드를 강제로 다시 띄움
            if (_focusNode.hasFocus) {
              SystemChannels.textInput.invokeMethod('TextInput.show');
            } else {
              _focusNode.requestFocus();
            }
          },
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
                            color: Color(0xFFE8896A))
                        : Text(
                            '연결하기',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _isFull
                                  ? const Color(0xFFE8896A)
                                  : const Color(0xFFE8896A)
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
                    ? const Color(0xFFE8896A)
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
