import cx from 'classnames';
import Icon from './Icon';

const styles = {
  note: {
    title: `text-violet-400`,
    body: `[--tw-prose-background:theme(colors.violet.50)] prose-a:text-violet-500 text-slate-300 prose-code:text-slate-300 prose-strong:text-white prose-em:text-slate-100`,
  },
  warning: {
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
  alt?: boolean;
  title?: string;
  children: React.ReactNode;
}

const Callout: React.FC<Props> = ({ type, title, children, alt }) => {
  const IconComponent = icons[type];
  return (
    <div
      className={cx(
        `Callout my-8 xs:flex rounded-3xl p-6 ring-1 ring-slate-300/10 pt-0 xs:pt-6 max-w-3xl`,
        alt ? `bg-slate-900/40` : `bg-slate-800/60`,
      )}
    >
      <IconComponent className="hidden xs:flex h-8 w-8 flex-none" />
      <span className="ml-4 flex-auto">
        {title ? (
          <span className="flex items-start gap-3 -mt-1.5 xs:mt-0">
            <IconComponent className="xs:hidden h-7 w-7 flex-none" />
            <span
              className={cx(
                `font-lexend m-0 block text-xl mb-5 xs:mb-2.5 leading-tight`,
                styles[type].title,
              )}
              dangerouslySetInnerHTML={{ __html: title }}
            />
          </span>
        ) : (
          <IconComponent className="hidden h-8 w-8 -mt-3 mb-2" />
        )}
        <span className={cx(`prose block -mt-2 xs:mt-0`, styles[type].body)}>
          {!title && (
            <IconComponent className="xs:hidden h-8 w-8 float-left mr-4 mb-1 translate-y-1.5" />
          )}
          {children}
        </span>
      </span>
    </div>
  );
};

export default Callout;
