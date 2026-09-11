export declare class LoginDto {
    kodeTenant?: string;
    email: string;
    password: string;
}
export declare class RefreshDto {
    refreshToken: string;
}
export declare class ChangePasswordDto {
    currentPassword: string;
    newPassword: string;
}
