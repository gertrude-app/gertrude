/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL fragment: SingleAppScopeFields
// ====================================================

export interface SingleAppScopeFields_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface SingleAppScopeFields_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type SingleAppScopeFields =
  | SingleAppScopeFields_IdentifiedAppData
  | SingleAppScopeFields_BundleIdData;
