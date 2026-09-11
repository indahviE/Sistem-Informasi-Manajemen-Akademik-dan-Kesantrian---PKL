"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CreateTahunAjaranDto = exports.UpdateMapelDto = exports.CreateMapelDto = exports.UpdateKelasDto = exports.CreateKelasDto = exports.UpdateUstadzDto = exports.CreateUstadzDto = void 0;
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
class CreateUstadzDto {
}
exports.CreateUstadzDto = CreateUstadzDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateUstadzDto.prototype, "nama", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.JenisUstadz, { message: 'Jenis harus GURU atau MUSYRIF' }),
    __metadata("design:type", String)
], CreateUstadzDto.prototype, "jenis", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateUstadzDto.prototype, "noHp", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateUstadzDto.prototype, "userId", void 0);
class UpdateUstadzDto {
}
exports.UpdateUstadzDto = UpdateUstadzDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUstadzDto.prototype, "nama", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(client_1.JenisUstadz),
    __metadata("design:type", String)
], UpdateUstadzDto.prototype, "jenis", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUstadzDto.prototype, "noHp", void 0);
class CreateKelasDto {
}
exports.CreateKelasDto = CreateKelasDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateKelasDto.prototype, "namaKelas", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateKelasDto.prototype, "tingkat", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateKelasDto.prototype, "waliKelasId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateKelasDto.prototype, "tahunAjaranId", void 0);
class UpdateKelasDto {
}
exports.UpdateKelasDto = UpdateKelasDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateKelasDto.prototype, "namaKelas", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateKelasDto.prototype, "tingkat", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateKelasDto.prototype, "waliKelasId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateKelasDto.prototype, "tahunAjaranId", void 0);
class CreateMapelDto {
}
exports.CreateMapelDto = CreateMapelDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateMapelDto.prototype, "namaMapel", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateMapelDto.prototype, "kode", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateMapelDto.prototype, "jenis", void 0);
class UpdateMapelDto {
}
exports.UpdateMapelDto = UpdateMapelDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateMapelDto.prototype, "namaMapel", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateMapelDto.prototype, "kode", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateMapelDto.prototype, "jenis", void 0);
class CreateTahunAjaranDto {
}
exports.CreateTahunAjaranDto = CreateTahunAjaranDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateTahunAjaranDto.prototype, "nama", void 0);
//# sourceMappingURL=master.dto.js.map