import React, { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import cx from 'classnames';
import {
  CheckIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  ClockIcon,
  KeyIcon,
  MagnifyingGlassIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline';
import { Badge, Button, Loading } from '@shared/components';
import { inflect } from '@shared/string';
import { defaults, type KeychainSummary as Keychain } from '@dash/types';
import type { KeychainSchedule as Schedule, RequestState } from '@dash/types';
import KeychainSchedule from '../Keychains/schedule/KeychainSchedule';

interface Props {
  request?: RequestState<{ own: Keychain[]; public: Keychain[] }>;
  selected?: Keychain;
  onSelect(keychain: Keychain): unknown;
  schedule?: Schedule;
  setSchedule(schedule?: Schedule): unknown;
  onDismiss(): unknown;
  onConfirm(): unknown;
  existingKeychains: Keychain[];
  userName: string;
}

const AddKeychainDrawer: React.FC<Props> = ({
  onDismiss,
  onConfirm,
  request,
  onSelect,
  selected,
  existingKeychains,
  userName,
  schedule,
  setSchedule,
}) => {
  const shown = request && request.state !== `idle`;
  const [whichKeychains, setWhichKeychains] = useState<'own' | 'public'>(`own`);
  const [searchQuery, setSearchQuery] = useState(``);
  const [page, setPage] = useState(1);
  const [prevSelected, setPrevSelected] = useState<Keychain | undefined>(undefined);
  const [showNew, setShowNew] = useState(false);

  const keychainsToDisplay =
    request?.state === `succeeded`
      ? request.payload[whichKeychains]
          .filter((k) => !existingKeychains.some((ek) => ek.id === k.id))
          .filter(
            (k) =>
              k.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
              (k.description &&
                k.description.toLowerCase().includes(searchQuery.toLowerCase())),
          )
      : [];
  const numPages = Math.ceil(keychainsToDisplay.length / 6);

  // esc to close:
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent): void => {
      if (e.key === `Escape`) {
        onDismiss();
      }
    };
    if (shown) document.addEventListener(`keydown`, handleKeyDown);
    return () => document.removeEventListener(`keydown`, handleKeyDown);
  }, [onDismiss, shown]);

  useEffect(() => {
    setShowNew(true);
  }, [selected]);

  const emptyState = (() => {
    switch (true) {
      case request?.state === `idle` || request?.state === `ongoing`:
        return (
          <div className="flex justify-center items-center w-full h-full">
            <Loading />
          </div>
        );
      case request?.state === `succeeded` && searchQuery.length > 0:
        return (
          <div className="w-full h-full flex justify-center items-center">
            <div className="flex flex-col items-center p-6 sm:p-12 bg-slate-100 rounded-3xl">
              <div className="w-10 sm:w-14 h-10 sm:h-14 bg-slate-200 rounded-full flex justify-center items-center mb-4">
                <i className="fa-solid fa-cow text-xl sm:text-2xl text-slate-400" />
              </div>
              <h2 className="text-lg sm:text-xl font-medium text-slate-500 text-center">
                Hmm, we couldn't find that keychain
              </h2>
            </div>
          </div>
        );
      case request?.state === `succeeded` &&
        whichKeychains === `own` &&
        keychainsToDisplay.length === 0:
        return (
          <div className="w-full h-full flex justify-center items-center">
            <div className="flex flex-col items-center p-12 bg-slate-100 rounded-3xl">
              <div className="w-10 sm:w-14 h-10 sm:h-14 bg-slate-200 rounded-full flex justify-center items-center mb-4">
                <i className="fa-solid fa-key text-xl sm:text-2xl text-slate-400" />
              </div>
              <h2 className="text-lg sm:text-xl font-medium text-slate-500 text-center">
                Looks like you don't have any keychains
              </h2>
              <Button type="link" to="/keychains" color="primary" className="mt-6">
                <i className="fa-solid fa-plus mr-2" />
                Create one
              </Button>
            </div>
          </div>
        );
      case request?.state === `succeeded` &&
        whichKeychains === `public` &&
        keychainsToDisplay.length === 0:
        return <div className="flex justify-center items-center h-full">Hi Jared :)</div>;
      case request?.state === `failed`:
      default:
        return (
          <div className="w-full h-full flex justify-center items-center">
            <div className="flex flex-col items-center p-12 bg-slate-100 rounded-3xl">
              <h2 className="text-lg sm:text-xl font-medium text-slate-500 text-center">
                Hmm, something went wrong
              </h2>
              <p className="text-slate-500 mt-1 text-center">
                Try refreshing the page and trying again
              </p>
            </div>
          </div>
        );
    }
  })();

  return createPortal(
    <div
      className={cx(
        `fixed left-0 top-0 w-full h-full transition-colors duration-300 z-50 flex justify-center items-end`,
        shown ? `bg-slate-200/60` : `bg-black/0 pointer-events-none`,
      )}
      onClick={onDismiss}
    >
      <div
        className={cx(
          `bg-white pb-12 rounded-3xl lg:rounded-t-[40px] shadow-2xl shadow-black/30 transition-transform duration-300 flex-grow max-w-[1000px]`,
          !shown ? `translate-y-[100%]` : `translate-y-12`,
        )}
        onClick={(e) => e.stopPropagation()}
      >
        <header className="px-3.5 lg:px-5 py-2 lg:py-4 flex items-center justify-between border-b border-slate-200">
          <div className="flex items-center gap-4">
            <div className="w-8 lg:w-10 h-8 lg:h-10 rounded-full bg-slate-200 flex justify-center items-center border border-slate-300">
              <KeyIcon className="w-5 lg:w-6 h-5 lg:h-6 text-slate-500" strokeWidth={2} />
            </div>
            <div>
              <h2 className="text-xl lg:text-2xl font-semibold -mb-1.5 lg:-mb-1">
                Add a keychain
              </h2>
              <span className="text-sm lg:text-base font-medium text-slate-500">
                to child <span className="text-violet-500">{userName}</span>
              </span>
            </div>
          </div>
          <button
            className="w-8 lg:w-10 h-8 lg:h-10 bg-slate-100 rounded-full flex justify-center items-center text-slate-400 hover:bg-slate-200 active:bg-slate-300 active:scale-90 transition-[transform,background-color] duration-150"
            onClick={() => onDismiss()}
          >
            <XMarkIcon className="w-5" strokeWidth={2.5} />
          </button>
        </header>
        <main className="bg-slate-50 pt-4 lg:pt-8 pb-2">
          <div className="flex justify-between px-4 lg:px-0 lg:justify-center items-center flex-col sm:flex-row lg:flex-col gap-4">
            <div className="relative flex-grow w-full xs:w-auto">
              <MagnifyingGlassIcon
                className="absolute w-5 top-2 lg:top-2.5 left-3 text-slate-500"
                strokeWidth={2.5}
              />
              <input
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setPage(1);
                }}
                placeholder="Search..."
                className="w-full xs:w-[400px] sm:w-full md+:w-[400px] text-lg py-1 lg:py-1.5 rounded-full bg-slate-200 hover:bg-slate-300/80 pl-10 outline-transparent outline-offset-0 transition-[outline-color,outline-offset,background-color] duration-200 focus:outline-offset-4 focus:outline-violet-500 placeholder:text-slate-400"
              />
            </div>
            <div className="bg-slate-200/70 rounded-xl">
              <button
                className={cx(
                  `px-4 py-1 rounded-xl border-[0.5px] font-medium transition-[background-color,color,box-shadow] duration-200`,
                  whichKeychains === `own`
                    ? `bg-white shadow text-slate-600 hover:text-slate-600 border-slate-200`
                    : `text-slate-500 hover:bg-slate-200 hover:text-slate-600 border-transparent`,
                )}
                onClick={() => {
                  setWhichKeychains(`own`);
                  setPage(1);
                }}
              >
                My keychains
              </button>
              <button
                className={cx(
                  `px-4 py-1 rounded-xl border-[0.5px] font-medium transition-[background-color,color,box-shadow] duration-200`,
                  whichKeychains === `public`
                    ? `bg-white shadow text-slate-600 hover:text-slate-600 border-slate-200`
                    : `text-slate-500 hover:bg-slate-200 hover:text-slate-600 border-transparent`,
                )}
                onClick={() => {
                  setWhichKeychains(`public`);
                  setPage(1);
                }}
              >
                Public keychains
              </button>
            </div>
          </div>
          <div className="flex sm:hidden w-screen overflow-scroll gap-4 p-4 pt-5 xs:pt-8 items-center">
            {keychainsToDisplay.length > 0
              ? keychainsToDisplay.map((k) => (
                  <SelectableKeychain
                    key={k.id}
                    keychain={k}
                    selected={selected}
                    setPrevSelected={setPrevSelected}
                    setShowNew={setShowNew}
                    onSelect={onSelect}
                  />
                ))
              : emptyState}
          </div>
          <div className="h-[260px] min-[1000px]:h-[312px] relative overflow-hidden hidden sm:block">
            <button
              className={cx(
                `absolute mt-10 lg:mt-0 h-[200px] lg:h-full w-14 top-0 left-0 flex justify-center items-center rounded-r-3xl hover:bg-slate-200/50 z-20 transition-[background-color,transform,opacity] duration-200 active:bg-slate-200`,
                page === 1 && `-translate-x-8 opacity-0 pointer-events-none`,
              )}
              onClick={() => setPage(page - 1)}
            >
              <ChevronLeftIcon className="w-7 text-slate-400" strokeWidth={2.5} />
            </button>
            <button
              className={cx(
                `absolute mt-10 lg:mt-0 h-[200px] lg:h-full w-14 top-0 right-0 flex justify-center items-center rounded-l-3xl hover:bg-slate-200/50 z-20 transition-[background-color,transform,opacity] duration-200 active:bg-slate-200`,
                (page === numPages || numPages === 0) &&
                  `translate-x-8 opacity-0 pointer-events-none`,
              )}
              onClick={() => setPage(page + 1)}
            >
              <ChevronRightIcon className="w-7 text-slate-400" strokeWidth={2.5} />
            </button>
            {keychainsToDisplay.length > 0
              ? Array.from({ length: numPages }).map((_, i) => (
                  <div
                    key={`index-${i}`}
                    className={cx(
                      `mt-5 px-16 flex flex-wrap gap-4 justify-center items-center content-start absolute w-full h-full transition-[opacity,transform] duration-300 max-[999px]:overflow-y-scroll`,
                      {
                        '-translate-x-[100%] opacity-0': i + 1 < page,
                        'translate-x-0': i + 1 === page,
                        'translate-x-[100%] opacity-0': i + 1 > page,
                      },
                    )}
                  >
                    <div className="sticky h-12 w-full z-20 top-0 left-0 bg-gradient-to-b from-slate-50 to-transparent min-[1000px]:hidden pointer-events-none" />
                    <div className="sticky h-12 w-full z-20 top-[calc(100%-68px)] left-0 bg-gradient-to-t from-slate-50 to-transparent min-[1000px]:hidden pointer-events-none" />
                    {keychainsToDisplay.slice(i * 6, (i + 1) * 6).map((k) => (
                      <SelectableKeychain
                        key={k.id}
                        keychain={k}
                        selected={selected}
                        setPrevSelected={setPrevSelected}
                        setShowNew={setShowNew}
                        onSelect={onSelect}
                      />
                    ))}
                  </div>
                ))
              : emptyState}
          </div>
          <div className="flex justify-center gap-4 pb-4 h-11 hidden sm:flex">
            {numPages > 1 &&
              Array.from({ length: numPages }).map((_, i) => (
                <button
                  key={i}
                  className={cx(
                    `rounded-full w-7 h-7 flex justify-center items-center font-medium hover:scale-110 transition-[background-color,transform] duration-150 active:scale-90`,
                    i + 1 === page
                      ? `bg-violet-200 text-violet-700`
                      : `bg-slate-200/50 text-slate-400 hover:bg-slate-200 active:bg-slate-300`,
                  )}
                  onClick={() => setPage(i + 1)}
                >
                  {i + 1}
                </button>
              ))}
          </div>
        </main>
        <footer className="border-t border-slate-200 bg-white p-6 relative">
          <div className="flex justify-start items-center gap-2 pb-4 sm:h-[52px]">
            {schedule ? (
              <>
                <KeychainSchedule schedule={schedule} setSchedule={setSchedule} />
                <button
                  onClick={() => setSchedule(undefined)}
                  className="h-4 w-4 flex justify-center items-center rounded-full hover:scale-150 hover:bg-slate-200 transition-[transform,background-color] duration-200 group active:scale-100 active:bg-slate-300"
                >
                  <XMarkIcon
                    strokeWidth={3}
                    className="w-4 h-4 text-slate-400 group-hover:scale-75 transition-transform duration-200"
                  />
                </button>
              </>
            ) : (
              <button
                onClick={() => selected && setSchedule(defaults.keychainSchedule())}
                className={cx(
                  `flex items-center px-2 py-1 rounded-full transition-[background-color,transform] duration-200 active:scale-90 gap-1.5 bg-slate-200/50 hover:bg-slate-200 active:bg-slate-300`,
                )}
              >
                <ClockIcon
                  className={cx(`w-3.5 h-3.5 shrink-0 text-slate-500`)}
                  strokeWidth={2.5}
                />
                <span className="text-sm text-slate-600 font-medium">Add schedule</span>
              </button>
            )}
          </div>
          <div className="flex flex-col sm:flex-row justify-between sm:items-end gap-4 xs:gap-8">
            <div className="flex flex-col flex-grow">
              <div className="flex items-center gap-2">
                <Badge
                  type="green"
                  className={cx(
                    `transition-[margin-right,transform,filter,opacity] duration-300`,
                    !selected?.isPublic && `-translate-y-4 -mr-[77px] blur-sm opacity-0`,
                  )}
                >
                  Public
                </Badge>
                <span className="text-slate-500 text-sm sm:text-base">
                  {selected?.numKeys}
                  {` `}
                  {selected
                    ? inflect(`key`, selected?.numKeys ?? 0)
                    : `No keychain selected`}
                </span>
              </div>
              <div className="mt-1 mb-2">
                <h3
                  className={cx(
                    `text-lg sm:text-xl font-semibold flex gap-1 absolute`,
                    !showNew
                      ? `translate-y-4 opacity-0 blur-sm`
                      : `transition-[transform,opacity,filter] delay-100 duration-300`,
                  )}
                >
                  {selected?.name || `---`}
                </h3>
                <h3
                  className={cx(
                    `text-lg sm:text-xl font-semibold flex gap-1`,
                    showNew &&
                      `-translate-y-4 opacity-0 transition-[transform,opacity,filter] delay-100 duration-300 blur-sm`,
                  )}
                >
                  {prevSelected?.name || `---`}
                </h3>
              </div>
              <div className="w-full bg-slate-100 rounded-lg p-2 h-[80px] sm:h-[120px] overflow-hidden relative">
                <p
                  className={cx(
                    `absolute text-sm sm:text-base`,
                    !showNew
                      ? `translate-y-4 opacity-0 blur-sm`
                      : `transition-[transform,opacity,filter] delay-200 duration-300`,
                    selected?.description ? `text-slate-600` : `text-slate-400 italic`,
                  )}
                >
                  {selected?.description || `No description`}
                </p>
                <p
                  className={cx(
                    `absolute text-sm sm:text-base`,
                    showNew &&
                      `-translate-y-4 opacity-0 transition-[transform,opacity,filter] delay-200 duration-300 blur-sm`,
                    prevSelected?.description
                      ? `text-slate-600`
                      : `text-slate-400 italic`,
                  )}
                >
                  {prevSelected?.description || `No description`}
                </p>
                <div className="absolute w-full h-8 left-0 bottom-0 bg-gradient-to-b from-transparent to-slate-100" />
              </div>
            </div>
            <Button
              type="button"
              onClick={onConfirm}
              disabled={!selected}
              color="primary"
              className="shrink-0"
            >
              Add keychain
            </Button>
          </div>
        </footer>
      </div>
    </div>,
    document.body,
  );
};

export default AddKeychainDrawer;

interface SelectableKeychainProps {
  keychain: Keychain;
  selected: Keychain | undefined;
  setPrevSelected(prevSelected: Keychain | undefined): unknown;
  setShowNew(showNew: boolean): unknown;
  onSelect(keychain: Keychain): unknown;
}

const SelectableKeychain: React.FC<SelectableKeychainProps> = ({
  keychain,
  selected,
  setPrevSelected,
  setShowNew,
  onSelect,
}) => {
  const kIsSelected = selected?.id === keychain.id;
  return (
    <div
      key={keychain.id}
      className={cx(
        `bg-white rounded-xl border-[0.5px] shadow-md shadow-slate-300/50 w-[280px] hover:shadow-lg hover:scale-[102%] transition-[box-shadow,transform] duration-200 cursor-pointer hover:shadow-slate-300/50 active:shadow active:scale-[98%] relative sm:-translate-y-24 min-[1000px]:translate-y-0 shrink-0`,
        kIsSelected ? `outline outline-4 outline-violet-500` : `outline-transparent`,
      )}
      onClick={() => {
        setPrevSelected(selected);
        setShowNew(false);
        onSelect(keychain);
      }}
    >
      <div
        className={cx(
          `w-8 h-8 rounded-full bg-violet-500 text-white flex justify-center items-center absolute z-10 -right-3 -top-4 transition-[transform,opacity] duration-100`,
          !kIsSelected && `scale-0`,
        )}
      >
        <CheckIcon className="w-5" strokeWidth={3} />
      </div>
      <div className="p-3 xs:p-4">
        <div className="relative overflow-hidden">
          <h3 className="text-lg font-medium whitespace-nowrap">{keychain.name}</h3>
          <div className="absolute h-full w-8 right-0 top-0 bg-gradient-to-r from-transparent to-white" />
        </div>
        {keychain.description ? (
          <div className="overflow-hidden relative">
            <p className="text-sm text-slate-500 leading-tight whitespace-nowrap">
              {keychain.description}
            </p>
            <div className="absolute h-full w-8 right-0 top-0 bg-gradient-to-r from-transparent to-white" />
          </div>
        ) : (
          <p className="text-sm text-slate-400 italic">No description</p>
        )}
      </div>
      <div className="border-t border-slate-200 pl-1.5 py-1.5 pr-2 flex justify-between items-center">
        {keychain.isPublic ? <Badge type="green">Public</Badge> : <div />}
        <span className="text-sm text-slate-400">
          {keychain.numKeys} {inflect(`key`, keychain.numKeys)}
        </span>
      </div>
    </div>
  );
};
