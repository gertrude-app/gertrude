import React from 'react';
import cx from 'classnames';

interface Props {
  size?: number;
  iconOnly?: boolean;
  className?: string;
  type?: 'default' | 'inverted';
  withForParents?: boolean | 'condensed';
  textSize?:
    | 'text-base'
    | 'text-lg'
    | 'text-xl'
    | 'text-2xl'
    | 'text-3xl'
    | 'text-4xl'
    | 'text-5xl'
    | string;
}

const Logo: React.FC<Props> = ({
  size = 53,
  className,
  iconOnly,
  type = `default`,
  textSize = `text-4xl`,
  withForParents = false,
}) => {
  let color = ``;

  switch (type) {
    case `inverted`:
      color = `white`;
      break;
    default:
      color = `url(#Gradient1)`;
  }

  return (
    <div className={cx(`flex items-center justify-start`, className)}>
      <div className="-m-2">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width={size}
          height={size}
          viewBox="0 0 1250 1240"
          version="1.1"
        >
          <defs>
            <linearGradient id="Gradient1" x1="0" x2="0" y1="0" y2="1">
              <stop stopColor="#8B5CF6" />
              <stop offset="1" stopColor="#D846EF" />
            </linearGradient>
          </defs>
          <path
            id="logo-path"
            d="M 595.177 170.634 C 561.903 175.767, 530.633 189.195, 504.039 209.770 C 482.421 226.495, 216.195 494.797, 206.126 510.005 C 161.875 576.845, 163.739 667.193, 210.616 727.631 C 222.488 742.937, 460.408 982.095, 502.761 1021.295 C 568.157 1081.824, 679.283 1082.653, 747.825 1023.124 C 779.646 995.487, 1032.850 739.640, 1041.878 726 C 1086.096 659.201, 1084.243 573.409, 1037.194 509 C 1031.604 501.347, 764.863 233.177, 746.040 216.285 C 706.625 180.914, 646.493 162.719, 595.177 170.634 M 631.500 349.485 C 611.720 353.858, 609.836 354.943, 513.500 417.474 C 398.233 492.291, 387.820 499.457, 378.809 510.167 C 350.091 544.300, 344.115 595.501, 364.708 630.989 C 383.738 663.785, 499.067 839.766, 507.431 848.772 C 547.214 891.607, 601.147 894.239, 660.500 856.242 C 689.279 837.819, 805.262 762.488, 828.080 747.400 C 882.786 711.226, 900.744 667.270, 882.888 613.239 C 878.898 601.165, 829.728 523.097, 751.101 404 C 722 359.921, 677.025 339.421, 631.500 349.485"
            stroke="none"
            fillRule="evenodd"
            fill={color}
          />
        </svg>
      </div>
      {!iconOnly && (
        <div className="flex flex-col ml-2.5">
          <span
            className={cx(
              `font-lato whitespace-nowrap`,
              type === `inverted` ? `text-white` : `text-slate-700`,
              textSize,
            )}
          >
            Gertrude
          </span>
          {withForParents && (
            <span
              className={cx(
                type === `inverted`
                  ? `from-indigo-400 to-fuchsia-400`
                  : `from-indigo-500 to-fuchsia-500`,
                `bg-gradient-to-r w-fit bg-clip-text [-webkit-background-clip:text] text-transparent tracking-wider text-sm font-medium uppercase`,
                withForParents === `condensed` && `-mt-0.5 border border-slate-900`,
              )}
            >
              For parents
            </span>
          )}
        </div>
      )}
    </div>
  );
};

export default Logo;
