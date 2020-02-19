import 'package:path/path.dart' as path;
import 'package:vm_service_lib/vm_service_lib.dart' show Log;
import 'package:vm_service_lib/vm_service_lib_io.dart' show vmServiceConnect;
import 'package:watcher/watcher.dart' show DirectoryWatcher, WatchEvent;

/// Uses the Dart VM's `reloadSources` feature to reload all sources of the
/// running isolate whenever [directory] changes. Assumes a running Dart VM
/// service at [host] with [port].
Stream<WatchEvent> reloadSourcesOnChanges(
    {String directory = '', String host = 'localhost', int port = 8181}) {
  final dir = path.absolute(directory);
  print('Watching $dir for hot reload');
  final w = DirectoryWatcher(dir);
  return w.events.asyncMap((event) async {
    await _reloadSources(host, port);
    return event;
  });
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