import React from 'react';

interface Props {
  title?: string;
  children: React.ReactNode;
}

const SidebarSection: React.FC<Props> = ({ title, children }) => {
  return (
    <div className="flex flex-col gap-2.5">
      <span className="text-xs font-medium text-stone-500 select-none">{title}</span>
      <div className="flex flex-col">{children}</div>
    </div>
  );
};

export default SidebarSection;
