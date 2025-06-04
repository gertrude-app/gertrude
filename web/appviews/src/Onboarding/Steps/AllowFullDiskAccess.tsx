import React, { useContext, useState } from 'react';
import ExpandableContent from '../ExpandableContent';
import InformationModal from '../InformationModal';
import OnboardingContext from '../OnboardingContext';
import TellMeMoreButton from '../TellMeMoreButton';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';

interface Props {
  step:
    | `allowFullDiskAccess_grantAndRestart`
    | `allowFullDiskAccess_failed`
    | `allowFullDiskAccess_success`;
}

const AllowFullDiskAccess: React.FC<Props> = ({ step }) => {
  const [showModal, setShowModal] = useState<false | `why` | `help`>(false);
  const { systemSettingsName, osVersion, currentStep, emit, isUpgrade } =
    useContext(OnboardingContext);
  switch (step) {
    case `allowFullDiskAccess_grantAndRestart`:
      return (
        <>
          <Onboarding.Centered direction="row" className="space-x-12">
            <ExpandableContent
              className="!ml-0"
              asset={assets.osImg(osVersion.name, `full-disk-access`)}
              width={800 / 1.9}
              height={600 / 1.9}
            />
            <div className="flex flex-col !mr-0">
              {!isUpgrade ? (
                <Onboarding.Heading>Allow full disk access</Onboarding.Heading>
              ) : (
                <Onboarding.Heading>Allow new permission</Onboarding.Heading>
              )}
              <Onboarding.Text className="max-w-2xl mt-4">
                {isUpgrade ? `Gertrude now needs ` : `Next, Gertrude needs `}
                <b>full disk access</b> to safely monitor your child.
                <TellMeMoreButton
                  size="small"
                  onClick={() => {
                    setShowModal(`why`);
                    emit({
                      case: `infoModalOpened`,
                      step: `allowKeylogging_required`,
                      detail: `why?`,
                    });
                  }}
                >
                  Why?
                </TellMeMoreButton>
              </Onboarding.Text>
              <Onboarding.Text className="max-w-2xl mt-4 mb-8">
                Click <b>Grant</b>, then follow the steps shown, which include{` `}
                <b>quitting Gertrude.</b> This screen will reopen when it restarts.
              </Onboarding.Text>
              <Onboarding.ButtonGroup
                primary="Grant"
                secondary={{
                  text: `Help, I’m stuck...`,
                  shadow: true,
                  onClick: () => {
                    setShowModal(`help`);
                    emit({
                      case: `infoModalOpened`,
                      step: `allowFullDiskAccess_grantAndRestart`,
                      detail: `helpStuck`,
                    });
                  },
                }}
              />
            </div>
            <Onboarding.EscapeHatchButton
              onClick={() => emit({ case: `secondaryBtnClicked` })}
            >
              {!isUpgrade ? (
                <>Continue and resolve later &rarr;</>
              ) : (
                <>&times; Close, I’ll do it later</>
              )}
            </Onboarding.EscapeHatchButton>
          </Onboarding.Centered>
          <InformationModal
            open={showModal === `why`}
            onClose={() => setShowModal(false)}
          >
            <p className="mb-4">
              Recent versions of macOS have introduced a privacy feature that is meant to
              protect users from malicious software recording their screen. This feature
              can cause a popup window to appear{` `}
              <i>every time Gertrude takes a screenshot of your child’s activity,</i>
              {` `}
              which is both annoying and unsafe because it reveals to them the frequency
              and approximate cadence of the screenshots.
            </p>
            <p>
              To prevent these repeated popups we need to <i>periodically modify</i> a
              specific configuration file, which requires <b>full disk access.</b>
              {` `}
              Gertrude already discloses to your child when they are being monitored by
              screenshots, although not the <i>exact moments</i>
              {` `}
              when the screenshots are being taken.
            </p>
          </InformationModal>
          {osVersion.major > 12 ? (
            <InformationModal
              open={showModal === `help`}
              onClose={() => setShowModal(false)}
            >
              When you clicked <b>Grant &rarr;</b> we <i>tried</i> to open the{` `}
              <b>{systemSettingsName} app</b> to the right spot for you to grant full disk
              access. If for some reason you can’t find the spot, try closing
              applications, moving windows, and checking any additional desktops you may
              have open. Failing that, click the Apple icon () in the far upper-left
              corner of your screen, and choose “{systemSettingsName}...” then search for
              “Privacy &amp; Security.” Once you’re in that area, select “Full Disk
              Access” on the right side, then follow the steps shown in the animated image
              below this popup. If Gertrude is not shown on the list, click the small plus
              icon and select it from the Applications folder.
            </InformationModal>
          ) : (
            <InformationModal
              open={showModal === `help`}
              onClose={() => setShowModal(false)}
            >
              When you clicked <b>Grant &rarr;</b> we <i>tried</i> to open the{` `}
              <b>{systemSettingsName} app</b> to the right spot for you to grant full disk
              access. If for some reason you can’t find the spot, try closing
              applications, moving windows, and checking any additional desktops you may
              have open. Failing that, click the Apple icon () in the far upper-left
              corner of your screen, and choose “{systemSettingsName}...” then click the
              icon labeled “Privacy &amp; Security.” Once you’re in that area, click the
              “Privacy” tab in the upper right, then click “Full Disk Access” from the
              list on the left, and finally follow the steps shown in the animated image
              below this popup. If Gertrude is not shown on the list, click the small plus
              icon and select it from the Applications folder.
            </InformationModal>
          )}
        </>
      );
    case `allowFullDiskAccess_success`:
      return (
        <Onboarding.Centered>
          <div className="flex flex-col items-center bg-white p-12 rounded-3xl shadow-lg shadow-slate-300/30">
            <Onboarding.Heading>Excellent!</Onboarding.Heading>
            <Onboarding.Text className="max-w-xl mt-4" centered>
              {!isUpgrade ? (
                <>
                  Gertrude now has <i>full disk access</i> permission.
                </>
              ) : (
                <>Gertrude has the permission it needs to keep protecting your child.</>
              )}
            </Onboarding.Text>
            <Onboarding.PrimaryButton
              icon={`fa-solid ${isUpgrade ? `fa-times` : `fa-arrow-right`}`}
              className="mt-8"
            >
              {!isUpgrade ? `Next` : `Close`}
            </Onboarding.PrimaryButton>
          </div>
        </Onboarding.Centered>
      );
    case `allowFullDiskAccess_failed`:
      return (
        <Onboarding.Centered>
          <Onboarding.Heading>
            <i className="fas fa-exclamation-triangle text-yellow-600 mr-4" />
            Full disk access not granted
          </Onboarding.Heading>
          <Onboarding.Text className="my-2">
            Watch the short video below for help granting permission.
          </Onboarding.Text>
          <ExpandableContent
            width={640 * 0.9}
            height={360 * 0.9}
            asset={assets.osVideo(
              osVersion.name,
              `troubleshoot-full-disk-access`,
              currentStep === `allowFullDiskAccess_failed`,
            )}
            className="mt-4 mb-6"
            showInstructions={false}
          />
          <Onboarding.ButtonGroup
            direction="row"
            primary="Try again"
            secondary={{ text: `Skip for now`, shadow: true }}
          />
        </Onboarding.Centered>
      );
  }
};

export default AllowFullDiskAccess;
