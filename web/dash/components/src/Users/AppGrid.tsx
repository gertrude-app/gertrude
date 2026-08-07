import cx from 'classnames';
import React, { useCallback, useState } from 'react';

export function useToggleSet(): [Set<string>, (id: string) => void, () => void] {
  const [ids, setIds] = useState<Set<string>>(new Set());
  const toggle = useCallback((id: string): void => {
    setIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }, []);
  const clear = useCallback((): void => setIds(new Set()), []);
  return [ids, toggle, clear];
}

export interface TileTheme {
  activeBorder: string;
  activeBg: string;
  activeNameClass: string;
  activeBadgeClass: string;
  activeLabel: string;
  activeIconClass?: string;
  inactiveBadgeClass: string;
  inactiveLabel: string;
}

export const AppGridIcon: React.FC<{
  name: string;
  iconUrl?: string;
  className?: string;
}> = ({ name, iconUrl, className }) =>
  iconUrl ? (
    <img
      src={iconUrl}
      alt={name}
      className={cx(`w-full h-full object-contain`, className)}
    />
  ) : (
    <div className="w-full h-full bg-gradient-to-br from-slate-200 to-slate-300 flex items-center justify-center">
      <span className="text-slate-500 text-lg font-bold">
        {name.charAt(0).toUpperCase()}
      </span>
    </div>
  );

export const AppGridTile: React.FC<{
  id: string;
  name: string;
  icon: React.ReactNode;
  active: boolean;
  theme: TileTheme;
  onToggle: (id: string) => void;
}> = ({ id, name, icon, active, theme, onToggle }) => (
  <button
    type="button"
    onClick={() => onToggle(id)}
    className={cx(
      `relative flex flex-row items-start gap-3 p-2.5 rounded-xl transition-all duration-150 cursor-pointer border-2 text-left`,
      active
        ? `${theme.activeBorder} ${theme.activeBg}`
        : `bg-white border-slate-200/70 shadow-sm hover:border-slate-300 hover:shadow-md hover:-translate-y-0.5`,
    )}
  >
    <div
      className={cx(
        `w-14 h-14 rounded-xl overflow-hidden flex-shrink-0 shadow-sm ring-1 ring-black/5`,
        active && theme.activeIconClass,
      )}
    >
      {icon}
    </div>
    <div className="flex flex-col items-start min-w-0 mt-1">
      <span
        className={cx(
          `text-sm font-medium leading-none line-clamp-2 text-left`,
          active ? theme.activeNameClass : `text-slate-700`,
        )}
      >
        {name}
      </span>
      <span
        className={cx(
          `mt-1.5 text-[10px] font-semibold px-1.5 py-0.5 rounded-full`,
          active ? theme.activeBadgeClass : theme.inactiveBadgeClass,
        )}
      >
        {active ? theme.activeLabel : theme.inactiveLabel}
      </span>
    </div>
  </button>
);

export const ScrollableAppGrid: React.FC<{
  children: React.ReactNode;
}> = ({ children }) => (
  <div className="relative min-w-0 sm:flex-1 sm:min-h-0">
    <div className="p-3 sm:h-full sm:overflow-y-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">{children}</div>
      <div className="hidden sm:block h-4 flex-shrink-0" />
    </div>
  </div>
);
