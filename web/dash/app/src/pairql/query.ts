import type { ClientAuth } from './shared';
import Result from '../lib/Result';

export async function pqlQuery<Input, Output>(
  input: Input,
  auth: ClientAuth,
  operation: string,
): Promise<Result<Output, string>> {
  try {
    const res = await fetch(`/gertieql/dashboard/${operation}`, {
      method: `POST`,
      headers: {
        'Content-Type': `application/json`,
        'X-AdminToken': `not-real-lol`,
      },
    });
    const json = await res.json();
    return Result.success(json);
  } catch (error) {
    return Result.error(`${error}`);
  }
}
