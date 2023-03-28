import React, { useState } from 'react';
import cx from 'classnames';
import { Button, TextInput } from '@shared/components';
import { Transition } from '@headlessui/react';

const RequestSuspension: React.FC = () => {
  const [reason, setReason] = useState(``);
  const [duration, setDuration] = useState<number | null>(null);
  const [popupOpen, setPopupOpen] = useState(false);
  const [popupPage, setPopupPage] = useState<1 | 2>(1);
  const [customDuration, setCustomDuration] = useState(``);

  return (
    <div className="h-full flex items-stretch flex-col bg-white dark:bg-slate-900 rounded-b-xl relative">
      <Transition
        show={popupOpen}
        enter="transition-opacity duration-75"
        enterFrom="opacity-0"
        enterTo="opacity-100"
        leave="transition-opacity duration-150"
        leaveFrom="opacity-100"
        leaveTo="opacity-0"
      >
        <div
          className={cx(
            `absolute flex justify-center items-center w-full h-full top-0 left-0 bg-black/60 z-40 rounded-b-xl`,
          )}
          onClick={() => {
            setPopupOpen(false);
            setPopupPage(1);
          }}
        >
          <div
            className={cx(
              `h-[330px] w-96 bg-white dark:bg-slate-800 rounded-xl shadow-xl relative overflow-hidden`,
            )}
            onClick={(event) => event.stopPropagation()}
          >
            <div
              className={cx(
                `absolute w-full flex flex-col items-stretch top-0 p-4 [transition:200ms]`,
                popupPage === 1 ? `left-0 opacity-100` : `-left-96 opacity-0`,
              )}
            >
              <h3 className="font-bold mb-3 dark:text-slate-100">Suspension duration</h3>
              <div className="grid grid-cols-2 gap-2">
                {[3, 5, 10, 20, 30, 60, 90, 120].map((minutes) => (
                  <button
                    key={minutes}
                    className="text-left rounded-lg px-3 py-2 bg-slate-50 dark:bg-slate-700 font-medium text-slate-700 dark:text-slate-100 hover:bg-slate-100 dark:hover:bg-slate-600 transition duration-100"
                    onClick={() => {
                      setDuration(minutes);
                      setPopupOpen(false);
                      setCustomDuration(``);
                    }}
                  >
                    {minutes > 59 ? minutes / 60 : minutes}
                    {` `}
                    {minutes > 59 ? (minutes === 60 ? `hour` : `hours`) : `minutes`}
                  </button>
                ))}
              </div>
              <div className="flex justify-center my-2.5">
                <span className="before:[content:'-_'] after:[content:'_-'] uppercase text-sm text-slate-400">
                  or
                </span>
              </div>
              <button
                className="rounded-lg p-2 bg-slate-50 dark:bg-slate-700 font-medium text-slate-700 dark:text-slate-100 text-center hover:bg-slate-100 dark:hover:bg-slate-600"
                onClick={() => {
                  setPopupPage(2);
                }}
              >
                Custom duration...
              </button>
            </div>
            <div
              className={cx(
                `absolute w-full h-full top-0 [transition:200ms] flex flex-col justify-between`,
                popupPage === 2 ? `left-0 opacity-100` : `left-96 opacity-0`,
              )}
            >
              <div className="p-4">
                <h3 className="font-bold mb-3 dark:text-slate-100">
                  Choose a custom duration
                </h3>
                <TextInput
                  type="positiveInteger"
                  value={customDuration}
                  setValue={setCustomDuration}
                  unit="minutes"
                />
              </div>
              <div className="flex justify-between items-center bg-slate-50 dark:bg-slate-900/50 p-4 rounded-b-xl">
                <Button
                  type="button"
                  onClick={() => setPopupPage(1)}
                  color="tertiary"
                  size="medium"
                >
                  <i className="fa-solid fa-arrow-left mr-2" />
                  Back
                </Button>
                <Button
                  type="button"
                  onClick={() => {
                    setDuration(Number(customDuration));
                    setPopupOpen(false);
                    setPopupPage(1);
                  }}
                  color="secondary"
                  size="medium"
                  disabled={!customDuration}
                >
                  Choose
                  <i className="fa-solid fa-check ml-2" />
                </Button>
              </div>
            </div>
          </div>
        </div>
      </Transition>
      <div className="p-8 bg-slate-50 dark:bg-slate-900 flex-grow flex justify-center flex-col items-center">
        <h2 className="text-lg font-semibold text-center dark:text-slate-100">
          Request temporary filter suspension
        </h2>
        <TextInput
          type="textarea"
          value={reason}
          setValue={setReason}
          rows={5}
          label="Reason:"
          noResize
          placeholder="Super compelling reason"
        />
      </div>
      <div className="flex justify-between items-center p-4 dark:bg-black/10 rounded-b-xl border-t border-slate-200 dark:border-slate-800">
        <Button
          type="button"
          onClick={() => setPopupOpen(true)}
          color="tertiary"
          size="medium"
        >
          <i className="fa-regular fa-clock mr-2" />
          {duration ? displayDuration(duration, !!customDuration) : `Choose duration...`}
        </Button>
        <Button
          type="button"
          onClick={() => {}}
          color="secondary"
          size="medium"
          disabled={!duration}
        >
          Submit
          <i className="fa-solid fa-arrow-right ml-2" />
        </Button>
      </div>
    </div>
  );
};

export default RequestSuspension;

function displayDuration(minutes: number, custom: boolean): string {
  if (minutes >= 60 && !custom) {
    return `${minutes / 60} hour${minutes / 60 !== 1 ? `s` : ``}`;
  } else {
    return `${minutes} minute${minutes !== 1 ? `s` : ``}`;
  }
}
