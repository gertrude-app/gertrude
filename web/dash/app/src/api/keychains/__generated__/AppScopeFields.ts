/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL fragment: AppScopeFields
// ====================================================

export interface AppScopeFields_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface AppScopeFields_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface AppScopeFields_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface AppScopeFields_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type AppScopeFields_SingleData_single =
  | AppScopeFields_SingleData_single_IdentifiedAppData
  | AppScopeFields_SingleData_single_BundleIdData;

export interface AppScopeFields_SingleData {
  __typename: 'SingleData';
  type: string;
  single: AppScopeFields_SingleData_single;
}

export type AppScopeFields =
  | AppScopeFields_WebBrowsersData
  | AppScopeFields_UnrestrictedData
  | AppScopeFields_SingleData;
