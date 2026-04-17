import { Button } from '@shared/components';
import cx from 'classnames';
import React, { useContext, useEffect, useState } from 'react';
import OnboardingContext, { WithinActiveStepContext } from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';

type Phase = `intro` | `diagramIn` | `buttonIn`;

const DIAGRAM_DELAY_MS = 3000;
const BUTTON_DELAY_MS = 2000;

const KEYS: { domain: string; purpose: string }[] = [
  { domain: `safesite.com`, purpose: `the site itself` },
  { domain: `images.safesite.com`, purpose: `its images` },
  { domain: `video-service.com`, purpose: `its videos` },
  { domain: `cdn.webfonts.net`, purpose: `its fonts` },
];

const MeetKeychains: React.FC = () => {
  const { emit } = useContext(OnboardingContext);
  const withinActiveStep = useContext(WithinActiveStepContext);
  const [phase, setPhase] = useState<Phase>(`intro`);

  useEffect(() => {
    if (!withinActiveStep) return;
    const t1 = setTimeout(() => setPhase(`diagramIn`), DIAGRAM_DELAY_MS);
    const t2 = setTimeout(() => setPhase(`buttonIn`), DIAGRAM_DELAY_MS + BUTTON_DELAY_MS);
    return () => {
      clearTimeout(t1);
      clearTimeout(t2);
    };
  }, [withinActiveStep]);

  return (
    <Onboarding.Centered className="!justify-start pt-24">
      <div className="flex flex-col items-center max-w-2xl">
        <div className="flex items-center gap-4">
          <span className="w-12 h-12 rounded-2xl bg-gradient-to-br from-violet-400 to-fuchsia-500 flex items-center justify-center shadow-lg shadow-violet-200/70">
            <i className="fa-solid fa-key text-white text-lg" />
          </span>
          <Onboarding.Heading>
            Meet <em className="xunderline">keychains</em>
          </Onboarding.Heading>
        </div>

        <Onboarding.Text className="mt-8 max-w-xl" centered>
          Gertrude keeps things organized by bundling all the addresses needed for a site
          into a single <b>“keychain”</b> with one <b>“key”</b> for each address.
        </Onboarding.Text>

        <div
          className={cx(
            `transition-opacity duration-700`,
            phase === `intro` ? `opacity-0` : `opacity-100`,
          )}
        >
          <KeychainDiagram />
        </div>

        <Button
          type="button"
          color="primary"
          size="large"
          disabled={phase !== `buttonIn`}
          onClick={() => emit({ case: `primaryBtnClicked` })}
          className="mt-10"
          tabIndex={-1}
        >
          Got it, next
          <i className="fa-solid fa-arrow-right ml-3" />
        </Button>
      </div>
    </Onboarding.Centered>
  );
};

const KeychainDiagram: React.FC = () => (
  <div className="mt-14 mb-4 w-full max-w-md">
    <div className="relative rounded-2xl border-2 border-violet-300 bg-violet-50/60 pt-7 pb-5 px-5 shadow-sm shadow-violet-100">
      <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full bg-gradient-to-br from-violet-500 to-fuchsia-500 text-white text-sm font-semibold shadow shadow-violet-200/70 flex items-center gap-1.5 whitespace-nowrap">
        <i className="fa-solid fa-link text-[10px]" />
        SafeSite keychain
      </div>
      <div className="flex flex-col gap-2">
        {KEYS.map((k) => (
          <div
            key={k.domain}
            className="flex items-center gap-3 pl-3 pr-4 py-2 rounded-lg bg-white border border-slate-200 shadow-sm"
          >
            <i className="fa-solid fa-key text-violet-500" />
            <span className="font-mono text-sm text-slate-700">{k.domain}</span>
            <span className="ml-auto text-xs text-emerald-600">{k.purpose}</span>
          </div>
        ))}
      </div>
    </div>
  </div>
);

export default MeetKeychains;
