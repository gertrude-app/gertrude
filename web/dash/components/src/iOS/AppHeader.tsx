import React from 'react';
import type { GertrudeIOSApp } from '../gertrudeApps';
import { APP_META } from '../gertrudeApps';

const AppHeader: React.FC<{ app: GertrudeIOSApp }> = ({ app }) => {
  const { name, iconSrc } = APP_META[app];
  return (
    <div className="flex items-center gap-3 pb-3 border-b border-slate-200">
      <img src={iconSrc} alt="" className="w-9 h-9 rounded-lg shadow-sm shrink-0" />
      <h2 className="text-xl font-bold text-slate-800">{name}</h2>
    </div>
  );
};

export default AppHeader;
