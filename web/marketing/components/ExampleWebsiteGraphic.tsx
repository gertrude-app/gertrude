import React from "react";

interface Props {
  className?: string;
}

const ExampleWebsiteGraphic: React.FC<Props> = ({ className }) => {
  return (
    <div
      className={`absolute w-52 h-52 bg-gray-800 shadow-xl rounded-xl flex flex-col border border-white border-opacity-20 ${className}`}
    >
      <div className="flex items-center">
        <div className="flex pl-3 pt-1">
          <div className="w-3 h-3 bg-red-500 rounded-full bg-opacity-90" />
          <div className="w-3 h-3 bg-yellow-500 rounded-full bg-opacity-90 ml-1.5" />
          <div className="w-3 h-3 bg-green-500 rounded-full bg-opacity-90 ml-1.5" />
        </div>
        <div className="flex-grow bg-gray-800 h-6 ml-2 rounded-tr-xl relative z-20 top-0 flex justify-center items-center">
          <div className="w-2/3 h-1 bg-gray-600 rounded-full" />
        </div>
        <div className="flex-grow bg-gray-700 ml-2 h-3 w-10 absolute top-0 left-24 z-10" />
        <div className="flex-grow bg-gray-700 h-6 rounded-bl-xl rounded-tr-xl" />
      </div>
      <div className="flex justify-center items-center p-3">
        <div className="h-3 flex-grow rounded-full bg-gray-600" />
      </div>
      <div className="bg-gray-900 flex-grow bg-opacity-30 flex flex-col rounded-b-xl">
        <div className="h-14 p-2 flex">
          <div className="flex-grow bg-gray-700 shadow-lg rounded-lg p-2 flex justify-between items-center">
            <div>
              <div className="rounded-full w-20 h-2 bg-violet-500 mb-1" />
              <div className="rounded-full w-28 h-1 bg-gray-500 mb-1" />
              <div className="rounded-full w-24 h-1 bg-gray-500" />
            </div>
            <div className="w-7 h-7 rounded-full bg-gray-600" />
          </div>
        </div>
        <div className="flex-grow flex -mt-2">
          <div className="w-20 p-2">
            <div className="h-full bg-gray-600 rounded-lg shadow-lg p-2">
              <div className="rounded-full w-10 h-1 bg-gray-400 mb-1" />
              <div className="rounded-full w-12 h-1 bg-gray-500 mb-1" />
              <div className="rounded-full w-8 h-1 bg-gray-500" />
              <div className="rounded-sm mt-2 w-12 h-10 bg-gray-500" />
            </div>
          </div>
          <div className="flex-grow flex flex-col justify-between p-2 pl-0">
            <div className="flex-grow bg-violet-700 shadow-lg rounded-lg p-2 flex justify-between items-center h-9 mb-2">
              <div>
                <div className="rounded-full w-20 h-1 bg-white bg-opacity-40 mb-1" />
                <div className="rounded-full w-14 h-1 bg-white bg-opacity-40" />
              </div>
            </div>
            <div className="flex-grow bg-gray-700 shadow-lg rounded-lg p-2 flex justify-between items-center h-9">
              <div>
                <div className="rounded-full w-20 h-1 bg-gray-500 mb-1" />
                <div className="rounded-full w-14 h-1 bg-gray-500" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ExampleWebsiteGraphic;
