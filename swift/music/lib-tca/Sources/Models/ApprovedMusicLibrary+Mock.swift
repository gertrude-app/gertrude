#if DEBUG
  import Foundation

  extension ApprovedMusicLibrary {
    static let mock = Self(albums: [
      .init(
        id: "1511628001",
        title: "Stories from the Outside",
        artistName: "Lena Jonsson Trio & Lena Jonsson",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg",
        ),
        tracks: [
          .init(
            id: "1511628002",
            title: "Rallpersgubben Kör Timmer",
            artistName: "Lena Jonsson Trio & Lena Jonsson",
            artworkURL: URL(
              string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg",
            ),
          ),
          .init(
            id: "1511628003",
            title: "Jullovsschottis (feat. Natalie Haas)",
            artistName: "Lena Jonsson Trio & Lena Jonsson",
            artworkURL: URL(
              string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg",
            ),
          ),
          .init(
            id: "1511628004",
            title: "Ispolskan (feat. Arvid Svenungsson)",
            artistName: "Lena Jonsson Trio & Lena Jonsson",
            artworkURL: URL(
              string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg",
            ),
          ),
        ],
      ),
      .init(
        id: "1682152618",
        title: "Elements",
        artistName: "Lena Jonsson Trio",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg",
        ),
        tracks: [
          .init(
            id: "1682152624",
            title: "Elements",
            artistName: "Lena Jonsson Trio",
            artworkURL: URL(
              string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg",
            ),
          ),
          .init(
            id: "1682152629",
            title: "Glöd",
            artistName: "Lena Jonsson Trio",
            artworkURL: URL(
              string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg",
            ),
          ),
        ],
      ),
      .init(
        id: "1641851258",
        title: "Brewed",
        artistName: "Väsen",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg",
        ),
        tracks: [
          .init(
            id: "1641851259",
            title: "Brewed",
            artistName: "Väsen",
            artworkURL: URL(
              string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg",
            ),
          ),
          .init(
            id: "1641851262",
            title: "Märtas",
            artistName: "Väsen",
            artworkURL: URL(
              string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg",
            ),
          ),
        ],
      ),
    ])
  }
#endif
