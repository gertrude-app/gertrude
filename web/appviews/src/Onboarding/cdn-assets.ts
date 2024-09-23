import type { MacOSVersion } from './onboarding-store';

interface VideoAsset {
  type: 'video';
  url: string;
  render: boolean;
}

interface StaticImgAsset {
  type: 'image';
  url: string;
}

interface SingleGifAsset {
  type: 'gif';
  url: string;
  duration: number;
}

interface MultiGifAsset {
  type: 'images';
  steps: Array<{ url: string; duration: number }>;
}

export type ImageAsset = StaticImgAsset | SingleGifAsset | MultiGifAsset;

export type CdnAsset = VideoAsset | ImageAsset;

class CdnAssets implements ExhaustiveAssets {
  os(os: MacOSVersion['name']): OsCdnAssets {
    return new OsCdnAssets(os);
  }

  video(id: VideoId, render = false): VideoAsset {
    return { type: `video`, url: `${ENDPOINT}/common/${id}.mp4`, render };
  }

  osVideo(os: MacOSVersion['name'], id: OsVideoId, render = false): VideoAsset {
    return new OsCdnAssets(os).video(id, render);
  }

  img(filename: CommonImgId): ImageAsset {
    const data = COMMON_IMG_DATA[filename];
    if (typeof data === `string`) {
      return { type: `image`, url: `${ENDPOINT}/common/${filename}.${data}` };
    } else if (data.length === 1) {
      return {
        type: `gif`,
        url: `${ENDPOINT}/common/${filename}.gif`,
        duration: data[0],
      };
    } else {
      return {
        type: `images`,
        steps: data.map((duration, index) => ({
          url: `${ENDPOINT}/common/${filename}--pt-${index + 1}.gif`,
          duration,
        })),
      };
    }
  }

  osImg(os: MacOSVersion['name'], filename: OsImgId): ImageAsset {
    return new OsCdnAssets(os).img(filename);
  }

  all(): CdnAsset[] {
    return [
      ...VIDEO_IDS.map((id) => this.video(id)),
      ...COMMON_IMG_IDS.map((filename) => this.img(filename)),
      ...new OsCdnAssets(`catalina`).all(),
      ...new OsCdnAssets(`bigSur`).all(),
      ...new OsCdnAssets(`monterey`).all(),
      ...new OsCdnAssets(`ventura`).all(),
      ...new OsCdnAssets(`sonoma`).all(),
      ...new OsCdnAssets(`sequoia`).all(),
    ];
  }
}

class OsCdnAssets implements ExhaustiveAssets {
  constructor(public readonly os: MacOSVersion['name']) {}

  video(id: OsVideoId, render = false): VideoAsset {
    return { type: `video`, url: `${ENDPOINT}/${this.os}/${id}.mp4`, render };
  }

  img(id: OsImgId): ImageAsset {
    const data = OS_IMAGE_DATA[id];
    if (typeof data === `string`) {
      return {
        type: `image`,
        url: `${ENDPOINT}/${this.os}/${id}.${data}`,
      };
    }
    const durations = data[this.os];
    if (durations.length > 1) {
      return {
        type: `images`,
        steps: durations.map((duration, index) => ({
          url: `${ENDPOINT}/${this.os}/${id}--pt-${index + 1}.gif`,
          duration,
        })),
      };
    } else {
      return {
        type: `gif`,
        url: `${ENDPOINT}/${this.os}/${id}.gif`,
        duration: durations[0],
      };
    }
  }

  // these are legacy non-multipart images, only used before 2.1.3
  // delete when no one should be onboarding with an old < 2.1.3 app
  legacyImgs(): string[] {
    return [
      `${ENDPOINT}/${this.os}/allow-notifications.gif`,
      `${ENDPOINT}/${this.os}/allow-screen-recording.gif`,
      `${ENDPOINT}/${this.os}/allow-keylogging.gif`,
      `${ENDPOINT}/${this.os}/install-sys-ext.gif`,
    ];
  }

  all(): CdnAsset[] {
    return [
      ...OS_VIDEO_IDS.map((id) => this.video(id)),
      ...OS_IMAGE_IDS.map((filename) => this.img(filename)),
      ...this.legacyImgs().map((url) => ({ type: `image`, url }) as const),
    ];
  }
}

export default new CdnAssets();

const ENDPOINT = `https://gertrude-web-assets.nyc3.cdn.digitaloceanspaces.com/onboarding-v2.5.0`;

const VIDEO_IDS = [`post-onboarding-tour`, `get-connection-code`] as const;

const OS_VIDEO_IDS = [
  `troubleshoot-notifications`,
  `troubleshoot-screen-recording`,
  `troubleshoot-keylogging`,
  `troubleshoot-sys-ext-install`,
] as const;

const COMMON_IMG_IDS = [
  `notifications`,
  `administrate`,
  `locate-menubar-icon`,
  `wrong-install-dir`,
  `how-to-use-gifs`,
] as const;

const OS_IMAGE_IDS = [
  `allow-keylogging`,
  `allow-notifications`,
  `allow-screen-recording`,
  `install-sys-ext`,
  `sys-ext-install-trick`,
] as const;

const COMMON_IMG_DATA: Record<CommonImgId, string | [number, ...number[]]> = {
  notifications: `png`,
  administrate: `png`,
  'locate-menubar-icon': `gif`,
  'wrong-install-dir': [10.8],
  'how-to-use-gifs': [4.88, 5.45],
};

const OS_IMAGE_DATA: Record<
  OsImgId,
  string | Record<MacOSVersion['name'], [number, number, ...number[]]>
> = {
  'sys-ext-install-trick': `png`,
  'allow-notifications': {
    catalina: [3.55, 3.93, 4.53],
    bigSur: [3.55, 3.93, 4.53],
    monterey: [3.55, 3.93, 4.53],
    ventura: [5.63, 4.73, 3.73],
    sonoma: [5.63, 4.73, 3.73],
    sequoia: [5.63, 4.73, 3.73],
  },
  'allow-screen-recording': {
    catalina: [3.03, 4.8, 3.06, 10.93, 4.8],
    bigSur: [3.03, 5.09, 2.81, 3.2],
    monterey: [3.03, 5.09, 2.81, 3.2],
    ventura: [3.27, 4.6, 3.73],
    sonoma: [3.27, 4.6, 3.73],
    sequoia: [3.27, 4.6, 3.73],
  },
  'allow-keylogging': {
    catalina: [3.58, 4.18],
    bigSur: [3.58, 4.18],
    monterey: [3.58, 4.18],
    ventura: [3.94, 4.93],
    sonoma: [3.94, 4.93],
    sequoia: [3.94, 4.93],
  },
  'install-sys-ext': {
    catalina: [2.95, 3.16, 3.86, 3.33],
    bigSur: [3.48, 5.48, 4.06, 4.2],
    monterey: [3.48, 5.48, 4.06, 4.2],
    ventura: [3.1, 6.72, 5.22],
    sonoma: [3.1, 6.72, 5.22],
    sequoia: [3.1, 6.72, 5.22], // 👋 <-- needs new version
  },
};

interface ExhaustiveAssets {
  all(): CdnAsset[];
}

type CommonImgId = (typeof COMMON_IMG_IDS)[number];
type OsImgId = (typeof OS_IMAGE_IDS)[number];
type VideoId = (typeof VIDEO_IDS)[number];
type OsVideoId = (typeof OS_VIDEO_IDS)[number];
