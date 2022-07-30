export function formatTime(date: Date) {
  const hours = date.getHours();
  const legibleHours = hours > 12 ? hours - 12 : hours;
  const minutes = date.getMinutes();
  const seconds = date.getSeconds();
  return `${legibleHours}:${minutes < 10 ? '0' : ''}${minutes}:${
    seconds < 10 ? '0' : ''
  }${seconds} ${hours > 12 ? 'PM' : 'AM'}`;
}
