import React from 'react';
import type InstallIOSAppModal from '#/components/devices/InstallIOSAppModal';
import type { IOSSetupApp } from '#/components/onboarding/setupApps';
import { gertrudeApps } from '#/lib/gertrudeApps';
import { useShareLink } from '#/lib/shareLink';

export function useInstallIOSApp(
  personName: string | undefined,
  closeOnChange?: unknown,
): {
  installIOSApp: (app: IOSSetupApp) => void;
  modalProps: React.ComponentProps<typeof InstallIOSAppModal>;
} {
  const [app, setApp] = React.useState<IOSSetupApp>(`blocker`);
  const [open, setOpen] = React.useState(false);
  const shareLink = useShareLink();

  React.useEffect(() => {
    setOpen(false);
  }, [closeOnChange]);

  return {
    installIOSApp: (nextApp) => {
      shareLink.reset();
      setApp(nextApp);
      setOpen(true);
    },
    modalProps: {
      open,
      onOpenChange: setOpen,
      app,
      personName,
      shareMethod: shareLink.method,
      copied: shareLink.copied,
      onShareLink: () => {
        const { name, appStoreUrl } = gertrudeApps[app];
        shareLink.share({ title: name, url: appStoreUrl });
      },
    },
  };
}
