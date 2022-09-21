import React from 'react';
import { UndoMainPadding } from '../../Chrome/Chrome';
import DashboardWidget from '../DashboardWidget';

type Props = {
  className?: string;
};

const WidgetsContainer: React.FC<Props> = ({ className }) => (
  <UndoMainPadding className="min-h-screen grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 lg:gap-6 xl:gap-8 p-6 md:p-10 border border-green-500">
    <DashboardWidget>1</DashboardWidget>
    <DashboardWidget>2</DashboardWidget>
    <DashboardWidget className="row-span-2">3</DashboardWidget>
    <DashboardWidget>4</DashboardWidget>
    <DashboardWidget>5</DashboardWidget>
  </UndoMainPadding>
);

export default WidgetsContainer;
