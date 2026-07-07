extension EventLabel {
  static func music(_ eventId: String) -> String? {
    switch eventId {

    // --- Setup / Apple Music ---
    case "e145e6b5": "Apple Music authorization denied"
    case "c58a3b1d": "Apple Music authorization restricted"
    case "7d682c16": "Apple Music authorization unavailable"
    case "8a026e2c": "Apple Music subscription permission denied"
    case "af4f5985": "Apple Music privacy acknowledgement required"
    case "aa99a570": "Music device claimed"
    case "d3cb7281": "Music app status failed"
    case "0f92a6a8": "Music app status polling failed"
    // --- Subscription ---
    case "bfa4b9e6": "Apple Music subscription required"
    case "e1c0d002": "Apple Music subscription status unavailable"
    case "c380387c": "Apple Music subscription offer shown"
    case "ded74480": "Gertrude Music subscription required"
    // --- Library ---
    case "e24738fc": "Approved library empty"
    case "cd55459e": "Approved library load failed"
    // --- Playback ---
    case "18378ebc": "Playback: subscription required"
    case "37358a04": "Playback: catalog lookup failed"
    case "9791174c": "Playback: Apple Music access denied"
    case "1676a4ae": "Playback: Apple Music restricted"
    case "f357b375": "Playback failed"
    case "21a860f7": "Playback: Apple Music setup needed"
    case "e1423c41": "Playback: track unavailable"
    default: nil
    }
  }
}
