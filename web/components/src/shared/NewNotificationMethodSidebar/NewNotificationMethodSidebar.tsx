import React from 'react';
import cx from 'classnames';
import Button from '../Button';

type Props = {
  open: boolean;
  setOpen(open: boolean): void;
};

const EditNotificationSidebar: React.FC<Props> = ({ open, setOpen }) => (
  <div
    className={cx(
      `fixed bg-white top-0 right-0 w-96 h-screen border-l shadow-xl [transition:150ms] z-30 flex flex-col justify-beween`,
      open ? 'mr-0' : '-mr-112',
    )}
  >
    <div className="p-8 flex-grow">
      <h2 className="text-2xl font-black text-gray-700">New notification method</h2>
    </div>
    <div className="px-6 py-4 flex justify-center space-x-4">
      <Button
        type="button"
        onClick={() => setOpen(false)}
        color="secondary-white"
        className="flex-grow"
      >
        Cancel
      </Button>
      <Button
        type="button"
        onClick={() => {}}
        color="primary-violet"
        className="flex-grow"
      >
        Save
      </Button>
    </div>
  </div>
);

export default EditNotificationSidebar;
