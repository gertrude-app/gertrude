/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: GetIdentifiedApps
// ====================================================

export interface GetIdentifiedApps_apps_bundleIds {
  __typename: 'BundleId';
  id: string;
  bundleId: string;
}

export interface GetIdentifiedApps_apps_category {
  __typename: 'AppCategory';
  id: string;
  name: string;
  slug: string;
}

export interface GetIdentifiedApps_apps {
  __typename: 'IdentifiedApp';
  id: string;
  name: string;
  slug: string;
  selectable: boolean;
  bundleIds: GetIdentifiedApps_apps_bundleIds[];
  category: GetIdentifiedApps_apps_category | null;
}

export interface GetIdentifiedApps {
  apps: GetIdentifiedApps_apps[];
}
