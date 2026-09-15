/**
 * Validação de CPF equivalente à do Value Object Domain\Shared\ValueObjects\Documento
 * da oficina-api. As duas implementações precisam concordar: o cliente que é
 * aceito aqui tem de ser o mesmo que a API reconhece.
 */

export function normalizarCpf(valor) {
  return String(valor ?? '').replace(/\D/g, '');
}

export function cpfValido(valor) {
  const cpf = normalizarCpf(valor);

  if (cpf.length !== 11 || /^(\d)\1{10}$/.test(cpf)) {
    return false;
  }

  const digito = (ate) => {
    let soma = 0;
    for (let i = 0; i < ate; i++) {
      soma += Number(cpf[i]) * (ate + 1 - i);
    }
    const resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  };

  return Number(cpf[9]) === digito(9) && Number(cpf[10]) === digito(10);
}
