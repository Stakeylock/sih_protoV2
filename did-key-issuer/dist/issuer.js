import { generateEd25519, toPublicKeyMultibaseEd25519, didKeyFromPublicKeyMultibase } from './crypto.js';
import { getActiveDigitalIdByUser, saveDigitalId, savePrivateKey } from './store.js';
export async function issueDidKey(opts) {
    const { userId, rotate = false } = opts;
    if (!userId)
        throw new Error('userId required');
    if (!rotate) {
        const existing = await getActiveDigitalIdByUser(userId);
        if (existing) {
            return {
                userId: existing.userId,
                did: existing.did,
                method: existing.method,
                publicKeyMultibase: existing.publicKeyMultibase,
                keyType: existing.keyType,
                issuedAt: existing.issuedAt,
                status: 'active',
            };
        }
    }
    const kp = generateEd25519();
    const publicKeyMultibase = toPublicKeyMultibaseEd25519(kp.publicKey);
    const did = didKeyFromPublicKeyMultibase(publicKeyMultibase);
    const issuedAt = new Date().toISOString();
    await saveDigitalId({
        userId,
        did,
        method: 'did:key',
        publicKeyMultibase,
        keyType: 'Ed25519',
        issuedAt,
        status: 'active',
    });
    await savePrivateKey(userId, kp.secretKey);
    return {
        userId,
        did,
        method: 'did:key',
        publicKeyMultibase,
        keyType: 'Ed25519',
        issuedAt,
        status: 'active',
    };
}
