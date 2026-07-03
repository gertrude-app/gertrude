import cx from 'clsx';
import React from 'react';

export const galleryParameters = { controls: { disable: true } };
export const useSyncedStoryState = <Value,>(
  value: Value,
): [Value, React.Dispatch<React.SetStateAction<Value>>] => {
  const [state, setState] = React.useState(value);

  React.useEffect(() => setState(value), [value]);

  return [state, setState];
};

type StoryCanvasProps = {
  children: React.ReactNode;
  className?: string;
  innerClassName?: string;
};

export const StoryCanvas: React.FC<StoryCanvasProps> = ({
  children,
  className,
  innerClassName,
}) => (
  <div className={cx(`min-h-screen bg-stone-100 p-12 text-stone-950`, className)}>
    <div className={cx(`mx-auto flex max-w-5xl flex-col gap-12`, innerClassName)}>
      {children}
    </div>
  </div>
);

type StorySectionProps = {
  title: string;
  children: React.ReactNode;
  className?: string;
  contentClassName?: string;
};

export const StorySection: React.FC<StorySectionProps> = ({
  title,
  children,
  className,
  contentClassName,
}) => (
  <section className={cx(`flex flex-col gap-3`, className)}>
    <h2 className="text-xs text-stone-500">{title}</h2>
    <div className={cx(`flex flex-wrap items-center gap-3`, contentClassName)}>
      {children}
    </div>
  </section>
);
