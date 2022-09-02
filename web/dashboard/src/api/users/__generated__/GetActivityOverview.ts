/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { DateRangeInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL query operation: GetActivityOverview
// ====================================================

export interface GetActivityOverview_user {
  __typename: 'User';
  name: string;
}

export interface GetActivityOverview_counts_dateRange {
  __typename: 'DateRange';
  start: string;
}

export interface GetActivityOverview_counts {
  __typename: 'MonitoringRangeCounts';
  dateRange: GetActivityOverview_counts_dateRange;
  numCompleted: number;
  numItems: number;
}

export interface GetActivityOverview {
  user: GetActivityOverview_user;
  counts: GetActivityOverview_counts[];
}

export interface GetActivityOverviewVariables {
  userId: UUID;
  ranges: DateRangeInput[];
}
