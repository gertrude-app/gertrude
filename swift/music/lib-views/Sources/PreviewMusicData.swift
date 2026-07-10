#if DEBUG
  import Foundation

  enum PreviewMusicData {
    static let nowPlayingTitle = "Josefin’s Waltz"
    static let nowPlayingArtist = "Alasdair Fraser & Natalie Haas"
    static let nowPlayingArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg",
    )
    static let storiesArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg",
    )
    static let brewedArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg",
    )
    static let ruleOf3ArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg",
    )
    static let frifotArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/60/de/53/60de531d-999b-e3ea-3bbb-de6fcf7e809a/dj.vemfnaju.jpg/600x600bb.jpg",
    )
    static let groupaArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/7c/a7/a4/7ca7a45d-bf36-0127-5804-de982bfafd9a/07391946082612.rgb.jpg/600x600bb.jpg",
    )
    static let aerArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/69/6c/db/696cdbe9-4c20-5149-b999-2a96a25662dc/7320470185339.png/600x600bb.jpg",
    )
    static let nordanArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/51/81/54/51815402-04b8-f6a3-5227-ed747447f3d5/00731452316127.rgb.jpg/600x600bb.jpg",
    )
    static let manskrattArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music5/v4/c5/8a/95/c58a956d-1116-bfad-fa46-2d08ba1ea7f7/dj.ynhzvvlg.jpg/600x600bb.jpg",
    )
    static let trettonArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/e2/54/29/e2542981-4315-57e1-6df7-0785143c4d84/7300343882657.jpg/600x600bb.jpg",
    )
    static let ranarimArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/87/aa/69/87aa69f3-e7ff-8d6f-5643-02e0bfcccd5e/7393844010315.jpg/600x600bb.jpg",
    )
    static let triakelArtworkURL = URL(
      string: "https://is1-ssl.mzstatic.com/image/thumb/Music/9c/e0/36/mzi.zhphocov.jpg/600x600bb.jpg",
    )
    static let liveInJapanArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/48/f5/8c/48f58c1c-508e-5653-762d-c704114d6d7d/7f8656d8-ffd9-455c-8daf-0165554a92e4.jpg/600x600bb.jpg",
    )
    static let nordanvindenArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/88/b0/5b/88b05b26-427d-aa23-2515-c2c06914e821/cover.jpg/600x600bb.jpg",
    )
    static let vasenStreetArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/Music122/v4/49/3b/11/493b11b6-3bd9-f908-d080-26ebf0000cb9/9fd89cdc-63c4-494a-9354-91ef9fc03222.jpg/600x600bb.jpg",
    )
    static let vasenArtistArtworkURL = URL(
      string:
      "https://is1-ssl.mzstatic.com/image/thumb/AMCArtistImages112/v4/e7/96/6c/e7966c1e-9654-6ec8-7758-d74134600bb4/600x600bb.jpg",
    )
  }

  extension [AlbumData] {
    static let previewAlbums: [AlbumData] = [
      .init(
        id: "1",
        title: "Stories from the Outside",
        artist: "Lena Jonsson Trio",
        artworkUrl: PreviewMusicData.storiesArtworkURL,
        artworkPalette: .init(
          bgColor: "5b1422",
          textColor1: "f0d4cf",
          textColor2: "db8c79",
          textColor3: "d2aeac",
          textColor4: "c27468",
        ),
      ),
      .init(
        id: "2",
        title: "Brewed",
        artist: "Väsen",
        artworkUrl: PreviewMusicData.brewedArtworkURL,
        artworkPalette: .init(
          bgColor: "070706",
          textColor1: "dfdedc",
          textColor2: "d3cec9",
          textColor3: "b4b3b1",
          textColor4: "aaa6a2",
        ),
      ),
      .init(
        id: "3",
        title: "Rule of 3",
        artist: "Väsen",
        artworkUrl: PreviewMusicData.ruleOf3ArtworkURL,
        artworkPalette: .init(
          bgColor: "221202",
          textColor1: "d7cdbe",
          textColor2: "cdbcb1",
          textColor3: "b3a898",
          textColor4: "ab9a8e",
        ),
      ),
      .init(
        id: "4",
        title: "Flyt",
        artist: "Frifot",
        artworkUrl: PreviewMusicData.frifotArtworkURL,
      ),
      .init(
        id: "5",
        title: "Lavalek",
        artist: "Groupa",
        artworkUrl: PreviewMusicData.groupaArtworkURL,
      ),
      .init(
        id: "6",
        title: "AER",
        artist: "Ahlberg, Ek & Roswall",
        artworkUrl: PreviewMusicData.aerArtworkURL,
      ),
      .init(
        id: "7",
        title: "Nordan",
        artist: "Ale Möller & Lena Willemark",
        artworkUrl: PreviewMusicData.nordanArtworkURL,
      ),
      .init(
        id: "8",
        title: "Månskratt",
        artist: "Groupa Med Lena Willemark",
        artworkUrl: PreviewMusicData.manskrattArtworkURL,
      ),
    ]

    static let longNamePreviewAlbums: [AlbumData] = [
      .init(
        id: "1",
        title: "Ingen större fröjd i världen är",
        artist: "Ahlberg, Ek & Roswall",
        artworkUrl: PreviewMusicData.trettonArtworkURL,
      ),
      .init(
        id: "2",
        title: "För världen älskar vad som är brokot",
        artist: "Ranarim",
        artworkUrl: PreviewMusicData.ranarimArtworkURL,
      ),
      .init(
        id: "3",
        title: "Sånger Från 63° N",
        artist: "Triakel",
        artworkUrl: PreviewMusicData.triakelArtworkURL,
      ),
      .init(
        id: "4",
        title: "Live in Japan (Live)",
        artist: "Väsen",
        artworkUrl: PreviewMusicData.liveInJapanArtworkURL,
      ),
    ]
  }

  extension [ArtistData] {
    static let previewArtists: [ArtistData] = [
      .init(
        id: "909253",
        name: "Väsen",
        artworkUrl: PreviewMusicData.vasenArtistArtworkURL,
        subtitle: "Swedish folk trio",
      ),
      .init(
        id: "1430482210",
        name: "Lena Jonsson Trio",
        artworkUrl: PreviewMusicData.storiesArtworkURL,
        subtitle: "Nyckelharpa-forward acoustic folk",
      ),
    ]
  }

  extension [TrackData] {
    static let previewTracks: [TrackData] = [
      .init(
        id: "1",
        title: "Josefins Dopvals",
        artist: "Väsen",
        artworkUrl: PreviewMusicData.ruleOf3ArtworkURL,
      ),
      .init(
        id: "2",
        title: "Bingsjö Polska",
        artist: "Lena Jonsson Trio",
        artworkUrl: PreviewMusicData.storiesArtworkURL,
      ),
      .init(
        id: "3",
        title: "Månskratt",
        artist: "Groupa Med Lena Willemark",
        artworkUrl: PreviewMusicData.manskrattArtworkURL,
      ),
      .init(
        id: "4",
        title: "Byss-Calle",
        artist: "Ahlberg, Ek & Roswall",
        artworkUrl: PreviewMusicData.aerArtworkURL,
      ),
      .init(
        id: "5",
        title: "Nordanvinden",
        artist: "Lena Jonsson Trio",
        artworkUrl: PreviewMusicData.nordanvindenArtworkURL,
      ),
      .init(
        id: "6",
        title: "Slängpolska efter Byss-Calle",
        artist: "Väsen",
        artworkUrl: PreviewMusicData.brewedArtworkURL,
      ),
      .init(
        id: "7",
        title: "Halling efter Per Loof",
        artist: "Frifot",
        artworkUrl: PreviewMusicData.frifotArtworkURL,
      ),
      .init(
        id: "8",
        title: "Ack Värmeland du sköna",
        artist: "Ranarim",
      ),
      .init(
        id: "9",
        title: "Trettondedagsmarschen",
        artist: "Ahlberg, Ek & Roswall",
        artworkUrl: PreviewMusicData.trettonArtworkURL,
      ),
      .init(
        id: "10",
        title: "Väsen Street",
        artist: "Väsen",
        artworkUrl: PreviewMusicData.vasenStreetArtworkURL,
      ),
      .init(
        id: "11",
        title: "Östbjörka Brudmarsch",
        artist: "Ale Möller & Lena Willemark",
        artworkUrl: PreviewMusicData.nordanArtworkURL,
      ),
      .init(
        id: "12",
        title: "Polska efter Höök Olle",
        artist: "Triakel",
        artworkUrl: PreviewMusicData.triakelArtworkURL,
      ),
    ]
  }
#endif
