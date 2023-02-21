import React, { render } from 'preact';
import MenuBar from './MenuBar/MenuBar';

render(
  <MenuBar filterOn={true} screenshotMonitoring={true} keystrokeMonitoring={false} />,
  document.getElementById(`app`) as HTMLElement,
);
