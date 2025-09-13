import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
const DATA_DIR = path.join(process.cwd(), 'data');
const PUBLIC_DB = path.join(DATA_DIR, 'digital_ids.json');
const VAULT_DB = path.join(DATA_DIR, 'vault.json');
async function ensureFiles() {
    await mkdir(DATA_DIR, { recursive: true });
    if (!existsSync(PUBLIC_DB))
        await writeFile(PUBLIC_DB, '[]', 'utf8');
    if (!existsSync(VAULT_DB))
        await writeFile(VAULT_DB, '[]', 'utf8');
}
async function readJSON(file) {
    await ensureFiles();
    return JSON.parse(await (await readFile(file, 'utf8')));
}
async function writeJSON(file, data) {
    await ensureFiles();
    await writeFile(file, JSON.stringify(data, null, 2), 'utf8');
}
export async function getActiveDigitalIdByUser(userId) {
    const all = await readJSON(PUBLIC_DB);
    return all.find(r => r.userId === userId && r.status === 'active');
}
export async function saveDigitalId(rec) {
    const all = await readJSON(PUBLIC_DB);
    // mark previous active as rotated if any (rotation readiness)
    all.forEach(r => {
        if (r.userId === rec.userId && r.status === 'active')
            r.status = 'rotated';
    });
    all.push(rec);
    await writeJSON(PUBLIC_DB, all);
}
export async function savePrivateKey(userId, privateKey) {
    const all = await readJSON(VAULT_DB);
    const privateKeyB64 = Buffer.from(privateKey).toString('base64');
    // Replace or add
    const idx = all.findIndex(v => v.userId === userId);
    if (idx >= 0)
        all[idx] = { userId, privateKeyB64 };
    else
        all.push({ userId, privateKeyB64 });
    await writeJSON(VAULT_DB, all);
}
