import React from "react";

interface Props {
  bgColor: string;
  borderColor: string;
  textColor: string;
  className?: string;
  hoverChanges: string;
  children: React.ReactNode;
  onClick(): void;
}

const ButtonPrimary: React.FC<Props> = ({
  bgColor,
  borderColor,
  textColor,
  className,
  children,
  hoverChanges,
  onClick,
}) => {
  return (
    <button
      className={`${className} ${bgColor} ${borderColor} ${textColor} border-2 px-5 py-2 font-bold rounded-lg transition duration-100 ${hoverChanges}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
};

export default ButtonPrimary;
