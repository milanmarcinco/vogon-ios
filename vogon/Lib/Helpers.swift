import CoreBluetooth
import Foundation

enum ApiRoutes {
  static let baseUrl = AppConfig.API_URL

  static let signIn = "\(baseUrl)/auth/sign-in"
  static let signOut = "\(baseUrl)/auth/sign-out"
  static let me = "\(baseUrl)/auth/me"
  
  static let devices = "\(baseUrl)/devices"
}
