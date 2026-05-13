import React from 'react';

interface Props {
  children: React.ReactNode;
  logoUrl: string;
}

const Sidebar: React.FC<Props> = ({ children, logoUrl }) => {
  return (
    <div className="w-68 shrink-0 bg-stone-50 border-r border-stone-200 flex flex-col p-5 gap-9">
      <div>
        <img src={logoUrl} alt="Logo" className="h-9" />
      </div>
      <div className="flex flex-col gap-7">{children}</div>
    </div>
  );
};

export default Sidebar;
