/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { Family } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL query operation: GetUser
// ====================================================

export interface GetUser_user_keychains_keys {
  __typename: 'KeyRecord';
  id: string;
}

export interface GetUser_user_keychains {
  __typename: 'Keychain';
  id: string;
  name: string;
  description: string | null;
  isPublic: boolean;
  authorId: string;
  keys: GetUser_user_keychains_keys[];
}

export interface GetUser_user_devices_model {
  __typename: 'Model';
  family: Family;
  title: string;
}

export interface GetUser_user_devices {
  __typename: 'Device';
  id: string;
  isOnline: boolean;
  model: GetUser_user_devices_model;
}

export interface GetUser_user {
  __typename: 'User';
  id: string;
  name: string;
  screenshotsEnabled: boolean;
  screenshotsResolution: number;
  screenshotsFrequency: number;
  keyloggingEnabled: boolean;
  keychains: GetUser_user_keychains[];
  devices: GetUser_user_devices[];
}

export interface GetUser {
  user: GetUser_user;
}

export interface GetUserVariables {
  id: UUID;
}
