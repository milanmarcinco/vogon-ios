import Alamofire
import KeychainAccess
import Observation
import SwiftUI

struct Token: Decodable {
  let token: String
}

enum AuthStatus {
  case unknown
  case pending
  case authenticated
  case unauthenticated
  case error
}

enum AuthError: Error {
  case invalidCredentials
  case notAuthenticated
  case networkError
  case internalError
}

@Observable
final class AuthManager {
  private let KEYCHAIN_ACCESS_TOKEN = "accessToken"
  private let keychain = Keychain(service: AppConfig.APP_BUNDLE_ID)

  private(set) var status: AuthStatus = .unknown
  private(set) var token: String? = nil

  func initialize() async {
    if status != .unknown { return }
    status = .pending

    if let savedToken = keychain[KEYCHAIN_ACCESS_TOKEN] {
      token = savedToken
    }

    let authenticated = try? await me()

    guard let authenticated else {
      status = .error
      return
    }

    if authenticated {
      status = .authenticated
    } else {
      status = .unauthenticated
    }
  }

  func me() async throws -> Bool {
    guard let token else { return false }

    let headers: HTTPHeaders = [.authorization(bearerToken: token)]

    let response = await AF.request(
      ApiRoutes.me,
      method: .get,
      headers: headers
    )
    .serializingData()
    .response

    if let status = response.response?.statusCode {
      switch status {
      case 200..<300:
        return true
      case 401:
        return false
      default:
        throw AuthError.notAuthenticated
      }
    }

    throw AuthError.networkError
  }

  func signIn(email: String, password: String) async throws {
    let parameters: [String: String] = [
      "email": email,
      "password": password,
    ]

    let response = await AF.request(
      ApiRoutes.signIn,
      method: .post,
      parameters: parameters,
      encoding: JSONEncoding.default
    )
    .serializingDecodable(Token.self)
    .response

    if let status = response.response?.statusCode {
      switch status {
      case 200..<300:
        if let payload = response.value {
          self.token = payload.token
          self.status = .authenticated

          keychain[KEYCHAIN_ACCESS_TOKEN] = payload.token
          return
        } else {
          throw AuthError.internalError
        }
      case 401:
        throw AuthError.notAuthenticated
      default:
        throw AuthError.networkError
      }
    }

    throw AuthError.networkError
  }

  func signOut() async {
    guard let token else { return }

    let headers: HTTPHeaders = [.authorization(bearerToken: token)]

    _ = await AF.request(
      ApiRoutes.signOut,
      method: .delete,
      headers: headers
    )
    .serializingData()
    .response

    do {
      try keychain.remove(KEYCHAIN_ACCESS_TOKEN)
    } catch {
      // Ignore
    }

    self.token = nil
    self.status = .unauthenticated
  }
}
