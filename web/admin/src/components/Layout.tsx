import React from 'react';
import { Link, useLocation } from 'react-router-dom';

interface LayoutProps {
  children: React.ReactNode;
  onLogout: () => void;
}

interface IconProps {
  className?: string;
}

const GertrudeLogo: React.FC<IconProps> = ({ className = `` }) => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1250 1240" className={className}>
    <defs>
      <linearGradient id="navLogoGradient" x1="0" x2="0" y1="0" y2="1">
        <stop stopColor="#A78BFA" />
        <stop offset="1" stopColor="#E879F9" />
      </linearGradient>
    </defs>
    <path
      d="M 595.177 170.634 C 561.903 175.767, 530.633 189.195, 504.039 209.770 C 482.421 226.495, 216.195 494.797, 206.126 510.005 C 161.875 576.845, 163.739 667.193, 210.616 727.631 C 222.488 742.937, 460.408 982.095, 502.761 1021.295 C 568.157 1081.824, 679.283 1082.653, 747.825 1023.124 C 779.646 995.487, 1032.850 739.640, 1041.878 726 C 1086.096 659.201, 1084.243 573.409, 1037.194 509 C 1031.604 501.347, 764.863 233.177, 746.040 216.285 C 706.625 180.914, 646.493 162.719, 595.177 170.634 M 631.500 349.485 C 611.720 353.858, 609.836 354.943, 513.500 417.474 C 398.233 492.291, 387.820 499.457, 378.809 510.167 C 350.091 544.300, 344.115 595.501, 364.708 630.989 C 383.738 663.785, 499.067 839.766, 507.431 848.772 C 547.214 891.607, 601.147 894.239, 660.500 856.242 C 689.279 837.819, 805.262 762.488, 828.080 747.400 C 882.786 711.226, 900.744 667.270, 882.888 613.239 C 878.898 601.165, 829.728 523.097, 751.101 404 C 722 359.921, 677.025 339.421, 631.500 349.485"
      stroke="none"
      fillRule="evenodd"
      fill="url(#navLogoGradient)"
    />
  </svg>
);

const HomeIcon: React.FC<IconProps> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
    <polyline points="9 22 9 12 15 12 15 22" />
  </svg>
);

const UsersIcon: React.FC<IconProps> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
    <circle cx="9" cy="7" r="4" />
    <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
    <path d="M16 3.13a4 4 0 0 1 0 7.75" />
  </svg>
);

const LogoutIcon: React.FC<IconProps> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
    <polyline points="16 17 21 12 16 7" />
    <line x1="21" x2="9" y1="12" y2="12" />
  </svg>
);

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
                <GertrudeLogo className="w-8 h-8" />
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
