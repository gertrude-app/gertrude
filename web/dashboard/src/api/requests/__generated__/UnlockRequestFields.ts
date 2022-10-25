/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { RequestStatus } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL fragment: UnlockRequestFields
// ====================================================

export interface UnlockRequestFields_networkDecision_ipProtocol {
  __typename: 'IpProtocol';
  description: string;
}

export interface UnlockRequestFields_networkDecision_app {
  __typename: 'AppDescriptor';
  bundleId: string;
  slug: string | null;
  displayName: string | null;
  categories: string[];
  shortDescription: string;
}

export interface UnlockRequestFields_networkDecision {
  __typename: 'NetworkDecision';
  ipProtocol: UnlockRequestFields_networkDecision_ipProtocol | null;
  url: string | null;
  hostname: string | null;
  ipAddress: string | null;
  app: UnlockRequestFields_networkDecision_app | null;
}

export interface UnlockRequestFields_device_user {
  __typename: 'User';
  id: string;
  name: string;
}

export interface UnlockRequestFields_device {
  __typename: 'Device';
  id: string;
  user: UnlockRequestFields_device_user;
}

export interface UnlockRequestFields {
  __typename: 'UnlockRequest';
  id: string;
  requestComment: string | null;
  createdAt: string;
  status: RequestStatus;
  networkDecision: UnlockRequestFields_networkDecision;
  device: UnlockRequestFields_device;
}
