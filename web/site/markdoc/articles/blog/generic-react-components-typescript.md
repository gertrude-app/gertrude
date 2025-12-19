---
title: Generic React Components in TypeScript
date: '2023-08-07T18:26:29.007Z'
slug: generic-react-components-typescript
description:
  Building a re-usable, typesafe radio or select component shows why we might need a
  generic React component. This tutorial explains how you can build your own well-typed
  and ergonomic generic components in typescript.
category: engineering
---

Creating generic React components isn't something you need to do every day, but when you
need one, it can be a really useful tool in your toolbox.

## 🤔 The Problem: A **Typesafe** Radio/Select Component

Imagine we're building a **reusable radio input component.** (I'll show a
`<input type=radio>` in the examples below, but this would work nearly exactly the same
for a `<select>` component)

Here's a _first pass:_

```tsx
interface Props {
  selected: string;
  options: Array<{ value: string; label: string }>;
  onChange(value: string): void;
}

const Radio: React.FC<Props> = ({ options, selected, onChange }) => (
  <div>
    {options.map((option) => (
      <label key={option.value}>
        <input
          type="radio"
          checked={option.value === selected}
          value={option.value}
          onChange={() => onChange(option.value)}
        />
        {option.label}
      </label>
    ))}
  </div>
);
```

Not a bad start. But notice how the typescript type for our selected value is `string`.
This is OK, but usually when we're rendering a radio input, we have a _well-known,
discrete set of options_, better modeled as a typescript **union**, like
`'small' | 'medium' | 'large'`. Choosing a union over `string` means we get compile errors
if we misspell an option, or when we're passing the wrong data from a typed API into a
component.

But, currently if we try to use our component with a well-typed union of strings...

```tsx
const BuyPants: React.FC = () => {
  const [size, setSize] = useState<'sm' | 'md' | 'lg'>(`sm`);
  return (
    <div>
      <h1>Buy pants! 🩳</h1>
      <Radio
        selected={size}
        options={[
          { value: `sm`, label: `Small` },
          { value: `md`, label: `Medium` },
          { value: `lg`, label: `Large` },
        ]}
        // 🚨 ERROR! Our nicely typed `setSize` fn is no bueno!
        onChange={setSize}
      />
    </div>
  );
};
```

...Typescript is _not buying it:_

```
typescript: Type 'Dispatch<SetStateAction<"sm" | "md" | "lg">>' is not assignable to type '(value: string) => void'.
  Types of parameters 'value' and 'value' are incompatible.
    Type 'string' is not assignable to type 'SetStateAction<"sm" | "md" | "lg">'. [2322]
```

The error is a bit cryptic, but it basically means that our `size` and `setSize` variables
work with types of `'sm' | 'med' | 'large'`, but our `Radio` component only deals with
`string`s, so the types don't match. From what we've told typescript, the `<Radio />`
component could call our `setSize()` function with _any string!_ We know it doesn't, but
the type system doesn't know that, so it politely stops us in our tracks.

## 💃 The Solution: A **Generic** Typescript React Component

The fix here is to make our component **generic over the `value` type.**

One tricky bit is if you're use to using the `React.FC` type and a _function expression_
(as shown above), there's no place to express the type parameter, so we'll need to switch
our component to a _function declaration_ so we have a place to slot in our type
parameter. Here's a first attempt: (this doesn't compile yet)

```tsx
interface Props<T> {
  selected: T;
  options: Array<{ value: T; label: string }>;
  onChange(value: T): void;
}

function Radio<T>({ options, selected, onChange }: Props<T>) {
  return (
    <div>
      {options.map((option) => (
        <label key={option.value}>
          <input
            type="radio"
            checked={option.value === selected}
            // 🚨 ERROR! Type 'T' is not assignable to 'string | number ...'
            value={option.value}
            onChange={() => onChange(option.value)}
          />
          {option.label}
        </label>
      ))}
    </div>
  );
}
```

Typescript's not OK with this yet, we get the following error:

```
Type 'T' is not assignable to type 'string | number | readonly string[] | undefined
```

Seems we've played a little too fast and loose with our generic `T`&mdash;the way we've
written it here, `T` could be _any_ type, but a react `<input type="radio">` can't take
just any old type.

We need to **narrow the generic type** a bit. Different languages have different terms and
syntax for this. In Swift, this would be called a _generic constraint,_ or in Rust, a
_bound_ for the generic. In typescript, these are also technically called
[generic constraints](https://www.typescriptlang.org/docs/handbook/2/generics.html#generic-constraints)
and we can express them using the `extends` keyword:

```tsx
interface Props<T extends string> {
  selected: T;
  options: Array<{ value: T; label: string }>;
  onChange(value: T): void;
}

function Radio<T extends string>({ options, selected, onChange }: Props<T>) {
  return (
    <div>
      {options.map((option) => (
        <label key={option.value}>
          <input
            type="radio"
            checked={option.value === selected}
            value={option.value}
            onChange={() => onChange(option.value)}
          />
          {option.label}
        </label>
      ))}
    </div>
  );
}
```

We're getting there. Typescript is happy now, but there are a couple things more we could
improve.

1. In switching to a function declaration we **lost the return type** supplied by the
   `React.FC` type. I'm a big believer in always requiring explicit return type
   annotations, because it protects me from making dumb mistakes.

2. As written above, we'll have to **spell out the generic type** every time even when our
   `value` type is a plain old string.

We're not savages. We can do better than this. The final code below fixes both of these
issues:

```tsx
interface Props<T extends string> {
  selected: T;
  options: Array<{ value: T; label: string }>;
  onChange(value: T): void;
}

function Radio<T extends string = string>({
  options,
  selected,
  onChange,
}: Props<T>): ReturnType<React.FC<Props<T>>> {
  return (
    <div>
      {options.map((option) => (
        <label key={option.value}>
          <input
            type="radio"
            checked={option.value === selected}
            value={option.value}
            onChange={() => onChange(option.value)}
          />
          {option.label}
        </label>
      ))}
    </div>
  );
}
```

The `<T extends string = string>` allows us to omit specifying the generic when we're
using a `string`.

And, the `ReturnType<React.FC<Props<T>>>` type, while a bit on the gnarly side, gives us
exactly what we want. We could write this shorter, but exactly what is returned by a React
component is not as simple as you might guess, so inferring it from the official type
seems like the right choice here. Plus, you know you're good at generics if your code
looks like someone barfed angle brackets all over it, AMIRIGHT?

## 💪 The Callsite: How to Render a Generic Component

Finally, in case this wasn't clear, and because it's not a syntax you see every day in
React/TypeScript codebases, here's how to render a component supplying the generic.
Nothing fancy, just **more angle brackets!**

The basic idea is, instead of typing `<MyComponent />` you also include the generic
(unless it's `string`): `<MyComponent<'foo' | 'bar'> />`.

```tsx
const BuyPants: React.FC = () => {
  const [size, setSize] = useState<'sm' | 'md' | 'lg'>(`sm`);
  return (
    <div>
      <h1>Buy pants! 🩳</h1>
      <Radio<'sm' | 'md' | 'lg'> // 1️⃣ supply the generic here...
        selected={size}
        options={[
          { value: `sm`, label: `Small` },
          { value: `md`, label: `Medium` },
          { value: `lg`, label: `Large` },
        ]}
        onChange={setSize} // ... 2️⃣ then revel in your type safety here!
      />
    </div>
  );
};
```
