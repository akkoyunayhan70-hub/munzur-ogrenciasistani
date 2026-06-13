import 'package:flutter/material.dart';
import '../models/grade.dart';
import '../services/ubys_service.dart';

class GradesScreen extends StatefulWidget {
  final UbysService service;

  const GradesScreen({super.key, required this.service});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  List<Grade>? _grades;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    setState(() {
      _loading = true;
      _error = null;
      _grades = null;
    });

    try {
      final grades = await widget.service.fetchGrades();
      setState(() => _grades = grades);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetchGrades,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchGrades,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_grades == null) return const SizedBox.shrink();

    if (_grades!.isEmpty) {
      return const Center(child: Text('Hiç not bulunamadı.'));
    }

    return _buildGroupedList();
  }

  Widget _buildGroupedList() {
    final Map<String, List<Grade>> byTerm = {};
    for (final g in _grades!) {
      (byTerm[g.semester] ??= []).add(g);
    }

    final terms = byTerm.keys.toList()
      ..sort((a, b) => _termNum(b).compareTo(_termNum(a)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: terms.length,
      itemBuilder: (context, i) {
        final term = terms[i];
        return _TermCard(term: term, courses: byTerm[term]!);
      },
    );
  }

  int _termNum(String s) {
    final m = RegExp(r'(\d+)').firstMatch(s);
    return m != null ? int.parse(m.group(1)!) : 0;
  }
}

class _TermCard extends StatefulWidget {
  final String term;
  final List<Grade> courses;

  const _TermCard({required this.term, required this.courses});

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard> {
  bool _expanded = true;

  static double? _coef(String hbn) {
    switch (hbn.toUpperCase()) {
      case 'AA': return 4.00;
      case 'BA': return 3.50;
      case 'BB': return 3.00;
      case 'CB': return 2.50;
      case 'CC': return 2.00;
      case 'DC': return 1.50;
      case 'DD': return 1.00;
      case 'FD': return 0.50;
      case 'FF': return 0.00;
      default: return null;
    }
  }

  String _dano() {
    double weighted = 0;
    double totalCredits = 0;
    for (final g in widget.courses) {
      final coef = _coef(g.letterGrade);
      if (coef == null) continue;
      final kred = double.tryParse(
            g.credits.split('|').first.trim().replaceAll(',', '.')) ?? 0;
      if (kred <= 0) continue;
      weighted += kred * coef;
      totalCredits += kred;
    }
    if (totalCredits == 0) return '-';
    return (weighted / totalCredits).toStringAsFixed(2);
  }

  Color _danoColor(String dano) {
    final v = double.tryParse(dano);
    if (v == null) return Colors.grey;
    if (v >= 3.0) return const Color(0xFF3AAFA9);
    if (v >= 2.0) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final dano = _dano();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.courses.length} ders',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dano != '-')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _danoColor(dano).withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _danoColor(dano).withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DANO ',
                            style: TextStyle(
                              fontSize: 11,
                              color: _danoColor(dano),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            dano,
                            style: TextStyle(
                              fontSize: 13,
                              color: _danoColor(dano),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...widget.courses.map((g) => _GradeTile(grade: g)),
        ],
      ),
    );
  }
}

class _GradeTile extends StatelessWidget {
  final Grade grade;

  const _GradeTile({required this.grade});

  Color _gradeColor(String hbn) {
    switch (hbn.toUpperCase()) {
      case 'AA':
        return Colors.green.shade700;
      case 'BA':
        return Colors.green.shade500;
      case 'BB':
        return Colors.lightGreen.shade600;
      case 'CB':
        return Colors.amber.shade700;
      case 'CC':
        return Colors.orange.shade700;
      case 'DC':
        return Colors.deepOrange.shade600;
      case 'DD':
        return Colors.red.shade400;
      case 'FF':
      case 'FD':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol: ders bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.courseCode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    grade.courseName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Vize / Final satırı
                  Row(
                    children: [
                      _ScoreChip(label: 'Vize', value: grade.midterm),
                      const SizedBox(width: 8),
                      _ScoreChip(label: 'Final', value: grade.final_),
                    ],
                  ),
                  if (grade.status.isNotEmpty && grade.status != 'Durumu Netleşmemiş')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        grade.status,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Sağ: HBN kutusu
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _gradeColor(grade.letterGrade),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                grade.letterGrade,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }
}
