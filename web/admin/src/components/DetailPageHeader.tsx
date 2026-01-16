import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowLeftIcon, type IconProps } from './Icons';

interface DetailPageHeaderProps {
  backTo: string;
  icon: React.FC<IconProps>;
  iconGradient: string;
  iconShadow: string;
  title: string;
  subtitle: React.ReactNode;
  badge?: React.ReactNode;
}

const DetailPageHeader: React.FC<DetailPageHeaderProps> = ({
  backTo,
  icon: Icon,
  iconGradient,
  iconShadow,
  title,
  subtitle,
  badge,
}) => (
  <div className="flex flex-col sm:flex-row sm:items-center gap-4">
    <Link
      to={backTo}
      className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 hover:text-slate-900 bg-slate-100 hover:bg-slate-200 rounded-lg transition-all group self-start"
    >
      <ArrowLeftIcon className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
      <span>Back</span>
    </Link>
    <div className="flex items-center gap-3">
      <div
        className={`w-10 h-10 rounded-xl bg-gradient-to-br ${iconGradient} flex items-center justify-center shadow-lg ${iconShadow}`}
      >
        <Icon className="w-5 h-5 text-white" />
      </div>
      <div>
        <h1 className="font-display font-semibold text-slate-900 text-2xl">{title}</h1>
        <p className="text-sm text-slate-500">{subtitle}</p>
      </div>
    </div>
    {badge && <div className="sm:ml-auto">{badge}</div>}
  </div>
);

export default DetailPageHeader;
