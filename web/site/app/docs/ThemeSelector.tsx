import { useEffect, useState } from 'react';
import { Listbox } from '@headlessui/react';
import cx from 'classnames';

interface Props {
  className?: string;
}

const ThemeSelector: React.FC<Props> = ({ className }) => {
  const [selectedTheme, setSelectedTheme] = useState<typeof themes[number] | null>(null);

  useEffect(() => {
    if (selectedTheme) {
      document.documentElement.setAttribute(`data-theme`, selectedTheme.value);
    } else {
      setSelectedTheme(
        themes.find(
          (theme) => theme.value === document.documentElement.getAttribute(`data-theme`),
        ) ?? null,
      );
    }
  }, [selectedTheme]);

  useEffect(() => {
    function handler(): void {
      setSelectedTheme(
        themes.find((theme) => theme.value === (window.localStorage.theme ?? `system`)) ??
          null,
      );
    }

    window.addEventListener(`storage`, handler);

    return () => window.removeEventListener(`storage`, handler);
  }, []);

  return (
    <Listbox
      as="div"
      value={selectedTheme}
      onChange={setSelectedTheme}
      className={className}
    >
      <Listbox.Label className="sr-only">Theme</Listbox.Label>
      <Listbox.Button
        className="flex h-6 w-6 items-center justify-center rounded-lg shadow-md shadow-black/5 ring-1 bg-slate-700 ring-inset ring-white/5"
        aria-label={selectedTheme?.name}
      >
        <DarkIcon className="h-4 w-4 fill-violet-400" />
        <DarkIcon className="h-4 w-4 fill-slate-400" />
      </Listbox.Button>
      <Listbox.Options className="absolute top-full left-1/2 mt-3 w-36 -translate-x-1/2 space-y-1 rounded-xl p-3 text-sm font-medium shadow-md shadow-black/5 ring-1 bg-slate-800 ring-white/5">
        {themes.map((theme) => (
          <Listbox.Option
            key={theme.value}
            value={theme}
            className={({ active, selected }) =>
              cx(`flex cursor-pointer select-none items-center rounded-[0.625rem] p-1`, {
                'text-violet-400': selected,
                'text-white': active && !selected,
                'text-slate-400': !active && !selected,
                'bg-slate-900/40': active,
              })
            }
          >
            {({ selected }) => (
              <>
                <div className="rounded-md p-1 shadow ring-1 bg-slate-700 ring-inset ring-white/5">
                  <theme.icon
                    className={cx(
                      `h-4 w-4`,
                      selected ? `fill-violet-400` : `fill-slate-400`,
                    )}
                  />
                </div>
                <div className="ml-3">{theme.name}</div>
              </>
            )}
          </Listbox.Option>
        ))}
      </Listbox.Options>
    </Listbox>
  );
};

export default ThemeSelector;

const LightIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg aria-hidden="true" viewBox="0 0 16 16" className={className}>
    <path
      fillRule="evenodd"
      clipRule="evenodd"
      d="M7 1a1 1 0 0 1 2 0v1a1 1 0 1 1-2 0V1Zm4 7a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm2.657-5.657a1 1 0 0 0-1.414 0l-.707.707a1 1 0 0 0 1.414 1.414l.707-.707a1 1 0 0 0 0-1.414Zm-1.415 11.313-.707-.707a1 1 0 0 1 1.415-1.415l.707.708a1 1 0 0 1-1.415 1.414ZM16 7.999a1 1 0 0 0-1-1h-1a1 1 0 1 0 0 2h1a1 1 0 0 0 1-1ZM7 14a1 1 0 1 1 2 0v1a1 1 0 1 1-2 0v-1Zm-2.536-2.464a1 1 0 0 0-1.414 0l-.707.707a1 1 0 0 0 1.414 1.414l.707-.707a1 1 0 0 0 0-1.414Zm0-8.486A1 1 0 0 1 3.05 4.464l-.707-.707a1 1 0 0 1 1.414-1.414l.707.707ZM3 8a1 1 0 0 0-1-1H1a1 1 0 0 0 0 2h1a1 1 0 0 0 1-1Z"
    />
  </svg>
);

const DarkIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg aria-hidden="true" viewBox="0 0 16 16" className={className}>
    <path
      fillRule="evenodd"
      clipRule="evenodd"
      d="M7.23 3.333C7.757 2.905 7.68 2 7 2a6 6 0 1 0 0 12c.68 0 .758-.905.23-1.332A5.989 5.989 0 0 1 5 8c0-1.885.87-3.568 2.23-4.668ZM12 5a1 1 0 0 1 1 1 1 1 0 0 0 1 1 1 1 0 1 1 0 2 1 1 0 0 0-1 1 1 1 0 1 1-2 0 1 1 0 0 0-1-1 1 1 0 1 1 0-2 1 1 0 0 0 1-1 1 1 0 0 1 1-1Z"
    />
  </svg>
);

const SystemIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg aria-hidden="true" viewBox="0 0 16 16" className={className}>
    <path
      fillRule="evenodd"
      clipRule="evenodd"
      d="M1 4a3 3 0 0 1 3-3h8a3 3 0 0 1 3 3v4a3 3 0 0 1-3 3h-1.5l.31 1.242c.084.333.36.573.63.808.091.08.182.158.264.24A1 1 0 0 1 11 15H5a1 1 0 0 1-.704-1.71c.082-.082.173-.16.264-.24.27-.235.546-.475.63-.808L5.5 11H4a3 3 0 0 1-3-3V4Zm3-1a1 1 0 0 0-1 1v4a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H4Z"
    />
  </svg>
);

const themes = [
  { name: `Light`, value: `light`, icon: LightIcon },
  { name: `Dark`, value: `dark`, icon: DarkIcon },
  { name: `System`, value: `system`, icon: SystemIcon },
];
