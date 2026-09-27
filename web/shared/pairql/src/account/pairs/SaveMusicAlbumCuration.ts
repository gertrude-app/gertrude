// auto-generated, do not edit
export namespace SaveMusicAlbumCuration {
  export interface Input {
    childId: UUID;
    appleMusicAlbumId: string;
    expectedRevision: number;
    selectedTrackIds: string[];
  }

  export interface Output {
    status: 'updated' | 'conflict' | 'coveredByArtist';
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
    album: {
      revision: number;
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
      releaseDate?: string;
      releaseType?: string;
      appleMusicUrl?: string;
      scope: 'none' | 'selectedTracks' | 'wholeAlbum' | 'artist';
      selectedTrackCount: number;
      catalogTrackCount: number;
      canEdit: boolean;
      governingArtistId?: string;
      governingArtistName?: string;
      tracks: Array<{
        id: string;
        title: string;
        artistName: string;
        artworkUrl?: string;
        durationInMillis?: number;
        discNumber?: number;
        trackNumber?: number;
        contentRating?: 'clean' | 'explicit';
        appleMusicUrl?: string;
        isSelected: boolean;
      }>;
    };
  }
}
