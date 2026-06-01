// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace ApproveMusicAlbum {
  export interface Input {
    childId: UUID;
    appleMusicAlbumId: string;
    title: string;
    artistName: string;
    artworkUrl?: string;
    trackCount?: number;
    showsArtwork: boolean;
  }

  export type Output = SuccessOutput;
}
