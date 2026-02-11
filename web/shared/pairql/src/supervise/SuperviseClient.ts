// auto-generated, do not edit
import type * as P from '.';
import type Result from '../Result';
import type { PrepareRequest } from '../types';
import type { ClientAuth as Auth } from './shared';
import Client from '../Client';

export default class SuperviseClient extends Client<Auth> {
  public constructor(endpoint: string, prepareRequest: PrepareRequest<Auth>) {
    super(endpoint, `supervise`, prepareRequest);
  }

  public getPendingSupervision = (
    input: P.GetPendingSupervision.Input,
  ): Promise<Result<P.GetPendingSupervision.Output>> => {
    return this.query<P.GetPendingSupervision.Output>(
      input,
      `GetPendingSupervision`,
      `none`,
    );
  };

  public logSupervisionEvent = (
    input: P.LogSupervisionEvent.Input,
  ): Promise<Result<P.LogSupervisionEvent.Output>> => {
    return this.query<P.LogSupervisionEvent.Output>(input, `LogSupervisionEvent`, `none`);
  };

  public markSupervisionVerified = (
    input: P.MarkSupervisionVerified.Input,
  ): Promise<Result<P.MarkSupervisionVerified.Output>> => {
    return this.query<P.MarkSupervisionVerified.Output>(
      input,
      `MarkSupervisionVerified`,
      `none`,
    );
  };

  public recordDeviceUSBConnection = (
    input: P.RecordDeviceUSBConnection.Input,
  ): Promise<Result<P.RecordDeviceUSBConnection.Output>> => {
    return this.query<P.RecordDeviceUSBConnection.Output>(
      input,
      `RecordDeviceUSBConnection`,
      `none`,
    );
  };

  public reportSupervisionFailed = (
    input: P.ReportSupervisionFailed.Input,
  ): Promise<Result<P.ReportSupervisionFailed.Output>> => {
    return this.query<P.ReportSupervisionFailed.Output>(
      input,
      `ReportSupervisionFailed`,
      `none`,
    );
  };
}

export type { P };
