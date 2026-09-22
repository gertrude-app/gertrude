import type {
  UnlockDomainGroup,
  UnlockRequestRow,
  UnlockReviewEntry,
} from '#/lib/unlockRequests';
import { keychains } from './fixtures';
import { buildUnlockReview } from '#/lib/unlockRequests';

export const waitForRender = (): Promise<void> =>
  new Promise((resolve) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
  );

export const unlockReviewDraft = (
  requests: UnlockRequestRow[],
  customize: (group: UnlockDomainGroup) => UnlockDomainGroup = (group) => group,
): UnlockReviewEntry[] =>
  buildUnlockReview(requests, keychains[0]?.id).map((entry) =>
    entry.kind === `web`
      ? { ...entry, group: customize(entry.group) }
      : { ...entry, groups: entry.groups.map(customize) },
  );
