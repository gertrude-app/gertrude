import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent } from '../onboarding-store';
import ExpandableImage from '../ExpandableImage';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const LocateMenuBarIcon: React.FC<Props> = ({ emit }) => (
  <div className="flex flex-col justify-center items-center h-full p-12">
    <h1 className="text-3xl font-bold">Find the menu bar icon</h1>
    <p className="mt-4 mb-2 text-slate-500 text-lg text-center max-w-2xl">
      From now on, you'll click the <b>menu bar icon</b> whenever you or your child needs
      to <em>interact with the Gertrude app.</em>
    </p>
    <p className="mb-8 text-slate-500 text-lg text-center max-w-2xl">
      Look up in the top right corner of your screen to find it, and give it a click.
    </p>
    <ExpandableImage
      src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/menu-bar-icon.png"
      alt={`Locate menu bar icon`}
      width={560}
      height={220}
    />
    <Button
      type="button"
      onClick={() => emit({ case: `primaryBtnClicked` })}
      color="primary"
      size="large"
      className="mt-8"
    >
      Found it, next
    </Button>
  </div>
);

export default LocateMenuBarIcon;
