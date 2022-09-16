/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { CreateKeychainInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: CreateKeychain
// ====================================================

export interface CreateKeychain_keychain {
  __typename: 'Keychain';
  id: string;
}

export interface CreateKeychain {
  keychain: CreateKeychain_keychain;
}

export interface CreateKeychainVariables {
  input: CreateKeychainInput;
}
