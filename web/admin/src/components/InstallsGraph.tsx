import React from 'react';
import TimeSeriesGraph from './TimeSeriesGraph';

interface Install {
  date: string;
  status: string;
  deviceType: string;
}

interface InstallsGraphProps {
  installs: Install[];
}

const InstallsGraph: React.FC<InstallsGraphProps> = ({ installs }) => {
  const items = installs.map((install) => ({
    date: install.date,
    status: install.status,
    label: install.deviceType,
  }));

  return (
    <TimeSeriesGraph
      items={items}
      itemLabel="install"
      gradient="blue"
      statusConfig={{
        isSuccess: (status) => status === `success`,
        isInfo: (status) => status === `supervised`,
        isWarning: () => false,
      }}
      twoColumnTooltip
    />
  );
};

export default InstallsGraph;
