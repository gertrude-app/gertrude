/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: GetKeychain
// ====================================================

export interface GetKeychain_keychain_keys {
  __typename: 'KeyRecord';
  id: string;
}

export interface GetKeychain_keychain {
  __typename: 'Keychain';
  id: string;
  name: string;
  description: string | null;
  isPublic: boolean;
  authorId: string;
  keys: GetKeychain_keychain_keys[];
}

export interface GetKeychain {
  keychain: GetKeychain_keychain;
}

export interface GetKeychainVariables {
  id: UUID;
}
