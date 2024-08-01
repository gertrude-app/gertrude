import { ApiErrorMessage, Loading } from '@dash/components';
import { Key, useQuery } from '../../hooks';
import Current from '../../environment';

const SecurityEventsFeed: React.FC = () => {
  const getFeed = useQuery(Key.securityEventsFeed, Current.api.securityEventsFeed);

  if (getFeed.isPending) {
    return <Loading />;
  }

  if (getFeed.isError) {
    return <ApiErrorMessage error={getFeed.error} />;
  }

  const feed = getFeed.data;

  return (
    <pre>
      <code>{JSON.stringify(feed, null, 2)}</code>
    </pre>
  );
};

export default SecurityEventsFeed;
