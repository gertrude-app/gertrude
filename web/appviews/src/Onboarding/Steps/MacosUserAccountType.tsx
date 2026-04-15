import { Button, TextInput } from '@shared/components';
import cx from 'classnames';
import React, { useContext, useMemo, useState } from 'react';
import type { MacOSUser, RequestState, UserRemediationStep } from '../onboarding-store';
import Callout from '../Callout';
import InformationModal from '../InformationModal';
import OnboardingContext from '../OnboardingContext';
import QRCode from '../QRCode';
import TellMeMoreButton from '../TellMeMoreButton';
import * as Onboarding from '../UtilityComponents';

interface Props {
  users: Array<MacOSUser>;
  current?: MacOSUser;
  remediationStep?: UserRemediationStep;
  logoutConfirmVisible: boolean;
  createUserRequest: RequestState;
  createdChildUser?: { fullName: string; username: string };
}

const MacOSUserAccountType: React.FC<Props> = ({
  users,
  current,
  remediationStep,
  logoutConfirmVisible,
  createUserRequest,
  createdChildUser,
}) => {
  const admins = users.filter((u) => u.isAdmin).map((u) => u.name);
  const nonAdmins = users.filter((u) => !u.isAdmin).map((u) => u.name);
  const demotable = admins.length > 1 ? [...admins] : [];

  const body = ((): React.ReactNode => {
    if (current?.isAdmin === false) {
      return <HappyPath adminUsers={admins} userName={current.name} />;
    }
    switch (remediationStep) {
      case undefined:
        return <WarnUserIsAdmin />;
      case `choose`:
        return <ChooseRemediation nonAdmins={nonAdmins} demotable={demotable} />;
      case `create`:
      case `switch`:
      case `demote`:
        return <StartRemediation action={remediationStep} />;
      case `createForm`:
        return <CreateUserForm createUserRequest={createUserRequest} />;
      case `createSuccess`:
        return (
          <PostCreateConfirm
            childName={createdChildUser?.fullName ?? ``}
            username={createdChildUser?.username ?? ``}
            currentUserName={current?.name ?? ``}
          />
        );
    }
  })();

  return (
    <>
      {body}
      {logoutConfirmVisible && (
        <LogoutConfirmModal currentUserName={current?.name ?? ``} />
      )}
    </>
  );
};

export default MacOSUserAccountType;

// --- Warn: admin user should not use Gertrude ---

const WarnUserIsAdmin: React.FC = () => (
  <Onboarding.Centered>
    <div className="w-16 h-16 rounded-full bg-amber-100 flex justify-center items-center mb-5">
      <i className="fa-solid fa-triangle-exclamation text-3xl text-amber-500" />
    </div>
    <Onboarding.Heading centered className="max-w-2xl">
      Gertrude can’t fully protect this account
    </Onboarding.Heading>
    <Onboarding.Text className="mt-4 mb-8 max-w-xl" centered>
      This Mac account has <b>admin privileges</b>. Anyone with the password can quit or
      uninstall Gertrude — including your child.
    </Onboarding.Text>
    <div className="grid grid-cols-2 gap-5 max-w-xl w-full mb-10">
      <StatCard
        big="48%"
        label="of admin installs get defeated with the password"
        tone="red"
      />
      <StatCard
        big="12%"
        label="of admin installs succeed with Gertrude long-term"
        tone="amber"
      />
    </div>
    <Onboarding.ButtonGroup
      primary="Fix this for me"
      secondary={{ text: `I accept the risk` }}
    />
  </Onboarding.Centered>
);

const StatCard: React.FC<{
  big: string;
  label: string;
  tone: `red` | `amber`;
}> = ({ big, label, tone }) => (
  <div className="bg-white rounded-2xl p-5 shadow-md shadow-slate-300/30 flex flex-col">
    <div
      className={
        tone === `red`
          ? `text-4xl font-bold text-rose-500 mb-1`
          : `text-4xl font-bold text-amber-500 mb-1`
      }
    >
      {big}
    </div>
    <div className="text-slate-700 text-sm font-medium leading-snug">{label}</div>
  </div>
);

// --- Choose remediation ---

type ChooseRemediationProps = {
  nonAdmins: string[];
  demotable: string[];
};

const ChooseRemediation: React.FC<ChooseRemediationProps> = ({
  nonAdmins,
  demotable,
}) => {
  const { emit } = useContext(OnboardingContext);
  const canSwitch = nonAdmins.length > 0;
  const canDemote = demotable.length > 0;
  return (
    <div className="p-12 flex flex-col justify-center items-center h-full">
      <Onboarding.Heading className="max-w-3xl w-full">
        How do you want to fix it?
      </Onboarding.Heading>
      <ol className="flex flex-col space-y-4 mt-8 max-w-3xl w-full">
        {canSwitch && (
          <ChoiceCard
            chip="Fastest"
            icon="fa-right-left"
            tone="emerald"
            recommended
            headline={
              nonAdmins.length === 1 ? (
                <>
                  Use <span className="text-emerald-600">{nonAdmins[0]}</span> instead
                </>
              ) : (
                <>Switch to a non-admin user</>
              )
            }
            body={
              nonAdmins.length === 1 ? (
                `Log out, and from now on your child signs in as ${nonAdmins[0]}.`
              ) : (
                <>
                  Log out, and from now on your child signs in as{` `}
                  <NameList
                    names={nonAdmins}
                    className="font-semibold text-emerald-600"
                  />
                  .
                </>
              )
            }
            buttonText="Log out and switch"
            onClick={() => emit({ case: `chooseSwitchToNonAdminUserClicked` })}
          />
        )}
        <ChoiceCard
          chip="Fast"
          icon="fa-user-plus"
          tone="violet"
          recommended={!canSwitch}
          headline={<>Create a new account for your child</>}
          body={`We’ll set one up for you right here in Gertrude.`}
          buttonText="Create account"
          onClick={() => emit({ case: `chooseCreateNonAdminClicked` })}
        />
        {canDemote && (
          <ChoiceCard
            icon="fa-user-shield"
            tone="slate"
            headline={
              demotable.length === 1 ? (
                <>
                  Remove admin from{` `}
                  <span className="text-slate-600">{demotable[0]}</span>
                </>
              ) : (
                <>Remove admin from an existing user</>
              )
            }
            body={
              demotable.length === 1 ? (
                `Convert a user into Standard. Short video walks you through it.`
              ) : (
                <>
                  Convert{` `}
                  <NameList names={demotable} className="font-semibold text-slate-700" />
                  {` `}into a Standard account. Short video walks you through it.
                </>
              )
            }
            buttonText="Show me how"
            onClick={() => emit({ case: `chooseDemoteAdminClicked` })}
          />
        )}
      </ol>
    </div>
  );
};

type Tone = `violet` | `emerald` | `slate`;

const ChoiceCard: React.FC<{
  chip?: string;
  icon: string;
  tone: Tone;
  recommended?: boolean;
  headline: React.ReactNode;
  body: React.ReactNode;
  buttonText: string;
  onClick?: () => void;
}> = ({ chip, icon, tone, recommended, headline, body, buttonText, onClick }) => (
  <li
    className={cx(
      `relative bg-white rounded-2xl flex items-center p-5 pr-6 transition-shadow`,
      recommended
        ? `ring-2 ring-violet-300 shadow-lg shadow-violet-200/40`
        : `shadow-md shadow-slate-300/30`,
    )}
  >
    <IconBubble icon={icon} tone={tone} />
    <div className="flex-1 ml-5 mr-4 min-w-0">
      <div className="flex items-center mb-1 gap-3">
        <h3 className="text-xl font-semibold text-slate-800 leading-tight">{headline}</h3>
        {chip && <Chip tone={tone}>{chip}</Chip>}
      </div>
      <p className="text-slate-500 text-[15px] leading-snug">{body}</p>
    </div>
    <Button
      color={recommended ? `primary` : `secondary`}
      size="medium"
      type="button"
      onClick={() => onClick?.()}
      className="flex-shrink-0"
      tabIndex={-1}
    >
      {buttonText} <i className="fa-solid fa-arrow-right ml-2" />
    </Button>
  </li>
);

const IconBubble: React.FC<{ icon: string; tone: Tone }> = ({ icon, tone }) => (
  <div
    className={cx(
      `w-14 h-14 rounded-2xl flex items-center justify-center flex-shrink-0`,
      tone === `violet` &&
        `bg-gradient-to-br from-violet-100 to-fuchsia-100 text-violet-600`,
      tone === `emerald` &&
        `bg-gradient-to-br from-emerald-100 to-teal-100 text-emerald-600`,
      tone === `slate` && `bg-gradient-to-br from-slate-100 to-slate-200 text-slate-500`,
    )}
  >
    <i className={cx(`fa-solid text-2xl`, icon)} />
  </div>
);

const NameList: React.FC<{ names: string[]; className: string }> = ({
  names,
  className,
}) => (
  <>
    {names.map((name, i) => (
      <React.Fragment key={name}>
        <span className={className}>{name}</span>
        {i < names.length - 2 && `, `}
        {i === names.length - 2 && ` or `}
      </React.Fragment>
    ))}
  </>
);

const Chip: React.FC<{ tone: Tone; children: React.ReactNode }> = ({
  tone,
  children,
}) => (
  <span
    className={cx(
      `text-[11px] font-semibold px-2.5 py-0.5 rounded-full whitespace-nowrap uppercase tracking-wide`,
      tone === `violet` && `bg-violet-100 text-violet-700`,
      tone === `emerald` && `bg-emerald-100 text-emerald-700`,
      tone === `slate` && `bg-slate-100 text-slate-500`,
    )}
  >
    {children}
  </span>
);

// --- Start remediation (QR tutorial: switch / demote / create fallback) ---

interface StartRemediationProps {
  action: `create` | `switch` | `demote`;
}

const StartRemediation: React.FC<StartRemediationProps> = ({ action }) => {
  const { osVersion } = useContext(OnboardingContext);
  const osSuffix = (() => {
    switch (osVersion.name) {
      case `catalina`:
        return `cl`;
      case `bigSur`:
        return `bs`;
      case `monterey`:
        return `mr`;
      case `ventura`:
        return `vt`;
      case `sonoma`:
        return `sn`;
      case `sequoia`:
        return `sq`;
      case `tahoe`:
        return `th`;
    }
  })();
  let lead: string;
  let tutorialSlug: string;
  switch (action) {
    case `create`:
      tutorialSlug = `cu-${osSuffix}`;
      lead = `Creating a new non-admin macOS user for your child will allow Gertrude to safely do its job.`;
      break;
    case `switch`:
      lead = `Having your child always use a non-admin macOS user will allow Gertrude to safely do its job.`;
      tutorialSlug = `su-${osSuffix}`;
      break;
    case `demote`:
      lead = `Removing admin privileges for the macOS user your child uses will allow Gertrude to safely do its job.`;
      tutorialSlug = `du-${osSuffix}`;
      break;
  }
  return (
    <div className="flex flex-col justify-center items-center h-full p-12 pt-16">
      <Onboarding.Heading className="max-w-[730px]" centered>
        {lead}
      </Onboarding.Heading>
      <Onboarding.Text className="mt-6 mb-4 max-w-3xl" centered>
        It only takes a few minutes, but you’ll need to <b>log out</b> of this user
        {action === `demote` ? ` (and maybe restart the computer)` : ``} as part of the
        process, so it’s best if you view the instructions on your phone so we can walk
        you through the process.
      </Onboarding.Text>
      <Onboarding.Text className="font-medium max-w-xl !text-slate-600" centered>
        Aim your phone’s camera at the QR code below for a video that will walk you
        through every step.
      </Onboarding.Text>
      <div className="flex justify-center mt-8">
        <QRCode url={`gertrude.app/${tutorialSlug}`} />
      </div>
      <Onboarding.EscapeHatchButton>
        Or, continue without fixing &rarr;
      </Onboarding.EscapeHatchButton>
    </div>
  );
};

// --- Happy path (non-admin) ---

const AboutUsers: React.FC = () => (
  <>
    Mac computers allow you to have more than one <b>user.</b> Having more than one user
    allows different people to use the same computer, each with their own settings and
    documents. There are two <i>types</i> of users: <b>Admin</b> and{` `}
    <b>Standard.</b> Admin users can disable, bypass, and uninstall Gertrude, while
    Standard users cannot.
  </>
);

interface HappyPathProps {
  adminUsers: string[];
  userName: string;
}

const HappyPath: React.FC<HappyPathProps> = ({ userName, adminUsers }) => {
  const [showModal, setShowModal] = useState(false);
  const { emit } = useContext(OnboardingContext);
  return (
    <Onboarding.Centered className="relative">
      <InformationModal open={showModal} onClose={() => setShowModal(false)}>
        <AboutUsers />
      </InformationModal>
      <Onboarding.Heading>Yay, you’ve got the right macOS user type!</Onboarding.Heading>
      <Onboarding.Text className="my-4" centered>
        This macOS user (<span>{userName}</span>) does <b>not</b> have admin privileges,
        which is just what we want.
      </Onboarding.Text>
      <TellMeMoreButton
        onClick={() => {
          setShowModal(true);
          emit({
            case: `infoModalOpened`,
            step: `macosUserAccountType`,
            detail: `happyPath`,
          });
        }}
      >
        Why does this matter?
      </TellMeMoreButton>
      <Callout heading="Watch out!" type={`warning`} className="mt-4 mb-8">
        Make sure that your child doesn’t know the <b>password</b> for the{` `}
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
      <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right">
        Continue
      </Onboarding.PrimaryButton>
    </Onboarding.Centered>
  );
};

// --- Logout confirmation modal (B1 Phase 3) ---

export const LogoutConfirmModal: React.FC<{
  currentUserName: string;
}> = ({ currentUserName }) => {
  const { emit } = useContext(OnboardingContext);
  return (
    <div className="absolute inset-0 flex items-center justify-center z-20">
      <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm" />
      <div
        className="relative bg-white rounded-3xl shadow-2xl shadow-slate-900/20 max-w-md w-[90%] p-8 z-10"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 className="text-2xl font-bold text-slate-800 mb-2">
          Ready to log out of {currentUserName}?
        </h2>
        <p className="text-slate-500 mb-6">
          Save anything you have open first — logout happens right away.
        </p>
        <div className="flex flex-row-reverse space-x-reverse space-x-3">
          <Button
            type="button"
            color="primary"
            size="large"
            onClick={() => emit({ case: `logoutConfirmClicked` })}
            tabIndex={-1}
          >
            Log out
            <i className="fa-solid fa-arrow-right ml-2" />
          </Button>
          <Button
            type="button"
            color="secondary"
            size="large"
            onClick={() => emit({ case: `logoutConfirmCanceled` })}
            tabIndex={-1}
          >
            Cancel
          </Button>
        </div>
      </div>
    </div>
  );
};

// --- In-app create-user form (B2) ---

const RESERVED_USERNAMES = new Set([
  `root`,
  `admin`,
  `administrator`,
  `daemon`,
  `nobody`,
  `guest`,
  `sharedaccess`,
  `gertrude`,
]);

const MIN_PASSWORD_LEN = 4;

function deriveUsername(fullName: string): string {
  return fullName
    .toLowerCase()
    .normalize(`NFKD`)
    .replace(/[^a-z0-9]/g, ``)
    .slice(0, 20);
}

interface Validity {
  fullName: { ok: boolean; hint?: string };
  username: { ok: boolean; hint?: string };
  password: { ok: boolean; hint?: string };
  allOk: boolean;
}

function validate(fullName: string, username: string, password: string): Validity {
  const fn = fullName.trim();
  const un = username.trim();
  const fullNameValid = fn.length >= 2;
  const usernameValid =
    un.length >= 3 && /^[a-z][a-z0-9]*$/.test(un) && !RESERVED_USERNAMES.has(un);
  const passwordValid = password.length >= MIN_PASSWORD_LEN;
  return {
    fullName: {
      ok: fullNameValid,
      hint: fn.length === 0 ? undefined : fullNameValid ? undefined : `Too short`,
    },
    username: {
      ok: usernameValid,
      hint:
        un.length === 0
          ? undefined
          : RESERVED_USERNAMES.has(un)
            ? `This username is reserved by macOS`
            : !/^[a-z]/.test(un)
              ? `Must start with a letter`
              : !/^[a-z0-9]+$/.test(un)
                ? `Only lowercase letters and numbers — no spaces`
                : un.length < 3
                  ? `At least 3 characters`
                  : undefined,
    },
    password: {
      ok: passwordValid,
      hint:
        password.length === 0
          ? undefined
          : passwordValid
            ? undefined
            : `At least ${MIN_PASSWORD_LEN} characters`,
    },
    allOk: fullNameValid && usernameValid && passwordValid,
  };
}

export const CreateUserForm: React.FC<{
  createUserRequest?: RequestState;
}> = ({ createUserRequest = { case: `idle` } }) => {
  const { emit, currentStep } = useContext(OnboardingContext);
  const inactive = currentStep !== `macosUserAccountType`;
  const submitting = createUserRequest.case === `ongoing`;
  const submitError =
    createUserRequest.case === `failed` ? createUserRequest.error : undefined;
  const [fullName, setFullName] = useState(``);
  const [usernameEdited, setUsernameEdited] = useState(false);
  const [usernameOverride, setUsernameOverride] = useState(``);
  const [password, setPassword] = useState(``);
  const [showPassword, setShowPassword] = useState(false);
  const [passwordHint, setPasswordHint] = useState(``);
  const [touched, setTouched] = useState({
    fullName: false,
    username: false,
    password: false,
  });

  const username = usernameEdited ? usernameOverride : deriveUsername(fullName);
  const v = useMemo(
    () => validate(fullName, username, password),
    [fullName, username, password],
  );

  return (
    <div className="h-full flex flex-col justify-center items-center px-10">
      <div className="max-w-2xl w-full">
        <div className="flex items-center mb-8">
          <div className="w-14 h-14 rounded-full bg-violet-100 flex items-center justify-center mr-4 flex-shrink-0">
            <i className="fa-solid fa-user-plus text-violet-500 text-2xl" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-800 leading-tight">
              Create your child’s account
            </h1>
            <p className="text-slate-500 text-sm mt-0.5">
              This account will be fully safe for your child to use with Gertrude.
            </p>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-x-4 gap-y-3">
          <FormField
            label="Full name"
            hint={touched.fullName ? v.fullName.hint : undefined}
            valid={touched.fullName && fullName.length > 0 ? v.fullName.ok : undefined}
          >
            <div onBlur={() => setTouched((t) => ({ ...t, fullName: true }))}>
              <TextInput
                type="text"
                value={fullName}
                setValue={setFullName}
                placeholder="John"
                autoComplete="off"
                disabled={inactive}
              />
            </div>
          </FormField>
          <FormField
            label="Account name"
            hint={touched.username ? v.username.hint : undefined}
            valid={touched.username && username.length > 0 ? v.username.ok : undefined}
          >
            <input
              type="text"
              value={username}
              onChange={(e) => {
                setUsernameEdited(true);
                setUsernameOverride(e.target.value);
              }}
              onBlur={() => setTouched((t) => ({ ...t, username: true }))}
              placeholder="john"
              name="gertrude-child-username"
              autoComplete="off"
              autoCorrect="off"
              autoCapitalize="off"
              spellCheck={false}
              data-1p-ignore=""
              data-lpignore="true"
              data-form-type="other"
              tabIndex={-1}
              disabled={inactive}
              className={cx(
                `w-full py-3 px-4 shadow-sm`,
                `border border-slate-200 rounded-xl`,
                `transition-[border-color,ring-color] duration-150`,
                `text-slate-600 placeholder:text-slate-400/90 placeholder:antialiased`,
                `outline-none focus:shadow-md focus:border-indigo-500 focus:ring-indigo-500 focus:ring-1`,
              )}
            />
          </FormField>
          <div className="col-span-2">
            <FormField
              label="Password"
              hint={touched.password ? v.password.hint : undefined}
              valid={touched.password && password.length > 0 ? v.password.ok : undefined}
            >
              <div
                className="relative"
                onBlur={() => setTouched((t) => ({ ...t, password: true }))}
              >
                <input
                  type={showPassword ? `text` : `password`}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder={`At least ${MIN_PASSWORD_LEN} characters`}
                  name="gertrude-child-pw"
                  autoComplete="off"
                  autoCorrect="off"
                  autoCapitalize="off"
                  spellCheck={false}
                  data-1p-ignore=""
                  data-lpignore="true"
                  data-form-type="other"
                  disabled={inactive}
                  className={cx(
                    `w-full py-3 pl-4 pr-11 shadow-sm`,
                    `border border-slate-200 rounded-xl`,
                    `transition-[border-color,ring-color] duration-150`,
                    `text-slate-600 placeholder:text-slate-400/90 placeholder:antialiased`,
                    `outline-none focus:shadow-md focus:border-indigo-500 focus:ring-indigo-500 focus:ring-1`,
                  )}
                />
                <button
                  type="button"
                  tabIndex={-1}
                  onClick={() => setShowPassword((s) => !s)}
                  className="absolute inset-y-0 right-0 flex items-center pr-3 text-slate-400 hover:text-slate-600 transition-colors"
                  aria-label={showPassword ? `Hide password` : `Show password`}
                >
                  <i
                    className={cx(`fa-solid`, showPassword ? `fa-eye-slash` : `fa-eye`)}
                  />
                </button>
              </div>
            </FormField>
          </div>
          <div className="col-span-2">
            <FormField label="Password hint">
              <input
                type="text"
                value={passwordHint}
                onChange={(e) => setPasswordHint(e.target.value)}
                placeholder="Shown on the login screen if they forget (optional)"
                name="gertrude-child-hint"
                autoComplete="off"
                disabled={inactive}
                className={cx(
                  `w-full py-3 px-4 shadow-sm`,
                  `border border-slate-200 rounded-xl`,
                  `transition-[border-color,ring-color] duration-150`,
                  `text-slate-600 placeholder:text-slate-400/90 placeholder:antialiased`,
                  `outline-none focus:shadow-md focus:border-indigo-500 focus:ring-indigo-500 focus:ring-1`,
                )}
              />
            </FormField>
          </div>
        </div>
        {submitError && (
          <div className="mt-4 text-sm text-rose-500 text-right">{submitError}</div>
        )}
        <div className="flex flex-row-reverse space-x-reverse space-x-3 mt-6">
          <Button
            type="button"
            color="primary"
            size="large"
            disabled={!v.allOk || submitting}
            onClick={() => {
              const trimmedHint = passwordHint.trim();
              emit({
                case: `createUserSubmitted`,
                fullName: fullName.trim(),
                username: username.trim(),
                password,
                passwordHint: trimmedHint.length > 0 ? trimmedHint : undefined,
              });
            }}
            tabIndex={-1}
            className={cx((!v.allOk || submitting) && `opacity-50 cursor-not-allowed`)}
          >
            {submitting ? `Creating…` : `Create account`}
            <i className="fa-solid fa-arrow-right ml-2" />
          </Button>
          <Button
            type="button"
            color="secondary"
            size="large"
            disabled={submitting}
            onClick={() => emit({ case: `createUserCanceled` })}
            tabIndex={-1}
            className={cx(submitting && `opacity-50 cursor-not-allowed`)}
          >
            Back
          </Button>
        </div>
      </div>
    </div>
  );
};

const FormField: React.FC<{
  label: string;
  hint?: string;
  valid?: boolean;
  children: React.ReactNode;
}> = ({ label, hint, valid, children }) => (
  <div>
    <div className="flex items-baseline justify-between mb-1">
      <label className="text-sm font-medium text-slate-700">{label}</label>
      {valid === true && (
        <i className="fa-solid fa-circle-check text-emerald-500 text-sm" />
      )}
    </div>
    {children}
    {hint && (
      <div
        className={cx(
          `text-xs mt-1`,
          valid === false ? `text-rose-500` : `text-slate-400`,
        )}
      >
        {hint}
      </div>
    )}
  </div>
);

// --- Post-create confirmation (log out as parent, sign in as child) ---

export const PostCreateConfirm: React.FC<{
  childName: string;
  username: string;
  currentUserName: string;
}> = ({ childName, username, currentUserName }) => {
  const { emit } = useContext(OnboardingContext);
  return (
    <Onboarding.Centered>
      <Onboarding.Heading centered className="max-w-2xl">
        {childName}’s account is ready
      </Onboarding.Heading>
      <Onboarding.Text className="mt-4 mb-8 max-w-xl" centered>
        One more step: log out of <b>{currentUserName}</b>, then sign back in as{` `}
        <b>{username}</b>. That’s the account Gertrude will protect.
      </Onboarding.Text>
      <div className="flex items-center space-x-4 mb-8">
        <UserBox name={currentUserName} sub="Admin (you)" tone="muted" />
        <i className="fa-solid fa-arrow-right text-slate-400 text-2xl" />
        <UserBox name={username} sub="Standard" tone="highlight" />
      </div>
      <Callout type="info" className="max-w-2xl mb-8">
        After you sign in as <code>{username},</code> <b>launch the Gertrude app</b> to
        finish the setup.
      </Callout>
      <Button
        type="button"
        color="primary"
        size="large"
        onClick={() => emit({ case: `postCreateLogoutClicked` })}
        tabIndex={-1}
      >
        Log out now
        <i className="fa-solid fa-arrow-right ml-3" />
      </Button>
      <Onboarding.EscapeHatchButton
        onClick={() => emit({ case: `postCreateSkipClicked` })}
      >
        Or, I’ll log out later &rarr;
      </Onboarding.EscapeHatchButton>
    </Onboarding.Centered>
  );
};

const UserBox: React.FC<{
  name: string;
  sub: string;
  tone: `muted` | `highlight`;
}> = ({ name, sub, tone }) => (
  <div
    className={cx(
      `flex flex-col items-center rounded-2xl p-5 w-40 border-2`,
      tone === `highlight`
        ? `bg-white border-violet-400 shadow-lg shadow-violet-300/60`
        : `bg-slate-50 border-slate-200 opacity-70`,
    )}
  >
    <div
      className={cx(
        `w-14 h-14 rounded-full flex items-center justify-center mb-2`,
        tone === `highlight`
          ? `bg-gradient-to-br from-violet-500 to-fuchsia-500 text-white`
          : `bg-slate-200 text-slate-500`,
      )}
    >
      <i className="fa-solid fa-user text-2xl" />
    </div>
    <div className="font-semibold text-slate-700 text-sm">{name}</div>
    <div className="text-xs text-slate-400">{sub}</div>
  </div>
);
