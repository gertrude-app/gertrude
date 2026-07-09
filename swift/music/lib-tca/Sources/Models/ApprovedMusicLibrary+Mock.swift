#if DEBUG
  import Foundation

  extension ApprovedMusicLibrary {
    static let mock = Self(
      albums: [
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
      ],
      artists: [
        .init(
          id: "909253",
          name: "Väsen",
          catalogMetadata: .init(
            artwork: .init(
              url: "https://is1-ssl.mzstatic.com/image/thumb/AMCArtistImages112/v4/e7/96/6c/e7966c1e-9654-6ec8-7758-d74134600bb4/{w}x{h}bb.jpg",
              width: 1080,
              height: 1080,
              bgColor: "26211d",
              textColor1: "f3ebe0",
              textColor2: "dfc596",
              textColor3: "c9c4ba",
              textColor4: "b8a47f",
            ),
            editorialNotes: .init(
              tagline: "Swedish folk trio",
              short: "Nyckelharpa-forward acoustic folk.",
              standard: "Väsen pairs nimble strings with deep Swedish folk roots.",
              name: "Väsen Essentials",
            ),
            appleMusicUrl: "https://music.apple.com/us/artist/v%C3%A4sen/909253",
            genreNames: ["Worldwide", "Folk"],
          ),
        ),
      ],
    )
  }
#endif
