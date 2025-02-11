public enum AsyncEuroReferenceXMLParserError: Error {
  /// The parser did not complete before the given timeout interval.
  case timeout

  /// There was a parsing error.
  /// The associated error can be retrieved to fetch specific details.
  case parsing(Error)
}
