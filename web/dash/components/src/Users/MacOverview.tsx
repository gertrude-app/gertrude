import { Button } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import type { MacAppConnectionCode, RequestState } from '@dash/types';
import EmptyState from '../EmptyState';
import PageHeading from '../PageHeading';
import ConnectDeviceModal from './ConnectDeviceModal';

type Glyph = `binoculars` | `lock` | `layer-group`;

const GLYPH_CLASS: Record<Glyph, string> = {
  binoculars: `fa-solid fa-binoculars`,
  lock: `fa-solid fa-lock`,
  'layer-group': `fa-solid fa-layer-group`,
};

const SectionGlyph: React.FC<{ glyph: Glyph }> = ({ glyph }) => (
  <div className="w-12 h-12 flex items-center justify-center -mt-0.5">
    <i
      className={cx(
        GLYPH_CLASS[glyph],
        `text-[28px] bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent`,
      )}
    />
  </div>
);

export interface SectionFact {
  text: string;
  muted?: boolean;
}

export interface MacOverviewSection {
  glyph: Glyph;
  title: string;
  facts: SectionFact[];
  manageLabel: string;
  onManage(): unknown;
}

const Section: React.FC<MacOverviewSection> = ({
  glyph,
  title,
  facts,
  manageLabel,
  onManage,
}) => (
  <div
    className={cx(
      `relative rounded-2xl shadow-md shadow-slate-300/40 border-[0.5px] border-slate-200 bg-white`,
      `flex flex-col transition-[border-color,box-shadow] duration-150`,
      `hover:border-violet-400 hover:shadow-violet-400/30`,
      `focus-within:border-violet-400 focus-within:shadow-violet-400/30`,
    )}
  >
    <button
      type="button"
      aria-label={manageLabel}
      onClick={onManage}
      className="absolute inset-0 rounded-2xl z-0 outline-none"
    />
    <div className="flex items-stretch pointer-events-none">
      <div className="w-16 xs:w-20 shrink-0 py-5 flex justify-center items-start">
        <SectionGlyph glyph={glyph} />
      </div>
      <div className="pr-5 py-5 flex flex-col flex-grow min-w-0">
        <h2 className="font-semibold text-2xl text-slate-900 leading-8 tracking-tight pt-1">
          {title}
        </h2>
        <ul className="mt-3 ml-5 space-y-1 text-sm list-disc marker:text-slate-300">
          {facts.map((f) => (
            <li
              key={f.text}
              className={cx(f.muted ? `text-slate-400` : `text-slate-500`)}
            >
              {f.text}
            </li>
          ))}
        </ul>
      </div>
    </div>
    <div className="border-t border-slate-100 rounded-b-2xl px-5 py-3 flex justify-end">
      <div className="relative z-10">
        <Button type="button" color="secondary" size="small" onClick={onManage}>
          {manageLabel} <i className="fa-solid fa-arrow-right ml-1.5" />
        </Button>
      </div>
    </div>
  </div>
);

interface Props {
  personName: string;
  hasMac: boolean;
  monitoring: MacOverviewSection;
  filtering: MacOverviewSection;
  apps: MacOverviewSection;
  startAddDevice(): unknown;
  dismissAddDevice(): unknown;
  addDeviceRequest?: RequestState<MacAppConnectionCode.Output>;
  onStartTrial(): unknown;
}

const MacOverview: React.FC<Props> = ({
  personName,
  hasMac,
  monitoring,
  filtering,
  apps,
  startAddDevice,
  dismissAddDevice,
  addDeviceRequest,
  onStartTrial,
}) => (
  <div className="relative max-w-3xl">
    <ConnectDeviceModal
      request={addDeviceRequest}
      dismissAddDevice={dismissAddDevice}
      onStartTrial={onStartTrial}
    />
    <PageHeading icon="laptop">{personName}&rsquo;s Mac</PageHeading>
    {hasMac ? (
      <>
        <p className="text-slate-500 mt-2 ml-[60px]">
          An overview of {personName}&rsquo;s parental controls.
        </p>
        <div className="mt-8 flex flex-col gap-3">
          <Section {...monitoring} />
          <Section {...filtering} />
          <Section {...apps} />
        </div>
      </>
    ) : (
      <EmptyState
        heading="No Mac connected"
        secondaryText={
          <>
            {personName} doesn&rsquo;t have a Mac connected yet. To get started, download
            the Mac app from{` `}
            <a
              href="https://gertrude.app/download"
              className="font-mono text-violet-600 hover:underline"
              target="_blank"
              rel="noreferrer"
            >
              https://gertrude.app/download
            </a>
            {` `}
            on the Mac your child uses, then click below for a connection code.
          </>
        }
        icon="laptop"
        buttonText="Get connection code"
        buttonIcon="desktop"
        action={startAddDevice}
        className="mt-8"
      />
    )}
  </div>
);

export default MacOverview;
