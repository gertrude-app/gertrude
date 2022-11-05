import { DashboardWidgetData } from '@dash/types';
import Result from '../Result';
import { gql, query } from '../apollo';
import * as T from './__generated__/GetWidgets';

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
