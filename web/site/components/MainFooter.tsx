import { Logo } from '@shared/components';
import { GithubIcon, YoutubeIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';

const MainFooter: React.FC = () => (
  <footer className="px-8 sm:px-12 lg:px-20 pt-20 pb-8 gap-20 relative border-t border-violet-400 flex flex-col bg-violet-500">
    <div className="flex flex-col sm:flex-row justify-between">
      <div className="self-center sm:self-start">
        <Link href="/">
          <Logo type="inverted" />
        </Link>
      </div>
      <div className="flex gap-12 mt-12 sm:mt-0 self-center sm:self-start">
        <ul className="flex flex-col items-center sm:items-start gap-1">
          <FooterLink href="/">Home</FooterLink>
          <FooterLink href="/download">Download</FooterLink>
          <FooterLink href="/contact">Contact</FooterLink>
        </ul>
        <ul className="flex flex-col items-center sm:items-start gap-1">
          <FooterLink href="https://parents.gertrude.app/signup">Sign up</FooterLink>
          <FooterLink href="https://parents.gertrude.app">Log in</FooterLink>
          <FooterLink href="/docs">Documentation</FooterLink>
          <FooterLink href="/blog">Blog</FooterLink>
        </ul>
      </div>
    </div>
    <div className="flex justify-between items-end">
      <p className="text-white/70">© {new Date().getFullYear()} NetRivet Inc.</p>
      <div className="flex items-center gap-4 self-center">
        <Link
          href="https://www.youtube.com/@gertrudeapp"
          className="text-white/60 hover:text-white/80 transition-colors duration-200"
        >
          <YoutubeIcon size={30} />
        </Link>
        <Link
          href="https://github.com/gertrude-app"
          className="text-white/60 hover:text-white/80 transition-colors duration-200"
        >
          <GithubIcon size={30} />
        </Link>
      </div>
    </div>
  </footer>
);

export default MainFooter;

interface FooterLinkProps {
  href: string;
  children: React.ReactNode;
}

const FooterLink: React.FC<FooterLinkProps> = ({ children, href }) => (
  <li>
    <Link
      href={href}
      className="text-lg text-white/60 hover:text-white/80 block w-fit transition-colors duration-200"
    >
      {children}
    </Link>
  </li>
);
