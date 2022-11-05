/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { RequestStatus } from '@dash/types';

// ====================================================
// GraphQL query operation: UserUnlockRequests
// ====================================================

export interface UserUnlockRequests_unlockRequests_networkDecision_ipProtocol {
  __typename: 'IpProtocol';
  description: string;
}

export interface UserUnlockRequests_unlockRequests_networkDecision_app {
  __typename: 'AppDescriptor';
  bundleId: string;
  slug: string | null;
  displayName: string | null;
  categories: string[];
  shortDescription: string;
}

export interface UserUnlockRequests_unlockRequests_networkDecision {
  __typename: 'NetworkDecision';
  ipProtocol: UserUnlockRequests_unlockRequests_networkDecision_ipProtocol | null;
  url: string | null;
  hostname: string | null;
  ipAddress: string | null;
  app: UserUnlockRequests_unlockRequests_networkDecision_app | null;
}

export interface UserUnlockRequests_unlockRequests_device_user {
  __typename: 'User';
  id: string;
  name: string;
}

export interface UserUnlockRequests_unlockRequests_device {
  __typename: 'Device';
  id: string;
  user: UserUnlockRequests_unlockRequests_device_user;
}

export interface UserUnlockRequests_unlockRequests {
  __typename: 'UnlockRequest';
  id: string;
  requestComment: string | null;
  createdAt: string;
  status: RequestStatus;
  networkDecision: UserUnlockRequests_unlockRequests_networkDecision;
  device: UserUnlockRequests_unlockRequests_device;
}

export interface UserUnlockRequests {
  unlockRequests: UserUnlockRequests_unlockRequests[];
}

export interface UserUnlockRequestsVariables {
  id: UUID;
}
