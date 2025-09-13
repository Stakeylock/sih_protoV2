import { readFile, writeFile, mkdir } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import path from 'node:path'

const DATA_DIR = path.join(process.cwd(), 'data')
const PUBLIC_DB = path.join(DATA_DIR, 'digital_ids.json')
const VAULT_DB = path.join(DATA_DIR, 'vault.json')

type DigitalIdRecord = {
    userId: string
    did: string
    method: string
    publicKeyMultibase: string
    keyType: 'Ed25519'
    issuedAt: string
    status: 'active' | 'rotated' | 'revoked'
}

type VaultRecord = {
    userId: string
    // base64-encoded private key bytes
    privateKeyB64: string
}

async function ensureFiles() {
    await mkdir(DATA_DIR, { recursive: true })
    if (!existsSync(PUBLIC_DB)) await writeFile(PUBLIC_DB, '[]', 'utf8')
    if (!existsSync(VAULT_DB)) await writeFile(VAULT_DB, '[]', 'utf8')
}

async function readJSON<T>(file: string): Promise<T> {
    await ensureFiles()
    return JSON.parse(await (await readFile(file, 'utf8')))
}

async function writeJSON<T>(file: string, data: T): Promise<void> {
    await ensureFiles()
    await writeFile(file, JSON.stringify(data, null, 2), 'utf8')
}

export async function getActiveDigitalIdByUser(userId: string): Promise<DigitalIdRecord | undefined> {
    const all: DigitalIdRecord[] = await readJSON(PUBLIC_DB)
    return all.find(r => r.userId === userId && r.status === 'active')
}

export async function saveDigitalId(rec: DigitalIdRecord): Promise<void> {
    const all: DigitalIdRecord[] = await readJSON(PUBLIC_DB)
    // mark previous active as rotated if any (rotation readiness)
    all.forEach(r => {
        if (r.userId === rec.userId && r.status === 'active') r.status = 'rotated'
    })
    all.push(rec)
    await writeJSON(PUBLIC_DB, all)
}

export async function savePrivateKey(userId: string, privateKey: Uint8Array): Promise<void> {
    const all: VaultRecord[] = await readJSON(VAULT_DB)
    const privateKeyB64 = Buffer.from(privateKey).toString('base64')
    // Replace or add
    const idx = all.findIndex(v => v.userId === userId)
    if (idx >= 0) all[idx] = { userId, privateKeyB64 }
    else all.push({ userId, privateKeyB64 })
    await writeJSON(VAULT_DB, all)
}