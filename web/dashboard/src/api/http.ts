import Result from './Result';

type GQLError = {
  statusCode: number;
  messages: string[];
};

export async function query<Data, Vars = undefined>(input: {
  query: string;
  variables: Vars;
}): Promise<Result<Data, GQLError>> {
  return await send<Data, Vars>(input.query, input.variables);
}

export async function mutate<Data, Vars>(
  mutation: string,
  variables: Vars,
): Promise<Result<Data, GQLError>>;

export async function mutate<Data>(
  mutation: string,
  variables?: undefined,
): Promise<Result<Data, GQLError>>;

export async function mutate<Data, Vars>(
  mutation: string,
  variables: Vars | undefined = undefined,
): Promise<Result<Data, GQLError>> {
  return query({ query: mutation, variables: variables });
}

async function send<Data, Vars>(
  operation: string,
  variables: Vars,
): Promise<Result<Data, GQLError>> {
  try {
    const endpoint = import.meta.env.SNOWPACK_PUBLIC_GRAPHQL_ENDPOINT;
    const response = await window.fetch(endpoint, {
      method: `POST`,
      headers: { 'Content-Type': `application/json` },
      body: JSON.stringify({
        query: operation,
        ...(variables ? { variables } : {}),
      }),
    });

    const json = await response.json();
    if (`data` in json && `errors` in json === false) {
      return Result.success(json.data);
    }

    if (`errors` in json && Array.isArray(json.errors)) {
      return Result.error({
        statusCode: response.status,
        messages: json.errors,
      });
    }

    return Result.error({
      statusCode: response.status,
      messages: [`Unexpected error`],
    });
  } catch (error) {
    return Result.error({ statusCode: 599, messages: [`Caught error: ${error}`] });
  }
}
