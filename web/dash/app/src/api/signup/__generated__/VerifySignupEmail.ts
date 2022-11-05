/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { UUIDInput } from '@dash/types';

// ====================================================
// GraphQL mutation operation: VerifySignupEmail
// ====================================================

export interface VerifySignupEmail_admin {
  __typename: 'Admin';
  id: string;
}

export interface VerifySignupEmail {
  admin: VerifySignupEmail_admin;
}

export interface VerifySignupEmailVariables {
  input: UUIDInput;
}
