import { isSettinged, isCleared } from "./slices/header";

export function settingNavIs(is) {
  return dispatch => dispatch(isSettinged(is));
}

export function clearNavIs() {
  return dispatch => dispatch(isCleared());
}
