/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { UpdateUserInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: UpdateUser
// ====================================================

export interface UpdateUser_user {
  __typename: 'User';
  id: string;
}

export interface UpdateUser {
  user: UpdateUser_user;
}

export interface UpdateUserVariables {
  input: UpdateUserInput;
}
