import type { CyHttpMessages } from 'cypress/types/net-stubbing';

export function hasOperationName(
  req: CyHttpMessages.IncomingRequest,
  operationName: string,
): boolean {
  const body: Record<string, unknown> | undefined = req.body;
  if (!body) {
    return false;
  }
  return body.operationName === operationName;
}

export function aliasOperation(
  req: CyHttpMessages.IncomingRequest,
  operationName: string,
): void {
  if (hasOperationName(req, operationName)) {
    req.alias = operationName;
  }
}
