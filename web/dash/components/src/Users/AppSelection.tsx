import { Button } from '@shared/components';
import cx from 'classnames';
import React, { useEffect, useState } from 'react';
import type { TileTheme } from './AppGrid';
import { AppGridIcon, AppGridTile, ScrollableAppGrid, useToggleSet } from './AppGrid';

export interface AppSelectionItem {
  id: string;
  name: string;
  iconUrl?: string;
}

export const BLOCKED_TILE_THEME: TileTheme = {
  activeBorder: `border-red-400`,
  activeBg: `bg-red-50/60`,
  activeNameClass: `text-slate-400 line-through`,
  activeBadgeClass: `bg-red-500 text-white`,
  activeLabel: `Blocked`,
  activeIconClass: `grayscale opacity-40`,
  inactiveBadgeClass: `bg-slate-100 text-slate-400`,
  inactiveLabel: `Allowed`,
};

export const INTERNET_TILE_THEME: TileTheme = {
  activeBorder: `border-emerald-400`,
  activeBg: `bg-emerald-50/60`,
  activeNameClass: `text-emerald-700`,
  activeBadgeClass: `bg-emerald-500 text-white`,
  activeLabel: `Unrestricted internet`,
  inactiveBadgeClass: `bg-slate-100 text-slate-400`,
  inactiveLabel: `No internet`,
};

export const EnterTransition: React.FC<{
  animate: boolean;
  children: React.ReactNode;
}> = ({ animate, children }) => {
  const [shown, setShown] = useState(!animate);
  useEffect(() => {
    if (!animate) return;
    const raf = requestAnimationFrame(() => setShown(true));
    return () => cancelAnimationFrame(raf);
  }, [animate]);
  return (
    <div
      className={cx(
        `transition-[opacity,transform] duration-300 ease-out`,
        shown ? `opacity-100 translate-y-0` : `opacity-0 -translate-y-2`,
      )}
    >
      {children}
    </div>
  );
};

export const AppSelectionEmptyHint: React.FC<{
  text: string;
  cta: string;
  onClick(): void;
}> = ({ text, cta, onClick }) => (
  <div className="flex flex-col items-center justify-center p-8 bg-slate-50 mt-2 rounded-2xl border border-dashed border-slate-200">
    <p className="text-slate-500 text-sm">{text}</p>
    <button
      type="button"
      onClick={onClick}
      className="mt-3 text-sm font-semibold text-violet-600 hover:underline"
    >
      {cta}
    </button>
  </div>
);

export const AddAppsPanel: React.FC<{
  open: boolean;
  apps: AppSelectionItem[];
  theme: TileTheme;
  commitLabel: (n: number) => string;
  onCommit: (ids: string[]) => void;
  onCancel: () => void;
}> = ({ open, apps, theme, commitLabel, onCommit, onCancel }) => {
  const [selected, toggle, clear] = useToggleSet();
  if (!open) return null;
  return (
    <div className="mt-3 border border-slate-200 rounded-2xl bg-slate-50 sm:overflow-hidden">
      {apps.length === 0 ? (
        <div className="px-4 py-10 text-center text-sm text-slate-400">
          No other apps to choose from.
        </div>
      ) : (
        <div className="flex flex-col sm:h-80">
          <ScrollableAppGrid>
            {apps.map((app) => (
              <AppGridTile
                key={app.id}
                id={app.id}
                name={app.name}
                icon={<AppGridIcon name={app.name} iconUrl={app.iconUrl} />}
                active={selected.has(app.id)}
                theme={theme}
                onToggle={toggle}
              />
            ))}
          </ScrollableAppGrid>
        </div>
      )}
      <div className="sticky bottom-0 sm:static z-10 flex items-center justify-between px-4 py-3 border-t border-slate-200 bg-white rounded-b-2xl sm:rounded-b-none shadow-[0_-8px_16px_-12px_rgba(15,23,42,0.18)]">
        <span className="text-sm text-slate-400">
          {selected.size > 0
            ? `${selected.size} selected`
            : `${apps.length} app${apps.length === 1 ? `` : `s`} available`}
        </span>
        <div className="flex items-center gap-4">
          <button
            type="button"
            onClick={() => {
              clear();
              onCancel();
            }}
            className="text-sm font-medium text-slate-500 hover:text-slate-700 transition-colors"
          >
            Cancel
          </button>
          <Button
            type="button"
            color="primary"
            size="small"
            disabled={selected.size === 0}
            onClick={() => {
              onCommit([...selected]);
              clear();
            }}
          >
            {commitLabel(selected.size)}
          </Button>
        </div>
      </div>
    </div>
  );
};

export const UnrestrictedAppCard: React.FC<{
  name: string;
  iconUrl?: string;
  onDelete?(): void;
  keychainName?: string;
  blocked?: boolean;
}> = ({ name, iconUrl, onDelete, keychainName, blocked }) => (
  <div className="p-2.5 border border-slate-200 bg-white rounded-xl flex items-center gap-3">
    <div className="w-8 h-8 rounded-md overflow-hidden shrink-0">
      <AppGridIcon name={name} iconUrl={iconUrl} />
    </div>
    <span className="font-semibold text-slate-600 truncate flex-grow min-w-0">
      {name}
    </span>
    {blocked ? (
      <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded-full bg-amber-100 text-amber-700 shrink-0">
        Blocked — no effect
      </span>
    ) : (
      <span className="text-[10px] font-semibold px-1.5 py-0.5 rounded-full bg-emerald-100 text-emerald-600 shrink-0">
        Unrestricted internet
      </span>
    )}
    {keychainName ? (
      <span
        title={`Granted by the “${keychainName}” keychain`}
        className="flex items-center gap-1.5 text-[10px] font-medium text-slate-400 shrink-0"
      >
        <i className="fa-solid fa-lock" />
        {keychainName}
      </span>
    ) : onDelete ? (
      <button
        type="button"
        onClick={onDelete}
        className="w-7 h-7 flex justify-center items-center rounded-full text-slate-400 hover:bg-slate-100 hover:text-red-500 transition-colors shrink-0"
      >
        <i className="fa-solid fa-trash text-sm" />
      </button>
    ) : null}
  </div>
);
