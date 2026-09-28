// it is needed for console visibility
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/foundation.dart';
import 'package:logger_api/logger_api.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TalkerAppLogger implements LoggerApi {
  TalkerAppLogger() {
    _talker = TalkerFlutter.init(
      settings: TalkerSettings(
        useConsoleLogs: !kReleaseMode,
        maxHistoryItems: 500,
      ),
    );
  }
  late final Talker _talker;

  @override
  Object get rawInstance => _talker;

  @override
  void info(String message) => _talker.info(message);

  @override
  void debug(String message) => _talker.debug(message);

  @override
  void warning(String message) => _talker.warning(message);

  @override
  void error(String message, [Object? exception, StackTrace? stackTrace]) {
    _talker.error(message, exception, stackTrace);
  }

  @override
  LoggerApi withTag(String tag) => _ScopedLogger(this, tag);
}

class _ScopedLogger implements LoggerApi {
  const _ScopedLogger(this._delegate, this._tag);

  final LoggerApi _delegate;
  final String _tag;

  @override
  void info(String message) => _delegate.info('[$_tag] $message');

  @override
  void debug(String message) => _delegate.debug('[$_tag] $message');

  @override
  void warning(String message) => _delegate.warning('[$_tag] $message');

  @override
  void error(String message, [Object? exception, StackTrace? stackTrace]) {
    _delegate.error('[$_tag] $message', exception, stackTrace);
  }

  @override
  LoggerApi withTag(String tag) => _ScopedLogger(_delegate, '$_tag/$tag');

  @override
  Object get rawInstance => _delegate.rawInstance;
}
