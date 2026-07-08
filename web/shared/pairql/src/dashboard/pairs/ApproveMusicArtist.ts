// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace ApproveMusicArtist {
  export interface Input {
    childId: UUID;
    appleMusicArtistId: string;
    name: string;
    catalogMetadata?: {
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
      editorialNotes?: {
        tagline?: string;
        short?: string;
        standard?: string;
        name?: string;
      };
      appleMusicUrl?: string;
      genreNames: string[];
    };
  }

  export type Output = SuccessOutput;
}
