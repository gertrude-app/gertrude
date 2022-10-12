import React from 'react';
import cx from 'classnames';
import FullscreenGradientBg from '../FullscreenGradientBg';
import LoadingSpinner from '../../../LoadingSpinner';

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
              `bg-white font-sans rounded-2xl mx-4 px-10 py-6 shadow-lg flex items-center`,
              props.request === `succeeded` ? `text-green-900` : `text-red-800`,
            )}
          >
            <span role="img" aria-hidden className="text-3xl pr-3">
              {props.request === `succeeded` ? `🎉 ` : `😢`}
            </span>
            <span>{props.request === `succeeded` ? props.message : props.error}</span>
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
