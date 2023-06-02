import type { PqlError } from '@dash/types';
import type { QueryResult } from './query';

type ZipQueryResult<T> =
  | {
      status: `loading`;
      isLoading: true;
      isError: false;
      isSuccess: false;
    }
  | {
      status: `error`;
      isLoading: false;
      isError: true;
      isSuccess: false;
      error: PqlError;
    }
  | {
      status: `success`;
      isLoading: false;
      isError: false;
      isSuccess: true;
      data: T;
    };

export function useZip<T1, T2>(
  query1: QueryResult<T1>,
  query2: QueryResult<T2>,
): ZipQueryResult<[T1, T2]>;

export function useZip<T1, T2, T3>(
  query1: QueryResult<T1>,
  query2: QueryResult<T2>,
  query3: QueryResult<T3>,
): ZipQueryResult<[T1, T2, T3]>;

export function useZip<T1, T2, T3>(
  query1: QueryResult<T1>,
  query2: QueryResult<T2>,
  query3?: QueryResult<T3>,
): ZipQueryResult<[T1, T2, T3]> | ZipQueryResult<[T1, T2]> {
  if (query1.isError) {
    return error(query1.error);
  }
  if (query2.isError) {
    return error(query2.error);
  }
  if (query3?.isError) {
    return error(query3.error);
  }
  if (query1.isLoading || query2.isLoading || query3?.isLoading) {
    return loading();
  }
  if (query3) {
    return success([query1.data, query2.data, query3.data]);
  } else {
    return success([query1.data, query2.data]);
  }
}

export function loading(): ZipQueryResult<any> {
  return {
    status: `loading`,
    isLoading: true,
    isError: false,
    isSuccess: false,
  };
}

function error(error: PqlError): ZipQueryResult<any> {
  return {
    status: `error`,
    isLoading: false,
    isError: true,
    isSuccess: false,
    error,
  };
}

function success<T>(data: T): ZipQueryResult<T> {
  return {
    status: `success`,
    isLoading: false,
    isError: false,
    isSuccess: true,
    data,
  };
}
