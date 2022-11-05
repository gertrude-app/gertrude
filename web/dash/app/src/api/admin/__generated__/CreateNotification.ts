/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { CreateAdminNotificationInput } from '@dash/types';

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
