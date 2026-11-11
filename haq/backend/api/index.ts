import { NestFactory } from '@nestjs/core';
import { ExpressAdapter } from '@nestjs/platform-express';
import { ValidationPipe } from '@nestjs/common';
import express, { json, urlencoded } from 'express';
import { AppModule } from '../src/app.module';

const server = express();
let ready: Promise<void> | null = null;

async function bootstrap() {
  const app = await NestFactory.create(AppModule, new ExpressAdapter(server));

  app.use(json({ limit: '15mb' }));
  app.use(urlencoded({ extended: true, limit: '15mb' }));
  app.enableCors();
  app.setGlobalPrefix('api');
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, transform: true, stopAtFirstError: true }),
  );

  await app.init();
}

export default async function handler(req: any, res: any) {
  ready ??= bootstrap();
  await ready;
  server(req, res);
}