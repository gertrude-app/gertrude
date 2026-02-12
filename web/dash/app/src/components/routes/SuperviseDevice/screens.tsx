import {
  ChildAssignmentPicker,
  DeviceContextBanner,
  PageHeading,
} from '@dash/components';
import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React, { useState } from 'react';
import type { ChildSelection } from '@dash/components';

type DeviceInfo = {
  childName: string;
  modelName: string;
  iosVersion: string;
};

export const ScreenShell: React.FC<{
  title: string;
  children: React.ReactNode;
}> = ({ title, children }) => (
  <div className="relative max-w-3xl">
    <PageHeading icon="phone">{title}</PageHeading>
    <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
      {children}
    </div>
  </div>
);

export const ClaimScreen: React.FC<{
  children: Array<{ id: string; name: string }>;
  deviceType: string;
  modelName: string;
  iosVersion: string;
  onSubmit: (selection: ChildSelection) => void;
  onCancel: () => void;
  isSubmitting: boolean;
  error?: string;
}> = ({
  children,
  deviceType,
  modelName,
  iosVersion,
  onSubmit,
  onCancel,
  isSubmitting,
  error,
}) => (
  <>
    <div className="mb-8">
      <DeviceContextBanner
        modelName={modelName}
        iosVersion={iosVersion}
        deviceType={deviceType as `iPhone` | `iPad`}
        label={`Adding ${deviceType}:`}
      />
    </div>
    <ChildAssignmentPicker
      children={children}
      deviceType={deviceType}
      onSubmit={onSubmit}
      onCancel={onCancel}
      isSubmitting={isSubmitting}
      error={error}
    />
  </>
);

const ScreenHeader: React.FC<{
  icon: string;
  title: string;
  subtitle?: string;
  step?: { current: number; total: number };
}> = ({ icon, title, subtitle, step }) => (
  <div className="flex items-start gap-4 mb-6">
    <div className="w-14 h-14 rounded-xl bg-violet-100 flex items-center justify-center flex-shrink-0">
      <i className={`fa-solid fa-${icon} text-violet-600 text-2xl`} />
    </div>
    <div className="flex-1">
      {step && (
        <div className="flex items-center justify-between mb-1">
          <p className="text-sm font-medium text-violet-600">
            Step {step.current} of {step.total}
          </p>
          <ProgressDots current={step.current} total={step.total} />
        </div>
      )}
      <h1 className="text-xl font-bold text-slate-800">{title}</h1>
      {subtitle && <p className="text-slate-500 text-sm mt-1">{subtitle}</p>}
    </div>
  </div>
);

export const MobileDetectedScreen: React.FC<{ onThisIsComputer: () => void }> = ({
  onThisIsComputer,
}) => (
  <div className="pt-4">
    <div className="flex flex-col items-center text-center mb-6">
      <div className="relative mb-6">
        <i className="fa-solid fa-laptop text-slate-300 text-6xl" />
        <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-red-100 flex items-center justify-center">
          <i className="fa-solid fa-exclamation text-red-400 text-xs" />
        </div>
      </div>
      <h1 className="text-2xl font-bold text-slate-800 mb-3">Computer Required</h1>
      <p className="text-slate-600 max-w-sm">
        This step requires a Mac or Windows PC with a USB port. Please login to your
        account on a computer to resume the setup.
      </p>
    </div>
    <div className="flex justify-end mt-16">
      <button
        onClick={onThisIsComputer}
        className="text-sm text-slate-400 hover:text-slate-500 hover:bg-slate-100 border border-slate-200 px-3 py-1.5 rounded-lg transition-colors"
      >
        This is a computer
      </button>
    </div>
  </div>
);

export const DownloadHelperScreen: React.FC<
  DeviceInfo & {
    onDownload: (platform: `mac` | `windows`) => void;
    onNext: () => void;
    initialDownloaded?: boolean;
  }
> = ({
  childName,
  modelName,
  iosVersion,
  onDownload,
  onNext,
  initialDownloaded = false,
}) => {
  const [hasDownloaded, setHasDownloaded] = useState(initialDownloaded);
  const [showWindowsModal, setShowWindowsModal] = useState(false);
  const detectedPlatform = /Mac|Macintosh/i.test(navigator.userAgent) ? `mac` : `windows`;

  const handleDownload = (platform: `mac` | `windows`): void => {
    if (platform === `windows`) {
      setShowWindowsModal(true);
    } else {
      setHasDownloaded(true);
      onDownload(platform);
    }
  };

  const handleWindowsDownloadConfirm = (): void => {
    setShowWindowsModal(false);
    setHasDownloaded(true);
    onDownload(`windows`);
  };

  return (
    <div>
      <ScreenHeader
        icon="download"
        title="Download the Supervision Helper App"
        subtitle={`Setting up ${childName}'s ${modelName} · iOS ${iosVersion}`}
        step={{ current: 1, total: 4 }}
      />

      <p className="text-slate-600 text-sm mb-5">
        The helper app is a small app that you run one time on your computer. It will
        guide you through supervising the device so that it can run Gertrude.
      </p>

      <HighlightableCard highlighted className="mb-6">
        <span className="font-medium text-slate-700 block mb-4">
          Download the app for your computer:
        </span>
        <div className="flex gap-3">
          <DownloadButton
            platform="mac"
            primary={!hasDownloaded && detectedPlatform === `mac`}
            onClick={() => handleDownload(`mac`)}
          />
          <DownloadButton
            platform="windows"
            primary={!hasDownloaded && detectedPlatform === `windows`}
            onClick={() => handleDownload(`windows`)}
          />
        </div>
      </HighlightableCard>

      <div className="flex justify-end">
        <Button type="button" color="primary" onClick={onNext} disabled={!hasDownloaded}>
          Next &rarr;
        </Button>
      </div>

      {showWindowsModal && (
        <WindowsSmartScreenModal
          onCancel={() => setShowWindowsModal(false)}
          onDownload={handleWindowsDownloadConfirm}
        />
      )}
    </div>
  );
};

export const LaunchHelperScreen: React.FC<
  DeviceInfo & {
    onNext: () => void;
  }
> = ({ childName, modelName, iosVersion, onNext }) => (
  <div>
    <ScreenHeader
      icon="arrow-up-right-from-square"
      title="Launch the Supervision Helper App"
      subtitle={`Setting up ${childName}'s ${modelName} · iOS ${iosVersion}`}
      step={{ current: 2, total: 4 }}
    />

    <div className="space-y-4 mb-6">
      <HighlightableCard highlighted={false} className="">
        <div className="flex items-center gap-2 mb-3">
          <span className="w-6 h-6 rounded-full bg-violet-100 text-violet-600 text-xs font-bold flex items-center justify-center">
            1
          </span>
          <span className="font-medium text-slate-700">Locate the downloaded file</span>
        </div>
        <p className="text-slate-500 text-sm ml-8">
          Check your <b>downloads folder</b> or <b>desktop</b> or the browser's download
          area for the file you just downloaded.
        </p>
      </HighlightableCard>

      <HighlightableCard highlighted={false} className="">
        <div className="flex items-center gap-2 mb-3">
          <span className="w-6 h-6 rounded-full bg-violet-100 text-violet-600 text-xs font-bold flex items-center justify-center">
            2
          </span>
          <span className="font-medium text-slate-700">Unzip if needed</span>
        </div>
        <p className="text-slate-500 text-sm ml-8">
          Safari unzips files automatically, but other browsers may not. If you see a{` `}
          <code className="text-xs bg-slate-100 px-1.5 py-0.5 rounded font-mono">
            .zip
          </code>
          {` `}file, double-click it to unzip first.
        </p>
      </HighlightableCard>

      <HighlightableCard highlighted={false} className="">
        <div className="flex items-center gap-2 mb-3">
          <span className="w-6 h-6 rounded-full bg-violet-100 text-violet-600 text-xs font-bold flex items-center justify-center">
            3
          </span>
          <span className="font-medium text-slate-700">Launch the app</span>
        </div>
        <div className="flex items-center gap-3 *ml-2">
          <img
            src="/supervise-app-icon.png"
            alt="Gertrude Supervisor app icon"
            className="w-20 h-20"
          />
          <p className="text-slate-500 text-sm">
            Double-click the{` `}
            <strong className="text-slate-700">Gertrude Supervisor</strong>
            {` `}app to open it. Finally, click the button below to continue.
          </p>
        </div>
      </HighlightableCard>
    </div>

    <div className="flex justify-end">
      <Button type="button" color="primary" onClick={onNext}>
        Done, helper app launched &rarr;
      </Button>
    </div>
  </div>
);

export const WindowsSmartScreenModal: React.FC<{
  onCancel: () => void;
  onDownload: () => void;
}> = ({ onCancel, onDownload }) => (
  <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
    <div className="bg-white rounded-2xl shadow-xl max-w-md mx-4 p-6">
      <div className="flex items-center gap-3 mb-4">
        <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center">
          <i className="fa-brands fa-windows text-amber-600 text-lg" />
        </div>
        <h2 className="text-lg font-bold text-slate-800">Windows Security Note</h2>
      </div>
      <p className="text-slate-600 text-sm mb-4">
        Windows will show a security warning for this app. When you see{` `}
        <span className="font-medium">"Windows protected your PC"</span>:
      </p>
      <ol className="text-slate-600 text-sm mb-6 ml-4 space-y-2">
        <li className="flex items-start gap-2">
          <span className="w-5 h-5 rounded-full bg-slate-100 text-slate-600 text-xs font-bold flex items-center justify-center flex-shrink-0 mt-0.5">
            1
          </span>
          <span>
            Click <span className="font-medium">"More info"</span> (small link below the
            warning text)
          </span>
        </li>
        <li className="flex items-start gap-2">
          <span className="w-5 h-5 rounded-full bg-slate-100 text-slate-600 text-xs font-bold flex items-center justify-center flex-shrink-0 mt-0.5">
            2
          </span>
          <span>
            Click <span className="font-medium">"Run anyway"</span>
          </span>
        </li>
      </ol>
      <div className="flex justify-end gap-3">
        <Button type="button" color="tertiary" onClick={onCancel}>
          Cancel
        </Button>
        <Button type="button" color="primary" onClick={onDownload}>
          <i className="fa-brands fa-windows mr-2" />
          Download for Windows
        </Button>
      </div>
    </div>
  </div>
);

export const SuperviseScreen: React.FC<
  DeviceInfo & {
    code: number;
    onDone: () => void;
    initialCopied?: boolean;
  }
> = ({ childName, modelName, iosVersion, code, onDone, initialCopied = false }) => {
  const [hasCopied, setHasCopied] = useState(initialCopied);
  const codeString = String(code).padStart(6, `0`);

  const handleCopyCode = async (): Promise<void> => {
    try {
      await navigator.clipboard.writeText(codeString);
      setHasCopied(true);
    } catch {
      setHasCopied(true);
    }
  };

  return (
    <div>
      <ScreenHeader
        icon="plug"
        title={`Connect ${childName}'s ${modelName} via USB`}
        subtitle={`Setting up ${childName}'s ${modelName} · iOS ${iosVersion}`}
        step={{ current: 3, total: 4 }}
      />

      <HighlightableCard highlighted={!hasCopied} className="mb-4">
        <div className="flex items-center gap-2 mb-4">
          <span className="w-6 h-6 rounded-full bg-violet-100 text-violet-600 text-xs font-bold flex items-center justify-center">
            1
          </span>
          <span className="font-medium text-slate-700">
            Plug {childName}'s {modelName} into this computer
          </span>
        </div>
        <div className="flex justify-center mb-4">
          <UsbConnectionIllustration />
        </div>
        <div className="flex items-center justify-between bg-fuchsia-50 rounded-lg px-4 py-3">
          <div>
            <p className="text-xs text-fuchsia-600 font-medium mb-1">
              Enter this code in the helper app:
            </p>
            <code className="text-2xl text-fuchsia-700 tracking-widest font-bold">
              {codeString}
            </code>
          </div>
          <button
            onClick={handleCopyCode}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium text-sm transition-colors ${
              hasCopied
                ? `bg-fuchsia-200 text-fuchsia-700`
                : `bg-fuchsia-600 text-white hover:bg-fuchsia-700`
            }`}
          >
            <i className={`fa-solid ${hasCopied ? `fa-check` : `fa-copy`}`} />
            {hasCopied ? `Copied` : `Copy Code`}
          </button>
        </div>
      </HighlightableCard>

      <HighlightableCard highlighted={hasCopied} className="mb-6">
        <div className="flex items-center gap-2 mb-3">
          <span className="w-6 h-6 rounded-full bg-violet-100 text-violet-600 text-xs font-bold flex items-center justify-center">
            2
          </span>
          <span className="font-medium text-slate-700">
            Follow the instructions in the helper app
          </span>
        </div>
        <p className="text-slate-500 text-sm ml-8">
          The helper app will guide you through the steps of the supervision process. When
          it's complete, click Done below.
        </p>
      </HighlightableCard>

      <div className="flex justify-end">
        <Button type="button" color="primary" onClick={onDone}>
          Done
        </Button>
      </div>
    </div>
  );
};

export const HighlightableCard: React.FC<{
  highlighted: boolean;
  className?: string;
  children: React.ReactNode;
}> = ({ highlighted, className, children }) => (
  <div
    className={`rounded-2xl p-[2px] ${className ?? ``} ${
      highlighted ? `bg-gradient-to-r from-violet-500 to-fuchsia-500` : `bg-slate-100`
    }`}
  >
    <div className={`rounded-[14px] p-5 ${highlighted ? `bg-white` : `bg-slate-50/50`}`}>
      {children}
    </div>
  </div>
);

const DownloadButton: React.FC<{
  platform: `mac` | `windows`;
  primary: boolean;
  onClick: () => void;
}> = ({ platform, primary, onClick }) => {
  const isMac = platform === `mac`;

  return (
    <Button type="button" color={primary ? `primary` : `tertiary`} onClick={onClick}>
      <i className={`${isMac ? `fa-brands fa-apple` : `fa-brands fa-windows`} mr-3`} />
      {isMac ? `Download for Mac` : `Download for Windows`}
    </Button>
  );
};

export const UsbConnectionIllustration: React.FC = () => (
  <svg
    viewBox="-10 0 310 145"
    className="w-full max-w-[300px] h-auto"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
  >
    <rect
      x="8"
      y="8"
      width="120"
      height="72"
      rx="4"
      className="fill-slate-100 stroke-slate-300"
      strokeWidth="2"
    />
    <rect x="14" y="14" width="108" height="60" rx="2" className="fill-slate-200" />
    <path
      d="M8 80 L-4 100 Q-6 104 0 104 L136 104 Q142 104 140 100 L128 80"
      className="fill-slate-100 stroke-slate-300"
      strokeWidth="2"
    />
    <rect x="20" y="86" width="96" height="10" rx="2" className="fill-slate-300" />

    <rect
      x="212"
      y="24"
      width="44"
      height="80"
      rx="6"
      className="fill-slate-100 stroke-slate-300"
      strokeWidth="2"
    />
    <rect x="218" y="34" width="32" height="60" rx="2" className="fill-slate-200" />
    <rect x="229" y="28" width="10" height="3" rx="1.5" className="fill-slate-300" />
    <rect x="227" y="98" width="14" height="3" rx="1.5" className="fill-slate-300" />

    <path
      d="M136 85 C152 85 162 100 172 118 C182 130 192 130 205 130 C225 130 234 125 234 108"
      className="stroke-violet-400"
      strokeWidth="3"
      strokeLinecap="round"
      fill="none"
    />
    <circle cx="205" cy="130" r="4" className="fill-violet-500" />
    <circle cx="205" cy="130" r="8" className="fill-violet-400/30" />
  </svg>
);

export const DoneScreen: React.FC<
  DeviceInfo & {
    deviceId: string;
  }
> = ({ childName, modelName, iosVersion, deviceId }) => {
  const deviceType = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;
  return (
    <div>
      <ScreenHeader
        icon="check"
        title="Setup Complete"
        subtitle={`${posessive(childName)} ${modelName} · iOS ${iosVersion}`}
        step={{ current: 4, total: 4 }}
      />

      <div className="space-y-4 mb-6">
        <HighlightableCard highlighted={false} className="">
          <div className="flex items-center gap-2 mb-3">
            <span className="w-6 h-6 rounded-full bg-violet-100 text-violet-600 text-xs font-bold flex items-center justify-center">
              1
            </span>
            <span className="font-medium text-slate-700">Setup complete</span>
          </div>
          <p className="text-slate-500 text-sm ml-8">
            {posessive(childName)} {modelName} is now set up with Gertrude. You can manage
            this {deviceType} from your dashboard.
          </p>
        </HighlightableCard>

        <HighlightableCard highlighted={false} className="">
          <div className="flex items-center gap-2 mb-3">
            <span className="w-6 h-6 rounded-full bg-violet-100 text-violet-600 text-xs font-bold flex items-center justify-center">
              2
            </span>
            <span className="font-medium text-slate-700">Keep your password safe</span>
          </div>
          <p className="text-slate-500 text-sm ml-8">
            The protection for this {deviceType} is managed from this website. It's
            important that {childName} does not know the password to log in here.
          </p>
        </HighlightableCard>
      </div>

      <div className="flex justify-end">
        <Button type="link" to={`/ios-devices/${deviceId}`} color="primary">
          Manage {deviceType} &rarr;
        </Button>
      </div>
    </div>
  );
};

export const PaymentGateScreen: React.FC<
  DeviceInfo & {
    deviceType: string;
    onSubscribe: () => void;
    isRedirecting?: boolean;
    checkoutCancelled?: boolean;
  }
> = ({
  childName,
  modelName,
  iosVersion,
  deviceType,
  onSubscribe,
  isRedirecting = false,
  checkoutCancelled = false,
}) => (
  <div>
    <ScreenHeader
      icon="credit-card"
      title="Subscribe to Continue"
      subtitle={`Setting up ${posessive(childName)} ${modelName} · iOS ${iosVersion}`}
    />

    <p className="text-slate-600 mb-5">
      To supervise and manage {posessive(childName)} {deviceType}, you’ll need a{` `}
      <b>Gertrude subscription.</b>
    </p>

    <HighlightableCard highlighted className="mb-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-bold text-slate-800">Light Plan</h3>
        <span className="text-lg font-bold text-violet-700">$10/year</span>
      </div>
      <ul className="space-y-2">
        {[
          `Supervise iPhones and iPads for 18+ users`,
          `All basic iOS blocking (GIFs, Apple Maps, Spotify etc.)`,
          `Unlimited devices for your family with one subscription`,
        ].map((feature) => (
          <li key={feature} className="flex items-center gap-2 text-sm text-slate-600">
            <i className="fa-solid fa-check text-violet-500 text-xs" />
            {feature}
          </li>
        ))}
      </ul>
      <p className="text-xs text-slate-400 mt-3">
        This is a one-time annual payment. No trial period.
      </p>
    </HighlightableCard>

    {checkoutCancelled && (
      <div className="bg-amber-50 border border-amber-200 rounded-lg px-4 py-3 mb-6 text-sm text-amber-700">
        Checkout was cancelled. You can try again when you're ready.
      </div>
    )}

    <div className="flex justify-end">
      <Button
        type="button"
        color="primary"
        onClick={onSubscribe}
        disabled={isRedirecting}
      >
        {isRedirecting ? `Redirecting...` : `Subscribe \u2014 $10/year`}
      </Button>
    </div>
  </div>
);

export const ProgressDots: React.FC<{
  current: number;
  total: number;
  className?: string;
}> = ({ current, total, className }) => (
  <div className={`flex items-center justify-center gap-2 ${className ?? ``}`}>
    {Array.from({ length: total }, (_, i) => (
      <div
        key={i}
        className={`rounded-full transition-all ${
          i + 1 === current
            ? `w-2.5 h-2.5 bg-violet-600`
            : i + 1 < current
              ? `w-2 h-2 bg-violet-400`
              : `w-2 h-2 bg-slate-200`
        }`}
      />
    ))}
  </div>
);
