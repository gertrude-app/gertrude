import { Result } from '@dash/types';
import type { ClientAuth, PqlError, ServerPqlError } from '@dash/types';
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
    if (!token) {
      return errorResult({
        isPqlError: true,
        id: `10569a9f`,
        type: `loggedOut`,
        debugMessage: `No parent token found`,
      });
    }
    headers[`X-AdminToken`] = token;
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
    const ENDPOINT = Current.env.apiEndpoint();
    const res = await fetch(`${ENDPOINT}/pairql/dashboard/${operation}`, init);
    const json = await res.json();
    if (res.status >= 300 || `__cyStubbedError` in json) {
      return errorResult(toClientError(json));
    } else {
      return Result.success(json);
    }
  } catch (error) {
    return handleUnknown(error);
  }
}

// todo: maybe move this?
export function ensurePqlError(error: unknown): PqlError {
  if (typeof error === `object` && error !== null && `isPqlError` in error) {
    return error as PqlError;
  } else {
    return {
      isPqlError: true,
      id: `59b169c4`,
      type: `clientError`,
      debugMessage: `Unexpected non-pql error: ${error}`,
      showContactSupport: true,
    };
  }
}

// helpers

function errorResult(error: PqlError): Result<never, PqlError> {
  if (!Current.env.isProd()) {
    console.error(`PqlError`, error); // eslint-disable-line no-console
  }
  return Result.error(error);
}

function toClientError(serverError: ServerPqlError): PqlError {
  return {
    isPqlError: true,
    id: serverError.id,
    type: serverError.type,
    serverRequestId: serverError.requestId,
    userMessage: serverError.userMessage,
    userAction: serverError.userAction,
    debugMessage: serverError.debugMessage,
    entityName: serverError.entityName,
    tag: serverError.dashboardTag,
    showContactSupport: serverError.showContactSupport,
  };
}

function handleUnknown(error: unknown): Result<never, PqlError> {
  if (`${error}`.includes(`Failed to fetch`)) {
    return errorResult({
      isPqlError: true,
      id: `34fbe3e3`,
      type: `clientError`,
      userMessage: `Something seems funny with the network. Are you sure you're connected to the internet?`,
      debugMessage: String(error),
    });
  }

  return errorResult({
    isPqlError: true,
    id: `b3162834`,
    type: `clientError`,
    debugMessage: `Unexpected error: ${error}`,
    showContactSupport: true,
  });
}
