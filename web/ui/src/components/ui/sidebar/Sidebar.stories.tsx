import {
  BookOpenTextIcon,
  HomeIcon,
  KeyIcon,
  LifeBuoyIcon,
  LogOutIcon,
  MonitorSmartphoneIcon,
  SettingsIcon,
  UsersIcon,
} from 'lucide-react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type React from 'react';
import Badge from '../Badge';
import PageHeading from '../PageHeading';
import Sidebar from './Sidebar';
import SidebarItem from './SidebarItem';
import SidebarLayout from './SidebarLayout';
import SidebarSection from './SidebarSection';
import { galleryParameters } from '#/storybook/StoryLayout';

const logoUrl = `/logo-wordmark.svg`;

const NavigationSidebar: React.FC<
  Pick<React.ComponentProps<typeof Sidebar>, `logoWidth`>
> = ({ logoWidth }) => (
  <Sidebar
    logoUrl={logoUrl}
    logoWidth={logoWidth}
    bottomButton={{ text: `Sign out`, href: `https://gertrude.app`, icon: LogOutIcon }}
  >
    <SidebarSection title="Platform">
      <SidebarItem title="Dashboard" icon={HomeIcon} href="/dashboard" selected />
      <SidebarItem title="Children" icon={UsersIcon} href="/people" badgeCount={3} />
      <SidebarItem
        title="Devices"
        icon={MonitorSmartphoneIcon}
        href="/devices"
        badgeCount={7}
      />
      <SidebarItem title="Keychains" icon={KeyIcon} href="/keychains" />
    </SidebarSection>
    <SidebarSection title="Help">
      <SidebarItem
        title="Docs"
        icon={BookOpenTextIcon}
        href="https://gertrude.app/docs"
      />
      <SidebarItem
        title="Support"
        icon={LifeBuoyIcon}
        href="https://gertrude.app/support"
      />
    </SidebarSection>
  </Sidebar>
);

const DashboardContent: React.FC = () => (
  <div className="min-h-screen bg-white p-8 @container/main">
    <PageHeading
      title="Dashboard"
      subtitle="A layout preview using the shared sidebar primitives."
      buttons={[{ text: `Settings`, href: `/settings`, icon: SettingsIcon }]}
    />
    <div className="mt-8 grid gap-4 sm:grid-cols-3">
      {[`Children`, `Devices`, `Requests`].map((label, index) => (
        <div key={label} className="rounded-2xl border border-stone-200 bg-stone-50 p-5">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-stone-700">{label}</span>
            <Badge color={index === 2 ? `yellow` : `green`}>{index + 2}</Badge>
          </div>
          <div className="mt-6 h-2 rounded-full bg-stone-200" />
          <div className="mt-3 h-2 w-2/3 rounded-full bg-stone-200" />
        </div>
      ))}
    </div>
  </div>
);

const meta = {
  title: 'UI/Sidebar',
  component: Sidebar,
  args: {
    logoUrl,
    logoWidth: 132,
    children: (
      <SidebarSection title="Platform">
        <SidebarItem title="Dashboard" icon={HomeIcon} href="/dashboard" selected />
      </SidebarSection>
    ),
  },
  argTypes: {
    logoWidth: { control: { type: `number`, min: 80, max: 180, step: 4 } },
    bottomButton: { control: false },
    children: { control: false },
    logoUrl: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Sidebar>;

export default meta;

type Story = StoryObj<typeof meta>;

export const FullLayout: Story = {
  parameters: galleryParameters,
  render: () => (
    <SidebarLayout content={<DashboardContent />}>
      <NavigationSidebar logoWidth={132} />
    </SidebarLayout>
  ),
};
