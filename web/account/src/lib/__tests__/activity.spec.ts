import { describe, expect, test } from 'vitest';
import type { GetPersonDayActivity } from '@shared/pairql/src/account';
import {
  type ActivityItem,
  chunkActivityBySuspension,
  chunkActivityForDeletion,
  prepareDelete,
  prepareDeleteCombined,
  toActivityItems,
} from '../activity';

const output: GetPersonDayActivity.Output = {
  personName: `Jude`,
  items: Array.from({ length: 5 }, (_, index) => ({
    case: `keylog`,
    id: `item-${index}`,
    ids: [`item-${index}`, `aggregated-${index}`],
    text: `Typing ${index}`,
    appName: `Safari`,
    date: `2026-11-04T12:00:00Z`,
    flagged: index === 0,
    duringSuspension: index < 3,
  })),
};
const items = toActivityItems(output, `person-1`);

describe(`chunkActivityForDeletion`, () => {
  test.each([
    [0, []],
    [99, [0]],
    [100, [0]],
    [101, [100, 0]],
    [200, [100, 0]],
    [201, [100, 200, 0]],
  ])(`places cumulative buttons for %i items`, (count, expected) => {
    const activity = Array.from({ length: count }, (_, index) => ({
      ...items[0]!,
      id: String(index),
    }));
    const batches = chunkActivityForDeletion(activity);
    expect(batches.map((batch) => batch.previousItems.length)).toEqual(expected);
    expect(
      batches.flatMap((batch) => batch.chunks.flatMap((chunk) => chunk.items)),
    ).toEqual(activity);
  });

  test(`splits suspension groups and includes exact cumulative IDs`, () => {
    const batches = chunkActivityForDeletion(items, 2);
    expect(batches.map((batch) => batch.previousItems.map((item) => item.id))).toEqual([
      [`item-0`, `item-1`],
      [`item-0`, `item-1`, `item-2`, `item-3`],
      [],
    ]);
    expect(
      batches.map((batch) =>
        batch.chunks.map((chunk) => [chunk.type, chunk.items.map((item) => item.id)]),
      ),
    ).toEqual([
      [[`duringSuspension`, [`item-0`, `item-1`]]],
      [
        [`duringSuspension`, [`item-2`]],
        [`normal`, [`item-3`]],
      ],
      [[`normal`, [`item-4`]]],
    ]);
    expect(items.map((item) => item.duringSuspension)).toEqual([
      true,
      true,
      true,
      false,
      false,
    ]);
  });

  test.each([0, -1, 1.5, Infinity])(`rejects invalid chunk size %i`, (size) => {
    expect(() => chunkActivityForDeletion(items, size)).toThrow();
  });
});

describe(`chunk deletion`, () => {
  test(`protects flags, expands IDs, and recalculates remaining boundaries`, () => {
    const batches = chunkActivityForDeletion(items, 2);
    const ids = batches[1]!.previousItems.map((item) => item.id);
    const [input, next] = prepareDelete(ids, output);
    expect(input).toEqual({
      keystrokeLineIds: [
        `item-1`,
        `aggregated-1`,
        `item-2`,
        `aggregated-2`,
        `item-3`,
        `aggregated-3`,
      ],
      screenshotIds: [],
    });
    expect(next.items.map((item) => item.id)).toEqual([`item-0`, `item-4`]);
    expect(
      chunkActivityForDeletion(toActivityItems(next, `person-1`), 2).map(
        (batch) => batch.previousItems,
      ),
    ).toEqual([[]]);
    expect(output.items).toHaveLength(5);
  });

  test(`combined deletion stays within the selected person and preserves order`, () => {
    const otherPerson = {
      ...output,
      personId: `person-2`,
      items: [
        {
          ...output.items[1]!,
          id: `other`,
          ids: [`other`],
        },
      ],
    };
    const combined = { people: [{ ...output, personId: `person-1` }, otherPerson] };
    const ids = chunkActivityForDeletion(items, 2)[0]!.previousItems.map(
      (item) => item.id,
    );
    const [input, next] = prepareDeleteCombined(ids, combined);
    expect(input.keystrokeLineIds).toEqual([`item-1`, `aggregated-1`]);
    expect(next.people.map((person) => person.personId)).toEqual([
      `person-1`,
      `person-2`,
    ]);
    expect(next.people[0]!.items.map((item) => item.id)).toEqual([
      `item-0`,
      `item-2`,
      `item-3`,
      `item-4`,
    ]);
    expect(next.people[1]).toEqual(otherPerson);
  });

  test(`deletes screenshots and leaves an all-flagged batch untouched`, () => {
    const screenshots: GetPersonDayActivity.Output = {
      personName: `Jude`,
      items: [
        {
          case: `screenshot`,
          id: `shot`,
          ids: [`shot`],
          url: `/shot.png`,
          width: 100,
          height: 100,
          date: `2026-11-04T12:00:00Z`,
          flagged: false,
          duringSuspension: false,
        },
        { ...output.items[0]! },
      ],
    };
    expect(prepareDelete([`shot`, `item-0`], screenshots)[0]).toEqual({
      screenshotIds: [`shot`],
      keystrokeLineIds: [],
    });
    const [input, next] = prepareDelete([`item-0`], screenshots);
    expect(input).toEqual({ screenshotIds: [], keystrokeLineIds: [] });
    expect(next).toEqual(screenshots);
  });
});

describe(`suspension keystroke heuristic`, () => {
  const screenshot: ActivityItem = {
    ...items[0]!,
    type: `screenshot`,
    url: `/shot.png`,
    width: 100,
    height: 100,
  };
  const suspended = {
    ...screenshot,
    id: `before`,
    date: new Date(`2026-11-04T12:00:00Z`),
  };
  const stray = {
    ...items[0]!,
    id: `stray`,
    duringSuspension: false,
    date: new Date(`2026-11-04T11:59:00Z`),
  };
  const after = { ...screenshot, id: `after`, date: new Date(`2026-11-04T11:58:00Z`) };

  test(`bridges stray keystrokes without changing source flags or item identity`, () => {
    const activity = Object.freeze([
      Object.freeze(suspended),
      Object.freeze(stray),
      Object.freeze(after),
    ]);
    const chunks = chunkActivityBySuspension(activity);
    expect(chunks).toEqual([{ type: `duringSuspension`, items: activity }]);
    expect(chunks[0]!.items[1]).toBe(stray);
    expect(stray.duringSuspension).toBe(false);
    expect(suspended.duringSuspension).toBe(true);
    expect(after.duringSuspension).toBe(true);
  });

  test.each([239999, 240000, 240001, -239999, -240000])(
    `uses a strict four-minute distance in either time order (%i ms)`,
    (distance) => {
      const chunks = chunkActivityBySuspension([
        suspended,
        stray,
        { ...after, date: new Date(suspended.date.getTime() - distance) },
      ]);
      expect(chunks.map((chunk) => chunk.type)).toEqual(
        Math.abs(distance) < 240000
          ? [`duringSuspension`]
          : [`duringSuspension`, `normal`, `duringSuspension`],
      );
    },
  );

  test.each([1, 2, 4, 5])(
    `looks ahead at most four entries across %i stray keystrokes`,
    (count) => {
      const activity = [
        suspended,
        ...Array.from({ length: count }, (_, index) => ({
          ...stray,
          id: `stray-${index}`,
        })),
        after,
      ];
      expect(chunkActivityBySuspension(activity).map((chunk) => chunk.type)).toEqual(
        count <= 4
          ? [`duringSuspension`]
          : [`duringSuspension`, `normal`, `duringSuspension`],
      );
    },
  );

  test(`does not cross or reclassify an unmarked screenshot`, () => {
    const unmarked = { ...screenshot, id: `unmarked`, duringSuspension: false };
    expect(chunkActivityBySuspension([suspended, stray, unmarked, after])).toEqual([
      { type: `duringSuspension`, items: [suspended] },
      { type: `normal`, items: [stray, unmarked] },
      { type: `duringSuspension`, items: [after] },
    ]);
  });

  test(`does not bridge to or look beyond a suspended keystroke`, () => {
    const markedKeystroke = { ...stray, id: `marked`, duringSuspension: true };
    expect(chunkActivityBySuspension([suspended, stray, markedKeystroke, after])).toEqual(
      [
        { type: `duringSuspension`, items: [suspended] },
        { type: `normal`, items: [stray] },
        { type: `duringSuspension`, items: [markedKeystroke, after] },
      ],
    );
  });

  test(`requires suspension activity before and a suspended screenshot after`, () => {
    expect(chunkActivityBySuspension([stray, after])).toEqual([
      { type: `normal`, items: [stray] },
      { type: `duringSuspension`, items: [after] },
    ]);
    expect(chunkActivityBySuspension([suspended, stray])).toEqual([
      { type: `duringSuspension`, items: [suspended] },
      { type: `normal`, items: [stray] },
    ]);
  });

  test(`keeps heuristic lookahead within deletion boundaries and preserves delete IDs`, () => {
    const batches = chunkActivityForDeletion([suspended, stray, after], 2);
    expect(batches[0]!.chunks).toEqual([
      { type: `duringSuspension`, items: [suspended] },
      { type: `normal`, items: [stray] },
    ]);
    expect(batches[0]!.previousItems.map((item) => item.id)).toEqual([`before`, `stray`]);
    expect(batches[1]!.chunks).toEqual([{ type: `duringSuspension`, items: [after] }]);
  });
});
