/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { LoginAdminInput } from '@dash/types';

// ====================================================
// GraphQL mutation operation: LoginAdmin
// ====================================================

export interface LoginAdmin_token_admin {
  __typename: 'Admin';
  id: string;
}

export interface LoginAdmin_token {
  __typename: 'AdminToken';
  value: string;
  admin: LoginAdmin_token_admin;
}

export interface LoginAdmin {
  token: LoginAdmin_token;
}

export interface LoginAdminVariables {
  input: LoginAdminInput;
}
