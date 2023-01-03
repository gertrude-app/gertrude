import { Result } from '@dash/types';
import type { ClientAuth } from '@dash/types';

export async function query<Input, Output>(
  input: Input,
  auth: ClientAuth,
  operation: string,
): Promise<Result<Output>> {
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
    return Result.error(`${error}` as any); // TODO: error handling for real
  }
}
