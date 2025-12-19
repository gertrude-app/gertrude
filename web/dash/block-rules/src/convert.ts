import type { EditBlockRuleProps } from './types';
import type { BlockRule } from '@dash/types';

export function blockRuleToProps(rule: BlockRule): EditBlockRuleProps | null {
  switch (rule.case) {
    case `bundleIdContains`:
    case `targetContains`:
    case `hostnameContains`:
    case `hostnameEquals`:
    case `hostnameEndsWith`:
    case `urlContains`:
      return createSimpleRule(rule);
    case `both`:
      return handleBothRule(rule);
    case `unless`:
      return handleUnlessRule(rule);
    default:
      return null;
  }
}

function createSimpleRule(rule: { case: string; value: string }): EditBlockRuleProps {
  return {
    type: rule.case === `bundleIdContains` ? `app` : `address`,
    primaryValue: rule.value,
    secondaryValue: ``,
    condition: `always`,
  };
}

function handleBothRule(rule: { a: BlockRule; b: BlockRule }): EditBlockRuleProps | null {
  const { a, b } = rule;
  if (a.case === `bundleIdContains`) {
    return handleBundleIdWithSecondRule(a, b);
  }
  if (isAddressRule(a)) {
    return handleAddressWithFlowType(a, b);
  }
  return null;
}

function handleBundleIdWithSecondRule(
  bundleRule: { value: string },
  secondRule: BlockRule,
): EditBlockRuleProps | null {
  if (isAddressRule(secondRule)) {
    return {
      type: `app`,
      primaryValue: bundleRule.value,
      secondaryValue: secondRule.value,
      condition: `whenAddressContains`,
    };
  }
  if (secondRule.case === `flowTypeIs` && secondRule.value === `browser`) {
    return {
      type: `app`,
      primaryValue: bundleRule.value,
      secondaryValue: ``,
      condition: `whenIsBrowser`,
    };
  }
  return null;
}

function handleAddressWithFlowType(
  addressRule: AddressRule,
  flowRule: BlockRule,
): EditBlockRuleProps | null {
  if (flowRule.case === `flowTypeIs` && flowRule.value === `browser`) {
    return {
      type: `address`,
      primaryValue: addressRule.value,
      secondaryValue: ``,
      condition: `whenIsBrowser`,
    };
  }
  return null;
}

function handleUnlessRule(rule: {
  rule: BlockRule;
  negatedBy: BlockRule[];
}): EditBlockRuleProps | null {
  if (rule.rule.case !== `bundleIdContains`) {
    return null;
  }
  const addressValues: string[] = [];
  for (const negatedRule of rule.negatedBy) {
    if (!isAddressRule(negatedRule)) {
      return null;
    }
    addressValues.push(negatedRule.value);
  }

  return {
    type: `app`,
    primaryValue: rule.rule.value,
    secondaryValue: addressValues.join(`\n`),
    condition: `unlessAddressContains`,
  };
}

type AddressRule = Extract<
  BlockRule,
  | { case: `targetContains` }
  | { case: `hostnameContains` }
  | { case: `hostnameEquals` }
  | { case: `hostnameEndsWith` }
  | { case: `urlContains` }
>;

function isAddressRule(rule: BlockRule): rule is AddressRule {
  return [
    `targetContains`,
    `hostnameContains`,
    `hostnameEquals`,
    `hostnameEndsWith`,
    `urlContains`,
  ].includes(rule.case);
}

export function propsToBlockRule(props: EditBlockRuleProps): BlockRule {
  const { type, primaryValue, secondaryValue, condition } = props;
  switch (condition) {
    case `always`:
      if (type === `app`) {
        return { case: `bundleIdContains`, value: primaryValue };
      } else {
        return { case: `targetContains`, value: primaryValue };
      }
    case `whenAddressContains`:
      return {
        case: `both`,
        a: { case: `bundleIdContains`, value: primaryValue },
        b: { case: `targetContains`, value: secondaryValue },
      };
    case `whenIsBrowser`:
      if (type === `app`) {
        return {
          case: `both`,
          a: { case: `bundleIdContains`, value: primaryValue },
          b: { case: `flowTypeIs`, value: `browser` },
        };
      } else {
        return {
          case: `both`,
          a: { case: `targetContains`, value: primaryValue },
          b: { case: `flowTypeIs`, value: `browser` },
        };
      }
    case `unlessAddressContains`: {
      const negatedRules: BlockRule[] = secondaryValue
        .split(`\n`)
        .filter((value) => value.trim())
        .map((value) => ({ case: `targetContains` as const, value: value.trim() }));
      return {
        case: `unless`,
        rule: { case: `bundleIdContains`, value: primaryValue },
        negatedBy: negatedRules,
      };
    }
  }
}
