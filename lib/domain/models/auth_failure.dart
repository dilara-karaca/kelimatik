/// Domain-level auth failure with a user-facing Turkish message.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
