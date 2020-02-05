import 'package:shelf/shelf.dart' show Middleware;

import 'directory_reload_sources.dart';
import 'html_reload.dart';

/// Watches [directory] and calls Dart VM's `reloadSources` whenever files
/// change. After every change an event is pushed out using web sockets to all
/// HTML pages served by this middleware, which are reloaded using an injected
/// JS snippet that calls `window.location.reload()`.
/// Assumes a running Dart VM service (debug mode) at [host] : [port].
Middleware hotReload(
        {String directory = '', String host = 'localhost', int port = 8181}) =>
    hotReloadOnEvent(
        reloadSourcesOnChanges(directory: directory, host: host, port: port));
