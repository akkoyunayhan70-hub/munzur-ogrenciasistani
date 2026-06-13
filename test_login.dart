import 'dart:io';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;

// dart run test_login.dart <kullanici_adi> <sifre>

void main(List<String> args) async {
  if (args.length < 2) {
    print('Kullanım: dart run test_login.dart <kullanici_adi> <sifre>');
    exit(1);
  }

  final username = args[0];
  final password = args[1];

  const base = 'https://ubys.munzur.edu.tr';
  const ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Safari/537.36';

  final client = HttpClient()
    ..badCertificateCallback = (_, __, ___) => true;

  final cookies = <String, String>{};

  void saveCookies(HttpClientResponse res) {
    res.headers.forEach((name, values) {
      if (name.toLowerCase() != 'set-cookie') return;
      for (final raw in values) {
        final semi = raw.indexOf(';');
        final pair = semi >= 0 ? raw.substring(0, semi) : raw;
        final eq = pair.indexOf('=');
        if (eq > 0) {
          final n = pair.substring(0, eq).trim();
          final v = pair.substring(eq + 1).trim();
          cookies[n] = v;
          print('[COOKIE] $n (${v.length} chars)');
        }
      }
    });
  }

  String buildCookieHeader() =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  void applyHeaders(HttpClientRequest req, {String? referer}) {
    req.headers.set('User-Agent', ua);
    req.headers.set('Accept',
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8');
    req.headers.set('Accept-Language', 'tr-TR,tr;q=0.9,en;q=0.8');
    if (referer != null) req.headers.set('Referer', referer);
    if (cookies.isNotEmpty) req.headers.set('Cookie', buildCookieHeader());
  }

  Future<HttpClientResponse> getUrl(String url) async {
    Uri uri = Uri.parse(url);
    int budget = 10;
    while (budget-- > 0) {
      final req = await client.getUrl(uri);
      req.followRedirects = false;
      applyHeaders(req, referer: uri.toString());
      final res = await req.close();
      saveCookies(res);
      print('[GET] ${res.statusCode} ${uri.path}');
      if ([301, 302, 303, 307, 308].contains(res.statusCode)) {
        final loc = res.headers.value('location');
        await res.drain<void>();
        if (loc == null) break;
        uri = uri.resolve(loc);
        continue;
      }
      return res;
    }
    throw Exception('Çok fazla yönlendirme');
  }

  Future<String> getText(String url) async {
    final res = await getUrl(url);
    final bytes = await res.fold<List<int>>([], (b, c) => b..addAll(c));
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<String> postForm(String url, Map<String, String> body) async {
    Uri uri = Uri.parse(url);
    int budget = 10;
    bool isPost = true;
    while (budget-- > 0) {
      late HttpClientResponse res;
      if (isPost) {
        final encoded = body.entries
            .map((e) =>
                '${Uri.encodeQueryComponent(e.key)}'
                '=${Uri.encodeQueryComponent(e.value)}')
            .join('&');
        final bytes = utf8.encode(encoded);
        final req = await client.postUrl(uri);
        req.followRedirects = false;
        applyHeaders(req, referer: base);
        req.headers.set('Content-Type', 'application/x-www-form-urlencoded');
        req.headers.set('Content-Length', bytes.length);
        req.add(bytes);
        res = await req.close();
        isPost = false;
      } else {
        final req = await client.getUrl(uri);
        req.followRedirects = false;
        applyHeaders(req, referer: uri.toString());
        res = await req.close();
      }
      saveCookies(res);
      print('[POST→] ${res.statusCode} ${uri.path}');
      if ([301, 302, 303, 307, 308].contains(res.statusCode)) {
        final loc = res.headers.value('location');
        await res.drain<void>();
        if (loc == null) break;
        uri = uri.resolve(loc);
        continue;
      }
      final bytes2 = await res.fold<List<int>>([], (b, c) => b..addAll(c));
      return utf8.decode(bytes2, allowMalformed: true);
    }
    throw Exception('Çok fazla yönlendirme');
  }

  // ── ADIM 1: Login sayfasını al ──
  print('\n=== ADIM 1: Login sayfası ===');
  final loginHtml = await getText(base);
  final doc = html_parser.parse(loginHtml);

  // Login formunu bul
  String formAction = '/';
  String? csrfToken;
  for (final form in doc.querySelectorAll('form')) {
    if (form.querySelector('input[name="username"]') != null) {
      // AJAX URL'yi tercih et (data-ajax-url), yoksa action'ı kullan
      formAction = form.attributes['data-ajax-url'] ??
          form.attributes['action'] ??
          '/';
      csrfToken = form
          .querySelector('input[name="__RequestVerificationToken"]')
          ?.attributes['value'];
      print('[FORM] action=$formAction csrf=${csrfToken != null ? "VAR" : "YOK"}');
      break;
    }
  }
  csrfToken ??= doc
      .querySelector('input[name="__RequestVerificationToken"]')
      ?.attributes['value'];

  // Login formunun tüm hidden inputlarını ve form HTML'ini yazdır
  for (final form in doc.querySelectorAll('form')) {
    if (form.querySelector('input[name="username"]') != null) {
      print('[FORM HTML]:\n${form.outerHtml.substring(0, form.outerHtml.length.clamp(0, 2000))}');
      break;
    }
  }

  if (csrfToken == null) {
    print('HATA: CSRF token alınamadı');
    client.close();
    exit(1);
  }

  // ── ADIM 2: Login POST ──
  print('\n=== ADIM 2: Login POST → $formAction ===');
  final loginResponse = await postForm(
    base + formAction,
    {
      'username': username,
      'password': password,
      '__RequestVerificationToken': csrfToken,
    },
  );

  final isLoginPage = loginResponse.contains('name="username"');
  print('[LOGIN] Hala login sayfasında mı: $isLoginPage');
  print('[LOGIN] Response title: ${html_parser.parse(loginResponse).querySelector("title")?.text}');
  print('[LOGIN] Cookie sayısı: ${cookies.length}');

  if (isLoginPage) {
    // Hata mesajı var mı bak
    final errorEl = html_parser.parse(loginResponse).querySelector('.alert, .error, .validation-summary-errors, [class*="error"], [class*="alert"]');
    print('[HATA MESAJI]: ${errorEl?.text.trim() ?? "bulunamadı"}');
    print('[RESPONSE ilk 1000]:\n${loginResponse.substring(0, loginResponse.length.clamp(0, 1000))}');
    print('\n❌ GİRİŞ BAŞARISIZ — sunucu login sayfasını döndürdü');
    client.close();
    exit(1);
  }

  // ── ADIM 3: Survey/Dashboard ──
  print('\n=== ADIM 3: Dashboard / Survey ===');
  final dashboardHtml = await getText('$base/AIS/Student/Home/Index');
  final doc2 = html_parser.parse(dashboardHtml);
  final title = doc2.querySelector('title')?.text;
  print('[TITLE] $title');

  // Anket sayfasındaysa tüm linklere bak
  final links = doc2.querySelectorAll('a[href]')
      .map((e) => e.attributes['href'] ?? '')
      .where((h) => h.isNotEmpty)
      .toList();
  print('[LİNKLER] ${links.take(20).join(", ")}');

  // Form action'larına da bak
  final forms = doc2.querySelectorAll('form[action]')
      .map((e) => e.attributes['action'] ?? '')
      .toList();
  print('[FORMLAR] $forms');

  // Anket var mı? "RememberLater" linkine git
  String workingHtml = dashboardHtml;
  final surveySkipLink = links.firstWhere(
    (l) => l.contains('RememberLater'),
    orElse: () => '',
  );
  if (surveySkipLink.isNotEmpty) {
    print('\n[ANKET] Atlatılıyor: $surveySkipLink');
    workingHtml = await getText(base + surveySkipLink);
    final t2 = html_parser.parse(workingHtml).querySelector('title')?.text;
    print('[TITLE sonrası] $t2');
  }

  // Dashboard'u dosyaya kaydet
  await File('dashboard.html').writeAsString(workingHtml);
  print('[KAYIT] dashboard.html olarak kaydedildi (${workingHtml.length} chars)');

  // ── ADIM 4: sapid'i Base64 JSON'dan çıkar ──
  print('\n=== ADIM 4: sapid (Base64 JSON) ===');
  String? sapid;
  final b64Matches = RegExp(r'Base64\.decode\("([^"]+)"\)').allMatches(workingHtml);
  for (final m in b64Matches) {
    try {
      final decoded = utf8.decode(base64.decode(m.group(1)!));
      if (decoded.contains('"Programs"')) {
        // Programs[0].StudentAcademicProgramId'yi çıkar
        final sapMatch = RegExp(r'"StudentAcademicProgramId"\s*:\s*(\d+)').firstMatch(decoded);
        if (sapMatch != null) {
          sapid = sapMatch.group(1)!;
          print('[SAPID] Bulundu: $sapid');
          // Ek bilgiler
          final gano = RegExp(r'"GANO"\s*:\s*([\d.]+)').firstMatch(decoded)?.group(1);
          final sinif = RegExp(r'"Class"\s*:\s*(\d+)').firstMatch(decoded)?.group(1);
          print('[GANO] $gano | [SINIF] $sinif');
          break;
        }
      }
    } catch (_) {}
  }

  // ── ADIM 5: Class/Index — şifreli sapid ile dene ──
  // Önce şifreli sapid'i JSON'dan çıkar
  String? encryptedSapid;
  String? encryptedStudentId;
  for (final m in RegExp(r'Base64\.decode\("([^"]+)"\)').allMatches(workingHtml)) {
    try {
      final decoded = utf8.decode(base64.decode(m.group(1)!));
      if (decoded.contains('"Programs"')) {
        final em = RegExp(r'"EncryptedStudentAcademicProgramId"\s*:\s*"([^"]+)"').firstMatch(decoded);
        final es = RegExp(r'"EncryptedStudentId"\s*:\s*"([^"]+)"').firstMatch(decoded);
        encryptedSapid = em?.group(1);
        encryptedStudentId = es?.group(1);
        print('[ENC_SAPID] $encryptedSapid');
        print('[ENC_STUDENT_ID] $encryptedStudentId');
        break;
      }
    } catch (_) {}
  }

  if (encryptedSapid != null) {
    print('\n=== ADIM 5: Class/Index?sapid=<encrypted> ===');
    final classHtml = await getText('$base/AIS/Student/Class/Index?sapid=$encryptedSapid');
    print('[CLASS] len=${classHtml.length} title="${html_parser.parse(classHtml).querySelector("title")?.text}"');
    print('[CLASS] table=${classHtml.contains("<table")} tbody=${classHtml.contains("<tbody")}');
    if (classHtml.length > 2000) {
      await File('class_index.html').writeAsString(classHtml);
      print('[KAYIT] class_index.html kaydedildi');
    } else {
      print('[CLASS CONTENT]\n$classHtml');
    }

    // Ayrıca sid parametresi ile de dene
    if (encryptedStudentId != null) {
      print('\n=== ADIM 5b: Class/Index?sid=<encrypted_student_id> ===');
      final classHtml2 = await getText('$base/AIS/Student/Class/Index?sid=$encryptedStudentId');
      print('[CLASS2] len=${classHtml2.length} table=${classHtml2.contains("<table")}');
      if (classHtml2.length < 2000) print('[CLASS2 CONTENT]\n$classHtml2');
    }
  }

  // ── ADIM 4: Transcript URL'yi çıkar ──
  print('\n=== ADIM 4: Transcript URL ===');
  final doc3 = html_parser.parse(workingHtml);
  final transcriptLink = doc3.querySelectorAll('a[href*="Transcript/Index"]')
      .map((e) => e.attributes['href'] ?? '')
      .where((h) => h.isNotEmpty)
      .firstOrNull;
  if (transcriptLink != null) {
    print('[TRANSCRIPT] $transcriptLink');
    final transcriptHtml = await getText('$base$transcriptLink');
    final tTitle = html_parser.parse(transcriptHtml).querySelector('title')?.text ?? '(yok)';
    final hasTable = transcriptHtml.contains('<table') || transcriptHtml.contains('<tbody');
    print('[TRANSCRIPT] title="$tTitle" table=$hasTable len=${transcriptHtml.length}');
    if (transcriptHtml.length < 3000) {
      print('[TRANSCRIPT CONTENT]\n$transcriptHtml');
    } else {
      await File('transcript.html').writeAsString(transcriptHtml);
      print('[KAYIT] transcript.html kaydedildi');
    }
  }

  // ── ADIM 5: JS bundle'dan getStudentClasses endpointini bul ──
  print('\n=== ADIM 5: JS Bundle ===');
  final homeBundle = '/AIS/bundles/AISStudentHomeIndex?v=CLaSbTo8ljcTOK3_y3aFysAJe7cMF_fmetEO7oYY1sA1';
  final layoutBundle = '/AIS/bundles/AISStudentLayoutScripts?v=wLqSMvDaKCj_tzIgZ3-ERWah_Z1KJncToJvxpbLiEJc1';
  for (final bundleUrl in [homeBundle, layoutBundle]) {
    final js = await getText('$base$bundleUrl');
    print('[BUNDLE] ${bundleUrl.split('?').first} len=${js.length}');
    // getStudentClasses fonksiyonunun etrafındaki 200 char'ı çıkar
    final idx = js.indexOf('getStudentClasses');
    if (idx >= 0) {
      final start = (idx - 50).clamp(0, js.length);
      final end = (idx + 300).clamp(0, js.length);
      print('[FOUND getStudentClasses]:\n${js.substring(start, end)}');
    }
    // Herhangi bir AJAX çağrısı için URL pattern ara
    final ajaxMatches = RegExp(r'url\s*:\s*"([^"]+)"').allMatches(js).take(20);
    final ajaxMatchList = ajaxMatches.toList();
    if (ajaxMatchList.isNotEmpty) {
      print('[AJAX URLs in bundle]:');
      for (final m in ajaxMatchList) {
        final u = m.group(1) ?? '';
        if (u.contains('Student') || u.contains('Class') || u.contains('Grade')) {
          print('  $u');
        }
      }
    }
  }

  // ── ADIM 6: Bilinen AJAX endpointleri dene ──
  print('\n=== ADIM 6: AJAX Endpoint Testleri ===');
  final ajaxEndpoints = [
    '/AIS/Student/Home/GetStudentClasses',
    '/AIS/Student/Home/GetClasses',
    '/AIS/Student/Class/GetList',
    '/AIS/Student/Class/GetStudentClassList',
    '/AIS/Student/Home/StudentInfo',
    '/AIS/Student/Home/GetStudentInfo',
  ];
  for (final ep in ajaxEndpoints) {
    try {
      final r = await getText('$base$ep');
      print('[EP] $ep → len=${r.length} preview="${r.substring(0, r.length.clamp(0, 100))}"');
    } catch (e) {
      print('[EP] $ep → HATA: $e');
    }
  }

  print('\n✅ TEST TAMAMLANDI');
  client.close();
}
