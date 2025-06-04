import type { RequestState } from './utility';
import type { CreatePendingNotificationMethod } from './';

export type NewAdminNotificationMethodEvent =
  | { type: `createClicked` }
  | { type: `cancelClicked` }
  | { type: `sendCodeClicked` }
  | { type: `verifyCodeClicked` }
  | { type: `createPendingMethodStarted` }
  | { type: `createPendingMethodSucceeded`; methodId: UUID }
  | { type: `createPendingMethodFailed` }
  | { type: `confirmPendingMethodStarted` }
  | { type: `confirmPendingMethodSucceeded` }
  | { type: `confirmPendingMethodFailed` }
  | { type: `codeUpdated`; code: string }
  | { type: `emailAddressUpdated`; email: string }
  | { type: `slackChannelNameUpdated`; channelName: string }
  | { type: `slackChannelIdUpdated`; channelId: string }
  | { type: `slackTokenUpdated`; token: string }
  | { type: `textPhoneNumberUpdated`; phoneNumber: string }
  | {
      type: `methodTypeUpdated`;
      methodType: CreatePendingNotificationMethod.Input[`case`];
    };

export type PendingNotificationMethod = {
  sendCodeRequest: RequestState<UUID>;
  confirmationRequest: RequestState;
  confirmationCode: string;
} & CreatePendingNotificationMethod.Input;
