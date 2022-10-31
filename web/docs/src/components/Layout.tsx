import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/router';
import cx from 'classnames';
import MobileNavigation from '@/components/MobileNavigation';
import Navigation from '@/components/Navigation';
import Prose from '@/components/Prose';
import navigation from '@/navigation';
import { Section } from '../pages/_app';
import Logo from './shared/Logo';

function useTableOfContents(tableOfContents: Section[]): string {
  const [currentSection, setCurrentSection] = useState(tableOfContents[0]?.id ?? ``);
  const getHeadings = useCallback((tableOfContents: Section[]) => {
    return tableOfContents
      .flatMap((node) => [node.id, ...(node.children ?? []).map((child) => child.id)])
      .map((id) => {
        const el = document.getElementById(id ?? ``);
        if (!el) {
          return { id: ``, top: 0 };
        }
        const style = window.getComputedStyle(el);
        const scrollMt = parseFloat(style.scrollMarginTop);
        const top = window.scrollY + el.getBoundingClientRect().top - scrollMt;
        return { id, top };
      });
  }, []);

  useEffect(() => {
    if (tableOfContents.length === 0) return;
    const headings = getHeadings(tableOfContents);

    function onScroll(): void {
      const top = window.scrollY;
      let current = headings[0]?.id ?? ``;
      for (const heading of headings) {
        if (top >= heading.top) {
          current = heading.id ?? ``;
        } else {
          break;
        }
      }
      setCurrentSection(current);
    }

    window.addEventListener(`scroll`, onScroll, { passive: true });
    onScroll();
    return () => {
      window.removeEventListener(`scroll`, onScroll);
    };
  }, [getHeadings, tableOfContents]);

  return currentSection;
}

interface Props {
  children: React.ReactNode;
  tableOfContents: Array<Section>;
  title: string;
}

const Layout: React.FC<Props> = ({ children, title, tableOfContents }) => {
  const router = useRouter();
  const allLinks = navigation.flatMap((section) => section.links);
  const linkIndex = allLinks.findIndex((link) => link.href === router.pathname);
  const previousPage = allLinks[linkIndex - 1];
  const nextPage = allLinks[linkIndex + 1];
  const section = navigation.find((section) =>
    section.links.find((link) => link.href === router.pathname),
  );
  const currentSection = useTableOfContents(tableOfContents);

  function isActive(section: Section): boolean {
    if (section.id === currentSection) {
      return true;
    }
    if (!section.children) {
      return false;
    }
    return section.children.findIndex(isActive) > -1;
  }

  return (
    <>
      <Header navigation={navigation} />
      <div className="max-w-8xl relative mx-auto flex justify-center sm:px-2 lg:px-8 xl:px-12">
        <div className="hidden lg:relative lg:block lg:flex-none">
          <div className="absolute inset-y-0 right-0 w-[50vw] bg-slate-50 dark:hidden" />
          <div className="absolute top-16 bottom-0 right-0 hidden h-12 w-px bg-gradient-to-t from-slate-800 dark:block" />
          <div className="absolute top-28 bottom-0 right-0 hidden w-px bg-slate-800 dark:block" />
          <div className="sticky top-[4.5rem] -ml-0.5 h-[calc(100vh-4.5rem)] overflow-y-auto overflow-x-hidden py-12 pl-0.5">
            <Navigation navigation={navigation} className="w-64 pr-8 xl:w-72 xl:pr-16" />
          </div>
        </div>
        <div className="min-w-0 max-w-2xl flex-auto px-4 py-12 lg:max-w-none lg:pr-0 lg:pl-8 xl:px-16">
          <article>
            {(title || section) && (
              <header className="mb-9 space-y-1">
                {section && (
                  <p className="font-display text-sm font-medium text-violet-400">
                    {section.title}
                  </p>
                )}
                {title && (
                  <h1 className="font-display text-3xl tracking-tight text-slate-900 dark:text-white">
                    {title}
                  </h1>
                )}
              </header>
            )}
            <Prose>{children}</Prose>
          </article>
          <dl className="mt-12 flex border-t border-slate-200 pt-6 dark:border-slate-800">
            {previousPage && (
              <div>
                <dt className="font-display text-sm font-medium text-slate-900 dark:text-white">
                  Previous
                </dt>
                <dd className="mt-1">
                  <Link
                    href={previousPage.href}
                    className="text-base font-semibold text-slate-500 hover:text-slate-600 dark:text-slate-400 dark:hover:text-slate-300"
                  >
                    <span aria-hidden="true">&larr;</span> {previousPage.title}
                  </Link>
                </dd>
              </div>
            )}
            {nextPage && (
              <div className="ml-auto text-right">
                <dt className="font-display text-sm font-medium text-slate-900 dark:text-white">
                  Next
                </dt>
                <dd className="mt-1">
                  <Link
                    href={nextPage.href}
                    className="text-base font-semibold text-slate-500 hover:text-slate-600 dark:text-slate-400 dark:hover:text-slate-300"
                  >
                    {nextPage.title} <span aria-hidden="true">&rarr;</span>
                  </Link>
                </dd>
              </div>
            )}
          </dl>
        </div>
        <div className="hidden xl:sticky xl:top-[4.5rem] xl:-mr-6 xl:block xl:h-[calc(100vh-4.5rem)] xl:flex-none xl:overflow-y-auto xl:py-12 xl:pr-6">
          <nav aria-labelledby="on-this-page-title" className="w-56">
            {tableOfContents.length > 0 && (
              <>
                <h2
                  id="on-this-page-title"
                  className="font-display text-sm font-medium text-slate-900 dark:text-white"
                >
                  On this page
                </h2>
                <ol className="mt-4 space-y-3 text-sm leading-snug">
                  {tableOfContents.map((section) => (
                    <li key={section.id}>
                      <h3>
                        <Link
                          href={`#${section.id}`}
                          className={cx(
                            isActive(section)
                              ? `text-violet-400`
                              : `font-normal text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-300`,
                          )}
                        >
                          {section.title}
                        </Link>
                      </h3>
                      {section.children && section.children.length > 0 && (
                        <ol className="mt-2 space-y-3 pl-5 text-slate-500 dark:text-slate-400">
                          {section.children &&
                            section.children.map((subSection) => (
                              <li key={subSection.id}>
                                <Link
                                  href={`#${subSection.id}`}
                                  className={
                                    isActive(subSection)
                                      ? `text-violet-400`
                                      : `hover:text-slate-600 dark:hover:text-slate-300`
                                  }
                                >
                                  {subSection.title}
                                </Link>
                              </li>
                            ))}
                        </ol>
                      )}
                    </li>
                  ))}
                </ol>
              </>
            )}
          </nav>
        </div>
      </div>
    </>
  );
};

export default Layout;

const Header: React.FC<{ navigation: typeof navigation }> = ({ navigation }) => {
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    function onScroll(): void {
      setIsScrolled(window.scrollY > 0);
    }
    onScroll();
    window.addEventListener(`scroll`, onScroll, { passive: true });
    return () => {
      window.removeEventListener(`scroll`, onScroll);
    };
  }, []);

  return (
    <header
      className={cx(
        `sticky top-0 z-50 flex flex-wrap items-center justify-between bg-white px-4 py-5 shadow-md shadow-slate-900/5 transition duration-500 dark:shadow-none sm:px-6 lg:px-8`,
        isScrolled
          ? `dark:bg-slate-900/95 dark:backdrop-blur dark:[@supports(backdrop-filter:blur(0))]:bg-slate-900/75`
          : `dark:bg-transparent`,
      )}
    >
      <div className="mr-6 flex lg:hidden">
        <MobileNavigation navigation={navigation} />
      </div>
      <div className="relative flex basis-0 items-center lg:flex-grow">
        <Link href="/" aria-label="Home page">
          <div className="flex">
            <Logo
              textSize="text-3xl"
              className="hidden opacity-80 lg:flex"
              type="on-dark"
            />
            <Logo
              type="on-dark"
              size={32}
              textSize="text-2xl"
              className="opacity-80 lg:hidden"
            />
            <span
              className={cx(
                `font-lato ml-1 bg-gradient-to-br from-indigo-500 to-fuchsia-400 bg-clip-text text-2xl font-extrabold text-transparent lg:text-3xl`,
                `mr-[48px] lg:mr-0`,
              )}
            >
              Docs
            </span>
          </div>
        </Link>
      </div>
      <div />
    </header>
  );
};
