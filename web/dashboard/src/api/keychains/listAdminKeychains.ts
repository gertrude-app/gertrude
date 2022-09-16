import Result from '../Result';
import * as T from './__generated__/ListAdminKeychains';
import { gql, query } from '../apollo';
import { toMap } from '../../redux/helpers';

export function mapKeychain(keychain: T.ListAdminKeychains['keychains'][0]): Keychain {
  return {
    id: keychain.id,
    name: keychain.name,
    description: keychain.description,
    isPublic: keychain.isPublic,
    authorId: keychain.authorId,
    keyRecords: toMap(
      keychain.keyRecords.map((keyRecord) => ({
        id: keyRecord.id,
        key: keyRecord.key.data as Key,
      })),
    ),
  };
}

export async function listAdminKeychains(): Promise<Result<Keychain[], ApiError>> {
  const result = await query<T.ListAdminKeychains>(QUERY);
  return result.mapApi((data) => data.keychains.map(mapKeychain));
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
