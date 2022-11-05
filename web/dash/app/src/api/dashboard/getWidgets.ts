import type { DashboardWidgetData } from '@dash/types';
import type Result from '../Result';
import type * as T from './__generated__/GetWidgets';
import { gql, query } from '../apollo';

export async function getWidgets(): Promise<Result<DashboardWidgetData, ApiError>> {
  const result = await query<T.GetWidgets>(QUERY);
  return result.mapApi((data) => data.widgets);
}

const QUERY = gql`
  query GetWidgets {
    widgets: getAdminDashboardWidgetData {
      users {
        id: userId
        isOnline
        name: userName
      }
      userActivity: userActivitySummaries {
        id
        userName: name
        numUnreviewed
      }
      unlockRequests {
        id
        target
        comment
        createdAt
        userName
      }
      userScreenshots: recentScreenshots {
        id
        url
        userName
        createdAt
      }
    }
  }
`;
