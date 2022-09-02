/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { DeleteMonitoringItemInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: DeleteActivityItems
// ====================================================

export interface DeleteActivityItems_items {
  __typename: 'IdentifiedEntity';
  id: string;
}

export interface DeleteActivityItems {
  items: DeleteActivityItems_items[];
}

export interface DeleteActivityItemsVariables {
  userId: UUID;
  items: DeleteMonitoringItemInput[];
}
