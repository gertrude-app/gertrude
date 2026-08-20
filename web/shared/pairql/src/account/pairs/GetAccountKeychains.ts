// auto-generated, do not edit
export namespace GetAccountKeychains {
  export type Input = void;

  export interface Output {
    keychains: Array<{
      id: UUID;
      name: string;
      description?: string;
      isPublic: boolean;
      numKeys: number;
      assignedPersonIds: UUID[];
    }>;
    people: Array<{
      id: UUID;
      name: string;
    }>;
  }
}
