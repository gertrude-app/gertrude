import type { Domain, PrepareRequest } from './types';
import { type PqlError, isPqlError, toClientError } from './PqlError';
import Result from './Result';

export default abstract class Client<Auth> {
  private endpoint: string;
  private domain: Domain;
  private prepareRequest: PrepareRequest<Auth>;

  protected constructor(
    endpoint: string,
    domain: Domain,
    prepareRequest: PrepareRequest<Auth> = () => null,
  ) {
    this.endpoint = endpoint;
    this.domain = domain;
    this.prepareRequest = prepareRequest;
  }

  protected async query<Output>(
    input: unknown,
    operation: string,
    auth: Auth,
  ): Promise<Result<Output, PqlError>> {
    const init: RequestInit = {
      method: `POST`,
      headers: { 'Content-Type': `application/json` },
      body: input === undefined ? undefined : JSON.stringify(input),
    };

    const error = this.prepareRequest(init, auth);
    if (error) {
      return Result.error(error);
    }

    try {
      const url = `${this.endpoint}/pairql/${this.domain}/${operation}`;
      const res = await fetch(url, init);
      const text = await res.text();
      let json: unknown;
      try {
        json = JSON.parse(text);
      } catch {
        return this.errorResult(`JSON parse error, body=${text}`);
      }
      if (res.status >= 300 || this.isStubbedError(json)) {
        return this.errorResult(json);
      } else {
        return Result.success(json as Output);
      }
    } catch (err) {
      return this.errorResult(err);
    }
  }

  private isStubbedError(json: unknown): boolean {
    return typeof json === `object` && json !== null && `__cyStubbedError` in json;
  }

  private shouldLogError(): boolean {
    return (
      this.endpoint.includes(`localhost`) ||
      this.endpoint.includes(`127.0.0.1`) ||
      this.endpoint.includes(`api--staging`)
    );
  }

  protected errorResult(error: unknown): Result<never, PqlError> {
    if (this.shouldLogError()) {
      console.error(`PqlError`, error); // eslint-disable-line no-console
    }

    if (isPqlError(error)) {
      return Result.error(error);
    }

    if (this.isStubbedError(error)) {
      return Result.error(toClientError(error as any));
    }

    const serverError = error as any;
    if (typeof serverError === `object` && serverError !== null && `id` in serverError) {
      return Result.error(toClientError(serverError));
    }

    // network/unknown errors
    if (`${error}`.includes(`Failed to fetch`)) {
      return Result.error<PqlError>({
        isPqlError: true,
        id: `34fbe3e3`,
        type: `clientError`,
        userMessage: `Something seems funny with the network. Are you sure you're connected to the internet?`,
        debugMessage: String(error),
      });
    }

    return Result.error<PqlError>({
      isPqlError: true,
      id: `b3162834`,
      type: `clientError`,
      debugMessage: `Unexpected error: ${error}`,
      showContactSupport: true,
    });
  }
}
