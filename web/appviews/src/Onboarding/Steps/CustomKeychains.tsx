import { TextInput } from '@shared/components';
import cx from 'classnames';
import React, { useContext, useState } from 'react';
import type { RequestState } from '../onboarding-store';
import OnboardingContext, { WithinActiveStepContext } from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';

interface Props {
  unlocked: string[];
  request: RequestState<void, string>;
}

const CustomKeychains: React.FC<Props> = ({ unlocked, request }) => {
  const { emit, currentStep, osVersion } = useContext(OnboardingContext);
  const withinActiveStep = useContext(WithinActiveStepContext);
  const [domain, setDomain] = useState(``);
  const ongoing = request.case === `ongoing`;
  const trimmed = domain.trim();
  const canSubmit = trimmed.includes(`.`) && !ongoing;
  const shouldAutoFocus = currentStep === `customKeychains` && osVersion.major > 12;

  return (
    <Onboarding.Centered>
      <Onboarding.Heading centered>
        Any specific websites your child needs?
      </Onboarding.Heading>
      <Onboarding.Text centered className="mt-5 mb-8 max-w-xl">
        If you already know sites your child will need to reach&mdash;a school portal,
        family site, sports team, etc.&mdash;add them here and Gertrude will unlock them.
        You can always add more later from the parents website.
      </Onboarding.Text>

      <form
        noValidate
        className="flex w-[540px] items-start gap-3"
        onSubmit={(e) => {
          e.preventDefault();
          if (canSubmit) {
            emit({ case: `createOnboardingKeychain`, domain: trimmed });
            setDomain(``);
          }
        }}
      >
        <TextInput
          key={unlocked.length}
          type="url"
          prefix="https://"
          value={domain}
          setValue={setDomain}
          placeholder="example.com"
          disabled={!withinActiveStep || ongoing}
          autoFocus={shouldAutoFocus}
          className="flex-grow"
        />
        <button
          type="submit"
          disabled={!canSubmit}
          tabIndex={-1}
          className={cx(
            `shrink-0 w-14 h-[50px] rounded-xl flex justify-center items-center transition-[transform,box-shadow,background-color,color] duration-200`,
            canSubmit
              ? `bg-gradient-to-br from-violet-500 to-fuchsia-500 text-white shadow-lg shadow-violet-500/40 hover:scale-[103%] active:scale-[97%] hover:shadow-xl hover:shadow-violet-500/50`
              : `bg-slate-100 text-slate-300 cursor-not-allowed`,
          )}
        >
          {ongoing ? (
            <i className="fa-solid fa-spinner animate-spin text-lg" />
          ) : (
            <i className="fa-solid fa-plus text-lg" />
          )}
        </button>
      </form>

      <div className="w-[540px]">
        <div className="h-6 mt-2 px-1">
          {request.case === `failed` && (
            <p className="text-sm text-red-500 antialiased">
              <i className="fa-solid fa-circle-exclamation mr-1.5" />
              {request.error ?? `Failed to add website`}
            </p>
          )}
        </div>

        <div
          className={cx(
            `overflow-hidden transition-[opacity,max-height,margin-top] duration-300`,
            unlocked.length === 0
              ? `opacity-0 max-h-0 mt-0`
              : `opacity-100 max-h-20 mt-1`,
          )}
        >
          <div className="flex items-center gap-3 rounded-xl bg-white border border-slate-200 px-4 py-2.5 shadow-sm">
            <div className="w-6 h-6 rounded-full bg-emerald-500 flex items-center justify-center text-white shrink-0">
              <i className="fa-solid fa-check text-[11px]" />
            </div>
            <span className="text-slate-700 font-mono text-sm truncate">
              <span className="text-slate-400">https://</span>
              {unlocked[unlocked.length - 1]}
            </span>
            {unlocked.length > 1 && (
              <span className="ml-auto text-xs text-slate-400 font-medium antialiased shrink-0">
                {unlocked.length} added
              </span>
            )}
          </div>
        </div>
      </div>

      <Onboarding.PrimaryButton
        renderAsSecondary={unlocked.length === 0}
        className="mt-10"
        icon="fa-solid fa-arrow-right"
      >
        {unlocked.length === 0 ? `Skip for now` : `All done`}
      </Onboarding.PrimaryButton>
    </Onboarding.Centered>
  );
};

export default CustomKeychains;
