/// {@template network_header_provider}
/// Supplies the headers that are added to every request the client sends.
///
/// The client asks for them once per request, so a value that changes while
/// the app runs — the selected language, an auth token — is always read
/// fresh, and a header a caller passes for a single request still wins.
/// {@endtemplate}
abstract interface class NetworkHeaderProvider {
  /// The headers to add to the request that is about to be sent.
  Map<String, String> get headers;
}
