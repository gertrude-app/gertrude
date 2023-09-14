import React from 'react';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const LocateMenuBarIcon: React.FC<Props> = ({ emit }) => (
  <div>
    <h1 className="text-3xl">Find the Menu Bar Icon</h1>
    <p className="my-3">
      From now on, you'll click the <b>menu bar icon</b> whenever you or your child needs
      to
      {` `}
      <em>interact with the Gertrude app.</em>
    </p>
    <p className="mb-3">
      Look up in the top right corner of your screen to find it, and give it a click.
    </p>
    <img
      className="h-[220px] rounded-lg mb-4"
      src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/menu-bar-icon.png"
      alt=""
    />
    <button
      className="bg-blue-500 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `secondaryBtnClicked` })}
    >
      Found it, next &rarr;
    </button>
  </div>
);

export default LocateMenuBarIcon;
