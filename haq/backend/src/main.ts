import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Dinaikkan dari 5mb -> 15mb: body PPDB sekarang bisa bawa sampai
  // 3 berkas base64 sekaligus (foto, KK, akta).
  app.use(json({ limit: '15mb' }));
  app.use(urlencoded({ extended: true, limit: '15mb' }));
  app.enableCors();
  app.setGlobalPrefix('api');
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, transform: true, stopAtFirstError: true }),
  );

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`API berjalan di http://localhost:${port}/api`);
}
bootstrap();