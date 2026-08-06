// auto-generated, do not edit
export namespace GetMusicAlbumCuration {
  export interface Input {
    childId: UUID;
    appleMusicAlbumId: string;
  }

  export interface Output {
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
  }
}
