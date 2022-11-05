/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { UUIDInput } from '@dash/types';

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
