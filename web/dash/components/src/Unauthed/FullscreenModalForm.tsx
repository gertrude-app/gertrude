import React from 'react';
import cx from 'classnames';
import { Button, Loading } from '@shared/components';
import GradientIcon from '../GradientIcon';
import FullscreenGradientBg from './FullscreenGradientBg';

type Props =
  | { state: `idle`; children: React.ReactNode }
  | { state: `ongoing`; text?: string }
  | { state: `failed`; error: React.ReactNode }
  | { state: `succeeded`; message: string }
  | { state: `custom`; children: React.ReactNode };

const FullscreenModalForm: React.FC<Props> = (props) => {
  switch (props.state) {
    case `ongoing`:
      return (
        <FullscreenGradientBg>
          <Loading withWhiteBg />
        </FullscreenGradientBg>
      );

    case `succeeded`:
    case `failed`:
    case `custom`:
      return (
        <FullscreenGradientBg>
          <div
            className={cx(
              `bg-white font-sans max-w-lg rounded-2xl mx-4 pt-8 pl-7 pr-8 shadow-lg flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4 relative items-center`,
              props.state !== `succeeded` ? `sm:items-start pb-6` : `pb-8`,
            )}
          >
            <GradientIcon
              icon={props.state === `failed` ? `exclamation-triangle` : `thumbs-up`}
              size="medium"
            />
            <div className="flex flex-col items-center sm:items-end">
              {props.state === `custom` ? (
                props.children
              ) : (
                <>
                  <p className="text-center sm:text-left text-slate-500">
                    {props.state === `succeeded` ? props.message : props.error}
                  </p>
                  {props.state === `failed` && (
                    <Button
                      color="secondary"
                      type="external"
                      href="https://gertrude.app/contact"
                      className="mt-5"
                    >
                      Contact support &rarr;
                    </Button>
                  )}
                </>
              )}
            </div>
          </div>
        </FullscreenGradientBg>
      );
  }

  return (
    <FullscreenGradientBg>
      <div className="pb-8 sm:pb-8 pt-12 px-5 sm:px-8 w-full max-w-md rounded-2xl shadow-lg flex justify-center items-center flex-row bg-white relative z-10 mx-3 sm:mx-10">
        {props.children}
      </div>
    </FullscreenGradientBg>
  );
};

export default FullscreenModalForm;
