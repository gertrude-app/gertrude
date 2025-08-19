import type { EditBlockRuleProps } from './types';

export function blockRuleProps(props: EditBlockRuleProps): boolean {
  if (props.primaryValue.trim() === ``) {
    return false;
  } else if (props.condition === `whenIsBrowser` || props.condition === `always`) {
    return true;
  } else {
    return props.secondaryValue.trim() !== ``;
  }
}
