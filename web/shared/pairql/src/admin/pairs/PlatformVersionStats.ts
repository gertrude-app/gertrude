// auto-generated, do not edit
export namespace PlatformVersionStats {
  export type Input = void;

  export interface Output {
    activeDays: number;
    macos: {
      total: number;
      versions: Array<{
        version: string;
        count: number;
      }>;
    };
    ios: {
      total: number;
      versions: Array<{
        version: string;
        count: number;
      }>;
    };
  }
}
