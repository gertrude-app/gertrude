import { useSearchParams } from 'react-router-dom';

export default function useLoginRedirect(): string | null {
  const [searchParams] = useSearchParams();
  const encodedPath = searchParams.get(`redirect`);
  if (encodedPath) {
    return decodeURIComponent(encodedPath);
  }
  return null;
}
