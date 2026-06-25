import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// 앱 내 정책 화면 — 루트의 .md 에셋(개인정보처리방침/계정삭제 안내)을 렌더.
/// GitHub Pages와 동일한 .md를 쓰므로 내용이 갈리지 않음.
class PolicyViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  const PolicyViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<PolicyViewerScreen> createState() => _PolicyViewerScreenState();
}

class _PolicyViewerScreenState extends State<PolicyViewerScreen> {
  String? _content;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(widget.assetPath);
    if (mounted) setState(() => _content = _stripFrontMatter(raw));
  }

  /// Jekyll front matter(--- ... ---) 제거 — 앱에선 불필요
  String _stripFrontMatter(String md) {
    final t = md.trimLeft();
    if (!t.startsWith('---')) return md;
    final close = t.indexOf('\n---', 3);
    if (close == -1) return md;
    final nl = t.indexOf('\n', close + 1);
    return nl == -1 ? '' : t.substring(nl + 1).trimLeft();
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
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
      ),
      body: _content == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8896A)))
          : Markdown(
              data: _content!,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href),
                      mode: LaunchMode.externalApplication);
                }
              },
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                    fontSize: 16, height: 1.6, color: Color(0xFF333333)),
                h1: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
                h2: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                    height: 2.0),
                listBullet: const TextStyle(
                    fontSize: 16, height: 1.6, color: Color(0xFF333333)),
                a: const TextStyle(
                    color: Color(0xFFE8896A),
                    decoration: TextDecoration.underline),
                strong: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}
