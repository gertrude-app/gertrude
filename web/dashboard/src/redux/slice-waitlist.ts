import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';

export interface WaitlistState {
  email: string;
  joinReq: RequestState;
}

const initialState: WaitlistState = {
  email: ``,
  joinReq: { state: `idle` },
};

export const slice = createSlice({
  name: `waitlist`,
  initialState,
  reducers: {
    emailUpdated: (state, action: PayloadAction<string>) => {
      state.email = action.payload;
    },
    joinReqUpdated: (state, action: PayloadAction<RequestState>) => {
      state.joinReq = action.payload;
    },
  },
  extraReducers(builder) {
    builder.addCase(joinWaitlist.pending, (state) => {
      state.joinReq = { state: `ongoing` };
    });
    builder.addCase(joinWaitlist.fulfilled, (state, action) => {
      state.joinReq = { state: action.payload ? `succeeded` : `failed` };
    });
    builder.addCase(joinWaitlist.rejected, (state) => {
      state.joinReq = { state: `failed` };
    });
  },
});

export const joinWaitlist = createAsyncThunk(
  `${slice.name}/join`,
  async (email: string) => {
    const result = await Current.api.signup.joinWaitlist(email);
    return result.isSuccess;
  },
);

export const { emailUpdated, joinReqUpdated } = slice.actions;

export default slice.reducer;
