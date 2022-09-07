/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: DeleteNotification
// ====================================================

export interface DeleteNotification_deleteAdminNotification {
  __typename: 'AdminNotification';
  id: string;
}

export interface DeleteNotification {
  deleteAdminNotification: DeleteNotification_deleteAdminNotification;
}

export interface DeleteNotificationVariables {
  id: UUID;
}
