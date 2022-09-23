/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { UpdateKeyRecordInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: UpdateKeyRecord
// ====================================================

export interface UpdateKeyRecord_keyRecord {
  __typename: 'KeyRecord';
  id: string;
}

export interface UpdateKeyRecord {
  keyRecord: UpdateKeyRecord_keyRecord;
}

export interface UpdateKeyRecordVariables {
  input: UpdateKeyRecordInput;
}
