import { AuthService } from './auth.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { LoginDto, RefreshDto, ChangePasswordDto } from './dto/auth.dto';
export declare class AuthController {
    private authService;
    constructor(authService: AuthService);
    login(dto: LoginDto): Promise<{
        user: {
            id: string;
            nama: string;
            email: string;
            role: import(".prisma/client").$Enums.Role;
            tenant: {
                id: string;
                namaPondok: string;
                kodeTenant: string;
                status: import(".prisma/client").$Enums.TenantStatus;
            };
        };
        accessToken: string;
        refreshToken: string;
    }>;
    refresh(dto: RefreshDto): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    changePassword(user: RequestUser, dto: ChangePasswordDto): Promise<{
        message: string;
    }>;
}
