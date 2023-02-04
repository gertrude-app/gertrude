import React from 'react';
import { Logo } from '@shared/components';

interface Props {}

const AppIcon: React.FC<Props> = ({}) => {
  return (
    <div className="p-6 rounded-[40px] bg-white shadow-lg flex flex-col justify-center items-center">
      <Logo iconOnly size={180} className="" />
    </div>
  );
};

export default AppIcon;
