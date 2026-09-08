import 'package:app_network_contract/app_network_contract.dart';
import 'package:network_api/network_api.dart';
import 'package:test/test.dart';

RawNetworkResponse _response(Object? body, {int? statusCode = 200}) {
  return RawNetworkResponse(
    statusCode: statusCode,
    body: body,
    headers: const {},
  );
}

NetworkFailure _failure(
  NetworkFailureKind kind, {
  RawNetworkResponse? response,
}) {
  return NetworkFailure(kind: kind, response: response);
}

void main() {
  final parser = AppResponseParser();

  group('parseSuccess', () {
    test('unwraps an object payload and lifts its message', () {
      final result = parser.parseSuccess(
        _response({
          'success': true,
          'data': {'message': 'Saved', 'id': 7},
        }),
      );

      expect(result.statusCode, 200);
      expect(result.message, 'Saved');
      expect(result.dataAsMap, {'id': 7});
    });

    test('does not mutate the decoded body while lifting the message', () {
      final body = {
        'success': true,
        'data': {'message': 'Saved', 'id': 7},
      };

      parser.parseSuccess(_response(body));

      expect(body['data'], {'message': 'Saved', 'id': 7});
    });

    test('keeps the envelope message for a list payload', () {
      final result = parser.parseSuccess(
        _response({
          'success': true,
          'message': 'Listed',
          'data': [
            {'id': 1},
            {'id': 2},
          ],
        }),
      );

      expect(result.message, 'Listed');
      expect(result.dataAsList, hasLength(2));
      expect(result.dataAsMap, isNull);
    });

    test('passes an unenveloped body through as the payload', () {
      final result = parser.parseSuccess(_response({'id': 7}));

      expect(result.dataAsMap, {'id': 7});
      expect(result.message, isNull);
    });

    test('honours an explicitly null data payload', () {
      final result = parser.parseSuccess(
        _response({'success': true, 'data': null, 'message': 'Deleted'}),
      );

      expect(result.data, isNull);
      expect(result.message, 'Deleted');
    });

    test('passes a non map body through untouched', () {
      final result = parser.parseSuccess(_response('plain text'));

      expect(result.data, 'plain text');
      expect(result.message, isNull);
    });
  });

  group('parseFailure', () {
    test('maps a connection failure to no internet', () {
      expect(
        parser.parseFailure(_failure(NetworkFailureKind.connection)),
        isA<AppNoInternetException>(),
      );
    });

    test('maps every timeout kind to a timeout exception', () {
      const timeouts = [
        NetworkFailureKind.connectionTimeout,
        NetworkFailureKind.sendTimeout,
        NetworkFailureKind.receiveTimeout,
      ];

      for (final kind in timeouts) {
        expect(
          parser.parseFailure(_failure(kind)),
          isA<AppTimeoutException>(),
          reason: '$kind should be a timeout',
        );
      }
    });

    test('maps a cancellation and an unknown failure', () {
      expect(
        parser.parseFailure(_failure(NetworkFailureKind.cancelled)),
        isA<AppRequestCancelledException>(),
      );
      expect(
        parser.parseFailure(_failure(NetworkFailureKind.unknown)),
        isA<AppUnknownNetworkException>(),
      );
    });

    test('reads a well formed error envelope', () {
      final result = parser.parseFailure(
        _failure(
          NetworkFailureKind.badResponse,
          response: _response({
            'success': false,
            'error': 'VALIDATION',
            'data': {'message': 'Email is taken', 'field': 'email'},
          }, statusCode: 422),
        ),
      );

      expect(
        result,
        isA<AppRequestException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.error, 'error', 'VALIDATION')
            .having((e) => e.message, 'message', 'Email is taken')
            .having((e) => e.data, 'data', containsPair('field', 'email')),
      );
    });

    test('falls back to a root level message', () {
      final result = parser.parseFailure(
        _failure(
          NetworkFailureKind.badResponse,
          response: _response({'message': 'Forbidden'}, statusCode: 403),
        ),
      );

      expect(result, isA<AppRequestException>());
      expect((result as AppRequestException).message, 'Forbidden');
    });

    test('survives a malformed error envelope', () {
      final malformed = <Object?>[
        // `success` missing entirely, `data` not an object.
        {'error': 'BOOM', 'data': 'nope'},
        // `data` is a list.
        {'success': false, 'data': <Object?>[]},
        // Not an envelope at all.
        'gateway timeout',
        null,
      ];

      for (final body in malformed) {
        final result = parser.parseFailure(
          _failure(
            NetworkFailureKind.badResponse,
            response: _response(body, statusCode: 500),
          ),
        );

        expect(
          result,
          isA<AppRequestException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', isNotEmpty),
          reason: 'body $body should not raise a TypeError',
        );
      }
    });

    test('handles a failure with no response at all', () {
      final result = parser.parseFailure(
        _failure(NetworkFailureKind.badResponse),
      );

      expect(result, isA<AppRequestException>());
      expect((result as AppRequestException).statusCode, isNull);
    });
  });
}
