// auto-generated, do not edit
export namespace GetApprovedMusicAlbums {
  export type Input = UUID;

  export interface Output {
    albums: Array<{
      id: string;
      title: string;
      artistName: string;
      artworkUrl?: string;
      trackCount?: number;
      showsArtwork: boolean;
      createdAt?: ISODateString;
    }>;
  }
}
