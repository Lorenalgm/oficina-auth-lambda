/**
 * Decide se o cliente encontrado pode receber token. Separado do handler para
 * ser testado sem banco.
 */
export function recusaDoCliente(cliente) {
  if (!cliente) {
    return { statusCode: 404, motivo: 'cliente_nao_encontrado', message: 'Cliente não encontrado.' };
  }
  if (cliente.ativo === false) {
    return { statusCode: 403, motivo: 'cliente_inativo', message: 'Cliente inativo.' };
  }
  return null;
}
