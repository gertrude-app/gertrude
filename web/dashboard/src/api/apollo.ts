import {
  ApolloClient,
  InMemoryCache,
  createHttpLink,
  from,
  DocumentNode,
  TypedDocumentNode,
  NormalizedCacheObject,
} from '@apollo/client';
import { setContext } from '@apollo/client/link/context';
import { GraphQLError } from 'graphql';
import Result from './Result';
import Current from '../environment';

export { gql } from '@apollo/client';

function getClient(): ApolloClient<NormalizedCacheObject> {
  if (cachedClient) {
    return cachedClient;
  }

  const httpLink = createHttpLink({ uri: Current.env.graphQLEndpoint() });
  const authLink = setContext((_, { headers }) => {
    const token =
      Current.sessionStorage.getItem(`admin_token`) ??
      Current.localStorage.getItem(`admin_token`);
    return {
      headers: {
        ...headers,
        Authorization: token ? `Bearer ${token}` : ``,
      },
    };
  });

  const client = new ApolloClient({
    link: from([authLink, httpLink]),
    cache: new InMemoryCache(),
  });

  cachedClient = client;
  return client;
}

export async function query<Data, Vars>(
  mutation: DocumentNode | TypedDocumentNode<Data, Vars>,
  variables: Vars,
): Promise<Result<Data, readonly GraphQLError[]>>;

export async function query<Data>(
  mutation: DocumentNode | TypedDocumentNode<Data>,
  variables?: undefined,
): Promise<Result<Data, readonly GraphQLError[]>>;

export async function query<Data, Vars>(
  query: DocumentNode | TypedDocumentNode<Data, Vars>,
  variables: Vars | undefined = undefined,
): Promise<Result<Data, readonly GraphQLError[]>> {
  try {
    const { data, errors } = await getClient().query<Data, Vars>({ query, variables });
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
    const { data, errors } = await getClient().mutate<Data, Vars>({
      mutation,
      variables,
    });
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

let cachedClient: ApolloClient<NormalizedCacheObject> | null = null;
