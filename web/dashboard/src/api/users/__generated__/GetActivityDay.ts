/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: GetActivityDay
// ====================================================

export interface GetActivityDay_items_CoalescedKeystrokeLine {
  __typename: 'CoalescedKeystrokeLine';
  id: string;
  ids: string[];
  appName: string;
  line: string;
  createdAt: string;
}

export interface GetActivityDay_items_Screenshot {
  __typename: 'Screenshot';
  id: string;
  ids: string[];
  url: string;
  width: number;
  height: number;
  createdAt: string;
}

export type GetActivityDay_items =
  | GetActivityDay_items_CoalescedKeystrokeLine
  | GetActivityDay_items_Screenshot;

export interface GetActivityDay {
  items: GetActivityDay_items[];
}

export interface GetActivityDayVariables {
  userId: UUID;
  before: string;
  after: string;
}
