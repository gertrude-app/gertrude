import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { GertrudeLogo, HomeIcon, LogoutIcon, UsersIcon } from './Icons';

interface LayoutProps {
  children: React.ReactNode;
  onLogout: () => void;
}

const Layout: React.FC<LayoutProps> = ({ children, onLogout }) => {
  const location = useLocation();

  const navLinks = [
    { to: `/`, label: `Home`, icon: HomeIcon },
    { to: `/parents`, label: `Parents`, icon: UsersIcon },
  ];

  const isActive = (path: string): boolean => {
    if (path === `/`) return location.pathname === `/`;
    return location.pathname.startsWith(path);
  };

  return (
    <div className="min-h-screen bg-slate-50">
      <nav className="bg-slate-900 border-b border-slate-800">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center gap-10">
              <Link to="/" className="flex items-center gap-1.5">
                <GertrudeLogo className="w-8 h-8" variant="light" />
                <span className="font-display font-semibold text-xl text-white">
                  Gertrude
                </span>
                <span className="text-xs font-medium text-slate-500 uppercase tracking-wider ml-1">
                  Admin
                </span>
              </Link>
              <div className="flex items-center gap-1">
                {navLinks.map((link) => {
                  const Icon = link.icon;
                  const active = isActive(link.to);
                  return (
                    <Link
                      key={link.to}
                      to={link.to}
                      className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                        active
                          ? `bg-slate-800 text-white`
                          : `text-slate-400 hover:text-white hover:bg-slate-800/50`
                      }`}
                    >
                      <Icon className="w-4 h-4" />
                      {link.label}
                    </Link>
                  );
                })}
              </div>
            </div>
            <button
              onClick={onLogout}
              className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-400 hover:text-white hover:bg-slate-800/50 rounded-lg transition-all"
            >
              <LogoutIcon className="w-4 h-4" />
              Logout
            </button>
          </div>
        </div>
      </nav>
      <main className="max-w-7xl mx-auto px-6 py-8">{children}</main>
    </div>
  );
};

export default Layout;
