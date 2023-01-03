// auto-generated, do not edit

export namespace GetSelectableKeychains {
  export type Input = void;

  export interface Keychain {
    id: UUID;
    name: string;
    isPublic: boolean;
    authorId: UUID;
    description?: string;
    numKeys: number;
  }

  export interface Output {
    own: Array<Keychain>;
    public: Array<Keychain>;
  }
}
