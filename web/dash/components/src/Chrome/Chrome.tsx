import { Dialog, DialogPanel, Transition, TransitionChild } from '@headlessui/react';
import { XMarkIcon } from '@heroicons/react/24/solid';
import cx from 'classnames';
import React from 'react';
import MobileStickyHeader from './MobileStickyHeader';
import SidebarNav from './SidebarNav';

interface Props {
  children: React.ReactNode;
  urlPath: string;
  mobileSidebarOpen: boolean;
  onMobileHamburgerClick(): unknown;
  onMobileSidebarClose(): unknown;
  onInternalLinkClick(): unknown;
  sidebarCollapsed: boolean;
  onToggleSidebarCollapsed(): unknown;
  usingMobileView?: boolean;
}

const Chrome: React.FC<Props> = ({
  children,
  mobileSidebarOpen,
  onMobileHamburgerClick,
  onMobileSidebarClose,
  urlPath,
  sidebarCollapsed,
  onToggleSidebarCollapsed,
  onInternalLinkClick,
  usingMobileView = false,
}) => (
  <div className="Chrome bg-slate-50">
    {/* mark: begin mobile menu */}
    <Transition show={mobileSidebarOpen}>
      <Dialog as="div" className="relative z-40 md:hidden" onClose={onMobileSidebarClose}>
        {/* mark: semi transparent overlay */}
        <TransitionChild
          as="div"
          aria-hidden="true"
          className="fixed inset-0 bg-white bg-opacity-50 backdrop-blur-xl transition-opacity duration-200 ease-linear data-[closed]:opacity-0"
        />

        <div className="fixed inset-0 flex z-40">
          {/* mark: begin mobile sidebar wrapper */}
          <TransitionChild
            as={DialogPanel}
            className="relative flex flex-col w-72 bg-slate-900 bg-gradient-to-b from-transparent to-violet-900/20 rounded-xl shadow-lg shadow-black/30 m-2 transition-transform duration-200 ease-in-out data-[closed]:-translate-x-full"
          >
            {/* mark: begin floating mobile overlay close 'X' button */}
            <TransitionChild
              as="div"
              className="absolute top-0 right-0 -mr-12 pt-4 transition-opacity duration-200 ease-in-out data-[closed]:opacity-0"
            >
              <button
                type="button"
                className="shadow-lg shadow-black/30 text-slate-400 hover:text-slate-300 flex items-center justify-center h-10 w-10 bg-slate-900 rounded-lg focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/50"
                onClick={onMobileSidebarClose}
              >
                <span className="sr-only">Close sidebar</span>
                <XMarkIcon className="h-6 leading-none" />
              </button>
            </TransitionChild>
            {/* mark: end floating mobile overlay close 'X' button */}
            <SidebarNav onInternalLinkClick={onInternalLinkClick} urlPath={urlPath} />
          </TransitionChild>
          {/* mark: end mobile sidebar wrapper */}
          <div className="flex-shrink-0 w-14" aria-hidden="true">
            {/* Dummy element to force sidebar to shrink to fit close icon */}
          </div>
        </div>
      </Dialog>
    </Transition>
    {/* mark: end mobile menu */}

    {/* Static sidebar for desktop */}
    <div
      className={cx(
        sidebarCollapsed ? `w-20` : `w-72`,
        `hidden relative flex-col md:flex md:fixed md:inset-y-0 transition-[width] m-3`,
        `bg-slate-900 bg-gradient-to-b from-transparent to-violet-900/50 rounded-2xl shadow-lg shadow-slate-500/30`,
      )}
    >
      <SidebarNav
        collapsed={sidebarCollapsed}
        toggleCollapsed={onToggleSidebarCollapsed}
        onInternalLinkClick={onInternalLinkClick}
        urlPath={urlPath}
      />
    </div>

    <div
      className={cx(
        `flex flex-col flex-1 transition-[padding]`,
        sidebarCollapsed ? `md:pl-24` : `md:pl-[304px]`,
      )}
    >
      <MobileStickyHeader
        className="sticky z-20 md:hidden"
        sidebarShown={mobileSidebarOpen}
        onHamburgerClick={onMobileHamburgerClick}
      />
      <main
        // simplify this when react supports `inert` properly
        ref={(node) => {
          if (usingMobileView && mobileSidebarOpen) {
            node?.setAttribute(`inert`, ``);
          } else {
            node?.removeAttribute(`inert`);
          }
        }}
      >
        <div className={`[min-height:calc(100vh-64px)] md:min-h-screen`}>
          <PaddedMain>{children}</PaddedMain>
        </div>
      </main>
    </div>
  </div>
);

export default Chrome;

const PaddedMain: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  // 👋 if you change this padding, you need to change the "Undo" below
  <div className="py-6 md:py-7 max-w-[1460px] px-4 sm:px-6 md:px-8">{children}</div>
);

export const UndoMainPadding: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className }) => (
  <div className={cx(`-my-6 md:-my-7 -mx-4 sm:-mx-6 md:-mx-8`, className)}>
    {children}
  </div>
);
