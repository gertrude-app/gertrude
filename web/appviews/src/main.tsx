import React, { render } from 'preact';
import MenuBar from './MenuBar/MenuBar';

render(<MenuBar state="notConnected" />, document.getElementById(`app`) as HTMLElement);
