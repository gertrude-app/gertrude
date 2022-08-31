/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { SetUserKeychainsInput } from './../../../graphqlTypes';

// ====================================================
// GraphQL mutation operation: SetUserKeychains
// ====================================================

export interface SetUserKeychains_user {
  __typename: 'User';
  id: string;
}

export interface SetUserKeychains {
  user: SetUserKeychains_user;
}

export interface SetUserKeychainsVariables {
  input: SetUserKeychainsInput;
}
