import cx from 'classnames';
import Link from 'next/link';
import React from 'react';

type IOSVersion = `ios-16` | `ios-17` | `ios-18` | `ios-26`;

type Props = {
  current: IOSVersion;
};

const GUIDE_PATH = `/guides/locking-down-an-iphone`;

const LATEST: IOSVersion = `ios-26`;

const versions: Array<{ id: IOSVersion; label: string }> = [
  { id: `ios-16`, label: `iOS 16` },
  { id: `ios-17`, label: `iOS 17` },
  { id: `ios-18`, label: `iOS 18` },
  { id: `ios-26`, label: `iOS 26` },
];

function versionHref(id: IOSVersion): string {
  return id === LATEST ? GUIDE_PATH : `${GUIDE_PATH}/${id}`;
}

const IOSVersionPicker: React.FC<Props> = ({ current }) => (
  <nav
    aria-label="Choose an iOS guide version"
    className="not-prose my-10 rounded-[24px] border border-white bg-white/50 p-3 shadow-md shadow-violet-950/5 xs:flex xs:items-center xs:justify-between xs:gap-5 xs:p-4"
  >
    <span className="block px-2 pb-3 text-base font-semibold text-stone-950 xs:pb-0">
      Choose your iOS version
    </span>
    <div className="grid grid-cols-4 gap-1 rounded-2xl bg-white/50 p-1">
      {versions.map((version) => {
        const selected = version.id === current;
        return (
          <Link
            key={version.id}
            href={versionHref(version.id)}
            aria-current={selected ? `page` : undefined}
            className={cx(
              `rounded-xl px-4 py-2 text-center text-sm font-semibold transition-colors duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-violet-400 focus-visible:ring-offset-2 focus-visible:ring-offset-violet-50`,
              selected
                ? `bg-violet-600 text-white shadow-sm`
                : `text-stone-700 hover:bg-white hover:text-violet-700`,
            )}
          >
            {version.label}
          </Link>
        );
      })}
    </div>
  </nav>
);

export default IOSVersionPicker;
