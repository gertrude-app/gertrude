import cx from 'classnames';
import type React from 'react';
import type { AppEvent, ViewAction } from '../../menubar-store';
import * as Btn from './Buttons';

interface Props {
  open: boolean;
  emit(event: AppEvent): unknown;
  dispatch(action: ViewAction): unknown;
}

const PauseDowntimeModal: React.FC<Props> = ({ open, emit, dispatch }) => (
  <>
    <div
      className={cx(
        `bg-white/50 dark:bg-white/10 backdrop-blur shadow-lg absolute z-20 px-3 py-2 rounded-xl w-80 transition-[opacity,transform] duration-300`,
        !open && `pointer-events-none opacity-0 translate-y-32 scale-0 -translate-x-32`,
      )}
    >
      <header className="flex justify-between">
        <h2 className="font-medium text-lg dark:text-white">Pause downtime for</h2>
        <button
          className="cursor-default"
          onClick={() => dispatch({ type: `toggleShowingDowntimePauseDuration` })}
        >
          <i className="fa fa-times text-black/40 dark:text-white/70 text-sm bg-black/10 dark:bg-white/10 w-5 h-5 rounded-full flex justify-center items-center hover:bg-black/20 dark:hover:bg-white/20 hover:scale-110 active:bg-black/30 dark:active:bg-white/30 active:scale-95 transition-[background-color,transform] duration-200" />
        </button>
      </header>
      <div className="flex flex-wrap justify-center gap-2 py-4">
        <Btn.White
          onClick={() => emit({ case: `pauseDowntimeClicked`, duration: `tenMinutes` })}
        >
          10 minutes
        </Btn.White>
        <Btn.White
          onClick={() => emit({ case: `pauseDowntimeClicked`, duration: `oneHour` })}
        >
          1 hour
        </Btn.White>
        <Btn.White
          onClick={() => emit({ case: `pauseDowntimeClicked`, duration: `oneDay` })}
        >
          Until next downtime
        </Btn.White>
      </div>
    </div>
    <div
      className={cx(
        `absolute w-full h-full top-0 left-0 z-10 transition-colors, duration-300`,
        open ? `bg-black/[15%]` : `bg-transparent pointer-events-none`,
      )}
      onClick={() => dispatch({ type: `toggleShowingDowntimePauseDuration` })}
    />
  </>
);
export default PauseDowntimeModal;
