import type React from 'react';

export type CSSVariableProperties = React.CSSProperties &
  Partial<Record<`--${string}`, string>>;

export type ViewportBreakpoint = `xs` | `sm` | `md` | `lg` | `xl` | `2xl`;
export type ContainerSize =
  `xs` | `sm` | `md` | `lg` | `xl` | `2xl` | `3xl` | `4xl` | `5xl` | `6xl` | `7xl`;
export type ContainerName = `main` | `slide`;
export type ContainerBreakpoint = `@${ContainerSize}/${ContainerName}`;
export type ResponsiveBreakpoint = ViewportBreakpoint | ContainerBreakpoint;
export type ResponsiveValueMap<Value> = { default?: Value } & Partial<
  Record<ResponsiveBreakpoint, Value>
>;
export type ResponsiveValue<Value> = Value | ResponsiveValueMap<Value>;
export type ResponsiveClassMap = Record<`default` | ResponsiveBreakpoint, string>;

export interface ResponsiveValueAttributes {
  style: CSSVariableProperties;
  className: string;
}

export const viewportBreakpoints = [`xs`, `sm`, `md`, `lg`, `xl`, `2xl`] as const;
export const mainContainerBreakpoints = [
  `@xs/main`,
  `@sm/main`,
  `@md/main`,
  `@lg/main`,
  `@xl/main`,
  `@2xl/main`,
  `@3xl/main`,
  `@4xl/main`,
  `@5xl/main`,
  `@6xl/main`,
  `@7xl/main`,
] as const;
export const slideContainerBreakpoints = [
  `@xs/slide`,
  `@sm/slide`,
  `@md/slide`,
  `@lg/slide`,
  `@xl/slide`,
  `@2xl/slide`,
  `@3xl/slide`,
  `@4xl/slide`,
  `@5xl/slide`,
  `@6xl/slide`,
  `@7xl/slide`,
] as const;
export const responsiveBreakpointGroups = [
  viewportBreakpoints,
  mainContainerBreakpoints,
  slideContainerBreakpoints,
] as const;
export const responsiveBreakpoints = [
  ...viewportBreakpoints,
  ...mainContainerBreakpoints,
  ...slideContainerBreakpoints,
] as const;

export const responsiveBreakpointSuffixes: Record<ResponsiveBreakpoint, string> = {
  xs: `xs`,
  sm: `sm`,
  md: `md`,
  lg: `lg`,
  xl: `xl`,
  '2xl': `2xl`,
  '@xs/main': `main-xs`,
  '@sm/main': `main-sm`,
  '@md/main': `main-md`,
  '@lg/main': `main-lg`,
  '@xl/main': `main-xl`,
  '@2xl/main': `main-2xl`,
  '@3xl/main': `main-3xl`,
  '@4xl/main': `main-4xl`,
  '@5xl/main': `main-5xl`,
  '@6xl/main': `main-6xl`,
  '@7xl/main': `main-7xl`,
  '@xs/slide': `slide-xs`,
  '@sm/slide': `slide-sm`,
  '@md/slide': `slide-md`,
  '@lg/slide': `slide-lg`,
  '@xl/slide': `slide-xl`,
  '@2xl/slide': `slide-2xl`,
  '@3xl/slide': `slide-3xl`,
  '@4xl/slide': `slide-4xl`,
  '@5xl/slide': `slide-5xl`,
  '@6xl/slide': `slide-6xl`,
  '@7xl/slide': `slide-7xl`,
};

const responsiveClassMapKeys = [`default`, ...responsiveBreakpoints] as const;

export const createResponsiveClassMap = (classes: string): ResponsiveClassMap => {
  const classNames = classes.trim().split(/\s+/);

  if (classNames.length !== responsiveClassMapKeys.length) {
    throw new Error(
      `Expected ${responsiveClassMapKeys.length} responsive classes, received ${classNames.length}`,
    );
  }

  const classMap = {} as ResponsiveClassMap;
  responsiveClassMapKeys.forEach((key, index) => {
    const className = classNames[index];
    if (className === undefined) {
      throw new Error(`Missing responsive class for ${key}`);
    }
    classMap[key] = className;
  });
  return classMap;
};

export const getResponsiveVariableName = (
  variableName: string,
  breakpoint?: ResponsiveBreakpoint,
): `--${string}` =>
  breakpoint
    ? `--${variableName}-${responsiveBreakpointSuffixes[breakpoint]}`
    : `--${variableName}`;

export const isResponsiveValueMap = <Value>(
  value: ResponsiveValue<Value>,
): value is ResponsiveValueMap<Value> =>
  typeof value === `object` && value !== null && !Array.isArray(value);

interface ResponsiveValueEntry<Value> {
  breakpoint: ResponsiveBreakpoint | undefined;
  value: Value;
}

const getResponsiveValueEntries = <Value>(
  value: ResponsiveValue<Value>,
  defaultValue: Value,
): ResponsiveValueEntry<Value>[] => {
  const entries: ResponsiveValueEntry<Value>[] = [];
  const addEntry = (
    breakpoint: ResponsiveBreakpoint | undefined,
    entryValue: Value,
  ): void => {
    entries.push({ breakpoint, value: entryValue });
  };

  if (!isResponsiveValueMap(value)) {
    addEntry(undefined, value);
    return entries;
  }

  const defaultResponsiveValue = value.default ?? defaultValue;
  addEntry(undefined, defaultResponsiveValue);

  responsiveBreakpointGroups.forEach((breakpointGroup) => {
    let currentValue = defaultResponsiveValue;

    breakpointGroup.forEach((breakpoint) => {
      const nextValue = value[breakpoint] ?? currentValue;
      if (!Object.is(nextValue, currentValue)) {
        currentValue = nextValue;
        addEntry(breakpoint, currentValue);
      }
    });
  });

  return entries;
};

const setResponsiveValueVariable = <Value>(
  style: CSSVariableProperties,
  variableName: string,
  breakpoint: ResponsiveBreakpoint | undefined,
  value: Value,
  serializeValue: (value: Value) => string,
): void => {
  style[getResponsiveVariableName(variableName, breakpoint)] = serializeValue(value);
};

export const getResponsiveValueStyle = <Value>(
  value: ResponsiveValue<Value>,
  variableName: string,
  serializeValue: (value: Value) => string,
  defaultValue: Value,
): CSSVariableProperties => {
  const style: CSSVariableProperties = {};

  getResponsiveValueEntries(value, defaultValue).forEach(
    ({ breakpoint, value: entryValue }) => {
      setResponsiveValueVariable(
        style,
        variableName,
        breakpoint,
        entryValue,
        serializeValue,
      );
    },
  );

  return style;
};

export const getResponsiveValueAttributes = <Value>(
  value: ResponsiveValue<Value>,
  variableName: string,
  serializeValue: (value: Value) => string,
  defaultValue: Value,
  classMap: ResponsiveClassMap,
): ResponsiveValueAttributes => {
  const style: CSSVariableProperties = {};
  const classNames: string[] = [];

  getResponsiveValueEntries(value, defaultValue).forEach(
    ({ breakpoint, value: entryValue }) => {
      setResponsiveValueVariable(
        style,
        variableName,
        breakpoint,
        entryValue,
        serializeValue,
      );
      classNames.push(classMap[breakpoint ?? `default`]);
    },
  );

  return { style, className: classNames.join(` `) };
};

export const mergeResponsiveValueAttributes = (
  ...attributes: ResponsiveValueAttributes[]
): ResponsiveValueAttributes => ({
  style: Object.assign(
    {},
    ...attributes.map((attribute) => attribute.style),
  ) as CSSVariableProperties,
  className: attributes
    .map((attribute) => attribute.className)
    .filter(Boolean)
    .join(` `),
});
