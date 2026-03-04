import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import {
  GertrudeLogo,
  HomeIcon,
  LogoutIcon,
  MenuIcon,
  SearchIcon,
  UsersIcon,
  XIcon,
} from './Icons';

interface LayoutProps {
  children: React.ReactNode;
  onLogout: () => void;
}

const Layout: React.FC<LayoutProps> = ({ children, onLogout }) => {
  const location = useLocation();
  const navigate = useNavigate();
  const [emailSearch, setEmailSearch] = useState(``);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleEmailSearch = (e: React.FormEvent): void => {
    e.preventDefault();
    const trimmed = emailSearch.trim();
    if (trimmed) {
      navigate(`/parents?email=${encodeURIComponent(trimmed)}`);
      setEmailSearch(``);
      setMobileMenuOpen(false);
    }
  };

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
        <div className="max-w-7xl mx-auto px-4 sm:px-6">
          <div className="flex justify-between items-center h-14 sm:h-16">
            <div className="flex items-center gap-4 sm:gap-10">
              <Link to="/" className="flex items-center gap-1.5">
                <GertrudeLogo className="w-7 h-7 sm:w-8 sm:h-8" variant="light" />
                <span className="font-display font-semibold text-lg sm:text-xl text-white">
                  Gertrude
                </span>
                <span className="text-xs font-medium text-slate-500 uppercase tracking-wider ml-1 hidden sm:inline">
                  Admin
                </span>
              </Link>
              <div className="hidden sm:flex items-center gap-1">
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
            <div className="hidden sm:flex items-center gap-4">
              <form onSubmit={handleEmailSearch} className="relative">
                <input
                  type="text"
                  value={emailSearch}
                  onChange={(e) => setEmailSearch(e.target.value)}
                  placeholder="Search parent by email..."
                  className="w-64 px-3 py-1.5 text-sm bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-brand-violet focus:ring-1 focus:ring-brand-violet"
                />
              </form>
              <button
                onClick={onLogout}
                className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-400 hover:text-white hover:bg-slate-800/50 rounded-lg transition-all"
              >
                <LogoutIcon className="w-4 h-4" />
                Logout
              </button>
            </div>
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="sm:hidden p-2 text-slate-400 hover:text-white rounded-lg transition-colors"
            >
              {mobileMenuOpen ? (
                <XIcon className="w-5 h-5" />
              ) : (
                <MenuIcon className="w-5 h-5" />
              )}
            </button>
          </div>
        </div>

        {mobileMenuOpen && (
          <div className="sm:hidden border-t border-slate-800 px-4 py-3 space-y-3">
            <div className="flex gap-2">
              {navLinks.map((link) => {
                const Icon = link.icon;
                const active = isActive(link.to);
                return (
                  <Link
                    key={link.to}
                    to={link.to}
                    onClick={() => setMobileMenuOpen(false)}
                    className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-all ${
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
              <button
                onClick={() => {
                  onLogout();
                  setMobileMenuOpen(false);
                }}
                className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-400 hover:text-white hover:bg-slate-800/50 rounded-lg transition-all ml-auto"
              >
                <LogoutIcon className="w-4 h-4" />
                Logout
              </button>
            </div>
            <form onSubmit={handleEmailSearch} className="relative">
              <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-500" />
              <input
                type="text"
                value={emailSearch}
                onChange={(e) => setEmailSearch(e.target.value)}
                placeholder="Search parent by email..."
                className="w-full pl-9 pr-3 py-2 text-sm bg-slate-800 border border-slate-700 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-brand-violet focus:ring-1 focus:ring-brand-violet"
              />
            </form>
          </div>
        )}
      </nav>
      <main className="max-w-7xl mx-auto px-4 sm:px-6 py-6 sm:py-8">{children}</main>
    </div>
  );
};

export default Layout;
