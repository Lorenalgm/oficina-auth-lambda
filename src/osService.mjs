export async function buscarCliente(documento, { baseUrl, token, correlationId, fetchFn = fetch }) {
  const resposta = await fetchFn(`${baseUrl}/internal/clientes/por-documento/${documento}`, {
    headers: { Accept: 'application/json', 'X-Internal-Token': token, 'X-Request-Id': correlationId },
    signal: AbortSignal.timeout(3000),
  });

  if (resposta.status === 404) {
    return undefined;
  }
  if (!resposta.ok) {
    throw new Error(`OS Service respondeu ${resposta.status} na consulta do cliente.`);
  }

  return (await resposta.json()).data;
}
