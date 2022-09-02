/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { CreateWaitlistedUserInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: JoinWaitlist
// ====================================================

export interface JoinWaitlist_user {
  __typename: 'WaitlistedUser';
  id: string;
}

export interface JoinWaitlist {
  user: JoinWaitlist_user;
}

export interface JoinWaitlistVariables {
  input: CreateWaitlistedUserInput;
}
