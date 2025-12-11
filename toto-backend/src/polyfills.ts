// Polyfills for Node 18 compatibility
import { webcrypto } from 'crypto';

if (!global.crypto) {
  (global as any).crypto = webcrypto;
}
