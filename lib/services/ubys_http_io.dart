import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// Native implementasyonu — Dio + CookieJar ile tam otomatik cookie yönetimi.
class UbysHttp {
  static const _base = 'https://ubys.munzur.edu.tr';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Safari/537.36';

  final CookieJar _jar = CookieJar();
  late final Dio _dio;

  UbysHttp() {
    _dio = Dio(BaseOptions(
      baseUrl: _base,
      followRedirects: true,
      maxRedirects: 10,
      responseType: ResponseType.plain,
      validateStatus: (s) => s != null,
      headers: {
        'User-Agent': _ua,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'tr-TR,tr;q=0.9,en;q=0.8',
      },
    ));
    _dio.interceptors.add(CookieManager(_jar));
  }

  int get cookieCount => 0; // CookieJar otomatik yönetir

  Future<String> get(String path, {String? referer}) async {
    final resp = await _dio.get<String>(
      path,
      options: referer != null
          ? Options(headers: {'Referer': referer})
          : null,
    );
    _log('GET $path → ${resp.statusCode}');
    return resp.data ?? '';
  }

  Future<String> post(
    String path,
    Map<String, String> body, {
    String? referer,
    bool xmlHttpRequest = false,
  }) async {
    final encoded = body.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}'
            '=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final resp = await _dio.post<String>(
      path,
      data: encoded,
      options: Options(
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': referer,
          if (xmlHttpRequest) 'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
    _log('POST $path → ${resp.statusCode}');
    return resp.data ?? '';
  }

  void dispose() => _dio.close();

  void _log(String msg) => print('[HTTP] $msg'); // ignore: avoid_print
}
