/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: ListAdminKeychains
// ====================================================

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_SingleData_single =

    | ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_SingleData_single_IdentifiedAppData
    | ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_SingleData_single_BundleIdData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_SingleData_single;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope =
  | ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_WebBrowsersData
  | ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_UnrestrictedData
  | ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope_SingleData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainData {
  __typename: 'DomainData';
  domain: string;
  type: string;
  scope: ListAdminKeychains_keychains_keyRecords_key_data_DomainData_scope;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_SkeletonData_scope_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_SkeletonData_scope_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_SkeletonData_scope =
  | ListAdminKeychains_keychains_keyRecords_key_data_SkeletonData_scope_IdentifiedAppData
  | ListAdminKeychains_keychains_keyRecords_key_data_SkeletonData_scope_BundleIdData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_SkeletonData {
  __typename: 'SkeletonData';
  type: string;
  scope: ListAdminKeychains_keychains_keyRecords_key_data_SkeletonData_scope;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_SingleData_single =

    | ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_SingleData_single_IdentifiedAppData
    | ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_SingleData_single_BundleIdData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_SingleData_single;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope =
  | ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_WebBrowsersData
  | ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_UnrestrictedData
  | ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope_SingleData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData {
  __typename: 'DomainRegexData';
  type: string;
  pattern: string;
  scope: ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData_scope;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_SingleData_single =

    | ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_IdentifiedAppData
    | ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_SingleData_single_BundleIdData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_SingleData_single;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope =
  | ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_WebBrowsersData
  | ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_UnrestrictedData
  | ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope_SingleData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData {
  __typename: 'AnySubdomainData';
  type: string;
  domain: string;
  scope: ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData_scope;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_SingleData_single =

    | ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_SingleData_single_IdentifiedAppData
    | ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_SingleData_single_BundleIdData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_SingleData_single;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope =
  | ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_WebBrowsersData
  | ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_UnrestrictedData
  | ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope_SingleData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_PathData {
  __typename: 'PathData';
  type: string;
  path: string;
  scope: ListAdminKeychains_keychains_keyRecords_key_data_PathData_scope;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_WebBrowsersData {
  __typename: 'WebBrowsersData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_UnrestrictedData {
  __typename: 'UnrestrictedData';
  type: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_SingleData_single_IdentifiedAppData {
  __typename: 'IdentifiedAppData';
  type: string;
  identifiedAppSlug: string;
}

export interface ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_SingleData_single_BundleIdData {
  __typename: 'BundleIdData';
  type: string;
  bundleId: string;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_SingleData_single =

    | ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_SingleData_single_IdentifiedAppData
    | ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_SingleData_single_BundleIdData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_SingleData {
  __typename: 'SingleData';
  type: string;
  single: ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_SingleData_single;
}

export type ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope =
  | ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_WebBrowsersData
  | ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_UnrestrictedData
  | ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope_SingleData;

export interface ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData {
  __typename: 'IpAddressData';
  type: string;
  ipAddress: string;
  scope: ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData_scope;
}

export type ListAdminKeychains_keychains_keyRecords_key_data =
  | ListAdminKeychains_keychains_keyRecords_key_data_DomainData
  | ListAdminKeychains_keychains_keyRecords_key_data_SkeletonData
  | ListAdminKeychains_keychains_keyRecords_key_data_DomainRegexData
  | ListAdminKeychains_keychains_keyRecords_key_data_AnySubdomainData
  | ListAdminKeychains_keychains_keyRecords_key_data_PathData
  | ListAdminKeychains_keychains_keyRecords_key_data_IpAddressData;

export interface ListAdminKeychains_keychains_keyRecords_key {
  __typename: 'Key';
  jsonString: string | null;
  data: ListAdminKeychains_keychains_keyRecords_key_data;
}

export interface ListAdminKeychains_keychains_keyRecords {
  __typename: 'KeyRecord';
  id: string;
  key: ListAdminKeychains_keychains_keyRecords_key;
}

export interface ListAdminKeychains_keychains {
  __typename: 'Keychain';
  id: string;
  name: string;
  description: string | null;
  isPublic: boolean;
  authorId: string;
  keyRecords: ListAdminKeychains_keychains_keyRecords[];
}

export interface ListAdminKeychains {
  keychains: ListAdminKeychains_keychains[];
}
