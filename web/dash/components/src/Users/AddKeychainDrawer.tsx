import React, { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import cx from 'classnames';
import {
  CheckIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  KeyIcon,
  MagnifyingGlassIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline';
import { Badge, Button } from '@shared/components';
import { inflect } from '@shared/string';
import type { KeychainSummary as Keychain, RequestState } from '@dash/types';

interface Props {
  request?: RequestState<{ own: Keychain[]; public: Keychain[] }>;
  selected?: Keychain;
  onDismiss(): unknown;
  onConfirm(): unknown;
  onSelect(keychain: Keychain): unknown;
  existingKeychains: Keychain[];
  userName: string;
  userId: string;
}

const AddKeychainDrawer: React.FC<Props> = ({
  onDismiss,
  onConfirm,
  request,
  onSelect,
  selected,
  existingKeychains,
  userName,
  userId,
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
          .filter((k) => !existingKeychains.includes(k))
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
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === `Escape`) {
        onDismiss();
      }
    };
    if (shown) document.addEventListener(`keydown`, handleKeyDown);
    return () => document.removeEventListener(`keydown`, handleKeyDown);
  }, [onDismiss]);

  useEffect(() => {
    setShowNew(true);
  }, [selected]);

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
          `bg-white pb-12 rounded-t-[40px] shadow-2xl shadow-black/30 transition-transform duration-300 flex-grow max-w-[1000px]`,
          !shown ? `translate-y-[100%]` : `translate-y-12`,
        )}
        onClick={(e) => e.stopPropagation()}
      >
        <header className="px-5 py-4 flex items-center justify-between border-b border-slate-200">
          <div className="flex items-center gap-4">
            <div className="w-10 h-10 rounded-full bg-slate-200 flex justify-center items-center border border-slate-300">
              <KeyIcon className="w-6 h-6 text-slate-500" strokeWidth={2} />
            </div>
            <div>
              <h2 className="text-2xl font-semibold -mb-1">Add a keychain</h2>
              <span className="font-medium text-slate-500">to child {userName}</span>
            </div>
          </div>
          <button
            className="w-10 h-10 bg-slate-100 rounded-full flex justify-center items-center text-slate-400 hover:bg-slate-200 active:bg-slate-300 active:scale-90 transition-[transform,background-color] duration-150"
            onClick={() => onDismiss()}
          >
            <XMarkIcon className="w-5" strokeWidth={2.5} />
          </button>
        </header>
        <main className="bg-slate-50 pt-8 pb-2">
          <div className="flex justify-center items-center flex-col gap-4">
            <div className="relative">
              <MagnifyingGlassIcon
                className="absolute w-5 top-2.5 left-3 text-slate-500"
                strokeWidth={2.5}
              />
              <input
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setPage(1);
                }}
                placeholder="Search..."
                className="w-[400px] text-lg py-1.5 rounded-full bg-slate-200 hover:bg-slate-300/80 pl-10 outline-transparent outline-offset-0 transition-[outline-color,outline-offset,background-color] duration-200 focus:outline-offset-4 focus:outline-violet-500 placeholder:text-slate-400"
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
          <div className="h-[312px] relative overflow-hidden">
            <button
              className={cx(
                `absolute h-full w-14 top-0 left-0 flex justify-center items-center rounded-r-3xl hover:bg-slate-200/50 z-20 transition-[background-color,transform,opacity] duration-200 active:bg-slate-200`,
                page === 1 && `-translate-x-8 opacity-0 pointer-events-none`,
              )}
              onClick={() => setPage(page - 1)}
            >
              <ChevronLeftIcon className="w-7 text-slate-400" strokeWidth={2.5} />
            </button>
            <button
              className={cx(
                `absolute h-full w-14 top-0 right-0 flex justify-center items-center rounded-l-3xl hover:bg-slate-200/50 z-20 transition-[background-color,transform,opacity] duration-200 active:bg-slate-200`,
                (page === numPages || numPages === 0) &&
                  `translate-x-8 opacity-0 pointer-events-none`,
              )}
              onClick={() => setPage(page + 1)}
            >
              <ChevronRightIcon className="w-7 text-slate-400" strokeWidth={2.5} />
            </button>
            {keychainsToDisplay.length > 0 ? (
              Array.from({ length: numPages }).map((_, i) => (
                <div
                  className={cx(
                    `p-5 flex flex-wrap gap-4 justify-center items-center absolute w-full h-full transition-[opacity,transform] duration-300`,
                    {
                      '-translate-x-[100%] opacity-0': i + 1 < page,
                      'translate-x-0': i + 1 === page,
                      'translate-x-[100%] opacity-0': i + 1 > page,
                    },
                  )}
                >
                  {keychainsToDisplay.slice(i * 6, (i + 1) * 6).map((k) => {
                    const kIsSelected = selected?.id === k.id;
                    return (
                      <div
                        key={k.id}
                        className={cx(
                          `bg-white rounded-xl border-[0.5px] shadow-md shadow-slate-300/50 w-[280px] hover:shadow-lg hover:scale-[102%] transition-[box-shadow,transform] duration-200 cursor-pointer hover:shadow-slate-300/50 active:shadow active:scale-[98%] relative`,
                          kIsSelected
                            ? `outline outline-4 outline-violet-500`
                            : `outline-transparent`,
                        )}
                        onClick={() => {
                          setPrevSelected(selected);
                          setShowNew(false);
                          onSelect(k);
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
                        <div className="p-4">
                          <div className="relative overflow-hidden">
                            <h3 className="text-lg font-medium whitespace-nowrap">
                              {k.name}
                            </h3>
                            <div className="absolute h-full w-8 right-0 top-0 bg-gradient-to-r from-transparent to-white" />
                          </div>
                          {k.description ? (
                            <div className="overflow-hidden relative">
                              <p className="text-sm text-slate-500 leading-tight whitespace-nowrap">
                                {k.description}
                              </p>
                              <div className="absolute h-full w-8 right-0 top-0 bg-gradient-to-r from-transparent to-white" />
                            </div>
                          ) : (
                            <p className="text-sm text-slate-400 italic">
                              No description
                            </p>
                          )}
                        </div>
                        <div className="border-t border-slate-200 pl-2 py-2 pr-3 flex justify-between items-center">
                          {k.isPublic ? <Badge type="green">Public</Badge> : <div />}
                          <span className="text-sm text-slate-400">
                            {k.numKeys} {inflect(`key`, k.numKeys)}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ))
            ) : whichKeychains === `own` ? (
              <div>loading...</div>
            ) : (
              // if there are no public keychains (you own all of them)
              <div className="h-full w-full flex justify-center items-center text-xl font-medium text-slate-300">
                Hi Jared :)
              </div>
            )}
          </div>
          <div className="flex justify-center gap-4 pb-4 h-11">
            {Array.from({ length: numPages }).map((_, i) => (
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
        <footer className="border-t border-slate-200 bg-white p-6 flex justify-between items-end gap-8 w-full">
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
              <span className="text-slate-500">
                {selected?.numKeys}
                {` `}
                {selected
                  ? inflect(`key`, selected?.numKeys ?? 0)
                  : `No keychain selected`}
              </span>
            </div>
            <div>
              <h3
                className={cx(
                  `text-xl font-semibold mt-1 mb-1 flex gap-1 absolute`,
                  !showNew
                    ? `translate-y-4 opacity-0 blur-sm`
                    : `transition-[transform,opacity,filter] delay-100 duration-300`,
                )}
              >
                {selected?.name || `---`}
              </h3>
              <h3
                className={cx(
                  `text-xl font-semibold mt-1 mb-1 flex gap-1`,
                  showNew &&
                    `-translate-y-4 opacity-0 transition-[transform,opacity,filter] delay-100 duration-300 blur-sm`,
                )}
              >
                {prevSelected?.name || `---`}
              </h3>
            </div>
            <div className="w-full bg-slate-100 rounded-lg p-2 -mx-2 h-[80px] overflow-hidden relative">
              <p
                className={cx(
                  `absolute`,
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
                  `absolute`,
                  showNew &&
                    `-translate-y-4 opacity-0 transition-[transform,opacity,filter] delay-200 duration-300 blur-sm`,
                  prevSelected?.description ? `text-slate-600` : `text-slate-400 italic`,
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
        </footer>
      </div>
    </div>,
    document.body,
  );
};

export default AddKeychainDrawer;
