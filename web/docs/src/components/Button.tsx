import Link from 'next/link';
import cx from 'classnames';

const styles = {
  primary: `rounded-full bg-violet-300 py-2 px-4 text-sm font-semibold text-slate-900 hover:bg-violet-200 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-violet-300/50 active:bg-violet-500`,
  secondary: `rounded-full bg-slate-800 py-2 px-4 text-sm font-medium text-white hover:bg-slate-700 focus:outline-none focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white/50 active:text-slate-400`,
};

interface Props {
  variant?: 'primary' | 'secondary';
  href?: string;
  className?: string;
  children: React.ReactNode;
}

const Button: React.FC<Props> = ({ variant = `primary`, href, className, ...props }) => {
  className = cx(styles[variant], className);

  return href ? (
    <Link href={href} className={className} {...props} />
  ) : (
    <button className={className} {...props} />
  );
};

export default Button;
