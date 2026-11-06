import { AppIcon, Button, HStack, Modal, Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import {
  CheckIcon,
  CopyIcon,
  DownloadIcon,
  LinkIcon,
  QrCodeIcon,
  ShareIcon,
} from 'lucide-react';
import React from 'react';
import type { IOSSetupApp } from '#/components/onboarding/setupApps';
import InstructionStep from './InstructionStep';
import QrCode from '#/components/QrCode';
import { gertrudeApps } from '#/lib/gertrudeApps';

export type ShareLinkMethod = `share` | `copy`;

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  app: IOSSetupApp;
  personName?: string;
  shareMethod: ShareLinkMethod;
  copied?: boolean;
  onShareLink: () => void;
  defaultShowQrCode?: boolean;
};

const connectInstructions: Record<IOSSetupApp, (device: string) => string> = {
  blocker: (device) =>
    `Open Gertrude Blocker on ${device} and follow the setup, and tap “Connect to account” when it asks. It’ll show a link to open on this device.`,
  music: (device) =>
    `Open Gertrude Music on ${device} and follow the setup. It’ll show a link to open on this device.`,
  podcasts: (device) =>
    `Open Gertrude Podcasts on ${device} and follow the setup. When it asks, tap “Connect now,” and it’ll show a link to open on this device. If you skip it, you can connect later from the app’s settings.`,
};

const appNotes: Partial<Record<IOSSetupApp, string>> = {
  blocker: `For someone 18 or older, the app sets up supervision instead, which needs a Mac or Windows computer.`,
  music: `Their device will also need an Apple Music subscription.`,
};

const InstallIOSAppModal: React.FC<Props> = ({
  open,
  onOpenChange,
  app,
  personName,
  shareMethod,
  copied = false,
  onShareLink,
  defaultShowQrCode = false,
}) => {
  const [showQrCode, setShowQrCode] = React.useState(defaultShowQrCode);
  React.useEffect(() => {
    setShowQrCode(defaultShowQrCode);
  }, [open, app, defaultShowQrCode]);
  const details = gertrudeApps[app];
  const device = personName ? `${personName}’s iPhone or iPad` : `their iPhone or iPad`;
  const note = appNotes[app];

  return (
    <Modal
      open={open}
      onOpenChange={onOpenChange}
      title={`Set up ${details.name}`}
      footer={
        <Button type="button" variant="primary" onClick={() => onOpenChange(false)}>
          Done
        </Button>
      }
      size="medium"
    >
      <VStack gap={3}>
        <InstructionStep
          icon={DownloadIcon}
          title="Install the app"
          media={
            <VStack className="mt-3">
              <HStack gap={2} wrap>
                <Button
                  type="button"
                  variant="default"
                  size="small"
                  icon={QrCodeIcon}
                  onClick={() => setShowQrCode(!showQrCode)}
                >
                  {showQrCode ? `Hide QR code` : `Show QR code`}
                </Button>
                <Button
                  type="button"
                  variant="default"
                  size="small"
                  icon={
                    shareMethod === `share` ? ShareIcon : copied ? CheckIcon : CopyIcon
                  }
                  onClick={onShareLink}
                >
                  {shareMethod === `share`
                    ? `Share link`
                    : copied
                      ? `Copied`
                      : `Copy link`}
                </Button>
              </HStack>
              <div
                inert={!showQrCode}
                className={cx(
                  `-mx-1 grid transition-[grid-template-rows] duration-300 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none`,
                  showQrCode ? `grid-rows-[1fr]` : `grid-rows-[0fr]`,
                )}
              >
                <div className="min-h-0 overflow-hidden">
                  <div className="mx-1 mt-3 mb-1 w-fit rounded-2xl border border-stone-200 bg-white p-3 shadow-sm">
                    <QrCode
                      value={details.appStoreUrl}
                      label={`QR code for ${details.name} on the App Store`}
                      center={
                        <AppIcon
                          src={details.icon}
                          size="medium"
                          outlined={details.iconOutlined}
                        />
                      }
                      className="size-52"
                    />
                  </div>
                </div>
              </div>
            </VStack>
          }
        >
          Send the App Store link to {device}, or show a QR code to scan with its camera.
        </InstructionStep>
        <InstructionStep icon={LinkIcon} title="Connect it to your account">
          {connectInstructions[app](device)}
        </InstructionStep>
        {note && (
          <Text as="p" variant="captionMuted" className="px-1">
            {note}
          </Text>
        )}
      </VStack>
    </Modal>
  );
};

export default InstallIOSAppModal;
