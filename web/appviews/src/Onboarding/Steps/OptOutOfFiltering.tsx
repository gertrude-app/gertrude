import React, { useContext, useState } from 'react';
import InformationModal from '../InformationModal';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';

const OptOutOfFiltering: React.FC = () => {
  const [showModal, setShowModal] = useState(false);
  const { emit, currentStep } = useContext(OnboardingContext);
  return (
    <Onboarding.Centered>
      <InformationModal open={showModal} onClose={() => setShowModal(false)}>
        <div className="space-y-4">
          <p>
            Gertrude has two main features: <b>internet filtering</b> and{` `}
            <b>monitoring</b> (screenshots and keystroke recording). Most families use
            both together, but they can be used independently.
          </p>
          <p>
            <b>Disabling filtering</b> means this user will have{` `}
            <em>unrestricted internet access</em>&mdash;no websites or apps will be
            blocked. Gertrude will still monitor their activity through screenshots and
            keystroke recording, so you&rsquo;ll be able to see what they&rsquo;re doing
            online.
          </p>
          <p>
            This is most commonly used for <b>older teens</b> or <b>adults</b> in
            accountability relationships, for whom restricted internet access isn&rsquo;t
            necessary or manageable.
          </p>
          <p>
            If you’re not sure what to do, keep filtering <b>enabled.</b> You can always
            change this later from the Gertrude parents account website.
          </p>
        </div>
      </InformationModal>
      <Onboarding.Heading centered>Disable internet filtering?</Onboarding.Heading>
      <Onboarding.Text centered className="mt-5 mb-3 max-w-lg">
        By default, Gertrude filters all internet requests, and requires you to choose
        what is allowed. This is safest for most situations.
      </Onboarding.Text>
      <Onboarding.Text centered className="mt-3 max-w-lg">
        But for some individuals it makes sense to <i>disable filtering</i>&mdash;allowing
        unrestricted internet access&mdash;and only use <b>screenshot monitoring</b> for
        accountability.
      </Onboarding.Text>
      <button
        tabIndex={-1}
        onClick={() => {
          setShowModal(true);
          emit({
            case: `infoModalOpened`,
            step: currentStep,
            detail: `learnMore`,
          });
        }}
        className="font-medium text-violet-500 hover:bg-violet-100 rounded-xl transition-[background-color,transform] duration-200 active:scale-[97%] active:bg-violet-200 py-2 px-4 mt-4 mb-6"
      >
        <i className="fa-solid far fa-circle-question mr-2" />
        <span>Tell me more</span>
      </button>
      <Onboarding.ButtonGroup
        direction="column"
        primary="Keep filtering enabled"
        secondary={{
          text: `Disable filtering for this user`,
          icon: `fa-solid fa-shield-xmark`,
          onClick: () => emit({ case: `secondaryBtnClicked` }),
        }}
      />
    </Onboarding.Centered>
  );
};

export default OptOutOfFiltering;
