import React, { useContext } from 'react';
import ExpandableContent from '../ExpandableContent';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';

const HowToUseGertrude: React.FC = () => {
  const { currentStep } = useContext(OnboardingContext);
  return (
    <Onboarding.Centered>
      <Onboarding.Heading>How to use Gertrude</Onboarding.Heading>
      <Onboarding.Text className="mt-2" centered>
        The short video below walks you through the basics of using Gertrude, including:
      </Onboarding.Text>
      <ul className="flex flex-wrap mt-3 justify-center">
        <ListItem index={1}>How to unblock parts of the internet</ListItem>
        <ListItem index={2}>How to see what your child is doing online</ListItem>
        <ListItem index={3}>How to suspend the filter temporarily</ListItem>
      </ul>
      <ExpandableContent
        width={640 * 0.8}
        height={360 * 0.8}
        asset={assets.video(`post-onboarding-tour`, currentStep === `howToUseGertrude`)}
        className="mt-4 mb-6"
        showInstructions={false}
      />
      <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right">
        Finish
      </Onboarding.PrimaryButton>
    </Onboarding.Centered>
  );
};

export default HowToUseGertrude;

interface ListItemProps {
  children?: React.ReactNode;
  index: number;
}

const ListItem: React.FC<ListItemProps> = ({ children, index }) => (
  <li className="flex items-center border border-slate-200 p-1.5 rounded-2xl m-1">
    <div className="bg-violet-100 text-violet-600 font-bold w-7 h-7 rounded-full flex justify-center items-center">
      {index}
    </div>
    <span className="ml-4 mr-2 text-slate-500">{children}</span>
  </li>
);
