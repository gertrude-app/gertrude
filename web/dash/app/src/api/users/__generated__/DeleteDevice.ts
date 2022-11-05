/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

// ====================================================
// GraphQL mutation operation: DeleteDevice
// ====================================================

export interface DeleteDevice_device {
  __typename: 'Device';
  id: string;
}

export interface DeleteDevice {
  device: DeleteDevice_device;
}

export interface DeleteDeviceVariables {
  id: UUID;
}
