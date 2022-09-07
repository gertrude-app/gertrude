/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import {
  SubscriptionStatus,
  Trigger,
} from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL query operation: GetAdmin
// ====================================================

export interface GetAdmin_admin_notifications_method {
  __typename: 'AdminVerifiedNotificationMethod';
  id: string;
}

export interface GetAdmin_admin_notifications {
  __typename: 'AdminNotification';
  id: string;
  trigger: Trigger;
  method: GetAdmin_admin_notifications_method;
}

export interface GetAdmin_admin_verifiedNotificationMethods_method_data_EmailData {
  __typename: 'EmailData';
  email: EmailAddress;
}

export interface GetAdmin_admin_verifiedNotificationMethods_method_data_TextData {
  __typename: 'TextData';
  phoneNumber: string;
}

export interface GetAdmin_admin_verifiedNotificationMethods_method_data_SlackData {
  __typename: 'SlackData';
  token: string;
  channelName: string;
  channelId: string;
}

export type GetAdmin_admin_verifiedNotificationMethods_method_data =
  | GetAdmin_admin_verifiedNotificationMethods_method_data_EmailData
  | GetAdmin_admin_verifiedNotificationMethods_method_data_TextData
  | GetAdmin_admin_verifiedNotificationMethods_method_data_SlackData;

export interface GetAdmin_admin_verifiedNotificationMethods_method {
  __typename: 'NotificationMethod';
  data: GetAdmin_admin_verifiedNotificationMethods_method_data;
}

export interface GetAdmin_admin_verifiedNotificationMethods {
  __typename: 'AdminVerifiedNotificationMethod';
  id: string;
  method: GetAdmin_admin_verifiedNotificationMethods_method;
}

export interface GetAdmin_admin {
  __typename: 'Admin';
  email: string;
  subscriptionStatus: SubscriptionStatus;
  notifications: GetAdmin_admin_notifications[];
  verifiedNotificationMethods: GetAdmin_admin_verifiedNotificationMethods[];
}

export interface GetAdmin {
  admin: GetAdmin_admin;
}

export interface GetAdminVariables {
  id: UUID;
}
