// framezero / conferencia da assinatura da licenca (roda no Node do FiveM)
// A API assina a resposta com Ed25519. Aqui conferimos com a chave publica.
// Trocar PUBLIC_KEY pela chave do seu par (license-public.pem do bot).

const crypto = require('crypto');

const PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAo+6ZhkfJqZaT3hCUoEATc7m30keQQcD667KX31ZaDlc=
-----END PUBLIC KEY-----`;

const key = crypto.createPublicKey(PUBLIC_KEY);

// body = texto cru da resposta: { payload, signature }
// Confere a assinatura, o nonce e o resource. So devolve ok=true se tudo bater.
function verify(body, expectedNonce, expectedResource) {
    let parsed;
    try {
        parsed = JSON.parse(body);
    } catch {
        return { ok: false, reason: 'resposta_invalida' };
    }
    if (!parsed.payload || !parsed.signature) return { ok: false, reason: 'resposta_invalida' };

    const valid = crypto.verify(null, Buffer.from(parsed.payload), key, Buffer.from(parsed.signature, 'base64'));
    if (!valid) return { ok: false, reason: 'assinatura_invalida' };

    let data;
    try {
        data = JSON.parse(parsed.payload);
    } catch {
        return { ok: false, reason: 'resposta_invalida' };
    }
    // Nonce diferente = resposta reaproveitada (replay)
    if (data.nonce !== expectedNonce) return { ok: false, reason: 'nonce_invalido' };
    if (data.resource !== expectedResource) return { ok: false, reason: 'resource_invalido' };
    // Resposta velha demais (mais de 2 minutos)
    if (Math.abs(Math.floor(Date.now() / 1000) - (data.ts || 0)) > 120) return { ok: false, reason: 'resposta_expirada' };

    return { ok: data.ok === true, reason: data.reason || null };
}

// Deixa a funcao disponivel para o Lua (framezero.License.Verify)
global.framezero = global.framezero || {};
global.framezero.VerifyLicense = verify;

exports('VerifyLicense', verify);
