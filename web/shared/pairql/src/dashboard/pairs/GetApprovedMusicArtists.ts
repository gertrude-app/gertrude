// auto-generated, do not edit
export namespace GetApprovedMusicArtists {
  export type Input = UUID;

  export interface Output {
    artists: Array<{
      id: string;
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
      createdAt?: ISODateString;
    }>;
  }
}
