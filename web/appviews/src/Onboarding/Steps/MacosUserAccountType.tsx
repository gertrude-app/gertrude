import React, { useState } from 'react';
import cx from 'classnames';
import type { AppEvent, MacOSUser, UserRemediationStep } from '../onboarding-store';
import QrCode from '../images/signup-qr-code.png';
import { Button } from '@shared/components';
import TellMeMoreButton from '../TellMeMoreButton';
import InformationModal from '../InformationModal';

interface Emit {
  emit(event: AppEvent): unknown;
}

interface Props extends Emit {
  users: Array<MacOSUser>;
  current: MacOSUser;
  remediationStep?: UserRemediationStep;
}

const MacOSUserAccountType: React.FC<Props> = ({
  emit,
  users,
  current,
  remediationStep,
}) => {
  const admins = users.filter((u) => u.isAdmin).map((u) => u.name);
  const nonAdmins = users.filter((u) => !u.isAdmin).map((u) => u.name);
  const demotable = admins.length > 1 ? [...admins] : [];

  let body: JSX.Element;
  if (!current.isAdmin) {
    body = <HappyPath emit={emit} adminUsers={admins} userName={current.name} />;
  } else {
    switch (remediationStep) {
      case undefined:
        body = <WarnUserIsAdmin emit={emit} />;
        break;

      case `choose`:
        body = (
          <ChooseRemediation emit={emit} nonAdmins={nonAdmins} demotable={demotable} />
        );
        break;

      case `create`:
      case `switch`:
      case `demote`:
        body = <StartRemediation action={remediationStep} />;
        break;
    }
  }

  return body;
};

export default MacOSUserAccountType;

type ChooseRemediationProps = Emit & {
  nonAdmins: string[];
  demotable: string[];
};

const ChooseRemediation: React.FC<ChooseRemediationProps> = ({
  emit,
  demotable,
  nonAdmins,
}) => {
  const canDemote = demotable.length > 0;
  const canSwitch = nonAdmins.length > 0;
  const numRemediations = canDemote && canSwitch ? `three` : `two`;
  return (
    <div>
      <p className="my-3">
        There are {numRemediations} ways to fix this issue, and we have short videos
        showing you how to do each of them.
      </p>
      <ol className="list-decimal list-inside">
        {canSwitch && (
          <li>
            {nonAdmins.length === 1
              ? `Have your child always use the existing non-admin user `
              : `Have your child always use one of the the non-admin users: `}
            <b>{nonAdmins.join(`, `)}</b>
            <button
              className="bg-blue-500 text-white font-bold py-2 px-4"
              onClick={() => emit({ case: `chooseSwitchToNonAdminUserClicked` })}
            >
              Show me how &rarr;
            </button>
          </li>
        )}
        {canDemote && (
          <li>
            {demotable.length === 1
              ? `Remove the admin privilege from the existing user `
              : `Remove the admin privilege from one of these existing users: `}
            <b>{demotable.join(`, `)}</b> and have your child always login as that user
            <button
              className="bg-blue-500 text-white font-bold py-2 px-4"
              onClick={() => emit({ case: `chooseDemoteAdminClicked` })}
            >
              Show me how &rarr;
            </button>
          </li>
        )}
        <li>
          Create a <b>new non-admin user</b> for your child to always log in with
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `chooseCreateNonAdminClicked` })}
          >
            Show me how &rarr;
          </button>
        </li>
      </ol>
    </div>
  );
};

interface StartRemediationProps {
  action: 'create' | 'switch' | 'demote';
}

const StartRemediation: React.FC<StartRemediationProps> = ({ action }) => {
  let lead: string;
  let tutorialSlug: string;
  switch (action) {
    case `create`:
      tutorialSlug = `h1`;
      lead = `Creating a new non-admin macOS user for your child will allow Gertrude to safely do it's job.`;
      break;
    case `switch`:
      lead = `Having your child always use a non-admin macOS user will allow Gertrude to safely do it's job.`;
      tutorialSlug = `h2`;
      break;
    case `demote`:
      lead = `Removing admin privileges for the macOS user your child uses will allow Gertrude to safely do it's job.`;
      tutorialSlug = `h3`;
      break;
  }
  return (
    <div>
      <p className="mb-3">{lead}</p>
      <p className="mb-3">
        It only takes a few minutes, but you'll need to log out of this user
        {action === `demote` ? ` and restart the computer` : ``} as part of the process,
        so it's best if you view the instructions on your phone so we can walk you through
        the process.
      </p>
      <p>
        Aim your phone's camera at the QR code below, or open the URL:{` `}
        <code>https://gertrude.app/{tutorialSlug}</code>
      </p>
      <img className="h-[200px]" src={QrCode} alt="QR code" />
    </div>
  );
};

const WarnUserIsAdmin: React.FC<Emit> = ({ emit }) => (
  <div className="flex h-full flex-col justify-center items-center p-12">
    <h1 className="text-3xl font-bold">Hmm, this user has admin privileges</h1>
    <p className="my-4 text-lg text-slate-500 text-center max-w-2xl">
      This macOS user has admin privileges, and so should <b>not be used</b> by a child
      protected by Gertrude. Admin privileges make it easy for your child to disable and
      bypass Gertrude.
    </p>
    <TellMeMoreButton onClick={() => {}}>Tell me more</TellMeMoreButton>
    <div className="flex flex-col gap-4 mt-8">
      <Button
        color="primary"
        size="large"
        type="button"
        onClick={() => emit({ case: `primaryBtnClicked` })}
        className="shadow shadow-violet-200/80"
      >
        Show me how to fix it <i className="fa-solid fa-arrow-right ml-2" />
      </Button>
      <Button
        color="secondary"
        size="large"
        type="button"
        onClick={() => emit({ case: `primaryBtnClicked` })}
        className="shadow shadow-violet-200/80"
      >
        I understand the risks, proceed anyway{' '}
        <i className="fa-solid fa-arrow-right ml-2" />
      </Button>
    </div>
  </div>
);

interface HappyPathProps extends Emit {
  adminUsers: string[];
  userName: string;
}

const HappyPath: React.FC<HappyPathProps> = ({ emit, userName, adminUsers }) => {
  const [showModal, setShowModal] = useState(false);
  return (
    <div className="h-full flex flex-col justify-center items-center p-12 relative">
      <InformationModal open={showModal} setOpen={setShowModal}>
        Lorem ipsum dolor sit amet consectetur adipisicing elit. Repellat at tempore culpa
        eaque, exercitationem molestiae voluptate, pariatur temporibus inventore excepturi
        sunt odit ea facere placeat iure cumque? Animi, maiores alias.
      </InformationModal>
      <h1 className="text-3xl font-bold">Yay, you've got the right macOS user type!</h1>
      <p className="my-4 text-lg text-slate-500">
        This macOS user (<span>{userName}</span>) does <b>not</b> have admin privileges,
        which is just what we want.
      </p>
      <TellMeMoreButton onClick={() => setShowModal(true)}>
        Why does this matter?
      </TellMeMoreButton>
      <div className="mt-4 mb-8 border border-slate-200 p-6 pt-8 rounded-2xl relative">
        <div className="absolute left-4 -top-6 w-12 h-12 rounded-full bg-slate-50 flex justify-center items-center">
          <i className="fa-solid fas fa-circle-exclamation text-3xl text-orange-300" />
        </div>
        <h3 className="text-lg font-semibold text-slate-700">Watch out!</h3>
        <p className="text-slate-500 mt-2">
          Make sure that your child doesn't know the password for the{` `}
          <span
            className="font-medium"
            dangerouslySetInnerHTML={{
              __html: adminUsers
                .map((name) => `<span key="${name}">${name}</span>`)
                .join(` or `),
            }}
          />
          {` `}
          user, or else they could disable Gertrude.
        </p>
      </div>
      <Button
        color="primary"
        size="large"
        type="button"
        onClick={() => emit({ case: `primaryBtnClicked` })}
      >
        Coninue <i className="fa-solid fa-arrow-right ml-2" />
      </Button>
    </div>
  );
};
