import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';
import { Req } from './helpers';

export interface WaitlistState {
  email: string;
  joinReq: RequestState;
}

const initialState: WaitlistState = {
  email: ``,
  joinReq: Req.idle(),
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
      state.joinReq = Req.ongoing();
    });
    builder.addCase(joinWaitlist.fulfilled, (state, { payload }) => {
      state.joinReq = payload ? Req.succeed(void 0) : Req.fail();
    });
    builder.addCase(joinWaitlist.rejected, (state) => {
      state.joinReq = Req.fail();
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
