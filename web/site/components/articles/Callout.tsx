import cx from 'classnames';
import { LightbulbIcon, TriangleAlertIcon } from 'lucide-react';
import React from 'react';
import Prose from './Prose';

const styles = {
  note: {
    icon: `text-violet-600`,
  },
  warning: {
    icon: `text-amber-600`,
  },
};

const icons = {
  note: LightbulbIcon,
  warning: TriangleAlertIcon,
};

interface Props {
  type: `note` | `warning`;
  alt?: boolean;
  title?: string;
  children: React.ReactNode;
}

const Callout: React.FC<Props> = ({ type, title, children, alt }) => {
  const IconComponent = icons[type];
  const style = styles[type];

  return (
    <aside
      className={cx(
        `Callout my-10 rounded-[24px] border border-white bg-white/50 p-5 shadow-md shadow-violet-950/5 xs:p-6`,
        alt && `bg-white/70`,
      )}
    >
      <div className="flex items-start gap-4">
        <span
          className={cx(
            `mt-1 flex size-6 shrink-0 items-center justify-center`,
            style.icon,
          )}
        >
          <IconComponent className="size-5" strokeWidth={1.9} />
        </span>
        <div className="min-w-0 flex-1 pt-1">
          {title && (
            <div
              className="text-lg font-semibold leading-6 text-stone-950"
              dangerouslySetInnerHTML={{ __html: title }}
            />
          )}
          <Prose
            size="base"
            className={cx(
              `prose-p:my-3 prose-p:leading-7 prose-li:my-1.5 prose-li:leading-7 prose-ul:my-3 prose-ol:my-3 prose-ol:list-decimal prose-ol:pl-6 prose-strong:font-semibold first:prose-p:mt-0 last:prose-p:mb-0`,
              title && `mt-2`,
            )}
          >
            {children}
          </Prose>
        </div>
      </div>
    </aside>
  );
};

export default Callout;
