import React, { useContext } from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import OnboardingContext from './OnboardingContext';

interface ButtonProps {
  children: React.ReactNode;
  icon?: string;
  className?: string;
}

export const PrimaryButton: React.FC<ButtonProps> = ({ children, icon, className }) => {
  const { emit } = useContext(OnboardingContext);
  return (
    <Button
      type="button"
      color="primary"
      size="large"
      onClick={() => emit({ case: `primaryBtnClicked` })}
      className={className}
    >
      {children}
      {icon && <i className={cx(icon, `ml-3`)} />}
    </Button>
  );
};

export const SecondaryButton: React.FC<
  ButtonProps & { shadow?: boolean; onClick?: () => unknown }
> = ({ children, icon, shadow, className, onClick }) => {
  const { emit } = useContext(OnboardingContext);
  return (
    <Button
      type="button"
      color="secondary"
      size="large"
      onClick={() => (onClick ? onClick() : emit({ case: `secondaryBtnClicked` }))}
      className={cx(shadow && `shadow shadow-violet-200/80 antialiased`, className)}
    >
      {children}
      {icon && <i className={cx(icon, `ml-3`)} />}
    </Button>
  );
};

interface ButtonGroupProps {
  primary: string | { text: string; icon: string | false };
  secondary: {
    text: string;
    icon?: string;
    shadow?: boolean;
    onClick?: () => void;
  };
  direction?: 'row' | 'column';
  className?: string;
}

export const ButtonGroup: React.FC<ButtonGroupProps> = ({
  primary,
  secondary,
  direction = `column`,
  className,
}) => (
  <div
    className={cx(
      `flex`,
      direction === `row`
        ? `flex-row-reverse space-x-reverse space-x-4`
        : `flex-col space-y-4`,
      className,
    )}
  >
    <PrimaryButton
      icon={
        typeof primary === `string`
          ? `fa-solid fa-arrow-right`
          : primary.icon || undefined
      }
    >
      {typeof primary === `string` ? primary : primary.text}
    </PrimaryButton>
    <SecondaryButton
      icon={secondary.icon}
      onClick={secondary.onClick}
      shadow={secondary.shadow}
    >
      {secondary.text}
    </SecondaryButton>
  </div>
);

export const TextButton: React.FC<{
  children: React.ReactNode;
  onClick?: () => unknown;
}> = ({ children, onClick }) => {
  const { emit } = useContext(OnboardingContext);
  return (
    <button
      className="text-blue-700 hover:underline cursor-pointer"
      onClick={() => (onClick ? onClick() : emit({ case: `secondaryBtnClicked` }))}
    >
      {children}
    </button>
  );
};

export const EscapeHatchButton: React.FC<{
  children: React.ReactNode;
  onClick?: () => unknown;
}> = ({ children, onClick }) => {
  const { emit } = useContext(OnboardingContext);
  return (
    <button
      className="text-sm text-slate-600 hover:text-red-700 antialiased opacity-75 absolute bottom-6 right-6"
      onClick={() => (onClick ? onClick() : emit({ case: `secondaryBtnClicked` }))}
    >
      {children}
    </button>
  );
};

interface HeadingProps {
  children: React.ReactNode;
  centered?: boolean;
  className?: string;
}

export const Heading: React.FC<HeadingProps> = ({ children, centered, className }) => (
  <h1 className={cx(`text-3xl font-bold`, centered && `text-center`, className)}>
    {children}
  </h1>
);

interface TextProps {
  children: React.ReactNode;
  centered?: boolean;
  className?: string;
}

export const Text: React.FC<TextProps> = ({ children, centered, className }) => (
  <p
    className={cx(
      `text-lg text-slate-600 antialiased`,
      centered && `text-center`,
      className,
    )}
  >
    {children}
  </p>
);

interface CenteredProps {
  children: React.ReactNode;
  direction?: 'row' | 'column';
  className?: string;
}

export const Centered: React.FC<CenteredProps> = ({
  children,
  direction = `column`,
  className,
}) => (
  <div
    className={cx(
      `h-full flex justify-center items-center p-12`,
      direction === `row` ? `flex-row` : `flex-col`,
      className,
    )}
  >
    {children}
  </div>
);
