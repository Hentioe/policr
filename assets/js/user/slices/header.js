import { createSlice } from "redux-starter-kit";

const initialState = {
  is: null,
  isTop: true
};

export const header = createSlice({
  name: "header",
  initialState,
  reducers: {
    isSettinged: (state, action) =>
      Object.assign({}, state, { is: `is-${action.payload}` }),
    isCleared: state => Object.assign({}, state, { is: null }),
    topFixed: state => Object.assign({}, state, { isTop: true }),
    topUnfixed: state => Object.assign({}, state, { isTop: false })
  }
});

export const { isSettinged, isCleared, topFixed, topUnfixed } = header.actions;

export default header.reducer;
