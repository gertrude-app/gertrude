/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { UUIDInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: CreateSignupPaymentUrl
// ====================================================

export interface CreateSignupPaymentUrl_payment {
  __typename: 'UrlResponse';
  url: string;
}

export interface CreateSignupPaymentUrl {
  payment: CreateSignupPaymentUrl_payment;
}

export interface CreateSignupPaymentUrlVariables {
  input: UUIDInput;
}
