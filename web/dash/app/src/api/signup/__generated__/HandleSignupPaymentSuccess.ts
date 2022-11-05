/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { StringInput } from '@dash/types';

// ====================================================
// GraphQL mutation operation: HandleSignupPaymentSuccess
// ====================================================

export interface HandleSignupPaymentSuccess_token_admin {
  __typename: 'Admin';
  id: string;
}

export interface HandleSignupPaymentSuccess_token {
  __typename: 'AdminToken';
  value: string;
  admin: HandleSignupPaymentSuccess_token_admin;
}

export interface HandleSignupPaymentSuccess {
  token: HandleSignupPaymentSuccess_token;
}

export interface HandleSignupPaymentSuccessVariables {
  input: StringInput;
}
