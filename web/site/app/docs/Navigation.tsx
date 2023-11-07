import Link from 'next/link';
import { useRouter } from 'next/router';
import cx from 'classnames';
import type navigation from './navigation-list';

interface Props {
  navigation: typeof navigation;
  className?: string;
}

const Navigation: React.FC<Props> = ({ navigation, className }) => {
  const router = useRouter();
  return (
    <nav className={cx(`text-base lg:text-sm`, className)}>
      <ul className="space-y-9">
        {navigation.map((section) => (
          <li key={section.title}>
            <h2 className="font-lexend font-medium text-white">{section.title}</h2>
            <ul className="mt-2 space-y-2 border-l-2 border-slate-800 lg:mt-4 lg:space-y-4">
              {section.links.map((link) => (
                <li key={link.href} className="relative">
                  <Link
                    href={link.href}
                    locale={link.href.includes(`bloquear`) ? `es` : `en`}
                    className={cx(
                      `block w-full pl-3.5 before:pointer-events-none before:absolute before:-left-1 before:top-1/2 before:h-1.5 before:w-1.5 before:-translate-y-1/2 before:rounded-full`,
                      link.href === router.pathname
                        ? `font-semibold text-violet-400 before:bg-violet-500`
                        : `text-slate-400 before:hidden hover:before:block before:bg-slate-700 hover:text-slate-300`,
                    )}
                  >
                    {link.title}
                  </Link>
                </li>
              ))}
            </ul>
          </li>
        ))}
      </ul>
    </nav>
  );
};

export default Navigation;
