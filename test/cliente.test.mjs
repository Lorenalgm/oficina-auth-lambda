import { test } from 'node:test';
import assert from 'node:assert/strict';
import { recusaDoCliente } from '../src/cliente.mjs';

test('cliente inexistente é recusado com 404', () => {
  assert.equal(recusaDoCliente(undefined).statusCode, 404);
});

test('cliente inativo é recusado com 403', () => {
  const recusa = recusaDoCliente({ id: 1, nome: 'Ana', ativo: false });
  assert.equal(recusa.statusCode, 403);
  assert.equal(recusa.message, 'Cliente inativo.');
});

test('cliente ativo pode receber token', () => {
  assert.equal(recusaDoCliente({ id: 1, nome: 'Ana', ativo: true }), null);
});
