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

  public getAccountKeychains = (
    input: P.GetAccountKeychains.Input,
  ): Promise<Result<P.GetAccountKeychains.Output>> => {
    return this.query<P.GetAccountKeychains.Output>(
      input,
      `GetAccountKeychains`,
      `parent`,
    );
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

  public getSuspensionRequests = (
    input: P.GetSuspensionRequests.Input,
  ): Promise<Result<P.GetSuspensionRequests.Output>> => {
    return this.query<P.GetSuspensionRequests.Output>(
      input,
      `GetSuspensionRequests`,
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

  public setAccountKeychainAssignment = (
    input: P.SetAccountKeychainAssignment.Input,
  ): Promise<Result<P.SetAccountKeychainAssignment.Output>> => {
    return this.query<P.SetAccountKeychainAssignment.Output>(
      input,
      `SetAccountKeychainAssignment`,
      `parent`,
    );
  };

  public toggleActivityFlag = (
    input: P.ToggleActivityFlag.Input,
  ): Promise<Result<P.ToggleActivityFlag.Output>> => {
    return this.query<P.ToggleActivityFlag.Output>(input, `ToggleActivityFlag`, `parent`);
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
