import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:rosco_api/rosco_api.dart';

/// Raised when a level's asset cannot be read at all.
///
/// The bundle signals a missing asset with a `FlutterError`, which is an
/// `Error` subclass that the lint rules rightly forbid catching by type. That
/// knowledge belongs here, in the one layer that talks to the bundle, rather
/// than leaking upward as a string match on an error message.
final class const WordBankAssetException({
  required final String assetPath,
  final Object? cause,
}) implements Exception {
  @override
  String toString() => 'WordBankAssetException($assetPath, $cause)';
}

/// {@template word_bank_asset_data_source}
/// Reads a level's raw word bank out of the bundled assets.
///
/// The only place an asset path is named. Returns decoded JSON and judges
/// nothing about its shape — validation belongs to the repository, which is
/// the layer that can express the result as a `RoscoFailure`.
/// {@endtemplate}
final class WordBankAssetDataSource({required final AssetBundle _bundle}) {
  /// Where a level's bank lives.
  ///
  /// `packages/<package>/...` is how a package's own assets are addressed
  /// through the root bundle; without the prefix this resolves against the
  /// *app's* assets and fails at runtime only.
  static String assetPathFor(CefrLevel level) =>
      'packages/rosco_impl/assets/words/${level.id}.json';

  /// The decoded document for [level].
  ///
  /// Throws [WordBankAssetException] when the asset cannot be read, and
  /// [FormatException] when it is not a JSON object — both mapped to failures
  /// one layer up.
  Future<Map<String, dynamic>> load(CefrLevel level) async {
    final path = assetPathFor(level);
    final String raw;

    try {
      raw = await _bundle.loadString(path);
    } on Object catch (error) {
      throw WordBankAssetException(assetPath: path, cause: error);
    }

    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('word bank is not a JSON object');
    }

    return decoded;
  }
}
