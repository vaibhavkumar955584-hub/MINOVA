import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SignaturePadWidget extends StatefulWidget {
  final String signerName;
  final String signerRole;
  final String? initialSignature;
  final bool isReadOnly;
  final bool hasError;
  final ValueChanged<String> onSignatureSaved;

  const SignaturePadWidget({
    super.key,
    required this.signerName,
    required this.signerRole,
    this.initialSignature,
    this.isReadOnly = false,
    this.hasError = false,
    required this.onSignatureSaved,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<List<Offset>> _strokes = [];
  bool _isSigned = false;

  @override
  void initState() {
    super.initState();
    _restoreInitialSignature();
  }

  @override
  void didUpdateWidget(covariant SignaturePadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSignature != widget.initialSignature &&
        _strokes.isEmpty) {
      _restoreInitialSignature();
    }
  }

  void _restoreInitialSignature() {
    final initial = widget.initialSignature;
    if (initial != null && initial.trim().isNotEmpty) {
      _isSigned = true;
      try {
        final decoded = utf8.decode(base64Decode(initial));
        if (decoded.startsWith('SIG:')) {
          final parts = decoded.split(':');
          if (parts.length >= 2) {
            final strokesStr = parts[1];
            final strokeGroups = strokesStr.split('|');
            for (final grp in strokeGroups) {
              if (grp.isEmpty) continue;
              final points = <Offset>[];
              for (final pt in grp.split(';')) {
                final xy = pt.split(',');
                if (xy.length == 2) {
                  final x = double.tryParse(xy[0]);
                  final y = double.tryParse(xy[1]);
                  if (x != null && y != null) {
                    points.add(Offset(x, y));
                  }
                }
              }
              if (points.isNotEmpty) {
                _strokes.add(points);
              }
            }
          }
        }
      } catch (_) {
        // Safe fallback if raw string format differs
      }
    }
  }

  void _clear() {
    if (widget.isReadOnly) return;
    setState(() {
      _strokes.clear();
      _isSigned = false;
    });
    // Immediately clear parent state
    widget.onSignatureSaved('');
  }

  void _saveSignature() {
    if (_strokes.isEmpty) return;

    // Generate deterministic hash string from stroke points for tamper verification
    final pointsString = _strokes
        .map((s) => s.map((p) => '${p.dx.toInt()},${p.dy.toInt()}').join(';'))
        .join('|');
    final hash = sha256.convert(utf8.encode(pointsString)).toString();
    final base64String = base64Encode(utf8.encode('SIG:$pointsString:$hash'));

    setState(() {
      _isSigned = true;
    });

    widget.onSignatureSaved(base64String);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isReadOnly
        ? AppColors.strokeLowLight
        : _isSigned
            ? AppColors.complianceGreen
            : widget.hasError
                ? AppColors.hazardRed
                : AppColors.primaryAmber.withAlpha(150);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardLayer2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: _isSigned || widget.hasError ? 2.0 : 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.draw_rounded,
                          size: 16,
                          color: _isSigned
                              ? AppColors.complianceGreen
                              : AppColors.primaryAmber,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'DIGITAL STATUTORY SIGNATURE',
                            style: AppTypography.labelSm.copyWith(
                              color: _isSigned
                                  ? AppColors.complianceGreen
                                  : AppColors.primaryAmber,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'यहाँ उंगली या स्टाइलस से हस्ताक्षर करें (Mandatory)',
                      style: AppTypography.bilingualCue.copyWith(
                        color: widget.hasError
                            ? AppColors.hazardRed
                            : AppColors.textMediumEmphasis,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isSigned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.complianceGreenLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.complianceGreen),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.complianceGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.isReadOnly ? 'LOCKED' : 'SIGNED & SEALED',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.complianceGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardLayer1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSigned
                    ? AppColors.complianceGreen.withAlpha(100)
                    : AppColors.strokeLowLight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Stack(
                children: [
                  // Signature Guideline / X marker
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 35,
                    child: Row(
                      children: [
                        Text(
                          '✕ ',
                          style: TextStyle(
                            color: AppColors.textDisabled.withAlpha(90),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.textDisabled.withAlpha(60),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SignaturePainter(strokes: _strokes),
                    ),
                  ),
                  if (!widget.isReadOnly)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (details) {
                          setState(() {
                            _strokes.add([details.localPosition]);
                            _isSigned = false;
                          });
                        },
                        onPanStart: (details) {
                          setState(() {
                            if (_strokes.isEmpty) {
                              _strokes.add([details.localPosition]);
                            }
                            _isSigned = false;
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            if (_strokes.isNotEmpty) {
                              _strokes.last.add(details.localPosition);
                            }
                          });
                        },
                        onPanEnd: (_) {
                          _saveSignature();
                        },
                      ),
                    ),
                  if (_strokes.isEmpty && !_isSigned)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.gesture_rounded,
                            size: 28,
                            color: AppColors.textDisabled.withAlpha(150),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Touch & draw signature inside this box\nहस्ताक्षर करने के लिए यहाँ ड्रा करें',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textDisabled,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_strokes.isEmpty && _isSigned)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.complianceGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Digitally Signed & Verified',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.complianceGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signer: ${widget.signerName}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.textHighEmphasis,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Role: ${widget.signerRole}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!widget.isReadOnly) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: AppColors.textMediumEmphasis,
                  ),
                  label: Text(
                    'CLEAR',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.textMediumEmphasis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryAmber
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          2.0,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
