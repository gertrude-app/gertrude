import cx from 'classnames';
import React, { useContext } from 'react';
import { ExemptUser } from '../../Administrate/screens/ExemptUsersScreen';
import Callout from '../Callout';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';

interface Props {
  exemptableUserIds: number[];
  exemptUserIds: number[];
}

const ExemptUsers: React.FC<Props> = ({ exemptableUserIds, exemptUserIds }) => {
  const { otherUsers, emit } = useContext(OnboardingContext);
  return (
    <Onboarding.Centered>
      <Onboarding.Heading>Unblock other Mac users</Onboarding.Heading>
      <Onboarding.Text centered className="max-w-3xl mt-4">
        For maximum safety, Gertrude blocks all internet for unknown users unless you
        explicitly allow them access. Click below to exempt any users{` `}
        <em>(like parent accounts)</em> that <b>should</b> have internet. You can always
        change this later.
      </Onboarding.Text>
      <div className="min-w-[660px] border border-slate-200 bg-white rounded-2xl mt-8 py-1">
        {otherUsers
          .filter((user) => exemptableUserIds.includes(user.id))
          .map((user) => (
            <ExemptUser
              key={user.id}
              name={user.name}
              isExempt={exemptUserIds.includes(user.id) ?? false}
              onToggle={() =>
                emit({
                  case: `setUserExemption`,
                  userId: user.id,
                  enabled: !exemptUserIds.includes(user.id),
                })
              }
              isAdmin={user.isAdmin}
            />
          ))}
      </div>
      <Callout
        className={cx(`mt-8`, exemptUserIds.length === 0 && `opacity-0`)}
        heading=""
        type="warning"
      >
        Make sure your child <b className="underline">doesn’t know the password</b> for
        any exempt users.
      </Callout>
      <Onboarding.PrimaryButton className="mt-8">
        Continue
        <i className="fa-solid fa-arrow-right ml-3" />
      </Onboarding.PrimaryButton>
    </Onboarding.Centered>
  );
};

export default ExemptUsers;
