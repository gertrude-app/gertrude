/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { CreateUserTokenInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: CreateUserToken
// ====================================================

export interface CreateUserToken_token {
  __typename: 'UserToken';
  value: string;
}

export interface CreateUserToken {
  token: CreateUserToken_token;
}

export interface CreateUserTokenVariables {
  input: CreateUserTokenInput;
}
