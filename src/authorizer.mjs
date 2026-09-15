import { jwtVerify } from 'jose';
import { carregarConfig } from './config.mjs';

const NEGAR = { isAuthorized: false };

/**
 * Lambda Authorizer do API Gateway (payload format 2.0, simple response).
 * Barra o tráfego antes de ele chegar ao cluster; a oficina-api revalida o
 * mesmo token como defesa em profundidade.
 */
export async function handler(event) {
  const header = event.headers?.authorization ?? event.headers?.Authorization ?? '';
  const [esquema, token] = header.split(' ');

  if (esquema !== 'Bearer' || !token) {
    return NEGAR;
  }

  try {
    const config = await carregarConfig();

    const { payload } = await jwtVerify(token, new TextEncoder().encode(config.jwtSecret), {
      algorithms: ['HS256'],
      issuer: config.issuer,
      clockTolerance: 30,
    });

    return {
      isAuthorized: true,
      context: { clienteId: payload.sub, cpf: payload.cpf },
    };
  } catch {
    return NEGAR;
  }
}
