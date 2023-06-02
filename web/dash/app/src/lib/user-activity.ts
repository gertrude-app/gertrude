import type { CombinedUsersActivityFeed, UserActivityFeed } from '@dash/types';
import type { ActivityFeedItem } from '@dash/components';

export function outputItemToActivityFeedItem(
  item: UserActivityFeed.Item,
): ActivityFeedItem {
  if (item.type === `CoalescedKeystrokeLine`) {
    return {
      type: `KeystrokeLine` as const,
      date: item.value.createdAt,
      ...item.value,
    };
  } else {
    return {
      type: `Screenshot` as const,
      date: item.value.createdAt,
      ...item.value,
    };
  }
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
): [
  input: { keystrokeLineIds: UUID[]; screenshotIds: UUID[] },
  optimisticUpdate: UserActivityFeed.Output,
] {
  let keystrokeLineIds: UUID[] = [];
  const screenshotIds: UUID[] = [];
  // impure filter function, but prevents iterating twice
  const remaining = queryData.items.filter((item) => {
    if (itemRootIds.includes(item.value.id)) {
      if (item.type === `CoalescedKeystrokeLine`) {
        keystrokeLineIds = [...keystrokeLineIds, ...item.value.ids];
      } else {
        screenshotIds.push(item.value.id);
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
      numDeleted: queryData.numDeleted + queryData.items.length - remaining.length,
    },
  ];
}
