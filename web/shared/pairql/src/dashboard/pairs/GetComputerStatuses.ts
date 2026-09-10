// auto-generated, do not edit
import type { ChildComputerStatus } from '../shared';

export namespace GetComputerStatuses {
  export type Input = void;

  export type Output = Array<{
    computerUserId: UUID;
    computerId: UUID;
    childId: UUID;
    status: ChildComputerStatus;
    apiReachable: boolean;
    effectiveFilterStatus?: ChildComputerStatus;
    snapshotReceivedAt?: ISODateString;
    snapshotFreshness: 'fresh' | 'stale' | 'unsupported' | 'missing';
  }>;
}
