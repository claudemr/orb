/* ORB - 3D/physics/AI engine
   Copyright (C) 2015-2017 Claude

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>. */

module orb.input.inputsystem;

//todo: support roll on enum for StateEvent instead of just bool

public import orb.render.window;
public import std.typecons : BitFlags;
public import gfm.math.vector;
public import entitysysd;

import orb.utils.exception;
import derelict.sdl2.sdl;
import std.typecons : Tuple, tuple;


enum KeyCode : uint
{
    unknown = 0,

    A = 4,
    B = 5,
    C = 6,
    D = 7,
    E = 8,
    F = 9,
    G = 10,
    H = 11,
    I = 12,
    J = 13,
    K = 14,
    L = 15,
    M = 16,
    N = 17,
    O = 18,
    P = 19,
    Q = 20,
    R = 21,
    S = 22,
    T = 23,
    U = 24,
    V = 25,
    W = 26,
    X = 27,
    Y = 28,
    Z = 29,

    N1 = 30,
    N2 = 31,
    N3 = 32,
    N4 = 33,
    N5 = 34,
    N6 = 35,
    N7 = 36,
    N8 = 37,
    N9 = 38,
    N0 = 39,

    RETURN = 40,
    ESCAPE = 41,
    BACKSPACE = 42,
    TAB = 43,
    SPACE = 44,

    MINUS = 45,
    EQUALS = 46,
    LEFTBRACKET = 47,
    RIGHTBRACKET = 48,
    BACKSLASH = 49,
    NONUSHASH = 50,
    SEMICOLON = 51,
    APOSTROPHE = 52,
    GRAVE = 53,
    COMMA = 54,
    PERIOD = 55,
    SLASH = 56,

    CAPSLOCK = 57,

    F1 = 58,
    F2 = 59,
    F3 = 60,
    F4 = 61,
    F5 = 62,
    F6 = 63,
    F7 = 64,
    F8 = 65,
    F9 = 66,
    F10 = 67,
    F11 = 68,
    F12 = 69,

    PRINTSCREEN = 70,
    SCROLLLOCK = 71,
    PAUSE = 72,
    INSERT = 73,
    HOME = 74,
    PAGEUP = 75,
    DELETE = 76,
    END = 77,
    PAGEDOWN = 78,
    RIGHT = 79,
    LEFT = 80,
    DOWN = 81,
    UP = 82,

    NUMLOCKCLEAR = 83,
    KP_DIVIDE = 84,
    KP_MULTIPLY = 85,
    KP_MINUS = 86,
    KP_PLUS = 87,
    KP_ENTER = 88,
    KP_1 = 89,
    KP_2 = 90,
    KP_3 = 91,
    KP_4 = 92,
    KP_5 = 93,
    KP_6 = 94,
    KP_7 = 95,
    KP_8 = 96,
    KP_9 = 97,
    KP_0 = 98,
    KP_PERIOD = 99,

    NONUSBACKSLASH = 100,
    APPLICATION = 101,
    POWER = 102,
    KP_EQUALS = 103,
    F13 = 104,
    F14 = 105,
    F15 = 106,
    F16 = 107,
    F17 = 108,
    F18 = 109,
    F19 = 110,
    F20 = 111,
    F21 = 112,
    F22 = 113,
    F23 = 114,
    F24 = 115,
    EXECUTE = 116,
    HELP = 117,
    MENU = 118,
    SELECT = 119,
    STOP = 120,
    AGAIN = 121,
    UNDO = 122,
    CUT = 123,
    COPY = 124,
    PASTE = 125,
    FIND = 126,
    MUTE = 127,
    VOLUMEUP = 128,
    VOLUMEDOWN = 129,
    KP_COMMA = 133,
    KP_EQUALSAS400 = 134,

    INTERNATIONAL1 = 135,
    INTERNATIONAL2 = 136,
    INTERNATIONAL3 = 137,
    INTERNATIONAL4 = 138,
    INTERNATIONAL5 = 139,
    INTERNATIONAL6 = 140,
    INTERNATIONAL7 = 141,
    INTERNATIONAL8 = 142,
    INTERNATIONAL9 = 143,
    LANG1 = 144,
    LANG2 = 145,
    LANG3 = 146,
    LANG4 = 147,
    LANG5 = 148,
    LANG6 = 149,
    LANG7 = 150,
    LANG8 = 151,
    LANG9 = 152,

    ALTERASE = 153,
    SYSREQ = 154,
    CANCEL = 155,
    CLEAR = 156,
    PRIOR = 157,
    RETURN2 = 158,
    SEPARATOR = 159,
    OUT = 160,
    OPER = 161,
    CLEARAGAIN = 162,
    CRSEL = 163,
    EXSEL = 164,

    KP_00 = 176,
    KP_000 = 177,
    THOUSANDSSEPARATOR = 178,
    DECIMALSEPARATOR = 179,
    CURRENCYUNIT = 180,
    CURRENCYSUBUNIT = 181,
    KP_LEFTPAREN = 182,
    KP_RIGHTPAREN = 183,
    KP_LEFTBRACE = 184,
    KP_RIGHTBRACE = 185,
    KP_TAB = 186,
    KP_BACKSPACE = 187,
    KP_A = 188,
    KP_B = 189,
    KP_C = 190,
    KP_D = 191,
    KP_E = 192,
    KP_F = 193,
    KP_XOR = 194,
    KP_POWER = 195,
    KP_PERCENT = 196,
    KP_LESS = 197,
    KP_GREATER = 198,
    KP_AMPERSAND = 199,
    KP_DBLAMPERSAND = 200,
    KP_VERTICALBAR = 201,
    KP_DBLVERTICALBAR = 202,
    KP_COLON = 203,
    KP_HASH = 204,
    KP_SPACE = 205,
    KP_AT = 206,
    KP_EXCLAM = 207,
    KP_MEMSTORE = 208,
    KP_MEMRECALL = 209,
    KP_MEMCLEAR = 210,
    KP_MEMADD = 211,
    KP_MEMSUBTRACT = 212,
    KP_MEMMULTIPLY = 213,
    KP_MEMDIVIDE = 214,
    KP_PLUSMINUS = 215,
    KP_CLEAR = 216,
    KP_CLEARENTRY = 217,
    KP_BINARY = 218,
    KP_OCTAL = 219,
    KP_DECIMAL = 220,
    KP_HEXADECIMAL = 221,

    LCTRL = 224,
    LSHIFT = 225,
    LALT = 226,
    LGUI = 227,
    RCTRL = 228,
    RSHIFT = 229,
    RALT = 230,
    RGUI = 231,

    MODE = 257,

    AUDIONEXT = 258,
    AUDIOPREV = 259,
    AUDIOSTOP = 260,
    AUDIOPLAY = 261,
    AUDIOMUTE = 262,
    MEDIASELECT = 263,
    WWW = 264,
    MAIL = 265,
    CALCULATOR = 266,
    COMPUTER = 267,
    AC_SEARCH = 268,
    AC_HOME = 269,
    AC_BACK = 270,
    AC_FORWARD = 271,
    AC_STOP = 272,
    AC_REFRESH = 273,
    AC_BOOKMARKS = 274,

    BRIGHTNESSDOWN = 275,
    BRIGHTNESSUP = 276,
    DISPLAYSWITCH = 277,
    KBDILLUMTOGGLE = 278,
    KBDILLUMDOWN = 279,
    KBDILLUMUP = 280,
    EJECT = 281,
    SLEEP = 282,

    APP1 = 283,
    APP2 = 284,

    any = uint.max
}

enum MouseButton : uint
{
    unknown = 0,
    left   = 1 << 1,
    middle = 1 << 2,
    right  = 1 << 3,
    x1     = 1 << 4,
    x2     = 1 << 5
}

enum KbLayout
{
    unknown,
    qwerty,
    azerty,
    qwertz,
    colemak,
    dvorak,
    bepo
}

interface IKeyEvent
{
    void receive(KeyCode code,
                 bool pressed, bool repeat,
                 EventManager events, Duration dt);
}

interface IStateEvent
{
    void receive(KeyCode code, MouseButton button, bool state,
                 EventManager events, Duration dt);
}

interface IMouseButtonEvent
{
    void receive(MouseButton button,
                 bool pressed, int nbClicks, vec2i pos,
                 EventManager events, Duration dt);
}

interface IMouseMotionEvent
{
    void receive(vec2i pos, vec2i motion,
                 BitFlags!MouseButton buttonFlags,
                 EventManager events, Duration dt);
}


private auto toKeyCode(SDL_Scancode code)
{
    // it should do the trick
    return cast(KeyCode)code;
}

private auto toMouseButton(Uint8 button)
{
    // it should do the trick
    return cast(MouseButton)1UL << button;
}

private auto toBitFlagsMouseButton(Uint32 state)
{
    BitFlags!MouseButton bf;

    if (state & MouseButton.left)
        bf |= MouseButton.left;
    if (state & MouseButton.middle)
        bf |= MouseButton.middle;
    if (state & MouseButton.right)
        bf |= MouseButton.right;
    if (state & MouseButton.x1)
        bf |= MouseButton.x1;
    if (state & MouseButton.x2)
        bf |= MouseButton.x2;

    return bf;
}

class InputSystem : System
{
    this(Window win)
    {
        //todo not needed yet, but just make the window actually exist now
        enforceOrb(win !is null);
    }

    static @property KbLayout keyboardLayout()
    {
        static bool scanDone = false;
        static KbLayout layout;

        if (!scanDone)
        {
            // check SDL keyboard API
            import std.string;
            assert(SDL_GetScancodeFromName("A") == SDL_SCANCODE_A &&
                   SDL_SCANCODE_A == 4);
            assert(SDL_GetKeyFromName("A") == SDLK_a &&
                   SDLK_a == 'a' && 'a' == 97);
            assert(SDL_GetScancodeName(4).fromStringz == "A");
            assert(SDL_GetKeyName(97).fromStringz == "A");

            import std.algorithm;
            auto keys = [SDL_SCANCODE_Q, SDL_SCANCODE_W, SDL_SCANCODE_Y]
                        .map!(a => SDL_GetKeyFromScancode(a))
                        .map!(a => cast(char)a);

            if (equal(keys, "qwy"))
                layout = KbLayout.qwerty;
            else if (equal(keys, "azy"))
                layout = KbLayout.azerty;
            else if (equal(keys, "qwz"))
                layout = KbLayout.qwertz;
            else if (equal(keys, "qwj"))
                layout = KbLayout.colemak;
            else if (equal(keys, "q,f"))
                layout = KbLayout.dvorak;
            else if (equal(keys, "b\xe9y"))
                // SDL2 doesn't seem to map deadkey ^ and falls back to y
                layout = KbLayout.bepo; // bépo
            else
                layout = KbLayout.unknown;

            scanDone = true;
        }

        return layout;
    }

    static void setRelativeMouseMode(bool enabled)
    {
        SDL_SetRelativeMouseMode(enabled);
    }

    override void prepare(EntityManager es, EventManager events, Duration dt)
    {
        SDL_Event event;

        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
            case SDL_KEYDOWN:
            case SDL_KEYUP:
                KeyCode code = event.key.keysym.scancode.toKeyCode();

                auto keyPtr = code in mKeyEvents;
                if (keyPtr !is null)
                {
                    keyPtr.receive(code,
                                   event.key.state == SDL_PRESSED,
                                   cast(bool)event.key.repeat,
                                   events,
                                   dt);
                }
                else
                {
                    // Handle key-state
                    auto keyStatePtr = code in mKeyStateEvents;
                    if (keyStatePtr !is null)
                    {
                        auto statePtr = *keyStatePtr in mEventStates;
                        if (!statePtr.changing && event.type == SDL_KEYDOWN)
                        {
                            statePtr.val = !statePtr.val;
                            keyStatePtr.receive(code,
                                                MouseButton.unknown,
                                                statePtr.val,
                                                events,
                                                dt);
                            statePtr.changing = true;
                        }
                        else if (event.type == SDL_KEYUP)
                        {
                            statePtr.changing = false;
                        }
                    }
                }
                break;

            case SDL_MOUSEBUTTONDOWN:
            case SDL_MOUSEBUTTONUP:
                MouseButton button = event.button.button.toMouseButton();
                auto buttonPtr = button in mMouseButtonEvents;
                if (buttonPtr !is null)
                {
                    buttonPtr.receive(button,
                                      event.button.state == SDL_PRESSED,
                                      event.button.clicks,
                                      vec2i(event.button.x, event.button.y),
                                      events,
                                      dt);
                }
                else
                {
                    // Handle mouse-button-state
                    auto buttonStatePtr = button in mButtonStateEvents;
                    if (buttonStatePtr !is null)
                    {
                        auto statePtr = *buttonStatePtr in mEventStates;
                        if (!statePtr.changing &&
                            event.type == SDL_MOUSEBUTTONDOWN)
                        {
                            statePtr.val = !statePtr.val;
                            buttonStatePtr.receive(KeyCode.unknown,
                                                   button,
                                                   statePtr.val,
                                                   events,
                                                   dt);
                            statePtr.changing = true;
                        }
                        else if (event.type == SDL_MOUSEBUTTONUP)
                        {
                            statePtr.changing = false;
                        }
                    }
                }
                break;

            case SDL_MOUSEMOTION:
                if (mMouseMotionEvent !is null)
                    mMouseMotionEvent.receive(
                            vec2i(event.motion.x, event.motion.y),
                            vec2i(event.motion.xrel, event.motion.yrel),
                            event.motion.state.toBitFlagsMouseButton(),
                            events,
                            dt);
                break;

            default:
                break;
            }
        }
    }

    void bind(IKeyEvent event, KeyCode code)
    {
        enforceOrb(code !in mKeyStateEvents);
        auto eventPtr = code in mKeyEvents;
        if (eventPtr is null)
            mKeyEvents[code] = event;
        else
            *eventPtr = event;
    }

    void bind(IStateEvent event, KeyCode code, bool defaultState = false)
    {
        //todo it currently uses a bool, roll around state enum
        enforceOrb(code !in mKeyEvents);
        auto eventPtr = code in mKeyStateEvents;
        if (eventPtr is null)
            mKeyStateEvents[code] = event;
        else
            *eventPtr = event;

        auto statePtr = event in mEventStates;
        if (statePtr is null)
            mEventStates[event] = tuple(defaultState, defaultState, false, 1);
        else
            statePtr.nbCodes++;
    }

    void bind(IStateEvent event, MouseButton button, bool defaultState = false)
    {
        //todo it currently uses a bool, roll around state enum
        enforceOrb(button !in mMouseButtonEvents);
        auto eventPtr = button in mButtonStateEvents;
        if (eventPtr is null)
            mButtonStateEvents[button] = event;
        else
            *eventPtr = event;

        auto statePtr = event in mEventStates;
        if (statePtr is null)
            mEventStates[event] = tuple(defaultState, defaultState, false, 1);
        else
            statePtr.nbCodes++;
    }

    void bind(IMouseButtonEvent event, MouseButton button)
    {
        enforceOrb(button !in mButtonStateEvents);
        auto eventPtr = button in mMouseButtonEvents;
        if (eventPtr is null)
            mMouseButtonEvents[button] = event;
        else
            *eventPtr = event;
    }

    void bind(IMouseMotionEvent event)
    {
        mMouseMotionEvent = event;
    }

    void unbind(IKeyEvent event, KeyCode code)
    {
        enforceOrb(mKeyEvents[code] == event);
        mKeyEvents.remove(code);
    }

    void unbind(IStateEvent event, KeyCode code)
    {
        enforceOrb(mKeyStateEvents[code] == event);
        mKeyStateEvents.remove(code);

        auto statePtr = event in mEventStates;
        if (statePtr !is null)
        {
            statePtr.nbCodes--;
            if (statePtr.nbCodes == 0)
                mEventStates.remove(event);
        }
    }

    void unbind(IStateEvent event, MouseButton button)
    {
        enforceOrb(mButtonStateEvents[button] == event);
        mButtonStateEvents.remove(button);

        auto statePtr = event in mEventStates;
        if (statePtr !is null)
        {
            statePtr.nbCodes--;
            if (statePtr.nbCodes == 0)
                mEventStates.remove(event);
        }
    }

    void unbind(IMouseButtonEvent event, MouseButton button)
    {
        enforceOrb(mMouseButtonEvents[button] == event);
        mMouseButtonEvents.remove(button);
    }

    void unbind(IMouseMotionEvent event)
    {
        mMouseMotionEvent = null;
    }

    /**
     * Reset the state of the event to its default state.
     */
    void reset(IStateEvent event)
    {
        auto eventStatePtr = event in mEventStates;
        if (eventStatePtr !is null)
        {
            eventStatePtr.changing = false;
            eventStatePtr.val      = eventStatePtr.defaultVal;
        }
    }

    bool get(IStateEvent event)
    {
        auto eventStatePtr = event in mEventStates;
        if (eventStatePtr !is null)
            return eventStatePtr.val;
        return false;
    }

private:
    IKeyEvent[KeyCode]                      mKeyEvents;
    IStateEvent[KeyCode]                    mKeyStateEvents;
    IStateEvent[MouseButton]                mButtonStateEvents;
    Tuple!(bool, "val",
           bool, "defaultVal",
           bool, "changing",
           int,  "nbCodes")[IStateEvent]    mEventStates;
    IMouseButtonEvent[MouseButton]          mMouseButtonEvents;
    IMouseMotionEvent                       mMouseMotionEvent;
}
