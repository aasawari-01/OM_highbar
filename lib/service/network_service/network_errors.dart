import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// True when a request failed because the server could not be reached (no
/// internet / no route / timeout), as opposed to the server answering with an
/// error. Offline-capable actions are saved locally only for these.
bool isNetworkError(Object e) =>
    e is SocketException ||
    e is TimeoutException ||
    e is HandshakeException ||
    e is http.ClientException;
