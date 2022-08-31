/* tslint:disable */
/* eslint-disable */
// @generated
// This file was automatically generated and should not be edited.

//==============================================================
// START Enums and Input Objects
//==============================================================

export enum Family {
  iMac = 'iMac',
  macBookAir = 'macBookAir',
  macBookPro = 'macBookPro',
  mini = 'mini',
  pro = 'pro',
  studio = 'studio',
  unknown = 'unknown',
}

export interface CreateWaitlistedUserInput {
  email: string;
  id?: UUID | null;
  signupToken?: UUID | null;
}

export interface DateRangeInput {
  end: string;
  start: string;
}

export interface DeleteMonitoringItemInput {
  id: UUID;
  type: string;
}

export interface LoginAdminInput {
  email: string;
  password: string;
}

//==============================================================
// END Enums and Input Objects
//==============================================================
