/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

import { RequestStatus } from './../../../../../components/src/shared/dashboard/types/GraphQL';

// ====================================================
// GraphQL query operation: GetSuspendFilterRequest
// ====================================================

export interface GetSuspendFilterRequest_request_device_user {
  __typename: 'User';
  name: string;
}

export interface GetSuspendFilterRequest_request_device {
  __typename: 'Device';
  id: string;
  user: GetSuspendFilterRequest_request_device_user;
}

export interface GetSuspendFilterRequest_request {
  __typename: 'SuspendFilterRequest';
  duration: number;
  requestComment: string | null;
  requestedDurationInSeconds: number;
  status: RequestStatus;
  device: GetSuspendFilterRequest_request_device;
}

export interface GetSuspendFilterRequest {
  request: GetSuspendFilterRequest_request;
}

export interface GetSuspendFilterRequestVariables {
  id: UUID;
}
