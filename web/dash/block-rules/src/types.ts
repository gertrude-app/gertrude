export type EditBlockRuleProps = {
  type: `app` | `address`;
  primaryValue: string;
  secondaryValue: string;
  condition: BlockCondition;
};

export type BlockCondition =
  | `always`
  | `whenAddressContains`
  | `whenIsBrowser`
  | `unlessAddressContains`;

export type EditEvent =
  | { type: `setPrimaryValue`; value: string }
  | { type: `setSecondaryValue`; value: string }
  | { type: `setType`; value: `app` | `address` }
  | { type: `setCondition`; value: BlockCondition };
