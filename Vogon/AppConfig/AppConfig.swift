import Foundation

enum AppConfig {
  static let APP_BUNDLE_ID = Bundle.main.object(forInfoDictionaryKey: "APP_BUNDLE_ID") as! String

  private static let API_SCHEME = Bundle.main.object(forInfoDictionaryKey: "API_SCHEME") as! String
  private static let API_HOST = Bundle.main.object(forInfoDictionaryKey: "API_HOST") as! String
  static let API_URL = "\(API_SCHEME)://\(API_HOST)"
}
