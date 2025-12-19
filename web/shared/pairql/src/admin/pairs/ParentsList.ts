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
      subscriptionStatus: string;
      numChildren: number;
      numKeychains: number;
      numNotifications: number;
      status: string;
    }>;
    totalCount: number;
    page: number;
    totalPages: number;
  }
}
