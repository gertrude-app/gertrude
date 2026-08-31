// auto-generated, do not edit
import type * as P from '.';
import type Result from '../Result';
import type { PrepareRequest } from '../types';
import type { ClientAuth as Auth } from './shared';
import Client from '../Client';

export default class AccountClient extends Client<Auth> {
  public constructor(endpoint: string, prepareRequest: PrepareRequest<Auth>) {
    super(endpoint, `account`, prepareRequest);
  }

  public accountLogin = (
    input: P.AccountLogin.Input,
  ): Promise<Result<P.AccountLogin.Output>> => {
    return this.query<P.AccountLogin.Output>(input, `AccountLogin`, `none`);
  };

  public accountLoginMagicLink = (
    input: P.AccountLoginMagicLink.Input,
  ): Promise<Result<P.AccountLoginMagicLink.Output>> => {
    return this.query<P.AccountLoginMagicLink.Output>(
      input,
      `AccountLoginMagicLink`,
      `none`,
    );
  };

  public accountRequestMagicLink = (
    input: P.AccountRequestMagicLink.Input,
  ): Promise<Result<P.AccountRequestMagicLink.Output>> => {
    return this.query<P.AccountRequestMagicLink.Output>(
      input,
      `AccountRequestMagicLink`,
      `none`,
    );
  };

  public accountResetPassword = (
    input: P.AccountResetPassword.Input,
  ): Promise<Result<P.AccountResetPassword.Output>> => {
    return this.query<P.AccountResetPassword.Output>(
      input,
      `AccountResetPassword`,
      `none`,
    );
  };

  public accountSendPasswordResetEmail = (
    input: P.AccountSendPasswordResetEmail.Input,
  ): Promise<Result<P.AccountSendPasswordResetEmail.Output>> => {
    return this.query<P.AccountSendPasswordResetEmail.Output>(
      input,
      `AccountSendPasswordResetEmail`,
      `none`,
    );
  };

  public changeAccountSubscriptionTier = (
    input: P.ChangeAccountSubscriptionTier.Input,
  ): Promise<Result<P.ChangeAccountSubscriptionTier.Output>> => {
    return this.query<P.ChangeAccountSubscriptionTier.Output>(
      input,
      `ChangeAccountSubscriptionTier`,
      `parent`,
    );
  };

  public confirmAccountNotificationMethod = (
    input: P.ConfirmAccountNotificationMethod.Input,
  ): Promise<Result<P.ConfirmAccountNotificationMethod.Output>> => {
    return this.query<P.ConfirmAccountNotificationMethod.Output>(
      input,
      `ConfirmAccountNotificationMethod`,
      `parent`,
    );
  };

  public createAccountNotificationMethod = (
    input: P.CreateAccountNotificationMethod.Input,
  ): Promise<Result<P.CreateAccountNotificationMethod.Output>> => {
    return this.query<P.CreateAccountNotificationMethod.Output>(
      input,
      `CreateAccountNotificationMethod`,
      `parent`,
    );
  };

  public createPerson = (
    input: P.CreatePerson.Input,
  ): Promise<Result<P.CreatePerson.Output>> => {
    return this.query<P.CreatePerson.Output>(input, `CreatePerson`, `parent`);
  };

  public decideSuspensionRequest = (
    input: P.DecideSuspensionRequest.Input,
  ): Promise<Result<P.DecideSuspensionRequest.Output>> => {
    return this.query<P.DecideSuspensionRequest.Output>(
      input,
      `DecideSuspensionRequest`,
      `parent`,
    );
  };

  public deleteAccountKey = (
    input: P.DeleteAccountKey.Input,
  ): Promise<Result<P.DeleteAccountKey.Output>> => {
    return this.query<P.DeleteAccountKey.Output>(input, `DeleteAccountKey`, `parent`);
  };

  public deleteAccountNotification = (
    input: P.DeleteAccountNotification.Input,
  ): Promise<Result<P.DeleteAccountNotification.Output>> => {
    return this.query<P.DeleteAccountNotification.Output>(
      input,
      `DeleteAccountNotification`,
      `parent`,
    );
  };

  public deleteAccountNotificationMethod = (
    input: P.DeleteAccountNotificationMethod.Input,
  ): Promise<Result<P.DeleteAccountNotificationMethod.Output>> => {
    return this.query<P.DeleteAccountNotificationMethod.Output>(
      input,
      `DeleteAccountNotificationMethod`,
      `parent`,
    );
  };

  public deleteActivity = (
    input: P.DeleteActivity.Input,
  ): Promise<Result<P.DeleteActivity.Output>> => {
    return this.query<P.DeleteActivity.Output>(input, `DeleteActivity`, `parent`);
  };

  public deletePerson = (
    input: P.DeletePerson.Input,
  ): Promise<Result<P.DeletePerson.Output>> => {
    return this.query<P.DeletePerson.Output>(input, `DeletePerson`, `parent`);
  };

  public getAccountBilling = (
    input: P.GetAccountBilling.Input,
  ): Promise<Result<P.GetAccountBilling.Output>> => {
    return this.query<P.GetAccountBilling.Output>(input, `GetAccountBilling`, `parent`);
  };

  public getAccountKeychain = (
    input: P.GetAccountKeychain.Input,
  ): Promise<Result<P.GetAccountKeychain.Output>> => {
    return this.query<P.GetAccountKeychain.Output>(input, `GetAccountKeychain`, `parent`);
  };

  public getAccountKeychains = (
    input: P.GetAccountKeychains.Input,
  ): Promise<Result<P.GetAccountKeychains.Output>> => {
    return this.query<P.GetAccountKeychains.Output>(
      input,
      `GetAccountKeychains`,
      `parent`,
    );
  };

  public getAccountSettings = (
    input: P.GetAccountSettings.Input,
  ): Promise<Result<P.GetAccountSettings.Output>> => {
    return this.query<P.GetAccountSettings.Output>(input, `GetAccountSettings`, `parent`);
  };

  public getActivitySummaries = (
    input: P.GetActivitySummaries.Input,
  ): Promise<Result<P.GetActivitySummaries.Output>> => {
    return this.query<P.GetActivitySummaries.Output>(
      input,
      `GetActivitySummaries`,
      `parent`,
    );
  };

  public getDayActivity = (
    input: P.GetDayActivity.Input,
  ): Promise<Result<P.GetDayActivity.Output>> => {
    return this.query<P.GetDayActivity.Output>(input, `GetDayActivity`, `parent`);
  };

  public getDevices = (
    input: P.GetDevices.Input,
  ): Promise<Result<P.GetDevices.Output>> => {
    return this.query<P.GetDevices.Output>(input, `GetDevices`, `parent`);
  };

  public getIosDeviceSettings = (
    input: P.GetIosDeviceSettings.Input,
  ): Promise<Result<P.GetIosDeviceSettings.Output>> => {
    return this.query<P.GetIosDeviceSettings.Output>(
      input,
      `GetIosDeviceSettings`,
      `parent`,
    );
  };

  public getMacDevice = (
    input: P.GetMacDevice.Input,
  ): Promise<Result<P.GetMacDevice.Output>> => {
    return this.query<P.GetMacDevice.Output>(input, `GetMacDevice`, `parent`);
  };

  public getPeople = (input: P.GetPeople.Input): Promise<Result<P.GetPeople.Output>> => {
    return this.query<P.GetPeople.Output>(input, `GetPeople`, `parent`);
  };

  public getPersonActivitySummaries = (
    input: P.GetPersonActivitySummaries.Input,
  ): Promise<Result<P.GetPersonActivitySummaries.Output>> => {
    return this.query<P.GetPersonActivitySummaries.Output>(
      input,
      `GetPersonActivitySummaries`,
      `parent`,
    );
  };

  public getPersonDayActivity = (
    input: P.GetPersonDayActivity.Input,
  ): Promise<Result<P.GetPersonDayActivity.Output>> => {
    return this.query<P.GetPersonDayActivity.Output>(
      input,
      `GetPersonDayActivity`,
      `parent`,
    );
  };

  public getPersonInstalledMacApps = (
    input: P.GetPersonInstalledMacApps.Input,
  ): Promise<Result<P.GetPersonInstalledMacApps.Output>> => {
    return this.query<P.GetPersonInstalledMacApps.Output>(
      input,
      `GetPersonInstalledMacApps`,
      `parent`,
    );
  };

  public getPersonMacSettings = (
    input: P.GetPersonMacSettings.Input,
  ): Promise<Result<P.GetPersonMacSettings.Output>> => {
    return this.query<P.GetPersonMacSettings.Output>(
      input,
      `GetPersonMacSettings`,
      `parent`,
    );
  };

  public getSecurityEvents = (
    input: P.GetSecurityEvents.Input,
  ): Promise<Result<P.GetSecurityEvents.Output>> => {
    return this.query<P.GetSecurityEvents.Output>(input, `GetSecurityEvents`, `parent`);
  };

  public getSuspensionRequests = (
    input: P.GetSuspensionRequests.Input,
  ): Promise<Result<P.GetSuspensionRequests.Output>> => {
    return this.query<P.GetSuspensionRequests.Output>(
      input,
      `GetSuspensionRequests`,
      `parent`,
    );
  };

  public handleAccountCheckoutCancel = (
    input: P.HandleAccountCheckoutCancel.Input,
  ): Promise<Result<P.HandleAccountCheckoutCancel.Output>> => {
    return this.query<P.HandleAccountCheckoutCancel.Output>(
      input,
      `HandleAccountCheckoutCancel`,
      `parent`,
    );
  };

  public handleAccountCheckoutSuccess = (
    input: P.HandleAccountCheckoutSuccess.Input,
  ): Promise<Result<P.HandleAccountCheckoutSuccess.Output>> => {
    return this.query<P.HandleAccountCheckoutSuccess.Output>(
      input,
      `HandleAccountCheckoutSuccess`,
      `parent`,
    );
  };

  public openAccountBillingPortal = (
    input: P.OpenAccountBillingPortal.Input,
  ): Promise<Result<P.OpenAccountBillingPortal.Output>> => {
    return this.query<P.OpenAccountBillingPortal.Output>(
      input,
      `OpenAccountBillingPortal`,
      `parent`,
    );
  };

  public requestAccountPublicKeychain = (
    input: P.RequestAccountPublicKeychain.Input,
  ): Promise<Result<P.RequestAccountPublicKeychain.Output>> => {
    return this.query<P.RequestAccountPublicKeychain.Output>(
      input,
      `RequestAccountPublicKeychain`,
      `parent`,
    );
  };

  public requestPodcastsPinReset = (
    input: P.RequestPodcastsPinReset.Input,
  ): Promise<Result<P.RequestPodcastsPinReset.Output>> => {
    return this.query<P.RequestPodcastsPinReset.Output>(
      input,
      `RequestPodcastsPinReset`,
      `parent`,
    );
  };

  public saveAccountKey = (
    input: P.SaveAccountKey.Input,
  ): Promise<Result<P.SaveAccountKey.Output>> => {
    return this.query<P.SaveAccountKey.Output>(input, `SaveAccountKey`, `parent`);
  };

  public saveAccountNotification = (
    input: P.SaveAccountNotification.Input,
  ): Promise<Result<P.SaveAccountNotification.Output>> => {
    return this.query<P.SaveAccountNotification.Output>(
      input,
      `SaveAccountNotification`,
      `parent`,
    );
  };

  public setAccountDailyReviewEmail = (
    input: P.SetAccountDailyReviewEmail.Input,
  ): Promise<Result<P.SetAccountDailyReviewEmail.Output>> => {
    return this.query<P.SetAccountDailyReviewEmail.Output>(
      input,
      `SetAccountDailyReviewEmail`,
      `parent`,
    );
  };

  public setAccountKeychainAssignment = (
    input: P.SetAccountKeychainAssignment.Input,
  ): Promise<Result<P.SetAccountKeychainAssignment.Output>> => {
    return this.query<P.SetAccountKeychainAssignment.Output>(
      input,
      `SetAccountKeychainAssignment`,
      `parent`,
    );
  };

  public startAccountCheckout = (
    input: P.StartAccountCheckout.Input,
  ): Promise<Result<P.StartAccountCheckout.Output>> => {
    return this.query<P.StartAccountCheckout.Output>(
      input,
      `StartAccountCheckout`,
      `parent`,
    );
  };

  public startAccountFullTrial = (
    input: P.StartAccountFullTrial.Input,
  ): Promise<Result<P.StartAccountFullTrial.Output>> => {
    return this.query<P.StartAccountFullTrial.Output>(
      input,
      `StartAccountFullTrial`,
      `parent`,
    );
  };

  public toggleActivityFlag = (
    input: P.ToggleActivityFlag.Input,
  ): Promise<Result<P.ToggleActivityFlag.Output>> => {
    return this.query<P.ToggleActivityFlag.Output>(input, `ToggleActivityFlag`, `parent`);
  };

  public updateIosDeviceBlockedGroups = (
    input: P.UpdateIosDeviceBlockedGroups.Input,
  ): Promise<Result<P.UpdateIosDeviceBlockedGroups.Output>> => {
    return this.query<P.UpdateIosDeviceBlockedGroups.Output>(
      input,
      `UpdateIosDeviceBlockedGroups`,
      `parent`,
    );
  };

  public updateIosDeviceProfileSettings = (
    input: P.UpdateIosDeviceProfileSettings.Input,
  ): Promise<Result<P.UpdateIosDeviceProfileSettings.Output>> => {
    return this.query<P.UpdateIosDeviceProfileSettings.Output>(
      input,
      `UpdateIosDeviceProfileSettings`,
      `parent`,
    );
  };

  public updateMacDevice = (
    input: P.UpdateMacDevice.Input,
  ): Promise<Result<P.UpdateMacDevice.Output>> => {
    return this.query<P.UpdateMacDevice.Output>(input, `UpdateMacDevice`, `parent`);
  };

  public updatePersonBasicDetails = (
    input: P.UpdatePersonBasicDetails.Input,
  ): Promise<Result<P.UpdatePersonBasicDetails.Output>> => {
    return this.query<P.UpdatePersonBasicDetails.Output>(
      input,
      `UpdatePersonBasicDetails`,
      `parent`,
    );
  };

  public updatePersonMacApps = (
    input: P.UpdatePersonMacApps.Input,
  ): Promise<Result<P.UpdatePersonMacApps.Output>> => {
    return this.query<P.UpdatePersonMacApps.Output>(
      input,
      `UpdatePersonMacApps`,
      `parent`,
    );
  };

  public updatePersonMacInternetFiltering = (
    input: P.UpdatePersonMacInternetFiltering.Input,
  ): Promise<Result<P.UpdatePersonMacInternetFiltering.Output>> => {
    return this.query<P.UpdatePersonMacInternetFiltering.Output>(
      input,
      `UpdatePersonMacInternetFiltering`,
      `parent`,
    );
  };

  public updatePersonMacMonitoringSettings = (
    input: P.UpdatePersonMacMonitoringSettings.Input,
  ): Promise<Result<P.UpdatePersonMacMonitoringSettings.Output>> => {
    return this.query<P.UpdatePersonMacMonitoringSettings.Output>(
      input,
      `UpdatePersonMacMonitoringSettings`,
      `parent`,
    );
  };
}

export type { P };
