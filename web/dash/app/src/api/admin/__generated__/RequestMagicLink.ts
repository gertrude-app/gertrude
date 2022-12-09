/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: RequestMagicLink
// ====================================================

export interface RequestMagicLink_result {
  __typename: 'GenericResponse';
  success: boolean;
}

export interface RequestMagicLink {
  result: RequestMagicLink_result;
}

export interface RequestMagicLinkVariables {
  email: string;
  redirect?: string | null;
}
