/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { InitiateSignupInput } from '@dash/types';

// ====================================================
// GraphQL mutation operation: InitiateSignup
// ====================================================

export interface InitiateSignup_result {
  __typename: 'OptionalUrlResponse';
  url: string | null;
}

export interface InitiateSignup {
  result: InitiateSignup_result;
}

export interface InitiateSignupVariables {
  input: InitiateSignupInput;
}
