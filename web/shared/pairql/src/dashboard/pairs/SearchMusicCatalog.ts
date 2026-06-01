// auto-generated, do not edit
export namespace SearchMusicCatalog {
  export interface Input {
    query: string;
    limit?: number;
  }

  export interface Output {
    albums: Array<{
      id: string;
      title: string;
      artistName: string;
      artworkUrl?: string;
      trackCount?: number;
      releaseDate?: string;
      appleMusicUrl?: string;
    }>;
  }
}
