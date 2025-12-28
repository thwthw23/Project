using System;
using System.Drawing;
using System.Windows.Forms;

namespace QuanLyCongViec.Helpers
{
    /// <summary>
    /// Helper class để set font Unicode cho các controls
    /// Đảm bảo tiếng Việt hiển thị đúng
    /// </summary>
    public static class FontHelper
    {
        /// <summary>
        /// Font mặc định hỗ trợ Unicode (tiếng Việt)
        /// Sử dụng font hệ thống hỗ trợ Unicode tốt nhất
        /// </summary>
        public static Font DefaultUnicodeFont = new Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point, ((byte)(0)));

        /// <summary>
        /// Font cho DataGridView hỗ trợ Unicode
        /// </summary>
        public static Font DataGridViewFont = new Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point, ((byte)(0)));

        /// <summary>
        /// Set font Unicode cho tất cả controls trong form
        /// </summary>
        /// <param name="form">Form cần set font</param>
        public static void SetUnicodeFont(Form form)
        {
            if (form == null) return;

            // Set font cho form
            form.Font = DefaultUnicodeFont;

            // Set font cho tất cả controls trong form
            SetUnicodeFontRecursive(form);
        }

        /// <summary>
        /// Set font Unicode cho control và tất cả controls con
        /// </summary>
        /// <param name="control">Control cần set font</param>
        private static void SetUnicodeFontRecursive(Control control)
        {
            if (control == null) return;

            // Set font cho control hiện tại (trừ DataGridView - sẽ set riêng)
            if (!(control is DataGridView))
            {
                control.Font = DefaultUnicodeFont;
            }
            else
            {
                // DataGridView cần set font riêng
                DataGridView dgv = control as DataGridView;
                dgv.Font = DataGridViewFont;
                dgv.DefaultCellStyle.Font = DataGridViewFont;
            }

            // Set font cho tất cả controls con
            foreach (Control child in control.Controls)
            {
                SetUnicodeFontRecursive(child);
            }
        }

        /// <summary>
        /// Set font Unicode cho DataGridView
        /// </summary>
        /// <param name="dataGridView">DataGridView cần set font</param>
        public static void SetUnicodeFontForDataGridView(DataGridView dataGridView)
        {
            if (dataGridView == null) return;

            dataGridView.Font = DataGridViewFont;
            dataGridView.DefaultCellStyle.Font = DataGridViewFont;
            dataGridView.ColumnHeadersDefaultCellStyle.Font = DataGridViewFont;
            dataGridView.RowHeadersDefaultCellStyle.Font = DataGridViewFont;
            
            // Đảm bảo DataGridView hỗ trợ Unicode
            dataGridView.DefaultCellStyle.FormatProvider = System.Globalization.CultureInfo.CurrentCulture;
            
            // Set encoding cho tất cả các cột
            foreach (DataGridViewColumn column in dataGridView.Columns)
            {
                column.DefaultCellStyle.Font = DataGridViewFont;
            }
        }
    }
}

