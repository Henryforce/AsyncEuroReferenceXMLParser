import Dispatch
import Foundation

/// Class that executes a single XML parsing flow.
/// This class ensures thread-safety and sendability conformance via an internal queue that
/// synchronizes its internal properties.
final class AsyncEuroReferenceXMLParserRunner: NSObject, @unchecked Sendable {

  /// The interval before triggering a timeout.
  private let timeout: TimeInterval

  /// The queue used to synchronize all method calls of this class.
  private let queue: DispatchQueue

  /// The object used to parse XML.
  private let parser: XMLParser

  /// The continuation needed to resume the parse task.
  private var continuation: CheckedContinuation<[AsyncEuroReferenceCurrencyPair], Error>?

  /// The task used as a timer used to trigger a timeout if the continuation is not resumed before
  /// the timeout interval.
  private var timeoutTask: Task<Void, Error>?

  /// The parsed currency pairs.
  private var currencyPairs: [AsyncEuroReferenceCurrencyPair]

  init(
    timeout: TimeInterval,
    queue: DispatchQueue = DispatchQueue(label: "AsyncXMLParserQueue"),
    parser: XMLParser
  ) {
    self.timeout = timeout
    self.queue = queue
    self.parser = parser
    self.currencyPairs = [
      AsyncEuroReferenceCurrencyPair(code: .euro, rate: "1.00")
    ]
  }

  func parse() async throws -> [AsyncEuroReferenceCurrencyPair] {
    return try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<[AsyncEuroReferenceCurrencyPair], Error>) in
      self.queue.async {
        self.startParsing(with: continuation)
      }
    }
  }

  /// Start the XMLParser with the URL.
  /// This method MUST only be called from inside the class' queue.
  private func startParsing(
    with continuation: CheckedContinuation<[AsyncEuroReferenceCurrencyPair], Error>
  ) {
    self.continuation = continuation

    // Start a task to behave as a timer with the given timeout.
    let timeoutInMilliseconds = timeout * 1000
    timeoutTask = Task { [weak self] in
      if #available(iOS 16.0, macOS 15.0, tvOS 9.0, watchOS 9.0, visionOS 1.0, *) {
        try await Task.sleep(for: .milliseconds(timeoutInMilliseconds))
      } else {
        try await Task.sleep(nanoseconds: UInt64(timeoutInMilliseconds) * 1_000_000)
      }
      guard !Task.isCancelled, let self else { return }
      self.queue.async {
        guard let existingContinuation = self.continuation else { return }
        existingContinuation.resume(throwing: AsyncEuroReferenceXMLParserError.timeout)
      }
    }

    parser.delegate = self
    parser.parse()
  }
}

extension AsyncEuroReferenceXMLParserRunner: XMLParserDelegate {
  func parserDidEndDocument(_ parser: XMLParser) {
    queue.async {
      guard let continuation = self.continuation else { return }
      continuation.resume(returning: self.currencyPairs)
      self.continuation = nil
      self.timeoutTask?.cancel()
    }
  }

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String]
  ) {
    queue.async {
      guard let code = attributeDict["currency"],
        let validCode = AsyncEuroReferenceCurrencyCode(rawValue: code),
        let rate = attributeDict["rate"]
      else {
        return
      }
      let currencyPair = AsyncEuroReferenceCurrencyPair(code: validCode, rate: rate)
      self.currencyPairs.append(currencyPair)
    }
  }

  func parser(_ parser: XMLParser, parseErrorOccurred parseError: any Error) {
    queue.async {
      guard let continuation = self.continuation else { return }
      continuation.resume(throwing: AsyncEuroReferenceXMLParserError.parsing(parseError))
      self.continuation = nil
      self.timeoutTask?.cancel()
    }
  }
}
