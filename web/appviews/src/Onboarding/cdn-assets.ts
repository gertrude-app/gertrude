import type { OSGroup } from './onboarding-store';

export type AssetType = 'video' | 'image';

export interface CdnAsset<T extends AssetType = AssetType> {
  url: string;
  type: T;
  render: boolean;
}

class CdnAssets implements ExhaustiveAssets {
  os(os: OSGroup): OsCdnAssets {
    return new OsCdnAssets(os);
  }

  video(id: VideoId, render = false): CdnAsset<'video'> {
    return { type: `video`, url: `${ENDPOINT}/common/${id}.mp4`, render };
  }

  osVideo(os: OSGroup, id: OsVideoId, render = false): CdnAsset<'video'> {
    return new OsCdnAssets(os).video(id, render);
  }

  img(filename: ImgFilename): CdnAsset<'image'> {
    return { type: `image`, url: `${ENDPOINT}/common/${filename}`, render: true };
  }

  osImg(os: OSGroup, filename: OsImgFilename): CdnAsset<'image'> {
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

  video(id: OsVideoId, render = false): CdnAsset<'video'> {
    return { type: `video`, url: `${ENDPOINT}/${this.os}/${id}.mp4`, render };
  }

  img(filename: OsImgFilename): CdnAsset<'image'> {
    return { type: `image`, url: `${ENDPOINT}/${this.os}/${filename}`, render: true };
  }

  all(): CdnAsset[] {
    return [
      ...OS_VIDEO_IDS.map((id) => this.video(id)),
      ...OS_IMAGE_FILENAMES.map((filename) => this.img(filename)),
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

const OS_IMAGE_FILENAMES = [
  `allow-keylogging.gif`,
  `allow-notifications.gif`,
  `allow-screen-recording.gif`,
  `install-sys-ext.gif`,
] as const;

interface ExhaustiveAssets {
  all(): CdnAsset[];
}

type ImgFilename = (typeof IMAGE_FILENAMES)[number];
type OsImgFilename = (typeof OS_IMAGE_FILENAMES)[number];
type VideoId = (typeof VIDEO_IDS)[number];
type OsVideoId = (typeof OS_VIDEO_IDS)[number];
