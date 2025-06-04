import { describe, expect, beforeEach, it } from 'vitest';
import { time } from '@shared/datetime';
import { chunkedRenderTasks, type Chunkable } from '../DeletableActivityChunks';

describe(`chunkedRenderTasks()`, () => {
  beforeEach(resetId);

  it(`should group into chunks`, () => {
    const chunks = chunkedRenderTasks(
      [screenshot(), screenshot(), screenshot(), screenshot()],
      2,
      true,
    );
    expect(simplify(chunks)).toMatchInlineSnapshot(`
      [
        "item(Screenshot)",
        "item(Screenshot)",
        "delete_btn",
        "item(Screenshot)",
        "item(Screenshot)",
      ]
    `);
  });

  it(`should group into chunks with suspension groups`, () => {
    const chunks = chunkedRenderTasks(
      [
        screenshot({ duringSuspension: true }),
        screenshot({ duringSuspension: true }),
        screenshot(),
        screenshot(),
      ],
      2,
      true,
    );
    expect(simplify(chunks)).toMatchInlineSnapshot(`
      [
        "suspension_group(Screenshot, Screenshot)",
        "delete_btn",
        "item(Screenshot)",
        "item(Screenshot)",
      ]
    `);
  });

  it(`should not highlight suspension activity when setting is off`, () => {
    const chunks = chunkedRenderTasks(
      [
        screenshot({ duringSuspension: true }),
        screenshot({ duringSuspension: true }),
        screenshot(),
        screenshot({ duringSuspension: true }),
      ],
      2,
      false,
    );
    expect(simplify(chunks)).toMatchInlineSnapshot(`
      [
        "item(Screenshot)",
        "item(Screenshot)",
        "delete_btn",
        "item(Screenshot)",
        "item(Screenshot)",
      ]
    `);
  });

  it(`handles suspensions across chunk boundaries`, () => {
    const chunks = chunkedRenderTasks(
      [
        keystroke({ duringSuspension: true }),
        screenshot({ duringSuspension: true }),
        screenshot({ duringSuspension: true }),
        screenshot(),
      ],
      2,
      true,
    );
    expect(simplify(chunks)).toMatchInlineSnapshot(`
      [
        "suspension_group(KeystrokeLine, Screenshot)",
        "delete_btn",
        "suspension_group(Screenshot)",
        "item(Screenshot)",
      ]
    `);
  });

  it(`handles all suspended`, () => {
    const chunks = chunkedRenderTasks(
      [
        keystroke({ duringSuspension: true }),
        screenshot({ duringSuspension: true }),
        screenshot({ duringSuspension: true }),
        screenshot({ duringSuspension: true }),
      ],
      2,
      true,
    );
    expect(simplify(chunks)).toMatchInlineSnapshot(`
      [
        "suspension_group(KeystrokeLine, Screenshot)",
        "delete_btn",
        "suspension_group(Screenshot, Screenshot)",
      ]
    `);
  });

  it(`merges stray keystroke lines into suspension group`, () => {
    const chunks = chunkedRenderTasks(
      [
        screenshot({
          duringSuspension: true,
          date: time.subtracting({ minutes: 1 }),
        }),
        keystroke({
          duringSuspension: false, // <-- stray keystroke line
          date: time.subtracting({ minutes: 2 }),
        }),
        screenshot({
          duringSuspension: true,
          date: time.subtracting({ minutes: 3 }),
        }),
        screenshot(),
      ],
      100,
      true,
    );
    expect(simplify(chunks)).toMatchInlineSnapshot(`
      [
        "suspension_group(Screenshot, KeystrokeLine, Screenshot)",
        "item(Screenshot)",
      ]
    `);
  });

  it(`does not merge keystroke if too far`, () => {
    const chunks = chunkedRenderTasks(
      [
        screenshot({
          duringSuspension: true,
          date: time.subtracting({ minutes: 1 }),
        }),
        keystroke({
          duringSuspension: false,
          date: time.subtracting({ minutes: 5.1 }),
        }),
        screenshot({
          duringSuspension: true,
          date: time.subtracting({ minutes: 5.2 }), // too far from prev
        }),
        screenshot(),
      ],
      100,
      true,
    );
    expect(simplify(chunks)).toMatchInlineSnapshot(`
      [
        "suspension_group(Screenshot)",
        "item(KeystrokeLine)",
        "suspension_group(Screenshot)",
        "item(Screenshot)",
      ]
    `);
  });
});

// helpers

function simplify(chunks: ReturnType<typeof chunkedRenderTasks>): string[] {
  return chunks
    .map((chunk) =>
      chunk.map((i) => {
        switch (i.type) {
          case `item`:
            return `item(${i.item.type})`;
          case `delete_btn`:
            return `delete_btn`;
          default:
            return `suspension_group(${i.items.map((i) => i.type).join(`, `)})`;
        }
      }),
    )
    .flat(1);
}

function screenshot(config: Partial<Omit<Chunkable, `type`>> = {}): Chunkable {
  return {
    type: `Screenshot`,
    id: nextId(),
    duringSuspension: false,
    date: time.stable(),
    ...config,
  };
}

function keystroke(config: Partial<Omit<Chunkable, `type`>> = {}): Chunkable {
  return {
    type: `KeystrokeLine`,
    id: nextId(),
    duringSuspension: false,
    date: time.stable(),
    ...config,
  };
}

let id = 0;
function nextId(): string {
  return String(++id);
}
function resetId(): void {
  id = 0;
}
