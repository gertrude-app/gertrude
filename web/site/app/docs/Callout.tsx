import cx from 'classnames';
import Icon from './Icon';

const styles = {
  note: {
    container: `bg-slate-800/60 ring-1 ring-slate-300/10`,
    title: `text-violet-400`,
    body: `[--tw-prose-background:theme(colors.violet.50)] prose-a:text-violet-900 text-slate-300 prose-code:text-slate-300 prose-strong:text-white prose-em:text-slate-100`,
  },
  warning: {
    container: `bg-slate-800/60 ring-1 ring-slate-300/10`,
    title: `text-amber-500`,
    body: `[--tw-prose-background:theme(colors.amber.50)] prose-a:text-amber-900 prose-strong:text-white prose-em:font-medium prose-em:text-slate-200 text-slate-300 [--tw-prose-underline:theme(colors.violet.700)] prose-code:text-slate-300`,
  },
};

const icons = {
  note: (props: { className?: string }) => (
    <Icon color="blue" icon="lightbulb" {...props} />
  ),
  warning: (props: { className?: string }) => (
    <Icon color="amber" icon="warning" {...props} />
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
        <span className={cx(`font-lexend m-0 block text-xl`, styles[type].title)}>
          {title}
        </span>
        <span className={cx(`prose mt-2.5 block`, styles[type].body)}>{children}</span>
      </span>
    </span>
  );
};

export default Callout;
