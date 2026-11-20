// auto-generated, do not edit
export namespace GetSuspensionRequestStatus {
  export interface Input {
    id: UUID;
  }

  export interface Output {
    status: 'pending' | 'accepted' | 'rejected' | 'expired';
    personName: string;
    durationInSeconds: number;
  }
}
