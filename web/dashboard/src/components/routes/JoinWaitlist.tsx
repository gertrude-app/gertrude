import Button from '@shared/Button';
import React from 'react';

const JoinWaitlist: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-gradient-to-b from-violet-500 to-fuchsia-500">
      {new Array(15).fill(0).map(() => {
        const s = Math.random() * 150 + 50;
        return (
          <SubtleLogo
            size={s}
            angle={Math.random() * 36}
            x={Math.random() * 150 - 2}
            y={Math.random() * 150 - 25}
          />
        );
      })}
      <div className="py-12 px-8 sm:px-12 rounded-2xl shadow-lg flex justify-center items-center flex-col border bg-white relative z-10 mx-10">
        <svg
          width="75"
          viewBox="0 0 35 35"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M2.95087 22.3525C0.21658 19.6194 0.216578 15.1883 2.95086 12.4552L12.4617 2.94862C15.196 0.215571 19.6292 0.215571 22.3635 2.94862L32.0667 12.6475C34.801 15.3806 34.801 19.8117 32.0667 22.5448L22.5558 32.0514C19.8215 34.7844 15.3884 34.7844 12.6541 32.0514L2.95087 22.3525Z"
            fill="url(#paint0_linear_16_3)"
          />
          <path
            d="M8.17925 18.3251C6.97568 16.4726 7.50215 13.9958 9.35513 12.793L16.465 8.17786C18.318 6.97506 20.7958 7.50174 21.9994 9.35423L26.6158 16.4597C27.8194 18.3122 27.2929 20.789 25.4399 21.9918L18.33 26.6069C16.477 27.8097 13.9992 27.283 12.7957 25.4305L8.17925 18.3251Z"
            fill="white"
          />
          <defs>
            <linearGradient
              id="paint0_linear_16_3"
              x1="17.5088"
              y1="0.898834"
              x2="17.5088"
              y2="34.1011"
              gradientUnits="userSpaceOnUse"
            >
              <stop stop-color="#8B5CF6" />
              <stop offset="1" stop-color="#D846EF" />
            </linearGradient>
          </defs>
        </svg>

        <h2 className="text-center mt-4 text-3xl font-inter">Join the waitlist</h2>
        <h3 className="text-center text-gray-500 mt-2">
          We'll notify you when you can begin trying out Gertrude
        </h3>
        <div className="mt-8 mb-6 flex flex-col w-full">
          <label htmlFor="email" className="mb-1 text-gray-500 text-lg">
            Email address
          </label>
          <input
            type="email"
            name="email"
            className="h-10 border ring-0 ring-gray-200 rounded-lg shadow-sm outline-none py-6 px-4 focus:shadow-md transition duration-150 focus:border-indigo-500 focus:ring-indigo-500 focus:ring-1 text-gray-600"
          />
        </div>
        <Button onClick={() => {}} color="primary-violet" type="button" fullWidth>
          Join the waitlist
        </Button>
        <Button type="link" to="/" color="secondary-white" className="mt-3" fullWidth>
          Cancel
        </Button>
      </div>
    </div>
  );
};

interface SubtleLogoProps {
  size: number;
  angle: number;
  x: number;
  y: number;
}

const SubtleLogo: React.FC<SubtleLogoProps> = ({ size, x, y, angle }) => {
  return (
    <div
      style={{
        width: size,
        height: size,
        left: `${x}%`,
        top: `${y}%`,
        borderRadius: size / 5,
        transform: `rotate(${angle}deg)`,
      }}
      className="border-2 absolute border-dashed justify-center items-center border-white border-opacity-40 hidden sm:flex"
    >
      <div
        className="border-2 border-dashed rotate-12 border-white border-opacity-40"
        style={{
          width: size / 1.7,
          height: size / 1.7,
          borderRadius: size / 7,
        }}
      />
    </div>
  );
};

export default JoinWaitlist;
