/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: DeleteKeyRecord
// ====================================================

export interface DeleteKeyRecord_key {
  __typename: 'KeyRecord';
  id: string;
}

export interface DeleteKeyRecord {
  key: DeleteKeyRecord_key;
}

export interface DeleteKeyRecordVariables {
  id: UUID;
}
