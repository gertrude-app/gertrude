/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { CreateWaitlistedUserInput } from './../../../../__generated__/globalTypes';

// ====================================================
// GraphQL mutation operation: CreateWaitlistedUser
// ====================================================

export interface CreateWaitlistedUser_user {
  __typename: 'WaitlistedUser';
  id: string;
}

export interface CreateWaitlistedUser {
  user: CreateWaitlistedUser_user;
}

export interface CreateWaitlistedUserVariables {
  input: CreateWaitlistedUserInput;
}
