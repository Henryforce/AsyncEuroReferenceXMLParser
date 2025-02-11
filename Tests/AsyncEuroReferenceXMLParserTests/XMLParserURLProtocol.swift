import Foundation

/// URLProtocol class for intercepting requests.
final class XMLParserURLProtocol: URLProtocol {
  nonisolated(unsafe) private static var stubs = [URL: Stub]()

  private struct Stub {
    let data: Data?
    let response: URLResponse?
    let error: Error?
  }

  static func stub(url: URL, data: Data?, response: URLResponse?, error: Error?) {
    stubs[url] = Stub(data: data, response: response, error: error)
  }

  static func startInterceptingRequests() {
    URLProtocol.registerClass(XMLParserURLProtocol.self)
  }

  static func stopInterceptingRequests() {
    URLProtocol.unregisterClass(XMLParserURLProtocol.self)
    stubs = [:]
  }

  override class func canInit(with request: URLRequest) -> Bool {
    guard let url = request.url else { return false }

    URLProtocol.registerClass(XMLParserURLProtocol.self)

    return stubs[url] != nil
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    guard let url = request.url, let stub = XMLParserURLProtocol.stubs[url] else { return }

    if let data = stub.data {
      client?.urlProtocol(self, didLoad: data)
    }

    if let response = stub.response {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }

    if let error = stub.error {
      client?.urlProtocol(self, didFailWithError: error)
    }

    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}

}
