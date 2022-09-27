/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { CreateKeyRecordInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: CreateKeyRecord
// ====================================================

export interface CreateKeyRecord_keyRecord {
  __typename: 'KeyRecord';
  id: string;
}

export interface CreateKeyRecord {
  keyRecord: CreateKeyRecord_keyRecord;
}

export interface CreateKeyRecordVariables {
  input: CreateKeyRecordInput;
}
