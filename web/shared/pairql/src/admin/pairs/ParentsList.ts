// auto-generated, do not edit
export namespace ParentsList {
  export interface Input {
    page: number;
    pageSize?: number;
  }

  export interface Output {
    parents: Array<{
      id: UUID;
      email: string;
      createdAt: ISODateString;
      planCase: string;
      subscriptionStatus: string;
      numChildren: number;
      macDeviceCount: number;
      iosDeviceCount: number;
      macAppStatus: string;
    }>;
    totalCount: number;
    page: number;
    totalPages: number;
  }
}
