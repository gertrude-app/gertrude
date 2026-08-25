import { Button } from '@gertrude/ui';
import { ChevronLeftIcon } from 'lucide-react';
import React from 'react';

interface Props {
  form: React.ReactNode;
  rightDisplay?: React.ReactNode;
}

const UnauthedPageLayout: React.FC<Props> = ({ form, rightDisplay }) => (
  <div className="flex min-h-screen">
    <div
      className={`flex flex-col xs:justify-center xs:items-center w-full relative xs:[background-image:url(/dot-noise-pattern.svg),url(/bg.svg)] xs:[background-size:1440px_1440px,cover] xs:[background-repeat:repeat,no-repeat] ${rightDisplay ? `xl:w-1/2` : ``}`}
    >
      <div className="absolute top-2 left-2">
        <Button
          type="link"
          href="https://gertrude.app"
          variant="ghost"
          icon={ChevronLeftIcon}
        >
          Home
        </Button>
      </div>
      {form}
    </div>
    {rightDisplay && (
      <div className="h-screen overflow-hidden bg-white w-1/2 border-l border-stone-200 hidden xl:block">
        {rightDisplay}
      </div>
    )}
  </div>
);

export default UnauthedPageLayout;
