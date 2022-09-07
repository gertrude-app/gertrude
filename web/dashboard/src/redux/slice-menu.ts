import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface MenuState {
  mobileSidebarOpen: boolean;
  desktopSidebarCollapsed: boolean;
  windowWidth: number;
}

export function initialState(): MenuState {
  return {
    mobileSidebarOpen: false,
    desktopSidebarCollapsed: false,
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
});

export const {
  hamburgerMenuClicked,
  mobileSidebarClosed,
  desktopSidebarCollapsedToggled,
  windowWidthChanged,
  menuInternalLinkClicked,
} = slice.actions;

export default slice.reducer;
