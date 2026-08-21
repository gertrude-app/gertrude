import { notFound } from 'next/navigation';
import type { Metadata, NextPage } from 'next';
import CollectionIndexPage from '@/components/articles/CollectionIndexPage';
import { createMetadata } from '@/lib/seo';
import { getHelpArticlePath } from '@/markdoc/files';
import { getHelpArticles } from '@/markdoc/help';

type HelpDevice = `mac` | `iphone-ipad`;

type PageProps = {
  params: Promise<{ device: string }>;
};

const DEVICE_DETAILS: Record<
  HelpDevice,
  { title: string; description: string; metadataDescription: string }
> = {
  mac: {
    title: `Mac help`,
    description: `Focused answers and step-by-step instructions for Gertrude for Mac.`,
    metadataDescription: `Help with Gertrude’s Mac internet filter, monitoring, settings, and troubleshooting.`,
  },
  'iphone-ipad': {
    title: `iPhone & iPad help`,
    description: `Focused answers and step-by-step instructions for Gertrude Blocker.`,
    metadataDescription: `Help with Gertrude Blocker on iPhone and iPad.`,
  },
};

export function generateStaticParams(): { device: HelpDevice }[] {
  return [{ device: `mac` }, { device: `iphone-ipad` }];
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { device } = await params;
  if (!isHelpDevice(device)) notFound();
  const details = DEVICE_DETAILS[device];
  return createMetadata(`${details.title} | Gertrude`, details.metadataDescription);
}

const DeviceHelpPage: NextPage<PageProps> = async ({ params }) => {
  const { device } = await params;
  if (!isHelpDevice(device)) notFound();
  const details = DEVICE_DETAILS[device];
  const articles = await getHelpArticles(device);

  return (
    <CollectionIndexPage
      title={details.title}
      description={details.description}
      items={articles.map((article) => ({
        href: getHelpArticlePath(article),
        title: article.title,
        description: article.description,
      }))}
    />
  );
};

export default DeviceHelpPage;

function isHelpDevice(device: string): device is HelpDevice {
  return device === `mac` || device === `iphone-ipad`;
}
