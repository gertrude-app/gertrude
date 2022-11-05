/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { UUIDInput } from '@dash/types';

// ====================================================
// GraphQL mutation operation: CreateBillingPortalSession
// ====================================================

export interface CreateBillingPortalSession_session {
  __typename: 'UrlResponse';
  url: string;
}

export interface CreateBillingPortalSession {
  session: CreateBillingPortalSession_session;
}

export interface CreateBillingPortalSessionVariables {
  input: UUIDInput;
}
