import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buscarCliente } from '../src/osService.mjs';

function fetchFalso(status, corpo) {
  const chamadas = [];
  const fn = async (url, opcoes) => {
    chamadas.push({ url, opcoes });
    return { status, ok: status >= 200 && status < 300, json: async () => corpo };
  };
  return { fn, chamadas };
}

const opcoes = (fetchFn) => ({ baseUrl: 'http://os', token: 'tk', correlationId: 'corr-1', fetchFn });

test('busca o cliente na rota interna com token e correlation id', async () => {
  const { fn, chamadas } = fetchFalso(200, { data: { id: 7, nome: 'Ana', ativo: true } });

  const cliente = await buscarCliente('52998224725', opcoes(fn));

  assert.deepEqual(cliente, { id: 7, nome: 'Ana', ativo: true });
  assert.equal(chamadas[0].url, 'http://os/internal/clientes/por-documento/52998224725');
  assert.equal(chamadas[0].opcoes.headers['X-Internal-Token'], 'tk');
  assert.equal(chamadas[0].opcoes.headers['X-Request-Id'], 'corr-1');
});

test('cliente inexistente vira undefined', async () => {
  assert.equal(await buscarCliente('1', opcoes(fetchFalso(404, {}).fn)), undefined);
});

test('erro do OS Service é propagado', async () => {
  await assert.rejects(buscarCliente('1', opcoes(fetchFalso(401, {}).fn)), /respondeu 401/);
});
