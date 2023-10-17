import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';

interface Props {
  open: boolean;
  setOpen: (open: boolean) => void;
  children: React.ReactNode;
}

const InformationModal: React.FC<Props> = ({ open, setOpen, children }) => (
  <div
    onClick={() => setOpen(false)}
    className={cx(
      `absolute left-0 top-0 w-full h-full bg-black/50 z-40 transition-[opacity,backdrop-filter] duration-300 flex justify-center items-center p-12`,
      open ? `opacity-100 backdrop-blur` : `opacity-0 pointer-events-none`,
    )}
  >
    <div
      className={cx(
        `bg-white rounded-3xl transition-[opacity,transform] duration-500`,
        open ? `opacity-100` : `opacity-0 translate-y-8`,
      )}
      onClick={(e) => e.stopPropagation()}
    >
      <div className="max-w-3xl p-10 pb-6 text-slate-600 text-lg">{children}</div>
      <div className="flex justify-end p-4 pt-0 rounded-b-3xl">
        <Button
          color="tertiary"
          size="medium"
          type="button"
          onClick={() => setOpen(false)}
        >
          Got it <i className="fa-solid fa-check ml-2" />
        </Button>
      </div>
    </div>
  </div>
);

export default InformationModal;
