"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AkademikModule = void 0;
const common_1 = require("@nestjs/common");
const akademik_service_1 = require("./akademik.service");
const akademik_controller_1 = require("./akademik.controller");
let AkademikModule = class AkademikModule {
};
exports.AkademikModule = AkademikModule;
exports.AkademikModule = AkademikModule = __decorate([
    (0, common_1.Module)({
        controllers: [akademik_controller_1.AkademikController],
        providers: [akademik_service_1.AkademikService],
        exports: [akademik_service_1.AkademikService],
    })
], AkademikModule);
//# sourceMappingURL=akademik.module.js.map