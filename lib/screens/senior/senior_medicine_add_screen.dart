import 'package:flutter/material.dart';

class SeniorMedicineAddScreen extends StatefulWidget {
  const SeniorMedicineAddScreen({super.key});

  @override
  State<SeniorMedicineAddScreen> createState() => _SeniorMedicineAddScreenState();
}

class _SeniorMedicineAddScreenState extends State<SeniorMedicineAddScreen> {
  String _ocrState = 'idle'; // idle | loading | success | failed
  final _nameController = TextEditingController();

  final Map<String, int> _times = {
    '아침': 8 * 60,
    '점심': 12 * 60,
    '저녁': 18 * 60,
    '취침': 21 * 60,
  };
  final Map<String, bool> _timeEnabled = {
    '아침': true,
    '점심': true,
    '저녁': true,
    '취침': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _adjustTime(String slot, int delta) {
    setState(() {
      _times[slot] = (_times[slot]! + delta).clamp(0, 23 * 60 + 59);
    });
  }

  void _simulateOCR() {
    setState(() => _ocrState = 'loading');
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final success = DateTime.now().millisecond % 10 < 7;
      setState(() {
        if (success) {
          _ocrState = 'success';
          _nameController.text = '혈압강하제';
          _timeEnabled['아침'] = true;
          _timeEnabled['점심'] = false;
          _timeEnabled['저녁'] = true;
          _timeEnabled['취침'] = false;
        } else {
          _ocrState = 'failed';
        }
      });
    });
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
          '약 추가',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_ocrState == 'idle') ..._idleSection(),
            if (_ocrState == 'loading') ..._loadingSection(),
            if (_ocrState == 'success') ..._statusBanner(true),
            if (_ocrState == 'failed') ..._statusBanner(false),
            if (_ocrState == 'success' || _ocrState == 'failed') ..._formSection(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _idleSection() => [
        const Text(
          '약 사진을 찍어주세요',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 8),
        const Text(
          '사진으로 약 정보를 자동으로 읽어드려요',
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _BigButton(
                icon: Icons.camera_alt_rounded,
                label: '사진 찍기',
                onTap: _simulateOCR,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _BigButton(
                icon: Icons.photo_library_rounded,
                label: '갤러리',
                onTap: _simulateOCR,
              ),
            ),
          ],
        ),
      ];

  List<Widget> _loadingSection() => [
        const SizedBox(height: 60),
        const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A90D9), strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            '약 정보를 읽고 있어요...',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
          ),
        ),
      ];

  List<Widget> _statusBanner(bool success) => [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (success ? const Color(0xFF4CAF50) : const Color(0xFFE53935))
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: success ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: success ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                success ? '약 정보를 읽었어요!' : '읽기 실패 — 직접 설정해주세요',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: success ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ];

  List<Widget> _formSection(BuildContext context) => [
        const Text('약 이름', style: TextStyle(fontSize: 18, color: Color(0xFF666666))),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '약 이름 입력',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '복용 시간 설정',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 12),
        ..._times.keys.map((slot) => _TimeRow(
              slot: slot,
              enabled: _timeEnabled[slot]!,
              formattedTime: _formatTime(_times[slot]!),
              onToggle: (v) => setState(() => _timeEnabled[slot] = v),
              onAdjust: (delta) => _adjustTime(slot, delta),
            )),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90D9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              '저장',
              style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ];
}

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BigButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 52, color: const Color(0xFF4A90D9)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String slot;
  final bool enabled;
  final String formattedTime;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onAdjust;

  const _TimeRow({
    required this.slot,
    required this.enabled,
    required this.formattedTime,
    required this.onToggle,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? const Color(0xFF4A90D9) : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: const Color(0xFF4A90D9),
              ),
              Text(
                slot,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: enabled ? const Color(0xFF1A1A2E) : const Color(0xFFCCCCCC),
                ),
              ),
            ],
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AdjBtn(label: '- 1h', onTap: () => onAdjust(-60)),
                  const SizedBox(width: 6),
                  _AdjBtn(label: '- 30m', onTap: () => onAdjust(-30)),
                  const SizedBox(width: 14),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90D9),
                    ),
                  ),
                  const SizedBox(width: 14),
                  _AdjBtn(label: '+ 30m', onTap: () => onAdjust(30)),
                  const SizedBox(width: 6),
                  _AdjBtn(label: '+ 1h', onTap: () => onAdjust(60)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AdjBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AdjBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4A90D9).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A90D9),
          ),
        ),
      ),
    );
  }
}
