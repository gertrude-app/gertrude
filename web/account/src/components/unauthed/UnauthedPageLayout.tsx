import { Button } from '@gertrude/ui';
import { ChevronLeftIcon } from 'lucide-react';
import React from 'react';
import StandalonePagePanel from '#/components/layout/StandalonePagePanel';

interface Props {
  form: React.ReactNode;
  rightDisplay?: React.ReactNode;
}

const UnauthedPageLayout: React.FC<Props> = ({ form, rightDisplay }) => (
  <div className="flex min-h-screen">
    <StandalonePagePanel className={rightDisplay ? `xl:w-1/2` : undefined}>
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
    </StandalonePagePanel>
    {rightDisplay && (
      <div className="h-screen overflow-hidden bg-white w-1/2 border-l border-stone-200 hidden xl:block">
        {rightDisplay}
      </div>
    )}
  </div>
);

export default UnauthedPageLayout;
