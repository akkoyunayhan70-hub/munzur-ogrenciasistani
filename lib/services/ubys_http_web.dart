import 'package:http/browser_client.dart';

/// Web implementasyonu.
/// BrowserClient + withCredentials=true ile tarayıcının kendi cookie store'u
/// ve redirect mekanizması devreye giriyor — manuel cookie yönetimi yok.
class UbysHttp {
  static const _base = 'https://ubys.munzur.edu.tr';
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Safari/537.36';

  final BrowserClient _client = BrowserClient()..withCredentials = true;

  Future<String> get(String path, {String? referer}) async {
    final res = await _client.get(
      Uri.parse('$_base$path'),
      headers: _headers(referer: referer),
    );
    return res.body;
  }

  Future<String> post(
    String path,
    Map<String, String> body, {
    String? referer,
    bool xmlHttpRequest = false,
  }) async {
    final headers = _headers(referer: referer);
    headers['Content-Type'] = 'application/x-www-form-urlencoded';
    if (xmlHttpRequest) headers['X-Requested-With'] = 'XMLHttpRequest';

    final res = await _client.post(
      Uri.parse('$_base$path'),
      headers: headers,
      body: body,
    );
    return res.body;
  }

  void dispose() => _client.close();

  Map<String, String> _headers({String? referer}) => {
        'User-Agent': _ua,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'tr-TR,tr;q=0.9,en;q=0.8',
        if (referer != null) 'Referer': referer, // ignore: use_null_aware_elements
      };
}
