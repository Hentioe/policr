import { combineReducers } from "redux";

import headerReducer from "./slices/header";

export default combineReducers({ header: headerReducer });
