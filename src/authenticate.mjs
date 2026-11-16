import { SignJWT } from 'jose';
import { cpfValido, normalizarCpf } from './cpf.mjs';
import { carregarConfig } from './config.mjs';
import { recusaDoCliente } from './cliente.mjs';
import { buscarCliente } from './osService.mjs';

function resposta(statusCode, corpo, correlationId) {
  return {
    statusCode,
    headers: { 'Content-Type': 'application/json', 'X-Request-Id': correlationId },
    body: JSON.stringify(corpo),
  };
}

function logar(nivel, mensagem, atributos) {
  // Log em JSON no mesmo formato da oficina-api, para que os dois apareçam
  // correlacionados nas mesmas consultas NRQL do New Relic.
  console.log(JSON.stringify({ level: nivel, message: mensagem, service: 'oficina-auth-lambda', ...atributos }));
}

export async function handler(event) {
  const correlationId = event.headers?.['x-request-id'] ?? event.requestContext?.requestId ?? 'sem-correlacao';
  const inicio = Date.now();

  try {
    const { cpf } = JSON.parse(event.body ?? '{}');

    if (!cpfValido(cpf)) {
      logar('warning', 'cpf_invalido', { event_type: 'auth_failed', motivo: 'cpf_invalido', correlation_id: correlationId });
      return resposta(400, { message: 'CPF inválido.' }, correlationId);
    }

    const documento = normalizarCpf(cpf);
    const config = await carregarConfig();

    const cliente = await buscarCliente(documento, {
      baseUrl: config.osServiceUrl,
      token: config.internalToken,
      correlationId,
    });
    const recusa = recusaDoCliente(cliente);

    if (recusa) {
      logar('warning', recusa.motivo, { event_type: 'auth_failed', motivo: recusa.motivo, correlation_id: correlationId });
      return resposta(recusa.statusCode, { message: recusa.message }, correlationId);
    }

    const agora = Math.floor(Date.now() / 1000);

    const token = await new SignJWT({ cpf: documento, nome: cliente.nome })
      .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
      .setIssuer(config.issuer)
      .setSubject(String(cliente.id))
      .setIssuedAt(agora)
      .setExpirationTime(agora + config.ttlSegundos)
      .sign(new TextEncoder().encode(config.jwtSecret));

    logar('info', 'auth_success', {
      event_type: 'auth_success',
      cliente_id: cliente.id,
      correlation_id: correlationId,
      duration_ms: Date.now() - inicio,
    });

    return resposta(200, { token, token_type: 'Bearer', expires_in: config.ttlSegundos }, correlationId);
  } catch (erro) {
    logar('error', erro.message, {
      event_type: 'auth_error',
      exception_class: erro.name,
      correlation_id: correlationId,
      duration_ms: Date.now() - inicio,
    });
    return resposta(500, { message: 'Erro ao autenticar.' }, correlationId);
  }
}
