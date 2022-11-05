/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { UUIDInput } from '@dash/types';

// ====================================================
// GraphQL mutation operation: CreatePendingAppConnection
// ====================================================

export interface CreatePendingAppConnection_connection {
  __typename: 'PendingAppConnectionResponse';
  code: number;
}

export interface CreatePendingAppConnection {
  connection: CreatePendingAppConnection_connection;
}

export interface CreatePendingAppConnectionVariables {
  input: UUIDInput;
}
