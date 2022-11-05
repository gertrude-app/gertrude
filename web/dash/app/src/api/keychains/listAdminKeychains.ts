import Result from '../Result';
import { Keychain, KeyRecord, Key } from '@dash/keys';
import * as T from './__generated__/ListAdminKeychains';
import { gql, query } from '../apollo';

export async function listAdminKeychains(): Promise<
  Result<[Keychain[], KeyRecord[]], ApiError>
> {
  const result = await query<T.ListAdminKeychains>(QUERY);
  return result.mapApi((data) => [
    data.keychains.map(mapKeychain),
    data.keychains.flatMap((keychain) =>
      keychain.keyRecords.map((keyRecord) => ({
        id: keyRecord.id,
        keychainId: keychain.id,
        key: keyRecord.key.data as Key,
      })),
    ),
  ]);
}

export const SINGLE_APP_SCOPE_FIELDS = gql`
  fragment SingleAppScopeFields on AppScopeSingleData {
    ... on IdentifiedAppData {
      type
      identifiedAppSlug
    }
    ... on BundleIdData {
      type
      bundleId
    }
  }
`;

export const APP_SCOPE_FIELDS = gql`
  ${SINGLE_APP_SCOPE_FIELDS}
  fragment AppScopeFields on AppScopeData {
    ... on WebBrowsersData {
      type
    }
    ... on UnrestrictedData {
      type
    }
    ... on SingleData {
      type
      single {
        ...SingleAppScopeFields
      }
    }
  }
`;

export const KEYCHAIN_FIELDS = gql`
  ${APP_SCOPE_FIELDS}
  fragment KeychainFields on Keychain {
    id
    name
    description
    isPublic
    authorId
    keyRecords: keys {
      id
      comment
      expiration: deletedAt
      key {
        jsonString
        data {
          ... on DomainData {
            domain
            type
            scope {
              ...AppScopeFields
            }
          }
          ... on SkeletonData {
            type
            scope {
              ...SingleAppScopeFields
            }
          }
          ... on DomainRegexData {
            type
            pattern
            scope {
              ...AppScopeFields
            }
          }
          ... on AnySubdomainData {
            type
            domain
            scope {
              ...AppScopeFields
            }
          }
          ... on PathData {
            type
            path
            scope {
              ...AppScopeFields
            }
          }
          ... on IpAddressData {
            type
            ipAddress
            scope {
              ...AppScopeFields
            }
          }
        }
      }
    }
  }
`;

// mutation

const QUERY = gql`
  ${KEYCHAIN_FIELDS}
  query ListAdminKeychains {
    keychains: getAdminKeychains {
      ...KeychainFields
    }
  }
`;

export function mapKeychain(
  keychain: Omit<T.ListAdminKeychains['keychains'][0], 'keyRecords'> & {
    keyRecords: Array<{ id: UUID }>;
  },
): Keychain {
  return {
    id: keychain.id,
    name: keychain.name,
    description: keychain.description,
    isPublic: keychain.isPublic,
    authorId: keychain.authorId,
    numKeys: keychain.keyRecords.length,
  };
}
