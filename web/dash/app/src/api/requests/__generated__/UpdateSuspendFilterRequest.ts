/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { UpdateSuspendFilterRequestInput } from '@dash/types';

// ====================================================
// GraphQL mutation operation: UpdateSuspendFilterRequest
// ====================================================

export interface UpdateSuspendFilterRequest_request {
  __typename: 'SuspendFilterRequest';
  id: string;
}

export interface UpdateSuspendFilterRequest {
  request: UpdateSuspendFilterRequest_request;
}

export interface UpdateSuspendFilterRequestVariables {
  input: UpdateSuspendFilterRequestInput;
}
