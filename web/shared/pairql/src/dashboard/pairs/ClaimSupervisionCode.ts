// auto-generated, do not edit
export namespace ClaimSupervisionCode {
  export interface Input {
    code: number;
    child:
      | {
          case: `newChild`;
          name: string;
        }
      | {
          case: `existingChild`;
          id: UUID;
        };
  }

  export interface Output {
    childName: string;
    modelName: string;
    iosVersion: string;
    code: number;
  }
}
