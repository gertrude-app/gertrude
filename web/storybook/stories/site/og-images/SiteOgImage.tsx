import React from 'react';

const OgImage: React.FC = () => (
  <section
    className="relative w-[1200px] h-[627px] overflow-hidden flex flex-col items-center justify-center text-center"
    style={{
      background: `radial-gradient(ellipse at 50% 40%, #1e1b4b 0%, #09090b 70%)`,
    }}
  >
    <div
      className="absolute inset-0 opacity-[0.35] pointer-events-none"
      style={{
        background: `radial-gradient(ellipse at 50% 50%, rgba(167,139,250,0.35) 0%, transparent 50%)`,
      }}
    />
    <div
      className="absolute inset-0 opacity-[0.06] pointer-events-none"
      style={{
        backgroundImage: `repeating-linear-gradient(45deg, rgba(255,255,255,0.15) 0px, rgba(255,255,255,0.15) 1px, transparent 1px, transparent 8px)`,
      }}
    />

    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={180}
      height={180}
      viewBox="0 0 1250 1240"
      className="relative mb-6 -translate-y-6"
      style={{
        filter: `drop-shadow(0 0 50px rgba(217,70,239,0.55)) drop-shadow(0 0 20px rgba(139,92,246,0.6))`,
      }}
    >
      <defs>
        <linearGradient id="SiteOgImageGradient" x1="0" x2="0" y1="0" y2="1">
          <stop stopColor="#c4b5fd" />
          <stop offset="1" stopColor="#f0abfc" />
        </linearGradient>
      </defs>
      <path
        d="M 595.177 170.634 C 561.903 175.767, 530.633 189.195, 504.039 209.770 C 482.421 226.495, 216.195 494.797, 206.126 510.005 C 161.875 576.845, 163.739 667.193, 210.616 727.631 C 222.488 742.937, 460.408 982.095, 502.761 1021.295 C 568.157 1081.824, 679.283 1082.653, 747.825 1023.124 C 779.646 995.487, 1032.850 739.640, 1041.878 726 C 1086.096 659.201, 1084.243 573.409, 1037.194 509 C 1031.604 501.347, 764.863 233.177, 746.040 216.285 C 706.625 180.914, 646.493 162.719, 595.177 170.634 M 631.500 349.485 C 611.720 353.858, 609.836 354.943, 513.500 417.474 C 398.233 492.291, 387.820 499.457, 378.809 510.167 C 350.091 544.300, 344.115 595.501, 364.708 630.989 C 383.738 663.785, 499.067 839.766, 507.431 848.772 C 547.214 891.607, 601.147 894.239, 660.500 856.242 C 689.279 837.819, 805.262 762.488, 828.080 747.400 C 882.786 711.226, 900.744 667.270, 882.888 613.239 C 878.898 601.165, 829.728 523.097, 751.101 404 C 722 359.921, 677.025 339.421, 631.500 349.485"
        fillRule="evenodd"
        fill="url(#SiteOgImageGradient)"
      />
    </svg>

    <div className="relative text-[118px] leading-[1] font-light tracking-[0.02em] text-white mb-2 -translate-y-6 font-inter">
      Gertrude
    </div>
    <div className="relative text-[32px] tracking-[0.4em] uppercase text-white/55 font-medium -translate-y-6">
      Tools for{` `}
      <span className="bg-gradient-to-r from-violet-300 via-fuchsia-300 to-pink-300 bg-clip-text [-webkit-background-clip:text] text-transparent font-semibold">
        Innocence
      </span>
    </div>

    <div className="absolute bottom-10 left-0 right-0 flex items-center justify-center gap-7 text-[18px] tracking-[0.3em] uppercase text-white/40 font-semibold">
      <span>Mac</span>
      <span className="w-1.5 h-1.5 rounded-full bg-white/30" />
      <span>iPhone / iPad</span>
      <span className="w-1.5 h-1.5 rounded-full bg-white/30" />
      <span>Podcasts</span>
    </div>
  </section>
);

export default OgImage;
