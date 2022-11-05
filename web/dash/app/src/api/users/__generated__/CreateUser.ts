/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { CreateUserInput } from '@dash/types';

// ====================================================
// GraphQL mutation operation: CreateUser
// ====================================================

export interface CreateUser_user {
  __typename: 'User';
  id: string;
}

export interface CreateUser {
  user: CreateUser_user;
}

export interface CreateUserVariables {
  input: CreateUserInput;
}
