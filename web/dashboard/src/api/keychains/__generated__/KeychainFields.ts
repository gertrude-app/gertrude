/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL fragment: KeychainFields
// ====================================================

export interface KeychainFields_keys {
  __typename: 'KeyRecord';
  id: string;
}

export interface KeychainFields {
  __typename: 'Keychain';
  id: string;
  name: string;
  description: string | null;
  isPublic: boolean;
  authorId: string;
  keys: KeychainFields_keys[];
}
