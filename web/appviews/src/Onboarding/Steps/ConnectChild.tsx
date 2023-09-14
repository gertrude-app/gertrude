import { Loading } from '@shared/components';
import React from 'react';
import type { AppEvent, RequestState, ViewAction } from '../onboarding-store';

interface Props {
  emit(event: AppEvent): unknown;
  dispatch(action: ViewAction): unknown;
  connectionCode: string;
  request: RequestState<string, string>;
}

const ConnectChild: React.FC<Props> = ({ emit, dispatch, connectionCode, request }) => {
  switch (request.state) {
    case `ongoing`:
      return <Loading />;
    case `idle`:
      return (
        <div>
          <h1 className="text-3xl">Connect a child</h1>
          <p>Enter the 6-digit connection code from the Gertrude parent's site</p>
          <input type="text" value={connectionCode} />
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() =>
              dispatch({ type: `updateConnectionCode`, code: connectionCode })
            }
          >
            Submit &rarr;
          </button>
        </div>
      );
    case `failed`:
      return (
        <div>
          <h1 className="text-3xl">Uh-oh, something went wrong</h1>
          <p>Failed to connect child</p>
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Try again
          </button>
          <button
            className="bg-gray-400 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `secondaryBtnClicked` })}
          >
            Get help
          </button>
        </div>
      );
    case `succeeded`:
      return (
        <div>
          <h1 className="text-3xl">Success!</h1>
          <p>
            You've connected this computer to the child <code>{request.payload}</code>
          </p>
          <button
            className="bg-blue-500 text-white font-bold py-2 px-4"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Next &rarr;
          </button>
        </div>
      );
  }
};

export default ConnectChild;
