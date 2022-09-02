/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: DeleteNotificationMethod
// ====================================================

export interface DeleteNotificationMethod_deleteAdminVerifiedNotificationMethod {
  __typename: 'AdminVerifiedNotificationMethod';
  id: string;
}

export interface DeleteNotificationMethod {
  deleteAdminVerifiedNotificationMethod: DeleteNotificationMethod_deleteAdminVerifiedNotificationMethod;
}

export interface DeleteNotificationMethodVariables {
  id: UUID;
}
