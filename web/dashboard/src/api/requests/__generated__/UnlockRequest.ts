/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { RequestStatus } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL query operation: UnlockRequest
// ====================================================

export interface UnlockRequest_unlockRequest_networkDecision_ipProtocol {
  __typename: 'IpProtocol';
  description: string;
}

export interface UnlockRequest_unlockRequest_networkDecision_app {
  __typename: 'AppDescriptor';
  bundleId: string;
  slug: string | null;
  displayName: string | null;
  categories: string[];
  shortDescription: string;
}

export interface UnlockRequest_unlockRequest_networkDecision {
  __typename: 'NetworkDecision';
  ipProtocol: UnlockRequest_unlockRequest_networkDecision_ipProtocol | null;
  url: string | null;
  hostname: string | null;
  ipAddress: string | null;
  app: UnlockRequest_unlockRequest_networkDecision_app | null;
}

export interface UnlockRequest_unlockRequest_device_user {
  __typename: 'User';
  name: string;
}

export interface UnlockRequest_unlockRequest_device {
  __typename: 'Device';
  id: string;
  user: UnlockRequest_unlockRequest_device_user;
}

export interface UnlockRequest_unlockRequest {
  __typename: 'UnlockRequest';
  id: string;
  requestComment: string | null;
  createdAt: string;
  status: RequestStatus;
  networkDecision: UnlockRequest_unlockRequest_networkDecision;
  device: UnlockRequest_unlockRequest_device;
}

export interface UnlockRequest {
  unlockRequest: UnlockRequest_unlockRequest;
}

export interface UnlockRequestVariables {
  id: UUID;
}
