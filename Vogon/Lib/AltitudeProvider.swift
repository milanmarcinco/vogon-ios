import CoreLocation

enum AltitudeError: LocalizedError {
  case denied
  case unavailable

  var errorDescription: String? {
    switch self {
    case .denied:
      "Location access is turned off for Vogon. Allow it in Settings to use your current altitude."
    case .unavailable:
      "Your current altitude is not available. Try again outdoors or enter it manually."
    }
  }
}

enum AltitudeProvider {
  // Returns the phone's altitude above mean sea level, rounded to the nearest metre.
  static func currentAltitude(timeout: Duration = .seconds(15)) async throws -> Int {
    let session = CLServiceSession(authorization: .whenInUse)
    defer { session.invalidate() }

    return try await withThrowingTaskGroup(of: Int.self) { group in
      group.addTask {
        for try await update in CLLocationUpdate.liveUpdates() {
          if update.authorizationDenied || update.authorizationDeniedGlobally {
            throw AltitudeError.denied
          }
          // A negative vertical accuracy means the altitude is invalid.
          if let location = update.location, location.verticalAccuracy >= 0 {
            return Int(location.altitude.rounded())
          }
        }
        throw AltitudeError.unavailable
      }

      group.addTask {
        try await Task.sleep(for: timeout)
        throw AltitudeError.unavailable
      }

      let altitude = try await group.next()!
      group.cancelAll()
      return altitude
    }
  }
}
