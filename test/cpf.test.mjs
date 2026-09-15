import test from 'node:test';
import assert from 'node:assert/strict';
import { cpfValido, normalizarCpf } from '../src/cpf.mjs';

// Mesmos casos usados em tests/Unit/DocumentoTest.php na oficina-api.
test('aceita CPF válido com e sem máscara', () => {
  assert.equal(cpfValido('529.982.247-25'), true);
  assert.equal(cpfValido('52998224725'), true);
});

test('rejeita dígito verificador errado', () => {
  assert.equal(cpfValido('529.982.247-26'), false);
});

test('rejeita dígitos repetidos', () => {
  assert.equal(cpfValido('11111111111'), false);
});

test('rejeita tamanho inválido e vazio', () => {
  assert.equal(cpfValido('123'), false);
  assert.equal(cpfValido(''), false);
  assert.equal(cpfValido(undefined), false);
});

test('normaliza removendo tudo que não é dígito', () => {
  assert.equal(normalizarCpf('529.982.247-25'), '52998224725');
});
