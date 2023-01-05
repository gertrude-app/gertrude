import { Result } from '@dash/types';
import type { ClientAuth } from '@dash/types';
import Current from '../environment';

export async function query<Input, Output>(
  input: Input,
  auth: ClientAuth,
  operation: string,
): Promise<Result<Output>> {
  const headers: Record<string, string> = { 'Content-Type': `application/json` };

  if (auth === `admin`) {
    const token =
      Current.localStorage.getItem(`admin_token`) ??
      Current.sessionStorage.getItem(`admin_token`);
    headers[`X-AdminToken`] = token ?? ``;
  }

  if (!Current.env.isProd()) {
    headers[`X-DashboardUrl`] = window.location.origin;
  }

  const init: RequestInit = {
    method: `POST`,
    headers,
  };

  if (input !== undefined) {
    init.body = JSON.stringify(input);
  }

  try {
    const res = await fetch(
      `${Current.env.apiEndpoint()}/pairql/dashboard/${operation}`,
      init,
    );
    const json = await res.json();
    return Result.success(json);
  } catch (error) {
    return Result.error({ debugMessage: `${error}` }); // TODO: error handling for real
  }
}
