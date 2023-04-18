// auto-generated, do not edit

export namespace GetUsersActivityOverviews {
  export type Input = Array<{
    start: string;
    end: string;
  }>;

  export type Output = Array<{
    userId: UUID;
    userName: string;
    days: Array<{
      date: ISODateString;
      numApproved: number;
      totalItems: number;
    }>;
  }>;
}
