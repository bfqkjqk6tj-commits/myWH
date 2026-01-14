Add-Type @"
using System;
using System.Windows.Forms;
using System.Drawing;

public class KeyStateNotify : Form
{
    private NotifyIcon notifyIcon;
    private Timer timer;

    public KeyStateNotify()
    {
        // 隐藏主窗体
        this.ShowInTaskbar = false;
        this.WindowState = FormWindowState.Minimized;

        notifyIcon = new NotifyIcon();
        notifyIcon.Text = "键盘状态监控";
        notifyIcon.Visible = true;

        // 定时器检测状态
        timer = new Timer();
        timer.Interval = 200;
        timer.Tick += Timer_Tick;
        timer.Start();

        // 右键退出菜单
        ContextMenuStrip contextMenu = new ContextMenuStrip();
        ToolStripMenuItem exitItem = new ToolStripMenuItem("退出");
        exitItem.Click += (s, e) => { Application.Exit(); };
        contextMenu.Items.Add(exitItem);
        notifyIcon.ContextMenuStrip = contextMenu;
    }

    private void Timer_Tick(object sender, EventArgs e)
    {
        // 检测NumLock和CapsLock状态
        bool isNumLockOn = Control.IsKeyLocked(Keys.NumLock);
        bool isCapsLockOn = Control.IsKeyLocked(Keys.CapsLock);

        // 生成对应图标
        notifyIcon.Icon = CreateKeyIcon(isNumLockOn, isCapsLockOn);
        // 拼接提示文本（纯英文+数字避免编码问题，也可直接用中文）
        notifyIcon.Text = string.Format("NumLock: {0}\nCapsLock: {1}",
            isNumLockOn ? "On" : "Off",
            isCapsLockOn ? "大写" : "小写");
    }

    // 生成带颜色和字母的图标
    private Icon CreateKeyIcon(bool numLockOn, bool capsLockOn)
    {
        Bitmap bmp = new Bitmap(16, 16);
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
            // NumLock背景色：绿色=开启，红色=关闭
            using (SolidBrush bgBrush = new SolidBrush(numLockOn ? Color.Green : Color.Red))
            {
                g.FillEllipse(bgBrush, 2, 2, 12, 12);
            }
            // CapsLock显示A/a
            string displayChar = capsLockOn ? "A" : "a";
            using (Font font = new Font("Arial", 8, FontStyle.Bold))
            using (SolidBrush textBrush = new SolidBrush(Color.Black))
            {
                StringFormat sf = new StringFormat();
                sf.Alignment = StringAlignment.Center;
                sf.LineAlignment = StringAlignment.Center;
                g.DrawString(displayChar, font, textBrush, new Rectangle(0, 0, 16, 16), sf);
            }
        }
        return Icon.FromHandle(bmp.GetHicon());
    }

    // 释放资源
    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            if (timer != null) timer.Dispose();
            if (notifyIcon != null) notifyIcon.Dispose();
        }
        base.Dispose(disposing);
    }

    [STAThread]
    public static void Main()
    {
        // 修正渲染顺序，避免启动报错
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new KeyStateNotify());
    }
}
"@ -ReferencedAssemblies System.Windows.Forms, System.Drawing

# 强制隐藏PowerShell窗口（静默运行）
$windowCode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncWindow = Add-Type -MemberDefinition $windowCode -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
$null = $asyncWindow::ShowWindowAsync((Get-Process -Id $PID).MainWindowHandle, 0)

# 启动程序
[KeyStateNotify]::Main()