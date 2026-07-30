// auto-generated, do not edit
export namespace ApproveMusicArtist_v2 {
  export interface Input {
    childId: UUID;
    appleMusicArtistId: string;
    confirmationToken?: string;
  }

  export interface Output {
    status: 'updated' | 'confirmationRequired';
    curation: {
      revision: number;
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
        catalogTrackCount: number;
        selectedTrackCount: number;
        releaseDate?: string;
        releaseType?: string;
        appleMusicUrl?: string;
        scope: 'selectedTracks' | 'wholeAlbum';
        showsArtwork: boolean;
        createdAt: ISODateString;
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
        createdAt: ISODateString;
      }>;
    };
    confirmation?: {
      revision: number;
      token: string;
      albumCount: number;
      trackCount: number;
    };
  }
}
