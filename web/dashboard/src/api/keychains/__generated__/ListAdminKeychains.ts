/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: ListAdminKeychains
// ====================================================

export interface ListAdminKeychains_keychains_keys {
  __typename: 'KeyRecord';
  id: string;
}

export interface ListAdminKeychains_keychains {
  __typename: 'Keychain';
  id: string;
  name: string;
  description: string | null;
  isPublic: boolean;
  authorId: string;
  keys: ListAdminKeychains_keychains_keys[];
}

export interface ListAdminKeychains {
  keychains: ListAdminKeychains_keychains[];
}
