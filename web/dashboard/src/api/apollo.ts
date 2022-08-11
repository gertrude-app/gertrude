import {
  ApolloClient,
  InMemoryCache,
  createHttpLink,
  from,
  DocumentNode,
  TypedDocumentNode,
} from '@apollo/client';
import { setContext } from '@apollo/client/link/context';
import { GraphQLError } from 'graphql';
import Result from './Result';

export { gql } from '@apollo/client';

const httpLink = createHttpLink({
  uri: import.meta.env.SNOWPACK_PUBLIC_GRAPHQL_ENDPOINT,
});

const authLink = setContext((_, { headers }) => {
  const token = localStorage.getItem(`token`);
  return {
    headers: {
      ...headers,
      authorization: token ? `Bearer ${token}` : ``,
    },
  };
});

const client = new ApolloClient({
  link: from([authLink, httpLink]),
  cache: new InMemoryCache(),
});

export async function mutate<Data, Vars>(
  mutation: DocumentNode | TypedDocumentNode<Data, Vars>,
  variables: Vars,
): Promise<Result<Data, readonly GraphQLError[]>>;

export async function mutate<Data>(
  mutation: DocumentNode | TypedDocumentNode<Data>,
  variables?: undefined,
): Promise<Result<Data, readonly GraphQLError[]>>;

export async function mutate<Data, Vars>(
  mutation: DocumentNode | TypedDocumentNode<Data, Vars>,
  variables: Vars | undefined = undefined,
): Promise<Result<Data, readonly GraphQLError[]>> {
  try {
    const { data, errors } = await client.mutate<Data, Vars>({ mutation, variables });
    if (errors) {
      return Result.error(errors);
    } else if (!data) {
      return Result.error([new GraphQLError(`No data returned`)]);
    } else {
      return Result.success(data);
    }
  } catch (error) {
    if (error instanceof GraphQLError) {
      return Result.error([error]);
    } else if (error instanceof Error) {
      return Result.error([new GraphQLError(error.message)]);
    } else {
      return Result.error([new GraphQLError(`${error}`)]);
    }
  }
}
