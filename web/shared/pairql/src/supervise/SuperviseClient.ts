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

  public superviseNoop = (
    input: P.SuperviseNoop.Input,
  ): Promise<Result<P.SuperviseNoop.Output>> => {
    return this.query<P.SuperviseNoop.Output>(input, `SuperviseNoop`, `none`);
  };
}

export type { P };
