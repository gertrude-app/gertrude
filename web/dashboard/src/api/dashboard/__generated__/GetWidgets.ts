/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: GetWidgets
// ====================================================

export interface GetWidgets_widgets_users {
  __typename: 'DashboardWidgetUser';
  id: string;
  isOnline: boolean;
  name: string;
}

export interface GetWidgets_widgets_userActivity {
  __typename: 'DashboardWidgetUserActivitySummary';
  id: string;
  userName: string;
  numUnreviewed: number;
}

export interface GetWidgets_widgets_unlockRequests {
  __typename: 'DashboardWidgetUnlockRequest';
  id: string;
  target: string;
  comment: string | null;
  createdAt: string;
  userName: string;
}

export interface GetWidgets_widgets_userScreenshots {
  __typename: 'DashboardWidgetRecentScreenshot';
  id: string;
  url: string;
  userName: string;
  createdAt: string;
}

export interface GetWidgets_widgets {
  __typename: 'DashboardWidgetData';
  users: GetWidgets_widgets_users[];
  userActivity: GetWidgets_widgets_userActivity[];
  unlockRequests: GetWidgets_widgets_unlockRequests[];
  userScreenshots: GetWidgets_widgets_userScreenshots[];
}

export interface GetWidgets {
  widgets: GetWidgets_widgets;
}
