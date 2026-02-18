import { Button } from '@shared/components';
import React from 'react';
import type { DashboardWidgets_v2 } from '@dash/types';
import ChildDeviceCard from './ChildDeviceCard';
import DashboardWidget from './DashboardWidget';
import WidgetTitle from './WidgetTitle';

type Props = {
  className?: string;
  children: DashboardWidgets_v2.Output[`children`];
};

const ChildrenDevicesWidget: React.FC<Props> = ({ className, children }) => {
  if (children.length === 0) return null;
  return (
    <DashboardWidget className={className}>
      <div className="flex items-center justify-between mb-3 sm:mb-4">
        <WidgetTitle icon="users" text="Children" className="!mb-0" />
        <Button type="link" to="/children" size="small" color="tertiary">
          All children
        </Button>
      </div>
      <div className="flex flex-col divide-y divide-slate-100">
        {children.map((child) => (
          <ChildDeviceCard key={child.id} {...child} />
        ))}
      </div>
    </DashboardWidget>
  );
};

export default ChildrenDevicesWidget;
