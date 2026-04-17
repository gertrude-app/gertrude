import cx from 'classnames';
import React, { useCallback, useState } from 'react';
import type { DiscoveredApp } from '../onboarding-store';

export function useToggleSet(): [Set<string>, (id: string) => void] {
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
  return [ids, toggle];
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

export const AppIcon: React.FC<{
  app: DiscoveredApp;
  className?: string;
}> = ({ app, className }) =>
  app.iconPath ? (
    <img
      src={
        app.iconPath.startsWith(`data:`)
          ? app.iconPath
          : app.iconPath.startsWith(`/`)
            ? `file://${app.iconPath}`
            : app.iconPath
      }
      alt={app.name}
      className={cx(`w-full h-full`, className)}
    />
  ) : (
    <div className="w-full h-full bg-gradient-to-br from-slate-200 to-slate-300 flex items-center justify-center">
      <span className="text-slate-500 text-lg font-bold">{app.name.charAt(0)}</span>
    </div>
  );

export const Tile: React.FC<{
  id: string;
  name: string;
  icon: React.ReactNode;
  active: boolean;
  theme: TileTheme;
  onToggle: (id: string) => void;
}> = ({ id, name, icon, active, theme, onToggle }) => (
  <button
    key={id}
    onClick={() => onToggle(id)}
    tabIndex={-1}
    className={cx(
      `relative flex flex-row items-start gap-3 p-2.5 rounded-xl transition-all duration-150 cursor-pointer border-2`,
      active
        ? `${theme.activeBorder} ${theme.activeBg}`
        : `border-slate-200/70 hover:border-slate-300`,
    )}
  >
    <div
      className={cx(
        `w-14 h-14 rounded-xl overflow-hidden flex-shrink-0 shadow-sm`,
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
}> = ({ children }) => {
  const [showScrollHint, setShowScrollHint] = useState(true);

  const handleScroll = useCallback(() => {
    setShowScrollHint(false);
  }, []);

  return (
    <div className="relative flex-1 min-w-0">
      <div
        className={cx(
          `absolute bottom-2 left-0 right-0 flex justify-center pointer-events-none z-10 transition-opacity duration-300`,
          showScrollHint ? `opacity-100` : `opacity-0`,
        )}
      >
        <div className="bg-white/90 backdrop-blur-sm shadow-md rounded-full px-3 py-1 flex items-center gap-1.5 text-xs text-slate-500 font-medium">
          <i className="fa-solid fa-chevron-down text-[10px] animate-bounce" />
          Scroll for more
        </div>
      </div>
      <div
        onScroll={handleScroll}
        className="h-full overflow-y-auto p-3 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
      >
        <div className="grid grid-cols-2 gap-2">{children}</div>
        <div className="h-14 flex-shrink-0" />
      </div>
    </div>
  );
};
