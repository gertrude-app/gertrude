import React from 'react';
import TimeSeriesGraph from './TimeSeriesGraph';

interface Install {
  date: string;
  deviceType: string;
  status: string;
}

interface PodcastInstallsGraphProps {
  installs: Install[];
}

const PodcastInstallsGraph: React.FC<PodcastInstallsGraphProps> = ({ installs }) => {
  const items = installs.map((install) => ({
    date: install.date,
    status: install.status,
    label: install.deviceType,
  }));

  return (
    <TimeSeriesGraph
      items={items}
      itemLabel="install"
      gradient="green"
      statusConfig={{
        isSuccess: (status) => status === `paid`,
        isWarning: (status) => status === `connected`,
      }}
      twoColumnTooltip
    />
  );
};

export default PodcastInstallsGraph;
