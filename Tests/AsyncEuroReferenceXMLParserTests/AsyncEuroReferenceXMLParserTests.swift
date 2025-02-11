import Foundation
import Testing

@testable import AsyncEuroReferenceXMLParser

@Test func successfulParse() async throws {
  // Given.
  let parser = BaseAsyncEuroReferenceXMLParser()
  let dataURL = Bundle.module.url(forResource: "EuroRef", withExtension: "xml")!

  // When.
  let currencyPairs = try await parser.fetchCurrencyPairs(from: dataURL, timeout: 10.0)

  // Then.
  #expect(currencyPairs.count == 30)
}

@Test func networkError() async throws {
  // Given.
  let parser = BaseAsyncEuroReferenceXMLParser()
  let dataURL = URL(string: "https://www.google.com/")!
  let error = XMLParserTestError.mockedError

  // When.
  XMLParserURLProtocol.startInterceptingRequests()
  XMLParserURLProtocol.stub(url: dataURL, data: nil, response: nil, error: error)

  // Then.
  await #expect(
    performing: {
      try await parser.fetchCurrencyPairs(from: dataURL, timeout: 10.0)
    },
    throws: { error in
      let validError = error as NSError
      return validError.domain == "AsyncEuroReferenceXMLParserTests.XMLParserTestError"
        && validError.code == 0
    })

  XMLParserURLProtocol.stopInterceptingRequests()
}

@Test func timeoutIsTriggered() async throws {
  // Given.
  let xmlParser = XMLParserFake(data: Data())
  let runner = AsyncEuroReferenceXMLParserRunner(timeout: 0.001, parser: xmlParser)

  await #expect(
    performing: {
      // When.
      try await runner.parse()
    },
    throws: { error in
      // Then.
      guard let xmlError = error as? AsyncEuroReferenceXMLParserError, case .timeout = xmlError
      else {
        return false
      }
      return true
    })
}

@Test func parseErrorIsTriggered() async throws {
  // Given.
  let invalidXML = "<?xml version="
  let xmlParser = XMLParser(data: invalidXML.data(using: .utf8)!)
  let runner = AsyncEuroReferenceXMLParserRunner(timeout: 5.0, parser: xmlParser)

  await #expect(
    performing: {
      // When.
      try await runner.parse()
    },
    throws: { error in
      // Then.
      guard let xmlError = error as? AsyncEuroReferenceXMLParserError, case .parsing = xmlError
      else {
        return false
      }
      return true
    })
}

/// Fake XMLParser used for triggering a timeout as the parse method is overriding with a
/// no-op.
final class XMLParserFake: XMLParser {
  override func parse() -> Bool {
    return false
  }
}

enum XMLParserTestError: Error {
  case mockedError
}
