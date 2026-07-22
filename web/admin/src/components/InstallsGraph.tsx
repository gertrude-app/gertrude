import React from 'react';
import TimeSeriesGraph, {
  type StatusConfig,
  type TimeSeriesGradient,
} from './TimeSeriesGraph';

interface Install {
  date: string;
  status: string;
  deviceType: string;
}

interface InstallsGraphProps {
  installs: Install[];
  gradient?: TimeSeriesGradient;
  statusConfig?: StatusConfig;
}

const defaultStatusConfig: StatusConfig = {
  isSuccess: (status) => status === `success`,
  isInfo: (status) => status === `supervised`,
  isWarning: () => false,
};

const InstallsGraph: React.FC<InstallsGraphProps> = ({
  installs,
  gradient = `blue`,
  statusConfig = defaultStatusConfig,
}) => {
  const items = installs.map((install) => ({
    date: install.date,
    status: install.status,
    label: install.deviceType,
  }));

  return (
    <TimeSeriesGraph
      items={items}
      itemLabel="install"
      gradient={gradient}
      statusConfig={statusConfig}
      twoColumnTooltip
    />
  );
};

export default InstallsGraph;
