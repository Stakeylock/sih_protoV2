import nacl from 'tweetnacl';
import { base58btc } from 'multiformats/bases/base58';
const ED25519_PUB_PREFIX = Uint8Array.from([0xed, 0x01]);
export function generateEd25519() {
    const kp = nacl.sign.keyPair();
    return { publicKey: kp.publicKey, secretKey: kp.secretKey };
}
export function toPublicKeyMultibaseEd25519(publicKey) {
    const prefixed = new Uint8Array(ED25519_PUB_PREFIX.length + publicKey.length);
    prefixed.set(ED25519_PUB_PREFIX, 0);
    prefixed.set(publicKey, ED25519_PUB_PREFIX.length);
    const multibaseStr = base58btc.encode(prefixed);
    return multibaseStr;
}
export function didKeyFromPublicKeyMultibase(publicKeyMultibase) {
    return `did:key:${publicKeyMultibase}`;
}
