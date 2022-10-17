import React from 'react';
import cx from 'classnames';
import FullscreenGradientBg from '../FullscreenGradientBg';
import LoadingSpinner from '../../../LoadingSpinner';
import GradientIcon from '../../GradientIcon';
import Button from '../../../Button';

type Props =
  | { request: `idle`; children: React.ReactNode }
  | { request: `ongoing`; text?: string }
  | { request: `failed`; error: React.ReactNode }
  | { request: `succeeded`; message: string };

const FullscreenModalForm: React.FC<Props> = (props) => {
  switch (props.request) {
    case `ongoing`:
      return (
        <FullscreenGradientBg>
          <LoadingSpinner text={props.text} />
        </FullscreenGradientBg>
      );

    case `succeeded`:
    case `failed`:
      return (
        <FullscreenGradientBg>
          <div
            className={cx(
              `bg-white font-sans max-w-lg rounded-2xl mx-4 pt-8 pl-7 pr-8 shadow-lg flex space-x-4`,
              props.request === `failed` ? `items-start pb-6` : `items-center pb-8`,
            )}
          >
            <GradientIcon
              icon={props.request === `succeeded` ? `thumbs-up` : `exclamation-triangle`}
              size="medium"
            />
            <div className="flex flex-col items-end">
              <p className={cx(props.request === `failed` ?? `text-red-900`)}>
                {props.request === `succeeded` ? props.message : props.error}
              </p>
              {props.request === `failed` && (
                <Button
                  color="secondary-white"
                  type="external"
                  href="https://gertrude.app/contact"
                  small
                  className="mt-5"
                >
                  Contact support &rarr;
                </Button>
              )}
            </div>
          </div>
        </FullscreenGradientBg>
      );
  }

  return (
    <FullscreenGradientBg>
      <div className="py-8 sm:py-12 px-5 sm:px-12 rounded-2xl shadow-lg flex justify-center items-center flex-col border bg-white relative z-10 mx-3 sm:mx-10">
        {props.children}
      </div>
    </FullscreenGradientBg>
  );
};

export default FullscreenModalForm;
