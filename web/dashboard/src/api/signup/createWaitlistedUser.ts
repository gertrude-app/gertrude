import Result from '../Result';
import { mutate } from '../http';
import gql from '../gql';

export namespace CreateWaitlistedUser {
  export type Vars = { input: { email: string } };
  export type Data = { id: string };
}

export async function createWaitlistedUser(
  email: string,
): Promise<Result<CreateWaitlistedUser.Data, void>> {
  const result = await mutate<CreateWaitlistedUser.Data, CreateWaitlistedUser.Vars>(
    MUTATION,
    { input: { email } },
  );

  return result.mapErrorToVoid();
}

// mutation

const MUTATION = gql`
  mutation CreateWaitlistedUser($input: CreateWaitlistedUserInput!) {
    createWaitlistedUser(input: $input) {
      email
    }
  }
`;
