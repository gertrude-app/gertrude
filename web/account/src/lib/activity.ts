import type { GetDayActivity, GetPersonDayActivity } from '@shared/pairql/src/account';

type ActivityWireItem = GetPersonDayActivity.Output[`items`][number];

type DayCounts = {
  date: string;
  numTotal: number;
  numDeleted: number;
  numFlagged: number;
};

export type ActivityReviewStats = {
  totalCount: number;
  deletedCount: number;
  flaggedCount: number;
  reviewedCount: number;
  reviewedPercent: number;
};

export type DaySummary = {
  date: Date;
  stats: ActivityReviewStats;
};

export function toDaySummaries(days: readonly DayCounts[]): DaySummary[] {
  return days.map((day) => {
    const reviewedCount = day.numDeleted + day.numFlagged;
    return {
      date: new Date(day.date),
      stats: {
        totalCount: day.numTotal,
        deletedCount: day.numDeleted,
        flaggedCount: day.numFlagged,
        reviewedCount,
        reviewedPercent: day.numTotal === 0 ? 0 : (reviewedCount / day.numTotal) * 100,
      },
    };
  });
}

export type ActivityItem = {
  id: string;
  personId: string;
  personName: string;
  duringSuspension: boolean;
  date: Date;
  flagged: boolean;
  deleted: boolean;
} & (
  | { type: `screenshot`; url: string; width: number; height: number }
  | { type: `keylog`; text: string; applicationName: string }
);

export type ActivityChunk =
  | { type: `normal`; items: ActivityItem[] }
  | { type: `duringSuspension`; items: ActivityItem[] };

export function toActivityItems(
  output: GetPersonDayActivity.Output,
  personId: string,
): ActivityItem[] {
  return output.items.map((item) => toActivityItem(item, personId, output.personName));
}

function toActivityItem(
  item: ActivityWireItem,
  personId: string,
  personName: string,
): ActivityItem {
  const base = {
    id: item.id,
    personId,
    personName,
    duringSuspension: item.duringSuspension,
    date: new Date(item.date),
    flagged: item.flagged,
    deleted: false,
  };
  if (item.case === `screenshot`) {
    return {
      ...base,
      type: `screenshot`,
      url: item.url,
      width: item.width,
      height: item.height,
    };
  }
  return { ...base, type: `keylog`, text: item.text, applicationName: item.appName };
}

export function toCombinedActivityItems(output: GetDayActivity.Output): ActivityItem[] {
  return output.people.flatMap((person) =>
    person.items.map((item) => toActivityItem(item, person.personId, person.personName)),
  );
}

export function prepareToggleFlag(
  rootId: string,
  output: GetPersonDayActivity.Output,
): [ids: string[], next: GetPersonDayActivity.Output] {
  const ids = output.items.find((item) => item.id === rootId)?.ids ?? [rootId];
  const next: GetPersonDayActivity.Output = {
    ...output,
    items: output.items.map((item) =>
      item.id === rootId ? { ...item, flagged: !item.flagged } : item,
    ),
  };
  return [ids, next];
}

export function prepareDelete(
  rootIds: string[],
  output: GetPersonDayActivity.Output,
): [
  input: { keystrokeLineIds: string[]; screenshotIds: string[] },
  next: GetPersonDayActivity.Output,
] {
  const keystrokeLineIds: string[] = [];
  const screenshotIds: string[] = [];
  // flagged items are delete-protected on the server, so skip them here too
  const remaining = output.items.filter((item) => {
    if (rootIds.includes(item.id) && !item.flagged) {
      if (item.case === `keylog`) {
        keystrokeLineIds.push(...item.ids);
      } else {
        screenshotIds.push(...item.ids);
      }
      return false;
    }
    return true;
  });
  return [
    { keystrokeLineIds, screenshotIds },
    { ...output, items: remaining },
  ];
}

export function prepareToggleFlagCombined(
  rootId: string,
  output: GetDayActivity.Output,
): [ids: string[], next: GetDayActivity.Output] {
  let ids: string[] = [rootId];
  const people = output.people.map((person) => ({
    ...person,
    items: person.items.map((item) => {
      if (item.id !== rootId) return item;
      ids = item.ids;
      return { ...item, flagged: !item.flagged };
    }),
  }));
  return [ids, { people }];
}

export function prepareDeleteCombined(
  rootIds: string[],
  output: GetDayActivity.Output,
): [
  input: { keystrokeLineIds: string[]; screenshotIds: string[] },
  next: GetDayActivity.Output,
] {
  const keystrokeLineIds: string[] = [];
  const screenshotIds: string[] = [];
  const people = output.people.map((person) => ({
    ...person,
    items: person.items.filter((item) => {
      if (rootIds.includes(item.id) && !item.flagged) {
        if (item.case === `keylog`) {
          keystrokeLineIds.push(...item.ids);
        } else {
          screenshotIds.push(...item.ids);
        }
        return false;
      }
      return true;
    }),
  }));
  return [{ keystrokeLineIds, screenshotIds }, { people }];
}

export function dateFromDayParam(day: string): Date {
  const [year = Number.NaN, month = Number.NaN, date = Number.NaN] = day
    .split(`-`)
    .map(Number);
  return new Date(year, month - 1, date);
}

export function dayRange(day: string): { start: string; end: string } {
  const start = dateFromDayParam(day);
  const end = new Date(start);
  end.setDate(end.getDate() + 1);
  return { start: start.toISOString(), end: end.toISOString() };
}

export function chunkActivityBySuspension(
  items: readonly ActivityItem[],
): ActivityChunk[] {
  return items.reduce<ActivityChunk[]>((chunks, item, index) => {
    const lastChunk = chunks.at(-1);
    const duringSuspension =
      item.duringSuspension ||
      (lastChunk?.type === `duringSuspension` &&
        shouldMergeKeystrokeIntoSuspension(items, index));
    const chunkType = duringSuspension ? `duringSuspension` : `normal`;

    if (lastChunk && lastChunk.type === chunkType) {
      lastChunk.items.push(item);
    } else if (chunkType === `duringSuspension`) {
      chunks.push({ type: `duringSuspension`, items: [item] });
    } else {
      chunks.push({ type: `normal`, items: [item] });
    }

    return chunks;
  }, []);
}

function shouldMergeKeystrokeIntoSuspension(
  items: readonly ActivityItem[],
  index: number,
): boolean {
  const item = items[index];
  const previous = items[index - 1];
  if (item?.type !== `keylog` || !previous) return false;

  for (const next of items.slice(index + 1, index + 5)) {
    if (next.type === `screenshot`) {
      return (
        next.duringSuspension &&
        Math.abs(previous.date.getTime() - next.date.getTime()) < 4 * 60 * 1000
      );
    }
    if (next.duringSuspension) return false;
  }
  return false;
}

export function chunkActivityForDeletion(
  items: readonly ActivityItem[],
  chunkSize = 100,
): Array<{ chunks: ActivityChunk[]; previousItems: ActivityItem[] }> {
  if (!Number.isInteger(chunkSize) || chunkSize < 1) {
    throw new Error(`Activity chunk size must be a positive integer`);
  }
  const batches = [];
  for (let offset = 0; offset < items.length; offset += chunkSize) {
    const end = offset + chunkSize;
    batches.push({
      chunks: chunkActivityBySuspension(items.slice(offset, end)),
      previousItems: end < items.length ? items.slice(0, end) : [],
    });
  }
  return batches;
}
