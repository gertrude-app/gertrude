import { createSlice } from '@reduxjs/toolkit';
import type { PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';
import { logoutRouteVisited } from './slice-auth';

export interface MenuState {
  mobileSidebarOpen: boolean;
  desktopSidebarCollapsed: boolean;
  windowWidth: number;
}

export function initialState(): MenuState {
  return {
    mobileSidebarOpen: false,
    desktopSidebarCollapsed:
      !import.meta.env.VITEST &&
      Current.localStorage.getItem(`desktop_sidebar_collapsed`) === `true`,
    windowWidth: typeof window !== `undefined` ? window.innerWidth : 0,
  };
}

export const slice = createSlice({
  name: `menu`,
  initialState,
  reducers: {
    hamburgerMenuClicked: (state) => {
      state.mobileSidebarOpen = true;
    },
    mobileSidebarClosed: (state) => {
      state.mobileSidebarOpen = false;
    },
    menuInternalLinkClicked: (state) => {
      state.mobileSidebarOpen = false;
    },
    desktopSidebarCollapsedToggled: (state) => {
      state.desktopSidebarCollapsed = !state.desktopSidebarCollapsed;
    },
    windowWidthChanged: (state, action: PayloadAction<number>) => {
      state.windowWidth = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(logoutRouteVisited, () => {
      return initialState();
    });
  },
});

export const {
  hamburgerMenuClicked,
  mobileSidebarClosed,
  desktopSidebarCollapsedToggled,
  windowWidthChanged,
  menuInternalLinkClicked,
} = slice.actions;

export default slice.reducer;
