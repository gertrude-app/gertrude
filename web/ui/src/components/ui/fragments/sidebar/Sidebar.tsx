import React from 'react';

interface Props {
  children: React.ReactNode;
  logoUrl: string;
}

const Sidebar: React.FC<Props> = ({ children, logoUrl }) => {
  return (
    <div className="w-64 shrink-0 bg-stone-50 border-r border-stone-200 flex flex-col p-4 gap-8">
      <div>
        <img src={logoUrl} alt="Logo" className="h-8" />
      </div>
      <div className="flex flex-col gap-6">{children}</div>
    </div>
  );
};

export default Sidebar;
