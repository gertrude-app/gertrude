/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL query operation: GetSelectableKeychains
// ====================================================

export interface GetSelectableKeychains_own_keyRecords {
  __typename: 'KeyRecord';
  id: string;
}

export interface GetSelectableKeychains_own {
  __typename: 'Keychain';
  id: string;
  name: string;
  isPublic: boolean;
  authorId: string;
  description: string | null;
  keyRecords: GetSelectableKeychains_own_keyRecords[];
}

export interface GetSelectableKeychains_public_keyRecords {
  __typename: 'KeyRecord';
  id: string;
}

export interface GetSelectableKeychains_public {
  __typename: 'Keychain';
  id: string;
  name: string;
  isPublic: boolean;
  authorId: string;
  description: string | null;
  keyRecords: GetSelectableKeychains_public_keyRecords[];
}

export interface GetSelectableKeychains {
  own: GetSelectableKeychains_own[];
  public: GetSelectableKeychains_public[];
}
