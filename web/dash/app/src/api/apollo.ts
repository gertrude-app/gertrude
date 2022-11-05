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
import Current from '../environment';
import Result from './Result';

export { gql } from '@apollo/client';

function getClient(): ApolloClient<NormalizedCacheObject> {
  if (cachedClient) {
    return cachedClient;
  }

  const httpLink = createHttpLink({ uri: Current.env.graphQLEndpoint() });
  const authLink = setContext((_, { headers }) => {
    const token =
      Current.localStorage.getItem(`admin_token`) ??
      Current.sessionStorage.getItem(`admin_token`);
    return {
      headers: {
        ...headers,
        Authorization: token ? `Bearer ${token}` : ``,
        ...(Current.env.isProd() ? {} : { 'X-Dashboard-Url': window.location.origin }),
      },
    };
  });

  const client = new ApolloClient({
    link: from([authLink, httpLink]),
    cache: new InMemoryCache({
      // @see https://github.com/apollographql/apollo-client/issues/7050
      // @see https://www.apollographql.com/docs/react/data/fragments/#using-fragments-with-unions-and-interfaces
      possibleTypes: {
        AppScopeData: [`WebBrowsersData`, `UnrestrictedData`, `SingleData`],
        AppScopeSingleData: [`IdentifiedAppData`, `BundleIdData`],
      },
    }),
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
    var { data, errors } = await getClient().query<Data, Vars>({ query, variables });
    if (errors) {
      return Result.error(errors);
    } else if (!data) {
      return Result.error([new GraphQLError(`No data returned`)]);
    } else {
      // in dev mode, apollo freezes it's objects, so you can't sort or otherwise mutate
      if (import.meta.env.MODE === `development`) {
        data = JSON.parse(JSON.stringify(data));
      }
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
    var { data, errors } = await getClient().mutate<Data, Vars>({
      mutation,
      variables,
    });
    if (errors) {
      return Result.error(errors);
    } else if (!data) {
      return Result.error([new GraphQLError(`No data returned`)]);
    } else {
      // in dev mode, apollo freezes it's objects, so you can't sort or otherwise mutate
      if (import.meta.env.MODE === `development`) {
        data = JSON.parse(JSON.stringify(data)) as Data;
      }
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
