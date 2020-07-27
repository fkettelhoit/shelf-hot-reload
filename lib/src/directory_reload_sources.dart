import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:vm_service_lib/vm_service_lib.dart' show Log;
import 'package:vm_service_lib/vm_service_lib_io.dart' show vmServiceConnect;
import 'package:watcher/watcher.dart' show DirectoryWatcher, WatchEvent;

typedef OnWatchEventFn = FutureOr<void> Function(String path);

/// Uses the Dart VM's `reloadSources` feature to reload all sources of the
/// running isolate whenever [directory] changes. Assumes a running Dart VM
/// service at [host] with [port].
Stream<WatchEvent> reloadSourcesOnChanges(
    {String directory = '',
    String host = 'localhost',
    int port = 8181,
    Set<String> allowedFileEndings = const {},
    OnWatchEventFn onWatchEvent}) {
  final dir = path.absolute(directory);
  print('Watching $dir for hot reload');
  final w = DirectoryWatcher(dir);
  final events = w.events.asBroadcastStream();

  events.handleError((dynamic e) {
    print('error in stream: $e');
  });

  final changeEvents = events
      .where((e) =>
          allowedFileEndings.isEmpty ||
          allowedFileEndings.contains(e.path.split('.').last))
      .asBroadcastStream();

  final reloadEvents = changeEvents.asyncMap((event) async {
    print('${event.path} has changed, reloading sources...');
    await _reloadSources(host, port);
    if (onWatchEvent != null) await onWatchEvent(event.path);
    return event;
  }).asBroadcastStream();

  // necessary to consume the stream
  reloadEvents.listen((event) {});

  return reloadEvents;
}

void _reloadSources(String host, int port) async {
  final serviceClient = await vmServiceConnect(host, port, log: _StdoutLog());
  final vm = await serviceClient.getVM();
  final isolates = vm.isolates.map((isolate) => isolate.id);
  for (final id in isolates) {
    final report = await serviceClient.reloadSources(id);
    if (report.success) {
      final details = report.json['details'] as Map<String, dynamic>;
      final loaded = details['loadedLibraryCount'] as int;
      final total = details['finalLibraryCount'] as int;
      print('Reloaded $loaded/$total libraries');
    } else {
      final notices = report.json['notices'] as List<dynamic>;
      for (final notice in notices) {
        final message = notice['message'] as String;
        print(message);
      }
    }
  }
}

class _StdoutLog extends Log {
  void warning(String message) => print(message);
  void severe(String message) => print(message);
}
