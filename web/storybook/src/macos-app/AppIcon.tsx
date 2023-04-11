import React from 'react';
import { Logo } from '@shared/components';

const AppIcon: React.FC = () => (
  <div className="p-6 rounded-[40px] bg-white shadow-lg flex flex-col justify-center items-center">
    <Logo iconOnly size={200} className="" />
  </div>
);

export default AppIcon;
