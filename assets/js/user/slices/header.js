import { createSlice } from "redux-starter-kit";

const initialState = {
  is: null
};

export const header = createSlice({
  name: "header",
  initialState,
  reducers: {
    isSettinged: (state, action) =>
      Object.assign({}, state, { is: `is-${action.payload}` }),
    isCleared: state => Object.assign({}, state, { is: null })
  }
});

export const { isSettinged, isCleared } = header.actions;

export default header.reducer;
