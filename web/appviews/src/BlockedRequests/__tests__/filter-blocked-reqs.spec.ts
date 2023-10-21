import { expect, it, describe } from 'vitest';
import { filterVisibleRequests } from '../BlockedRequests';

describe(`filterVisibleRequests()`, () => {
  it(`removes tcp requests when tcpOnly true`, () => {
    const requests = [
      { protocol: `tcp` as const, searchableText: `tcp 1`, time: `1` },
      { protocol: `udp` as const, searchableText: `udp 1`, time: `2` },
      { protocol: `tcp` as const, searchableText: `tcp 2`, time: `3` },
    ];

    const all = filterVisibleRequests(requests, ``, false);
    expect(all).toEqual([...requests].reverse());

    const tcpOnly = filterVisibleRequests(requests, ``, true);
    expect(tcpOnly).toEqual([
      { protocol: `tcp` as const, searchableText: `tcp 2`, time: `3` },
      { protocol: `tcp` as const, searchableText: `tcp 1`, time: `1` },
    ]);
  });

  it(`filters by search text`, () => {
    const requests = [
      { protocol: `tcp` as const, searchableText: `jim jam bar`, time: `3` },
      { protocol: `udp` as const, searchableText: `Foo quux bar`, time: `2` },
      { protocol: `tcp` as const, searchableText: `foo bar baz foobar`, time: `1` },
    ];

    let filtered = filterVisibleRequests(requests, `bar jim`, false);
    expect(filtered).toEqual([
      { protocol: `tcp` as const, searchableText: `jim jam bar`, time: `3` },
    ]);

    filtered = filterVisibleRequests(requests, `foo BAR`, false);
    expect(filtered).toEqual([
      { protocol: `udp` as const, searchableText: `Foo quux bar`, time: `2` },
      { protocol: `tcp` as const, searchableText: `foo bar baz foobar`, time: `1` },
    ]);
  });
});
