import type { QueryResult } from './query';
import type { PqlError } from '@dash/types';

type ZipQueryResult<T> =
  | {
      status: `loading`;
      isPending: true;
      isError: false;
      isSuccess: false;
    }
  | {
      status: `error`;
      isPending: false;
      isError: true;
      isSuccess: false;
      error: PqlError;
    }
  | {
      status: `success`;
      isPending: false;
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
  if (query1.isPending || query2.isPending || query3?.isPending) {
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
    isPending: true,
    isError: false,
    isSuccess: false,
  };
}

function error(error: PqlError): ZipQueryResult<any> {
  return {
    status: `error`,
    isPending: false,
    isError: true,
    isSuccess: false,
    error,
  };
}

function success<T>(data: T): ZipQueryResult<T> {
  return {
    status: `success`,
    isPending: false,
    isError: false,
    isSuccess: true,
    data,
  };
}
