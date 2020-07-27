import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_hot_reload/shelf_hot_reload.dart' as shelf_hot_reload;

/// Must be launched with the VM arguments:
/// --observe --disable-service-auth-codes
void main(List<String> args) async {
  final port = 8283;

  final pipeline = shelf.Pipeline()
      .addMiddleware(shelf_hot_reload.hotReload())
      .addHandler(_handler);

  final server = await shelf_io.serve(pipeline, '0.0.0.0', port);
  print('Serving at http://${server.address.host}:${server.port}');
}

FutureOr<shelf.Response> _handler(shelf.Request request) =>
    shelf.Response.ok('''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8"/>
    <title>Hot Reload Example</title>
</head>
<body>
  <h1>Change this, save the file and wait for the hot reload</h1>
</body>
</html>
''', headers: {'content-type': 'text/html'});
