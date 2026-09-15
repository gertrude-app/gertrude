export interface PodcastArtwork {
  title: string;
  src: string;
  credit: string;
  source: string;
  license:
    | `CC BY 4.0`
    | `CC BY-ND 4.0`
    | `CC0 1.0`
    | `CC BY (publisher grant)`
    | `Public domain`;
  licenseUrl: string;
  showUrl: string;
  feedUrl: string;
  originalSha256?: string;
  frameColor?: string;
}

export const podcastArtwork = {
  materialism: {
    title: `Materialism`,
    src: `/podcasts/licensed-artwork/materialism.webp`,
    credit: `Andrew Falkowski`,
    source: `https://commons.wikimedia.org/wiki/File:Materialism_Cover_Art.png`,
    license: `CC BY 4.0`,
    licenseUrl: `https://creativecommons.org/licenses/by/4.0/`,
    showUrl: `https://materialismpodcast.com/`,
    feedUrl: `https://pinecast.com/feed/materialism`,
  },
  'new-rustacean': {
    title: `New Rustacean`,
    src: `/podcasts/licensed-artwork/new-rustacean.webp`,
    credit: `Chris Krycho; Rust logo by the Rust Foundation`,
    source: `https://newrustacean.com/`,
    license: `CC BY (publisher grant)`,
    licenseUrl: `https://newrustacean.com/`,
    showUrl: `https://newrustacean.com/`,
    feedUrl: `https://newrustacean.com/feed.xml`,
  },
  'destination-linux': {
    title: `Destination Linux`,
    frameColor: `#eaeaea`,
    src: `/podcasts/licensed-artwork/destination-linux.webp`,
    credit: `TuxDigital`,
    source: `https://tuxdigital.com/podcasts/destination-linux/`,
    license: `CC BY-ND 4.0`,
    licenseUrl: `https://creativecommons.org/licenses/by-nd/4.0/`,
    showUrl: `https://tuxdigital.com/podcasts/destination-linux/`,
    feedUrl: `https://feeds.fireside.fm/destinationlinux/rss`,
    originalSha256: `e38e1a7589c8c61e3c15f686f28486cec00765dcd7c9440573cbcd57332b44ba`,
  },
  'hardware-addicts': {
    title: `Hardware Addicts`,
    frameColor: `#153b3e`,
    src: `/podcasts/licensed-artwork/hardware-addicts.webp`,
    credit: `TuxDigital`,
    source: `https://tuxdigital.com/podcasts/hardware-addicts/`,
    license: `CC BY-ND 4.0`,
    licenseUrl: `https://creativecommons.org/licenses/by-nd/4.0/`,
    showUrl: `https://tuxdigital.com/podcasts/hardware-addicts/`,
    feedUrl: `https://feeds.fireside.fm/hardwareaddicts/rss`,
    originalSha256: `1dab599f734cee521c683d1bacf57d011bb1f0cf519590cc8d98d74b5f0453fb`,
  },
  'linux-out-loud': {
    title: `Linux Out Loud`,
    frameColor: `#cccccc`,
    src: `/podcasts/licensed-artwork/linux-out-loud.webp`,
    credit: `TuxDigital`,
    source: `https://tuxdigital.com/podcasts/linux-out-loud/`,
    license: `CC BY-ND 4.0`,
    licenseUrl: `https://creativecommons.org/licenses/by-nd/4.0/`,
    showUrl: `https://tuxdigital.com/podcasts/linux-out-loud/`,
    feedUrl: `https://feeds.fireside.fm/dlnxtend/rss`,
    originalSha256: `89898a37bde3a40e79e28ae2e8466f56227ea9406331f808dba6b99cab5f22ad`,
  },
  'this-week-in-linux': {
    title: `This Week in Linux`,
    frameColor: `#416592`,
    src: `/podcasts/licensed-artwork/this-week-in-linux.webp`,
    credit: `TuxDigital`,
    source: `https://tuxdigital.com/podcasts/this-week-in-linux/`,
    license: `CC BY-ND 4.0`,
    licenseUrl: `https://creativecommons.org/licenses/by-nd/4.0/`,
    showUrl: `https://tuxdigital.com/podcasts/this-week-in-linux/`,
    feedUrl: `https://feeds.fireside.fm/thisweekinlinux/rss`,
    originalSha256: `182870b3b18ffad0a17e9b3c2e1b159935e98bb98089a2b46759f29d87cfcf67`,
  },
  'sudo-show': {
    title: `Sudo Show`,
    frameColor: `#000000`,
    src: `/podcasts/licensed-artwork/sudo-show.webp`,
    credit: `TuxDigital`,
    source: `https://tuxdigital.com/podcasts/sudo-show/`,
    license: `CC BY-ND 4.0`,
    licenseUrl: `https://creativecommons.org/licenses/by-nd/4.0/`,
    showUrl: `https://tuxdigital.com/podcasts/sudo-show/`,
    feedUrl: `https://feeds.fireside.fm/sudoshow/rss`,
    originalSha256: `63bdb42d0585c739ce0553c01b9ec56e7ae3530fbff4170a1ab2752cebbe88af`,
  },
  frets: {
    title: `Frets with DJ Fey`,
    src: `/podcasts/licensed-artwork/frets.webp`,
    credit: `DJFey58`,
    source: `https://commons.wikimedia.org/wiki/File:Frets_Logo_1200_rnd.png`,
    license: `CC0 1.0`,
    licenseUrl: `https://creativecommons.org/publicdomain/zero/1.0/`,
    showUrl: `https://www.fretspodcast.com/`,
    feedUrl: `https://rss.buzzsprout.com/1898249.rss`,
  },
  'web-but-green': {
    title: `Web, But Green!`,
    src: `/podcasts/licensed-artwork/web-but-green.webp`,
    credit: `Tbeyer01 (Dr. Torsten Beyer)`,
    source: `https://commons.wikimedia.org/wiki/File:Web_But_Green_Podcast_Cover.jpg`,
    license: `CC BY 4.0`,
    licenseUrl: `https://creativecommons.org/licenses/by/4.0/`,
    showUrl: `https://webbutgreen.de/`,
    feedUrl: `https://web-but-green.podigee.io/feed/mp3`,
  },
  'beatrix-potter': {
    title: `The Great Big Treasury of Beatrix Potter`,
    src: `/podcasts/licensed-artwork/beatrix-potter.webp`,
    credit: `Beatrix Potter; cover design by Bart de Leeuw / LibriVox`,
    source: `https://librivox.org/the-great-big-treasury-of-beatrix-potter-by-beatrix-potter/`,
    license: `Public domain`,
    licenseUrl: `https://librivox.org/pages/public-domain/`,
    showUrl: `https://librivox.org/the-great-big-treasury-of-beatrix-potter-by-beatrix-potter/`,
    feedUrl: `https://librivox.org/rss/2990`,
  },
  'velveteen-rabbit': {
    title: `The Velveteen Rabbit`,
    src: `/podcasts/licensed-artwork/velveteen-rabbit.webp`,
    credit: `William Nicholson; cover design by Janette Brown / LibriVox`,
    source: `https://librivox.org/the-velveteen-rabbit-by-margery-williams/`,
    license: `Public domain`,
    licenseUrl: `https://librivox.org/pages/public-domain/`,
    showUrl: `https://librivox.org/the-velveteen-rabbit-by-margery-williams/`,
    feedUrl: `https://librivox.org/rss/432`,
  },
} as const satisfies Record<string, PodcastArtwork>;
