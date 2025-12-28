using System;

namespace QuanLyCongViec.Helpers
{
    /// <summary>
    /// Helper class để xử lý mật khẩu
    /// LƯU Ý: Không hash password, lưu dạng plain text (chỉ dùng cho development/test)
    /// </summary>
    public static class PasswordHelper
    {
        /// <summary>
        /// Trả về mật khẩu gốc (không hash)
        /// </summary>
        /// <param name="password">Mật khẩu cần xử lý</param>
        /// <returns>Mật khẩu gốc</returns>
        public static string HashPassword(string password)
        {
            if (string.IsNullOrWhiteSpace(password))
            {
                throw new ArgumentException("Mật khẩu không được để trống", nameof(password));
            }

            // Trả về password gốc, không hash
            return password;
        }

        /// <summary>
        /// Verify mật khẩu có khớp không (so sánh trực tiếp)
        /// </summary>
        /// <param name="password">Mật khẩu cần kiểm tra</param>
        /// <param name="storedPassword">Mật khẩu đã lưu trong database</param>
        /// <returns>True nếu mật khẩu khớp</returns>
        public static bool VerifyPassword(string password, string storedPassword)
        {
            if (string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(storedPassword))
            {
                return false;
            }

            // So sánh trực tiếp, không hash
            return password.Equals(storedPassword, StringComparison.OrdinalIgnoreCase);
        }
    }
}

