import 'package:flutter/material.dart';
import '../models/grade.dart';
import '../services/ubys_service.dart';

const _grades = ['AA', 'BA', 'BB', 'CB', 'CC', 'DC', 'DD', 'FD', 'FF'];

double? _coef(String? hbn) {
  switch (hbn) {
    case 'AA': return 4.00;
    case 'BA': return 3.50;
    case 'BB': return 3.00;
    case 'CB': return 2.50;
    case 'CC': return 2.00;
    case 'DC': return 1.50;
    case 'DD': return 1.00;
    case 'FD': return 0.50;
    case 'FF': return 0.00;
    default:   return null;
  }
}

Color _gradeColor(String? hbn) {
  switch (hbn) {
    case 'AA': return const Color(0xFF2E7D32);
    case 'BA': return const Color(0xFF388E3C);
    case 'BB': return const Color(0xFF689F38);
    case 'CB': return const Color(0xFFF57F17);
    case 'CC': return const Color(0xFFE65100);
    case 'DC': return const Color(0xFFBF360C);
    case 'DD': return const Color(0xFFD32F2F);
    case 'FD':
    case 'FF': return const Color(0xFFB71C1C);
    default:   return Colors.grey.shade400;
  }
}

class HesaplaScreen extends StatefulWidget {
  final UbysService service;
  const HesaplaScreen({super.key, required this.service});

  @override
  State<HesaplaScreen> createState() => _HesaplaScreenState();
}

class _HesaplaScreenState extends State<HesaplaScreen> {
  // courseKey → seçili harf notu
  final Map<String, String?> _selected = {};

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onUpdate);
    _syncFromGrades();
  }

  @override
  void dispose() {
    widget.service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    _syncFromGrades();
    if (mounted) setState(() {});
  }

  void _syncFromGrades() {
    for (final g in widget.service.cachedGrades) {
      final k = _key(g);
      if (!_selected.containsKey(k)) {
        final hbn = g.letterGrade;
        _selected[k] = _grades.contains(hbn) ? hbn : null;
      }
    }
  }

  String _key(Grade g) => '${g.semester}__${g.courseCode}';

  double? _kred(Grade g) =>
      double.tryParse(g.credits.split('|').first.trim().replaceAll(',', '.'));

  String _calcDano(List<Grade> courses) {
    double w = 0, cr = 0;
    for (final g in courses) {
      final hbn = _selected[_key(g)];
      final coef = _coef(hbn);
      final kred = _kred(g) ?? 0;
      if (coef == null || kred <= 0) continue;
      w += kred * coef;
      cr += kred;
    }
    return cr == 0 ? '-' : (w / cr).toStringAsFixed(2);
  }

  String _calcGano(List<Grade> all) {
    double w = 0, cr = 0;
    for (final g in all) {
      final hbn = _selected[_key(g)];
      final coef = _coef(hbn);
      final kred = _kred(g) ?? 0;
      if (coef == null || kred <= 0) continue;
      w += kred * coef;
      cr += kred;
    }
    return cr == 0 ? '-' : (w / cr).toStringAsFixed(2);
  }

  Color _danoColor(String dano) {
    final v = double.tryParse(dano);
    if (v == null) return Colors.grey;
    if (v >= 3.0) return const Color(0xFF3AAFA9);
    if (v >= 2.0) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  int _termNum(String s) {
    final m = RegExp(r'(\d+)').firstMatch(s);
    return m != null ? int.parse(m.group(1)!) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final grades = widget.service.cachedGrades;

    if (grades.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hesap Makinesi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calculate_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Önce Notlarım sekmesini açıp notları yükle.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final byTerm = <String, List<Grade>>{};
    for (final g in grades) {
      (byTerm[g.semester] ??= []).add(g);
    }
    final terms = byTerm.keys.toList()
      ..sort((a, b) => _termNum(b).compareTo(_termNum(a)));

    final gano = _calcGano(grades);

    return Scaffold(
      appBar: AppBar(title: const Text('Hesap Makinesi')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: terms.length,
              itemBuilder: (_, i) {
                final term = terms[i];
                final courses = byTerm[term]!;
                final dano = _calcDano(courses);
                return _TermCard(
                  term: term,
                  courses: courses,
                  dano: dano,
                  danoColor: _danoColor(dano),
                  selected: _selected,
                  keyOf: _key,
                  onChanged: (k, val) => setState(() => _selected[k] = val),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            const Text(
              'Tahmini GANO',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF2B4141),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF3AAFA9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                gano,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermCard extends StatefulWidget {
  final String term;
  final List<Grade> courses;
  final String dano;
  final Color danoColor;
  final Map<String, String?> selected;
  final String Function(Grade) keyOf;
  final void Function(String key, String? val) onChanged;

  const _TermCard({
    required this.term,
    required this.courses,
    required this.dano,
    required this.danoColor,
    required this.selected,
    required this.keyOf,
    required this.onChanged,
  });

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.term.isEmpty ? 'Dönem' : widget.term,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${widget.courses.length} ders',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  if (widget.dano != '-') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.danoColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: widget.danoColor.withAlpha(60)),
                      ),
                      child: Text(
                        'DANO ${widget.dano}',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.danoColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.courses.map((g) {
              final k = widget.keyOf(g);
              final hbn = widget.selected[k];
              final kred = g.credits.split('|').first.trim()
                  .replaceAll(',', '.')
                  .replaceAll(RegExp(r'\.0+$'), '');
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.courseName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$kred kredi',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Harf notu dropdown
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _gradeColor(hbn).withAlpha(hbn != null ? 220 : 30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _gradeColor(hbn).withAlpha(hbn != null ? 180 : 80),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: hbn,
                          hint: Text(
                            '  —  ',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: hbn != null ? Colors.white : Colors.grey,
                            size: 18,
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('  —  ',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.normal)),
                            ),
                            ..._grades.map((gr) => DropdownMenuItem<String?>(
                                  value: gr,
                                  child: Text(
                                    gr,
                                    style: TextStyle(
                                      color: _gradeColor(gr),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )),
                          ],
                          onChanged: (val) => widget.onChanged(k, val),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
