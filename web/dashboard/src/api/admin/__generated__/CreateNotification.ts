/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { CreateAdminNotificationInput } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL mutation operation: CreateNotification
// ====================================================

export interface CreateNotification_notification {
  __typename: 'AdminNotification';
  id: string;
}

export interface CreateNotification {
  notification: CreateNotification_notification;
}

export interface CreateNotificationVariables {
  input: CreateAdminNotificationInput;
}
