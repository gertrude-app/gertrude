import { ApiErrorMessage, Loading, SecurityEventsFeed } from '@dash/components';
import { useEffect, useState } from 'react';
import type { IpLocation } from '@dash/components';
import Current from '../../environment';
import { Key, useQuery } from '../../hooks';

const SecurityEventsFeedRoute: React.FC = () => {
  const getFeed = useQuery(Key.securityEventsFeed, Current.api.securityEventsFeed);
  const [locations, setLocations] = useState<Record<string, IpLocation>>({});

  useEffect(() => {
    if (!getFeed.data) return;

    const ips = new Set<string>();
    for (const event of getFeed.data) {
      if (event.case === `admin` && event.ipAddress) {
        ips.add(event.ipAddress);
      }
    }

    for (const ip of ips) {
      getLocation(ip).then((loc) => {
        if (loc) {
          setLocations((prev) => ({ ...prev, [ip]: loc }));
        }
      });
    }
  }, [getFeed.data]);

  if (getFeed.isPending) {
    return <Loading />;
  }

  if (getFeed.isError) {
    return <ApiErrorMessage error={getFeed.error} />;
  }

  return <SecurityEventsFeed events={getFeed.data} locations={locations} />;
};

export default SecurityEventsFeedRoute;

const locationCache: Record<string, Promise<IpLocation | null>> = {};

function getLocation(ip: string): Promise<IpLocation | null> {
  if (!locationCache[ip]) {
    locationCache[ip] = fetch(`https://ipapi.co/${ip}/json/`)
      .then((res) => res.json())
      .then((data) =>
        data.city
          ? { city: data.city, region: data.region, countryCode: data.country_code }
          : null,
      )
      .catch(() => null);
  }
  return locationCache[ip];
}
