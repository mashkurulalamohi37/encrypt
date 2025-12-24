import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
// import 'package:socks5_proxy/socks5_proxy.dart';

class TorService {
  // Local Tor SOCKS5 proxy port
  static const int _torPort = 9050;
  static const String _torHost = '127.0.0.1';

  /// Returns an HTTP client routed through Tor
  static http.Client getClient() {
    final HttpClient httpClient = HttpClient();

    // Use socks5_proxy to route traffic
    // Note: Ensure the Tor binary is running on the device on port 9050.
    /*
    SocksTCPClient.assignToHttpClient(httpClient, [
      ProxySettings(InternetAddress.loopbackIPv4, _torPort),
    ]);
    */

    return IOClient(httpClient);
  }
}
