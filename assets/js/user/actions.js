import { isSettinged, isCleared, topFixed, topUnfixed } from "./slices/header";

export function settingNavIs(is) {
  return dispatch => dispatch(isSettinged(is));
}

export function clearNavIs() {
  return dispatch => dispatch(isCleared());
}

export function fixedNav() {
  return dispatch => dispatch(topFixed());
}

export function unfixedNav() {
  return dispatch => dispatch(topUnfixed());
}
