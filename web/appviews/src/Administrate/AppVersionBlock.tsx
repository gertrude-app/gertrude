import { SelectMenu } from '@dash/components';
import { Button } from '@shared/components';
import React from 'react';

interface Props {
  appVersion: string;
}

const AppVersionBlock: React.FC<Props> = ({ appVersion }) => {
  return (
    <div className="p-4 bg-slate-50 dark:bg-black/10 rounded-xl">
      <h3 className="font-semibold text-xl text-slate-600 dark:text-slate-400">
        Running version{` `}
        <span className="font-black text-violet-700 dark:text-violet-400">
          {appVersion}
        </span>
        {` `}
        of Gertrude
      </h3>
      <div className="flex justify-between mt-4">
        <div className="flex space-x-4">
          <Button type="button" onClick={() => {}} color="secondary" size="small">
            Check for updates
          </Button>
          <SelectMenu
            size="small"
            options={[
              { value: `stable`, display: `stable versions` },
              { value: `insiders`, display: `insider versions` },
              { value: `nightly`, display: `nightly versions` },
            ]}
            selectedOption={`stable`}
            setSelected={() => {}}
          />
        </div>
        <Button type="button" onClick={() => {}} color="tertiary" size="small">
          Reinstall
        </Button>
      </div>
    </div>
  );
};

export default AppVersionBlock;
