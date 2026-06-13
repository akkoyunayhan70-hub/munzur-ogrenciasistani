import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import '../models/grade.dart';
import 'ubys_http.dart';

class UbysService {
  static const String _baseUrl = 'https://ubys.munzur.edu.tr';

  final _http = UbysHttp();

  Future<bool> login(String username, String password) async {
    final loginHtml = await _http.get('/');
    final doc = html_parser.parse(loginHtml);

    String formAction = '/Account/Login';
    String? csrfToken;

    for (final form in doc.querySelectorAll('form')) {
      if (form.querySelector('input[name="username"]') != null) {
        formAction = form.attributes['data-ajax-url'] ??
            form.attributes['action'] ??
            '/Account/Login';
        csrfToken = form
            .querySelector('input[name="__RequestVerificationToken"]')
            ?.attributes['value'];
        _log('Login formu: action=$formAction');
        break;
      }
    }

    csrfToken ??= doc
        .querySelector('input[name="__RequestVerificationToken"]')
        ?.attributes['value'];

    if (csrfToken == null) {
      _log('CSRF token alınamadı.');
      return false;
    }

    final body = await _http.post(
      formAction,
      {
        'username': username,
        'password': password,
        '__RequestVerificationToken': csrfToken,
      },
      referer: _baseUrl,
    );

    final failed = body.contains('Kullanıcı adı veya şifre hatalı') ||
        body.contains('Hatalı giriş') ||
        body.contains('name="username"');
    _log('Giriş ${failed ? "BAŞARISIZ" : "BAŞARILI"}');
    return !failed;
  }

  Future<List<Grade>> fetchGrades() async {
    _log('Dashboard\'a bağlanıyor...');
    String pageHtml = await _http.get('/AIS/Student/Home/Index');

    // Anket sayfasındaysa atla
    if (pageHtml.contains('RememberLaterThisSurvey') ||
        pageHtml.contains('PortalSurveyManagement')) {
      _log('Anket tespit edildi, atlanıyor...');
      final docSurvey = html_parser.parse(pageHtml);
      final surveyLink = docSurvey
          .querySelectorAll('a[href]')
          .map((e) => e.attributes['href'] ?? '')
          .where((h) => h.contains('RememberLaterThisSurvey'))
          .firstOrNull;

      if (surveyLink != null) {
        await _http.get(surveyLink);
        pageHtml = await _http.get('/AIS/Student/Home/Index');
      }
    }

    _log('Dashboard: ${html_parser.parse(pageHtml).querySelector("title")?.text}');

    // Base64 JSON'dan EncryptedStudentAcademicProgramId'yi çıkar
    final encSapid = _extractEncryptedSapid(pageHtml);
    if (encSapid == null) {
      throw Exception(
        'Öğrenci program ID\'si bulunamadı. Lütfen tekrar giriş yapın.',
      );
    }

    _log('EncryptedSapid: $encSapid');
    final classHtml = await _http.get(
      '/AIS/Student/Class/Index?sapid=$encSapid',
      referer: '$_baseUrl/AIS/Student/Home/Index',
    );

    _log('Class sayfası uzunluğu: ${classHtml.length}');
    return _parseClassIndex(classHtml);
  }

  void dispose() => _http.dispose();

  /// Dashboard HTML'indeki Base64 JSON'dan şifreli sapid'i çıkarır
  String? _extractEncryptedSapid(String html) {
    for (final m in RegExp(r'Base64\.decode\("([^"]+)"\)').allMatches(html)) {
      try {
        final decoded = utf8.decode(base64.decode(m.group(1)!));
        if (!decoded.contains('"Programs"')) continue;
        final em = RegExp(
          r'"EncryptedStudentAcademicProgramId"\s*:\s*"([^"]+)"',
        ).firstMatch(decoded);
        if (em != null) return em.group(1);
      } catch (_) {}
    }
    return null;
  }

  /// Dönem adını table id'sinden çıkarır (e.g. "Bahar2025table" → "Bahar 2025")
  String _parseSemesterName(String tableId) {
    final m = RegExp(r'([A-ZÇĞİÖŞÜa-zçğışöüA-Z]+)(\d{4})').firstMatch(tableId);
    if (m != null) return '${m.group(1)} ${m.group(2)}';
    return tableId.replaceAll('table', '').trim();
  }

  List<Grade> _parseClassIndex(String html) {
    final doc = html_parser.parse(html);
    final grades = <Grade>[];

    for (final table in doc.querySelectorAll(
      'table.table.table-bordered.table-striped',
    )) {
      final tableId = table.attributes['id'] ?? '';
      final semester = _parseSemesterName(tableId);

      final rows = table.querySelectorAll('tbody > tr').toList();
      int i = 0;
      while (i < rows.length) {
        final mainRow = rows[i];
        final courseLink = mainRow.querySelector('a[data-class-id]');
        if (courseLink == null) {
          i++;
          continue;
        }

        final courseCode = courseLink.text.trim();
        final cells = mainRow.querySelectorAll('td').toList();

        // cells sırası: [0]=code [1]=ad [2]=kredi [3]=akts [4]=koordinatör
        //               [5]=devam [6]=geçme notu [7]=HBN [8]=başarı [9]=action
        final courseName = cells.length > 1 ? cells[1].text.trim() : '';
        final kredi = cells.length > 2 ? cells[2].text.trim() : '';
        final akts = cells.length > 3 ? cells[3].text.trim() : '';
        final credits = '$kredi | $akts';
        final hbn = cells.length > 7 ? cells[7].text.trim() : '';
        final status =
            cells.length > 8 ? cells[8].text.trim().replaceAll(RegExp(r'\s+'), ' ') : '';

        // Sonraki satır: Vize/Final iç tablosu
        String midterm = '-';
        String finalGrade = '-';
        if (i + 1 < rows.length) {
          final detailRow = rows[i + 1];
          final innerTable = detailRow.querySelector('table');
          if (innerTable != null) {
            for (final r in innerTable.querySelectorAll('tr')) {
              final tds = r.querySelectorAll('td').toList();
              if (tds.length < 2) continue;
              final label = tds[0].text.trim().toLowerCase();
              final value = tds[1].text.trim();
              if (label.contains('vize')) midterm = value;
              if (label.contains('final')) finalGrade = value;
            }
            i += 2;
          } else {
            i++;
          }
        } else {
          i++;
        }

        if (courseCode.isEmpty || courseName.isEmpty) continue;

        grades.add(Grade(
          courseCode: courseCode,
          courseName: courseName,
          semester: semester,
          credits: credits,
          midterm: midterm.isEmpty ? '-' : midterm,
          final_: finalGrade.isEmpty ? '-' : finalGrade,
          letterGrade: hbn.isEmpty ? '-' : hbn,
          status: status,
        ));
      }
    }

    _log('Toplam ${grades.length} ders bulundu.');
    return grades;
  }

  void _log(String msg) => print('[UBYS] $msg'); // ignore: avoid_print
}
