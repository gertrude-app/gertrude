import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface MenuState {
  mobileSidebarOpen: boolean;
  desktopSidebarCollapsed: boolean;
  windowWidth: number;
}

const initialState: MenuState = {
  mobileSidebarOpen: false,
  desktopSidebarCollapsed: false,
  windowWidth: window.innerWidth,
};

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
} = slice.actions;

export default slice.reducer;
