// auto-generated, do not edit
export namespace GetApprovedMusicAlbums {
  export type Input = UUID;

  export interface Output {
    albums: Array<{
      id: string;
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
      createdAt?: ISODateString;
    }>;
  }
}
