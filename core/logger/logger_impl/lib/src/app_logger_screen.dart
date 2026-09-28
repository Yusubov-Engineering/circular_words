import 'package:logger_api/logger_api.dart';
import 'package:material_ui/material_ui.dart';
import 'package:talker_flutter/talker_flutter.dart';

class const AppLoggerScreen({required final LoggerApi _loggerApi, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final talker = _loggerApi.rawInstance;

    if (talker is! Talker) {
      return const Scaffold(
        body: Center(
          child: Text('Log screen is not supported with the current logger.'),
        ),
      );
    }

    return MaterialApp(
      home: TalkerScreen(
        talker: talker,
        appBarTitle: 'App Logs',
        theme: const TalkerScreenTheme(backgroundColor: Color(0xFF1E1E1E)),
      ),
    );
  }
}
