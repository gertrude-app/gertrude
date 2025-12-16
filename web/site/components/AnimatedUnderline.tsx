interface AnimatedUnderlineProps {
  isVisible: boolean;
  delay?: number;
  gradientId: string;
  fromColor: string;
  toColor: string;
  height?: number;
  strokeWidth?: number;
  className?: string;
}

const AnimatedUnderline: React.FC<AnimatedUnderlineProps> = ({
  isVisible,
  delay = 0,
  gradientId,
  fromColor,
  toColor,
  height = 6,
  strokeWidth = 3,
  className = `absolute bottom-0 left-0 w-full translate-y-0.5 md:translate-y-1`,
}) => (
  <svg
    className={className}
    height={height}
    viewBox={`0 0 200 ${height}`}
    preserveAspectRatio="none"
  >
    <defs>
      <linearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" style={{ stopColor: fromColor, stopOpacity: 1 }} />
        <stop offset="100%" style={{ stopColor: toColor, stopOpacity: 1 }} />
      </linearGradient>
    </defs>
    <path
      d={`M 0 ${height / 2} Q 50 ${height / 2 - 2}, 100 ${height / 2} T 200 ${height / 2}`}
      stroke={`url(#${gradientId})`}
      strokeWidth={strokeWidth}
      fill="none"
      strokeLinecap="butt"
      pathLength="1"
      strokeDasharray="1"
      strokeDashoffset={isVisible ? 0 : 1}
      style={{
        transition: `stroke-dashoffset 0.3s ease-out`,
        transitionDelay: isVisible ? `${delay}ms` : `0ms`,
      }}
    />
  </svg>
);

export default AnimatedUnderline;
