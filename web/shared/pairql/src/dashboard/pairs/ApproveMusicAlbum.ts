// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace ApproveMusicAlbum {
  export interface Input {
    childId: UUID;
    appleMusicAlbumId: string;
    title: string;
    artistName: string;
    artworkUrl?: string;
    artwork?: {
      url?: string;
      width?: number;
      height?: number;
      bgColor?: string;
      textColor1?: string;
      textColor2?: string;
      textColor3?: string;
      textColor4?: string;
    };
    trackCount?: number;
    showsArtwork: boolean;
  }

  export type Output = SuccessOutput;
}
