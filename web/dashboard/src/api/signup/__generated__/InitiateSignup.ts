/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { EmailInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: InitiateSignup
// ====================================================

export interface InitiateSignup_result {
  __typename: 'GenericResponse';
  success: boolean;
}

export interface InitiateSignup {
  result: InitiateSignup_result;
}

export interface InitiateSignupVariables {
  input: EmailInput;
}
