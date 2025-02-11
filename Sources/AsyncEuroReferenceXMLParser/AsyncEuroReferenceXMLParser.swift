import Foundation

/// Interface for the object that parses the euro reference XML.
public protocol AsyncEuroReferenceXMLParser: Sendable {
  /// Fetch and parse the contents of a XML file matching the formatting of the euro reference
  /// to return the currency pairs.
  func fetchCurrencyPairs(from url: URL, timeout: TimeInterval) async throws
    -> [AsyncEuroReferenceCurrencyPair]
}

/// Base implementation of the AsyncEuroReferenceXMLParser protocol.
public struct BaseAsyncEuroReferenceXMLParser: AsyncEuroReferenceXMLParser {
  public init() {}

  public func fetchCurrencyPairs(from url: URL, timeout: TimeInterval) async throws
    -> [AsyncEuroReferenceCurrencyPair]
  {
    // Load the data asynchronously via URLSession.
    // (Calls can be intercepted via URLProtocol conforming classes during testing).
    let data = try await URLSession.shared.data(from: url).0

    // Create a Foundation XMLParser with the loaded data.
    let xmlParser = XMLParser(data: data)

    // Create a one-time runner to execute this parsing operation.
    let runner = AsyncEuroReferenceXMLParserRunner(timeout: timeout, parser: xmlParser)

    return try await runner.parse()
  }
}
