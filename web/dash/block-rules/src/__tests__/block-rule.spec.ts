import { describe, expect, test } from 'vitest';
import type { EditBlockRuleProps } from '../types';
import type { BlockRule } from '@dash/types';
import { blockRuleToProps, propsToBlockRule } from '../convert';

describe(`blockRuleToProps`, () => {
  const cases: Array<[BlockRule, EditBlockRuleProps | null]> = [
    [
      { case: `bundleIdContains`, value: `com.example.app` },
      {
        type: `app`,
        primaryValue: `com.example.app`,
        secondaryValue: ``,
        condition: `always`,
      },
    ],
    [
      { case: `urlContains`, value: `example.com` },
      {
        type: `address`,
        primaryValue: `example.com`,
        secondaryValue: ``,
        condition: `always`,
      },
    ],
    [
      { case: `hostnameContains`, value: `foo` },
      {
        type: `address`,
        primaryValue: `foo`,
        secondaryValue: ``,
        condition: `always`,
      },
    ],
    [
      { case: `hostnameEquals`, value: `bar.com` },
      {
        type: `address`,
        primaryValue: `bar.com`,
        secondaryValue: ``,
        condition: `always`,
      },
    ],
    [
      { case: `hostnameEndsWith`, value: `.org` },
      {
        type: `address`,
        primaryValue: `.org`,
        secondaryValue: ``,
        condition: `always`,
      },
    ],
    [
      { case: `targetContains`, value: `baz` },
      {
        type: `address`,
        primaryValue: `baz`,
        secondaryValue: ``,
        condition: `always`,
      },
    ],
    [
      {
        case: `both`,
        a: { case: `bundleIdContains`, value: `com.foo` },
        b: { case: `hostnameEquals`, value: `foo.com` },
      },
      {
        type: `app`,
        primaryValue: `com.foo`,
        secondaryValue: `foo.com`,
        condition: `whenAddressContains`,
      },
    ],
    [
      {
        case: `both`,
        a: { case: `bundleIdContains`, value: `com.foo` },
        b: { case: `flowTypeIs`, value: `browser` },
      },
      {
        type: `app`,
        primaryValue: `com.foo`,
        secondaryValue: ``,
        condition: `whenIsBrowser`,
      },
    ],
    [
      {
        case: `both`,
        a: { case: `hostnameContains`, value: `foo.com` },
        b: { case: `flowTypeIs`, value: `browser` },
      },
      {
        type: `address`,
        primaryValue: `foo.com`,
        secondaryValue: ``,
        condition: `whenIsBrowser`,
      },
    ],
    [
      {
        case: `unless`,
        rule: { case: `bundleIdContains`, value: `com.foo` },
        negatedBy: [
          { case: `hostnameEquals`, value: `foo.com` },
          { case: `hostnameEquals`, value: `bar.com` },
        ],
      },
      {
        type: `app`,
        primaryValue: `com.foo`,
        secondaryValue: `foo.com\nbar.com`,
        condition: `unlessAddressContains`,
      },
    ],
    [
      {
        case: `unless`,
        rule: { case: `bundleIdContains`, value: `com.foo` },
        negatedBy: [
          { case: `hostnameEquals`, value: `foo.com` },
          { case: `flowTypeIs`, value: `browser` }, // <-- causes null
        ],
      },
      null,
    ],
    [{ case: `flowTypeIs`, value: `browser` }, null],
    [{ case: `flowTypeIs`, value: `socket` }, null],
  ];

  test.each(cases)(`blockRuleProps %#`, (input, expected) => {
    expect(blockRuleToProps(input)).toEqual(expected);
  });
});

describe(`propsToBlockRule`, () => {
  const cases: Array<[EditBlockRuleProps, BlockRule]> = [
    [
      {
        type: `app`,
        primaryValue: `com.example.app`,
        secondaryValue: ``,
        condition: `always`,
      },
      { case: `bundleIdContains`, value: `com.example.app` },
    ],
    [
      {
        type: `address`,
        primaryValue: `example.com`,
        secondaryValue: ``,
        condition: `always`,
      },
      { case: `targetContains`, value: `example.com` },
    ],
    [
      {
        type: `address`,
        primaryValue: `foo`,
        secondaryValue: ``,
        condition: `always`,
      },
      { case: `targetContains`, value: `foo` },
    ],
    [
      {
        type: `address`,
        primaryValue: `bar.com`,
        secondaryValue: ``,
        condition: `always`,
      },
      { case: `targetContains`, value: `bar.com` },
    ],
    [
      {
        type: `address`,
        primaryValue: `.org`,
        secondaryValue: ``,
        condition: `always`,
      },
      { case: `targetContains`, value: `.org` },
    ],
    [
      {
        type: `address`,
        primaryValue: `baz`,
        secondaryValue: ``,
        condition: `always`,
      },
      { case: `targetContains`, value: `baz` },
    ],
    [
      {
        type: `app`,
        primaryValue: `com.foo`,
        secondaryValue: `foo.com`,
        condition: `whenAddressContains`,
      },
      {
        case: `both`,
        a: { case: `bundleIdContains`, value: `com.foo` },
        b: { case: `targetContains`, value: `foo.com` },
      },
    ],
    [
      {
        type: `app`,
        primaryValue: `com.foo`,
        secondaryValue: ``,
        condition: `whenIsBrowser`,
      },
      {
        case: `both`,
        a: { case: `bundleIdContains`, value: `com.foo` },
        b: { case: `flowTypeIs`, value: `browser` },
      },
    ],
    [
      {
        type: `address`,
        primaryValue: `foo.com`,
        secondaryValue: ``,
        condition: `whenIsBrowser`,
      },
      {
        case: `both`,
        a: { case: `targetContains`, value: `foo.com` },
        b: { case: `flowTypeIs`, value: `browser` },
      },
    ],
    [
      {
        type: `app`,
        primaryValue: `com.foo`,
        secondaryValue: `foo.com\nbar.com`,
        condition: `unlessAddressContains`,
      },
      {
        case: `unless`,
        rule: { case: `bundleIdContains`, value: `com.foo` },
        negatedBy: [
          { case: `targetContains`, value: `foo.com` },
          { case: `targetContains`, value: `bar.com` },
        ],
      },
    ],
  ];

  test.each(cases)(`propsToBlockRule %#`, (props, expectedRule) => {
    expect(propsToBlockRule(props)).toEqual(expectedRule);
  });
});
