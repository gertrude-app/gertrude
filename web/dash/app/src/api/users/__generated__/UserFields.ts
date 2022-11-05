/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { Family } from '@dash/types';

// ====================================================
// GraphQL fragment: UserFields
// ====================================================

export interface UserFields_keychains_keyRecords {
  __typename: 'KeyRecord';
  id: string;
}

export interface UserFields_keychains {
  __typename: 'Keychain';
  id: string;
  name: string;
  description: string | null;
  isPublic: boolean;
  authorId: string;
  keyRecords: UserFields_keychains_keyRecords[];
}

export interface UserFields_devices_model {
  __typename: 'Model';
  family: Family;
  title: string;
}

export interface UserFields_devices {
  __typename: 'Device';
  id: string;
  isOnline: boolean;
  model: UserFields_devices_model;
}

export interface UserFields {
  __typename: 'User';
  id: string;
  name: string;
  screenshotsEnabled: boolean;
  screenshotsResolution: number;
  screenshotsFrequency: number;
  keyloggingEnabled: boolean;
  keychains: UserFields_keychains[];
  devices: UserFields_devices[];
}
