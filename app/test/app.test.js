import assert from 'node:assert';
import http from 'node:http';
import test from 'node:test';
import app from '../app.js';

test('GET /hola', async (t) => {
    
    const server = app.listen(0);
    const { port } = server.address();
    const body = await new Promise((resolve, reject) => {
        http.get(`http://localhost:${port}/hola`, (res) => {
            let data = '';
            res.on("data", (chunk) => { data += chunk; });
            res.on("end", () => { resolve(data); });
        }).on("error", reject);
    });

    await new Promise((r) => server.close(r));
    const parsed = JSON.parse(body);
    assert.strictEqual(parsed.mensaje, 'Hola Mundo');
});