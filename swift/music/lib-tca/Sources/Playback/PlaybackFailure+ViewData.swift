extension PlaybackFailure {
  var title: String {
    switch self {
    case .appleMusicSubscriptionRequired:
      "Apple Music subscription required"
    case .catalogLookupFailed:
      "Couldn’t load song"
    case .musicAccessDenied:
      "Apple Music access needed"
    case .musicAccessRestricted:
      "Apple Music is restricted"
    case .playbackFailed:
      "Couldn’t start playback"
    case .privacyAcknowledgementRequired:
      "Apple Music setup needed"
    case .trackUnavailable:
      "Song unavailable"
    }
  }

  var message: String {
    switch self {
    case .appleMusicSubscriptionRequired:
      "This device needs an active Apple Music subscription to play approved music."
    case .catalogLookupFailed:
      "Gertrude Music couldn’t load this song from Apple Music. Try another approved track."
    case .musicAccessDenied:
      "Allow Gertrude Music to use Apple Music so approved music can play."
    case .musicAccessRestricted:
      "Apple Music access appears to be restricted on this device."
    case .playbackFailed:
      "Check your connection and try again."
    case .privacyAcknowledgementRequired:
      "This Apple ID needs to finish Apple Music setup before playback can start. Finish any iOS prompts, then try again."
    case .trackUnavailable:
      "This song isn’t available from Apple Music right now. Try another approved track."
    }
  }

  var systemImage: String {
    switch self {
    case .appleMusicSubscriptionRequired:
      "person.crop.circle.badge.exclamationmark"
    case .catalogLookupFailed:
      "icloud.slash.fill"
    case .musicAccessDenied:
      "music.note.list"
    case .musicAccessRestricted:
      "lock.fill"
    case .playbackFailed:
      "wifi.exclamationmark"
    case .privacyAcknowledgementRequired:
      "exclamationmark.bubble.fill"
    case .trackUnavailable:
      "exclamationmark.triangle.fill"
    }
  }

  var actionTitle: String? {
    switch self {
    case .musicAccessDenied, .musicAccessRestricted:
      "Open Settings"
    case .appleMusicSubscriptionRequired,
         .catalogLookupFailed,
         .playbackFailed,
         .privacyAcknowledgementRequired,
         .trackUnavailable:
      nil
    }
  }
}
