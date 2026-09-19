import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

class ImageHttpClient extends Fake implements HttpClient {
  final List<int> bytes;
  ImageHttpClient(this.bytes);
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImageRequest(bytes);
}

class _ImageRequest extends Fake implements HttpClientRequest {
  final List<int> bytes;
  _ImageRequest(this.bytes);
  @override
  Future<HttpClientResponse> close() async => _ImageResponse(bytes);
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> bytes;
  _ImageResponse(this.bytes);
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
