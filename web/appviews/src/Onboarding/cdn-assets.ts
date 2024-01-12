import type { OSGroup } from './onboarding-store';

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
  os(os: OSGroup): OsCdnAssets {
    return new OsCdnAssets(os);
  }

  video(id: VideoId, render = false): VideoAsset {
    return { type: `video`, url: `${ENDPOINT}/common/${id}.mp4`, render };
  }

  osVideo(os: OSGroup, id: OsVideoId, render = false): VideoAsset {
    return new OsCdnAssets(os).video(id, render);
  }

  img(filename: ImgFilename): StaticImgAsset | SingleGifAsset {
    const duration = IMAGE_DATA[filename];
    if (duration) {
      return { type: `gif`, url: `${ENDPOINT}/common/${filename}`, duration };
    } else {
      return { type: `image`, url: `${ENDPOINT}/common/${filename}` };
    }
  }

  osImg(os: OSGroup, filename: OsImgId): ImageAsset {
    return new OsCdnAssets(os).img(filename);
  }

  all(): CdnAsset[] {
    return [
      ...VIDEO_IDS.map((id) => this.video(id)),
      ...IMAGE_FILENAMES.map((filename) => this.img(filename)),
      ...new OsCdnAssets(`catalina`).all(),
      ...new OsCdnAssets(`bigSurOrMonterey`).all(),
      ...new OsCdnAssets(`venturaOrLater`).all(),
    ];
  }
}

class OsCdnAssets implements ExhaustiveAssets {
  constructor(public readonly os: OSGroup) {}

  video(id: OsVideoId, render = false): VideoAsset {
    return { type: `video`, url: `${ENDPOINT}/${this.os}/${id}.mp4`, render };
  }

  img(id: OsImgId): ImageAsset {
    const durations = OS_IMAGE_DATA[id][this.os];
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

const ENDPOINT = `https://gertrude-web-assets.nyc3.cdn.digitaloceanspaces.com/onboarding`;

const VIDEO_IDS = [`post-onboarding-tour`, `get-connection-code`] as const;

const OS_VIDEO_IDS = [
  `troubleshoot-notifications`,
  `troubleshoot-screen-recording`,
  `troubleshoot-keylogging`,
  `troubleshoot-sys-ext-install`,
] as const;

const IMAGE_FILENAMES = [
  `notifications.png`,
  `administrate.png`,
  `locate-menubar-icon.gif`,
  `wrong-install-dir.gif`,
] as const;

const OS_IMAGE_IDS = [
  `allow-keylogging`,
  `allow-notifications`,
  `allow-screen-recording`,
  `install-sys-ext`,
] as const;

const IMAGE_DATA: Record<ImgFilename, number | null> = {
  'notifications.png': null,
  'administrate.png': null,
  'locate-menubar-icon.gif': null,
  'wrong-install-dir.gif': 10.8,
};

const OS_IMAGE_DATA: Record<OsImgId, Record<OSGroup, [number, ...number[]]>> = {
  'allow-notifications': {
    catalina: [3.55, 3.93, 4.53],
    bigSurOrMonterey: [3.55, 3.93, 4.53],
    venturaOrLater: [5.63, 4.73, 3.73],
  },
  'allow-screen-recording': {
    catalina: [3.03, 4.8, 3.06, 10.93, 4.8],
    bigSurOrMonterey: [3.03, 5.09, 2.81, 3.2],
    venturaOrLater: [3.27, 4.6, 3.73],
  },
  'allow-keylogging': {
    catalina: [3.58, 4.18],
    bigSurOrMonterey: [3.58, 4.18],
    venturaOrLater: [3.94, 4.93],
  },
  'install-sys-ext': {
    catalina: [2.95, 3.16, 3.86, 3.33],
    bigSurOrMonterey: [3.48, 5.48, 4.06, 4.2],
    venturaOrLater: [3.1, 6.72, 5.22],
  },
};

interface ExhaustiveAssets {
  all(): CdnAsset[];
}

type ImgFilename = (typeof IMAGE_FILENAMES)[number];
type OsImgId = (typeof OS_IMAGE_IDS)[number];
type VideoId = (typeof VIDEO_IDS)[number];
type OsVideoId = (typeof OS_VIDEO_IDS)[number];
