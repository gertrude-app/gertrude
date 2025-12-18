const TYPES = [
  `notFound`,
  `badRequest`,
  `serverError`,
  `unauthorized`,
  `loggedOut`,
  `clientError`,
  `other`,
] as const;
export type PqlErrorType = (typeof TYPES)[number];

export interface ServerPqlError {
  id: string;
  requestId?: string;
  type: Exclude<PqlErrorType, `clientError`>;
  debugMessage?: string;
  userMessage?: string;
  userAction?: string;
  entityName?: string;
  dashboardTag?: string;
  appTag?: string;
  showContactSupport?: boolean;
  statusCode?: number;
  version?: string;
}

export interface PqlError {
  isPqlError: true;
  id: string;
  type: PqlErrorType;
  debugMessage: string;
  userMessage?: string;
  userAction?: string;
  entityName?: string;
  tag?: string;
  showContactSupport?: boolean;
  serverRequestId?: string;
  clientRequestId?: string;
}

export function isPqlError(input: unknown): input is PqlError {
  if (typeof input !== `object` || input === null) {
    return false;
  }
  const object = input as Record<string, unknown>;
  if (object.isPqlError !== true) {
    return false;
  }
  if (typeof object.id !== `string`) {
    return false;
  }
  if (typeof object.type !== `string`) {
    return false;
  }
  return TYPES.includes(object.type as PqlErrorType);
}

export function toClientError(serverError: ServerPqlError): PqlError {
  return {
    isPqlError: true,
    id: serverError.id,
    type: serverError.type,
    serverRequestId: serverError.requestId,
    userMessage: serverError.userMessage,
    userAction: serverError.userAction,
    debugMessage: serverError.debugMessage ?? `[no debug message]`,
    entityName: serverError.entityName,
    tag: serverError.dashboardTag,
    showContactSupport: serverError.showContactSupport,
  };
}

export function ensurePqlError(error: unknown): PqlError {
  if (isPqlError(error)) {
    return error;
  }
  return {
    isPqlError: true,
    id: `59b169c4`,
    type: `clientError`,
    debugMessage: `Unexpected non-pql error: ${error}`,
    showContactSupport: true,
  };
}
