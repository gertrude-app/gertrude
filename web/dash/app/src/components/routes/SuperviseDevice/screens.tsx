import { CodeChip, HighlightableCard, ScreenHeader } from '@dash/components';
import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React, { useState } from 'react';

type DeviceInfo = {
  childName: string;
  modelName: string;
  iosVersion: string;
};

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
  const detectedPlatform = /Mac|Macintosh/i.test(navigator.userAgent) ? `mac` : `windows`;

  const handleDownload = (platform: `mac` | `windows`): void => {
    setHasDownloaded(true);
    onDownload(platform);
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
            <CodeChip code={codeString} size="md" pill={false} />
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
    childId: string;
  }
> = ({ childName, modelName, iosVersion, deviceId, childId }) => {
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
        <Button
          type="link"
          to={`/children/${childId}/ios-devices/${deviceId}`}
          color="primary"
        >
          Manage {deviceType} &rarr;
        </Button>
      </div>
    </div>
  );
};
