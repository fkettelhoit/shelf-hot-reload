Hot reload for the shelf web server
------------------------------------

This library watches a directory (by default your working directory) for
changes, reloads all the Dart sources of the running isolate and then reloads
all the HTML pages served using this middleware.

The reload of the Dart sources is done using the Dart VM Service's
`reloadSources`, which requires a running Dart VM with debugging enabled at
`localhost:8181` (or whatever you pass as `host` and `port`). In most cases
it should be enough to start the Dart process with the arguments
`--observe --disable-service-auth-codes`.

The reload of the pages served by the middleware based on these change events
is done using an injected JS snippet that listens to a web socket and then
calls `window.location.reload()`.

Since hot reload needs to reload the page, only `GET` requests are injected
with the hot reload functionality. To make sure that hot reload works properly
after `POST` requests, make sure to follow a
[Post/Redirect/Get](https://en.wikipedia.org/wiki/Post/Redirect/Get) pattern,
for example by returning a `303` response pointing to the same url, just with
a `GET`:

```dart
final redirected = request.url.replace(path: '/${request.url.path}');
return Response.seeOther(redirected);
```
