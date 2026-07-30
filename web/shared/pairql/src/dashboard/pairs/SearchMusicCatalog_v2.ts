// auto-generated, do not edit
export namespace SearchMusicCatalog_v2 {
  export interface Input {
    childId: UUID;
    query: string;
    limit?: number;
  }

  export interface Output {
    revision: number;
    items: Array<{
      kind: 'track' | 'album' | 'artist';
      track?: {
        id: string;
        title: string;
        artistName: string;
        preferredAlbumId: string;
        albumTitle: string;
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
        durationInMillis?: number;
        discNumber?: number;
        trackNumber?: number;
        contentRating?: 'clean' | 'explicit';
        appleMusicUrl?: string;
        status: {
          kind: 'available' | 'selected' | 'allowedWithAlbum' | 'allowedWithArtist';
          managementAlbumId?: string;
          governingArtistId?: string;
          governingArtistName?: string;
        };
      };
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
        releaseType?: string;
        appleMusicUrl?: string;
        status: {
          kind: 'available' | 'selectedTracks' | 'wholeAlbum' | 'allowedWithArtist';
          selectedTrackCount: number;
          governingArtistId?: string;
          governingArtistName?: string;
        };
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
        status: 'available' | 'allowed';
      };
    }>;
  }
}
