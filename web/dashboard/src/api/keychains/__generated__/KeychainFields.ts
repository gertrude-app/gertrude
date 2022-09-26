/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL fragment: KeychainFields
// ====================================================

export interface KeychainFields_keyRecords_key_data_DomainData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_DomainData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_DomainData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface KeychainFields_keyRecords_key_data_DomainData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type KeychainFields_keyRecords_key_data_DomainData_scope_SingleData_single =
  | KeychainFields_keyRecords_key_data_DomainData_scope_SingleData_single_IdentifiedAppData
  | KeychainFields_keyRecords_key_data_DomainData_scope_SingleData_single_BundleIdData;

export interface KeychainFields_keyRecords_key_data_DomainData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: KeychainFields_keyRecords_key_data_DomainData_scope_SingleData_single;
}

export type KeychainFields_keyRecords_key_data_DomainData_scope =
  | KeychainFields_keyRecords_key_data_DomainData_scope_WebBrowsersData
  | KeychainFields_keyRecords_key_data_DomainData_scope_UnrestrictedData
  | KeychainFields_keyRecords_key_data_DomainData_scope_SingleData;

export interface KeychainFields_keyRecords_key_data_DomainData {
  __typename: 'DomainData';
  domain: string;
  type: string;
  scope: KeychainFields_keyRecords_key_data_DomainData_scope;
}

export interface KeychainFields_keyRecords_key_data_SkeletonData_scope_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface KeychainFields_keyRecords_key_data_SkeletonData_scope_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type KeychainFields_keyRecords_key_data_SkeletonData_scope =
  | KeychainFields_keyRecords_key_data_SkeletonData_scope_IdentifiedAppData
  | KeychainFields_keyRecords_key_data_SkeletonData_scope_BundleIdData;

export interface KeychainFields_keyRecords_key_data_SkeletonData {
  __typename: 'SkeletonData';
  type: string;
  scope: KeychainFields_keyRecords_key_data_SkeletonData_scope;
}

export interface KeychainFields_keyRecords_key_data_DomainRegexData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_DomainRegexData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_DomainRegexData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface KeychainFields_keyRecords_key_data_DomainRegexData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type KeychainFields_keyRecords_key_data_DomainRegexData_scope_SingleData_single =
  | KeychainFields_keyRecords_key_data_DomainRegexData_scope_SingleData_single_IdentifiedAppData
  | KeychainFields_keyRecords_key_data_DomainRegexData_scope_SingleData_single_BundleIdData;

export interface KeychainFields_keyRecords_key_data_DomainRegexData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: KeychainFields_keyRecords_key_data_DomainRegexData_scope_SingleData_single;
}

export type KeychainFields_keyRecords_key_data_DomainRegexData_scope =
  | KeychainFields_keyRecords_key_data_DomainRegexData_scope_WebBrowsersData
  | KeychainFields_keyRecords_key_data_DomainRegexData_scope_UnrestrictedData
  | KeychainFields_keyRecords_key_data_DomainRegexData_scope_SingleData;

export interface KeychainFields_keyRecords_key_data_DomainRegexData {
  __typename: 'DomainRegexData';
  type: string;
  pattern: string;
  scope: KeychainFields_keyRecords_key_data_DomainRegexData_scope;
}

export interface KeychainFields_keyRecords_key_data_AnySubdomainData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_AnySubdomainData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface KeychainFields_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type KeychainFields_keyRecords_key_data_AnySubdomainData_scope_SingleData_single =
  | KeychainFields_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_IdentifiedAppData
  | KeychainFields_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_BundleIdData;

export interface KeychainFields_keyRecords_key_data_AnySubdomainData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: KeychainFields_keyRecords_key_data_AnySubdomainData_scope_SingleData_single;
}

export type KeychainFields_keyRecords_key_data_AnySubdomainData_scope =
  | KeychainFields_keyRecords_key_data_AnySubdomainData_scope_WebBrowsersData
  | KeychainFields_keyRecords_key_data_AnySubdomainData_scope_UnrestrictedData
  | KeychainFields_keyRecords_key_data_AnySubdomainData_scope_SingleData;

export interface KeychainFields_keyRecords_key_data_AnySubdomainData {
  __typename: 'AnySubdomainData';
  type: string;
  domain: string;
  scope: KeychainFields_keyRecords_key_data_AnySubdomainData_scope;
}

export interface KeychainFields_keyRecords_key_data_PathData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_PathData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_PathData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface KeychainFields_keyRecords_key_data_PathData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type KeychainFields_keyRecords_key_data_PathData_scope_SingleData_single =
  | KeychainFields_keyRecords_key_data_PathData_scope_SingleData_single_IdentifiedAppData
  | KeychainFields_keyRecords_key_data_PathData_scope_SingleData_single_BundleIdData;

export interface KeychainFields_keyRecords_key_data_PathData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: KeychainFields_keyRecords_key_data_PathData_scope_SingleData_single;
}

export type KeychainFields_keyRecords_key_data_PathData_scope =
  | KeychainFields_keyRecords_key_data_PathData_scope_WebBrowsersData
  | KeychainFields_keyRecords_key_data_PathData_scope_UnrestrictedData
  | KeychainFields_keyRecords_key_data_PathData_scope_SingleData;

export interface KeychainFields_keyRecords_key_data_PathData {
  __typename: 'PathData';
  type: string;
  path: string;
  scope: KeychainFields_keyRecords_key_data_PathData_scope;
}

export interface KeychainFields_keyRecords_key_data_IpAddressData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_IpAddressData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface KeychainFields_keyRecords_key_data_IpAddressData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface KeychainFields_keyRecords_key_data_IpAddressData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type KeychainFields_keyRecords_key_data_IpAddressData_scope_SingleData_single =
  | KeychainFields_keyRecords_key_data_IpAddressData_scope_SingleData_single_IdentifiedAppData
  | KeychainFields_keyRecords_key_data_IpAddressData_scope_SingleData_single_BundleIdData;

export interface KeychainFields_keyRecords_key_data_IpAddressData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: KeychainFields_keyRecords_key_data_IpAddressData_scope_SingleData_single;
}

export type KeychainFields_keyRecords_key_data_IpAddressData_scope =
  | KeychainFields_keyRecords_key_data_IpAddressData_scope_WebBrowsersData
  | KeychainFields_keyRecords_key_data_IpAddressData_scope_UnrestrictedData
  | KeychainFields_keyRecords_key_data_IpAddressData_scope_SingleData;

export interface KeychainFields_keyRecords_key_data_IpAddressData {
  __typename: 'IpAddressData';
  type: string;
  ipAddress: string;
  scope: KeychainFields_keyRecords_key_data_IpAddressData_scope;
}

export type KeychainFields_keyRecords_key_data =
  | KeychainFields_keyRecords_key_data_DomainData
  | KeychainFields_keyRecords_key_data_SkeletonData
  | KeychainFields_keyRecords_key_data_DomainRegexData
  | KeychainFields_keyRecords_key_data_AnySubdomainData
  | KeychainFields_keyRecords_key_data_PathData
  | KeychainFields_keyRecords_key_data_IpAddressData;

export interface KeychainFields_keyRecords_key {
  __typename: 'Key';
  jsonString: string | null;
  data: KeychainFields_keyRecords_key_data;
}

export interface KeychainFields_keyRecords {
  __typename: 'KeyRecord';
  id: string;
  comment: string | null;
  expiration: string | null;
  key: KeychainFields_keyRecords_key;
}

export interface KeychainFields {
  __typename: 'Keychain';
  id: string;
  name: string;
  description: string | null;
  isPublic: boolean;
  authorId: string;
  keyRecords: KeychainFields_keyRecords[];
}
