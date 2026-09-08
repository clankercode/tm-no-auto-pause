// Keep Trackmania Turbo running when the window loses focus.
//
// WndProc writes DAT_01b51258 / DAT_01c0b480. WinMain then takes the unfocused
// yield path, and App_NotifyWindowFocus(0) vtable-pauses (menu + race clock).
// Update() cannot undo that: once paused it never runs. Patch the pause and
// WinMain checks; leave hasFocus as WndProc wrote it so we can log transitions.
// research/turbo/2026-09-08-Turbo-Unfocus-Pause.md

#if TURBO

const uint64 RVA_NotifyWindowFocus   = 0x0F1FD0;
const uint64 RVA_IsInactivePredicate = 0xCD6E40;
const uint64 RVA_WindowHasFocus      = 0x1751258;
const uint64 RVA_WindowInactive      = 0x180B480;
const uint64 RVA_CmdBuffer           = 0x17F1C68;

const string NotifyFocus_Prologue = "83 B9 90 08 00 00 00";
const uint16 NotifyFocus_JzOff = 0x2D;
const string NotifyFocus_JzOrig = "74 0E";
const string NotifyFocus_JzNew  = "74 2A";

const string Inactive_Orig = "83 3D 80 B4 C0 01 00";
const string Inactive_New  = "31 C0 C3 90 90 90 90";

const uint64 RVA_KillFocusInactive = 0x455989;
const string KillFocusInactive_Orig = "C7 05 80 B4 C0 01 01 00 00 00";
const string KillFocusInactive_New  = "C7 05 80 B4 C0 01 00 00 00 00";

const uint64 RVA_ActivateSetz = 0x4558AA;
const string ActivateSetz_Orig = "0F 94 C0";
const string ActivateSetz_New  = "90 90 90";

const uint64 RVA_IsIconicCall = 0x455591;
const string IsIconicCall_Orig = "FF 15 E0 34 6A 01";
const string IsIconicCall_New  = "31 C0 90 90 90 90";

// WinMain: always take the focused branch (CMP [inactive],0 ...)
const uint64 RVA_WinMain1 = 0x454F57;
const string WinMain1_Orig = "83 3D 80 B4 C0 01 00";
const string WinMain1_New  = "EB 1B 90 90 90 90 90"; // JMP 0x00854F74

const uint64 RVA_WinMain2 = 0x454FAE;
const string WinMain2_Orig = "83 3D 80 B4 C0 01 00";
const string WinMain2_New  = "EB 1A 90 90 90 90 90"; // JMP 0x00854FCA

const uint64 RVA_WinMain3 = 0x454FFB;
const string WinMain3_Orig = "83 3D 80 B4 C0 01 00";
const string WinMain3_New  = "EB 34 90 90 90 90 90"; // JMP 0x00855031

#else

const uint64 RVA_NotifyWindowFocus = 0;
const uint64 RVA_IsInactivePredicate = 0;
const uint64 RVA_WindowHasFocus = 0;
const uint64 RVA_WindowInactive = 0;
const uint64 RVA_CmdBuffer = 0;

#endif

[Setting category="General" name="Keep running when unfocused"]
bool S_Enabled = true;

string g_status = "not installed";
bool g_applied = false;

string HexAt(uint64 ptr, uint n) {
    string s = "";
    for (uint i = 0; i < n; i++) {
        if (i > 0) s += " ";
        s += Text::Format("%02X", Dev::ReadUInt8(ptr + i));
    }
    return s;
}

uint ByteLen(const string &in hex) {
    return (hex.Trim().Length + 1) / 3;
}

class PatchSite {
    uint64 rva;
    string orig;
    string neu;
    string saved;
    bool on;

    PatchSite(uint64 rva, const string &in orig, const string &in neu) {
        this.rva = rva;
        this.orig = orig;
        this.neu = neu;
    }

    bool Apply() {
        if (on) return true;
        uint64 p = Dev::BaseAddress() + rva;
        string have = HexAt(p, ByteLen(orig));
        if (have != orig) {
            g_status = "mismatch at " + Text::FormatPointer(p) + " have " + have;
            warn("No Auto-Pause: " + g_status);
            return false;
        }
        saved = Dev::Patch(p, neu);
        on = true;
        return true;
    }

    void Unapply() {
        if (!on) return;
        Dev::Patch(Dev::BaseAddress() + rva, saved);
        on = false;
    }
}

#if TURBO
PatchSite@[] g_sites;
#endif

void Main() {
#if TURBO
    if (S_Enabled) Install();
#else
    g_status = "Turbo only - this game has no patch";
    warn("No Auto-Pause: Trackmania Turbo only.");
#endif
}

void OnDestroyed() {
#if TURBO
    Uninstall();
#endif
}
void OnDisabled() {
#if TURBO
    Uninstall();
#endif
}

bool g_haveLast = false;
bool g_lastFocus = true;
bool g_lastPaused = false;
uint g_lastNow = 0;
uint g_stall = 0;
uint g_nowAtFocusLog = 0;
const uint StallFrames = 20;

void Update(float dt) {
#if TURBO
    if (S_Enabled != g_applied) {
        if (S_Enabled) Install();
        else Uninstall();
    }
    LogTransitions();
#endif
}

void RenderMenu() {
    if (UI::MenuItem("\\$8f8" + Icons::Play + "\\$z No Auto-Pause", "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}

void LogTransitions() {
#if TURBO
    uint64 base = Dev::BaseAddress();
    bool focus = true;
    bool cmdPaused = false;
    try { focus = Dev::ReadUInt32(base + RVA_WindowHasFocus) != 0; } catch { }
    try { cmdPaused = Dev::ReadUInt32(base + RVA_CmdBuffer + 0x40) == 0; } catch { }

    uint now = 0;
    bool inRace = false;
    auto app = GetApp();
    if (app !is null) {
        auto rules = cast<CTrackManiaRaceRules>(app.PlaygroundScript);
        if (rules !is null) {
            now = rules.Now;
            inRace = now > 0;
        }
    }
    if (inRace) {
        if (now == g_lastNow) g_stall++;
        else g_stall = 0;
        g_lastNow = now;
    } else {
        g_stall = 0;
    }
    // cmdbuffer+0x40 missed the 13:50 Now=1032155 freeze (paused=no while clock flat).
    bool paused = cmdPaused || (inRace && g_stall >= StallFrames);

    if (!g_haveLast) {
        g_lastFocus = focus;
        g_lastPaused = paused;
        g_nowAtFocusLog = now;
        g_haveLast = true;
        trace("No Auto-Pause: initial focus=" + (focus ? "yes" : "no")
            + " paused=" + (paused ? "yes" : "no") + " Now=" + now);
        return;
    }
    if (focus != g_lastFocus) {
        string dNow = now >= g_nowAtFocusLog
            ? ("+" + (now - g_nowAtFocusLog))
            : ("-" + (g_nowAtFocusLog - now));
        trace("No Auto-Pause: focus " + (focus ? "gained" : "lost")
            + " paused=" + (paused ? "yes" : "no") + " Now=" + now + " dNow=" + dNow);
        g_nowAtFocusLog = now;
        g_lastFocus = focus;
    }
    if (paused != g_lastPaused) {
        trace("No Auto-Pause: pause " + (paused ? "started" : "ended")
            + " focus=" + (focus ? "yes" : "no") + " Now=" + now);
        g_lastPaused = paused;
    }
#endif
}

#if TURBO

void BuildSites() {
    g_sites.RemoveRange(0, g_sites.Length);
    g_sites.InsertLast(PatchSite(RVA_NotifyWindowFocus + NotifyFocus_JzOff, NotifyFocus_JzOrig, NotifyFocus_JzNew));
    g_sites.InsertLast(PatchSite(RVA_IsInactivePredicate, Inactive_Orig, Inactive_New));
    g_sites.InsertLast(PatchSite(RVA_KillFocusInactive, KillFocusInactive_Orig, KillFocusInactive_New));
    g_sites.InsertLast(PatchSite(RVA_ActivateSetz, ActivateSetz_Orig, ActivateSetz_New));
    g_sites.InsertLast(PatchSite(RVA_IsIconicCall, IsIconicCall_Orig, IsIconicCall_New));
    g_sites.InsertLast(PatchSite(RVA_WinMain1, WinMain1_Orig, WinMain1_New));
    g_sites.InsertLast(PatchSite(RVA_WinMain2, WinMain2_Orig, WinMain2_New));
    g_sites.InsertLast(PatchSite(RVA_WinMain3, WinMain3_Orig, WinMain3_New));
}

bool Install() {
    if (g_applied) return true;
    uint64 base = Dev::BaseAddress();
    string haveN = HexAt(base + RVA_NotifyWindowFocus, ByteLen(NotifyFocus_Prologue));
    if (haveN != NotifyFocus_Prologue) {
        g_status = "notify prologue mismatch (" + haveN + ")";
        warn("No Auto-Pause: " + g_status);
        return false;
    }
    BuildSites();
    for (uint i = 0; i < g_sites.Length; i++) {
        if (!g_sites[i].Apply()) {
            for (uint j = 0; j <= i; j++) g_sites[j].Unapply();
            return false;
        }
    }
    g_applied = true;
    g_status = "patched";
    trace("No Auto-Pause: patched " + g_sites.Length + " sites");
    return true;
}

void Uninstall() {
    if (!g_applied) return;
    for (int i = int(g_sites.Length) - 1; i >= 0; i--) g_sites[i].Unapply();
    g_applied = false;
    g_status = "uninstalled";
    g_haveLast = false;
    g_stall = 0;
    trace("No Auto-Pause: restored original bytes");
}

#endif
