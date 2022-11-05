/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { DecideUnlockRequestInput } from '@dash/types';

// ====================================================
// GraphQL mutation operation: DecideUnlockRequest
// ====================================================

export interface DecideUnlockRequest_unlockRequest {
  __typename: 'UnlockRequest';
  id: string;
}

export interface DecideUnlockRequest {
  unlockRequest: DecideUnlockRequest_unlockRequest;
}

export interface DecideUnlockRequestVariables {
  input: DecideUnlockRequestInput;
}
