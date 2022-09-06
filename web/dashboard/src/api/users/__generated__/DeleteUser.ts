/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: DeleteUser
// ====================================================

export interface DeleteUser_device {
  __typename: 'User';
  id: string;
}

export interface DeleteUser {
  device: DeleteUser_device;
}

export interface DeleteUserVariables {
  id: UUID;
}
