import React, { useState, useContext } from 'react';
import ExpandableContent from '../ExpandableContent';
import TellMeMoreButton from '../TellMeMoreButton';
import * as Onboarding from '../UtilityComponents';
import OnboardingContext from '../OnboardingContext';
import InformationModal from '../InformationModal';
import assets from '../cdn-assets';

const BypassPrivacyWarning: React.FC = () => {
  const [showModal, setShowModal] = useState(false);
  const { emit } = useContext(OnboardingContext);
  return (
    <>
      <Onboarding.Centered className="space-x-12" direction="row">
        <div>
          <Onboarding.Heading>If you see this warning...</Onboarding.Heading>
          <Onboarding.Text className="mt-3 mb-8 max-w-2xl">
            Starting in macOS Sequoia, Apple shows this <em>misleading</em> warning when
            Gertrude first tries to take a screenshot. We never record any audio. Just
            click “Allow for One Month.”
          </Onboarding.Text>
          <div className="flex items-center">
            <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right">
              Got it, next
            </Onboarding.PrimaryButton>
            <TellMeMoreButton
              onClick={() => {
                setShowModal(true);
                emit({
                  case: `infoModalOpened`,
                  step: `screenshotsPrivacyWarning`,
                });
              }}
            >
              Tell me more
            </TellMeMoreButton>
          </div>
        </div>
        <ExpandableContent
          asset={assets.img(`bypass-picker-warning`)}
          lessRounded
          width={617 * 0.62}
          height={445 * 0.62}
          maxWidth={617}
        />
      </Onboarding.Centered>
      <InformationModal open={showModal} setOpen={setShowModal}>
        <p>
          In an effort to protect your privacy and guard users against scams and malicious
          software, macOS Sequoia has introduced this warning whenever an app tries to
          take a screenshot without first allowing the user to select which part of the
          screen they want to share. However, the whole point of Gertrude’s screenshot
          feature is to capture the entire screen, so we can’t show a picker.
        </p>
        <p className="mt-4">
          There have been many apps adversely affected by this new warning, and we know
          Apple has received a lot of negative feedback about it, so we are hopeful they
          may remove it in the future.
        </p>
        <p className="mt-4">
          We absolutely <b>do not record any audio whatsoever.</b> The code for Gertrude
          is open source, you’re welcome to{` `}
          <a className="text-violet-600 underline" href="https://github.com/gertrude-app">
            see for yourself
          </a>
          {` `}
          if you like!
        </p>
      </InformationModal>
    </>
  );
};

export default BypassPrivacyWarning;
