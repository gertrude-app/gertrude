import type {
  CombinedUsersActivityFeed,
  UserActivityFeed,
  UserActivityItem,
} from '@dash/types';
import type { ActivityFeedItem } from '@dash/components';

export function outputItemToActivityFeedItem(item: UserActivityItem): ActivityFeedItem {
  if (item.case === `keystrokeLine`) {
    return {
      type: `KeystrokeLine` as const,
      date: item.createdAt,
      ...item,
    };
  } else {
    return {
      type: `Screenshot` as const,
      date: item.createdAt,
      ...item,
    };
  }
}

export function itemFromRootId(
  rootId: UUID,
  queryData?: CombinedUsersActivityFeed.Output,
): UserActivityItem | null {
  if (!queryData) return null;
  for (const childChunk of queryData) {
    for (const item of childChunk.items) {
      if (item.ids.includes(rootId)) {
        return item;
      }
    }
  }
  return null;
}

export function prepareCombinedUsersActivityDelete(
  itemRootIds: UUID[],
  queryData: CombinedUsersActivityFeed.Output,
): [
  input: { keystrokeLineIds: UUID[]; screenshotIds: UUID[] },
  optimisticUpdate: CombinedUsersActivityFeed.Output,
] {
  const chunked = queryData.map((userChunk) =>
    prepareUserActivityDelete(itemRootIds, userChunk),
  );
  return [
    chunked
      .map(([input]) => input)
      .reduce(
        (acc, input) => ({
          keystrokeLineIds: [...acc.keystrokeLineIds, ...input.keystrokeLineIds],
          screenshotIds: [...acc.screenshotIds, ...input.screenshotIds],
        }),
        { keystrokeLineIds: [], screenshotIds: [] },
      ),
    chunked.map(([, optimisticUpdate]) => optimisticUpdate),
  ];
}

export function prepareUserActivityDelete(
  itemRootIds: UUID[],
  queryData: UserActivityFeed.Output,
  flagged: UUID[] = [],
): [
  input: { keystrokeLineIds: UUID[]; screenshotIds: UUID[] },
  optimisticUpdate: UserActivityFeed.Output,
] {
  let keystrokeLineIds: UUID[] = [];
  const screenshotIds: UUID[] = [];
  // impure filter function, but prevents iterating twice
  const remaining = queryData.items.filter((item) => {
    if (itemRootIds.includes(item.id) && !flagged.includes(item.id)) {
      if (item.case === `keystrokeLine`) {
        keystrokeLineIds = [...keystrokeLineIds, ...item.ids];
      } else {
        screenshotIds.push(item.id);
      }
      return false;
    }
    return true;
  });
  return [
    { keystrokeLineIds, screenshotIds },
    {
      userName: queryData.userName,
      items: remaining,
      showSuspensionActivity: queryData.showSuspensionActivity,
      numDeleted: queryData.numDeleted + queryData.items.length - remaining.length,
    },
  ];
}
