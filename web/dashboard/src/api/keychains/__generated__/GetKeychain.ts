/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: GetKeychain
// ====================================================

export interface GetKeychain_keychain_keyRecords_key_data_DomainData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_DomainData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_DomainData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_DomainData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type GetKeychain_keychain_keyRecords_key_data_DomainData_scope_SingleData_single =
  | GetKeychain_keychain_keyRecords_key_data_DomainData_scope_SingleData_single_IdentifiedAppData
  | GetKeychain_keychain_keyRecords_key_data_DomainData_scope_SingleData_single_BundleIdData;

export interface GetKeychain_keychain_keyRecords_key_data_DomainData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: GetKeychain_keychain_keyRecords_key_data_DomainData_scope_SingleData_single;
}

export type GetKeychain_keychain_keyRecords_key_data_DomainData_scope =
  | GetKeychain_keychain_keyRecords_key_data_DomainData_scope_WebBrowsersData
  | GetKeychain_keychain_keyRecords_key_data_DomainData_scope_UnrestrictedData
  | GetKeychain_keychain_keyRecords_key_data_DomainData_scope_SingleData;

export interface GetKeychain_keychain_keyRecords_key_data_DomainData {
  __typename: 'DomainData';
  domain: string;
  type: string;
  scope: GetKeychain_keychain_keyRecords_key_data_DomainData_scope;
}

export interface GetKeychain_keychain_keyRecords_key_data_SkeletonData_scope_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_SkeletonData_scope_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type GetKeychain_keychain_keyRecords_key_data_SkeletonData_scope =
  | GetKeychain_keychain_keyRecords_key_data_SkeletonData_scope_IdentifiedAppData
  | GetKeychain_keychain_keyRecords_key_data_SkeletonData_scope_BundleIdData;

export interface GetKeychain_keychain_keyRecords_key_data_SkeletonData {
  __typename: 'SkeletonData';
  type: string;
  scope: GetKeychain_keychain_keyRecords_key_data_SkeletonData_scope;
}

export interface GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_SingleData_single =

    | GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_SingleData_single_IdentifiedAppData
    | GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_SingleData_single_BundleIdData;

export interface GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_SingleData_single;
}

export type GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope =
  | GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_WebBrowsersData
  | GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_UnrestrictedData
  | GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope_SingleData;

export interface GetKeychain_keychain_keyRecords_key_data_DomainRegexData {
  __typename: 'DomainRegexData';
  type: string;
  pattern: string;
  scope: GetKeychain_keychain_keyRecords_key_data_DomainRegexData_scope;
}

export interface GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_SingleData_single =

    | GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_IdentifiedAppData
    | GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_BundleIdData;

export interface GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_SingleData_single;
}

export type GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope =
  | GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_WebBrowsersData
  | GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_UnrestrictedData
  | GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope_SingleData;

export interface GetKeychain_keychain_keyRecords_key_data_AnySubdomainData {
  __typename: 'AnySubdomainData';
  type: string;
  domain: string;
  scope: GetKeychain_keychain_keyRecords_key_data_AnySubdomainData_scope;
}

export interface GetKeychain_keychain_keyRecords_key_data_PathData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_PathData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_PathData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_PathData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type GetKeychain_keychain_keyRecords_key_data_PathData_scope_SingleData_single =
  | GetKeychain_keychain_keyRecords_key_data_PathData_scope_SingleData_single_IdentifiedAppData
  | GetKeychain_keychain_keyRecords_key_data_PathData_scope_SingleData_single_BundleIdData;

export interface GetKeychain_keychain_keyRecords_key_data_PathData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: GetKeychain_keychain_keyRecords_key_data_PathData_scope_SingleData_single;
}

export type GetKeychain_keychain_keyRecords_key_data_PathData_scope =
  | GetKeychain_keychain_keyRecords_key_data_PathData_scope_WebBrowsersData
  | GetKeychain_keychain_keyRecords_key_data_PathData_scope_UnrestrictedData
  | GetKeychain_keychain_keyRecords_key_data_PathData_scope_SingleData;

export interface GetKeychain_keychain_keyRecords_key_data_PathData {
  __typename: 'PathData';
  type: string;
  path: string;
  scope: GetKeychain_keychain_keyRecords_key_data_PathData_scope;
}

export interface GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_SingleData_single =

    | GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_SingleData_single_IdentifiedAppData
    | GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_SingleData_single_BundleIdData;

export interface GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_SingleData_single;
}

export type GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope =
  | GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_WebBrowsersData
  | GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_UnrestrictedData
  | GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope_SingleData;

export interface GetKeychain_keychain_keyRecords_key_data_IpAddressData {
  __typename: 'IpAddressData';
  type: string;
  ipAddress: string;
  scope: GetKeychain_keychain_keyRecords_key_data_IpAddressData_scope;
}

export type GetKeychain_keychain_keyRecords_key_data =
  | GetKeychain_keychain_keyRecords_key_data_DomainData
  | GetKeychain_keychain_keyRecords_key_data_SkeletonData
  | GetKeychain_keychain_keyRecords_key_data_DomainRegexData
  | GetKeychain_keychain_keyRecords_key_data_AnySubdomainData
  | GetKeychain_keychain_keyRecords_key_data_PathData
  | GetKeychain_keychain_keyRecords_key_data_IpAddressData;

export interface GetKeychain_keychain_keyRecords_key {
  __typename: 'Key';
  jsonString: string | null;
  data: GetKeychain_keychain_keyRecords_key_data;
}

export interface GetKeychain_keychain_keyRecords {
  __typename: 'KeyRecord';
  id: string;
  comment: string | null;
  expiration: string | null;
  key: GetKeychain_keychain_keyRecords_key;
}

export interface GetKeychain_keychain {
  __typename: 'Keychain';
  id: string;
  name: string;
  description: string | null;
  isPublic: boolean;
  authorId: string;
  keyRecords: GetKeychain_keychain_keyRecords[];
}

export interface GetKeychain {
  keychain: GetKeychain_keychain;
}

export interface GetKeychainVariables {
  id: UUID;
}
