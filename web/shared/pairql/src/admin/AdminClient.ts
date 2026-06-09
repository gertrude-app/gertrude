// auto-generated, do not edit
import type * as P from '.';
import type Result from '../Result';
import type { PrepareRequest } from '../types';
import type { ClientAuth as Auth } from './shared';
import Client from '../Client';

export default class AdminClient extends Client<Auth> {
  public constructor(endpoint: string, prepareRequest: PrepareRequest<Auth>) {
    super(endpoint, `admin`, prepareRequest);
  }

  public appRatings = (
    input: P.AppRatings.Input,
  ): Promise<Result<P.AppRatings.Output>> => {
    return this.query<P.AppRatings.Output>(input, `AppRatings`, `superAdmin`);
  };

  public cohortAnalysis = (
    input: P.CohortAnalysis.Input,
  ): Promise<Result<P.CohortAnalysis.Output>> => {
    return this.query<P.CohortAnalysis.Output>(input, `CohortAnalysis`, `superAdmin`);
  };

  public deleteParent = (
    input: P.DeleteParent.Input,
  ): Promise<Result<P.DeleteParent.Output>> => {
    return this.query<P.DeleteParent.Output>(input, `DeleteParent`, `superAdmin`);
  };

  public getIdentifiedAppsForAdmin = (
    input: P.GetIdentifiedAppsForAdmin.Input,
  ): Promise<Result<P.GetIdentifiedAppsForAdmin.Output>> => {
    return this.query<P.GetIdentifiedAppsForAdmin.Output>(
      input,
      `GetIdentifiedAppsForAdmin`,
      `superAdmin`,
    );
  };

  public getPairqlTelemetrySummary = (
    input: P.GetPairqlTelemetrySummary.Input,
  ): Promise<Result<P.GetPairqlTelemetrySummary.Output>> => {
    return this.query<P.GetPairqlTelemetrySummary.Output>(
      input,
      `GetPairqlTelemetrySummary`,
      `superAdmin`,
    );
  };

  public getParentRecentTelemetry = (
    input: P.GetParentRecentTelemetry.Input,
  ): Promise<Result<P.GetParentRecentTelemetry.Output>> => {
    return this.query<P.GetParentRecentTelemetry.Output>(
      input,
      `GetParentRecentTelemetry`,
      `superAdmin`,
    );
  };

  public getRecentPairqlErrors = (
    input: P.GetRecentPairqlErrors.Input,
  ): Promise<Result<P.GetRecentPairqlErrors.Output>> => {
    return this.query<P.GetRecentPairqlErrors.Output>(
      input,
      `GetRecentPairqlErrors`,
      `superAdmin`,
    );
  };

  public getUnidentifiedApps = (
    input: P.GetUnidentifiedApps.Input,
  ): Promise<Result<P.GetUnidentifiedApps.Output>> => {
    return this.query<P.GetUnidentifiedApps.Output>(
      input,
      `GetUnidentifiedApps`,
      `superAdmin`,
    );
  };

  public iOSDetailedStats = (
    input: P.IOSDetailedStats.Input,
  ): Promise<Result<P.IOSDetailedStats.Output>> => {
    return this.query<P.IOSDetailedStats.Output>(input, `IOSDetailedStats`, `superAdmin`);
  };

  public iOSDeviceEvents = (
    input: P.IOSDeviceEvents.Input,
  ): Promise<Result<P.IOSDeviceEvents.Output>> => {
    return this.query<P.IOSDeviceEvents.Output>(input, `IOSDeviceEvents`, `superAdmin`);
  };

  public iOSDevicesList = (
    input: P.IOSDevicesList.Input,
  ): Promise<Result<P.IOSDevicesList.Output>> => {
    return this.query<P.IOSDevicesList.Output>(input, `IOSDevicesList`, `superAdmin`);
  };

  public iOSOverview = (
    input: P.IOSOverview.Input,
  ): Promise<Result<P.IOSOverview.Output>> => {
    return this.query<P.IOSOverview.Output>(input, `IOSOverview`, `superAdmin`);
  };

  public macOverview = (
    input: P.MacOverview.Input,
  ): Promise<Result<P.MacOverview.Output>> => {
    return this.query<P.MacOverview.Output>(input, `MacOverview`, `superAdmin`);
  };

  public parentDetail = (
    input: P.ParentDetail.Input,
  ): Promise<Result<P.ParentDetail.Output>> => {
    return this.query<P.ParentDetail.Output>(input, `ParentDetail`, `superAdmin`);
  };

  public parentsList = (
    input: P.ParentsList.Input,
  ): Promise<Result<P.ParentsList.Output>> => {
    return this.query<P.ParentsList.Output>(input, `ParentsList`, `superAdmin`);
  };

  public platformVersionStats = (
    input: P.PlatformVersionStats.Input,
  ): Promise<Result<P.PlatformVersionStats.Output>> => {
    return this.query<P.PlatformVersionStats.Output>(
      input,
      `PlatformVersionStats`,
      `superAdmin`,
    );
  };

  public podcastInstallDetail = (
    input: P.PodcastInstallDetail.Input,
  ): Promise<Result<P.PodcastInstallDetail.Output>> => {
    return this.query<P.PodcastInstallDetail.Output>(
      input,
      `PodcastInstallDetail`,
      `superAdmin`,
    );
  };

  public podcastInstallsList = (
    input: P.PodcastInstallsList.Input,
  ): Promise<Result<P.PodcastInstallsList.Output>> => {
    return this.query<P.PodcastInstallsList.Output>(
      input,
      `PodcastInstallsList`,
      `superAdmin`,
    );
  };

  public podcastOverview = (
    input: P.PodcastOverview.Input,
  ): Promise<Result<P.PodcastOverview.Output>> => {
    return this.query<P.PodcastOverview.Output>(input, `PodcastOverview`, `superAdmin`);
  };

  public promoteApp = (
    input: P.PromoteApp.Input,
  ): Promise<Result<P.PromoteApp.Output>> => {
    return this.query<P.PromoteApp.Output>(input, `PromoteApp`, `superAdmin`);
  };

  public requestAdminMagicLink = (
    input: P.RequestAdminMagicLink.Input,
  ): Promise<Result<P.RequestAdminMagicLink.Output>> => {
    return this.query<P.RequestAdminMagicLink.Output>(
      input,
      `RequestAdminMagicLink`,
      `none`,
    );
  };

  public searchParentByEmail = (
    input: P.SearchParentByEmail.Input,
  ): Promise<Result<P.SearchParentByEmail.Output>> => {
    return this.query<P.SearchParentByEmail.Output>(
      input,
      `SearchParentByEmail`,
      `superAdmin`,
    );
  };

  public subscriptionsOverview = (
    input: P.SubscriptionsOverview.Input,
  ): Promise<Result<P.SubscriptionsOverview.Output>> => {
    return this.query<P.SubscriptionsOverview.Output>(
      input,
      `SubscriptionsOverview`,
      `superAdmin`,
    );
  };

  public verifyAdminMagicLink = (
    input: P.VerifyAdminMagicLink.Input,
  ): Promise<Result<P.VerifyAdminMagicLink.Output>> => {
    return this.query<P.VerifyAdminMagicLink.Output>(
      input,
      `VerifyAdminMagicLink`,
      `none`,
    );
  };
}

export type { P };
