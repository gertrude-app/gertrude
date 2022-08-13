import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import * as api from '../api';

export interface WaitlistState {
  email: string;
  requestState: RequestState;
}

const initialState: WaitlistState = {
  email: ``,
  requestState: `idle`,
};

export const slice = createSlice({
  name: `waitlist`,
  initialState,
  reducers: {
    emailUpdated: (state, action: PayloadAction<string>) => {
      state.email = action.payload;
    },
    requestStateUpdated: (state, action: PayloadAction<RequestState>) => {
      state.requestState = action.payload;
    },
  },
  extraReducers(builder) {
    builder.addCase(joinWaitlist.pending, (state) => {
      state.requestState = `ongoing`;
    });
    builder.addCase(joinWaitlist.fulfilled, (state, action) => {
      state.requestState = action.payload ? `succeeded` : `failed`;
    });
    builder.addCase(joinWaitlist.rejected, (state) => {
      state.requestState = `failed`;
    });
  },
});

export const joinWaitlist = createAsyncThunk(
  `${slice.name}/join`,
  async (email: string) => {
    const result = await api.signup.createWaitlistedUser(email);
    return result.value ?? false;
  },
);

export const { emailUpdated, requestStateUpdated } = slice.actions;

export default slice.reducer;
