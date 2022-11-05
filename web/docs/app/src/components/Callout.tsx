import cx from 'classnames';
import Icon from '@/components/Icon';

const styles = {
  note: {
    container: `bg-violet-50 dark:bg-slate-800/60 dark:ring-1 dark:ring-slate-300/10`,
    title: `text-violet-900 dark:text-violet-400`,
    body: `text-violet-800 [--tw-prose-background:theme(colors.violet.50)] prose-a:text-violet-900 prose-code:text-violet-900 dark:text-slate-300 dark:prose-code:text-slate-300 prose-strong:text-white prose-em:text-slate-100`,
  },
  warning: {
    container: `bg-amber-50 dark:bg-slate-800/60 dark:ring-1 dark:ring-slate-300/10`,
    title: `text-amber-900 dark:text-amber-500`,
    body: `text-amber-800 [--tw-prose-underline:theme(colors.amber.400)] [--tw-prose-background:theme(colors.amber.50)] prose-a:text-amber-900 prose-strong:text-white prose-em:font-medium prose-em:text-slate-200 prose-code:text-amber-900 dark:text-slate-300 dark:[--tw-prose-underline:theme(colors.violet.700)] dark:prose-code:text-slate-300`,
  },
};

const icons = {
  note: (props: { className?: string }) => (
    <Icon color="blue" icon="lightbulb" {...props} />
  ),
  warning: (props: { className?: string }) => (
    <Icon icon="warning" color="amber" {...props} />
  ),
};

interface Props {
  type: 'note' | 'warning';
  title: string;
  children: React.ReactNode;
}

const Callout: React.FC<Props> = ({ type, title, children }) => {
  const IconComponent = icons[type];
  return (
    <span className={cx(`my-8 flex rounded-3xl p-6`, styles[type].container)}>
      <IconComponent className="h-8 w-8 flex-none" />
      <span className="ml-4 flex-auto">
        <span className={cx(`font-display m-0 block text-xl`, styles[type].title)}>
          {title}
        </span>
        <span className={cx(`prose mt-2.5 block`, styles[type].body)}>{children}</span>
      </span>
    </span>
  );
};

export default Callout;
