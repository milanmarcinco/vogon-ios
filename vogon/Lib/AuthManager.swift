import Alamofire
import KeychainAccess
import Observation
import SwiftUI

struct Token: Decodable {
  let token: String
}

enum AuthError: Error {
  case invalidCredentials
  case notAuthenticated
  case networkError
  case internalError
}

@Observable
final class AuthManager {
  let KEYCHAIN_ACCESS_TOKEN = "accessToken"

  private(set) var initialized = false
  private(set) var isAuthenticated = false
  private(set) var isError = false

  private(set) var token: String? = nil

  let keychain = Keychain(service: AppConfig.APP_BUNDLE_ID)

  func initialize() async {
    if initialized { return }

    if let savedToken = keychain[KEYCHAIN_ACCESS_TOKEN] {
      self.token = savedToken
    }

    do {
      self.isAuthenticated = try await me()
    } catch {
      self.isAuthenticated = false
      self.isError = true
    }

    self.initialized = true
  }

  func me() async throws -> Bool {
    guard let token else { return false }

    let url = "\(AppConfig.API_URL)/auth/me"
    let headers: HTTPHeaders = [.authorization(bearerToken: token)]

    let response = await AF.request(
      url,
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
    let url = "\(AppConfig.API_URL)/auth/sign-in"

    let parameters: [String: String] = [
      "email": email,
      "password": password,
    ]

    let response = await AF.request(
      url,
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
          self.isAuthenticated = true

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

    let url = "\(AppConfig.API_URL)/auth/sign-out"
    let headers: HTTPHeaders = [.authorization(bearerToken: token)]

    _ = await AF.request(
      url,
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
    self.isAuthenticated = false
  }
}
