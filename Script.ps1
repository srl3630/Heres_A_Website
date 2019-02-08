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


# Start the app
app='microsoft-edge'
value='http://www.hackertyper.com/'
$startString = $app + ":" + $value
start $startString

# Wait and send key stroke 
sleep 2
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

Disable-UserInput -seconds 4 | Out-Null

