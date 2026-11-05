import { AppIcon, Button, Modal, Text, VStack } from '@gertrude/ui';
import { CheckIcon, CopyIcon, DownloadIcon, LinkIcon, ShareIcon } from 'lucide-react';
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
};

const connectInstructions: Record<IOSSetupApp, (device: string) => string> = {
  blocker: (device) =>
    `Open Gertrude Blocker on ${device} and follow the setup. When it offers to connect to an account, tap “Connect to account.” It’ll give you a link to open on this computer or your phone.`,
  music: (device) =>
    `Open Gertrude Music on ${device} and follow the setup. It’ll give you a link to open on this computer or your phone.`,
  podcasts: (device) =>
    `Open Gertrude Podcasts on ${device} and follow the setup. It’ll give you a link to open on this computer or your phone.`,
};

const appNotes: Partial<Record<IOSSetupApp, string>> = {
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
}) => {
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
            <VStack align="center" gap={3} className="mt-4">
              <div className="rounded-2xl border border-stone-200 bg-white p-3 shadow-sm">
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
              <Button
                type="button"
                variant="default"
                size="small"
                icon={shareMethod === `share` ? ShareIcon : copied ? CheckIcon : CopyIcon}
                onClick={onShareLink}
              >
                {shareMethod === `share` ? `Share link` : copied ? `Copied` : `Copy link`}
              </Button>
            </VStack>
          }
        >
          Scan this code with the camera on {device}, or send the link there.
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
