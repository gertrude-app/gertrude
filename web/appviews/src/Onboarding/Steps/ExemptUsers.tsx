import { inflect } from '@shared/string';
import React, { useContext } from 'react';
import { ExemptUser } from '../../Administrate/screens/ExemptUsersScreen';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';

const ExemptUsers: React.FC = () => {
  const { otherUsers } = useContext(OnboardingContext);
  return (
    <Onboarding.Centered>
      <Onboarding.Heading>Grant other users internet access</Onboarding.Heading>
      <Onboarding.Text centered className="max-w-3xl mt-4">
        For safety, Gertrude will block all internet access for other users unless you
        explicitly exempt them from filtering. You have {otherUsers.length} other{` `}
        {inflect(`user`, otherUsers.length)} on this computer; if you want them to have
        access to the internet, click the corresponding checkbox below. Make sure your
        child doesn&apos;t know the password for these unpretected users.
      </Onboarding.Text>
      <div className="min-w-[660px] border border-slate-200 bg-white rounded-2xl mt-8">
        {otherUsers.map((user) => (
          <ExemptUser
            name={user.name}
            isExempt={true}
            onToggle={() => alert(`TODO`)}
            isAdmin={user.isAdmin}
          />
        ))}
      </div>
      <Onboarding.PrimaryButton className="mt-8">
        Continue
        <i className="fa-solid fa-arrow-right ml-3" />
      </Onboarding.PrimaryButton>
    </Onboarding.Centered>
  );
};

export default ExemptUsers;
