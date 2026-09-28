/// {@template http_method}
/// The HTTP verb a request is sent with.
/// {@endtemplate}
enum HttpMethod {
  /// `GET`
  get,

  /// `POST`
  post,

  /// `PUT`
  put,

  /// `PATCH`
  patch,

  /// `DELETE`
  delete;

  /// The wire representation of the verb, e.g. `GET`.
  String get value => name.toUpperCase();
}
