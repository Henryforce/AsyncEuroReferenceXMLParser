/// The quotation of the relative value of a euro against the unit of another currency.
public struct AsyncEuroReferenceCurrencyPair: Codable, Hashable, Sendable {
  /// The currency code of this pair relative to the euro.
  public let code: AsyncEuroReferenceCurrencyCode

  /// The rate of this pair relative to the euro.
  public let rate: String

  public init(code: AsyncEuroReferenceCurrencyCode, rate: String) {
    self.code = code
    self.rate = rate
  }
}
