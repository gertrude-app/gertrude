import Foundation

extension ApprovedMusicLibrary {
  static let mock = Self(
    albums: [
      .init(
        id: "1511628001",
        title: "Stories from the Outside",
        artistName: "Lena Jonsson Trio & Lena Jonsson",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg"
        ),
        trackIDs: [
          "1511628002",
          "1511628003",
          "1511628004",
          "1511628005",
          "1511628276",
          "1511628277",
        ],
      ),
      .init(
        id: "1682152618",
        title: "Elements",
        artistName: "Lena Jonsson Trio",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1682152624",
          "1682152629",
          "1682152939",
          "1682152945",
          "1682152954",
          "1682152962",
        ],
      ),
      .init(
        id: "1641791000",
        title: "Rule of 3",
        artistName: "Väsen",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1641791004",
          "1641791010",
          "1641791019",
          "1641791022",
          "1641791357",
          "1641791367",
        ],
      ),
      .init(
        id: "1641851258",
        title: "Brewed",
        artistName: "Väsen",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg"
        ),
        showsArtwork: false,
        trackIDs: [
          "1641851259",
          "1641851262",
          "1641851263",
          "1641851808",
          "1641851809",
          "1641851811",
        ],
      ),
      .init(
        id: "337679172",
        title: "Månskratt",
        artistName: "Groupa Med Lena Willemark",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music5/v4/c5/8a/95/c58a956d-1116-bfad-fa46-2d08ba1ea7f7/dj.ynhzvvlg.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "337679253",
          "337679254",
          "337679255",
          "337679257",
          "337679260",
          "337679261",
        ],
      ),
      .init(
        id: "337816392",
        title: "Flyt",
        artistName: "Frifot",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/60/de/53/60de531d-999b-e3ea-3bbb-de6fcf7e809a/dj.vemfnaju.jpg/600x600bb.jpg"
        ),
        showsArtwork: false,
        trackIDs: [
          "337816583",
          "337816585",
          "337816590",
          "337816595",
          "337816616",
          "337816643",
        ],
      ),
      .init(
        id: "81005155",
        title: "Fire & Grace",
        artistName: "Alasdair Fraser & Natalie Haas",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/ca/9b/bf/ca9bbff6-3bc1-cabf-cce4-006ed518b285/mzi.rntmujxz.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "81005084",
          "81005089",
          "81005091",
          "81005093",
          "81005095",
          "81005097",
        ],
      ),
      .init(
        id: "425926410",
        title: "Highlander's Farewell",
        artistName: "Alasdair Fraser & Natalie Haas",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "425926432",
          "425926434",
          "425926436",
          "425926438",
          "425926440",
          "425926443",
        ],
      ),
      .init(
        id: "1215440641",
        title: "Ports of Call",
        artistName: "Alasdair Fraser & Natalie Haas",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music111/v4/a1/e0/cf/a1e0cfc3-46f9-d67c-d7a8-2a13a00c7ab0/755997012528.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1215440791",
          "1215440799",
          "1215441058",
          "1215441113",
          "1215441125",
          "1215441196",
        ],
      ),
      .init(
        id: "265621036",
        title: "The Lonesome Touch",
        artistName: "Dennis Cahill & Martin Hayes",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/7c/cc/d1/mzi.lkdflxsw.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "265621046",
          "265621145",
          "265621269",
          "265621460",
          "265621511",
          "265621613",
        ],
      ),
      .init(
        id: "264226184",
        title: "Live In Seattle",
        artistName: "Dennis Cahill & Martin Hayes",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/72/3c/88/mzi.gvdputxf.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "264226209",
          "264226657",
          "264228955",
          "264229396",
          "264230057",
        ],
      ),
      .init(
        id: "767502097",
        title: "The Gloaming",
        artistName: "The Gloaming",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/00/5d/6c/005d6c6b-aeb9-41c0-ad0f-10b0e2edd328/632662558768.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "767502122",
          "767502123",
          "767502124",
          "767502125",
          "767502126",
          "767502127",
        ],
      ),
      .init(
        id: "1077568224",
        title: "2",
        artistName: "The Gloaming",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music69/v4/e9/b6/86/e9b68616-59dd-f86a-4cd1-38df05675ca3/632662560235.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1077568226",
          "1077568227",
          "1077568228",
          "1077568229",
          "1077568230",
          "1077568231",
        ],
      ),
      .init(
        id: "265623640",
        title: "Lake Effect",
        artistName: "Liz Carroll",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/c7/fd/db/mzi.umotolux.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "265623654",
          "265623789",
          "265623921",
          "265624365",
          "265624507",
          "265624805",
        ],
      ),
      .init(
        id: "731785219",
        title: "On the Offbeat",
        artistName: "Liz Carroll",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/df/b9/b3/dfb9b343-2517-7c94-f559-133c7e5b87d4/884501979375.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "731785393",
          "731785396",
          "731785412",
          "731785434",
          "731785448",
          "731785450",
        ],
      ),
      .init(
        id: "1126907142",
        title: "If the Cap Fits (Remastered)",
        artistName: "Kevin Burke",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music30/v4/86/f5/b3/86f5b3ee-d447-1bac-2bd9-423c74968142/766397302126-square_copy.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1126907364",
          "1126907366",
          "1126907367",
          "1126907368",
          "1126907370",
          "1126907371",
        ],
      ),
      .init(
        id: "1799239869",
        title: "In My Hands",
        artistName: "Natalie MacMaster",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/d7/b6/b4/d7b6b4c0-e34a-a106-39a6-7aa1b4477921/011661702523_cover.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1799239870",
          "1799239873",
          "1799239878",
          "1799240089",
          "1799240091",
          "1799240095",
        ],
      ),
      .init(
        id: "1841433567",
        title: "Tromper Le Temps",
        artistName: "Le Vent du Nord",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/d8/6b/16/d86b16cd-f693-2c9b-4cf5-9b9b13adaecb/cover.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1841433574",
          "1841433578",
          "1841433852",
          "1841433865",
          "1841433868",
          "1841433873",
        ],
      ),
      .init(
        id: "1841433531",
        title: "Têtu",
        artistName: "Le Vent du Nord",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/1c/7a/79/1c7a799c-e773-cc91-0e87-9eb477cfe6fe/cover.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1841433532",
          "1841433535",
          "1841433536",
          "1841433539",
          "1841433540",
          "1841433541",
        ],
      ),
      .init(
        id: "1345713469",
        title: "The Gap of Dreams",
        artistName: "Altan",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/ac/1d/d5/ac1dd5b8-be0d-4a91-316c-1b3230301cb8/679.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1345713711",
          "1345713762",
          "1345713763",
          "1345713764",
          "1345713765",
          "1345713766",
        ],
      ),
      .init(
        id: "353046697",
        title: "The Turning Tide",
        artistName: "Solas",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/2a/bb/00/2abb00cc-5b81-9d35-95d7-9da3f65d2875/mzi.ftntdnur.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "353046724",
          "353046771",
          "353046892",
          "353046897",
          "353046973",
          "353047114",
        ],
      ),
      .init(
        id: "1376942431",
        title: "Some Strange Country",
        artistName: "Crooked Still",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/5c/75/76/5c75766d-aaa0-4946-fb6b-b711db72bcb6/Some_Strange_Country_3000x3000px.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1376942433",
          "1376942434",
          "1376942435",
          "1376942436",
          "1376942437",
          "1376942438",
        ],
      ),
      .init(
        id: "1457049384",
        title: "Contented Must Be",
        artistName: "Bruce Molsky",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/1b/8a/36/1b8a3639-61f7-b563-d0d1-4f5735c38347/00888072088757.rgb.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1457049742",
          "1457049929",
          "1457049951",
          "1457049954",
          "1457050052",
          "1457050053",
        ],
      ),
      .init(
        id: "544499766",
        title: "Outshine the Sun",
        artistName: "Foghorn Stringband",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/v4/d5/4d/6e/d54d6e24-24ef-1eec-079c-363eaa13e265/885767190191.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "544499767",
          "544499768",
          "544499789",
          "544499790",
          "544499791",
          "544499792",
        ],
      ),
      .init(
        id: "808948486",
        title: "Dot the Dragon's Eyes",
        artistName: "Hanneke Cassel",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/75/cd/23/75cd23d9-dfd9-e589-577b-199a65222ee8/888295014083.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "808948494",
          "808948495",
          "808948496",
          "808948497",
          "808948498",
          "808948499",
        ],
      ),
      .init(
        id: "1786282479",
        title: "Chasing Sparks",
        artistName: "Jeremy Kittel",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/94/53/9f/94539ff7-7290-4f0d-e025-23072e5e07c7/artwork.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1786282480",
          "1786282483",
          "1786282484",
          "1786282486",
          "1786282487",
          "1786282488",
        ],
      ),
      .init(
        id: "1617775324",
        title: "North",
        artistName: "Blazin' Fiddles",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/0b/c0/9c/0bc09c8a-bc59-403f-4b3c-140a98d6f974/5052442011613.png/600x600bb.jpg"
        ),
        trackIDs: [
          "1617775596",
          "1617775597",
          "1617775598",
          "1617775599",
          "1617775600",
          "1617775602",
        ],
      ),
      .init(
        id: "1823330663",
        title: "All Hands",
        artistName: "Beòlach",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/58/68/eb/5868ebeb-9939-97c7-31f9-5cf243fd5867/118.jpg/600x600bb.jpg"
        ),
        trackIDs: [
          "1823330674",
          "1823330676",
          "1823330677",
          "1823330680",
          "1823330683",
          "1823330684",
        ],
      ),
    ],
    artists: [
      .init(
        id: "1501251736",
        name: "Lena Jonsson Trio & Lena Jonsson",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg"
        ),
        isRootAllowed: true,
        albumIDs: [
          "1511628001",
          "1682152618",
        ],
        trackIDs: [
          "1511628002",
          "1511628003",
          "1511628004",
          "1511628005",
          "1511628276",
          "1511628277",
          "1682152624",
          "1682152629",
          "1682152939",
          "1682152945",
          "1682152954",
          "1682152962",
        ],
      ),
      .init(
        id: "64784615",
        name: "Väsen",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg"
        ),
        isRootAllowed: true,
        albumIDs: [
          "1641791000",
          "1641851258",
        ],
        trackIDs: [
          "1641791004",
          "1641791010",
          "1641791019",
          "1641791022",
          "1641791357",
          "1641791367",
          "1641851259",
          "1641851262",
          "1641851263",
          "1641851808",
          "1641851809",
          "1641851811",
        ],
      ),
      .init(
        id: "273512071",
        name: "Groupa Med Lena Willemark",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music5/v4/c5/8a/95/c58a956d-1116-bfad-fa46-2d08ba1ea7f7/dj.ynhzvvlg.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "337679172",
        ],
        trackIDs: [
          "337679253",
          "337679254",
          "337679255",
          "337679257",
          "337679260",
          "337679261",
        ],
      ),
      .init(
        id: "64812322",
        name: "Frifot",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/60/de/53/60de531d-999b-e3ea-3bbb-de6fcf7e809a/dj.vemfnaju.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "337816392",
        ],
        trackIDs: [
          "337816583",
          "337816585",
          "337816590",
          "337816595",
          "337816616",
          "337816643",
        ],
      ),
      .init(
        id: "652246",
        name: "Alasdair Fraser & Natalie Haas",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/ca/9b/bf/ca9bbff6-3bc1-cabf-cce4-006ed518b285/mzi.rntmujxz.jpg/600x600bb.jpg"
        ),
        isRootAllowed: true,
        albumIDs: [
          "81005155",
          "425926410",
          "1215440641",
        ],
        trackIDs: [
          "81005084",
          "81005089",
          "81005091",
          "81005093",
          "81005095",
          "81005097",
          "425926432",
          "425926434",
          "425926436",
          "425926438",
          "425926440",
          "425926443",
          "1215440791",
          "1215440799",
          "1215441058",
          "1215441113",
          "1215441125",
          "1215441196",
        ],
      ),
      .init(
        id: "68316724",
        name: "Dennis Cahill & Martin Hayes",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/7c/cc/d1/mzi.lkdflxsw.jpg/600x600bb.jpg"
        ),
        isRootAllowed: true,
        albumIDs: [
          "265621036",
          "264226184",
        ],
        trackIDs: [
          "265621046",
          "265621145",
          "265621269",
          "265621460",
          "265621511",
          "265621613",
          "264226209",
          "264226657",
          "264228955",
          "264229396",
          "264230057",
        ],
      ),
      .init(
        id: "289089863",
        name: "The Gloaming",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/00/5d/6c/005d6c6b-aeb9-41c0-ad0f-10b0e2edd328/632662558768.jpg/600x600bb.jpg"
        ),
        isRootAllowed: true,
        albumIDs: [
          "767502097",
          "1077568224",
        ],
        trackIDs: [
          "767502122",
          "767502123",
          "767502124",
          "767502125",
          "767502126",
          "767502127",
          "1077568226",
          "1077568227",
          "1077568228",
          "1077568229",
          "1077568230",
          "1077568231",
        ],
      ),
      .init(
        id: "2614660",
        name: "Liz Carroll",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/c7/fd/db/mzi.umotolux.jpg/600x600bb.jpg"
        ),
        isRootAllowed: true,
        albumIDs: [
          "265623640",
          "731785219",
        ],
        trackIDs: [
          "265623654",
          "265623789",
          "265623921",
          "265624365",
          "265624507",
          "265624805",
          "731785393",
          "731785396",
          "731785412",
          "731785434",
          "731785448",
          "731785450",
        ],
      ),
      .init(
        id: "27909953",
        name: "Kevin Burke",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music30/v4/86/f5/b3/86f5b3ee-d447-1bac-2bd9-423c74968142/766397302126-square_copy.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "1126907142",
        ],
        trackIDs: [
          "1126907364",
          "1126907366",
          "1126907367",
          "1126907368",
          "1126907370",
          "1126907371",
        ],
      ),
      .init(
        id: "2678016",
        name: "Natalie MacMaster",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/d7/b6/b4/d7b6b4c0-e34a-a106-39a6-7aa1b4477921/011661702523_cover.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "1799239869",
        ],
        trackIDs: [
          "1799239870",
          "1799239873",
          "1799239878",
          "1799240089",
          "1799240091",
          "1799240095",
        ],
      ),
      .init(
        id: "73194550",
        name: "Le Vent du Nord",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/d8/6b/16/d86b16cd-f693-2c9b-4cf5-9b9b13adaecb/cover.jpg/600x600bb.jpg"
        ),
        isRootAllowed: true,
        albumIDs: [
          "1841433567",
          "1841433531",
        ],
        trackIDs: [
          "1841433574",
          "1841433578",
          "1841433852",
          "1841433865",
          "1841433868",
          "1841433873",
          "1841433532",
          "1841433535",
          "1841433536",
          "1841433539",
          "1841433540",
          "1841433541",
        ],
      ),
      .init(
        id: "652048",
        name: "Altan",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/ac/1d/d5/ac1dd5b8-be0d-4a91-316c-1b3230301cb8/679.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "1345713469",
        ],
        trackIDs: [
          "1345713711",
          "1345713762",
          "1345713763",
          "1345713764",
          "1345713765",
          "1345713766",
        ],
      ),
      .init(
        id: "73721590",
        name: "Solas",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/2a/bb/00/2abb00cc-5b81-9d35-95d7-9da3f65d2875/mzi.ftntdnur.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "353046697",
        ],
        trackIDs: [
          "353046724",
          "353046771",
          "353046892",
          "353046897",
          "353046973",
          "353047114",
        ],
      ),
      .init(
        id: "39338237",
        name: "Crooked Still",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/5c/75/76/5c75766d-aaa0-4946-fb6b-b711db72bcb6/Some_Strange_Country_3000x3000px.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "1376942431",
        ],
        trackIDs: [
          "1376942433",
          "1376942434",
          "1376942435",
          "1376942436",
          "1376942437",
          "1376942438",
        ],
      ),
      .init(
        id: "2468192",
        name: "Bruce Molsky",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/1b/8a/36/1b8a3639-61f7-b563-d0d1-4f5735c38347/00888072088757.rgb.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "1457049384",
        ],
        trackIDs: [
          "1457049742",
          "1457049929",
          "1457049951",
          "1457049954",
          "1457050052",
          "1457050053",
        ],
      ),
      .init(
        id: "6306607",
        name: "Foghorn Stringband",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/v4/d5/4d/6e/d54d6e24-24ef-1eec-079c-363eaa13e265/885767190191.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "544499766",
        ],
        trackIDs: [
          "544499767",
          "544499768",
          "544499789",
          "544499790",
          "544499791",
          "544499792",
        ],
      ),
      .init(
        id: "73250452",
        name: "Hanneke Cassel",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/75/cd/23/75cd23d9-dfd9-e589-577b-199a65222ee8/888295014083.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "808948486",
        ],
        trackIDs: [
          "808948494",
          "808948495",
          "808948496",
          "808948497",
          "808948498",
          "808948499",
        ],
      ),
      .init(
        id: "6091987",
        name: "Jeremy Kittel",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/94/53/9f/94539ff7-7290-4f0d-e025-23072e5e07c7/artwork.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "1786282479",
        ],
        trackIDs: [
          "1786282480",
          "1786282483",
          "1786282484",
          "1786282486",
          "1786282487",
          "1786282488",
        ],
      ),
      .init(
        id: "372104300",
        name: "Blazin' Fiddles",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/0b/c0/9c/0bc09c8a-bc59-403f-4b3c-140a98d6f974/5052442011613.png/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "1617775324",
        ],
        trackIDs: [
          "1617775596",
          "1617775597",
          "1617775598",
          "1617775599",
          "1617775600",
          "1617775602",
        ],
      ),
      .init(
        id: "254797848",
        name: "Beòlach",
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/58/68/eb/5868ebeb-9939-97c7-31f9-5cf243fd5867/118.jpg/600x600bb.jpg"
        ),
        isRootAllowed: false,
        albumIDs: [
          "1823330663",
        ],
        trackIDs: [
          "1823330674",
          "1823330676",
          "1823330677",
          "1823330680",
          "1823330683",
          "1823330684",
        ],
      ),
    ],
    tracks: [
      .init(
        id: "1511628002",
        title: "Rallpersgubben Kör Timmer",
        artistName: "Lena Jonsson Trio & Lena Jonsson",
        albumTitle: "Stories from the Outside",
        albumID: "1511628001",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1511628003",
        title: "Jullovsschottis (feat. Natalie Haas)",
        artistName: "Lena Jonsson Trio & Lena Jonsson",
        albumTitle: "Stories from the Outside",
        albumID: "1511628001",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1511628004",
        title: "Ispolskan (feat. Arvid Svenungsson)",
        artistName: "Lena Jonsson Trio & Lena Jonsson",
        albumTitle: "Stories from the Outside",
        albumID: "1511628001",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1511628005",
        title: "Sjön",
        artistName: "Lena Jonsson Trio & Lena Jonsson",
        albumTitle: "Stories from the Outside",
        albumID: "1511628001",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1511628276",
        title: "Big Lake",
        artistName: "Lena Jonsson Trio & Lena Jonsson",
        albumTitle: "Stories from the Outside",
        albumID: "1511628001",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1511628277",
        title: "Frisklåten (feat. Arvid Svenungsson & Alexander Wallin)",
        artistName: "Lena Jonsson Trio & Lena Jonsson",
        albumTitle: "Stories from the Outside",
        albumID: "1511628001",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1682152624",
        title: "Regnig dag",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Elements",
        albumID: "1682152618",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1682152629",
        title: "Schack",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Elements",
        albumID: "1682152618",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1682152939",
        title: "Allt är kärlek",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Elements",
        albumID: "1682152618",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1682152945",
        title: "Stora steg",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Elements",
        albumID: "1682152618",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1682152954",
        title: "Gamla stigar",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Elements",
        albumID: "1682152618",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1682152962",
        title: "Singelschottis",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Elements",
        albumID: "1682152618",
        artistIDs: [
          "1501251736",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641791004",
        title: "Typhoon Nozaki",
        artistName: "Väsen",
        albumTitle: "Rule of 3",
        albumID: "1641791000",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641791010",
        title: "Hörrgårdar'n",
        artistName: "Väsen",
        albumTitle: "Rule of 3",
        albumID: "1641791000",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641791019",
        title: "Rosenlundsvalsen",
        artistName: "Väsen",
        albumTitle: "Rule of 3",
        albumID: "1641791000",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641791022",
        title: "Josefin",
        artistName: "Väsen",
        albumTitle: "Rule of 3",
        albumID: "1641791000",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641791357",
        title: "Hållfastmarschen",
        artistName: "Väsen",
        albumTitle: "Rule of 3",
        albumID: "1641791000",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641791367",
        title: "Elsa",
        artistName: "Väsen",
        albumTitle: "Rule of 3",
        albumID: "1641791000",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641851259",
        title: "Väsenvalsen",
        artistName: "Väsen",
        albumTitle: "Brewed",
        albumID: "1641851258",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641851262",
        title: "IPA-gubben",
        artistName: "Väsen",
        albumTitle: "Brewed",
        albumID: "1641851258",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641851263",
        title: "Sommarpolskan",
        artistName: "Väsen",
        albumTitle: "Brewed",
        albumID: "1641851258",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641851808",
        title: "Ellis & Andrés bröllopssvit",
        artistName: "Väsen",
        albumTitle: "Brewed",
        albumID: "1641851258",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641851809",
        title: "Bråkstaken",
        artistName: "Väsen",
        albumTitle: "Brewed",
        albumID: "1641851258",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1641851811",
        title: "Mellow D",
        artistName: "Väsen",
        albumTitle: "Brewed",
        albumID: "1641851258",
        artistIDs: [
          "64784615",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337679253",
        title: "Krafthalling",
        artistName: "Groupa Med Lena Willemark",
        albumTitle: "Månskratt",
        albumID: "337679172",
        artistIDs: [
          "273512071",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music5/v4/c5/8a/95/c58a956d-1116-bfad-fa46-2d08ba1ea7f7/dj.ynhzvvlg.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337679254",
        title: "Klappvalsen",
        artistName: "Groupa Med Lena Willemark",
        albumTitle: "Månskratt",
        albumID: "337679172",
        artistIDs: [
          "273512071",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music5/v4/c5/8a/95/c58a956d-1116-bfad-fa46-2d08ba1ea7f7/dj.ynhzvvlg.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337679255",
        title: "Gobelängedrömmar",
        artistName: "Groupa Med Lena Willemark",
        albumTitle: "Månskratt",
        albumID: "337679172",
        artistIDs: [
          "273512071",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music5/v4/c5/8a/95/c58a956d-1116-bfad-fa46-2d08ba1ea7f7/dj.ynhzvvlg.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337679257",
        title: "Sion Klagar/Edh Ir Kusulit/Stormens Tallar",
        artistName: "Groupa Med Lena Willemark",
        albumTitle: "Månskratt",
        albumID: "337679172",
        artistIDs: [
          "273512071",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music5/v4/c5/8a/95/c58a956d-1116-bfad-fa46-2d08ba1ea7f7/dj.ynhzvvlg.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337679260",
        title: "Vallevan",
        artistName: "Groupa Med Lena Willemark",
        albumTitle: "Månskratt",
        albumID: "337679172",
        artistIDs: [
          "273512071",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music5/v4/c5/8a/95/c58a956d-1116-bfad-fa46-2d08ba1ea7f7/dj.ynhzvvlg.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337679261",
        title: "Krokodiltårar",
        artistName: "Groupa Med Lena Willemark",
        albumTitle: "Månskratt",
        albumID: "337679172",
        artistIDs: [
          "273512071",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music5/v4/c5/8a/95/c58a956d-1116-bfad-fa46-2d08ba1ea7f7/dj.ynhzvvlg.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337816583",
        title: "Kappa Grå",
        artistName: "Frifot",
        albumTitle: "Flyt",
        albumID: "337816392",
        artistIDs: [
          "64812322",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/60/de/53/60de531d-999b-e3ea-3bbb-de6fcf7e809a/dj.vemfnaju.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337816585",
        title: "Gummistöveln",
        artistName: "Frifot",
        albumTitle: "Flyt",
        albumID: "337816392",
        artistIDs: [
          "64812322",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/60/de/53/60de531d-999b-e3ea-3bbb-de6fcf7e809a/dj.vemfnaju.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337816590",
        title: "Vildfågel/Härjedalingarna",
        artistName: "Frifot",
        albumTitle: "Flyt",
        albumID: "337816392",
        artistIDs: [
          "64812322",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/60/de/53/60de531d-999b-e3ea-3bbb-de6fcf7e809a/dj.vemfnaju.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337816595",
        title: "Min sol",
        artistName: "Frifot",
        albumTitle: "Flyt",
        albumID: "337816392",
        artistIDs: [
          "64812322",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/60/de/53/60de531d-999b-e3ea-3bbb-de6fcf7e809a/dj.vemfnaju.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337816616",
        title: "Polska Efter Ollas Per",
        artistName: "Frifot",
        albumTitle: "Flyt",
        albumID: "337816392",
        artistIDs: [
          "64812322",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/60/de/53/60de531d-999b-e3ea-3bbb-de6fcf7e809a/dj.vemfnaju.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "337816643",
        title: "Gammelspaken",
        artistName: "Frifot",
        albumTitle: "Flyt",
        albumID: "337816392",
        artistIDs: [
          "64812322",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/60/de/53/60de531d-999b-e3ea-3bbb-de6fcf7e809a/dj.vemfnaju.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "81005084",
        title: "Calliope Meets Frank",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Fire & Grace",
        albumID: "81005155",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/ca/9b/bf/ca9bbff6-3bc1-cabf-cce4-006ed518b285/mzi.rntmujxz.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "81005089",
        title: "Stirling Castle Set",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Fire & Grace",
        albumID: "81005155",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/ca/9b/bf/ca9bbff6-3bc1-cabf-cce4-006ed518b285/mzi.rntmujxz.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "81005091",
        title: "Josefin's Waltz",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Fire & Grace",
        albumID: "81005155",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/ca/9b/bf/ca9bbff6-3bc1-cabf-cce4-006ed518b285/mzi.rntmujxz.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "81005093",
        title: "St Kilda Wedding / Brose and Butter",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Fire & Grace",
        albumID: "81005155",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/ca/9b/bf/ca9bbff6-3bc1-cabf-cce4-006ed518b285/mzi.rntmujxz.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "81005095",
        title: "The Scandinavian",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Fire & Grace",
        albumID: "81005155",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/ca/9b/bf/ca9bbff6-3bc1-cabf-cce4-006ed518b285/mzi.rntmujxz.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "81005097",
        title: "Archibald MacDonald of Keppoch",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Fire & Grace",
        albumID: "81005155",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/ca/9b/bf/ca9bbff6-3bc1-cabf-cce4-006ed518b285/mzi.rntmujxz.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "425926432",
        title: "Highlander’s Farewell to Ireland / Farewell to Ireland / O'er the Water to Charlie / Highlander’s Farewell (Version Info)",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Highlander's Farewell",
        albumID: "425926410",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "425926434",
        title: "Jig Runrig / The Ramnee Ceilidh",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Highlander's Farewell",
        albumID: "425926410",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "425926436",
        title: "The Pitnacree Ferryman",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Highlander's Farewell",
        albumID: "425926410",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "425926438",
        title: "Grand Etang / Hull’s Reel",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Highlander's Farewell",
        albumID: "425926410",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "425926440",
        title: "Nathaniel Gow’s Lament for the Death of His Brother / The Gallowglass",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Highlander's Farewell",
        albumID: "425926410",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "425926443",
        title: "The Wee Man from Uist / The High Drive",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Highlander's Farewell",
        albumID: "425926410",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/0c/52/75/0c527506-8b79-5abd-0b03-8d93f5303ced/755997012320.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1215440791",
        title: "Freedom Come All Ye",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Ports of Call",
        albumID: "1215440641",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music111/v4/a1/e0/cf/a1e0cfc3-46f9-d67c-d7a8-2a13a00c7ab0/755997012528.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1215440799",
        title: "Derrière Les Carreaux",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Ports of Call",
        albumID: "1215440641",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music111/v4/a1/e0/cf/a1e0cfc3-46f9-d67c-d7a8-2a13a00c7ab0/755997012528.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1215441058",
        title: "Silver and Stuff",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Ports of Call",
        albumID: "1215440641",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music111/v4/a1/e0/cf/a1e0cfc3-46f9-d67c-d7a8-2a13a00c7ab0/755997012528.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1215441113",
        title: "Muiñeiras",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Ports of Call",
        albumID: "1215440641",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music111/v4/a1/e0/cf/a1e0cfc3-46f9-d67c-d7a8-2a13a00c7ab0/755997012528.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1215441125",
        title: "Waltzska for Su-A",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Ports of Call",
        albumID: "1215440641",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music111/v4/a1/e0/cf/a1e0cfc3-46f9-d67c-d7a8-2a13a00c7ab0/755997012528.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1215441196",
        title: "Adelaide/Keeping up with Christine",
        artistName: "Alasdair Fraser & Natalie Haas",
        albumTitle: "Ports of Call",
        albumID: "1215440641",
        artistIDs: [
          "652246",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music111/v4/a1/e0/cf/a1e0cfc3-46f9-d67c-d7a8-2a13a00c7ab0/755997012528.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265621046",
        title: "Paddy Fahy's Reel",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "The Lonesome Touch",
        albumID: "265621036",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/7c/cc/d1/mzi.lkdflxsw.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265621145",
        title: "The Kerfunken Jig",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "The Lonesome Touch",
        albumID: "265621036",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/7c/cc/d1/mzi.lkdflxsw.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265621269",
        title: "Paul Ha'penny / The Garden of Butterflies / The Broken Pledge / The Mother and Child Reel...",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "The Lonesome Touch",
        albumID: "265621036",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/7c/cc/d1/mzi.lkdflxsw.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265621460",
        title: "John Naughton's Reel / Another Paddy Fahy Reel",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "The Lonesome Touch",
        albumID: "265621036",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/7c/cc/d1/mzi.lkdflxsw.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265621511",
        title: "The Cat In the Corner / John Naughton's Jig",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "The Lonesome Touch",
        albumID: "265621036",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/7c/cc/d1/mzi.lkdflxsw.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265621613",
        title: "The Old Bush / The Reel With the Burl",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "The Lonesome Touch",
        albumID: "265621036",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/7c/cc/d1/mzi.lkdflxsw.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "264226209",
        title: "Martin Rochford's / Green Gowned Lass",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "Live In Seattle",
        albumID: "264226184",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/72/3c/88/mzi.gvdputxf.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "264226657",
        title: "Port Na Bpucai / Kilnamona Barndance / Ship In Full Sail / Jer the Rigger / The Old Blackthorn / Exile of Erin / Humours of Tulla / Fitzgerald's Hornpipe / Rakish Paddy / Finbarr Dwyer's Reel No. 1 / P Joe's Pecurious Pa",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "Live In Seattle",
        albumID: "264226184",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/72/3c/88/mzi.gvdputxf.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "264228955",
        title: "Carraroe / Out On the Ocean",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "Live In Seattle",
        albumID: "264226184",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/72/3c/88/mzi.gvdputxf.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "264229396",
        title: "Mary McMahon of Ballinahinch / Miss Lyon's",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "Live In Seattle",
        albumID: "264226184",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/72/3c/88/mzi.gvdputxf.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "264230057",
        title: "Dowd's No.9 / Come West Along the Road",
        artistName: "Dennis Cahill & Martin Hayes",
        albumTitle: "Live In Seattle",
        albumID: "264226184",
        artistIDs: [
          "68316724",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/72/3c/88/mzi.gvdputxf.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "767502122",
        title: "Song 44",
        artistName: "The Gloaming",
        albumTitle: "The Gloaming",
        albumID: "767502097",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/00/5d/6c/005d6c6b-aeb9-41c0-ad0f-10b0e2edd328/632662558768.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "767502123",
        title: "Allistrum's March",
        artistName: "The Gloaming",
        albumTitle: "The Gloaming",
        albumID: "767502097",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/00/5d/6c/005d6c6b-aeb9-41c0-ad0f-10b0e2edd328/632662558768.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "767502124",
        title: "The Necklace of Wrens",
        artistName: "The Gloaming",
        albumTitle: "The Gloaming",
        albumID: "767502097",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/00/5d/6c/005d6c6b-aeb9-41c0-ad0f-10b0e2edd328/632662558768.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "767502125",
        title: "The Girl Who Broke My Heart",
        artistName: "The Gloaming",
        albumTitle: "The Gloaming",
        albumID: "767502097",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/00/5d/6c/005d6c6b-aeb9-41c0-ad0f-10b0e2edd328/632662558768.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "767502126",
        title: "Freedom / Saoirse",
        artistName: "The Gloaming",
        albumTitle: "The Gloaming",
        albumID: "767502097",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/00/5d/6c/005d6c6b-aeb9-41c0-ad0f-10b0e2edd328/632662558768.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "767502127",
        title: "The Sailor's Bonnet",
        artistName: "The Gloaming",
        albumTitle: "The Gloaming",
        albumID: "767502097",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/00/5d/6c/005d6c6b-aeb9-41c0-ad0f-10b0e2edd328/632662558768.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1077568226",
        title: "The Pilgrim's Song",
        artistName: "The Gloaming",
        albumTitle: "2",
        albumID: "1077568224",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music69/v4/e9/b6/86/e9b68616-59dd-f86a-4cd1-38df05675ca3/632662560235.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1077568227",
        title: "Fáinleog (Wanderer)",
        artistName: "The Gloaming",
        albumTitle: "2",
        albumID: "1077568224",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music69/v4/e9/b6/86/e9b68616-59dd-f86a-4cd1-38df05675ca3/632662560235.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1077568228",
        title: "The Hare",
        artistName: "The Gloaming",
        albumTitle: "2",
        albumID: "1077568224",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music69/v4/e9/b6/86/e9b68616-59dd-f86a-4cd1-38df05675ca3/632662560235.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1077568229",
        title: "Oisin's Song",
        artistName: "The Gloaming",
        albumTitle: "2",
        albumID: "1077568224",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music69/v4/e9/b6/86/e9b68616-59dd-f86a-4cd1-38df05675ca3/632662560235.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1077568230",
        title: "The Booley House",
        artistName: "The Gloaming",
        albumTitle: "2",
        albumID: "1077568224",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music69/v4/e9/b6/86/e9b68616-59dd-f86a-4cd1-38df05675ca3/632662560235.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1077568231",
        title: "Repeal of the Union",
        artistName: "The Gloaming",
        albumTitle: "2",
        albumID: "1077568224",
        artistIDs: [
          "289089863",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music69/v4/e9/b6/86/e9b68616-59dd-f86a-4cd1-38df05675ca3/632662560235.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265623654",
        title: "The Rock Reel / The Morning Dew / Reeling On the Box",
        artistName: "Liz Carroll",
        albumTitle: "Lake Effect",
        albumID: "265623640",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/c7/fd/db/mzi.umotolux.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265623789",
        title: "Anlon McDinney  /  Mind the Dresser",
        artistName: "Liz Carroll",
        albumTitle: "Lake Effect",
        albumID: "265623640",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/c7/fd/db/mzi.umotolux.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265623921",
        title: "The Ghost / The Hatchlings / The Long Bow",
        artistName: "Liz Carroll",
        albumTitle: "Lake Effect",
        albumID: "265623640",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/c7/fd/db/mzi.umotolux.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265624365",
        title: "The Jump Ball / Whipple Hill / How We Spent the Christmas",
        artistName: "Liz Carroll",
        albumTitle: "Lake Effect",
        albumID: "265623640",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/c7/fd/db/mzi.umotolux.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265624507",
        title: "Catherine Kelly's / Lake Effect",
        artistName: "Liz Carroll",
        albumTitle: "Lake Effect",
        albumID: "265623640",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/c7/fd/db/mzi.umotolux.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "265624805",
        title: "The Ornery Upright / Sass Is Back",
        artistName: "Liz Carroll",
        albumTitle: "Lake Effect",
        albumID: "265623640",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/c7/fd/db/mzi.umotolux.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "731785393",
        title: "Barbra Streisand's Trip to Saginaw / Michael Connell's",
        artistName: "Liz Carroll",
        albumTitle: "On the Offbeat",
        albumID: "731785219",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/df/b9/b3/dfb9b343-2517-7c94-f559-133c7e5b87d4/884501979375.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "731785396",
        title: "The Fruit and the Snoot / On the Offbeat",
        artistName: "Liz Carroll",
        albumTitle: "On the Offbeat",
        albumID: "731785219",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/df/b9/b3/dfb9b343-2517-7c94-f559-133c7e5b87d4/884501979375.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "731785412",
        title: "Tinsel",
        artistName: "Liz Carroll",
        albumTitle: "On the Offbeat",
        albumID: "731785219",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/df/b9/b3/dfb9b343-2517-7c94-f559-133c7e5b87d4/884501979375.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "731785434",
        title: "Miss Cathy Chilcott / Fiddle Heaven / Fish On",
        artistName: "Liz Carroll",
        albumTitle: "On the Offbeat",
        albumID: "731785219",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/df/b9/b3/dfb9b343-2517-7c94-f559-133c7e5b87d4/884501979375.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "731785448",
        title: "The Wolf / The Duck",
        artistName: "Liz Carroll",
        albumTitle: "On the Offbeat",
        albumID: "731785219",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/df/b9/b3/dfb9b343-2517-7c94-f559-133c7e5b87d4/884501979375.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "731785450",
        title: "Jerome Lacey / The Rogue's Reel",
        artistName: "Liz Carroll",
        albumTitle: "On the Offbeat",
        albumID: "731785219",
        artistIDs: [
          "2614660",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/df/b9/b3/dfb9b343-2517-7c94-f559-133c7e5b87d4/884501979375.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1126907364",
        title: "A Kerry Reel / Michael Coleman's / The Wheels of the World / Julia Delaney",
        artistName: "Kevin Burke",
        albumTitle: "If the Cap Fits (Remastered)",
        albumID: "1126907142",
        artistIDs: [
          "27909953",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music30/v4/86/f5/b3/86f5b3ee-d447-1bac-2bd9-423c74968142/766397302126-square_copy.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1126907366",
        title: "Dinney Delaney's / The Yellow Wattle",
        artistName: "Kevin Burke",
        albumTitle: "If the Cap Fits (Remastered)",
        albumID: "1126907142",
        artistIDs: [
          "27909953",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music30/v4/86/f5/b3/86f5b3ee-d447-1bac-2bd9-423c74968142/766397302126-square_copy.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1126907367",
        title: "The Mason's Apron / Laington's Reel",
        artistName: "Kevin Burke",
        albumTitle: "If the Cap Fits (Remastered)",
        albumID: "1126907142",
        artistIDs: [
          "27909953",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music30/v4/86/f5/b3/86f5b3ee-d447-1bac-2bd9-423c74968142/766397302126-square_copy.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1126907368",
        title: "Paddy Fahy's Jigs / Cliffs of Moher",
        artistName: "Kevin Burke",
        albumTitle: "If the Cap Fits (Remastered)",
        albumID: "1126907142",
        artistIDs: [
          "27909953",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music30/v4/86/f5/b3/86f5b3ee-d447-1bac-2bd9-423c74968142/766397302126-square_copy.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1126907370",
        title: "The Star of Munster / John Stenson's No. 1 / John Stenson's No. 2",
        artistName: "Kevin Burke",
        albumTitle: "If the Cap Fits (Remastered)",
        albumID: "1126907142",
        artistIDs: [
          "27909953",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music30/v4/86/f5/b3/86f5b3ee-d447-1bac-2bd9-423c74968142/766397302126-square_copy.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1126907371",
        title: "Biddy Martin's / Ger the Rigger / Bill Sullivan's Polka",
        artistName: "Kevin Burke",
        albumTitle: "If the Cap Fits (Remastered)",
        albumID: "1126907142",
        artistIDs: [
          "27909953",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music30/v4/86/f5/b3/86f5b3ee-d447-1bac-2bd9-423c74968142/766397302126-square_copy.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1799239870",
        title: "In My Hands",
        artistName: "Natalie MacMaster",
        albumTitle: "In My Hands",
        albumID: "1799239869",
        artistIDs: [
          "2678016",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/d7/b6/b4/d7b6b4c0-e34a-a106-39a6-7aa1b4477921/011661702523_cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1799239873",
        title: "Welcome To The Trossachs",
        artistName: "Natalie MacMaster",
        albumTitle: "In My Hands",
        albumID: "1799239869",
        artistIDs: [
          "2678016",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/d7/b6/b4/d7b6b4c0-e34a-a106-39a6-7aa1b4477921/011661702523_cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1799239878",
        title: "Gramma",
        artistName: "Natalie MacMaster",
        albumTitle: "In My Hands",
        albumID: "1799239869",
        artistIDs: [
          "2678016",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/d7/b6/b4/d7b6b4c0-e34a-a106-39a6-7aa1b4477921/011661702523_cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1799240089",
        title: "Blue Bonnets Over The Border",
        artistName: "Natalie MacMaster",
        albumTitle: "In My Hands",
        albumID: "1799239869",
        artistIDs: [
          "2678016",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/d7/b6/b4/d7b6b4c0-e34a-a106-39a6-7aa1b4477921/011661702523_cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1799240091",
        title: "New York Jig",
        artistName: "Natalie MacMaster",
        albumTitle: "In My Hands",
        albumID: "1799239869",
        artistIDs: [
          "2678016",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/d7/b6/b4/d7b6b4c0-e34a-a106-39a6-7aa1b4477921/011661702523_cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1799240095",
        title: "Flamenco Fling",
        artistName: "Natalie MacMaster",
        albumTitle: "In My Hands",
        albumID: "1799239869",
        artistIDs: [
          "2678016",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/d7/b6/b4/d7b6b4c0-e34a-a106-39a6-7aa1b4477921/011661702523_cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433574",
        title: "Lettre À Durham",
        artistName: "Le Vent du Nord",
        albumTitle: "Tromper Le Temps",
        albumID: "1841433567",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/d8/6b/16/d86b16cd-f693-2c9b-4cf5-9b9b13adaecb/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433578",
        title: "Le Dragon De Chimay",
        artistName: "Le Vent du Nord",
        albumTitle: "Tromper Le Temps",
        albumID: "1841433567",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/d8/6b/16/d86b16cd-f693-2c9b-4cf5-9b9b13adaecb/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433852",
        title: "Toujours Amants",
        artistName: "Le Vent du Nord",
        albumTitle: "Tromper Le Temps",
        albumID: "1841433567",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/d8/6b/16/d86b16cd-f693-2c9b-4cf5-9b9b13adaecb/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433865",
        title: "Le Winnebago",
        artistName: "Le Vent du Nord",
        albumTitle: "Tromper Le Temps",
        albumID: "1841433567",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/d8/6b/16/d86b16cd-f693-2c9b-4cf5-9b9b13adaecb/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433868",
        title: "Le Souhait",
        artistName: "Le Vent du Nord",
        albumTitle: "Tromper Le Temps",
        albumID: "1841433567",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/d8/6b/16/d86b16cd-f693-2c9b-4cf5-9b9b13adaecb/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433873",
        title: "Manteau D'Hiver",
        artistName: "Le Vent du Nord",
        albumTitle: "Tromper Le Temps",
        albumID: "1841433567",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/d8/6b/16/d86b16cd-f693-2c9b-4cf5-9b9b13adaecb/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433532",
        title: "Noce tragique",
        artistName: "Le Vent du Nord",
        albumTitle: "Têtu",
        albumID: "1841433531",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/1c/7a/79/1c7a799c-e773-cc91-0e87-9eb477cfe6fe/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433535",
        title: "Loup-garou",
        artistName: "Le Vent du Nord",
        albumTitle: "Têtu",
        albumID: "1841433531",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/1c/7a/79/1c7a799c-e773-cc91-0e87-9eb477cfe6fe/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433536",
        title: "Le rosier",
        artistName: "Le Vent du Nord",
        albumTitle: "Têtu",
        albumID: "1841433531",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/1c/7a/79/1c7a799c-e773-cc91-0e87-9eb477cfe6fe/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433539",
        title: "Cardeuse-Riopel",
        artistName: "Le Vent du Nord",
        albumTitle: "Têtu",
        albumID: "1841433531",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/1c/7a/79/1c7a799c-e773-cc91-0e87-9eb477cfe6fe/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433540",
        title: "Confédération",
        artistName: "Le Vent du Nord",
        albumTitle: "Têtu",
        albumID: "1841433531",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/1c/7a/79/1c7a799c-e773-cc91-0e87-9eb477cfe6fe/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1841433541",
        title: "Chaise ardente",
        artistName: "Le Vent du Nord",
        albumTitle: "Têtu",
        albumID: "1841433531",
        artistIDs: [
          "73194550",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/1c/7a/79/1c7a799c-e773-cc91-0e87-9eb477cfe6fe/cover.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1345713711",
        title: "The Gap of Dreams / Nia’s Jig / The Beekeeper",
        artistName: "Altan",
        albumTitle: "The Gap of Dreams",
        albumID: "1345713469",
        artistIDs: [
          "652048",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/ac/1d/d5/ac1dd5b8-be0d-4a91-316c-1b3230301cb8/679.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1345713762",
        title: "The Month of January",
        artistName: "Altan",
        albumTitle: "The Gap of Dreams",
        albumID: "1345713469",
        artistIDs: [
          "652048",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/ac/1d/d5/ac1dd5b8-be0d-4a91-316c-1b3230301cb8/679.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1345713763",
        title: "Seán sa Cheo / Tuar / Oíche Fheidhmiúil (A Spirited Night)",
        artistName: "Altan",
        albumTitle: "The Gap of Dreams",
        albumID: "1345713469",
        artistIDs: [
          "652048",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/ac/1d/d5/ac1dd5b8-be0d-4a91-316c-1b3230301cb8/679.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1345713764",
        title: "Bacach Shíl Andaí",
        artistName: "Altan",
        albumTitle: "The Gap of Dreams",
        albumID: "1345713469",
        artistIDs: [
          "652048",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/ac/1d/d5/ac1dd5b8-be0d-4a91-316c-1b3230301cb8/679.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1345713765",
        title: "The Piper in the Cave / An Ghaoth Aniar Aneas (The South-West Wind)",
        artistName: "Altan",
        albumTitle: "The Gap of Dreams",
        albumID: "1345713469",
        artistIDs: [
          "652048",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/ac/1d/d5/ac1dd5b8-be0d-4a91-316c-1b3230301cb8/679.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1345713766",
        title: "Níon a’ Bhaoigheallaigh",
        artistName: "Altan",
        albumTitle: "The Gap of Dreams",
        albumID: "1345713469",
        artistIDs: [
          "652048",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/ac/1d/d5/ac1dd5b8-be0d-4a91-316c-1b3230301cb8/679.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "353046724",
        title: "Hugo’s Big Reel",
        artistName: "Solas",
        albumTitle: "The Turning Tide",
        albumID: "353046697",
        artistIDs: [
          "73721590",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/2a/bb/00/2abb00cc-5b81-9d35-95d7-9da3f65d2875/mzi.ftntdnur.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "353046771",
        title: "The Ditching Boy",
        artistName: "Solas",
        albumTitle: "The Turning Tide",
        albumID: "353046697",
        artistIDs: [
          "73721590",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/2a/bb/00/2abb00cc-5b81-9d35-95d7-9da3f65d2875/mzi.ftntdnur.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "353046892",
        title: "The Crows of Killimer/Box Reel #2/Boys of Malin/The Opera House",
        artistName: "Solas",
        albumTitle: "The Turning Tide",
        albumID: "353046697",
        artistIDs: [
          "73721590",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/2a/bb/00/2abb00cc-5b81-9d35-95d7-9da3f65d2875/mzi.ftntdnur.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "353046897",
        title: "A Girl In the War",
        artistName: "Solas",
        albumTitle: "The Turning Tide",
        albumID: "353046697",
        artistIDs: [
          "73721590",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/2a/bb/00/2abb00cc-5b81-9d35-95d7-9da3f65d2875/mzi.ftntdnur.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "353046973",
        title: "A Waltz for Mairead",
        artistName: "Solas",
        albumTitle: "The Turning Tide",
        albumID: "353046697",
        artistIDs: [
          "73721590",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/2a/bb/00/2abb00cc-5b81-9d35-95d7-9da3f65d2875/mzi.ftntdnur.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "353047114",
        title: "Ghost of Tom Joad",
        artistName: "Solas",
        albumTitle: "The Turning Tide",
        albumID: "353046697",
        artistIDs: [
          "73721590",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/2a/bb/00/2abb00cc-5b81-9d35-95d7-9da3f65d2875/mzi.ftntdnur.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1376942433",
        title: "Sometimes In This Country",
        artistName: "Crooked Still",
        albumTitle: "Some Strange Country",
        albumID: "1376942431",
        artistIDs: [
          "39338237",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/5c/75/76/5c75766d-aaa0-4946-fb6b-b711db72bcb6/Some_Strange_Country_3000x3000px.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1376942434",
        title: "The Golden Vanity",
        artistName: "Crooked Still",
        albumTitle: "Some Strange Country",
        albumID: "1376942431",
        artistIDs: [
          "39338237",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/5c/75/76/5c75766d-aaa0-4946-fb6b-b711db72bcb6/Some_Strange_Country_3000x3000px.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1376942435",
        title: "Distress",
        artistName: "Crooked Still",
        albumTitle: "Some Strange Country",
        albumID: "1376942431",
        artistIDs: [
          "39338237",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/5c/75/76/5c75766d-aaa0-4946-fb6b-b711db72bcb6/Some_Strange_Country_3000x3000px.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1376942436",
        title: "Henry Lee",
        artistName: "Crooked Still",
        albumTitle: "Some Strange Country",
        albumID: "1376942431",
        artistIDs: [
          "39338237",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/5c/75/76/5c75766d-aaa0-4946-fb6b-b711db72bcb6/Some_Strange_Country_3000x3000px.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1376942437",
        title: "Half of What We Know",
        artistName: "Crooked Still",
        albumTitle: "Some Strange Country",
        albumID: "1376942431",
        artistIDs: [
          "39338237",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/5c/75/76/5c75766d-aaa0-4946-fb6b-b711db72bcb6/Some_Strange_Country_3000x3000px.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1376942438",
        title: "I'm Troubled",
        artistName: "Crooked Still",
        albumTitle: "Some Strange Country",
        albumID: "1376942431",
        artistIDs: [
          "39338237",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/5c/75/76/5c75766d-aaa0-4946-fb6b-b711db72bcb6/Some_Strange_Country_3000x3000px.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1457049742",
        title: "Ways Of The World",
        artistName: "Bruce Molsky",
        albumTitle: "Contented Must Be",
        albumID: "1457049384",
        artistIDs: [
          "2468192",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/1b/8a/36/1b8a3639-61f7-b563-d0d1-4f5735c38347/00888072088757.rgb.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1457049929",
        title: "Brushy Run",
        artistName: "Bruce Molsky",
        albumTitle: "Contented Must Be",
        albumID: "1457049384",
        artistIDs: [
          "2468192",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/1b/8a/36/1b8a3639-61f7-b563-d0d1-4f5735c38347/00888072088757.rgb.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1457049951",
        title: "Hills Of Mexico",
        artistName: "Bruce Molsky",
        albumTitle: "Contented Must Be",
        albumID: "1457049384",
        artistIDs: [
          "2468192",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/1b/8a/36/1b8a3639-61f7-b563-d0d1-4f5735c38347/00888072088757.rgb.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1457049954",
        title: "Wake Up Susan & Durang's Hornpipe",
        artistName: "Bruce Molsky",
        albumTitle: "Contented Must Be",
        albumID: "1457049384",
        artistIDs: [
          "2468192",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/1b/8a/36/1b8a3639-61f7-b563-d0d1-4f5735c38347/00888072088757.rgb.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1457050052",
        title: "Green Grows The Laurel",
        artistName: "Bruce Molsky",
        albumTitle: "Contented Must Be",
        albumID: "1457049384",
        artistIDs: [
          "2468192",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/1b/8a/36/1b8a3639-61f7-b563-d0d1-4f5735c38347/00888072088757.rgb.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1457050053",
        title: "Grey Owl & Victor's No. 39",
        artistName: "Bruce Molsky",
        albumTitle: "Contented Must Be",
        albumID: "1457049384",
        artistIDs: [
          "2468192",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music113/v4/1b/8a/36/1b8a3639-61f7-b563-d0d1-4f5735c38347/00888072088757.rgb.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "544499767",
        title: "Be Kind to a Man While He's Down",
        artistName: "Foghorn Stringband",
        albumTitle: "Outshine the Sun",
        albumID: "544499766",
        artistIDs: [
          "6306607",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/v4/d5/4d/6e/d54d6e24-24ef-1eec-079c-363eaa13e265/885767190191.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "544499768",
        title: "Humpback Mule",
        artistName: "Foghorn Stringband",
        albumTitle: "Outshine the Sun",
        albumID: "544499766",
        artistIDs: [
          "6306607",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/v4/d5/4d/6e/d54d6e24-24ef-1eec-079c-363eaa13e265/885767190191.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "544499789",
        title: "Homestead On the Farm",
        artistName: "Foghorn Stringband",
        albumTitle: "Outshine the Sun",
        albumID: "544499766",
        artistIDs: [
          "6306607",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/v4/d5/4d/6e/d54d6e24-24ef-1eec-079c-363eaa13e265/885767190191.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "544499790",
        title: "Salty River Reel",
        artistName: "Foghorn Stringband",
        albumTitle: "Outshine the Sun",
        albumID: "544499766",
        artistIDs: [
          "6306607",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/v4/d5/4d/6e/d54d6e24-24ef-1eec-079c-363eaa13e265/885767190191.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "544499791",
        title: "Going Home",
        artistName: "Foghorn Stringband",
        albumTitle: "Outshine the Sun",
        albumID: "544499766",
        artistIDs: [
          "6306607",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/v4/d5/4d/6e/d54d6e24-24ef-1eec-079c-363eaa13e265/885767190191.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "544499792",
        title: "Horseshoe Bend",
        artistName: "Foghorn Stringband",
        albumTitle: "Outshine the Sun",
        albumID: "544499766",
        artistIDs: [
          "6306607",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music/v4/d5/4d/6e/d54d6e24-24ef-1eec-079c-363eaa13e265/885767190191.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "808948494",
        title: "Dot the Dragon's Eyes",
        artistName: "Hanneke Cassel",
        albumTitle: "Dot the Dragon's Eyes",
        albumID: "808948486",
        artistIDs: [
          "73250452",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/75/cd/23/75cd23d9-dfd9-e589-577b-199a65222ee8/888295014083.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "808948495",
        title: "Katrina McCoy's Jig / Sierra Fiddle Circle's Compliments to the Girls of Mudzini Kwetu",
        artistName: "Hanneke Cassel",
        albumTitle: "Dot the Dragon's Eyes",
        albumID: "808948486",
        artistIDs: [
          "73250452",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/75/cd/23/75cd23d9-dfd9-e589-577b-199a65222ee8/888295014083.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "808948496",
        title: "The Captain",
        artistName: "Hanneke Cassel",
        albumTitle: "Dot the Dragon's Eyes",
        albumID: "808948486",
        artistIDs: [
          "73250452",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/75/cd/23/75cd23d9-dfd9-e589-577b-199a65222ee8/888295014083.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "808948497",
        title: "Natasha McCoy's Reel / Lianne Mclean's Revenge",
        artistName: "Hanneke Cassel",
        albumTitle: "Dot the Dragon's Eyes",
        albumID: "808948486",
        artistIDs: [
          "73250452",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/75/cd/23/75cd23d9-dfd9-e589-577b-199a65222ee8/888295014083.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "808948498",
        title: "Jig for Christina",
        artistName: "Hanneke Cassel",
        albumTitle: "Dot the Dragon's Eyes",
        albumID: "808948486",
        artistIDs: [
          "73250452",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/75/cd/23/75cd23d9-dfd9-e589-577b-199a65222ee8/888295014083.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "808948499",
        title: "Eliana Grace / Dancing with Bryce",
        artistName: "Hanneke Cassel",
        albumTitle: "Dot the Dragon's Eyes",
        albumID: "808948486",
        artistIDs: [
          "73250452",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music124/v4/75/cd/23/75cd23d9-dfd9-e589-577b-199a65222ee8/888295014083.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1786282480",
        title: "The Curious Beetle Medley (feat. Tola Custy)",
        artistName: "Jeremy Kittel",
        albumTitle: "Chasing Sparks",
        albumID: "1786282479",
        artistIDs: [
          "6091987",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/94/53/9f/94539ff7-7290-4f0d-e025-23072e5e07c7/artwork.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1786282483",
        title: "The Golden-Plover Set",
        artistName: "Jeremy Kittel",
        albumTitle: "Chasing Sparks",
        albumID: "1786282479",
        artistIDs: [
          "6091987",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/94/53/9f/94539ff7-7290-4f0d-e025-23072e5e07c7/artwork.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1786282484",
        title: "Remember Blake",
        artistName: "Jeremy Kittel",
        albumTitle: "Chasing Sparks",
        albumID: "1786282479",
        artistIDs: [
          "6091987",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/94/53/9f/94539ff7-7290-4f0d-e025-23072e5e07c7/artwork.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1786282486",
        title: "The Chase",
        artistName: "Jeremy Kittel",
        albumTitle: "Chasing Sparks",
        albumID: "1786282479",
        artistIDs: [
          "6091987",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/94/53/9f/94539ff7-7290-4f0d-e025-23072e5e07c7/artwork.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1786282487",
        title: "The May Morning Dew",
        artistName: "Jeremy Kittel",
        albumTitle: "Chasing Sparks",
        albumID: "1786282479",
        artistIDs: [
          "6091987",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/94/53/9f/94539ff7-7290-4f0d-e025-23072e5e07c7/artwork.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1786282488",
        title: "Disconnect",
        artistName: "Jeremy Kittel",
        albumTitle: "Chasing Sparks",
        albumID: "1786282479",
        artistIDs: [
          "6091987",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/94/53/9f/94539ff7-7290-4f0d-e025-23072e5e07c7/artwork.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1617775596",
        title: "Shetland Night",
        artistName: "Blazin' Fiddles",
        albumTitle: "North",
        albumID: "1617775324",
        artistIDs: [
          "372104300",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/0b/c0/9c/0bc09c8a-bc59-403f-4b3c-140a98d6f974/5052442011613.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1617775597",
        title: "Arran Ceilidh",
        artistName: "Blazin' Fiddles",
        albumTitle: "North",
        albumID: "1617775324",
        artistIDs: [
          "372104300",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/0b/c0/9c/0bc09c8a-bc59-403f-4b3c-140a98d6f974/5052442011613.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1617775598",
        title: "Gamekeeper's",
        artistName: "Blazin' Fiddles",
        albumTitle: "North",
        albumID: "1617775324",
        artistIDs: [
          "372104300",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/0b/c0/9c/0bc09c8a-bc59-403f-4b3c-140a98d6f974/5052442011613.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1617775599",
        title: "Braehead Cottage",
        artistName: "Blazin' Fiddles",
        albumTitle: "North",
        albumID: "1617775324",
        artistIDs: [
          "372104300",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/0b/c0/9c/0bc09c8a-bc59-403f-4b3c-140a98d6f974/5052442011613.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1617775600",
        title: "Catch and Kiss",
        artistName: "Blazin' Fiddles",
        albumTitle: "North",
        albumID: "1617775324",
        artistIDs: [
          "372104300",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/0b/c0/9c/0bc09c8a-bc59-403f-4b3c-140a98d6f974/5052442011613.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1617775602",
        title: "Java",
        artistName: "Blazin' Fiddles",
        albumTitle: "North",
        albumID: "1617775324",
        artistIDs: [
          "372104300",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/0b/c0/9c/0bc09c8a-bc59-403f-4b3c-140a98d6f974/5052442011613.png/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1823330674",
        title: "Annie’s New Heart",
        artistName: "Beòlach",
        albumTitle: "All Hands",
        albumID: "1823330663",
        artistIDs: [
          "254797848",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/58/68/eb/5868ebeb-9939-97c7-31f9-5cf243fd5867/118.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1823330676",
        title: "Kilts on Fire",
        artistName: "Beòlach",
        albumTitle: "All Hands",
        albumID: "1823330663",
        artistIDs: [
          "254797848",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/58/68/eb/5868ebeb-9939-97c7-31f9-5cf243fd5867/118.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1823330677",
        title: "Veronica’s",
        artistName: "Beòlach",
        albumTitle: "All Hands",
        albumID: "1823330663",
        artistIDs: [
          "254797848",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/58/68/eb/5868ebeb-9939-97c7-31f9-5cf243fd5867/118.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1823330680",
        title: "Schooner Lane",
        artistName: "Beòlach",
        albumTitle: "All Hands",
        albumID: "1823330663",
        artistIDs: [
          "254797848",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/58/68/eb/5868ebeb-9939-97c7-31f9-5cf243fd5867/118.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1823330683",
        title: "Backstreet Girls",
        artistName: "Beòlach",
        albumTitle: "All Hands",
        albumID: "1823330663",
        artistIDs: [
          "254797848",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/58/68/eb/5868ebeb-9939-97c7-31f9-5cf243fd5867/118.jpg/600x600bb.jpg"
        ),
      ),
      .init(
        id: "1823330684",
        title: "Prayerful Hymn",
        artistName: "Beòlach",
        albumTitle: "All Hands",
        albumID: "1823330663",
        artistIDs: [
          "254797848",
        ],
        artworkURL: URL(
          string: "https://is1-ssl.mzstatic.com/image/thumb/Music221/v4/58/68/eb/5868ebeb-9939-97c7-31f9-5cf243fd5867/118.jpg/600x600bb.jpg"
        ),
      ),
    ],
  )
}
