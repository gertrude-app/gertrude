export interface PodcastScreenshotArtwork {
  title: string;
  credit: string;
  source: string;
  license: `CC BY (publisher grant)` | `Public domain`;
  licenseUrl: string;
}

export const podcastScreenshotArtwork: PodcastScreenshotArtwork[] = [
  {
    title: `Treasure Island`,
    credit: `Scott Carpenter / LibriVox; artwork from the 1911 edition`,
    source: `https://librivox.org/treasure-island-by-robert-louis-stevenson/`,
    license: `Public domain`,
    licenseUrl: `https://librivox.org/pages/public-domain/`,
  },
  {
    title: `Alice’s Adventures in Wonderland`,
    credit: `John Tenniel; cover design by Seth Jones / LibriVox`,
    source: `https://librivox.org/alices-adventures-in-wonderland-by-lewis-carroll/`,
    license: `Public domain`,
    licenseUrl: `https://librivox.org/pages/public-domain/`,
  },
  {
    title: `The Velveteen Rabbit`,
    credit: `William Nicholson; cover design by Janette Brown / LibriVox`,
    source: `https://librivox.org/the-velveteen-rabbit-by-margery-williams/`,
    license: `Public domain`,
    licenseUrl: `https://librivox.org/pages/public-domain/`,
  },
  {
    title: `The Great Big Treasury of Beatrix Potter`,
    credit: `Beatrix Potter; cover design by Bart de Leeuw / LibriVox`,
    source: `https://librivox.org/the-great-big-treasury-of-beatrix-potter-by-beatrix-potter/`,
    license: `Public domain`,
    licenseUrl: `https://librivox.org/pages/public-domain/`,
  },
  {
    title: `New Rustacean`,
    credit: `Chris Krycho; Rust logo by the Rust Foundation`,
    source: `https://newrustacean.com/`,
    license: `CC BY (publisher grant)`,
    licenseUrl: `https://newrustacean.com/`,
  },
];
