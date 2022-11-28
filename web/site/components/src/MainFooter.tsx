import { Logo } from '@shared/components';
import React from 'react';

const MainFooter: React.FC = () => (
  <footer className="bg-gray-900">
    <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-start p-8 xs:p-12">
      <div>
        <Logo type="on-dark" />
      </div>
      <div className="flex space-x-12 mt-10 sm:mt-0">
        <ul className="flex flex-col space-y-3 flex-grow">
          <li>
            <FooterLink href="https://gertrude.app/download">Download</FooterLink>
          </li>
          <li>
            <FooterLink href="https://gertrude.app/docs">Documentation</FooterLink>
          </li>
          <li>
            <FooterLink href="https://gertrude.app/contact">Contact us</FooterLink>
          </li>
        </ul>
        <ul className="flex flex-col space-y-3 flex-grow">
          <li>
            <FooterLink href="https://dash.gertrude.app/signup">Signup</FooterLink>
          </li>
          <li>
            <FooterLink href="https://dash.gertrude.app">Login</FooterLink>
          </li>
        </ul>
      </div>
    </div>
    <div className="flex justify-center items-center p-6 pt-0">
      <p className="text-slate-700 text-lg">© {new Date().getFullYear()} NetRivet Inc.</p>
    </div>
  </footer>
);

export default MainFooter;

interface FooterLinkProps {
  children: React.ReactNode;
  href: string;
}

const FooterLink: React.FC<FooterLinkProps> = ({ children, href }) => {
  return (
    <a
      href={href}
      className="text-slate-600 hover:text-slate-500 transition duration-100 p-1 text-lg"
    >
      {children}
    </a>
  );
};
