/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: ListUsers
// ====================================================

export interface ListUsers_user_keychains_keys {
  __typename: 'KeyRecord';
  id: string;
}

export interface ListUsers_user_keychains {
  __typename: 'Keychain';
  keys: ListUsers_user_keychains_keys[];
}

export interface ListUsers_user_devices {
  __typename: 'Device';
  id: string;
  hostname: string | null;
}

export interface ListUsers_user {
  __typename: 'User';
  id: string;
  name: string;
  screenshotsEnabled: boolean;
  keystrokesEnabled: boolean;
  keychains: ListUsers_user_keychains[];
  devices: ListUsers_user_devices[];
}

export interface ListUsers {
  user: ListUsers_user[];
}
