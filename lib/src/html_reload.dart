import 'dart:async';

import 'package:shelf/shelf.dart' show Handler, Middleware, Request, Response;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Reloads an HTML page whenever the [broadcast] streams a new event.
/// The reload is done by injecting a short JS snippet that listens to the
/// event stream using a web socket and then calls `window.location.reload()`.
/// For the hot reload to have any effect, the Dart VM needs to have already
/// reloaded its isolate sources.
Middleware hotReloadOnEvent(Stream broadcast) => (innerHandler) {
      return (request) => _wrap(broadcast, innerHandler, request);
    };

Handler _wsHandler(Stream broadcast) =>
    webSocketHandler((WebSocketChannel webSocket) {
      final subscription = broadcast.listen((dynamic message) async {
        webSocket.sink.add('ping');
      });
      webSocket.stream
          .listen((dynamic message) async {}, onDone: subscription.cancel);
    });

Future<Response> _wrap(
    Stream broadcast, Handler innerHandler, Request request) async {
  if (request.headers.containsKey('Upgrade') &&
      request.headers['Upgrade'].toLowerCase() == 'websocket') {
    return _wsHandler(broadcast)(request);
  }
  return _injectListener(innerHandler, request);
}

Future<Response> _injectListener(Handler innerHandler, Request request) async {
  if (request.method == 'GET') {
    final r =
        Request('GET', request.requestedUri, headers: {'accept': 'text/html'});
    final response = await innerHandler(r);
    final websocketUri = request.requestedUri.replace(scheme: 'ws');
    final body = (await response.readAsString())
        .replaceFirst('<head>', '<head>${_websocketInjection(websocketUri)}');
    return response.change(body: body);
  }
  return innerHandler(request);
}

String _websocketInjection(Uri websocketUri) => '''
<script type="application/javascript">
    const socket = new WebSocket('$websocketUri');
    socket.addEventListener('message', function (event) {
        socket.close();
        window.location.reload();
    });
</script>
''';
