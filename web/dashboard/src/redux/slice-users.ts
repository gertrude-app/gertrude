import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { ListUsers_user } from '../api/users/__generated__/ListUsers';
import Current from '../environment';
import { Req, toMap } from './helpers';

export interface UsersState {
  listReq: RequestState<Record<UUID, ListUsers_user>>;
}

const initialState: UsersState = {
  listReq: Req.idle(),
};

export const slice = createSlice({
  name: `users`,
  initialState,
  reducers: {
    listReqUpdated: (state, action: PayloadAction<UsersState['listReq']>) => {
      state.listReq = action.payload;
    },
  },
});

export const fetchUsers = createAsyncThunk(
  `${slice.name}/fetchUsers`,
  async (_, { dispatch }) => {
    dispatch(listReqUpdated(Req.ongoing()));
    const result = await Current.api.users.list();
    result.on({
      success: (users) => dispatch(listReqUpdated(Req.succeed(toMap(users)))),
      error: (error) => dispatch(listReqUpdated(Req.fail(error))),
    });
  },
);

export const { listReqUpdated } = slice.actions;

export default slice.reducer;
