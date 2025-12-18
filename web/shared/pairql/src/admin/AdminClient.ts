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

  public podcastOverview = (
    input: P.PodcastOverview.Input,
  ): Promise<Result<P.PodcastOverview.Output>> => {
    return this.query<P.PodcastOverview.Output>(input, `PodcastOverview`, `superAdmin`);
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
