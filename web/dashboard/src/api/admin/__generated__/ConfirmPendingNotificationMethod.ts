/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: ConfirmPendingNotificationMethod
// ====================================================

export interface ConfirmPendingNotificationMethod_method {
  __typename: 'GenericResponse';
  success: boolean;
}

export interface ConfirmPendingNotificationMethod {
  method: ConfirmPendingNotificationMethod_method;
}

export interface ConfirmPendingNotificationMethodVariables {
  id: UUID;
  code: number;
}
