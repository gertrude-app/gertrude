import React from 'react';

interface Props {
  children: React.ReactNode;
  logoUrl: string;
}

const Sidebar: React.FC<Props> = ({ children, logoUrl }) => {
  return (
    <div className="sticky top-0 flex h-screen w-68 shrink-0 flex-col gap-9 overflow-y-auto border-r border-stone-200 bg-stone-50 p-5">
      <div>
        <img src={logoUrl} alt="Logo" className="h-9" />
      </div>
      <div className="flex flex-col gap-7">{children}</div>
    </div>
  );
};

export default Sidebar;
