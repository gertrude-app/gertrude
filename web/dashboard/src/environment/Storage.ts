export interface StorageClient {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
  clear(): void;
}

export class LiveStorage implements StorageClient {
  public constructor(private storage: Storage) {}
  public getItem(key: string): string | null {
    return this.storage.getItem(key);
  }
  public setItem(key: string, value: string): void {
    return this.storage.setItem(key, value);
  }
  public removeItem(key: string): void {
    return this.storage.removeItem(key);
  }
  public clear(): void {
    return this.storage.clear();
  }
}

export class ThrowingStorage implements StorageClient {
  public constructor(private type: 'local' | 'session') {}
  public getItem(_key: string): string | null {
    throw new Error(`StorageClient<${this.type}>.getItem() not implemented`);
  }
  public setItem(_key: string, _value: string): void {
    throw new Error(`StorageClient<${this.type}>.setItem() not implemented`);
  }
  public removeItem(_key: string): void {
    throw new Error(`StorageClient<${this.type}>.removeItem() not implemented`);
  }
  public clear(): void {
    throw new Error(`StorageClient<${this.type}>.clear() not implemented`);
  }
}

export class NoopStorage implements StorageClient {
  public getItem(_key: string): string | null {
    return null;
  }
  public setItem(_key: string, _value: string): void {
    return;
  }
  public removeItem(_key: string): void {
    return;
  }
  public clear(): void {
    return;
  }
}
