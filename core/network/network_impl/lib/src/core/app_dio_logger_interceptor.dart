import 'package:logger_api/logger_api.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

class AppDioLoggerInterceptor extends TalkerDioLogger {
  AppDioLoggerInterceptor({required LoggerApi loggerApi})
    : super(
        // Do the cast internally here
        talker: loggerApi.rawInstance as Talker,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
        ),
      );
}
