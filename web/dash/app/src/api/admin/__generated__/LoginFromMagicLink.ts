/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: LoginFromMagicLink
// ====================================================

export interface LoginFromMagicLink_adminToken_admin {
  __typename: 'Admin';
  id: string;
}

export interface LoginFromMagicLink_adminToken {
  __typename: 'AdminToken';
  value: string;
  admin: LoginFromMagicLink_adminToken_admin;
}

export interface LoginFromMagicLink {
  adminToken: LoginFromMagicLink_adminToken;
}

export interface LoginFromMagicLinkVariables {
  token: string;
}
