import { useLocation, useNavigate, useRouter } from '@tanstack/react-router';
import React from 'react';
import { normalizePath } from './utils';

export interface RouteOpenStateOptions {
  path?: string;
  closeTo?: string;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
}

export interface RouteOpenState {
  open: boolean | undefined;
  routed: boolean;
  setOpen: (open: boolean) => void;
}

const parentPath = (path: string): string =>
  path.split(`/`).slice(0, -1).join(`/`) || `/`;

const isWithinPath = (pathname: string, path: string): boolean => {
  const current = normalizePath(pathname);
  return current === path || current.startsWith(`${path}/`);
};

export const useRouteOpenState = ({
  path,
  closeTo,
  open,
  onOpenChange,
}: RouteOpenStateOptions): RouteOpenState => {
  const { pathname } = useLocation();
  const router = useRouter();
  const navigate = useNavigate();
  const openedInApp = React.useRef(false);
  const openPath = path === undefined ? undefined : normalizePath(path);

  if (openPath === undefined) {
    return { open, routed: false, setOpen: (next) => onOpenChange?.(next) };
  }

  const closePath = normalizePath(closeTo ?? parentPath(openPath));
  return {
    open: isWithinPath(pathname, openPath),
    routed: true,
    setOpen: (next) => {
      const currentlyOpen = isWithinPath(router.state.location.pathname, openPath);
      if (next && !currentlyOpen) {
        openedInApp.current = true;
        void navigate({ to: openPath, resetScroll: false });
      }
      if (!next && currentlyOpen) {
        if (openedInApp.current) {
          openedInApp.current = false;
          router.history.back();
        } else {
          void navigate({ to: closePath, replace: true, resetScroll: false });
        }
      }
      onOpenChange?.(next);
    },
  };
};
