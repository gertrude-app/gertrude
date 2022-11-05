/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: DeleteKeychain
// ====================================================

export interface DeleteKeychain_keychain {
  __typename: 'Keychain';
  id: string;
}

export interface DeleteKeychain {
  keychain: DeleteKeychain_keychain;
}

export interface DeleteKeychainVariables {
  id: UUID;
}
