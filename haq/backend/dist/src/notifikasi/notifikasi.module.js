"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotifikasiModule = void 0;
const common_1 = require("@nestjs/common");
const notifikasi_service_1 = require("./notifikasi.service");
const notifikasi_controller_1 = require("./notifikasi.controller");
let NotifikasiModule = class NotifikasiModule {
};
exports.NotifikasiModule = NotifikasiModule;
exports.NotifikasiModule = NotifikasiModule = __decorate([
    (0, common_1.Module)({
        controllers: [notifikasi_controller_1.NotifikasiController],
        providers: [notifikasi_service_1.NotifikasiService],
        exports: [notifikasi_service_1.NotifikasiService],
    })
], NotifikasiModule);
//# sourceMappingURL=notifikasi.module.js.map