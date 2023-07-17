import type { UserActivitySummaries } from './pairql';

export type DateRangeInput = UserActivitySummaries.Input['dateRanges'][number];

export type ReleaseChannel = 'stable' | 'beta' | 'canary';
