const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const rows = await prisma.$queryRaw`
    SELECT ujianId, santriId, COUNT(*) AS jumlah
    FROM remedials
    GROUP BY ujianId, santriId
    HAVING COUNT(*) > 1
  `;
  console.log(rows);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());