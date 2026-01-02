import React from 'react';
import TimeSeriesGraph from './TimeSeriesGraph';

interface Install {
  date: string;
  deviceType: string;
  isPaid: boolean;
}

interface PodcastInstallsGraphProps {
  installs: Install[];
}

const PodcastInstallsGraph: React.FC<PodcastInstallsGraphProps> = ({ installs }) => {
  const items = installs.map((install) => ({
    date: install.date,
    status: install.isPaid ? `paid` : `free`,
    label: install.deviceType,
  }));

  return (
    <TimeSeriesGraph
      items={items}
      itemLabel="install"
      gradient="green"
      statusConfig={{
        isSuccess: (status) => status === `paid`,
        isWarning: () => false,
      }}
      twoColumnTooltip
    />
  );
};

export default PodcastInstallsGraph;
