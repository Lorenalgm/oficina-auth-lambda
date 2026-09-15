import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const secrets = new SecretsManagerClient({});

// Cache entre invocações: o container da Lambda é reaproveitado, então só a
// primeira chamada de cada container paga a ida ao Secrets Manager.
let cache = null;

export async function carregarConfig() {
  if (cache) {
    return cache;
  }

  const arn = process.env.SECRET_ARN;

  if (!arn) {
    throw new Error('SECRET_ARN não configurado.');
  }

  const resposta = await secrets.send(new GetSecretValueCommand({ SecretId: arn }));
  const segredo = JSON.parse(resposta.SecretString);

  cache = {
    jwtSecret: segredo.JWT_SECRET,
    issuer: process.env.JWT_ISSUER ?? 'oficina-auth',
    ttlSegundos: Number(process.env.JWT_TTL_SECONDS ?? 3600),
    db: {
      host: segredo.DB_HOST,
      port: Number(segredo.DB_PORT ?? 5432),
      database: segredo.DB_DATABASE,
      user: segredo.DB_USERNAME,
      password: segredo.DB_PASSWORD,
      ssl: { rejectUnauthorized: false },
      connectionTimeoutMillis: 5000,
    },
  };

  return cache;
}
