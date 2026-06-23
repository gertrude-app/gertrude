import { Toast } from '@base-ui/react/toast';
import type { ToastManagerAddOptions } from '@base-ui/react/toast';
import type React from 'react';

export type ToastVariant = `success` | `error` | `info` | `loading`;

export type ToastOptions = Omit<ToastManagerAddOptions<object>, `description` | `type`>;

export type ToastVariantFunction = (
  message: React.ReactNode,
  options?: ToastOptions,
) => string;

export type ToastAsyncOptions<Value> = {
  loading?: React.ReactNode;
  success?: React.ReactNode | ((value: Value) => React.ReactNode);
  error?: React.ReactNode | ((error: unknown) => React.ReactNode);
};

export type ToastAsyncFunction = <Value>(
  promise: Promise<Value>,
  options?: ToastAsyncOptions<Value>,
) => Promise<Value>;

export interface ToastFunction extends ToastVariantFunction {
  success: ToastVariantFunction;
  error: ToastVariantFunction;
  info: ToastVariantFunction;
  async: ToastAsyncFunction;
  dismiss: (id?: string) => void;
}

export const toastManager = Toast.createToastManager();

const addToast = (
  variant: ToastVariant,
  message: React.ReactNode,
  options: ToastOptions = {},
): string =>
  toastManager.add({
    ...options,
    description: message,
    type: variant,
    priority: options.priority ?? (variant === `error` ? `high` : `low`),
  });

const resolveAsyncMessage = <Value>(
  message: React.ReactNode | ((value: Value) => React.ReactNode) | undefined,
  value: Value,
  fallback: React.ReactNode,
): React.ReactNode =>
  typeof message === `function` ? message(value) : (message ?? fallback);

const addAsyncToast: ToastAsyncFunction = (promise, options = {}) =>
  toastManager.promise(promise, {
    loading: { description: options.loading ?? `Working…` },
    success: (value) => ({
      description: resolveAsyncMessage(options.success, value, `Done`),
    }),
    error: (error) => ({
      description: resolveAsyncMessage(options.error, error, `Something went wrong`),
      priority: `high`,
    }),
  });

export const toast: ToastFunction = Object.assign(
  (message: React.ReactNode, options?: ToastOptions) =>
    addToast(`info`, message, options),
  {
    success: (message: React.ReactNode, options?: ToastOptions) =>
      addToast(`success`, message, options),
    error: (message: React.ReactNode, options?: ToastOptions) =>
      addToast(`error`, message, options),
    info: (message: React.ReactNode, options?: ToastOptions) =>
      addToast(`info`, message, options),
    async: addAsyncToast,
    dismiss: toastManager.close,
  },
);
