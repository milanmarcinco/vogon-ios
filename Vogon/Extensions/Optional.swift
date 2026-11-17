extension Optional where Wrapped == Int {
  func asString(_ defaultValue: String = "") -> String {
    switch self {
    case .some(let v):
      return String(v)
    case .none:
      return defaultValue
    }
  }
}
