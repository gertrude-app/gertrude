import type { ActivityItem } from '#/lib/mock';

export type ActivityChunk =
  | {
      type: `normal`;
      items: ActivityItem[];
    }
  | {
      type: `duringSuspension`;
      items: ActivityItem[];
    };

export type ActivityReviewStats = {
  totalCount: number;
  deletedCount: number;
  flaggedCount: number;
  reviewedCount: number;
  reviewedPercent: number;
};

export function activityDayPath(date: Date): string {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, `0`);
  const day = `${date.getDate()}`.padStart(2, `0`);
  return `${year}-${month}-${day}`;
}

export function dateFromDayParam(day: string): Date {
  const [year, month, date] = day.split(`-`).map(Number);
  return new Date(year, month - 1, date);
}

export function allActivityDayHref(date: Date): string {
  return `/activity/day/${activityDayPath(date)}`;
}

export function personActivityHref(personId: string): string {
  return `/activity/person/${personId}`;
}

export function personActivityDayHref(personId: string, date: Date): string {
  return `/activity/person/${personId}/day/${activityDayPath(date)}`;
}

export function getActivityReviewStats(
  activities: readonly ActivityItem[],
): ActivityReviewStats {
  const totalCount = activities.length;
  const deletedCount = activities.filter((activity) => activity.deleted).length;
  const flaggedCount = activities.filter((activity) => activity.flagged).length;
  const reviewedCount = deletedCount + flaggedCount;

  return {
    totalCount,
    deletedCount,
    flaggedCount,
    reviewedCount,
    reviewedPercent: totalCount === 0 ? 0 : (reviewedCount / totalCount) * 100,
  };
}

export function chunkActivityBySuspension(
  items: readonly ActivityItem[],
): ActivityChunk[] {
  return items.reduce<ActivityChunk[]>((chunks, item) => {
    const chunkType = item.duringSuspension ? `duringSuspension` : `normal`;
    const lastChunk = chunks.at(-1);

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
