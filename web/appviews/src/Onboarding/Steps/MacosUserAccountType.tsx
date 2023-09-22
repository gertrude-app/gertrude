import React, { useState } from 'react';
import { Button } from '@shared/components';
import type { AppEvent, MacOSUser, UserRemediationStep } from '../onboarding-store';
import QrCode from '../images/signup-qr-code.png';
import TellMeMoreButton from '../TellMeMoreButton';
import InformationModal from '../InformationModal';
import QRCode from '../QRCode';
import Callout from '../Callout';

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
    <div className="p-12 flex flex-col justify-center h-full">
      <h1 className="text-3xl font-bold">Here's how we can fix this</h1>
      <p className="mt-4 mb-8 text-lg text-slate-500 max-w-xl">
        There are {numRemediations} ways to fix this issue, and we have short videos
        showing you how to do each of them.
      </p>
      <ol className="flex flex-col gap-4">
        {canSwitch && (
          <PossibleRemediation
            emit={emit}
            buttonAction="chooseSwitchToNonAdminUserClicked"
          >
            {nonAdmins.length === 1
              ? `Have your child always use the existing non-admin user `
              : `Have your child always use one of the the non-admin users: `}
            <b>{nonAdmins.join(`, `)}</b>
          </PossibleRemediation>
        )}
        {canDemote && (
          <PossibleRemediation emit={emit} buttonAction="chooseDemoteAdminClicked">
            {demotable.length === 1
              ? `Remove the admin privilege from the existing user `
              : `Remove the admin privilege from one of these existing users: `}
            <b>{demotable.join(`, `)}</b> and have your child always login as that user
          </PossibleRemediation>
        )}
        <PossibleRemediation emit={emit} buttonAction="chooseCreateNonAdminClicked">
          Create a <b>new non-admin user</b> for your child to always log in with
        </PossibleRemediation>
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
      lead = `Creating a new non-admin macOS user for your child will allow Gertrude to safely do its job.`;
      break;
    case `switch`:
      lead = `Having your child always use a non-admin macOS user will allow Gertrude to safely do its job.`;
      tutorialSlug = `h2`;
      break;
    case `demote`:
      lead = `Removing admin privileges for the macOS user your child uses will allow Gertrude to safely do its job.`;
      tutorialSlug = `h3`;
      break;
  }
  return (
    <div className="flex flex-col justify-center items-center h-full p-12">
      <h2 className="text-3xl font-bold max-w-2xl text-center">{lead}</h2>
      <p className="mt-6 mb-4 max-w-3xl text-lg text-slate-500 text-center">
        It only takes a few minutes, but you'll need to log out of this user
        {action === `demote` ? ` and restart the computer` : ``} as part of the process,
        so it's best if you view the instructions on your phone so we can walk you through
        the process.
      </p>
      <p className="text-lg text-slate-600 font-medium max-w-xl text-center">
        Aim your phone's camera at the QR code below for a video that will walk you
        through every step.
      </p>
      <div className="flex justify-center mt-8">
        <QRCode img={QrCode} url={`https://gertrude.app/${tutorialSlug}`} />
      </div>
    </div>
  );
};

const WarnUserIsAdmin: React.FC<Emit> = ({ emit }) => {
  const [showModal, setShowModal] = useState(false);
  return (
    <div className="flex h-full flex-col justify-center items-center p-12 relative">
      <InformationModal open={showModal} setOpen={setShowModal}>
        Lorem ipsum dolor sit amet consectetur adipisicing elit. Repellat at tempore culpa
        eaque, exercitationem molestiae voluptate, pariatur temporibus inventore excepturi
        sunt odit ea facere placeat iure cumque? Animi, maiores alias.
      </InformationModal>
      <h1 className="text-3xl font-bold">Hmm, this user has admin privileges</h1>
      <p className="my-4 text-lg text-slate-500 text-center max-w-2xl">
        This macOS user has admin privileges, and so should <b>not be used</b> by a child
        protected by Gertrude. Admin privileges make it easy for your child to disable and
        bypass Gertrude.
      </p>
      <TellMeMoreButton onClick={() => setShowModal(true)}>Tell me more</TellMeMoreButton>
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
          I understand the risks, proceed anyway{` `}
          <i className="fa-solid fa-arrow-right ml-2" />
        </Button>
      </div>
    </div>
  );
};

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
      <Callout heading="Watch out!" type={`warning`} className="mt-4 mb-8">
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
      </Callout>
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

type PossibleRemediationProps = Emit & {
  buttonAction:
    | 'chooseCreateNonAdminClicked'
    | 'chooseSwitchToNonAdminUserClicked'
    | 'chooseDemoteAdminClicked';
  children: React.ReactNode;
};

const PossibleRemediation: React.FC<PossibleRemediationProps> = ({
  emit,
  buttonAction,
  children,
}) => (
  <li className="bg-white shadow-md shadow-slate-300/30 rounded-2xl flex flex-col max-w-3xl">
    <p className="text-slate-600 p-6 pb-2 text-lg">{children}</p>
    <Button
      color="secondary"
      size="medium"
      type="button"
      onClick={() => emit({ case: buttonAction })}
      className="self-end m-4 mt-0"
    >
      Show me how <i className="fa-solid fa-arrow-right ml-2" />
    </Button>
  </li>
);
