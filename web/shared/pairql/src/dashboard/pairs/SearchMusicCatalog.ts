// auto-generated, do not edit
export namespace SearchMusicCatalog {
  export interface Input {
    query: string;
    limit?: number;
  }

  export interface Output {
    items: Array<{
      kind: 'album' | 'artist';
      album?: {
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
        releaseDate?: string;
        appleMusicUrl?: string;
      };
      artist?: {
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
      };
    }>;
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
      releaseDate?: string;
      appleMusicUrl?: string;
    }>;
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
    }>;
  }
}
