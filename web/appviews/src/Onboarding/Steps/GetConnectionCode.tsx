import React, { useRef, useState } from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import type { AppEvent } from '../onboarding-store';
import ExpandableImage from '../ExpandableImage';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const GetConnectionCode: React.FC<Props> = ({ emit }) => {
  const imageFrameRef = useRef<HTMLDivElement>(null);
  const [imageExpanded, setImageExpanded] = useState(false);
  return (
    <div className="flex flex-row items-center justify-center h-full p-12 gap-12 relative">
      <div>
        <h1 className="text-3xl font-bold">Get Connection Code</h1>
        <p className="mt-4 mb-6 text-lg text-slate-500 max-w-2xl">
          On your phone, open the Gertrude parents website at{` `}
          <span className="font-medium">parents.gertrude.app</span>, and select the child
          you want to connect to. Then, click the <b>Get Connection Code</b> button.
        </p>
        <div className="flex flex-col gap-4">
          <Button
            color="primary"
            size="large"
            type="button"
            onClick={() => emit({ case: `primaryBtnClicked` })}
            className="shadow shadow-violet-200/80"
          >
            Got it, next <i className="fa-solid fa-arrow-right ml-2" />
          </Button>
          <Button
            color="secondary"
            size="large"
            type="button"
            onClick={() => emit({ case: `primaryBtnClicked` })}
            className="shadow shadow-violet-200/80"
          >
            I need help...
          </Button>
        </div>
      </div>
      <ExpandableImage
        src="https://gertrude.nyc3.digitaloceanspaces.com/appview-assets/onboarding/get-connection-code.png"
        alt="TODO"
        width={400}
        height={260}
      />
    </div>
  );
};

export default GetConnectionCode;
