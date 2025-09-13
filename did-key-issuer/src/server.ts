import { Hono } from 'hono' // Hono app
import { serve } from '@hono/node-server' // Node adapter
import { cors } from 'hono/cors' // CORS middleware
import { issueDidKey } from './issuer.js'

// For dev, allow all origins. In prod, set to your exact Flutter Web origin (e.g., http://localhost:61372).
const WEB_ORIGIN = process.env.WEB_ORIGIN ?? '*'

const app = new Hono()

// 1) CORS must be registered BEFORE routes. Handles preflight automatically.
app.use('*', cors({
origin: WEB_ORIGIN,
allowMethods: ['OPTIONS', 'GET', 'POST'],
allowHeaders: ['Content-Type', 'Authorization'],
}))

// 2) Optional explicit preflight catcher (helps when proxies swallow OPTIONS).
app.options('*', (c) => c.body(null, 204))

app.get('/', (c) => c.text('DID Issuer is running'))

app.post('/issue-did', async (c) => {
try {
const body = await c.req.json().catch(() => ({} as any))
const userId = String(body.userId ?? '')
const rotate = Boolean(body.rotate)
if (!userId) {
// Ensure CORS header on actual POST responses too.
c.header('Access-Control-Allow-Origin', WEB_ORIGIN)
return c.json({ error: 'userId is required' }, 400)
}
const result = await issueDidKey({ userId, rotate })

// Critical: echo CORS on POST response so the browser accepts it after preflight.[6]
c.header('Access-Control-Allow-Origin', WEB_ORIGIN)
return c.json(result, 200)
} catch (e: any) {
c.header('Access-Control-Allow-Origin', WEB_ORIGIN)
return c.json({ error: e?.message ?? 'Unknown error' }, 400)
}
})

const port = Number(process.env.PORT ?? 8787)
serve({ fetch: app.fetch, port })
console.log(`DID Issuer listening on http://localhost:${port}`)