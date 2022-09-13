/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { UpdateKeychainInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: UpdateKeychain
// ====================================================

export interface UpdateKeychain_notification {
  __typename: 'Keychain';
  id: string;
}

export interface UpdateKeychain {
  notification: UpdateKeychain_notification;
}

export interface UpdateKeychainVariables {
  input: UpdateKeychainInput;
}
