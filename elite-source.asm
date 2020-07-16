\ ******************************************************************************
\ ELITE GAME SOURCE
\ ******************************************************************************

INCLUDE "elite-header.h.asm"

_REMOVE_COMMANDER_CHECK = TRUE AND _REMOVE_CHECKSUMS
_ENABLE_MAX_COMMANDER   = TRUE AND _REMOVE_CHECKSUMS

GUARD &6000             ; Screen buffer starts here

\ ******************************************************************************
\ Configuration variables
\ ******************************************************************************

NOST = 18               ; Maximum number of stardust particles

NOSH = 12               ; Maximum number of ships at any one time (counting
                        ; from 0, so there are actually 13 ship slots)

COPS = 2                ; Viper
MAM = 3                 ; Mamba
THG = 6                 ; Thargoid
CYL = 7                 ; Cobra Mk III
SST = 8                 ; Space station
MSL = 9                 ; Missile
AST = 10                ; Asteroid
OIL = 11                ; Cargo canister
TGL = 12                ; Thargon
ESC = 13                ; Escape Pod

POW = 15                ; Pulse laser power

NI% = 36                ; Number of bytes for each object in our universe (as
                        ; stored in INWK and pointed to by UNIV)

\ ******************************************************************************
\ MOS definitions
\ ******************************************************************************

OSBYTE = &FFF4
OSWORD = &FFF1
OSFILE = &FFDD

SHEILA = &FE00

VSCAN  = 57             ; Defines the split position in the split screen mode

VEC    = &7FFE          ; Set to the original IRQ1 vector by elite-loader.asm

SVN    = &7FFD          ; Set to 1 while we are saving a commander, 0 otherwise

X = 128                 ; Centre coordinates of the 256 x 192 mode 4 space view
Y = 96

\ ******************************************************************************
\ Function key numbers
\ ******************************************************************************

f0 = &20
f1 = &71
f2 = &72
f3 = &73
f4 = &14
f5 = &74
f6 = &75
f7 = &16
f8 = &76
f9 = &77

\ ******************************************************************************
\ Macro definitions
\ ******************************************************************************

MACRO CHAR x
  EQUB x EOR 35         ; Insert ASCII character "x"
ENDMACRO

MACRO TWOK n
  EQUB n EOR 35         ; Insert two-letter token <n>
ENDMACRO

MACRO CTRL n
  EQUB n EOR 35         ; Insert control code token {n}
ENDMACRO

MACRO RTOK n
  IF n >= 0 AND n <= 95
    t = n + 160         ; Insert recursive token [n]
  ELIF n >= 128         ;
    t = n - 114         ; Tokens 0-95 get stored as n + 160
  ELSE                  ; Tokens 128-145 get stored as n - 114
    t = n               ; Tokens 96-127 get stored as n
  ENDIF
  EQUB t EOR 35
ENDMACRO

MACRO ITEM price, factor, units, quantity, mask
  IF factor < 0
    s = 1 << 7          ; Insert an item into the market prices table at QQ23
  ELSE                  ;
    s = 0               ; Arguments:
  ENDIF                 ;
  IF units == 't'       ;   price = Base price
    u = 0               ;   factor = Economic factor
  ELIF units == 'k'     ;   units = "t", "g" or "k"
    u = 1 << 5          ;   quantity = Base quantity
  ELSE                  ;   mask = Fluctutaions mask
    u = 1 << 6          ;
  ENDIF                 ; See location QQ23 for details of how the above data
  e = ABS(factor)       ; is stored in the table
  EQUB price
  EQUB s + u + e
  EQUB quantity
  EQUB mask
ENDMACRO

\ ******************************************************************************
\ Zero page workspace ZP at &0000 - &00B0
\ ******************************************************************************

ORG &0000

.ZP                     ; Zero page workspace

.RAND

 SKIP 4                 ; Random number seeds, four 8-bit numbers

.TRTB%

 SKIP 2                 ; Set by elite-loader.asm to point to the MOS key
                        ; translation table, used to translate internal key
                        ; values to ASCII

.T1

 SKIP 1                 ; Temporary storage, used quite a lot

.SC

 SKIP 1                 ; Screen address (low byte)

.SCH

 SKIP 1                 ; Screen address (high byte)

.XX16

 SKIP 18                ; 

.P

 SKIP 3                 ; Temporary storage for a memory pointer (e.g. used in
                        ; TT26 to store the address of character definitions)

.XX0

 SKIP 2                 ; Stores address of ship blueprint in NWSHP

.INF

 SKIP 2                 ; Stores address of new ship data block when adding a
                        ; new ship

.V

 SKIP 2                 ;

.XX

 SKIP 2                 ;

.YY

 SKIP 2                 ;

.SUNX

 SKIP 2                 ;

.BETA

 SKIP 1                 ; Pitch rate, reduced from the dashboard indicator
                        ; value in JSTY, with the sign flipped

.BET1

 SKIP 1                 ;

.XC

 SKIP 1                 ; Contains the x-coordinate of the text cursor (i.e.
                        ; the text column), from 0 to 32
                        ;
                        ; A value of 0 denotes the leftmost column and 32 the
                        ; rightmost column, but because the top part of the
                        ; screen (the mode 4 part) has a box border that
                        ; clashes with columns 0 amd 32, text is only shown
                        ; at columns 1-31


.YC

 SKIP 1                 ; Contains the y-coordinate of the text cursor (i.e.
                        ; the text row), from 0 to 23
                        ;
                        ; A value of 0 denotes the top row, but because the
                        ; top part of the screen has a box border that clashes
                        ; with row 0, text is always shown at row 1 or greater

.QQ22

 SKIP 2                 ; Hyperspace countdown counters
                        ;
                        ; Before a hyperspace jump, both QQ22 and QQ22+1 are
                        ; set to 15.
                        ;
                        ; QQ22 is an internal counter that counts down by 1
                        ; each time TT102 is called, which happens every
                        ; iteration of the main game loop. When it reaches
                        ; zero, the on-screen counter in QQ22+1 gets
                        ; decremented, and QQ22 gets set to 5 and the countdown
                        ; continues (so the first tick of the hyperspace counter
                        ; takes 15 iterations to happen, but subsequent ticks
                        ; take 5 iterations each).
                        ;
                        ; QQ22+1 contains the number that's shown on-screen
                        ; during countdown. It counts down from 15 to 1, and
                        ; when it hits 0, the hyperspace engines kick in.

.ECMA

 SKIP 1                 ; E.C.M. countdown timer (can be either our E.C.M.
                        ; or an opponent's)
                        ;
                        ; 0 is off, non-zero is on and counting down

.XX15                   ; 6-byte storage from XX15 TO XX15+5

.X1

 SKIP 1                 ; Temporary storage for coordinates in line-drawing
                        ; routines

.Y1

 SKIP 1                 ; Temporary storage for coordinates in line-drawing
                        ; routines

.X2

 SKIP 1                 ; Temporary storage for coordinates in line-drawing
                        ; routines

.Y2

 SKIP 1                 ; Temporary storage for coordinates in line-drawing
                        ; routines

 SKIP 2                 ; Last 2 bytes of XX15

.XX12

 SKIP 6                 ; 

.K

 SKIP 4                 ; Temporary storage, used all over the place

.KL

 SKIP 1                 ; If a key is being pressed that is not in the keyboard
                        ; table at KYTB, it can be stored here (as seen in
                        ; routine DK4, for example)

                        ; The following bytes implement a key logger that
                        ; enables Elite to scan for concurrent key presses of
                        ; all the flight keys (so this effectively implements
                        ; a 15-key rollover for the flight keys listed in the
                        ; keyboard table at KYTB, enabling players to roll,
                        ; pitch, change speed and fire lasers at the same, all
                        ; while targeting missiles and setting off their E.C.M.
                        ; and energy bomb, without the keyboard ignoring them).
                        ; The various keyboard canning routines, such as the one
                        ; at DKS1, can set the relevant byte in this table to
                        ; &FF to denote that that particular key is being
                        ; pressed. The logger is cleared to zero (no keys are
                        ; being pressed) by the U% routine.

.KY1

 SKIP 1                 ; ? key pressed (0 = no, non-zero = yes)

.KY2

 SKIP 1                 ; Space key pressed (0 = no, non-zero = yes)

.KY3

 SKIP 1                 ; < key pressed (0 = no, non-zero = yes)

.KY4

 SKIP 1                 ; > key pressed (0 = no, non-zero = yes)

.KY5

 SKIP 1                 ; X key pressed (0 = no, non-zero = yes)

.KY6

 SKIP 1                 ; S key pressed (0 = no, non-zero = yes)

.KY7

 SKIP 1                 ; A key pressed (0 = no, non-zero = yes)
                        ; Also, joystick fire button pressed

.KY12

 SKIP 1                 ; Tab key pressed (0 = no, non-zero = yes)

.KY13

 SKIP 1                 ; Escape key pressed (0 = no, non-zero = yes)

.KY14

 SKIP 1                 ; T key pressed (0 = no, non-zero = yes)

.KY15

 SKIP 1                 ; U key pressed (0 = no, non-zero = yes)

.KY16

 SKIP 1                 ; M key pressed (0 = no, non-zero = yes)

.KY17

 SKIP 1                 ; E key pressed (0 = no, non-zero = yes)

.KY18

 SKIP 1                 ; J key pressed (0 = no, non-zero = yes)

.KY19

 SKIP 1                 ; C key pressed (0 = no, non-zero = yes)

.LAS

 SKIP 1                 ; Bits 0-6 of the laser power of the current space view
                        ; (bit 7 doesn't denote laser power, just whether or
                        ; not the laser pulses)

.MSTG

 SKIP 1                 ; Missile lock target
                        ; 
                        ; &FF = no target, otherwise contains the number of the
                        ; ship in the missile lock

.XX1
 
.INWK

 SKIP 33                ; Workspace for a ship
                        ;
                        ; x-coordinate = (INWK+1 INWK+0), sign in INWK+2
                        ; y-coordinate = (INWK+4 INWK+3), sign in INWK+5
                        ; z-coordinate = (INWK+7 INWK+6), sign in INWK+8
                        ;
                        ;                   (rotmat0x rotmat0y rotmat0z)
                        ; Rotation matrix = (rotmat1x rotmat1y rotmat1z)
                        ;                   (rotmat2x rotmat2y rotmat2z)
                        ;
                        ;                   (INWK+10,9  INWK+12,11 INWK+14,13)
                        ;                 = (INWK+16,15 INWK+18,17 INWK+20,19)
                        ;                   (INWK+22,21 INWK+24,23 INWK+26,25)
                        ;
                        ;                   (  0     0   &E000)   (0  0 -1)
                        ; Zero'd in ZINF to (  0   &6000   0  ) = (0  1  0)
                        ;                   (&6000   0     0  )   (1  0  0)
                        ;
                        ; &6000 is the figure we use to represent 1 in the
                        ; rotation matrix, while &E000 represents -1
                        ;
                        ; INWK    = x_lo
                        ; INWK+1  = x_hi
                        ; INWK+2  = x_sign (for planets, x_distance)
                        ; INWK+3  = y_lo
                        ; INWK+4  = y_hi
                        ; INWK+5  = y_sign (for planets, y_distance)
                        ; INWK+6  = z_lo
                        ; INWK+7  = z_hi
                        ; INWK+8  = z_sign (for planets, z_distance)
                        ; INWK+9  = rotmat0x_lo
                        ; INWK+10 = rotmat0x_hi     xincrot_hi
                        ; INWK+11 = rotmat0y_lo
                        ; INWK+12 = rotmat0y_hi     yincrot_hi
                        ; INWK+13 = rotmat0z_lo
                        ; INWK+14 = rotmat0z_hi     zincrot_hi
                        ; INWK+15 = rotmat1x_lo
                        ; INWK+16 = rotmat1x_hi
                        ; INWK+17 = rotmat1y_lo
                        ; INWK+18 = rotmat1y_hi
                        ; INWK+19 = rotmat1z_lo
                        ; INWK+20 = rotmat1z_hi
                        ; INWK+21 = rotmat2x_lo
                        ; INWK+22 = rotmat2x_hi
                        ; INWK+23 = rotmat2y_lo
                        ; INWK+24 = rotmat2y_hi
                        ; INWK+25 = rotmat2z_lo
                        ; INWK+26 = rotmat2z_hi
                        ; INWK+27 = speed (32 = quite fast)
                        ; INWK+28 = acceleration
                        ; INWK+29 = rotx counter, 127 = no damping, damps roll
                        ; INWK+30 = rotz counter, 127 = no damping, damps pitch
                        ; INWK+31 = exploding/killed state, or missile count
                        ;           Bit 5 = 0 (not exploding) or 1 (exploding)
                        ;           Bit 7 = 1 (ship has been killed)
                        ; INWK+32 = AI, hostitity and E.C.M.
                        ;           Bit 0 = 0 (no E.C.M.) or 1 (has E.C.M.)
                        ;           Bit 6 = 0 (friendly) or 1 (hostile)
                        ;           Bit 7 = 0 (dumb) or 1 (has AI)
                        ;           So &FF = AI, hostile, has E.C.M.
                        ;           For space station, bit 7 set = angry
                        ; INWK+33 = ship lines heap space pointer lo
                        ; INWK+34 = ship lines heap space pointer hi
                        ; INWK+35 = ship energy

.XX19

 SKIP NI% - 33          ; XX19 shares location with INWK+33

.LSP

 SKIP 1                 ;

.QQ15

 SKIP 6                 ; Contains the three 16-bit seeds (6 bytes) for the
                        ; selected system, i.e. the one in the cross-hairs in
                        ; the short range chart.
                        ;
                        ; The seeds are stored as little-endian 16-bit numbers,
                        ; so the low (least significant) byte is first followed
                        ; by the high (most significant) byte. That means if
                        ; the seeds are w0, w1 and w2, they are stored like
                        ; this:
                        ;
                        ;       low byte  high byte
                        ;   w0  QQ15      QQ15+1
                        ;   w1  QQ15+2    QQ15+3
                        ;   w2  QQ15+4    QQ15+5
                        ;
                        ; In this documentation, we denote the low byte of w0
                        ; as w0_lo and the high byte as w0_hi, and so on for
                        ; w1_lo, w1_hi, w2_lo and w2_hi.

.K5

.XX18

.QQ17

 SKIP 1                 ; QQ17 stores flags that affect how text tokens are
                        ; printed, including the capitalisation setting
                        ;
                        ; Setting QQ17 = 255 disables text printing entirely
                        ;
                        ; Otherwise:
                        ;
                        ; Bit 7 = 0 means ALL CAPS
                        ; Bit 7 = 1 means Sentence Case, bit 6 determines case
                        ;           of next letter to print
                        ;
                        ; Bit 6 = 0 means print the next letter in upper case
                        ; Bit 6 = 1 means print the next letter in lower case
                        ;
                        ; So:
                        ;
                        ; QQ17 = 0   (%0000 0000) means case is set to ALL CAPS
                        ; QQ17 = 128 (%1000 0000) means Sentence Case,
                        ;                         currently printing upper case
                        ; QQ17 = 192 (%1100 0000) means Sentence Case,
                        ;                         currently printing lower case
                        ;
                        ; If any of bits 0-5 are set and QQ17 is not &FF, we
                        ; print in lower case

.QQ19

 SKIP 3                 ; Temporary storage (e.g. used in TT25 to store results
                        ; when calculating adjectives to show for system species
                        ; names, and in TT151 when printing market prices, and
                        ; in TT111 when working out which system is nearest to
                        ; the cross-hairs in the system charts)

.K6

 SKIP 5                 ; Temporary storage for seed pairs (e.g. used in cpl
                        ; as a temporary backup when twisting three 16-bit
                        ; seeds, and in TT151 when printing market prices)

.ALP1

 SKIP 1                 ; Roll rate, reduced from the dashboard indicator
                        ; value in JSTX

.ALP2

 SKIP 2                 ; ALP2   = flipped sign of the roll rate
                        ; ALP2+1 = correct sign of the roll rate

.BET2

 SKIP 2                 ; BET2   = correct sign of the pitch rate
                        ; BET2+1 = flipped sign of the pitch rate

.DELTA

 SKIP 1                 ; Current speed, 1-40

.DELT4

 SKIP 2                 ; The current speed * 64
                        ;
                        ; The high byte therefore contains the current speed
                        ; divided by 4

.U

 SKIP 1                 ; Temporary storage (e.g. used in BPRNT to store the
                        ; last position at which we must start printing digits)

.Q

 SKIP 1                 ; Temporary storage, used all over the place

.R

 SKIP 1                 ; Temporary storage, used all over the place

.S

 SKIP 1                 ; Temporary storage, used all over the place

.XSAV

 SKIP 1                 ; Temporary storage for X, used all over the place

.YSAV

 SKIP 1                 ; Temporary storage for Y, used all over the place

.XX17

 SKIP 1                 ; Temporary storage (e.g. used in BPRNT to store the
                        ; number of characters to print)

.QQ11

 SKIP 1                 ; Current view
                        ;
                        ; 0   = Space view
                        ; 1   = Title screen
                        ;       Buy Cargo screen (red key f1)
                        ;       Data on System screen (red key f6)
                        ;       Get commander name ("@", save/load commander)
                        ;       In-system jump just arrived ("J")
                        ;       Mis-jump just arrived (witchspace)
                        ; 4   = Sell Cargo screen (red key f2)
                        ; 6   = Death screen
                        ; 8   = Status Mode screen (red key f8)
                        ;       Inventory screen (red key f9)
                        ; 16  = Market Price screen (red key f7)
                        ; 32  = Equip Ship screen (red key f3)
                        ; 64  = Long-range Chart (red key f4)
                        ; 128 = Short-range Chart (red key f5)

.ZZ

 SKIP 1                 ; 

.XX13

 SKIP 1                 ; Number of pirates currently spawned

.MCNT

 SKIP 1                 ; Main loop counter
                        ;
                        ; Gets set to 0 when we buy fuel
                        ;
                        ; Gets set to &FF on death and in-system jump
                        ;
                        ; Gets decremented every time the main loop at TT100 is
                        ; entered
                        ;
                        ; Used to determine when to do certain actions within
                        ; the main loop, so ship energy and shields are bumped
                        ; up every 8 loops, we check whether we are near a
                        ; space station every 32 loops, we check the ship's
                        ; altitude every 10 loops, and so on

.DL

 SKIP 1                 ; Line scan counter
                        ;
                        ; Gets set to 30 every vertical sync on the video
                        ; system, which happens 50 times a second (50Hz)

.TYPE

 SKIP 1                 ; Temporary storage, used to store the current ship type
                        ; in places like the main flight loop

.JSTX

 SKIP 1                 ; Current rate of roll (as shown in the dashboard's RL
                        ; indicator), ranging from 1 to 255 with 128 as the
                        ; centre point (so 1 means roll is decreasing at the
                        ; maximum rate, 128 means roll is not changing, and
                        ; 255 means roll is increasing at the maximum rate)

.JSTY

 SKIP 1                 ; Current rate of pitch (as shown in the dashboard's DC
                        ; indicator), ranging from 1 to 255 with 128 as the
                        ; centre point (so 1 means pitch is decreasing at the
                        ; maximum rate, 128 means pitch is not changing, and
                        ; 255 means pitch is increasing at the maximum rate)

.ALPHA

 SKIP 1                 ; Roll rate, reduced from the dashboard indicator
                        ; value in JSTX, with the sign flipped

.QQ12

 SKIP 1                 ; Docked status
                        ;
                        ; 0 = not docked, &FF = docked

.TGT

 SKIP 1                 ; 

.SWAP

 SKIP 1                 ; 

.COL

 SKIP 1                 ; 

.FLAG

 SKIP 1                 ; 

.CNT

 SKIP 1                 ; 

.CNT2

 SKIP 1                 ; 

.STP

 SKIP 1                 ; 

.XX4

 SKIP 1                 ; Used as temporary storage (e.g. used in STATUS as a
                        ; loop counter)

.XX20

 SKIP 1                 ; 

.XX14

 SKIP 1                 ; 

.RAT

 SKIP 1                 ; 

.RAT2

 SKIP 1                 ; 

.K2

 SKIP 4

ORG &D1

.T

 SKIP 1                 ; Used as temporary storage (e.g. used in cpl for the
                        ; loop counter)

.K3                     ; Used as temporary storage (e.g. used in TT27 for the
                        ; character to print)

.XX2

 SKIP 14

.K4                     ; Used as temporary storage (e.g. used in TT27 for the
                        ; character to print)

PRINT "Zero page variables from ", ~ZP, " to ", ~P%

\ ******************************************************************************
\ Workspace XX3 at &0100
\
\ Used as heap space for storing temporary data during calculations shared with
\ the descending 6502 stack, which works down from &01FF.
\ ******************************************************************************

ORG &0100

.XX3                    ; Temporary heap space

\ ******************************************************************************
\ Workspace T% at &0300 - &035F
\
\ Contains the current commander data (NT% bytes at location TP), and the
\ stardust data block (NOST bytes at location SX)
\ ******************************************************************************

ORG &0300               ; Start of the commander block

.T%                     ; Start of workspace T%

.TP

 SKIP 1                 ; Mission status, always 0 for the tape version of Elite

.QQ0

 SKIP 1                 ; Current system's galactic x-coordinate

.QQ1

 SKIP 1                 ; Current system's galactic y-coordinate

.QQ21

 SKIP 6                 ; Three 16-bit seeds for the current system

.CASH

 SKIP 4                 ; Cash as a 32-bit unsigned integer, stored with the
                        ; most significant byte in CASH and the least
                        ; significant in CASH+3 (big-endian, which is not the
                        ; same way that 6502 assembler stores addresses) - 
                        ; or, to use our notation, it's CASH(0 1 2 3)

.QQ14

 SKIP 1                 ; Contains the current fuel level * 10 (so a 1 in QQ14
                        ; represents 0.1 light years)
                        ;
                        ; Maximum value is 70 (7.0 light years)

.COK

 SKIP 1                 ; Competition code flags
                        ;
                        ; Bit 7 is set on start-up if CHK and CHK2 do not match,
                        ; which presumably indicates that there may have been
                        ; some cheatimg going on
                        ;
                        ; Bit 1 is set on start-up
                        ;
                        ; Bit 0 is set in routine ptg if we hold X during
                        ; hyperspace to force a mis-jump (having first paused
                        ; the game and toggled on the author credits with X)

.GCNT

 SKIP 1                 ; Contains the current galaxy number, 0-7
                        ;
                        ; When this is displayed in-game, 1 is added to the
                        ; number (so we start in galaxy 1 in-game, but it's
                        ; stored as galaxy 0 internally)

.LASER

 SKIP 4                 ; Laser power
                        ;
                        ; (byte 0 = front, 1 = rear, 2 = left, 3 = right)
                        ;
                        ; 0 means no laser, non-zero denotes the following:
                        ;
                        ; Bits 0-6 contain the laser's power
                        ;
                        ; Bit 7 determines whether or not the laser pulses
                        ; (pulse laser) or is always on (beam laser)

 SKIP 2                 ; Not used (originally reserved for up/down lasers,
                        ; perhaps?)
 
.CRGO

 SKIP 1                 ; Cargo capacity
                        ;
                        ; 22 = standard cargo bay of 20 tonnes
                        ;
                        ; 37 = large cargo bay of 35 tonnes

.QQ20

 SKIP 17                ; Contents of cargo hold
                        ;
                        ; The amount of market item X in the hold is in QQ20+X,
                        ; so QQ20 contains the amount of food (item 0) while
                        ; QQ20+7 contains the amount of computers (item 7). See
                        ; QQ23 for a list of market item numbers.

.ECM

 SKIP 1                 ; E.C.M. system
                        ;
                        ; 0 = not fitted, &FF = fitted
                        
.BST

 SKIP 1                 ; Fuel scoops ("barrel status")
                        ;
                        ; 0 = not fitted, &FF = fitted

.BOMB

 SKIP 1                 ; Energy bomb
                        ;
                        ; 0 = not fitted, &7F = fitted

.ENGY

 SKIP 1                 ; Energy unit
                        ;
                        ; 0 = not fitted, 1 = fitted

.DKCMP

 SKIP 1                 ; Docking computer
                        ;
                        ; 0 = not fitted, &FF = fitted
                        
.GHYP

 SKIP 1                 ; Galactic hyperdrive
                        ;
                        ; 0 = not fitted, &FF = fitted
                        
.ESCP

 SKIP 1                 ; Escape pod
                        ;
                        ; 0 = not fitted, &FF = fitted

 SKIP 4                 ; Not used

.NOMSL

 SKIP 1                 ; Number of missiles

.FIST

 SKIP 1                 ; Legal status ("fugitive/innocent status")
                        ;
                        ; 0    = Clean
                        ; 1-49 = Offender
                        ; 50+  = Fugitive
                        ;
                        ; You get 64 points if you kill a cop, so that's
                        ; straight to fugitive

.AVL

 SKIP 17                ; Market availability
                        ;
                        ; The available amount of market item X is in AVL+X, so
                        ; AVL contains the amount of food (item 0) while AVL+7
                        ; contains the amount of computers (item 7). See QQ23
                        ; for a list of market item numbers.

.QQ26

 SKIP 1                 ; A random value that changes for each visit to a
                        ; system, for randomising market prices (see TT151 for
                        ; details of the market price calculation)

.TALLY

 SKIP 2                 ; Number of kills as a 16-bit number, stored as
                        ; TALLY(1 0) - so the high byte is in TALLY+1 and the
                        ; low in TALLY
                        ;
                        ; If the high byte in TALLY+1 = 0 then we are Harmless,
                        ; Mostly Harmless, Poor, Average or Above Average,
                        ; according to the value of the low byte in TALLY:
                        ;
                        ; Harmless        = 0000 0000 to 0000 0011 = 0 to 3
                        ; Mostly Harmless = 0000 0100 to 0000 0111 = 4 to 7
                        ; Poor            = 0000 1000 to 0000 1111 = 8 to 15
                        ; Average         = 0001 0000 to 0001 1111 = 16 to 31
                        ; Above Average   = 0010 0000 to 1111 1111 = 32 to 255
                        ;
                        ; If the high byte in TALLY+1 is non-zero then we are
                        ; Competent, Dangerous, Deadly or Elite, according to
                        ; the high byte in TALLY+1:
                        ;
                        ; Competent       = 1           = 256 to 511 kills
                        ; Dangerous       = 2 to 9      = 512 to 2559 kills 
                        ; Deadly          = 10 to 24    = 2560 to 6399 kills 
                        ; Elite           = 25 and up   = 6400 kills and up
                        ;
                        ; You can see the rating calculation in STATUS.

.SVC

 SKIP 1                 ; Save count, gets halved with each save

 SKIP 2                 ; Reserve two bytes for commander checksum, so when
                        ; current commander block is copied to the last saved
                        ; commnder block at NA%, CHK and CHK2 get overwritten

NT% = SVC + 2 - TP      ; Set to the size of the commander block, which starts
                        ; at T% (&300) and goes to SVC+3

SX = P%                 ; SX points to the stardust data block, which is NOST
                        ; bytes (NOST = "number of stars")

SXL = SX + NOST + 1     ; SXL points to the end of the stardust data block

PRINT "T% workspace from  ", ~T%, " to ", ~SXL

\ ******************************************************************************
\ ELITE WORDS9 at &0400 - &07FF
\
\ Produces the binary file WORDS9.bin which gets loaded by elite-loader.asm.
\
\ The recursive token table is loaded at &1100 and is moved down to &0400 as
\ part of elite-loader.asm.
\ ******************************************************************************

CODE_WORDS% = &0400
LOAD_WORDS% = &1100

ORG CODE_WORDS%

\ ******************************************************************************
\ Variable: QQ18
\
\ Recursive token table for tokens 0-148.
\ ******************************************************************************
\
\ This table contains data for the recursive token system used in Elite. There
\ are actually three types of token used by Elite - recursive, two-letter and
\ control codes - so let's look at all of them in one go.
\
\ Tokens in Elite
\ ---------------
\ Elite uses a tokenisation system to store the text it displays during the
\ game. This enables the game to store strings more efficiently than would be
\ the case if they were simply inserted into the source code using EQUS, and it
\ also makes it possible to create things like system names using procedural
\ generation.
\ 
\ To support tokenisation, characters are printed to the screen using a special
\ subroutine (TT27), which not only supports the usual range of letters,
\ numbers and punctuation, but also three different types of token. When
\ printed, these tokens get expanded into longer strings, which enables the
\ game to squeeze a lot of text into a small amount of storage.
\ 
\ To print something, you pass a byte through to the printing routine at TT27.
\ The value of that byte determines what gets printed, as follows:
\ 
\   Value (n)     Type
\   ---------     -------------------------------------------------------
\   0-13          Control codes 0-13
\   14-31         Recursive tokens 128-145 (i.e. token number = n + 114)
\   32-95         Normal ASCII characters 32-95 (0-9, A-Z and most punctuation)
\   96-127        Recursive tokens 96-127 (i.e. token number = n)
\   128-159       Two-letter tokens 128-159
\   160-255       Recursive tokens 0-95 (i.e. token number = n - 160)
\ 
\ Characters with codes 32-95 represent the normal ASCII characters from " " to
\ "_", so a value of 65 in an Elite string represents the letter A (as "A" has
\ character code 65 in the BBC Micro's character set).
\ 
\ All other character codes (0-31 and 96-255) represent tokens, and they can
\ print anything from single characters to entire sentences. In the case of
\ recursive tokens, the tokens can themselves contain other tokens, and in this
\ way long strings can be stored in very few bytes, at the expense of code
\ readability and speed.
\ 
\ To make things easier to follow in the discussion and comments below, let's
\ refer to the three token types like this, where n is the character code:
\ 
\   {n}           Control codes             n = 0 to 13
\   <n>           Two-letter token          n = 128 to 159
\   [n]           Recursive token           n = 0 to 148
\ 
\ So when we say {13} we're talking about control code 13 ("crlf"), while <141>
\ is the two-letter token 141 ("DI"), and [3] is the recursive token 3 ("DATA
\ ON {current system}"). The brackets are just there to make things easier to
\ understand when following the code, because the way these tokens are stored
\ in memory and passed to subroutines is confusing, to say the least.
\ 
\ We'll take a look at each of the three token types in more detail below, but
\ first a word about how characters get printed in Elite.
\ 
\ The TT27 print subroutine
\ -------------------------
\ Elite contains a subroutine at TT27 that prints out the character given in
\ the accumulator, and if that number refers to a token, then the token is
\ expanded before being printed. Whole strings can be printed by calling this
\ subroutine on one character at a time, and this is how almost all of the text
\ in the game gets put on screen. For example, the following code:
\ 
\   LDA #65
\   JSR TT27
\ 
\ prints a capital A, while this code:
\ 
\   LDA #163
\   JSR TT27
\ 
\ prints recursive token number 3 (see below for more on why we pass #163
\ instead of #3). This would produce the following if we were currently
\ visiting Tionisla:
\ 
\   DATA ON TIONISLA
\ 
\ This is because token 3 expands to the string "DATA ON {current system}". You
\ can see this very call being used in TT25, which displays data on the
\ selected system when F6 is pressed (this particular call is what prints the
\ title at the top of the screen).
\ 
\ The ex print subroutine
\ -----------------------
\ You may have noticed that in the table above, there are character codes for
\ all our ASCII characters and tokens, except for recursive tokens 146, 147 and
\ 148. How do we print these?
\ 
\ To print these tokens, there is another subroutine at ex that always prints
\ the recursive token number in the accumulator, so we can use that to print
\ these tokens.
\ 
\ (Incidentally, the ex subroutine is what TT27 calls when it has analysed the
\ character code, determined that it is a recursive token, and subtracted 160
\ or added 114 as appropriate to get the token number, so calling it directly
\ with 146-148 in the accumulator is acceptable.)
\ 
\ Control codes: {n}
\ ------------------
\ Control codes are in the range 0 to 13, and expand to the following when
\ printed via TT27:
\ 
\   0   Current cash, right-aligned to width 9, then " CR", newline
\   1   Current galaxy number, right-aligned to width 3
\   2   Current system name
\   3   Selected system name (the cross-hairs in the short range chart)
\   4   Commander's name
\   5   "FUEL: ", fuel level, " LIGHT YEARS", newline, "CASH:", {0}, newline
\   6   Switch case to Sentence Case
\   7   Beep
\   8   Switch case to ALL CAPS
\   9   Tab to column 21, then print a colon
\   10  Line feed (i.e. move cursor down)
\   11  (not used, does the same as 13)
\   12  (not used, does the same as 13)
\   13  Newline (i.e. carriage return and line feed)
\ 
\ So a value of 4 in a tokenised string will be expanded to the current
\ commander's name, while a value of 5 will print the current fuel level in the
\ format "FUEL: 5.3 LIGHT YEARS", followed by a newline, followed by "CASH: ",
\ and then followed by control code 0, which shows the amount of cash to one
\ significant figure, right-aligned to a width of 9 characters, and finished
\ off with " CR" and another newline. The result is something like this, when
\ displayed in Sentence Case:
\ 
\   Fuel: 6.7 Light Years
\   Cash:    1234.5 Cr
\ 
\ If you press f8 to show the Status Mode screen, you can see control code 4
\ being used to show the commander's name in the title, while control code 5 is
\ responsible for displaying the fuel and cash lines.
\ 
\ When talking about encoded strings in the code comments below, control
\ characters are shown as {n}, so {4} expands to the commander's name and {5}
\ to the current fuel.
\ 
\ By default, Elite prints words using Sentence Case, where the first letter of
\ each word is capitalised. Control code {8} can be used to switch to ALL CAPS
\ (so it acts like Caps Lock), and {6} can be used to switch back to Sentence
\ Case. You can see this in action on the Status Mode screen, where the title
\ and equipment headers are in ALL CAPS, while everything else is in Sentence
\ Case. Tokens are stored in capital letters only, and each letter's case is
\ set by the logic in TT27.
\ 
\ Two-letter tokens: <n>
\ ----------------------
\ Two-letter tokens expand to the following:
\ 
\   128     AL
\   129     LE
\   130     XE
\   131     GE
\   132     ZA
\   133     CE
\   134     BI
\   135     SO
\   136     US
\   137     ES
\   138     AR
\   139     MA
\   140     IN
\   141     DI
\   142     RE
\   143     A?
\   144     ER
\   145     AT
\   146     EN
\   147     BE
\   148     RA
\   149     LA
\   150     VE
\   151     TI
\   152     ED
\   153     OR
\   154     QU
\   155     AN
\   156     TE
\   157     IS
\   158     RI
\   159     ON
\ 
\ So a value of 150 in the tokenised string would expand to VE, for example.
\ When talking about encoded strings in the code comments below, two-letter
\ tokens are shown as <n>, so <150> expands to VE.
\ 
\ The set of two-letter tokens is stored as one long string ("ALLEXEGE...") at
\ location QQ16. This string is also used to generate system names
\ procedurally, as described in routine cpl.
\ 
\ Note that question marks are not printed, so token <143> expands to A. This
\ allows names with an odd number of characters to be generated from sequences
\ of two-letter tokens, though only if they contain the letter A.
\ 
\ Recursive tokens: [n]
\ ---------------------
\ The binary file that is assembled by this source file (WORDS9.bin) contains
\ 149 recursive tokens, numbered from 0 to 148, which are stored from &0400 to
\ &06FF in a tokenised form. These tokenised strings can include references to
\ other tokens, hence "recursive".
\ 
\ When talking about encoded strings in the code comments below, recursive
\ tokens are shown as [n], so [111] expands to "FUEL SCOOPS", for example, and
\ [110] expands to "[102][104]S", which in turn expands to "EXTRA BEAM LASERS"
\ (as [102] expands to "EXTRA " and [104] to "BEAM LASER").
\ 
\ The recursive tokens are numbered from 0 to 148, but because we've already
\ reserved codes 0-13 for control characters, 32-95 for ASCII characters and
\ 128-159 for two-letter tokens, we can't just send the token number straight
\ to TT27 to print it out (sending 65 to TT27 prints "A", for example, and not
\ recursive token 65). So instead, we use the table above to work out what to
\ send to TT27; here are the relevant lines:
\ 
\   Value (n)     Type
\   ---------     -------------------------------------------------------
\   14-31         Recursive tokens 128-145 (i.e. token number = n + 114)
\   96-127        Recursive tokens 96-127 (i.e. token number = n)
\   160-255       Recursive tokens 0-95 (i.e. token number = n - 160)
\ 
\ The first column is the number we need to send to TT27 to print the token
\ mentioned in the second column.
\ 
\ So, if we want to print recursive token 132, then according to the first row
\ in this table, we need to subtract 114 to get 18, and send that to TT27.
\ 
\ Meanwhile, if we want to print token 101, then according to the second row,
\ we can just pass that straight through to TT27.
\ 
\ Finally, if we want to print token 3, then according to the third row, we
\ need to add 160 to get 163.
\ 
\ Note that, as described in the section above, you can't use TT27 to print
\ recursive tokens 146-148, but instead you need to call the ex subroutine, so
\ the method described here only applies to recursive tokens 0-145.
\ 
\ How recursive tokens are stored in memory
\ -----------------------------------------
\ 
\ The 149 recursive tokens are stored one after the other in memory, starting
\ at &0400, with each token being terminated by a null character (EQUB 0).
\ 
\ To complicate matters, the strings themselves are all EOR'd with 35 before
\ being stored, and this process is repeated when they are read from memory (as
\ EOR is reversible). This is done in the routine at TT50.
\ 
\ Note that if a recursive token contains another recursive token, then that
\ token's number is stored as the number that would be sent to TT27, rather
\ than the number of the token itself.
\ 
\ All of this makes it pretty challenging to work out how one would store a
\ specific token in memory, which is why this file uses a handful of macros to
\ make life easier. They are:
\ 
\   CHAR n        ; insert ASCII character n        n = 32 to 95
\   CTRL n        ; insert control code n           n = 0 to 13
\   TWOK n        ; insert two-letter token n       n = 128 to 159
\   RTOK n        ; insert recursive token n        n = 0 to 148
\ 
\ A side effect of all this obfuscation is that tokenised strings can't contain
\ ASCII 35 characters ("#"). This is because ASCII "#" EOR 35 is 0, and the
\ null character is already used to terminate our tokens in memory, so if you
\ did have a string containing the hash character, it wouldn't print the hash,
\ but would instead terminate at the character before.
\ 
\ Interestingly, there's no lookup table for each recursive token's starting
\ point im memory, as that would take up too much space, so to get hold of the
\ encoded string for a specific recursive token, the print routine runs through
\ the entire list of tokens, character by character, counting all the nulls
\ until it reaches the right spot. This might not be fast, but it is much more
\ space-efficient than a lookup table; you can see this loop in the subroutine
\ at ex, which is where recursive tokens are printed.
\ 
\ An example
\ ----------
\ 
\ Given all this, let's consider recursive token 3 again, which is printed
\ using the following code (remember, we have to add 160 to 3 to pass through
\ to TT27):
\ 
\   LDA #163
\   JSR TT27
\ 
\ Token 3 is stored in the tokenised form:
\ 
\   D<145>A[131]{3}
\ 
\ which we could store in memory using the following (adding in the null
\ terminator at the end):
\ 
\   CHAR 'D'
\   TWOK 145
\   CHAR 'A'
\   RTOK 131
\   CTRL 3
\   EQUB 0
\ 
\ As mentioned above, the values that are actually stored are EOR'd with 35,
\ and token [131] has to have 114 taken off it before it's ready for TT27, so
\ the bytes that are actually stored in memory for this token are:
\ 
\   EQUB 'D' EOR 35
\   EQUB 145 EOR 35
\   EQUB 'A' EOR 35
\   EQUB (131 - 114) EOR 35
\   EQUB 3 EOR 35
\   EQUB 0
\ 
\ or, as they would appear in the raw WORDS9.bin file, this:
\ 
\   EQUB &67, &B2, &62, &32, &20, &00
\ 
\ These all produce the same output, but the first version is rather easier to
\ understand.
\ 
\ Now that the token is stored in memory, we can call TT27 with the accumulator
\ set to 163, and the token will be printed as follows:
\ 
\   D             The letter D                      "D"
\   <145>         Two-letter token 145              "AT"
\   A             The letter A                      "A"
\   [131]         Recursive token 131               " ON "
\   {3}           Control character 3               The selected system name
\ 
\ So if the system under the cross-hairs in the short range chart is Tionisla,
\ this expands into "DATA ON TIONISLA".
\ ******************************************************************************

.QQ18

 RTOK 111               ; Token 0:      "FUEL SCOOPS ON {beep}"
 RTOK 131               ; Encoded as:   "[111][131]{7}"
 CTRL 7
 EQUB 0

 CHAR ' '               ; Token 1:      " CHART"
 CHAR 'C'               ; Encoded as:   " CH<138>T"
 CHAR 'H'
 TWOK 138
 CHAR 'T'
 EQUB 0

 CHAR 'G'               ; Token 2:      "GOVERNMENT"
 CHAR 'O'               ; Encoded as:   "GO<150>RNM<146>T"
 TWOK 150
 CHAR 'R'
 CHAR 'N'
 CHAR 'M'
 TWOK 146
 CHAR 'T'
 EQUB 0

 CHAR 'D'               ; Token 3:      "DATA ON {selected system name}"
 TWOK 145               ; Encoded as:   "D<145>A[131]{3}"
 CHAR 'A'
 RTOK 131
 CTRL 3
 EQUB 0

 TWOK 140               ; Token 4:      "INVENTORY{crlf}"
 TWOK 150               ; Encoded as:   "<140><150>NT<153>Y{13}"
 CHAR 'N'
 CHAR 'T'
 TWOK 153
 CHAR 'Y'
 CTRL 13
 EQUB 0

 CHAR 'S'               ; Token 5:      "SYSTEM"
 CHAR 'Y'               ; Encoded as:   "SYS<156>M"
 CHAR 'S'
 TWOK 156
 CHAR 'M'
 EQUB 0

 CHAR 'P'               ; Token 6:      "PRICE"
 TWOK 158               ; Encoded as:   "P<158><133>"
 TWOK 133
 EQUB 0

 CTRL 2                 ; Token 7:      "{current system name} MARKET PRICES"
 CHAR ' '               ; Encoded as:   "{2} <139>RKET [6]S"
 TWOK 139
 CHAR 'R'
 CHAR 'K'
 CHAR 'E'
 CHAR 'T'
 CHAR ' '
 RTOK 6
 CHAR 'S'
 EQUB 0

 TWOK 140               ; Token 8:      "INDUSTRIAL"
 CHAR 'D'               ; Encoded as:   "<140>D<136>T<158><128>"
 TWOK 136
 CHAR 'T'
 TWOK 158
 TWOK 128
 EQUB 0

 CHAR 'A'               ; Token 9:      "AGRICULTURAL"
 CHAR 'G'               ; Encoded as:   "AG<158>CULTU<148>L"
 TWOK 158
 CHAR 'C'
 CHAR 'U'
 CHAR 'L'
 CHAR 'T'
 CHAR 'U'
 TWOK 148
 CHAR 'L'
 EQUB 0

 TWOK 158               ; Token 10:     "RICH "
 CHAR 'C'               ; Encoded as:   "<158>CH "
 CHAR 'H'
 CHAR ' '
 EQUB 0

 CHAR 'A'               ; Token 11:     "AVERAGE "
 TWOK 150               ; Encoded as:   "A<150><148><131> "
 TWOK 148
 TWOK 131
 CHAR ' '
 EQUB 0

 CHAR 'P'               ; Token 12:     "POOR "
 CHAR 'O'               ; Encoded as:   "PO<153> "
 TWOK 153
 CHAR ' '
 EQUB 0                 ; Encoded as:   "PO<153> "

 TWOK 139               ; Token 13:     "MAINLY "
 TWOK 140               ; Encoded as:   "<139><140>LY "
 CHAR 'L'
 CHAR 'Y'
 CHAR ' '
 EQUB 0

 CHAR 'U'               ; Token 14:     "UNIT"
 CHAR 'N'               ; Encoded as:   "UNIT"
 CHAR 'I'
 CHAR 'T'
 EQUB 0

 CHAR 'V'               ; Token 15:     "VIEW "
 CHAR 'I'               ; Encoded as:   "VIEW "
 CHAR 'E'
 CHAR 'W'
 CHAR ' '
 EQUB 0

 TWOK 154               ; Token 16:     "QUANTITY"
 TWOK 155               ; Encoded as:   "<154><155><151>TY"
 TWOK 151
 CHAR 'T'
 CHAR 'Y'
 EQUB 0

 TWOK 155               ; Token 17:     "ANARCHY"
 TWOK 138               ; Encoded as:   "<155><138>CHY"
 CHAR 'C'
 CHAR 'H'
 CHAR 'Y'
 EQUB 0

 CHAR 'F'               ; Token 18:     "FEUDAL"
 CHAR 'E'               ; Encoded as:   "FEUD<128>"
 CHAR 'U'
 CHAR 'D'
 TWOK 128
 EQUB 0

 CHAR 'M'               ; Token 19:     "MULTI-GOVERNMENT"
 CHAR 'U'               ; Encoded as:   "MUL<151>-[2]"
 CHAR 'L'
 TWOK 151
 CHAR '-'
 RTOK 2
 EQUB 0

 TWOK 141               ; Token 20:     "DICTATORSHIP"
 CHAR 'C'               ; Encoded as:   "<141>CT<145><153>[25]"
 CHAR 'T'
 TWOK 145
 TWOK 153
 RTOK 25
 EQUB 0

 RTOK 91                ; Token 21:     "COMMUNIST"
 CHAR 'M'               ; Encoded as:   "[91]MUN<157>T"
 CHAR 'U'
 CHAR 'N'
 TWOK 157
 CHAR 'T'
 EQUB 0

 CHAR 'C'               ; Token 22:     "CONFEDERACY"
 TWOK 159               ; Encoded as:   "C<159>F<152><144>ACY"
 CHAR 'F'
 TWOK 152
 TWOK 144
 CHAR 'A'
 CHAR 'C'
 CHAR 'Y'
 EQUB 0

 CHAR 'D'               ; Token 23:     "DEMOCRACY"
 CHAR 'E'               ; Encoded as:   "DEMOC<148>CY"
 CHAR 'M'
 CHAR 'O'
 CHAR 'C'
 TWOK 148
 CHAR 'C'
 CHAR 'Y'
 EQUB 0

 CHAR 'C'               ; Token 24:     "CORPORATE STATE"
 TWOK 153               ; Encoded as:   "C<153>P<153><145>E [43]<145>E"
 CHAR 'P'
 TWOK 153
 TWOK 145
 CHAR 'E'
 CHAR ' '
 RTOK 43
 TWOK 145
 CHAR 'E'
 EQUB 0

 CHAR 'S'               ; Token 25:     "SHIP"
 CHAR 'H'               ; Encoded as:   "SHIP"
 CHAR 'I'
 CHAR 'P'
 EQUB 0

 CHAR 'P'               ; Token 26:     "PRODUCT"
 CHAR 'R'               ; Encoded as:   "PRODUCT"
 CHAR 'O'
 CHAR 'D'
 CHAR 'U'
 CHAR 'C'
 CHAR 'T'
 EQUB 0

 CHAR ' '               ; Token 27:     " LASER"
 TWOK 149               ; Encoded as:   " <149>S<144>"
 CHAR 'S'
 TWOK 144
 EQUB 0

 CHAR 'H'               ; Token 28:     "HUMAN COLONIAL"
 CHAR 'U'               ; Encoded as:   "HUM<155> COL<159>I<128>"
 CHAR 'M'
 TWOK 155
 CHAR ' '
 CHAR 'C'
 CHAR 'O'
 CHAR 'L'
 TWOK 159
 CHAR 'I'
 TWOK 128
 EQUB 0

 CHAR 'H'               ; Token 29:     "HYPERSPACE "
 CHAR 'Y'               ; Encoded as:   "HYP<144>SPA<133> "
 CHAR 'P'
 TWOK 144
 CHAR 'S'
 CHAR 'P'
 CHAR 'A'
 TWOK 133
 CHAR ' '
 EQUB 0

 CHAR 'S'               ; Token 30:     "SHORT RANGE CHART"
 CHAR 'H'               ; Encoded as:   "SH<153>T [42][1]"
 TWOK 153
 CHAR 'T'
 CHAR ' '
 RTOK 42
 RTOK 1
 EQUB 0

 TWOK 141               ; Token 31:     "DISTANCE"
 RTOK 43                ; Encoded as:   "<141>[43]<155><133>"
 TWOK 155
 TWOK 133
 EQUB 0

 CHAR 'P'               ; Token 32:     "POPULATION"
 CHAR 'O'               ; Encoded as:   "POPUL<145>I<159>"
 CHAR 'P'
 CHAR 'U'
 CHAR 'L'
 TWOK 145
 CHAR 'I'
 TWOK 159
 EQUB 0

 CHAR 'G'               ; Token 33:     "GROSS PRODUCTIVITY"
 CHAR 'R'               ; Encoded as:   "GROSS [26]IVITY"
 CHAR 'O'
 CHAR 'S'
 CHAR 'S'
 CHAR ' '
 RTOK 26
 CHAR 'I'
 CHAR 'V'
 CHAR 'I'
 CHAR 'T'
 CHAR 'Y'
 EQUB 0

 CHAR 'E'               ; Token 34:     "ECONOMY"
 CHAR 'C'               ; Encoded as:   "EC<159>OMY"
 TWOK 159
 CHAR 'O'
 CHAR 'M'
 CHAR 'Y'
 EQUB 0

 CHAR ' '               ; Token 35:     " LIGHT YEARS"
 CHAR 'L'               ; Encoded as:   " LIGHT YE<138>S"
 CHAR 'I'
 CHAR 'G'
 CHAR 'H'
 CHAR 'T'
 CHAR ' '
 CHAR 'Y'
 CHAR 'E'
 TWOK 138
 CHAR 'S'
 EQUB 0

 TWOK 156               ; Token 36:     "TECH.LEVEL"
 CHAR 'C'               ; Encoded as:   "<156>CH.<129><150>L"
 CHAR 'H'
 CHAR '.'
 TWOK 129
 TWOK 150
 CHAR 'L'
 EQUB 0

 CHAR 'C'               ; Token 37:     "CASH"
 CHAR 'A'               ; Encoded as:   "CASH"
 CHAR 'S'
 CHAR 'H'
 EQUB 0

 CHAR ' '               ; Token 38:     " BILLION"
 TWOK 134               ; Encoded as:   " <134>[118]I<159>"
 RTOK 118
 CHAR 'I'
 TWOK 159
 EQUB 0

 RTOK 122               ; Token 39:     "GALACTIC CHART{galaxy number
 RTOK 1                 ;                right-aligned to width 3}"
 CTRL 1                 ; Encoded as:   "[122][1]{1}"
 EQUB 0

 CHAR 'T'               ; Token 40:     "TARGET LOST"
 TWOK 138               ; Encoded as:   "T<138><131>T LO[43]"
 TWOK 131
 CHAR 'T'
 CHAR ' '
 CHAR 'L'
 CHAR 'O'
 RTOK 43
 EQUB 0

 RTOK 106               ; Token 41:     "MISSILE JAMMED"
 CHAR ' '               ; Encoded as:   "[106] JAMM<152>"
 CHAR 'J'
 CHAR 'A'
 CHAR 'M'
 CHAR 'M'
 TWOK 152
 EQUB 0

 CHAR 'R'               ; Token 42:     "RANGE"
 TWOK 155               ; Encoded as:   "R<155><131>"
 TWOK 131
 EQUB 0

 CHAR 'S'               ; Token 43:     "ST"
 CHAR 'T'               ; Encoded as:   "ST"
 EQUB 0

 RTOK 16                ; Token 44:     "QUANTITY OF "
 CHAR ' '               ; Encoded as:   "[16] OF "
 CHAR 'O'
 CHAR 'F'
 CHAR ' '
 EQUB 0

 CHAR 'S'               ; Token 45:     "SELL"
 CHAR 'E'               ; Encoded as:   "SE[118]"
 RTOK 118
 EQUB 0

 CHAR ' '               ; Token 46:     " CARGO{switch to sentence case}"
 CHAR 'C'               ; Encoded as:   " C<138>GO{6}"
 TWOK 138
 CHAR 'G'
 CHAR 'O'
 CTRL 6
 EQUB 0

 CHAR 'E'               ; Token 47:     "EQUIP"
 TWOK 154               ; Encoded as:   "E<154>IP"
 CHAR 'I'
 CHAR 'P'
 EQUB 0

 CHAR 'F'               ; Token 48:     "FOOD"
 CHAR 'O'               ; Encoded as:   "FOOD"
 CHAR 'O'
 CHAR 'D'
 EQUB 0

 TWOK 156               ; Token 49:     "TEXTILES"
 CHAR 'X'               ; Encoded as:   "<156>X<151>L<137>"
 TWOK 151
 CHAR 'L'
 TWOK 137
 EQUB 0

 TWOK 148               ; Token 50:     "RADIOACTIVES"
 TWOK 141               ; Encoded as:   "<148><141>OAC<151><150>S"
 CHAR 'O'
 CHAR 'A'
 CHAR 'C'
 TWOK 151
 TWOK 150
 CHAR 'S'
 EQUB 0

 CHAR 'S'               ; Token 51:     "SLAVES"
 TWOK 149               ; Encoded as:   "S<149><150>S"
 TWOK 150
 CHAR 'S'
 EQUB 0

 CHAR 'L'               ; Token 52:     "LIQUOR/WINES"
 CHAR 'I'               ; Encoded as:   "LI<154><153>/W<140><137>"
 TWOK 154
 TWOK 153
 CHAR '/'
 CHAR 'W'
 TWOK 140
 TWOK 137
 EQUB 0

 CHAR 'L'               ; Token 53:     "LUXURIES"
 CHAR 'U'               ; Encoded as:   "LUXU<158><137>"
 CHAR 'X'
 CHAR 'U'
 TWOK 158
 TWOK 137
 EQUB 0

 CHAR 'N'               ; Token 54:     "NARCOTICS"
 TWOK 138               ; Encoded as:   "N<138>CO<151>CS"
 CHAR 'C'
 CHAR 'O'
 TWOK 151
 CHAR 'C'
 CHAR 'S'
 EQUB 0

 RTOK 91                ; Token 55:     "COMPUTERS"
 CHAR 'P'               ; Encoded as:   "[91]PUT<144>S"
 CHAR 'U'
 CHAR 'T'
 TWOK 144
 CHAR 'S'
 EQUB 0

 TWOK 139               ; Token 56:     "MACHINERY"
 CHAR 'C'               ; Encoded as:   "<139>CH<140><144>Y"
 CHAR 'H'
 TWOK 140
 TWOK 144
 CHAR 'Y'
 EQUB 0

 RTOK 117               ; Token 57:     "ALLOYS"
 CHAR 'O'               ; Encoded as:   "[117]OYS"
 CHAR 'Y'
 CHAR 'S'
 EQUB 0

 CHAR 'F'               ; Token 58:     "FIREARMS"
 CHAR 'I'               ; Encoded as:   "FI<142><138>MS"
 TWOK 142
 TWOK 138
 CHAR 'M'
 CHAR 'S'
 EQUB 0

 CHAR 'F'               ; Token 59:     "FURS"
 CHAR 'U'               ; Encoded as:   "FURS"
 CHAR 'R'
 CHAR 'S'
 EQUB 0

 CHAR 'M'               ; Token 60:     "MINERALS"
 TWOK 140               ; Encoded as:   "M<140><144><128>S"
 TWOK 144
 TWOK 128
 CHAR 'S'
 EQUB 0

 CHAR 'G'               ; Token 61:     "GOLD"
 CHAR 'O'               ; Encoded as:   "GOLD"
 CHAR 'L'
 CHAR 'D'
 EQUB 0

 CHAR 'P'               ; Token 62:     "PLATINUM"
 CHAR 'L'               ; Encoded as:   "PL<145><140>UM"
 TWOK 145
 TWOK 140
 CHAR 'U'
 CHAR 'M'
 EQUB 0

 TWOK 131               ; Token 63:     "GEM-STONES"
 CHAR 'M'               ; Encoded as:   "<131>M-[43]<159><137>"
 CHAR '-'
 RTOK 43
 TWOK 159
 TWOK 137
 EQUB 0

 TWOK 128               ; Token 64:     "ALIEN ITEMS"
 CHAR 'I'               ; Encoded as:   "<128>I<146> [127]S"
 TWOK 146
 CHAR ' '
 RTOK 127
 CHAR 'S'
 EQUB 0

 CHAR '('               ; Token 65:     "(Y/N)?"
 CHAR 'Y'               ; Encoded as:   "(Y/N)?"
 CHAR '/'
 CHAR 'N'
 CHAR ')'
 CHAR '?'
 EQUB 0

 CHAR ' '               ; Token 66:     " CR"
 CHAR 'C'               ; Encoded as:   " CR"
 CHAR 'R'
 EQUB 0

 CHAR 'L'               ; Token 67:     "LARGE"
 TWOK 138               ; Encoded as:   "L<138><131>"
 TWOK 131
 EQUB 0

 CHAR 'F'               ; Token 68:     "FIERCE"
 CHAR 'I'               ; Encoded as:   "FI<144><133>"
 TWOK 144
 TWOK 133
 EQUB 0

 CHAR 'S'               ; Token 69:     "SMALL"
 TWOK 139               ; Encoded as:   "S<139>[118]"
 RTOK 118
 EQUB 0

 CHAR 'G'               ; Token 70:     "GREEN"
 TWOK 142               ; Encoded as:   "G<142><146>"
 TWOK 146
 EQUB 0

 CHAR 'R'               ; Token 71:     "RED"
 TWOK 152               ; Encoded as:   "R<152>"
 EQUB 0

 CHAR 'Y'               ; Token 72:     "YELLOW"
 CHAR 'E'               ; Encoded as:   "YE[118]OW"
 RTOK 118
 CHAR 'O'
 CHAR 'W'
 EQUB 0

 CHAR 'B'               ; Token 73:     "BLUE"
 CHAR 'L'               ; Encoded as:   "BLUE"
 CHAR 'U'
 CHAR 'E'
 EQUB 0

 CHAR 'B'               ; Token 74:     "BLACK"
 TWOK 149               ; Encoded as:   "B<149>CK"
 CHAR 'C'
 CHAR 'K'
 EQUB 0

 RTOK 136               ; Token 75:     "HARMLESS"
 EQUB 0                 ; Encoded as:   "[136]"

 CHAR 'S'               ; Token 76:     "SLIMY"
 CHAR 'L'               ; Encoded as:   "SLIMY"
 CHAR 'I'
 CHAR 'M'
 CHAR 'Y'
 EQUB 0

 CHAR 'B'               ; Token 77:     "BUG-EYED"
 CHAR 'U'               ; Encoded as:   "BUG-EY<152>"
 CHAR 'G'
 CHAR '-'
 CHAR 'E'
 CHAR 'Y'
 TWOK 152
 EQUB 0

 CHAR 'H'               ; Token 78:     "HORNED"
 TWOK 153               ; Encoded as:   "H<153>N<152>"
 CHAR 'N'
 TWOK 152
 EQUB 0

 CHAR 'B'               ; Token 79:     "BONY"
 TWOK 159               ; Encoded as:   "B<159>Y"
 CHAR 'Y'
 EQUB 0

 CHAR 'F'               ; Token 80:     "FAT"
 TWOK 145               ; Encoded as:   "F<145>"
 EQUB 0

 CHAR 'F'               ; Token 81:     "FURRY"
 CHAR 'U'               ; Encoded as:   "FURRY"
 CHAR 'R'
 CHAR 'R'
 CHAR 'Y'
 EQUB 0

 CHAR 'R'               ; Token 82:     "RODENT"
 CHAR 'O'               ; Encoded as:   "ROD<146>T"
 CHAR 'D'
 TWOK 146
 CHAR 'T'
 EQUB 0

 CHAR 'F'               ; Token 83:     "FROG"
 CHAR 'R'               ; Encoded as:   "FROG"
 CHAR 'O'
 CHAR 'G'
 EQUB 0

 CHAR 'L'               ; Token 84:     "LIZARD"
 CHAR 'I'               ; Encoded as:   "LI<132>RD"
 TWOK 132
 CHAR 'R'
 CHAR 'D'
 EQUB 0

 CHAR 'L'               ; Token 85:     "LOBSTER"
 CHAR 'O'               ; Encoded as:   "LOB[43]<144>"
 CHAR 'B'
 RTOK 43
 TWOK 144
 EQUB 0

 TWOK 134               ; Token 86:     "BIRD"
 CHAR 'R'               ; Encoded as:   "<134>RD"
 CHAR 'D'
 EQUB 0

 CHAR 'H'               ; Token 87:     "HUMANOID"
 CHAR 'U'               ; Encoded as:   "HUM<155>OID"
 CHAR 'M'
 TWOK 155
 CHAR 'O'
 CHAR 'I'
 CHAR 'D'
 EQUB 0

 CHAR 'F'               ; Token 88:     "FELINE"
 CHAR 'E'               ; Encoded as:   "FEL<140>E"
 CHAR 'L'
 TWOK 140
 CHAR 'E'
 EQUB 0

 TWOK 140               ; Token 89:     "INSECT"
 CHAR 'S'               ; Encoded as:   "<140>SECT"
 CHAR 'E'
 CHAR 'C'
 CHAR 'T'
 EQUB 0

 RTOK 11                ; Token 90:     "AVERAGE RADIUS"
 TWOK 148               ; Encoded as:   "[11]<148><141><136>"
 TWOK 141
 TWOK 136
 EQUB 0

 CHAR 'C'               ; Token 91:     "COM"
 CHAR 'O'               ; Encoded as:   "COM"
 CHAR 'M'
 EQUB 0

 RTOK 91                ; Token 92:     "COMMANDER"
 CHAR 'M'               ; Encoded as:   "[91]M<155>D<144>"
 TWOK 155
 CHAR 'D'
 TWOK 144
 EQUB 0

 CHAR ' '               ; Token 93:     " DESTROYED"
 CHAR 'D'               ; Encoded as:   " D<137>TROY<152>"
 TWOK 137
 CHAR 'T'
 CHAR 'R'
 CHAR 'O'
 CHAR 'Y'
 TWOK 152
 EQUB 0

 CHAR 'B'               ; Token 94:     "BY D.BRABEN & I.BELL"
 CHAR 'Y'               ; Encoded as:   "BY D.B<148><147>N & I.<147>[118]"
 CHAR ' '
 CHAR 'D'
 CHAR '.'
 CHAR 'B'
 TWOK 148
 TWOK 147
 CHAR 'N'
 CHAR ' '
 CHAR '&'
 CHAR ' '
 CHAR 'I'
 CHAR '.'
 TWOK 147
 RTOK 118
 EQUB 0

 RTOK 14                ; Token 95:     "UNIT  QUANTITY{crlf} PRODUCT   UNIT
 CHAR ' '               ;                 PRICE FOR SALE{crlf}{lf}"
 CHAR ' '               ; Encoded as:   "[14]  [16]{13} [26]   [14] [6] F<153>
 RTOK 16                ;                 SA<129>{13}{10}"
 CTRL 13
 CHAR ' '
 RTOK 26
 CHAR ' '
 CHAR ' '
 CHAR ' '
 RTOK 14
 CHAR ' '
 RTOK 6
 CHAR ' '
 CHAR 'F'
 TWOK 153
 CHAR ' '
 CHAR 'S'
 CHAR 'A'
 TWOK 129
 CTRL 13
 CTRL 10
 EQUB 0

 CHAR 'F'               ; Token 96:     "FRONT"
 CHAR 'R'               ; Encoded as:   "FR<159>T"
 TWOK 159
 CHAR 'T'
 EQUB 0

 TWOK 142               ; Token 97:     "REAR"
 TWOK 138               ; Encoded as:   "<142><138>"
 EQUB 0

 TWOK 129               ; Token 98:     "LEFT"
 CHAR 'F'               ; Encoded as:   "<129>FT"
 CHAR 'T'
 EQUB 0

 TWOK 158               ; Token 99:     "RIGHT"
 CHAR 'G'               ; Encoded as:   "<158>GHT"
 CHAR 'H'
 CHAR 'T'
 EQUB 0

 RTOK 121               ; Token 100:    "ENERGY LOW{beep}"
 CHAR 'L'               ; Encoded as:   "[121]LOW{7}"
 CHAR 'O'
 CHAR 'W'
 CTRL 7
 EQUB 0

 RTOK 99                ; Token 101:    "RIGHT ON COMMANDER!"
 RTOK 131               ; Encoded as:   "[99][131][92]!"
 RTOK 92
 CHAR '!'
 EQUB 0

 CHAR 'E'               ; Token 102:    "EXTRA "
 CHAR 'X'               ; Encoded as:   "EXT<148> "
 CHAR 'T'
 TWOK 148
 CHAR ' '
 EQUB 0

 CHAR 'P'               ; Token 103:    "PULSE LASER"
 CHAR 'U'               ; Encoded as:   "PULSE[27]"
 CHAR 'L'
 CHAR 'S'
 CHAR 'E'
 RTOK 27
 EQUB 0

 TWOK 147               ; Token 104:    "BEAM LASER"
 CHAR 'A'               ; Encoded as:   "<147>AM[27]"
 CHAR 'M'
 RTOK 27
 EQUB 0

 CHAR 'F'               ; Token 105:    "FUEL"
 CHAR 'U'               ; Encoded as:   "FUEL"
 CHAR 'E'
 CHAR 'L'
 EQUB 0

 CHAR 'M'               ; Token 106:    "MISSILE"
 TWOK 157               ; Encoded as:   "M<157>SI<129>"
 CHAR 'S'
 CHAR 'I'
 TWOK 129
 EQUB 0

 RTOK 67                ; Token 107:    "LARGE CARGO{switch to sentence
 RTOK 46                ;                 case} BAY"
 CHAR ' '               ; Encoded as:   "[67][46] BAY"
 CHAR 'B'
 CHAR 'A'
 CHAR 'Y'
 EQUB 0

 CHAR 'E'               ; Token 108:    "E.C.M.SYSTEM"
 CHAR '.'               ; Encoded as:   "E.C.M.[5]"
 CHAR 'C'
 CHAR '.'
 CHAR 'M'
 CHAR '.'
 RTOK 5
 EQUB 0

 RTOK 102               ; Token 109:    "EXTRA PULSE LASERS"
 RTOK 103               ; Encoded as:   "[102][103]S"
 CHAR 'S'
 EQUB 0

 RTOK 102               ; Token 110:    "EXTRA BEAM LASERS"
 RTOK 104               ; Encoded as:   "[102][104]S"
 CHAR 'S'
 EQUB 0

 RTOK 105               ; Token 111:    "FUEL SCOOPS"
 CHAR ' '               ; Encoded as:   "[105] SCOOPS"
 CHAR 'S'
 CHAR 'C'
 CHAR 'O'
 CHAR 'O'
 CHAR 'P'
 CHAR 'S'
 EQUB 0

 TWOK 137               ; Token 112:    "ESCAPE POD"
 CHAR 'C'               ; Encoded as:   "<137>CAPE POD"
 CHAR 'A'
 CHAR 'P'
 CHAR 'E'
 CHAR ' '
 CHAR 'P'
 CHAR 'O'
 CHAR 'D'
 EQUB 0

 RTOK 121               ; Token 113:    "ENERGY BOMB"
 CHAR 'B'               ; Encoded as:   "[121]BOMB"
 CHAR 'O'
 CHAR 'M'
 CHAR 'B'
 EQUB 0

 RTOK 121               ; Token 114:    "ENERGY UNIT"
 RTOK 14                ; Encoded as:   "[121][14]"
 EQUB 0

 RTOK 124               ; Token 115:    "DOCKING COMPUTERS"
 TWOK 140               ; Encoded as:   "[124]<140>G [55]"
 CHAR 'G'
 CHAR ' '
 RTOK 55
 EQUB 0

 RTOK 122               ; Token 116:    "GALACTIC HYPERSPACE "
 CHAR ' '               ; Encoded as:   "[122] [29]"
 RTOK 29
 EQUB 0

 CHAR 'A'               ; Token 117:    "ALL"
 RTOK 118               ; Encoded as:   "A[118]"
 EQUB 0

 CHAR 'L'               ; Token 118:    "LL"
 CHAR 'L'               ; Encoded as:   "LL"
 EQUB 0

 RTOK 37                ; Token 119:    "CASH:{cash right-aligned to width 9}
 CHAR ':'               ;                 CR{crlf}"
 CTRL 0                 ; Encoded as:   "[37]:{0}"
 EQUB 0

 TWOK 140               ; Token 120:    "INCOMING MISSILE"
 RTOK 91                ; Encoded as:   "<140>[91]<140>G [106]"
 TWOK 140
 CHAR 'G'
 CHAR ' '
 RTOK 106
 EQUB 0

 TWOK 146               ; Token 121:    "ENERGY "
 TWOK 144               ; Encoded as:   "<146><144>GY "
 CHAR 'G'
 CHAR 'Y'
 CHAR ' '
 EQUB 0

 CHAR 'G'               ; Token 122:    "GALACTIC"
 CHAR 'A'               ; Encoded as:   "GA<149>C<151>C"
 TWOK 149
 CHAR 'C'
 TWOK 151
 CHAR 'C'
 EQUB 0

 CTRL 13                ; Token 123:    "{crlf}COMMANDER'S NAME? "
 RTOK 92                ; Encoded as:   "{13}[92]'S NAME? "
 CHAR 39                ; CHAR 39 is the apostrophe
 CHAR 'S'
 CHAR ' '
 CHAR 'N'
 CHAR 'A'
 CHAR 'M'
 CHAR 'E'
 CHAR '?'
 CHAR ' '
 EQUB 0

 CHAR 'D'               ; Token 124:    "DOCK"
 CHAR 'O'               ; Encoded as:   "DOCK"
 CHAR 'C'
 CHAR 'K'
 EQUB 0

 CTRL 5                 ; Token 125:    "FUEL: {fuel level} LIGHT YEARS{crlf}
 TWOK 129               ;                CASH:{cash right-aligned to width 9}
 CHAR 'G'               ;                 CR{crlf}LEGAL STATUS:"
 TWOK 128               ; Encoded as:   "{5}<129>G<128> [43]<145><136>:"
 CHAR ' '
 RTOK 43
 TWOK 145
 TWOK 136
 CHAR ':'
 EQUB 0

 RTOK 92                ; Token 126:    "COMMANDER {commander name}{crlf}{crlf}
 CHAR ' '               ;                {crlf}{switch to sentence case}PRESENT
 CTRL 4                 ;                 SYSTEM{tab to column 21}:{current 
 CTRL 13                ;                system name}{crlf}HYPERSPACE SYSTEM
 CTRL 13                ;                {tab to column 21}:{selected system
 CTRL 13                ;                name}{crlf}CONDITION{tab to column
 CTRL 6                 ;                21}:"
 RTOK 145               ; Encoded as:   "[92] {4}{13}{13}{13}{6}[145] [5]{9}{2}
 CHAR ' '               ;                {13}[29][5]{9}{3}{13}C<159><141><151>
 RTOK 5                 ;                <159>{9}"
 CTRL 9
 CTRL 2
 CTRL 13
 RTOK 29
 RTOK 5
 CTRL 9
 CTRL 3
 CTRL 13
 CHAR 'C'
 TWOK 159
 TWOK 141
 TWOK 151
 TWOK 159
 CTRL 9
 EQUB 0

 CHAR 'I'               ; Token 127:    "ITEM"
 TWOK 156               ; Encoded as:   "I<156>M"
 CHAR 'M'
 EQUB 0

 CHAR ' '               ; Token 128:    "  LOAD NEW COMMANDER (Y/N)?
 CHAR ' '               ;                {crlf}{crlf}"
 CHAR 'L'               ; Encoded as:   "  LOAD NEW [92] [65]{13}{13}"
 CHAR 'O'
 CHAR 'A'
 CHAR 'D'
 CHAR ' '
 CHAR 'N'
 CHAR 'E'
 CHAR 'W'
 CHAR ' '
 RTOK 92
 CHAR ' '
 RTOK 65
 CTRL 13
 CTRL 13
 EQUB 0

 CTRL 6                 ; Token 129:    "{switch to sentence case}DOCKED"
 RTOK 124               ; Encoded as:   "{6}[124]<152>"
 TWOK 152
 EQUB 0

 TWOK 148               ; Token 130:    "RATING:"
 TWOK 151               ; Encoded as:   "<148><151>NG:"
 CHAR 'N'
 CHAR 'G'
 CHAR ':'
 EQUB 0

 CHAR ' '               ; Token 131:    " ON "
 TWOK 159               ; Encoded as:   " <159> "
 CHAR ' '
 EQUB 0

 CTRL 13                ; Token 132:    "{crlf}{switch to all caps}EQUIPMENT:
 CTRL 8                 ;                {switch to sentence case}"
 RTOK 47                ; Encoded as:   "{13}{8}[47]M<146>T:{6}"
 CHAR 'M'
 TWOK 146
 CHAR 'T'
 CHAR ':'
 CTRL 6
 EQUB 0

 CHAR 'C'               ; Token 133:    "CLEAN"
 TWOK 129               ; Encoded as:   "C<129><155>"
 TWOK 155
 EQUB 0

 CHAR 'O'               ; Token 134:    "OFFENDER"
 CHAR 'F'               ; Encoded as:   "OFF<146>D<144>"
 CHAR 'F'
 TWOK 146
 CHAR 'D'
 TWOK 144
 EQUB 0

 CHAR 'F'               ; Token 135:    "FUGITIVE"
 CHAR 'U'               ; Encoded as:   "FUGI<151><150>"
 CHAR 'G'
 CHAR 'I'
 TWOK 151
 TWOK 150
 EQUB 0

 CHAR 'H'               ; Token 136:    "HARMLESS"
 TWOK 138               ; Encoded as:   "H<138>M<129>SS"
 CHAR 'M'
 TWOK 129
 CHAR 'S'
 CHAR 'S'
 EQUB 0

 CHAR 'M'               ; Token 137:    "MOSTLY HARMLESS"
 CHAR 'O'               ; Encoded as:   "MO[43]LY [136]"
 RTOK 43
 CHAR 'L'
 CHAR 'Y'
 CHAR ' '
 RTOK 136
 EQUB 0

 RTOK 12                ; Token 138:    "POOR "
 EQUB 0                 ; Encoded as:   "[12]"

 RTOK 11                ; Token 139:    "AVERAGE "
 EQUB 0                 ; Encoded as:   "[11]"

 CHAR 'A'               ; Token 140:    "ABOVE AVERAGE "
 CHAR 'B'               ; Encoded as:   "ABO<150> [11]"
 CHAR 'O'
 TWOK 150
 CHAR ' '
 RTOK 11
 EQUB 0

 RTOK 91                ; Token 141:    "COMPETENT"
 CHAR 'P'               ; Encoded as:   "[91]PET<146>T"
 CHAR 'E'
 CHAR 'T'
 TWOK 146
 CHAR 'T'
 EQUB 0

 CHAR 'D'               ; Token 142:    "DANGEROUS"
 TWOK 155               ; Encoded as:   "D<155><131>RO<136>"
 TWOK 131
 CHAR 'R'
 CHAR 'O'
 TWOK 136
 EQUB 0

 CHAR 'D'               ; Token 143:    "DEADLY"
 CHAR 'E'               ; Encoded as:   "DEADLY"
 CHAR 'A'
 CHAR 'D'
 CHAR 'L'
 CHAR 'Y'
 EQUB 0

 CHAR '-'               ; Token 144:    "---- E L I T E ----"
 CHAR '-'               ; Encoded as:   "---- E L I T E ----"
 CHAR '-'
 CHAR '-'
 CHAR ' '
 CHAR 'E'
 CHAR ' '
 CHAR 'L'
 CHAR ' '
 CHAR 'I'
 CHAR ' '
 CHAR 'T'
 CHAR ' '
 CHAR 'E'
 CHAR ' '
 CHAR '-'
 CHAR '-'
 CHAR '-'
 CHAR '-'
 EQUB 0

 CHAR 'P'               ; Token 145:    "PRESENT"
 TWOK 142               ; Encoded as:   "P<142>S<146>T"
 CHAR 'S'
 TWOK 146
 CHAR 'T'
 EQUB 0

 CTRL 8                 ; Token 146:    "{switch to all caps}GAME OVER"
 CHAR 'G'               ; Encoded as:   "{8}GAME O<150>R"
 CHAR 'A'
 CHAR 'M'
 CHAR 'E'
 CHAR ' '
 CHAR 'O'
 TWOK 150
 CHAR 'R'
 EQUB 0

 CHAR 'P'               ; Token 147:    "PRESS FIRE OR SPACE,COMMANDER.
 CHAR 'R'               ;                {crlf}{crlf}"
 TWOK 137               ; Encoded as:   "PR<137>S FI<142> <153> SPA<133>,[92].
 CHAR 'S'               ;                {13}{13}"
 CHAR ' '
 CHAR 'F'
 CHAR 'I'
 TWOK 142
 CHAR ' '
 TWOK 153
 CHAR ' '
 CHAR 'S'
 CHAR 'P'
 CHAR 'A'
 TWOK 133
 CHAR ','
 RTOK 92
 CHAR '.'
 CTRL 13
 CTRL 13
 EQUB 0

 CHAR '('               ; Token 148:    "(C) ACORNSOFT 1984"
 CHAR 'C'               ; Encoded as:   "(C) AC<153>N<135>FT 1984"
 CHAR ')'
 CHAR ' '
 CHAR 'A'
 CHAR 'C'
 TWOK 153
 CHAR 'N'
 TWOK 135
 CHAR 'F'
 CHAR 'T'
 CHAR ' '
 CHAR '1'
 CHAR '9'
 CHAR '8'
 CHAR '4'
 EQUB 0

\ ******************************************************************************
\ Save output/WORDS9.bin
\ ******************************************************************************

PRINT "WORDS9"
PRINT "Assembled at ", ~CODE_WORDS%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_WORDS%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_WORDS%

PRINT "S.WORDS9 ",~CODE%," ",~P%," ",~LOAD%," ",~LOAD_WORDS%
SAVE "output/WORDS9.bin", CODE_WORDS%, P%, LOAD%

\ ******************************************************************************
\ Workspace K% at &0900
\
\ Pointed to by the lookup table at location UNIV, the first 468 bytes of which
\ holds data on 13 ships, 36 (NI%) bytes each.
\ ******************************************************************************

ORG &0900

.K%                     ; Ship data blocks and ship lines heap space

\ ******************************************************************************
\ Workspace WP at &0D40 - &0F34
\ ******************************************************************************

ORG &0D40

.WP                     ; Start of workspace WP

.FRIN

 SKIP NOSH + 1          ; Slots for the 13 ships in the local bubble of universe
                        ;
                        ; Each slot contains a ship type from 1-13 (see the list
                        ; of ship types in location XX21), or 0 if the slot is
                        ; empty.
                        ; 
                        ; The corresponding address in the lookup table at UNIV
                        ; points to the ship's data block, which in turn points
                        ; to that ship's line heap space.
                        ;
                        ; The first ship slot at location FRIN is reserved for
                        ; the planet.
                        ;
                        ; The second ship slot at FRIN+1 is reserved for the
                        ; sun or space station (we only ever have one of these
                        ; in our local bubble of space). If FRIN+1 is 0, we
                        ; show the space station, otherwise we show the sun.
                        ;
                        ; Ships in our local bubble start at FRIN+2 onwards.
                        ; The slots are kept in order, with asteroids first.

.CABTMP                 ; Cabin temperature
                        ;
                        ; 30 = cabin temperature in deep space (i.e. one notch
                        ;      on the dashboard bar)
                        ;
                        ; We get higher temperatures closer to the sun
                        ;
                        ; Shares a location with MANY, but that's OK because
                        ; MANY would contain the number of ships of type 0, but
                        ; isn't used because ship types start at 1

.MANY

 SKIP SST               ; Ship counts by type
                        ; 
                        ; Contains a count of how many ships there are of each
                        ; type in our local bubble of universe, with the number
                        ; of ships of type X being stored at offset X, so the
                        ; current number of Sidewinders is at MANY+1, the number
                        ; of Mambas is at MANY+2, and so on

.SSPR

 SKIP 14 - SST          ; "Space station present" flag
                        ;
                        ; Non-zero if we are inside the space station safe zone
                        ;
                        ; 0 if we aren't (in which case we can show the sun)
                        ; 
                        ; This flag is at MANY+SST, which is no coincidence, as
                        ; MANY+SST is a count of how many space stations there
                        ; are in our local bubble, which is the same as saying
                        ; "space station present"

.ECMP

 SKIP 1                 ; Our E.C.M. status
                        ;
                        ; 0 is off, non-zero is on

.MJ

 SKIP 1                 ; Are we in witchspace (i.e. we mis-jumped)?
                        ;
                        ; 0 = no, &FF = yes

.LAS2

 SKIP 1                 ; Laser power for the current laser
                        ;
                        ; Bits 0-6 of the laser power of the current space view
                        ; (bit 7 doesn't denote laser power, just whether or
                        ; not the laser pulses)

.MSAR

 SKIP 1                 ; Leftmost missile is currently armed
                        ;
                        ; 0 = no, non-zero = yes

.VIEW

 SKIP 1                 ; Current space view
                        ;
                        ; 0 = forward
                        ; 1 = rear
                        ; 2 = left
                        ; 3 = right

.LASCT

 SKIP 1                 ; Laser pulse count for the current laser
                        ;
                        ; Defines the gap between pulses of a pulse laser
                        ;
                        ; 0 for beam laser, 10 for pulse laser
                        ;
                        ; This gets decremented every vertical sync (in LINSCN),
                        ; and is set to a non-zero value for pulse lasers only.
                        ; The laser only fires when the value of LASCT hits
                        ; zero, so for pulse lasers with a value of 10, that
                        ; means it fires once every 10 vertical syncs (or 5
                        ; times a second). In comparison, beam lasers fire
                        ; continuously.

.GNTMP

 SKIP 1                 ; Laser ("gun") temperature
                        ;
                        ; If the laser temperature exceeds 242 then the laser
                        ; overheats and cannot be fired again until it has
                        ; cooled down

.HFX

 SKIP 1                 ; Toggle hyperspace colour effects
                        ;
                        ; 0 = no effects, non-zero = hyperspace effects
                        ;
                        ; When this is set to 1, the mode 4 screen that makes
                        ; up the top part of the display is switched to mode 5
                        ; (the same as the dashboard), which has the effect of
                        ; blurring and colouring the hyperspace rings. The code
                        ; to do this is in the LINSCN routine, where HFX is
                        ; checked and the mode 4 code is skipped if it is 1,
                        ; thus leaving the top part of the screen in mode 5.

.EV

 SKIP 1                 ; Extra vessels spawning counter
                        ;
                        ; This counter is set to 0 on arrival in a system and
                        ; following an in-system jump, and is bumped up when we
                        ; spawn bounty hunters or pirates ("extra vessels")
                        ;
                        ; It decreases by 1 each time we consider spawning more
                        ; "extra vessels" the main game loop (TT100 part 4), so
                        ; increasing the value of EV delays their spawning
                        ;
                        ; In other words, this counter stops bounty hunters and
                        ; pirates from continually appearing, and instead adds
                        ; a delay between spawnings

.DLY

 SKIP 1                 ; In-flight message delay
                        ;
                        ; This counter is used to keep an in-flight message up
                        ; for a specified time before it gets removed. The value
                        ; in DLY is decremented each time we enter the main
                        ; loop at TT100.

.de

 SKIP 1                 ; Equipment destruction flag
                        ;
                        ; Bit 1 set means "DESTROYED" is appended to the 
                        ; in-flight message printed by MESS

.LSX

.LSO

 SKIP 192               ; This block is shared by LSX and LSO:
                        ;
                        ; LSX is the the line buffer for the sun
                        ;
                        ; LSO is the ship lines heap space for the space station
                        ;
                        ; This space can be shared as our local bubble of
                        ; universe can support either the sun or a space
                        ; station, but not both
.LSX2

 SKIP 78                ; 

.LSY2

 SKIP 78                ; 

.SY

 SKIP NOST + 1          ; 

.SYL

 SKIP NOST + 1          ; 

.SZ

 SKIP NOST + 1          ; 

.SZL

 SKIP NOST + 1          ; 

.XSAV2

 SKIP 1                 ; Temporary storage for the X register (e.g. used in
                        ; TT27 to store X while printing is performed)

.YSAV2

 SKIP 1                 ; Temporary storage for the Y register (e.g. used in
                        ; TT27 to store X while printing is performed)

.MCH

 SKIP 1                 ; The text token of the in-flight message that is
                        ; currently being shown, and which will be removed by
                        ; me2 when the counter in DLY reaches zero

.FSH

 SKIP 1                 ; Forward shield status
                        ;
                        ; 0 = empty, &FF = full

.ASH

 SKIP 1                 ; Aft shield status
                        ;
                        ; 0 = empty, &FF = full

.ENERGY

 SKIP 1                 ; Energy bank status
                        ;
                        ; 0 = empty, &FF = full

.LASX

 SKIP 1                 ; 

.LASY

 SKIP 1                 ; 

.COMX

 SKIP 1                 ; 

.COMY

 SKIP 1                 ; 

.QQ24

 SKIP 1                 ; Temporary storage (e.g. used in TT151 for the current
                        ; market item's price)

.QQ25

 SKIP 1                 ; Temporary storage (e.g. used in TT151 for the current
                        ; market item's availability)

.QQ28

 SKIP 1                 ; Temporary storage (e.g. used in var for the economy
                        ; byte of the current system)

.QQ29

 SKIP 1                 ; Temporary storage (e.g. used in TT219 for the current
                        ; market item)

.gov

 SKIP 1                 ; Government of current system

.tek

 SKIP 1                 ; Tech level of current system (0-14)

.SLSP

 SKIP 2                 ; Points to the start of the ship lines heap space,
                        ; which is a descending block that starts at SLSP and
                        ; ends at WP, and which can be extended downwards by
                        ; lowering SLSP if more heap space is required

.XX24

 SKIP 1                 ; 

.ALTIT

 SKIP 1                 ; Our altitude above the planet
                        ;
                        ; &FF = maximum
                        ;
                        ; Otherwise this contains our altitude as the square
                        ; root of x_hi^2 + y_hi^2 + z_hi^2 - 6^2, where our
                        ; ship is at the origin, the centre of the planet is at
                        ; (x_hi, y_hi, z_hi), and the radius of the planet is 6
                        ;
                        ; If this value drops to zero, we have crashed

.QQ2

 SKIP 6                 ; Contains the three 16-bit seeds for the current system
                        ; (see QQ15 above for details of how the three seeds are
                        ; stored in memory)

.QQ3

 SKIP 1                 ; Selected system's economy (0-7)

.QQ4

 SKIP 1                 ; Selected system's government (0-7)

.QQ5

 SKIP 1                 ; Selected system's tech level (0-14)

.QQ6

 SKIP 2                 ; Selected system's population * 10 in billions (1-71)

.QQ7

 SKIP 2                 ; Selected system's productivity in M CR (96-62480)

.QQ8

 SKIP 2                 ; Distance to the selected system * 10 in light years,
                        ; stored as a 16-bit number
                        ;
                        ; Will be 0 if this is the current system
                        ;
                        ; The galaxy chart is 102.4 light years wide and 51.2
                        ; light years tall (see the intra-system distance
                        ; calculations in TT111 for details), which would be
                        ; 1024 x 512 in terms of QQ8

.QQ9

 SKIP 1                 ; Selected system's galactic x-coordinate

.QQ10

 SKIP 1                 ; Selected system's galactic y-coordinate

.NOSTM

 SKIP 1                 ; Number of stardust particles

PRINT "WP workspace from  ", ~WP," to ", ~P%

\ ******************************************************************************
\ ELITE A
\
\ Produces the binary file ELTA.bin which gets loaded by elite-bcfs.asm.
\
\ The main game code (ELITE A through G, plus the ship data) is loaded at &1128
\ and is moved down to &0F40 as part of elite-loader.asm.
\ ******************************************************************************

CODE% = &0F40
LOAD% = &1128

ORG CODE%

LOAD_A% = LOAD%

.S%

 EQUW TT170             ; Entry point for Elite game; once the main code has
                        ; been loaded, decrypted and moved to the right place
                        ; by elite-loader.asm, the game is started by a
                        ; JMP (S%) instruction, which jumps to the main entry
                        ; point TT170 via this location

 EQUW TT26              ; WRCHV is set to point here by elite-loader.asm

 EQUW IRQ1              ; IRQ1V is set to point here by elite-loader.asm

 EQUW BR1               ; BRKV is set to point here by elite-loader.asm

.COMC

 EQUB 0                 ; Compass colour
                        ;
                        ; &F0 = in front, &FF = behind

.DNOIZ

 EQUB 0                 ; Sound on/off configuration setting
                        ;
                        ; 0 = on (default), non-zero = off
                        ;
                        ; Toggled by pressing "S" when paused, see DK4

.DAMP

 EQUB 0                 ; Keyboard damping configuration setting
                        ;
                        ; 0 = enabled (default), non-zero = disabled
                        ;
                        ; Toggled by pressing Caps Lock when paused, see DKS3

.DJD

 EQUB 0                 ; Keyboard auto-recentre configuration setting
                        ;
                        ; 0 = enabled (default), non-zero = disabled
                        ;
                        ; Toggled by pressing "A" when paused, see DKS3

.PATG

 EQUB 0                 ; Configuration setting to show author names on start-up
                        ; screen and enable manual hyperspace mis-jumps
                        ;
                        ; 0 = off (default), &FF = on
                        ;
                        ; Toggled by pressing "X" when paused, see DKS3
                        ;
                        ; This needs to be turned on for manual mis-jumps to be
                        ; possible. To to do a manual mis-jump, first toggle the
                        ; author display by pausing the game (Copy) and pressing
                        ; X, and during the next hyperspace, hold down CTRL to
                        ; force a mis-jump; see routine ee5 for the "AND PATG"
                        ; instruction that implements this.

.FLH

 EQUB 0                 ; Flashing console bars configuration setting
                        ;
                        ; 0 = static (default), non-zero = flashing
                        ;
                        ; Toggled by pressing "F" when paused, see DKS3

.JSTGY

 EQUB 0                 ; Reverse joystick Y channel configuration setting
                        ;
                        ; 0 = standard (default), &FF = reversed
                        ;
                        ; Toggled by pressing "Y" when paused, see DKS3

.JSTE

 EQUB 0                 ; Reverse both joystick channels configuration setting
                        ;
                        ; 0 = standard (default), &FF = reversed
                        ;
                        ; Toggled by pressing "J" when paused, see DKS3

.JSTK

 EQUB 0                 ; Keyboard or joystick configuration setting
                        ;
                        ; 0 = keyboard (default), non-zero = joystick
                        ;
                        ; Toggled by pressing "K" when paused, see DKS3

\ ******************************************************************************
\ Subroutine: M% (Part 1)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Seed the random number generator
\ ******************************************************************************

.M%
{
 LDA K%                 ; Seed the random number generator with whatever is in
 STA RAND               ; location K%, which will be fairly random as this is
                        ; where we store the ship data blocks

\ ******************************************************************************
\ Subroutine: M% (Part 2)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Calculate the alpha and beta angles from the current roll and pitch
\
\ Here we take the current rate of roll and pitch, as set by the joystick or
\ keyboard, and convert them into alpha and beta angles that we can use in the
\ matrix functions to rotate space around our ship. The alpha angle covers
\ roll, while the beta angle covers pitch (there is no yaw in this version of
\ Elite). The angles are in radians, which allows us to use the small angle
\ approximation when moving objects in the sky (see the MVEIT routine for more
\ on this). Also, the signs of the two angles are stored separately, in both
\ the sign and the flipped sign, as this makes calculations easier.
\ ******************************************************************************

 LDX JSTX               ; Set X to the current rate of roll in JSTX, and
 JSR cntr               ; apply keyboard damping twice (if enabled) so the roll
 JSR cntr               ; rate in X creeps towards the centre by 2

 TXA                    ; Set A and Y to the roll rate but with the sign
 EOR #%10000000         ; bit flipped
 TAY
 
 AND #%10000000         ; Extract the flipped sign of the roll rate and store
 STA ALP2               ; in ALP2

 STX JSTX               ; Update JSTX with the damped value that's still in X

 EOR #%10000000         ; Extract the correct sign of the roll rate and store
 STA ALP2+1             ; in APL2+1

 TYA                    ; If the roll rate but with the sign bit flipped is
 BPL P%+7               ; positive (i.e. if the current roll rate is negative),
                        ; skip the following 3 instructions

 EOR #%11111111         ; The current roll rate is negative, so change the sign
 CLC                    ; of A using two's complement, so A is now -A, or |A|
 ADC #1

 LSR A                  ; Divide the (positive) roll rate in A by 4
 LSR A

 CMP #8                 ; If A >= 8, skip the following two instructions
 BCS P%+4

 LSR A                  ; A < 8, so halve A again and clear the carry flag, so
 CLC                    ; so we can do addition later without the carry flag
                        ; affecting the result

 STA ALP1               ; Store A in ALP1, so:
                        ;
                        ;   ALP1 = |JSTX| / 8    if |JSTX| <= 32
                        ;
                        ;   ALP1 = |JSTX| / 4    if |JSTX| > 32
                        ;
                        ; So higher roll rates are reduced closer to zero

 ORA ALP2               ; Store A in ALPHA, but with the sign set to ALP2 (so
 STA ALPHA              ; ALPHA has a different sign to the actual roll rate

 LDX JSTY               ; Set X to the current rate of pitch in JSTY, and
 JSR cntr               ; apply keyboard damping so the pitch rate in X creeps
                        ; towards the centre by 1

 TXA                    ; Set A and Y to the pitch rate but with the sign
 EOR #%10000000         ; flipped
 TAY

 AND #%10000000         ; Extract the flipped sign of the pitch rate into A

 STX JSTY               ; Update JSTY with the damped value that's still in X

 STA BET2+1             ; Store the flipped sign of the pitch rate into BET2+1

 EOR #%10000000         ; Extract the correct sign of the pitch rate and store
 STA BET2               ; in BET2

 TYA                    ; If the pitch rate but with the sign bit flipped is
 BPL P%+4               ; positive (i.e. if the current pitch rate is
                        ; negative), skip the following 2 instructions

 EOR #%11111111         ; The current pitch rate is negative, so flip the
 ADC #4                 ; bits and add 4

 LSR A                  ; Divide the (positive) pitch rate in A by 16
 LSR A
 LSR A
 LSR A

 CMP #3                 ; If A >= 3, skip the following instruction
 BCS P%+3

 LSR A                  ; A < 3, so halve A again

 STA BET1               ; Store A in BET1

 ORA BET2               ; Store A in BETA, but with the sign set to BET2 (so
 STA BETA               ; BETA has the same sign as the actual pitch rate)

\ ******************************************************************************
\ Subroutine: M% (Part 3)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Scan for flight keys and process the results
\
\ Flight keys are logged in the key logger at location KY1 onwards, with a
\ non-zero value in the relevant location indicating a key press. See the KL
\ and KY1 locations for more details.
\
\ The keypresses that are processed are as follows:
\
\   * Space and "?" to speed up and slow down
\   * "U", "T" and "M" for disarming, arming and firing missiles
\   * Tab for firing an energy bomb
\   * Escape for launching an escape pod
\   * "J" for initiating an in-system jump
\   * "E" to deploy E.C.M. anti-missile countermeasures
\   * "C" to use the docking computer
\   * "A" to fire lasers
\ ******************************************************************************

 LDA KY2                ; If Space is being pressed, keep going, otherwise jump
 BEQ MA17               ; down to MA17 to skip the following

 LDA DELTA              ; The "go faster" key is being pressed, so first we
 CMP #40                ; fetch the current speed from DELTA into A, and if
 BCS MA17               ; A >= 40, we are already going at full pelt, so jump
                        ; down to MA17 to skip the following
 
 INC DELTA              ; We can go a bit faster, so increment the speed in
                        ; location DELTA

.MA17

 LDA KY1                ; If "?" is being pressed, keep going, otherwise jump
 BEQ MA4                ; down to MA4 to skip the following

 DEC DELTA              ; The "slow down" key is being pressed, so we decrement
                        ; the current ship speed in DELTA

 BNE MA4                ; If the speed is still greater then zero, jump to MA4
 
 INC DELTA              ; Otherwise we just braked a little too hard, so bump
                        ; the speed back up to the minimum value of 1

.MA4

 LDA KY15               ; If "U" is being pressed and the number of missiles
 AND NOMSL              ; in NOMSL is non-zero, keep going, otherwise jump down
 BEQ MA20               ; to MA20 to skip the following

 LDY #&EE               ; The "disarm missiles" key is being pressed, so call
 JSR ABORT              ; ABORT to disarm the missile and update the missile
                        ; indicators on the dashboard

 LDA #40                ; Call the NOISE routine with A = 40 to make a low,
 JSR NOISE              ; long beep to indicate the missile is now disarmed

.MA31

 LDA #0                 ; Set MSAR to 0 to indicate that no missiles are
 STA MSAR               ; currently armed

.MA20

 LDA MSTG               ; If MSTG is positive (i.e. does not have bit 7 set),
 BPL MA25               ; then it indicates we already have a missile locked on
                        ; a target (in which case MSTG contains the ship number
                        ; of the target), so jump to MA25 to skip targetting (or
                        ; put another way, if MSTG = &FF, which means there is
                        ; no current target lock, keep going)

 LDA KY14               ; If "T" is being pressed, keep going, otherwise jump
 BEQ MA25               ; down to MA25 to skip the following

 LDX NOMSL              ; If the number of missiles in NOMSL is zero, jump down
 BEQ MA25               ; to MA25 to skip the following

 STA MSAR               ; The "target missile" key is being pressed and we have
                        ; at least one missile, so set MSAR = &FF to denote that
                        ; our missile is currently armed (we know A has the
                        ; value &FF, as we just loaded it from MSTG and checked
                        ; that it was negative)

 LDY #&E0               ; Change the leftmost missile indicator to yellow on the
 JSR MSBAR              ; missile bar (this changes the leftmost indicator
                        ; because we set X to the number of missiles in NOMSL
                        ; above, and the indicators are numbered from right to
                        ; left, so X is the number of the leftmost indicator)

.MA25

 LDA KY16               ; If "M" is being pressed, keep going, otherwise jump
 BEQ MA24               ; down to MA24 to skip the following

 LDA MSTG               ; If MSTG = &FF there is no target lock, so jump to
 BMI MA64               ; MA64 to skip the following (skipping the checks for
                        ; Tab, Escape, "J" and "E")

 JSR FRMIS              ; The "fire missile" key is being pressed and we have
                        ; a missile lock, so call the FRMIS routine to fire
                        ; the missile

.MA24

 LDA KY12               ; If Tab is being pressed, keep going, otherwise jump
 BEQ MA76               ; jump down to MA76 to skip the following

 ASL BOMB               ; The "energy bomb" key is being pressed, so double
                        ; the value in BOMB (so if we have an energy bomb
                        ; fitted, BOMB now contains %11111110, or -2, otherwise
                        ; it still contains 0). The bomb explosion is dealt
                        ; with in the MAL1 routine below - this just registers
                        ; the fact that we've set the bomb ticking.

.MA76

 LDA KY13               ; If Escape is being pressed and we have an escape pod
 AND ESCP               ; fitted, keep going, otherwise skip the next
 BEQ P%+5               ; instruction

 JMP ESCAPE             ; The "launch escape pod" button is being pressed and
                        ; we have an escape pod fitted, so jump to ESCAPE to
                        ; launch it

 LDA KY18               ; If "J" is being pressed, keep going, otherwise skip
 BEQ P%+5               ; the next instruction

 JSR WARP               ; Call the WARP routine to do an in-system jump

 LDA KY17               ; If "E" is being pressed and we have an E.C.M. fitted,
 AND ECM                ; keep going, otherwise jump down to MA64 to skip the
 BEQ MA64               ; following

 LDA ECMA               ; If ECMA is non-zero, that means an E.C.M. is already
 BNE MA64               ; operating and is counting down (this can be either
                        ; our E.C.M. or an opponent's), so jump down to MA64 to
                        ; skip the following (as we can't have two E.C.M.s
                        ; operating at the same time)

 DEC ECMP               ; The "E.C.M." button is being pressed and nobody else
                        ; is operating their E.C.M., so decrease the value of
                        ; ECMP to make it non-zero, to denote that our E.C.M.
                        ; is now on

 JSR ECBLB2             ; Call ECBLB2 to light up the E.C.M. indicator bulb on
                        ; the dashboard, set the E.C.M. countdown timer to 32,
                        ; and start making the E.C.M. sound

.MA64

 LDA KY19               ; If "C" is being pressed, we have a docking computer
 AND DKCMP              ; fitted, and we are inside the space station's safe
 AND SSPR               ; zone, keep going, otherwise jump down to MA68 to
 BEQ MA68               ; skip the following

 LDA K% + NI% + 32      ; Fetch the AI counter (byte 32) of the second ship
 BMI MA68               ; in the ship data workspace at K%, which is reserved
                        ; for the sun or the space station (in this case it's
                        ; the latter), and if it's negative, meaning the
                        ; station is angry with us, jump down to MA68 to skip
                        ; the following (so we can't use the docking computer
                        ; to dock at a station that we have annoyed)

 JMP GOIN               ; The "docking computer" button has been pressed and
                        ; we are allowed to dock at the station, so jump to
                        ; GOIN to dock (or "go in")

.MA68

 LDA #0                 ; Set LAS = 0, to switch the laser off while we do the
 STA LAS                ; following logic

 STA DELT4              ; Take the 16-bit value (DELTA 0) - i.e. a two-byte
 LDA DELTA              ; number with DELTA as the high byte and 0 as the low
 LSR A                  ; byte - and divide it by 4, storing the 16-bit result
 ROR DELT4              ; in (DELT4 DELT4+1). This is the same as storing the
 LSR A                  ; current speed * 64 in the 16-bit location DELT4.
 ROR DELT4
 STA DELT4+1

 LDA LASCT              ; If LASCT is zero, keep going, otherwise the laser is
 BNE MA3                ; a pulse laser that is between pulses, so jump down to
                        ; MA3 to skip the following

 LDA KY7                ; If "A" is being pressed, keep going, otherwise jump
 BEQ MA3                ; down to MA3 to skip the following

 LDA GNTMP              ; If the laser temperature >= 242 then the laser has
 CMP #242               ; overheated, so jump down to MA3 to skip the following
 BCS MA3

 LDX VIEW               ; If the current space has a laser fitted (i.e. the
 LDA LASER,X            ; laser power for this view is greater than zero),
 BEQ MA3                ; then keep going, otherwise jump down to MA3 to skip
                        ; the following

                        ; If we get here, then the "fire" button is being
                        ; pressed, our laser hasn't overheated and isn't
                        ; already beign fired, and we actually have a laser
                        ; fitted to the current space view, so it's time to hit
                        ; me with those laser beams

 PHA                    ; Store the current view's laser power on the stack

 AND #%01111111         ; Set LAS and LAS2 to bits 0-6 of the laser power
 STA LAS
 STA LAS2

 LDA #0                 ; Call the NOISE routine with A = 0 to make the sound
 JSR NOISE              ; of our laser firing

 JSR LASLI              ; Draw laser lines

 PLA                    ; Restore the current view's laser power into A

 BPL ma1                ; If the laser power has bit 7 set, it's an "always
                        ; on" laser, so keep going, otherwise jump down to ma1
                        ; to skip the following instruction

 LDA #0                 ; This is an "always on" laser (i.e. a beam laser,
                        ; as tape Elite doesn't have military lasers), so
                        ; set A = 0, which will be stored in LASCT to denote
                        ; that this is not a pulsing laser

.ma1

 AND #%11111010         ; LASCT will be set to 0 for beam lasers, and to the
 STA LASCT              ; laser power AND %11111010 for pulse lasers, which
                        ; comes to 10 (as pulse lasers have a power of 15). See
                        ; MA23 below for more on laser pulsing and LASCT.
                        
\ ******************************************************************************
\ Subroutine: M% (Part 4)
\
\ Other entry points: MAL1
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Start looping through all the ships in the local bubble, and for each
\     one:
\
\     * Copy the ship's data block from K% to INWK
\ ******************************************************************************

.MA3

 LDX #0                 ; We're about to work our way through all the ships in
                        ; our little bubble of universe, so set a counter in X,
                        ; starting from 0, to refer to each ship slot in turn

.^MAL1

 STX XSAV               ; Store the slot number in XSAV

 LDA FRIN,X             ; Fetch the contents of this slot into A. If it is 0
 BNE P%+5               ; then this slot is empty and we have no more ships to
 JMP MA18               ; process, so jump tp MA18 below, otherwise A contains
                        ; the type of ship in this slot, so skip the JMP MA18
                        ; and keep going

 STA TYPE               ; Store the ship type in TYPE

 JSR GINF               ; Get the address of the data block for ship number X
                        ; and store it in INF

                        ; Next we want to copy the ship data from INF to the
                        ; local workspace at INWK, so we can process it

 LDY #NI%-1             ; There are NI% bytes in the INWK workspace, so set a
                        ; counter in Y so we can loop through them

.MAL2

 LDA (INF),Y            ; Load the Y-th byte of INF and store it in the Y-th
 STA INWK,Y             ; byte of INWK

 DEY                    ; Decrement the loop counter

 BPL MAL2               ; Loop back for the next byte, ending when we have
                        ; copied the last byte from INF to INWK

 LDA TYPE               ; If the ship type is negative then this indicates a
 BMI MA21               ; planet or sun, so jump down to MA21, as the next
                        ; section sets up a ship data block, which doesn't
                        ; apply to planets and suns

 ASL A                  ; Set Y = ship type * 2
 TAY

 LDA XX21-2,Y           ; The ship blueprints at XX21 start with a lookup
 STA XX0                ; table that points to the individual ship blueprints,
                        ; so this fetches the low byte of this particular ship
                        ; type's blueprint and stores it in XX0

 LDA XX21-1,Y           ; Fetch the high byte of this particular ship type's 
 STA XX0+1              ; blueprint and store it in XX0+1

\ ******************************************************************************
\ Subroutine: M% (Part 5)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * If an energy bomb has been set off and this ship can be killed, kill it
\       and increase the kill tally
\ ******************************************************************************

 LDA BOMB               ; If we set off our energy bomb by pressing Tab (see
 BPL MA21               ; MA24 above), then BOMB is now negative, so this skips
                        ; to MA21 if our energy bomb is not going off

 CPY #2*SST             ; If the ship in Y is the space station, jump to BA21
 BEQ MA21               ; as energy bombs have no effect on space stations

 LDA INWK+31            ; If the ship we are checking has bit 5 set in their
 AND #%00100000         ; INWK+31 byte, then they are already exploding, so 
 BNE MA21               ; jump to BA21 as they can't explode more than once

 LDA INWK+31            ; The energy bomb is killing this ship, so set bit 7
 ORA #%10000000         ; of the ship's INWK+31 byte to indicate that it has
 STA INWK+31            ; now been killed

 JSR EXNO2              ; Call EXNO2 to process the fact that we have killed a
                        ; ship (so increase the kill tally, make an explosion
                        ; noise and so on)

\ ******************************************************************************
\ Subroutine: M% (Part 6)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Move the ship in space and update K% with the new data
\ ******************************************************************************

.MA21

 JSR MVEIT              ; Move the ship we are processing in space

 LDY #(NI%-1)           ; Now that we are done processing this ship, we need
                        ; to copy the ship data back from INWK to INF, so set
                        ; a counter in Y so we can loop through the NI% bytes
                        ; once again

.MAL3

 LDA INWK,Y             ; Load the Y-th byte of INWK and store it in the Y-th
 STA (INF),Y            ; byte of INF

 DEY                    ; Decrement the loop counter

 BPL MAL3               ; Loop back for the next byte, ending when we have
                        ; copied the last byte from INWK back to INF

\ ******************************************************************************
\ Subroutine: M% (Part 7)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Check how close we are to this ship and work out if we are docking,
\       scooping or colliding with it
\ ******************************************************************************

 LDA INWK+31            ; Fetch the status of this ship from bits 5 (is ship
 AND #%10100000         ; exploding?) and bit 7 (has ship been killed?) from
                        ; INWK+31 into A

 JSR MAS4               ; Or this value with x_hi, y_hi and z_hi

 BNE MA65               ; If this value is non-zero, then either the ship is
                        ; far away (i.e. has a non-zero high byte in at least
                        ; one of the three axes), or it is already exploding,
                        ; or has been flagged as being killed - in which case
                        ; jump to MA65 to skip the following

 LDA INWK               ; Set A = (x_lo OR y_lo OR z_lo), and if bit 7 of the
 ORA INWK+3             ; result is set, the ship is still a fair distance
 ORA INWK+6             ; away, so jump to MA65 to skip the following
 BMI MA65

 LDX TYPE               ; If the ship type is negative then this indicates a
 BMI MA65               ; planet or sun, so jump down to MA65 to skip the
                        ; following

 CPX #SST               ; If this ship is the space station, jump to ISDK to
 BEQ ISDK               ; check for docking

 AND #%11000000         ; If bit 6 of (x_lo OR y_lo OR z_lo) is set, then we
 BNE MA65               ; are still a reasonable distance away, so jump to
                        ; MA65 to skip the following

 CPX #MSL               ; If this ship is a missile, jump down to MA65 to skip
 BEQ MA65               ; the following

 CPX #OIL               ; If ship type >= OIL (i.e. it's a cargo canister,
 BCS P%+5               ; Thargon or escape pod), skip the JMP instruction and
 JMP MA58               ; continue on, otherwise jump to MA58 to process a
                        ; collision

 LDA BST                ; If we have fuel scoops fitted then BST will be 127,
                        ; otherwise it will be 0

 AND INWK+5             ; INWK+5 contains the y_sign of this ship, so a -1 here
                        ; means the canister is below us, so this result will
                        ; be negative if the canister is below us and we have a
                        ; fuel scoop fitted

 BPL MA58               ; If the result is positive, then we either have no
                        ; scoop or the canister is above us, and in both cases
                        ; this means we can't scoop the item, so jump to MA58
                        ; to process a collision

\ ******************************************************************************
\ Subroutine: M% (Part 8)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Process scooping of items
\ ******************************************************************************

 LDA #3                 ; Set A to 3 to denote we may be scooping an escape pod

 CPX #TGL               ; If ship type < Thargon, i.e. it's a canister, jump
 BCC oily               ; to oily to scoop the canister

 BNE slvy2              ; If ship type <> Thargon, i.e. it's an escape pod,
                        ; jump to slvy2 with A = 3

 LDA #16                ; Otherwise this is a Thargon, so jump to slvy2 with
 BNE slvy2              ; A = 16 (this BNE is effectively a JMP as A will never
                        ; be zero)

.oily

 JSR DORND              ; Set A and X to random numbers and reduce A to a
 AND #7                 ; random number in the range 0-7

.slvy2                  ; By the time we get here, we are scooping, and A
                        ; contains the type of item we are scooping (a random
                        ; number 0-7 if we are scooping a cargo canister, 3 if
                        ; we are scooping an escape pod, or 16 if we are
                        ; scooping a Thargon). These numbers correspond to the
                        ; relevant market items (see QQ23 for a list), so a
                        ; cargo canister can contain anything from food to
                        ; computers, while escape pods contain slaves, and
                        ; Thargons become alien items when scooped

 STA QQ29               ; Call tnpr with the scooped cargo type stored in QQ29
 LDA #1                 ; and A = 1 to work out whether we have room in the
 JSR tnpr               ; hold for the scooped item (A is preserved by this
                        ; call, and the carry flag contains the result)

 LDY #78                ; This instruction has no effect, so presumably it used
                        ; to do something, and didn't get removed

 BCS MA59               ; If carry is set then we have no room in the hold for
                        ; the scooped item, so jump down to MA59 make a noise
                        ; to indicate failure, and destroy the canister

 LDY QQ29               ; Scooping was successful, so set Y to the type of
                        ; item we just scooped

 ADC QQ20,Y             ; Add A to the number of items of type Y in the cargo
 STA QQ20,Y             ; hold, as we just successfully scooped A units of Y

 TYA                    ; Print recursive token 48 + A as an in-flight token,
 ADC #208               ; which will be in the range 48 ("FOOD") to 64 ("ALIEN
 JSR MESS               ; ITEMS"), so this prints the scooped item's name

 JMP MA60               ; We are done scooping, so jump down to MA60 to
                        ; set the kill flag on the canister, as it no longer
                        ; exists in the local bubble

.MA65

 JMP MA26               ; If we get here, then the ship we are processing was
                        ; too far away to be scooped, docked or collided with,
                        ; so jump to MA26 to skip over the collision routines
                        ; and to move on to missile targeting

\ ******************************************************************************
\ Subroutine: M% (Part 9)
\
\ Other entry points: GOIN
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Process docking with space station
\
\ ******************************************************************************
\
\ The following routine does five tests to confirm whether we are docking
\ safely, as opposed to slamming into the sides of the space station, leaving
\ a trail of sparks and dented pride. They are:
\
\   1. Make sure the station isn't hostile.
\
\   2. Make sure our ship is pointed in the right direction, by checking that
\      our angle of approach is less than 26 degrees off the perfect, head-on
\      approach.
\
\   3. Confirm that we are moving towards the centre of the space station.
\
\   4. Confirm that we are within a small "cone" of safe approach.
\
\   5. Unsure at this point - needs more investigation.
\
\ Here's a further look at the more complicated of these tests.
\
\ 2. Check the angle of approach
\ ------------------------------
\ The space station's ship data is in INWK. The rotmat0 vector in INWK+9 to
\ INWK+14 is the station's forward-facing normal vector, and it's perpendicular
\ to the face containing the slot, pointing straight out into space out of the
\ docking slot. You can see this in the diagram on the left, which is a side-on
\ view of the station, with us approaching at a jaunty angle from the top-right,
\ with the docking slot on the top face of the station. You can imagine this
\ vector as a big stick, sticking out of the slot.
\
\       rotmat0
\          ^         ship
\          :       /
\          :      /
\          :     L
\          :    /
\          : t / <--- approach
\          :  /       vector
\          : /
\          :/
\     ____====____
\    /     /\     \
\   |    /    \    |
\   |  /        \  |
\   : . station  . :
\
\ We want to check whether the angle t is too large, because if it is, we are
\ coming in at the wrong angle and will probably bounce off the front of the
\ space station. To find out the value of t, we need to look at the geometry
\ of ths situation.
\
\ The station's normal vector has length 1, because it's a unit vector. We
\ actually store a 1 in a unit vector as &6000, because this means we don't
\ have to deal with fractions. We can also just consider the high byte of
\ this figure, so 1 has a high byte of &60 when we're talking about vectors
\ like the station's normal vector.
\
\ So the normal vector is a big stick, poking out of the slot, with a length of
\ 1 unit (stored as a high byte of &60 internally).
\
\ Now, if that vector was coming perpendicularly out of the screen towards us,
\ we would be on a perfect approach angle, the stick would be poking in our
\ face, and the length of the stick in our direction would be the full length
\ of 1, or &60. However, if our angle of approach is off by a bit, then the
\ normal vector won't be pointing straight at us, and the end of the stick will
\ be further away from us - less "in our face", if you like.
\
\ In other words, the end of the stick is less in our direction, or to put it
\ yet another way, it's not so far towards us along the z-axis, which goes in
\ and out of the screen.
\
\ Or, to put it mathematically, the z-coordinate of the end of the stick, or
\ rotmat0z, is smaller when our approach angle is off. The routine below uses
\ this method to see how well we are approaching the slot, by comparing rotmat0z
\ with &D6, so what does that mean?
\
\ We can draw a triangle showing this whole stick-slot situation, like this. The
\ left triangle is from the diagram above, while the triangle on the right is
\ the same triangle, rotated slightly to the left:
\
\          ^         ship                 ________  ship
\          :       /                      \       |
\          :      /                        \      |
\          :     L                          \     v
\          :    /                         1  \    | rotmat0z
\          : t /                              \ t |
\          :  /                                \  |
\          : /                                  \ |
\          :/                                    \|
\          + station                              + station
\
\ The stick is the left edge of each triangle, poking out of the slot at the
\ bottom, and the ship is at the top, looking down towards the slot. We know
\ that the right-hand edge of the triangle - the adjacent side - has length
\ rotmat0z, while the hypotenuse is the length of the space station's vector, 1
\ (stored as &60). So we can do some trigonometry, like this, if we just
\ consider the high bytes of our vectors:
\
\   cos(t) = adjacent / hypotenuse
\          = rotmat0z_hi / &60
\
\ so:
\
\   rotmat0z_hi = &60 * cos(t)
\
\ We need our approach angle to be off by less than 26 degrees, so this
\ becomes the following, if we round down the result to an integer:
\
\   rotmat0z_hi = &60 * cos(26)
\               = &56
\
\ So, we get this:
\
\   The angle of approach is less than 26 degrees if rotmat0z_hi >= &56
\
\ There is one final twist, however, because we are approaching the slot head
\ on, the z-zxis from our perspective points into the screen, so that means
\ the station normal vector is coming out of the screen towards us, so it has
\ a negative z-coordinate. So the station normal vector in this case is
\ actually in the reverse direction, so we need to reverse the check and set
\ the sign bit, to this:
\
\   The angle of approach is less than 26 degrees if rotmat0z_hi <= &D6
\
\ And that's the check we make below to make sure our docking angle is correct.
\
\ 4. Cone of safe approach
\ ------------------------
\ This is similar to the angle-of-approach check, but where check 2 only looked
\ at the orientation of our ship, this check makes sure we are in the right
\ place in space. That place is within a cone that extends out from the slot
\ and into space, and we can check where we are in that cone by checking the
\ angle of the vector between our position and the space station.
\ ******************************************************************************

.ISDK

 LDA K% + NI% + 32      ; 1. Fetch the AI counter (byte 32) of the second ship
 BMI MA62               ; in the ship data workspace at K%, which is reserved
                        ; for the sun or the space station (in this case it's
                        ; the latter), and if it's negative, meaning the
                        ; station is angry with us, jump down to MA62 to fail
                        ; docking (so trying to dock at a station that we have
                        ; annoyed does not end well)

 LDA INWK+14            ; 2. If rotmat0z_hi < &D6, jump down to MA62 to fail
 CMP #&D6               ; docking, as the angle of approach is greater than 26
 BCC MA62               ; degrees (see the notes on test 2 above)

 JSR SPS4               ; Call SPS4 to get the vector to the space station
                        ; into XX15

 LDA XX15+2             ; 3. Check the sign of the z-axis (bit 7 of XX15+2) and
 BMI MA62               ; if it is negative, we are facing away from the
                        ; station, so jump to MA62 to fail docking

 CMP #&59               ; 4. If z-axis < &59, jump to MA62 to fail docking
 BCC MA62

 LDA INWK+16            ; 5. If |rotmat1x_hi| < &50, jump to MA62 to fail
 AND #%01111111         ; docking
 CMP #&50               ; Is this something to do with matching the slot
 BCC MA62               ; rotation?

.^GOIN                  ; If we arrive here, either the docking computer has
                        ; been activated, or we just docked successfully

 LDA #0                 ; Set the on-screen hyperspace counter to 0
 STA QQ22+1

 LDA #8                 ; This instruction has no effect, so presumably it used
                        ; to do something, and didn't get removed

 JSR LAUN               ; Show the space station launch tunnel

 JSR RES4               ; Reset the shields and energy banks, stardust and INWK
                        ; workspace

 JMP BAY                ; Go to the docking bay (i.e. show the Status Mode
                        ; screen)

.MA62                   ; If we arrive here, docking has just failed

 LDA DELTA              ; If the ship's speed is < 5, jump to MA67 to register
 CMP #5                 ; some damage, but not a huge amount
 BCC MA67

 JMP DEATH              ; Otherwise we have just crashed into the station, so
                        ; process our death

\ ******************************************************************************
\ Subroutine: M% (Part 10)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Remove scooped item after both successful and failed scoopings
\
\     * Process collisions
\ ******************************************************************************

.MA59                   ; If we get here then scooping failed

 JSR EXNO3              ; Make the sound of the cargo canister being destroyed
                        ; and fall through into MA60 to remove the canister
                        ; from our local bubble

.MA60                   ; If we get here then scooping was successful

 ASL INWK+31            ; Set bit 7 of the scooped or destroyed item, to denote
 SEC                    ; that it has been killed and should be removed from
 ROR INWK+31            ; the local bubble

.MA61                   ; This label is not used but is in the original source

 BNE MA26               ; Jump to MA26 to skip over the collision routines and
                        ; to move on to missile targeting (this BNE is
                        ; effectively a JMP as A will never be zero)

.MA67                   ; If we get here then we have collided with something,
                        ; but not fatally

 LDA #1                 ; Set the speed in DELTA to 1 (i.e. a sudden stop)
 STA DELTA
 LDA #5                 ; Set the amount of damage in A to 5 (a small dent) and
 BNE MA63               ; jump down to MA63 to process the damage (this BNE is
                        ; effectively a JMP as A will never be zero)

.MA58                   ; If we get here, we have collided with something in a
                        ; fatal way

 ASL INWK+31            ; Set bit 7 of the ship we just collided with, to
 SEC                    ; denote that it has been killed and should be removed
 ROR INWK+31            ; from the local bubble

 LDA INWK+35            ; Load A with the energy level of the ship we just hit

 SEC                    ; Set the amount of damage in A to 128 + A / 2, so
 ROR A                  ; this is quite a big dent, and colliding with higher
                        ; energy ships will cause more damage

.MA63

 JSR OOPS               ; The amount of damage is in A, so call OOPS to reduce
                        ; our shields, and if the shields are gone, there's a
                        ; a chance of cargo loss or even death

 JSR EXNO3              ; Make the sound of colliding with the other ship and
                        ; fall through into MA26 to try targeting a missile

\ ******************************************************************************
\ Subroutine: M% (Part 11)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Process missile lock
\
\     * Process our laser firing
\ ******************************************************************************

.MA26

 LDA QQ11               ; If this is not a space view, jump to MA15 to skip
 BNE MA15               ; missile and laser locking

 JSR PLUT               ; Call PLUT to update the geometric axes in INWK to
                        ; match the view (forward, rear, left, right)

 JSR HITCH              ; Call HITCH to see if this ship is in the cross-hairs,
 BCC MA8                ; in which case carry will be set (so if there is no
                        ; missile or laser lock, we jump to MA8 to skip the
                        ; following)

 LDA MSAR               ; We have missile lock, so check whether the leftmost
 BEQ MA47               ; missile is currently armed, and if not, jump to MA47
                        ; to process laser fire, as we can't lock an unarmed
                        ; missile

 JSR BEEP               ; We have missile lock and an armed missile, so call
                        ; the BEEP subroutine to make a short, high beep

 LDX XSAV               ; Call ABORT2 to store the details of this missile
 LDY #&E                ; lock, with the targeted ship's slot number in X
 JSR ABORT2             ; (which we stored in XSAV at the start of this ship's
                        ; loop at MAL1), and set the colour of the misile
                        ; indicator to the colour in Y (red = &0E)

.MA47                   ; If we get here then the ship is in our sights, but
                        ; we didn't lock a missile, so let's see if we're
                        ; firing the laser

 LDA LAS                ; If we are firing the laser then LAS will contain the
 BEQ MA8                ; laser power (which we set in MA68 above), so if this
                        ; is zero, jump down to MA8 to skip the following

 LDX #15                ; We are firing our laser and the ship in INWK is in
 JSR EXNO               ; the cross-hairs, so call EXNO to make the sound of
                        ; us making a laser strike on another ship

 LDA INWK+35            ; Fetch the hit ship's energy from INWK+35 and subtract
 SEC                    ; our current laser power, and if the result is greater
 SBC LAS                ; than zero, the other ship has survived the hit, so
 BCS MA14               ; jump down to MA14

 LDA TYPE               ; Did we just hit the space station? If so, jump to
 CMP #SST               ; MA14+2 to make the station hostile, skipping the
 BEQ MA14+2             ; following as we can't destroy a space station

 LDA INWK+31            ; Set bit 7 of the enemy ship's INWK+31 flag, to
 ORA #%10000000         ; to indicate that it has been killed
 STA INWK+31

 BCS MA8                ; If the enemy ship type is >= SST (i.e. missile,
                        ; asteroid, canister, Thargon or escape pod) then
                        ; jump down to MA8

 JSR DORND              ; Fetch a random number, and jump to oh if it is
 BPL oh                 ; positive (50% chance)

 LDY #0                 ; Fetch the first byte of the hit ship's blueprint,
 AND (XX0),Y            ; which determines the maximum number of bits of
                        ; debris shown when the ship is destroyed, and AND
                        ; with the random number we just fetched

 STA CNT                ; Store the result in CNT, so CNT contains a random
                        ; number between 0 and the maximum number of bits of
                        ; debris that this ship will release when destroyed

.um

 BEQ oh                 ; We're going to go round a loop using CNT as a counter
                        ; so this checks whether the counter is zero and jumps
                        ; to oh when it gets there (which might be straight
                        ; away)

 LDX #OIL               ; Call SFS1 to spawn a cargo canister from the now
 LDA #0                 ; deceased parent ship, giving the spawned canister an
 JSR SFS1               ; AI flag of 0 (no AI)

 DEC CNT                ; Decrease the loop counter

 BPL um                 ; Jump back up to um (this BPL is effectively a JMP as
                        ; CNT will never be negative)


.oh

 JSR EXNO2              ; Call EXNO2 to process the fact that we have killed a
                        ; ship (so increase the kill tally, make an explosion
                        ; noise and so on)

.MA14

 STA INWK+35            ; Store the hit ship's updated energy in INWK+35

 LDA TYPE               ; Call ANGRY to make this ship hostile, now that we
 JSR ANGRY              ; have hit it

\ ******************************************************************************
\ Subroutine: M% (Part 12)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Continue looping through all the ships in the local bubble, and for each
\     one:
\
\     * Draw the ship
\
\     * Process removal of killed ships
\
\   * Loop back up to MAL1 to move onto the next ship in the local bubble
\ ******************************************************************************

.MA8

 JSR LL9                ; Call LL9 to draw the ship we're processing on screen

.MA15

 LDY #35                ; Fetch the ship's energy from INWK+35 and copy it to
 LDA INWK+35            ; byte 35 in INF (so the ship's data in K% gets
 STA (INF),Y            ; updated)

 LDA INWK+31            ; If bit 7 of the ship's INWK+31 byte is clear, then
 BPL MAC1               ; the ship hasn't been killed by energy bomb, collision
                        ; or laser fire, so jump to MAC1 to skip the following

 AND #%00100000         ; If bit 5 of the ship's INWK+31 byte is clear then the
 BEQ NBOUN              ; ship is no longer exploding, so jump to NBOUN to skip
                        ; the following

 LDA TYPE               ; If the ship we just destroyed was a cop, keep going,
 CMP #COPS              ; otherwise jump to q2 to skip the following
 BNE q2

 LDA FIST               ; We shot the sheriff, so update our FIST flag
 ORA #64                ; ("fugitive/ innocent status") to at least 64, which
 STA FIST               ; will instantly make us a fugitive

.q2

 LDA DLY                ; If we already have an in-flight message on screen (in
 ORA MJ                 ; which case DLY > 0), or we are in witchspace (in
 BNE KS1S               ; which case MJ > 0), jump to KS1S to skip showing an
                        ; on-screen bounty for this kill

 LDY #10                ; Fetch byte #10 of the ship's blueprint, which is the
 LDA (XX0),Y            ; low byte of the bounty awarded when this ship is
 BEQ KS1S               ; killed (in Cr * 10), and if it's zero jump to KS1S as
                        ; there is no on-screen bounty to display

 TAX                    ; Put the low byte of the bounty into X

 INY                    ; Fetch byte #11 of the ship's blueprint, which is the
 LDA (XX0),Y            ; high byte of the bounty awarded (in Cr * 10), and put
 TAY                    ; it into Y

 JSR MCASH              ; Call MCASH to add (Y X) to the cash pot

 LDA #0                 ; Print control code 0 (current cash, right-aligned to
 JSR MESS               ; width 9, then " CR", newline) as an in-flight message

.KS1S

 JMP KS1                ; Process the killing of this ship (which removes this
                        ; ship from its slot and shuffles all the other ships
                        ; down to close up the gap)

.NBOUN

.MAC1

 LDA TYPE               ; If the ship we are processing is a planet or sun,
 BMI MA27               ; jump to MA27 to skip the following two instructions

 JSR FAROF              ; If the ship we are processing is a long way away (its
 BCC KS1S               ; distance in any one direction is > &E0, jump to KS1S
                        ; to remove the ship from our local bubble, as it's just
                        ; left the building

.MA27

 LDY #31                ; Fetch the ship's explosion/killed state from INWK+31
 LDA INWK+31            ; and copy it to byte 31 in INF (so the ship's data in
 STA (INF),Y            ; K% gets updated)

 LDX XSAV               ; We're done processing this ship, so fetch the ship's
                        ; slot number, which we saved in XSAV back at the start
                        ; of the loop

 INX                    ; Increment the slot number to move on to the next slot

 JMP MAL1               ; And jump back up to the beginning of the loop to get
                        ; the next ship in the local bubble for processing

\ ******************************************************************************
\ Subroutine: M% (Part 13)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Show energy bomb effect (if applicable)
\
\   * Charge shields and energy banks (every 7 iterations of the main loop)
\ ******************************************************************************

.MA18

 LDA BOMB               ; If we set off our energy bomb by pressing Tab (see
 BPL MA77               ; MA24 above), then BOMB is now negative, so this skips
                        ; to MA77 if our energy bomb is not going off

 ASL BOMB               ; We set off our energy bomb, so rotate BOMB to the
                        ; left by one place. BOMB was rotated left once already
                        ; during this iteration of the main loop, back at MA24,
                        ; so if this is the first pass it will already be
                        ; %11111110, and this will shift it to %11111100 - so
                        ; if we set off an energy bomb, it stays activated
                        ; (BOMB > 0) for four iterations of the main loop

 JSR WSCAN              ; Wait for the vertical sync, so the whole screen has
                        ; been drawn and the following palette change won't
                        ; kick in while the screen is still refreshing

 LDA #%00110000         ; Set the palette byte at SHEILA+&21 to map logical
 STA SHEILA+&21         ; colour 0 to physical colour 7 (white), but with only
                        ; one mapping (rather than the 7 mappings requires to
                        ; do the mapping properly). This makes the space screen
                        ; flash with black and white stripes. See p.382 of the
                        ; Advanced User Guide for details of why this single
                        ; palette change creates a special effect.

.MA77

 LDA MCNT               ; Fetch the main loop counter and look at bits 0-2,
 AND #%00000111         ; jumping to MA22 if they are zero (so the following
 BNE MA22               ; section only runs every 8 iterations of the main loop)

 LDX ENERGY             ; Fetch our ship's energy levels and skip to b if bit 7
 BPL b                  ; is not set, i.e. only charge the shields from the
                        ; energy banks if they are at more than 50% charge

 LDX ASH                ; Call SHD to recharge our aft shield and update the
 JSR SHD                ; shield status in ASH
 STX ASH

 LDX FSH                ; Call SHD to recharge our forward shield and update
 JSR SHD                ; the shield status in FSH
 STX FSH

.b

 SEC                    ; Set A = ENERGY + ENGY + 1, so our ship's energy
 LDA ENGY               ; level goes up by 2 if we have an energy unit fitted,
 ADC ENERGY             ; otherwise it goes up by 1

 BCS P%+5               ; If the value of A did not overflow (the maximum
 STA ENERGY             ; energy level is &FF), then store A in ENERGY

\ ******************************************************************************
\ Subroutine: M% (Part 14)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Spawn a space station if we are close enough to the planet (every 32
\     iterations of the main loop)
\ ******************************************************************************

 LDA MJ                 ; If we are in witchspace, jump down to MA23S to skip
 BNE MA23S              ; the following, as there are no space stations in
                        ; witchspace

 LDA MCNT               ; Fetch the main loop counter and look at bits 0-4,
 AND #%00011111         ; jumping to MA93 if they are zero (so the following
 BNE MA93               ; section only runs every 32 iterations of the main loop)

 LDA SSPR               ; If we are inside the space station safe zone, jump to
 BNE MA23S              ; MA23S to skip the following, as we already have a
                        ; space station and don't need another

 TAY                    ; Set Y = A = 0 (A is 0 as we didn't branch with the
                        ; previous BNE instruction)

 JSR MAS2               ; Call MAS2 to calculate the largest distance to the
 BNE MA23S              ; planet in any of the three axes, and if it's
                        ; non-zero, jump to MA23S to skip the following, as we
                        ; are too far from the planet to bump into a space
                        ; station

                        ; We now want to spawn a space station, so first we
                        ; need to set up a ship data block for the station in
                        ; INWK that we can then pass to NWSPS to add a new
                        ; station to our bubble of universe. We do this by
                        ; copying the planet data block from K% to INWK so we
                        ; can work on it, but we only need the first 29 bytes,
                        ; as we don't need to worry about INWK+29 to INWK+35
                        ; for planets (as they don't have rotation counters,
                        ; AI, explosions, missiles, a ship lines heap or energy
                        ; levels). 

 LDX #28                ; So we set a counter in X to copy 29 bytes from K%+0
                        ; to K%+28

.MAL4

 LDA K%,X               ; Load the X-th byte of K% and store in the X-th byte
 STA INWK,X             ; of the INWK workspace

 DEX                    ; Decrement the loop counter

 BPL MAL4               ; Loop back for the next byte until we have copied the
                        ; first 28 bytes of K% to INWK

                        ; We now check the distance from our ship (at the
                        ; origin) towards the planet's surface, by adding the
                        ; planet's rotmat0 vector to the planet's centre at
                        ; (x, y, z) and checking our distance to the end
                        ; point along the relevant axis

 INX                    ; Set X = 0 (as we ended the above loop with X as &FF)

 LDY #9                 ; Call MAS1 with X = 0, Y = 9 to do the following:
 JSR MAS1               ;
                        ; (x_sign x_hi x_lo) += (rotmat0x_hi rotmat0x_lo) * 2
                        ;
                        ; A = |x_hi|

 BNE MA23S              ; If A > 0, jump to MA23S to skip the following, as we
                        ; are too far from the planet in the x-direction to
                        ; bump into a space station

 LDX #3                 ; Call MAS1 with X = 3, Y = 11 to do the following:
 LDY #11                ;
 JSR MAS1               ; (y_sign y_hi y_lo) += (rotmat0y_hi rotmat0y_lo) * 2
                        ;
                        ; A = |y_hi|

 BNE MA23S              ; If A > 0, jump to MA23S to skip the following, as we
                        ; are too far from the planet in the y-direction to
                        ; bump into a space station

 LDX #6                 ; Call MAS1 with X = 6, Y = 13 to do the following:
 LDY #13                ;
 JSR MAS1               ; (z_sign z_hi z_lo) += (rotmat0z_hi rotmat0z_lo) * 2
                        ;
                        ; A = |z_hi|

 BNE MA23S              ; If A > 0, jump to MA23S to skip the following, as we
                        ; are too far from the planet in the z-direction to
                        ; bump into a space station

 LDA #&C0               ; Call FAROF2 to compare x_hi, y_hi and z_hi with &C0,
 JSR FAROF2             ; which will set the C flag if all three are < &C0, or
                        ; clear the C flag if any of them are >= &C0

 BCC MA23S              ; Jump to MA23S if any one of x_hi, y_hi or z_hi are
                        ; >= &C0 (i.e. they must all be < &C0 for us to be near
                        ; enough to the planet to bump into a space station)

 LDA QQ11               ; If the current view is a space view, call WPLS to
 BNE P%+5               ; remove the sun from the screen, as we can't have both
 JSR WPLS               ; the sun and the space station at the same time

 JSR NWSPS              ; Add a new space station to our little bubble of
                        ; universe

.MA23S

 JMP MA23               ; Jump to MA23 to skip the following planet and sun
                        ; altitude checks

\ ******************************************************************************
\ Subroutine: M% (Part 15)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Altitude check (every 32 iterations of the main loop, on iteration 10
\     of each 32)
\
\   * Sun altitude check and fuel scooping (every 32 iterations of the main
\     loop, on iteration 20 of each 32)
\ ******************************************************************************

.MA22

 LDA MJ                 ; If we are in witchspace, jump down to MA23 to skip
 BNE MA23               ; the following, as there are no planets or suns to
                        ; bump into in witchspace

 LDA MCNT               ; Fetch the main loop counter and look at bits 0-4,
 AND #%00011111         ; so this tells us the position of this loop in each
                        ; block of 32 iterations

.MA93

 CMP #10                ; If this is the tenth iteration in this block of 32,
 BNE MA29               ; do the following, otherwise jump to MA29 to skip the
                        ; planet altitude check and move on to the sun distance
                        ; check

 LDA #50                ; If our energy bank status in ENERGY is >= 50, skip
 CMP ENERGY             ; printing the following message (so the message is
 BCC P%+6               ; only shown if our energy is low)

 ASL A                  ; Print recursive token 100 ("ENERGY LOW{beep}") as an
 JSR MESS               ; in-flight message

 LDY #&FF               ; Set our altitude in ALTIT to &FF, the maximum
 STY ALTIT

 INY                    ; Set Y = 0

 JSR m                  ; Call m to calculate the maximum distance to the
                        ; planet in any of the three axes, returned in A
 
 BNE MA23               ; If A > 0 then we are a fair distance away from the
                        ; planet in at least one axis, so jump to MA23 to skip
                        ; the rest of the altitude check

 JSR MAS3               ; Set A = x_hi^2 + y_hi^2 + z_hi^2, so using Pythagoras
                        ; we now know that A now contains the square of the
                        ; distance between our ship (at the origin) and the
                        ; centre of the planet at (x_hi, y_hi, z_hi)

 BCS MA23               ; If the C flag was set by MAS3, then the result
                        ; overflowed (was greater than &FF) and we are still a
                        ; fair distance from the planet, so jump to MA23 as we
                        ; haven't crashed into the planet

 SBC #36                ; Subtract 36 from x_hi^2 + y_hi^2 + z_hi^2. The radius
                        ; of the planet is defined as 6 units and 6^2 = 36, so
                        ; A now contains the high byte of our altitude above
                        ; the planet surface, squared

 BCC MA28               ; If A < 0 then jump to MA28 as we have crashed into
                        ; the planet

 STA R                  ; We are getting close to the planet, so we need to
 JSR LL5                ; work out how close. We know from the above that A
                        ; contains our altitude squared, so we store A in R
                        ; and call LL5 to calculate:
                        ;
                        ;   Q = SQRT(R Q) = SQRT(A Q)
                        ;
                        ; Interestingly, Q doesn't appear to be set to 0 for
                        ; this calculation, so presumably this doesn't make a
                        ; difference

 LDA Q                  ; Store the result in ALTIT, our altitude
 STA ALTIT

 BNE MA23               ; If our altitude is non-zero then we haven't crashed,
                        ; so jump to MA23 to skip to the next section

.MA28

 JMP DEATH              ; If we get here then we just crashed into the planet
                        ; or got too close to the sun, so call DEATH to start
                        ; the funeral preparations

.MA29

 CMP #20                ; If this is the 20th iteration in this block of 32,
 BNE MA23               ; do the following, otherwise jump to MA23 to skip the
                        ; sun altitude check

 LDA #30                ; Set CABTMP to 30, the cabin temperature in deep space
 STA CABTMP             ; (i.e. one notch on the dashboard bar)

 LDA SSPR               ; If we are inside the space station safe zone, jump to
 BNE MA23               ; MA23 to skip the following, as we can't have both the
                        ; sun and space station at the same time, so we clearly
                        ; can't be flying near the sun

 LDY #NI%               ; Set Y to NI%, which is the offset in K% for the sun's
                        ; data block, as the second block at K% is reserved for
                        ; the sun (or space station)

 JSR MAS2               ; Call MAS2 to calculate the largest distance to the
 BNE MA23               ; sun in any of the three axes, and if it's non-zero,
                        ; jump to MA23 to skip the following, as we are too far
                        ; from the sun for scooping or temperature changes

 JSR MAS3               ; Set A = x_hi^2 + y_hi^2 + z_hi^2, so using Pythagoras
                        ; we now know that A now contains the square of the
                        ; distance between our ship (at the origin) and the
                        ; heart of the sun at (x_hi, y_hi, z_hi)

 EOR #%11111111         ; Invert A, so A is now small if we are far from the
                        ; sun and large if we are close to the sun, in the
                        ; range 0 = far away to &FF = extremely close, ouch,
                        ; hot, hot, hot!

 ADC #30                ; Add the minimum cabin temperature of 30, so we get
                        ; one of the following:
                        ;
                        ; If the C flag is clear, A contains the cabin
                        ; temperature, ranging from 30 to 255, that's hotter
                        ; the closer we are to the sun
                        ;
                        ; If the C flag is set, the addition has rolled over
                        ; and the cabin temperature is over 255

 STA CABTMP             ; Store the updated cabin temperature

 BCS MA28               ; If the C flag is set then jump to MA28 to die, as
                        ; our temperature is off the scale

 CMP #&E0               ; If the cabin temperature < 224 then jump to MA23 to
 BCC MA23               ; to skip fuel scooping, as we aren't close enough

 LDA BST                ; If we don't have fuel scoops fitted, jump to BA23 to
 BEQ MA23               ; skip fuel scooping, as we can't scoop without fuel
                        ; scoops

 LDA DELT4+1            ; We are now cuccessfully fuel scooping, so it's time
 LSR A                  ; to work out how much fuel we're scooping. Fetch the
                        ; high byte of DELT4, which contains our current speed
                        ; divided by 4, and halve it to get our current speed
                        ; divided by 8 (so it's now a value between 1 and 5, as
                        ; our speed is normally between 1 and 40). This gives
                        ; us the amount of fuel that's being scooped in A, so
                        ; the faster we go, the more fuel we scoop, and because
                        ; the fuel levels are stored as 10 * the fuel in light
                        ; years, that means we just scooped between 0.1 and 0.5
                        ; light years of free fuel

 ADC QQ14               ; Set A = A + the current fuel level * 10 (from QQ14)

 CMP #70                ; If A > 70 then set A = 70 (as 70 is the maximum fuel
 BCC P%+4               ; level, or 7.0 light years)
 LDA #70

 STA QQ14               ; Store the updated fuel level in QQ14

 LDA #160               ; Print recursive token 0 ("FUEL SCOOPS ON") as an
 JSR MESS               ; in-flight message

\ ******************************************************************************
\ Subroutine: M% (Part 16)
\
\ M% is called as part of the main game loop at TT100, and covers most of the
\ flight-specific aspects of Elite. This section of M% covers the following:
\
\   * Process laser pulsing
\
\   * Process E.C.M. energy drain
\
\   * Jump to the stardust routine if we are in space
\
\   * Return from the main flight loop
\ ******************************************************************************

.MA23

 LDA LAS2               ; If the current view has no laser, jump to MA16 to skip
 BEQ MA16               ; the following

 LDA LASCT              ; If LASCT >= 8, jump to MA16 to skip the following, so
 CMP #8                 ; for a pulse laser with a LASCT between 8 and 10, the
 BCS MA16               ; the laser stays on, but for a LASCT of 7 or less it
                        ; gets turned off and stays off until LASCT reaches zero
                        ; and the next pulse can start (if the fire button is
                        ; still being pressed).
                        ;
                        ; For pulse lasers, LASCT gets set to 10 in ma1 above,
                        ; and it decrements every vertical sync (50 times a
                        ; second), so this means it pulses five times a second,
                        ; with the laser being on for the first 3/10 of each
                        ; pulse and off for the rest of the pulse.
                        ;
                        ; If this is a beam laser, LASCT is 0 so we always keep
                        ; going here. This means the laser doesn't pulse, but it
                        ; does get drawn and removed every cycle, in a slightly
                        ; different place each time, so the beams still flicker
                        ; around the screen.

 JSR LASLI2             ; Redraw the existing laser lines, which has the effect
                        ; of removing them from the screen
 
 LDA #0                 ; Set LAS2 to 0 so if this is a pulse laser, it will
 STA LAS2               ; skip over the above until the next pulse (this has no
                        ; effect if this is a beam laser)

.MA16

 LDA ECMP               ; If our E.C.M is not on, skip to MA69, otherwise keep
 BEQ MA69               ; going to drain some energy

 JSR DENGY              ; Call DENGY to deplete our energy banks by 1

 BEQ MA70               ; If we have no energy left, jump to MA70 to turn our
                        ; E.C.M. off

.MA69

 LDA ECMA               ; If an E.C.M is going off (our's or an opponent's) then
 BEQ MA66               ; keep going, otherwise skip to MA66

 DEC ECMA               ; Decrement the E.C.M. countdown timer, and if it has
 BNE MA66               ; reached zero, keep going, otherwise skip to MA66

.MA70

 JSR ECMOF              ; If we get here then either we have either run out of
                        ; energy, or the E.C.M. timer has run down, so switch
                        ; off the E.C.M.

.MA66

 LDA QQ11               ; If this is not a space view (i.e. QQ11 is non-zero)
 BNE MA9                ; then jump to MA9 to return from the main flight loop
                        ; (as MA9 is an RTS)

 JMP STARS              ; This is a space view, so jump to the STARS routine to
                        ; process the stardust, and return from the main flight
                        ; loop using a tail call
}

\ ******************************************************************************
\ Subroutine: MAS1
\
\ Other entry points: MA9 (RTS)
\
\ Add a doubled rotmat0 axis, e.g. (rotmat0y_hi rotmat0y_lo) * 2, to an INWK
\ coordinate, e.g. (x_sign x_hi x_lo), storing the result in the INWK
\ coordinate. The axes used in each side of the addition are specified by the
\ arguments X and Y.
\
\ In the comments below, we document the routine as if we are doing the
\ following, i.e. if X = 0 and Y = 11:
\
\   (x_sign x_hi x_lo) += (rotmat0y_hi rotmat0y_lo) * 2
\
\ as that way the variable names in the comments contain "x" and "y" to match
\ the registers that specify the axes to use.
\
\ Arguments:
\
\   X           The coordinate to add, as follows:
\
\                 * If X = 0, add the rotmat to (x_sign x_hi x_lo)
\                 * If X = 3, add the rotmat to (y_sign y_hi y_lo)
\                 * If X = 6, add the rotmat to (z_sign z_hi z_lo)
\
\   Y           The rotmat to add, as follows:
\
\                 * If Y = 9,  add (rotmat0x_hi rotmat0x_lo) to the coordinate
\                 * If Y = 11, add (rotmat0y_hi rotmat0y_lo) to the coordinate
\                 * If Y = 13, add (rotmat0z_hi rotmat0z_lo) to the coordinate
\
\ Returns:
\
\   A           The high byte of the result with the sign cleared (e.g. |x_hi|
\               if X = 0, etc.)
\ ******************************************************************************

.MAS1
{
 LDA INWK,Y             ; Set K(2 1) = (rotmat0y_hi rotmat0y_lo) * 2
 ASL A
 STA K+1
 LDA INWK+1,Y
 ROL A
 STA K+2

 LDA #0                 ; Set K+3 bit 7 to the carry flag, so the sign bit
 ROR A                  ; of the above result goes into K+3
 STA K+3

 JSR MVT3               ; Add (x_sign x_hi x_lo) to K(3 2 1)

 STA INWK+2,X           ; Store the sign of the result in x_sign

 LDY K+1                ; Store K(2 1) in (x_hi x_lo)
 STY INWK,X
 LDY K+2
 STY INWK+1,X

 AND #%01111111         ; Set A to the sign byte with the sign cleared

.^MA9

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: m
\
\ Given a value in Y that points to the start of a ship data block as an offset
\ from K%, calculate the following:
\
\   A = x_distance OR y_distance OR z_distance
\
\ and clear the sign bit of the result. The K% workspace contains the ship data
\ blocks, so the offset in Y must be 0 or a multiple of NI% (as each block in
\ K% contains NI% bytes).
\
\ The result effectively contains a maximum cap of the three values (though it
\ might not be one of the three input values - it's just guaranteed to be
\ larger than all of them).
\
\ If Y = 0, then this calculates the maximum distance to the planet in any of
\ the three axes, as K%+2 = x_distance, K%+5 = y_distance and K%+8 = z_distance
\ (the first slot in the K% workspace represents the planet).
\
\ Arguments:
\
\   Y           The offset from K% for the three values to OR
\
\ Returns:
\
\   A           K%+2+Y OR K%+5+Y OR K%+8+Y, with bit 7 cleared
\ ******************************************************************************

.m
{
 LDA #0               ; Set A = 0 and fall through into MAS2 to calculate the
                      ; OR of the three bytes at K%+2+Y, K%+5+Y and K%+8+Y
}

\ ******************************************************************************
\ Subroutine: MAS2
\
\ Given a value in Y that points to the start of a ship data block as an offset
\ from K%, calculate the following:
\
\   A = A OR x_distance OR y_distance OR z_distance
\
\ and clear the sign bit of the result. The K% workspace contains the ship data
\ blocks, so the offset in Y must be 0 or a multiple of NI% (as each block in
\ K% contains NI% bytes).
\
\ The result effectively contains a maximum cap of the three values (though it
\ might not be one of the three input values - it's just guaranteed to be
\ larger than all of them).
\
\ If Y = 0 and A = 0, then this calculates the maximum cap of the highest byte
\ containing the distance to the planet, as K%+2 = x_distance, K%+5 = y_distance
\ and K%+8 = z_distance (the first slot in the K% workspace represents the
\ planet).
\
\ Arguments:
\
\   Y           The offset from K% for the start of the ship data block to use
\
\ Returns:
\
\   A           A OR K%+2+Y OR K%+5+Y OR K%+8+Y, with bit 7 cleared
\ ******************************************************************************

.MAS2
{
 ORA K%+2,Y             ; Set A = A OR x_distance OR y_distance OR z_distance
 ORA K%+5,Y
 ORA K%+8,Y

 AND #%01111111         ; Clear bit 7 in A

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: MAS3
\
\ Given a value in Y that points to the start of a ship data block as an offset
\ from K%, calculate the following:
\
\   A = x_hi^2 + y_hi^2 + z_hi^2
\
\ returning A = &FF if the calculation overflows a one-byte result. The K%
\ workspace contains the ship data blocks, so the offset in Y must be 0 or a
\ multiple of NI% (as each block in K% contains NI% bytes).
\
\ Arguments:
\
\   Y           The offset from K% for the start of the ship data block to use
\
\ Returns
\
\   A           A = x_hi^2 + y_hi^2 + z_hi^2
\
\               A = &FF if the calculation overflows a one-byte result
\ ******************************************************************************

.MAS3
{
 LDA K%+1,Y             ; Set (A P) = x_hi * x_hi
 JSR SQUA2

 STA R                  ; Store A (high byte of result) in R

 LDA K%+4,Y             ; Set (A P) = y_hi * y_hi
 JSR SQUA2

 ADC R                  ; Add A (high byte of second result) to R

 BCS MA30               ; If the addition of the two high bytes caused a carry
                        ; (i.e. they overflowed), jump to MA30 to return A = &FF
 
 STA R                  ; Store A (sum of the two high bytes) in R

 LDA K%+7,Y             ; Set (A P) = z_hi * z_hi
 JSR SQUA2

 ADC R                  ; Add A (high byte of third result) to R, so R now
                        ; contains the sum of x_hi^2 + y_hi^2 + z_hi^2

 BCC P%+4               ; If there is no carry, skip the following instruction
                        ; to return straight from the subroutine

.MA30

 LDA #&FF               ; The calculation has overflowed, so set A = &FF

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: MVEIT
\
\ Move ship/planet/object
\ ******************************************************************************

.MVEIT                  ; Move It, data in INWK and hull XXX0
{
 LDA INWK+31            ; exploding/display state|missiles
 AND #&A0               ; kill or in explosion?
 BNE MV30               ; Dumb ship or exploding

 LDA MCNT               ; Fetch main loop counter
 EOR XSAV               ; nearby ship slot
 AND #15                ; only tidy ship if slot survives
 BNE MV3                ; else skip tidy
 JSR TIDY               ; re-orthogonalize rotation matrix

.MV3                    ; skipped tidy

 LDX TYPE               ; ship type
 BPL P%+5               ; not planet
 JMP MV40               ; else, move Planet.
 LDA INWK+32            ; ai_attack_univ_ecm
 BPL MV30               ; Dumb ship
 CPX #MSL
 BEQ MV26               ; missile done every mcnt

 LDA MCNT               ; Fetch main loop counter
 EOR XSAV               ; nearby ship slot
 AND #7                 ; else tactics only needed every 8
 BNE MV30               ; Dumb ship

.MV26                   ; missile done every mcnt

 JSR TACTICS

.MV30                   ; Dumb ship or exploding

 JSR SCAN               ; erase inwk ship on scanner

 LDA INWK+27            ; speed
 ASL A
 ASL A                  ; *=4 speed
 STA Q
 LDA INWK+10
 AND #127               ; x_inc/2 hi
 JSR FMLTU              ; x_inc*speed/256unsg
 STA R
 LDA INWK+10
 LDX #0                 ; x_inc/2 hi
 JSR MVT1-2             ; use Abit7 for x+=R

 LDA INWK+12
 AND #127               ; y_inc/2 hi
 JSR FMLTU              ; y_inc*speed/256unsg
 STA R
 LDA INWK+12
 LDX #3                 ; y_inc/2 hi
 JSR MVT1-2             ; use Abit7 for y+=R
 LDA INWK+14
 AND #127               ; z_inc/2 hi
 JSR FMLTU              ; z_inc*speed/256unsg
 STA R
 LDA INWK+14
 LDX #6                 ; z_inc/2 hi
 JSR MVT1-2             ; use Abit7 for z+=R

 LDA INWK+27
 CLC                    ; update speed with
 ADC INWK+28            ; accel used for 1 frame
 BPL P%+4               ; keep speed +ve
 LDA #0                 ; cant go -ve
 LDY #15                ; hull byte#15 is max speed
 CMP (XX0),Y
 BCC P%+4               ; else clamp speed to hull max
 LDA (XX0),Y
 STA INWK+27            ; speed

 LDA #0                 ; accel was used for 1 frame
 STA INWK+28

 LDX ALP1               ; roll mag lower7 bits
 LDA INWK
 EOR #&FF               ; flip xlo
 STA P
 LDA INWK+1             ; xhi
 JSR MLTU2-2            ; AP(2)= AP* alp1_unsg(EOR P)
 STA P+2
 LDA ALP2+1             ; flipped roll sign
 EOR INWK+2             ; xsg
 LDX #3                 ; y_shift
 JSR MVT6               ; P(1,2) += inwk,x (A is protected but with new sign)

 STA K2+3               ; sg for Y-aX
 LDA P+1
 STA K2+1
 EOR #&FF               ; flip
 STA P
 LDA P+2
 STA K2+2;              ; K2=Y-aX \ their comment \ Yinwk corrected for alpha roll

 LDX BET1               ; pitch mag lower7 bits
 JSR MLTU2-2            ; AP(2)= AP* bet1_unsg(EOR P)
 STA P+2
 LDA K2+3
 EOR BET2               ; pitch sign
 LDX #6                 ; z_shift
 JSR MVT6               ; P(1,2) += inwk,x (A is protected but with new sign)
 STA INWK+8             ; zsg
 LDA P+1
 STA INWK+6             ; zlo
 EOR #&FF               ; flip
 STA P
 LDA P+2
 STA INWK+7             ; zhi \ Z=Z+bK2 \ their comment

 JSR MLTU2              ; AP(2)= AP* Qunsg(EOR P) \ Q = speed
 STA P+2
 LDA K2+3
 STA INWK+5             ; ysg
 EOR BET2               ; pitch sign
 EOR INWK+8             ; zsg
 BPL MV43               ; +ve zsg
 LDA P+1
 ADC K2+1
 STA INWK+3             ; ylo
 LDA P+2
 ADC K2+2
 STA INWK+4             ; yhi
 JMP MV44               ; roll&pitch continue

.MV43                   ; +ve ysg zsg

 LDA K2+1
 SBC P+1
 STA INWK+3             ; ylo
 LDA K2+2
 SBC P+2
 STA INWK+4             ; yhi
 BCS MV44               ; roll&pitch continue
 LDA #1                 ; ylo flipped
 SBC INWK+3
 STA INWK+3
 LDA #0                 ; any carry into yhi
 SBC INWK+4
 STA INWK+4
 LDA INWK+5
 EOR #128               ; flip ysg
 STA INWK+5             ; ysg \ Y=K2-bZ \ their comment

.MV44                   ; roll&pitch continue

 LDX ALP1               ; roll mag lower7 bits
 LDA INWK+3
 EOR #&FF               ; flip ylo
 STA P
 LDA INWK+4             ; yhi
 JSR MLTU2-2            ; AP(2)= AP* alp1_unsg(EOR P)
 STA P+2
 LDA ALP2               ; roll sign
 EOR INWK+5             ; ysg
 LDX #0                 ; x_shift
 JSR MVT6               ; P(1,2) += inwk,x (A is protected but with new sign)
 STA INWK+2             ; xsg
 LDA P+2
 STA INWK+1             ; xhi
 LDA P+1
 STA INWK               ; X=X+aY \ their comment
}

.MV45                   ; move inwk by speed
{
 LDA DELTA              ; speed
 STA R
 LDA #128               ; force inc sign to be -ve
 LDX #6                 ; z_shift
 JSR MVT1               ; Add R|sgnA to inwk,x+0to2
 LDA TYPE               ; ship type
 AND #&81               ; sun bits
 CMP #&81               ; is sun?
 BNE P%+3
 RTS                    ; Z=Z-d \ their comment

                        ; All except Suns

 LDY #9                 ; select row
 JSR MVS4               ; pitch&roll update to rotmat
 LDY #15
 JSR MVS4               ; pitch&roll update to rotmat
 LDY #21
 JSR MVS4               ; pitch&roll update to rotmat
 LDA INWK+30            ; rotz counter
 AND #128               ; rotz sign
 STA RAT2
 LDA INWK+30
 AND #127               ; pitch mag lower 7bits
 BEQ MV8                ; rotz=0, Other rotation.
 CMP #127               ; C set if equal, no damping of pitch
 SBC #0                 ; reduce z pitch, rotz
 ORA RAT2               ; reinclude rotz sign
 STA INWK+30            ; rotz counter

 LDX #15                ; select column
 LDY #9                 ; select row
 JSR MVS5               ; moveship5, small rotation in matrix
 LDX #17
 LDY #11
 JSR MVS5
 LDX #19
 LDY #13
 JSR MVS5

.MV8                    ; Other rotation, roll.

 LDA INWK+29            ; rotx counter
 AND #128               ; rotx sign
 STA RAT2
 LDA INWK+29            ; rotx counter
 AND #127               ; roll mag lower 7 bits
 BEQ MV5                ; rotations Done
 CMP #127               ; C set if equal, no damping of x roll
 SBC #0                 ; reduce x roll
 ORA RAT2               ; reinclude sign
 STA INWK+29            ; rotx counter

 LDX #15                ; select column
 LDY #21                ; select row
 JSR MVS5               ; moveship5, small rotation in matrix
 LDX #17
 LDY #23
 JSR MVS5
 LDX #19
 LDY #25
 JSR MVS5

.MV5                    ; rotations Done

 LDA INWK+31            ; display explosion state|missiles
 AND #&A0               ; do kill at end of explosion
 BNE MVD1               ; end explosion
 LDA INWK+31
 ORA #16                ; else keep visible on scanner, set bit4.
 STA INWK+31
 JMP SCAN               ; ships inwk on scanner

.MVD1                   ; end explosion

 LDA INWK+31
 AND #&EF               ; clear bit4, now invisible.
 STA INWK+31
 RTS

 AND #128               ; use Abit7 for x+=R
}

.MVT1                   ; Add Rlo.Ahi.sg to inwk,x+0to2 ship translation
{
 ASL A                  ; bit7 into carry
 STA S                  ; A6to0
 LDA #0
 ROR A                  ; sign bit from Acc
 STA T
 LSR S                  ; A6to0
 EOR INWK+2,X
 BMI MV10               ; -ve sg eor T
 LDA R                  ; lo
 ADC INWK,X
 STA INWK,X
 LDA S                  ; hi
 ADC INWK+1,X
 STA INWK+1,X
 LDA INWK+2,X
 ADC #0                 ; sign bit from Acc
 ORA T
 STA INWK+2,X
 RTS

.MV10                   ; -ve sg eor T

 LDA INWK,X             ; INWK+0,X
 SEC                    ; lo sub
 SBC R
 STA INWK,X
 LDA INWK+1,X
 SBC S                  ; hi
 STA INWK+1,X
 LDA INWK+2,X
 AND #127               ; keep far
 SBC #0                 ; any carry
 ORA #128               ; sign
 EOR T
 STA INWK+2,X
 BCS MV11               ; rts

 LDA #1                 ; else need to flip sign
 SBC INWK,X
 STA INWK,X
 LDA #0                 ; hi
 SBC INWK+1,X
 STA INWK+1,X
 LDA #0                 ; sg
 SBC INWK+2,X
 AND #127               ; keep far
 ORA T
 STA INWK+2,X

.MV11

 RTS                    ; MVT1 done
}

\ ******************************************************************************
\ Subroutine: MVT3
\
\ Add an INWK position coordinate - i.e. x, y or z - to K(3 2 1).
\
\ The INWK coordinate to add to K(3 2 1) is specified by X.
\
\ Arguments:
\
\   X           The coordinate to add to K(3 2 1), as follows:
\
\                 * If X = 0, set K(3 2 1) = K(3 2 1) + (x_sign x_hi x_lo)
\                 * If X = 3, set K(3 2 1) = K(3 2 1) + (y_sign y_hi y_lo)
\                 * If X = 6, set K(3 2 1) = K(3 2 1) + (z_sign z_hi z_lo)
\ ******************************************************************************

.MVT3
{
 LDA K+3                ; Set S = K+3
 STA S

 AND #%10000000         ; Set T = sign bit of K(3 2 1)
 STA T

 EOR INWK+2,X           ; If x_sign has a different sign to K(3 2 1), jump to
 BMI MV13               ; MV13 to process the addition as a subtraction

 LDA K+1                ; Set K(3 2 1) = K(3 2 1) + (x_sign x_hi x_lo)
 CLC                    ; starting with the low bytes
 ADC INWK,X
 STA K+1

 LDA K+2                ; Then the middle bytes
 ADC INWK+1,X
 STA K+2

 LDA K+3                ; And finally the high bytes
 ADC INWK+2,X

 AND #%01111111         ; Setting the sign bit of K+3 to T, the original sign
 ORA T                  ; of K(3 2 1)
 STA K+3

 RTS                    ; Return from the subroutine

.MV13

 LDA S                  ; Set S = |K+3| (i.e. K+3 with the sign bit cleared)
 AND #%01111111
 STA S

 LDA INWK,X             ; Set K(3 2 1) = (x_sign x_hi x_lo) - K(3 2 1)
 SEC                    ; starting with the low bytes
 SBC K+1
 STA K+1

 LDA INWK+1,X           ; Then the middle bytes
 SBC K+2
 STA K+2

 LDA INWK+2,X           ; And finally the high bytes, doing A = |x_sign| - |K+3|
 AND #%01111111         ; and setting the C flag for testing below
 SBC S

 ORA #%10000000         ; Set the sign bit of K+3 to the opposite sign of T,
 EOR T                  ; i.e. the opposite sign to the original K(3 2 1)
 STA K+3

 BCS MV14               ; If the C flag is set, i.e. |x_sign| >= |K+3|, then
                        ; the sign of K(3 2 1). In this case, we want the
                        ; result to have the same sign as the largest argument,
                        ; which is (x_sign x_hi x_lo), which we know has the
                        ; oposite sign to K(3 2 1), and that's what we just set
                        ; the sign of K(3 2 1) to... so we can jump to MV14 to
                        ; return from the subroutine

 LDA #1                 ; We need to swap the sign of the result in K(3 2 1),
 SBC K+1                ; which we do by calculating 0 - K(3 2 1), which we can
 STA K+1                ; do with 1 - C - K(3 2 1), as we know the C flag is
                        ; clear. We start with the low bytes
 
 LDA #0                 ; Then the middle bytes
 SBC K+2
 STA K+2

 LDA #0                 ; And finally the high bytes
 SBC K+3

 AND #%01111111         ; Set the sign bit of K+3 to the same sign as T,
 ORA T                  ; i.e. the same sign as the original K(3 2 1), as
 STA K+3                ; that's the largest argument

.MV14

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: MVS4
\
\ Apply pitch and roll angles alpha and beta to the rotmat row given in Y.
\
\ Specifically, this routine rotates a point (x, y, z) around the origin by
\ pitch alpha and roll beta, using the small angle approximation to make the
\ maths easier, and incorporating the Minsky circle algorithm to make the
\ rotation more stable (though more elliptic).
\
\ If that paragraph makes sense to you, then you should probably be writing
\ this commentary! For the rest of us, there's an explanation below.
\ 
\ Arguments:
\
\   Y           Determines which row of the INWK rotation matrix to transform:
\
\                 * Y = 9 rotates row 0 (rotmat0x, rotmat0y, rotmat0z)
\
\                 * Y = 15 rotates row 1 (rotmat1x, rotmat1y, rotmat1z)
\
\                 * Y = 21 rotates row 2 (rotmat2x, rotmat2y, rotmat2z)
\
\ ******************************************************************************
\
\ In order to understand this routine, we need first to understand what it's
\ for, so consider our Cobra Mk III sitting in deep space, minding its own
\ business, when an enemy ship appears in the distance. Inside the little
\ bubble of universe that Elite creates to simulate this scenario, our ship is
\ at the origin (0, 0, 0), and the enemy ship has just popped into existence at
\ (x, y, z), where the x-axis is to our right, the y-axis is up, and the z-axis
\ is in the direction our Cobra is pointing in.
\ 
\ Of course, our first thought is to roll and pitch our Cobra to get the new
\ arrival firmly into the cross-hairs, and in doing this the enemy ship will
\ appear to move in space, relative to us. For example, if we do a pitch by
\ pulling back on the joystick or pressing "X", this will pull the nose of our
\ Cobra Mk III up, and the point (x, y, z) will appear to move down in the sky
\ in front of us.
\ 
\ So this routine calculates the movement of the enemy ship in space when we
\ pitch and roll, as then the game can show the ship on screen and work out
\ whether our lasers are pointing in the correct direction to unleash fiery
\ death on the pirate/cop/innocent trader in our sights.
\ 
\ Roll and pitch
\ --------------
\ 
\ To make it easier to work with the 3D rotations of pitching and rolling, we
\ break down the movement into two separate rotations, the roll and the pitch,
\ and we apply one of them first, and then the other (in Elite, we do the roll
\ first, and then the pitch).
\ 
\ So let's look at the first one: the roll. Imagine we're sitting in our
\ spaceship and do a roll to the right by pressing ">". From our perspective
\ this is the same as the universe doing a roll to the left, so if we're
\ looking out of the front of our ship, and there's a stationary enemy ship at
\ (x, y, z), then rolling by an angle of a will look something like this:
\ 
\   y
\   
\   ^         (x´, y´, z´)
\   |       /
\   |      /    <-_ 
\   |     /        `.
\   |    /       a   \
\   |   /             
\   |  /              __ (x, y, z)
\   | /       __..--''
\   |/__..--''     
\   +-----------------------> x
\ 
\ So the enemy ship will move from (x, y, z) to (x´, y´, z´) in our little
\ bubble of universe. Moreover, because the enemy ship is stationary, rolling
\ our ship won't change the enemy ship's z-coordinate - it will always be the
\ same distance in front of us, however far we roll. So we know that z´ = z,
\ but how do we calculate x´ and y´?
\ 
\ First, let's ditch the z-coordinate, as we know this doesn't change. This
\ leaves us with a 2D rotation to consider; we are effectively only interested
\ in what happens in the 2D plane at distance z in front of our ship (imagine a
\ cinema screen at distance z, and that's what we're about to draw graphs on).
\ 
\ Now, let's look at the triangle formed by the original (x, y) point:
\ 
\   ^
\   |
\   |
\   |
\   |
\   |
\   |         h        __ (x, y)
\   |         __..--''  |
\   | __..--''    t     | <------- y
\   +----------------------->
\        <---- x ---->
\ 
\ In this triangle, let's call the angle at the origin t and the hypotenuse h,
\ and we already know the adjacent side is x and the opposite side is y. If we
\ plug these into the equations for sine and cosine, we get:
\ 
\   cos t = adjacent / hypotenuse = x / h
\   sin t = opposite / hypotenuse = y / h
\ 
\ which gives us the following when we multiply both sides by h:
\ 
\   x = h * cos(t)
\   y = h * sin(t)
\ 
\ (We could use Pythagoras to calculate h from x and y, but we don't need to -
\ you'll see why in a minute.)
\ 
\ Now let's look at the 2D triangle formed by the new, post-roll (x´, y´)
\ point:
\ 
\   ^         (x´, y´)
\   |       /|
\   |      / |
\   |     /  |
\   |  h /   |
\   |   /    | <------- y´
\   |  /     |
\   | /      |
\   |/ t+a   |
\   +----------------------->
\   <-- x´ -->
\ 
\ In this triangle, the angle is now t + a (as we have rolled left by an angle
\ of a), the hypotenuse is still h (because we're rotating around the origin),
\ the adjacent is x´ and the opposite is y´. If we plug these into the
\ equations for sine and cosine, we get:
\ 
\  cos(t + a) = adjacent / hypotenuse = x´ / h
\  sin(t + a) = opposite / hypotenuse = y´ / h
\ 
\ which gives us the following when we multiply both sides by h:
\ 
\   x´ = h * cos(t + a)                                   (i)
\   y´ = h * sin(t + a)                                   (ii)
\ 
\ We can expand these using the standard trigonometric formulae for compound
\ angles, like this:
\ 
\   x´ = h * cos(t + a)                                   (i)
\      = h * (cos(t) * cos(a) - * sin(t) * sin(a))
\      = h * cos(t) * cos(a) - h * sin(t) * sin(a)        (iii)
\ 
\   y´ = h * sin(t + a)                                   (ii)
\      = h * (sin(t) * cos(a) + cos(t) * sin(a))
\      = h * sin(t) * cos(a) + h * cos(t) * sin(a)        (iv)
\ 
\ and finally we can substitute the values of x and y that we calculated from
\ the first triangle above:
\ 
\   x´ = h * cos(t) * cos(a) - h * sin(t) * sin(a)        (iii)
\      = x * cos(a) - y * sin(a)
\ 
\   y´ = h * sin(t) * cos(a) + h * cos(t) * sin(a)        (iv)
\      = y * cos(a) + x * sin(a)
\ 
\ So, to summarise, if we do a roll of angle a, then the ship at (x, y, z) will
\ move to (x´, y´, z´), where:
\ 
\   x´ = x * cos(a) - y * sin(a)
\   y´ = y * cos(a) + x * sin(a)
\   z´ = z
\ 
\ Tranformation matrices
\ ----------------------
\ 
\ We can express the exact same thing in matrix form, like this:
\ 
\   [  cos(a)  sin(a)  0 ]     [ x ]     [ x * cos(a) + y * sin(a) ]
\   [ -sin(a)  cos(a)  0 ]  x  [ y ]  =  [ y * cos(a) - x * sin(a) ]
\   [    0       0     1 ]     [ z ]     [            z            ]
\ 
\ The matrix on the left is therefore the transformation matrix for rolling
\ through an angle a.
\ 
\ We can apply the exact same process to the pitch rotation, which gives us a
\ transformation matrix for pitching through an angle b, as follows:
\
\   [ 1    0        0    ]     [ x ]     [            x            ]
\   [ 0  cos(b)  -sin(b) ]  x  [ y ]  =  [ y * cos(b) - z * sin(a) ]
\   [ 0  sin(b)   cos(b) ]     [ z ]     [ y * sin(b) + z * cos(b) ]
\
\ Finally, we can multiply these two rotation matrices together to get a
\ transformation matrix that applies roll and then pitch in one go:
\
\   [       cos(a)           sin(a)         0    ]     [ x ]
\   [ -sin(a) * cos(b)  cos(a) * cos(b)  -sin(b) ]  x  [ y ]
\   [ -sin(a) * sin(b)  cos(a) * sin(b)   cos(b) ]     [ z ]
\
\ So, to move our enemy ship in space when we pitch and roll, we simply need
\ to do this matrix multiplication. In 6502 assembly language. In a very small
\ memory footprint. Oh, and it needs to be quick, too, because we're going to
\ be using this routine a lot. Got that?
\
\ Small angle approximation
\ -------------------------
\
\ Luckily we can simplify the maths considerably by applying the "small angle
\ approximation". This states that for small angles in radians, the following
\ approximations hold true:
\
\   sin a ~= a
\   cos a ~= 1
\   tan a ~= a
\
\ These approximations make sense when you look at the triangle geometry that
\ is used to show the ratios of trigonometry, and imagine what happens when the
\ angle gets small; for example, cosine is defined as the adjacent over the
\ hypotenuse, and as the angle tends to 0, the hypotenuse "hinges" down on top
\ of the adjacent, so it's intuitive that cos a tends to 1 for small angles.
\
\ (A quick aside: the approximations actually state that cos a approximates to
\ 1 - a^2/2, but Elite uses 1 and corrects for this in the TIDY routine, so
\ let's stick to the simpler version.)
\
\ So dropping the small angle approximations into our rotation calculation above
\ gives the following, much simpler version:
\
\   [  1   a   0 ]     [ x ]     [    x + ay     ]
\   [ -a   1  -b ]  x  [ y ]  =  [ y - ax  - bz  ]
\   [ -ab  b   1 ]     [ z ]     [ z + b(y - ax) ]
\
\ So to move rotate a point (x, y, z) around the origin (the centre of our
\ ship) by the current pitch and roll angles (alpha and beta), we just need to
\ calculate these three relatively simple equations:
\
\   x -> x + alpha * y
\   y -> y - alpha * x - beta * z
\   z -> z + beta * (y - alpha * x)
\
\ There's a fascinating document on Ian Bell's Elite website that shows this
\ exact calculation, in the author's own handwritten notes for the game. You
\ can see it in the second image here:
\
\   http://www.iancgbell.clara.net/elite/design/index.htm
\
\ judt below the original design for the cockpit, before the iconic 3D scanner
\ was added (which is a whole other story...).
\
\ Minsky circles
\ --------------
\
\ So that's what this routine does... it transforms x, y and z when we roll and
\ pitch. But there is a twist. Let's write the transformation equations as you
\ might write them in code (and, indeed this is how the routine itself is
\ structured).
\
\ First, we do the roll calculations:
\
\   y = y - alpha * x
\   x = x + alpha * y
\
\ and then we do the pitch calculations:
\
\   y = y - beta * z
\   z = z + beta * y
\
\ At first glance this code looks the same as the matrix calculation above, but
\ then you notice that the value of y used in the calculations of x and z is not
\ the original value of y, but the updated value of y. In fact, the above code
\ actually does the following transformation of (x, y, z):
\
\   x -> x + alpha * (y - alpha * x)
\   y -> y - alpha * x - beta * z
\   z -> z + beta * (y - alpha * x - beta * z)
\
\ Oops, that isn't what we wanted to calculate... except this version turns out
\ to do a better job than our original matrix multiplication above. This new
\ version, where we reuse the updated y in the calculations of x and z instead
\ of the original y, was "invented by mistake when [Marvin Minsky] tried to save
\ one register in a display hack", and inadvertently discovered a way to rotate
\ points within a pretty good approximation of a circle without using complex
\ maths. The method appeared as item 149 in the 1972 HAKMEM memo, and if that
\ doesn't mean anything to you, see if you can take the time to look it up.
\ It's worth the effort if you're interested in this kind of thing (and you're
\ the one reading a commentary on 8-bit code from 1984, so I'm guessing this
\ might include you).
\
\ Anyway, the rotation in Minsky's method doesn't describe a perfect circle,
\ but instead it follows a slightly sheared ellipse, but that's close enough
\ for 8-bit space combat in 192 x 256 pixels. So, coming back to the Elite
\ sourced code, the routine below implements the rotation like this (shown
\ here for row 0 of the INWK rotation matrix, i.e. rotmat0x, rotmat0y and
\ rotmat0z):
\
\ Roll calculations:
\
\   rotmat0y = rotmat0y - alpha * rotmat0x_hi
\   rotmat0x = rotmat0x + alpha * rotmat0y_hi
\
\ Pitch calculations:
\
\   rotmat0y = rotmat0y - beta * rotmat0z_hi
\   rotmat0z = rotmat0z + beta * rotmat0y_hi
\
\ And that's how we rotate a point around the origin by pitch alpha and roll
\ beta, using the small angle approximation to make the maths easier, and
\ incorporating the Minsky circle algorithm to make the rotation more stable.
\ ******************************************************************************

.MVS4

 LDA ALPHA              ; Set Q = alpha (the roll angle to rotate through)
 STA Q

 LDX INWK+2,Y           ; Set (S R) = rotmat0y
 STX R
 LDX INWK+3,Y
 STX S

 LDX INWK,Y             ; These instructions have no effect as MAD overwrites
 STX P                  ; X and P when called, but they set X = P = rotmat0x_lo

 LDA INWK+1,Y           ; Set A = -rotmat0x_hi
 EOR #%10000000
 
 JSR MAD                ; Set (A X) = Q * A + (S R)
 STA INWK+3,Y           ;           = alpha * -rotmat0x_hi + rotmat0y
 STX INWK+2,Y           ;
                        ; and store (A X) in rotmat0y, so this does:
                        ;
                        ; rotmat0y = rotmat0y - alpha * rotmat0x_hi

 STX P                  ; This instruction has no effect as MAD overwrites P,
                        ; but it sets P = rotmat0y_lo

 LDX INWK,Y             ; Set (S R) = rotmat0x
 STX R
 LDX INWK+1,Y
 STX S

 LDA INWK+3,Y           ; Set A = rotmat0y_hi

 JSR MAD                ; Set (A X) = Q * A + (S R)
 STA INWK+1,Y           ;           = alpha * rotmat0y_hi + rotmat0x
 STX INWK,Y             ;
                        ; and store (A X) in rotmat0x, so this does:
                        ;
                        ; rotmat0x = rotmat0x + alpha * rotmat0y_hi

 STX P                  ; This instruction has no effect as MAD overwrites P,
                        ; but it sets P = rotmat0x_lo

 LDA BETA               ; Set Q = beta (the pitch angle to rotate through)
 STA Q

 LDX INWK+2,Y           ; Set (S R) = rotmat0y
 STX R
 LDX INWK+3,Y
 STX S
 LDX INWK+4,Y

 STX P                  ; This instruction has no effect as MAD overwrites P,
                        ; but it sets P = rotmat0y

 LDA INWK+5,Y           ; Set A = -rotmat0z_hi
 EOR #%10000000

 JSR MAD                ; Set (A X) = Q * A + (S R)
 STA INWK+3,Y           ;           = beta * -rotmat0z_hi + rotmat0y
 STX INWK+2,Y           ;
                        ; and store (A X) in rotmat0y, so this does:
                        ;
                        ; rotmat0y = rotmat0y - beta * rotmat0z_hi

 STX P                  ; This instruction has no effect as MAD overwrites P,
                        ; but it sets P = rotmat0y_lo

 LDX INWK+4,Y           ; Set (S R) = rotmat0z
 STX R
 LDX INWK+5,Y
 STX S

 LDA INWK+3,Y           ; Set A = rotmat0y_hi

 JSR MAD                ; Set (A X) = Q * A + (S R)
 STA INWK+5,Y           ;           = beta * rotmat0y_hi + rotmat0z
 STX INWK+4,Y           ;
                        ; and store (A X) in rotmat0z, so this does:
                        ;
                        ; rotmat0z = rotmat0z + beta * rotmat0y_hi

 RTS                    ; Return from the subroutine

\ ******************************************************************************
\ Subroutine: MVS5
\
\ Moveship5, small rotation in matrix (1-1/2/256 = cos  1/16 = sine)
\ ******************************************************************************

.MVS5                   ; Moveship5, small rotation in matrix (1-1/2/256 = cos  1/16 = sine)
{
 LDA INWK+1,X
 AND #127               ; hi7
 LSR A                  ; hi7/2
 STA T
 LDA INWK,X
 SEC                    ; lo
 SBC T
 STA R                  ; Xindex one is 1-1/512
 LDA INWK+1,X
 SBC #0                 ; hi
 STA S
 LDA INWK,Y
 STA P                  ; Prepare to divide Yindex one by 16
 LDA INWK+1,Y
 AND #128               ; sign bit
 STA T
 LDA INWK+1,Y
 AND #127               ; hi7
 LSR A                  ; hi7/2
 ROR P                  ; lo
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P                  ; divided by 16
 ORA T                  ; sign bit
 EOR RAT2               ; rot sign
 STX Q                  ; protect Xindex
 JSR ADD                ; (A X) = (A P) + (S R)
 STA K+1                ; hi
 STX K                  ; lo, save for later

 LDX Q                  ; restore Xindex
 LDA INWK+1,Y
 AND #127               ; hi7
 LSR A                  ; hi7/2
 STA T
 LDA INWK,Y
 SEC                    ; sub lo
 SBC T
 STA R                  ; Yindex one is 1-1/512
 LDA INWK+1,Y
 SBC #0                 ; sub hi
 STA S
 LDA INWK,X
 STA P                  ; Prepare to divide Xindex one by 16
 LDA INWK+1,X
 AND #128               ; sign bit
 STA T
 LDA INWK+1,X
 AND #127               ; hi7
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P                  ; divided by 16
 ORA T                  ; sign bit
 EOR #128               ; flip sign
 EOR RAT2               ; rot sign

 STX Q                  ; protect Xindex
 JSR ADD                ; (A X) = (A P) + (S R)
 STA INWK+1,Y
 STX INWK,Y             ; Yindex one now updated by 1/16th of a radian rotation
 LDX Q                  ; restore Xindex
 LDA K                  ; restore Xindex one lo
 STA INWK,X
 LDA K+1                ; Xindex one now updated by 1/16th of a radian rotation
 STA INWK+1,X
 RTS                    ; MVS5 done
}

\ ******************************************************************************
\ Subroutine: MVT6
\
\ P(1,2) += inwk,x (A is protected but with new sign)
\ ******************************************************************************

.MVT6                   ; Planet P(1,2) += inwk,x for planet (Asg is protected but with new sign)
{
 TAY                    ; Yreg = sg
 EOR INWK+2,X
 BMI MV50               ; sg -ve
 LDA P+1
 CLC                    ; add lo
 ADC INWK,X
 STA P+1
 LDA P+2                ; add hi
 ADC INWK+1,X
 STA P+2
 TYA                    ; restore old sg ok
 RTS

.MV50                   ; sg -ve

 LDA INWK,X
 SEC                    ; sub lo
 SBC P+1
 STA P+1
 LDA INWK+1,X
 SBC P+2                ; sub hi
 STA P+2
 BCC MV51               ; fix -ve
 TYA                    ; restore Asg
 EOR #128               ; but flip sign
 RTS

.MV51                   ; fix -ve

 LDA #1                 ; carry was clear
 SBC P+1
 STA P+1
 LDA #0                 ; sub hi
 SBC P+2
 STA P+2
 TYA                    ; old Asg ok
 RTS                    ; MVT6 done.
}

\ ******************************************************************************
\ Subroutine: MV40
\
\ Move Planet
\ ******************************************************************************

.MV40                   ; move Planet
{
 LDA ALPHA
 EOR #128               ; flip roll
 STA Q
 LDA INWK
 STA P                  ; xlo
 LDA INWK+1
 STA P+1                ; xhi
 LDA INWK+2             ; xsg
 JSR MULT3              ; K(4)= -AP(2)*alpha
 LDX #3                 ; Y coords
 JSR MVT3               ; add INWK(0to2+X) to K(1to3)  \ K=Y-a*X \ their comment

 LDA K+1
 STA K2+1
 STA P                  ; lo
 LDA K+2
 STA K2+2
 STA P+1                ; hi
 LDA BETA
 STA Q
 LDA K+3
 STA K2+3               ; sg
 JSR MULT3              ; K(4)= AP(2)*beta
 LDX #6                 ; Z coords
 JSR MVT3               ; add INWK(0to2+X) to K(1to3) \ K = Z+b*K2
 LDA K+1
 STA P                  ; zlo
 STA INWK+6
 LDA K+2
 STA P+1                ; zhi
 STA INWK+7
 LDA K+3
 STA INWK+8             ; zsg \Z=Z+b*K2 \ their comment

 EOR #128               ; -Z sgn
 JSR MULT3              ; K(4)= -Z*beta
 LDA K+3
 AND #128               ; sign
 STA T
 EOR K2+3
 BMI MV1                ; planet y = -Z*beta-K2

 LDA K
\CLC                    ; else y = -Z*beta+K2
 ADC K2
 LDA K+1
 ADC K2+1
 STA INWK+3
 LDA K+2
 ADC K2+2
 STA INWK+4             ; ylo
 LDA K+3
 ADC K2+3
 JMP MV2

.MV1                    ; planet y = -Z*beta-K2

 LDA K
 SEC                    ; yre
 SBC K2
 LDA K+1
 SBC K2+1
 STA INWK+3             ; ylo
 LDA K+2
 SBC K2+2
 STA INWK+4             ; yhi
 LDA K2+3
 AND #127               ; mag of K2+3
 STA P
 LDA K+3
 AND #127               ; mag of K+3
 SBC P
 STA P
 BCS MV2                ; continue pitch Planet

 LDA #1                 ; carry clear, fix ylo
 SBC INWK+3
 STA INWK+3
 LDA #0                 ; yhi
 SBC INWK+4
 STA INWK+4
 LDA #0                 ; mag of K2+3
 SBC P
 ORA #128               ; set bit7

.MV2                    ; continue pitch planet

 EOR T
 STA INWK+5             ; ysg \ Y=K2-bZ \ their comment

 LDA ALPHA
 STA Q
 LDA INWK+3
 STA P                  ; ylo
 LDA INWK+4
 STA P+1                ; yhi
 LDA INWK+5             ; ysg
 JSR MULT3              ; K(4)=AP(2)*alpha
 LDX #0                 ; X coords
 JSR MVT3               ; add INWK(0to2+X) to K(1to3) \ K = X+Ya
 LDA K+1
 STA INWK               ; xlo
 LDA K+2
 STA INWK+1             ; xhi
 LDA K+3
 STA INWK+2             ; xsg \ X=X+aY \ their comment

 JMP MV45               ; move inwk by speed, end of MV40 move planet.
}

\ ******************************************************************************
\ Save output/ELTA.bin
\ ******************************************************************************

PRINT "ELITE A"
PRINT "Assembled at ", ~CODE%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_A%

PRINT "S.ELTA ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_A%
SAVE "output/ELTA.bin", CODE%, P%, LOAD%

\ ******************************************************************************
\ ELITE B
\
\ Produces the binary file ELTB.bin which gets loaded by elite-bcfs.asm.
\ ******************************************************************************

CODE_B% = P%
LOAD_B% = LOAD% + P% - CODE%
Q% = _ENABLE_MAX_COMMANDER

\ ******************************************************************************
\ Variable: NA%
\
\ Other entry points: CHK, CHK2
\
\ Contains the last saved commander data, with the name at NA% and the data at
\ NA%+8 onwards. The size of the data block is given in NT%. This block is
\ initially set up with the default commander, which can be maxed out for
\ testing purposes by setting Q% to TRUE.
\
\ The commander's name is stored at NA%, and can be up to 7 characters long
\ (the DFS filename limit). It is terminated with a carriage return character,
\ ASCII 13.
\ ******************************************************************************

.NA%
{
 EQUS "JAMESON"         ; Default commander name
 EQUB 13                ; Terminated by a carriage return; commander name can
                        ; be up to 7 characters (the DFS limit for file names)
 
                        ; NA%+8 - the start of the commander data block
                        ;
                        ; This block contains the last saved commander data
                        ; block. As the game is played it uses an identical
                        ; block at location TP to store the current commander
                        ; state, and that block is copied here when the game is
                        ; saved. Conversely, when the game starts up, the block
                        ; here is copied to TP, which restores the last saved
                        ; commander when we die.
                        ;
                        ; The intial state of this block defines the default
                        ; commander. Q% can be set to TRUE to give the default
                        ; commander lots of credits and equipment.

 EQUB 0                 ; Mission status. The disc version of the game has two
                        ; missions, and this byte contains the status of those
                        ; missions (the possible values are 0, 1, 2, &A, &E). As
                        ; the tape version doesn't have missions, this byte will
                        ; always be zero, which means no missions have been
                        ; started.
                        ;
                        ; Note that this byte must not have bit 7 set, or
                        ; loading this commander will cause the game to restart

 EQUB 20                ; QQ0 = current system X-coordinate (Lave)
 EQUB 173               ; QQ1 = current system Y-coordinate (Lave)

 EQUW &5A4A             ; QQ21 = Seed w0 for system 0 in galaxy 0 (Tibedied)
 EQUW &0248             ; QQ21 = Seed w1 for system 0 in galaxy 0 (Tibedied)
 EQUW &B753             ; QQ21 = Seed w2 for system 0 in galaxy 0 (Tibedied)

IF Q%
 EQUD &00CA9A3B         ; CASH = Amount of cash (100,000,000 Cr)
ELSE
 EQUD &E8030000         ; CASH = Amount of cash (100 Cr)
ENDIF

 EQUB 70                ; QQ14 = Fuel level

 EQUB 0                 ; COK = Competition code

 EQUB 0                 ; GCNT = Galaxy number, 0-7

 EQUB POW+(128 AND Q%)  ; LASER = Front laser

IF Q% OR _FIX_REAR_LASER
 EQUB (POW+128) AND Q%  ; LASER+1 = Rear laser, as in ELITEB source
ELSE
 EQUB POW               ; LASER+1 = Rear laser, as in extracted ELTB binary
ENDIF

 EQUB 0                 ; LASER+2 = Left laser

 EQUB 0                 ; LASER+3 = Right laser

 EQUW 0                 ; Not used (reserved for up/down lasers, maybe?)

 EQUB 22+(15 AND Q%)    ; CRGO = Cargo capacity

 EQUD 0                 ; QQ20 = Contents of cargo hold (17 bytes)
 EQUD 0
 EQUD 0
 EQUD 0
 EQUB 0

 EQUB Q%                ; ECM = E.C.M.

 EQUB Q%                ; BST = Fuel scoops ("barrel status")

 EQUB Q% AND 127        ; BOMB = Energy bomb

 EQUB Q% AND 1          ; ENGY = Energy/shield level

 EQUB Q%                ; DKCMP = Docking computer

 EQUB Q%                ; GHYP = Galactic hyperdrive

 EQUB Q%                ; ESCP = Escape pod

 EQUD FALSE             ; Not used

 EQUB 3+(Q% AND 1)      ; NOMSL = Number of missiles

 EQUB FALSE             ; FIST = Legal status ("fugitive/innocent status")

 EQUB 16                ; AVL = Market availability (17 bytes)
 EQUB 15
 EQUB 17
 EQUB 0
 EQUB 3
 EQUB 28
 EQUB 14
 EQUB 0
 EQUB 0
 EQUB 10
 EQUB 0
 EQUB 17
 EQUB 58
 EQUB 7
 EQUB 9
 EQUB 8
 EQUB 0

 EQUB 0                 ; QQ26 = Random byte that changes for each visit to a
                        ; system, for randomising market prices

 EQUW 0                 ; TALLY = Number of kills

 EQUB 128               ; SVC = Save count

IF _FIX_REAR_LASER
 CH% = &3
ELSE
 CH% = &92
ENDIF

PRINT "CH% = ", ~CH%

.^CHK2

 EQUB CH% EOR &A9       ; Commander checksum byte, EOR'd with &A9 to make it
                        ; harder to tamper with the checksum byte

.^CHK

 EQUB CH%               ; Commander checksum byte, see elite-checksum.py for
                        ; more details
}

\ ******************************************************************************
\ Variable: UNIV
\
\ The little bubble of the universe that we simulate in Elite can contain up to
\ NOSH + 1 (13) ships. Each of those ships has its own block of 36 (NI%) bytes
\ that contains information such as the ship's position in space, speed,
\ rotation, energy and so on, as well as a pointer to the line data for
\ plotting it on screen. These 13 blocks of ship data live in the first 468
\ bytes of the workspace at K% (&0900 to &0AD4).
\
\ In order to update the ship data, the whole block is copied to the INWK ship
\ workspace in zero page, as it's easier and quicker to work with zero page
\ locations. See the INWK documentation for details of the 36 bytes and the
\ information that they contain.
\
\ UNIV contains a table of address pointers to these data blocks, one for each
\ of the 13 ships. So if we want to read the data for ship number 3 in our
\ little bubble of the universe, we would look at the address held in UNIV+3
\ (ship numbers start at 0).
\
\ Along with FRIN, which has a slot for each of the ships in the local bubble
\ containing the ship types (or 0 for an empty slot), UNIV and K% contain all
\ the information about the 13 ships and objects that can populate local space
\ in Elite.
\ ******************************************************************************

.UNIV
{
FOR I%, 0, NOSH
 EQUW K% + I% * NI%     ; Address of block no. I%, of size NI%, in workspace K%
NEXT
}

\ ******************************************************************************
\ Variable: TWOS
\
\ Ready-made bytes for plotting one-pixel points in mode 4 (the top part of the
\ split screen). See the PIXEL routine for details.
\ ******************************************************************************

.TWOS
{
 EQUB %10000000
 EQUB %01000000
 EQUB %00100000
 EQUB %00010000
 EQUB %00001000
 EQUB %00000100
 EQUB %00000010
 EQUB %00000001
}

\ ******************************************************************************
\ Variable: TWOS2
\
\ Ready-made bytes for plotting two-pixel dashes in mode 4 (the top part of the
\ split screen). See the PIXEL routine for details.
\ ******************************************************************************

.TWOS2
{
 EQUB %11000000
 EQUB %01100000
 EQUB %00110000
 EQUB %00011000
 EQUB %00001100
 EQUB %00000110
 EQUB %00000011
 EQUB %00000011
}

\ ******************************************************************************
\ Variable: CTWOS
\
\ Ready-made bytes for plotting one-pixel points in mode 5 (the bottom part of
\ the split screen). See the dashboard routines SCAN, DIL2 and CPIX2 for
\ details.
\ ******************************************************************************

.CTWOS
{
 EQUB %10001000
 EQUB %01000100
 EQUB %00100010
 EQUB %00010001
 EQUB %10001000         ; One extra for the compass
}

\ ******************************************************************************
\ Subroutine: LL30, LOIN
\
\ Draw Line using (X1,Y1) , (X2,Y2).
\ ******************************************************************************

.LL30                   ; draw Line using (X1,Y1) , (X2,Y2)
.LOIN
{
 STY YSAV               ; will be restored at the end

 LDA #128               ; set bit7
 STA S
 ASL A                  ; = 0
 STA SWAP
 LDA X2
 SBC X1
 BCS LI1                ; deltaX
 EOR #&FF               ; else negate
 ADC #1
 SEC

.LI1                    ; deltaX

 STA P                  ; delta-X

 LDA Y2
 SBC Y1
 BCS LI2                ; deltaY
 EOR #&FF               ; else negate
 ADC #1

.LI2                    ; deltaY

 STA Q                  ; delta-Y
 CMP P                  ; is Q < P ?
 BCC STPX               ; if yes will Step along x
 JMP STPY               ; else will step along y

.STPX                   ; Step along x for line

 LDX X1
 CPX X2
 BCC LI3                ; is X1 < X2 ? hop down, order correct
 DEC SWAP               ; set flag
 LDA X2
 STA X1
 STX X2
 TAX
 LDA Y2
 LDY Y1
 STA Y1
 STY Y2

.LI3                    ; order correct    Xreg = X1

 LDA Y1
 LSR A                  ; build screen index
 LSR A
 LSR A
 ORA #&60               ; high byte of screen memory set to page &60+ Y1/8
 STA SCH
 LDA Y1
 AND #7                 ; build lo
 TAY                    ; row in char
 TXA                    ; X1
 AND #&F8               ; keep upper 5 bits
 STA SC                 ; screen lo

 TXA                    ; X1
 AND #7                 ; keep lower 3 bits
 TAX                    ; index mask
 LDA TWOS,X             ; Mode 4 single pixel
 STA R                  ; mask byte

 LDA Q                  ; delta-Y
 LDX #254               ; roll counter
 STX Q

.LIL1                   ; roll Q

 ASL A                  ; highest bit of delta-Y
 BCS LI4                ; steep
 CMP P                  ; delta-X
 BCC LI5                ; shallow

.LI4                    ; steep

 SBC P
 SEC

.LI5                    ; shallow

 ROL Q
 BCS LIL1               ; loop Q, end with some low bits in Q

 LDX P
 INX                    ; Xreg is width
 LDA Y2
 SBC Y1
 BCS DOWN               ; draw line to the right and down

 LDA SWAP
 BNE LI6                ; else Xreg was correct after all, no need to update R
 DEX

.LIL2                   ; counter X width

 LDA R                  ; mask byte
 EOR (SC),Y
 STA (SC),Y

.LI6                    ; Xreg correct

 LSR R                  ; mask byte
 BCC LI7                ; else moving to next column to right. Bring carry in back
 ROR R
 LDA SC
 ADC #8                 ; next column
 STA SC

.LI7                    ; S += Q. this is like an overflow monitor to update Y

 LDA S
 ADC Q                  ; some low bits
 STA S
 BCC LIC2               ; skip Y adjustment
 DEY
 BPL LIC2               ; skip Y adjustment
 DEC SCH
 LDY #7

.LIC2                   ; skip Y adjustment

 DEX
 BNE LIL2               ; loop X width
 LDY YSAV               ; restore Yreg
 RTS

.DOWN                   ; Line is going to the right and down

 LDA SWAP
 BEQ LI9                ; no swap
 DEX

.LIL3                   ; counter X width

 LDA R                  ; mask byte
 EOR (SC),Y
 STA (SC),Y

.LI9                    ; no swap

 LSR R
 BCC LI10               ; still in correct column, hop
 ROR R
 LDA SC
 ADC #8                 ; next column
 STA SC

.LI10                   ; this is like an overflow monitor to update Y

 LDA S
 ADC Q
 STA S
 BCC LIC3               ; skip Y adjustment
 INY
 CPY #8
 BNE LIC3               ; have not reached bottom byte of char, hop
 INC SCH
 LDY #0

.LIC3                   ; skipped Y adjustment

 DEX
 BNE LIL3               ; loop X width
 LDY YSAV               ; restore Yreg
 RTS

.STPY                   ; Step along y for line, goes down and to right

 LDY Y1
 TYA
 LDX X1
 CPY Y2
 BCS LI15               ; skip swap if Y1 >= Y2
 DEC SWAP
 LDA X2
 STA X1
 STX X2
 TAX
 LDA Y2
 STA Y1
 STY Y2
 TAY

.LI15                   ; Y1 Y2 order is now correct

 LSR A
 LSR A
 LSR A
 ORA #&60
 STA SCH                ; screen hi
 TXA                    ; X1
 AND #&F8
 STA SC                 ; screen lo

 TXA
 AND #7                 ; mask index
 TAX
 LDA TWOS,X             ; Mode4 single pixel
 STA R                  ; mask
 LDA Y1
 AND #7
 TAY

 LDA P                  ; delta-X
 LDX #1                 ; roll counter
 STX P

.LIL4                   ; roll P

 ASL A
 BCS LI13               ; do subtraction
 CMP Q                  ; delta-Y
 BCC LI14               ; less than Q

.LI13                   ; do subtraction

 SBC Q
 SEC

.LI14                   ; less than Q

 ROL P
 BCC LIL4               ; loop P, end with some low bits in P
 LDX Q
 INX                    ; adjust height
 LDA X2
 SBC X1
 BCC LFT                ; if C cleared then line moving to the left - hop down

 CLC
 LDA SWAP
 BEQ LI17               ; skip first point
 DEX

.LIL5                   ; skipped first point, counter X

 LDA R                  ; mask byte
 EOR (SC),Y
 STA (SC),Y

.LI17                   ; skipped first point

 DEY
 BPL LI16               ; skip hi adjust
 DEC SCH
 LDY #7                 ; new char

.LI16                   ; skipped hi adjust

 LDA S
 ADC P
 STA S
 BCC LIC5               ; skip, still in same column
 LSR R                  ; mask
 BCC LIC5               ; no mask bit hop
 ROR R                  ; else moved over to next column, reset mask
 LDA SC                 ; screen lo
 ADC #8                 ; next char below
 STA SC

.LIC5                   ; same column

 DEX
 BNE LIL5               ; loop X height
 LDY YSAV               ; restore Yreg
 RTS

.LFT                    ; going left

 LDA SWAP
 BEQ LI18               ; skip first point
 DEX                    ; reduce height

.LIL6                   ; counter X height

 LDA R                  ; mask byte
 EOR (SC),Y
 STA (SC),Y

.LI18

 DEY
 BPL LI19               ; skip hi adjust
 DEC SCH
 LDY #7                 ; rest char row

.LI19                   ; skipped hi adjust

 LDA S
 ADC P                  ; some low bits
 STA S
 BCC LIC6               ; no overflow

 ASL R                  ; else move byte mask to the left
 BCC LIC6               ; no overflow
 ROL R
 LDA SC
 SBC #7                 ; down 1 char
 STA SC
 CLC

.LIC6                   ; no overflow

 DEX                    ; height
 BNE LIL6               ; loop X
 LDY YSAV               ; restore Yreg
}

.HL6
{
 RTS                    ; end Line drawing
}

\ ******************************************************************************
\ Subroutine: NLIN3
\
\ Print a text token and draw a horizontal line at pixel row 19.
\ ******************************************************************************

.NLIN3
{
 JSR TT27               ; Print the text token in A

                        ; Fall through into NLIN4 to draw a horizontal line at
                        ; pixel row 19
}

\ ******************************************************************************
\ Subroutine: NLIN4
\
\ Draw a horizontal line at pixel row 19.
\ ******************************************************************************

.NLIN4
{
 LDA #19                ; Jump to NLIN2 to draw a horizontal line at pixel row
 BNE NLIN2              ; 19, returning from the subroutine with using a tail
                        ; call (this BNE is effectively a JMP as A will never
                        ; be zero)
}

\ ******************************************************************************
\ Subroutine: NLIN
\
\ Draw a horizontal line at pixel row 23 and move the text cursor down one
\ line.
\ ******************************************************************************

.NLIN
{
 LDA #23                ; Set A = 23 so NLIN2 below draws a horizontal line at
                        ; pixel row 23

 INC YC                 ; Move the text cursor down one line

                        ; Fall through into NLIN2 to draw the horizontal line
                        ; at row 23
}

\ ******************************************************************************
\ Subroutine: NLIN2
\
\ Draw a screen-wide horizontal line at the pixel row given in A - so the line
\ goes from (2, A) to (254, A).
\
\ Arguments:
\
\   A           The pixel row on which to draw the horizontal line
\ ******************************************************************************

.NLIN2
{
 STA Y1                 ; Set (X1, Y1) = (2, A)
 LDX #2
 STX X1

 LDX #254               ; Set X2 = 254
 STX X2

 BNE HLOIN              ; Call HLOIN to draw a horizontal line from (2, A) to
                        ; (254, A) and return from the subroutine (this BNE is
                        ; effectively a JMP as A will never be zero)

}

\ ******************************************************************************
\ Subroutine: HLOIN2
\
\ Horizontal line X1,X2 using YY as mid-point, Acc is half-wdith.
\ ******************************************************************************

.HLOIN2                 ; Horizontal line X1,X2 using YY as mid-point, Acc is half-wdith.
{
 JSR EDGES              ; Clips Horizontal lines
 STY Y1
 LDA #0                 ; flag in line buffer solar at height Y1
 STA LSO,Y
}

\ ******************************************************************************
\ Subroutine: HLOIN
\
\ Draw a horizontal line from (X1, Y1) to (X2, Y1).
\ ******************************************************************************

.HLOIN                  ; Draw a horizontal lines that only needs X1,Y1,X2
{
 STY YSAV               ; protect Yreg
 LDX X1
 CPX X2
 BEQ HL6                ; no line rts
 BCC HL5                ; no swap needed
 LDA X2
 STA X1
 STX X2
 TAX                    ; Xreg=X1

.HL5                    ; no swap needed

 DEC X2

 LDA Y1
 LSR A                  ; build screen hi
 LSR A
 LSR A
 ORA #&60
 STA SCH
 LDA Y1
 AND #7
 STA SC                 ; screen lo
 TXA                    ; X1
 AND #&F8
 TAY                    ; upper 5 bits of X1

.HL1

 TXA                    ; X1
 AND #&F8
 STA T
 LDA X2
 AND #&F8
 SEC
 SBC T
 BEQ HL2                ; within one column
 LSR A
 LSR A
 LSR A
 STA R                  ; wide count

 LDA X1
 AND #7
 TAX                    ; mask index
 LDA TWFR,X             ; right
 EOR (SC),Y
 STA (SC),Y
 TYA
 ADC #8
 TAY                    ; next column
 LDX R                  ; wide count
 DEX
 BEQ HL3                ; approaching end

 CLC

.HLL1                   ; counter X wide count

 LDA #&FF               ; mask full line
 EOR (SC),Y
 STA (SC),Y
 TYA
 ADC #8                 ; next column
 TAY
 DEX
 BNE HLL1               ; loop X wide

.HL3                    ; approaching end R =1 in HL1

 LDA X2
 AND #7
 TAX                    ; mask index
 LDA TWFL,X             ; left
 EOR (SC),Y
 STA (SC),Y
 LDY YSAV               ; restore Yreg
 RTS

.HL2                    ; wide done, X1 and X2 within 1 column

 LDA X1
 AND #7
 TAX                    ; mask index
 LDA TWFR,X             ; right
 STA T                  ; temp mask
 LDA X2
 AND #7
 TAX                    ; mask index
 LDA TWFL,X             ; left
 AND T                  ; temp mask
 EOR (SC),Y
 STA (SC),Y
 LDY YSAV               ; restore Y reg 
 RTS                    ; end horizontal line
}

\ ******************************************************************************
\ Variable: TWFL
\
\ Mask left of horizontal line.
\ ******************************************************************************

.TWFL                   ; mask left of horizontal line.
{
 EQUD &F0E0C080
 EQUW &FCF8
 EQUB &FE
}

\ ******************************************************************************
\ Variable: TWFR
\
\ Mask right of horizontal line.
\ ******************************************************************************

.TWFR                   ; mask right of horizontal line.
{
 EQUD &1F3F7FFF
 EQUD &0103070F
}

\ ******************************************************************************
\ Subroutine: PX3
\
\ This routine is called from PIXEL to set 1 pixel within a character block for
\ a distant point (i.e. where the distance ZZ >= &90). See the PIXEL routine for
\ details, as this routine is effectively part of PIXEL.
\
\ Arguments:
\
\   X           The x-coordinate of the pixel within the character block
\
\   Y           The y-coordinate of the pixel within the character block
\
\   (SC+1 SC)   The screen addresss of the character block
\
\   T1          The value of Y to restore on exit, so Y is preserved by the call
\               to PIXEL
\ ******************************************************************************

.PX3
{
 LDA TWOS,X             ; Fetch a 1-pixel byte from TWOS and EOR it into SC+Y
 EOR (SC),Y
 STA (SC),Y

 LDY T1                 ; Restore Y from T1, so Y is preserved by the routine

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: PIX1
\
\ Draw dust Pixel, Acc has ALPHA or BETA in it
\ ******************************************************************************

.PIX1                   ; dust Pixel, Acc has ALPHA or BETA in it
{
 JSR ADD                ; (A X) = (A P) + (S R)
 STA YY+1               ; hi
 TXA                    ; lo
 STA SYL,Y              ; dust ylo
}

\ ******************************************************************************
\ Subroutine: PIXEL2
\
\ Draw dust (X1,Y1) from middle
\ ******************************************************************************

.PIXEL2                 ; dust (X1,Y1) from middle
{
 LDA X1                 ; xscreen
 BPL PX1                ; +ve X dust
 EOR #&7F               ; else negate
 CLC
 ADC #1

.PX1                    ; +ve X dust

 EOR #128               ; flip bit7 of X1
 TAX                    ; xscreen
 LDA Y1
 AND #127
 CMP #96                ; #Y screen half height
 BCS PX4                ; too high, rts
 LDA Y1
 BPL PX2                ; +ve Y dust
 EOR #&7F               ; else negate
 ADC #1

.PX2                    ; +ve Y dust

 STA T                  ; temp y dust
 LDA #97                ; #Y+1 above mid-point
 SBC T
}

\ ******************************************************************************
\ Subroutine: PIXEL
\
\ Other entry points: PX4 (RTS)
\
\ Draw a point at screen coordinate (X, A) at a distance of ZZ away, on the
\ top part of the screen (the monochrome mode 4 portion).
\
\ Arguments:
\
\   X           The screen x-coordinate of the point to draw
\
\   A           The screen y-coordinate of the point to draw
\
\   ZZ          The distance of the point (further away = smaller point)
\
\ Returns:
\
\   Y           Y is preserved
\
\ ******************************************************************************
\
\ The top part of Elite's split screen mode - the monochrome mode 4 part -
\ consists of 192 rows of pixels, with 256 pixels in each row. That sounds nice
\ and simple... except the way the BBC Micro stores its screen memory isn't
\ completely straightforward, and to understand Elite's drawing routines, an
\ understanding of this memory structure is essential.
\ 
\ Screen memory
\ -------------
\ First up, the simple part. Because mode 4 is a monochrome screen mode, each
\ pixel is represented by one bit (1 for white, 0 for black). It's more complex
\ for the four-colour mode 5 that's used for the dashboard portion of the
\ screen, but for mode 4 it's as simple as it gets.
\ 
\ However, screen memory is not laid out as you would expect. It isn't a simple
\ sequence of 256-bit lines, one for each horizontal pixel line, but instead
\ the screen is split into rows and columns. Each row is 8 pixels high, and
\ each column is 8 pixels wide, so the 192x256 space view has 24 rows and 32
\ columns. That 8x8 size is the same size as a standard BBC Micro text
\ character, so the screen memory is effectively split up into character rows
\ and columns (and it's no coincidence that these match the character layout
\ used in Elite, where XC and YC hold the location of the text cursor, with XC
\ in the range 0 to 23 and YC in the range 0 to 32).
\ 
\ The mode 4 screen starts in memory at &6000, and each character row takes up
\ 8 rows of 256 bits, or 256 bytes, so that means each character row takes up
\ one page of memory. So the first character row starts at &6000, the second
\ character row starts at &6100, and so on.
\ 
\ Each character row on screen is laid out like this in memory, where each
\ digit (0, 1, 2 etc.) represents a pixel, or bit:
\ 
\         01234567 ->-.      ,------->- 01234567->-.
\                      |    |                       |
\    ,-------<--------´     |     ,-------<--------´
\   |                       |    |
\    `->- 01234567 ->-.     |     `->- 01234567 ->-.
\                      |    |                       |
\    ,-------<--------´     |     ,-------<--------´
\   |                       |    |
\    `->- 01234567 ->-.     |     `->- 01234567 ->-.
\                      |    |                       |
\    ,-------<--------´     |     ,-------<--------´
\   |                       |    |
\    `->- 01234567 ->-.     |     `->- 01234567 ->-.
\                      |    |                       |
\    ,-------<--------´     |     ,-------<--------´
\   |                       |    |
\    `->- 01234567 ->-.     |     `->- 01234567 ->-.
\                      |    |                       |
\    ,-------<--------´     |     ,-------<--------´
\   |                       |    |
\    `->- 01234567 ->-.     |     `->- 01234567 ->-.
\                      |    |                       |
\    ,-------<--------´     |     ,-------<--------´
\   |                       |    |
\    `->- 01234567 ->-.     |     `->- 01234567 ->-.      ^
\                      |    |                       |     :
\    ,-------<--------´     |     ,-------<--------´      :
\   |                       |    |                        |
\    `->- 01234567 ->------´      `->- 01234567 ->-------´
\ 
\ The left-hand half of the diagram displays one 8x8 character's worth of
\ pixels, while the right-hand half shows a second 8x8 character's worth, and
\ so on along the row, for 32 characters. Specifically, the diagram above would
\ produce the following pixels in the top-left corner of the screen:
\ 
\   0123456701234567
\   0123456701234567
\   0123456701234567
\   0123456701234567
\   0123456701234567
\   0123456701234567
\   0123456701234567
\   0123456701234567
\ 
\ So let's imagine we want to draw a 2x2 bit of stardust on the screen at pixel
\ location (7, 2) - where the origin (0, 0) is in the top-left corner - so that
\ the top-left corner of the screen looks like this:
\ 
\   ................
\   ................
\   .......XX.......
\   .......XX.......
\   ................
\   ................
\   ................
\   ................
\ 
\ Let's split this up to match the above diagram a bit more closely:
\ 
\   ........ ........
\   ........ ........
\   .......X X.......
\   .......X X.......
\   ........ ........
\   ........ ........
\   ........ ........
\   ........ ........
\ 
\ As this is the first screen row, the address of the top-left corner is &6000.
\ The first byte is the first row on the left, the second byte is the second
\ row, and so on, like this:
\ 
\   &6000 = ........    &6008 = ........
\   &6001 = ........    &6009 = ........
\   &6002 = .......X    &600A = X.......
\   &6003 = .......X    &600B = X.......
\   &6004 = ........    &600C = ........
\   &6005 = ........    &600D = ........
\   &6006 = ........    &600E = ........
\   &6007 = ........    &600F = ........
\ 
\ So you can see that if we want to draw our 2x2 bit of stardust, we need to do
\ the following:
\ 
\   Set &6002 = %00000001
\   Set &6003 = %00000001
\   Set &600A = %10000000
\   Set &600B = %10000000
\ 
\ Or, if we want to draw our stardust without obliterating anything that's
\ already on screen in this area, we can use EOR logic, like this:
\ 
\   Set &6002 = ?&6002 EOR %00000001
\   Set &6003 = ?&6002 EOR %00000001
\   Set &600A = ?&6002 EOR %10000000
\   Set &600B = ?&6002 EOR %10000000
\ 
\ where ?&6002 denotes the current value of location &6002. Because of the way
\ EOR works:
\ 
\   0 EOR x = x
\   1 EOR x = NOT x
\ 
\ this means that the screen display will only change when we want to poke a
\ bit with value 1 into the screen memory (i.e. paint it white), and when we're
\ doing this, it will invert what's already on screen. This not only means that
\ poking a 0 into the screen memory means "leave this pixel as it is", it also
\ means we can draw something on the screen, and then redraw the exact same
\ thing to remove it from the screen, which can be a lot more efficient than
\ clearing the whole screen and redrawing the whole thing every time something
\ moves.
\ 
\ (The downside of EOR screen logic is that when white pixels overlap, they go
\ black, but that's not a particularly big deal in space - and it also means
\ that things like in-flight messages show up as black when they overlap the
\ sun, without complex logic.)
\ 
\ Converting pixel coordinates to screen locations
\ ------------------------------------------------
\ Given the above, we clearly need a way of converting pixel coordinates like
\ (7, 2) into screen memory locations. There are two parts to this - first, we
\ need to find out which character block we need to write into, and second,
\ which pixel row and column within that character corresponds to the pixel we
\ want to paint.
\ 
\ The first step is pretty easy. The screen is split up into character rows and
\ columns, with 8 pixels per character in both directions, so we can simply
\ divide the pixel coordinates by 8 to get the character location. Let's look
\ at some examples:
\ 
\   (7,   2)     becomes   (0.875,  0.25)
\   (57,  82)    becomes   (7.125,  10.25)
\   (191, 255)   becomes   (23.875, 31.875)
\ 
\ So the first pixel is at (0.875, 0.25), which is the same as saying it's in
\ the first character block (0, 0), and is at position (0.875, 0.25) within
\ that character. For the second example, the pixel is inside character (7, 10)
\ and is at position (0.125, 0.25) within that character, and the third is in
\ character (23, 31) at (0.875, 0.875) inside the character.
\ 
\ We can now codify this. To get the character block that contains a specific
\ pixel, we can divide the coordinates by 8 and ignore any remainder to get the
\ result we want, which is what the div operator does. So:
\ 
\   (7,   2)     is in character block   (7   div 8,   2 div 8)   =   (0, 0)
\   (57,  82)    is in character block   (57  div 8,  82 div 8)   =   (7, 10)
\   (191, 255)   is in character block   (191 div 8, 255 div 8)   =   (23, 31)
\ 
\ We can do the div 8 operation really easily in assembly language, by shifting
\ right three times, so in assembly, we get this:
\ 
\   Pixel (x, y) is in the character block at (x >> 3, y >> 3)
\ 
\ Next, we can then use the remainder to work out where our pixel is within
\ this 8x8 character block. The remainder is given by the mod operator, so:
\ 
\   (7, 2)       is at pixel   (7   mod 8,   2 mod 8)   =   (7, 2)
\   (57, 82)     is at pixel   (57  mod 8,  82 mod 8)   =   (1, 2)
\   (191, 255)   is at pixel   (191 mod 8, 255 mod 8)   =   (7, 7)
\ 
\ We can do a mod 8 operation really easily in assembly language by simply
\ ANDing with %111, so in assembly, we get this:
\ 
\   Pixel (x, y) is at position (x AND %111, y AND %111) within the character
\ 
\ And this is the algorithm that's implemented in this routine, though with a
\ small twist.
\ 
\ Poking bytes into screen addresses
\ ----------------------------------
\ To summarise, in order to paint pixel (x, y) on screen, we need to update
\ this character block:
\ 
\   (x >> 3, y >> 3)
\ 
\ and this specific pixel within that character block:
\ 
\   (x AND %111, y AND %111)
\ 
\ As mentioned above, we can update this pixel by poking a byte into screen
\ memory, so now we need to work out which memory location we need to update,
\ and what to update it with.
\ 
\ We've already discussed how each character row takes up one page (256 bytes)
\ of memory in Elite's mode 4 screen, so we can work out the page of the
\ location we need to update by taking the y-coordinate of the character for
\ the page. So, if (SCH SC) is the 16-bit address of the byte that we need to
\ update in order to paint pixel (x, y) on screen (i.e. SCH is the high byte and
\ SC is the low byte), then we know:
\ 
\   SCH = &60 + y >> 3
\ 
\ because the first character row takes up page &60 (screen memory starts at
\ &6000), and each character row takes up one page.
\ 
\ Next, within this page of memory, we want to update the character number x >>
\ 3. Each character takes up 8x8 pixels, which is 64 bits, or 8 bytes, so we
\ can calculate the memory location of where that character is stored in screen
\ memory by multiplying the character number by 8, like this:
\ 
\   The character starts at byte (x >> 3) * 8 within the row's page
\ 
\ Next, we know that the pixel we want to update within this block is on row (y
\ AND %111) in the character, and because there are 8 bits in each row (one
\ byte), this is also the byte offset of the start of that row within the
\ character block. So we also know this:
\ 
\   The pixel is in the character byte number (y AND %111)
\ 
\ So, to summarise, we know we need to update this byte in the row's memory
\ page:
\ 
\   (x >> 3) * 8 + (y AND %111)
\ 
\ The final question is what to poke into this byte.
\
\ The two TWOS tables
\ -------------------
\ So we know which byte to update, and we also know which bit to set within
\ that byte - it's bit number (x AND %111). We could always fetch that byte and
\ EOR it with 1 shifted by the relevant number of spaces, but Elite chooses a
\ slightly different approach, one which makes it easier for us to plot not only
\ individual pixels, but also two pixels and even blocks of four.
\
\ The are two tables of bytes, one at TWOS and the other at TWOS2, that contain
\ ready-made bytes for plotting one-pixel and two-pixel points. In each table,
\ the byte at offset X contains a byte that, when poked into a character row,
\ will plot a single-pixel at column X (for TWOS) or a two-pixel "dash" at
\ column X (for TWOS2). As one example, this is what's in the fourth entry from
\ each table (i.e. the entry at offset 3):
\
\   TWOS+3  = %00010000
\
\   TWOS2+3 = %00011000
\
\ This is the value we need to EOR with the byte we worked out above, where the
\ offset is the bit number we want to set, i.e. (x AND %111). Or to put it
\ another way, if we set the following:
\
\   SCH = &60 + y >> 3
\   SC = (x >> 3) * 8 + (y AND %111)
\   X = x AND %111
\
\ then we want to fetch this byte:
\
\   TWOS+X
\
\ and poke it here:
\
\   (SCH SC)
\
\ to set the pixel (x, y) on screen. (Or, if we want to set two pixels at this
\ location, we can use TWOS2, and if we wants a 2x2 square of pixels setting,
\ we can do the same again on the row below.)
\
\ And that's the approach used below.
\ ******************************************************************************

.PIXEL
{
 STY T1                 ; Store Y in T1

 TAY                    ; Copy A into Y, for use later

 LSR A                  ; Set SCH = &60 + A >> 3
 LSR A
 LSR A
 ORA #%01100000
 STA SCH
  
 TXA                    ; Set SC = (X >> 3) * 8
 AND #%11111000
 STA SC

 TYA                    ; Set Y = Y AND %111
 AND #%00000111
 TAY

 TXA                    ; Set X = X AND %111
 AND #%00000111
 TAX

 LDA ZZ                 ; If distance in ZZ >= &90, then this point is a very
 CMP #&90               ; long way away, so jump to PX3 to fetch a 1-pixel point
 BCS PX3                ; from TWOS and EOR it into SC+Y

 LDA TWOS2,X            ; Otherwise fetch a 2-pixel dash from TWOS2 and EOR it
 EOR (SC),Y             ; into SC+Y
 STA (SC),Y

 LDA ZZ                 ; If distance in ZZ >= &50, then this point is a medium
 CMP #&50               ; distance away, so jump to PX13 to stop drawing, as a
 BCS PX13               ; 2-pixel dash is enough
 
                        ; Otherwise we keep going to draw another 2 pixel point
                        ; either above or below the one we just drew, to make a
                        ; 4-pixel square
 
 DEY                    ; Reduce Y by 1 to point to the pixel row above the one
 BPL PX14               ; we just plotted, and if it is still positive, jump to
                        ; PX14 to draw our second 2-pixel dash

 LDY #1                 ; Reducing Y by 1 made it negative, which means Y was
                        ; 0 before we did the DEY above, so set Y to 1 to point
                        ; to the pixel row after the one we just plotted

.PX14

 LDA TWOS2,X            ; Fetch a 2-pixel dash from TWOS2 and EOR it into this
 EOR (SC),Y             ; second row to make a 4-pixel square
 STA (SC),Y

.PX13

 LDY T1                 ; Restore Y from T1, so Y is preserved by the routine

.^PX4

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: BLINE
\
\ Ball line for Circle2 uses (X.T) as next y offset for arc
\ ******************************************************************************

.BLINE                  ; Ball line for Circle2 uses (X.T) as next y offset for arc
{
 TXA
 ADC K4                 ; y0 offset from circle2 is (X,T)
 STA K6+2               ; y2 lo = X + K4 lo
 LDA K4+1
 ADC T
 STA K6+3               ; y2 hi = T + K4 hi

 LDA FLAG               ; set to #&FF at beginning of CIRCLE2
 BEQ BL1                ; flag 0
 INC FLAG

.BL5                    ; counter LSP supplied and updated

 LDY LSP
 LDA #&FF
 CMP LSY2-1,Y
 BEQ BL7                ; end, move K6 to K5
 STA LSY2,Y
 INC LSP
 BNE BL7                ; end, move K6 to K5

.BL1                    ; flag 0 \ Prepare to clip

 LDA K5
 STA XX15               ; x1 lo
 LDA K5+1
 STA XX15+1             ; x1 hi

 LDA K5+2
 STA XX15+2             ; y1 lo
 LDA K5+3
 STA XX15+3             ; y1 hi

 LDA K6
 STA XX15+4             ; x2 lo
 LDA K6+1
 STA XX15+5             ; x2 hi

 LDA K6+2
 STA XX12               ; y2 lo
 LDA K6+3
 STA XX12+1             ; y2 hi

 JSR LL145              ; Clip XX15 XX12 vector
 BCS BL5                ; no line visible, loop LSP
 LDA SWAP
 BEQ BL9                ; skip swap
 LDA X1
 LDY X2
 STA X2
 STY X1
 LDA Y1
 LDY Y2
 STA Y2
 STY Y1

.BL9                    ; swap done

 LDY LSP
 LDA LSY2-1,Y
 CMP #&FF
 BNE BL8                ; skip stores to line buffers
 LDA X1
 STA LSX2,Y
 LDA Y1
 STA LSY2,Y
 INY                    ; LSP+1 other end of line segment

.BL8                    ; skipped stores

 LDA X2
 STA LSX2,Y
 LDA Y2
 STA LSY2,Y
 INY                    ; next LSP
 STY LSP
 JSR LOIN               ; draw line using (X1,Y1), (X2,Y2)

 LDA XX13               ; flag from clip
 BNE BL5                ; loop LSP as XX13 clip

.BL7                    ; end, move K6 to K5, cnt+=stp

 LDA K6
 STA K5
 LDA K6+1
 STA K5+1
 LDA K6+2
 STA K5+2
 LDA K6+3
 STA K5+3
 LDA CNT                ; count
 CLC                    ; cnt += step
 ADC STP                ; step for ring
 STA CNT
 RTS                    ; ball line done.
}

\ ******************************************************************************
\ Subroutine: FLIP
\
\ Switch dusty and dustx
\ ******************************************************************************

.FLIP                   ; switch dusty and dustx
{
\LDA MJ
\BNE FLIP-1
 LDY NOSTM              ; number of dust particles

.FLL1                   ; counter Y

 LDX SY,Y               ; dusty
 LDA SX,Y               ; dustx
 STA Y1
 STA SY,Y               ; dusty
 TXA                    ; old dusty
 STA X1
 STA SX,Y
 LDA SZ,Y
 STA ZZ                 ; dust distance
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY                    ; next buffer entry
 BNE FLL1               ; loop Y
 RTS
}

\ ******************************************************************************
\ Subroutine: STARS
\
\ Dust Field Enter
\ ******************************************************************************

.STARS                  ; Dust Field Enter
{
\LDA #&FF
\STA COL
 LDX VIEW               ; laser mount
 BEQ STARS1             ; Forward Dust
 DEX
 BNE ST11               ; Left or Right dust
 JMP STARS6             ; Rear dust

.ST11                   ; Left or Right dust

 JMP STARS2             ; Left or Right dust

.STARS1                 ; Forward Dust

 LDY NOSTM              ; number of dust particles
}

.STL1                   ; counter Y
{
 JSR DV42               ; P.R = speed/SZ(Y) \ travel step of dust particle front/rear
 LDA R                  ; remainder
 LSR P                  ; hi
 ROR A
 LSR P                  ; hi is now emptied out.
 ROR A                  ; remainder
 ORA #1
 STA Q                  ; upper 2 bits above remainder

 LDA SZL,Y              ; dust zlo
 SBC DELT4              ; upper 2 bits are lowest 2 of speed
 STA SZL,Y              ; dust zlo
 LDA SZ,Y               ; dustz
 STA ZZ                 ; old distance
 SBC DELT4+1            ; hi, speed/4, 10 max
 STA SZ,Y               ; dustz

 JSR MLU1               ; Y1 = SY,Y and P.A = Y1 7bit * Q
 STA YY+1
 LDA P                  ; lo
 ADC SYL,Y              ; dust ylo
 STA YY
 STA R                  ; offsetY lo
 LDA Y1                 ; old SY,Y
 ADC YY+1
 STA YY+1
 STA S

 LDA SX,Y               ; dustx
 STA X1
 JSR MLU2               ; P.A = A7bit*Q
 STA XX+1
 LDA P
 ADC SXL,Y              ; dust xlo
 STA XX
 LDA X1
 ADC XX+1
 STA XX+1

 EOR ALP2+1             ; roll sign
 JSR MLS1               ; P.A = A*alp1 (alp1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STA YY+1
 STX YY

 EOR ALP2               ; roll sign
 JSR MLS2               ; R.S = XX(0to1) and P.A = A*alp1 (alp1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STA XX+1
 STX XX

 LDX BET1               ; pitch lower7 bits
 LDA YY+1
 EOR BET2+1             ; flipped pitch sign
 JSR MULTS-2            ; AP=A*bet1 (bet1+<32)
 STA Q
 JSR MUT2               ; S = XX+1, R = XX, A.P=Q*A
 ASL P
 ROL A
 STA T
 LDA #0
 ROR A
 ORA T
 JSR ADD                ; (A X) = (A P) + (S R)
 STA XX+1
 TXA
 STA SXL,Y              ; dust xlo

 LDA YY
 STA R
 LDA YY+1
\JSR MAD
\STA S
\STX R
 STA S                  ; offset for pix1
 LDA #0
 STA P
 LDA BETA
 EOR #128

 JSR PIX1               ; dust, X1 has xscreen. yscreen = R.S+P.A
 LDA XX+1
 STA X1
 STA SX,Y               ; dustx
 AND #127               ; drop sign
 CMP #120
 BCS KILL1              ; kill the forward dust
 LDA YY+1
 STA SY,Y               ; dusty
 STA Y1
 AND #127               ; drop sign
 CMP #120
 BCS KILL1              ; kill the forward dust

 LDA SZ,Y               ; dustz
 CMP #16
 BCC KILL1              ; kill the forward dust
 STA ZZ                 ; old distance
}

.STC1                   ; Re-enter after kill
{
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY                    ; next dust particle
 BEQ P%+5               ; rts
 JMP STL1               ; loop Y forward dust
 RTS
}

\ ******************************************************************************
\ Subroutine: KILL1
\
\ Kill the forward dust
\ ******************************************************************************

.KILL1                  ; kill the forward dust
{
 JSR DORND              ; Set A and X to random numbers
 ORA #4                 ; flick up/down
 STA Y1                 ; ydistance from middle
 STA SY,Y               ; dusty
 JSR DORND              ; Set A and X to random numbers
 ORA #8                 ; flick left/right
 STA X1
 STA SX,Y               ; dustx
 JSR DORND              ; Set A and X to random numbers
 ORA #&90               ; flick distance
 STA SZ,Y               ; dustz
 STA ZZ                 ; old distance
 LDA Y1                 ; ydistance from middle
 JMP STC1               ; guaranteed, Re-enter forward dust loop
}

\ ******************************************************************************
\ Subroutine: STARS6
\
\ Rear dust
\ ******************************************************************************

.STARS6                 ; Rear dust
{
 LDY NOSTM              ; number of dust particles
}

.STL6                   ; counter Y
{
 JSR DV42               ; travel step of dust particle front/rear
 LDA R                  ; remainder
 LSR P                  ; hi
 ROR A
 LSR P                  ; hi is now emptied out
 ROR A
 ORA #1
 STA Q                  ; upper 2 bits above remainder

 LDA SX,Y               ; dustx
 STA X1
 JSR MLU2               ; P.A = A7bit*Q
 STA XX+1
 LDA SXL,Y              ; dust xlo
 SBC P
 STA XX
 LDA X1
 SBC XX+1
 STA XX+1

 JSR MLU1               ; Y1 = SY,Y and P.A = Y1 7bit * Q
 STA YY+1
 LDA SYL,Y              ; dust ylo
 SBC P
 STA YY
 STA R
 LDA Y1
 SBC YY+1
 STA YY+1
 STA S

 LDA SZL,Y              ; dust zlo
 ADC DELT4              ; upper 2 bits are lowest 2 of speed
 STA SZL,Y              ; dust zlo
 LDA SZ,Y               ; dustz
 STA ZZ                 ; old distance
 ADC DELT4+1            ; hi, speed/4, 10 max
 STA SZ,Y               ; dustz

 LDA XX+1
 EOR ALP2               ; roll sign
 JSR MLS1               ; P.A = A*alp1 (alp1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STA YY+1
 STX YY

 EOR ALP2+1             ; flipped roll sign
 JSR MLS2               ; R.S = XX(0to1) and P.A = A*alp1 (alp1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STA XX+1
 STX XX

 LDA YY+1
 EOR BET2+1             ; flipped pitch sign
 LDX BET1               ; pitch lower7 bits
 JSR MULTS-2            ; AP=A*bet1 (bet1+<32)
 STA Q
 LDA XX+1
 STA S
 EOR #128
 JSR MUT1               ; R = XX, A.P=Q*A
 ASL P
 ROL A
 STA T
 LDA #0
 ROR A
 ORA T
 JSR ADD                ; (A X) = (A P) + (S R)
 STA XX+1
 TXA
 STA SXL,Y              ; dust xlo

 LDA YY
 STA R
 LDA YY+1
 STA S                  ; offset for pix1
\EOR #128
\JSR MAD
\STA S
\STX R
 LDA #0
 STA P
 LDA BETA

 JSR PIX1               ; dust, X1 has xscreen. yscreen = R.S+P.A
 LDA XX+1
 STA X1
 STA SX,Y               ; dustx
 LDA YY+1
 STA SY,Y               ; dusty
 STA Y1
 AND #127               ; ignore sign
 CMP #110
 BCS KILL6              ; rear dust kill

 LDA SZ,Y               ; dustz
 CMP #160
 BCS KILL6              ; rear dust kill
 STA ZZ                 ; old distance
}

.STC6                   ; Re-enter after kill
{
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY
 BEQ ST3                ; rts
 JMP STL6               ; loop Y rear dust

.ST3                    ; rts

 RTS
}

\ ******************************************************************************
\ Subroutine: KILL6
\
\ Rear dust kill
\ ******************************************************************************

.KILL6                  ; rear dust kill
{
 JSR DORND              ; Set A and X to random numbers
 AND #127
 ADC #10
 STA SZ,Y               ; dustz
 STA ZZ                 ; old distance
 LSR A                  ; get carry
 BCS ST4                ; half of the new dust
 LSR A
 LDA #&FC               ; new dustx at edges
 ROR A                  ; may get a carry
 STA X1
 STA SX,Y               ; dustx
 JSR DORND              ; Set A and X to random numbers
 STA Y1
 STA SY,Y               ; dusty
 JMP STC6               ; Re-enter rear dust loop

.ST4                    ; half of the new dust

 JSR DORND              ; Set A and X to random numbers
 STA X1
 STA SX,Y               ; dustx
 LSR A                  ; get carry
 LDA #230               ; new dusty at edges
 ROR A
 STA Y1
 STA SY,Y               ; dusty
 BNE STC6               ; guaranteed, Re-enter rear loop
}

\ ******************************************************************************
\ Variable: PRXS
\
\ Equipment prices.
\ ******************************************************************************

.PRXS
{
 EQUW 1                 ; 0  Fuel, calculated in EQSHP  140.0 Cr (full tank)
 EQUW 300               ; 1  Missile                     30.0 Cr
 EQUW 4000              ; 2  Large Cargo Bay            400.0 Cr
 EQUW 6000              ; 3  E.C.M. System              600.0 Cr
 EQUW 4000              ; 4  Extra Pulse Lasers         400.0 Cr
 EQUW 10000             ; 5  Extra Beam Lasers         1000.0 Cr
 EQUW 5250              ; 6  Fuel Scoops                525.0 Cr
 EQUW 10000             ; 7  Escape Pod                1000.0 Cr
 EQUW 9000              ; 8  Energy Bomb                900.0 Cr
 EQUW 15000             ; 9  Energy Unit               1500.0 Cr
 EQUW 10000             ; 10 Docking Computer          1000.0 Cr
 EQUW 50000             ; 11 Galactic Hyperspace       5000.0 Cr
}

\ ******************************************************************************
\ Subroutine: STATUS
\
\ Show the Status Mode screen (red key f8).
\ ******************************************************************************

{
.st4                    ; We call this from st5 below with the high byte of the
                        ; kill tally in A, which is non-zero, and want to return
                        ; with the following in X, depending on our rating:
                        ;
                        ; Competent = 6
                        ; Dangerous = 7
                        ; Deadly    = 8
                        ; Elite     = 9
                        ;
                        ; The high bytes of the top tier ratings are as follows,
                        ; so this a relatively simple calculation:
                        ;
                        ; Competent       = 1 to 2
                        ; Dangerous       = 2 to 9
                        ; Deadly          = 10 to 24
                        ; Elite           = 25 and up

 LDX #9                 ; Set X to 9 for an Elite rating
 
 CMP #25                ; If A >= 25, jump to st3 to print out our rating, as we
 BCS st3                ; are Elite

 DEX                    ; Decrement X to 8 for a Deadly rating
 
 CMP #10                ; If A >= 10, jump to st3 to print out our rating, as we
 BCS st3                ; are Deadly

 DEX                    ; Decrement X to 7 for a Dangerous rating
 
 CMP #2                 ; If A >= 2, jump to st3 to print out our rating, as we
 BCS st3                ; are Dangerous

 DEX                    ; Decrement X to 6 for a Competant rating

 BNE st3                ; Jump to st3 to print out our rating, as we are
                        ; Competent (this BNE is effectively a JMP as A will
                        ; never be zero)

.^STATUS

 LDA #8                 ; Clear the top part of the screen, draw a box border,
 JSR TT66               ; and set the current view type in QQ11 to 8 (Status
                        ; Mode screen)

 JSR TT111              ; Select the target system closest to galactic
                        ; coordinates (QQ9, QQ10)

 LDA #7                 ; Move the text cursor to column 7
 STA XC

 LDA #126               ; Print recursive token 126, which prints the top
 JSR NLIN3              ; four lines of the Status Mode screen:
                        ;
                        ;         COMMANDER {commander name}
                        ;
                        ;
                        ;   Present System      : {current system name}
                        ;   Hyperspace System   : {selected system name}
                        ;   Condition           :
                        ;
                        ; and draw a horizontal line at pixel row 19 to box
                        ; in the title

 LDA #15                ; Set A to token 129 ("{switch to sentence case}
                        ; DOCKED")

 LDY QQ12               ; Fetch the docked status from QQ12, and if we are
 BNE st6                ; docked, jump to st6 to print "Docked" for our
                        ; ship's condition

 LDA #230               ; Otherwise we are in space, so start off by setting A
                        ; to token 70 ("GREEN")

 LDY MANY+AST           ; Set Y to the number of asteroids in our little bubble
                        ; of universe

 LDX FRIN+2,Y           ; The ship slots at FRIN are ordered with the first two
                        ; slots reserved for the planet and sun/space staion,
                        ; then asteroids, and then ships, so FRIN+2+Y points to
                        ; the first ship-occupied slot, we we fetch into X

 BEQ st6                ; If X = 0 then there are no ships in the vicinity, so
                        ; jump to st6 to print "Green" for our ship's condition

 LDY ENERGY             ; Otherwise we have ships in the vicinity, so we load
                        ; our energy levels into Y

 CPY #128               ; Set the C flag if Y >= 128, so C is set if we have
                        ; more than half of our energy banks charged

 ADC #1                 ; Add 1 + C to A, so if C is not set (i.e. we have low
                        ; energy levels) then A is set to token 231 ("RED"),
                        ; and if C is set (i.e. we have healthy energy levels)
                        ; then A is set to token 232 ("YELLOW")

.st6

 JSR plf                ; Print the text token in A (which contains our ship's
                        ; condition) followed by a newline

 LDA #125               ; Print recursive token 125, which prints the next
 JSR spc                ; three lines of the Status Mode screen:
                        ;
                        ;   Fuel: {fuel level} Light Years
                        ;   Cash: {cash right-aligned to width 9} Cr
                        ;   Legal Status:
                        ;
                        ; followed by a space

 LDA #19                ; Set A to token 133 ("CLEAN")

 LDY FIST               ; Fetch our legal status, and if it is 0, we are clean,
 BEQ st5                ; so jump to st5 to print "Clean"

 CPY #50                ; Set the C flag if Y >= 50, so C is set if we have
                        ; a legal status of 50+ (i.e. we are a fugitive)

 ADC #1                 ; Add 1 + C to A, so if C is not set (i.e. we have a
                        ; legal status between 1 and 49) then A is set to token
                        ; 134 ("OFFENDER"), and if C is set (i.e. we have a
                        ; legal status of 50+) then A is set to token 135
                        ; ("FUGITIVE")

.st5

 JSR plf                ; Print the text token in A (which contains our legal
                        ; status) followed by a newline

 LDA #16                ; Print recursive token 130 ("RATING:")
 JSR spc

 LDA TALLY+1            ; Fetch the high byte of the kill tally, and if it is
 BNE st4                ; not zero, then we have more than 256 kills, so jump
                        ; to st4 to work out whether we are Competent,
                        ; Dangerous, Deadly or Elite

                        ; Otherwise we have fewer than 256 kills, so we are one
                        ; of Harmless, Mostly Harmless, Poor, Average or Above
                        ; Average

 TAX                    ; Set X to 0 (as A is 0)

 LDA TALLY              ; Set A = lower byte of tally / 4
 LSR A
 LSR A

.st5L                   ; We now loop through bits 2 to 7, shifting each of them
                        ; off the end of A until there are no set bits left, and
                        ; incrementing X for each shift, so at the end of the
                        ; process, X contains the position of the leftmost 1 in
                        ; A. Looking at the rank values in TALLY:
                        ;
                        ;   Harmless        = %0000 0000 to %0000 0011
                        ;   Mostly Harmless = %0000 0100 to %0000 0111
                        ;   Poor            = %0000 1000 to %0000 1111
                        ;   Average         = %0001 0000 to %0001 1111
                        ;   Above Average   = %0010 0000 to %1111 1111
                        ;
                        ; we can see that the values returned by this process
                        ; are:
                        ;
                        ;   Harmless        = 1
                        ;   Mostly Harmless = 2
                        ;   Poor            = 3
                        ;   Average         = 4
                        ;   Above Average   = 5

 INX                    ; Increment X for each shift

 LSR A                  ; Shift A to the right

 BNE st5L               ; Keep looping around until A = 0, which means there are
                        ; no set bits left in A
.st3

 TXA                    ; A now contains our rating as a value of 1 to 9, so
                        ; transfer X to A, so we can print it out

 CLC                    ; Print recursive token 135 + A, which will be in the
 ADC #21                ; range 136 ("HARMLESS") to 144 ("---- E L I T E ----")
 JSR plf                ; followed by a newline

 LDA #18                ; Print recursive token 132, which prints the next bit
 JSR plf2               ; of the Status Mode screen:
                        ;
                        ;   EQUIPMENT:
                        ;
                        ; followed by a newline and an indent of 6 characters

 LDA CRGO               ; If our ship's cargo capacity is < 26 (i.e. we do not
 CMP #26                ; have a cargo bay extension), skip the following two
 BCC P%+7               ; instructions

 LDA #107               ; We do have a cargo bay extension, so print recursive
 JSR plf2               ; token 107 ("LARGE CARGO{switch to sentence case}
                        ; BAY"), followed by a newline and an indent of 6
                        ; characters

 LDA BST                ; If we don't have fuel scoops fitted, skip the
 BEQ P%+7               ; following two instructions

 LDA #111               ; We do have a fuel scoops fitted, so print recursive
 JSR plf2               ; token 111 ("FUEL SCOOPS"), followed by a newline and
                        ; an indent of 6 characters

 LDA ECM                ; If we don't have an E.C.M. fitted, skip the following
 BEQ P%+7               ; two instructions

 LDA #108               ; We do have an E.C.M. fitted, so print recursive token
 JSR plf2               ; 108 ("E.C.M.SYSTEM"), followed by a newline and an
                        ; indent of 6 characters

 LDA #113               ; We now cover the four pieces of equipment whose flags
 STA XX4                ; are stored in BOMB through BOMB+3, and whose names
                        ; correspond with text tokens 113 through 116:
                        ;
                        ;   BOMB+0 = BOMB  = token 113 = Energy bomb
                        ;   BOMB+1 = ENGY  = token 114 = Energy unit
                        ;   BOMB+2 = DKCMP = token 115 = Docking computer
                        ;   BOMB+3 = GHYP  = token 116 = Galactic hyperdrive
                        ;
                        ; We can print these out using a loop, so we set XX4 to
                        ; 113 as a counter (and we also set A as well, to pass
                        ; through to plf2)

.stqv

 TAY                    ; Fetch byte BOMB+0 through BOMB+4 for values of XX4 
 LDX BOMB-113,Y         ; from 113 through 117

 BEQ P%+5               ; If it is zero then we do not own that piece of
                        ; equipment, so skip the next instruction
 
 JSR plf2               ; Print the recursive token in A from 113 ("ENERGY
                        ; BOMB") through 116 ("GALACTIC HYPERSPACE "), followed
                        ; by a newline and an indent of 6 characters

 INC XX4                ; Increment the counter (and A as well)
 LDA XX4

 CMP #117               ; If A < 117, loop back up to stqv to print the next
 BCC stqv               ; piece of equipment

 LDX #0                 ; Now to print our ship's lasers, so set a counter in X
                        ; to count through the four laser mounts (0 = front,
                        ; 1 = rear, 2 = left, 3 = right)

.st

 STX CNT                ; Store the laser mount number in CNT

 LDY LASER,X            ; Fetch the laser power for laser mount X, and if we do 
 BEQ st1                ; not have a laser fitted to that view, jump to st1 to
                        ; move on to the next one

 TXA                    ; Print recursive token 96 + X, which will print from 96
 CLC                    ; ("FRONT") through to 99 ("RIGHT"), follwed by a space
 ADC #96
 JSR spc
 
 LDA #103               ; Set A to token 103 ("PULSE LASER")
 
 LDX CNT                ; If the laser power for laser mount X has bit 7 clear,
 LDY LASER,X            ; it is a pulse laser, so skip the following instruction
 BPL P%+4

 LDA #104               ; Set A to token 104 ("BEAM LASER")

 JSR plf2               ; Print the text token in A (which contains our legal
                        ; status) followed by a newline and an indent of 6
                        ; characters

.st1

 LDX CNT                ; Increment the counter in X and CNT to point to the
 INX                    ; next laser mount

 CPX #4                 ; If this isn't the last of the four laser mounts, jump
 BCC st                 ; back up to st to print out the next one

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: plf2
\
\ Print a text token followed by a newline, and indent the next line to text
\ column 6.
\
\ Arguments:
\
\   A           The text token to be printed
\ ******************************************************************************

.plf2
{

 JSR plf                ; Print the text token in A followed by a newline

 LDX #6                 ; Set the text cursor to column 6
 STX XC

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Variable: TENS
\
\ Contains the four low bytes of the value 100,000,000,000 (100 billion).
\
\ The maximum number of digits that we can print with the the BPRNT routine
\ below is 11, so the biggest number we can print is 99,999,999,999. This
\ maximum number plus 1 is 100,000,000,000, which in hexadecimal is:
\
\   & 17 48 76 E8 00
\
\ The TENS variable contains the lowest four bytes in this number, with the
\ least significant byte first, i.e. 00 E8 76 48. This value is used in the
\ BPRNT routine when working out which decimal digits to print when printing a
\ number.
\ ******************************************************************************

.TENS
{
 EQUD &00E87648
}

\ ******************************************************************************
\ Subroutine: pr2
\
\ Print the 8-bit number in X to 3 digits, left-padding with spaces for numbers
\ with fewer than 3 digits (so numbers < 100 are right-aligned). Optionally
\ include a decimal point.
\
\ Arguments:
\
\   X           The number to print
\
\   C flag      If set, include a decimal point
\ ******************************************************************************

.pr2
{
 LDA #3                 ; Set A to the number of digits (3)

 LDY #0                 ; Zero the Y register, so we can fall through into TT11
                        ; to print the 16-bit number (Y X) to 3 digits, which
                        ; effectively prints X to 3 digits as the high byte is
                        ; zero
}

\ ******************************************************************************
\ Subroutine: TT11
\
\ Print the 16-bit number in (Y X) to a specific number of digits, left-padding
\ with spaces for numbers with fewer digits (so lower numbers will be right-
\ aligned). Optionally include a decimal point.
\
\ Arguments:
\
\   X           The low byte of the number to print
\
\   Y           The high byte of the number to print
\
\   A           The number of digits
\
\   C flag      If set, include a decimal point
\ ******************************************************************************

.TT11
{
 STA U                  ; We are going to use the BPRNT routine (below) to
                        ; print this number, so we store the number of digits
                        ; in U, as that's what BPRNT takes as an argument
 
 LDA #0                 ; BPRNT takes a 32-bit number in K to K+3, with the
 STA K                  ; most significant byte first (big-endian), so we set
 STA K+1                ; the two most significant bytes to zero (K and K+1)
 STY K+2                ; and store (Y X) in the least two significant bytes
 STX K+3                ; (K+2 and K+3), so we are going to print the 32-bit
                        ; number (0 0 Y X)

                        ; Finally we fall through into BPRNT to print out the
                        ; number in K to K+3, which now contains (Y X), to 3
                        ; digits (as U = 3), using the same carry flag as when
                        ; pr2 was called to control the decimal point
}

\ ******************************************************************************
\ Subroutine: BPRNT
\
\ Print the 32-bit number stored in K to K+3 to a specific number of digits,
\ left-padding with spaces for numbers with fewer digits (so lower numbers are
\ right-aligned). Optionally include a decimal point.
\
\ Arguments:
\
\   K...K+3     The number to print, stored with the most significant byte in K
\               and the least significant in K+3 (big-endian, which is not the
\               same way that 6502 assembler stores addresses)
\
\   U           The maximum number of digits to print, including the decimal
\               point (spaces will be used on the left to pad out the result to
\               this width, so the number is right-aligned to this width). The
\               maximum number of characters including any decimal point must
\               be 11 or less.
\
\   C flag      If set, include a decimal point followed by one fractional
\               digit (i.e. show the number to 1 decimal place). In this case,
\               the number in K to K+3 contains 10 * the number we end up
\               printing, so to print 123.4, we would pass 1234 in K to K+3 and
\               would set the C flag.
\
\ ******************************************************************************
\
\ The algorithm is relatively simple, but it looks fairly complicated because
\ we're dealing with 32-bit numbers.
\ 
\ To see how it works, let's first consider a simple example with fewer digits.
\ Let's say we want to print out the following number to three digits:
\ 
\   567
\ 
\ First we subtract 100 repeatedly until we can't do it any more, counting how
\ many times we can do this:
\ 
\   567 - 100 - 100 - 100 - 100 - 100 = 67
\ 
\ Not surprisingly, we can subtract it 5 times, so our first digit is 5. Now we
\ multiply the remaining number by 10 to get 670, and repeat the process:
\ 
\   670 - 100 - 100 - 100 - 100 - 100 - 100 = 70
\ 
\ We subtracted 100 6 times, so the second digit is 6. Now to multiply by 10
\ again to get 700 and repeat the process:
\ 
\   700 - 100 - 100 - 100 - 100 - 100 - 100 - 100 = 0
\ 
\ So the third digit is 7 and we are done.
\ 
\ The BPRNT subroutine code does exactly this in its main loop at TT36, except
\ instead of having a three-digit number and subtracting 100, we have up to an
\ 11-digit number and subtract 10 billion each time (as 10 billion has 11
\ digits), using 32-bit arithmetic and an overflow byte, and that's where
\ the complexity comes in.
\ 
\ Given this, let's use some terminology to make it easier to talk about
\ multi-byte numbers, and specifically the big-endian numbers that Elite uses
\ to store large numbers like the current cash amount (big-endian numbers store
\ their most significant byte first, then the lowest significant bytes, which
\ is different to how 6502 assembly stores it's 16-bit numbers; Elite's large
\ numbers are stored in the same way that we write numbers, with the largest
\ digits first, while 6502 does it the other way round, where &30 &FE
\ represents &FE30, for example).
\ 
\ If K is made up of four bytes, then we may talk about K(0 1 2 3) as the
\ 32-bit number that is stored in memory at K thorough K+3, with the most
\ significant byte in K and the least significant in K+3. If we want to add
\ another significant byte to make this a five-byte number - an overflow byte
\ in a memory location called S, say - then we might talk about K(S 0 1 2 3).
\ Similarly, XX15(4 0 1 2 3) is a five-byte number stored with the highest byte
\ in XX15+4, then the next most significant in XX15, then XX15+1 and XX15+2,
\ through to the lowest byte in XX15+3 (yes, the following code does store one
\ of its numbers like this). It might help to think of the digits listed in
\ the brackets as being written down in the same order that we would write them
\ down as humans.
\ 
\ Now that we have some terminology, let's look at the above algorithm. We need
\ multi-byte subtraction, which we can do byte-by-byte using the carry flag,
\ but we also need to be able to multiply a multi-byte number by 10, which is
\ slightly trickier. Multiplying by 10 isn't directly supported the 6502, but
\ multiplying by 2 is, in the guise of shifting and rotating left, so we can do
\ this to multiply K by 10:
\ 
\   K * 10 = K * (2 + 8)
\          = (K * 2) + (K * 8)
\          = (K * 2) + (K * 2 * 2 * 2)
\ 
\ And that's what we do in the TT35 subroutine below, just with 32-bit
\ numbers with an 8-bit overflow. This doubling process is used quite a few
\ times in the following, so let's look an an example, in which we double the
\ number in K(S 0 1 2 3):
\ 
\   ASL K+3
\   ROL K+2
\   ROL K+1
\   ROL K
\   ROL S
\ 
\ First we use ASL K+3 to shift the least significant byte left (so bit 7 goes
\ to the carry flag). Then we rotate the next most significant byte with ROL
\ K+2 (so the carry flag goes into bit 0 and bit 7 goes into the carry), and we
\ repeat this with each byte in turn, until we get to the overflow byte S. This
\ has the effect of shifting the entire five-byte number one place to the left,
\ which doubles it in-place.
\ 
\ Finally, there are three variables that are used as counters in the above
\ loop, each of which gets decremented as we go work our way through the
\ digits. Their starting values are:
\ 
\   XX17   The maximum number of characters to print in total (this is
\          hard-coded to 11)
\ 
\   T      The maximum number of digits that we might end up printing (11 if
\          there's no decimal point, 10 otherwise)
\ 
\   U      The loop number at which we should start printing digits or spaces
\          (calculated from the U argument to BPRNT)
\ 
\ We do the loop XX11 times, once for each character that we might print. We
\ start printing characters once we reach loop number U (at which point we
\ print a space if there isn't a digit at that point, otherwise we print the
\ calculated digit). As soon as we have printed our first digit we set T to 0
\ to indicate that we should print characters for all subsequent loops, so T is
\ effectively a flag for denoting that we're switching from spaces to zeroes
\ for zero values, and decrementing T ensures that we always have at least one
\ digit in the number, even if it's a zero.
\ ******************************************************************************

.BPRNT
{
 LDX #11                ; Set T to the maximum number of digits allowed (11
 STX T                  ; characters, which is the number of digits in 10
                        ; billion); we will use this as a flag when printing
                        ; characters in TT37 below

 PHP                    ; Make a copy of the status register (in particular
                        ; the carry flag) so we can retrieve it later

 BCC TT30               ; If the carry flag is clear, we do not want to print a
                        ; decimal point, so skip the next two instructions

 DEC T                  ; As we are going to show a decimal point, decrement
 DEC U                  ; both the number of characters and the number of
                        ; digits (as one of them is now a decimal point)

.TT30

 LDA #11                ; Set A to 11, the maximum number of digits allowed

 SEC                    ; Set the carry flag so we can do subtraction without
                        ; the carry flag affecting the result

 STA XX17               ; Store the maximum number of digits allowed (11) in
                        ; XX17

 SBC U                  ; Set U = 11 - U + 1, so U now contains the maximum 
 STA U                  ; number of digits minus the number of digits we want
 INC U                  ; to display, plus 1 (so this is the number of digits
                        ; we should skip before starting to print the number
                        ; itself, and the plus 1 is there to ensure we at least
                        ; print one digit)

 LDY #0                 ; In the main loop below, we use Y to count the number
                        ; of times we subtract 10 billion to get the left-most
                        ; digit, so set this to zero (see below TT36 for an
                        ; of how this algorithm works)

 STY S                  ; In the main loop below, we use location S as an
                        ; 8-bit overflow for the 32-bit calculations, so
                        ; we need to set this to 0 before joining the loop

 JMP TT36               ; Jump to TT36 to start the process of printing this
                        ; number's digits

.TT35                   ; This subroutine multiplies K(S 0 1 2 3) by 10 and
                        ; stores the result back in K(S 0 1 2 3), using the
                        ; (K * 2) + (K * 2 * 2 * 2) approach described above

 ASL K+3                ; Set K(S 0 1 2 3) = K(S 0 1 2 3) * 2 by rotating bits.
 ROL K+2                ; See above for an explanation.
 ROL K+1
 ROL K
 ROL S

 LDX #3                 ; Now we want to make a copy of the newly doubled K in
                        ; XX15, so we can use it for the first (K * 2) in the
                        ; equation above, so set up a counter in X for copying
                        ; four bytes, starting with the last byte in memory
                        ; (i.e. the least significant)

.tt35

 LDA K,X                ; Copy the X-th byte of K(0 1 2 3) to the X-th byte of
 STA XX15,X             ; XX15(0 1 2 3), so that XX15 will contain a copy of
                        ; K(0 1 2 3) once we've copied all four bytes

 DEX                    ; Decrement the loop counter so we move to the next
                        ; byte, going from least significant (3) to most
                        ; significant (0)
 
 BPL tt35               ; Loop back to copy the next byte
 
 LDA S                  ; Store the value of location S, our overflow byte, in
 STA XX15+4             ; XX15+4, so now XX15(4 0 1 2 3) contains a copy of
                        ; K(S 0 1 2 3), which is the value of (K * 2) that we
                        ; want

 ASL K+3                ; Now to calculate the (K * 2 * 2 * 2) part. We still
 ROL K+2                ; have (K * 2) in K(S 0 1 2 3), so we just need to
 ROL K+1                ; it twice. This is the first one, so we do
 ROL K                  ; K(S 0 1 2 3) = K(S 0 1 2 3) * 2 (i.e. K * 4)
 ROL S

 ASL K+3                ; And then we do it again, so that means
 ROL K+2                ; K(S 0 1 2 3) = K(S 0 1 2 3) * 2 (i.e. K * 8)
 ROL K+1
 ROL K
 ROL S

 CLC                    ; Clear the carry flag so we can do addition without
                        ; the carry flag affecting the result
 
 LDX #3                 ; By now we've got (K * 2) in XX15(4 0 1 2 3) and
                        ; (K * 8) in K(S 0 1 2 3), so the final step is to add
                        ; these two 32-bit numbers together to get K * 10.
                        ; So we set a counter in X for four bytes, starting
                        ; with the last byte in memory (i.e. the least
                        ; significant)

.tt36

 LDA K,X                ; Fetch the X-th byte of K into A

 ADC XX15,X             ; Add the X-th byte of XX15 to A, with carry

 STA K,X                ; Store the result in the X-th byte of K
 
 DEX                    ; Decrement the loop counter so we move to the next
                        ; byte, going from least significant (3) to most
                        ; significant (0)
 
 BPL tt36               ; Loop back to add the next byte

 LDA XX15+4             ; Finally, fetch the overflow byte from XX15(4 0 1 2 3)

 ADC S                  ; And add it to the overflow byte from K(S 0 1 2 3),
                        ; with carry

 STA S                  ; And store the result in the overflow byte from
                        ; K(S 0 1 2 3), so now we have our desired result that
                        ; K(S 0 1 2 3) is now K(S 0 1 2 3) * 10

 LDY #0                 ; In the main loop below, we use Y to count the number
                        ; of times we subtract 10 billion to get the left-most
                        ; digit, so set this to zero

.TT36                   ; This is the main loop of our digit-printing routine.
                        ; In the following loop, we are going to count the
                        ; number of times that we can subtract 10 million in Y,
                        ; which we have already set to 0

 LDX #3                 ; Our first calculation concerns 32-bit numbers, so
                        ; set up a counter for a four-byte loop

 SEC                    ; Set the carry flag so we can do subtraction without
                        ; the carry flag affecting the result

.tt37                   ; Now we loop thorough each byte in turn to do this:

                        ;
                        ; XX15(4 0 1 2 3) = K(S 0 1 2 3) - 100,000,000,000

 LDA K,X                ; Subtract the X-th byte of TENS (i.e. 10 billion) from
 SBC TENS,X             ; the X-th byte of K

 STA XX15,X             ; Store the result in the X-th byte of XX15

 DEX                    ; Decrement the loop counter so we move to the next
                        ; byte, going from least significant (3) to most
                        ; significant (0)

 BPL tt37               ; Loop back to subtract from the next byte

 LDA S                  ; Subtract the fifth byte of 10 billion (i.e. &17) from
 SBC #&17               ; the fifth (overflow) byte of K, which is S
 
 STA XX15+4             ; Store the result in the overflow byte of XX15

 BCC TT37               ; If subtracting 10 billion took us below zero, jump to
                        ; TT37 to print out this digit, which is now in Y

 LDX #3                 ; We now want to copy XX15(4 0 1 2 3) back to
                        ; K(S 0 1 2 3), so we can loop back up to do the next
                        ; subtraction, so set up a counter for a four-byte loop

.tt38

 LDA XX15,X             ; Copy the X-th byte of XX15(0 1 2 3) to the X-th byte
 STA K,X                ; of K(0 1 2 3), so that K will contain a copy of
                        ; XX15(0 1 2 3) once we've copied all four bytes
 
 DEX                    ; Decrement the loop counter so we move to the next
                        ; byte, going from least significant (3) to most
                        ; significant (0)
 
 BPL tt38               ; Loop back to copy the next byte

 LDA XX15+4             ; Store the value of location XX15+4, our overflow
 STA S                  ; byte in S, so now K(S 0 1 2 3) contains a copy of
                        ; XX15(4 0 1 2 3)
 
 INY                    ; We have now managed to subtract 10 billion from our
                        ; number, so increment Y, which is where we are keeping
                        ; count of the number of subtractions so far
 
 JMP TT36               ; Jump back to TT36 to subtract the next 10 billion

.TT37

 TYA                    ; If we get here then Y contains the digit that we want
                        ; to print (as Y has now counted the total number of
                        ; subtractions of 10 billion), so transfer Y into A

 BNE TT32               ; If the digit is non-zero, jump to TT32 to print it

 LDA T                  ; Otherwise the digit is zero. If we are already
                        ; printing the number then we will want to print a 0,
                        ; but if we haven't started printing the number yet,
                        ; then we probbaly don't, as we don't want to print
                        ; leading zeroes unless this is the only digit before
                        ; the decimal point
                        ; 
                        ; To help with this, we are going to use T as a flag
                        ; that tells us whether we have already started
                        ; printing digits:
                        ;
                        ;   If T <> 0 we haven't printed anything yet
                        ;   If T = 0 then we have started printing digits
                        ;
                        ; We initially set T to the maximum number of
                        ; characters allowed at, less 1 if we are printing a
                        ; decimal point, so the first time we enter the digit
                        ; printing routine at TT37, it is definitely non-zero
 
 BEQ TT32               ; If T = 0, jump straight to the print routine at TT32,
                        ; as we have already started printing the number, so we
                        ; definitely want to print this digit too

 DEC U                  ; We initially set U to the number of digits we want to
 BPL TT34               ; skip before starting to print the number. If we get
                        ; here then we haven't printed any digits yet, so
                        ; decrement U to see if we have reached the point where
                        ; we should start printing the number, and if not, jump
                        ; to TT34 to set up things for the next digit

 LDA #' '               ; We haven't started printing any digits yet, but we
 BNE tt34               ; have reached the point where we should start printing
                        ; our number, so call TT26 (via tt34) to print a space
                        ; so that the number is left-padded with spaces (this
                        ; BNE is effectively a JMP as A will never be zero)

.TT32

 LDY #0                 ; We are printing an actual digit, so first set T to 0,
 STY T                  ; to denote that we have now started printing digits as
                        ; opposed to spaces

 CLC                    ; The digit value is in A, so add ASCII "0" to get the
 ADC #'0'               ; ASCII character number to print

.tt34

 JSR TT26               ; Print the character in A and fall through into TT34
                        ; to get things ready for the next digit

.TT34

 DEC T                  ; Decrement T but keep T >= 0 (by incrementing it
 BPL P%+4               ; again if the above decrement made T negative)
 INC T

 DEC XX17               ; Decrement the total number of characters to print in
                        ; XX17

 BMI RR3+1              ; If it is negative, we have printed all the characters
                        ; so return from the subroutine (as RR3 contains an
                        ; ORA #&60 instruction, so RR3+1 is &60, which is the
                        ; opcode for an RTS)

 BNE P%+10              ; If it is positive (> 0) loop back to TT35 (via the
                        ; last instruction in this subroutine) to print the
                        ; next digit

 PLP                    ; If we get here then we have printed the exact number
                        ; of digits that we wanted to, so restore the carry
                        ; flag that we stored at the start of BPRNT

 BCC P%+7               ; If carry is clear, we don't want a decimal point, so
                        ; look back to TT35 (via the last instruction in this
                        ; subroutine) to print the next digit

 LDA #'.'               ; Print the decimal point
 JSR TT26

 JMP TT35               ; Loop back to TT35 to print the next digit
}

\ ******************************************************************************
\ Subroutine: BELL
\
\ Make a beep sound.
\ ******************************************************************************

.BELL
{
 LDA #7                 ; Control code 7 makes a beep, so load this into A so
                        ; we can fall through into the TT27 print routine to
                        ; actually make the sound
}

\ ******************************************************************************
\ Subroutine: TT26
\
\ Other entry points: RR3, RREN, RR4, rT9 RTS, R5
\
\ Print a character at the text cursor (XC, YC), do a beep, print a newline,
\ or delete left (backspace).
\
\ WRCHV is set to point here by elite-loader.asm.
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\
\                 * 127 (delete the character to the left of the text cursor
\                   and move the cursor to the left)
\
\   XC            Contains the text column to print at (the x-coordinate)
\
\   YC            Contains the line number to print on (the y-coordinate)
\
\ Returns:
\
\   A           A is preserved
\
\   X           X is preserved
\
\   Y           Y is preserved
\
\   C flag      Carry is cleared
\ ******************************************************************************

.TT26
{
 STA K3                 ; Store the A, X and Y registers, so we can restore
 STY YSAV2              ; them at the end (so they don't get changed by this
 STX XSAV2              ; routine)

 LDY QQ17               ; Load the QQ17 flag, which contains the text printing
                        ; flags

 CPY #&FF               ; If QQ17 = #&FF, then jump to RR4, which doesn't print
 BEQ RR4                ; anything, it just restore of the registers and
                        ; returns from the subroutine

 CMP #7                 ; If this is a beep character (A = 7), jump to R5,
 BEQ R5                 ; which will emit the beep, restore the registers and
                        ; return from the subroutine

 CMP #32                ; If this is an ASCII character (A >= 32), jump to RR1
 BCS RR1                ; below, which will print the character, restore the
                        ; registers and return from the subroutine

 CMP #10                ; If this is control code 10 (line feed) then jump to
 BEQ RRX1               ; RRX1, which will move down a line, restore the
                        ; registers and return from the subroutine

 LDX #1                 ; If we get here, then this is control code 11-13, of
 STX XC                 ; which only 13 is used. This code prints a newline,
                        ; which we can achieve by moving the text cursor
                        ; to the start of the line (carriage return) and down
                        ; one line (line feed). These two lines do the first
                        ; bit by setting XC = 1, and we then fall through into
                        ; the line feed routine that's used by control code 10

.RRX1

 INC YC                 ; Print a line feed, simply by incrementing the row
                        ; number (y-coordinate) of the text cursor, which is
                        ; stored in YC

 BNE RR4                ; Jump to RR4 to restore the registers and return from
                        ; the subroutine (this BNE is effectively a JMP as Y
                        ; will never be zero)

.RR1                    ; If we get here, then the character to print is an
                        ; ASCII character in the range 32-95. The quickest way
                        ; to display text on screen is to poke the character
                        ; pixel by pixel, directly into screen memory, so
                        ; that's what the rest of this routine does.
                        ; 
                        ; The first step, then, is to get hold of the bitmap
                        ; definition for the character we want to draw on the
                        ; screen (i.e. we need the pixel shape of this
                        ; character). The OS ROM contains bitmap definitions
                        ; of the BBC's ASCII characters, starting from &C000
                        ; for space (ASCII 32) and ending with the £ symbol
                        ; (ASCII 126).
                        ;
                        ; There are 32 characters' definitions in each page of
                        ; memory, as each definition takes up 8 bytes (8 rows
                        ; of 8 pixels) and 32 * 8 = 256 bytes = 1 page. So:
                        ;
                        ;   ASCII 32-63  are defined in &C000-&C0FF (page &C0)
                        ;   ASCII 64-95  are defined in &C100-&C1FF (page &C1)
                        ;   ASCII 96-126 are defined in &C200-&C2F0 (page &C2)
                        ;
                        ; The following code reads the relevant character
                        ; bitmap from the above locations in ROM and pokes
                        ; those values into the correct position in screen
                        ; memory, thus printing the character on screen
                        ;
                        ; It's a long way from 10 PRINT "Hello world!":GOTO 10

\LDX #LO(K3)            ; These instructions are commented out in the original
\INX                    ; source, but they call OSWORD &A, which reads the
\STX P+1                ; character bitmap for the character number in K3 and
\DEX                    ; stores it in the block at K3+1, while also setting
\LDY #HI(K3)            ; P+1 to point to the character definition. This is
\STY P+2                ; exactly what the following uncommented code does,
\LDA #10                ; just without calling OSWORD. Presumably the code
\JSR OSWORD             ; below is faster than using the system call, as this
                        ; version takes up 15 bytes, while the version below
                        ; (which ends with STA P+1 and SYX P+2) is 17 bytes.
                        ; Every efficiency saving helps, especially as this
                        ; routine is run each time the game prints a character.
                        ;
                        ; If you want to switch this code back on, uncomment
                        ; the above block, and comment out the code below from
                        ; TAY to STX P+2. You will also need to uncomment the
                        ; LDA YC instruction a few lines down (in RR2), just to
                        ; make sure the rest of the code doesn't shift in
                        ; memory. To be honest I can't see a massive difference
                        ; in speed, but there you go.

 TAY                    ; Copy the character number from A to Y, as we are
                        ; about to pull A apart to work out where this
                        ; character definition lives in the ROM

                        ; Now we want to set X to point to the revevant page
                        ; number for this character - i.e. &C0, &C1 or &C2.
                        ; The following logic is easier to follow if we look
                        ; at the three character number ranges in binary:
                        ;
                        ;   Bit # 7654 3210
                        ; 
                        ;   32  = 0010 0000     Page &C0
                        ;   63  = 0011 1111
                        ;
                        ;   64  = 0100 0000     Page &C1
                        ;   95  = 0101 1111
                        ;
                        ;   96  = 0110 0000     Page &C2
                        ;   125 = 0111 1101
                        ;
                        ; We'll refer to this below.

 LDX #&BF               ; Set X to point to the first font page in ROM minus 1,
                        ; which is &C0 - 1, or &BF

 ASL A                  ; If bit 6 of the character is clear (A is 32-63)
 ASL A                  ; then skip the following instruction
 BCC P%+4

 LDX #&C1               ; A is 64-126, so set X to point to page &C1

 ASL A                  ; If bit 5 of the character is clear (A is 64-95)
 BCC P%+3               ; then skip the following instruction

 INX                    ; Increment X
                        ;
                        ; By this point, we started with X = &BF, and then
                        ; we did the following:
                        ;
                        ;   If A = 32-63:   skip    then INX  so X = &C0
                        ;   If A = 64-95:   X = &C1 then skip so X = &C1
                        ;   If A = 96-126:  X = &C1 then INX  so X = &C2
                        ;
                        ; In other words, X points to the relevant page. But
                        ; what about the value of A? That gets shifted to the
                        ; left three times during the above code, which
                        ; multiplies the number by 8 but also drops bits 7, 6
                        ; and 5 in the process. Look at the above binary
                        ; figures and you can see that if we cleared bits 5-7,
                        ; then that would change 32-53 to 0-31... but it would
                        ; do exactly the same to 64-95 and 96-125. And because
                        ; we also multiply this figure by 8, A now points to
                        ; the start of the character's definition within its
                        ; page (because there are 8 bytes per character
                        ; definition).
                        ;
                        ; Or, to put it another way, X contains the high byte
                        ; (the page) of the address of the definition that we
                        ; want, while A contains the low byte (the offset into
                        ; the page) of the address.
 
 STA P+1                ; Store the address of this character's definition in
 STX P+2                ; P+1 (low byte) and P+2 (high byte)

 LDA XC                 ; Fetch XC, the x-coordinate (column) of the text
 ASL A                  ; cursor, multiply by 8, and store in SC. As each
 ASL A                  ; character is 8 bits wide, and the special screen mode
 ASL A                  ; Elite uses for the top part of the screen is 256
 STA SC                 ; bits across with one bit per pixel, this value is 
                        ; not only the screen address offest of the text cursor
                        ; from the left side of the screen, it's also the least
                        ; significant byte of the screen address where we want
                        ; to print this character, as each row of on-screen
                        ; pixels corresponds to one page. To put this more
                        ; explicitly, the screen starts at &6000, so the
                        ; text rows are stored in screen memory like this:
                        ;
                        ;   Row 1: &6000 - &60FF    YC = 1, XC = 0 to 31
                        ;   Row 2: &6100 - &61FF    YC = 2, XC = 0 to 31
                        ;   Row 3: &6200 - &62FF    YC = 3, XC = 0 to 31
                        ;
                        ; and so on.
 
 LDA YC                 ; Fetch YC, the y-coordinate (row) of the text cursor

 CPY #127               ; If the character number (which is in Y) <> 127, then
 BNE RR2                ; skip to RR2 to print that character, otherwise this is
                        ; the delete character, so continue on

 DEC XC                 ; We want to delete the character to the left of the
                        ; text cursor and move the cursor back one, so let's
                        ; do that by decrementing YC. Note that this doesn't
                        ; have anything to do with the actual deletion below,
                        ; we're just updating the cursor so it's in the right
                        ; position following the deletion.

 ADC #&5E               ; A contains YC (from above) and the carry flag is set
 TAX                    ; (from the CPY #127 above), so these instructions do
                        ; this: X = YC + &5E + 1 = YC + &5F
                        ;
                        ; Because YC starts at 1 for the first text row, this
                        ; means that X will be &60 for row 1, &61 for row 2
                        ; and so on. In other words, X is now set to the page
                        ; number for the relevant row in screen memory (see
                        ; the comment above).

 LDY #&F8               ; Set Y = -8

 JSR ZES2               ; Call ZES2, which zero-fills the page pointed to by X,
                        ; from position SC + Y to SC - so that's the 8 bytes
                        ; before SC. We set SC above to point to the current
                        ; character, so this zero-fills the character before
                        ; that, effectively deleting the character to the left

 BEQ RR4                ; We are done deleting, so restore the registers and
                        ; return from the subroutine (this BNE is effectively
                        ; a JMP as ZES2 always returns with the zero flag set)

.RR2                    ; Now to actually print the character

 INC XC                 ; Once we print the character, we want to move the text
                        ; cursor to the right, so we do this by incrementing
                        ; XC. Note that this doesn't have anything to do
                        ; with the actual printing below, we're just updating
                        ; the cursor so it's in the right position following
                        ; the print.

\LDA YC                 ; This instruction is commented out in the original
                        ; source. It isn't required because we only just did a
                        ; LDA YC before jumping to RR2, so this is presumably
                        ; an example of the authors squeezing the code to save
                        ; 2 bytes and 3 cycles.
                        ;
                        ; If you want to re-enable the commented block near the
                        ; start of this routine, you should uncomment this
                        ; instruction as well

 CMP #24                ; If the text cursor is on the screen (i.e. YC < 24, so
 BCC RR3                ; we are on rows 1-23), then jump to RR3 to print the
                        ; character

 JSR TTX66              ; Otherwise we are off the bottom of the screen, so
                        ; clear the screen and draw a box border

 JMP RR4                ; And restore the registers and return from the
                        ; subroutine

.^RR3

 ORA #&60               ; A contains the value of YC - the screen row where we
                        ; want to print this character - so now we need to
                        ; convert this into a screen address, so we can poke
                        ; the character data to the right place in screen
                        ; memory. We already stored the least significant byte
                        ; of this screen address in SC above (see the STA SC
                        ; instruction above), so all we need is the most
                        ; significant byte. As mentioned above, in Elite's
                        ; square mode 4 screen, each row of text on screen
                        ; takes up exactly one page, so the first row is page
                        ; &60xx, the second row is page &61xx, so we can get
                        ; the page for character (XC, YC) by OR-ing with &60.
                        ; To see this in action, consider that our two values
                        ; are, in binary:
                        ;
                        ;   YC is between:  %0000 0000
                        ;             and:  %0001 0111
                        ;          &60 is:  %0110 0000
                        ;
                        ; so YC OR &60 effectively adds &60 to YV, giving us
                        ; the page number that we want

.^RREN

 STA SC+1               ; Store the page number of the destination screen
                        ; location in SC+1, so SC now points to the full screen
                        ; location where this character should go

 LDY #7                 ; We want to print the 8 bytes of character data to the
                        ; screen (one byte per row), so set up a counter in Y
                        ; to count these bytes

.RRL1

 LDA (P+1),Y            ; The character definition is at P+1 (low byte) and P+2
                        ; (high byte) - we set this up above -  so load the
                        ; Y-th byte from P+1

 EOR (SC),Y             ; If we EOR this value with the existing screen
                        ; contents, then it's reversible (so reprinting the
                        ; same character in the same place will revert the
                        ; screen to what it looked like before we printed
                        ; anything); this means that printing a white pixel on
                        ; onto a white background results in a black pixel, but
                        ; that's a small price to pay for easily erasable text

 STA (SC),Y             ; Store the Y-th byte at the screen address for this
                        ; character location

 DEY                    ; Decrement the loop counter

 BPL RRL1               ; Loop back for the next byte to print to the screen=

.^RR4

 LDY YSAV2              ; We're done printing, so restore the values of the
 LDX XSAV2              ; A, X and Y registers that we saved above and clear
 LDA K3                 ; the carry flag, so everything is back to how it was
 CLC

.^rT9

 RTS                    ; Return from the subroutine

.^R5

 JSR BEEP               ; Call the BEEP subroutine to make a short, high beep

 JMP RR4                ; Jump to RR4 to restore the registers and return from
                        ; the subroutine
}

\ ******************************************************************************
\ Subroutine: DIALS
\
\ Update the dashboard.
\ ******************************************************************************

.DIALS                  ; update displayed Dials
{
 LDA #&D0               ; screen lo
 STA SC                 ; bottom console (SC) = &78D0
 LDA #&78               ; screen hi
 STA SC+1
 JSR PZW                ; flashing X.A = F0.0F or F0.0?
 STX K+1
 STA K
 LDA #14                ; threshold to change colour
 STA T1
 LDA DELTA              ; player ship's speed
\LSR A
 JSR DIL-1              ; only /2

 LDA #0
 STA R                  ; lo
 STA P                  ; lo
 LDA #8                 ; center indicator
 STA S                  ; = 8 hi
 LDA ALP1               ; roll magnitude
 LSR A
 LSR A
 ORA ALP2               ; roll sign
 EOR #128               ; flipped
 JSR ADD                ; (A X) = (A P) + (S R)
 JSR DIL2               ; roll/pitch indicator takes X.A
 LDA BETA               ; pitch
 LDX BET1               ; pitch sign
 BEQ P%+4               ; skip sbc #1
 SBC #1                 ; will add S=8 to Acc to center
 JSR ADD                ; (A X) = (A P) + (S R)
 JSR DIL2               ; roll/pitch indicator takes X.A

 LDA MCNT               ; movecount
 AND #3                 ; only 1in4 times
 BNE rT9                ; continue, else rts
 LDY #0
 JSR PZW                ; flashing X.A = F0.0F or F0.0
 STX K
 STA K+1
 LDX #3                 ; 4 energy banks
 STX T1                 ; threshold

.DLL23                  ; counter X

 STY XX12,X
 DEX                    ; energy bank
 BPL DLL23              ; loop X
 LDX #3                 ; player's energy
 LDA ENERGY
 LSR A
 LSR A                  ; = ENERGY/4
 STA Q

.DLL24                  ; counter X

 SEC
 SBC #16                ; each bank
 BCC DLL26              ; exit subtraction with valid Q, X
 STA Q                  ; bank fraction
 LDA #16                ; full bank
 STA XX12,X
 LDA Q
 DEX                    ; next energy bank, 0 will be top one.
 BPL DLL24              ; loop X
 BMI DLL9               ; guaranteed hop, all full.

.DLL26                  ; exit subtraction with valid Q, X

 LDA Q                  ; bank fraction
 STA XX12,X

.DLL9                   ; all full, counter Y

 LDA XX12,Y
 STY P                  ; store Y
 JSR DIL                ; energy bank
 LDY P                  ; restore Y
 INY
 CPY #4                 ; reached last energy bank?
 BNE DLL9               ; loop Y

 LDA #&78               ; move to top left row
 STA SC+1
 LDA #16                ; some comment about in range 0to80, shield range
 STA SC
 LDA FSH                ; forward shield
 JSR DILX               ; shield bar
 LDA ASH                ; aft shield
 JSR DILX               ; shield bar
 LDA QQ14               ; ship fuel #70 = #&46
 JSR DILX+2             ; /8 not /16 bar

 JSR PZW                ; flashing X.A = F0.0F or F0.0
 STX K+1
 STA K
 LDX #11                ; ambient cabin temperature
 STX T1                 ; threshold to change bar colour
 LDA CABTMP             ; cabin temperature
 JSR DILX               ; shield bar
 LDA GNTMP              ; laser temperature
 JSR DILX               ; shield bar

 LDA #&F0               ; high altitude
 STA T1                 ; threshold to change bar colour
 STA K+1
 LDA ALTIT              ; Altimeter
 JSR DILX               ; shield bar
 JMP COMPAS             ; space compass.

.PZW                    ; Flashing X.A = F0.0F or F0.0?

 LDX #&F0               ; yellow
 LDA MCNT               ; movecount
 AND #8
 AND FLH                ; flash toggle
 BEQ P%+4               ; if zero default to lda #&0F
 TXA                    ; else return A = X

 EQUB &2C               ; Skip the next instruction by turning it into
                        ; &2C &A9 &0F, or BIT &0FA9, which does nothing bar
                        ; affecting the flags

 LDA #15                ; red

 RTS
}

\ ******************************************************************************
\ Subroutine: DILX
\
\ Show speed, shield bar, fuel
\ ******************************************************************************

.DILX                   ; shield bar
{
 LSR A                  ; /=  2
 LSR A                  ; fuel bar starts here
 LSR A                  ; DILX+2
 LSR A                  ; DIL-1
}

.DIL                    ; energy bank
{
 STA Q                  ; bar value 0to15
 LDX #&FF               ; mask
 STX R
 CMP T1                 ; threshold to change bar colour
 BCS DL30               ; Acc >= threshold colour will be K
 LDA K+1                ; other colour
 BNE DL31               ; skip lda K

.DL30                   ; threshold colour will be K

 LDA K

.DL31

 STA COL                ; the colour
 LDY #2                 ; height offset
 LDX #3                 ; height of bar-1

.DL1                    ; counter X height

 LDA Q                  ; bar value 0to15
 CMP #4
 BCC DL2                ; exit, Q < 4
 SBC #4
 STA Q
 LDA R                  ; mask

.DL5                    ; loop Mask

 AND COL
 STA (SC),Y
 INY
 STA (SC),Y
 INY
 STA (SC),Y
 TYA                    ; step to next char
 CLC
 ADC #6                 ; +=6
 TAY
 DEX                    ; reduce height
 BMI DL6                ; ended, next bar.
 BPL DL1                ; else guaranteed loop X height

.DL2                    ; exited, Q < 4

 EOR #3                 ; counter
 STA Q
 LDA R                  ; load up mask colour byte = &FF

.DL3                    ; counter small Q

 ASL A                  ; empty out mask
 AND #239
 DEC Q
 BPL DL3                ; loop Q
 PHA                    ; store mask
 LDA #0                 ; black
 STA R
 LDA #99                ; into Q
 STA Q
 PLA                    ; restore mask
 JMP DL5                ; up, loop mask

.DL6                    ; next bar

 INC SC+1

.DL9

 RTS
}

\ ******************************************************************************
\ Subroutine: DIL2
\
\ Show roll/pitch indicator
\ ******************************************************************************

.DIL2                   ; roll/pitch indicator takes X.A
{
 LDY #1                 ; counter Y = 1
 STA Q                  ; xpos

.DLL10                  ; counter Y til #30

 SEC
 LDA Q                  ; xpos
 SBC #4                 ; xpos-4
 BCS DLL11              ; blank
 LDA #&FF               ; else indicator
 LDX Q                  ; palette index
 STA Q                  ; = #&FF
 LDA CTWOS,X
 AND #&F0               ; Mode5 colour yellow
 BNE DLL12              ; fill

.DLL11                  ; blank

 STA Q                  ; new xpos
 LDA #0

.DLL12                  ; fill

 STA (SC),Y
 INY
 STA (SC),Y
 INY
 STA (SC),Y
 INY
 STA (SC),Y
 TYA                    ; step to next char
 CLC
 ADC #5
 TAY                    ; Y updated to next char
 CPY #30
 BCC DLL10              ; loop Y
 INC SC+1               ; next row, at end.
 RTS
}

\ ******************************************************************************
\ Variable: TVT1
\
\ Palette bytes for use with the split screen mode (see IRQ1 below for more
\ details).
\
\ Palette data is given as a set of bytes, with each byte mapping a logical
\ colour to a physical one. In each byte, the logical colour is given in bits
\ 4-7 and the physical colour in bits 0-3. See p.379 of the Advanced User Guide
\ for details of how palette mapping works, as in modes 4 and 5 we have to do
\ multiple palette commands to change the colours correctly, and the physical
\ colour value is EOR'd with 7, just to make things even more confusing. 
\
\ Similarly, the palette at TVT1+16 is for the monochrome space view, where
\ logical colour 1 is mapped to physical colour 0 EOR 7 = 7 (white), and
\ logical colour 0 is mapped to physical colour 7 EOR 7 = 0 (black). Each of
\ these mappings requires six calls to SHEILA+&21 - see p.379 of the Advanced
\ User Guide for an explanation.
\ ******************************************************************************

.TVT1

 EQUB &D4,&C4,&94,&84   ; This block of palette data is used to create two
 EQUB &F5,&E5,&B5,&A5   ; palettes used in three different places, all of them
 EQUB &76,&66,&36,&26   ; redefining four colours in mode 5:
 EQUB &E1,&F1,&B1,&A1   ;
                        ; 12 bytes from TVT1 (i.e. the first 3 EQUDs): applied
                        ; when the T1 timer runs down at the switch from the
                        ; space view to the dashboard, so this is the standard
                        ; dashboard palette
                        ; 
                        ; 8 bytes from TVT1+8 (i.e. the last 2 EQUDs): applied
                        ; when the T1 timer runs down at the switch from the
                        ; space view to the dashboard, and we have an escape
                        ; pod fitted, so this is the escape pod dashboard
                        ; palette
                        ;
                        ; 8 bytes from TVT1+8 (i.e. the last 2 EQUDs): applied
                        ; at vertical sync in LINSCN when HFX is non-zero, to
                        ; create the hyperspace effect in LINSCN (where the
                        ; whole screen is switched to mode 5 at vertical sync)

 EQUB &F0,&E0,&B0,&A0   ; 12 bytes of palette data at TVT1+16, used to set the
 EQUB &D0,&C0,&90,&80   ; mode 4 palette in LINSCN when we hit vertical sync,
 EQUB &77,&67,&37,&27   ; so the palette is set to monochrome when we start to
                        ; draw the first row of the screen


\ ******************************************************************************
\ Subroutine: IRQ1
\
\ The main interrupt handler, which implements Elite's split screen mode.
\
\ IRQ1V is set to point to IRQ1 by elite-loader.asm.
\
\ ******************************************************************************
\
\ Elite uses a unique split-screen mode that enables a high-resolution
\ black-and-white space view to coexist with a lower resolution, colour ship
\ dashboard. There are two parts to this screen mode: the custom mode, and the
\ split-screen aspect.
\ 
\ Elite's screen mode is a custom mode, based on mode 4 but with fewer pixels.
\ This mode is set up in elite-loader.asm by reprogramming the registers of the
\ 6845 CRTC - see the section on VDU command data in that file for more
\ details, but the salient part is the screen size, which is 32 columns by 31
\ rows rather than the 40 x 32 of standard mode 4. Screen sizes are given in
\ terms of characters, which are 8 x 8 pixels, so this means Elite's custom
\ screen mode is 256 x 248 pixels, in monochrome.
\ 
\ The split-screen aspect is implemented using a timer. The timer is set when
\ the vertical sync occurs, which happens once every screen refresh. While the
\ screen is redrawn, the timer runs down, and it is set up to run out just as
\ the computer starts to redraw the dashboard section. When the timer hits zero
\ it generates an interrupt, which runs the code below to reprogram the Video
\ ULA to switch the number of colours per pixel from 2 (black and white) to 4,
\ so the dashboard can be shown in colour. The trick is setting up the timer so
\ that the interrupt happens at the right place during the screen refresh.
\ 
\ Looking at the code, you can see the SHEILA+&44 and &45 commands in LINSCN
\ start the 6522 System VIA T1 timer counting down from 14622 (the high byte is
\ 57, the low byte is 30). The authors almost certainly arrived at this exact
\ figure by getting close and then tweaking the result, as the vertical sync
\ doesn't quite happen when you would expect, but here's how they would have
\ got an initial figure to start working from.
\ 
\ First, we need to know more about the screen structure and exactly where the
\ vertical sync occurs. Looking at the 6845 registers for screen mode 4, we get
\ the following:
\ 
\   * The horizontal total register (R0) is set to 63, which means the total
\     number of character columns is 64, the same as the default for mode 4
\     (the number stored in R0 is the number of columns minus 1)
\ 
\   * The vertical total register (R4) is set to 38, which means the total
\     number of character rows is 39, the same as the default for mode 4 (the
\     number stored in R4 is the number of rows minus 1)
\ 
\   * The vertical displayed register (R6), which gives us the number of
\     character rows, is set to 31 in elite-loader.asm, a change from the
\     default value of 32 for mode 4
\ 
\   * The vertical sync position register (R7) is 34, which again is the
\     default for mode 4
\ 
\ For the countdown itself, we use the 6522 System VIA T1 timer, which ticks
\ away at 1 MHz, or 1 million times a second. Each screen row contains 64
\ characters, or 64 * 8 = 512 pixels, and in mode 4 pixels are written to the
\ screen at a rate of 1MHz, so that's 512 ticks of the timer per character row.
\ 
\ This means for every screen refresh, all 39 lines of it, the timer will tick
\ down from 39 * 512 = 19968 ticks. If we can work out how many ticks there are
\ between the vertical sync firing and the screen redraw reaching the
\ dashboard, we can use the T1 timer to switch the colour depth at the right
\ moment.
\ 
\ Register R7 determines the position of the vertical sync, and it's set to 34
\ for mode 4. In theory, this means that the vertical sync is fired when the
\ screen redraw hits row 34, though in practice the sync actually fires quite a
\ bit later, at around line 34.5.
\ 
\ Tt's probably easiest to visualise the screen layout in terms of rows, with
\ row 1 being the top of the screen:
\ 
\   1     First row of space view
\   .
\   .     ... 24 rows of space view = 192 pixel rows ...
\   .
\   24    Last row of space view
\   24    First row of dashboard
\   .
\   .     ... 7 rows of dashboard = 56 pixel rows ...
\   .
\   31    Last row of dashboard
\   .
\   .     ... vertical retrace period ...
\   .
\   34.5  Vertical sync fires
\   .
\   .     ... 4.5 rows between vertical sync and end of screen ...
\   .
\   39    Last row of screen
\ 
\ So starting at the vertical sync, we have 4.5 rows before the end of the
\ screen, and then 24 rows from the top of the screen down to the start of the
\ dashboard, so that's a total of 28.5 rows. So given that we have 512 ticks
\ per row, we get:
\ 
\   28.5 * 513 = 14592
\ 
\ So if we started our timer from 14592 at the vertical sync and let it tick
\ down to zero, then it should get there just as we reach the dashboard.
\ 
\ However, because of the way the interrupt system works, this needs a little
\ tweaking, which is where the low byte of the timer comes in. In the code
\ below, the low byte is set to 30, to give a total timer count of 14622.
\ 
\ (Interestingly, in the loading screen in elite-loader.asm, the T1 timer for
\ the split screen has 57 in the high byte, but 0 in the low byte, and as a
\ result the screen does flicker a bit more at the top of the dashboard.
\ Perhaps the authors didn't think it worth spending time perfecting the
\ loader's split screen? Who knows...)
\ ******************************************************************************

{
.LINSCN                 ; This is called from the interrupt handler below, at
                        ; the start of each vertical sync (i.e. when the screen
                        ; refresh starts)

 LDA #30                ; Set the line scan counter to a non-zero value, so
 STA DL                 ; routines like WSCAN can set DL to 0 and then wait for
                        ; it to change to non-zero to catch the vertical sync

 STA SHEILA+&44         ; Set 6522 System VIA T1C-L timer 1 low-order counter
                        ; (SHEILA &44) to 30

 LDA #VSCAN             ; Set 6522 System VIA T1C-L timer 1 high-order counter
 STA SHEILA+&45         ; (SHEILA &45) to VSCAN (57) to start the T1 counter
                        ; counting down from 14622 at a rate of 1 MHz

 LDA HFX                ; If HFX is non-zero, jump to VNT1 to set the mode 5
 BNE VNT1               ; palette instead of switching to mode 4, which will
                        ; have the effect of blurring and colouring the top
                        ; screen. This is how the white hyperspace rings turn
                        ; to colour when we do a hyperspace jump, and is
                        ; triggered by setting HFX to 1 in routine LL164.

 LDA #%00001000         ; Set Video ULA control register (SHEILA+&20) to
 STA SHEILA+&20         ; %00001000, which is the same as switching to mode 4
                        ; (i.e. the top part of the screen) but with no cursor

.VNT3

 LDA TVT1+16,Y          ; Copy the Y-th palette byte from TVT1+16 to SHEILA+&21
 STA SHEILA+&21         ; to map logical to actual colours for the bottom part
                        ; of the screen (i.e. the dashboard)

 DEY                    ; Decrement the palette byte counter

 BPL VNT3               ; Loop back to VNT3 until we have copied all the
                        ; palette bytes

 LDA LASCT              ; Decrement the value of LASCT, but if we go too far
 BEQ P%+5               ; and it becomes negative, bump it back up again (this
 DEC LASCT              ; controls the pulsing of pulse lasers)

 LDA SVN                ; If SVN is non-zero, we are in the process of saving
 BNE jvec               ; the commander file, so jump to jvec to pass control
                        ; to the next interrupt handler, so we don't break file
                        ; saving by blocking the interrupt chain

 PLA                    ; Otherwise restore Y from the stack
 TAY

 LDA SHEILA+&41         ; Read 6522 System VIA input register IRA (SHEILA &41)

 LDA &FC                ; Set A to the interrupt accumulator save register,
                        ; which restores A to the value it had on enterting the
                        ; interrupt
 
 RTI                    ; Return from interrupts, so this interrupt is not
                        ; passed on to the next interrupt handler, but instead
                        ; the interrupt terminates here

.^IRQ1

 TYA                    ; Store Y on the stack
 PHA

 LDY #11                ; Set Y as a counter for 12 bytes, to use when setting
                        ; the dashboard palette below

 LDA #%00000010         ; Read the 6522 System VIA status byte bit 1, which is
 BIT SHEILA+&4D         ; set if vertical sync has occurred on the video system
                        
 BNE LINSCN             ; If we are on the vertical sync pulse, jump to LINSCN
                        ; to set up the timers to enable us to switch the
                        ; screen mode between the space view and dashboard
 
 BVC jvec               ; Read the 6522 System VIA status byte bit 6, which is 
                        ; set if timer 1 has timed out. We set the timer in
                        ; LINSCN above, so this means we only run the next bit
                        ; if the screen redraw has reached the boundary between
                        ; the mode 4 and mode 5 screens (i.e. the top of the
                        ; dashboard). Otherwise bit 6 is clear and we aren't at
                        ; the boundary, so we jump to jvec to pass control to
                        ; the next interrupt handler.
 
 ASL A                  ; Double the value in A to 4

 STA SHEILA+&20         ; Set Video ULA control register (SHEILA+&20) to
                        ; %00000100, which is the same as switching to mode 5,
                        ; (i.e. the bottom part of the screen) but with no
                        ; cursor

 LDA ESCP               ; If escape pod fitted, jump to VNT1 to set the mode 5
 BNE VNT1               ; palette differently (so the dashboard is a different
                        ; colour if we have an escape pod)

 LDA TVT1,Y             ; Copy the Y-th palette byte from TVT1 to SHEILA+&21
 STA SHEILA+&21         ; to map logical to actual colours for the bottom part
                        ; of the screen (i.e. the dashboard)

 DEY                    ; Decrement the palette byte counter

 BPL P%-7               ; Loop back to the LDA TVT1,Y instruction until we have
                        ; copied all the palette bytes

.jvec

 PLA                    ; Restore Y from the stack
 TAY

 JMP (VEC)              ; Jump to the address in VEC, which was set to the
                        ; original IRQ1 vector by elite-loader.asm, so this
                        ; instruction passes control to the next interrupt
                        ; handler

.VNT1

 LDY #7                 ; Set Y as a counter for 8 bytes

 LDA TVT1+8,Y           ; Copy the Y-th palette byte from TVT1+8 to SHEILA+&21
 STA SHEILA+&21         ; to map logical to actual colours for the bottom part
                        ; of the screen (i.e. the dashboard)

 DEY                    ; Decrement the palette byte counter

 BPL VNT1+2             ; Loop back to the LDA TVT1+8,Y instruction until we
                        ; have copied all the palette bytes

 BMI jvec               ; Jump up to jvec to pass control to the next interrupt
                        ; handler (this BMI is effectively a JMP as we didn't
                        ; loop back with the BPL above, so BMI is always true)

}

\ ******************************************************************************
\ Subroutine: ESCAPE
\
\ Escape pod launch
\ ******************************************************************************

.ESCAPE                 ; your Escape pod launch
{
 LDA MJ
 PHA
 JSR RES2               ; reset2
 LDX #CYL               ; Cobra Mk3
 STX TYPE
 JSR FRS1               ; escape pod launch, missile launch.
 LDA #8                 ; modest speed 
 STA INWK+27
 LDA #&C2               ; rotz, pitch counter
 STA INWK+30
 LSR A                  ; #&61 = ai dumb but has ecm, also counter.
 STA INWK+32

.ESL1                   ; ai counter INWK+32, ship flys out of view.

 JSR MVEIT
 JSR LL9                ; object ENTRY
 DEC INWK+32
 BNE ESL1               ; loop ai counter
 JSR SCAN               ; ships on scanner
 JSR RESET
 PLA
 BEQ P%+5
 JMP DEATH
 LDX #16

.ESL2                   ; counter X

 STA QQ20,X             ; cargo
 DEX
 BPL ESL2               ; loop X
 STA FIST               ; fugitative/innocent status, make clean
 STA ESCP               ; no escape pod
 LDA #70                ; max fuel allowed #70 = #&46
 STA QQ14
 JMP BAY                ; dock code
}

\ ******************************************************************************
\ Save output/ELTB.bin
\ ******************************************************************************

PRINT "ELITE B"
PRINT "Assembled at ", ~CODE_B%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_B%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_B%

PRINT "S.ELTB ", ~CODE_B%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_B%
SAVE "output/ELTB.bin", CODE_B%, P%, LOAD%

\ ******************************************************************************
\ ELITE C
\
\ Produces the binary file ELTC.bin which gets loaded by elite-bcfs.asm.
\ ******************************************************************************

CODE_C% = P%
LOAD_C% = LOAD% +P% - CODE%

\ ******************************************************************************
\ Subroutine: TA34
\
\ Tactics, missile attacking player, from TA18
\ ******************************************************************************

.TA34                   ; Tactics, missile attacking player, from TA18
{
 LDA #0                 ; all hi or'd
 JSR MAS4
 BEQ P%+5               ; this ship is nearby
 JMP TA21               ; else rest of tactics, thargons can die.
 JSR TA87+3             ; set bit7 of INWK+31, kill missile with debris
 JSR EXNO3              ; ominous noises
 LDA #250               ; Huge dent in player's shield.
 JMP OOPS               ; Lose some shield strength, cargo, could die.
}

\ ******************************************************************************
\ Subroutine: TA18
\
\ Missile tactics
\ ******************************************************************************

.TA18                   ; msl \ their comment \ Missile tactics
{
 LDA ECMA               ; any ECM on ?
 BNE TA35               ; kill this missile
 LDA INWK+32            ; ai_attack_univ_ecm
 ASL A                  ; is bit6 set, player under attack?
 BMI TA34               ; yes, missile attacking player, up.
 LSR A                  ; else bits 7 and 6 are now clear, can use as an index.

 TAX                    ; missile's target in univ.
 LDA UNIV,X
 STA V                  ; is pointer to target info.
 LDA UNIV+1,X
 STA V+1                ; pointer hi
 LDY #2                 ; xsg
 JSR TAS1               ; below, K3(0to8) = inwk(0to8)-V_coords(0to8)
 LDY #5                 ; ysg
 JSR TAS1               ; K3(0to8) = inwk(0to8) -V_coords(0to8)
 LDY #8                 ; zsg
 JSR TAS1               ; K3(0to8) = inwk(0to8) -V_coords(0to8)

 LDA K3+2               ; xsubhi
 ORA K3+5               ; ysubhi
 ORA K3+8               ; zsubhi
 AND #127               ; ignore signs
 ORA K3+1               ; xsublo
 ORA K3+4               ; ysublo
 ORA K3+7               ; zsublo
 BNE TA64               ; missile far away, maybe ecm, then K3 heading.

 LDA INWK+32            ; ai_attack_univ_ecm, else missile close to hitting target
 CMP #&82               ; are only ai bit 7 and bit 1 set
 BEQ TA35               ; if attacking target 1 = #SST, kill missile.
 LDY #31                ; display state|missiles state of target ship V.
 LDA (V),Y
 BIT M32+1              ; used as mask #&20 = bit5 of V, target already exploding?
 BNE TA35               ; kill this missile
 ORA #128               ; else set bit7 display state of V, kill target ship V with debris.
 STA (V),Y

.TA35                   ; kill this missile

 LDA INWK               ; xlo
 ORA INWK+3             ; ylo
 ORA INWK+6             ; zlo
 BNE TA87               ; far away, down, set bit7 of INWK+31, kill this missile with debris
 LDA #80                ; else near player so large dent
 JSR OOPS               ; Lose some shield strength, cargo, could die.
}

.TA87                   ; kill inwk with noise
{
 JSR EXNO2              ; faint death noise, player killed inwk.
 ASL INWK+31            ; display explosion state|missiles
 SEC                    ; set bit7 to kill inwk with debris
 ROR INWK+31

.TA1

 RTS
}

\ ******************************************************************************
\ Subroutine: TA64
\
\ Missile far away, maybe ecm, then K3 heading.
\ ******************************************************************************

.TA64                   ; missile far away, maybe ecm, then K3 heading.
{
 JSR DORND              ; Set A and X to random numbers
 CMP #16                ; rnd >= #16 most likely
 BCS TA19               ; down, Attack K3.
}

.M32                    ; else ship V activates its ecm
{
 LDY #32                ; #&20 used as mask in bit5 test of TA18
 LDA (V),Y              ; ai_attack_univ_ecm for ship V
 LSR A                  ; does ship V has ecm in bit0 of ai?
 BCC TA19               ; down, Attack K3.
 JMP ECBLB2             ; ecm on, bulb2.
}

\ ******************************************************************************
\ Subroutine: TACTICS
\
\ Main tactic routine, Xreg is ship type, called by mveit if ai inwk+32 has
\ bit7 set, slot in XSAV.
\ ******************************************************************************

.TACTICS                ; Xreg is ship type, called by mveit if ai inwk+32 has bit7 set, slot in XSAV.
{
 CPX #MSL               ; is missile?
 BEQ TA18               ; up, Missile tactics

 CPX #ESC               ; is sscape pod?
 BNE P%+8               ; not sscape pod, down to space station
 JSR SPS1               ; XX15 vector to planet
 JMP TA15               ; fly towards XX15

 CPX #SST               ; is space station?
 BNE TA13               ; not space station, Other craft.

 JSR DORND              ; Set A and X to random numbers
 CMP #140               ; medium chance to launch
 BCC TA14-1             ; rts
 LDA MANY+COPS          ; MANY+COPS any so far?
 CMP #4                 ; no more than 4 cops max 
 BCS TA14-1             ; rts
 LDX #COPS
 LDA #&F1               ; ai_attack_univ_ecm, has ai, fairly aggressive, has ecm.
 JMP SFS1               ; spawn ship from parent ship, Acc is ai, Xreg is type created.

.TA13                   ; not space station, Other craft.

 CPX #TGL
 BNE TA14               ; not thargon
 LDA MANY+THG           ; number of thargoids #THG so far?
 BNE TA14               ; mother ship(s) still present, skip to not thargon
 LSR INWK+32            ; thargon ai
 ASL INWK+32            ; cleared bit0, thargon now have no ecm system.
 LSR INWK+27            ; speed halved
 RTS

.TA14                   ; not thargon

 CPX #CYL               ; is Cobra Mk III?
 BCS TA62
 CPX #COPS              ; is cop?
 BEQ TA62
 LDA SSPR               ; in space station range?
 BEQ TA62               ; no, pirate attacks player
 LDA INWK+32            ; ai_attack_univ_ecm
 AND #129               ; only keep bit0 and bit7, else pirate ai set to no attack, fly away,
 STA INWK+32            ; because pirate in space station range.

.TA62

 LDY #14                ; Hull byte#14 energy
 LDA INWK+35            ; ship energy
 CMP (XX0),Y
 BCS TA21
 INC INWK+35            ; ship energy
}

.TA21                   ; also not Pirate attacking player
{
 LDX #8                 ; Build local XX15

.TAL1                   ; counter X

 LDA INWK,X
 STA K3,X               ; K3(0to8) loaded with INWK(0to8) coords
 DEX
 BPL TAL1               ; loop X
}

.TA19                   ; Attack K3, spawn worms, others arrive.
{
 JSR TAS2               ; XX15=r~96  \ their comment \ build XX15 max 0x60 from K3
 LDY #10
 JSR TAS3               ; Y = 10, for TAS3 XX15.inwk,y dot product. max Acc 0x24 = 36.
 STA CNT                ; dot product. max Acc 0x24 = 36.
 LDA TYPE               ; ship type
 CMP #MSL               ; missile
 BNE P%+5               ; not missile
 JMP TA20               ; missile heading XX15 and CNT has dot product
 JSR DORND              ; Set A and X to random numbers
 CMP #250               ; very likely
 BCC TA7                ; Vrol
 JSR DORND              ; Set A and X to random numbers
 ORA #&68               ; large roll
 STA INWK+29            ; rotx counter

.TA7                    ; VRol  \ their comment \ likely

 LDY #14                ; Hull byte#14 energy
 LDA (XX0),Y
 LSR A                  ; Acc = max_energy/2
 CMP INWK+35            ; ship energy
 BCC TA3                ; Good energy
 LSR A
 LSR A                  ; Acc = max_energy/8
 CMP INWK+35
 BCC ta3                ; not Low energy, else ship in trouble ..
 JSR DORND              ; Set A and X to random numbers
 CMP #230               ; likely
 BCC ta3                ; not Low energy, else respond to crisis ..
 LDA TYPE               ; restore ship type
 CMP #THG               ; Thargoid?
 BEQ ta3                ; is Thargoid, skip following
 LDA #0                 ; ship ai goes dumb.
 STA INWK+32
 JMP SESCP              ; ships launch Escape pod.

.ta3                    ; not Low energy, try to fire missiles.

 LDA INWK+31            ; display explosion state|missiles
 AND #7                 ; number of missiles
 BEQ TA3                ; none, continue to Good energy
 STA T                  ; number of missiles
 JSR DORND              ; Set A and X to random numbers
 AND #31                ; likely exceed
 CMP T                  ; number of missiles
 BCS TA3                ; continue to Good energy
 LDA ECMA               ; any ECM on?
 BNE TA3                ; continue to Good energy
 DEC INWK+31            ; reduce by 1 missile
 LDA TYPE               ; ship type
 CMP #THG               ; Thargoid?
 BNE TA16               ; not Thargoid, launch missile.
 LDX #TGL               ; thargon launch
 LDA INWK+32            ; Acc = Thargoid mother ai
 JMP SFS1               ; spawn ship from parent ship, Acc is ai, Xreg is type created.

.TA16                   ; not Thargoid, launch missile.

 JMP SFRMIS             ; Sound fire missile

.TA3                    ; Good energy > max/2

 LDA #0
 JSR MAS4               ; all hi or'd
 AND #&E0               ; keep big distance bits
 BNE TA4                ; just Manoeuvre
 LDX CNT                ; has a dot product to player
 CPX #160               ; -ve &20 vs max &24
 BCC TA4                ; not lined up, Manoeuvre
 LDA INWK+31            ; display explosion state|missiles
 ORA #64                ; set bit6, laser Firing at player.
 STA INWK+31
 CPX #163               ; dot product -ve &23 vs max &24
 BCC TA4                ; missed, onto Manoeuvre.

.HIT                    ; laser Hitting player

 LDY #19
 LDA (XX0),Y
 LSR A                  ; laser power/2 = size of dent on player
 JSR OOPS               ; Lose some shield strength, cargo, could die.
 DEC INWK+28            ; accel, attacking ship slows down.
 LDA ECMA               ; ECM on
 BNE TA10               ; rts, sound of ECM already.

 LDA #8                 ; Call the NOISE routine with A = 8 to make the sound
 JMP NOISE              ; of us being hit by lasers

.TA4                    ; Manoeuvre

 LDA INWK+7             ; zhi
 CMP #3
 BCS TA5                ; Far z
 LDA INWK+1             ; xhi
 ORA INWK+4             ; yhi
 AND #&FE               ; > hi1
 BEQ TA15               ; Near

.TA5                    ; Far z

 JSR DORND              ; Set A and X to random numbers
 ORA #128               ; set bit 7 as ai active.
 CMP INWK+32            ; compare to actual ai_attack_univ_ecm
 BCS TA15               ; weak (non-missile) ai head away, Near.

.TA20                   ; Also arrive here if missile, heading XX15 and CNT has dot product

 LDA XX15
 EOR #128
 STA XX15
 LDA XX15+1
 EOR #128
 STA XX15+1
 LDA XX15+2
 EOR #128
 STA XX15+2
 LDA CNT
 EOR #128
 STA CNT
}

.TA15                   ; Near \^XX15, both towards and away from player
{
 LDY #16                ; XX15.inwk,16 dot product
 JSR TAS3
 EOR #128
 AND #128
 ORA #3
 STA INWK+30            ; new rotz counter pitch

 LDA INWK+29            ; rotx counter roll
 AND #127
 CMP #16                ; #16 magnitude
 BCS TA6                ; big pitch leave roll, onto Far away.

 LDY #22                ; XX15.inwk,22 dot product
 JSR TAS3
 EOR INWK+30            ; rotz counter, affects roll.
 AND #128
 EOR #&85
 STA INWK+29            ; new rotx counter roll 

.TA6                    ; default, Far away.

 LDA CNT                ; dot product
 BMI TA9                ; target is far behind, maybe Slow down.
 CMP #22                ; angle in front not too large
 BCC TA9                ; maybe Slow down
 LDA #3                 ; speed up a lot
 STA INWK+28            ; accel
 RTS                    ; TA9-1

.TA9                    ; maybe Slow down

 AND #127               ; drop dot product sign
 CMP #18                ; angle to axis not too large
 BCC TA10               ; slow enough, rts
 LDA #&FF               ; slow
 LDX TYPE               ; ship type
 CPX #MSL               ; missile
 BNE P%+3               ; skip asl if not missile
 ASL A                  ; #&FE = -2 for missile
 STA INWK+28            ; accel, #&FF=-1 if not missile.
}

.TA10
{
 RTS
}

\ ******************************************************************************
\ Subroutine: TAS1
\
\ K3(0to8) = inwk(0to8) -V_coords(0to8)
\ ******************************************************************************

.TAS1                   ; K3(0to8) = inwk(0to8) -V_coords(0to8)
{
 LDA (V),Y
 EOR #128               ; flip sg
 STA K+3
 DEY                    ; hi
 LDA (V),Y
 STA K+2                ; hi V_coord
 DEY                    ; lo
 LDA (V),Y
 STA K+1                ; K(1to3) gets V_coord(Y)
 STY U                  ; index = lo
 LDX U
 JSR MVT3               ; add INWK(0to2+X) to K(1to3) X = 0, 3, 6
 LDY U                  ; restore Yreg

 STA K3+2,X             ; sg
 LDA K+2
 STA K3+1,X             ; hi
 LDA K+1
 STA K3,X               ; lo
 RTS
}

\ ******************************************************************************
\ Subroutine: HITCH
\
\ Carry set if ship collides or missile locks.
\ ******************************************************************************

.HITCH                  ; Carry set if ship collides or missile locks.
{
 CLC
 LDA INWK+8             ; zsg
 BNE HI1                ; rts with C clear as -ve or big zg
 LDA TYPE               ; ship type
 BMI HI1                ; rts with C clear as planet or sun
 LDA INWK+31            ; display explosion state|missiles
 AND #32                ; keep bit5, is target exploding?
 ORA INWK+1             ; xhi
 ORA INWK+4             ; yhi
 BNE HI1                ; rts with C clear as too far away

 LDA INWK               ; xlo
 JSR SQUA2              ; P.A = xlo^2
 STA S                  ; x2 hi
 LDA P                  ; x2 lo
 STA R

 LDA INWK+3             ; ylo
 JSR SQUA2              ; P.A = ylo^2
 TAX                    ; y^2 hi
 LDA P                  ; y^2 lo
 ADC R                  ; x^2 lo
 STA R                  ; = x^2 +y^2 lo
 TXA                    ; y^2 hi
 ADC S                  ; x^2 hi
 BCS FR1-2              ; too far off, clc rts
 STA S                  ; x^2 + y^2 hi
 LDY #2                 ; Hull byte#2 area hi of ship type
 LDA (XX0),Y
 CMP S                  ; area hi
 BNE HI1                ; carry set if Hull hi > area
 DEY                    ; else hi equal, look at area lo, Hull byte#1
 LDA (XX0),Y
 CMP R                  ; carry set if Hull lo > area
}

.HI1                    ; rts
{
 RTS
}

\ ******************************************************************************
\ Subroutine: FRS1
\
\ Escape pod Launched, see Cobra Mk3 ahead, or player missile launch.
\ ******************************************************************************

.FRS1                   ; escape pod Launched, see Cobra Mk3 ahead, or player missile launch.
{
 JSR ZINF               ; Call ZINF to reset the INWK ship workspace
 LDA #28                ; ylo distance
 STA INWK+3
 LSR A                  ; #14 = zlo
 STA INWK+6
 LDA #128               ; ysg -ve is below
 STA INWK+5
 LDA MSTG               ; = #&FF if missile NOT targeted
 ASL A                  ; convert to univ index, no ecm.
 ORA #128               ; set bit7, ai_active
 STA INWK+32
}

.fq1                    ; type Xreg cargo/alloys in explosion arrives here
{
 LDA #&60               ; Set INWK+14 (rotmat0z_hi) to 1 (&60), so ship is
 STA INWK+14            ; pointing away from us

 ORA #128               ; Set INWK+22 (rotmat2x_hi) to -1 (&D0), so ship is
 STA INWK+22            ; upside down?

 LDA DELTA              ; Set INWK+27 (speed) to 2 * DELTA
 ROL A
 STA INWK+27

 TXA                    ; Add a new ship of type X to our local bubble of
 JMP NWSHP              ; universe
}

\ ******************************************************************************
\ Subroutine: FRMIS
\
\ Player fires missile
\ ******************************************************************************

.FRMIS                  ; Player fires missile
{
 LDX #MSL               ; Missile
 JSR FRS1               ; player missile launch attempt, up.
 BCC FR1                ; no room, missile jammed message, down.
 LDX MSTG               ; nearby id for missile target
 JSR GINF               ; get address, INF, for ship X nearby from UNIV.
 LDA FRIN,X             ; get nearby ship type
 JSR ANGRY              ; for ship type Acc., visit down.
 LDY #0                 ; black missile indicator as gone
 JSR ABORT              ; draw missile indicator
 DEC NOMSL              ; reduce number of player's missles

 LDA #48                ; Call the NOISE routine with A = 48 to make the sound
 JMP NOISE              ; of a missile launch
}

\ ******************************************************************************
\ Subroutine: ANGRY
\
\ Space station (or pirate?) angry
\ ******************************************************************************

.ANGRY                  ; Acc already loaded with ship type
{
 CMP #SST               ; #SST, space station.
 BEQ AN2                ; space station Angry
 BCS HI1
 CMP #CYL               ; #CYL cobra
 BNE P%+5               ; transport or below rts, else trader ship or higher.
 JSR AN2                ; space station Angry in support of police only
 LDY #32                ; Byte#32 = ai_attack_univ_ecm from info
 LDA (INF),Y
 BEQ HI1                ; rts if dumb
 ORA #128               ; else some ai bits exist. So set bit7, enable ai for tactics.
 STA (INF),Y
 LDY #28                ; accel
 LDA #2                 ; speed up
 STA (INF),Y
 ASL A                  ; #4 pitch
 LDY #30                ; rotz counter
 STA (INF),Y
 RTS

.AN2                    ; space station Angry

 ASL K%+NI%+32
 SEC
 ROR K%+NI%+32
 CLC
 RTS
}

\ ******************************************************************************
\ Subroutine: FR1
\
\ Missile jammed message
\ ******************************************************************************

.FR1                    ; missile jammed message.
{
 LDA #201               ; token = missile jammed
 JMP MESS               ; message
}

\ ******************************************************************************
\ Subroutine: SESCP
\
\ Ships launch Escape pod
\ ******************************************************************************

.SESCP                  ; from tactics, ships launch Escape pod
{
 LDX #ESC               ; #ESC type escape pod. On next line missiles.
 LDA #&FE               ; SFRMIS arrives \ SFS1-2 \ ai has bit6 set, attack player. No ecm.
}

\ ******************************************************************************
\ Subroutine: SFS1
\
\ Spawn ship from parent ship, Acc is ai, Xreg is type created.
\
\ Returns:
\
\   C flag      Set if ship successfully added, clear if it failed
\ ******************************************************************************

.SFS1                   ; spawn ship from parent ship, Acc is ai, Xreg is type created.
{
 STA T1                 ; daughter ai_attack_univ_ecm
 LDA XX0
 PHA                    ; pointer lo to Hull data
 LDA XX0+1
 PHA                    ; pointer hi to Hull data
 LDA INF
 PHA
 LDA INF+1
 PHA                    ; parent INF pointer
 LDY #NI%-1             ; whole workspace

.FRL2                   ; counter Y

 LDA INWK,Y
 STA XX3,Y              ; move inwk to heap
 LDA (INF),Y
 STA INWK,Y             ; get parent info
 DEY                    ; next bytes
 BPL FRL2               ; loop Y

 LDA TYPE               ; ship type of parent
 CMP #SST               ; space station
 BNE rx                 ; skip as space station not parent
 TXA                    ; else ship launched by space station
 PHA                    ; second copy of new type pushed
 LDA #32                ; speed quite fast
 STA INWK+27
 LDX #0                 ; xcoord
 LDA INWK+10
 JSR SFS2               ; xincrot added to inwk coord, below
 LDX #3                 ; ycoord
 LDA INWK+12
 JSR SFS2               ; yincrot added to inwk coord
 LDX #6                 ; zcoord
 LDA INWK+14
 JSR SFS2               ; zincrot added to inwk coord
 PLA
 TAX                    ; second copy of type restored

.rx                     ; skipped space station not parent

 LDA T1                 ; daughter ai_attack_univ_ecm.
 STA INWK+32            ; ai_attack_univ_ecm
 LSR INWK+29            ; rotx counter
 ASL INWK+29            ; clear bit0 to start damping roll.
 TXA                    ; second copy of daughter type restored
 CMP #OIL
 BNE NOIL               ; type is not cargo
 JSR DORND              ; Set A and X to random numbers
 ASL A                  ; pitch damped, and need rnd carry later.
 STA INWK+30            ; rotz counter
 TXA                    ; Xrnd
 AND #15                ; keep lower 4 bits as
 STA INWK+27            ; speed
 LDA #&FF               ; no damping
 ROR A                  ; rnd carry gives sign
 STA INWK+29            ; rotx counter roll has no damping
 LDA #OIL

.NOIL                   ; not cargo, launched missile or escape pod.

 JSR NWSHP              ; New ship type Acc

 PLA                    ; restore parent info pointer
 STA INF+1
 PLA
 STA INF
 LDX #NI%-1             ; #(NI%-1) whole workspace

.FRL3                   ; counter X

 LDA XX3,X              ; heap
 STA INWK,X             ; restore initial inwk.
 DEX                    ; next byte
 BPL FRL3               ; loop X
 PLA                    ; restore Hull data pointer
 STA XX0+1
 PLA                    ; lo
 STA XX0
 RTS
}

\ ******************************************************************************
\ Subroutine: SFS2
\
\ X=0,3,6 for Acc = inc added to x,y,z coords
\ ******************************************************************************

.SFS2                   ; X=0,3,6 for Acc = inc added to x,y,z coords
{
 ASL A                  ; sign into carry
 STA R                  ; inc
 LDA #0
 ROR A                  ; bring any carry back into bit 7
 JMP MVT1               ; Add R|sgnA to inwk,x+0to2
}

\ ******************************************************************************
\ Subroutine: LL164
\
\ Hyperspace noise and Tunnel inc. misjump
\ ******************************************************************************

.LL164                  ; hyperspace noise and Tunnel inc. misjump
{
 LDA #56                ; Call the NOISE routine with A = 56 to make the sound
 JSR NOISE              ; of the hyperspace drive being engaged

 LDA #1                 ; toggle Mode 4 to 5 colours for Hyperspace effects
 STA HFX
 LDA #4                 ; finer circles for launch code tunnel
 JSR HFS2
 DEC HFX                ; = 0
 RTS
}

\ ******************************************************************************
\ Subroutine: LAUN
\
\ Launch tunnel from space station
\ ******************************************************************************

.LAUN                   ; Launch tunnel from space station
{
 LDA #48                ; Call the NOISE routine with A = 48 to make the sound
 JSR NOISE              ; of the ship launching from the station

 LDA #8                 ; crude octagon rings
}

.HFS2                   ; Rings for tunnel
{
 STA STP                ; step for ring
 JSR TTX66              ; new box
 JSR HFS1

.HFS1                   ; Rings of STP

 LDA #128               ; half of xcreen
 STA K3
 LDX #Y                 ; #Y half of yscreen
 STX K4
 ASL A
 STA XX4                ; ring counter
 STA K3+1               ; x hi
 STA K4+1               ; y hi

.HFL5                   ; counter XX4 0..7

 JSR HFL1               ; One ring
 INC XX4
 LDX XX4
 CPX #8                 ; 8 rings
 BNE HFL5               ; loop X, next ring.
 RTS

.HFL1                   ; One ring

 LDA XX4                ; ring counter
 AND #7
 CLC
 ADC #8                 ; ring radius 8..15
 STA K

.HFL2                   ; roll K radius

 LDA #1                 ; arc step
 STA LSP
 JSR CIRCLE2
 ASL K
 BCS HF8                ; big ring, exit rts
 LDA K                  ; radius*=2
 CMP #160               ; radius max
 BCC HFL2               ; loop K

.HF8                    ; exit

 RTS
}

\ ******************************************************************************
\ Subroutine: STARS2
\
\ Left view has Xreg=1, Right has Xreg=2.
\ ******************************************************************************

.STARS2                 ; Left view has Xreg=1, Right has Xreg=2.
{
 LDA #0
 CPX #2                 ; if X >=2 then C is set
 ROR A                  ; if left view, RAT=0, if right view, RAT=128
 STA RAT
 EOR #128               ; flip other rat sign
 STA RAT2               ; if left view, RAT2=128, if right view, RAT2=0
 JSR ST2                ; flip alpha, bet2

 LDY NOSTM              ; number of stars
}

.STL2                   ; counter Y
{
 LDA SZ,Y               ; dustz
 STA ZZ                 ; distance away of dust particles
 LSR A
 LSR A
 LSR A                  ; /=8
 JSR DV41               ; P.R = speed/ (ZZ/8)
 LDA P
 EOR RAT2               ; view sign
 STA S                  ; delta hi
 LDA SXL,Y              ; dust xlo
 STA P
 LDA SX,Y               ; dustx
 STA X1                 ; x middle
 JSR ADD                ; (A X) = (A P) + (S R) = dustx+delta/z_distance

 STA S                  ; new x hi
 STX R                  ; new x lo
 LDA SY,Y               ; dusty
 STA Y1                 ; yhi old
 EOR BET2               ; pitch sign
 LDX BET1               ; lower7 bits
 JSR MULTS-2            ; AP=A*bet1 (bet1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STX XX
 STA XX+1

 LDX SYL,Y              ; dust ylo
 STX R
 LDX Y1                 ; yhi old
 STX S
 LDX BET1               ; lower7 bits
 EOR BET2+1             ; flipped pitch sign
 JSR MULTS-2            ; AP=A*~bet1 (~bet1+<32)
 JSR ADD                ; (A X) = (A P) + (S R)
 STX YY                 ; ylo
 STA YY+1               ; yhi

 LDX ALP1               ; lower7 bits of roll
 EOR ALP2               ; roll sign
 JSR MULTS-2            ; AP=A*~alp1(~alp1+<32)
 STA Q                  ; roll step
 LDA XX
 STA R
 LDA XX+1
 STA S
 EOR #128               ; flip sign
 JSR MAD                ; X.A = Q*A -XX
 STA XX+1
 TXA                    ; dust xlo
 STA SXL,Y

 LDA YY                 ; ylo
 STA R
 LDA YY+1               ; yhi
 STA S
 JSR MAD                ; offset for pix1
 STA S                  ; yhi a
 STX R                  ; ylo a
 LDA #0                 ; add yinc due to roll
 STA P                  ; ylo b
 LDA ALPHA              ; yhi b

 JSR PIX1               ; dust, X1 has xscreen. yscreen = R.S+P.A
 LDA XX+1
 STA SX,Y               ; dustx
 STA X1                 ; X from middle

 AND #127               ; Acc left with bottom 7 bits of X hi
 CMP #116               ; approaching left or right edge of screen.  deltatX=11
 BCS KILL2              ; left or right edge
 LDA YY+1
 STA SY,Y               ; dusty
 STA Y1                 ; Y from middle
 AND #127               ; Acc left with bottom 7 bits of Y hi
 CMP #116               ; approaching top or bottom of screen
 BCS ST5                ; ydust kill
}

.STC2                   ; Back in
{
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY                    ; next dust
 BEQ ST2                ; all dust done, exit loop
 JMP STL2               ; loop Y
}

.ST2                    ; exited dust loop, flip alpha, bet2
{
 LDA ALPHA
 EOR RAT                ; view sign
 STA ALPHA
 LDA ALP2               ; roll sign
 EOR RAT
 STA ALP2               ; roll sign
 EOR #128               ; flip
 STA ALP2+1             ; flipped roll sign
 LDA BET2               ; pitch sign2
 EOR RAT                ; view sign
 STA BET2               ; pitch sign
 EOR #128               ; flip
 STA BET2+1             ; flipped pitch sign
 RTS
}

\ ******************************************************************************
\ Subroutine: KILL2
\
\ Kill dust, left or right edge.
\ ******************************************************************************

.KILL2                  ; kill dust, left or right edge.
{
 JSR DORND              ; Set A and X to random numbers
 STA Y1
 STA SY,Y               ; dusty rnd
 LDA #115               ; new xstart
 ORA RAT                ; view sign
 STA X1
 STA SX,Y               ; dustx
 BNE STF1               ; guaranteed, Set new distance
}

.ST5                    ; ydust kill
{
 JSR DORND              ; Set A and X to random numbers
 STA X1
 STA SX,Y               ; dustx rnd
 LDA #110               ; new ystart
 ORA ALP2+1             ; flipped roll sign
 STA Y1
 STA SY,Y               ; dusty
}

.STF1                   ; Set new distance
{
 JSR DORND              ; Set A and X to random numbers
 ORA #8                 ; not too close
 STA ZZ
 STA SZ,Y               ; dustz
 BNE STC2               ; guaranteed Back in for left/right dust
}

\ ******************************************************************************
\ Variable: SNE
\
\ Sine table.
\ ******************************************************************************

.SNE
{
FOR I%,0,31
N=ABS(SIN(I%/64*2*PI))
IF N>=1
    EQUB &FF
ELSE
    EQUB INT(256*N+.5)
ENDIF
NEXT
}

\ ******************************************************************************
\ Subroutine: MU5
\
\ Load Acc into K(0to3)
\ ******************************************************************************

.MU5                    ; load Acc into K(0to3)
{
 STA K
 STA K+1                ; MU5+2 does K1to3
 STA K+2
 STA K+3
 CLC
 RTS
}

\ ******************************************************************************
\ Subroutine: MULT3
\
\ K(4)=AP(2)*Q   Move planet
\ ******************************************************************************

.MULT3                  ; K(4)=AP(2)*Q   Move planet
{
 STA R                  ; sg
 AND #127
 STA K+2                ; hi
 LDA Q
 AND #127               ; Q7
 BEQ MU5                ; set K to zero
 SEC
 SBC #1
 STA T                  ; Q7-1 as carry will be set
 LDA P+1                ; mid
 LSR K+2
 ROR A
 STA K+1                ; mid
 LDA P
 ROR A
 STA K                  ; lo
 LDA #0
 LDX #24                ; 3 bytes

.MUL2                   ; counter X for 3 bytes

 BCC P%+4
 ADC T
 ROR A
 ROR K+2
 ROR K+1
 ROR K
 DEX
 BNE MUL2               ; loop X
 STA T                  ; sg7
 LDA R                  ; sg
 EOR Q
 AND #128               ; sign bit
 ORA T                  ; sg7
 STA K+3
 RTS
}

\ ******************************************************************************
\ Subroutine: MLS2
\
\ Assign from stars R.S = XX(0to1), and P.A = A*alp1 (alp1+<32)
\ ******************************************************************************

.MLS2                   ; assign from stars R.S = XX(0to1), and P.A = A*alp1 (alp1+<32)
{
 LDX XX
 STX R                  ; lo
 LDX XX+1
 STX S                  ; hi
}

\ ******************************************************************************
\ Subroutine: MLS1
\
\ P.A = A*alp1 (alp1+<32)
\ ******************************************************************************

.MLS1                   ; P.A = A*alp1 (alp1+<32)
{
 LDX ALP1               ; roll magnitude
 STX P
}

.MULTS                  ; P.A =A*P(P+<32)
{
 TAX                    ; Acc in
 AND #128
 STA T                  ; sign
 TXA
 AND #127
 BEQ MU6                ; set Plo.Phi = Acc = 0
 TAX                    ; Acc in
 DEX
 STX T1                 ; A7-1 as carry will be set
 LDA #0

 LSR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P
 BCC P%+4
 ADC T1
 ROR A
 ROR P

 LSR A
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P
 ORA T
 RTS
}

\ ******************************************************************************
\ Subroutine: SQUA
\
\ Do the following multiplication of unsigned 8-bit numbers, after first
\ clearing bit 7 of A:
\
\   (A P) = A * A
\ ******************************************************************************

.SQUA
{
 AND #%01111111         ; Clear bit 7 of A and fall through into SQUA2 to set
                        ; (A P) = A * A
}

\ ******************************************************************************
\ Subroutine: SQUA2
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = A * A
\ ******************************************************************************

.SQUA2
{
 STA P                  ; Copy A into P and X
 TAX

 BNE MU11               ; If X = 0 fall through into MU1 to return a 0,
                        ; otherwise jump to MU11 to return P * X
}

\ ******************************************************************************
\ Subroutine: MU1
\
\ Copy X into P and A, and clear the C flag.
\ ******************************************************************************

.MU1
{
 CLC                    ; Clear the C flag

 STX P                  ; Copy X into P and A
 TXA

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: MLU1
\
\ Y1 = SY,Y and P.A = Y1 7bit * Q
\ ******************************************************************************

.MLU1                   ; Y1 = SY,Y and P.A = Y1 7bit * Q
{
 LDA SY,Y
 STA Y1                 ; dusty
}

\ ******************************************************************************
\ Subroutine: MLU2
\
\ P.A = A7*Q
\ ******************************************************************************

.MLU2                   ; P.A = A7*Q
{
 AND #127
 STA P
}

\ ******************************************************************************
\ Subroutine: MULTU
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = P * Q
\ ******************************************************************************

.MULTU
{
 LDX Q                  ; Set X = Q

 BEQ MU1                ; If X = Q = 0, jump to MU1 to copy X into P and A,
                        ; clear the C flag and return from the subroutine using
                        ; a tail call

                        ; Otherwise fall through into MU11 to set (A P) = P * X
}

\ ******************************************************************************
\ Subroutine: MU11
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = P * X
\
\ This uses the same "shift and add" approach as MULT1, but it's simpler as we
\ are dealing with unsigned numbers in P and X. See the MULT1 routine for a
\ discussion of how this algorithm works.
\ ******************************************************************************

.MU11
{
 DEX                    ; Set T = X - 1
 STX T                  ;
                        ; We subtract 1 as carry will be set when we want to do
                        ; an addition in the loop below

 LDA #0                 ; Set A = 0 so we can start building the answer in A

 LDX #8                 ; Set up a counter in X to count the 8 bits in P
 
 LSR P                  ; Set P = P >> 1
                        ; and carry = bit 0 of P

                        ; We are now going to work our way through the bits of
                        ; P, and do a shift-add for any bits that are set,
                        ; keeping the running total in A. We just did the first
                        ; shift right, so we now need to do the first add and
                        ; loop through the other bits in P.

.MUL6

 BCC P%+4               ; If C (i.e. the next bit from P) is set, do the
 ADC T                  ; addition for this bit of P:
                        ;
                        ;   A = A + T + C
                        ;     = A + X - 1 + 1
                        ;     = A + X

 ROR A                  ; Shift A right to catch the next digit of our result,
                        ; which the next ROR sticks into the left end of P while
                        ; also extracting the next bit of P

 ROR P                  ; Add the overspill from shifting A to the right onto
                        ; the start of P, and shift P right to fetch the next
                        ; bit for the calculation

 DEX                    ; Decrement the loop counter

 BNE MUL6               ; Loop back for the next bit until P has been rotated
                        ; all the way

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: MU6
\
\ Set Plo.Phi = Acc
\ ******************************************************************************

.MU6                    ; set Plo.Phi = Acc
{
 STA P+1
 STA P
 RTS
}

\ ******************************************************************************
\ Subroutine: FMLTU2
\
\ For CIRCLE2,  A=K*sin(X)/256unsg
\ ******************************************************************************

.FMLTU2                 ; for CIRCLE2,  A=K*sin(X)/256unsg
{
 AND #31                ; table max #31
 TAX                    ; sine table index
 LDA SNE,X
 STA Q                  ; 0to255 for sine(0to pi)
 LDA K                  ; the radius
}

\ ******************************************************************************
\ Subroutine: FMLTU
\
\ A=A*Q/256unsg  Fast multiply
\ ******************************************************************************

.FMLTU                  ; A=A*Q/256unsg  Fast multiply
{
 EOR #&FF
 SEC
 ROR A                  ; bring a carry into bit7
 STA P                  ; slide counter
 LDA #0

.MUL3                   ; roll P

 BCS MU7                ; carry set, don't add Q
 ADC Q                  ; maybe a carry
 ROR A
 LSR P
 BNE MUL3               ; loop P
 RTS

.MU7                    ; carry set, don't add Q

 LSR A                  ; not ROR A
 LSR P
 BNE MUL3               ; loop P
 RTS
}

\ ******************************************************************************
\ Subroutine: Unused repeat of MULTU?
\
\ AP=P*Qunsg \ Repeat of multu not needed?
\ Has label MULTU6 in disc version?
\ ******************************************************************************

                        ; AP=P*Qunsg \ Repeat of multu not needed?
{
 LDX Q
 BEQ MU1                ; up, P = Acc = Xreg = 0
 
      	                ; P*X will be done
 DEX
 STX T                  ; = Q-1 as carry will be set for addition
 LDA #0
 LDX #8                 ; counter
 LSR P

.MUL6                   ; counter X

 BCC P%+4               ; low bit of P lo clear
 ADC T                  ; +=Q as carry set
 ROR A                  ; hi
 ROR P
 DEX
 BNE MUL6               ; loop X
 RTS                    ; Repeat of mul6 not needed ?

}

\ ******************************************************************************
\ Subroutine: MLTU2-2
\
\ AP(2)= AP* Xunsg(EOR P)
\ ******************************************************************************

 STX Q                  ; AP(2)= AP* Xunsg(EOR P)

\ ******************************************************************************
\ Subroutine: MLTU2
\
\ AP(2)= AP* Qunsg(EOR P)
\ ******************************************************************************

.MLTU2                  ; AP(2)= AP* Qunsg(EOR P)
{
 EOR #&FF               ; use 2 bytes of P and A for result
 LSR A                  ; hi
 STA P+1
 LDA #0
 LDX #16                ; 2 bytes
 ROR P                  ; lo

.MUL7                   ; counter X

 BCS MU21               ; carry set, don't add Q
 ADC Q
 ROR A                  ; 3 byte result
 ROR P+1
 ROR P
 DEX
 BNE MUL7               ; loop X
 RTS

.MU21                   ; carry set, don't add Q

 LSR A                  ; not ROR A
 ROR P+1
 ROR P
 DEX
 BNE MUL7               ; loop X
 RTS
}

\ ******************************************************************************
\ Subroutine: MUT3
\
\ R.S = XX(2), A.P=A*Q
\ Not called?
\ ******************************************************************************

.MUT3                   ; R.S = XX(2), A.P=A*Q
{
 LDX ALP1               ; roll magnitude
 STX P                  ; over-written
}

\ ******************************************************************************
\ Subroutine: MUT2
\
\ R.S = XX(2), A.P=A*Q
\ ******************************************************************************

.MUT2                   ; R.S = XX(2), A.P=A*Q
{
 LDX XX+1
 STX S                  ; hi
}

\ ******************************************************************************
\ Subroutine: MUT1
\
\ Rlo = XX(1), A.P=A*Q
\ ******************************************************************************

.MUT1                   ; Rlo = XX(1), A.P=A*Q
{
 LDX XX
 STX R                  ; lo
}

\ ******************************************************************************
\ Subroutine: MULT1
\
\ Do the following multiplication of signed 8-bit numbers:
\
\   (A P) = Q * A
\
\ This routine implements simple multiplication of two 8-bit numbers into a
\ 16-bit result using the "shift and add algorithm". Consider multiplying two
\ example numbers, which we'll call p and a (as this makes it easier to map the
\ following to the code below):
\
\   p * a = %00101001 * a
\
\ This is the same as:
\
\   p * a = (%00100000 + %00001000 + %00000001) * a
\
\ or:
\
\   p * a = %00100000 * a + %00001000 * a + %00000001 * a
\
\ or:
\
\   p * a = a << 5 + a << 3 + a << 0
\
\ or, to lay this out in the way we're used to seeing it in school books on
\ long multiplication, if a is made up of binary digits aaaaaaaa, it's the same
\ as:
\
\          00101001         p
\          aaaaaaaa x       * a
\   ---------------
\          aaaaaaaa
\         00000000
\        00000000
\       aaaaaaaa
\      00000000
\     aaaaaaaa
\    00000000
\   00000000        +
\   ---------------
\   xxxxxxxxxxxxxxx         -> the result of p * a
\
\ In other words, we can work our way through the digits in the first number p
\ and every time there's a 1, we add an a to the result, shifted to the left by
\ the position of that digit.
\
\ We could code this into assembly relatively easily, but Elite takes a rather
\ more optimised route. Instead of shifting the number aaaaaaaa to the left for
\ each addition, we can instead shift the entire result to the right, saving
\ the bit that falls off the right end, and add an unshifted value of a. If you
\ think of one of the sums in our longhand version like this:
\ 
\     a7a6a5a4a3a2a1a0
\   a7a6a5a4a3a2a1a0   +
\ 
\ then instead of shifting the second number to the left, we can shift the
\ first number to the right and save the rightmost bit, like this:
\ 
\     a7a6a5a4a3a2a1        -> result bit 0 is a0
\   a7a6a5a4a3a2a1a0 +
\ 
\ So the reviews approach is to work our way through the digits in the first
\ number p, shifting the result right every time and saving the rightmost bit
\ in the final result, and every time there's a 1 in p, we add another a to the
\ sum.
\ 
\ This is essentially what Elite does in this routine, but there is one more
\ tweak that makes the process even more efficient (and even more confusing,
\ especially when you first read through the code). Instead of saving the
\ result bits out into a separate location, we can stick them onto the left end
\ of p, because every time we shift p to the right, we gain a spare bit on the
\ left end of p that we no longer use.
\ 
\ See http://nparker.llx.com/a2/mult.html for an explanation
\ ******************************************************************************

.MULT1
{
 TAX                    ; Store A in X

 AND #%01111111         ; Set P = |A| >> 1
 LSR A                  ; and carry = bit 0 of A
 STA P

 TXA                    ; Restore argument A

 EOR Q                  ; Set bit 7 of A and T if Q and A have different signs,
 AND #%10000000         ; clear bit 7 if they have the same signs, 0 all other
 STA T                  ; bits, i.e. T contains the sign bit of Q * A

 LDA Q                  ; Set A = |Q|
 AND #%01111111

 BEQ mu10               ; If |Q| = 0 jump to mu10 (with A set to 0)
 
 TAX                    ; Set T1 = |Q| - 1
 DEX                    ;
 STX T1                 ; We subtract 1 as carry will be set when we want to do
                        ; an addition in the loop below

                        ; We are now going to work our way through the bits of
                        ; P, and do a shift-add for any bits that are set,
                        ; keeping the running total in A. We already set up
                        ; the first shift at the start of this routine, as
                        ; P = |A| >> 1 and C = bit 0 of A, so we now need to set
                        ; up a loop to sift through the other 7 bits in P.
                        
 LDA #0                 ; Set A = 0 so we can start building the answer in A

 LDX #7                 ; Set up a counter in X to count the 7 bits remaining
                        ; in P

.MUL4

 BCC P%+4               ; If C (i.e. the next bit from P) is set, do the
 ADC T1                 ; addition for this bit of P:
                        ;
                        ;   A = A + T1 + C
                        ;     = A + |Q| - 1 + 1
                        ;     = A + |Q|

 ROR A                  ; As mentioned above, this ROR shifts A right and
                        ; catches bit 0 in C - giving another digit for our
                        ; result - and the next ROR sticks that bit into the
                        ; left end of P while also extracting the next bit of P
                        ; for the next addition.

 ROR P                  ; Add the overspill from shifting A to the right onto
                        ; the start of P, and shift P right to fetch the next
                        ; bit for the calculation

 DEX                    ; Decrement the loop counter

 BNE MUL4               ; Loop back for the next bit until P has been rotated
                        ; all the way

 LSR A                  ; Rotate (A P) once more to get the final result, as
 ROR P                  ; we only pushed 7 bits through the above process

 ORA T                  ; Set the sign bit of the result that we stored in T

 RTS                    ; Return from the subroutine

.mu10

 STA P                  ; If we get here, the result is 0 and A = 0, so set
                        ; P = 0 so (A P) = 0

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: MULT12
\
\ R.S = Q * A \ visited quite often
\ ******************************************************************************

.MULT12                 ; R.S = Q * A \ visited quite often
{
 JSR MULT1              ; visit above,  (P,A)= Q * A
 STA S                  ; hi
 LDA P
 STA R                  ; lo
 RTS
}

\ ******************************************************************************
\ Subroutine: TAS3
\
\ Returns XX15.inwk,y  Dot product
\ ******************************************************************************

.TAS3                   ; returns XX15.inwk,y  Dot product
{
 LDX INWK,Y
 STX Q
 LDA XX15               ; xunit
 JSR MULT12             ; R.S = inwk*xx15
 LDX INWK+2,Y
 STX Q
 LDA XX15+1             ; yunit
 JSR MAD                ; X.A = inwk*xx15 + R.S
 STA S
 STX R

 LDX INWK+4,Y
 STX Q
 LDA XX15+2             ; zunit
}

\ ******************************************************************************
\ Subroutine: MAD
\
\ Multiply and add
\
\   (A X) = Q * A + (S R)
\ ******************************************************************************

.MAD
{
 JSR MULT1              ; Call MULT1 to set (A P) = Q * A, protects Y

                        ; Fall through into ADD to do:
                        ;
                        ;   (A X) = (A P) + (S R)
                        ;         = Q * A + (S R)
}

\ ******************************************************************************
\ Subroutine: ADD
\
\ Add two signed 16-bit numbers together, making sure the result has the
\ correct sign. Specifically:
\
\   (A X) = (A P) + (S R)
\
\ ******************************************************************************
\
\ When adding two signed numbers using two's complement, the result can have
\ the wrong sign when an overflow occurs. The classic example in 8-bit signed
\ arithmetic is 127 + 1, which doesn't give the expected 128, but instead gives
\ -128. In binary the sum looks like this:
\ 
\   0111 1111 + 0000 0001 = 1000 0000
\ 
\ The result has bit 7 set, so it is a negative number, 127 + 1 gives -128.
\ This is where the overflow flag V comes in - V would be set by the above sum
\ - but this means that every time you do a sum, you have to check the overflow
\ flag and deal with the overflow.
\ 
\ Elite doesn't want to have to bother with this overhead, so the ADD
\ subroutine, which adds two signed 16-bit numbers, instead ensures that the
\ result always had the correct sign, even in the event of an overflow, though
\ if the addition does overflow, the result still won't be correct. It will
\ have the right sign, though.
\ 
\ To implement this, the algorithm goes as follows. We want to add A and S, so:
\ 
\   * If both A and S are positive, just add them as normal
\ 
\   * If both A and S are negative, then add them and make sure the result is
\     negative
\ 
\   * If A and S have different signs, then we can use the absolute values of A
\     and S to work out the sum, as follows:
\ 
\     * Subtract the smaller absolute value from the larger absolute value
\ 
\     * Give the answer the same sign as the argument with the larger absolute
\       value
\ 
\ To see why this works, try visualising a number line containing the two
\ numbers A and S, with one to the left of zero and one to the right. Adding
\ the numbers is a bit like moving the number with the larger absolute value
\ towards zero on the number line, moving it by the amount of the smaller
\ absolute number; so it's like subtracting the smaller absolute value from the
\ larger one. You can also see that the sum of the two numbers will be on the
\ same side of zero as the number that is furthest from zero, so that's why the
\ answer should have the same sign as the argument with the larger absolute
\ value.
\ 
\ We can implement these steps like this:
\ 
\   * If |A| = |S|, then the result is 0
\ 
\   * If |A| > |S|, then the result is |A| - |S|, with the sign set to the same
\     sign as A
\ 
\   * If |S| > |A|, then the result is |S| - |A|, with the sign set to the same
\     sign as S
\ 
\ So that's what we do below to implement 16-bit signed addition that produces
\ results with the correct sign.
\ ******************************************************************************

.ADD
{
 STA T1                 ; Store argument A in T1

 AND #128               ; Extract the sign (bit 7) of A and store it in T
 STA T

 EOR S                  ; EOR bit 7 of A with S. If they have different bit 7s
 BMI MU8                ; (i.e. they have different signs) then bit 7 in the
                        ; EOR result will be 1, which means the EOR result is
                        ; negative. So the AND, EOR and BMI together mean "jump
                        ; to MU8 if A and S have different signs".

                        ; If we reach here, then A and S have the same sign, so
                        ; we can add them and set the sign to get the result

 LDA R                  ; Add the least significant bytes together into X, so
 CLC                    ;
 ADC P                  ;   X = P + R
 TAX
 
 LDA S                  ; Add the most significant bytes together into A. We
 ADC T1                 ; stored the original argument A in T1 earlier, so we
                        ; can do this with:
                        ;
                        ;   A = A  + S + carry
                        ;     = T1 + S + carry

 ORA T                  ; If argument A was negative (and therefore S was also
                        ; negative) then make sure result A is negative by
                        ; OR-ing the result with the sign bit from argument A
                        ; (which we stored in T)

 RTS                    ; Return from subroutine

.MU8                    ; If we reach here, then A and S have different signs,
                        ; so we can subtract their absolute values and set the
                        ; sign to get the result

 LDA S                  ; Clear the sign (bit 7) in S and store the result in
 AND #127               ; U, so U now contains |S|
 STA U

 LDA P                  ; Subtract the least significant bytes into X, so
 SEC                    ;   X = P - R
 SBC R
 TAX

 LDA T1                 ; Restore the A of the argument (A P) from T1 and
 AND #127               ; clear the sign (bit 7), so A now contains |A|

 SBC U                  ; Set A = |A| - |S|

                        ; At this point we have |A P| - |S R| in (A X), so we
                        ; need to check whether the subtraction above was the
                        ; the right way round (i.e. that we subtracted the
                        ; smaller absolute value from the larger absolute
                        ; value)

 BCS MU9                ; If |A| >= |S|, our subtraction was the right way
                        ; round, so jump to MU9 to set the sign

                        ; If we get here, then |A| < |S|, so our subtraction
                        ; above was the wrong way round (we actually subtracted
                        ; the larger absolute value from the smaller absolute
                        ; value. So let's subtract the result we have in (A X)
                        ; from zero, so that the subtraction is the right way
                        ; round

 STA U                  ; Store A in U

 TXA                    ; Set X = 0 - X using two's complement (to negate a
 EOR #&FF               ; number in two's complement, you can invert the bits
 ADC #1                 ; and add one - and we know carry is clear as we didn't
 TAX                    ; take the BCS branch above, so ADC will do the job)

 LDA #0                 ; Set A = 0 - A, which we can do this time using a
 SBC U                  ; a subtraction with carry clear
 
 ORA #128               ; We now set the sign bit of A, so that the EOR on the
                        ; next line wil give the result the opposite sign to
                        ; argument A (as T contains the sign bit of argument
                        ; A). This is the same as giving the result the same
                        ; sign as argument S (as A and S have different signs),
                        ; which is what we want, as S has the larger absolute
                        ; value.

.MU9

 EOR T                  ; If we get here from the BCS above, then |A| >= |S|,
                        ; so we want to give the result the same sign as
                        ; argument A, so if argument A was negative, we flip
                        ; the sign of the result with an EOR (to make it
                        ; negative)

 RTS                    ; Return from subroutine
}

\ ******************************************************************************
\ Subroutine: TIS1
\
\ Tidy subroutine 1  X.A =  (-X*A  + (R.S))/96
\ ******************************************************************************

.TIS1                   ; Tidy subroutine 1  X.A =  (-X*A  + (R.S))/96
{
 STX Q
 EOR #128               ; flip sign of Acc
 JSR MAD                ; multiply and add (X,A) =  -X*A  + (R,S)

.DVID96                 ; Their comment A=A/96: answer is A*255/96

 TAX
 AND #128               ; hi sign
 STA T
 TXA
 AND #127               ; hi A7
 LDX #254               ; slide counter
 STX T1

.DVL3                   ; roll T1  clamp Acc to #96 for rotation matrix unity

 ASL A
 CMP #96                ; max 96
 BCC DV4                ; skip subtraction
 SBC #96

.DV4                    ; skip subtraction

 ROL T1
 BCS DVL3               ; loop T1
 LDA T1
 ORA T                  ; hi sign
 RTS
}

\ ******************************************************************************
\ Subroutine: DV42
\
\ Travel step of dust particle front/rear
\ ******************************************************************************

.DV42                   ; travel step of dust particle front/rear
{
 LDA SZ,Y               ; dustz
}

\ ******************************************************************************
\ Subroutine: DV41
\
\ P.R = speed/ (ZZ/8) Called by STARS2 left/right
\ ******************************************************************************

.DV41                   ; P.R = speed/ (ZZ/8) Called by STARS2 left/right
{
 STA Q
 LDA DELTA              ; speed, how far has dust moved based on its z-coord
}

\ ******************************************************************************
\ Subroutine: DVID4
\
\ P-R=A/Qunsg \ P.R = A/Q unsigned  called by compass in Block E
\ ******************************************************************************

.DVID4                  ; P-R=A/Qunsg \ P.R = A/Q unsigned  called by compass in Block E
{
 LDX #8                 ; counter
 ASL A
 STA P
 LDA #0

.DVL4                   ; counter X

 ROL A
 BCS DV8                ; Acc carried
 CMP Q
 BCC DV5                ; skip subtraction

.DV8                    ; Acc carried

 SBC Q
 SEC                    ; carry gets set

.DV5                    ; skip subtraction

 ROL P                  ; hi
 DEX
 BNE DVL4               ; loop X, hi left in P.
 JMP LL28+4             ; Block G remainder R for A*256/Q
}

\ ******************************************************************************
\ Subroutine: DVID3B2
\
\ Divide 3 bytes by 2 bytes, K = P.A/INWK_z for planet, Xreg protected.
\ ******************************************************************************

.DVID3B2                ; Divide 3 bytes by 2 bytes, K = P.A/INWK_z for planet, Xreg protected.
{
 STA P+2                ; num sg
 LDA INWK+6             ; z coord lo
 STA Q
 LDA INWK+7             ; z coord hi
 STA R
 LDA INWK+8             ; z coord sg
 STA S

.DVID3B                 ; K (3bytes)=P(3bytes)/S.R.Q. aprx  Acc equiv K(0)

 LDA P                  ; num lo
 ORA #1                 ; avoid 0
 STA P
 LDA P+2                ; num sg
 EOR S                  ; zsg
 AND #128               ; extract sign
 STA T
 LDY #0                 ; counter
 LDA P+2                ; num sg
 AND #127               ; will look at lower 7 bits of Acc in.

.DVL9                   ; counter Y up

 CMP #&40               ; object very far away?
 BCS DV14               ; scaled, exit Ycount
 ASL P
 ROL P+1
 ROL A                  ; 3 bytes
 INY
 BNE DVL9               ; loop Y

.DV14                   ; scaled, exited Ycount

 STA P+2                ; big numerator
 LDA S                  ; zsg
 AND #127               ; denom sg7
 BMI DV9                ; can't happen

.DVL6                   ; counter Y back down, roll S.

 DEY                    ; scale Y back
 ASL Q                  ; denom lo
 ROL R
 ROL A                  ; hi S
 BPL DVL6               ; loop roll S until Abit7 set.

.DV9                    ; bmi cant happen?

 STA Q                  ; mostly empty so now reuse as hi denom
 LDA #254               ; Xreg protected so can't LL28+4
 STA R
 LDA P+2                ; big numerator
 JSR LL31               ; R now =A*256/Q

 LDA #0                 ; K1to3 = 0
 STA K+1
 STA K+2
 STA K+3
 TYA                    ; Y counter for scale
 BPL DV12               ; Ycount +ve
 LDA R                  ; else Y count is -ve, Acc = remainder.

.DVL8                   ; counter Y up

 ASL A                  ; boost up
 ROL K+1
 ROL K+2
 ROL K+3
 INY
 BNE DVL8               ; loop Y up
 STA K                  ; lo
 LDA K+3                ; sign
 ORA T
 STA K+3
 RTS

.DV13                   ; Ycount zero \ K(1to2) already = 0

 LDA R                  ; already correct
 STA K                  ; lo
 LDA T                  ; sign
 STA K+3
 RTS

.DV12                   ; Ycount +ve

 BEQ DV13               ; Ycount zero, up.
 LDA R                  ; else reduce remainder

.DVL10                  ; counter Y reduce

 LSR A
 DEY
 BNE DVL10              ; loop Y reduce
 STA K                  ; lo
 LDA T                  ; sign
 STA K+3
 RTS
}

\ ******************************************************************************
\ Subroutine: cntr
\
\ Apply damping to the value in X, where X ranges from 1 to 255 with 128 as the
\ centre point (so X represents a position on a centre-based dashboard slider,
\ such as pitch or roll). If the value is in the left-hand side of the slider
\ (1-127) then it bumps the value up by 1 so it moves towards towards the
\ centre, and if it's in the right-hand side, it reduces it by 1, also moving
\ it towards the centre.
\ ******************************************************************************

.cntr
{
 LDA DAMP               ; If DAMP is non-zero, then keyboard damping is not
 BNE RE1                ; enabled, so jump to RE1 to return from the subroutine

 TXA                    ; If X < 128, then it's in the left-hand side of the
 BPL BUMP               ; dashboard slider, so jump to BUMP to bump it up by 1,
                        ; to move it closer to the centre

 DEX                    ; Otherwise X >= 128, so it's in the right-hand side
 BMI RE1                ; of the dashboard slider, so decrement X by 1, and if
                        ; it's still >= 128, jump to RE1 to return from the
                        ; subroutine, otherwise fall through to BUMP to undo
                        ; the bump and then return

.BUMP

 INX                    ; Bump X up by 1, and if it hasn't ovedrshot the end of
 BNE RE1                ; the dashboard slider, jump to RE1 to return from the
                        ; subroutine, otherwise fall through to REDU to drop
                        ; it down by 1 again

.REDU                   

 DEX                    ; Reduce X by 1, and if we have reached 0 jump up to
 BEQ BUMP               ; BUMP to add 1, because we need the value to be in the
                        ; range 1 to 255

.RE1

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: BUMP2
\
\ Other entry points: RE2
\
\ Increase ("bump up") X by A, where X is either the current rate of pitch or
\ the current rate of roll.
\
\ The rate of pitch or roll ranges from 1 to 255 with 128 as the centre point.
\ This is the amount by which the pitch or roll is currently changing, so 1
\ means it is decreasing at the maximum rate, 128 means it is not changing,
\ and 255 means it is increasing at the maximum rate. These values correspond
\ to the line on the DC or RL indicators on the dashboard, with 1 meaning full
\ left, 128 meaning the middle, and 255 meaning full right.
\
\ If bumping up X would push it past 255, then X is set to 255.
\
\ If keyboard auto-recentre is configured and the result is less than 128, we
\ bump X up to the mid-point, 128. This is the equivalent of having a roll or
\ pitch in the left half of the indicator, when increasing the roll or pitch
\ should jump us straight to the mid-point.
\ ******************************************************************************

.BUMP2
{
 STA T                  ; Store argument A in T so we can restore it later

 TXA                    ; Copy argument X into A

 CLC                    ; Clear the carry flag so we can do addition without
                        ; the carry flag affecting the result

 ADC T                  ; Set X = A = argument X + argument A
 TAX

 BCC RE2                ; If carry is clear, then we didn't overflow, so jump
                        ; to RE2 to auto-recentre and return the result

 LDX #255               ; We have an overflow, so set X to the maximum possible
                        ; value, 255

.^RE2

 BPL RE3+2              ; If X has bit 7 clear (i.e. the result < 128), then
                        ; jump to RE3+2 below to do an auto-recentre, if
                        ; configured, because the result is on the left side of
                        ; the centre point of 128

                        ; Jumps to RE2+2 end up here

 LDA T                  ; Restore the original argument A into A

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: REDU2
\
\ Other entry points: RE3
\
\ Reduce X by A, where X is either the current rate of pitch or the current
\ rate of roll.
\
\ The rate of pitch or roll ranges from 1 to 255 with 128 as the centre point.
\ This is the amount by which the pitch or roll is currently changing, so 1
\ means it is decreasing at the maximum rate, 128 means it is not changing,
\ and 255 means it is increasing at the maximum rate. These values correspond
\ to the line on the DC or RL indicators on the dashboard, with 1 meaning full
\ left, 128 meaning the middle, and 255 meaning full right.
\
\ If reducing X would bring it below 1, then X is set to 1.
\
\ If keyboard auto-recentre is configured and the result is greater than 128, we
\ reduce X down to the mid-point, 128. This is the equivalent of having a roll
\ or pitch in the right half of the indicator, when decreasing the roll or pitch
\ should jump us straight to the mid-point.
\ ******************************************************************************

.REDU2
{
 STA T                  ; Store argument A in T so we can restore it later

 TXA                    ; Copy argument X into A

 SEC                    ; Set the carry flag so we can do subtraction without
                        ; the carry flag affecting the result

 SBC T                  ; Set X = A = argument X - argument A
 TAX

 BCS RE3                ; If carry is set, then we didn't underflow, so jump
                        ; to RE3 to auto-recentre and return the result

 LDX #1                 ; We have an underflow, so set X to the minimum possible
                        ; value, 1

.^RE3

 BPL RE2+2              ; If X has bit 7 clear (i.e. the result < 128), then
                        ; jump to RE2+2 above to return the result as is,
                        ; because the result is on the left side of the centre
                        ; point of 128, so we don't need to auto-centre

                        ; Jumps to RE3+2 end up here

                        ; If we get here, then we need to apply auto-recentre,
                        ; if it is configured

 LDA DJD                ; If keyboard auto-recentre is disabled, then
 BNE RE2+2              ; jump to RE2+2 to restore A and return

 LDX #128               ; If keyboard auto-recentre is enabled, set X to 128
 BMI RE2+2              ; (the middle of our range) and jump to RE2+2 to
                        ; restore A and return
}

\ ******************************************************************************
\ Subroutine: ARCTAN
\
\ A=TAN-1(P/Q) \ A=arctan (P/Q)  called from block E
\ ******************************************************************************

.ARCTAN                 ; A=TAN-1(P/Q) \ A=arctan (P/Q)  called from block E
{
 LDA P
 EOR Q
 STA T1                 ; quadrant info
 LDA Q
 BEQ AR2                ; Q=0 so set angle to 63, pi/2
 ASL A                  ; drop sign
 STA Q
 LDA P
 ASL A                  ; drop sign
 CMP Q
 BCS AR1                ; swop A and Q as A >= Q
 JSR ARS1               ; get Angle for A*32/Q from table.
 SEC

.AR4                    ; sub o.k

 LDX T1
 BMI AR3                ; -ve quadrant
 RTS

.AR1                    ; swop A and Q

 LDX Q
 STA Q
 STX P
 TXA
 JSR ARS1               ; get Angle for A*32/Q from table.
 STA T                  ; angle
 LDA #64                ; next range of angle, pi/4 to pi/2
 SBC T
 BCS AR4                ; sub o.k

.AR2                    ; set angle to 90 degrees

 LDA #63
 RTS

.AR3                    ; -ve quadrant

 STA T                  ; angle
 LDA #128               ; pi
\SEC
 SBC T                  ; A = 128-T, so now covering range pi/2 to pi correctly
 RTS

.ARS1                   ; get Angle for A*32/Q from table.

 JSR LL28               ; BFRDIV R=A*256/Q
 LDA R
 LSR A
 LSR A
 LSR A                  ; 31 max.
 TAX                    ; index into table at end of words data
 LDA ACT,X
 RTS
}

\ ******************************************************************************
\ Variable: ACT
\
\ Arctan table.
\ ******************************************************************************

.ACT
{
FOR I%,0,31
 EQUB INT(128/PI*ATN(I%/32)+.5)
NEXT
}

\ ******************************************************************************
\ Subroutine: WARP
\
\ In-system jump. Esc, cargo, asteroid, transporter dragged with you.
\ ******************************************************************************

.WARP                   ; Jump J key was hit. Esc, cargo, asteroid, transporter dragged with you.
{
 LDA MANY+AST
 CLC
 ADC MANY+ESC
 CLC                    ; Not in ELITEC.TXT, but in ELTC source image

 ADC MANY+OIL
 TAX
 LDA FRIN+2,X           ; more entries than just junk?
 ORA SSPR               ; space station present
 ORA MJ                 ; mis-jump
 BNE WA1                ; Warning noise #40 jump failed
 LDY K%+8               ; planet zsg
 BMI WA3                ; planet behind
 TAY                    ; A = Y = 0 for planet
 JSR MAS2               ; or'd x,y,z coordinate of &902+Y to A.
\LSR A                  ; ignore lowest bit of sg
\BEQ WA1                ; Warning, as planet too close
 CMP #2
 BCC WA1                ; Not in ELITEC.TXT, but in ELTC source image

.WA3                    ; planet behind

 LDY K%+NI%+8           ; Sun zsg
 BMI WA2                ; sun behind
 LDY #NI%               ; NI% for Sun
 JSR m                  ; max of x,y,z at &902+Y to A.
\LSR A                  ; ignore lowest bit of sg
\BEQ WA1                ; Warning, as Sun too close
 CMP #2
 BCC WA1                ; Not in ELITEC.TXT, but in ELTC source image

.WA2                    ; sun behind, Shift.

 LDA #&81               ; shift sun and planet zsg
 STA S                  ; hi
 STA R                  ; lo
 STA P                  ; lo
 LDA K%+8               ; planet zsg
 JSR ADD                ; (A X) = (A P) + (S R) = &81.zsg + &81.&81
 STA K%+8               ; allwk+8
 LDA K%+NI%+8           ; Sun zsg
 JSR ADD                ; (A X) = (A P) + (S R)
 STA K%+NI%+8           ; allwk+37+8

 LDA #1                 ; menu id
 STA QQ11
 STA MCNT               ; Fetch main loop counter
 LSR A                  ; #0
 STA EV                 ; extra vessels
 LDX VIEW               ; forward
 JMP LOOK1              ; start view X

.WA1                    ; Warning sound

 LDA #40                ; Call the NOISE routine with A = 40 to make a long,
 JMP NOISE              ; low beep
}

\ ******************************************************************************
\ Subroutine: LASLI
\
\ Laser lines
\ ******************************************************************************

.LASLI                  ; laser lines
{
 JSR DORND              ; Set A and X to random numbers
 AND #7
 ADC #Y-4               ; below center of screen
 STA LASY
 JSR DORND              ; Set A and X to random numbers
 AND #7
 ADC #X-4               ; left of center
 STA LASX
 LDA GNTMP              ; gun temperature
 ADC #8                 ; heat up laser temperature
 STA GNTMP
 JSR DENGY              ; drain energy by 1 for active ECM pulse
}

\ ******************************************************************************
\ Subroutine: LASLI2
\
\ Stops drawing laser lines early for pulse laser
\ ******************************************************************************

.LASLI2
{
 LDA QQ11               ; If not zero then not a space view
 BNE PU1-1              ; rts
 LDA #32                ; xleft
 LDY #224               ; xright
 JSR las                ; (a few lines below) twice
 LDA #48                ; new xleft
 LDY #208               ; new xright

.las

 STA X2
 LDA LASX               ; center-X
 STA X1
 LDA LASY               ; center-Y
 STA Y1
 LDA #2*Y-1             ; bottom of screen
 STA Y2
 JSR LOIN               ; from center (X1,Y1) to bottom left (X2,Y2)
 LDA LASX
 STA X1
 LDA LASY
 STA Y1
 STY X2
 LDA #2*Y-1
 STA Y2
 JMP LOIN
}

\ ******************************************************************************
\ Subroutine: PLUT
\
\ Other entry points: PU1-1 (RTS), LO2 (RTS)
\
\ This routine flips the relevant geometric axes in INWK depending on which
\ view we are looking through (forward, rear, left, right).

\ The easiest way to think about this is that the z-axis always points into the
\ screen, the y-axis always points up, and the x-axis always points to the
\ right, like this:
\
\     y
\     ^
\     |   z (into screen)
\     |  /
\     | /
\     |/
\     +---------> x
\
\ This rule applies, whichever view we are looking through. So when we're
\ looking through the forward view, z is into the screen - in the direction of
\ travel - but if we switch, then the direction of travel is now to our right.
\
\ The local universe is stored as if we are looking forward, so the z-axis is
\ in the direction of travel. This routine takes those stored coordinates and
\ switches the axes around if we are looking bahind us or to the sides, so that
\ we can use the same maths to display what's in that view - in other words, to
\ switch the axes so that the value of the z-coordinate that we've stored in
\ our universe - the direction of travel - is translated into the correct axis
\ for the view we are looking at (for the z-axis, which points into the screen
\ for the forward view, we move it to point out of the screen if we are looking
\ backwards, to the right if we're looking out of the left view, or to the left
\ if we are looking out of the right view).
\
\ For the forward view, then we change nothing as the default universe is set up
\ for this view (so the coordinates and matrices in K%, UNIV, INWK etc. are
\ already correct for this view). Let's look at the other views in more detail.
\
\ Rear view
\ ---------
\ For the rear view, this is what our original universe axes look like when we
\ we are looking backwards:
\
\                 y
\                 ^
\                 |
\                 |
\                 |
\                 |
\     x <---------+
\                /
\               z (out of screen)
\
\ so to convert these axes into the standard "up, right, into-the-screen" set
\ of axes we need for drawing to the screen, we need to do the changes on the
\ left (with the original set of axes on the right for comparison):
\ 
\   y                                           y
\   ^                                           ^
\   |   -z (into screen)                        |   z (into screen)
\   |  /                                        |  /
\   | /                                         | /
\   |/                                          |/
\   +---------> -x                              +---------> x
\ 
\ So to change the INWK workspace from the original axes on the right to the
\ new set on the left, we need to change the signs of the x and z coordinates
\ and matrices in INWK, which we can do by flipping the signs of the following:
\ 
\   * x_sign, z_sign
\   * rotmat0x_hi, rotmat0z_hi
\   * rotmat1x_hi, rotmat1z_hi
\   * rotmat2x_hi, rotmat2z_hi
\ 
\ so that's what we do below.
\ 
\ Left view
\ ---------
\ For the left view, this is what our original universe axes look like when we
\ are looking to the left:
\ 
\       y
\       ^
\       |
\       |
\       |
\       |
\       +---------> z
\      /
\     /
\    /
\   x (out of screen)
\ 
\ so to convert these axes into the standard "up, right, into-the-screen" set
\ of axes we need for drawing to the screen, we need to do the changes on the
\ left (with the original set of axes on the right for comparison):
\ 
\   y                                           y
\   ^                                           ^
\   |   -x (into screen)                        |   z (into screen)
\   |  /                                        |  /
\   | /                                         | /
\   |/                                          |/
\   +---------> z                               +---------> x
\ 
\ In other words, to go from the original set of axes on the right to the new
\ set of axes on the left, we need to swap the x- and z-axes around, and flip
\ the sign of the one now going in and out of the screen (i.e. the new z-axis).
\ In other words, we swap the following values in INWK:
\ 
\   * x_lo and z_lo
\   * x_hi and z_hi
\   * x_sign and z_sign
\   * rotmat0x_lo and rotmat0z_lo
\   * rotmat1x_lo and rotmat1z_lo
\   * rotmat2x_lo and rotmat2z_lo
\ 
\ and then change the sign of the axis going in and out of the screen by
\ flipping the signs of the following:
\ 
\   * z_sign
\   * rotmat0z_hi
\   * rotmat1z_hi
\   * rotmat2z_hi
\ 
\ So this is what we do below.
\ 
\ Right view
\ ---------
\ For the right view, this is what our original universe axes look like when we
\ are looking to the right:
\ 
\               y
\               ^
\               |   x (into screen)
\               |  /
\               | /
\               |/
\   z <---------+
\ 
\ so to convert these axes into the standard "up, right, into-the-screen" set
\ of axes we need for drawing to the screen, we need to do the changes on the
\ left (with the original set of axes on the right for comparison):
\ 
\   y                                           y
\   ^                                           ^
\   |   x (into screen)                         |   z (into screen)
\   |  /                                        |  /
\   | /                                         | /
\   |/                                          |/
\   +---------> -z                              +---------> x
\ 
\ In other words, to go from the original set of axes on the right to the new
\ set of axes on the left, we need to swap the x- and z-axes around, and flip
\ the sign of the one now going to the right (i.e. the new x-axis). In other
\ words, we swap the following values in INWK:
\ 
\   * x_lo and z_lo
\   * x_hi and z_hi
\   * x_sign and z_sign
\   * rotmat0x_lo and rotmat0z_lo
\   * rotmat1x_lo and rotmat1z_lo
\   * rotmat2x_lo and rotmat2z_lo
\ 
\ and then change the sign of the axis going to the right by flipping the signs
\ of the following:
\ 
\   * x_sign
\   * rotmat0x_hi
\   * rotmat1x_hi
\   * rotmat2x_hi
\ 
\ So this is what we do below.
\ ******************************************************************************

.PLUT
{
 LDX VIEW               ; Load the current view into X:
                        ;
                        ; 0 = forward
                        ; 1 = rear
                        ; 2 = left
                        ; 3 = right


 BNE PU1                ; If the current view is forward, return from the
 RTS                    ; subroutine, as the geometry in INWK is already
                        ; correct

.^PU1

 DEX                    ; Decrement the view, so now:
                        ; 0 = rear
                        ; 1 = left
                        ; 2 = right

 BNE PU2                ; If the current view is left or right, jump to PU2,
                        ; otherwise this is the rear view, so continue on

 LDA INWK+2             ; Flip the sign of x_sign
 EOR #%10000000
 STA INWK+2

 LDA INWK+8             ; Flip the sign of z_sign
 EOR #%10000000
 STA INWK+8

 LDA INWK+10            ; Flip the sign of rotmat0x_hi
 EOR #%10000000
 STA INWK+10

 LDA INWK+14            ; Flip the sign of rotmat0z_hi
 EOR #%10000000
 STA INWK+14

 LDA INWK+16            ; Flip the sign of rotmat1x_hi
 EOR #%10000000
 STA INWK+16

 LDA INWK+20            ; Flip the sign of rotmat1z_hi
 EOR #%10000000
 STA INWK+20

 LDA INWK+22            ; Flip the sign of rotmat2x_hi
 EOR #%10000000
 STA INWK+22

 LDA INWK+26            ; Flip the sign of rotmat1z_hi
 EOR #%10000000
 STA INWK+26

 RTS                    ; Return from the subroutine

.PU2                    ; We enter this with X set to the view, as follows:
                        ;
                        ; 1 = left
                        ; 2 = right

 LDA #0                 ; Set RAT2 = 0 (left view) or -1 (right view)
 CPX #2
 ROR A
 STA RAT2

 EOR #%10000000         ; Set RAT = -1 (left view) or 0 (right view)
 STA RAT

 LDA INWK               ; Swap x_lo and z_lo
 LDX INWK+6
 STA INWK+6
 STX INWK

 LDA INWK+1             ; Swap x_hi and z_hi
 LDX INWK+7
 STA INWK+7
 STX INWK+1

 LDA INWK+2             ; Swap x_sign and z_sign
 EOR RAT                ; If left view, flip sign of new z_sign
 TAX                    ; If right view, flip sign of new x_sign
 LDA INWK+8
 EOR RAT2
 STA INWK+2
 STX INWK+8

 LDY #9                 ; Swap rotmat0x_lo and rotmat0z_lo
 JSR PUS1               ; Swap rotmat0x_hi and rotmat0z_hi
                        ; If left view, flip sign of new rotmat0z_hi
                        ; If right view, flip sign of new rotmat0x_hi

 LDY #15                ; Swap rotmat1x_lo and rotmat1z_lo
 JSR PUS1               ; Swap rotmat1x_hi and rotmat1z_hi
                        ; If left view, flip sign of new rotmat1z_hi
                        ; If right view, flip sign of new rotmat1x_hi

 LDY #21                ; Swap rotmat2x_lo and rotmat2z_lo
                        ; Swap rotmat2x_hi and rotmat2z_hi
                        ; If left view, flip sign of new rotmat2z_hi
                        ; If right view, flip sign of new rotmat2x_hi

.PUS1

 LDA INWK,Y             ; Swap rotmatx_lo and rotmatz_lo for the matrix offset
 LDX INWK+4,Y           ; in Y, i.e.
 STA INWK+4,Y           ; for Y =  9 swap rotmat0x_lo and rotmat0z_lo
 STX INWK,Y             ; for Y = 15 swap rotmat1x_lo and rotmat1z_lo
                        ; for Y = 21 swap rotmat2x_lo and rotmat2z_lo

 LDA INWK+1,Y           ; Swap rotmatx_hi and rotmatz_hi for the offset in Y
 EOR RAT                ; If left view, flip sign of new rotmatnz_hi
 TAX                    ; If right view, flip sign of new rotmatnx_hi
 LDA INWK+5,Y
 EOR RAT2
 STA INWK+1,Y
 STX INWK+5,Y

.^LO2

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: LQ
\
\ new view X, Acc = 0
\ ******************************************************************************

.LQ                     ; new view X, Acc = 0
{
 STX VIEW               ; laser mount
 JSR TT66               ; box border with menu id QQ11 set to Acc
 JSR SIGHT              ; laser cross-hairs
 JMP NWSTARS            ; new dust field
}

\ ******************************************************************************
\ Subroutine: LOOK1
\
\ Start view X
\ ******************************************************************************

.LOOK1                  ; Start view X
{
 LDA #0                 ; menu id is space view
 LDY QQ11
 BNE LQ                 ; new view X, Acc = 0.
 CPX VIEW
 BEQ LO2                ; rts as view unchanged
 STX VIEW               ; else new view
 JSR TT66               ; box border with QQ11 set to Acc
 JSR FLIP               ; switch dusty and dustx
 JSR WPSHPS             ; wipe ships on scanner
}

\ ******************************************************************************
\ Subroutine: SIGHT
\
\ Laser cross-hairs
\ ******************************************************************************

.SIGHT                  ; Laser cross-hairs
{
 LDY VIEW
 LDA LASER,Y
 BEQ LO2                ; no laser cross-hairs, rts
 LDA #128               ; xscreen mid
 STA QQ19
 LDA #Y-24              ; #Y-24 = #72 yscreen mid
 STA QQ19+1
 LDA #20                ; size of cross hair
 STA QQ19+2
 JSR TT15               ; the cross hair using QQ19(0to2)
 LDA #10                ; negate out small cross-hairs
 STA QQ19+2
 JMP TT15               ; again, negate out small cross-hairs.
}

\ ******************************************************************************
\ Subroutine: TT66
\
\ Other entry points: TT66-2 (set A to 1)
\
\ Clear the top part of the screen (mode 4), draw a box border, and set the
\ current view type in QQ11 to A.
\
\ Arguments:
\
\   A           The type of the new current view (see QQ11 for a list of view
\               types)
\ ******************************************************************************

{
 LDA #1

.^TT66

 STA QQ11               ; Set the current view type in QQ11 to A
}

\ ******************************************************************************
\ Subroutine: TTX66
\
\ Clear the top part of the screen (mode 4) and draw a box border.
\ ******************************************************************************

.TTX66                  ; New box
{
 LDA #128               ; set bit7 One uppercase letter
 STA QQ17               ; flag for flight tokens
 ASL A
 STA LASCT              ; Acc =0, is LAS2 in ELITEC.TXT
 STA DLY                ; delay printing
 STA de                 ; clear flag for item + destroyed
 LDX #&60               ; screen hi page start

.BOL1                   ; box loop 1, counter X

 JSR ZES1               ; zero page X
 INX                    ; next page
 CPX #&78               ; last screen page
 BNE BOL1               ; loop X

 LDX QQ22+1
 BEQ BOX                ; skip if no outer hyperspace countdown
 JSR ee3                ; else reprint hyperspace countdown in X
}

.BOX                    ; front view box but no title if menu id > 0
{
 LDY #1                 ; Y text cursor to top
 STY YC
 LDA QQ11               ; menu id
 BNE tt66
 LDY #11                ; X text cursor indent
 STY XC
 LDA VIEW
 ORA #&60               ; build token = front rear
 JSR TT27               ; process flight text token
 JSR TT162              ; white space
 LDA #175               ; token = VIEW
 JSR TT27

.tt66                   ; no view title

 LDX #0                 ; top horizontal line
 STX X1
 STX Y1
 STX QQ17               ; printing flag all Upper case
 DEX                    ; #255
 STX X2
 JSR HLOIN              ; horizontal line  X1,X2,Y1. Yreg protected.

 LDA #2                 ; 2 then 1, 0, 255, 254
 STA X1
 STA X2
 JSR BOS2               ; do twice

.BOS2

 JSR BOS1               ; do twice

.BOS1

 LDA #0                 ; bottom of screen
 STA Y1
 LDA #2*Y-1             ; #(2*Y-1) is top of screen
 STA Y2
 DEC X1
 DEC X2
 JMP LOIN               ; line using (X1,Y1), (X2,Y2) Yreg protected.
}

\ ******************************************************************************
\ Subroutine: DELAY-5
\
\ Short delay
\ ******************************************************************************

 LDY #2
 EQUB &2C               ; Skip the next instruction by turning it into
                        ; &2C &A0 &08, or BIT &08A0, which does nothing bar
                        ; affecting the flags

\ ******************************************************************************
\ Subroutine: DEL8
\
\ Wait for 8/50 of a second (0.16 seconds).
\ ******************************************************************************

.DEL8
{
 LDY #8                 ; Set Y to 8 vertical syncs and fall through into DELAY
                        ; to wait for this long
}

\ ******************************************************************************
\ Subroutine: DELAY
\
\ Wait for the number of vertical syncs given in Y, so this effectively waits
\ for Y/50 of a second (as the vertical sync occurs 50 times a second).
\
\ Arguments:
\
\   Y           The number of vertical sync events to wait for
\ ******************************************************************************

.DELAY
{
 JSR WSCAN              ; Jump to WSCAN to wait for the next vertical sync

 DEY                    ; Decrement the counter in Y

 BNE DELAY              ; If Y isn't yet at zero, jump back to DELAY to wait
                        ; for another vertical sync

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: hm
\
\ Move hyperspace cross-hairs. Returns A = 0.
\ ******************************************************************************

.hm
{
 JSR TT103              ; Draw small cross-hairs at coordinates (QQ9, QQ10),
                        ; which will erase the cross-hairs that are currently
                        ; there

 JSR TT111              ; Select the target system closest to galactic
                        ; coordinates (QQ9, QQ10)

 JSR TT103              ; Draw small cross-hairs at coordinates (QQ9, QQ10),
                        ; which will draw the cross-hairs at our current home
                        ; system

 LDA QQ11
 BEQ SC5
}

\ ******************************************************************************
\ Subroutine: CLYNS
\
\ Clear some space at the bottom of the screen and move the text cursor to 
\ column 1, row 21. Specifically, this zeroes the following screen locations:
\
\   &7507 to &75F0
\   &7607 to &76F0
\   &7707 to &77F0
\
\ which clears the three bottom text rows of the space view (rows 21 to 23),
\ from text column 1 to 30 (so it doesn't overwrite the box border in columns 0
\ and 32, or the last usable column, column 31).
\
\ Returns:
\
\   A           A is set to 0
\
\   Y           Y is set to 0
\ ******************************************************************************

.CLYNS
{
 LDA #20                ; Move the text cursor to row 20, near the bottom of
 STA YC                 ; the screen

 LDA #&75               ; Set the two-byte value in SC to &7507
 STA SC+1
 LDA #7
 STA SC

 JSR TT67               ; Print a newline, which will move the text cursor down
                        ; a line (to row 21) and back to column 1

 LDA #0                 ; Call LYN to clear the pixels from &7507 to &75F0
 JSR LYN

 INC SC+1               ; Increment SC+1 so SC points to &7607

 JSR LYN                ; Call LYN to clear the pixels from &7607 to &76F0

 INC SC+1               ; Increment SC+1 so SC points to &7707

 INY                    ; Move the text cursor to column 1 (as LYN sets Y to 0)
 STY XC

                        ; Fall through into LYN to clear the pixels from &7707
                        ; to &77F0
}

\ ******************************************************************************
\ Subroutine: LYN
\
\ Other entry points: SC5 (RTS)
\
\ Set pixels 0-233 to the value in A, starting at the pixel pointed to by SC.
\
\ Arguments:
\
\   A           The value to store in pixels 1-233 (the only value that is
\               actually used is A = 0, which clears those pixels)
\
\ Returns:
\
\   Y           Y is set to 0
\ ******************************************************************************

.LYN
{
 LDY #233               ; Set up a counter in Y to count down from pixel 233

.EE2

 STA (SC),Y             ; Store A in the Y-th byte after the address pointed to
                        ; by SC

 DEY                    ; Decrement Y

 BNE EE2                ; Loop back until Y is zero

.^SC5

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: SCAN
\
\ Ships on Scanner - last code written
\ ******************************************************************************

.SCAN                   ; ships on Scanner - last code written
{
 LDA INWK+31            ; display explosion state|missiles
 AND #16                ; dont show on scanner if bit4 clear, invisible.
 BEQ SC5                ; rts
 LDA TYPE               ; ship type
 BMI SC5                ; dont show planet, rts
 LDX #&FF               ; default scanner colour Yellow
\CMP #TGL
\BEQ SC49
 CMP #MSL               ; missile
 BNE P%+4               ; not missile
 LDX #&F0               ; scanner colour updated for missile to Red
\CMP #AST
\BCC P%+4
\LDX #&F

\.SC49

 STX COL                ; the colour for stick
 LDA INWK+1             ; xhi
 ORA INWK+4             ; yhi
 ORA INWK+7             ; zhi
 AND #&C0               ; too far away?
 BNE SC5                ; rts

 LDA INWK+1             ; xhi
 CLC                    ; build stick xcoord
 LDX INWK+2             ; xsg
 BPL SC2                ; xsg +ve
 EOR #&FF               ; else flip
 ADC #1

.SC2                    ; xsg +ve

 ADC #123               ; xhi+#123
 STA X1                 ; Xscreen for stick

 LDA INWK+7
 LSR A                  ; zhi
 LSR A                  ; Acc = zhi /4
 CLC                    ; onto zsg
 LDX INWK+8
 BPL SC3                ; z +ve
 EOR #&FF               ; else
 SEC                    ; flip zhi/4

.SC3                    ; z +ve

 ADC #35                ; zhi/4+ #35
 EOR #&FF               ; flip to screen lo
 STA SC                 ; store Z component of stick base

 LDA INWK+4             ; yhi
 LSR A                  ; Acc = yhi/2
 CLC                    ; onto ysg
 LDX INWK+5
 BMI SCD6               ; y +ve
 EOR #&FF               ; else flip yhi/2
 SEC

.SCD6                   ; y +ve , now add to z-component

 ADC SC                 ; add Z component of stick base
 BPL ld246              ; stick goes up
 CMP #194               ; >= #194 ?
 BCS P%+4               ; skip min at #194
 LDA #194               ; clamp y min
 CMP #247               ; < #247 ?
 BCC P%+4               ; skip max at #246

.ld246                  ; stick goes up

 LDA #246               ; clamp y max
 STA Y1                 ; Yscreen for stick head
 SEC                    ; sub z-component to leave y length
 SBC SC
 PHP                    ; push sign
\BCS SC48
\EOR #&FF
\ADC #1

.SC48

 PHA                    ; sub result used as counter
 JSR CPIX4              ; big flag on stick, at (X1,Y1)
 LDA CTWOS+1,X          ; recall mask
 AND COL                ; the colour
 STA X1                 ; colour temp
 PLA                    ; sub result used as counter
 PLP                    ; sign info
 TAX                    ; sub result used as counter
 BEQ RTS                ; no stick height, rts
 BCC RTS+1              ; -ve stick length

.VLL1                   ; positive stick counter X.

 DEY                    ; Y was running through byte char in CPIX4
 BPL VL1                ; else reset Y to 7 for
 LDY #7                 ; next row
 DEC SC+1               ; screen hi

.VL1                    ; Y reset done

 LDA X1                 ; colour temp for stick
 EOR (SC),Y
 STA (SC),Y
 DEX                    ; next dot of stick up
 BNE VLL1               ; loop X

.RTS

 RTS

\.SCRTS+1               ; -ve stick length

 INY                    ; Y was running through byte char in CPIX4
 CPY #8                 ; hop reset
 BNE P%+6               ; Y continue
 LDY #0                 ; else reset for next row
 INC SC+1               ; screen hi

.VLL2                   ; Y continue, counter X

 INY                    ; Y was running through byte char in CPIX4
 CPY #8                 ; hop reset
 BNE VL2                ; same row
 LDY #0                 ; else reset for next row
 INC SC+1               ; screen hi

.VL2                    ; same row

 LDA X1                 ; colour temp for stick
 EOR (SC),Y
 STA (SC),Y
 INX                    ; next dot of stick down
 BNE VLL2               ; loop X
 RTS
}

\ ******************************************************************************
\ Subroutine: WSCAN
\
\ Wait for vertical sync to occur on the video system - in other words, wait
\ for the screen to start its refresh cycle, which it does 50 times a second
\ (50Hz).
\ ******************************************************************************

.WSCAN
{
 LDA #0                 ; Set DL to 0
 STA DL

 LDA DL                 ; Loop round these two instructions until DL is no
 BEQ P%-2               ; longer 0 (DL gets set to 30 in the LINSCN routine,
                        ; which is run when vertical sync has occurred on the
                        ; video system, so DL will change to a non-zero value
                        ; at the start of each screen refresh)

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Save output/ELTC.bin
\ ******************************************************************************

PRINT "ELITE C"
PRINT "Assembled at ", ~CODE_C%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_C%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_C%

PRINT "S.ELTC ", ~CODE_C%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_C%
SAVE "output/ELTC.bin", CODE_C%, P%, LOAD%

\ ******************************************************************************
\ ELITE D
\
\ Produces the binary file ELTD.bin which gets loaded by elite-bcfs.asm.
\ ******************************************************************************

CODE_D% = P%
LOAD_D% = LOAD% + P% - CODE%

\ ******************************************************************************
\ Subroutine: tnpr
\
\ Given a market item and an amount, work out whether there is room in the
\ cargo hold for this item.
\
\ For standard tonne canisters, the limit is given by the type of cargo hold we
\ have, with a standard cargo hold having a capacity of 20t and an extended
\ cargo bay being 35t.
\
\ For items measured in kg (gold, platinum), g (gem-stones) and alien items,
\ the individual limit on each of these is 200 units.
\
\ Arguments:
\
\   A           The number of units of this market item
\
\   QQ29        The type of market item (see QQ23 for a list of market item
\               numbers)
\
\ Returns:
\
\   A           A is preserved
\
\   C flag      Returns the result:
\
\                 * Set if there is no room for this item
\
\                 * Clear if there is room for this item
\ ******************************************************************************

.tnpr
{
 PHA                    ; Store A on the stack

 LDX #12                ; If QQ29 > 12 then jump to kg below, as this cargo
 CPX QQ29               ; type is gold, platinum, gem-stones or alien items,
 BCC kg                 ; and they have different cargo limits to the standard
                        ; tonne canisters

.Tml                    ; Here we count the tonne canisters we have in the hold
                        ; and add to A to see if we have enough room for A more
                        ; tonnes of cargo, using X as the loop counter, starting
                        ; with X = 12

 ADC QQ20,X             ; Set A = A + the number of tonnes we have in the hold
                        ; of market item number X. Note that the first time we
                        ; go round this loop, the C flag is set (as we didn't
                        ; branch with the BCC above, so the effect of this loop
                        ; is count the number of tonne canisters in the hold, and
                        ; add 1

 DEX                    ; Decrement the loop counter

 BPL Tml                ; Loop back to add in the next market item in the hold,
                        ; until we have added up all market items from 12
                        ; (minerals) down to 0 (food)

 CMP CRGO               ; If A < CRGO then the C flag will be clear (we have
                        ; room in the hold)
                        ;
                        ; If A >= CRGO then the C flag will be set (we do not
                        ; have room in the hold)
                        ;
                        ; This works because A contains the number of canisters
                        ; plus 1, while CRGO contains our cargo capacity plus 2,
                        ; so if we actually have "a" canisters and a capacity
                        ; of "c", then:
                        ;
                        ; A < CRGO means: a+1 <  c+2
                        ;                 a   <  c+1
                        ;                 a   <= c
                        ;
                        ; So this is why the value in CRGO is 2 higher than the
                        ; actual cargo bay size, i.e. it's 22 for the standard
                        ; 20-tonne bay, and 37 for the large 35-tonne bay

 PLA                    ; Restore A from the stack

 RTS                    ; Return from the subroutine

.kg                     ; Here we count the number of items of this type that
                        ; we already have in the hold, and add to A to see if
                        ; we have enough room for A more units

 LDY QQ29               ; Set Y to the item number we want to add

 ADC QQ20,Y             ; Set A = A + the number of units of this item that we
                        ; already have in the hold

 CMP #200               ; Is the result greater than 200 (the limit on
                        ; individual stocks of gold, platinum, gem-stones and
                        ; alien items)?
                        ;
                        ; If so, this sets the carry flag (no room)
                        ;
                        ; Otherwise it is clear (we have room)

 PLA                    ; Restore A from the stack

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: TT20
\
\ Twist the three 16-bit seeds in QQ15 (selected system) four times, to
\ generate the next system.
\ ******************************************************************************

.TT20
{
 JSR P%+3               ; This line calls the line below as a subroutine, which
                        ; does two twists before returning here, and then we
                        ; fall through to the line below for another two
                        ; twists, so the net effect of these two consecutive
                        ; JSR calls is four twists, not counting the ones
                        ; inside your head as you try to follow this process

 JSR P%+3               ; This line calls TT54 as a subroutine to do a twist,
                        ; and then falls through into TT54 to do another twist
                        ; before returning from the subroutine
}

\ ******************************************************************************
\ Subroutine: TT54
\
\ This routine twists the three 16-bit seeds in QQ15 once.
\
\ ******************************************************************************
\
\ Famously, the universe in Elite is generated procedurally, and the core of
\ this process is the set of three 16-bit seeds that describe each system in
\ the universe. Each of the eight galaxies in the game is generated in the same
\ way, by taking an initial set of seeds and "twisting" them to generate 256
\ systems, one after the other (the actual twisting process is described
\ below).
\
\ Specifically, given the initial set of seeds, we can generate the next system
\ in the sequence by twisting that system's seeds four times. As we do these
\ twists, we can extract the system's data from the seed values - including the
\ system name, which is generated by the subroutine cpl, where you can read
\ about how this aspect works.
\
\ It is therefore no exaggeration that the twisting process implemented below
\ is the fundamental building block of Elite's "universe in a bottle" approach,
\ which enabled the authors to squeeze eight galaxies of 256 planets out of
\ nothing more then three initial numbers and a short twisting routine (and
\ they could have had far larger galaxies and many more of them, if they had
\ wanted, but they made the wise decision to limit the number). Let's look at
\ how this twisting proces works.
\
\ The three seeds that describe a system represent three consecutive numbers in
\ a Tribonacci sequence, where each number is equal to the sum of the preceding
\ three numbers (the name is a play on Fibonacci sequence, in which each number
\ is equal to the sum of the preceding two numbers). Twisting is the process of
\ moving along the sequence by one place. So, say our seeds currently point to
\ these numbers in the sequence:
\
\   0   0   1   1   2   4   7   13   24   44   ...
\                       ^   ^    ^
\
\ so they are 4, 7 and 13, then twisting would move them all along by one
\ place, like this:
\
\   0   0   1   1   2   4   7   13   24   44   ...
\                           ^    ^    ^
\
\ giving us 7, 13 and 24. To generalise this, if we start with seeds w0, w1
\ and w2 and we want to work out their new values after we perform a twist
\ (let's call the new values x0, x1 and x2), then:
\
\   x0 = w1
\   x1 = w2
\   x2 = w0 + w1 + w2
\ 
\ So given an existing set of seeds in w0, w1 and w2, we can get the new values
\ x0, x1 and x2 simply by doing the above sums. And if we want to do the above
\ in-place without creating three new x variables, then we can do the
\ following:
\
\   tmp = w0 + w1
\   w0 = w1
\   w1 = w2
\   w2 = tmp + w1
\
\ In Elite, the numbers we're dealing with are two-byte, 16-bit numbers, and
\ because these 16-bit numbers can only hold values up to 65535, the sequence
\ wraps around at the end. But the maths is the same, it just has to be done
\ on 16-bit numbers, one byte at a time.
\
\ The seeds are stored as little-endian 16-bit numbers, so the low (least
\ significant) byte is first, followed by the high (most significant) byte.
\ Taking the case of the currently selected system, whose seeds are stored
\ in the six bytes from QQ15, that means our seed values are stored like this:
\
\       low byte  high byte
\   w0  QQ15      QQ15+1
\   w1  QQ15+2    QQ15+3
\   w2  QQ15+4    QQ15+5
\
\ If we denote the low byte of w0 as w0_lo and the high byte as w0_hi, then
\ the twist operation above can be rewritten for 16-bit values like this,
\ assuming the additions include the carry flag:
\ 
\   tmp_lo = w0_lo + w1_lo          ; tmp = w0 + w1
\   tmp_hi = w0_hi + w1_hi
\   w0_lo  = w1_lo                  ; w0 = w1
\   w0_hi  = w1_hi
\   w1_lo  = w2_lo                  ; w1 = w2
\   w1_hi  = w2_hi
\   w2_lo  = tmp_lo + w1_lo         ; w2 = tmp + w1
\   w2_hi  = tmp_hi + w1_hi
\
\ And that's exactly what this subroutine does to twist our three 16-bit
\ seeds to the next values in the sequence, using X to store tmp_lo and Y to
\ store tmp_hi.
\ ******************************************************************************

.TT54
{
 LDA QQ15               ; X = tmp_lo = w0_lo + w1_lo
 CLC
 ADC QQ15+2
 TAX

 LDA QQ15+1             ; Y = tmp_hi = w1_hi + w1_hi + carry
 ADC QQ15+3
 TAY

 LDA QQ15+2             ; w0_lo = w1_lo
 STA QQ15
 
 LDA QQ15+3             ; w0_hi = w1_hi
 STA QQ15+1
 
 LDA QQ15+5             ; w1_hi = w2_hi
 STA QQ15+3
 
 LDA QQ15+4             ; w1_lo = w2_lo
 STA QQ15+2
 
 CLC                    ; w2_lo = X + w1_lo
 TXA
 ADC QQ15+2
 STA QQ15+4

 TYA                    ; w2_hi = Y + w1_hi + carry
 ADC QQ15+3
 STA QQ15+5

 RTS                    ; The twist is complete so return from the subroutine
}

\ ******************************************************************************
\ Subroutine: TT146
\
\ Print the distance to the selected system in light years, if non-zero. If
\ zero, just move the text cursor down a line.
\
\ Specifically, if the distance in QQ8 is non-zero, print token 31 ("DISTANCE"),
\ then a colon, then the distance to one decimal place, then token 35 ("LIGHT
\ YEARS"). If the distance is zero, move the cursor down one line.
\ ******************************************************************************

.TT146
{
 LDA QQ8                ; Take the two bytes of the 16-bit value in QQ8 and
 ORA QQ8+1              ; OR them together to check whether there are any
 BNE TT63               ; non-zero bits, and if so, jump to TT63 to print the
                        ; distance

 INC YC                 ; The distance is zero, so we just move the text cursor
 RTS                    ; in YC down by one line and return from the subroutine

.TT63

 LDA #191               ; Print recursive token 31 ("DISTANCE") followed by
 JSR TT68               ; a colon

 LDX QQ8                ; Load (Y X) from QQ8, which contains the 16-bit
 LDY QQ8+1              ; distance we want to show

 SEC                    ; Set the carry flag so that the call to pr5 will
                        ; include a decimal point, and display the value as
                        ; (Y X) / 10

 JSR pr5                ; Print (Y X) to 5 digits, including a decimal point

 LDA #195               ; Set A to the recursive token 35 (" LIGHT YEARS") and
                        ; fall through into TT60 to print the token followed
                        ; by a paragraph break
}

\ ******************************************************************************
\ Subroutine: TT60
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token). Then print a paragraph break (a blank line between
\ paragraphs) by moving the cursor down a line, setting Sentence Case, and then
\ printing a newline.
\
\ Arguments:
\
\   A           The text token to be printed
\ ******************************************************************************

.TT60
{
 JSR TT27               ; Print the text token in A and fall through into TTX69
                        ; to print the paragraph break
}

\ ******************************************************************************
\ Subroutine: TTX69
\
\ Print a paragraph break (a blank line between paragraphs) by moving the cursor
\ down a line, setting Sentence Case, and then printing a newline.
\ ******************************************************************************

.TTX69
{
 INC YC                 ; Move the text cursor down a line and then fall
                        ; through into TT69 to set Sentence Case and print a
                        ; newline
}

\ ******************************************************************************
\ Subroutine: TT69
\
\ Set Sentence Case and print a newline.
\ ******************************************************************************

.TT69
{
 LDA #128               ; Set QQ17 to 128, which denotes Sentence Case, and
 STA QQ17               ; fall througn into TT67 to print a newline
}

\ ******************************************************************************
\ Subroutine: TT67
\
\ Print a newline.
\ ******************************************************************************

.TT67
{
 LDA #13                ; Load a newline character into A

 JMP TT27               ; Print the text token in A and return from the
                        ; subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: TT70
\
\ Display "MAINLY " and jump to TT72. This subroutine is called by TT25 when
\ displaying a system's economy.
\ ******************************************************************************

.TT70
{
 LDA #173               ; Print recursive token 13 ("MAINLY ")
 JSR TT27

 JMP TT72               ; Jump to TT72 to continue printing system data as part
                        ; of routine TT25
}

\ ******************************************************************************
\ Subroutine: spc
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token) followed by a space.
\
\ Arguments:
\
\   A           The text token to be printed
\ ******************************************************************************

.spc
{
 JSR TT27               ; Print the text token in A

 JMP TT162              ; Print a space and return from the subroutine using a
                        ; tail call
}

\ ******************************************************************************
\ Subroutine: TT25
\
\ Other entry points: TT72
\
\ Show the Data on System screen (red key f6).
\
\ ******************************************************************************
\
\ Although most system data is calculated in TT24 below and stored in locations
\ QQ3 to QQ7, the species type and average radius are not. Here's how they are
\ calculated.
\
\ Species type
\ ------------
\ The species type is either Human Colonials, or it's an alien species that
\ consists of up to three adjectives and a species name (so you can get
\ anything from "Rodents" and "Fierce Frogs" to "Black Fat Felines" and "Small
\ Yellow Bony Lobsters").
\ 
\ As with the rest of the system data, the species is built from various bits
\ in the seeds. Specifically, all the bits in w2_hi are used, along with bits
\ 0-2 of w0_hi and w1_hi, and bit 7 of w2_lo.
\ 
\ First, we check bit 7 of w2_lo. It it is clear, print "Human Colonials" and
\ stop, otherwise this is an alien species, so we move onto the following
\ steps. (In the following steps, the potential range of the calculated value
\ of A is 0-7, and if a match isn't made, nothing is printed for that step.)
\ 
\   1. Set A = bits 2-4 of w2_hi
\ 
\     * If A = 0,  print "Large "
\     * If A = 1,  print "Fierce "
\     * If A = 2,  print "Small "
\ 
\   2. Set A = bits 5-7 of w2_hi
\ 
\     * If A = 0,  print "Green "
\     * If A = 1,  print "Red "
\     * If A = 2,  print "Yellow "
\     * If A = 3,  print "Blue "
\     * If A = 4,  print "Black "
\     * If A = 5,  print "Harmless "
\ 
\   3. Set A = bits 0-2 of (w0_hi EOR w1_hi)
\ 
\     * If A = 0,  print "Slimy "
\     * If A = 1,  print "Bug-Eyed "
\     * If A = 2,  print "Horned "
\     * If A = 3,  print "Bony "
\     * If A = 4,  print "Fat "
\     * If A = 5,  print "Furry "
\ 
\   4. Add bits 0-1 of w2_hi to A from step 3, and take bits 0-2 of the result
\ 
\     * If A = 0,  print "Rodents"
\     * If A = 1,  print "Frogs"
\     * If A = 2,  print "Lizards"
\     * If A = 3,  print "Lobsters"
\     * If A = 4,  print "Birds"
\     * If A = 5,  print "Humanoids"
\     * If A = 6,  print "Felines"
\     * If A = 7,  print "Insects"
\ 
\ So if we print an adjective at step 3, then the only options for the species
\ name are from A to A + 3 (because we add a 2-bit number) in step 4. So only
\ certain combinations are possible:
\ 
\   * Only rodents, frogs, lizards and lobsters can be slimy
\   * Only frogs, lizards, lobsters and birds can be bug-eyed
\   * Only lizards, lobsters, birds and humanoids can be horned
\   * Only lobsters, birds, humanoids and felines can be bony
\   * Only birds, humanoids, felines and insects can be fat
\   * Only humanoids, felines, insects and rodents can be furry
\ 
\ So however hard you look, you will never find slimy humanoids, bony insects,
\ fat rodents or furry frogs, which is probably for the best.
\
\ Average radius
\ --------------
\ The average radius is calculated as follows:
\ 
\   ((w2_hi AND %1111) + 11) * 256 + w1_hi
\ 
\ The highest average radius is (15 + 11) * 256 + 255 = 6911 km, and the lowest
\ is 11 * 256 = 2816 km.
\ ******************************************************************************

.TT25
{
 JSR TT66-2             ; Clear the top part of the screen, draw a box border,
                        ; and set the current view type in QQ11 to 1

 LDA #9                 ; Set the text cursor XC to column 9
 STA XC

 LDA #163               ; Print recursive token 3 as a title in capitals at
 JSR TT27               ; the top ("DATA ON {selected system name}")

 JSR NLIN               ; Draw a horizontal line underneath the title

 JSR TTX69              ; Print a paragraph break and set Sentence Case

 INC YC                 ; Move the text cursor down one more line

 JSR TT146              ; If the distance to this system is non-zero, print
                        ; "DISTANCE", then the distance, "LIGHT YEARS" and a
                        ; paragraph break, otherwise just move the cursor down
                        ; a line

 LDA #194               ; Print recursive token 34 ("ECONOMY") followed by
 JSR TT68               ; a colon

 LDA QQ3                ; The system economy is determined by the value in QQ3,
                        ; so fetch it into A. First we work out the system's
                        ; prosperity as follows:
                        ;
                        ;   QQ3 = 0 or 5 = %000 or %101 = Rich
                        ;   QQ3 = 1 or 6 = %001 or %110 = Average
                        ;   QQ3 = 2 or 7 = %010 or %111 = Poor
                        ;   QQ3 = 3 or 4 = %011 or %100 = Mainly

 CLC                    ; If (QQ3 + 1) >> 1 = %10, i.e. if QQ3 = %011 or %100
 ADC #1                 ; (3 or 4), then call TT70, which prints "MAINLY " and
 LSR A                  ; jumps down to TT72 to print the type of economy
 CMP #%00000010
 BEQ TT70
 
 LDA QQ3                ; The LSR A above shifted bit 0 of QQ3 into the carry
 BCC TT71               ; flag, so this jumps to TT71 if bit 0 of QQ3 is 0,
                        ; i.e. if QQ3 = %000, %001 or %010 (0, 1 or 2)

 SBC #5                 ; Here QQ3 = %101, %110 or %111 (5, 6 or 7), so
 CLC                    ; subtract 5 to bring it down to 0, 1 or 2 (the carry
                        ; flag is already set so the SBC will be correct)

.TT71

 ADC #170               ; A is now 0, 1 or 2, so print recursive token 10 + A.
 JSR TT27               ; This means that:
                        ;
                        ;   QQ3 = 0 or 5 prints token 10 ("RICH ")
                        ;   QQ3 = 1 or 6 prints token 11 ("AVERAGE ")
                        ;   QQ3 = 2 or 7 prints token 12 ("POOR ")

.^TT72

 LDA QQ3                ; Now to work out the type of economy, which is
 LSR A                  ; determined by bit 2 of QQ3, as follows:
 LSR A                  ;
                        ;   QQ3 bit 2 = 0 = Industrial
                        ;   QQ3 bit 2 = 1 = Agricultural
                        ;
                        ; So we fetch QQ3 into A and set A = bit 2 of QQ3 using
                        ; two right shifts (which will work as QQ3 is only a
                        ; 3-bit number)

 CLC                    ; Print recursive token 8 + A, followed by a paragraph
 ADC #168               ; break and Sentence Case, so:
 JSR TT60               ;
                        ;   QQ3 bit 2 = 0 prints token 8 ("INDUSTRIAL")
                        ;   QQ3 bit 2 = 1 prints token 9 ("AGRICULTURAL")

 LDA #162               ; Print recursive token 2 ("GOVERNMENT") followed by
 JSR TT68               ; a colon

 LDA QQ4                ; The system economy is determined by the value in QQ4,
                        ; so fetch it into A

 CLC                    ; Print recursive token 17 + A, followed by a paragraph
 ADC #177               ; break and Sentence Case, so:
 JSR TT60               ;
                        ;   QQ4 = 0 prints token 17 ("ANARCHY")
                        ;   QQ4 = 1 prints token 18 ("FEUDAL")
                        ;   QQ4 = 2 prints token 19 ("MULTI-GOVERNMENT")
                        ;   QQ4 = 3 prints token 20 ("DICTATORSHIP")
                        ;   QQ4 = 4 prints token 21 ("COMMUNIST")
                        ;   QQ4 = 5 prints token 22 ("CONFEDERACY")
                        ;   QQ4 = 6 prints token 23 ("DEMOCRACY")
                        ;   QQ4 = 7 prints token 24 ("CORPORATE STATE")

 LDA #196               ; Print recursive token 36 ("TECH.LEVEL") followed by a
 JSR TT68               ; colon

 LDX QQ5                ; Fetch the tech level from QQ5 and increment it, as it
 INX                    ; is stored in the range 0-14 but the displayed range
                        ; should be 1-15

 CLC                    ; Call pr2 to print the technology level as a 3-digit
 JSR pr2                ; number without a decimal point (by clearing the carry
                        ; flag)

 JSR TTX69              ; Print a paragraph break and set Sentence Case

 LDA #192               ; Print recursive token 32 ("POPULATION") followed by a
 JSR TT68               ; colon

 SEC                    ; Call pr2 to print the population as a 3-digit number
 LDX QQ6                ; with a decimal point (by setting the carry flag), so
 JSR pr2                ; the number printed will be population / 10

 LDA #198               ; Print recursive token 38 (" BILLION"), followed by a
 JSR TT60               ; paragraph break and Sentence Case

 LDA #'('               ; Print an opening bracket
 JSR TT27

 LDA QQ15+4             ; Now to calculate the species, so first check bit 7 of
 BMI TT75               ; w2_lo, and if it is set, jump to TT75 as this is an
                        ; alien species

 LDA #188               ; Bit 7 of w2_lo is clear, so print recursive token 28
 JSR TT27               ; ("HUMAN COLONIAL")

 JMP TT76               ; Jump to TT76 to print "S)" and a paragraph break, so
                        ; the whole species string is "(HUMAN COLONIALS)"

.TT75

 LDA QQ15+5             ; This is an alien species, and we start with the first
 LSR A                  ; adjective, so fetch bits 2-7 of w2_hi into A and push
 LSR A                  ; onto the stack so we can use this later
 PHA

 AND #7                 ; Set A = bits 0-2 of A (so that's bits 2-4 of w2_hi)

 CMP #3                 ; If A >= 3, jump to TT205 to skip the first adjective,
 BCS TT205

 ADC #227               ; Otherwise A = 0, 1 or 2, so print recursive token
 JSR spc                ; 67 + A, followed by a space, so:
                        ;
                        ;   A = 0 prints token 67 ("LARGE") and a space
                        ;   A = 1 prints token 67 ("FIERCE") and a space
                        ;   A = 2 prints token 67 ("SMALL") and a space

.TT205

 PLA                    ; Now for the second adjective, so restore A to bits
 LSR A                  ; 2-7 of w2_hi, and throw away bits 2-4 to leave
 LSR A                  ; A = bits 5-7 of w2_hi
 LSR A

 CMP #6                 ; If A >= 6, jump to TT206 to skip the second adjective
 BCS TT206

 ADC #230               ; Otherwise A = 0 to 5, so print recursive token
 JSR spc                ; 70 + A, followed by a space, so:
                        ;
                        ;   A = 0 prints token 70 ("GREEN") and a space
                        ;   A = 1 prints token 71 ("RED") and a space
                        ;   A = 2 prints token 72 ("YELLOW") and a space
                        ;   A = 3 prints token 73 ("BLUE") and a space
                        ;   A = 4 prints token 74 ("BLACK") and a space
                        ;   A = 5 prints token 75 ("HARMLESS") and a space

.TT206

 LDA QQ15+3             ; Now for the third adjective, so EOR the high bytes of
 EOR QQ15+1             ; w0 and w1 and extract bits 0-2 of the result:
 AND #%00000111         ;
 STA QQ19               ;   A = (w0_hi EOR w1_hi) AND %111
                        ;
                        ; storing the result in QQ19 so we can use it later

 CMP #6                 ; If A >= 6, jump to TT207 to skip the third adjective
 BCS TT207

 ADC #236               ; Otherwise A = 0 to 5, so print recursive token
 JSR spc                ; 76 + A, followed by a space, so:
                        ;
                        ;   A = 0 prints token 76 ("SLIMY") and a space
                        ;   A = 1 prints token 77 ("BUG-EYED") and a space
                        ;   A = 2 prints token 78 ("HORNED") and a space
                        ;   A = 3 prints token 79 ("BONY") and a space
                        ;   A = 4 prints token 80 ("FAT") and a space
                        ;   A = 5 prints token 81 ("FURRY") and a space

.TT207

 LDA QQ15+5             ; Now for the actual species, so take bits 0-1 of
 AND #3                 ; w2_hi, add this to the value of A that we used for
 CLC                    ; the third adjective, and take bits 0-2 of the result
 ADC QQ19
 AND #7

 ADC #242               ; A = 0 to 7, so print recursive token 82 + A, so:
 JSR TT27               ;
                        ;   A = 0 prints token 76 ("RODENT")
                        ;   A = 1 prints token 76 ("FROG")
                        ;   A = 2 prints token 76 ("LIZARD")
                        ;   A = 3 prints token 76 ("LOBSTER")
                        ;   A = 4 prints token 76 ("BIRD")
                        ;   A = 5 prints token 76 ("HUMANOID")
                        ;   A = 6 prints token 76 ("FELINE")
                        ;   A = 7 prints token 76 ("INSECT")

.TT76

 LDA #'S'               ; Print an "S" to pluralise the species
 JSR TT27

 LDA #')'               ; And finally, print a closing bracket, followed by a
 JSR TT60               ; paragraph break and Sentence Case, to end the species
                        ; section

 LDA #193               ; Print recursive token 33 ("GROSS PRODUCTIVITY"),
 JSR TT68               ; followed by colon

 LDX QQ7                ; Fetch the 16-bit productivity value from QQ7 into
 LDY QQ7+1              ; (Y X)

 JSR pr6                ; Print (Y X) to 5 digits with no decimal point

 JSR TT162              ; Print a space

 LDA #0                 ; Set QQ17 = 0 for ALL CAPS
 STA QQ17

 LDA #'M'               ; Print "M"
 JSR TT27

 LDA #226               ; Print recursive token 66 (" CR"), followed by a
 JSR TT60               ; paragraph break and Sentence Case

 LDA #250               ; Print recursive token 90 ("AVERAGE RADIUS"), followed
 JSR TT68               ; by a colon

                        ; The average radius is calculated like this:
                        ;
                        ;   ((w2_hi AND %1111) + 11) * 256 + w1_hi
                        ;
                        ; or, in terms of memory locations:
                        ;
                        ;   ((QQ15+5 AND %1111) + 11) * 256 + QQ15+3
                        ;
                        ; Because the multiplication is by 256, this is the
                        ; same as saying a 16-bit number, with high byte:
                        ;
                        ;   (QQ15+5 AND %1111) + 11
                        ;
                        ; and low byte:
                        ;
                        ;   QQ15+3
                        ;
                        ; so we can set this up in (Y X) and call the pr5
                        ; routine to print it out.

 LDA QQ15+5             ; Set A = QQ15+5
 LDX QQ15+3             ; Set X = QQ15+3

 AND #%00001111         ; Set Y = (A AND %1111) + 11
 CLC
 ADC #11
 TAY

 JSR pr5                ; Print (Y X) to 5 digits, not including a decimal
                        ; point, as the carry flag will be clear (as the
                        ; maximum radius will always fit into 16 bits)

 JSR TT162              ; Print a space

 LDA #'k'               ; Print "km", returning from the subroutine using a
 JSR TT26               ; tail call
 LDA #'m'
 JMP TT26
}

\ ******************************************************************************
\ Subroutine: TT24
\
\ Calculate system data from the seeds in QQ15 and store them in the relevant
\ locations. Specifically, this routine calculates the following from the three
\ 16-bit seeds in QQ15 (using only w0_hi, w1_hi and w1_lo):
\
\   QQ3 = economy (0-7)
\   QQ4 = government (0-7)
\   QQ5 = technology level (0-14)
\   QQ6 = population * 10 (1-71)
\   QQ7 = productivity (96-62480)
\
\ The ranges of the various values are shown in brackets. Note that the radius
\ and type of inhabitant are calculated on-the-fly in the TT25 routine when
\ the system data gets displayed, so they aren't calculated here.
\
\ ******************************************************************************
\
\ The above system statistics are generated from the system seeds, specifically
\ from parts of w0_hi, w1_hi and w1_lo. Here's how it all works.
\ 
\ Government
\ ----------
\ The government is given by a 3-bit value, taken from bits 3-5 of w1_lo. This
\ value determine the type of government as follows:
\ 
\   0 = Anarchy
\   1 = Feudal
\   2 = Multi-government
\   3 = Dictatorship
\   4 = Communist
\   5 = Confederacy
\   6 = Democracy
\   7 = Corporate State
\ 
\ The highest government value is 7 and the lowest is 0.
\
\ Economy
\ -------
\ The economy is given by a 3-bit value, taken from bits 0-2 of w0_hi. This
\ value determine the prosperity of the economy:
\ 
\   0 or 5 = %000 or %101 = Rich
\   1 or 6 = %001 or %110 = Average
\   2 or 7 = %010 or %111 = Poor
\   3 or 4 = %011 or %100 = Mainly
\ 
\ while bit 2 determines the type of economy:
\ 
\   bit 2 = %0 = Industrial
\   bit 2 = %1 = Agricultural
\
\ Putting these two together, we get:
\
\   0 = Rich Industrial
\   1 = Average Industrial
\   2 = Poor Industrial
\   3 = Mainly Industrial
\   4 = Mainly Agricultural
\   5 = Rich Agricultural
\   6 = Average Agricultural
\   7 = Poor Agricultural
\ 
\ If the government is an anarchy or feudal state, we need to fix the economy
\ so it can't be rich (as that wouldn't make sense). We do this by setting bit
\ 1 of the economy value, giving possible values of %010, %011, %110, %111.
\ Looking at the prosperity list above, we can see this forces the economy to
\ be poor, mainly, average, or poor respectively, so there's now a 50% chance
\ of the system being poor, a 25% chance of it being average, and a 25% chance
\ of it being "Mainly Agricultural" or "Mainly Industrial".
\ 
\ The highest economy value is 7 and the lowest is 0.
\ 
\ Technology level
\ ----------------
\ The tech level is calculated as follows:
\ 
\   flipped economy + (w1_hi AND %11) + (government / 2)
\ 
\ where "flipped economy" is the economy value with its bits inverted (keeping
\ it as a 3-bit value, so if the economy is %001, the flipped economy is %110).
\ The division is done using LSR and the addition uses ADC, so this rounds up
\ the division for odd-numbered government types.
\ 
\ Flipping the three economy bits gives the following spread of numbers:
\ 
\   7 or 2 = %111 or %010 = Rich
\   6 or 1 = %110 or %001 = Average
\   5 or 0 = %101 or %000 = Poor
\   4 or 3 = %100 or %011 = Mainly
\ 
\ This, on average, gives a higher number to rich states compared with poor
\ states, as well as giving higher values to industrial economies compared to
\ agricultural, all of which makes a reasonable basis for a measurement of
\ technology level.
\ 
\ The highest tech level is 7 + 3 + (7 / 2) = 14 (when rounded up) and the
\ lowest is 0.
\ 
\ Population
\ ----------
\ The population is calculated as follows:
\ 
\   (tech level * 4) + economy + government + 1
\ 
\ This means that systems with higher tech levels, better economies and more
\ stable governments have higher populations, with the tech level having the
\ most influence. The number stored is actually the population * 10 (in
\ billions), so we can display it to one decimal place by calling the pr2
\ subroutine (so if the population value is 52, it means 5.2 billion).
\ 
\ The highest population is 14 * 4 + 7 + 7 + 1 = 71 (7.1 billion) and the
\ lowest is 1 (0.1 billion).
\ 
\ Productivity
\ ------------
\ The productivity is calculated as follows:
\ 
\   (flipped economy + 3) * (government + 4) * population * 8
\ 
\ Productivity is measured in millions of credits, so a productivity of 23740
\ would be displayed as "23740 M CR".
\ 
\ The highest productivity is 10 * 11 * 71 * 8 = 62480, while the lowest is 3 *
\ 4 * 1 * 8 = 96 (so the range is between 96 and 62480 million credits).
\ ******************************************************************************

.TT24
{
 LDA QQ15+1             ; Fetch w0_hi and extract bits 0-2 to determine the
 AND #%00000111         ; system's economy, and store in QQ3
 STA QQ3
 
 LDA QQ15+2             ; Fetch w1_lo and extract bits 3-5 to determine the
 LSR A                  ; system's government, and store in QQ4
 LSR A
 LSR A
 AND #%00000111
 STA QQ4
 
 LSR A                  ; If government isn't anarchy or feudal, skip to TT77,
 BNE TT77               ; as we need to fix the economy of anarchy and feudal
                        ; systems so they can't be rich

 LDA QQ3                ; Set bit 1 of the economy in QQ3 to fix the economy
 ORA #%00000010         ; for anarchy and feudal governments
 STA QQ3

.TT77

 LDA QQ3                ; Now to work out the tech level, which we do like this:
 EOR #%00000111         ; 
 CLC                    ;   flipped economy + (w1_hi AND %11) + (government / 2)
 STA QQ5                ;
                        ; or, in terms of memory locations:
                        ;
                        ;   QQ5 = (QQ3 EOR %111) + (QQ15+3 AND %11) + (QQ4 / 2)
                        ;
                        ; We start by setting QQ5 = QQ3 EOR %111

 LDA QQ15+3             ; We then take the first 2 bits of w1_hi (QQ15+3) and
 AND #%00000011         ; add it into QQ5
 ADC QQ5
 STA QQ5

 LDA QQ4                ; And finally we add QQ4 / 2 and store the result in
 LSR A                  ; QQ5, using LSR then ADC to divide by 2, which rounds
 ADC QQ5                ; up the result for odd-numbered government types
 STA QQ5 
 
 ASL A                  ; Now to work out the population, like so:
 ASL A                  ;
 ADC QQ3                ;   (tech level * 4) + economy + government + 1
 ADC QQ4                ;
 ADC #1                 ; or, in terms of memory locations:
 STA QQ6                ;
                        ;   QQ6 = (QQ5 * 4) + QQ3 + QQ4 + 1

 LDA QQ3                ; Finally, we work out productivity, like this:
 EOR #%00000111         ;
 ADC #3                 ;  (flipped economy + 3) * (government + 4)
 STA P                  ;                        * population
 LDA QQ4                ;                        * 8
 ADC #4                 ;
 STA Q                  ; or, in terms of memory locations:
 JSR MULTU              ;
                        ;   QQ7 = (QQ3 EOR %111 + 3) * (QQ4 + 4) * QQ6 * 8
                        ;
                        ; We do the first step by setting P to the first
                        ; expression in brackets and Q to the second, and
                        ; calling MULTU, so now (A P) = P * Q. The highest this
                        ; can be is 10 * 11 (as the maximum values of economy
                        ; and government are 7), so the high byte of the result
                        ; will always be 0, so we actually have:
                        ;
                        ;   P = P * Q
                        ;     = (flipped economy + 3) * (government + 4)

 LDA QQ6                ; We now take the result in P and multiply by the
 STA Q                  ; population to get the productivity, by setting Q to
 JSR MULTU              ; the population from QQ6 and calling MULTU again, so
                        ; now we have:
                        ;
                        ;   (A P) = P * population

 ASL P                  ; Next we multiply the result by 8, as a 16-bit number,
 ROL A                  ; so we shift both bytes to the left three times,
 ASL P                  ; using the carry flag to carry bits from bit 7 of the
 ROL A                  ; low byte into bit 0 of the high byte
 ASL P
 ROL A

 STA QQ7+1              ; Finally, we store the productivity in two bytes, with
 LDA P                  ; the low byte in QQ7 and the high byte in QQ7+1
 STA QQ7

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: TT22
\
\ Show the Long-range Chart (red key f4).
\ ******************************************************************************

.TT22
{
 LDA #64                ; Clear the top part of the screen, draw a box border,
 JSR TT66               ; and set the current view type in QQ11 to 32 (Long-
                        ; range Chart)

 LDA #7                 ; Move the text cursor to column 7
 STA XC

 JSR TT81               ; Set the seeds in QQ15 to those of the current system
                        ; (i.e. copy the seeds from QQ21 to QQ15)

 LDA #199               ; Print recursive token 39 ("GALACTIC CHART{galaxy
 JSR TT27               ; number right-aligned to width 3}")

 JSR NLIN               ; Draw a horizontal line at pixel row 23 to box in the
                        ; title and act as the top frame of the chart, and move
                        ; the text cursor down one line

 LDA #152               ; Draw a screen-wide horizontal line at pixel row 152
 JSR NLIN2              ; for the bottom edge of the chart, so the chart itself
                        ; is 128 pixels high, starting on row 24 and ending on
                        ; row 151

 JSR TT14               ; Call TT14 to draw a circle with a cross-hair at the
                        ; current system's galactic coordinates

 LDX #0                 ; We're now going to plot each of the galaxy's systems,
                        ; so set up a counter in X for each system, starting at
                        ; 0 and looping through to 255

.TT83

 STX XSAV               ; Store the counter in XSAV

 LDX QQ15+3             ; Fetch the w1_hi seed into X, which gives us the
                        ; galactic x-coordinate of this system

 LDY QQ15+4             ; Fetch the w2_lo seed and clear all the bits apart
 TYA                    ; from bits 4 and 6, storing the result in ZZ to give a
 ORA #%01010000         ; random number out of 0, &10, &40 or &50 (but which 
 STA ZZ                 ; will always be the same for this system). We use this
                        ; valueto determine the size of the point for this
                        ; system on the chart by passing it as the distance
                        ; argument to the PIXEL routine below

 LDA QQ15+1             ; Fetch the w0_hi seed into A, which gives us the
                        ; galactic y-coordinate of this system

 LSR A                  ; We halve the y-coordinate because the galaxy in
                        ; in Elite is rectangular rather than square, and is
                        ; twice as wide (x-axis) as it is high (y-axis), so the
                        ; chart is 256 pixels wide and 128 high
 
 CLC                    ; Add 24 to the halved y-coordinate and store in XX15+1
 ADC #24                ; (as the top of the chart is on pixel row 24, just
 STA XX15+1             ; below the line we drew on row 23 above)

 JSR PIXEL              ; Call PIXEL to draw a point at (X, A), with the size of
                        ; the point dependent on the distance specified in ZZ
                        ; (so a high value of ZZ will produce a 1-pixel point,
                        ; a medium value will produce a 2-pixel dash, and a
                        ; small value will produce a 4-pixel square)

 JSR TT20               ; We want to move on to the next system, so call TT20
                        ; to twist the three 16-bit seeds in QQ15

 LDX XSAV               ; Restore the loop counter from XSAV

 INX                    ; Increment the counter

 BNE TT83               ; If X > 0 then we haven't done all 256 systems yet, so
                        ; loop back up to TT83

 LDA QQ9                ; Set QQ19 to the target system's x-coordinate
 STA QQ19

 LDA QQ10               ; Set QQ19+1 to the target system's y-coordinate,
 LSR A                  ; halved to fit it into the chart
 STA QQ19+1

 LDA #4                 ; Set QQ19+2 to 4 and fall through into TT15 to draw a
 STA QQ19+2             ; cross-hair of size 4 at the target system
}

\ ******************************************************************************
\ Subroutine: TT15
\
\ Cross hair using QQ19(0to2) for laser or chart
\ ******************************************************************************

.TT15                   ; cross hair using QQ19(0to2) for laser or chart
{
 LDA #24                ; default cross size
 LDX QQ11               ; menu i.d.
 BPL P%+4               ; if bit7 clear hop over lda #0
 LDA #0                 ; else Short range chart
 STA QQ19+5             ; Ycross could be #24
 LDA QQ19               ; Xorg
 SEC
 SBC QQ19+2             ; cross-hair size
 BCS TT84               ; Xorg-cross-hair ok
 LDA #0

.TT84                   ; Xorg-cross-hair ok

 STA XX15               ; left
 LDA QQ19               ; Xorg
 CLC                    ; Xorg+cross-hair size
 ADC QQ19+2
 BCC P%+4               ; no X overflow
 LDA #&FF               ; else right edge
 STA XX15+2

 LDA QQ19+1
 CLC                    ; Yorg + Ycross
 ADC QQ19+5             ; could be #24
 STA XX15+1             ; Yorg + Ycross
 JSR HLOIN              ; horizontal line  X1,Y1,X2  Yreg protected.
 LDA QQ19+1
 SEC                    ; Yorg - cross-hair size
 SBC QQ19+2
 BCS TT86               ; Yorg-cross-hair ok
 LDA #0

.TT86                   ; Yorg-cross-hair ok

 CLC
 ADC QQ19+5             ; could be #24
 STA XX15+1             ; the top-most extent
 LDA QQ19+1             ; Yorg
 CLC
 ADC QQ19+2             ; cross-hair size
 ADC QQ19+5             ; could be #24
 CMP #152               ; Ytop
 BCC TT87               ; Yscreen sum ok

 LDX QQ11               ; menu id = short range chart?
 BMI TT87               ; Yscreen sum ok
 LDA #151               ; else ymax

.TT87                   ; Yscreen sum ok

 STA XX15+3             ; Y cross top
 LDA QQ19               ; Xorg
 STA XX15               ; X1
 STA XX15+2             ; X2
 JMP LL30               ; draw vertical line using (X1,Y1), (X2,Y2)
}

.TT126                  ; default  Circle with a cross-hair
{
 LDA #104               ; Xorg
 STA QQ19
 LDA #90                ; Yorg
 STA QQ19+1
 LDA #16                ; cross-hair size
 STA QQ19+2
 JSR TT15               ; the cross hair using QQ19(0to2)
 LDA QQ14               ; ship fuel #70 = #&46
 STA K                  ; radius
 JMP TT128              ; below. QQ19(0,1) and K for Circle
}

\ ******************************************************************************
\ Subroutine: TT14
\
\ Draw a circle with a cross-hair at the current system's galactic coordinates.
\ ******************************************************************************

.TT14                   ; Crcl/+ \ their comment \ Circle with a cross hair
{
 LDA QQ11               ; menu i.d.
 BMI TT126              ; if bit7 set up, Short range chart default.
 LDA QQ14               ; else ship fuel #70 = #&46
 LSR A                  ; Long range chart uses
 LSR A                  ; /=4
 STA K                  ; radius
 LDA QQ0                ; present X
 STA QQ19               ; Xorg
 LDA QQ1                ; present Y
 LSR A                  ; Y /=2
 STA QQ19+1             ; Yorg
 LDA #7                 ; cross-hair size
 STA QQ19+2
 JSR TT15               ; present cross hair using QQ19
 LDA QQ19+1             ; Yorg
 CLC
 ADC #24
 STA QQ19+1             ; Ytop
}

\ ******************************************************************************
\ Subroutine: TT128
\
\ QQ19(0,1) and K for circle
\ ******************************************************************************

.TT128                  ; QQ19(0,1) and K for circle
{
 LDA QQ19
 STA K3                 ; Xorg
 LDA QQ19+1
 STA K4                 ; Yorg
 LDX #0                 ; hi
 STX K4+1
 STX K3+1
\STX
\LSX
 INX                    ; step size for circle = 1
 STX LSP
 LDX #2                 ; load step =2, fairly big circle with small step size.
 STX STP

 JSR CIRCLE2
\LDA #&FF
\STA
\LSX
 RTS                    ; could have used jmp
}

\ ******************************************************************************
\ Subroutine: TT219
\
\ Other entry points: BAY2
\
\ Show the Buy Cargo screen (red key f1).
\ ******************************************************************************

.TT219
{
\LDA#2                  ; This instruction is commented out in the original
                        ; source. Perhaps this view originally had a QQ11 value
                        ; of 2, but it turned out not to need its own unique ID,
                        ; so the authors found they could just use a view value
                        ; of 1 and save an instruction at the same time?

 JSR TT66-2             ; Clear the top part of the screen, draw a box border,
                        ; and set the current view type in QQ11 to 1

 JSR TT163              ; Print the column headers for the prices table

 LDA #128               ; Set QQ17 = 128 to switch to Sentence Case, with the
 STA QQ17               ; next letter in capitals

\JSR FLKB               ; This instruction is commented out in the original
                        ; source. It calls a routine to flush the keyboard
                        ; buffer (FLKB) that isn't present in the tape version
                        ; but is in the disc version.

 LDA #0                 ; We're going to loop through all the available market
 STA QQ29               ; items, so we set up a counter in QQ29 to denote the
                        ; current item and start it at 0

.TT220

 JSR TT151              ; Call TT151 to print the item name, market price and
                        ; availability of the current item, and set QQ24 to the
                        ; item's price / 4, QQ25 to the quantity available and
                        ; QQ19+1 to byte #1 from the market prices table for
                        ; this item

 LDA QQ25               ; If there are some of the current item available, jump
 BNE TT224              ; to TT224 below to see if we want to buy any

 JMP TT222              ; Otherwise there are none available, so jump down to
                        ; TT222 to skip this item

.TQ4

 LDY #176               ; Set Y to the recursive token 16 ("QUANTITY")

.Tc

 JSR TT162              ; Print a space

 TYA                    ; Print the recursive token in Y followed by a question
 JSR prq                ; mark

.TTX224

 JSR dn2                ; Call dn2 to make a short, high beep and delay for 1
                        ; second

.TT224

 JSR CLYNS              ; Clear the bottom three text rows of the upper screen,
                        ; and move the text cursor to column 1 on row 21, i.e.
                        ; the start of the top row of the three bottom rows

 LDA #204               ; Print recursive token 44 ("QUANTITY OF ")
 JSR TT27

 LDA QQ29               ; Print recursive token 48 + QQ29, which will be in the
 CLC                    ; range 48 ("FOOD") to 64 ("ALIEN ITEMS"), so this
 ADC #208               ; prints the current item's name
 JSR TT27

 LDA #'/'               ; Print "/"
 JSR TT27

 JSR TT152              ; Print the unit ("t", "kg" or "g") for the current item
                        ; (as the call to TT151 above set QQ19+1 with the
                        ; appropriate value)

 LDA #'?'               ; Print "?"
 JSR TT27

 JSR TT67               ; Print a newline
 
 LDX #0                 ; These instructions have no effect, as they are
 STX R                  ; repeated at the start of gnum, which we call next.
 LDX #12                ; Perhaps they were left behind when code was moved from
 STX T1                 ; here into gnum, and weren't deleted?

\.TT223                 ; This label is commented out in the original source,
                        ; and is a duplicate of a label in gnum, so this could
                        ; also be a remnant if the code in gnum was originally
                        ; here, but got moved into the gnum subroutine

 JSR gnum               ; Call gnum to get a number from the keyboard, which
                        ; will be the quantity of this item we want to purchase,
                        ; returning the number entered in A and R

 BCS TQ4                ; If gnum set the C flag, the number entered is greater
                        ; then the quantity available, so jump up to TQ4 to
                        ; display a "Quantity?" error, beep, clear the number
                        ; and try again

 STA P                  ; Otherwise we have a valid purchase quantity entered,
                        ; so store the amount we want to purchase in P

 JSR tnpr               ; Call tnpr to work out whether there is room in the
                        ; cargo hold for this item

 LDY #206               ; If the C flag is set, then there is no room in the
 BCS Tc                 ; cargo hold, so set Y to the recursive token 46
                        ; (" CARGO{switch to sentence case}") and jump up to
                        ; Tc to print a "Cargo?" error, beep, clear the number
                        ; and try again

 LDA QQ24               ; There is room in the cargo hold, so now to check
 STA Q                  ; whether we have enough cash, so fetch the item's
                        ; price / 4, which was returned in QQ24 by the call
                        ; to TT151 above and store it in Q

 JSR GCASH              ; Call GCASH to calculate
                        ;
                        ;   (Y X) = P * Q * 4
                        ;
                        ; which will be the total price of this transaction
                        ; (as P contains the purchase quantity and Q contains
                        ; the item's price / 4)

 JSR LCASH              ; Subtract (Y X) cash from the cash pot in CASH

 LDY #197               ; If the C flag is clear, we didn't have enough cash,
 BCC Tc                 ; so set Y to the recursive token 37 ("CASH") and jump
                        ; up to Tc to print a "Cash?" error, beep, clear the
                        ; number and try again

 LDY QQ29               ; Fetch the current market item number from QQ29 into Y

 LDA R                  ; Set A to the number of items we just purchased (this
                        ; was set by gnum above)

 PHA                    ; Store the quantity just purchased on the stack

 CLC                    ; Add the number purchased to the Y-th byte of QQ20,
 ADC QQ20,Y             ; which contains the number of items of this type in
 STA QQ20,Y             ; our hold (so this transfers the bought items into our
                        ; cargo hold)

 LDA AVL,Y              ; Subtract the number of items from the Y-th byte of
 SEC                    ; AVL,which contains the number of items of this type
 SBC R                  ; that are available on the market
 STA AVL,Y

 PLA                    ; Restore the quantity just purchased

 BEQ TT222              ; If we didn't buy anything, jump to TT222 to skip the
                        ; following instruction

 JSR dn                 ; Call dn to print the amount of cash left in the cash
                        ; pot, then make a short, high beep to confirm the
                        ; purchase, and delay for 1 second

.TT222

 LDA QQ29               ; Move the text cursor to row QQ29 + 5 (where QQ29 is
 CLC                    ; the item numberm starting from 0)
 ADC #5
 STA YC

 LDA #0                 ; Move the text cursor to column 0
 STA XC

 INC QQ29               ; Increment QQ29 to point to the next item

 LDA QQ29               ; If QQ29 >= 17 then jump to BAY2 as we have done the
 CMP #17                ; last item
 BCS BAY2

 JMP TT220              ; Otherwise loop back to TT220 to print the next market
                        ; item

.^BAY2

 LDA #f9                ; Jump into the main loop at FRCE, setting the key
 JMP FRCE               ; "pressed" to red key f9 (so we show the Inventory
                        ; screen)
}

\ ******************************************************************************
\ Subroutine: gnum
\
\ Get a number from the keyboard, up to the maximum number in QQ25. Pressing a
\ key with an ASCII code less than ASCII "0" will return a 0 in A (so that
\ includes pressing Space or Return), while pressing a ley with an ASCII code
\ greater than ASCII "9" will jump to the Inventory screen (so that includes
\ all letters and most punctuation).
\
\ Arguments:
\
\   QQ25        Maximum number allowed
\
\ Returns:
\
\   A           The number entered
\
\   R           Also contains the number entered
\
\   C flag      Set if the number is too large (> QQ25), clear otherwise
\ ******************************************************************************

.gnum
{
 LDX #0                 ; We will build the number entered in R, so initialise
 STX R                  ; it with 0
 
 LDX #12                ; We will check for up to 12 key presses, so set a
 STX T1                 ; counter in T1

.TT223

 JSR TT217              ; Scan the keyboard until a key is pressed, and return
                        ; the key's ASCII code in A (and X)
 
 STA Q                  ; Store the key pressed in Q
 
 SEC                    ; Subtract ASCII '0' from the key pressed, to leave the
 SBC #'0'               ; numeric value of the key in A (if it was a number key)
 
 BCC OUT                ; If A < 0, jump to OUT to return from the subroutine
                        ; with a result of 0, as the key pressed was not a
                        ; number or letter and is less than ASCII "0"

 CMP #10                ; If A >= 10, jump to BAY2 to display the Inventory
 BCS BAY2               ; screen, as the key pressed was a letter or other
                        ; non-digit and is greater than ASCII "9"

 STA S                  ; Store the numeric value of the key pressed in S
 
 LDA R                  ; Fetch the result so far into A
 
 CMP #26                ; If A >= 26, where A is the number entered so far, then
 BCS OUT                ; adding a further digit will make it bigger than 256,
                        ; so jump to OUT to return from the subroutine with the
                        ; result in R (i.e. ignore the last key press)

 ASL A                  ; Set A = (A * 2) + (A * 8) = A * 10
 STA T
 ASL A
 ASL A
 ADC T

 ADC S                  ; Add the pressed digit to A and store in R, so R now
 STA R                  ; contains its previous value with the new key press
                        ; tacked onto the end

 CMP QQ25               ; If the result in R = the maximum allowed in QQ25, jump
 BEQ TT226              ; to TT226 to print the key press and keep looping (the
                        ; BEQ is needed because the BCS below would jump to OUT
                        ; if R >= QQ25, which we don't want)

 BCS OUT                ; If the result in R > QQ25, jump to OUT to return from
                        ; the subroutine with the result in R

.TT226

 LDA Q                  ; Print the character in Q (i.e. the key that was
 JSR TT26               ; pressed, as we stored the ASCII value in Q earlier)

 DEC T1                 ; Decrement the loop counter

 BNE TT223              ; Loop back to TT223 until we have checked for 12 digits

.OUT

 LDA R                  ; Set A to the result we have been building in R

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: TT208
\
\ Show the Sell Cargo screen (red key f2).
\ ******************************************************************************

.TT208
{
 LDA #4                 ; Clear the top part of the screen, draw a box border,
 JSR TT66               ; and set the current view type in QQ11 to 4 (Sell
                        ; Cargo screen)
 
 LDA #4                 ; Move the text cursor to row 4, column 4
 STA YC 
 STA XC

\JSR FLKB               ; This instruction is commented out in the original
                        ; source. It calls a routine to flush the keyboard
                        ; buffer (FLKB) that isn't present in the tape version
                        ; but is in the disc version.

 LDA #205               ; Print recursive token 45 ("SELL")
 JSR TT27

 LDA #206               ; Print recursive token 46 (" CARGO{switch to sentence
 JSR TT68               ; case}") followed by a colon

                        ; Fall through into TT210 to show the Inventory screen
                        ; with the option to sell
}

\ ******************************************************************************
\ Subroutine: TT210
\
\ Show a list of current cargo in our hold, either with the abilty to sell (the
\ Sell Cargo screen) or without (the Inventory screen), depending on the current
\ view.
\
\ Arguments:
\
\   QQ11        Current view, 4 = Sell Cargo, 8 = Inventory
\ ******************************************************************************

.TT210
{
 LDY #0                 ; We're going to loop through all the available market
                        ; items and check whether we have any in the hold (and,
                        ; if we are in the Sell Cargo screen, whether we want
                        ; to sell any items), so we set up a counter in Y to
                        ; denote the current item and start it at 0

.TT211

 STY QQ29               ; Store the current item number in QQ29

 LDX QQ20,Y             ; Fetch into X the amount of the current item that we
 BEQ TT212              ; have in our cargo hold, which is stored in QQ20+Y,
                        ; and if there are no items of this type in the hold,
                        ; jump down to TT212 to skip to the next item

 TYA                    ; Set Y = Y * 4, so this will act as an index into the
 ASL A                  ; market prices table at QQ23 for this item (as there
 ASL A                  ; are four bytes per item in the table)
 TAY

 LDA QQ23+1,Y           ; Fetch byte #1 from the market prices table for the
 STA QQ19+1             ; current item and store it in QQ19+1, for use by the
                        ; call to TT152 below

 TXA                    ; Store the amount of item in the hold (in X) on the
 PHA                    ; stack

 JSR TT69               ; Call TT69 to set Sentence Case and print a newline

 CLC                    ; Print recursive token 48 + QQ29, which will be in the
 LDA QQ29               ; range 48 ("FOOD") to 64 ("ALIEN ITEMS"), so this
 ADC #208               ; prints the current item's name
 JSR TT27

 LDA #14                ; Set the text cursor to column 14, for the item's
 STA XC                 ; quantity

 PLA                    ; Retore the amount of item in the hold into X
 TAX

 CLC                    ; Print the 8-bit number in X to 3 digits, without a
 JSR pr2                ; decimal point

 JSR TT152              ; Print the unit ("t", "kg" or "g") for the market item
                        ; whose byte #1 from the market prices table is in
                        ; QQ19+1 (which we set up above)

 LDA QQ11               ; If the current view type in QQ11 is not 4 (Sell Cargo
 CMP #4                 ; screen), jump to TT212 to skip the option to sell
 BNE TT212              ; items

 LDA #205               ; Set A to recursive token 45 ("SELL")

 JSR TT214              ; Call TT214 to print "Sell(Y/N)?" and return the
                        ; response in the C flag

 BCC TT212              ; If the response was "no", jump to TT212 to move on to
                        ; the next item

 LDA QQ29               ; We are selling this item, so fetch the item number
                        ; from QQ29

 LDX #255               ; Set QQ17 = 255 to disable printing
 STX QQ17

 JSR TT151              ; Call TT151 to set QQ24 to the item's price / 4 (the
                        ; routine doesn't print the item details, as we just
                        ; disabled printing)

 LDY QQ29               ; Set P to the amount of this item we have in our cargo
 LDA QQ20,Y             ; hold (which is the amount to sell)
 STA P

 LDA QQ24               ; Set Q to the item's price / 4
 STA Q

 JSR GCASH              ; Call GCASH to calculate
                        ;
                        ;   (Y X) = P * Q * 4
                        ;
                        ; which will be the total price we make from this sale
                        ; (as P contains the quantity we're selling and Q
                        ; contains the item's price / 4)

 JSR MCASH              ; Add (Y X) cash to the cash pot in CASH

 LDA #0                 ; We've made the sale, so set the amount 
 LDY QQ29               ; item index
 STA QQ20,Y             ; ship cargo count

 STA QQ17               ; Set QQ17 = 0, which enables printing again

.TT212

 LDY QQ29               ; Fetch the item number from QQ29 into Y, and increment
 INY                    ; Y to point to the next item

 CPY #17                ; If A >= 17 then skip the next instruction as we have
 BCS P%+5               ; done the last item

 JMP TT211              ; Otherwise loop back to TT211 to print the next item
                        ; in the hold

 LDA QQ11               ; If the current view type in QQ11 is not 4 (Sell Cargo
 CMP #4                 ; screen), skip the next two instructions and just return
 BNE P%+8               ; from the subroutine

 JSR dn2                ; This is the Sell Cargo screen, so call dn2 to make a
                        ; short, high beep and delay for 1 second

 JMP BAY2               ; And then jump to BAY2 to display the Inventory
                        ; screen, as we have finished selling cargo

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: TT213
\
\ Show the Inventory screen (red key f9).
\ ******************************************************************************

.TT213
{
 LDA #8                 ; Clear the top part of the screen, draw a box border,
 JSR TT66               ; and set the current view type in QQ11 to 8 (Inventory
                        ; screen)

 LDA #11                ; Move the text cursor to column 11 to print the screen
 STA XC                 ; title

 LDA #164               ; Print recursive token 4 ("INVENTORY{crlf}") followed
 JSR TT60               ; by a paragraph break and Sentence Case

 JSR NLIN4              ; Draw a horizontal line at pixel row 19 to box in the
                        ; title

 JSR fwl                ; Call fwl to print the fuel and cash levels on two
                        ; separate lines

 LDA CRGO               ; If our ship's cargo capacity is < 26 (i.e. we do not
 CMP #26                ; have a cargo bay extension), skip the following two
 BCC P%+7               ; instructions

 LDA #107               ; We do have a cargo bay extension, so print recursive
 JSR TT27               ; token 107 ("LARGE CARGO{switch to sentence case}
                        ; BAY")

 JMP TT210              ; Jump to TT210 to print the contents of our cargo bay
                        ; and return from the subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: TT214
\
\ Ask a question with a "Y/N?" prompt and return the response.
\
\ Arguments:
\
\   A           The text token to print before the "Y/N?" prompt
\
\ Returns:
\
\   C flag      Set if the response was "yes", clear otherwise
\ ******************************************************************************

.TT214
{
 PHA                    ; Print a space, using the stack to preserve the value
 JSR TT162              ; of A
 PLA

.TT221

 JSR TT27               ; Print the text token in A

 LDA #225               ; Pring recursive token 65 ("(Y/N)?")
 JSR TT27

 JSR TT217              ; Scan the keyboard until a key is pressed, and return
                        ; the key's ASCII code in A and X

 ORA #%00100000         ; Set bit 5 in the value of the key pressed, which
                        ; converts it to lower case

 CMP #'y'               ; If "y" was pressed, jump to TT218
 BEQ TT218

 LDA #'n'               ; Otherwise jump to TT26 to print "n" and return from
 JMP TT26               ; the subroutine using a tail call (so all other
                        ; responses apart from "y" indicate a no)

.TT218

 JSR TT26               ; Print the character in A, i.e. print "y"

 SEC                    ; Set the C flag to indicate a "yes" response

 RTS
}

\ ******************************************************************************
\ Subroutine: TT16
\
\ Move the chart cross-hairs by the amount in X and Y.
\
\ Arguments:
\
\   X           The amount to move the cross-hairs in the x-axis, if applicable
\
\   Y           The amount to move the cross-hairs in the y-axis, if applicable
\ ******************************************************************************

.TT16
{
 TXA
 PHA                    ; Xinc
 DEY                    ; negate Yinc
 TYA
 EOR #255
 PHA                    ; negate Yinc
 JSR WSCAN              ; wait for line scan, ie whole frame completed.
 JSR TT103              ; erase small cross hairs at target hyperspace
 PLA                    ; negated Yinc
 STA QQ19+3             ; inc

 LDA QQ10               ; target y
 JSR TT123              ; coordinate update, fix overflow
 LDA QQ19+4             ; result
 STA QQ10               ; target y
 STA QQ19+1             ; new Y
 PLA                    ; Xinc

 STA QQ19+3             ; inc
 LDA QQ9                ; target x
 JSR TT123              ; coordinate update, fix overflow
 LDA QQ19+4             ; result
 STA QQ9                ; target x
 STA QQ19               ; new X
}

\ ******************************************************************************
\ Subroutine: TT103
\
\ Draw small cross hairs at target hyperspace system.
\ ******************************************************************************

.TT103                  ; Draw small cross hairs at target hyperspace system.
{
 LDA QQ11               ; menu i.d.
 BEQ TT180
 BMI TT105              ; bit7 set is Short range chart cross-hair clip
 LDA QQ9                ; target x
 STA QQ19
 LDA QQ10               ; target y
 LSR A                  ; Y /=2
 STA QQ19+1
 LDA #4                 ; small cross hair
 STA QQ19+2
 JMP TT15               ; cross hairs for laser or chart
}

\ ******************************************************************************
\ Subroutine: TT123
\
\ Coordinate update, fix overflow
\ ******************************************************************************

.TT123                  ; coordinate update, fix overflow
{
 STA QQ19+4             ; coordinate to update
 CLC                    ; add inc
 ADC QQ19+3
 LDX QQ19+3
 BMI TT124              ; shift was -ve
 BCC TT125              ; else addition went o.k.
 RTS

.TT124                  ; shift was -ve

 BCC TT180              ; shift was -ve,  RTS.

.TT125                  ; update ok

 STA QQ19+4             ; updated coordinate
}

.TT180                  ; rts
{
 RTS
}

\ ******************************************************************************
\ Subroutine: TT105
\
\ Short range chart cross-hair clip
\ ******************************************************************************

.TT105                  ; Short range chart cross-hair clip
{
 LDA QQ9                ; target X
 SEC
 SBC QQ0                ; present X
 CMP #38
 BCC TT179              ; targetX-presentX, X is close
 CMP #230
 BCC TT180              ; rts

.TT179                  ; X is close

 ASL A
 ASL A                  ; X*4
 CLC
 ADC #104               ; cross X
 STA QQ19

 LDA QQ10               ; target Y
 SEC
 SBC QQ1                ; present Y
 CMP #38
 BCC P%+6               ; targetY-presentY, Y is close
 CMP #220
 BCC TT180              ; rts

 ASL A                  ; Y*2
 CLC
 ADC #90                ; cross Y
 STA QQ19+1
 LDA #8                 ; big cross
 STA QQ19+2
 JMP TT15               ; the cross hair using QQ19(0to2)
}

\ ******************************************************************************
\ Subroutine: TT23
\
\ Show the Short-range Chart (red key f5).
\ ******************************************************************************

.TT23
{
 LDA #128               ; Clear the top part of the screen, draw a box border,
 JSR TT66               ; and set the current view type in QQ11 to 128 (Short-
                        ; range Chart)

 LDA #7                 ; Move the text cursor to column 7
 STA XC

 LDA #190               ; Print recursive token 30 ("SHORT RANGE CHART") and
 JSR NLIN3              ; draw a horizontal line at pixel row 19 to box in the
                        ; title

 JSR TT14               ; Call TT14 to draw a circle with a cross-hair at the
                        ; current system's galactic coordinates

 JSR TT103              ; Draw small cross-hairs at coordinates (QQ9, QQ10),
                        ; i.e. at the selected system

 JSR TT81               ; Set the seeds in QQ15 to those of the current system
                        ; (i.e. copy the seeds from QQ21 to QQ15)

 LDA #0                 ; Set A = 0, which we'll use below to zero out the INWK
                        ; workspace

 STA XX20               ; We're about to start working our way through each of
                        ; the galaxy's systems, so set up a counter in XX20 for
                        ; each system, starting at 0 and looping through to 255

 LDX #24                ; First, though, we need to zero out the 25 bytes at
                        ; INWK so we can use them to work out which systems have
                        ; room for a label, so set a counter in X for 25 bytes

.EE3

 STA INWK,X             ; Set the X-th byte of INWK to zero

 DEX                    ; Decrement the counter

 BPL EE3                ; Loop back to EE3 for the next byte until we've zeroed
                        ; all 25 bytes

                        ; We now loop through every single system in the galaxy
                        ; and check the distance from the current system whose
                        ; coordinates are in (QQ0, QQ1). We get the galactic
                        ; coordinates of each system from the system's seeds,
                        ; like this:
                        ;
                        ;   x = w1_hi (which is stored in QQ15+3)
                        ;   y = w0_hi (which is stored in QQ15+1)
                        ;
                        ; so the following loops through each system in the
                        ; galaxy in turn and calculates the distance between
                        ; (QQ0, QQ1) and (w1_hi, w0_hi) to find the closest one

.TT182

 LDA QQ15+3             ; Set A = w1_hi - QQ0, the horizontal distance between
 SEC                    ; (w1_hi, w0_hi) and (QQ0, QQ1)
 SBC QQ0

 BCS TT184              ; If a borrow didn't occur, i.e. w1_hi >= QQ0, then the
                        ; result is positive, so jump to TT184 and skip the
                        ; following two instructions

 EOR #&FF               ; Otherwise negate the result in A, so A is always
 ADC #1                 ; positive (i.e. A = |w1_hi - QQ0|)

.TT184

 CMP #20                ; If the horizontal distance in A is >= 20, then this
 BCS TT187              ; system is too far away from the current system to
                        ; appear in the short-range chart, so jump to TT187 to
                        ; move on to the next system

 LDA QQ15+1             ; Set A = w0_hi - QQ1, the vertical distance between
 SEC                    ; (w1_hi, w0_hi) and (QQ0, QQ1)
 SBC QQ1

 BCS TT186              ; If a borrow didn't occur, i.e. w0_hi >= QQ1, then the
                        ; result is positive, so jump to TT186 and skip the
                        ; following two instructions

 EOR #&FF               ; Otherwise negate the result in A, so A is always
 ADC #1                 ; positive (i.e. A = |w0_hi - QQ1|)

.TT186

 CMP #38                ; If the vertical distance in A is >= 38, then this
 BCS TT187              ; system is too far away from the current system to
                        ; appear in the short-range chart, so jump to TT187 to
                        ; move on to the next system

                        ; This system should be shown on the short-range chart,
                        ; so now we need to work out where the label should go,
                        ; and set up the various variables we need to draw the
                        ; system's filled circle on the chart

 LDA QQ15+3             ; Set A = w1_hi - QQ0, the horizontal distance between
 SEC                    ; this system and the current system, where |A| < 20.
 SBC QQ0                ; Let's call this the x-delta, as it's the horizontal
                        ; difference between the current system at the centre of
                        ; the chart, and this system (and this time we keep the
                        ; sign of A, so it can be negative if it's to the left
                        ; of the chart's centre, or positive if it's to the
                        ; right)

 ASL A                  ; Set XX12 = 104 + x-delta * 4
 ASL A                  ;
 ADC #104               ; 104 is the x-coordinate of the centre of the chart,
 STA XX12               ; so this sets XX12 to the centre 104 +/- 76, the pixel
                        ; x-coordinate of this system

 LSR A                  ; Move the text cursor to column x-delta / 2 + 1
 LSR A                  ; which will be in the range 1-10
 LSR A
 STA XC
 INC XC

 LDA QQ15+1             ; Set A = w0_hi - QQ1, the vertical distance between
 SEC                    ; this system and the current system, where |A| < 38.
 SBC QQ1                ; Let's call this the y-delta, as it's the vertical
                        ; difference between the current system at the centre of
                        ; the chart, and this system (and this time we keep the
                        ; sign of A, so it can be negative if it's above the
                        ; chart's centre, or positive if it's below)

 ASL A                  ; Set K4 = 90 + y-delta * 2
 ADC #90                ;
 STA K4                 ; 90 is the y-coordinate of the centre of the chart,
                        ; so this sets K4 to the centre 90 +/- 74, the pixel
                        ; y-coordinate of this system

 LSR A                  ; Set Y = K4 / 8, so Y contains the number of the text
 LSR A                  ; row that contains this system
 LSR A
 TAY

                        ; Now to see if there is room for this system's label.
                        ; Ideally we would print the system name on the same
                        ; text row as the system, but we only want to print one
                        ; label per row, to prevent overlap, so now we check
                        ; this system's row, and if that's already occupied,
                        ; the row above, and if that's already occupied, the
                        ; row below... and if that's already occupied, we give
                        ; up and don't print a label for this system

 LDX INWK,Y             ; If the value in INWK+Y is 0 (i.e. the text row
 BEQ EE4                ; containing this system does not already have another
                        ; system's label on it), jump to EE4 to store this
                        ; system's label on this row

 INY                    ; If the value in INWK+Y+1 is 0 (i.e. the text row below
 LDX INWK,Y             ; the one containing this system does not already have
 BEQ EE4                ; another system's label on it), jump to EE4 to store
                        ; this system's label on this row

 DEY                    ; If the value in INWK+Y-1 is 0 (i.e. the text row above
 DEY                    ; the one containing this system does not already have
 LDX INWK,Y             ; another system's label on it), fall through into to
 BNE ee1                ; EE4 to store this system's label on this row,
                        ; otherwise jump to ee1 to skip printing a label for
                        ; this system (as there simply isn't room)

.EE4

 STY YC                 ; Now to print the label, so move the text cursor to row
                        ; Y (which contains the row where we can print this
                        ; system's label)

 CPY #3                 ; If Y < 3, then the label would clash with the chart
 BCC TT187              ; title, so jump to TT187 to skip printing the label

 DEX                    ; We entered the EE4 routine with X = 0, so this stores
 STX INWK,Y             ; &FF in INWK+Y, to denote that this row is now occupied
                        ; so we don't try to print another system's label on
                        ; this row

 LDA #128               ; Set QQ17 to 128, which denotes Sentence Case
 STA QQ17

 JSR cpl                ; Call cpl to print out the system name for the seeds
                        ; in QQ15 (which now contains the seeds for the current
                        ; system)

.ee1

 LDA #0                 ; Now to plot the star, so set the high bytes of K, K3
 STA K3+1               ; and K4 to 0
 STA K4+1
 STA K+1

 LDA XX12               ; Set the low byte of K3 to XX12, the pixel x-coordinate
 STA K3                 ; of this system

 LDA QQ15+5             ; Fetch w2_hi for this system from QQ15+5, extract bit 0
 AND #1                 ; and add 2 to get the size of the star, which we store
 ADC #2                 ; in K. This will be either 2, 3 or 4, depending on the
 STA K                  ; value of bit 0, and whether the C flag is set (which
                        ; will vary depending on what happens in the above call
                        ; to cpl). Incidentally, the planet's average radius
                        ; also uses w2_hi, bits 0-3 to be precise, but that
                        ; doesn't mean the two sizes affect each other

                        ; We now have the following:
                        ;
                        ;   K(1 0)  = radius of star (2, 3 or 4)
                        ;
                        ;   K3(1 0) = pixel x-coordinate of system
                        ;
                        ;   K4(1 0) = pixel y-coordinate of system
                        ;
                        ; which we can now pass to the SUN routine to draw a
                        ; small "sun" on the short-range chart for this system

 JSR FLFLLS             ; Call FLFLLS to reset the LSO block

 JSR SUN                ; Call SUN to plot a sun with radius K at pixel
                        ; coordinate (K3, K4)

 JSR FLFLLS             ; Call FLFLLS to reset the LSO block

.TT187

 JSR TT20               ; We want to move on to the next system, so call TT20
                        ; to twist the three 16-bit seeds in QQ15

 INC XX20               ; Increment the counter

 BEQ TT111-1            ; If X = 0 then we have done all 256 systems, so return
                        ; from the subroutine (as TT111-1 contains an RTS)

 JMP TT182              ; Otherwise jump back up to TT182 to process the next
                        ; system
}

\ ******************************************************************************
\ Subroutine: TT81
\
\ Copy the three 16-bit seeds for the current system (QQ21) into the seeds for
\ the selected system (QQ15) - in other words, set the selected system's seeds
\ to those of the current system.
\ ******************************************************************************

.TT81
{
 LDX #5                 ; Set up a counter in X to copy six bytes (for three
                        ; 16-bit numbers)

 LDA QQ21,X             ; Copy the X-th byte in QQ21 to the X-th byte in QQ15
 STA QQ15,X

 DEX                    ; Decrement the counter

 BPL TT81+2             ; Loop back up to the LDA instruction if we still have
                        ; more bytes to copy

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: TT111
\
\ Other entry points: TT111-1 (RTS)
\
\ Given a set of galactic coordinates in (QQ9, QQ10), find the nearest system
\ to this point in the galaxy, and set this as the currently selected system.
\
\ Arguments:
\
\   QQ9         The x-coordinate near which we want to find a system
\
\   QQ10        The y-coordinate near which we want to find a system
\
\ Returns:
\
\   (QQ8 QQ8+1) The distance from the current system to the
\               nearest system to the original coordinates
\
\   QQ9         The x-coordinate of the nearest system to the original
\               coordinates
\ 
\   QQ10        The y-coordinate of the nearest system to the original
\               coordinates
\
\   QQ15 to     The three 16-bit seeds of the nearest system to the original
\   QQ15+5      coordinates
\ ******************************************************************************

.TT111
{
 JSR TT81               ; Set the seeds in QQ15 to those of the current system
                        ; (i.e. copy the seeds from QQ21 to QQ15)

                        ; We now loop through every single system in the galaxy
                        ; and check the distance from (QQ9, QQ10). We get the
                        ; galactic coordinates of each system from the system's
                        ; seeds, like this:
                        ;
                        ;   x = w1_hi (which is stored in QQ15+3)
                        ;   y = w0_hi (which is stored in QQ15+1)
                        ;
                        ; so the following loops through each system in the
                        ; galaxy in turn and calculates the distance between
                        ; (QQ9, QQ10) and (w1_hi, w0_hi) to find the closest one

 LDY #127               ; Set Y = T = 127 to hold the shortest distance we've
 STY T                  ; found so far, which we initially set to half the
                        ; distance across the galaxy, or 127, as our coordinate
                        ; system ranges from (0,0) to (255, 255)

 LDA #0                 ; Set A = U = 0 to act as a counter for each system in
 STA U                  ; the current galaxy, which we start at system 0 and
                        ; loop through to 255, the last system

.TT130

 LDA QQ15+3             ; Set A = w1_hi - QQ9, the horizontal distance between
 SEC                    ; (w1_hi, w0_hi) and (QQ9, QQ10)
 SBC QQ9

 BCS TT132              ; If a borrow didn't occur, i.e. w1_hi >= QQ9, then the
                        ; result is positive, so jump to TT132 and skip the
                        ; following two instructions

 EOR #&FF               ; Otherwise negate the result in A, so A is always
 ADC #1                 ; positive (i.e. A = |w1_hi - QQ9|)

.TT132

 LSR A                  ; Set S = A / 2
 STA S                  ;       = |w1_hi - QQ9| / 2

 LDA QQ15+1             ; Set A = w0_hi - QQ10, the vertical distance between
 SEC                    ; (w1_hi, w0_hi) and (QQ9, QQ10)
 SBC QQ10

 BCS TT134              ; If a borrow didn't occur, i.e. w0_hi >= QQ10, then the
                        ; result is positive, so jump to TT134 and skip the
                        ; following two instructions

 EOR #&FF               ; Otherwise negate the result in A, so A is always
 ADC #1                 ; positive (i.e. A = |w0_hi - QQ10|)

.TT134

 LSR A                  ; Set A = S + A / 2
 CLC                    ;       = |w1_hi - QQ9| / 2 + |w0_hi - QQ10| / 2
 ADC S                  ;
                        ; So A now contains the sum of the horizontal and
                        ; vertical distances, both divided by 2 so the result
                        ; fits into one byte, and although this doesn't contain
                        ; the actual distance between the systems, it's a good
                        ; enough approximation to use for comparing distances

 CMP T                  ; If A >= T, then this system's distance is bigger than
 BCS TT135              ; our "minimum distance so far" stored in T, so it's no
                        ; closer than the systems we have already found, so
                        ; skip to TT135 to move on to the next system

 STA T                  ; This system is the closest to (QQ9, QQ10) so far, so
                        ; update T with the new "distance" approximation

 LDX #5                 ; As this system is the closest we have found yet, we
                        ; want to store the system's seeds in case it ends up
                        ; being the closest of all, so we set up a counter in X
                        ; to copy six bytes (for three 16-bit numbers)

.TT136

 LDA QQ15,X             ; Copy the X-th byte in QQ15 to the X-th byte in QQ19,
 STA QQ19,X             ; where QQ15 contains the seeds for the system we just
                        ; found to be the closest so far, and QQ19 is temporary
                        ; storage

 DEX                    ; Decrement the counter

 BPL TT136              ; Loop back to TT136 if we still have more bytes to
                        ; copy

.TT135

 JSR TT20               ; We want to move on to the next system, so call TT20
                        ; to twist the three 16-bit seeds in QQ15

 INC U                  ; Increment the system counter in U

 BNE TT130              ; If U > 0 then we haven't done all 256 systems yet, so
                        ; loop back up to TT130

                        ; We have now finished checking all the systems in the
                        ; galaxy, and the seeds for the closest system are in
                        ; QQ19, so now we want to copy these seeds to QQ15,
                        ; to set the selected system to this closest system
                        
 LDX #5                 ; So we set up a counter in X to copy six bytes (for
                        ; three 16-bit numbers)

.TT137

 LDA QQ19,X             ; Copy the X-th byte in QQ19 to the X-th byte in QQ15,
 STA QQ15,X

 DEX                    ; Decrement the counter

 BPL TT137              ; Loop back to TT137 if we still have more bytes to
                        ; copy

 LDA QQ15+1             ; The y-coordinate of the system described by the seeds
 STA QQ10               ; in QQ15 is in QQ15+1 (w0_hi), so we copy this to QQ10
                        ; as this is where we store the selected system's
                        ; y-coordinate

 LDA QQ15+3             ; The x-coordinate of the system described by the seeds
 STA QQ9                ; in QQ15 is in QQ15+3 (w1_hi), so we copy this to QQ9
                        ; as this is where we store the selected system's
                        ; x-coordinate

                        ; We have now found the closest system to (QQ9, QQ10)
                        ; and have set it as the selected system, so now we
                        ; need to work out the distance between the selected
                        ; system and the current system

 SEC                    ; Set A = QQ9 - QQ0, the horizontal distance between
 SBC QQ0                ; the selected system's x-coordinate (QQ9) and the
                        ; current system's x-coordinate (QQ0)

 BCS TT139              ; If a borrow didn't occur, i.e. QQ9 >= QQ0, then the
                        ; result is positive, so jump to TT139 and skip the
                        ; following two instructions

 EOR #&FF               ; Otherwise negate the result in A, so A is always
 ADC #1                 ; positive (i.e. A = |QQ9 - QQ0|)

                        ; A now contains the difference between the two
                        ; systems' x-coordinates, with the sign removed. We
                        ; will refer to this as the x-delta ("delta" means
                        ; change or difference in maths)

.TT139

 JSR SQUA2              ; Set (A P) = A * A
                        ;           = |QQ9 - QQ0| ^ 2
                        ;           = x_delta ^ 2

 STA K+1                ; Store (A P) in K(1 0)
 LDA P
 STA K

 LDA QQ10               ; Set A = QQ10 - QQ1, the vertical distance between the
 SEC                    ; selected system's y-coordinate (QQ10) and the current
 SBC QQ1                ; system's y-coordinate (QQ1)

 BCS TT141              ; If a borrow didn't occur, i.e. QQ10 >= QQ1, then the
                        ; result is positive, so jump to TT141 and skip the
                        ; following two instructions

 EOR #&FF               ; Otherwise negate the result in A, so A is always
 ADC #1                 ; positive (i.e. A = |QQ10 - QQ1|)

.TT141

 LSR A                  ; Set A = A / 2

                        ; A now contains the difference between the two
                        ; systems' y-coordinates, with the sign removed, and
                        ; halved. We halve the value because the galaxy in
                        ; in Elite is rectangular rather than square, and is
                        ; twice as wide (x-axis) as it is high (y-axis), so to
                        ; get a distance that matches the shape of the
                        ; long-range galaxy chart, we need to halve the
                        ; distance between the vertical y-coordinates. We will
                        ; refer to this as the y-delta.


 JSR SQUA2              ; Set (A P) = A * A
                        ;           = (|QQ10 - QQ1| / 2) ^ 2
                        ;           = y_delta ^ 2

                        ; By this point we have the following results:
                        ;
                        ;   K(1 0) = x_delta ^ 2
                        ;    (A P) = y_delta ^ 2
                        ;
                        ; so to find the distance between the two points, we
                        ; can use Pythagoras - so first we need to add the two
                        ; results together, and then take the square root

 PHA                    ; Store the high byte of the y-axis value on the stack,
                        ; so we can use A for another purpose

 LDA P                  ; Set Q = P + K, which adds the low bytes of the two
 CLC                    ; calculated values
 ADC K
 STA Q

 PLA                    ; Restore the high byte of the y-axis value from the
                        ; stack into A again

 ADC K+1                ; Set R = A + K+1, which adds the high bytes of the two
 STA R                  ; calculated values, so we now have:
                        ;
                        ;   (R Q) = K(1 0) + (A P)
                        ;         = (x_delta ^ 2) + (y_delta ^ 2)

 JSR LL5                ; Set Q = SQRT(R Q), so Q now contains the distance
                        ; between the two systems, in terms of coordinates

                        ; We now store the distance to the selected system * 4
                        ; in the two-byte location QQ8, by taking (0 Q) and
                        ; shifting it left twice, storing it in (QQ8+1 QQ8)

 LDA Q                  ; First we shift the low byte left by setting
 ASL A                  ; A = Q * 2, with bit 7 of A going into the C flag

 LDX #0                 ; Now we set the high byte in QQ8+1 to 0 and rotate
 STX QQ8+1              ; the C flag into bit 0 of QQ8+1
 ROL QQ8+1

 ASL A                  ; And then we repeat the shift left of (QQ8+1 A)
 ROL QQ8+1

 STA QQ8                ; And store A in the low byte, QQ8, so (QQ8+1 QQ8) now
                        ; contains Q * 4. Given that the width of the galaxy is
                        ; 256 in coordinate terms, the width of the galaxy
                        ; would be 1024 in the units we store in QQ8

 JMP TT24               ; Call TT24 to calculate system data from the seeds in
                        ; QQ15 and store them in the relevant locations, so our
                        ; new selected system is fully set up
}

\ ******************************************************************************
\ Subroutine: hy6
\
\ Print "Docked" at the bottom of the screen to indicate we can't hyperspace
\ when docked.
\ ******************************************************************************

.hy6
{
 JSR CLYNS              ; Clear the bottom three text rows of the upper screen,
                        ; and move the text cursor to column 1 on row 21, i.e.
                        ; the start of the top row of the three bottom rows

 LDA #15                ; Move the text cursor to column 15 (the middle of the
 STA XC                 ; screen), setting A to 15 at the same time for the
                        ; following call to TT27

 JMP TT27               ; Print recursive token 129 ("{switch to sentence case}
                        ; DOCKED") and return from the subroutine using a tail
                        ; call
}

\ ******************************************************************************
\ Subroutine: hyp
\
\ hyperspace start, key H hit.
\ ******************************************************************************

.hyp
{
 LDA QQ12               ; If we are docked (QQ12 = &FF) then jump to hy6 to
 BNE hy6                ; print an error message and return from the subroutine
                        ; using a tail call (as we can't hyperspace when docked)

 LDA QQ22+1             ; hyp countdown lo
 BNE zZ+1               ; rts! as countdown already going on
 JSR CTRL               ; scan from ctrl key upwards on keyboard
 BMI Ghy                ; Galactic hyperdrive for ctrl-H
 JSR hm                 ; move hyperspace cross on chart

                        ; check range, all.
 LDA QQ8                ; distance in 0.1 LY units
 ORA QQ8+1              ; zero?
 BEQ zZ+1               ; rts!
 LDA #7                 ; indent
 STA XC
 LDA #23                ; near bottom row for hyperspace message
 STA YC
 LDA #0                 ; All upper case
 STA QQ17
 LDA #189               ; token = HYPERSPACE
 JSR TT27               ; process flight text token
 LDA QQ8+1              ; distance hi
 BNE TT147              ; hyperspace range too far
 LDA QQ14               ; ship fuel #70 = #&46
 CMP QQ8                ; distance lo
 BCC TT147              ; hyperspace too far

 LDA #&2D               ; ascii "-" in  "HYPERSPACE -ISINOR"
 JSR TT27
 JSR cpl                ; Planet name for seed QQ15
}

.wW                     ; Also Galactic hyperdrive countdown starting
{
 LDA #15                ; counter for outer and inner hyperspace countdown loops
 STA QQ22+1
 STA QQ22               ; inner hyperspace countdown
 TAX                    ; starts at 15
 JMP ee3                ; digit in top left hand corner, using Xreg.

\hy5 RTS
}

\ ******************************************************************************
\ Subroutine: Ghy
\
\ Galactic hyperdrive for ctrl-H
\ ******************************************************************************

.Ghy                    ; Galactic hyperdrive for ctrl-H
{
\JSR TT111              ; is in ELITED.TXT but not in ELITE SOURCE IMAGE
 LDX GHYP               ; possess galactic hyperdrive?
 BEQ hy5                ; rts
 INX                    ; Xreg = 0
 STX QQ8
 STX QQ8+1
 STX GHYP               ; works once
 STX FIST               ; clean Fugitive/Innocent status
 JSR wW                 ; start countdown
 LDX #5                 ; 6 seeds
 INC GCNT               ; next galaxy
 LDA GCNT
 AND #7                 ; round count to just 8
 STA GCNT

.G1                     ; counter X  ROLL galaxy seeds

 LDA QQ21,X             ; Galaxy seeds, 6 bytes
 ASL A                  ; to get carry to load back into bit 0
 ROL QQ21,X             ; rolled galaxy seeds
 DEX
 BPL G1                 ; loop X
\JSR DORND
}

.zZ                     ; Arrive closest to (96,96)
{
 LDA #&60               ; zZ+1 is an rts !
 STA QQ9
 STA QQ10
 JSR TT110              ; Launch ship decision
 LDA #116               ; token = Galactic Hyperspace
 JSR MESS               ; message
}

.jmp                    ; move target coordinates to become new present
{
 LDA QQ9
 STA QQ0
 LDA QQ10
 STA QQ1
}

.hy5
{
 RTS                    ; ee3-1
}

\ ******************************************************************************
\ Subroutine: ee3
\
\ Print the 8-bit number in X at text location (0, 1). Print the number to
\ 5 digits, left-padding with spaces for numbers with fewer than 3 digits (so
\ numbers < 10000 are right-aligned), with no decimal point.
\
\ Arguments:
\
\   X           The number to print
\ ******************************************************************************

.ee3
{
 LDY #1                 ; Set YC = 1 (first row)
 STY YC

 DEY                    ; Set XC = 0 (first character)
 STY XC

                        ; Fall through into pr6 to print X to 5 digits
}

\ ******************************************************************************
\ Subroutine: pr6
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned),
\ with no decimal point.
\
\ Arguments:
\
\   X           The low byte of the number to print
\
\   Y           The high byte of the number to print
\ ******************************************************************************

.pr6
{
 CLC                    ; Do not display a decimal point when printing

                        ; Fall through into pr5 to print X to 5 digits
}

\ ******************************************************************************
\ Subroutine: pr5
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned).
\ Optionally include a decimal point.
\
\ Arguments:
\
\   X           The low byte of the number to print
\
\   Y           The high byte of the number to print
\
\   C flag      If set, include a decimal point
\ ******************************************************************************

.pr5
{
 LDA #5                 ; Set the number of digits to print to 5

 JMP TT11               ; Call TT11 to print (Y X) to 5 digits and return from
                        ; the subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: TT147
\
\ Print "RANGE?" for when the hyperspace distance is too far.
\ ******************************************************************************

.TT147
{
 LDA #202               ; Load A with token 42 ("RANGE") and fall through into
                        ; prq to print it, followed by a question mark
}

\ ******************************************************************************
\ Subroutine: prq
\
\ Print a text token followed by a question mark.
\
\ Arguments:
\
\   A           The text token to be printed
\ ******************************************************************************

.prq
{
 JSR TT27               ; Print the text token in A

 LDA #'?'               ; Print a question mark and return from the 
 JMP TT27               ; subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: TT151
\
\ Print the item name, market price and availability for a market item.
\
\ Arguments:
\
\   A           The number of the market item to print, 0-16 (see QQ23 for
\               details of item numbers)
\
\ Results:
\
\   QQ19+1      Byte #1 from the market prices table for this item
\
\   QQ24        The item's price / 4
\
\   QQ25        The item's availability
\ ******************************************************************************
\
\ Item prices are calculated using a formula that takes a number of variables
\ into consideration, and mixes in a bit of random behaviour to boot. This is
\ the formula, which is performed as an 8-bit calculation:
\
\   price = ((base_price + (random AND mask) + economy * economic_factor)) * 4
\
\ The resulting price is 10 times the displayed price, so we can show it to one
\ decimal place. The individual items in the calculation are as follows:
\
\   * The item's base_price is byte #0 in the market prices table at QQ23, so
\     it's 19 for food, 20 for textiles, 235 for narcotics and so on.
\
\   * Each time we arrive in a new system, a random number is generated and
\     stored in location QQ26, and this is shown as "random" in the calculation
\     above.
\
\   * The item's mask is byte #3 in the market prices table at QQ23, so
\     it's &01 for food, &03 for textiles, &78 for narcotics and so on. The
\     more set bits there are in this mask, and the higher their position in
\     this byte, the larger the price fluctuations for this commodity, as the
\     random number is AND'd with the mask. So narcotics will vary wildly in
\     price, while food and textiles will be relatively stable.
\
\   * The economy for a system is given in a 3-bit value, from 0 to 7, that is
\     stored in QQ28. This value is described in more detail in routine TT24,
\     but this is the range of values:
\
\       0 = Rich Industrial
\       1 = Average Industrial
\       2 = Poor Industrial
\       3 = Mainly Industrial
\       4 = Mainly Agricultural
\       5 = Rich Agricultural
\       6 = Average Agricultural
\       7 = Poor Agricultural
\
\   * The economic_factor is stored in bits 0-4 of byte #1 in the market prices
\     table at QQ23, and its sign is in bit 7, so it's -2 for food, -1 for
\     textiles, +8 for narcotics and so on. Negative factors show products that
\     tend to be cheaper than average in agricultural economies but closer to
\     average in rich industrial ones, while positive factors are more
\     expensive in poor agricultural systems than rich industrial ones - so
\     food is cheaper in poor agricultural systems while narcotics are very
\     expensive, and it's the other way round in rich industrial systems,
\     where narcotics are closer to the average price, but food is pricier.
\
\   * The units for this item (i.e. tonnes, grams pr kilograms) are given by
\     bits 5-6 of of byte #1 in the market prices table at QQ23.
\ ******************************************************************************

.TT151
{
 PHA                    ; Store the item number on the stack and in QQ14+4
 STA QQ19+4             

 ASL A                  ; Store the item number * 4 in QQ19, so this will act as
 ASL A                  ; an index into the market prices table at QQ23 for this
 STA QQ19               ; item (as there are four bytes per item in the table)

 LDA #1                 ; Set the text cursor to column 1, for the item's name
 STA XC

 PLA                    ; Restore the item number

 ADC #208               ; Print recursive token 48 + A, which will be in the
 JSR TT27               ; range 48 ("FOOD") to 64 ("ALIEN ITEMS"), so this
                        ; prints the item's name

 LDA #14                ; Set the text cursor to column 14, for the price
 STA XC

 LDX QQ19               ; Fetch byte #1 from the market prices table for this
 LDA QQ23+1,X           ; item and store in QQ19+1
 STA QQ19+1

 LDA QQ26               ; Fetch the random number for this system visit and 
 AND QQ23+3,X           ; AND with byte #3 from the market prices table (mask)
                        ; to give:
                        ;
                        ;   A = random AND mask
 
 CLC                    ; Add byte #0 from the market prices table (base_price),
 ADC QQ23,X             ; so we now have:
 STA QQ24               ;
                        ;   A = base_price + (random AND mask)

 JSR TT152              ; Call TT152 to print the item's unit ("t", "kg" or
                        ; "g"), padded to a width of two characters

 JSR var                ; Call var to set QQ19+3  = economy * |economic_factor|
                        ; (and set the availability of Alien Items to 0)

 LDA QQ19+1             ; Fetch the byte #1 that we stored above and jump to
 BMI TT155              ; TT155 if it is negative (i.e. if the economic_factor
                        ; is negative)

 LDA QQ24               ; Set A = QQ24 + QQ19+3
 ADC QQ19+3             ;
                        ;       = base_price + (random AND mask)
                        ;         + (economy * |economic_factor|)
                        ;
                        ; which is the result we want, as the economic_factor
                        ; is positive

 JMP TT156              ; Jump to TT156 to multiply the result by 4

.TT155

 LDA QQ24               ; Set A = QQ24 - QQ19+3
 SEC                    ; 
 SBC QQ19+3             ;       = base_price + (random AND mask)
                        ;         - (economy * |economic_factor|)
                        ;
                        ; which is the result we want, as economic_factor
                        ; is negative

.TT156

 STA QQ24               ; Store the result in QQ24 and P
 STA P

 LDA #0                 ; Set A = 0 and call GC2 to calculate (Y X) = (A P) * 4,
 JSR GC2                ; which is the same as (Y X) = P * 4 because A = 0

 SEC                    ; We now have our final price, * 10, so we can call pr5
 JSR pr5                ; to print (Y X) to 5 digits, including a decimal
                        ; point, as the carry flag is set

 LDY QQ19+4             ; We now move on to availability, so fetch the market
                        ; item number that we stored in QQ19+4 at the start
 
 LDA #5                 ; Set A to 5 so we can print the availability to 5
                        ; digits (right-padded with spaces)

 LDX AVL,Y              ; Set X to the item's availability, which is given in
                        ; the AVL table

 STX QQ25               ; Store the availability in QQ25

 CLC                    ; Clear the carry flag
 
 BEQ TT172              ; If none are available, jump to TT172 to print a tab
                        ; and a "-"

 JSR pr2+2              ; Otherwise print the 8-bit number in X to 5 digits,
                        ; right-aligned with spaces. This works because we set
                        ; A to 5 above, and we jump into the pr2 routine just
                        ; after the first instruction, which would normally
                        ; set the number of digits to 3.
 
 JMP TT152              ; Print the unit ("t", "kg" or "g") for the market item,
                        ; with a following space if required to make it two
                        ; characters long

.TT172

 LDA XC                 ; Move the text cursor in XC to the right by 4 columns,
 ADC #4                 ; so the cursor is where the last digit would be if we
 STA XC                 ; were printing a 5-digit availability number.

 LDA #'-'               ; Print a "-" character by jumping to TT162+2, which
 BNE TT162+2            ; contains JMP TT27 (this BNE is effectively a JMP as A
                        ; will never be zero), and return from the subroutine
                        ; using a tail call
}

\ ******************************************************************************
\ Subroutine: TT152
\
\ Print the unit ("t", "kg" or "g") for the market item whose byte #1 from the
\ market prices table is in QQ19+1, right-padded with spaces to a width of two
\ characters (so that's "t ", "kg" or "g ").
\ ******************************************************************************

.TT152
{
 LDA QQ19+1             ; Fetch the economic_factor from QQ19+1

 AND #96                ; If bits 5 and 6 are both clear, jump to TT160 to
 BEQ TT160              ; print "t" for tonne, followed by a space, and return
                        ; from the subroutine using a tail call

 CMP #32                ; If bit 5 is set, jump to TT161 to print "kg" for
 BEQ TT161              ; kilograms, and return from the subroutine using a tail
                        ; call

 JSR TT16a              ; Otherwise call TT16a to print "g" for grams, and fall
                        ; through into TT162 to print a space and return from
                        ; the subroutine
}

\ ******************************************************************************
\ Subroutine: TT162
\
\ Print a space.
\ ******************************************************************************

.TT162
{
 LDA #' '               ; Load a space character into A

 JMP TT27               ; Print the text token in A and return from the
                        ; subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: TT160
\
\ Print "t" (for tonne) and a space.
\ ******************************************************************************

.TT160
{
 LDA #'t'               ; Load a "t" character into A

 JSR TT26               ; Print the character, using TT216 so that it doesn't
                        ; change the character case

 BCC TT162              ; Jump to TT162 to print a space and return from the
                        ; subroutine using a tail call (this BCC is effectively
                        ; a JMP as carry is cleared by TT26)
}

\ ******************************************************************************
\ Subroutine: TT161
\
\ Print "kg" (for kilograms).
\ ******************************************************************************

.TT161
{
 LDA #'k'               ; Load a "k" character into A

 JSR TT26               ; Print the character, using TT216 so that it doesn't
                        ; change the character case, and fall through into
                        ; TT16a to print a "g" character
}

\ ******************************************************************************
\ Subroutine: TT16a
\
\ Print "g" (for grams).
\ ******************************************************************************

.TT16a
{
 LDA #&67               ; Load a "k" character into A

 JMP TT26               ; Print the character, using TT216 so that it doesn't
                        ; change the character case, and return from the
                        ; subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: TT163
\
\ Print the column headers for the prices table in the Buy Cargo and Market
\ Price screens.
\ ******************************************************************************

.TT163
{
 LDA #17                ; Move the text cursor in XC to column 17
 STA XC

 LDA #255               ; Print recursive token 95 token ("UNIT  QUANTITY
 BNE TT162+2            ; {crlf} PRODUCT   UNIT PRICE FOR SALE{crlf}{lf}") by
                        ; jumping to TT162+2, which contains JMP TT27 (this BNE
                        ; is effectively a JMP as A will never be zero), and
                        ; return from the subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: TT167
\
\ Show the Market Price screen (red key f7).
\ ******************************************************************************

.TT167
{
 LDA #16                ; Clear the top part of the screen, draw a box border,
 JSR TT66               ; and set the current view type in QQ11 to 16 (Market
                        ; Price screen)

 LDA #5                 ; Move the text cursor to column 4
 STA XC

 LDA #167               ; Print recursive token 7 token ("{current system name}
 JSR NLIN3              ; MARKET PRICES") and draw a horizontal line at pixel
                        ; row 19 to box in the title

 LDA #3                 ; Move the text cursor to row 3
 STA YC

 JSR TT163              ; Print the column headers for the prices table

 LDA #0                 ; We're going to loop through all the available market
 STA QQ29               ; items, so we set up a counter in QQ29 to denote the
                        ; current item and start it at 0

.TT168

 LDX #128               ; Set QQ17 = 128 to switch to Sentence Case, with the
 STX QQ17               ; next letter in capitals

 JSR TT151              ; Call TT151 to print the item name, market price and
                        ; availability of the current item, and set QQ24 to the
                        ; item's price / 4, QQ25 to the quantity available and
                        ; QQ19+1 to byte #1 from the market prices table for
                        ; this item

 INC YC                 ; Move the text cursor down one row

 INC QQ29               ; Increment QQ29 to point to the next item

 LDA QQ29               ; If QQ29 >= 17 then jump to TT168 as we have done the
 CMP #17                ; last item
 BCC TT168

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: var
\
\ Set QQ19+3 = economy * |economic_factor|, given byte #1 of the market prices
\ table for an item. Also sets the availability of Alien Items to 0.
\
\ Arguments:
\
\   QQ19+1      Byte #1 of the market prices table for this market item (which
\               contains the economic_factor in bits 0-5, and the sign of the
\               economic_factor in bit 7)
\ ******************************************************************************

.var
{
 LDA QQ19+1             ; Extract bits 0-5 from QQ19+1 into A, to get the
 AND #31                ; economic_factor without its sign, in other words:
                        ;
                        ;   A = |economic_factor|

 LDY QQ28               ; Set Y to the economy byte of the current system
 
 STA QQ19+2             ; Store A in QQ19+2

 CLC                    ; Clear the carry flag so we can do additions below

 LDA #0                 ; Set AVL+16 (availability of Alien Items) to 0,
 STA AVL+16             ; setting A to 0 in the process

.TT153                  ; We now do the multiplication by doing a series of
                        ; additions in a loop, building the result in A. Each
                        ; loop adds QQ19+2 (|economic_factor|) to A, and it
                        ; loops the number of times given by the economy byte;
                        ; in other words, because A starts at 0, this sets:
                        ;
                        ;   A = economy * |economic_factor|

 DEY                    ; Decrement the economy in Y, exiting the loop when it
 BMI TT154              ; becomes negative

 ADC QQ19+2             ; Add QQ19+2 to A

 JMP TT153              ; Loop back to TT153 to do another addition

.TT154

 STA QQ19+3             ; Store the result in QQ19+3

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: hyp1
\
\ Arrive in the system closest to galactic coordinates (QQ9, QQ10).
\ ******************************************************************************

.hyp1
{
 JSR TT111              ; Select the target system closest to galactic
                        ; coordinates (QQ9, QQ10), and then fall through into
                        ; the arrival routine below
}

\ ******************************************************************************
\ Subroutine: hyp1+3
\
\ Arrive in the system at (QQ9, QQ10)
\ ******************************************************************************

{
 JSR jmp                ; move target coordinates to present
 LDX #5                 ; 6 bytes

.TT112                  ; counter X

 LDA QQ15,X             ; safehouse,X  target seeds
 STA QQ2,X              ; copied over to home seeds
 DEX                    ; next seed
 BPL TT112              ; loop X
 INX                    ; X = 0
 STX EV                 ; 0 extra vessels
 LDA QQ3                ; economy of target system
 STA QQ28               ; economy of present system
 LDA QQ5                ; Tech
 STA tek                ; techlevel-1 of present system 
 LDA QQ4                ; Government, 0 is Anarchy
 STA gov                ; gov of present system
 RTS
}

\ ******************************************************************************
\ Subroutine: GVL
\
\ Set up system market on arrival?
\ ******************************************************************************

.GVL
{
 JSR DORND              ; Set A and X to random numbers
 STA QQ26               ; random byte for each system vist (for market)
 LDX #0                 ; set up availability
 STX XX4

.hy9                    ; counter XX4  availability table

 LDA QQ23+1,X
 STA QQ19+1
 JSR var                ; slope QQ19+3  = economy * gradient
 LDA QQ23+3,X           ; byte3 of Market Prxs info
 AND QQ26               ; random byte for system market
 CLC                    ; masked by market byte3
 ADC QQ23+2,X           ; base price byte2 of Market Prxs info
 LDY QQ19+1
 BMI TT157              ; -ve byte1
 SEC                    ; else subtract
 SBC QQ19+3             ; slope
 JMP TT158              ; hop over to both avail

.TT157                  ; -ve byte1

 CLC                    ; add slope
 ADC QQ19+3

.TT158                  ; both avail

 BPL TT159
 LDA #0                 ; else negative avail, set to zero.

.TT159                  ; both options arrive here

 LDY XX4                ; counter as index
 AND #63                ; take lower 6 bits as quantity available
 STA AVL,Y              ; availability
 INY                    ; next item
 TYA                    ; counter
 STA XX4
 ASL A                  ; build index
 ASL A                  ; *=4
 TAX                    ; X = Y*4 to index table
 CMP #63                ; XX4 < 63?
 BCC hy9                ; loop XX4 availability
}

.hyR
{
 RTS
}

\ ******************************************************************************
\ Subroutine: GTHG
\
\ Get Thargoid ship
\ ******************************************************************************

.GTHG                   ; get Thargoid ship
{
 JSR Ze                 ; Zero for new ship, new inwk coords, ends with dornd and T1 = rnd too.
 LDA #&FF               ; ai attack everyone, has ecm.
 STA INWK+32
 LDA #THG               ; thargoid ship
 JSR NWSHP              ; new ship type Acc
 LDA #TGL               ; accompanying thargon
 JMP NWSHP              ; new ship type Acc
}

.ptg                    ; shift forced hyperspace misjump
{
 LSR COK                ; Set bit 0 of COK, the competition code
 SEC
 ROL COK
}

\ ******************************************************************************
\ Subroutine: MJP
\
\ Miss-jump to Thargoids in witchspace
\ ******************************************************************************

.MJP                    ; miss jump
{
\LDA #1                 ; not required as this is present at TT66-2
 JSR TT66-2             ; box border with QQ11 set to A = 1
 JSR LL164              ; hyperspace noise and tunnel
 JSR RES2               ; reset2
 STY MJ                 ; mis-jump flag set #&FF

.MJP1                   ; counter MANY + #29 thargoids

 JSR GTHG               ; get Thargoid ship
 LDA #3                 ; 3 Thargoid ships
 CMP MANY+THG           ; thargoids
 BCS MJP1               ; loop if thargoids < 3
 STA NOSTM              ; number of stars, dust = 3
 LDX #0                 ; forward view
 JSR LOOK1
 LDA QQ1                ; present Y
 EOR #31                ; flip lower y coord bits
 STA QQ1
 RTS
}

\ ******************************************************************************
\ Subroutine: TT18
\
\ Countdown finished, (try) go through Hyperspace
\ ******************************************************************************

.TT18                   ; HSPC \ their comment \ Countdown finished, (try) go through Hyperspace
{
 LDA QQ14               ; ship fuel #70 = #&46
 SEC                    ; Subtract distance in 0.1 LY units
 SBC QQ8
 STA QQ14
 LDA QQ11
 BNE ee5                ; menu i.d. not a space view
 JSR TT66               ; else box border with QQ11 set to Acc
 JSR LL164              ; hyperspace noise and tunnel

.ee5                    ; not a space view

 JSR CTRL               ; scan from ctrl on keyboard
 AND PATG               ; PATG = &FF if credits have been enabled
 BMI ptg                ; shift key forced misjump, up.
 JSR DORND              ; Set A and X to random numbers
 CMP #253               ; also small chance that
 BCS MJP                ; miss-jump to Thargoids in witchspace
 \JSR TT111
 JSR hyp1+3             ; else don't move to QQ9,10 but do Arrive in system.
 JSR GVL
 JSR RES2               ; reset2, MJ flag cleared.
 JSR SOLAR              ; Set up planet and sun

 LDA QQ11
 AND #63                ; menu i.d. not space views, but maybe charts.
 BNE hyR                ; rts
 JSR TTX66              ; else new box for space view or new chart.
 LDA QQ11
 BNE TT114              ; menu i.d. not space view, a new chart.
 INC QQ11               ; else space, menu id = 1 for new dust view.
}

\ ******************************************************************************
\ Subroutine: TT110
\
\ Launch ship decision. Also arrive here after galactic hyperdrive jump, and
\ after f0 hit.
\ ******************************************************************************

.TT110                  ; Launch ship decision. Also arrive here after galactic hyperdrive jump, and after f0 hit.
{
 LDX QQ12               ; Docked flag
 BEQ NLUNCH             ; not launched
 JSR LAUN               ; launched from space station
 JSR RES2               ; reset2, small reset.

 JSR TT111              ; Select the target system closest to galactic
                        ; coordinates (QQ9, QQ10)

 INC INWK+8             ; zsg, push away planet in front.
 JSR SOS1               ; set up planet
 LDA #128               ; space station behind you
 STA INWK+8
 INC INWK+7             ; zhi=1
 JSR NWSPS              ; New space station at INWK, S bulb appears.
 LDA #12                ; launch speed
 STA DELTA
 JSR BAD                ; scan for QQ20(3,6,10), 32 tons of Slaves, Narcotics
 ORA FIST               ; fugitive/innocent status
 STA FIST

.NLUNCH                 ; also not launched

 LDX #0                 ; forward
 STX QQ12               ; check messages
 JMP LOOK1              ; start view Xreg = 0
}

.TT114                  ; not space view, a chart.
{
 BMI TT115              ; menu i.d. bit7 Short range chart

 JMP TT22               ; else Long range galactic chart

.TT115                  ; Short range chart

 JMP TT23               ; Short range chart
}

\ ******************************************************************************
\ Subroutine: LCASH
\
\ Subtract (Y X) cash from the cash pot in CASH, but only if there is enough
\ cash in the pot. As CASH is a four-byte number, this calculates:
\
\   CASH(0 1 2 3) = CASH(0 1 2 3) - (0 0 Y X)
\
\ Returns:
\
\   C flag      If set, there was enough cash to do the subtraction
\
\               If clear, there was not enough cash to do the subtraction
\ ******************************************************************************

.LCASH
{
 STX T1                 ; Subtract the least significant bytes:
 LDA CASH+3             ;
 SEC                    ;   CASH+3 = CASH+3 - X
 SBC T1
 STA CASH+3

 STY T1                 ; Then the second most significant bytes:
 LDA CASH+2             ;
 SBC T1                 ;   CASH+2 = CASH+2 - Y
 STA CASH+2

 LDA CASH+1             ; Then the third most significant bytes (which are 0):
 SBC #0                 ;
 STA CASH+1             ;   CASH+1 = CASH+1 - 0

 LDA CASH               ; And finally the most significant bytes (which are 0):
 SBC #0                 ;
 STA CASH               ;   CASH = CASH - 0

 BCS TT113              ; If the C flag is set then the subtraction didn't
                        ; underflow, so the value in CASH is correct and we can
                        ; jump to TT113 to return from the subroutine with the
                        ; C flag set to indicate success (as TT113 contains an
                        ; RTS)

                        ; Otherwise we didn't have enough cash in CASH to
                        ; subtract (Y X) from it, so fall through into
                        ; MCASH to reverse the sum and restore the original
                        ; value in CASH, and returning with the C flag clear
}

\ ******************************************************************************
\ Subroutine: MCASH
\
\ Other entry points: TT113 (RTS)
\
\ Add (Y X) cash to the cash pot in CASH. As CASH is a four-byte number, this
\ calculates:
\
\   CASH(0 1 2 3) = CASH(0 1 2 3) + (0 0 Y X)
\ ******************************************************************************

.MCASH
{
 TXA                    ; Add the least significant bytes:
 CLC                    ;
 ADC CASH+3             ;   CASH+3 = CASH+3 + X
 STA CASH+3

 TYA                    ; Then the second most significant bytes:
 ADC CASH+2             ;
 STA CASH+2             ;   CASH+2 = CASH+2 + Y

 LDA CASH+1             ; Then the third most significant bytes (which are 0):
 ADC #0                 ;
 STA CASH+1             ;   CASH+1 = CASH+1 + 0

 LDA CASH               ; And finally the most significant bytes (which are 0):
 ADC #0                 ;
 STA CASH               ;   CASH = CASH + 0

 CLC                    ; Clear the C flag, so if the above was done following
                        ; a failed LCASH call, the C flag correctly indicates
                        ; failure

.^TT113

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: GCASH
\
\ Calculate the following multiplication of unsigned 8-bit numbers:
\
\   (Y X) = P * Q * 4
\ ******************************************************************************

.GCASH
{
 JSR MULTU              ; Call MULTU to calculate (A P) = P * Q
}

\ ******************************************************************************
\ Subroutine: GC2
\
\ Calculate the following multiplication of unsigned 16-bit numbers:
\
\   (Y X) = (A P) * 4
\ ******************************************************************************

.GC2
{
 ASL P                  ; Set (A P) = (A P) * 4
 ROL A
 ASL P
 ROL A

 TAY                    ; Set (Y X) = (A P)
 LDX P

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: EQSHP
\
\ Other entry points: err
\
\ Show the Equip Ship screen (red key f3).
\ ******************************************************************************

{
.bay

 JMP BAY                ; Go to the docking bay (i.e. show the Status Mode
                        ; screen)

.^EQSHP

 JSR DIALS              ; Call DIALS to update the dashboard

 LDA #32                ; Clear the top part of the screen, draw a box border,
 JSR TT66               ; and set the current view type in QQ11 to 32 (Equip
                        ; Ship screen)

 LDA #12                ; Move the text cursor to column 12
 STA XC

 LDA #207               ; Print recursive token 47 ("EQUIP") followed by a space
 JSR spc

 LDA #185               ; Print recursive token 25 ("SHIP") and draw a
 JSR NLIN3              ; horizontal line at pixel row 19 to box in the title

 LDA #128               ; Set QQ17 = 128 to switch to Sentence Case, with the
 STA QQ17               ; next letter in capitals

 INC YC                 ; Move the text cursor down one line

 LDA tek                ; Fetch the tech level of the current system from tek
 CLC                    ; and add 3 (the tech level is stored as 0-14, so A is
 ADC #3                 ; now set to between 3 and 17)

 CMP #12                ; If A >= 12 then set A = 12, so A is now set to between
 BCC P%+4               ; 3 and 12
 LDA #12

 STA Q                  ; Set QQ25 = A (so QQ25 is in the range 3-12 and
 STA QQ25               ; represents number of the most advanced item available
 INC Q                  ; in this system, which we can pass to gnum below when
                        ; asking which item we want to buy)
                        ;
                        ; Set Q = A + 1 (so Q is in the range 4-13 and contains
                        ; QQ25 + 1, i.e. the highest item number on sale + 1)
 
 LDA #70                ; Set A = 70 - QQ14, where QQ14 contains the current
 SEC                    ; level in light years * 10, so this leaves the amount
 SBC QQ14               ; of fuel we need to fill 'er up (in light years * 10)

 ASL A                  ; The price of fuel is always 2 Cr per light year, so we
 STA PRXS               ; double A and store it in PRXS, as the first price in
                        ; the price list (which is reserved for fuel), and
                        ; because the table contains prices as price * 10, it's
                        ; in the right format (so a full tank, or 7.0 light
                        ; years, would be 14.0 Cr, or a PRXS value of 140)

 LDX #1                 ; We are now going to work our way through the equipment
                        ; price list at PRXS, printing out the equipment that is
                        ; available at this station, so set a counter in X,
                        ; starting at 1, to hold the number of the current item
                        ; plus 1 (so the item number in X loops through 1-13)

.EQL1

 STX XX13               ; Store the current item number + 1 in XX13

 JSR TT67               ; Print a newline

 LDX XX13               ; Print the current item number + 1 to 3 digits, left-
 CLC                    ; padding with spaces, and with no decimal point, so the
 JSR pr2                ; items are numbered from 1

 JSR TT162              ; Print a space

 LDA XX13               ; Print recursive token 104 + XX13, which will be in the
 CLC                    ; range 105 ("FUEL") to 116 ("GALACTIC HYPERSPACE ")
 ADC #104               ; so this prints the current item's name
 JSR TT27

 LDA XX13               ; Call prx-3 to set (Y X) to the price of the item with
 JSR prx-3              ; number XX13 - 1 (as XX13 contains the item number + 1)

 SEC                    ; Set the C flag so we will print a decimal point when
                        ; we print the price

 LDA #25                ; Move the text cursor to column 25
 STA XC

 LDA #6                 ; Print the number in (Y X) to 6 digits, left-padding
 JSR TT11               ; with spaces and including a decimal point, which will
                        ; be the correct price for this item as (Y X) contains
                        ; the price * 10, so the trailing zero will go after the
                        ; decimal point (i.e. 5250 will be printed as 525.0)

 LDX XX13               ; Increment the current item number in XX13
 INX

 CPX Q                  ; If X < Q, loop back up to print the next item on the
 BCC EQL1               ; list of equipment available at this station

 JSR CLYNS              ; Clear the bottom three text rows of the upper screen,
                        ; and move the text cursor to column 1 on row 21, i.e.
                        ; the start of the top row of the three bottom rows

 LDA #127               ; Print recursive token 127 ("ITEM") followed by a
 JSR prq                ; question mark

 JSR gnum               ; Call gnum to get a number from the keyboard, which
                        ; will be the number of the item we want to purchase,
                        ; returning the number entered in A and R, and setting
                        ; the C flag if the number is bigger than the highest
                        ; item number in QQ25

 BEQ bay                ; If no number was entered, jump up to bay to go to the
                        ; docking bay (i.e. show the Status Mode screen)

 BCS bay                ; If the number entered was too big, jump up to bay to
                        ; go to the docking bay (i.e. show the Status Mode
                        ; screen)

 SBC #0                 ; Set A to the number entered - 1 (because the C flag is
                        ; clear), which will be the actual item number we want
                        ; to buy
 
 LDX #2                 ; Move the text cursor to column 2 on the next line
 STX XC
 INC YC

 PHA                    ; While preserving the value in A, call eq to subtract
 JSR eq                 ; the price of the item we want to buy (which is in A)
 PLA                    ; from our cash pot, but only if we have enough cash in
                        ; the pot. If we don't have enough cash, exit to the
                        ; docking bay (i.e. show the Status Mode screen).

 BNE et0                ; If A is not 0 (i.e. the item we've just bought is not
                        ; fuel), skip to et0

 STA MCNT               ; We just bought fuel, so we zero the main loop counter

 LDX #70                ; And set the current fuel level * 10 in QQ14 to 70, or
 STX QQ14               ; 7.0 light years (a full tank)

.et0

 CMP #1                 ; If A is not 1 (i.e. the item we've just bought is not
 BNE et1                ; a missile), skip to et1

 LDX NOMSL              ; Fetch the current number of missiles from NOMSL into X

 INX                    ; Increment X to the new number of missiles

 LDY #117               ; Set Y to recursive token 117 ("ALL")

 CPX #5                 ; If buying this missile would give us 5 missiles, this
 BCS pres               ; is more than the maximum of 4 missiles that we can
                        ; fit, so jump to pres to show the error "All Present",
                        ; beep and exit to the docking bay (i.e. show the Status
                        ; Mode screen)

 STX NOMSL              ; Otherwise update the number of missiles in NOMSL

 JSR msblob             ; And call msblob to update the dashboard's missile
                        ; indicators with our new purchase

.et1

 LDY #107               ; Set Y to recursive token 107 ("LARGE CARGO{switch to
                        ; sentence case} BAY")

 CMP #2                 ; If A is not 2 (i.e. the item we've just bought is not
 BNE et2                ; a large cargo bay), skip to et2

 LDX #37                ; If our current cargo capacity in CRGO is 37, then we
 CPX CRGO               ; already have a large cargo bay fitted, so jump to pres
 BEQ pres               ; to show the error "Large Cargo Bay Present", beep and
                        ; exit to the docking bay (i.e. show the Status Mode
                        ; screen)

 STX CRGO               ; Otherwise we just scored ourselves a large cargo bay,
                        ; so update our current cargo capacity in CRGO to 37

.et2

 CMP #3                 ; If A is not 3 (i.e. the item we've just bought is not
 BNE et3                ; an E.C.M. system), skip to et3

 INY                    ; Increment Y to recursive token 108 ("E.C.M.SYSTEM")

 LDX ECM                ; If we already have an E.C.M. fitted (i.e. ECM is
 BNE pres               ; non-zero), jump to pres to show the error "E.C.M.
                        ; System Present", beep and exit to the docking bay
                        ; (i.e. show the Status Mode screen)

 DEC ECM                ; Otherwise we just took delivery of a brand new E.C.M.
                        ; system, so set ECM to &FF (as ECM was 0 before the DEC
                        ; instruction)

.et3

 CMP #4                 ; If A is not 4 (i.e. the item we've just bought is not
 BNE et4                ; an extra pulse laser), skip to et4

 JSR qv                 ; Print a menu listing the four available laser mounts,
                        ; with a "View ?" prompt, and ask for a view number,
                        ; returned in X (which now contains 0-3)

 LDA #4                 ; This instruction doesn't appear to do anything, as we
                        ; either don't need it (if we already have this laser)
                        ; or we set A to 4 below (if we buy it)

 LDY LASER,X            ; If there is no laser mounted in the chosen view (i.e.
 BEQ ed4                ; LASER+X, which contains the laser power for mount X,
                        ; is zero), jump to ed4 to buy a pulse laser

.ed7

 LDY #187               ; Otherwise we already have a laser mounted in this
 BNE pres               ; view, so jump to pres with Y set to token 27
                        ; (" LASER") to show the error "Laser Present", beep
                        ; and exit to the docking bay (i.e. show the Status
                        ; Mode screen)

.ed4

 LDA #POW               ; We just bought a pulse laser for view X, so we need
 STA LASER,X            ; to mount it by storing the laser power for a pulse
                        ; laser (given in POW) in LASER+X

 LDA #4                 ; Set A to 4 as we just overwrote the original value,
                        ; and we still need it set correctly so we can continue
                        ; through the conditional statements for all the other
                        ; equipment

.et4

 CMP #5                 ; If A is not 5 (i.e. the item we've just bought is not
 BNE et5                ; an extra beam laser), skip to et5

 JSR qv                 ; Print a menu listing the four available laser mounts,
                        ; with a "View ?" prompt, and ask for a view number,
                        ; returned in X (which now contains 0-3)

 STX T1                 ; Store the view in T1 so we can retrieve it below

 LDA #5                 ; Set A to 5 as the call to qv will have overwritten
                        ; the original value, and we still need it set
                        ; correctly so we can continue through the conditional
                        ; statements for all the other equipment

 LDY LASER,X            ; If there is no laser mounted in the chosen view (i.e.
 BEQ ed5                ; LASER+X, which contains the laser power for mount X,
                        ; is zero), jump to ed5 to buy a beam laser

\BPL P%+4               ; This instruction is commented out in the original
                        ; source, though it would have no effect (it would
                        ; simply skip the BMI if A is positive, which is what
                        ; BMI does anyway)

 BMI ed7                ; If there is a beam laser already mounted in the chosen
                        ; view (i.e. LASER+X has bit 7 set, which indicates a
                        ; beam laser rather than a pulse laser), skip back to
                        ; ed7 to print a "Laser Present" error, beep and exit
                        ; to the docking bay (i.e. show the Status Mode screen)

 LDA #4                 ; If we get here then we already have a pulse laser in
 JSR prx                ; the selected view, so we call prx to set (Y X) to the
                        ; price of equipment item number 4 (extra pulse laser)
                        ; so we can give a refund of the pulse laser
                        
 JSR MCASH              ; Add (Y X) cash to the cash pot in CASH, so we refund
                        ; the price of the pulse laser we are exchanging for a
                        ; new beam laser

.ed5

 LDA #POW+128           ; We just bought a beam laser for view X, so we need
 LDX T1                 ; to mount it by storing the laser power for a beam
 STA LASER,X            ; laser (given in POW+128) in LASER+X, using the view
                        ; number we stored in T1 earlier, as the call to prx
                        ; will have overwritten the original value in X


.et5

 LDY #111               ; Set Y to recursive token 107 ("FUEL SCOOPS")

 CMP #6                 ; If A is not 6 (i.e. the item we've just bought is not
 BNE et6                ; a fuel scoop), skip to et6

 LDX BST                ; If we already have fuel scoops fitted (i.e. BST is
 BEQ ed9                ; zero), jump to ed9, otherwise fall through into pres
                        ; to show the error "Fuel Scoops Present", beep and
                        ; exit to the docking bay (i.e. show the Status Mode
                        ; screen)

.pres                   ; If we get here we need to show an error to say that
                        ; item number A is already present, where the item's
                        ; name is recursive token Y

 STY K                  ; Store the item's name in K                        

 JSR prx                ; Call prx to set (Y X) to the price of equipment item
                        ; number A

 JSR MCASH              ; Add (Y X) cash to the cash pot in CASH, as the station
                        ; already took the money for this item in the JSR eq
                        ; instruction above, but we can't fit the item, so need
                        ; our money back

 LDA K                  ; Print the recursive token in K (the item's name)
 JSR spc                ; followed by a space

 LDA #31                ; Print recursive token 145 ("PRESENT")
 JSR TT27

.^err

 JSR dn2                ; Call dn2 to make a short, high beep and delay for 1
                        ; second

 JMP BAY                ; Jump to BAY to go to the docking bay (i.e. show the
                        ; Status Mode screen)

.ed9

 DEC BST                ; We just bought a shiny new fuel scoop, so set BST to
                        ; &FF (as BST was 0 before the jump to ed9 above)

.et6

 INY                    ; Increment Y to recursive token 112 ("E.C.M.SYSTEM")

 CMP #7                 ; If A is not 7 (i.e. the item we've just bought is not
 BNE et7                ; an escape pod), skip to et7

 LDX ESCP               ; If we already have an escape pod fitted (i.e. ESCP is
 BNE pres               ; non-zero), jump to pres to show the error "Escape Pod
                        ; Present", beep and exit to the docking bay (i.e. show
                        ; the Status Mode screen)

 DEC ESCP               ; Otherwise we just bought an escape pod, so set ESCP
                        ; to &FF (as ESCP was 0 before the DEC instruction)

.et7

 INY                    ; Increment Y to recursive token 113 ("ENERGY BOMB")

 CMP #8                 ; If A is not 8 (i.e. the item we've just bought is not
 BNE et8                ; an energy bomb), skip to et8

 LDX BOMB               ; If we already have an energy bomb fitted (i.e. BOMB
 BNE pres               ; is non-zero), jump to pres to show the error "Energy
                        ; Bomb Present", beep and exit to the docking bay (i.e.
                        ; show the Status Mode screen)

 LDX #&7F               ; Otherwise we just bought an energy bomb, so set BOMB
 STX BOMB               ; to &7F

.et8

 INY                    ; Increment Y to recursive token 114 ("ENERGY UNIT")

 CMP #9                 ; If A is not 9 (i.e. the item we've just bought is not
 BNE etA                ; an energy unit), skip to etA

 LDX ENGY               ; If we already have an energy unit fitted (i.e. ENGY is
 BNE pres               ; non-zero), jump to pres to show the error "Energy Unit
                        ; Present", beep and exit to the docking bay (i.e. show
                        ; the Status Mode screen)

 INC ENGY               ; Otherwise we just picked up an energy unit, so set
                        ; ENGY to 1 (as ENGY was 0 before the INC instruction)

.etA

 INY                    ; Increment Y to recursive token 115 ("DOCKING
                        ; COMPUTERS")

 CMP #10                ; If A is not 10 (i.e. the item we've just bought is not
 BNE etB                ; a docking computer), skip to etB

 LDX DKCMP              ; If we already have a docking computer fitted (i.e.
 BNE pres               ; DKCMP is non-zero), jump to pres to show the error 
                        ; "Docking Computer Present", beep and exit to the
                        ; docking bay (i.e. show the Status Mode screen)

 DEC DKCMP              ; Otherwise we just got hold of a docking computer, so
                        ; set DKCMP to &FF (as DKCMP was 0 before the DEC
                        ; instruction)

.etB

 INY                    ; Increment Y to recursive token 116 ("GALACTIC
                        ; HYPERSPACE ")

 CMP #11                ; If A is not 11 (i.e. the item we've just bought is not
 BNE et9                ; a galactic hyperdrive), skip to et9

 LDX GHYP               ; If we already have a galactic hyperdrive fitted (i.e.
 BNE pres               ; GHYP is non-zero), jump to pres to show the error 
                        ; "Galactic Hyperspace Present", beep and exit to the
                        ; docking bay (i.e. show the Status Mode screen)

 DEC GHYP               ; Otherwise we just splashed out on a galactic
                        ; hyperdrive, so set GHYP to &FF (as GHYP was 0 before
                        ; the DEC instruction)

.et9

 JSR dn                 ; We are done buying equipment, so print the amount of
                        ; cash left in the cash pot, then make a short, high
                        ; beep to confirm the purchase, and delay for 1 second

 JMP EQSHP              ; Jump back up to EQSHP to show the Equip Ship screen
                        ; again and see if we can't track down another bargain
}

\ ******************************************************************************
\ Subroutine: dn
\
\ Print the amount of money in the cash pot, then make a short, high beep and
\ delay for 1 second.
\ ******************************************************************************

.dn
{
 JSR TT162              ; Print a space

 LDA #119               ; Print recursive token 119 ("CASH:{cash right-aligned
 JSR spc                ; to width 9} CR{crlf}") followed by a space

                        ; Fall through into dn2 to make a beep and delay for
                        ; 1 second before returning from the subroutine
}

\ ******************************************************************************
\ Subroutine: dn2
\
\ Make a short, high beep and delay for 1 second.
\ ******************************************************************************

.dn2
{
 JSR BEEP               ; Call the BEEP subroutine to make a short, high beep

 LDY #50                ; Delay for 50 vertical syncs (50/50 = 1 second) and
 JMP DELAY              ; return from the subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: eq
\
\ If we have enough cash, subtract the price of a specified piece of equipment
\ from our cash pot and return from the subroutine. If we don't have enough
\ cash, exit to the docking bay (i.e. show the Status Mode screen).
\
\ Arguments:
\
\   A           The item number of the piece of equipment (0-11) as shown in
\               the table at PRXS
\ ******************************************************************************

.eq
{
 JSR prx                ; Call prx to set (Y X) to the price of equipment item
                        ; number A

 JSR LCASH              ; Subtract (Y X) cash from the cash pot, but only if
                        ; we have enough cash

 BCS c                  ; If the C flag is set then we did have enough cash for
                        ; the transaction, so jump to c to return from the
                        ; subroutine (as c contains an RTS)

 LDA #197               ; Otherwise we don't have enough cash to but this piece
 JSR prq                ; of equipment, so print recursive token 37 ("CASH")
                        ; followed by a question mark

 JMP err                ; Jump to err to beep, pause and go to the docking bay
                        ; (i.e. show the Status Mode screen)
}

\ ******************************************************************************
\ Subroutine: prx
\
\ Return the price of a piece of equipment, as listed in the table at PRXS.
\
\ Other entry points:
\
\   prx-3       Return the price of the item with number A - 1
\
\ Arguments:
\
\   A           The item number of the piece of equipment (0-11) as shown in
\               the table at PRXS
\
\ Returns:
\
\   (Y X)       The item price in Cr * 10 (Y = high byte, X = low byte)
\ ******************************************************************************

{
 SEC                    ; Decrement A (for when this routine is called via
 SBC #1                 ; prx-3)
 
.^prx

 ASL A                  ; Set Y = A * 2, so it can act as an index into the
 TAY                    ; PRXS table, which has two bytes per entry

 LDX PRXS,Y             ; Fetch the low byte of the price into X

 LDA PRXS+1,Y           ; Fetch the low byte of the price into A and transfer
 TAY                    ; it to X, so the price is now in (Y X)

.^c

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: qv
\
\ Print a menu in the bottom-middle of the screen, at row 16, column 12, that
\ lists the four available laser mounts, like this:
\
\                 0 Front
\                 1 Rear
\                 2 Left
\                 3 Right
\
\ Also print a "View ?" prompt and ask for a view number. The menu is shown
\ when we choose to buy a new laser in the Equip Ship screen.
\
\ Returns:
\
\   X           The chosen view number (0-3)
\ ******************************************************************************

.qv
{
 LDY #16                ; Move the text cursor to row 16, and at the same time
 STY YC                 ; set Y to a counter going from 16-20 in the loop below

.qv1

 LDX #12                ; Move the text cursor to column 12
 STX XC

 TYA                    ; Transfer the counter value from Y to A

 CLC                    ; Print ASCII character "0" - 16 + A, so as A goes from
 ADC #'0'-16            ; 16 to 20, this prints "0" through "3" followed by a
 JSR spc                ; space

 LDA YC                 ; Print recursive text token 80 + YC, so as YC goes from
 CLC                    ; 16 to 20, this prints "FRONT", "REAR", "LEFT" and
 ADC #80                ; "RIGHT"
 JSR TT27

 INC YC                 ; Move the text cursor down a row)

 LDY YC                 ; Update Y with the incremented counter in YC

 CPY #20                ; If Y < 20 then loop back up to qv1 to print the next
 BCC qv1                ; view in the menu

.qv3

 JSR CLYNS              ; Clear the bottom three text rows of the upper screen,
                        ; and move the text cursor to column 1 on row 21, i.e.
                        ; the start of the top row of the three bottom rows

.qv2

 LDA #175               ; Print recursive text token 15 ("VIEW ") followed by
 JSR prq                ; a question mark

 JSR TT217              ; Scan the keyboard until a key is pressed, and return
                        ; the key's ASCII code in A (and X)

 SEC                    ; Subtract ASCII '0' from the key pressed, to leave the
 SBC #'0'               ; numeric value of the key in A (if it was a number key)

 CMP #4                 ; If the number entered in A >= 4, then it is not a
 BCS qv3                ; valid view number, so jump back to qv3 to try again

 TAX                    ; We have a valid view number, so transfer it to X

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Save output/ELTD.bin
\ ******************************************************************************

PRINT "ELITE D"
PRINT "Assembled at ", ~CODE_D%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_D%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_D%

PRINT "S.ELTD ", ~CODE_D%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_D%
SAVE "output/ELTD.bin", CODE_D%, P%, LOAD%

\ ******************************************************************************
\ ELITE E
\
\ Produces the binary file ELTE.bin which gets loaded by elite-bcfs.asm.
\ ******************************************************************************

CODE_E% = P%
LOAD_E% = LOAD% + P% - CODE%

MAPCHAR '(', '('EOR&A4
MAPCHAR 'C', 'C'EOR&A4
MAPCHAR ')', ')'EOR&A4
MAPCHAR 'B', 'B'EOR&A4
MAPCHAR 'e', 'e'EOR&A4
MAPCHAR 'l', 'l'EOR&A4
MAPCHAR '/', '/'EOR&A4
MAPCHAR 'r', 'r'EOR&A4
MAPCHAR 'a', 'a'EOR&A4
MAPCHAR 'b', 'b'EOR&A4
MAPCHAR 'n', 'n'EOR&A4
MAPCHAR '1', '1'EOR&A4
MAPCHAR '9', '9'EOR&A4
MAPCHAR '8', '8'EOR&A4
MAPCHAR '4', '4'EOR&A4

.BDOLLAR
 EQUS  "(C)Bell/Braben1984"

MAPCHAR '(', '('
MAPCHAR 'C', 'C'
MAPCHAR ')', ')'
MAPCHAR 'B', 'B'
MAPCHAR 'e', 'e'
MAPCHAR 'l', 'l'
MAPCHAR '/', '/'
MAPCHAR 'r', 'r'
MAPCHAR 'a', 'a'
MAPCHAR 'b', 'b'
MAPCHAR 'n', 'n'
MAPCHAR '1', '1'
MAPCHAR '9', '9'
MAPCHAR '8', '8'
MAPCHAR '4', '4'

\ ******************************************************************************
\ Subroutine: cpl
\
\ Print control code 3 (the selected system name, i.e. the one in the
\ cross-hairs in the short range chart).
\
\ ******************************************************************************
\
\ System names are generated from the three 16-bit seeds for that system. In
\ the case of the selected system, those seeds live at QQ15. The process works
\ as follows, where w0, w1, w2 are the seeds for the system in question 
\
\   1. Check bit 6 of w0_lo. If it is set then we will generate four two-letter
\      pairs for the name (8 characters in total), otherwise we will generate
\      three pairs (6 characters).
\
\   2. Generate the first two letters by taking bits 0-4 of w2_hi. If this is
\      zero, jump to the next step, otherwise we have a number in the range
\      1-31. Add 128 to get a number in the range 129-159, and convert this to
\      a two-letter token (see variable QQ18 for more on two-letter tokens).
\
\   3. Twist the seeds by calling TT54 and repeat the previous step, until we
\      have processed three or four pairs, depending on step 1.
\
\ One final note. As the process above involves twisting the seeds three or
\ four times, they will be changed, so we also need to back up the original
\ seeds before starting the above process, and restore them afterwards.
\ ******************************************************************************

.cpl
{
 LDX #5                 ; First we need to backup the seeds in QQ15, so set up
                        ; a counter in X to cover three 16-bit seeds (i.e.
                        ; 6 bytes)

.TT53

 LDA QQ15,X             ; Copy byte X from QQ15 to QQ19
 STA QQ19,X

 DEX                    ; Decrement the loop counter

 BPL TT53               ; Loop back for the next byte to backup

 LDY #3                 ; Step 1: Now that the seeds are backed up, we can
                        ; start the name-generation process. We will either
                        ; need to loop three or four times, so for now set
                        ; up a counter in Y to loop four times

 BIT QQ15               ; Check bit 6 of w0_lo, which is stored in QQ15

 BVS P%+3               ; If bit 6 is set then skip over the next instruction

 DEY                    ; Bit 6 is clear, so we only want to loop three times,
                        ; so decrement the loop counter in Y

 STY T                  ; Store the loop counter in T

.TT55

 LDA QQ15+5             ; Step 2: Load w2_hi, which is stored in QQ15+5, and
 AND #%00011111         ; extract bits 0-4 by AND-ing with %11111

 BEQ P%+7               ; If all those bits are zero, then skip the following
                        ; 2 instructions to go to step 3

 ORA #%10000000         ; We now have a number in the range 1-31, which we can
                        ; easily convert into a two-letter token, but first we
                        ; need to add 128 (or set bit 7) to get a range of
                        ; 129-159

 JSR TT27               ; Print the two-letter token in A
 
 JSR TT54               ; Step 3: twist the seeds in QQ15

 DEC T                  ; Decrement the loop counter

 BPL TT55               ; Loop back for the next two letters

 LDX #5                 ; We have printed the system name, so we can now
                        ; restore the seeds we backed up earlier. Set up a
                        ; counter in X to cover three 16-bit seeds (i.e. 6
                        ; bytes)

.TT56

 LDA QQ19,X             ; Copy byte X from QQ19 to QQ15
 STA QQ15,X

 DEX                    ; Decrement the loop counter

 BPL TT56               ; Loop back for the next byte to restore

 RTS                    ; Once all the seeds are restored, return from the
                        ; subroutine
}

\ ******************************************************************************
\ Subroutine: cmn
\
\ Print control code 4 (the commander's name).
\ ******************************************************************************

.cmn
{
 LDY #0                 ; Set up a counter in Y, starting from 0

.QUL4

 LDA NA%,Y              ; The commander's name is stored at NA%, so load the
                        ; Y-th character from NA%
 
 CMP #13                ; If we have reached the end of the name, return from
 BEQ ypl-1              ; the subroutine (ypl-1 points to the RTS below)
 
 JSR TT26               ; Print the character we just loaded
 
 INY                    ; Increment the loop counter
 
 BNE QUL4               ; Loop back for the next character
 
 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: ypl
\
\ Print control code 2 (the current system name).
\ ******************************************************************************

.ypl
{
 LDA MJ                 ; Check the mis-jump flag at MJ, and if it is non-zero
 BNE cmn-1              ; then return from the subroutine, as we are in
                        ; witchspace, and witchspace doesn't have a system name
 
 JSR TT62               ; Call TT62 below to swap the three 16-bit seeds in
                        ; QQ2 and QQ15 (before the swap, QQ2 contains the seeds
                        ; for the current system, while QQ15 contains the seeds
                        ; for the selected system)
 
 JSR cpl                ; Call cpl to print out the system name for the seeds
                        ; in QQ15 (which now contains the seeds for the current
                        ; system)

                        ; Now we fall through into the TT62 subroutine, which
                        ; will swap QQ2 and QQ15 once again, so everything goes
                        ; back into the right place, and the RTS at the end of
                        ; TT62 will return from the subroutine

.TT62

 LDX #5                 ; Set up a counter in X for the three 16-bit seeds we
                        ; want to swap (i.e. 6 bytes)

.TT78

 LDA QQ15,X             ; Swap byte X between QQ2 and QQ15
 LDY QQ2,X
 STA QQ2,X
 STY QQ15,X
 
 DEX                    ; Decrement the loop counter
 
 BPL TT78               ; Loop back for the next byte to swap
 
 RTS                    ; Once all bytes are swapped, return from the
                        ; subroutine
}

\ ******************************************************************************
\ Subroutine: tal
\
\ Print control code 1 (the current galaxy number, right-aligned to width 3).
\ ******************************************************************************

.tal
{
 CLC                    ; We don't want to print the galaxy number with a
                        ; decimal point, so clear the carry flag for pr2 to
                        ; take as an argument
 
 LDX GCNT               ; Load the current galaxy number from GCNT into X
 
 INX                    ; Add 1 to the galaxy number, as the galaxy numbers
                        ; are 0-7 internally, but we want to display them as
                        ; galaxy 1 through 8
 
 JMP pr2                ; Jump to pr2, which prints the number in X to a width
                        ; of 3 figures, left-padding with spaces to a width of
                        ; 3, and once done, return from the subroutine (as pr2
                        ; ends with an RTS)
}

\ ******************************************************************************
\ Subroutine: fwl
\
\ Print control code 5 ("FUEL: ", fuel level, " LIGHT YEARS", newline, "CASH:",
\ control code 0).
\ ******************************************************************************

.fwl
{
 LDA #105               ; Print recursive token 105 ("FUEL") followed by a
 JSR TT68               ; colon
 
 LDX QQ14               ; Load the current fuel level from QQ14

 SEC                    ; We want to print the fuel level with a decimal point,
                        ; so set the carry flag for pr2 to take as an argument

 JSR pr2                ; Call pr2, which prints the number in X to a width of
                        ; 3 figures (i.e. in the format x.x, which will always
                        ; be exactly 3 characters as the maximum fuel is 7.0)

 LDA #195               ; Print recursive token 35 ("LIGHT YEARS") followed by
 JSR plf                ; a newline

.PCASH                  ; This label is not used but is in the original source

 LDA #119               ; Print recursive token 119 ("CASH:" then control code
 BNE TT27               ; 0, which prints cash levels, then " CR" and newline)
}

\ ******************************************************************************
\ Subroutine: csh
\
\ Print control code 0 (the current amount of cash, right-aligned to width 9,
\ followed by " CR" and a newline).
\ ******************************************************************************

.csh
{
 LDX #3                 ; We are going to use the BPRNT routine to print out
                        ; the current amount of cash, which is stored as a
                        ; 32-bit number at location CASH. BPRNT prints out
                        ; the 32-bit number stored in K, so before we call
                        ; BPRNT, we need to copy the four bytes from CASH into
                        ; K, so first we set up a counter in X for the 4 bytes

.pc1

 LDA CASH,X             ; Copy byte X from CASH to K
 STA K,X

 DEX                    ; Decrement the loop counter
 
 BPL pc1                ; Loop back for the next byte to copy

 LDA #9                 ; We want to print the cash using up to 9 digits
 STA U                  ; (including the decimal point), so store this in U
                        ; for BRPNT to take as an argument
 
 SEC                    ; We want to print the fuel level with a decimal point,
                        ; so set the carry flag for BRPNT to take as an
                        ; argument

 JSR BPRNT              ; Print the amount of cash to 9 digits with a decimal
                        ; point

 LDA #226               ; Print recursive token 66 (" CR") followed by a
                        ; newline by falling through into plf
}

\ ******************************************************************************
\ Subroutine: plf
\
\ Print a text token followed by a newline.
\
\ Arguments:
\
\   A           The text token to be printed
\ ******************************************************************************

.plf
{
 JSR TT27               ; Print the text token in A

 JMP TT67               ; Jump to TT67 to print a newline and return from the
                        ; subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: TT68
\
\ Print a text token followed by a colon.
\
\ Arguments:
\
\   A           The text token to be printed
\ ******************************************************************************

.TT68
{
 JSR TT27               ; Print the text token in A and fall through into TT73
                        ; to print a colon
}

\ ******************************************************************************
\ Subroutine: TT73
\
\ Print a colon.
\ ******************************************************************************

.TT73
{
 LDA #':'               ; Set A to ASCII ":" and fall through into TT27 to
                        ; actually print the colon
}

\ ******************************************************************************
\ Subroutine: TT27
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token). See variable QQ18 for a discussion of the token system
\ used in Elite.
\
\ Arguments:
\
\   A           The text token to be printed
\ ******************************************************************************

.TT27
{
 TAX                    ; Copy the token number from A to X. We can then keep
                        ; decrementing X and testing it against zero, while
                        ; keeping the original token number intact in A; this
                        ; effectively implements a switch statement on the
                        ; value of the token

 BEQ csh                ; If token = 0, this is control code 0 (current amount
                        ; of cash and newline), so jump to csh

 BMI TT43               ; If token > 127, this is either a two-letter token
                        ; (128-159) or a recursive token (160-255), so jump
                        ; to .TT43 to process tokens

 DEX                    ; If token = 1, this is control code 1 (current
 BEQ tal                ; galaxy number), so jump to tal
 
 DEX                    ; If token = 2, this is control code 2 (current system
 BEQ ypl                ; name), so jump to ypl

 DEX                    ; If token > 3, skip the following instruction
 BNE P%+5
 
 JMP cpl                ; This token is control code 3 (selected system name)
                        ; so jump to cpl

 DEX                    ; If token = 4, this is control code 4 (commander
 BEQ cmn                ; name), so jump to cmm

 DEX                    ; If token = 5, this is control code 5 (fuel, newline,
 BEQ fwl                ; cash, newline), so jump to fwl

 DEX                    ; If token > 6, skip the following 3 instructions
 BNE P%+7

 LDA #128               ; This token is control code 6 (switch to sentence
 STA QQ17               ; case), so store 128 (bit 7 set, bit 6 clear) in QQ17,
 RTS                    ; which controls letter case, and return from the
                        ; subroutine as we are done

 DEX                    ; If token > 8, skip the following 2 instructions
 DEX
 BNE P%+5
 
 STX QQ17               ; This token is control code 8 (switch to ALL CAPS)
 RTS                    ; so store 0 in QQ17, which controls letter case, and
                        ; return from the subroutine as we are done

 DEX                    ; If token = 9, this is control code 9 (tab to column
 BEQ crlf               ; 21 and print a colon), so jump to crlf
 
 CMP #96                ; By this point, token is either 7, or in 10-127.
 BCS ex                 ; Check token number in A and if token >= 96, then the
                        ; token is in 96-127, which is a recursive token, so
                        ; jump to ex, which prints recursive tokens in this
                        ; range (i.e. where the recursive token number is
                        ; correct and doesn't need correcting)
 
 CMP #14                ; If token < 14, skip the following 2 instructions
 BCC P%+6
 
 CMP #32                ; If token < 32, then this means token is in 14-31, so
 BCC qw                 ; this is a recursive token that needs 114 adding to it
                        ; to get the recursive token number, so jump to qw
                        ; which will do this

                        ; By this point, token is either 7 (beep) or in 10-13
                        ; (line feeds and carriage returns), or in 32-95
                        ; (ASCII letters, numbers and punctuation)

 LDX QQ17               ; Fetch QQ17, which controls letter case, into X
 
 BEQ TT74               ; If QQ17 = 0, then ALL CAPS is set, so jump to TT27
                        ; to print this character as is (i.e. as a capital)

 BMI TT41               ; If QQ17 has bit 7 set, then we are using Sentence
                        ; Case, so jump to TT41, which will print the
                        ; character in upper or lower case, depending on
                        ; whether this is the first letter in a word

 BIT QQ17               ; If we get here, QQ17 is not 0 and bit 7 is clear, so
 BVS TT46               ; either it is bit 6 that is set, or some other flag in
                        ; QQ17 is set (bits 0-5). So check whether bit 6 is set.
                        ; If it is, then ALL CAPS has been set (as bit 7 is
                        ; clear) but bit 6 is still indicating that the next
                        ; character should be printed in lower case, so we need
                        ; to fix this. We do this with a jump to TT46, which
                        ; will print this character in upper case and clear bit
                        ; 6, so the flags are consistent with ALL CAPS going
                        ; forward.

                        ; If we get here, some other flag is set in QQ17 (one
                        ; of bits 0-5 is set), which shouldn't happen in this
                        ; version of Elite. If this were the case, then we
                        ; would fall through into TT42 to print in lower case,
                        ; which is how printing all words in lower case could
                        ; be supported (by setting QQ17 to 1, say).
}

\ ******************************************************************************
\ Subroutine: TT42
\
\ Other entry points: TT44
\
\ Print a letter in lower case.
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\ ******************************************************************************

.TT42
{
 CMP #'A'               ; If A < ASCII "A", then this is punctuation, so jump
 BCC TT44               ; to TT26 (via TT44) to print the character as is, as
                        ; we don't care about the character's case

 CMP #'Z' + 1           ; If A >= (ASCII "Z" + 1), then this is also
 BCS TT44               ; punctuation, so jump to TT26 (via TT44) to print the
                        ; character as is, as we don't care about the
                        ; character's case

 ADC #32                ; Add 32 to the character, to convert it from upper to
                        ; to lower case

.^TT44

 JMP TT26               ; Print the character in A
}

\ ******************************************************************************
\ Subroutine: TT41
\
\ Print a letter according to Sentence Case. The rules are as follows:
\
\   * If QQ17 bit 6 is set, print lower case (via TT45)
\
\   * If QQ17 bit 6 clear, then:
\
\       * If character is punctuation, just print it
\
\       * If character is a letter, set QQ17 bit 6 and print letter as a capital
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\
\   X           Contains the current value of QQ17
\
\   QQ17        Bit 7 is set
\ ******************************************************************************

.TT41                   ; If we get here, then QQ17 has bit 7 set, so we are in
{
                        ; Sentence Case
 
 BIT QQ17               ; If QQ17 also has bit 6 set, jump to TT45 to print
 BVS TT45               ; this character in lower case

                        ; If we get here, then QQ17 has bit 6 clear and bit 7
                        ; set, so we are in Sentence Case and we need to print
                        ; the next letter in upper case

 CMP #'A'               ; If A < ASCII "A", then this is punctuation, so jump
 BCC TT74               ; to TT26 (via TT44) to print the character as is, as
                        ; we don't care about the character's case

 PHA                    ; Otherwise this is a letter, so store the token number
 
 TXA                    ; Set bit 6 in QQ17 (X contains the current QQ17)
 ORA #%1000000          ; so the next letter after this one is printed in lower
 STA QQ17               ; case
 
 PLA                    ; Restore the token number into A
 
 BNE TT44               ; Jump to TT26 (via TT44) to print the character in A
                        ; (this BNE is effectively a JMP as A will never be
                        ; zero)
}

\ ******************************************************************************
\ Subroutine: qw
\
\ Print a recursive token where the token number is in 128-145 (so the value
\ passed to TT27 is in the range 14-31).
\
\ Arguments:
\
\   A           A value from 128-145, which refers to a recursive token in the
\               range 14-31
\ ******************************************************************************

.qw
{
 ADC #114               ; This is a recursive token in the range 0-95, so add
 BNE ex                 ; 114 to the argument to get the token number 128-145
                        ; and jump to ex to print it
}

\ ******************************************************************************
\ Subroutine: crlf
\
\ Print control code 9 (tab to column 21 and print a colon). The subroutine
\ name is pretty misleading, as it doesn't have anything to do with carriage
\ returns or line feeds.
\ ******************************************************************************

.crlf
{
 LDA #21                ; Set the X-column in XC to 21
 STA XC

 BNE TT73               ; Jump to TT73, which prints a colon (this BNE is
                        ; effectively a JMP as A will never be zero)
}

\ ******************************************************************************
\ Subroutine: TT45
\
\ Print a letter in lower case. Specifically:
\
\   * If QQ17 = &FF, abort printing this character
\
\   * If a letter then print in lower case
\
\   * Otherwise this is punctuation, so clear bit 6 in QQ17 and print
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\
\   X           Contains the current value of QQ17
\
\   QQ17        Bits 6 and 7 are set
\ ******************************************************************************

.TT45                   ; If we get here, then QQ17 has bit 6 and 7 set, so we
{
                        ; are in Sentence Case and we need to print the next
                        ; letter in lower case

 CPX #&FF               ; If QQ17 = #&FF then return from the subroutine (as
 BEQ TT48               ; TT48 contains an RTS)

 CMP #'A'               ; If A >= ASCII "A", then jump to TT42, which will
 BCS TT42               ; print the letter in lowercase
 
                        ; Otherwise this is not a letter, it's punctuation, so
                        ; this is effectively a word break. We therefore fall
                        ; through to TT46 to print the character and set QQ17
                        ; to ensure the next word starts with a capital letter
}

\ ******************************************************************************
\ Subroutine: TT46
\
\ Print character and clear bit 6 in QQ17, so that the next letter that gets
\ printed after this will start with a capital letter.
\
\ Arguments:
\
\   A           The character to be printed. Can be one of the following:
\
\                 * 7 (beep)
\
\                 * 10-13 (line feeds and carriage returns)
\
\                 * 32-95 (ASCII capital letters, numbers and punctuation)
\
\   X           Contains the current value of QQ17
\
\   QQ17        Bits 6 and 7 are set
\ ******************************************************************************

.TT46
{
 PHA                    ; Store the token number
 
 TXA                    ; Clear bit 6 in QQ17 (X contains the current QQ17)
 AND #191               ; so the next letter after this one is printed in upper
 STA QQ17               ; case
 
 PLA                    ; Restore the token number into A

                        ; Now fall through into TT74 to print the character
}

\ ******************************************************************************
\ Subroutine: TT74
\
\ Print a character.
\
\ Arguments:
\
\   A           The character to be printed
\ ******************************************************************************

.TT74
{
 JMP TT26               ; Print the character in A
}

\ ******************************************************************************
\ Subroutine: TT43
\
\ Print a two-letter token, or a recursive token where the token number is in
\ 0-95 (so the value passed to TT27 is in the range 160-255).
\
\ Arguments:
\
\   A           One of the following:
\                 * 128-159 (two-letter token)
\                 * 160-255 (the argument to TT27 that refers to a recursive
\                   token in the range 0-95)
\ ******************************************************************************

.TT43
{
 CMP #160               ; If token >= 160, then this is a recursive token, so
 BCS TT47               ; jump to TT47 below to process it

 AND #127               ; This is a two-letter token with number 128-159. The
 ASL A                  ; set of two-letter tokens is stored as one long string
                        ; ("ALLEXEGE...") at QQ16, so to convert this into the
                        ; token's position in this string, we subtract 128 (or
                        ; just clear bit 7) and multiply by 2 (or shift left)

 TAY                    ; Transfer the token's position into Y so we can look
                        ; up the token using absolute indexed mode

 LDA QQ16,Y             ; Get the first letter of the token and print it
 JSR TT27

 LDA QQ16+1,Y           ; Get the second letter of the token

 CMP #'?'               ; If the second letter of the token is a question mark
 BEQ TT48               ; then this is a one-letter token, so just return from
                        ; the subroutine without printing (as TT48 contains an
                        ; RTS)

 JMP TT27               ; Print the second letter and return from the
                        ; subroutine

.TT47

 SBC #160               ; This is a recursive token in the range 160-255, so
                        ; subtract 160 from the argument to get the token
                        ; number 0-95 and fall through into ex to print it
}

\ ******************************************************************************
\ Subroutine: ex
\
\ Other entry points: TT48 (RTS)
\
\ Print a recursive token.
\
\ Arguments:
\
\   A           The recursive token to be printed, in the range 0-148
\
\ ******************************************************************************
\
\ This routine works its way through the recursive tokens that are stored in
\ tokenised form in memory at &0400 - &06FF, and when it finds token number A,
\ it prints it. Tokens are null-terminated in memory and fill three pages,
\ but there is no lookup table as that would consume too much memory, so the
\ only way to find the correct token is to start at the beginning and look
\ through the table byte by byte, counting tokens as we go until we are in the
\ right place. This approach might not be terribly speed efficient, but it is
\ certainly memory-efficient.
\
\ The variable QQ18 points to the token table at &0400.
\
\ For details of the tokenisation system, see variable QQ18.
\ ******************************************************************************

.ex
{
 TAX                    ; Copy the token number into X

 LDA #LO(QQ18)          ; Set V, V+1 to point to the recursive token table at
 STA V                  ; location QQ18
 LDA #HI(QQ18)
 STA V+1

 LDY #0                 ; Set a counter Y to point to the character offset
                        ; as we scan through the table

 TXA                    ; Copy the token number back into A, so both A and X
                        ; now contain the token number we want to print

 BEQ TT50               ; If the token number we want is 0, then we have
                        ; already found the token we are looking for, so jump
                        ; to TT50, otherwise start working our way through the
                        ; null-terminated token table until we find the X-th
                        ; token

.TT51

 LDA (V),Y              ; Fetch the Y-th character from the token table page
                        ; we are currently scanning

 BEQ TT49               ; If the character is null, we've reached the end of
                        ; this token, so jump to TT49

 INY                    ; Increment character pointer and loop back round for
 BNE TT51               ; the next character in this token, assuming Y hasn't
                        ; yet wrapped around to 0

 INC V+1                ; If it has wrapped round to 0, we have just crossed
 BNE TT51               ; into a new page, so increment V+1 so that V points
                        ; to the start of the new page

.TT49

 INY                    ; Increment the character pointer

 BNE TT59               ; If Y hasn't just wrapped around to 0, skip the next
                        ; instruction

 INC V+1                ; We have just crossed into a new page, so increment
                        ; V+1 so that V points to the start of the new page

.TT59

 DEX                    ; We have just reached a new token, so decrement the
                        ; token number we are looking for

 BNE TT51               ; Assuming we haven't yet reached the token number in
                        ; X, look back up to keep fetching characters

.TT50                   ; We have now reached the correct token in the token
                        ; table, with Y pointing to the start of the token as
                        ; an offset within the page pointed to by V, so let's
                        ; print the recursive token. Because recursive tokens
                        ; can contain other recursive tokens, we need to store
                        ; our current state on the stack, so we can retrieve
                        ; it after printing each character in this token.

 TYA                    ; Store the offset in Y on the stack
 PHA

 LDA V+1                ; Store the high byte of V (the page containing the
 PHA                    ; token we have found) on the stack, so the stack now
                        ; contains the address of the start of this token

 LDA (V),Y              ; Load the character at offset Y in the token table,
                        ; which is the next character of this token that we
                        ; want to print

 EOR #35                ; Tokens are stored in memory having been EOR'd with 35
                        ; (see variable QQ18 for details), so we repeat the
                        ; EOR to get the actual character to print

 JSR TT27               ; Print the text token in A, which could be a letter,
                        ; number, control code, two-letter token or another
                        ; recursive token

 PLA                    ; Restore the high byte of V (the page containing the
 STA V+1                ; token we have found) into V+1

 PLA                    ; Restore the offset into Y
 TAY

 INY                    ; Increment Y to point to the next character in the
                        ; token we are printing

 BNE P%+4               ; If Y is zero then we have just crossed into a new
 INC V+1                ; page, so increment V+1 so that V points to the start
                        ; of the new page

 LDA (V),Y              ; Load the next character we want to print into A

 BNE TT50               ; If this is not the null character at the end of the
                        ; token, jump back up to TT50 to print the next
                        ; character, otherwise we are done printing

.^TT48

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: EX2
\
\ ready to remove - Explosion Code
\ ******************************************************************************

.EX2                    ; ready to remove - Explosion Code
{
 LDA INWK+31            ; exploding/display state|missiles
 ORA #&A0               ; bit7 to kill it, bit5 finished exploding.
 STA INWK+31
 RTS
}

\ ******************************************************************************
\ Subroutine: DOEXP
\
\ Do Explosion as bit5 set by LL9
\ ******************************************************************************

.DOEXP                  ; Do Explosion as bit5 set by LL9
{
 LDA INWK+31
 AND #64                ; display state keep bit6
 BEQ P%+5               ; exploding not started, skip ptcls
 JSR PTCLS              ; else exploding has started, remove old plot Cloud.
 LDA INWK+6             ; zlo. All do a round of cloud counter.
 STA T
 LDA INWK+7
 CMP #&20               ; zhi < 32,  boost*8
 BCC P%+6               ; skip default
 LDA #&FE               ; furthest cloud distance
 BNE yy                 ; guaranteed Cloud
 ASL T                  ; else use zlo
 ROL A                  ; *=2
 ASL T
 ROL A                  ; z lo.hi*=4
 SEC                    ; ensure cloud distance not 0
 ROL A

.yy                     ; Cloud

 STA Q                  ; cloud distance
 LDY #1                 ; get ship heap byte1, which started at #18
 LDA (XX19),Y
 ADC #4                 ; +=4 Cloud counter 
 BCS EX2                ; until overflow and ready to removed, up.

 STA (XX19),Y           ; else update Cloud counter
 JSR DVID4              ; P.R = cloud counter/cloud distance
 LDA P
 CMP #&1C               ; hi < #28 ?
 BCC P%+6               ; cloud radius < 28 skip max
 LDA #&FE               ; else max radius
 BNE LABEL_1            ; guaranteed  Acc = Cloud radius
 ASL R
 ROL A                  ; *=2
 ASL R
 ROL A                  ; *=4
 ASL R
 ROL A                  ; *=8

.LABEL_1                ; Acc = Cloud radius

 DEY                    ; Y = 0, save ship heap byte0 = Cloud radius
 STA (XX19),Y
 LDA INWK+31            ; display explosion state|missiles
 AND #&BF               ; clear bit6 in case can't start
 STA INWK+31
 AND #8                 ; keep bit3 of display state, something to erase?
 BEQ TT48               ; rts, up.

 LDY #2                 ; else ship heap byte2 = hull byte#7 dust
 LDA (XX19),Y
 TAY                    ; Y counter multiples of 4, greater than 6.

.EXL1                   ; counter Y

 LDA XX3-7,Y            ; from (all visible) vertex heap
 STA (XX19),Y           ; to ship heap
 DEY                    ; next vertex
 CPY #6                 ; until down to 7
 BNE EXL1               ; loop Y
 LDA INWK+31
 ORA #64                ; set bit6 so this dust will be erased
 STA INWK+31

.PTCLS                  ; plot Cloud

 LDY #0                 ; ship heap byte0 = Cloud radius
 LDA (XX19),Y
 STA Q                  ; Cloud radius
 INY                    ; ship byte1 = Cloud counter
 LDA (XX19),Y
 BPL P%+4               ; Cloud counter not half way, skip flip
 EOR #&FF               ; else more than half way through cloud counter
 LSR A
 LSR A
 LSR A                  ; cloud counter/8 max = 15 pixels
                        ; pixel count set
 ORA #1                 ; 1 min
 STA U                  ; number of pixels per vertex
 INY                    ; ship byte2 = dust = counter target
 LDA (XX19),Y
 STA TGT                ; = hull byte#7 dust = counter target
 LDA RAND+1
 PHA                    ; restrict random

 LDY #6                 ; ship heap index at vertex-1

.EXL5                   ; counter Y=CNT Outer loop +=4 for each vertex on ship heap

 LDX #3

.EXL3                   ; counter X, K3 loaded with reversed vertex from heap.

 INY                    ; Y++ = 7 start is a vertex on ship heap
 LDA (XX19),Y
 STA K3,X               ; Yorg hi,lo, Xorg hi,lo
 DEX                    ; next coord
 BPL EXL3               ; loop X
 STY CNT                ; store index for vertex on ship heap
 LDY #2

.EXL2                   ; inner counter Y to set rnd for each vertex

 INY                    ; Y++ = 3 start, the 4 randoms on ship heap.
 LDA (XX19),Y
 EOR CNT                ; rnd seeded for each vertex CNT
 STA &FFFD,Y            ; using bytes 3,4,5,6.
 CPY #6                 ; 6 is last one
 BNE EXL2               ; loop next inner Y rnd seed
 LDY U                  ; number of pixels per vertex

.EXL4                   ; counter Y for pixels at each (reversed) vertex in K3

 JSR DORND2             ; leave bit0 of RAND+2 at 0
 STA ZZ                 ; restricted pixel depth
 LDA K3+1               ; Yorg lo
 STA R
 LDA K3                 ; Yorg hi
 JSR EXS1               ; Xlo.Ahi = Ylo+/-rnd*Cloud radius
 BNE EX11               ; Ahi too big, skip but new rnd
 CPX #2*Y-1             ; #2*Y-1 = Y screen range
 BCS EX11               ; too big, skip but new rnd.
 STX Y1                 ; Y coord
 LDA K3+3               ; Xorg lo
 STA R
 LDA K3+2               ; Xorg hi
 JSR EXS1               ; Xlo.Ahi = Xlo+/-rnd*Cloud radius
 BNE EX4                ; skip pixel
 LDA Y1                 ; reload Y coord
 JSR PIXEL              ; at (X,Y1) ZZ away

.EX4                    ; skipped pixel

 DEY                    ; loop Y
 BPL EXL4               ; next pixel at vertex
 LDY CNT                ; reload index for vertex on ship heap
 CPY TGT                ; counter target
 BCC EXL5               ; Outer loop, next vertex on ship heap

 PLA                    ; restore random
 STA RAND+1
 LDA K%+6               ; planet zlo seed
 STA RAND+3
 RTS

.EX11                   ; skipped pixel as Y too big, but new rnd

 JSR DORND2             ; new restricted rnd
 JMP EX4                ; skipped pixel, up.

.EXS1                   ; Xlo.Ahi = Rlo.Ahi+/-rnd*Q

 STA S                  ; store origin hi
 JSR DORND2             ; restricted rnd, carry.
 ROL A                  ; rnd hi
 BCS EX5                ; negative
 JSR FMLTU              ; Xlo = Arnd*Q=Cloud radius/256
 ADC R
 TAX                    ; Xlo = R+Arnd*Cloud radius/256
 LDA S
 ADC #0                 ; Ahi = S
 RTS

.EX5                    ; rnd hi negative

 JSR FMLTU              ; A=A*Q/256unsg
 STA T
 LDA R
 SBC T                  ; Arnd*Q=Cloud radius/256
 TAX                    ; Xlo = Rlo-T
 LDA S
 SBC #0                 ; Ahi = S
 RTS                    ; end of explosion code
}

\ ******************************************************************************
\ Subroutine: SOS1
\
\ Set up planet
\ ******************************************************************************

.SOS1                   ; Set up planet
{
 JSR msblob             ; draw all missile indicators
 LDA #127               ; no damping of rotation
 STA INWK+29            ; rotx counter
 STA INWK+30            ; roty counter
 LDA tek                ; techlevel of present system
 AND #2                 ; bit1 determines planet type 80..82
 ORA #128               ; type is planet
 JMP NWSHP              ; new ship type Acc
}

\ ******************************************************************************
\ Subroutine: SOLAR
\
\ Set up planet and sun
\ ******************************************************************************

.SOLAR                  ; Set up planet and sun
{
 LSR FIST               ; reduce Fugitative/Innocent legal status
 JSR ZINF               ; Call ZINF to reset the INWK ship workspace
 LDA QQ15+1             ; w0_h is Economy
 AND #7                 ; disc version has AND 3
 ADC #6                 ; disc version has ADC 3
 LSR A                  ; not in disc version
 STA INWK+8             ; zsg is planet distance
 ROR A                  ; planet off to top right
 STA INWK+2             ; xsg
 STA INWK+5             ; ysg

 JSR SOS1               ; set up planet,up.
 LDA QQ15+3             ; w1_h
 AND #7
 ORA #129               ; sun behind you
 STA INWK+8             ; zsg
 LDA QQ15+5             ; w2_h
 AND #3
 STA INWK+2             ; xsg
 STA INWK+1             ; xhi
 LDA #0                 ; no rotation for sun
 STA INWK+29            ; rotx counter
 STA INWK+30            ; rotz counter
 LDA #&81               ; type is Sun
 JSR NWSHP              ; new ship type Acc
}

\ ******************************************************************************
\ Subroutine: NWSTARS
\
\ New dust field
\ ******************************************************************************

.NWSTARS                ; New dust field
{
 LDA QQ11               ; menu i.d. QQ11 == 0 is space view
\ORA MJ
 BNE WPSHPS             ; if not space view skip over to Wipe Ships
}

\ ******************************************************************************
\ Subroutine: nWq
\
\ Create a cloud of stardust containing the maximum number of dust particles
\ (i.e. NOSTM of them).
\ ******************************************************************************

.nWq
{
 LDY NOSTM              ; number of dust particles

.SAL4                   ; counter Y

 JSR DORND              ; Set A and X to random numbers
 ORA #8                 ; flick out in z
 STA SZ,Y               ; dustz
 STA ZZ                 ; distance
 JSR DORND              ; Set A and X to random numbers
 STA SX,Y               ; dustx
 STA X1
 JSR DORND              ; Set A and X to random numbers
 STA SY,Y               ; dusty
 STA Y1
 JSR PIXEL2             ; dust (X1,Y1) from middle
 DEY                    ; next dust
 BNE SAL4               ; loop Y
}

\ ******************************************************************************
\ Subroutine: WPSHPS
\
\ Wipe Ships on scanner
\ ******************************************************************************

.WPSHPS                 ; Wipe Ships on scanner
{
 LDX #0

.WSL1                   ; outer counter X

 LDA FRIN,X             ; the Type for each of the 12 ships allowed
 BEQ WS2                ; exit as Nothing
 BMI WS1                ; loop as Planet or Sun
 STA TYPE               ; ship type
 JSR GINF               ; Get info on ship X, update INF pointer
 LDY #31                ; load some INWK from (INF)

.WSL2                   ; inner counter Y

 LDA (INF),Y
 STA INWK,Y
 DEY                    ; next byte of univ inf to inwk
 BPL WSL2               ; inner loop Y
 STX XSAV               ; store nearby ship count outer
 JSR SCAN               ; ships on scanner
 LDX XSAV               ; restore
 LDY #31                ; need to adjust INF display state
 LDA (INF),Y
 AND #&A7               ; clear bits 6,4,3 (explode,invisible,dot)
 STA (INF),Y            ; keep bits 7,5,2,1,0 (kill,exploding,missiles)

.WS1                    ; loop as Planet or Sun

 INX                    ; next nearby slot
 BNE WSL1               ; outer loop X

.WS2                    ; exit as Nothing

 LDX #&FF               ; clear line buffers
 STX LSX2               ; lines X2
 STX LSY2               ; lines Y2
}

\ ******************************************************************************
\ Subroutine: FLFLLS
\
\ Reset the LSO block by zero-filling it and setting LSO to &FF.
\
\ Returns:
\
\   A           Set to 0
\ ******************************************************************************

.FLFLLS
{
 LDY #2*Y-1             ; #Y is the y-coordinate of the centre of the mode 4
                        ; space view, so this sets Y as a counter for the number
                        ; of lines in the space view (i.e. 191), which is also
                        ; the number of lines in the LSO block

 LDA #0                 ; Set A to 0 so we can zero-fill the LSO block

.SAL6

 STA LSO,Y              ; Set the Y-th byte of the LSO block to 0

 DEY                    ; Decrement the counter

 BNE SAL6               ; Loop back until we have filled all the way to LSO+1

 DEY                    ; Decrement Y to value of &FF (as we exit the above loop
                        ; with Y = 0)

 STY LSX                ; Set the first byte of the LSO block, which shares its
                        ; location with LSX, to &FF (this could also be written
                        ; STY LSO, which would be clearer, but for some reason
                        ; it isn't)

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: DET1
\
\ Set the screen to show the number of text rows given in X. This is used when
\ we are killed, as reducing the number of rows from the usual 31 to 24 has the
\ effect of hiding the dashboard, leaving a monochrome image of ship debris and
\ explosion clouds. Increasing the rows back up to 31 makes the dashboard
\ reappear, as the dashboard's screen memory doesn't get touched by this
\ process.
\
\ Arguments:
\
\   X           The number of text rows to display on screen (24 will hide the
\               dashboard, 31 will make it reappear)
\
\ Returns
\
\   A           A is set to 6
\ ******************************************************************************

.DET1
{
 LDA #6                 ; Set A to 6 so we can update 6845 register R6 below

 SEI                    ; Disable interrupts so we can update the 6845

 STA SHEILA+&00         ; Set 6845 register R6 to the value in X. Register R6
 STX SHEILA+&01         ; is the "vertical displayed" register, which sets the
                        ; number of rows shown on screen

 CLI                    ; Re-enable interrupts

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: SHD-2
\
\ cap Shield = #&FF \ SHD-2
\ ******************************************************************************

{
 DEX                    ; cap Shield = #&FF \ SHD-2
 RTS                    ; Shield = #&FF
}

\ ******************************************************************************
\ Subroutine: SHD
\
\ let Shield X recharge
\ ******************************************************************************

.SHD                    ; let Shield X recharge
{
 INX
 BEQ SHD-2              ; cap Shield up = #&FF if too big else
}

\ ******************************************************************************
\ Subroutine: DENGY
\
\ Drain player's Energy
\ ******************************************************************************

.DENGY                  ; Drain player's Energy
{
 DEC ENERGY
 PHP                    ; push dec flag
 BNE P%+5               ; skip inc, else underflowing
 INC ENERGY             ; energy set back to 1
 PLP                    ; pull dec flag
 RTS
}

\ ******************************************************************************
\ Subroutine: COMPAS
\
\ space Compass
\ ******************************************************************************

.COMPAS                 ; space Compass
{
 JSR DOT                ; compass dot remove
 LDA SSPR               ; space station present? 0 is SUN.
 BNE SP1                ; compass point to space station, down.
 JSR SPS1               ; XX15 vector to planet
 JMP SP2                ; compass point to XX15
}

\ ******************************************************************************
\ Subroutine: SPS2
\
\ X.Y = A/10 for space compass display
\ ******************************************************************************

.SPS2                   ; X.Y = A/10 for space compass display
{
 ASL A                  ; A is signed unit vector
 TAX                    ; X = 7bits
 LDA #0                 ; Acc gets sign in bit7
 ROR A                  ; from any carry
 TAY                    ; Yreg = bit7 sign
 LDA #20                ; denominator
 STA Q
 TXA                    ; 7bits
 JSR DVID4              ; Phi.Rlo=A/20
 LDX P

 TYA                    ; sign bit
 BMI LL163              ; flip sign of X
 LDY #0                 ; hi +ve
 RTS

.LL163                  ; flip sign of X

 LDY #&FF               ; hi -ve
 TXA                    ; 7bits
 EOR #&FF
 TAX                    ; flipped
 INX                    ; -ve P
 RTS                    ; X -> -X, Y = #&FF.
}

\ ******************************************************************************
\ Subroutine: SPS4
\
\ XX15 vector to #SST
\ ******************************************************************************

.SPS4                   ; XX15 vector to #SST
{
 LDX #8                 ; 9 coords

.SPL1                   ; counter X

 LDA K%+NI%,X           ; allwk+37,X
 STA K3,X
 DEX                    ; next coord
 BPL SPL1               ; loop X
 JMP TAS2               ; build XX15 from K3
}

\ ******************************************************************************
\ Subroutine: SP1
\
\ compass point to space station
\ ******************************************************************************

.SP1                    ; compass point to space station
{
 JSR SPS4               ; XX15 vector to #SST, up.
}

\ ******************************************************************************
\ Subroutine: SP2
\
\ compass point to XX15
\ ******************************************************************************

.SP2                    ; compass point to XX15
{
 LDA XX15               ; xunit
 JSR SPS2               ; X.Y = xunit/10 for space compass display
 TXA                    ; left edge of compass
 ADC #195               ; X-1 \ their comment
 STA COMX               ; compass-x
 LDA XX15+1             ; yunit
 JSR SPS2               ; X.Y = yunit/10 for space compass display
 STX T
 LDA #204               ; needs to be flipped around
 SBC T
 STA COMY               ; compass-y

 LDA #&F0               ; default compass colour yellow
 LDX XX15+2             ; zunit
 BPL P%+4               ; its in front
 LDA #&FF               ; else behind colour is green
 STA COMC               ; compass colour
}

\ ******************************************************************************
\ Subroutine: DOT
\
\ Compass dot
\ ******************************************************************************

.DOT                    ; Compass dot
{
 LDA COMY               ; compass-y
 STA Y1
 LDA COMX               ; compass-x
 STA X1
 LDA COMC               ; compass colour
 STA COL                ; the colour
 CMP #&F0               ; yellow is in front?
 BNE CPIX2              ; hop ahead 4 lines if behind you, narrower bar
}

\ ******************************************************************************
\ Subroutine: CPIX4
\
\ stick head on scanner at height Y1
\ ******************************************************************************

.CPIX4                  ; stick head on scanner at height Y1
{
 JSR CPIX2              ; two visits, Y1 then Y1-1 to make twice as thick.
 DEC Y1                 ; next bar
}

\ ******************************************************************************
\ Subroutine: CPIX2
\
\ narrower bar
\ ******************************************************************************

.CPIX2                  ; Colour Pixel Mode 5
{
 LDA Y1                 ; yscreen

\.CPIX

 TAY                    ; build screen page
 LSR A
 LSR A                  ; upper 5 bits
 LSR A                  ; Y1/8
 ORA #&60               ; screen hi
 STA SCH                ; SC+1
 LDA X1                 ; xscreen
 AND #&F8               ; upper 5 bits
 STA SC
 TYA                    ; yscreen
 AND #7                 ; lower 3 bits
 TAY                    ; byte row set
 LDA X1
 AND #6                 ; build mask index bits 2,1
 LSR A                  ; /=2, carry cleared.
 TAX                    ; color mask index for Mode 5, coloured.
 LDA CTWOS,X
 AND COL                ; the colour
 EOR (SC),Y
 STA (SC),Y

 LDA CTWOS+1,X
 BPL CP1                ; same column
 LDA SC
 ADC #8                 ; next screen column
 STA SC
 LDA CTWOS+1,X

.CP1                    ; same column

 AND COL                ; the colour
 EOR (SC),Y
 STA (SC),Y
 RTS
}

\ ******************************************************************************
\ Subroutine: OOPS
\
\ Lose some shield strength, cargo, could die.
\
\ A = amount of damage
\ ******************************************************************************

.OOPS                   ; Lose some shield strength, cargo, could die.
{
 STA T                  ; dent was in Acc
 LDY #8                 ; get zsg of ship hit
 LDX #0                 ; min
 LDA (INF),Y
 BMI OO1                ; aft shield hit
 LDA FSH                ; forward shield
 SBC T                  ; dent
 BCC OO2                ; clamp forward at 0
 STA FSH                ; forward shield
 RTS

.OO2                    ; clamp forward at 0

\LDX #0
 STX FSH                ; forward shield = 0
 BCC OO3                ; guaranteed, Shield gone

.OO1                    ; Aft shield hit

 LDA ASH                ; aft shield = 0
 SBC T                  ; dent
 BCC OO5                ; clamp aft at 0
 STA ASH                ; aft shield
 RTS

.OO5                    ; clamp aft at 0

\LDX #0
 STX ASH                ; aft shield

.OO3                    ; Shield gone

 ADC ENERGY             ; some energy added, wraps as small dent.
 STA ENERGY
 BEQ P%+4               ; if 0, DEATH
 BCS P%+5               ; overflow just noise EXNO3, OUCH
 JMP DEATH
 JSR EXNO3              ; ominous noises
 JMP OUCH               ; lose cargo/equipment
}

\ ******************************************************************************
\ Subroutine: SPS3
\
\ planet if Xreg=0 for space compass into K3(0to8)
\ ******************************************************************************

.SPS3                   ; planet if Xreg=0 for space compass into K3(0to8)
{
 LDA K%+1,X             ; allwk+1,X
 STA K3,X               ; hi
 LDA K%+2,X             ; allwk+2,X
 TAY                    ; sg
 AND #127               ; sg far7
 STA K3+1,X
 TYA                    ; sg
 AND #128               ; bit7 sign
 STA K3+2,X
 RTS
}

\ ******************************************************************************
\ Subroutine: GINF
\
\ Get the address of the data block for ship number X and store it in INF. This
\ address is fetched from the UNIV table, which stores the addresses of the 13
\ ship data blocks in workspace K%.
\
\ Arguments:
\
\   X           The ship number for which we want the data block address
\ ******************************************************************************

.GINF
{
 TXA                    ; Set Y = X * 2
 ASL A
 TAY

 LDA UNIV,Y             ; Get the high byte of the address of the X-th ship
 STA INF                ; from UNIV and store it in INF

 LDA UNIV+1,Y           ; Get the low byte of the address of the X-th ship
 STA INF+1              ; from UNIV and store it in INF

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: NWSPS
\
\ Add a new space station to our little bubble of universe.
\ ******************************************************************************

.NWSPS
{
 JSR SPBLB              ; Light up the space station bulb on the dashboard

 LDX #1                 ; Set the AI flag in INWK+32 to 1 (friendly, no AI, has
 STX INWK+32            ; E.C.M.)

 DEX                    ; Set rotz counter to 0 (no pitch, roll only)
 STX INWK+30

\STX INWK+31            ; This instruction is commented out in the original
                        ; source. It would set the exploding state and missile
                        ; count to 0.

 STX FRIN+1             ; Set the sun/space station slot at FRIN+1 to 0, to
                        ; indicate we should show the space station rather than
                        ; the sun

 DEX                    ; Set rotx counter to 255 (maximum roll with no
 STX INWK+29            ; damping)

 LDX #10                ; Call NwS1 to flip the sign of rotmat0x_hi (INWK+10)
 JSR NwS1

 JSR NwS1               ; And again to flip the sign of rotmat0y_hi (INWK+12)

 JSR NwS1               ; And again to flip the sign of rotmat0z_hi (INWK+14)

 LDA #LO(LSO)           ; Set INWK+33 and INWK+34 to point to LSO for the ship
 STA INWK+33            ; lines heap space for the space station
 LDA #HI(LSO)
 STA INWK+34

 LDA #SST               ; Set A to the space station type, and fall through
                        ; into NWSHP to finish adding the space station to the
                        ; universe
}

\ ******************************************************************************
\ Subroutine: NWSHP
\
\ Add a new ship to our local bubble of universe. This creates a block of ship
\ data in the workspace at K% (where we store the ships in our current bubble),
\ and we also add the ship type into the slot index table at FRIN. We can
\ retrieve this block of ship data later using the lookup table at UNIV.
\
\ Arguments:
\
\   A           The type of the ship to add (see variable XX21 for a list of
\               ship types)
\
\ Returns:
\
\   C flag      Set if the ship was successfully added, clear if it wasn't
\               (as there wasn't enough free memory)
\ ******************************************************************************

.NWSHP
{
 STA T                  ; Store the ship type in location T

 LDX #0                 ; Before we can add a new ship, we need to check
                        ; whether we have an empty slot we can put it in. To do
                        ; this, we need to loop through all the slots to look
                        ; for an empty one, so set a counter in X that starts
                        ; from the first slot at 0. When ships are killed, then
                        ; the slots are shuffled down by the KILLSHP routine, so
                        ; the first empty slot will always come after the last
                        ; filled slot. This allows us to tack the new ship's
                        ; data block and ship lines heap onto the end of the
                        ; existing ship data and heap, as shown in the memory
                        ; map below.

.NWL1

 LDA FRIN,X             ; Load the ship type for the X-th slot

 BEQ NW1                ; If it is zero, then this slot is empty and we can use
                        ; it for our new ship, so jump down to NW1

 INX                    ; Otherwise increment X to point to the next slot

 CPX #NOSH              ; If we haven't reached the last slot yet, loop back up
 BCC NWL1               ; to NWL1 to check the next slot

.NW3

 CLC                    ; Otherwise we don't have an empty slot, so we can't
 RTS                    ; add a new ship, so clear the carry flag to indicate
                        ; that we have not managed to create the new ship, and
                        ; return from the subroutine

.NW1                    ; If we get here, then we have found an empty slot at
                        ; index X, so we can go ahead and create our new ship.
                        ; We do that by creating a ship data block at INWK and,
                        ; when we are done, copying the block from INWK into
                        ; the workspace at K% (specifically, to INF).

 JSR GINF               ; Get the address of the data block for ship X (which
                        ; is in workspace K%) and store it in INF

 LDA T                  ; If the type of ship that we want to create is
 BMI NW2                ; negative, then this indicates a planet or sun, so
                        ; jump down to NW2, as the next section sets up a ship
                        ; data block, which doesn't apply to planets and suns,
                        ; as they don't have things like shields, missiles,
                        ; vertices and edges.

                        ; This is a ship, so first we need to set up various
                        ; pointers to the ship blueprint we will need. The
                        ; blueprints for each ship type in Elite are stored
                        ; in a table at location XX21, so refer to the comments
                        ; on that variable for more details on the data we're
                        ; about to access.

 ASL A                  ; Set Y = ship type * 2
 TAY

 LDA XX21-2,Y           ; The ship blueprints at XX21 start with a lookup
 STA XX0                ; table that points to the individual ship blueprints,
                        ; so this fetches the low byte of this particular ship
                        ; type's blueprint and stores it in XX0

 LDA XX21-1,Y           ; Fetch the high byte of this particular ship type's 
 STA XX0+1              ; blueprint and store it in XX0+1

 CPY #2*SST             ; If the ship type is a space station (SST), then jump
 BEQ NW6                ; to NW6, skipping the heap space steps below

                        ; We now want to allocate a heap space that we can use
                        ; while drawing our new ship - the ship lines heap
                        ; space. SLSP points to the start of the current
                        ; heap space, and we can extend it downwards with the
                        ; heap for our new ship (as the heap space always ends
                        ; just before the workspace at WP).

 LDY #5                 ; Fetch ship blueprint byte #5, which contains the
 LDA (XX0),Y            ; maximum heap size required for plotting the new ship,
 STA T1                 ; and store it in T1

 LDA SLSP               ; Take the 16-bit address in SLSP and subtract T1,
 SEC                    ; storing the 16-bit result in (INWK+34 INWK+33),
 SBC T1                 ; so this now points to the start of the heap space
 STA INWK+33            ; for our new ship
 LDA SLSP+1
 SBC #0
 STA INWK+34

                        ; We now need to check that there is enough free space
                        ; for both this new heap space and the new data block
                        ; for our ship. In memory, this is the layout of the
                        ; ship data and heap space:
                        ;
                        ;   High address
                        ;
                        ;   +-----------------------------------+   &0F34
                        ;   |                                   |
                        ;   | WP workspace                      |
                        ;   |                                   |
                        ;   +-----------------------------------+   &0D40 = WP
                        ;   |                                   |
                        ;   | Current ship lines heap           |
                        ;   |                                   |
                        ;   +-----------------------------------+   SLSP
                        ;   |                                   |
                        ;   | Proposed heap for new ship        |
                        ;   |                                   |
                        ;   +-----------------------------------+   INWK+33
                        ;   |                                   |
                        ;   .                                   .
                        ;   .                                   .
                        ;   .                                   .
                        ;   .                                   .
                        ;   .                                   .
                        ;   |                                   |
                        ;   +-----------------------------------+   INF+NI%
                        ;   |                                   |
                        ;   | Proposed data block for new ship  |
                        ;   |                                   |
                        ;   +-----------------------------------+   INF
                        ;   |                                   |
                        ;   | Existing ship data blocks         |
                        ;   |                                   |
                        ;   +-----------------------------------+   &0900 = K%
                        ;
                        ;   Low address
                        ;
                        ; So, to work out if we have enough space, we have to
                        ; make sure there is room between the end of our new
                        ; ship data block at INF+NI%, and the start of the
                        ; proposed heap for our new ship at INWK+33. Or, to
                        ; put it another way, we need to make sure that:
                        ;
                        ;   INWK+33 > INF+NI%
                        ;
                        ; which is the same as saying:
                        ;
                        ;   INWK+33 - INF > NI%

 LDA INWK+33            ; Calculate INWK+33 - INF, again using 16-bit
\SEC                    ; arithmetic, and put the result in (A Y), so the high
 SBC INF                ; byte is in A and the low byte in Y. The SEC
 TAY                    ; instruction is commented out in the original source;
 LDA INWK+34            ; as the previous subtraction will never underflow, it
 SBC INF+1              ; is superfluous.

 BCC NW3+1              ; If we have an underflow from the subtraction, then
                        ; INF > INWK+33 and we definitely don't have enough
                        ; room for this ship, so jump to NW3+1, which clears
                        ; the carry flag and returns from the subroutine

 BNE NW4                ; If the subtraction of the high bytes in A is not
                        ; zero, and we don't have underflow, then we definitely
                        ; have enough space, so jump to NW4 to continue setting
                        ; up the new ship

 CPY #NI%               ; Otherwise the high bytes are the same in our
 BCC NW3+1              ; subtraction, so now we compare the low byte of the
                        ; result (which is in Y) with NI%. This is the same as
                        ; doing INWK+33 - INF > NI% (see above). If this isn't
                        ; true, the carry flag will be clear and we don't have
                        ; enough space, so we jump to NW3+1, which clears the
                        ; carry flag and returns from the subroutine.

.NW4

 LDA INWK+33            ; If we get here then we do have enough space for our
 STA SLSP               ; new ship, so store the new bottom of the ship lines
 LDA INWK+34            ; heap space (i.e. INWK+33) in SLSP, doing both the
 STA SLSP+1             ; high and low bytes

.NW6

 LDY #14                ; Fetch ship blueprint byte #14, which contains the
 LDA (XX0),Y            ; ship's energy, and store it in INWK+35
 STA INWK+35

 LDY #19                ; Fetch ship blueprint byte #19, which contains the
 LDA (XX0),Y            ; number of missiles and laser power, and AND with %111
 AND #%00000111         ; to extract the number of missiles before storing in
 STA INWK+31            ; INWK+31

 LDA T                  ; Restore the ship type we stored above

.NW2

 STA FRIN,X             ; Store the ship type in the X-th byte of FRIN, so the
                        ; this slot is now shown as occupied in the index table
 
 TAX                    ; Copy the ship type into X

 BMI P%+5               ; If the ship type is negative (planet or sun), then
                        ; skip the following instruction

 INC MANY,X             ; Increment the total number of ships of type X

 LDY #(NI%-1)           ; The final step is to copy the new ship's data block
                        ; from INWK to INF, so set up a counter for NI% bytes
                        ; in Y

.NWL3

 LDA INWK,Y             ; Load the Y-th byte of INWK and store in the Y-th byte
 STA (INF),Y            ; of the workspace pointed to by INF
 
 DEY                    ; Decrement the loop counter
 
 BPL NWL3               ; Loop back for the next byte until we have copied them
                        ; all over

 SEC                    ; We have successfuly created our new ship, so set the
                        ; carry flag to indicate success

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: NwS1
\
\ Flip the sign of the INWK byte at offset X, and increment X by 2. This is
\ is used by the space station creation routine at NWSPS.
\
\ Arguments:
\
\   X           The offset of the INWK byte to be flipped
\
\ Returns:
\
\   X           X is incremented by 2
\ ******************************************************************************

.NwS1
{
 LDA INWK,X             ; Load the X-th byte of INWK into A and flip bit 7,
 EOR #%10000000         ; storing the result back in the X-th byte of INWK
 STA INWK,X

 INX                    ; Add 2 to X
 INX

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: ABORT
\
\ draw missile indicator, Unarm missile
\ ******************************************************************************

.ABORT                  ; draw missile indicator, Unarm missile
{
 LDX #&FF
}

\ ******************************************************************************
\ Subroutine: ABORT2
\
\ missile found a target
\ ******************************************************************************

.ABORT2                 ; Xreg stored as Missile target
{
 STX MSTG               ; missile targeted 12 choices
 LDX NOMSL              ; number of missiles
 JSR MSBAR              ; draw missile bar, returns with Y = 0.
 STY MSAR               ; missiles armed status
 RTS
}

\ ******************************************************************************
\ Subroutine: ECBLB2
\
\ set ECM bulb
\ ******************************************************************************

.ECBLB2                 ; set ECM bulb
{
 LDA #32
 STA ECMA               ; ECM on
 ASL A                  ; #64

 JSR NOISE              ; Call the NOISE routine with A = 64 to make the sound
                        ; the E.C.M. being switched on
}

\ ******************************************************************************
\ Subroutine: ECBLB
\
\ Light up the E.C.M. bulb on the dashboard.
\ ******************************************************************************

.ECBLB                  ; ECM bulb switch
{
 LDA #7*8               ; SC lo for E on left of row
 LDX #LO(ECBT)
 LDY #HI(ECBT)
 BNE BULB-2             ; guaranteed, but assume same Y page
}

\ ******************************************************************************
\ Subroutine: SPBLB
\
\ Light up the space station bulb on the dashboard.
\ ******************************************************************************

.SPBLB                  ; Space Station bulb
{
 LDA #24*8              ; Screen lo destination SC on right of row
 LDX #LO(SPBT)          ; font source
}

\ ******************************************************************************
\ Subroutine: BULB-2
\
\ Bulb
\ ******************************************************************************

{
 LDY #HI(SPBT)
}

\ ******************************************************************************
\ Subroutine: BULB
\
\ Bulb
\ ******************************************************************************

.BULB
{
 STA SC                 ; screen lo
 STX P+1                ; font pointer lo
 STY P+2                ; font pointer hi
 LDA #&7D               ; screen hi SC+1 destination (SC) = &7DC0
 JMP RREN               ; Acc has screen hi for 8 bytes from (P+1)
}

\ ******************************************************************************
\ Variable: ECBT
\
\ "E" displayed in lower console.
\ ******************************************************************************

.ECBT
{
 EQUW &E0E0             ; "E" displayed in lower console
 EQUB &80
}

\ ******************************************************************************
\ Variable: SPBT
\
\ "S" displayed in lower console.
\ ******************************************************************************

.SPBT                   ; make sure same page !
{
 EQUD &E080E0E0         ; "S" displayed in lower console
 EQUD &E0E020E0
}

\ ******************************************************************************
\ Subroutine: MSBAR
\
\ Update a specific indicator in the dashboards's missile bar.
\
\ Arguments:
\
\   X           Number of the missile indicator to update (counting from right
\               to left, so indicator NOMSL is the leftmost indicator)
\
\   Y           New colour of the missile indicator:
\
\                 * &00 = black (no missile)
\
\                 * &0E = red (armed and locked)
\
\                 * &E0 = yellow (armed)
\
\                 * &EE = green (disarmed)
\ ******************************************************************************

.MSBAR                  ; draw Missile bar. X is number of missiles. Y is strip design.
{
 TXA                    ; missile i.d.
 ASL A
 ASL A
 ASL A                  ; X*8 move over to missile indicator of interest
 STA T
 LDA #49                ; far right
 SBC T
 STA SC                 ; screen low byte in console
 LDA #&7E               ; bottom row of visible console
 STA SCH
 TYA                    ; strip mask
 LDY #5                 ; 5 strips

.MBL1                   ; counter Y to build block

 STA (SC),Y
 DEY                    ; next strip
 BNE MBL1               ; loop Y
 RTS
}

\ ******************************************************************************
\ Subroutine: PROJ
\
\ Project K+INWK(x,y)/z to K3,K4 for center to screen
\ ******************************************************************************

.PROJ                   ; Project K+INWK(x,y)/z to K3,K4 for center to screen
{
 LDA INWK               ; xlo
 STA P
 LDA INWK+1             ; xhi
 STA P+1
 LDA INWK+2             ; xsg
 JSR PLS6               ; Klo.Xhi = P.A/INWK_z, C set if big
 BCS PL2-1              ; rts as x big
 LDA K
 ADC #X                 ; add xcenter
 STA K3
 TXA                    ; xhi
 ADC #0                 ; K3 is xcenter of planet
 STA K3+1

 LDA INWK+3             ; ylo
 STA P
 LDA INWK+4             ; yhi
 STA P+1
 LDA INWK+5             ; ysg
 EOR #128               ; flip yscreen
 JSR PLS6               ; Klo.Xhi = P.A/INWK_z, C set if big
 BCS PL2-1              ; rts as y big
 LDA K
 ADC #Y                 ; #Y for add ycenter
 STA K4
 TXA                    ; y hi
 ADC #0                 ; K4 is ycenter of planet
 STA K4+1
 CLC                    ; carry clear is center is on screen
 RTS                    ; PL2-1
}

\ ******************************************************************************
\ Subroutine: PL2
\
\ Wipe planet/sun
\ ******************************************************************************

.PL2                    ; planet/sun behind
{
 LDA TYPE               ; ship type
 LSR A                  ; bit0
 BCS P%+5               ; sun has bit0 set
 JMP WPLS2              ; bit0 clear Wipe Planet
 JMP WPLS               ; Wipe Sun
}

\ ******************************************************************************
\ Subroutine: PLANET
\
\ Planet or Sun type to screen
\ ******************************************************************************

.PLANET                 ; Planet or Sun type to screen
{
 LDA INWK+8             ; zsg if behind
 BMI PL2                ; wipe planet/sun
 CMP #48                ; very far away?
 BCS PL2                ; wipe planet/sun
 ORA INWK+7             ; zhi
 BEQ PL2                ; else too close, wipe planet/sun
 JSR PROJ               ; Project K+INWK(x,y)/z to K3,K4 for center to screen
 BCS PL2                ; if center large offset wipe planet/sun

 LDA #96                ; default radius hi
 STA P+1
 LDA #0                 ; radius lo
 STA P
 JSR DVID3B2            ; divide 3bytes by 2, K = P(2).A/INWK_z
 LDA K+1                ; radius hi
 BEQ PL82               ; radius hi fits
 LDA #&F8               ; else too big
 STA K                  ; radius

.PL82                   ; radius fits

 LDA TYPE               ; ship type
 LSR A                  ; sun has bit0 set
 BCC PL9                ; planet radius K
 JMP SUN                ; else Sun #&81 #&83 .. with radius Ks

.PL9                    ; Planet radius K

 JSR WPLS2              ; wipe planet
 JSR CIRCLE             ; for planet
 BCS PL20               ; rts, else circle done
 LDA K+1
 BEQ PL25               ; planet on screen

.PL20

 RTS

.PL25                   ; Planet on screen

 LDA TYPE               ; ship type
 CMP #&80               ; Lave 2-rings is #&80
 BNE PL26               ; Other planet #&82 is crater
 LDA K
 CMP #6                 ; very small radius ?
 BCC PL20               ; rts
 LDA INWK+14            ; rotmat0z hi. Start first  meridian
 EOR #128               ; flipped rotmat0z hi
 STA P                  ; meridian width
 LDA INWK+20            ; rotmat1z hi, for meridian1
 JSR PLS4               ; CNT2 = angle of P_opp/A_adj for Lave
 LDX #9                 ; rotmat0.x for both meridians
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA K2                 ; mag  0.x   used in final x of arc
 STY XX16               ; sign 0.x
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA K2+1               ; mag  0.y   used in final y of arc
 STY XX16+1             ; sign 0.y
 LDX #15                ; rotmat1.x for first meridian
 JSR PLS5               ; mag K2+2,3 sign XX16+2,3 = NWK(X+=2)/INWK_z

 JSR PLS2               ; Lave half ring, phase offset CNT2.
 LDA INWK+14            ; rotmat0z hi. Start second meridian
 EOR #128               ; flipped rotmat0z hi
 STA P                  ; meridian width again
 LDA INWK+26            ; rotmat2z hi, for meridian2 at 90 degrees.
 JSR PLS4               ; CNT2 = angle of P_opp/A_adj for Lave

 LDX #21                ; rotmat2.x for second meridian
 JSR PLS5               ; mag K2+2,3 sign XX16+2,3 = NWK(X+=2)/INWK_z
 JMP PLS2               ; Lave half ring, phase offset CNT2.

.PL26                   ; crtr \ their comment \ Other planet e.g. #&82 has One crater.

 LDA INWK+20            ; rotmat1z hi
 BMI PL20               ; rts, crater on far side

 LDX #15                ; rotmat1.x (same as meridian1)
 JSR PLS3               ; A.Y = 222* INWK(X+=2)/INWK_z. 222 is xoffset of crater
 CLC                    ; add xorg lo
 ADC K3
 STA K3
 TYA                    ; xoffset hi of crater center updated
 ADC K3+1
 STA K3+1
 JSR PLS3               ; A.Y = 222* INWK(X+=2)/INWK_z. 222 is yoffset of crater
 STA P
 LDA K4
 SEC                    ; sub Plo from yorg lo
 SBC P
 STA K4
 STY P                  ; yoffset hi temp
 LDA K4+1               ; yorg hi
 SBC P                  ; yoffset hi temp
 STA K4+1               ; y of crater center updated

 LDX #9                 ; rotmat0.x  (same as both meridians)
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 LSR A                  ; /2 used in final x of ring
 STA K2                 ; mag 0.x/2
 STY XX16               ; sign 0.x
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 LSR A                  ; /2 used in final y of ring
 STA K2+1               ; mag 0.y/2
 STY XX16+1             ; sign 0.y

 LDX #21                ; rotmat2.x (same as second meridian)
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 LSR A                  ; /2 used in final x of ring
 STA K2+2               ; mag 2.x/2
 STY XX16+2             ; sign 2.x
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 LSR A                  ; /2 used in final y of ring
 STA K2+3               ; mag 2.y/2
 STY XX16+3             ; sign 2.y

 LDA #64                ; full circle
 STA TGT                ; count target
 LDA #0                 ; no phase offset for crater ring
 STA CNT2
 JMP PLS22              ; guaranteed crater with TGT = #64
}

\ ******************************************************************************
\ Subroutine: PLS1
\
\ X = 9 etc. A.Y = INWK(X+=2)/INWK_z
\ ******************************************************************************

.PLS1                   ; X = 9 etc. A.Y = INWK(X+=2)/INWK_z
{
 LDA INWK,X
 STA P
 LDA INWK+1,X
 AND #127               ; 7bits of hi
 STA P+1
 LDA INWK+1,X           ; again, get sign for 3rd byte
 AND #128               ; sign only

 JSR DVID3B2            ; divide 3bytes by 2, K = P(2).A/INWK_z
 LDA K                  ; lo
 LDY K+1                ; hi
 BEQ P%+4
 LDA #&FE               ; else sat Acc and keep Y = K+1 non-zero
 LDY K+3                ; sign
 INX                    ; X+=2
 INX
 RTS
}

\ ******************************************************************************
\ Subroutine: PLS2
\
\ Lave half ring, mags K2+0to3, signs XX16+0to3, xy(0)xy(1), phase offset CNT2
\ ******************************************************************************

.PLS2                   ; Lave half ring, mags K2+0to3, signs XX16+0to3, xy(0)xy(1), phase offset CNT2
{
 LDA #31                ; half-circle
 STA TGT                ; count target
}

\ ******************************************************************************
\ Subroutine: PLS22
\
\ Also crater with TGT = #64
\ ******************************************************************************

.PLS22                  ; also crater with TGT = #64
{
 LDX #0
 STX CNT                ; count
 DEX                    ; X = #&FF
 STX FLAG

.PLL4                   ; counter CNT+= STP > TGT planet ring

 LDA CNT2               ; for arc
 AND #31                ; angle index
 TAX                    ; sine table
 LDA SNE,X
 STA Q                  ; sine
 LDA K2+2               ; mag x1
 JSR FMLTU              ; A=A*Q/256unsg
 STA R                  ; part2 lo x = mag x1 * sin
 LDA K2+3               ; mag y1
 JSR FMLTU              ; A=A*Q/256unsg
 STA K                  ; part2 lo y =  mag y1 * sin
 LDX CNT2
 CPX #33                ; for arc
 LDA #0                 ; any sign
 ROR A                  ; into 7th bit
 STA XX16+5             ; ysign

 LDA CNT2
 CLC                    ; for arc
 ADC #16                ; cosine
 AND #31                ; index
 TAX                    ; sinetable
 LDA SNE,X
 STA Q                  ; cosine
 LDA K2+1               ; mag y0
 JSR FMLTU              ; A=A*Q/256unsg
 STA K+2                ; part1 lo y = mag y0 * cos
 LDA K2                 ; mag x0
 JSR FMLTU              ; A=A*Q/256unsg
 STA P                  ; part1 lo x  = mag x0 * cos
 LDA CNT2
 ADC #15                ; for arc
 AND #63                ; 63 max
 CMP #33                ; > 32 ?
 LDA #0                 ; any carry is sign
 ROR A                  ; into 7th bit
 STA XX16+4             ; xsign

 LDA XX16+5             ; ysign
 EOR XX16+2             ; x1 sign
 STA S                  ; S = part2 hi x
 LDA XX16+4             ; xsign
 EOR XX16               ; A = part1 hi x
 JSR ADD                ; lo x = mag x0 * cos + mag x1 * sin
 STA T                  ; sum hi
 BPL PL42               ; hop xplus
 TXA                    ; else minus, sum lo
 EOR #&FF
 CLC
 ADC #1
 TAX                    ; flipped lo
 LDA T                  ; sum hi
 EOR #&7F
 ADC #0
 STA T                  ; flip sum hi and continue

.PL42                   ; hop xplus

 TXA                    ; sum x lo
 ADC K3                 ; xcenter lo
 STA K6                 ; xfinal lo
 LDA T                  ; sum x hi
 ADC K3+1               ; xcenter hi
 STA K6+1               ; xfinal hi

 LDA K                  ; part2 lo y
 STA R                  ; part2 lo y
 LDA XX16+5             ; ysign
 EOR XX16+3             ; y1 sign
 STA S                  ; part2 hi y
 LDA K+2                ; part1 lo y
 STA P                  ; part1 lo y
 LDA XX16+4             ; xsign
 EOR XX16+1             ; A = part1 hi y
 JSR ADD                ; lo y = mag y0 * cos +  mag y1 * sin
 EOR #128               ; flip
 STA T                  ; yfinal hi
 BPL PL43               ; hop yplus
 TXA                    ; else minus, sum lo
 EOR #&FF
 CLC
 ADC #1
 TAX                    ; flipped lo, yfinal lo
 LDA T                  ; yfinal hi
 EOR #&7F
 ADC #0
 STA T                  ; flipped sum hi and continue, yfinal hi

.PL43                   ; hop yplus

 JSR BLINE              ; ball line uses (X.T) as next y offset for arc
 CMP TGT                ; CNT+= STP > TGT
 BEQ P%+4               ; = TGT, next.
 BCS PL40               ; > TGT exit arc rts
 LDA CNT2               ; next, CNT2
 CLC                    ; +step for ring
 ADC STP
 AND #63                ; round
 STA CNT2
 JMP PLL4               ; loop planet ring

.PL40

 RTS                    ; end Crater ring
}

\ ******************************************************************************
\ Subroutine: PLF3-3
\
\ Wipe Sun
\ ******************************************************************************

{
 JMP WPLS               ; Wipe Sun
}

\ ******************************************************************************
\ Subroutine: PLF3
\
\ Flip height for planet/sun fill
\ ******************************************************************************

.PLF3                   ; flip height for planet/sun fill
{
 TXA                    ; Yscreen height lo
 EOR #&FF               ; flip
 CLC
 ADC #1
 TAX                    ; height flipped
}

\ ******************************************************************************
\ Subroutine: PLF17
\
\ up A = #&FF as Xlo =0
\ ******************************************************************************

.PLF17                  ; up A = #&FF as Xlo =0
{
 LDA #&FF               ; fringe flag will run up
 JMP PLF5               ; guaranteed, Xreg = height ready
}

\ ******************************************************************************
\ Subroutine: SUN
\
\ Plot a sun with radius K at pixel coordinate (K3, K4).
\
\ Arguments:
\
\   K(1 0)      The sun's radius as a 16-bit integer
\
\   K3(1 0)     Pixel x-coordinate of the centre of the sun as a 16-bit integer
\
\   K4(1 0)     Pixel y-coordinate of the centre of the sun as a 16-bit integer
\ ******************************************************************************

.SUN                    ; Sun with radius K
{
 LDA #1
 STA LSX                ; overlaps with LSO vector
 JSR CHKON              ; P+1 set to maxY
 BCS PLF3-3             ; jmp wpls Wipe Sun
 LDA #0                 ; fill up Acc bits based on size
 LDX K                  ; radius
 CPX #&60               ; any carry becomes low bit
 ROL A
 CPX #&28               ; 4 if K >= 40
 ROL A
 CPX #&10               ; 2 if K >= 16
 ROL A                  ; extent of fringes set

.PLF18

 STA CNT                ; bits are extent of fringes
 LDA #2*Y-1             ; 2*#Y-1 is Yscreen
 LDX P+2
 BNE PLF2               ; big height
 CMP P+1                ; is Y screen < P+1
 BCC PLF2               ; big height
 LDA P+1                ; now Acc loaded
 BNE PLF2               ; big height
 LDA #1                 ; else Acc=1 is bottom end of Yscreen

.PLF2                   ; big height

 STA TGT                ; top of screen for Y height
 LDA #2*Y-1             ; #2*Y-1 is Yscreen
 SEC                    ; subtract
 SBC K4                 ; Yorg
 TAX                    ; lo Yscreen lo
 LDA #0                 ; hi
 SBC K4+1
 BMI PLF3               ; flip height then ready to run up
 BNE PLF4               ; if Yscreen hi not zero then height is full radius
 INX
 DEX                    ; ysub lo
 BEQ PLF17              ; if ylo = 0 then ready to run up with A = #&FF
 CPX K                  ; Yscreen lo < radius ?
 BCC PLF5               ; if ylo < radius then ready to run down

.PLF4                   ; height is full radius

 LDX K                  ; counter V height is radius
 LDA #0                 ; fringe flag will run down
}

\ ******************************************************************************
\ Subroutine: PLF5
\
\ Other entry points: RTS2 (RTS)
\
\ Xreg = height ready, Acc is flag for run direction
\ ******************************************************************************

.PLF5                   ; Xreg = height ready, Acc is flag for run direction
{
 STX V                  ; counter height
 STA V+1                ; flag 0 (up) or FF (down)

 LDA K
 JSR SQUA2              ; P.A =A*A unsigned
 STA K2+1               ; squared 16-bit radius hi
 LDA P                  ; lo
 STA K2                 ; squared 16-bit stored in K2
 LDY #2*Y-1             ; 2*#Y-1 is Yscreen is counter start
 LDA SUNX
 STA YY                 ; old mid-point of horizontal line
 LDA SUNX+1
 STA YY+1               ; hi

.PLFL2                  ; counter Y down erase top Disc

 CPY TGT                ; Yheight top reached?
 BEQ PLFL               ; exit to Start, Y height = TGT top.
 LDA LSO,Y
 BEQ PLF13              ; if half width zero skip line drawing
 JSR HLOIN2             ; line X1,X2 using YY as mid-point, Acc is half-width

.PLF13                  ; skipped line drawing

 DEY                    ; erase top Disc
 BNE PLFL2              ; loop Y

.PLFL                   ; exited as reached Start. Y = TGT, counter V height. Work out extent.

 LDA V                  ; counter height
 JSR SQUA2              ; P.A =A*A unsigned
 STA T                  ; squared height hi
 LDA K2                 ; squared 16-bit radius lo
 SEC
 SBC P                  ; height squared lo
 STA Q                  ; radius^2-height^2 lo
 LDA K2+1               ; radius^2 hi
 SBC T                  ; height squared hi
 STA R                  ; extent^2 hi
 STY Y1                 ; Y store line height
 JSR LL5                ; SQRT Q = SQR(Q,R) = sqrt(sub)
 LDY Y1                 ; restore line counter
 JSR DORND              ; do random number
 AND CNT                ; trim fringe
 CLC
 ADC Q                  ; new extent
 BCC PLF44              ; not saturated
 LDA #&FF               ; fringe max extent

.PLF44                  ; fringes not saturated

 LDX LSO,Y
 STA LSO,Y
 BEQ PLF11              ; updated extent, if zero No previous old line
 LDA SUNX
 STA YY                 ; Old mid-point of line
 LDA SUNX+1
 STA YY+1               ; hi
 TXA                    ; old lso,y half-width extent
 JSR EDGES              ; horizontal line old extent clip
 LDA X1
 STA XX                 ; old left
 LDA X2
 STA XX+1               ; old right

 LDA K3                 ; Xcenter
 STA YY                 ; new mid-point
 LDA K3+1
 STA YY+1               ; hi
 LDA LSO,Y
 JSR EDGES              ; horizontal line new extent clip
 BCS PLF23              ; No new line
 LDA X2
 LDX XX                 ; old left
 STX X2
 STA XX                 ; swopped old left and new X2 right
 JSR HLOIN              ; horizontal line X1,Y1,X2  Left fringe

.PLF23                  ; also No new line

 LDA XX                 ; old left or new right
 STA X1
 LDA XX+1               ; old right
 STA X2

.PLF16                  ; Draw New line, also from PLF11

 JSR HLOIN              ; horizontal line X1,Y1,X2  Whole old, or new Right fringe.

.PLF6                   ; tail Next line

 DEY                    ; next height Y
 BEQ PLF8               ; Exit Sun fill
 LDA V+1                ; if flag already set
 BNE PLF10              ; take height counter V back up to radius K
 DEC V                  ; else counter height down
 BNE PLFL               ; loop V, Work out extent
 DEC V+1                ; finished down, set flag to go other way.

.PLFLS                  ; loop back to Work out extent

 JMP PLFL               ; loop V back, Work out extent.

.PLF11                  ; No previous old line at Y1 screen

 LDX K3                 ; Xcenter
 STX YY                 ; new mid-point
 LDX K3+1
 STX YY+1               ; hi
 JSR EDGES              ; horizontal line X1,Y1,X2
 BCC PLF16              ; Draw New line, up.
 LDA #0                 ; else no line at height Y
 STA LSO,Y
 BEQ PLF6               ; guaranteed, tail Next line up

.PLF10                  ; V flag set to take height back up to radius K

 LDX V                  ; counter height
 INX                    ; next
 STX V
 CPX K                  ; if height < radius
 BCC PLFLS              ; loop V, Work out extent
 BEQ PLFLS              ; if height = radius, loop V, Work out extent
 LDA SUNX
 STA YY                 ; Onto remaining erase. Old mid-point of line
 LDA SUNX+1
 STA YY+1               ; hi

.PLFL3                  ; rest of counter Y screen line

 LDA LSO,Y
 BEQ PLF9               ; no fringe, skip draw line
 JSR HLOIN2             ; line X1,X2 using YY as mid-point, Acc is half-width

.PLF9                   ; skipped erase line

 DEY                    ; rest of screen
 BNE PLFL3              ; loop Y erase bottom Disc

.PLF8                   ; Exit Planet fill

 CLC                    ; update mid-point of line
 LDA K3
 STA SUNX
 LDA K3+1
 STA SUNX+1

.^RTS2

 RTS                    ; End of Sun fill
}

\ ******************************************************************************
\ Subroutine: CIRCLE
\
\ Circle for planet
\ ******************************************************************************

.CIRCLE                 ; Circle for planet
{
 JSR CHKON              ; P+1 set to maxY
 BCS RTS2               ; rts

 LDA #0
 STA LSX2

 LDX K                  ; radius
 LDA #8                 ; set up STP size based on radius
 CPX #8                 ; is radius X < 8 ?
 BCC PL89               ; small
 LSR A                  ; STP #4
 CPX #60
 BCC PL89               ; small
 LSR A                  ; bigger circles get smaller step

.PL89                   ; small

 STA STP                ; step for ring
}

\ ******************************************************************************
\ Subroutine: CIRCLE2
\
\ also on chart at origin (K3,K4) STP already set
\ ******************************************************************************

.CIRCLE2                ; also on chart at origin (K3,K4) STP already set
{
 LDX #&FF
 STX FLAG
 INX                    ; X = 0
 STX CNT

.PLL3                   ; counter CNT  until = 64

 LDA CNT
 JSR FMLTU2             ; Get K*sin(CNT) in Acc
 LDX #0                 ; hi
 STX T
 LDX CNT                ; the count around the circle
 CPX #33                ; <= #32 ?
 BCC PL37               ; right-half of circle
 EOR #&FF               ; else Xreg = A lo flipped
 ADC #0
 TAX                    ; lo
 LDA #&FF               ; hi flipped
 ADC #0                 ; any carry
 STA T
 TXA                    ; lo flipped, later moved into K6(0,1) for BLINE x offset
 CLC

.PL37                   ; right-half of circle, Acc = xlo

 ADC K3                 ; Xorg
 STA K6                 ; K3(0) + Acc  = lsb of X for bline
 LDA K3+1               ; hi
 ADC T                  ; hi
 STA K6+1               ; K3(1) + T + C = hsb of X for bline

 LDA CNT
 CLC                    ; onto Y
 ADC #16                ; Go ahead a quarter of a quadrant for cosine index
 JSR FMLTU2             ; Get K*sin(CNT) into A
 TAX                    ; y lo =  K*sin(CNT)
 LDA #0                 ; y hi = 0
 STA T
 LDA CNT
 ADC #15                ; count +=15
 AND #63                ; round within 64
 CMP #33                ; <= 32 ?
 BCC PL38               ; if true skip y flip
 TXA                    ; Ylo
 EOR #&FF               ; flip
 ADC #0
 TAX                    ; Ylo flipped
 LDA #&FF               ; hi flipped
 ADC #0                 ; any carry
 STA T
 CLC

.PL38                   ; skipped Y flip

 JSR BLINE              ; ball line uses (X.T) as next y
 CMP #65                ; > #64?
 BCS P%+5               ; hop to exit
 JMP PLL3               ; loop CNT back
 CLC
 RTS                    ; End Circle
}

\ ******************************************************************************
\ Subroutine: WPLS2
\
\ Wipe Planet
\ ******************************************************************************

.WPLS2                  ; Wipe Planet
{
 LDY LSX2               ; 78 bytes used by bline Xcoords
 BNE WP1                ; Avoid lines down

.WPL1                   ; counter Y starts at 0

 CPY LSP
 BCS WP1                ; arc step reached, exit to Avoid lines.
 LDA LSY2,Y             ; buffer Ycoords
 CMP #&FF               ; flag
 BEQ WP2                ; move into X1,Y1
 STA Y2                 ; else move into X2,Y2
 LDA LSX2,Y             ; buffer Xcoords
 STA X2
 JSR LOIN               ; draw line using (X1,Y1), (X2,Y2)
 INY                    ; next vertex
 LDA SWAP
 BNE WPL1               ; loop Y through buffer

 LDA X2                 ; else swap (X2,Y2) -> (X1,Y1)
 STA X1
 LDA Y2
 STA Y1
 JMP WPL1               ; loop Y through buffer

.WP2                    ; flagged move into X1,Y1

 INY                    ; next vertex
 LDA LSX2,Y
 STA X1
 LDA LSY2,Y
 STA Y1
 INY                    ; next vertex
 JMP WPL1               ; loop Y through buffer

.WP1                    ; Avoid lines, used by wipe planet code

 LDA #1
 STA LSP                ; arc step
 LDA #&FF
 STA LSX2
 RTS                    ; WPLS-1
}

\ ******************************************************************************
\ Subroutine: WPLS
\
\ Wipe Sun
\ ******************************************************************************

.WPLS                   ; Wipe Sun
{
 LDA LSX
 BMI WPLS-1             ; rts
 LDA SUNX
 STA YY                 ; mid-point of line lo
 LDA SUNX+1
 STA YY+1               ; hi
 LDY #2*Y-1             ; #2*Y-1 = Yscreen top

.WPL2                   ; counter Y

 LDA LSO,Y
 BEQ P%+5               ; skip hline2
 JSR HLOIN2             ; line using YY as mid-point, A is half-width.
 DEY
 BNE WPL2               ; loop Y
 DEY                    ; Yreg = #&FF, solar empty.
 STY LSX
 RTS
}

\ ******************************************************************************
\ Subroutine: EDGES
\
\ Clip Horizontal line centered on YY to X1 X2
\ ******************************************************************************

.EDGES                  ; Clip Horizontal line centered on YY to X1 X2
{
 STA T
 CLC                    ; trial halfwidth
 ADC YY                 ; add center of line X mid-point
 STA X2                 ; right
 LDA YY+1               ; hi
 ADC #0                 ; any carry
 BMI ED1                ; right overflow
 BEQ P%+6               ; no hsb present, hop to LDA YY
 LDA #254               ; else saturate right
 STA X2

 LDA YY                 ; center of line X mid-point
 SEC                    ; subtract trial halfwidth
 SBC T
 STA X1                 ; left
 LDA YY+1               ; hi
 SBC #0                 ; any carry
 BNE ED3                ; left underflow
 CLC                    ; else, ok draw line
 RTS                    ; X1 and X2 now known

.ED3                    ; left underflow

 BPL ED1                ; X1 left under flow, dont draw.
 LDA #2                 ; else saturate left
 STA X1
 CLC                    ; ok draw line
 RTS

.ED1                    ; right overflow, also left dont draw

 LDA #0                 ; clear line buffer solar
 STA LSO,Y
 SEC                    ; dont draw
 RTS                    ; end of Clipped edges
}

\ ******************************************************************************
\ Subroutine: CHKON
\
\ Check extent of circles, P+1 set to maxY, Y protected.
\ ******************************************************************************

.CHKON                  ; check extent of circles, P+1 set to maxY, Y protected.
{
 LDA K3                 ; Xorg
 CLC
 ADC K                  ; radius
 LDA K3+1               ; hi
 ADC #0
 BMI PL21               ; overflow to right, sec rts
 LDA K3                 ; Xorg
 SEC
 SBC K                  ; radius
 LDA K3+1               ; hi
 SBC #0
 BMI PL31               ; Xrange ok
 BNE PL21               ; underflow to left, sec rts

.PL31                   ; Xrange ok

 LDA K4                 ; Yorg
 CLC
 ADC K                  ; radius
 STA P+1                ; maxY = Yorg+radius
 LDA K4+1               ; hi
 ADC #0
 BMI PL21               ; overflow top, sec rts
 STA P+2                ; maxY hi
 LDA K4                 ; Yorg
 SEC
 SBC K                  ; radius
 TAX                    ; bottom lo
 LDA K4+1               ; hi
 SBC #0
 BMI PL44               ; ok to draw, clc
 BNE PL21               ; bottom underflowed, sec rts
 CPX #2*Y-1             ; #2*Y-1, bottom Ylo >= screen Ytop?
 RTS
}

\ ******************************************************************************
\ Subroutine: PL21
\
\ dont draw
\ ******************************************************************************

.PL21                   ; dont draw
{
 SEC
 RTS
}

\ ******************************************************************************
\ Subroutine: PLS3
\
\ Only Crater uses this, A.Y = 222* INWK(X+=2)/INWK_z
\ ******************************************************************************

.PLS3                   ; only Crater uses this, A.Y = 222* INWK(X+=2)/INWK_z
{
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA P
 LDA #222               ; offset to crater, divide/256 * unit to offset crater center
 STA Q
 STX U                  ; store index
 JSR MULTU              ; P.A = P*Q = 222* INWK(X+=2)/INWK_z
 LDX U                  ; restore index
 LDY K+3                ; sign
 BPL PL12               ; +ve
 EOR #&FF               ; else flip A hi
 CLC
 ADC #1
 BEQ PL12               ; +ve
 LDY #&FF               ; else A flipped
 RTS

.PL12                   ; +ve

 LDY #0
 RTS
}

\ ******************************************************************************
\ Subroutine: PLS4
\
\ CNT2 = angle of P_opp/A_adj for Lave
\ ******************************************************************************

.PLS4                   ; CNT2 = angle of P_opp/A_adj for Lave
{
 STA Q
 JSR ARCTAN             ; A=arctan (P/Q)
 LDX INWK+14            ; rotmat0z hi
 BMI P%+4               ; -ve rotmat0z hi keeps arctan +ve
 EOR #128               ; else arctan -ve
 LSR A
 LSR A                  ; /4
 STA CNT2               ; phase offset
 RTS
}

\ ******************************************************************************
\ Subroutine: PLS5
\
\ Mag K2+2,3 sign XX16+2,3  = NWK(X+=2)/INWK_z for Lave
\ ******************************************************************************

.PLS5                   ; mag K2+2,3 sign XX16+2,3  = NWK(X+=2)/INWK_z for Lave
{
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA K2+2               ; mag
 STY XX16+2             ; sign
 JSR PLS1               ; A.Y = INWK(X+=2)/INWK_z
 STA K2+3               ; mag
 STY XX16+3             ; sign
 RTS
}

\ ******************************************************************************
\ Subroutine: PLS6
\
\ Visited from PROJ \ Klo.Xhi = P.A/INWK_z, C set if big
\ ******************************************************************************

.PLS6                   ; visited from PROJ \ Klo.Xhi = P.A/INWK_z, C set if big
{
 JSR DVID3B2            ; divide 3bytes by 2, K = P(2).A/INWK_z
 LDA K+3
 AND #127               ; sg 7bits
 ORA K+2
 BNE PL21               ; sec rts as too far off
 LDX K+1
 CPX #4                 ; hi >= 4 ? ie >= 1024
 BCS PL6                ; rts as too far off
 LDA K+3                ; sign
\CLC
 BPL PL6                ; rts C clear ok
 LDA K                  ; else flip K lo
 EOR #&FF
 ADC #1                 ; flipped lo
 STA K
 TXA                    ; K+1
 EOR #&FF               ; flip hi
 ADC #0
 TAX                    ; X = K+1 hi flipped
}

\ ******************************************************************************
\ Subroutine: PL44
\
\ ok to draw
\ ******************************************************************************

.PL44                   ; ok to draw
{
 CLC
}

\ ******************************************************************************
\ Subroutine: PL6
\
\ End of Planet, onto keyboard block E ---
\ ******************************************************************************

.PL6
{
 RTS                    ; end of Planet, onto keyboard block E ---
}

\ ******************************************************************************
\ Subroutine: TT17
\
\ Scan the keyboard and joystick for cursor key or stick movement, and return
\ the result as deltas (changes) in x- and y-coordinates as follows:
\
\   * For joystick, X and Y are integers between -2 and +2 depending on how far
\     the stick has moved
\
\   * For keyboard, X and Y are integers between -1 and +1 depending on which
\     keys ar pressed
\
\ Returns:
\
\   A           The key pressed, if the arrow keys were used
\
\   X           Change in the x-coordinate according to the cursor keys being
\               pressed or joystick movement, as an integer (see above)
\
\   Y           Change in the y-coordinate according to the cursor keys being
\               pressed or joystick movement, as an integer (see above)
\ ******************************************************************************

.TT17
{
 JSR DOKEY              ; Scan the keyboard for flight controls and pause keys,
                        ; (or the equivalent on joystick) and update the key
                        ; logger, setting KL to the key pressed

 LDA JSTK               ; If the joystick was not used, jump down to TJ1,
 BEQ TJ1                ; otherwise we move the cursor with the joystick

 LDA JSTX               ; Fetch the joystick roll, ranging from 1 to 255 with
                        ; 128 as the centre point

 EOR #&FF               ; Flip the sign so A = -JSTX, because the joystick roll
                        ; works in the opposite way to moving a cursor on screen
                        ; in terms of left and right

 JSR TJS1               ; Call TJS1 just below to set Y to a value between -2
                        ; and +2 depending on the joystick roll value (moving
                        ; the stick sideways)

 TYA                    ; Copy Y to A and X
 TAX

 LDA JSTY               ; Fetch the joystick pitch, ranging from 1 to 255 with
                        ; 128 as the centre point, and fall through into TJS1 to
                        ; joystick pitch value (moving the stick up and down)

.TJS1

 TAY                    ; Store A in Y

 LDA #0                 ; Set the result, A = 0

 CPY #&10               ; If Y >= &10 set carry, so A = A - 1
 SBC #0

\CPY #&20               ; These instructions are commented out in the original
\SBC #0                 ; source, but they would make the joystick move the
                        ; cursor faster by increasing the range of Y by -1 to +1

 CPY #&40               ; If Y >= &40 set carry, so A = A - 1
 SBC #0

 CPY #&C0               ; If Y >= &C0 set carry, so A = A + 1
 ADC #0

 CPY #&E0               ; If Y >= &E0 set carry, so A = A + 1
 ADC #0

\CPY #&F0               ; These instructions are commented out in the original
\ADC #0                 ; source, but they would make the joystick move the
                        ; cursor faster by increasing the range of Y by -1 to +1

 TAY                    ; Copy the value of A into Y

 LDA KL                 ; Set A to the value of KL (the key pressed)

 RTS                    ; Return from subroutine

.TJ1                    ; Arrows from keyboard

 LDA KL                 ; Set A to the value of KL (the key pressed)

 LDX #0                 ; Set the results, X = Y = 0
 LDY #0

 CMP #&19               ; If left arrow was pressed, set X = X - 1
 BNE P%+3
 DEX

 CMP #&79               ; If right arrow was pressed, set X = X + 1
 BNE P%+3
 INX

 CMP #&39               ; If up arrow was pressed, set Y = Y + 1
 BNE P%+3
 INY

 CMP #&29               ; If down arrow was pressed, set Y = Y - 1
 BNE P%+3
 DEY

 RTS                    ; Return from subroutine
}

\ ******************************************************************************
\ Subroutine: ping
\
\ Set the target system to the current system.
\ ******************************************************************************

.ping
{
 LDX #1                 ; We want to copy the X- and Y-coordinates of the
                        ; current system in (QQ0, QQ1) to the target system's
                        ; coordinates in (QQ9, QQ10), so set up a counter to
                        ; copy two bytes

.pl1

 LDA QQ0,X              ; Load byte X from the current system in QQ0/QQ1

 STA QQ9,X              ; Store byte X in the target system in QQ9/QQ10
 
 DEX                    ; Decrement the loop counter

 BPL pl1                ; Loop back for the next byte to copy

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Save output/ELTE.bin
\ ******************************************************************************

PRINT "ELITE E"
PRINT "Assembled at ", ~CODE_E%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_E%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_E%

PRINT "S.ELTE ", ~CODE_E%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_E%
SAVE "output/ELTE.bin", CODE_E%, P%, LOAD%

\ ******************************************************************************
\ ELITE F
\
\ Produces the binary file ELTF.bin which gets loaded by elite-bcfs.asm.
\ ******************************************************************************

CODE_F% = P%
LOAD_F% = LOAD% + P% - CODE%

\ ******************************************************************************
\ Subroutine: KS3
\
\ exit as end found, temp P correct.
\ ******************************************************************************

.KS3                    ; exit as end found, temp P correct.
{
 LDA P                  ; temp pointer lo
 STA SLSP               ; last ship lines stack pointer
 LDA P+1                ; temp pointer hi
 STA SLSP+1
 RTS
}

\ ******************************************************************************
\ Subroutine: KS1
\
\ Kill ships from Block A loop Enters here
\ ******************************************************************************

.KS1                    ; Kill ships from Block A loop Enters here
{
 LDX XSAV               ; nearby ship index
 JSR KILLSHP            ; Kill target X, down.
 LDX XSAV               ; reload ship index
 JMP MAL1               ; rejoin loop in Block A
}

\ ******************************************************************************
\ Subroutine: KS4
\
\ Removing Space Station to make new Sun
\ ******************************************************************************

.KS4                    ; removing Space Station to make new Sun
{
 JSR ZINF               ; Call ZINF to reset the INWK ship workspace
                        ; ends with A = #&C0.
 JSR FLFLLS             ; ends with A=0
 STA FRIN+1             ; #SST slot emptied
 STA SSPR               ; space station present, 0 is SUN.
 JSR SPBLB              ; erase space station bulb "S" symbol
 LDA #6                 ; sun location up in the sky
 STA INWK+5             ; ysg
 LDA #&81               ; new Sun
 JMP NWSHP              ; new ship type Acc
}

\ ******************************************************************************
\ Subroutine: KS2
\
\ frin shuffled, update Missiles
\ ******************************************************************************

.KS2                    ; frin shuffled, update Missiles
{
 LDX #&FF

.KSL4                   ; counter X

 INX                    ; starts at X=0
 LDA FRIN,X             ; nearby ship types
 BEQ KS3                ; exit as end found, up temp P correct.
 CMP #MSL               ; else this slot is a missile?
 BNE KSL4               ; not missile, loop X
 TXA                    ; else, missile
 ASL A                  ; slot*2
 TAY                    ; build index Y into
 LDA UNIV,Y
 STA SC                 ; missile info lo
 LDA UNIV+1,Y
 STA SC+1               ; missile info hi

 LDY #32                ; info byte#32 is ai_attack_univ_ecm
 LDA (SC),Y
 BPL KSL4               ; ai dumb, loop X
 AND #&7F               ; else, drop ai active bit
 LSR A                  ; bit6, attack you, can be ignored here
 CMP XX4                ; kill target id
 BCC KSL4               ; loop if missile doesn't have target XX4
 BEQ KS6                ; else found missile X with kill target XX4
 SBC #1                 ; else update target -=1
 ASL A                  ; update missile ai
 ORA #128               ; set bit7, ai is active.
 STA (SC),Y
 BNE KSL4               ; guaranteed loop X

.KS6                    ; found missile X with kill target XX4

 LDA #0                 ; missile dumb, no attack target.
 STA (SC),Y
 BEQ KSL4               ; guaranteed loop X
}

\ ******************************************************************************
\ Subroutine: KILLSHP
\
\ Kill target X Entry
\ ******************************************************************************

.KILLSHP                ; Kill target X Entry
{
 STX XX4                ; store kill target slot id
\CPX MSTG
 LDA MSTG               ; NOT IN ELITEF.TXT but is in ELITE SOURCE IMAGE
 CMP XX4                ; was targeted by player's missile? NOT IN ELITEF.TXT but is in ELITE SOURCE IMAGE
 BNE KS5                ; dstar, else no target for player's missile
 LDY #&EE               ; colour strip green for missile indicator
 JSR ABORT              ; draw missile indicator
 LDA #200               ; token = target lost
 JSR MESS               ; message and rejoin

.KS5                    ; dstar

 LDY XX4                ; kill target slot id
 LDX FRIN,Y             ; target ship type
 CPX #SST               ; #SST space station?
 BEQ KS4                ; removing Space Station, up
 DEC MANY,X             ; remove from sums of each type 
 LDX XX4                ; reload kill target id, lost type.

 LDY #5                 ; target Hull byte#5 maxlines
 LDA (XX0),Y
 LDY #33                ; info byte#33 is XX19, the ship heap pointer lo
 CLC                    ; unwind lines pointer
 ADC (INF),Y
 STA P                  ; new pointer lo
 INY                    ; info byte#34 is XX19 hi
 LDA (INF),Y
 ADC #0                 ; new pointer hi 
 STA P+1

.KSL1                   ; counter X shuffle higher ships down

 INX                    ; above target id
 LDA FRIN,X             ; nearby ship types
 STA FRIN-1,X           ; down one
 BEQ KS2                ; else exit as frin shuffled, update Missiles up
 ASL A                  ; build index
 TAY                    ; for hull type
 LDA XX21-2,Y
 STA SC                 ; hull data lo
 LDA XX21-1,Y
 STA SC+1               ; hull data hi
 LDY #5                 ; higher Hull byte#5 maxlines
 LDA (SC),Y
 STA T                  ; maxlines for ship heap after XX4
 LDA P                  ; pointer temp lo
 SEC
 SBC T                  ; maxlines for ship heap after XX4
 STA P                  ; pointer temp lo -= maxlines
 LDA P+1
 SBC #0                 ; any carry
 STA P+1
 TXA                    ; slot above target
 ASL A                  ; build index
 TAY                    ; for ship info
 LDA UNIV,Y
 STA SC                 ; inf pointer of higher ship
 LDA UNIV+1,Y
 STA SC+1               ; hi
 LDY #35                ; NEWB of higher ship
 LDA (SC),Y
 STA (INF),Y
 DEY                    ; info#byte35 = energy
 LDA (SC),Y
 STA K+1                ; heap pointer temp hi
 LDA P+1                ; pointer temp hi - maxlines
 STA (INF),Y            ; new XX19 hi
 DEY                    ; info byte#33 = XX19 ship heap pointer lo
 LDA (SC),Y
 STA K                  ; heap pointer temp lo
 LDA P                  ; pointer temp lo - maxlines
 STA (INF),Y            ; new XX19 lo
 DEY                    ; #32 = rest of inwk, ai downwards.

.KSL2                   ; counter Y

 LDA (SC),Y
 STA (INF),Y
 DEY                    ; next inwk byte
 BPL KSL2               ; loop Y
 LDA SC                 ; pointer for inf in slot above
 STA INF
 LDA SC+1               ; hi
 STA INF+1
 LDY T                  ; maxlines for ship heap after XX4 counter

.KSL3                   ; counter Y

 DEY                    ; move entries
 LDA (K),Y              ; on old heap to
 STA (P),Y              ; new temp heap
 TYA
 BNE KSL3               ; loop Y
 BEQ KSL1               ; guaranteed up, shuffle higher slots remaining
}

\ ******************************************************************************
\ Variable: SFX
\
\ Sound data. To make a sound, the NOS1 routine copies the four relevant sound
\ bytes to XX16, and NO3 then makes the sound. The sound numbers are shown in
\ the table, and are always multiples of 8. Generally, sounds are made by
\ calling the NOISE routine with the sound number in A.
\
\ These bytes are passed to OSWORD 7, and are the equivalents to the parameters
\ passed to the SOUND keyword in BASIC. The parameters therefore have these
\ meanings:
\
\   channel/flush, amplitude (or envelope number if 1-4), pitch, duration
\
\ For the channel/flush parameter, the first byte is the channel while the
\ second is the flush control (where a flush control of 0 queues the sound,
\ while a flush control of 1 makes the sound instantly). When written in
\ hexadecimal, the first figure gives the flush control, while the second is
\ the channel (so &13 indicates flush control = 1 and channel = 3).
\
\ So when we call NOISE with A = 40 to make a long, low beep, then this is
\ effectively what the NOISE routine does:
\
\   SOUND &13, &F4, &0C, &08
\
\ which makes a sound with flush control 1 on channel 3, and with amplitude &F4
\ (-12), pitch &0C (2) and duration &08 (8). Meanwhile, to make the hyperspace
\ sound, the NOISE routine does this:
\
\   SOUND &10, &02, &60, &10
\
\ which makes a sound with flush control 1 on channel 0, using envelope 2,
\ and with pitch &60 (96) and duration &10 (16). The four sound envelopes (1-4)
\ are set up in elite-loader.asm.
\ ******************************************************************************

.SFX
{
 EQUB &12,&01,&00,&10   ; 0  - Lasers fired by us
 EQUB &12,&02,&2C,&08   ; 8  - We're being hit by lasers
 EQUB &11,&03,&F0,&18   ; 16 - We died 1 / We made a hit or kill 2
 EQUB &10,&F1,&07,&1A   ; 24 - We died 2 / We made a hit or kill 1
 EQUB &03,&F1,&BC,&01   ; 32 - Short, high beep
 EQUB &13,&F4,&0C,&08   ; 40 - Long, low beep
 EQUB &10,&F1,&06,&0C   ; 48 - Missile launched / Ship launched from station
 EQUB &10,&02,&60,&10   ; 56 - Hyperspace drive engaged
 EQUB &13,&04,&C2,&FF   ; 64 - E.C.M. on
 EQUB &13,&00,&00,&00   ; 72 - E.C.M. off
}

\ ******************************************************************************
\ Subroutine: RESET
\
\ Reset our ship and various controls, then fall through into RES4 to restore
\ shields and energy, and reset the stardust and the ship workspace at INWK.
\
\ In this subroutine, this means zero-filling the following locations:
\
\   * Pages &9, &A, &B, &C and &D
\
\   * BETA to BETA+6, which covers the following:
\
\     * BETA, BET1 - Set pitch to 0
\
\     * XC, YC - Set text cursor to (0, 0)
\
\     * QQ22 - Set hyperspace counters to 0
\
\     * ECMA - Turn E.C.M. off
\
\ It also sets QQ12 to &FF, to indicate we are docked, and then falls through
\ into RES4.
\ ******************************************************************************

.RESET
{
 JSR ZERO               ; Zero-fill pages &9, &A, &B, &C and &D

 LDX #6                 ; Set up a counter for zeroing BETA through BETA+6

.SAL3

 STA BETA,X             ; Zero the X-th byte after BETA

 DEX                    ; Decrement the loop counter

 BPL SAL3               ; Loop back for the next byte to zero

 STX QQ12               ; X is now negative - i.e. &FF - so this sets QQ12 to
                        ; &FF to indicate we are docked

                        ; Fall through into RES4 to restore shields and energy,
                        ; and reset the stardust and ship workspace at INWK
}

\ ******************************************************************************
\ Subroutine: RES4
\
\ Reset the shields and energy banks, then fall through into RES2 to reset the
\ stardust and the ship workspace at INWK.
\ ******************************************************************************

.RES4
{
 LDA #&FF               ; Set A to &FF so we can fill up the shields and energy
                        ; bars with a full charge

 LDX #2                 ; The two shields and energy bank levels are stored in
                        ; three consecutive bytes, at FSH through FSH+2, so set
                        ; up a counter in X to index these three bytes

.REL5

 STA FSH,X              ; Set the X-th byte in the FSH block to &FF

 DEX                    ; Decrement the loop counter

 BPL REL5               ; Loop back to do the next byte, until we have done
                        ; all three

                        ; Fall through into RES2 to reset stardust and INWK
}

\ ******************************************************************************
\ Subroutine: RES2
\
\ Reset a number of flight variables and workspaces.
\
\ This is called after we launch from a space station, arrive in a new system
\ after hyperspace, launch an escape pod, or die a cold, lonely death in the
\ depths of space.
\ ******************************************************************************

.RES2
{
 LDA #NOST              ; Reset NOSTM, the number of stardust particles, to the
 STA NOSTM              ; maximum allowed (18)

 LDX #&FF               ; Reset LSX2 and LSY2, the buffers used by the BLINE
 STX LSX2               ; routine for drawing the planet's ball line, to &FF
 STX LSY2

 STX MSTG               ; Reset MSTG, the missile target, to &FF (no target)

 LDA #128               ; Set the current pitch rate to the mid-point, 128
 STA JSTY

 STA ALP2               ; Reset ALP2 (flipped roll sign) and BET2 (pitch sign)
 STA BET2               ; to negative, i.e. roll positive, pitch negative

 ASL A                  ; This sets A to 0

 STA ALP2+1             ; Reset ALP2+1 (roll sign) and BET2+1 (flipped pitch
 STA BET2+1             ; sign) to positive, i.e. roll positive, pitch negative

 STA MCNT               ; Reset MCNT (move count) to 0

 LDA #3                 ; Reset DELTA (speed) to 3
 STA DELTA

 STA ALPHA              ; Reset ALPHA (flipped reduced roll rate) to 3

 STA ALP1               ; Reset ALP1 (reduced roll rate) to 3

 LDA SSPR               ; Fetch the "space station present" flag, and if we are
 BEQ P%+5               ; not inside the safe zone, skip the next instruction

 JSR SPBLB              ; Light up the space station bulb on the dashboard

 LDA ECMA               ; Fetch the E.C.M. status flag, and if E.C.M. is off,
 BEQ yu                 ; skip the next instruction

 JSR ECMOF              ; Turn off the E.C.M. sound

.yu

 JSR WPSHPS             ; Wipe all ships from the scanner

 JSR ZERO               ; Zero-fill pages &9, &A, &B, &C and &D

 LDA #LO(WP-1)          ; Reset the ship lines pointer to be empty, so point
 STA SLSP               ; SLSP to the byte before the WP workspace
 LDA #HI(WP-1)
 STA SLSP+1

 JSR DIALS              ; Update the dashboard

                        ; Finally, fall through into ZINF to reset the INWK
                        ; ship workspace
}

\ ******************************************************************************
\ Subroutine: ZINF
\
\ Zero-fill the INWK ship workspace and reset the rotation matrix.
\ ******************************************************************************

.ZINF
{
 LDY #NI%-1             ; There are NI% bytes in the INWK workspace, so set a
                        ; counter in Y so we can loop through them

 LDA #0                 ; Set A to 0 so we can zero-fill the workspace

.ZI1

 STA INWK,Y             ; Zero the Y-th byte of the INWK workspace

 DEY                    ; Decrement the loop counter

 BPL ZI1                ; Loop back for the next byte, ending when we have
                        ; zero-filled the last byte at INWK

                        ; Finally, we reset the rotation matrix to unity,
                        ; as follows:
                        ;
                        ;                   (rotmat0x rotmat0y rotmat0z)
                        ; Rotation matrix = (rotmat1x rotmat1y rotmat1z)
                        ;                   (rotmat2x rotmat2y rotmat2z)
                        ;
                        ;                   (INWK+10,9  INWK+12,11 INWK+14,13)
                        ;                 = (INWK+16,15 INWK+18,17 INWK+20,19)
                        ;                   (INWK+22,21 INWK+24,23 INWK+26,25)
                        ;
                        ;                   (  0     0   &E000)   (0  0 -1)
                        ;                 = (  0   &6000   0  ) = (0  1  0)
                        ;                   (&6000   0     0  )   (1  0  0)
                        ;
                        ; &6000 represents 1 in the rotation matrix, while
                        ; &E000 represents -1
                        ;
                        ; We already set the whole matrix to zero above, so
                        ; we just need to set up the diagonal values and we're
                        ; done.

 LDA #&60               ; Set A to represent a 1 in the matrix

 STA INWK+18            ; Set INWK+18 = rotmat1y_hi = &60 = 1 in the matrix
 STA INWK+22            ; Set INWK+22 = rotmat2x_hi = &60 = 1 in the matrix

 ORA #128               ; Flip the sign of A to represent a -1 in the matrix

 STA INWK+14            ; Set INWK+14 = rotmat0z_hi = &E0 = -1 in the matrix

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: msblob
\
\ Update the dashboard's missile indicators
\ ******************************************************************************

.msblob                 ; update missile indicators on console
{
 LDX #4                 ; number of missile indicators

.ss                     ; counter X

 CPX NOMSL              ; compare Xreg to number of missiles
 BEQ SAL8               ; remaining missiles are green
 LDY #0                 ; else black bar
 JSR MSBAR              ; draw missile indicator Xreg
 DEX                    ; next missile
 BNE ss                 ; loop X
 RTS

.SAL8                   ; remaining missiles are green, counter X

 LDY #&EE               ; green
 JSR MSBAR              ; draw missile indicator Xreg
 DEX                    ; next missile
 BNE SAL8               ; loop X
 RTS
}

\ ******************************************************************************
\ Subroutine: me2
\
\ Remove an in-flight message from the space view.
\ ******************************************************************************

.me2
{
 LDA MCH                ; Fetch the token number of the current message into A

 JSR MESS               ; Call MESS to print the token, which will remove it
                        ; from the screen as printing uses EOR logic

 LDA #0                 ; Set the delay in DLY to 0, to indicate that we are
 STA DLY                ; no longer showing an in-flight message

 JMP me3                ; Jump back into the main spawning loop at TT100
}

\ ******************************************************************************
\ Subroutine: Ze
\
\ Initialise INWK to a hostile ship. Specifically:
\
\   * Reset the INWK ship workspace
\ 
\   * Set the ship to a fair distance away (32) in all axes, in front of us but
\     randomly up or down, left or right
\
\   * Give the ship a 4% chance of having E.C.M.
\ 
\   * Set the ship to hostile, with AI enabled
\
\ Also sets X and T1 to a random value, and A to a random value between 192 and
\ 255,and the C flag randomly.
\ ******************************************************************************

.Ze
{
 JSR ZINF               ; Call ZINF to reset the INWK ship workspace

 JSR DORND              ; Set A and X to random numbers

 STA T1                 ; Store A in T1

 AND #%10000000         ; Extract the sign of A and store in x_sign
 STA INWK+2

 TXA                    ; Extract the sign of X and store in y_sign
 AND #%10000000
 STA INWK+5

 LDA #32                ; Set x_hi = y_hi = z_hi = 32, a fair distance away
 STA INWK+1
 STA INWK+4
 STA INWK+7

 TXA                    ; Set the C flag if X >= 245 (4% chance)
 CMP #245

 ROL A                  ; Set bit 0 of A to the C flag (i.e. there's a 4%
                        ; chance of this ship having E.C.M.)

 ORA #%11000000         ; Set bits 6 and 7 of A, so the ship is hostile (bit 6
                        ; and has AI (bit 7)
                        
 STA INWK+32            ; Store A in the AI flag of this ship
}

\ ******************************************************************************
\ Subroutine: DORND2
\
\ A version of DORND that restricts the value of r2 so that bit 0 is always 0.
\ Having C cleared changes the calculations in DORND to:
\
\   r2´ = ((r0 << 1) mod 256)
\   r0´ = r2´ + r2 + bit 7 of r0
\
\ so r2´ always has bit 0 cleared, i.e. r2 is always a multiple of 2.
\ ******************************************************************************

.DORND2
{
 CLC                    ; This ensures that bit 0 of r2 is 0
}

\ ******************************************************************************
\ Subroutine: DORND
\
\ Set A and X to random numbers. Carry flag is also set randomly. Overflow flag
\ will be have a 50% probability of being 0 or 1.
\
\ There are two calculations of two 8-bit numbers in this routine. The first
\ pair is at RAND and RAND+2 (let's call them r0 and r2) and the second pair
\ is at RAND+1 and RAND+3 (let's call them r1 and r3).
\
\ The values of r0 and r2 are not read by any other routine apart from this
\ one, so they are effectively internal to the random number generation
\ routine. r1 and r3, meanwhile, are returned in A and X with each call to
\ DORND, and along with the returned values of the C and V flags, form the
\ the random results we're looking for.
\
\ The seeds are overwritten in three places:
\
\   * All four locations are updated by EXL2, using a STA &FFFD,Y instruction
\     with Y = 2, 3, 4, 5 (so this points the write to zero page location &00,
\     which is where RAND is located, in the first four bytes of memory).
\
\  * r0 is written to at the start of M% in the main loop, to seed the random
\    number generator. Here, r0 is set to the first byte of the ship data block
\    at K% (x_lo for the first ship at K%).
\
\  * r3 is written to in EX4 as part of the explosion routine, with r3 being
\    set to the seventh byte of the ship data block at K%+6 (z_lo for the
\    first ship at K%).
\
\ r0 and r2 follow the following sequence through successive calls to DORND,
\ going from r0 and r2 to r0´ and r2´ with each call:
\
\   r2´ = ((r0 << 1) mod 256) + C
\   r0´ = r2´ + r2 + bit 7 of r0
\
\ C is the carry flag on entry. If this routine is entered with the carry flag
\ clear, e.g. via DORND2, then if bit 0 of RAND+2 is 0, it will remain at 0.
\
\ r1 and r3 (which are returned in A and X) follow this number sequence through
\ successive calls to DORND, going from r1 and r3 to r1´ and r3´:
\
\   A = r1´ = r1 + r3 + C
\   X = r3´ = r1
\
\ C is the carry flag from the calculation of r0´ above, i.e. from the addition
\ of r2´ with r2 and bit 7 of r0. Because r3´ is set to r1, this can be thought
\ of as a number sequence, with A being the next number in the sequence and X
\ being the value of A from the previous call.
\ ******************************************************************************

.DORND
{
 LDA RAND               ; r2´ = ((r0 << 1) mod 256) + C
 ROL A                  ; r0´ = r2´ + r2 + bit 7 of r0
 TAX
 ADC RAND+2             ; C = carry bit from r0´ calculation
 STA RAND
 STX RAND+2

 LDA RAND+1             ; A = r1´ = r1 + r3 + C
 TAX                    ; X = r3´ = r1
 ADC RAND+3
 STA RAND+1
 STX RAND+3

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: Main game loop (Part 1)
\
\ This is part of the main game loop. This section covers the following:
\
\   * Spawn a trader, i.e. a Cobra Mk III that isn't attacking anyone, with one
\     missile and a 50% chance of having an E.C.M., a speed between 16 and 31,
\     and a clockwise roll
\
\ We call this from within the main loop, with A set to a random number and the
\ carry flag set.
\ ******************************************************************************

{
.MTT4

 LSR A                  ; Clear bit 7 of our random number in A

 STA INWK+32            ; Store this in the ship's AI flag, so this ship does
                        ; not have AI

 STA INWK+29            ; Store A in the ship's rotx counter, giving it a
                        ; clockwise roll (as bit 7 is clear), and a 1 in 127
                        ; chance of it having no damping

 ROL INWK+31            ; Set bit 0 of missile count (as we know the carry flag
                        ; is set), giving the ship one missile

 AND #31                ; Set the ship speed to our random number, set to a
 ORA #16                ; minimum of 16 and a maximum of 31
 STA INWK+27

 LDA #CYL               ; Add a new Cobra Mk III to the local universe and fall
 JSR NWSHP              ; through into the main game loop again

\ ******************************************************************************
\ Subroutine: Main game loop (Part 2)
\
\ Other entry points: TT100, me3
\
\ This is part of the main game loop. This section covers the following:
\
\   * Call M% to do the main flight loop
\
\   * Potentially spawn a trader, asteroid or cargo canister
\ ******************************************************************************

.^TT100

 JSR M%                 ; Call the M% routine to do the main flight loop

 DEC DLY                ; Decrement the delay counter in DLY, so any in-flight
                        ; messages get removed once the counter reaches zero

 BEQ me2                ; If DLY is now 0, jump to me2 to remove any in-flight
                        ; message from the space view, and once done, return to
                        ; me3 below, skipping the following two instructions

 BPL me3                ; If DLY is positive, jump to me3 to skip the next
                        ; instruction

 INC DLY                ; If we get here, DLY is negative, so we have gone too
                        ; and need to increment DLY back to 0

.^me3

 DEC MCNT               ; Decrement the main loop counter in MCNT

 BEQ P%+5               ; If the counter has reached zero, which it will do
                        ; every 256 main loops, skip the next JMP instruction
                        ; (or to put it another way, if the counter hasn't
                        ; reached zero, jump down to MLOOP, skipping all the
                        ; following checks)

.ytq

 JMP MLOOP              ; Jump down to MLOOP to do some end-of-loop tidying and
                        ; restart the main loop

                        ; We only get here once every 256 iterations of the
                        ; main loop. If we aren't in witchspace and don't
                        ; already have 3 or more asteroids in our local bubble,
                        ; then this section has a 13% chance of spawning a new
                        ; ship. 50% of the time this will be a Cobra Mk III,
                        ; and the other 50% of the time it will either be an
                        ; asteroid (98.5% chance) or, very rarely, a cargo
                        ; (1.5% chance) canister.

 LDA MJ                 ; If we are in witchspace following a mis-jump, skip the
 BNE ytq                ; following by jumping down to MLOOP (via ytq above)

 JSR DORND              ; Set A and X to random numbers

 CMP #35                ; If A >= 35 (87% chance), jump down to MTT1 to skip
 BCS MTT1               ; the spawning of an asteroid or cargo canister and
                        ; potentially spawn something else

 LDA MANY+AST           ; If we already have 3 or more asteroids in the local
 CMP #3                 ; bubble, jump down to MTT1 to skip the following and
 BCS MTT1               ; potentially spawn something else

 JSR ZINF               ; Call ZINF to reset the INWK ship workspace

 LDA #38                ; Set z_hi = 38 (far away)
 STA INWK+7

 JSR DORND              ; Set A, X and carry flag to random numbers

 STA INWK               ; Set x_lo = random

 STX INWK+3             ; Set y_lo = random

 AND #%10000000         ; Set x_sign = bit 7 of x_lo
 STA INWK+2

 TXA                    ; Set y_sign = bit 7 of y_lo
 AND #%10000000
 STA INWK+5

 ROL INWK+1             ; Set bit 2 of x_hi to the carry flag, which is random,
 ROL INWK+1             ; so this randomly moves us slightly off-centre

 JSR DORND              ; Set A, X and overflow flag to random numbers

 BVS MTT4               ; If overflow is set (50% chance), jump up to MTT4 to
                        ; spawn a trader

 ORA #%01101111         ; Take the random number in A and set bits 0-3 and 5-6,
 STA INWK+29            ; so the result has a 50% chance of being positive or
                        ; negative, and a 50% chance of bits 0-6 being 127.
                        ; Storing this number in the rotx counter therefore
                        ; gives our new ship a fast roll speed with a 50%
                        ; chance of having no damping, plus a 50% chance of
                        ; rolling clockwise or anti-clockwise

 LDA SSPR               ; If we are inside the space station safe zone, jump 
 BNE MTT1               ; down to MTT1 to skip the following and potentially
                        ; spawn something else

 TXA                    ; Set A to the random X we set above, which we haven't
 BCS MTT2               ; used yet, and if carry is set (50% chance) jump down
                        ; to MTT2 to skip the following

 AND #31                ; Set the ship speed to our random number, set to a
 ORA #16                ; minimum of 16 and a maximum of 31
 STA INWK+27

 BCC MTT3               ; Jump down to MTT3, skipping the following (this BCC
                        ; is effectively a JMP as we know the carry flag is
                        ; clear, having passed through the BCS above)

.MTT2

 ORA #%01111111         ; Set bits 0-6 of A to 127, leaving bit 7 as random, so
 STA INWK+30            ; storing this number in the rotz counter means we have
                        ; full pitch with no damping, with a 50% chance of
                        ; pitching up or down

.MTT3

 JSR DORND              ; Set A and X to random numbers

 CMP #5                 ; Set A to the ship number of an asteroid, and keep
 LDA #AST               ; this value for 98.5% of the time (i.e. if random
 BCS P%+4               ; A >= 5 skip the following instruction)

 LDA #OIL               ; Set A to the ship number of a cargo canister

 JSR NWSHP              ; Add our new asteroid or canister to the universe

\ ******************************************************************************
\ Subroutine: Main game loop (Part 3)
\
\ This is part of the main game loop. This section covers the following:
\
\   * Potentially spawn a cop
\ ******************************************************************************

.MTT1

 LDA SSPR               ; If we are inside the space station's safe zone, jump
 BNE MLOOP              ; to MLOOP to skip the following

 JSR BAD                ; Call BAD to work out how much illegal contraband we
                        ; are carrying in our hold (A is up to 40 for a
                        ; standard hold crammed with contraband, up to 70 for
                        ; an extended cargo hold full of narcotics and slaves)

 ASL A                  ; Double A to a maximum of 80 or 140

 LDX MANY+COPS          ; If there are no cops in the local bubble, skip the
 BEQ P%+5               ; next instruction

 ORA FIST               ; There are cops in the vicinity and we've got a hold
                        ; full of jail time, so OR the value in A with FIST to
                        ; get a new value that is at least as high as both
                        ; values, to reflect the fact that they have almost
                        ; certainly scanned our ship

 STA T                  ; Store our badness level in T

 JSR Ze                 ; Call Ze to initialise INWK to a potentially hostile
                        ; ship, and set X to a random value and A to a random
                        ; value between 192 and 255

 CMP T                  ; If the random value in A >= our badness level, which
 BCS P%+7               ; will be the case unless we have been really, really
                        ; bad, then skip the following two instructions (so if
                        ; we are really bad, there's a higher chance of
                        ; spawning a cop, otherwise we got away with it, for
                        ; now)

 LDA #COPS              ; Add a new police ship to the local bubble
 JSR NWSHP

 LDA MANY+COPS          ; If we now have at least one cop in the local bubble,
 BNE MLOOP              ; jump down to MLOOP, otherwise fall through into the
                        ; next part to look at spawning something else

\ ******************************************************************************
\ Subroutine: Main game loop (Part 4)
\
\ This is part of the main game loop. This section covers the following:
\
\   * Potentially spawn a lone bounty hunter, a Thargoid, or a group of up to 4
\     pirates
\ ******************************************************************************

 DEC EV                 ; Decrement EV, the extra vessels spawning delay, and 
 BPL MLOOP              ; jump to MLOOP if it is still positive, so we only
                        ; do the following when the EV counter runs down

 INC EV                 ; EV is negative, so bump it up again, setting it back
                        ; to 0

 JSR DORND              ; Set A and X to random numbers

 LDY gov                ; If the government of this system is 0 (anarchy), jump
 BEQ LABEL_2            ; straight to LABEL_2 to start spawning pirates or a
                        ; lone bounty hunter

 CMP #90                ; If the random number in A >= 90 (65% chance), jump to
 BCS MLOOP              ; MLOOP to stop spawning (so there's a 35% chance of
                        ; spawning pirates or a lone bounty hunter)

 AND #7                 ; Reduce the random number in A to the range 0-7, and
 CMP gov                ; if A is less than government of this system, jump
 BCC MLOOP              ; to MLOOP to stop spawning (so safer governments with
                        ; larger gov numbers have a greater chance of jumping
                        ; out, which is another way of saying that more
                        ; dangerous systems spawn pirates and bounty hunters
                        ; more often)
 
.LABEL_2                ; Now to spawn a lone bounty hunter, a Thargoid or a
                        ; group of pirates

 JSR Ze                 ; Call Ze to initialise INWK to a potentially hostile
                        ; ship, and set X to a random value and A to a random
                        ; value between 192 and 255

 CMP #200               ; If the random number in A >= 200 (87% chance), jump
 BCS mt1                ; to mt1 to spawn pirates, otherwise keep going to
                        ; spawn a lone bounty hunter or a Thargoid

 INC EV                 ; Increase the extra vessels spawning counter, to
                        ; prevent the next attempt to spawn extra vessels

 AND #3                 ; Set A = Y = random number in the range 3-6, which
 ADC #3                 ; we will use to determine the type of ship
 TAY

                        ; We now build the AI flag for this ship in A

 TXA                    ; First, set the C flag if X >= 200 (22% chance)
 CMP #200

 ROL A                  ; Set bit 0 of A to the C flag (i.e. there's a 22%
                        ; chance of this ship having E.C.M.)

 ORA #%11000000         ; Set bits 6 and 7 of A, so the ship is hostile (bit 6
                        ; and has AI (bit 7)

 CPY #6                 ; If Y = 6 (i.e. a Thargoid), jump down to the tha
 BEQ tha                ; routine to decide whether or not to spawn it (where
                        ; there's a 22% chance of this happening)

 STA INWK+32            ; Store A in the AI flag of this ship

 TYA                    ; Add a new ship of type Y to the local bubble
 JSR NWSHP

.mj1

 JMP MLOOP              ; Jump down to MLOOP, as we are done spawning ships

.mt1

 AND #3                 ; It's time to spawn a group of pirates, so set A to a
                        ; random number in the range 0-3, which will be the
                        ; loop counter for spawning pirates below (so we will
                        ; spawn 1-4 pirates)

 STA EV                 ; Delay further spawnings by this number

 STA XX13               ; Store the number in XX13, the pirate counter

.mt3

 JSR DORND              ; Set A and X to random numbers

 AND #3                 ; Set A to a random number in the range 0-3

 ORA #1                 ; Set A to %01 or %11 (Sidewinder or Mamba)

 JSR NWSHP              ; Add a new ship of type A to the local bubble

 DEC XX13               ; Decrement the pirate counter

 BPL mt3                ; If we need more pirates, loop back up to mt3,
                        ; otherwise we are done spawning, so fall through into
                        ; the end of the main loop at MLOOP

\ ******************************************************************************
\ Subroutine: Main game loop (Part 5)
\
\ Other entry points: MLOOP
\
\ This is part of the main game loop. This section covers the following:
\
\   * Cool down lasers
\
\   * Make calls to update the dashboard
\ ******************************************************************************

.^MLOOP
 LDA #%00000001         ; Set 6522 System VIA interrupt enable register IER
 STA SHEILA+&4E         ; (SHEILA &4E) bit 1 (i.e. disable the CA2 interrupt,
                        ; which comes from the keyboard)

 LDX #&FF               ; Reset the 6502 stack pointer, which clears the stack
 TXS

 LDX GNTMP              ; If the laser temperature in GNTMP is non-zero,
 BEQ EE20               ; decrement it (i.e. cool it down a bit))
 DEC GNTMP

.EE20

 JSR DIALS              ; Call DIALS to update the dashboard

 LDA QQ11               ; If this is a space view, skip the following four
 BEQ P%+11              ; instructions (i.e. jump to JSR TT17 below)

 AND PATG               ; If PATG = &FF (author names are shown on start-up)
 LSR A                  ; and bit 0 of QQ11 is 1 (the current view is type 1),
 BCS P%+5               ; then skip the following instruction

 JSR DELAY-5            ; Delay for 8 vertical syncs (8/50 = 0.16 seconds), to
                        ; slow the main loop down a bit

 JSR TT17               ; Scan the keyboard for the cursor keys or joystick,
                        ; returning the cursor's delta values in X and Y and
                        ; the key pressed in A

\ ******************************************************************************
\ Subroutine: Main game loop (Part 6)
\
\ Other entry points: FRCE
\
\ This is part of the main game loop. This section covers the following:
\
\   * Process more keypresses (red function keys, docked keys etc.)
\
\   * Support joining the main loop with a key already "pressed", so we can
\     jump into the main game loop to perform a specific action. In practice,
\     this is used when we enter the docking bay in BAY to display Status Mode
\     (red key f8), and when we finish buying or selling cargo in BAY2 to jump
\     to the Inventory (red key f9).
\
\ Arguments for FRCE:
\
\   A           The internal key number of the key we want to "press"
\ ******************************************************************************

.^FRCE

 JSR TT102              ; Call TT102 to process the keypress in A

 LDA QQ12               ; Fetch the docked flag from QQ12 into A

 BNE MLOOP              ; If we are docked, loop back up to MLOOP just above
                        ; to restart the main loop, but skipping all the flight
                        ; and spawning code in the top part of the main loop

 JMP TT100              ; Otherwise jump to TT100 to restart the main loop from
                        ; the start
}

\ ******************************************************************************
\ Subroutine: tha
\
\ Consider spawning a Thargoid (22% chance).
\ ******************************************************************************

.tha
{
 JSR DORND              ; Set A and X to random numbers

 CMP #200               ; If A < 200 (78% chance), skip the next instruction
 BCC P%+5

 JSR GTHG               ; Call GTHG to spawn a Thargoid

 JMP MLOOP              ; Jump back into the main loop at MLOOP, which is just
                        ; after the ship-spawning section
}

\ ******************************************************************************
\ Subroutine: TT102
\
\ Process function key presses, plus "@" (save commander), "H" (hyperspace),
\ "D" (show distance to system) and "O" (move chart cursor back to current
\ system). We can also pass cursor position deltas in X and Y to indicate that
\ the cursor keys or joystick have been used (i.e. the values that are returned
\ by routine TT17).
\
\ Arguments:
\
\   A           The internal key number of the key pressed (see p.142 of the
\               Advanced User Guide for a list of internal key values)
\
\   X           The amount to move the cross-hairs in the x-axis, if applicable
\
\   Y           The amount to move the cross-hairs in the y-axis, if applicable
\ ******************************************************************************

.TT102
{
 CMP #f8                ; If red key f8 was pressed, jump to STATUS to show the
 BNE P%+5               ; Status Mode screen, returning from the subroutine
 JMP STATUS             ; using a tail call

 CMP #f4                ; If red key f4 was pressed, jump to TT22 to show the
 BNE P%+5               ; Long-range Chart, returning from the subroutine using
 JMP TT22               ; a tail call

 CMP #f5                ; If red key f5 was pressed, jump to TT23 to show the
 BNE P%+5               ; Short-range Chart, returning from the subroutine using
 JMP TT23               ; a tail call

 CMP #f6                ; If red key f6 was pressed, call TT111 to select the
 BNE TT92               ; system nearest to galactic coordinates (QQ9, QQ10)
 JSR TT111              ; (the location of the chart cross-hairs) and jump to
 JMP TT25               ; TT25 to show the Data on System screen, returning
                        ; from the subroutine using a tail call

.TT92

 CMP #f9                ; If red key f9 was pressed, jump to TT213 to show the
 BNE P%+5               ; Inventory screen, returning from the subroutine
 JMP TT213              ; using a tail call

 CMP #f7                ; If red key f7 was pressed, jump to TT167 to show the
 BNE P%+5               ; Market Price screen, returning from the subroutine
 JMP TT167              ; using a tail call

 CMP #f0                ; If red key f0 was pressed, jump to TT110 to launch our
 BNE fvw                ; ship (if docked), returning from the subroutine using
 JMP TT110              ; a tail call

.fvw

 BIT QQ12               ; If bit 7 of QQ12 is clear (i.e. we are not docked, but
 BPL INSP               ; in space), jump to INSP to skip the following checks
                        ; for f1-f3 and "@" (save commander file) keypresses

 CMP #f3                ; If red key f3 was pressed, jump to EQSHP to show the
 BNE P%+5               ; Equip Ship screen, returning from the subroutine using
 JMP EQSHP              ; a tail call

 CMP #f1                ; If red key f1 was pressed, jump to TT219 to show the
 BNE P%+5               ; Buy Cargo screen, returning from the subroutine using
 JMP TT219              ; a tail call

 CMP #&47               ; If "@" was pressed, jump to SVE to save the commander
 BNE P%+5               ; file, returning from the subroutine using a tail call
 JMP SVE

 CMP #f2                ; If red key f2 was pressed, jump to TT208 to show the
 BNE LABEL_3            ; Sell Cargo screen, returning from the subroutine using
 JMP TT208              ; a tail call

.INSP

 CMP #f1                ; If the key pressed is < red key f1 or > red key f3,
 BCC LABEL_3            ; jump to LABEL_3 (so only do the following if the key
 CMP #f3+1              ; pressed is f1, f2 or f3)
 BCS LABEL_3

 AND #3                 ; If we get here then we are either in space, or we are
 TAX                    ; docked and none of f1-f3 were pressed, so we can now
 JMP LOOK1              ; process f1-f3 with their in-flight functions, i,e.
                        ; switching space views.
                        ;
                        ; A will contain &71, &72 or &73 (for f1, f2 or f3), so
                        ; set X to the last digit (1, 2 or 3) and jump to LOOK1
                        ; to switch to view X (back, left or right), returning
                        ; from the subroutine using a tail call.

.LABEL_3

 CMP #&54               ; If "H" was pressed, jump to hyp to do a hyperspace
 BNE P%+5               ; jump (if we are in space), returning from the
 JMP hyp                ; subroutine using a tail call

 CMP #&32               ; If "D" was pressed, jump to T95 to print the distance
 BEQ T95                ; to a system (if we are in one of the chart screens)

 STA T1                 ; Store A (the key that's been pressed) in T1

 LDA QQ11               ; If the current view is a chart (QQ11 = 64 or 128),
 AND #%11000000         ; keep going, otherwise jump down to TT107 to skip the
 BEQ TT107              ; following

 LDA QQ22+1             ; If the on-screen hyperspace counter is non-zero,
 BNE TT107              ; then we are already counting down, so jump to TT107
                        ; to skip the following

 LDA T1                 ; Restore the original value of A (the key that's been
                        ; pressed) from T1

 CMP #&36               ; If "O" was pressed, do the following three JSRs,
 BNE ee2                ; otherwise jump to ee2 to skip the following

 JSR TT103              ; Draw small cross-hairs at coordinates (QQ9, QQ10),
                        ; which will erase the cross-hairs that are currently
                        ; there

 JSR ping               ; Set the target system to the current system (which
                        ; will move the location in (QQ9, QQ10) to the current
                        ; home system

 JSR TT103              ; Draw small cross-hairs at coordinates (QQ9, QQ10),
                        ; which will draw the cross-hairs at our current home
                        ; system

.ee2

 JSR TT16               ; Call TT16 to move the cross-hairs by the amount in X
                        ; and Y, which were passed to this subroutine as
                        ; arguments

.TT107

 LDA QQ22+1             ; If the on-screen hyperspace counter is zero, return
 BEQ t95                ; from the subroutine (as t95 contains an RTS), as we
                        ; are not currently counting down to a hyperspace jump

 DEC QQ22               ; Decrement the internal hyperspace counter

 BNE t95                ; If the internal hyperspace counter is still non-zero,
                        ; then we are still counting down, so return from the
                        ; subroutine (as t95 contains an RTS)

                        ; If we get here then the internal hyperspace counter
                        ; has just reached zero and it wasn't zero before, so
                        ; we need to reduce the on-screen counter and update
                        ; the screen. We do this by first printing the next
                        ; number in the countdown sequence, and then printing
                        ; the old number, which will erase the old number
                        ; and display the new one because printing uses EOR
                        ; logic.

 LDX QQ22+1             ; Set X = the on-screen hyperspace counter - 1
 DEX                    ; (i.e. the next number in the sequence)

 JSR ee3                ; Print the 8-bit number in X at text location (0, 1)

 LDA #5                 ; Reset the the internal hyperspace counter to 5
 STA QQ22

 LDX QQ22+1             ; Set X = the on-screen hyperspace counter (i.e. the
                        ; current number in the sequence, which is already
                        ; shown on-screen)

 JSR ee3                ; Print the 8-bit number in X at text location (0, 1),
                        ; i.e. print the hyperspace countdown in the top-left
                        ; corner

 DEC QQ22+1             ; Decrement the on-screen hyperspace countdown

 BNE t95                ; If the countdown is not yet at zero, return from the
                        ; subroutine (as t95 contains an RTS)

 JMP TT18               ; Otherwise the countdown has finished, so jump to TT18
                        ; to do a hyperspace jump, returning from the subroutine
                        ; using a tail call

.t95

 RTS                    ; Return from the subroutine

.T95                    ; If we get here, "D" was pressed, so we need to show
                        ; the distance to the selected system (if we are in a
                        ; chart view)

 LDA QQ11               ; If the current view is a chart (QQ11 = 64 or 128),
 AND #%11000000         ; keep going, otherwise return from the subroutine (as
 BEQ t95                ; t95 contains an RTS)

 JSR hm                 ; Call hm to move the cross-hairs to the target system
                        ; in (QQ9, QQ10), returning with A = 0

 STA QQ17               ; Set QQ17 = 0 to switch to ALL CAPS

 JSR cpl                ; Print control code 3 (the selected system name)

 LDA #128               ; Set QQ17 = 128 to switch to Sentence Case, with the
 STA QQ17               ; next letter in capitals

 LDA #1                 ; Move the text cursor to column 1 and down one line
 STA XC                 ; (in other words, to the start of the next line)
 INC YC

 JMP TT146              ; Print the distance to the selected system and return
                        ; from the subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: BAD
\
\ Work out how bad we are from the amount of contraband in our hold. The
\ formula is:
\
\   (slaves + narcotics) * 2 + firearms
\
\ so slaves and narcotics are twice as illegal as firearms. The value in FIST
\ (our legal status) is set to a minimum of this value whenever we launch from
\ a space station, and a FIST of 50 or more is fugitive status, so leaving a
\ station carrying 25 tonnes of slaves/narcotics, or 50 tonnes of firearms
\ across multiple trips, is enough to make us a fugitive.
\ ******************************************************************************

.BAD                    ; Legal status from Cargo scan
{
 LDA QQ20+3             ; Set A to the number of tonnes of slaves in the hold

 CLC                    ; Clear the carry flag so we can do addition without
                        ; the carry flag affecting the result

 ADC QQ20+6             ; Add the number of tonnes of narcotics in the hold

 ASL A                  ; Double the result and add the number of tonnes of
 ADC QQ20+10            ; firearms in the hold

 RTS                    ; Return from subroutine
}

\ ******************************************************************************
\ Subroutine: FAROF
\
\ Compare x_hi, y_hi and z_hi with &E0, and set the C flag if all three <= &E0,
\ otherwise clear the C flag.
\
\ Returns:
\
\   C flag      Set if x_hi <= &E0 and y_hi <= &E0 and z_hi <= &E0
\               Clear otherwise (i.e. if any one of them are bigger than &E0)
\ ******************************************************************************

.FAROF
{
 LDA #&E0               ; Set A = &E0 and fall through into FAROF2 to do the
                        ; comparison
}

\ ******************************************************************************
\ Subroutine: FAROF2
\
\ Compare x_hi, y_hi and z_hi with A, and set the C flag if all three <= A,
\ otherwise clear the C flag.
\
\ Returns:
\
\   C flag      Set if x_hi <= A and y_hi <= A and z_hi <= A
\               Clear otherwise (i.e. if any one of them are bigger than A)
\ ******************************************************************************

.FAROF2
{
 CMP INWK+1             ; If A < x_hi, C will be clear so jump to MA34 to
 BCC MA34               ; return from the subroutine with C clear, otherwise
                        ; C will be set so move on to the next one

 CMP INWK+4             ; If A < y_hi, C will be clear so jump to MA34 to
 BCC MA34               ; return from the subroutine with C clear, otherwise
                        ; C will be set so move on to the next one

 CMP INWK+7             ; If A < z_hi, C will be clear, otherwise C will be set

.MA34

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: MAS4
\
\ Logical OR the value in A with the high bytes of the ship's position (x_hi,
\ y_hi and z_hi).
\
\ Returns:
\
\   A           A OR x_hi OR y_hi OR z_hi
\ ******************************************************************************

.MAS4
{
 ORA INWK+1             ; OR A with x_hi, y_hi and z_hi
 ORA INWK+4
 ORA INWK+7

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: DEATH
\
\ We have been killed, so clean up the mess.
\ ******************************************************************************

.DEATH
{
 JSR EXNO3              ; Make the sound of us dying

 JSR RES2               ; Reset a number of flight variables and workspaces

 ASL DELTA              ; Divide our speed in DELTA by 4
 ASL DELTA
 
 LDX #24                ; Set the screen to only show 24 text rows, which hides
 JSR DET1               ; the dashboard, setting A to 6 in the process

 JSR TT66               ; Clear the top part of the screen, draw a box border,
                        ; and set the current view type in QQ11 to 6 (death
                        ; screen)

 JSR BOX                ; Call BOX to redraw the same box border (BOX is part of
                        ; TT66), which removes the border as the box is drawn
                        ; using EOR logic

 JSR nWq                ; Create a cloud of stardust containing the maximum
                        ; number of dust particles (i.e. NOSTM of them)

 LDA #12                ; Move the text cursor to column 12 on row 12
 STA YC
 STA XC

 LDA #146               ; Print recursive token 13 ("{switch to all caps}GAME
 JSR ex                 ; OVER"

.D1

 JSR Ze                 ; Initialise INWK workspace, set X and T1 to a random
                        ; value, and A to a random value between 192 and 255 and
                        ; the C flag randomly

 LSR A                  ; Set A = A / 4, so A is now between 48 and 63, and
 LSR A                  ; store in INWK+0 (x_lo)
 STA INWK

 LDY #0                 ; Set the following to 0: the current view in QQ11
 STY QQ11               ; (space view), x_hi, y_hi, z_hi and the AI flag (no AI
 STY INWK+1             ; or E.C.M. and not hostile)
 STY INWK+4
 STY INWK+7
 STY INWK+32
 
 DEY                    ; Set Y = 255

 STY MCNT               ; Reset the main loop counter to 255, so all timer-based
                        ; calls will be stopped

 STY LASCT              ; Set the laser count to 255 to act as a counter in the
                        ; D2 loop below, so this setting determines how long the
                        ; death animation lasts (it's 5.1 seconds, as LASCT is
                        ; decremented every vertical sync, or 50 times a second,
                        ; and 255 / 50 = 5.1)

 EOR #%00101010         ; Flip bits 1, 3 and 5 in A (x_lo) to get another number
 STA INWK+3             ; between 48 and 63, and store in INWK+3 (y_lo)
 
 ORA #%01010000         ; Set bits 4 and 6 of A to bump it up to between 112 and 
 STA INWK+6             ; 127, and store in INWK+6 (z_lo)
 
 TXA                    ; Set A to the random number in X and keep bits 0-3 and
 AND #%10001111         ; the bit 7 to get a number between -15 and +15, and
 STA INWK+29            ; store in INWK+29 (rotx counter) to give our ship a
                        ; gentle roll with damping
 
 ROR A                  ; C is random from above call to Ze, so this sets A to a
 AND #%10000111         ; number between -7 and +7, which we store in INWK+30
 STA INWK+30            ; (rotz counter) to give our ship a very gentle pitch
                        ; with damping
 
 PHP                    ; Store the processor flags

 LDX #OIL               ; Call fq1 with X set to OIL, which adds a new cargo
 JSR fq1                ; canister to our local bubble of universe and points it
                        ; away from us with double DELTA speed (i.e. 6, as DELTA
                        ; was set to 3 by the call to RES2 above). INF is set to
                        ; point to the ship's data block in K%.

 PLP                    ; Restore the processor flags, including our random C
                        ; flag from before
 
 LDA #0                 ; Set bit 7 of A to our random C flag and store in byte
 ROR A                  ; 31 of the ship's data block, so this has a 50% chance
 LDY #31                ; of marking our new canister as being killed (so it
 STA (INF),Y            ; will explode)
 
 LDA FRIN+3             ; The call we made to RES2 before we entered the loop at
 BEQ D1                 ; D1 will have reset all the ship slots at FRIN, so this
                        ; checks to see if the fourth slot is empty, and if it
                        ; is we loop back to D1 to add another canister, until
                        ; we have added four of them

 JSR U%                 ; Clear the key logger, which also sets A = 0

 STA DELTA              ; Set our speed in DELTA to 3, so all the cargo
                        ; canisters we just added drift away from us

.D2

 JSR M%                 ; Call the M% routine to do the main flight loop once,
                        ; which will display our exploding canister scene and
                        ; move everything about

 LDA LASCT              ; Loop back to D2 to run the main flight loop until
 BNE D2                 ; LASCT reaches zero (which will take 5.1 seconds, as
                        ; explained above)

 LDX #31                ; Set the screen to show all 31 text rows, which shows
 JSR DET1               ; the dashboard, and fall through into DEATH2 to reset
                        ; and restart the game

}

\ ******************************************************************************
\ Subroutine: DEATH2
\
\ Reset most of the game and restart from the title screen.
\ ******************************************************************************

.DEATH2
{
 JSR RES2               ; Reset a number of flight variables and workspaces
                        ; and fall through into the entry code for the game
                        ; to restart from the title screen
}

\ ******************************************************************************
\ Subroutine: TT170
\
\ Other entry points: BR1
\
\ Entry point for Elite game code. Also called following death or quitting a
\ game (by pressing Escape when paused).
\
\ BRKV is set to point to BR1 by elite-loader.asm.
\ ******************************************************************************

.TT170
{
 LDX #&FF               ; Set stack pointer to &01FF, so stack is in page 1
 TXS                    ; (this is the standard location for the 6502 stack)

.^BR1                   ; BRKV is set to point here by elite-loader.asm

 LDX #3                 ; Set XC = 3 (set text cursor to column 3)
 STX XC

 JSR FX200              ; Disable the Escape key and clear memory if the Break
                        ; key is pressed (*FX 200,3)

 LDX #CYL               ; Call the TITLE subroutine to show the rotating ship
 LDA #128               ; and load prompt. The arguments sent to TITLE are:
 JSR TITLE              ; 
                        ;   X = type of ship to show, CYL is Cobra Mk III
                        ;
                        ;   A = text token to show below the rotating ship, 128
                        ;       is "  LOAD NEW COMMANDER (Y/N)?{crlf}{crlf}"
                        ;
                        ; The TITLE subroutine returns with the internal number
                        ; of the key pressed in A (see p.142 of the Advanced
                        ; User Guide for a list of internal key number)

 CMP #&44               ; Did we press "Y"? If not, jump to QU5, otherwise
 BNE QU5                ; continue on to load a new commander

\BR1                    ; These instructions are commented out in the original
\LDX #3                 ; source. This block starts with the same *FX call as
\STX XC                 ; above, then clears the screen, calls a routine to
\JSR FX200              ; flush the keyboard buffer (FLKB) that isn't present
\LDA #1                 ; in the tape version but is in the disc version, and 
\JSR TT66               ; then it displays "LOAD NEW COMMANDER (Y/N)?" and
\JSR FLKB               ; lists the current cargo, before falling straight into
\LDA #14                ; the load routine below, whether or not we have
\JSR TT214              ; pressed "Y". This may be a testing loop for testing
\BCC QU5                ; the cargo aspect of loading commander files.

 JSR GTNME              ; We want to load a new commander, so we need to get
                        ; the commander name to load

 JSR LOD                ; We then call the LOD subroutine to load the commander
                        ; file to address NA%+8, which is where we store the
                        ; commander save file

 JSR TRNME              ; Once loaded, we copy the commander name to NA%

 JSR TTX66              ; And we clear the top part of the screen and draw a
                        ; box border

.QU5                    ; By the time we get here, the correct commander name
                        ; is at NA% and the correct commander data is at NA%+8.
                        ; Specifically:
                        ;
                        ; If we loaded a commander file, then the name and data
                        ; from that file will be at NA% and NA%+8.
                        ;
                        ; If this is a brand new game, then NA% will contain
                        ; the default starting commander name ("JAMESON") and
                        ; NA%+8 will contain the default commander data.
                        ;
                        ; If this is not a new game (because they died or quit)
                        ; and we didn't want to load a commander file, then NA%
                        ; will contain the last saved commander name, and NA%+8
                        ; the last saved commander data. If the game has never
                        ; been saved, this will still be the default commander.

\JSR TTX66              ; This instruction is commented out in the original
                        ; source; it clears the screen and draws a border

 LDX #NT%               ; The size of the commander data block is NT% bytes,
                        ; and it starts at NA%+8, so we need to copy the data
                        ; from the "last saved" buffer at NA%+8 to the current
                        ; commander workspace at TP. So we set up a counter in X
                        ; for the NT% bytes that we want to copy.

.QUL1

 LDA NA%+7,X            ; Copy the X-th byte of NA%+7 to the X-th byte of TP-1,
 STA TP-1,X             ; (the -1 is because X is counting down from NT% to 1)

 DEX                    ; Decrement the loop counter

 BNE QUL1               ; Loop back for the next byte of the commander file

 STX QQ11               ; X is 0 by the end of the above loop, so this sets QQ11
                        ; to 0, which means we will be showing a view without a
                        ; boxed title at the top (i.e. we're going to use the
                        ; screen layout of a space view in the following)
 
                        ; If the commander check below fails, we keep jumping
                        ; back to here to crash the game with an infinite loop

 JSR CHECK              ; Call the CHECK subroutine to calculate the checksum
                        ; for the current commander block at NA%+8 and put it
                        ; in A

 CMP CHK                ; Test the calculated checksum against CHK

IF _REMOVE_COMMANDER_CHECK

 NOP                    ; If we have disabled the commander check, then ignore
 NOP                    ; the checksum and fall through into the next part

ELSE

 BNE P%-6               ; If commander check is enabled and the calculated
                        ; checksum does not match CHK, then loop back to repeat
                        ; the check - in other words, we enter an infinite loop
                        ; here, as the checksum routine will keep returning the
                        ; same incorrect value

ENDIF

                        ; The checksum CHK is correct, so now we check whether
                        ; CHK2 = CHK EOR A9, and if this check fails, bit 7 of
                        ; the competition code COK gets set, presumably to
                        ; indicate to Acornsoft that there may have been some
                        ; hacking going on with this competition entry

 EOR #&A9               ; X = checksum EOR &A9
 TAX

 LDA COK                ; Set A = competition code in COK

 CPX CHK2               ; If X = CHK2, then skip the next instruction
 BEQ tZ

 ORA #128               ; Set bit 7 of A

.tZ

 ORA #2                 ; Set bit 1 of A

 STA COK                ; Store the competition code A in COK

 JSR msblob             ; Update the dashboard's missile indicators

 LDA #147               ; Call the TITLE subroutine to show the rotating ship
 LDX #MAM               ; and fire/space prompt. The arguments sent to TITLE
 JSR TITLE              ; are:
                        ; 
                        ;   X = type of ship to show, MAM is Mamba
                        ;   A = text token to show below the rotating ship, 147
                        ;       is "PRESS FIRE OR SPACE,COMMANDER.{crlf}{crlf}"
 
 JSR ping               ; Set the target system coordinates (QQ9, QQ10) to the
                        ; current system coordinates (QQ0, QQ1) we just loaded

 JSR hyp1               ; Arrive in the system closest to (QQ9, QQ10) and then
                        ; and then fall through into the docking bay routine
                        ; below
}

\ ******************************************************************************
\ Subroutine: BAY
\
\ Go to the docking bay (i.e. show the Status Mode screen).
\
\ We end up here after the startup process (load commander etc.), as well as
\ after a successful save, an escape pod launch, a successful docking, the end
\ of a cargo sell, and various errors (such as not having enough cash, entering
\ too many items when buying, trying to fit an item to your ship when you
\ already have it, running out of cargo space, and so on).
\ ******************************************************************************

.BAY
{
 LDA #&FF               ; Set QQ12 = &FF (the docked flag) to indicate that we
 STA QQ12               ; are docked

 LDA #f8                ; Jump into the main loop at FRCE, setting the key
 JMP FRCE               ; "pressed" to red key f8 (so we show the Status Mode
                        ; screen)
}

\ ******************************************************************************
\ Subroutine: TITLE
\
\ Display the title screen, with a rotating ship and a recursive text token at
\ the bottom of the screen.
\
\ Arguments:
\
\   A           The number of the recursive token to show below the rotating
\               ship (see variable QQ18 for details of recursive tokens)
\
\   X           The type of the ship to show (see variable XX21 for a list of
\               ship types)
\ ******************************************************************************

.TITLE
{
 PHA                    ; Store the token number on the stack for later

 STX TYPE               ; Store the ship type in location TYPE

 JSR RESET              ; Reset our ship so we can use it for the rotating
                        ; title ship

 LDA #1                 ; Clear the top part of the screen, draw a box border,
 JSR TT66               ; and set the current view type in QQ11 to 1

 DEC QQ11               ; Decrement QQ11 to 0, so from here on we are using a
                        ; space view

 LDA #96                ; Set rotmat0z hi = 96 (96 is the value of unity in the
 STA INWK+14            ; rotation vector)

\LSR A                  ; This instruction is commented out in the original
                        ; source. It would halve the value of zhi to 48, so the
                        ; ship would start off closer to the viewer.

 STA INWK+7             ; Set z_hi, the high byte of the ship's z-coordinate,
                        ; to 96, which is the distance at which the rotating
                        ; ship starts out before coming towards us

 LDX #127
 STX INWK+29            ; Set rotx counter = 127, so don't dampen the roll
 STX INWK+30            ; Set rotz counter = 127, so don't dampen the pitch

 INX                    ; Set QQ17 = 128, which sets Sentence Case, with the
 STX QQ17               ; next letter printing in upper case

 LDA TYPE               ; Set up a new ship, using the ship type in TYPE
 JSR NWSHP

 LDY #6                 ; Set the text cursor to column 6
 STY XC

 JSR DELAY              ; Delay for 6 vertical syncs (6/50 = 0.12 seconds)
 
 LDA #30                ; Print recursive token 144 ("---- E L I T E ----")
 JSR plf                ; followed by a newline

 LDY #6                 ; Set the text cursor to column 6 again
 STY XC
 
 INC YC                 ; Move the text cursor down a row

 LDA PATG               ; If PATG = 0, skip the following two lines, which
 BEQ awe                ; print the author credits (PATG can be toggled by
                        ; pausing the game and pressing "X")

 LDA #254               ; Print recursive token 94, "BY D.BRABEN & I.BELL"
 JSR TT27

.awe

 JSR CLYNS              ; Clear the bottom three text rows of the upper screen,
                        ; and move the text cursor to column 1 on row 21, i.e.
                        ; the start of the top row of the three bottom rows.
                        ; It also returns with Y = 0

 STY DELTA              ; Set DELTA = 0 (i.e. ship speed = 0)

 STY JSTK               ; Set KSTK = 0 (i.e. keyboard, not joystick)

 PLA                    ; Restore the recursive token number we stored on the
 JSR ex                 ; stack at the start of this subroutine, and print that
                        ; token

 LDA #148               ; Move the text cursor to column 7 and print recursive
 LDX #7                 ; token 148 ("(C) ACORNSOFT 1984")
 STX XC
 JSR ex

.TLL2

 LDA INWK+7             ; If z_hi (the ship's distance) is 1, jump to TL1 to
 CMP #1                 ; skip the following decrement
 BEQ TL1

 DEC INWK+7             ; Decrement the ship's distance, to bring the ship
                        ; a bit closer to us

.TL1

 JSR MVEIT              ; Move the ship in space according to the rotation
                        ; matrix and the new value in z_hi

 LDA #128               ; Set z_lo = 128 (so the closest the ship gets to us is
 STA INWK+6             ; z_hi = 1, z_lo = 128, or 256 + 128 = 384

 ASL A                  ; Set A = 0

 STA INWK               ; Set x_lo = 0, so ship remains in the screen centre

 STA INWK+3             ; Set y_lo = 0, so ship remains in the screen centre

 JSR LL9                ; Call LL9 to display the ship

 DEC MCNT               ; Decrement the move counter

 LDA SHEILA+&40         ; Read 6522 System VIA input register IRB (SHEILA &40)

 AND #%00010000         ; Bit 4 of IRB (PB4) is clear if joystick 1's fire
                        ; button is pressed, otherwise it is set, so AND'ing
                        ; the value of IRB with %10000 extracts this bit

\TAX                    ; This instruction is commented out in the original
                        ; source

 BEQ TL2                ; If the joystick fire button is pressed, jump to BL2

 JSR RDKEY              ; Scan the keyboard for a keypress

 BEQ TLL2               ; If no key was pressed, loop back up to move/rotate
                        ; the ship and check again for a key press

 RTS                    ; Return from the subroutine

.TL2

 DEC JSTK               ; Joystick fire button was pressed, so set JSTK to &FF
                        ; (it was set to 0 above), to disable keyboard and
                        ; enable joysticks

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: CHECK
\
\ Calculate the checksum for the last saved commander data block, to protect
\ against corruption and tampering. The checksum is returned in A.
\
\ This algorithm is also implemented in elite-checksum.py.
\ ******************************************************************************

.CHECK
{
 LDX #NT%-2             ; Set X to the size of the commander data block, less
                        ; 2 (as there are two checksum bytes)

 CLC                    ; Clear the carry flag so we can do addition without
                        ; the carry flag affecting the result

 TXA                    ; Seed the checksum calculation by setting A to the
                        ; size of the commander data block, less 2

                        ; We now loop through the commander data block,
                        ; starting at the end and looping down to the start
                        ; (so at the start of this loop, the X-th byte is the
                        ; last byte of the commander data block, i.e. the save
                        ; count)

.QUL2

 ADC NA%+7,X            ; Add the X-1-th byte of the data block to A, plus
                        ; carry

 EOR NA%+8,X            ; EOR A with the X-th byte of the data block

 DEX                    ; Decrement the loop counter

 BNE QUL2               ; Loop back for the next byte in the data block

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: TRNME
\
\ Copy the last saved commander's name from INWK to NA%.
\ ******************************************************************************

.TRNME
{
 LDX #7                 ; The commander's name can contain a maximum of 7
                        ; characters, and is terminated by a carriage return,
                        ; so set up a counter in X to copy 8 characters

.GTL1

 LDA INWK,X             ; Copy the X-th byte of INWK to the X-th byte of NA%
 STA NA%,X

 DEX                    ; Decrement the loop counter

 BPL GTL1               ; Loop back until we have copied all 8 bytes

                        ; Fall through into TR1 to copy the name back from NA%
                        ; to INWK, though this has no effect apart from saving
                        ; one byte, as we don't need an RTS here
}

\ ******************************************************************************
\ Subroutine: TR1
\
\ Copy the last saved commander's name from NA% to INWK.
\ ******************************************************************************

.TR1
{
 LDX #7                 ; The commander's name can contain a maximum of 7
                        ; characters, and is terminated by a carriage return,
                        ; so set up a counter in X to copy 8 characters

.GTL2

 LDA NA%,X              ; Copy the X-th byte of NA% to the X-th byte of INWK
 STA INWK,X

 DEX                    ; Decrement the loop counter

 BPL GTL2               ; Loop back until we have copied all 8 bytes

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: GTNME
\
\ Get the commander's name for loading or saving a commander file. The name is
\ stored at INWK, terminated by a return character (13).
\
\ If Escape is pressed or a blank name is entered, then INWK is set to the name
\ from the last saved commander block.
\ ******************************************************************************

.GTNME
{
 LDA #1                 ; Clear the top part of the screen, draw a box border,
 JSR TT66               ; and set the current view type in QQ11 to 1

 LDA #123               ; Print recursive token 123 ("{crlf}COMMANDER'S NAME? ")
 JSR TT27

 JSR DEL8               ; Wait for 8/50 of a second (0.16 seconds)

 LDA #%10000001         ; Clear 6522 System VIA interrupt enable register IER
 STA SHEILA+&4E         ; (SHEILA &4E) bit 1 (i.e. enable the CA2 interrupt
                        ; which comes from the keyboard)

 LDA #15                ; Perform a *FX 15,0 command (flush all buffers)
 TAX
 JSR OSBYTE

 LDX #LO(RLINE)         ; Call OSWORD with A = 0 and (Y X) pointing to the
 LDY #HI(RLINE)         ; configuration block below, which reads a line from
 LDA #0                 ; the current input stream (i.e. the keyboard)
 JSR OSWORD

\LDA #%00000001         ; These instructions are commented out in the original
\STA SHEILA+&4E         ; source, but they would set 6522 System VIA interrupt
                        ; enable register IER (SHEILA &4E) bit 1 (i.e. disable
                        ; the CA2 interrupt, which comes from the keyboard)

 BCS TR1                ; The C flag will be set if we pressed Escape when
                        ; entering the name, in which case jump to TR1 to copy
                        ; the last saved commander's name from NA% to INWK
                        ; and return from the subroutine there

 TYA                    ; The OSWORD call returns the length of the commander's
 BEQ TR1                ; name in Y, so transfer this to A, and if it is zero
                        ; (a blank name was entered), jump to TR1 to copy
                        ; the last saved commander's name from NA% to INWK
                        ; and return from the subroutine there

 JMP TT67               ; We have a name, so jump to TT67 to print a newline
                        ; and return from the subroutine using a tail call

.RLINE                  ; This is the OSWORD configuration block used above

 EQUW INWK              ; The address to store the input, so the commander's
                        ; name will be stored in INWK as it is typed

 EQUB 7                 ; Maximum line length = 7, as that's the maximum size
                        ; for a commander's name

 EQUB '!'               ; Allow ASCII characters from "!" through to "z" in
 EQUB 'z'               ; the name
}

\ ******************************************************************************
\ Subroutine: ZERO
\
\ Zero-fill pages &9, &A, &B, &C and &D.
\ ******************************************************************************

.ZERO
{
 LDX #&D                ; Point X to page &D

.ZEL

 JSR ZES1               ; Call ZES1 below to zero-fill the page in X

 DEX                    ; Decrement X to point to the next page

 CPX #9                 ; If X is > 9 (i.e. is &A, &B or &C), then loop back
 BNE ZEL                ; up to clear the next page

                        ; Then fall through into ZES1 with X set to 9, so we
                        ; clear page &9 too
}

\ ******************************************************************************
\ Subroutine: ZES1
\
\ Zero-fill the page whose number is in X.
\
\ Arguments:
\
\   X           The page we want to zero-fill
\ ******************************************************************************

.ZES1
{
 LDY #0                 ; If we set Y = SC = 0 and fall through into ZES2
 STY SC                 ; below, then we will zero-fill 255 bytes starting from
                        ; SC - in other words, we will zero-fill the whole of
                        ; page X
}

\ ******************************************************************************
\ Subroutine: ZES2
\
\ Zero-fill the page whose number is in X, from position SC to SC + Y.
\
\ If Y is 0, this will zero-fill 255 bytes starting from SC
\
\ If Y is negative, this will zero-fill from SC + Y to SC - 1, i.e. the Y bytes
\ before SC
\
\ Arguments:
\
\   X           The page where we want to zero-fill
\
\   Y           A negative value denoting how many bytes before SC we want
\               to start zeroing
\
\   SC          The position in the page where we should zero fill up to
\ ******************************************************************************

.ZES2
{
 LDA #0                 ; Load X with the byte we want to fill the memory block
                        ; with - i.e. zero

 STX SC+1               ; We want to zero-fill page X, so store this in the
                        ; high byte of SC, so the 16-bit address in SC and
                        ; SC+1 is now pointing to the SC-th byte of page X

.ZEL1

 STA (SC),Y             ; Zero the Y-th byte of the block pointed to by SC,
                        ; so that's effectively the Y-th byte before SC

 INY                    ; Increment the loop counter

 BNE ZEL1               ; Loop back to zero the next byte
 
 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: SVE
\
\ Save the commander file.
\ ******************************************************************************

.SVE
{
 JSR GTNME              ; Clear the screen and ask for the commander filename
                        ; to save, storing the name at INWK

 JSR TRNME              ; Transfer the commander filename from INWK to NA%

 JSR ZERO               ; Zero-fill pages &9, &A, &B, &C and &D
 
 LSR SVC                ; Halve the save count value in SVC

 LDX #NT%               ; We now want to copy the current commander data block
                        ; from location TP to the last saved commander block at
                        ; NA%+8, so set a counter in X to copy the NT% bytes in
                        ; the commander data block.
                        ;
                        ; We also want to copy the data block to another
                        ; location &0B00, which is normally used for the ship
                        ; lines heap

.SVL1

 LDA TP,X               ; Copy the X-th byte of TP to the X-th byte of &B00
 STA &B00,X             ; and NA%+8
 STA NA%+8,X

 DEX                    ; Decrement the loop counter

 BPL SVL1               ; Loop back until we have copied all NT% bytes

 JSR CHECK              ; Call CHECK to calculate the checksum for the last
                        ; saved commander and return it in A

 STA CHK                ; Store the checksum in CHK, which is at the end of the
                        ; last saved commander block

 PHA                    ; Store the checksum on the stack

 ORA #%10000000         ; Set K = checksum with bit 7 set
 STA K

 EOR COK                ; Set K+2 = K EOR'd with COK
 STA K+2

 EOR CASH+2             ; Set K+1 = K+2 EOR'd with the third cash byte
 STA K+1

 EOR #%01011010         ; Set K+3 = K+1 EOR 01011010 EOR high byte of kill tally
 EOR TALLY+1
 STA K+3

 JSR BPRNT              ; Print the competition number stored in K to K+3. The
                        ; values of the C flag and U will affect how this is
                        ; printed, which is odd as they appear to be random (C
                        ; is last set in CHECK and could go either way, and it's
                        ; hard to know when U was last set as it's a temporary
                        ; variable in zero page, so isn't reset by ZERO). I
                        ; wonder if the competition number can ever get printed
                        ; out incorrectly, with a decimal point and the wrong
                        ; number of digits?
 
 JSR TT67               ; Call TT67 twice to print two newlines
 JSR TT67

 PLA                    ; Restore the checksum from the stack

 STA &B00+NT%           ; Store the checksum in the last byte of the save file
                        ; at &0B00 (the equivalent of CHK in the last saved
                        ; block)

 EOR #&A9               ; Store the checksum EOR &A9 in CHK2, the penultimate
 STA CHK2               ; byte of the last saved commander block
 
 STA &AFF+NT%           ; Store the checksum EOR &A9 in the penultimate byte of
                        ; the save file at &0B00 (the equivalent of CHK2 in the
                        ; last saved block)
 
 LDY #&B                ; Set up an OSFILE block at &0C00, containing:
 STY &C0B               ; 
 INY                    ; Start address for save = &00000B00 in &0C0A to &0C0D
 STY &C0F               ; 
                        ; End address for save = &00000C00 in &0C0E to &0C11
                        ;
                        ; Y is left containing &C which we use below

 LDA #%10000001         ; Clear 6522 System VIA interrupt enable register IER
 STA SHEILA+&4E         ; (SHEILA &4E) bit 1 (i.e. enable the CA2 interrupt,
                        ; which comes from the keyboard)

 INC SVN                ; Increment SVN to indicate we are about to start saving
                        ; (SVN is actually a screen address at &7FFD)

 LDA #0                 ; Call QUS1 with A = 0, Y = &C to save the commander
 JSR QUS1               ; file with the filename we copied to INWK at the start
                        ; of this routine
 
 LDX #0                 ; Set X = 0 for storing in SVN below

 \STX SHEILA+&4E        ; This instruction is commented out in the original
                        ; source. It would affect the 6522 System VIA interrupt
                        ; enable register IER (SHEILA &4E) if any of bits 0-6
                        ; of X were set, but they aren't, so this instruction
                        ; would have no effect anyway.

 \DEX                   ; This instruction is commented out in the original
                        ; source. It would end up setting SVN to &FF, which
                        ; affects the logic in the IRQ1 handler.

 STX SVN                ; Set SVN to 0 to indicate we are done saving

 JMP BAY                ; Go to the docking bay (i.e. show Status Mode)
}

\ ******************************************************************************
\ Subroutine: QUS1
\
\ Load or save the commander file. The filename should be stored at INWK,
\ terminated with a carriage return (13), and the routine should be called with
\ Y set to &C.
\
\ Arguments:
\
\   A           File operation to be performed. Can be one of the following:
\
\                 * 0 (save file)
\
\                 * &FF (load file)
\
\   Y           Points to the page number containing the OSFILE block, which
\               must be &C because that's where the pointer to the filename in
\               INWK is stored below (by the STX &C00 instruction)
\ ******************************************************************************

.QUS1
{
 LDX #INWK              ; Store a pointer to INWK at the start of the block at
 STX &0C00              ; &0C00, in byte 0 because INWK is in zero page

 LDX #0                 ; Set X to 0 so (Y X) = &0C00

 JMP OSFILE             ; Jump to OSFILE to do the file operation specified in
                        ; &0C00, returning from the subroutine using a tail
                        ; call
}

\ ******************************************************************************
\ Subroutine: LOD
\
\ Load a commander file. The filename should be stored at INWK, terminated with
\ a carriage return (13).
\ ******************************************************************************

.LOD
{
 LDX #2                 ; Enable the Escape key and clear memory if the Break
 JSR FX200              ; key is pressed (*FX 200,2)

 JSR ZERO               ; Zero-fill pages &9, &A, &B, &C and &D

 LDY #&B                ; Set up an OSFILE block at &0C00, containing:
 STY &0C03              ; 
 INC &0C0B              ; Load address = &00000B00 in &0C02 to &0C05
 INY                    ; 
                        ; Length of file = &00000100 in &0C0A to &0C0D
                        ;
                        ; Y is left containing &C which we use next

 LDA #&FF               ; Call QUS1 with A = &FF, Y = &C to load the commander
 JSR QUS1               ; file at address &0B00
 
 LDA &B00               ; If the first byte of the loaded file has bit 7 set,
 BMI SPS1+1             ; jump to SPS+1, which is the second byte of an LDA #0
                        ; instruction, i.e. a BRK instruction, which will force
                        ; an interrupt to call the address in BRKV, which is set
                        ; to BR1... so this instruction restarts the game from
                        ; the title screen. Valid commander files for the tape
                        ; version of Elite only have 0 for the first byte, while
                        ; the disc version can have 0, 1, 2, &A or &E, so having
                        ; bit 7 set is invalid anyway.

 LDX #NT%               ; We have successfully loaded the commander file at
                        ; &0B00, so now we want to copy it to the last saved
                        ; commander data block at NA%+8, so we set up a counter
                        ; in X to copy NT% bytes

.LOL1

 LDA &B00,X             ; Copy the X-th byte of &0B00 to the X-th byte of NA%+8
 STA NA%+8,X

 DEX                    ; Decrement the loop counter

 BPL LOL1               ; Loop back until we have copied all NT% bytes

 LDX #3                 ; Fall through into FX200 to disable the Escape key and
                        ; clear memory if the Break key is pressed (*FX 200,3)
                        ; and return from the subroutine there
}

\ ******************************************************************************
\ Subroutine: FX200
\
\ Performs a *FX 200,X command, which controls the behaviour of the Escape and
\ Break keys.
\ ******************************************************************************

.FX200
{
 LDY #0                 ; Call OSBYTE &C8 (200) with Y = 0, so new value is
 LDA #200               ; set to X
 JMP OSBYTE

 RTS                    ; Return from subroutine
}

\ ******************************************************************************
\ Subroutine: SPS1
\
\ XX15 vector to planet
\ ******************************************************************************

.SPS1                   ; XX15 vector to planet
{
 LDX #0                 ; xcoord planet
 JSR SPS3               ; planet for space compass into K3(0to8)
 LDX #3                 ; ycoord
 JSR SPS3
 LDX #6                 ; zcoord
 JSR SPS3
}

\ ******************************************************************************
\ Subroutine: TAS2
\
\ XX15=r~96 \ their comment \ build XX15 from K3
\ ******************************************************************************

.TAS2                   ; XX15=r~96 \ their comment \ build XX15 from K3
{
 LDA K3
 ORA K3+3
 ORA K3+6
 ORA #1                 ; not zero
 STA K3+9               ; lo or'd max
 LDA K3+1               ; x hi
 ORA K3+4               ; y hi
 ORA K3+7               ; z hi

.TAL2                   ; roll Acc = xyz  hi

 ASL K3+9               ; all lo max
 ROL A                  ; all hi max
 BCS TA2                ; exit when xyz hi*=2 overflows
 ASL K3                 ; xlo
 ROL K3+1               ; xhi*=2
 ASL K3+3               ; ylo
 ROL K3+4               ; yhi*=2
 ASL K3+6               ; zlo
 ROL K3+7               ; zhi*=2
 BCC TAL2               ; loop roll Acc xyz hi

.TA2                    ; exited, Build XX15(0to2) from (raw) K3(1to8)

 LDA K3+1               ; xhi
 LSR A                  ; clear bit7 for sign
 ORA K3+2               ; xsg
 STA XX15               ; xunit, bit7 is xsign
 LDA K3+4               ; yhi
 LSR A
 ORA K3+5               ; ysg
 STA XX15+1             ; yunit, bit7 is ysign
 LDA K3+7               ; zhi
 LSR A
 ORA K3+8               ; zsg
 STA XX15+2             ; zunit, bit7 is zsign
}

\ ******************************************************************************
\ Subroutine: NORM
\
\ Normalize 3-vector length of XX15
\ ******************************************************************************

.NORM                   ; Normalize 3-vector length of XX15
{
 LDA XX15
 JSR SQUA               ; P.A =A7*A7  x^2
 STA R                  ; hi sum
 LDA P                  ; lo
 STA Q                  ; lo sum
 LDA XX15+1
 JSR SQUA               ; P.A =A7*A7 y^2
 STA T                  ; temp hi
 LDA P                  ; lo
 ADC Q
 STA Q
 LDA T                  ; hi
 ADC R
 STA R
 LDA XX15+2
 JSR SQUA               ; P.A =A7*A7 z^2
 STA T
 LDA P                  ; lo
 ADC Q
 STA Q                  ; xlo2 + ylo2 + zlo2
 LDA T                  ; temp hi
 ADC R
 STA R

 JSR LL5                ; Q = SQR(Qlo.Rhi), Q <~127

 LDA XX15
 JSR TIS2               ; *96/Q
 STA XX15               ; xunit

 LDA XX15+1
 JSR TIS2
 STA XX15+1             ; yunit

 LDA XX15+2
 JSR TIS2
 STA XX15+2             ; zunit
}

.NO1
{
 RTS                    ; end of norm
}

\ ******************************************************************************
\ Subroutine: RDKEY
\
\ Scan the keyboard, starting with internal key number 16 (Q) and working
\ through the set of internal key numbers (see p.142 of the Advanced User Guide
\ for a list of internal key values).
\
\ This routine is effectively the same as OSBYTE &7A, though the OSBYTE call
\ preserves A, unlike this routine.
\
\ Returns:
\
\   X           If a key is being pressed, X contains the internal key number,
\               otherwise it contains 0
\
\   A           Contains the same as X
\ ******************************************************************************

.RDKEY
{
 LDX #16                ; Start the scan with internal key number 16 (Q)

.Rd1

 JSR DKS4               ; Scan the keyboard to see if the key in X is currently
                        ; being pressed

 BMI Rd2                ; Jump to Rd2 if this key is being pressed (in which
                        ; case DKS4 will have returned a negative value,
                        ; specifically 128 + X)

 INX                    ; Increment the key number

 BPL Rd1                ; Loop back to test the next key, ending the loop when
                        ; X is negative (i.e. 128)

 TXA                    ; If we get here, nothing is being pressed, so copy X
                        ; into A so that X = A = 128

.Rd2

 EOR #128               ; EOR A with 128, to switch off bit 7, so A now
                        ; contains 0 if no key has been pressed, or the
                        ; internal key number if it has been pressed

 TAX                    ; Copy A into X

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: ECMOF
\
\ Switch the E.C.M. off, turn off the dashboard bulb and make the sound of the
\ E.C.M. switching off).
\ ******************************************************************************

.ECMOF
{
 LDA #0                 ; Set ECMA and ECMB to 0 to indicate that no E.C.M. is
 STA ECMA               ; currently running
 STA ECMP

 JSR ECBLB              ; Update the E.C.M. indicator bulb on the dashboard

 LDA #72                ; Call the NOISE routine with A = 72 to make the sound
 BNE NOISE              ; of the E.C.M. being turned off and return from the
                        ; subroutine using a tail call (this BNE is effectively
                        ; a JMP as A will never be zero)
}

\ ******************************************************************************
\ Subroutine: EXNO3
\
\ Make the sound of death in the cold, hard vacuum of space. Apparently, in
\ Elite space, everyone can hear you scream.
\
\ This routine also makes the noise of a destroyed cargo canister if you don't
\ get scooping right, and the noise of us colliding with another ship.
\ ******************************************************************************

.EXNO3
{
 LDA #16                ; Call the NOISE routine with A = 16 to make the first
 JSR NOISE              ; death sound

 LDA #24                ; Call the NOISE routine with A = 24 to make the second
 BNE NOISE              ; death sound and return from the subroutine using a
                        ; tail call (this BNE is effectively a JMP as A will
                        ; never be zero)
}

\ ******************************************************************************
\ Subroutine: SFRMIS
\
\ Enemy fires a missile, so add the missile to our universe if there is room,
\ and if there is, make the appropriate warnings and noises. 
\ ******************************************************************************

.SFRMIS
{
 LDX #MSL               ; Set X to the ship type of a missile, and call SFS1-2
 JSR SFS1-2             ; to add the missile to our universe with an AI of &FE

 BCC NO1                ; The carry flag will be set if the call to SFS1-2 was
                        ; a success, so if it's clear, jump to NO1 to return
                        ; from the subroutine (as NO1 contains an RTS)

 LDA #120               ; Print recursive token 120 ("INCOMING MISSILE") as an
 JSR MESS               ; in-flight message

 LDA #48                ; Call the NOISE routine with A = 48 to make the sound
 BNE NOISE              ; of the missile being launched and return from the
                        ; subroutine using a tail call (this BNE is effectively
                        ; a JMP as A will never be zero)
}

\ ******************************************************************************
\ Subroutine: EXNO2
\
\ We have killed a ship, so increase the kill tally, displaying an iconic
\ message of encouragement if the kill total is a multiple of 256, and then 
\ make a nearby explosion noise.
\ ******************************************************************************

.EXNO2
{
 INC TALLY              ; Increment the low byte of the kill count in TALLY

 BNE EXNO-2             ; If there is no carry, jump to the LDX #7 below (at
                        ; EXNO-2)

 INC TALLY+1            ; Increment the high byte of the kill count in TALLY

 LDA #101               ; The kill total is a multiple of 256, so it's time
 JSR MESS               ; for a pat on the back, so print recursive token 101
                        ; ("RIGHT ON COMMANDER!") as an in-flight message

 LDX #7                 ; Set X = 7 and fall through into EXNO to make the
                        ; sound of a ship exploding
}

\ ******************************************************************************
\ Subroutine: EXNO
\
\ Make the two-part explosion noise of us making a laser strike, or of another
\ ship exploding.
\
\ The volume of the first explosion is affected by the distance of the ship
\ being hit, with more distant ships being quieter. The value in X also affects
\ the volume of the first explosion, with a higher X giving a quieter sound
\ (so X can be used to differentiate a laser strike from an explosion).
\
\ Arguments:
\
\   X           The larger the value of X, the fainter the explosion. Allowed
\               values are:
\
\                 * 7  = explosion is louder (i.e. the ship has exploded)
\
\                 * 15 = explosion is quieter (i.e. this is just a laser
\                        strike)
\ ******************************************************************************

.EXNO
{
 STX T                  ; Store the distance in T

 LDA #24                ; Set A = 24 to denote the sound of us making a hit or
 JSR NOS1               ; kill (part 1), and call NOS1 to set up the sound
                        ; block in XX16

 LDA INWK+7             ; Fetch z_hi, the distance of the ship being hit in
 LSR A                  ; terms of the z-axis (in and out of the screen), and
 LSR A                  ; divide by 4. If z_hi has either bit 6 or 7 set then
                        ; that ship is too far away to be shown on the scanner
                        ; (as per the SCAN routine), so we know the maximum
                        ; z_hi at this point is %00111111, and shifting z_hi
                        ; to the right twice gives us a maximum value of
                        ; %00001111.

 AND T                  ; This reduces A to a maximum of X; X can be either
                        ; 7 = %0111 or 15 = %1111, so AND'ing with 15 will
                        ; not affect A, while AND'ing with 7 will clear bit
                        ; 3, reducing the maximum value in A to 7

 ORA #%11110001         ; The SOUND command's amplitude ranges from 0 (for no
                        ; sound) to -15 (full volume), so we can set bits 0 and
                        ; 4-7 in A, and keep bits 1-3 from the above to get
                        ; a value between -15 (%11110001) and -1 (%11111111),
                        ; with lower values of z_hi and argument X leading
                        ; to a more negative number (so the closer the ship or
                        ; the smaller the value of X, the louder the sound)

 STA XX16+2             ; The amplitude byte of the sound block in XX16 is in
                        ; byte 3 (where it's the low byte of the amplitude), so
                        ; this sets the amplitude to the value in A

 JSR NO3                ; Make the sound from our updated sound block in XX16

 LDA #16                ; Set A = 16 to denote we have made a hit or kill
                        ; (part 2), and fall through into NOISE to make the
                        ; sound

 EQUB &2C               ; Skip the next instruction by turning it into
                        ; &2C &A9 &20, or BIT &20A9, which does nothing bar
                        ; affecting the flags
}

\ ******************************************************************************
\ Subroutine: BEEP
\
\ Make a short, high beep.
\ ******************************************************************************

.BEEP
{
 LDA #32                ; Set A = 32 to denote a short, high beep, and fall
                        ; through into NOISE to make the sound
}

\ ******************************************************************************
\ Subroutine: NOISE
\
\ Make the sound whose number is in A.
\
\ Arguments:
\
\   A           The number of the sound to be made. See the documentation for
\               variable SFX for a list of sound numbers.
\ ******************************************************************************

.NOISE
{
 JSR NOS1               ; Set up the sound block in XX16 for the sound in A and
                        ; fall through into NO3 to make the sound
}

\ ******************************************************************************
\ Subroutine: NO3
\
\ Make a sound from a prepared sound block in XX16 (if sound is enabled). See
\ routine NOS1 for details of preparing the XX16 sound block.
\ ******************************************************************************

.NO3
{
 LDX DNOIZ              ; If DNOIZ is non-zero, then sound is disabled, so 
 BNE NO1                ; return from the subroutine

 LDX #LO(XX16)          ; Otherwise call OSWORD 7, with (Y X) pointing to the
 LDY #HI(XX16)          ; sound block in XX16. This makes the sound as
 LDA #7                 ; described in the documentation for variable SFX,
 JMP OSWORD             ; and returns from the subroutine using a tail call.
}

\ ******************************************************************************
\ Subroutine: NOS1
\
\ Copy four sound bytes from SFX into XX16, interspersing them with null bytes,
\ with Y indicating the sound number to copy (from the values in the sound
\ table at SFX). So, for example, if we call this routine with A = 40 (long,
\ low beep), the following bytes will be set in XX16 to XX16+7:
\
\   &13 &00 &F4 &00 &0C &00 &08 &00
\
\ This block will be passed to OSWORD 7 to make the sound, which expects the
\ four sound attributes as 16-bit big-endian values - in other words, with the
\ low byte first. So the above block would pass the values &0013, &00F4, &000C
\ and &0008 to the SOUND command when used with OSWORD 7, or:
\
\   SOUND &13, &F4, &0C, &08
\
\ as the high bytes are always zero.
\
\ Arguments:
\
\   A           The sound number to copy from SFX to XX16, which is always a
\               multiple of 8
\ ******************************************************************************

.NOS1
{
 LSR A                  ; Divide A by 2, and also clear the carry flag, as bit
                        ; of A is always zero

 ADC #3                 ; Set Y = A + 3, so Y now points to the last byte of
 TAY                    ; four within the block of four-byte values

 LDX #7                 ; We want to copy four bytes, spread out into an 8-byte
                        ; block, so set a counter in Y to cover 8 bytes

.NOL1

 LDA #0                 ; Set the X-th byte of XX16 to 0
 STA XX16,X

 DEX                    ; Decrement the destination byte pointer

 LDA SFX,Y              ; Set the X-th byte of XX16 to the value from SFX+Y
 STA XX16,X

 DEY                    ; Decrement the source byte pointer again

 DEX                    ; Decrement the destination byte pointer again

 BPL NOL1               ; Loop back for the next source byte

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Variable: KYTB
\
\ Keyboard table for in-flight controls. This table contains the internal key
\ codes for the flight keys (see p.142 of the Advanced User Guide for a list of
\ internal key values).
\
\ The pitch, roll, speed and laser keys (i.e. the seven primary flight
\ control keys) have bit 7 set, so they have 128 added to their internal
\ values. This doesn't appear to be used anywhere.
\
\ Note that KYTB actually points to the byte before the start of the table, so
\ the offset of the first key value is 1 (i.e. KYTB+1), not 0.
\ ******************************************************************************

KYTB = P% - 1           ; Point KYTB to the byte before the start of the table
{
                        ; These are the primary flight controls (pitch, roll,
                        ; speed and lasers):

 EQUB &68 + 128         ; ?         KYTB+1      Slow down
 EQUB &62 + 128         ; Space     KYTB+2      Speed up
 EQUB &66 + 128         ; <         KYTB+3      Roll left
 EQUB &67 + 128         ; >         KYTB+4      Roll right
 EQUB &42 + 128         ; X         KYTB+5      Pitch up
 EQUB &51 + 128         ; S         KYTB+6      Pitch down
 EQUB &41 + 128         ; A         KYTB+7      Fire lasers

                        ; These are the secondary flight controls:

 EQUB &60               ; Tab       KYTB+8      Energy bomb
 EQUB &70               ; Escape    KYTB+9      Launch escape pod
 EQUB &23               ; T         KYTB+10     Arm missile
 EQUB &35               ; U         KYTB+11     Unarm missile
 EQUB &65               ; M         KYTB+12     Fire missile
 EQUB &22               ; E         KYTB+13     E.C.M.
 EQUB &45               ; J         KYTB+14     In-system jump
 EQUB &52               ; C         KYTB+15     Docking computer
}

\ ******************************************************************************
\ Subroutine: DKS1
\
\ Scan the keyboard for the flight key given in register Y, where Y is the
\ offset into the KYTB table above (so we can scan for Space by setting Y to
\ 2, for example). If the key is pressed, set the corresponding byte in the
\ key logger at KL to &FF.
\
\ Arguments:
\
\   Y           The offset into the KYTB table above of the key that we want to
\               scan on the keyboard
\ ******************************************************************************

.DKS1
{
 LDX KYTB,Y             ; Get the internal key number from the Y-th byte of the
                        ; KYTB table above

 JSR DKS4               ; Call DKS4, which will set A and X to a negative value
                        ; if the key is being pressed

 BPL DKS2-1             ; The key is not being pressed, so return from the
                        ; subroutine (as DKS2-1 contains an RTS)

 LDX #&FF               ; Store &FF in the Y-th byte of the key logger at KL
 STX KL,Y

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: CTRL
\
\ Scan the keyboard to see if CTRL is currently pressed.
\ ******************************************************************************

.CTRL
{
 LDX #1                 ; Set X to the internal key number for CTRL and fall
                        ; through to DSK4 to scan the keyboard
}

\ ******************************************************************************
\ Subroutine: DKS4
\
\ Scan the keyboard to see if the key specified in X is currently being
\ pressed.
\
\ Arguments:
\
\   X           The internal number of the key to check (see p.142 of the
\               Advanced User Guide for a list of internal key values)
\
\ Returns:
\
\   X           If the key in X is being pressed, X contains the original
\               argument X, but with bit 7 set (i.e. X + 128). If the key in
\               X is not being pressed, the value in X is unchanged.
\
\   A           Contains the same as X
\ ******************************************************************************

.DKS4
{
 LDA #3                 ; Set A to 3, so it's ready to send to SHEILA once
                        ; interrupts have been disabled

 SEI                    ; Disable interrupts so we can scan the keyboard
                        ; without being hijacked

 STA SHEILA+&40         ; Set 6522 System VIA output register ORB (SHEILA &40)
                        ; to %0011 to stop auto scan of keyboard

 LDA #%01111111         ; Set 6522 System VIA data direction register DDRA
 STA SHEILA+&43         ; (SHEILA &43) to %0111 1111. This sets the A registers
                        ; (IRA and ORA) so that 
                        ;
                        ; Bits 0-6 of ORA will sent to the keyboard
                        ;
                        ; Bit 7 of IRA will be read from the keyboard

 STX SHEILA+&4F         ; Set 6522 System VIA output register ORA (SHEILA &4F)
                        ; to X, the key we want to scan for; bits 0-6 will be
                        ; sent to the keyboard, of which bits 0-3 determine the
                        ; keyboard column, and bits 4-6 the keyboard row

 LDX SHEILA+&4F         ; Read 6522 System VIA output register IRA (SHEILA &4F)
                        ; into X; bit 7 is the only bit that will have changed.
                        ; If the key is pressed, then bit 7 will be set (so X
                        ; will contain 128 + X), otherwise it will be clear (so
                        ; X will be unchanged).
 
 LDA #%00001011         ; Set 6522 System VIA output register ORB (SHEILA &40)
 STA SHEILA+&40         ; to %1011 to restart auto scan of keyboard

 CLI                    ; Allow interrupts again

 TXA                    ; Transfer X into A

 RTS
}

\ ******************************************************************************
\ Subroutine: DKS2
\
\ Return the value of ADC channel in X (used to read the joystick). The value
\ will be inverted if the game has been configured to reverse both joystick
\ channels (which can be done by pausing the game and pressing J).
\
\ Arguments:
\
\   X           The ADC channel to read (1 = joystick X, 2 = joystick Y)
\
\ Returns:
\
\   (A X)       The 16-bit value read from channel X, with the value inverted
\               if the game has been configured to reverse the joystick
\ ******************************************************************************

.DKS2
{
 LDA #&80               ; Call OSBYTE &80 to fetch the 16-bit value from ADC
 JSR OSBYTE             ; channel X, returning (Y X), i.e. the high byte in Y
                        ; and the low byte in X

 TYA                    ; Copy Y to A, so the result is now in (A X)

 EOR JSTE               ; The high byte A is now EOR'd with the value in
                        ; location JSTE, which contains &FF if both joystick
                        ; channels are reversed and 0 otherwise (so A now 
                        ; contains the high byte but inverted, if that's what
                        ; the current settings say)

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: DKS3
\
\ Toggle a configuration setting and emit a beep. This is called when the game
\ is paused and a key is pressed that changes the games's configuration.
\ Specifically, this routine toggles the configuration settings for the
\ following keys:
\
\   * Caps Lock toggles keyboard flight damping (&40)
\   * A toggles keyboard auto-recentre (&41)
\   * X toggles author names on start-up screen (&42)
\   * F toggles flashing console bars (&43)
\   * Y toggles reverse joystick Y channel (&44)
\   * J toggles reverse both joystick channels (&45)
\   * K toggles keyboard and joystick (&46)
\
\ The numbers in brackets are the internal key numbers (see p.142 of the
\ Advanced User Guide for a list of internal key values). We pass the key that
\ has been pressed in X, and the configuration option to check it against in Y,
\ so this routine is typically called in a loop that loops through the various
\ configuration options.
\
\ Arguments:
\
\   X           The internal number of the key that's been pressed
\
\   Y           The internal number of the configuration key to check against,
\               from the list above (i.e. Y must be from &40 to &46)
\ ******************************************************************************

.DKS3
{
 STY T                  ; Store the configuration key argument in T

 CPX T                  ; If X <> Y, jump to Dk3 to return from the subroutine
 BNE Dk3

                        ; We have a match between X and Y, so now to toggle
                        ; the relevant configuration byte. Caps Lock has a key
                        ; value of &40 and has its configuration byte at
                        ; location DAMP, A has a value of &41 and has its byte
                        ; at location DJD, which is DAMP+1, and so on. So we
                        ; can toggle the configuration byte by changing the
                        ; byte at DAMP + (X - &40), or to put it in indexing
                        ; terms, DAMP-&40,X. It's no coincidence that the
                        ; game's configuration bytes are set up in this order
                        ; and with these keys (and this is also why the sound
                        ; on/off keys are dealt with elsewhere, as the internal
                        ; key for S and Q are &51 and &10, which don't fit
                        ; nicely into this approach).

 LDA DAMP-&40,X         ; Fetch the byte from DAMP + (X - &40), invert it and
 EOR #&FF               ; put it back (0 means no and &FF means yes in the
 STA DAMP-&40,X         ; configuration bytes, so this toggles the setting)

 JSR BELL               ; Make a beep sound so we know something has happened

 JSR DELAY              ; Wait for Y vertical syncs (Y is between 64 and 70, so
                        ; this is always a bit longer than a second)

 LDY T                  ; Restore the configuration key argument into Y

.Dk3

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: DKJ1
\
\ Read joystick flight controls. Specifically, scan the keyboard for the speed
\ up and slow down keys, and read the joystick's fire button and X and Y axes,
\ storing the results in the key logger and the joystick position variables.
\
\ This routine is only called if joysticks are enabled (JSTK = non-zero).
\ ******************************************************************************

.DKJ1
{
 LDY #1                 ; Update the key logger for key 1 in the KYTB table, so
 JSR DKS1               ; KY1 will be &FF if ? (slow down) is being pressed

 INY                    ; Update the key logger for key 2 in the KYTB table, so
 JSR DKS1               ; KY2 will be &FF if Space (speed up) is being pressed

 LDA SHEILA+&40         ; Read 6522 System VIA input register IRB (SHEILA &40)

 TAX                    ; This instruction doesn't seem to have any effect, as
                        ; X is overwritten in a few instructions. When the
                        ; joystick is checked in a similar way in the TITLE
                        ; subroutine for the "Press Fire Or Space,Commander."
                        ; stage of the start-up screen, there's another
                        ; unnecessary TAX instruction present, but there it's
                        ; commented out.

 AND #%00010000         ; Bit 4 of IRB (PB4) is clear if joystick 1's fire
                        ; button is pressed, otherwise it is set, so AND'ing
                        ; the value of IRB with %10000 extracts this bit

 EOR #%00010000         ; Flip bit 4 so that it's set if the fire button has
 STA KY7                ; been pressed, and store the result in the keyboard
                        ; logger at location KY7, which is also where the A key
                        ; (fire lasers) key is logged

 LDX #1                 ; Call DKS2 to fetch the value of ADC channel 1 (the
 JSR DKS2               ; joystick X value) into (A X), and OR A with 1. This
 ORA #1                 ; ensures that the high byte is at least 1, and then we
 STA JSTX               ; store the result in JSTX.

 LDX #2                 ; Call DKS2 to fetch the value of ADC channel 2 (the
 JSR DKS2               ; joystick Y value) into (A X), and EOR A with JSTGY.
 EOR JSTGY              ; JSTGY will be &FF if the game is configured to
 STA JSTY               ; reverse the joystick Y channel, so this EOR does
                        ; exactly that, and then we store the result in JSTY.

 JMP DK4                ; We are done scanning the joystick flight controls,
                        ; so jump to DK4 to scan for other keys, using a tail
                        ; call so we can return from the subroutine there.
}

\ ******************************************************************************
\ Subroutine: U%
\
\ Clear the key logger (from KY1 through KY19).
\
\ Returns:
\
\   A           A is set to 0
\ ******************************************************************************

.U%
{
 LDA #0                 ; Set A to 0, as this means "key not pressed" in the
                        ; key logger at KL

 LDY #15                ; We want to clear the 15 key logger locations from
                        ; KY1 to KY19, so set a counter in Y. We don't want to
                        ; clear the first key logger location, at KL, as the
                        ; keyboard table at KYTB starts with offset 1, not 0,
                        ; so KL is not technically part of the key logger
                        ; (it's actually used for logging keys that don't
                        ; appear in the keyboard table, and which therefore
                        ; don't use the key logger)

.DKL3

 STA KL,Y               ; Store 0 in the Y-th byte of the key logger

 DEY                    ; Decrement the counter

 BNE DKL3               ; And loop back for the next key

 RTS
}

\ ******************************************************************************
\ Subroutine: DOKEY
\
\ Scan for the seven primary flight controls (or the equivalent on joystick),
\ pause and configuration keys, and secondary flight controls, and update the
\ key logger accordingly. Specifically:
\
\   * If we are on keyboard configuration, clear the key logger and update it
\     for the seven primary flight controls, and update the roll and pitch
\     rates accordingly.
\
\   * If we are on joystick configuration, clear the key logger and jump to
\     DKJ1, which reads the joystick equivalents of the primary flight
\     controls.
\
\ Both options end up at DK4 to scan for other keys, beyond the seven primary
\ flight controls.
\ ******************************************************************************

.DOKEY
{
 JSR U%                 ; Call U% to clear the key logger

 LDA JSTK               ; If JSTK is non-zero, then we are configured to use
 BNE DKJ1               ; the joystick rather than keyboard, so jump to DKJ1
                        ; to read the joystick flight controls, before jumping
                        ; to DK4 below

 LDY #7                 ; We're going to work our way through the primary flight
                        ; control keys (pitch, roll, speed and laser), so set a
                        ; counter in Y so we can loop through all 7

.DKL2

 JSR DKS1               ; Call DKS1 to see if the KYTB key at offset Y is being
                        ; pressed, and set the key logger accordingly

 DEY                    ; Decrement the loop counter

 BNE DKL2               ; Loop back for the next key, working our way from A at
                        ; KYTB+7 down to ? at KYTB+1

 LDX JSTX               ; Set X = JSTX, the current roll rate (as shown in the
                        ; RL indicator on the dashboard)

 LDA #7                 ; Set A to 7, which is the amount we want to alter the
                        ; roll rate by if the roll keys are being pressed

 LDY KL+3               ; If the < key is being pressed, then call the BUMP2
 BEQ P%+5               ; routine to increase the roll rate in X by A
 JSR BUMP2

 LDY KL+4               ; If the > key is being pressed, then call the REDU2
 BEQ P%+5               ; routine to decrease the roll rate in X by A, taking
 JSR REDU2              ; the keyboard auto re-centre setting into account

 STX JSTX               ; Store the updated roll rate in JSTX

 ASL A                  ; Double the value of A, to 14

 LDX JSTY               ; Set X = JSTY, the current pitch rate (as shown in the
                        ; DC indicator on the dashboard)

 LDY KL+5               ; If the > key is being pressed, then call the REDU2
 BEQ P%+5               ; routine to decrease the pitch rate in X by A, taking
 JSR REDU2              ; the keyboard auto re-centre setting into account

 LDY KL+6               ; If the S key is being pressed, then call the BUMP2
 BEQ P%+5               ; routine to increase the pitch rate in X by A
 JSR BUMP2

 STX JSTY               ; Store the updated roll rate in JSTY

                        ; Fall through into DK4 to scan for other keys
}

\ ******************************************************************************
\ Subroutine: DK4
\
\ Scan for pause and configuration keys, and if this is a space view, also scan
\ for secondary flight controls.
\
\ Specifically:
\
\   * Scan for the pause button (COPY) and if it's pressed, pause the game and
\     process any configuration key presses until the game is unpaused (DELETE)
\
\   * If this is a space view, scan for secondary flight keys and update the
\     relevant bytes in the key logger
\ ******************************************************************************

.DK4
{
 JSR RDKEY              ; Scan the keyboard from Q upwards and fetch any key
                        ; press into X

 STX KL                 ; Store X in KL, byte 0 of the key logger

 CPX #&69               ; If COPY is not being pressed, jump to DK2 below,
 BNE DK2                ; otherwise let's process the configuration keys

.FREEZE                 ; COPY is being pressed, so we enter a loop that
                        ; listens for configuration keys, and we keep looping
                        ; until we detect a DELETE keypress. This effectively
                        ; pauses the game when COPY is pressed, and unpauses
                        ; it when DELETE is pressed.

 JSR WSCAN              ; Wait for line scan, so the whole frame is completed

 JSR RDKEY              ; Scan the keyboard from Q upwards and fetch any key
                        ; press into X

 CPX #&51               ; If S is not being pressed, skip to DK6
 BNE DK6

 LDA #0                 ; S is being pressed, so set DNOIZ to 0 to turn the
 STA DNOIZ              ; sound on

.DK6

 LDY #&40               ; We now want to loop through the keys that toggle
                        ; various settings. These have internal key numbers
                        ; between &40 (Caps Lock) and &46 (K), so we set up the
                        ; first key number in Y to act as a loop counter. See
                        ; subroutine DKS3 for more details on this.

.DKL4

 JSR DKS3               ; Call DKS3 to scan for the key given in Y, and toggle
                        ; the relevant setting if it is pressed

 INY                    ; Increment Y to point to the next toggle key

 CPY #&47               ; The last toggle key is &46 (K), so check whether we
                        ; have just done that one

 BNE DKL4               ; If not, loop back to check for the next toggle key

.DK55

 CPX #&10               ; If Q is not being pressed, skip to DK7
 BNE DK7

 STX DNOIZ              ; S is being pressed, so set DNOIZ to X, which is
                        ; non-zero (&10), so this will turn the sound off

.DK7

 CPX #&70               ; If Escape is not being pressed, skip over the next
 BNE P%+5               ; instruction

 JMP DEATH2             ; Escape is being pressed, so jump to DEATH2 to end
                        ; the game

 CPX #&59               ; If DELETE is not being pressed, we are still paused,
 BNE FREEZE             ; so loop back up to keep listening for configuration
                        ; keys, otherwise fall through into the rest of the
                        ; key detection code, which unpauses the game

.DK2

 LDA QQ11               ; If the current view is non-zero (i.e. not a space
 BNE DK5                ; view), return from the subroutine (as DK5 contains
                        ; an RTS)

 LDY #15                ; This is a space view, so now we want to check for all
                        ; the secondary flight keys. The internal key numbers
                        ; are in the keyboard table KYTB from KYTB+8 to
                        ; KYTB+15, and their key logger locations are from KL+8
                        ; to KL+15. So set a decreasing counter in Y for the
                        ; index, starting at 15, so we can loop through them.

 LDA #&FF               ; Set A to &FF so we can store this in the keyboard
                        ; logger for keys that are being pressed

.DKL1

 LDX KYTB,Y             ; Get the internal key value of the Y-th flight key
                        ; the KYTB keyboard table

 CPX KL                 ; We stored the key that's being pressed in Kl above,
                        ; so check to see if the Y-th flight key is being
                        ; pressed

 BNE DK1                ; If it is not being pressed, skip to DK1 below

 STA KL,Y               ; The Y-th flight key is being pressed, so set that
                        ; key's location in the key logger to &FF

.DK1

 DEY                    ; Decrement the loop counter

 CPY #7                 ; Have we just done the last key?

 BNE DKL1               ; If not, loop back to process the next key

.DK5

 RTS                    ; Return from subroutine
}

\ ******************************************************************************
\ Subroutine: TT217
\
\ Other entry points: out (RTS)
\
\ Scan the keyboard until a key is pressed, and return the key's ASCII code.
\ If, on entry, a key is already being held down, then wait until that key is
\ released first (so this routine detects the first key down event following
\ the subroutine call).
\
\ Returns:
\
\   X           The ASCII code of the key that was pressed
\
\   A           Contains the same as X
\
\   Y           Y is preserved
\ ******************************************************************************

.TT217
{
 STY YSAV               ; Store Y in temporary storage, so we can restore it
                        ; later

.t

 JSR DELAY-5            ; Delay for 8 vertical syncs (8/50 = 0.16 seconds) so we
                        ; don't take up too much CPU time while looping round

 JSR RDKEY              ; Scan the keyboard, starting from Q

 BNE t                  ; If a key was already being held down when we entered
                        ; this routine, keep looping back up to t, until the
                        ; key is released

.t2

 JSR RDKEY              ; Any pre-existing key press is now gone, so we can
                        ; start scanning the keyboard again, starting from Q

 BEQ t2                 ; Keep looping up to t2 until a key is pressed

 TAY                    ; Copy A to Y, so Y contains the internal key number
                        ; of the key pressed

 LDA (TRTB%),Y          ; The address in TRTB% points to the MOS key
                        ; translation table, which is used to translate
                        ; internal key values to ASCII, so this fetches the
                        ; key's ASCII code into A
 
 LDY YSAV               ; Restore the original value of Y we stored above

 TAX                    ; Copy A into X

.^out

 RTS                    ; Return from the subroutine
}

\ ******************************************************************************
\ Subroutine: me1
\
\ Erase an old in-flight message and display a new one.
\
\ Arguments:
\
\   A           The text token to be printed
\
\   X           Must be set to 0
\ ******************************************************************************

.me1
{
 STX DLY                ; Set the message delay in DLY to 0

 PHA                    ; Store the new message token we want to print

 LDA MCH                ; Set A to the token number of the message that is
 JSR mes9               ; currently on screen, and call mes9 to print it (which
                        ; will remove it from the screen, as printing is done
                        ; using EOR logic)

 PLA                    ; Restore the new message token

 EQUB &2C               ; Fall through into me1 to print the new message, but
                        ; skip the first instruction by turning it into
                        ; &2C &A9 &6C, or BIT &6CA9, which does nothing bar
                        ; affecting the flags
}

\ ******************************************************************************
\ Subroutine: ou2
\
\ Display "E.C.M.SYSTEM DESTROYED" as an in-flight message.
\ ******************************************************************************

.ou2
{
 LDA #108               ; Set A to recursive token 108 ("E.C.M.SYSTEM")

 EQUB &2C               ; Fall through into ou3 to print the new message, but
                        ; skip the first instruction by turning it into
                        ; &2C &A9 &6F, or BIT &6FA9, which does nothing bar
                        ; affecting the flags
}

\ ******************************************************************************
\ Subroutine: ou3
\
\ Display "FUEL SCOOPS DESTROYED" as an in-flight message.
\ ******************************************************************************

.ou3
{
 LDA #111               ; Set A to recursive token 111 ("FUEL SCOOPS")
}

\ ******************************************************************************
\ Subroutine: MESS
\
\ Display an in-flight message in capitals at the bottom of the space view,
\ erasing any existing in-flight message first.
\
\ Arguments:
\
\   A           The text token to be printed
\ ******************************************************************************

.MESS
{
 LDX #0                 ; Set QQ17 = 0 to set ALL CAPS
 STX QQ17

 LDY #9                 ; Move the text cursor to column 9, row 22, at the
 STY XC                 ; bottom middle of the screen
 LDY #22
 STY YC

 CPX DLY                ; If the message delay in DLY is not zero, jump up to
 BNE me1                ; me1 to erase the current message first (whose token
                        ; number will be in MCH)

 STY DLY                ; Set the message delay in DLY to 22

 STA MCH                ; Set MCH to the token we are about to display and fall
                        ; through to mes9 to print the token
}

\ ******************************************************************************
\ Subroutine: mes9
\
\ Print a text token, followed by "DESTROYED" if the destruction flag is set
\ (for when a piece of equipment is destroyed).
\ ******************************************************************************

.mes9
{
 JSR TT27               ; Call TT27 to print the text token in A

 LSR de                 ; If bit 1 of location de is clear, return from the
 BCC out                ; subroutine (as out contains an RTS)

 LDA #253               ; Print recursive token 93 (" DESTROYED") and return
 JMP TT27               ; from the subroutine using a tail call
}

\ ******************************************************************************
\ Subroutine: OUCH
\
\ Shield depleted and taking hits to energy, lose cargo/equipment.
\ ******************************************************************************

.OUCH                   ; Shield depleted and taking hits to energy, lose cargo/equipment.
{
 JSR DORND              ; Set A and X to random numbers
 BMI out                ; rts, 50% prob
 CPX #22                ; max equipment
 BCS out                ; item too high
 LDA QQ20,X             ; cargo or equipment
 BEQ out                ; dont have, rts.
 LDA DLY                ; delay printing already going on
 BNE out                ; rts
 LDY #3                 ; also Acc now 0
 STY de                 ; message flag for item + destroyed
 STA QQ20,X             ; = 0
 CPX #17                ; max cargo
 BCS ou1                ; if yes, equipment Lost, down.
 TXA                    ; else cargo lost, carry is clear.
 ADC #208               ; add to token = food
 BNE MESS               ; guaranteed up, Message start.

.ou1                    ; equipment Lost

 BEQ ou2                ; equipment lost is X=17 ecm, up.
 CPX #18                ; equipment item is 
 BEQ ou3                ; fuel scoops, up.
 TXA                    ; else carry set probably
 ADC #113-20            ; #113-20, token = Bomb, energy unit, docking computer
 BNE MESS               ; guaranteed up, Message start.
}

\ ******************************************************************************
\ Variable: QQ16
\
\ Two-letter token lookup string for tokens 128-159. See variable QQ18 for
\ details of how the two-letter token system works.
\ ******************************************************************************

.QQ16
{
 EQUS "ALLEXEGEZACEBISOUSESARMAINDIREA?ERATENBERALAVETIEDORQUANTEISRION"
}

\ ******************************************************************************
\ Variable: QQ23
\
\ Market prices table. Each item has four bytes of data, like this:
\
\   Byte #0 = Base price
\   Byte #1 = Economic factor in bits 0-4, with the sign in bit 7
\             Unit in bits 5-6
\   Byte #2 = Base quantity
\   Byte #3 = Mask to control price fluctuations
\
\ To make it easier for humans to follow, we've defined a macro called ITEM
\ that takes the following arguments and builds the four bytes for us:
\
\   ITEM base price, economic factor, units, base quantity, mask
\
\ So for food, we have the following:
\
\   * Base price = 19
\   * Economic factor = -2
\   * Unit = tonnes
\   * Base quantity = 6
\   * Mask = %00000001
\ ******************************************************************************

.QQ23
{          
 ITEM 19,  -2, 't',   6, %00000001   ; 0  = Food

 ITEM 20,  -1, 't',  10, %00000011   ; 1  = Textiles

 ITEM 65,  -3, 't',   2, %00000111   ; 2  = Radioactives

 ITEM 40,  -5, 't', 226, %00011111   ; 3  = Slaves

 ITEM 83,  -5, 't', 251, %00001111   ; 4  = Liquor/Wines

 ITEM 196,  8, 't',  54, %00000011   ; 5  = Luxuries

 ITEM 235, 29, 't',   8, %01111000   ; 6  = Narcotics

 ITEM 154, 14, 't',  56, %00000011   ; 7  = Computers

 ITEM 117,  6, 't',  40, %00000111   ; 8  = Machinery

 ITEM 78,   1, 't',  17, %00011111   ; 9  = Alloys

 ITEM 124, 13, 't',  29, %00000111   ; 10 = Firearms

 ITEM 176, -9, 't', 220, %00111111   ; 11 = Furs

 ITEM 32,  -1, 't',  53, %00000011   ; 12 = Minerals

 ITEM 97,  -1, 'k',  66, %00000111   ; 13 = Gold

 ITEM 171, -2, 'k',  55, %00011111   ; 14 = Platinum

 ITEM 45,  -1, 'g', 250, %00001111   ; 15 = Gem-Stones

 ITEM 53,  15, 't', 192, %00000111   ; 16 = Alien Items
}

\ ******************************************************************************
\ Subroutine: TI2
\
\ Tidy2 \ yunit small, used to renormalize rotation matrix Xreg = index1 = 0
\ ******************************************************************************

.TI2                    ; Tidy2 \ yunit small, used to renormalize rotation matrix Xreg = index1 = 0
{
 TYA                    ; Acc  index3 = 4
 LDY #2                 ; Yreg index2 = 2
 JSR TIS3               ; below, denom is z
 STA INWK+20            ; Uz=-(FxUx+FyUy)/Fz \ their comment \ rotmat1z hi
 JMP TI3                ; Tidy3
}

\ ******************************************************************************
\ Subroutine: TI1
\
\ Tidy1 \ xunit small, with Y = 4
\ ******************************************************************************

.TI1                    ; Tidy1 \ xunit small, with Y = 4
{
 TAX                    ; Xreg = index1 = 0
 LDA XX15+1
 AND #&60               ; is yunit vector small
 BEQ TI2                ; up, Tidy2  Y = 4
 LDA #2                 ; else index2 = 4, index3 = 2
 JSR TIS3               ; below, denom is y
 STA INWK+18            ; rotmat1 hi
 JMP TI3                ; Tidy3
}

\ ******************************************************************************
\ Subroutine: TIDY
\
\ Orthogonalize rotation matrix that uses 0x60 as unity
\ returns INWK(16,18,20) = INWK(12*18+14*20, 10*16+14*20, 10*16+12*18) / INWK(10,12,14)
\ Ux,Uy,Uz = -(FyUy+FzUz, FxUx+FzUz, FxUx+FyUy)/ Fx,Fy,Fz
\ ******************************************************************************

.TIDY                   ; Orthogonalize rotation matrix that uses 0x60 as unity
{
 LDA INWK+10            ; rotmat0x hi
 STA XX15               ; XX15(0,1,2) = Fx,Fy,Fz
 LDA INWK+12            ; rotmat0y hi
 STA XX15+1
 LDA INWK+14            ; rotmat0z hi
 STA XX15+2
 JSR NORM               ; normalize  F= Rotmat0
 LDA XX15               ; XX15+0
 STA INWK+10            ; rotmat0x hi
 LDA XX15+1
 STA INWK+12            ; rotmat0y hi
 LDA XX15+2
 STA INWK+14            ; rotmat0z hi

 LDY #4                 ; Y=#4
 LDA XX15
 AND #&60               ; is xunit small?
 BEQ TI1                ; up to Tidy1 with Y = 4
 LDX #2                 ; index1 = 2
 LDA #0                 ; index3 = 0
 JSR TIS3               ; below with Yreg = index2 = 4, denom = x
 STA INWK+16            ; rotmat1x hi
}

.TI3                    ; Tidy3  \ All 3 choices continue with rotmat1? updated
{
 LDA INWK+16            ; rotmat1x hi
 STA XX15
 LDA INWK+18            ; rotmat1y hi
 STA XX15+1
 LDA INWK+20            ; rotmat1z hi
 STA XX15+2             ; XX15(0,1,2) = Ux,Uy,Uz
 JSR NORM               ; normalize Rotmat1
 LDA XX15
 STA INWK+16            ; rotmat1x hi
 LDA XX15+1
 STA INWK+18            ; rotmat1y hi
 LDA XX15+2
 STA INWK+20            ; rotmat1z hi
 LDA INWK+12            ; rotmat0y hi
 STA Q                  ; = Fy
 LDA INWK+20            ; = Uz   \ rotmat1z hi
 JSR MULT12             ; R.S = P.A = Q * A = FyUz
 LDX INWK+14            ; = Fz	\ rotmat0z hi
 LDA INWK+18            ; = Uy	\ rotmat1y hi
 JSR TIS1               ; X.A =  -X*A  + (R.S)/96
 EOR #128               ; flip
 STA INWK+22            ; hsb(FzUy-FyUz)/96*255 \ rotmat2x hi
 LDA INWK+16            ; = Ux \ rotmat1x hi
 JSR MULT12             ; R.S = Q * A = FyUx
 LDX INWK+10            ; = Fx \ rotmat0x hi
 LDA INWK+20            ; = Uz \ rotmat1z hi
 JSR TIS1               ; X.A =  -X*A  + (R.S)/96
 EOR #128               ; flip
 STA INWK+24            ; rotmat2y hi
 LDA INWK+18            ; = Uy \ rotmat1y hi
 JSR MULT12             ; R.S = Q * A = FyUy
 LDX INWK+12            ; = Fy \ rotmat0y hi
 LDA INWK+16            ; = Ux \ rotmat1x hi
 JSR TIS1               ; X.A =  -X*A  + (R.S)/96
 EOR #128               ; flip
 STA INWK+26            ; rotmat2z hi
 LDA #0                 ; clear matrix lo's
 LDX #14                ; except 2z's

.TIL1                   ; counter X

 STA INWK+9,X
 DEX                    ; +23 and down
 DEX                    ; skip hi's
 BPL TIL1               ; loop X
 RTS
}

.TIS2                   ; Reduce Acc in NORM routine i.e. *96/Q
{
 TAY                    ; copy of Acc
 AND #127               ; ignore sign
 CMP Q
 BCS TI4                ; clean to +/- unity
 LDX #254               ; division roll
 STX T

.TIL2                   ; roll T

 ASL A
 CMP Q
 BCC P%+4               ; skip sbc
 SBC Q
 ROL T
 BCS TIL2               ; loop T
 LDA T

 LSR A
 LSR A                  ; result/4
 STA T
 LSR A                  ; result/8
 ADC T
 STA T                  ; T = 3/8*Acc (max = 96)
 TYA                    ; copy of Acc
 AND #128               ; sign
 ORA T
 RTS

.TI4                    ; clean to +/- unity

 TYA                    ; copy of Acc
 AND #128               ; sign
 ORA #96                ; +/- unity
 RTS
}

\ ******************************************************************************
\ Subroutine: TIS3
\
\ A = INWK(12*18+14*20, 10*16+14*20, 10*16+12*18) / INWK(10,12,14)
\ Ux,Uy,Uz = -(FyUy+FzUz, FxUx+FzUz, FxUx+FyUy)/ Fx,Fy,Fz
\ Xreg = index1, Yreg = index2, Acc = index3
\ ******************************************************************************

.TIS3                   ; visited by TI1,TI2
{
 STA P+2                ; store index3
 LDA INWK+10,X          ; rotmat0x,X hi
 STA Q
 LDA INWK+16,X          ; rotmat1x,X hi
 JSR MULT12             ; R.S = Q * rotmat1x
 LDX INWK+10,Y          ; rotmat0x,Y hi
 STX Q
 LDA INWK+16,Y          ; rotmat1x,Y hi
 JSR MAD                ; X.A = rotmat0x*rotmat1y + R.S

 STX P                  ; num lo
 LDY P+2                ; index3
 LDX INWK+10,Y          ; rotmat0x,A hi
 STX Q                  ; is denominator
 EOR #128               ; num -hi
}

\ ******************************************************************************
\ Subroutine: DVIDT
\
\ A=AP/Q \ their comment.  A = (P,A)/Q
\ ******************************************************************************

.DVIDT                  ; A=AP/Q \ their comment.  A = (P,A)/Q
{
 STA P+1                ; num hi
 EOR Q
 AND #128               ; sign bit
 STA T
 LDA #0
 LDX #16                ; counter 2 bytes
 ASL P                  ; num lo
 ROL P+1                ; num hi
 ASL Q                  ; denom
 LSR Q                  ; lose sign bit, clear carry

.DVL2                   ; counter X

 ROL A
 CMP Q
 BCC P%+4               ; skip sbc
 SBC Q
 ROL P                  ; result
 ROL P+1
 DEX
 BNE DVL2               ; loop X
 LDA P
 ORA T                  ; sign bit
 RTS                    ; -- end of TIDY 

}

\ ******************************************************************************
\ Save output/ELTF.bin
\ ******************************************************************************

PRINT "ELITE F"
PRINT "Assembled at ", ~CODE_F%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_F%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_F%

PRINT "S.ELTF ", ~CODE_F%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_F%
SAVE "output/ELTF.bin", CODE_F%, P%, LOAD%

\ ******************************************************************************
\ ELITE G
\
\ Produces the binary file ELTG.bin which gets loaded by elite-bcfs.asm.
\ ******************************************************************************

CODE_G% = P%
LOAD_G% = LOAD% + P% - CODE%

\ ******************************************************************************
\ Subroutine: SHPPT
\
\ Ship plot as point from LL10
\ ******************************************************************************

.SHPPT                  ; ship plot as point from LL10
{
 JSR EE51               ; if bit3 set draw to erase lines in XX19 heap
 JSR PROJ               ; Project K+INWK(x,y)/z to K3,K4 for craft center
 ORA K3+1
 BNE nono
 LDA K4                 ; #Y Ymiddle not K4 when docked
 CMP #Y*2-2             ; #Y*2-2  96*2-2 screen height
 BCS nono               ; off top of screen
 LDY #2                 ; index for edge heap
 JSR Shpt               ; Ship is point, could end if nono-2
 LDY #6                 ; index for edge heap
 LDA K4                 ; #Y
 ADC #1                 ; 1 pixel uo
 JSR Shpt               ; Ship is point, could end if nono-2
 LDA #8                 ; set bit3 (to erase later) and plot as Dot
 ORA XX1+31             ; display/exploding state|missiles
 STA XX1+31
 LDA #8                 ; Dot uses #8 not U
 JMP LL81+2             ; skip first two edges on XX19 heap
 PLA                    ; nono-2 \ Changing return address
 PLA                    ; ending routine early
}

\ ******************************************************************************
\ Subroutine: nono
\
\ Clear bit3 nothing to erase in next round, no draw.
\ ******************************************************************************

.nono                   ; clear bit3 nothing to erase in next round, no draw.
{
 LDA #&F7               ; clear bit3
 AND XX1+31             ; display/exploding state|missiles
 STA XX1+31
 RTS
}

\ ******************************************************************************
\ Subroutine: Shpt
\
\ Ship is point at screen center
\ ******************************************************************************

.Shpt                   ; ship is point at screen center
{
 STA (XX19),Y
 INY
 INY                    ; next Y coord
 STA (XX19),Y
 LDA K3                 ; Xscreen-mid, not K3 when docked
 DEY                    ; 2nd X coord
 STA (XX19),Y
 ADC #3                 ; 1st X coord
 BCS nono-2             ; overflowed to right, remove 2 from stack and clear bit 3
 DEY
 DEY                    ; first entry in group of 4 added to ship line heap
 STA (XX19),Y
 RTS
}

\ ******************************************************************************
\ Subroutine: LL5
\
\ Calculate the following square root:
\
\   Q = SQRT(R Q)
\ ******************************************************************************

.LL5                    ; 2BSQRT Q=SQR(RQ) \ two-byte square root, R is hi, Q is lo.
{
 LDY R                  ; hi
 LDA Q
 STA S                  ; lo
 LDX #0                 ; result
 STX Q
 LDA #8                 ; counter
 STA T

.LL6                    ; counter T

 CPX Q
 BCC LL7                ; no carry
 BNE LL8                ; hop ne
 CPY #&40               ; hi
 BCC LL7                ; no carry

.LL8                    ; hop ne

 TYA
 SBC #&40
 TAY                    ; new hi
 TXA
 SBC Q
 TAX                    ; maybe carry into

.LL7                    ; no carry

 ROL Q                  ; result
 ASL S                  ; maybe carry into Yreg
 TYA
 ROL A
 TAY                    ; Yhi *2
 TXA
 ROL A
 TAX                    ; Xlo *2
 ASL S                  ; maybe carry into Yreg
 TYA
 ROL A
 TAY                    ; Yhi *2
 TXA
 ROL A
 TAX                    ; Xlo *2
 DEC T
 BNE LL6                ; loop T
 RTS                    ; Q left with root
}

\ ******************************************************************************
\ Subroutine: LL28
\
\ BFRDIV R=A*256/Q \ byte from remainder of division
\ ******************************************************************************

.LL28                   ; BFRDIV R=A*256/Q \ byte from remainder of division
{
 CMP Q                  ; is A >=  Q ?
 BCS LL2                ; if yes, answer too big for 1 byte, R=#&FF
 LDX #254               ; remainder R for AofQ *256/Q
 STX R                  ; div roll counter
}

.LL31                   ; roll R
{
 ASL A
 BCS LL29               ; hop to Reduce
 CMP Q
 BCC P%+4               ; skip sbc
 SBC Q
 ROL R
 BCS LL31               ; loop R
 RTS                    ; R left with remainder of division

.LL29                   ; Reduce

 SBC Q
 SEC
 ROL R
 BCS LL31               ; loop R
 RTS                    ; R left with remainder of division
}

.LL2                    ; answer too big for 1 byte, R=#&FF
{
 LDA #&FF
 STA R
 RTS
}

\ ******************************************************************************
\ Subroutine: LL38
\
\ BADD(S)A=R+Q(SA) \ byte add (subtract)   (Sign S)A = R + Q*(Sign from A^S)
\ ******************************************************************************

.LL38                   ; BADD(S)A=R+Q(SA) \ byte add (subtract)   (Sign S)A = R + Q*(Sign from A^S)
{
 EOR S                  ; sign of operator is A xor S
 BMI LL39               ; 1 byte subtraction
 LDA Q                  ; else addition, S already correct
 CLC
 ADC R
 RTS

.LL39                   ; 1 byte subtraction (S)A = R-Q

 LDA R
 SEC
 SBC Q
 BCC P%+4               ; sign of S needs correcting, hop over rts
 CLC
 RTS
 PHA                    ; store subtraction result
 LDA S
 EOR #128               ; flip
 STA S
 PLA                    ; restore subtraction result
 EOR #255
 ADC #1                 ; negate
 RTS
}

\ ******************************************************************************
\ Subroutine: LL51
\
\ XX12=XX15.XX16  each vector is 16-bit x,y,z
\ XX16_hsb[   1  3  5    highest XX16 done below is 5, then X taken up by 6, Y taken up by 2.
\             7  9 11
\	         13 15 17=0 ?]
\ ******************************************************************************

.LL51                   ; XX12=XX15.XX16  each vector is 16-bit x,y,z
{
 LDX #0
 LDY #0

.ll51                   ; counter X+=6 < 17  Y+=2

 LDA XX15               ; xmag
 STA Q
 LDA XX16,X
 JSR FMLTU              ; Acc= XX15 *XX16 /256 assume unsigned
 STA T
 LDA XX15+1
 EOR XX16+1,X
 STA S                  ; xsign
 LDA XX15+2             ; ymag
 STA Q
 LDA XX16+2,X
 JSR FMLTU              ; Acc= XX15 *XX16 /256 assume unsigned
 STA Q
 LDA T
 STA R                  ; move T to R
 LDA XX15+3             ; ysign
 EOR XX16+3,X
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 STA T
 LDA XX15+4             ; zmag
 STA Q
 LDA XX16+4,X
 JSR FMLTU              ; Acc= XX15 *XX16 /256 assume unsigned
 STA Q
 LDA T
 STA R                  ; move T to R
 LDA XX15+5             ; zsign
 EOR XX16+5,X
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 STA XX12,Y
 LDA S                  ; result sign
 STA XX12+1,Y
 INY
 INY                    ; Y +=2
 TXA
 CLC
 ADC #6
 TAX                    ; X +=6
 CMP #17                ; X finished?
 BCC ll51               ; loop for second half of matrix
 RTS
}

\ ******************************************************************************
\ Subroutine: LL25
\
\ Planet
\ ******************************************************************************

.LL25                   ; planet
{
 JMP PLANET
}

\ ******************************************************************************
\ Subroutine: LL9
\
\ Object ENTRY for displaying, including debris.
\ ******************************************************************************

.LL9                    ; object ENTRY for displaying, including debris.
{
 LDA TYPE               ; ship type
 BMI LL25               ; planet as bit7 set
 LDA #31                ; max visibility
 STA XX4
 LDA #32                ; mask for bit 5, exploding
 BIT XX1+31             ; display explosion state|missiles
 BNE EE28               ; bit5 set, explosion ongoing
 BPL EE28               ; bit7 clear, else Start blowing up!
 ORA XX1+31
 AND #&3F               ; clear bit7,6
 STA XX1+31
 LDA #0                 ; acceleration & pitch zeroed.
 LDY #28                ; byte #28 accel
 STA (INF),Y
 LDY #30                ; byte #30 rotz counter
 STA (INF),Y
 JSR EE51               ; if bit3 set erase old lines in XX19 heap
 LDY #1                 ; edge heap byte1
 LDA #18                ; counter for explosion radius
 STA (XX19),Y
 LDY #7                 ; Hull byte#7 explosion of ship type e.g. &2A
 LDA (XX0),Y
 LDY #2                 ; edge heap byte2
 STA (XX19),Y

\LDA XX1+32
\AND #&7F
\STA XX1+32

.EE55                   ; counter Y, 4 rnd bytes to edge heap

 INY                    ; #3 start
 JSR DORND
 STA (XX19),Y
 CPY #6                 ; bytes 3to6 = random bytes for seed
 BNE EE55               ; loop Y

.EE28                   ; bit5 set do explosion, or bit7 clear, dont kill.

 LDA XX1+8              ; sign of Z coord

.EE49                   ; In view?

 BPL LL10               ; hop over as object in front
}

.LL14                   ; Test to remove object
{
 LDA XX1+31             ; display explosion state|missiles
 AND #32                ; bit5 ongoing explosion?
 BEQ EE51               ; if no then if bit3 set erase old lines in XX19 heap
 LDA XX1+31             ; else exploding
 AND #&F7               ; clear bit3
 STA XX1+31
 JMP DOEXP              ; Explosion
}

.EE51                   ; if bit3 set draw lines in XX19 heap
{
 LDA #8                 ; mask for bit 3
 BIT XX1+31             ; exploding/display state|missiles
 BEQ LL10-1             ; if bit3 clear, just rts
 EOR XX1+31             ; else toggle bit3 to allow lines
 STA XX1+31
 JMP LL155              ; clear LINEstr. Draw lines in XX19 heap.

\LL24
 RTS                    ; needed by beq \ LL10-1 
}

.LL10                   ; object in front of you
{
 LDA XX1+7              ; zhi
 CMP #&C0               ; far in front
 BCS LL14               ; test to remove object
 LDA XX1                ; xlo
 CMP XX1+6              ; zlo
 LDA XX1+1              ; xhi
 SBC XX1+7              ; zhi, gives angle to object
 BCS LL14               ; test to remove object
 LDA XX1+3              ; ylo
 CMP XX1+6              ; zlo
 LDA XX1+4              ; yhi
 SBC XX1+7              ; zhi
 BCS LL14               ; test to remove object
 LDY #6                 ; Hull byte6, node gun*4
 LDA (XX0),Y
 TAX                    ; node heap index
 LDA #255               ; flag on node heap at gun
 STA XX3,X
 STA XX3+1,X
 LDA XX1+6              ; zlo
 STA T
 LDA XX1+7              ; zhi
 LSR A
 ROR T
 LSR A
 ROR T
 LSR A
 ROR T
 LSR A
 BNE LL13               ; hop as far
 LDA T
 ROR A                  ; bring in hi bit0
 LSR A
 LSR A                  ; small zlo
 LSR A                  ; updated visibility
 STA XX4
 BPL LL17               ; guaranteed hop to Draw wireframe

.LL13                   ; hopped to as far

 LDY #13                ; Hull byte#13, distance point at which ship becomes a dot
 LDA (XX0),Y
 CMP XX1+7              ; dot_distance >= z_hi will leave carry set
 BCS LL17               ; hop over to draw Wireframe
 LDA #32                ; mask bit5 exploding
 AND XX1+31             ; exploding/display state|missiles
 BNE LL17               ; hop over to Draw wireframe or exploding
 JMP SHPPT              ; else ship plot point, up.

.LL17                   ; draw Wireframe (including nodes exploding)

 LDX #5                 ; load rotmat into XX16

.LL15                   ; counter X

 LDA XX1+21,X
 STA XX16,X
 LDA XX1+15,X
 STA XX16+6,X
 LDA XX1+9,X
 STA XX16+12,X
 DEX
 BPL LL15               ; loop X
 LDA #197               ; comment here about NORM
 STA Q
 LDY #16

.LL21                   ; counter Y -=2

 LDA XX16,Y             ; XX16+0,Y
 ASL A                  ; get carry, only once.
 LDA XX16+1,Y
 ROL A
 JSR LL28               ; BFRDIV R=A*256/197
 LDX R
 STX XX16,Y
 DEY
 DEY                    ; Y -=2
 BPL LL21               ; loop Y
 LDX #8                 ; load craft coords into XX18

.ll91                   ; counter X

 LDA XX1,X
 STA XX18,X
 DEX
 BPL ll91               ; loop X

 LDA #255               ; last normal is always visible
 STA XX2+15
 LDY #12                ; Hull byte 12 =  normals*4
 LDA XX1+31
 AND #32                ; mask bit5 exploding
 BEQ EE29               ; no, only Some visible
 LDA (XX0),Y
 LSR A                  ; else do explosion needs all vertices
 LSR A                  ; /=4
 TAX                    ; Xreg = number of normals, faces
 LDA #&FF               ; all faces visible

.EE30                   ; counter X  for each face

 STA XX2,X
 DEX
 BPL EE30               ; loop X
 INX                    ; X = 0
 STX XX4                ; visibility = 0

.LL41                   ; visibilities now set in XX2,X Transpose matrix.

 JMP LL42               ; jump to transpose matrix

.EE29                   ; only Some visible  Yreg =Hull byte12, normals*4

 LDA (XX0),Y
 BEQ LL41               ; if no normals, visibilities now set in XX2,X Transpose matrix.
 STA XX20               ; normals*4
 LDY #18                ; Hull byte #18  normals scaled by 2^Q%
                        ; DtProd^XX2 \ their comment \ Dot product gives  normals' visibility in XX2
 LDA (XX0),Y
 TAX                    ; normals scaled by 2^X plus
 LDA XX18+7             ; z_hi

.LL90                   ; scaling object distance

 TAY                    ; z_hi
 BEQ LL91               ; object close/small, hop
 INX                    ; repeat INWK z brought closer, take X up
 LSR XX18+4             ; yhi
 ROR XX18+3             ; ylo
 LSR XX18+1             ; xhi
 ROR XX18               ; xlo
 LSR A                  ; zhi /=2
 ROR XX18+6             ; z_lo
 TAY                    ; zhi
 BNE LL90+3             ; again as z_hi too big

.LL91                   ; object close/small

 STX XX17               ; keep Scale required
 LDA XX18+8             ; last member of INWK copied over
 STA XX15+5             ; zsign 6 members
 LDA XX18
 STA XX15               ; xscaled
 LDA XX18+2
 STA XX15+1             ; xsign
 LDA XX18+3
 STA XX15+2             ; yscaled
 LDA XX18+5
 STA XX15+3             ; ysign
 LDA XX18+6
 STA XX15+4             ; zscaled
 JSR LL51               ; XX12=XX15.XX16  each vector is 16-bit x,y,z
 LDA XX12
 STA XX18               ; load result back in
 LDA XX12+1
 STA XX18+2             ; xsg
 LDA XX12+2
 STA XX18+3
 LDA XX12+3
 STA XX18+5             ; ysg
 LDA XX12+4
 STA XX18+6
 LDA XX12+5
 STA XX18+8             ; zsg

 LDY #4                 ; Hull byte#4 = lsb of offset to normals
 LDA (XX0),Y
 CLC                    ; lo
 ADC XX0
 STA V                  ; will point to start of normals
 LDY #17                ; Hull byte#17 = hsb of offset to normals
 LDA (XX0),Y
 ADC XX0+1
 STA V+1                ; hi of pointer to normals data
 LDY #0                 ; byte#0 of normal

.LL86                   ; counter Y/4 go through all normals

 LDA (V),Y
 STA XX12+1             ; byte#0
 AND #31                ; lower 5 bits are face visibility
 CMP XX4
 BCS LL87               ; >= XX4 visibility, skip over jump LL88
 TYA                    ; face*4 count
 LSR A                  ; else visible
 LSR A                  ; counter/4
 TAX                    ; Xreg is normal count
 LDA #255               ; visible face
 STA XX2,X
 TYA                    ; next face*4
 ADC #4                 ; +=4
 TAY                    ; Yreg +=4 is next normal
 JMP LL88               ; to near end of normal's visibility loop

.LL87                   ; normal visibility>= XX4

 LDA XX12+1             ; byte#0 of normal
 ASL A                  ; get sign y
 STA XX12+3
 ASL A                  ; get sign z
 STA XX12+5
 INY                    ; byte#1 of normal
 LDA (V),Y
 STA XX12               ; xnormal lo
 INY                    ; byte#2 of normal
 LDA (V),Y
 STA XX12+2             ; ynormal lo
 INY                    ; byte#3 of normal
 LDA (V),Y
 STA XX12+4             ; znormal lo
 LDX XX17               ; kept Scale required
 CPX #4                 ; is XX17 < 4 ?
 BCC LL92               ; scale required is Quite close

.LL143                  ; Face offset<<PV \ their comment \ far enough away, use XX18.

 LDA XX18               ; xlo
 STA XX15
 LDA XX18+2             ; xsg
 STA XX15+1
 LDA XX18+3             ; ylo
 STA XX15+2
 LDA XX18+5             ; ysg
 STA XX15+3
 LDA XX18+6             ; zlo
 STA XX15+4
 LDA XX18+8             ; zsg
 STA XX15+5
 JMP LL89               ; XX15(6) ready, down to START.

.ovflw                  ; overflow from below, reduce xx18+0,3,6

 LSR XX18               ; x_lo/2
 LSR XX18+6             ; z_lo/2
 LSR XX18+3             ; y_lo/2
 LDX #1                 ; scale finished

.LL92                   ; arrive if Quite close, with scale in Xreg.  Normals translate.

 LDA XX12               ; xnormal lo
 STA XX15
 LDA XX12+2             ; ynormal lo
 STA XX15+2
 LDA XX12+4             ; znormal lo

.LL93

 DEX                    ; scale--
 BMI LL94               ; exit, Scale done.
 LSR XX15               ; counter X
 LSR XX15+2             ; ynormal lo/2
 LSR A                  ; znormal lo/2
 DEX                    ; reduce scale
 BPL LL93+3             ; loop to lsr xx15

.LL94                   ; Scale done.

 STA R                  ; znormal  XX15+4
 LDA XX12+5             ; zsg
 STA S                  ; z_hi to translate
 LDA XX18+6             ; z_lo
 STA Q
 LDA XX18+8             ; zsg
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 BCS ovflw              ; up to overflow, reduce xx18+0,3,6

 STA XX15+4             ; new z
 LDA S                  ; maybe new sign
 STA XX15+5             ; zsg

 LDA XX15
 STA R                  ; xnormal
 LDA XX12+1             ; xsg
 STA S                  ; x_hi to translate

 LDA XX18               ; x_lo
 STA Q
 LDA XX18+2             ; xsg
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 BCS ovflw              ; up to overflow, reduce xx18+0,3,6
 STA XX15               ; new x
 LDA S                  ; maybe new sign
 STA XX15+1             ; xsg
 LDA XX15+2
 STA R                  ; ynormal
 LDA XX12+3             ; ysg
 STA S                  ; y_hi to translate
 LDA XX18+3             ; y_lo
 STA Q
 LDA XX18+5             ; ysg
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 BCS ovflw              ; up to overflow, reduce xx18+0,3,6
 STA XX15+2             ; new y
 LDA S                  ; maybe new sign
 STA XX15+3             ; ysg

.LL89                   ; START also arrive from LL143  Face offset<<PV  XX15(6) ready
                        ; Calculate 3D dot product  XX12 . XX15 for (x,y,z)

 LDA XX12               ; xnormal lo
 STA Q
 LDA XX15
 JSR FMLTU              ; A=A*Q/256unsg
 STA T                  ; x-dot
 LDA XX12+1
 EOR XX15+1
 STA S                  ; x-sign
 LDA XX12+2             ; ynormal lo
 STA Q
 LDA XX15+2
 JSR FMLTU              ; A=A*Q/256unsg
 STA Q                  ; y-dot
 LDA T                  ; x-dot
 STA R
 LDA XX12+3             ; ysg
 EOR XX15+3
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 STA T                  ; xdot+ydot
 LDA XX12+4             ; znormal lo
 STA Q
 LDA XX15+4
 JSR FMLTU              ; A=A*Q/256unsg
 STA Q                  ; zdot
 LDA T
 STA R                  ; xdot+ydot
 LDA XX15+5
 EOR XX12+5             ; hi sign
 JSR LL38               ; BADD(S)A=R+Q(SA) \ 1byte add (subtract)
 PHA                    ; push xdot+ydot+zdot
 TYA                    ; normal_count *4 so far
 LSR A
 LSR A                  ; /=4
 TAX                    ; normal index
 PLA                    ; xdot+ydot+zdot
 BIT S                  ; maybe new sign
 BMI P%+4               ; if -ve then keep Acc
 LDA #0                 ; else face not visible
 STA XX2,X              ; face visibility
 INY                    ; Y now taken up by a total of 4

.LL88                   ; near end of normals visibility loop

 CPY XX20               ; number of normals*4
 BCS LL42               ; If Y >= XX20 all normals' visibilities set, onto Transpose.
 JMP LL86               ; loop normals visibility Y

                        ; -- All normals' visibilities now set in XX2,X
.LL42                   ; DO nodeX-Ycoords \ their comment  \  TrnspMat

 LDY XX16+2             ; Transpose Matrix
 LDX XX16+3
 LDA XX16+6
 STA XX16+2
 LDA XX16+7
 STA XX16+3
 STY XX16+6
 STX XX16+7
 LDY XX16+4
 LDX XX16+5
 LDA XX16+12
 STA XX16+4
 LDA XX16+13
 STA XX16+5
 STY XX16+12
 STX XX16+13
 LDY XX16+10
 LDX XX16+11
 LDA XX16+14
 STA XX16+10
 LDA XX16+15
 STA XX16+11
 STY XX16+14
 STX XX16+15

\XX16 got INWK 9..21..26 up at LL15  . The ROTMAT has 18 bytes, for 3x3 matrix
\XX16_lsb[   0  2  4    highest XX16 done below is 5, then X taken up by 6, Y taken up by 2.
\            6  8 10
\	    12 14 16=0 ?]

 LDY #8                 ; Hull byte#8 = number of vertices *6
 LDA (XX0),Y
 STA XX20
 LDA XX0                ; pointer to ship type data
 CLC                    ; build
 ADC #20                ; vertex data fixed offset 
 STA V                  ; pointer to start of hull vertices
 LDA XX0+1
 ADC #0                 ; any carry
 STA V+1
 LDY #0                 ; index for XX3 heap
 STY CNT
}

.LL48                   ; Start loop on Nodes for visibility, each node has 4 faces associated with it.
{
 STY XX17               ; vertex*6 counter
 LDA (V),Y
 STA XX15               ; xlo
 INY                    ; vertex byte#1
 LDA (V),Y
 STA XX15+2
 INY                    ; vertex byte#2
 LDA (V),Y
 STA XX15+4
 INY                    ; vertex byte#3
 LDA (V),Y
 STA T                  ; sign bits of vertex
 AND #31                ; visibility
 CMP XX4
 BCC LL49-3             ; if yes jmp LL50, next vertex.
 INY                    ; vertex byte#4, first 2 faces
 LDA (V),Y
 STA P                  ; two 4-bit indices 0:15 into XX2 for 2 of the 4 normals
 AND #15                ; face 1
 TAX                    ; face visibility index
 LDA XX2,X
 BNE LL49               ; vertex is visible
 LDA P                  ; restore
 LSR A
 LSR A
 LSR A
 LSR A                  ; hi nibble
 TAX                    ; face 2
 LDA XX2,X
 BNE LL49               ; vertex is visible
 INY                    ; vertex byte#5, other 2 faces
 LDA (V),Y
 STA P                  ; two 4-bit indices 0:15 into XX2
 AND #15                ; face 3
 TAX                    ; face visibility index
 LDA XX2,X
 BNE LL49               ; vertex is visible
 LDA P                  ; restore
 LSR A
 LSR A
 LSR A
 LSR A                  ; hi nibble
 TAX                    ; face 4
 LDA XX2,X
 BNE LL49               ; vertex is visible
 JMP LL50               ; both arrive here \ LL49-3 \ next vertex.

                        ; This jump can only happen if got 4 zeros from XX2 normals visibility.
.LL49                   ; Else vertex is visible, update info on XX3 node heap.

 LDA T                  ; 4th byte read for vertex, sign bits.
 STA XX15+1
 ASL A                  ; y sgn
 STA XX15+3
 ASL A                  ; z sgn
 STA XX15+5
 JSR LL51               ; XX12=XX15.XX16   Rotated.
 LDA XX1+2              ; x-sign
 STA XX15+2
 EOR XX12+1             ; rotated xnode hi
 BMI LL52               ; hop as -ve x sign
 CLC                    ; else x +ve
 LDA XX12               ; rotated xnode lo
 ADC XX1                ; xorg lo
 STA XX15               ; new x
 LDA XX1+1              ; INWK+1
 ADC #0                 ; hi x
 STA XX15+1
 JMP LL53               ; Onto y

.LL52                   ; -ve x sign

 LDA XX1                ; xorg lo
 SEC
 SBC XX12               ; rotated xnode lo
 STA XX15               ; new x
 LDA XX1+1              ; INWK+1
 SBC #0                 ; hi x
 STA XX15+1
 BCS LL53               ; usually ok Onto y
 EOR #&FF               ; else fix x negative
 STA XX15+1
 LDA #1                 ; negate
 SBC XX15
 STA XX15
 BCC P%+4               ; skip x hi
 INC XX15+1
 LDA XX15+2
 EOR #128               ; flip xsg
 STA XX15+2

.LL53                   ; Both x signs arrive here, Onto y

 LDA XX1+5              ; y-sign
 STA XX15+5
 EOR XX12+3             ; rotated ynode hi
 BMI LL54               ; hop as -ve y sign
 CLC                    ; else y +ve
 LDA XX12+2             ; rotated ynode lo
 ADC XX1+3              ; yorg lo
 STA XX15+3             ; new y
 LDA XX1+4
 ADC #0                 ; hi y
 STA XX15+4
 JMP LL55               ; Onto z

.LL54                   ; -ve y sign

 LDA XX1+3              ; yorg lo
 SEC
 SBC XX12+2             ; rotated ynode lo
 STA XX15+3             ; new ylo
 LDA XX1+4
 SBC #0                 ; hi y

 STA XX15+4
 BCS LL55               ; usually ok Onto z
 EOR #255               ; else fix y negative
 STA XX15+4
 LDA XX15+3
 EOR #255               ; negate y lo
 ADC #1
 STA XX15+3
 LDA XX15+5
 EOR #128               ; flip ysg
 STA XX15+5
 BCC LL55               ; Onto z
 INC XX15+4

.LL55                   ; Both y signs arrive here, Onto z

 LDA XX12+5             ; rotated znode hi
 BMI LL56               ; -ve Z node
 LDA XX12+4             ; rotated znode lo
 CLC
 ADC XX1+6              ; zorg lo
 STA T                  ; z new lo
 LDA XX1+7
 ADC #0                 ; hi
 STA U                  ; z new hi
 JMP LL57               ; Node additions done, z = U.T case
}

\ ******************************************************************************
\ Subroutine: LL61
\
\ Doing additions and scalings for each visible node around here
\ ******************************************************************************

                        ; Doing additions and scalings for each visible node around here
.LL61                   ; Handling division R=A/Q for case further down

 LDX Q
 BEQ LL84               ; div by zero div error
 LDX #0

.LL63                   ; roll Acc count Xreg

 LSR A
 INX                    ; counts required will be stored in S
 CMP Q
 BCS LL63               ; loop back if Acc >= Q
 STX S
 JSR LL28               ; BFRDIV R=A*256/Q byte from remainder of division
 LDX S                  ; restore Xcount
 LDA R                  ; remainder

.LL64                   ; counter Xreg

 ASL A                  ; lo boost
 ROL U                  ; hi
 BMI LL84               ; bit7 set, overflowed, div error
 DEX                    ; bring X back down
 BNE LL64               ; loop X
 STA R                  ; remainder
 RTS

.LL84                   ; div error  R=U=#50

 LDA #50
 STA R
 STA U
 RTS

.LL62                   ; Arrive from LL65 just below, screen for -ve RU onto XX3 heap, index X=CNT

 LDA #128               ; x-screen mid-point
 SEC                    ; xcoord lo
 SBC R
 STA XX3,X
 INX                    ; hi
 LDA #0                 ; xcoord hi
 SBC U
 STA XX3,X
 JMP LL66               ; xccord shoved, go back down

.LL56                   ; Enter XX12+5 -ve Z node case  from above

 LDA XX1+6              ; z org lo
 SEC
 SBC XX12+4             ; rotated z node lo
 STA T
 LDA XX1+7              ; zhi
 SBC #0
 STA U
 BCC LL140              ; underflow, make node close
 BNE LL57               ; Enter Node additions done, UT=z
 LDA T                  ; restore z lo
 CMP #4                 ; >= 4 ?
 BCS LL57               ; zlo big enough, Enter Node additions done.

.LL140                  ; else make node close

 LDA #0                 ; hi
 STA U
 LDA #4                 ; lo
 STA T

.LL57                   ; Enter Node additions done, z=T.U set up from LL55

 LDA U                  ; z hi
 ORA XX15+1             ; x hi
 ORA XX15+4             ; y hi
 BEQ LL60               ; exit loop down once hi U rolled to 0
 LSR XX15+1
 ROR XX15
 LSR XX15+4
 ROR XX15+3
 LSR U                  ; z hi
 ROR T                  ; z lo
 JMP LL57               ; loop U

.LL60                   ; hi U rolled to 0, exited loop above.

 LDA T
 STA Q                  ; zdist lo
 LDA XX15               ; rolled x lo
 CMP Q
 BCC LL69               ; if xdist < zdist hop over jmp to small x angle
 JSR LL61               ; visit up  R = A/Q = x/z
 JMP LL65               ; hop over small xangle

.LL69                   ; small x angle

 JSR LL28               ; BFRDIV R=A*256/Q byte for remainder of division

.LL65                   ; both continue for scaling based on z

 LDX CNT                ; index for XX3 heap
 LDA XX15+2             ; sign of X dist
 BMI LL62               ; up, -ve Xdist, RU screen onto XX3 heap
 LDA R                  ; xscaled
 CLC                    ; xcoord lo to XX3 heap
 ADC #128               ; x screen mid-point
 STA XX3,X
 INX                    ; x hi onto node heap
 LDA U
 ADC #0                 ; any carry to hi
 STA XX3,X

.LL66                   ; also from LL62, XX3 node heap has xscreen node so far.

 TXA                    ; Onto y coord
 PHA                    ; push XX3 heap pointer
 LDA #0                 ; y hi = 0
 STA U
 LDA T
 STA Q                  ; zdist lo
 LDA XX15+3             ; rolled y low
 CMP Q
 BCC LL67               ; if ydist < zdist hop to small yangle

 JSR LL61               ; else visit up R = A/Q = y/z
 JMP LL68               ; hop over small y yangle

.LL70                   ; arrive from below, Yscreen for -ve RU onto XX3 node heap, index X=CNT

 LDA #Y                 ; #Y = #96 mid Yscreen \ also rts at LL70+1
 CLC                    ; ycoord lo to XX3 node heap
 ADC R                  ; yscaled
 STA XX3,X
 INX                    ; y hi to node heap
 LDA #0                 ; any carry to y hi
 ADC U
 STA XX3,X
 JMP LL50               ; down XX3 heap has yscreen node

.LL67                   ; Arrive from LL66 above if XX15+3 < Q \ small yangle

 JSR LL28               ; BFRDIV R=A*256/Q byte from remainder of division

.LL68                   ; -> &4CF5 both carry on, also arrive from LL66, yscaled based on z

 PLA                    ; restore
 TAX                    ; XX3 heap index
 INX                    ; take XX3 heap index up
 LDA XX15+5             ; rolled Ydist sign
 BMI LL70               ; up, -ve RU onto XX3 heap
 LDA #Y                 ; #Y = #96 Yscreen
 SEC                    ; subtracted yscaled and store on heap
 SBC R
 STA XX3,X
 INX                    ; y screen hi
 LDA #0                 ; any carry
 SBC U
 STA XX3,X

.LL50                   ; also from LL70, Also from  LL49-3. XX3 heap has yscreen, Next vertex.

 CLC                    ; reload XX3 heap index base
 LDA CNT
 ADC #4                 ; +=4, next 16bit xcoord,ycoord pair on XX3 heap
 STA CNT
 LDA XX17               ; vertex*6 count
 ADC #6                 ; +=6
 TAY                    ; Y taken up to next vertex
 BCS LL72               ; down Loaded if maxed out number of vertices (42)
 CMP XX20               ; number of vertices*6
 BCS LL72               ; done Loaded if all vertices done, exit loop
 JMP LL48               ; loop Y back to next vertex at transpose matrix

.LL72                   ; XX3 node heap already loaded with 16bit xy screen

 LDA XX1+31             ; display/exploding state|missiles
 AND #32                ; bit5 of mask
 BEQ EE31               ; if zero no explosion
 LDA XX1+31
 ORA #8                 ; else set bit3 to erase old line
 STA XX1+31
 JMP DOEXP              ; explosion

.EE31                   ; no explosion

 LDA #8                 ; mask bit 3 set of
 BIT XX1+31             ; exploding/display state|missiles
 BEQ LL74               ; clear is hop to do New lines
 JSR LL155              ; else erase lines in XX19 heap at LINEstr down
 LDA #8                 ; set bit3, as new lines

.LL74                   ; do New lines

 ORA XX1+31
 STA XX1+31
 LDY #9                 ; Hull byte#9, number of edges
 LDA (XX0),Y
 STA XX20               ; number of edges
 LDY #0                 ; ship lines heap offset to 0 for XX19
 STY U
 STY XX17               ; edge counter
 INC U                  ; ship lines heap offset = 1
 BIT XX1+31
 BVC LL170              ; bit6 of display state clear (laser not firing) \ Calculate new lines
 LDA XX1+31
 AND #&BF               ; else laser is firing, clear bit6.
 STA XX1+31
 LDY #6                 ; Hull byte#6, gun vertex*4
 LDA (XX0),Y
 TAY                    ; index to gun on XX3 heap
 LDX XX3,Y
 STX XX15               ;  x1 lo
 INX                    ; was heap entry updated from #255?
 BEQ LL170              ; skip the rest (laser node not visible)
 LDX XX3+1,Y
 STX XX15+1             ;  x1 hi
 INX                    ; was heap entry updated from #255?
 BEQ LL170              ; skip the rest (laser node not visible)
 LDX XX3+2,Y
 STX XX15+2             ; y1 lo
 LDX XX3+3,Y
 STX XX15+3             ; y1 hi
 LDA #0                 ; x2 lo.hi = 0
 STA XX15+4
 STA XX15+5
 STA XX12+1             ; y2 high = 0
 LDA XX1+6              ; z ship lo
 STA XX12               ; y2 low = z-lo
 LDA XX1+2              ; xship-sgn
 BPL P%+4               ; skip dec
 DEC XX15+4             ; else x2 lo =#255 to right across screen
 JSR LL145              ; clip test on XX15 XX12 vector
 BCS LL170              ; if carry set skip the rest (laser not firing)
 LDY U                  ; ship lines heap offset
 LDA XX15               ; push (now clipped) to clipped lines ship heap
 STA (XX19),Y
 INY
 LDA XX15+1             ; Y1
 STA (XX19),Y
 INY
 LDA XX15+2             ; X2
 STA (XX19),Y
 INY
 LDA XX15+3             ; Y2
 STA (XX19),Y
 INY
 STY U                  ; ship lines heap offset updated

.LL170                  ; (laser not firing) \ Calculate new lines	\ their comment

 LDY #3                 ; Hull byte#3 edges lo
 CLC                    ; build base pointer
 LDA (XX0),Y
 ADC XX0
 STA V                  ; is pointer to where edges data start
 LDY #16                ; Hull byte #16 edges hi
 LDA (XX0),Y
 ADC XX0+1
 STA V+1
 LDY #5                 ; Hull byte#5 is 4*MAXLI + 1, for ship lines stack
 LDA (XX0),Y
 STA T1                 ; 4*MAXLI + 1, edge counter limit.
 LDY XX17               ; edge counter

.LL75                   ; count Visible edges

 LDA (V),Y              ; edge data byte#0
 CMP XX4                ; visibility
 BCC LL78               ; edge not visible
 INY
 LDA (V),Y              ; edge data byte#1
 INY                    ; Y = 2
 STA P                  ; store byte#1
 AND #15
 TAX                    ; lower 4 bits are face1
 LDA XX2,X              ; face visibility
 BNE LL79               ; hop down to Visible edge
 LDA P                  ; restore byte#1
 LSR A
 LSR A
 LSR A
 LSR A                  ; /=16 upper nibble
 TAX                    ; upper 4 bits are face2
 LDA XX2,X              ; face visibility
 BEQ LL78               ; edge not visible

.LL79                   ; Visible edge

 LDA (V),Y              ; edge data byte#2
 TAX                    ; index into node heap for first node of edge
 INY                    ; Y = 3
 LDA (V),Y              ; edge data byte#3
 STA Q                  ; index into node heap for other node of edge
 LDA XX3+1,X
 STA XX15+1             ; x1 hi
 LDA XX3,X
 STA XX15               ; x1 lo
 LDA XX3+2,X
 STA XX15+2             ; y1 lo
 LDA XX3+3,X
 STA XX15+3             ; y1 hi
 LDX Q                  ; other index into node heap for second node
 LDA XX3,X
 STA XX15+4             ; x2 lo
 LDA XX3+3,X
 STA XX12+1             ; y2 hi
 LDA XX3+2,X
 STA XX12               ; y2 lo
 LDA XX3+1,X
 STA XX15+5             ; x2 hi
 JSR LL147              ; CLIP2, take care of swop and clips
 BCS LL78               ; jmp LL78 edge not visible

.LL80                   ; Shove visible edge onto XX19 ship lines heap counter U

 LDY U                  ; clipped edges heap index
 LDA XX15               ; X1
 STA (XX19),Y
 INY
 LDA XX15+1             ; Y1
 STA (XX19),Y
 INY
 LDA XX15+2             ; X2
 STA (XX19),Y
 INY
 LDA XX15+3             ; Y2
 STA (XX19),Y
 INY
 STY U                  ; clipped ship lines heap index
 CPY T1                 ; >=  4*MAXLI + 1 counter limit
 BCS LL81               ; hop over jmp to Exit edge data loop

.LL78                   ; also arrive here if Edge not visible, loop next data edge.

 INC XX17               ; edge counter
 LDY XX17
 CPY XX20               ; number of edges
 BCS LL81               ; hop over jmp to Exit edge data loop
 LDY #0                 ; else next edge
 LDA V
 ADC #4                 ; take edge data pointer up to next edge
 STA V
 BCC ll81               ; skip inc hi
 INC V+1

.ll81                   ; skip inc hi

 JMP LL75               ; Loop Next Edge

.LL81                   ; Exited edge data loop

 LDA U                  ; clipped ship lines heap index for (XX19),Y
 LDY #0                 ; first entry in ship edges heap is number of bytes
 STA (XX19),Y

.LL155                  ; CLEAR LINEstr visited by EE31 when XX3 heap ready to draw/erase lines in XX19 heap.

 LDY #0                 ; number of bytes
 LDA (XX19),Y
 STA XX20               ; valid length of heap XX19
 CMP #4                 ; if < 4 then
 BCC LL118-1            ; rts
 INY                    ; #1

.LL27                   ; counter Y, Draw clipped lines in XX19 ship lines heap

 LDA (XX19),Y
 STA XX15               ; X1
 INY
 LDA (XX19),Y
 STA XX15+1             ; Y1
 INY
 LDA (XX19),Y
 STA XX15+2             ; X2
 INY
 LDA (XX19),Y
 STA XX15+3             ; Y2
 JSR LL30               ; draw line using (X1,Y1), (X2,Y2)
 INY                    ; +=4
 CPY XX20               ; valid number of edges in heap XX19
 BCC LL27               ; loop Y
\LL82
 RTS                    ; --- Wireframe end  \ LL118-1

\ ******************************************************************************
\ Subroutine: LL118
\
\ Trim XX15,XX15+2 to screen grad=XX12+2 for CLIP
\ ******************************************************************************

.LL118                  ; Trim XX15,XX15+2 to screen grad=XX12+2 for CLIP
{
 LDA XX15+1             ; x1 hi
 BPL LL119              ; x1 hi+ve skip down
 STA S                  ; else x1 hi -ve
 JSR LL120              ; X1<0 \ their comment \ X.Y = x1_lo.S *  M/256
 TXA                    ; step Y1 lo
 CLC
 ADC XX15+2             ; Y1 lo 
 STA XX15+2
 TYA                    ; step Y1 hi
 ADC XX15+3             ; Y1 hi
 STA XX15+3
 LDA #0                 ; xleft min
 STA XX15               ; X1 lo 
 STA XX15+1             ; X1 = 0
 TAX                    ; Xreg = 0, will skip to Ytrim

.LL119                  ; x1 hi +ve from LL118

 BEQ LL134              ; if x1 hi = 0 skip to Ytrim
 STA S                  ; else x1 hi > 0
 DEC S                  ; x1 hi-1
 JSR LL120              ; X1>255 \ their comment \ X.Y = x1lo.S *  M/256
 TXA                    ; step Y1 lo
 CLC
 ADC XX15+2             ; Y1 lo 
 STA XX15+2
 TYA                    ; step Y1 hi
 ADC XX15+3             ; Y1 hi
 STA XX15+3
 LDX #&FF               ; xright max
 STX XX15               ; X1 lo = 255
 INX                    ; = 0
 STX XX15+1             ; X1 hi

.LL134                  ; Ytrim

 LDA XX15+3             ; y1 hi
 BPL LL135              ; y1 hi +ve
 STA S                  ; else y1 hi -ve
 LDA XX15+2             ; y1 lo
 STA R                  ; Y1<0 their comment
 JSR LL123              ; X.Y=R.S*256/M (M=grad.)   \where 256/M is gradient
 TXA                    ; step X1 lo
 CLC
 ADC XX15               ; X1 lo
 STA XX15
 TYA                    ; step X1 hi
 ADC XX15+1             ; X1 hi
 STA XX15+1
 LDA #0                 ; Y bottom min
 STA XX15+2             ; Y1 lo
 STA XX15+3             ; Y1 hi = 0

.LL135                  ; y1 hi +ve from LL134
\BNE LL139
 LDA XX15+2             ; Y1 lo
 SEC
 SBC #Y*2               ; #Y*2  screen y height
 STA R                  ; Y1>191 their comment
 LDA XX15+3             ; Y1 hi
 SBC #0
 STA S
 BCC LL136              ; failed, rts

.LL139

 JSR LL123              ; X.Y=R.S*256/M (M=grad.)   \where 256/M is gradient
 TXA                    ; step X1 lo
 CLC
 ADC XX15               ; X1 lo
 STA XX15
 TYA                    ; step X1 hi
 ADC XX15+1             ; X1 hi
 STA XX15+1
 LDA #Y*2-1             ; #Y*2-1 = y top max
 STA XX15+2             ; Y1 lo
 LDA #0                 ; Y1 hi = 0
 STA XX15+3             ; Y1 = 191

.LL136                  ; rts

 RTS                    ; -- trim for CLIP done
}

\ ******************************************************************************
\ Subroutine: LL120
\
\ X.Y=x1lo.S*M/256  	\ where M/256 is gradient
\ ******************************************************************************

.LL120                  ; X.Y=x1lo.S*M/256  	\ where M/256 is gradient
{
 LDA XX15               ; x1 lo
 STA R

\.LL120

 JSR LL129              ; RS = abs(x1=RS) and return with
 PHA                    ; store Acc = hsb x1 EOR quadrant_info, Q = (1/)gradient
 LDX T                  ; steep toggle = 0 or FF for steep/shallow down
 BNE LL121              ; down Steep
}

.LL122                  ; else Shallow return step, also arrive from LL123 for steep stepX
{
 LDA #0
 TAX
 TAY                    ; all = 0 at start
 LSR S                  ; hi /=2
 ROR R                  ; lo /=2
 ASL Q                  ; double 1/gradient
 BCC LL126              ; hop first half of loop

.LL125                  ; roll Q up

 TXA                    ; increase step
 CLC
 ADC R
 TAX                    ; lo
 TYA                    ; hi
 ADC S
 TAY                    ; hi

.LL126                  ; first half of loop done

 LSR S                  ; hi /=2
 ROR R                  ; lo /=2
 ASL Q                  ; double 1/gradient
 BCS LL125              ; if gradient not too small, loop Q
 BNE LL126              ; half loop as Q not emptied yet.
 PLA                    ; restore quadrant info
 BPL LL133              ; flip XY sign
 RTS
}

\ ******************************************************************************
\ Subroutine: LL123
\
\ X.Y=R.S*256/M (M=grad.)	\ where 256/M is gradient
\ ******************************************************************************

.LL123                  ; X.Y=R.S*256/M (M=grad.)	\ where 256/M is gradient
{
 JSR LL129              ; RS = abs(y1=RS) and return with
 PHA                    ; store  Acc = hsb x1 EOR hi, Q = (1/)gradient
 LDX T                  ; steep toggle = 0 or FF for steep/shallow up
 BNE LL122              ; up Shallow
}

.LL121                  ; T = #&FF for Steep return stepY, shallow stepX
{
 LDA #255
 TAY
 ASL A                  ; #&FE
 TAX                    ; Step X.Y= &FFFE at start

.LL130                  ; roll Y

 ASL R                  ; lo *=2
 ROL S                  ; hi *=2
 LDA S
 BCS LL131              ; if S overflowed skip Q test and do subtractions
 CMP Q
 BCC LL132              ; if S <  Q = 256/gradient skip subtractions

.LL131                  ; skipped Q test

 SBC Q
 STA S                  ; lo
 LDA R
 SBC #0                 ; hi
 STA R
 SEC

.LL132                  ; skipped subtractions

 TXA                    ; increase step
 ROL A
 TAX                    ; stepX lo
 TYA
 ROL A
 TAY                    ; stepX hi
 BCS LL130              ; loop Y if bit fell out of Y
 PLA                    ; restore quadrant info
 BMI LL128              ; down rts
}

.LL133                  ; flip XY sign, quadrant info +ve in LL120 arrives here too
{
 TXA
 EOR #&FF
\CLC
 ADC #1
 TAX                    ; flip sign of x
 TYA
 EOR #&FF
 ADC #0
 TAY                    ; flip sign of y
}

.LL128
{
 RTS
}

\ ******************************************************************************
\ Subroutine: LL129
\
\ RS = abs(RS) and return Acc = hsb x1 EOR hi, Q = (1/)gradient
\ ******************************************************************************

.LL129                  ; RS = abs(RS) and return Acc = hsb x1 EOR hi, Q = (1/)gradient
{
 LDX XX12+2             ; gradient
 STX Q
 LDA S                  ; hi
 BPL LL127              ; hop to eor
 LDA #0                 ; else flip sign of R
 SEC
 SBC R
 STA R
 LDA S
 PHA                    ; push old S
 EOR #255               ; flip S
 ADC #0
 STA S
 PLA                    ; pull old S for eor

.LL127

 EOR XX12+3             ; Acc ^= quadrant info
 RTS                    ; -- CLIP, bounding box is now done,
}

\ ******************************************************************************
\ Subroutine: LL145
\
\ CLIP  XX15 XX12 line
\ ******************************************************************************

.LL145                  ; -> &4E19  CLIP  XX15 XX12 line
{
                        ; also called by BLINE, waiting for (X1,Y1), (X2,Y2) to draw a line.
                        ; Before clipping,  XX15(0,1) was x1.  XX15(2,3) was y1. XX15(4,5) was x2. XX12(0,1) was y2.

 LDA #0
 STA SWAP
 LDA XX15+5             ; x2 hi
}

.LL147                  ; CLIP2 arrives from LL79 to do swop and clip
{
 LDX #Y*2-1             ; #Y*2-1 yClip = screen height
 ORA XX12+1             ; y2 hi
 BNE LL107              ; skip yClip
 CPX XX12               ; is screen hight < y2 lo ?
 BCC LL107              ; if yes, skip yClip
 LDX #0                 ; else yClip = 0

.LL107                  ; skipped yClip

 STX XX13               ; yClip
 LDA XX15+1             ; x1 hi
 ORA XX15+3             ; y1 hi
 BNE LL83               ; no hi bits in coord 1 present
 LDA #Y*2-1             ; #Y*2-1  screen height
 CMP XX15+2             ; y1 lo
 BCC LL83               ; if screen height < y1 lo skip A top
 LDA XX13               ; yClip
 BNE LL108              ; hop down, yClip not zero

.LL146                  ; Finished clipping, Shuffle XX15 down to (X1,Y1) (X2,Y2)

 LDA XX15+2             ; y1 lo
 STA XX15+1             ; new Y1
 LDA XX15+4             ; x2 lo
 STA XX15+2             ; new X2
 LDA XX12               ; y2 lo
 STA XX15+3             ; new Y2
 CLC                    ; valid to plot is in XX15(0to3)
 RTS                    ; 2nd pro different, it swops based on swop flag around here.

.LL109                  ; clipped line Not visible

 SEC
 RTS

.LL108                  ; arrived as yClip not zero in LL107 clipping

 LSR XX13               ; yClip = Ymid

.LL83                   ; also arrive from LL107 if bits in hi present or y1_lo > screen height, A top

 LDA XX13               ; yClip
 BPL LL115              ; yClip < 128
 LDA XX15+1             ; x1 hi
 AND XX15+5             ; x2 hi
 BMI LL109              ; clipped line Not visible
 LDA XX15+3             ; y1 hi
 AND XX12+1             ; y2 hi
 BMI LL109              ; clipped line Not visible
 LDX XX15+1             ; x1 hi
 DEX
 TXA                    ; Acc = x1 hi -1
 LDX XX15+5             ; x2 hi
 DEX
 STX XX12+2             ; x2 hi --
 ORA XX12+2             ; (x1 hi -1) or (x2 hi -1)
 BPL LL109              ; clipped line not visible
 LDA XX15+2             ; y1 lo
 CMP #Y*2               ; #Y*2  screen height, maybe carry set
 LDA XX15+3             ; y1 hi
 SBC #0                 ; any carry
 STA XX12+2             ; y1 hi--
 LDA XX12               ; y2 lo
 CMP #Y*2               ; #Y*2 screen height, maybe carry set
 LDA XX12+1             ; y2 hi
 SBC #0                 ; any carry
 ORA XX12+2             ; (y1 hi -1) or (y2 hi -1)
 BPL LL109              ; clipped line Not visible

.LL115                  ; also arrive from LL83 with yClip < 128 need to trim.

 TYA                    ; index for edge data
 PHA                    ; protect offset
 LDA XX15+4             ; x2 lo
 SEC
 SBC XX15               ; x1 lo
 STA XX12+2             ; delta_x lo
 LDA XX15+5             ; x2 hi
 SBC XX15+1             ; x1 hi
 STA XX12+3             ; delta_x hi
 LDA XX12               ; y2 lo
 SEC
 SBC XX15+2             ; y1 lo
 STA XX12+4             ; delta_y lo
 LDA XX12+1             ; y2 hi
 SBC XX15+3             ; y1 hi
 STA XX12+5             ; delta_y hi
 EOR XX12+3             ; delta_x hi
 STA S                  ; quadrant relationship for gradient
 LDA XX12+5             ; delta_y hi
 BPL LL110              ; hop down if delta_y positive
 LDA #0                 ; else flip sign of delta_y
 SEC                    ; delta_y lo
 SBC XX12+4
 STA XX12+4
 LDA #0                 ; delta_y hi
 SBC XX12+5
 STA XX12+5

.LL110                  ; delta_y positive

 LDA XX12+3             ; delta_x hi
 BPL LL111              ; hop down if positive to GETgrad
 SEC                    ; else flip sign of delta_x
 LDA #0                 ; delta_x lo
 SBC XX12+2
 STA XX12+2
 LDA #0                 ; Acc will have delta_x hi +ve
 SBC XX12+3

                        ; GETgrad get Gradient for trimming
.LL111                  ; roll Acc  delta_x hi

 TAX                    ; delta_x hi
 BNE LL112              ; skip if delta_x hi not zero
 LDX XX12+5             ; delta_y hi
 BEQ LL113              ; Exit when both delta hi zero

.LL112                  ; skipped as delta_x hi not zero

 LSR A                  ; delta_x hi/=2
 ROR XX12+2             ; delta_x lo/=2

 LSR XX12+5             ; delta_y hi/=2
 ROR XX12+4             ; delta_y lo/=2
 JMP LL111              ; loop GETgrad

.LL113                  ; Exited as both delta hi zero for trimming

 STX T                  ; delta_y hi = 0
 LDA XX12+2             ; delta_x lo
 CMP XX12+4             ; delta_y lo
 BCC LL114              ; hop to STEEP as x < y
 STA Q                  ; else shallow, Q = delta_x lo
 LDA XX12+4             ; delta_y lo
 JSR LL28               ; BFRDIV R=A*256/Q = delta_y / delta_x

                        ; Use Y/X grad. \ as not steep
 JMP LL116              ; gradient now known, go a few lines down

.LL114                  ; else STEEP

 LDA XX12+4             ; delta_y lo
 STA Q
 LDA XX12+2             ; delta_x lo
 JSR LL28               ; BFRDIV R=A*256/Q = delta_x / delta_y

                        ; Use X/Y grad.
 DEC T                  ; steep toggle updated T = #&FF

.LL116                  ; arrive here for both options with known gradient

 LDA R                  ; gradient
 STA XX12+2
 LDA S                  ; quadrant info
 STA XX12+3
 LDA XX13
 BEQ LL138              ; yClip = 0 or 191?, skip bpl
 BPL LLX117             ; yClip+ve, swop nodes

.LL138                  ; yClip = 0 or or >127   need to fit x1,y1 into bounding box

 JSR LL118              ; Trim XX15,XX15+2 to screen grad=XX12+2
 LDA XX13
 BPL LL124              ; yClip+ve, finish clip

.LL117                  ; yClip > 127

 LDA XX15+1             ; x1 hi
 ORA XX15+3             ; y1 hi
 BNE LL137              ; some hi bits present, no line.
 LDA XX15+2             ; y1 lo
 CMP #Y*2               ; #Y*2  Yscreen full height
 BCS LL137              ; if y1 lo >= Yscreen,  no line.

.LLX117                 ; yClip+ve from LL116, swop nodes then trim nodes, XX12+2 = gradient, XX12+3 = quadrant info.

 LDX XX15               ; x1 lo
 LDA XX15+4             ; x2 lo
 STA XX15
 STX XX15+4
 LDA XX15+5             ; x2 hi
 LDX XX15+1             ; x1 hi
 STX XX15+5
 STA XX15+1
 LDX XX15+2             ; Onto swopping y
 LDA XX12               ; y2 lo
 STA XX15+2
 STX XX12
 LDA XX12+1             ; y2 hi
 LDX XX15+3             ; y1 hi
 STX XX12+1
 STA XX15+3             ; finished swop of (x1 y1) and (x2 y2)
 JSR LL118              ; Trim XX15,XX15+2 to screen grad=XX12+2
 DEC SWAP

.LL124                  ; also yClip+ve from LL138, finish clip

 PLA                    ; restore ship edge index
 TAY
 JMP LL146              ; up, Finished clipping, Shuffle XX15 down to (x1,y1) (x2,y2)

.LL137                  ; no line

 PLA                    ; restore ship edge index
 TAY
 SEC                    ; not visible
 RTS                    ; -- Finished clipping
}

\ ******************************************************************************
\ Save output/ELTG.bin
\ ******************************************************************************

PRINT "ELITE G"
PRINT "Assembled at ", ~CODE_G%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_G%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_G%

PRINT "S.ELTG ", ~CODE_G%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_G%
SAVE "output/ELTG.bin", CODE_G%, P%, LOAD%

\ ******************************************************************************
\ Variable: checksum0
\
\ This byte contains a checksum for the entire source file. It is populated by
\ elite-checksum.py and is used by the encryption checks in elite-loader.asm
\ (see the CHK routine in the loader for more details).
\ ******************************************************************************

.checksum0
{
SKIP 1
}

\ ******************************************************************************
\ ELITE SHIP BLUEPRINTS
\
\ Produces the binary file SHIPS.bin which gets loaded by elite-bcfs.asm.
\ ******************************************************************************

CODE_SHIPS% = P%
LOAD_SHIPS% = LOAD% + P% - CODE%

\ ******************************************************************************
\ Variable: XX21
\
\ Ship blueprints lookup table.
\ ******************************************************************************

\ The following lookup table points to the individual ship blueprints below.

.XX21

 EQUW SHIP1                         ;         1 = Sidewinder
 EQUW SHIP2                         ; COPS =  2 = Viper
 EQUW SHIP3                         ; MAM  =  3 = Mamba
 EQUW &7F00                         ;         4 = &7F00
 EQUW SHIP5                         ;         5 = Points to Cobra Mk III
 EQUW SHIP6                         ; THG  =  6 = Thargoid
 EQUW SHIP5                         ; CYL  =  7 = Cobra Mk III
 EQUW SHIP8                         ; SST  =  8 = Coriolis space station
 EQUW SHIP9                         ; MSL  =  9 = Missile
 EQUW SHIP10                        ; AST  = 10 = Asteroid
 EQUW SHIP11                        ; OIL  = 11 = Cargo
 EQUW SHIP12                        ; TGL  = 12 = Thargon
 EQUW SHIP13                        ; ESC  = 13 = Escape pod

\ ******************************************************************************
\ Ships in Elite
\ ******************************************************************************
\
\ For each ship blueprint below, the first 20 bytes define the following:
\
\ Byte #0       Maximum number of bits of debris shown when destroyed
\ Byte #1-2     Area of ship that can be locked onto by a missle (lo, hi)
\ Byte #3       Edges data offset lo (offset is from byte #0)
\ Byte #4       Faces data offset lo (offset is from byte #0)
\ Byte #5       Maximum heap size for plotting ship = 1 + 4 * max. no of
\               visible edges
\ Byte #6       Number * 4 of the vertex used for gun spike, if applicable
\ Byte #7       Explosion count = 4 * n + 6, where n = number of vertices used
\               as origins for explosion dust
\ Byte #8       Number of vertices * 6
\ Byte #10-11   Bounty awarded in Cr * 10 (lo, hi)
\ Byte #12      Number of faces * 4
\ Byte #13      Beyond this distance, show this ship as a dot
\ Byte #14      Maximum energy/shields
\ Byte #15      Maximum speed
\ Byte #16      Edges data offset hi (if this is negative (&FF) it points to
\               another ship's edge net)
\ Byte #17      Faces data offset hi
\ Byte #18      Q%: Normals are scaled by 2^Q% to make large objects' normals
\               flare out further away (see EE29)
\ Byte #19      %00 lll mmm, where bits 0-2 = number of missiles,
\               bits 3-5 = laser power

\ ******************************************************************************
\ Variable: SHIP1
\
\ Sidewinder ship blueprint
\ ******************************************************************************

.SHIP1

 EQUB &00
 EQUB &81, &10
 EQUB &50
 EQUB &8C
 EQUB &3D
 EQUB &00                           ; gun vertex = 0
 EQUB &1E
 EQUB &3C                           ; number of vertices = &3C / 6 = 10
 EQUB &0F                           ; number of edges = &0F = 15
 EQUW 50                            ; bounty = 50
 EQUB &1C                           ; number of faces = &1C / 4 = 7
 EQUB &14
 EQUB &46
 EQUB &25
 EQUB &00
 EQUB &00
 EQUB &02
 EQUB %00010000                     ; laser power = 2, missiles = 0

 EQUB &20, &00, &24, &9F, &10, &54  ; vertices data (10*6)
 EQUB &20, &00, &24, &1F, &20, &65
 EQUB &40, &00, &1C, &3F, &32, &66
 EQUB &40, &00, &1C, &BF, &31, &44
 EQUB &00, &10, &1C, &3F, &10, &32

 EQUB &00, &10, &1C, &7F, &43, &65
 EQUB &0C, &06, &1C, &AF, &33, &33
 EQUB &0C, &06, &1C, &2F, &33, &33
 EQUB &0C, &06, &1C, &6C, &33, &33
 EQUB &0C, &06, &1C, &EC, &33, &33

 EQUB &1F, &50, &00, &04            ; edges data (15*4)
 EQUB &1F, &62, &04, &08
 EQUB &1F, &20, &04, &10
 EQUB &1F, &10, &00, &10
 EQUB &1F, &41, &00, &0C

 EQUB &1F, &31, &0C, &10
 EQUB &1F, &32, &08, &10
 EQUB &1F, &43, &0C, &14
 EQUB &1F, &63, &08, &14
 EQUB &1F, &65, &04, &14

 EQUB &1F, &54, &00, &14
 EQUB &0F, &33, &18, &1C
 EQUB &0C, &33, &1C, &20
 EQUB &0C, &33, &18, &24
 EQUB &0C, &33, &20, &24

 EQUB &1F, &00, &20, &08            ; faces data (7*4)
 EQUB &9F, &0C, &2F, &06
 EQUB &1F, &0C, &2F, &06
 EQUB &3F, &00, &00, &70
 EQUB &DF, &0C, &2F, &06

 EQUB &5F, &00, &20, &08
 EQUB &5F, &0C, &2F, &06

\ ******************************************************************************
\ Variable: SHIP2
\
\ Viper ship blueprint
\ ******************************************************************************

.SHIP2

 EQUB &00
 EQUB &F9, &15
 EQUB &6E
 EQUB &BE
 EQUB &4D
 EQUB &00                           ; gun vertex = 0
 EQUB &2A
 EQUB &5A                           ; number of vertices = &5A / 6 = 15
 EQUB &14                           ; number of edges = &14 = 20
 EQUW 0                             ; bounty = 0
 EQUB &1C                           ; number of faces = &1C / 4 = 7
 EQUB &17
 EQUB &78
 EQUB &20
 EQUB &00
 EQUB &00
 EQUB &01
 EQUB %00010001                     ; laser power = 2, missiles = 1

 EQUB &00, &00, &48, &1F, &21, &43  ; vertices data (15*6)
 EQUB &00, &10, &18, &1E, &10, &22
 EQUB &00, &10, &18, &5E, &43, &55
 EQUB &30, &00, &18, &3F, &42, &66
 EQUB &30, &00, &18, &BF, &31, &66

 EQUB &18, &10, &18, &7E, &54, &66
 EQUB &18, &10, &18, &FE, &35, &66
 EQUB &18, &10, &18, &3F, &20, &66
 EQUB &18, &10, &18, &BF, &10, &66
 EQUB &20, &00, &18, &B3, &66, &66

 EQUB &20, &00, &18, &33, &66, &66
 EQUB &08, &08, &18, &33, &66, &66
 EQUB &08, &08, &18, &B3, &66, &66
 EQUB &08, &08, &18, &F2, &66, &66
 EQUB &08, &08, &18, &72, &66, &66

 EQUB &1F, &42, &00, &0C            ; edges data (20*4)
 EQUB &1E, &21, &00, &04
 EQUB &1E, &43, &00, &08
 EQUB &1F, &31, &00, &10
 EQUB &1E, &20, &04, &1C

 EQUB &1E, &10, &04, &20
 EQUB &1E, &54, &08, &14
 EQUB &1E, &53, &08, &18
 EQUB &1F, &60, &1C, &20
 EQUB &1E, &65, &14, &18

 EQUB &1F, &61, &10, &20
 EQUB &1E, &63, &10, &18
 EQUB &1F, &62, &0C, &1C
 EQUB &1E, &46, &0C, &14
 EQUB &13, &66, &24, &30

 EQUB &12, &66, &24, &34
 EQUB &13, &66, &28, &2C
 EQUB &12, &66, &28, &38
 EQUB &10, &66, &2C, &38
 EQUB &10, &66, &30, &34

 EQUB &1F, &00, &20, &00            ; faces data (7*4)
 EQUB &9F, &16, &21, &0B
 EQUB &1F, &16, &21, &0B
 EQUB &DF, &16, &21, &0B
 EQUB &5F, &16, &21, &0B

 EQUB &5F, &00, &20, &00
 EQUB &3F, &00, &00, &30

\ ******************************************************************************
\ Variable: SHIP3
\
\ Mamba ship blueprint
\ ******************************************************************************

.SHIP3

 EQUB &01                           ; debris shown = 1
 EQUB &24, &13
 EQUB &AA
 EQUB &1A
 EQUB &5D
 EQUB &00                           ; gun vertex = 0
 EQUB &22
 EQUB &96                           ; number of vertices = &96 / 6 = 25
 EQUB &1C                           ; number of edges = &1C = 28
 EQUW 150                           ; bounty = 150
 EQUB &14                           ; number of faces = &14 / 4 = 5
 EQUB &19
 EQUB &5A
 EQUB &1E
 EQUB &00
 EQUB &01
 EQUB &02
 EQUB %000010010                    ; laser power = 2, missiles = 2

 EQUB &00, &00, &40, &1F, &10, &32  ; vertices data (25*6)
 EQUB &40, &08, &20, &FF, &20, &44
 EQUB &20, &08, &20, &BE, &21, &44
 EQUB &20, &08, &20, &3E, &31, &44
 EQUB &40, &08, &20, &7F, &30, &44

 EQUB &04, &04, &10, &8E, &11, &11
 EQUB &04, &04, &10, &0E, &11, &11
 EQUB &08, &03, &1C, &0D, &11, &11
 EQUB &08, &03, &1C, &8D, &11, &11
 EQUB &14, &04, &10, &D4, &00, &00

 EQUB &14, &04, &10, &54, &00, &00
 EQUB &18, &07, &14, &F4, &00, &00
 EQUB &10, &07, &14, &F0, &00, &00
 EQUB &10, &07, &14, &70, &00, &00
 EQUB &18, &07, &14, &74, &00, &00

 EQUB &08, &04, &20, &AD, &44, &44
 EQUB &08, &04, &20, &2D, &44, &44
 EQUB &08, &04, &20, &6E, &44, &44
 EQUB &08, &04, &20, &EE, &44, &44
 EQUB &20, &04, &20, &A7, &44, &44

 EQUB &20, &04, &20, &27, &44, &44
 EQUB &24, &04, &20, &67, &44, &44
 EQUB &24, &04, &20, &E7, &44, &44
 EQUB &26, &00, &20, &A5, &44, &44
 EQUB &26, &00, &20, &25, &44, &44

 EQUB &1F, &20, &00, &04            ; edges data (28*4)
 EQUB &1F, &30, &00, &10
 EQUB &1F, &40, &04, &10
 EQUB &1E, &42, &04, &08
 EQUB &1E, &41, &08, &0C

 EQUB &1E, &43, &0C, &10
 EQUB &0E, &11, &14, &18
 EQUB &0C, &11, &18, &1C
 EQUB &0D, &11, &1C, &20
 EQUB &0C, &11, &14, &20

 EQUB &14, &00, &24, &2C
 EQUB &10, &00, &24, &30
 EQUB &10, &00, &28, &34
 EQUB &14, &00, &28, &38
 EQUB &0E, &00, &34, &38

 EQUB &0E, &00, &2C, &30
 EQUB &0D, &44, &3C, &40
 EQUB &0E, &44, &44, &48
 EQUB &0C, &44, &3C, &48
 EQUB &0C, &44, &40, &44

 EQUB &07, &44, &50, &54
 EQUB &05, &44, &50, &60
 EQUB &05, &44, &54, &60
 EQUB &07, &44, &4C, &58
 EQUB &05, &44, &4C, &5C

 EQUB &05, &44, &58, &5C
 EQUB &1E, &21, &00, &08
 EQUB &1E, &31, &00, &0C

 EQUB &5E, &00, &18, &02            ; faces data (5*4)
 EQUB &1E, &00, &18, &02
 EQUB &9E, &20, &40, &10
 EQUB &1E, &20, &40, &10
 EQUB &3E, &00, &00, &7F

\ ******************************************************************************
\ Variable: SHIP5
\
\ Cobra Mk III ship blueprint
\ ******************************************************************************

.SHIP5

 EQUB &03                           ; debris shown = 3
 EQUB &41, &23                      ; area for missile lock = &2331
 EQUB &BC                           ; edges data offset = &00BC
 EQUB &54                           ; faces data offset = &0154
 EQUB &99                           ; max. edge count = (&99 - 1) / 4 = 38
 EQUB &54                           ; gun vertex = &54 / 4 = 21
 EQUB &2A                           ; explosion count = 9, (4 * n) + 6 = &2A
 EQUB &A8                           ; number of vertices = &A8 / 6 = 28
 EQUB &26                           ; number of edges = &26 = 38
 EQUW 0                             ; bounty = 0
 EQUB &34                           ; number of faces = &34 / 4 = 13
 EQUB &32                           ; show as a dot past a distance of 50
 EQUB &96                           ; maximum energy/shields = 150
 EQUB &1C                           ; maximum speed = 28
 EQUB &00                           ; edges data offset = &00BC
 EQUB &01                           ; faces data offset = &0154
 EQUB &01                           ; normals are scaled by 2^1 = 2
 EQUB %00010011                     ; laser power = 2, missiles = 3

 EQUB &20, &00, &4C, &1F, &FF, &FF  ; vertices data (28*6)
 EQUB &20, &00, &4C, &9F, &FF, &FF
 EQUB &00, &1A, &18, &1F, &FF, &FF
 EQUB &78, &03, &08, &FF, &73, &AA
 EQUB &78, &03, &08, &7F, &84, &CC

 EQUB &58, &10, &28, &BF, &FF, &FF
 EQUB &58, &10, &28, &3F, &FF, &FF
 EQUB &80, &08, &28, &7F, &98, &CC
 EQUB &80, &08, &28, &FF, &97, &AA
 EQUB &00, &1A, &28, &3F, &65, &99

 EQUB &20, &18, &28, &FF, &A9, &BB
 EQUB &20, &18, &28, &7F, &B9, &CC
 EQUB &24, &08, &28, &B4, &99, &99
 EQUB &08, &0C, &28, &B4, &99, &99
 EQUB &08, &0C, &28, &34, &99, &99

 EQUB &24, &08, &28, &34, &99, &99
 EQUB &24, &0C, &28, &74, &99, &99
 EQUB &08, &10, &28, &74, &99, &99
 EQUB &08, &10, &28, &F4, &99, &99
 EQUB &24, &0C, &28, &F4, &99, &99

 EQUB &00, &00, &4C, &06, &B0, &BB
 EQUB &00, &00, &5A, &1F, &B0, &BB
 EQUB &50, &06, &28, &E8, &99, &99
 EQUB &50, &06, &28, &A8, &99, &99
 EQUB &58, &00, &28, &A6, &99, &99

 EQUB &50, &06, &28, &28, &99, &99
 EQUB &58, &00, &28, &26, &99, &99
 EQUB &50, &06, &28, &68, &99, &99

 EQUB &1F, &B0, &00, &04            ; edges data (38*4)
 EQUB &1F, &C4, &00, &10
 EQUB &1F, &A3, &04, &0C
 EQUB &1F, &A7, &0C, &20
 EQUB &1F, &C8, &10, &1C

 EQUB &1F, &98, &18, &1C
 EQUB &1F, &96, &18, &24
 EQUB &1F, &95, &14, &24
 EQUB &1F, &97, &14, &20
 EQUB &1F, &51, &08, &14

 EQUB &1F, &62, &08, &18
 EQUB &1F, &73, &0C, &14
 EQUB &1F, &84, &10, &18
 EQUB &1F, &10, &04, &08
 EQUB &1F, &20, &00, &08

 EQUB &1F, &A9, &20, &28
 EQUB &1F, &B9, &28, &2C
 EQUB &1F, &C9, &1C, &2C
 EQUB &1F, &BA, &04, &28
 EQUB &1F, &CB, &00, &2C

 EQUB &1D, &31, &04, &14
 EQUB &1D, &42, &00, &18
 EQUB &06, &B0, &50, &54
 EQUB &14, &99, &30, &34
 EQUB &14, &99, &48, &4C

 EQUB &14, &99, &38, &3C
 EQUB &14, &99, &40, &44
 EQUB &13, &99, &3C, &40
 EQUB &11, &99, &38, &44
 EQUB &13, &99, &34, &48

 EQUB &13, &99, &30, &4C
 EQUB &1E, &65, &08, &24
 EQUB &06, &99, &58, &60
 EQUB &06, &99, &5C, &60
 EQUB &08, &99, &58, &5C

 EQUB &06, &99, &64, &68
 EQUB &06, &99, &68, &6C
 EQUB &08, &99, &64, &6C

 EQUB &1F, &00, &3E, &1F            ; faces data (13*4)
 EQUB &9F, &12, &37, &10            ; start normals #0 = top front plate of
 EQUB &1F, &12, &37, &10            ; Cobra
 EQUB &9F, &10, &34, &0E
 EQUB &1F, &10, &34, &0E

 EQUB &9F, &0E, &2F, &00
 EQUB &1F, &0E, &2F, &00
 EQUB &9F, &3D, &66, &00
 EQUB &1F, &3D, &66, &00
 EQUB &3F, &00, &00, &50

 EQUB &DF, &07, &2A, &09
 EQUB &5F, &00, &1E, &06
 EQUB &5F, &07, &2A, &09

\ ******************************************************************************
\ Variable: SHIP6
\
\ Thargoid ship blueprint
\ ******************************************************************************

.SHIP6

 EQUB &00
 EQUB &49, &26
 EQUB &8C
 EQUB &F4
 EQUB &65
 EQUB &3C                           ; gun vertex = &3C / 4 = 15
 EQUB &26
 EQUB &78                           ; number of vertices = &78 / 6 = 20
 EQUB &1A                           ; number of edges = &1A = 26
 EQUW 500                           ; bounty = 500
 EQUB &28                           ; number of faces = &28 / 4 = 10
 EQUB &37
 EQUB &F0
 EQUB &27
 EQUB &00
 EQUB &00
 EQUB &02
 EQUB %00010110                     ; laser power = 2, missiles = 6

 EQUB &20, &30, &30, &5F, &40, &88  ; vertices data (20)
 EQUB &20, &44, &00, &5F, &10, &44
 EQUB &20, &30, &30, &7F, &21, &44
 EQUB &20, &00, &44, &3F, &32, &44
 EQUB &20, &30, &30, &3F, &43, &55

 EQUB &20, &44, &00, &1F, &54, &66
 EQUB &20, &30, &30, &1F, &64, &77
 EQUB &20, &00, &44, &1F, &74, &88
 EQUB &18, &74, &74, &DF, &80, &99
 EQUB &18, &A4, &00, &DF, &10, &99

 EQUB &18, &74, &74, &FF, &21, &99
 EQUB &18, &00, &A4, &BF, &32, &99
 EQUB &18, &74, &74, &BF, &53, &99
 EQUB &18, &A4, &00, &9F, &65, &99
 EQUB &18, &74, &74, &9F, &76, &99

 EQUB &18, &00, &A4, &9F, &87, &99
 EQUB &18, &40, &50, &9E, &99, &99
 EQUB &18, &40, &50, &BE, &99, &99
 EQUB &18, &40, &50, &FE, &99, &99
 EQUB &18, &40, &50, &DE, &99, &99

 EQUB &1F, &84, &00, &1C            ; edges data (26*4)
 EQUB &1F, &40, &00, &04
 EQUB &1F, &41, &04, &08
 EQUB &1F, &42, &08, &0C
 EQUB &1F, &43, &0C, &10

 EQUB &1F, &54, &10, &14
 EQUB &1F, &64, &14, &18
 EQUB &1F, &74, &18, &1C
 EQUB &1F, &80, &00, &20
 EQUB &1F, &10, &04, &24

 EQUB &1F, &21, &08, &28
 EQUB &1F, &32, &0C, &2C
 EQUB &1F, &53, &10, &30
 EQUB &1F, &65, &14, &34
 EQUB &1F, &76, &18, &38

 EQUB &1F, &87, &1C, &3C
 EQUB &1F, &98, &20, &3C
 EQUB &1F, &90, &20, &24
 EQUB &1F, &91, &24, &28
 EQUB &1F, &92, &28, &2C

 EQUB &1F, &93, &2C, &30
 EQUB &1F, &95, &30, &34
 EQUB &1F, &96, &34, &38
 EQUB &1F, &97, &38, &3C
 EQUB &1E, &99, &40, &44

 EQUB &1E, &99, &48, &4C

 EQUB &5F, &67, &3C, &19            ; faces data (10*4)
 EQUB &7F, &67, &3C, &19
 EQUB &7F, &67, &19, &3C
 EQUB &3F, &67, &19, &3C
 EQUB &1F, &40, &00, &00

 EQUB &3F, &67, &3C, &19
 EQUB &1F, &67, &3C, &19
 EQUB &1F, &67, &19, &3C
 EQUB &5F, &67, &19, &3C
 EQUB &9F, &30, &00, &00

\ ******************************************************************************
\ Variable: SHIP8
\
\ Coriolis space station blueprint
\ ******************************************************************************

.SHIP8

 EQUB &00
 EQUB &00, &64
 EQUB &74
 EQUB &E4
 EQUB &55
 EQUB &00                           ; gun vertex = 0
 EQUB &36
 EQUB &60                           ; number of vertices = &60 / 6 = 16
 EQUB &1C                           ; number of edges = &1C = 28
 EQUW 0                             ; bounty = 0
 EQUB &38                           ; number of faces = &38 / 4 = 14
 EQUB &78
 EQUB &F0
 EQUB &00
 EQUB &00
 EQUB &00
 EQUB &00
 EQUB &06

 EQUB &A0, &00, &A0, &1F, &10, &62  ; vertices data (16*6)
 EQUB &00, &A0, &A0, &1F, &20, &83
 EQUB &A0, &00, &A0, &9F, &30, &74
 EQUB &00, &A0, &A0, &5F, &10, &54
 EQUB &A0, &A0, &00, &5F, &51, &A6

 EQUB &A0, &A0, &00, &1F, &62, &B8
 EQUB &A0, &A0, &00, &9F, &73, &C8
 EQUB &A0, &A0, &00, &DF, &54, &97
 EQUB &A0, &00, &A0, &3F, &A6, &DB
 EQUB &00, &A0, &A0, &3F, &B8, &DC

 EQUB &A0, &00, &A0, &BF, &97, &DC
 EQUB &00, &A0, &A0, &7F, &95, &DA
 EQUB &0A, &1E, &A0, &5E, &00, &00
 EQUB &0A, &1E, &A0, &1E, &00, &00
 EQUB &0A, &1E, &A0, &9E, &00, &00

 EQUB &0A, &1E, &A0, &DE, &00, &00

 EQUB &1F, &10, &00, &0C            ; edges data (28*4)
 EQUB &1F, &20, &00, &04
 EQUB &1F, &30, &04, &08
 EQUB &1F, &40, &08, &0C
 EQUB &1F, &51, &0C, &10

 EQUB &1F, &61, &00, &10
 EQUB &1F, &62, &00, &14
 EQUB &1F, &82, &14, &04
 EQUB &1F, &83, &04, &18
 EQUB &1F, &73, &08, &18

 EQUB &1F, &74, &08, &1C
 EQUB &1F, &54, &0C, &1C
 EQUB &1F, &DA, &20, &2C
 EQUB &1F, &DB, &20, &24
 EQUB &1F, &DC, &24, &28

 EQUB &1F, &D9, &28, &2C
 EQUB &1F, &A5, &10, &2C
 EQUB &1F, &A6, &10, &20
 EQUB &1F, &B6, &14, &20
 EQUB &1F, &B8, &14, &24

 EQUB &1F, &C8, &18, &24
 EQUB &1F, &C7, &18, &28
 EQUB &1F, &97, &1C, &28
 EQUB &1F, &95, &1C, &2C
 EQUB &1E, &00, &30, &34

 EQUB &1E, &00, &34, &38
 EQUB &1E, &00, &38, &3C
 EQUB &1E, &00, &3C, &30

 EQUB &1F, &00, &00, &A0            ; faces data (14*4)
 EQUB &5F, &6B, &6B, &6B
 EQUB &1F, &6B, &6B, &6B
 EQUB &9F, &6B, &6B, &6B
 EQUB &DF, &6B, &6B, &6B

 EQUB &5F, &00, &A0, &00
 EQUB &1F, &A0, &00, &00
 EQUB &9F, &A0, &00, &00
 EQUB &1F, &00, &A0, &00
 EQUB &FF, &6B, &6B, &6B

 EQUB &7F, &6B, &6B, &6B
 EQUB &3F, &6B, &6B, &6B
 EQUB &BF, &6B, &6B, &6B
 EQUB &3F, &00, &00, &A0

\ ******************************************************************************
\ Variable: SHIP9
\
\ Missile blueprint
\ ******************************************************************************

.SHIP9

 EQUB &00
 EQUB &40, &06
 EQUB &7A
 EQUB &DA
 EQUB &51
 EQUB &00                           ; gun vertex = 0
 EQUB &0A
 EQUB &66                           ; number of vertices = &66 / 6 = 17
 EQUB &18                           ; number of edges = &18 = 24
 EQUW 0                             ; bounty = 0
 EQUB &24                           ; number of faces = &24 / 4 = 9
 EQUB &0E
 EQUB &02
 EQUB &2C
 EQUB &00
 EQUB &00
 EQUB &02
 EQUB %00000000                     ; laser power = 0, missiles = 0

 EQUB &00, &00, &44, &1F, &10, &32  ; vertices data (17*6)
 EQUB &08, &08, &24, &5F, &21, &54
 EQUB &08, &08, &24, &1F, &32, &74
 EQUB &08, &08, &24, &9F, &30, &76
 EQUB &08, &08, &24, &DF, &10, &65

 EQUB &08, &08, &2C, &3F, &74, &88
 EQUB &08, &08, &2C, &7F, &54, &88
 EQUB &08, &08, &2C, &FF, &65, &88
 EQUB &08, &08, &2C, &BF, &76, &88
 EQUB &0C, &0C, &2C, &28, &74, &88

 EQUB &0C, &0C, &2C, &68, &54, &88
 EQUB &0C, &0C, &2C, &E8, &65, &88
 EQUB &0C, &0C, &2C, &A8, &76, &88
 EQUB &08, &08, &0C, &A8, &76, &77
 EQUB &08, &08, &0C, &E8, &65, &66

 EQUB &08, &08, &0C, &28, &74, &77
 EQUB &08, &08, &0C, &68, &54, &55

 EQUB &1F, &21, &00, &04            ; edges data (24*4)
 EQUB &1F, &32, &00, &08
 EQUB &1F, &30, &00, &0C
 EQUB &1F, &10, &00, &10
 EQUB &1F, &24, &04, &08

 EQUB &1F, &51, &04, &10
 EQUB &1F, &60, &0C, &10
 EQUB &1F, &73, &08, &0C
 EQUB &1F, &74, &08, &14
 EQUB &1F, &54, &04, &18

 EQUB &1F, &65, &10, &1C
 EQUB &1F, &76, &0C, &20
 EQUB &1F, &86, &1C, &20
 EQUB &1F, &87, &14, &20
 EQUB &1F, &84, &14, &18

 EQUB &1F, &85, &18, &1C
 EQUB &08, &85, &18, &28
 EQUB &08, &87, &14, &24
 EQUB &08, &87, &20, &30
 EQUB &08, &85, &1C, &2C

 EQUB &08, &74, &24, &3C
 EQUB &08, &54, &28, &40
 EQUB &08, &76, &30, &34
 EQUB &08, &65, &2C, &38

 EQUB &9F, &40, &00, &10             ; faces data (9*4)
 EQUB &5F, &00, &40, &10
 EQUB &1F, &40, &00, &10
 EQUB &1F, &00, &40, &10
 EQUB &1F, &20, &00, &00

 EQUB &5F, &00, &20, &00
 EQUB &9F, &20, &00, &00
 EQUB &1F, &00, &20, &00
 EQUB &3F, &00, &00, &B0

\ ******************************************************************************
\ Variable: SHIP10
\
\ Asteroid blueprint
\ ******************************************************************************

.SHIP10

 EQUB &00
 EQUB &00, &19
 EQUB &4A
 EQUB &9E
 EQUB &41
 EQUB &00                           ; gun vertex = 0
 EQUB &22
 EQUB &36                           ; number of vertices = &36 / 6 = 9
 EQUB &15                           ; number of edges = &15 = 21
 EQUW 5                             ; bounty = 5
 EQUB &38                           ; number of faces = &38 / 4 = 14
 EQUB &32
 EQUB &3C
 EQUB &1E
 EQUB &00
 EQUB &00
 EQUB &01
 EQUB %00000000                     ; laser power = 0, missiles = 0

 EQUB &00, &50, &00, &1F, &FF, &FF  ; vertices data (25*9)
 EQUB &50, &0A, &00, &DF, &FF, &FF
 EQUB &00, &50, &00, &5F, &FF, &FF
 EQUB &46, &28, &00, &5F, &FF, &FF
 EQUB &3C, &32, &00, &1F, &65, &DC

 EQUB &32, &00, &3C, &1F, &FF, &FF
 EQUB &28, &00, &46, &9F, &10, &32
 EQUB &00, &1E, &4B, &3F, &FF, &FF
 EQUB &00, &32, &3C, &7F, &98, &BA

 EQUB &1F, &72, &00, &04            ; edges data (21*4)
 EQUB &1F, &D6, &00, &10
 EQUB &1F, &C5, &0C, &10
 EQUB &1F, &B4, &08, &0C
 EQUB &1F, &A3, &04, &08

 EQUB &1F, &32, &04, &18
 EQUB &1F, &31, &08, &18
 EQUB &1F, &41, &08, &14
 EQUB &1F, &10, &14, &18
 EQUB &1F, &60, &00, &14

 EQUB &1F, &54, &0C, &14
 EQUB &1F, &20, &00, &18
 EQUB &1F, &65, &10, &14
 EQUB &1F, &A8, &04, &20
 EQUB &1F, &87, &04, &1C

 EQUB &1F, &D7, &00, &1C
 EQUB &1F, &DC, &10, &1C
 EQUB &1F, &C9, &0C, &1C
 EQUB &1F, &B9, &0C, &20
 EQUB &1F, &BA, &08, &20

 EQUB &1F, &98, &1C, &20

 EQUB &1F, &09, &42, &51            ; faces data (14*4)
 EQUB &5F, &09, &42, &51
 EQUB &9F, &48, &40, &1F
 EQUB &DF, &40, &49, &2F
 EQUB &5F, &2D, &4F, &41

 EQUB &1F, &87, &0F, &23
 EQUB &1F, &26, &4C, &46
 EQUB &BF, &42, &3B, &27
 EQUB &FF, &43, &0F, &50
 EQUB &7F, &42, &0E, &4B

 EQUB &FF, &46, &50, &28
 EQUB &7F, &3A, &66, &33
 EQUB &3F, &51, &09, &43
 EQUB &3F, &2F, &5E, &3F

\ ******************************************************************************
\ Variable: SHIP11
\
\ Cargo canister blueprint
\ ******************************************************************************

.SHIP11

 EQUB &00
 EQUB &90, &01
 EQUB &50
 EQUB &8C
 EQUB &31
 EQUB &00                           ; gun vertex = 0
 EQUB &12
 EQUB &3C                           ; number of vertices = &3C / 6 = 10
 EQUB &0F                           ; number of edges = &0F = 15
 EQUW 0                             ; bounty = 0
 EQUB &1C                           ; number of faces = &1C / 4 = 7
 EQUB &0C
 EQUB &11
 EQUB &0F
 EQUB &00
 EQUB &00
 EQUB &02
 EQUB %00000000                     ; laser power = 0, missiles = 0

 EQUB &18, &10, &00, &1F, &10, &55  ; vertices data (10*6)
 EQUB &18, &05, &0F, &1F, &10, &22
 EQUB &18, &0D, &09, &5F, &20, &33
 EQUB &18, &0D, &09, &7F, &30, &44
 EQUB &18, &05, &0F, &3F, &40, &55

 EQUB &18, &10, &00, &9F, &51, &66
 EQUB &18, &05, &0F, &9F, &21, &66
 EQUB &18, &0D, &09, &DF, &32, &66
 EQUB &18, &0D, &09, &FF, &43, &66
 EQUB &18, &05, &0F, &BF, &54, &66

 EQUB &1F, &10, &00, &04            ; edges data (15*4)
 EQUB &1F, &20, &04, &08
 EQUB &1F, &30, &08, &0C
 EQUB &1F, &40, &0C, &10
 EQUB &1F, &50, &00, &10

 EQUB &1F, &51, &00, &14
 EQUB &1F, &21, &04, &18
 EQUB &1F, &32, &08, &1C
 EQUB &1F, &43, &0C, &20
 EQUB &1F, &54, &10, &24

 EQUB &1F, &61, &14, &18
 EQUB &1F, &62, &18, &1C
 EQUB &1F, &63, &1C, &20
 EQUB &1F, &64, &20, &24
 EQUB &1F, &65, &24, &14

 EQUB &1F, &60, &00, &00            ; faces data (7*4)
 EQUB &1F, &00, &29, &1E
 EQUB &5F, &00, &12, &30
 EQUB &5F, &00, &33, &00
 EQUB &7F, &00, &12, &30

 EQUB &3F, &00, &29, &1E
 EQUB &9F, &60, &00, &00

\ ******************************************************************************
\ Variable: SHIP12
\
\ Thargon ship blueprint
\ ******************************************************************************

.SHIP12

 EQUB &00
 EQUB &40, &06
 EQUB &A8                           ; use Thargoid edge data at &FFA8 = -88
 EQUB &50
 EQUB &41
 EQUB &00                           ; gun vertex = 0
 EQUB &12
 EQUB &3C                           ; number of vertices = &3C / 6 = 10
 EQUB &0F                           ; number of edges = &0F = 15
 EQUW 50                            ; bounty = 50
 EQUB &1C                           ; number of faces = &1C / 4 = 7
 EQUB &14
 EQUB &14
 EQUB &1E
 EQUB &FF                           ; use Thargoid edge data at &FFA8 = -88
 EQUB &00
 EQUB &02
 EQUB %00010000                     ; laser power = 2, missiles = 0

 EQUB &09, &00, &28, &9F, &01, &55  ; vertices data (10*6)
 EQUB &09, &26, &0C, &DF, &01, &22
 EQUB &09, &18, &20, &FF, &02, &33
 EQUB &09, &18, &20, &BF, &03, &44
 EQUB &09, &26, &0C, &9F, &04, &55

 EQUB &09, &00, &08, &3F, &15, &66
 EQUB &09, &0A, &0F, &7F, &12, &66
 EQUB &09, &06, &1A, &7F, &23, &66
 EQUB &09, &06, &1A, &3F, &34, &66
 EQUB &09, &0A, &0F, &3F, &45, &66

 EQUB &9F, &24, &00, &00            ; faces data (7*4)
 EQUB &5F, &14, &05, &07
 EQUB &7F, &2E, &2A, &0E
 EQUB &3F, &24, &00, &68
 EQUB &3F, &2E, &2A, &0E

 EQUB &1F, &14, &05, &07
 EQUB &1F, &24, &00, &00

\ ******************************************************************************
\ Variable: SHIP13
\
\ Escape pod blueprint
\ ******************************************************************************

.SHIP13

 EQUB &00
 EQUB &00, &01
 EQUB &2C
 EQUB &44
 EQUB &19
 EQUB &00                           ; gun vertex = 0
 EQUB &16
 EQUB &18                           ; number of vertices = &18 / 6 = 4
 EQUB &06                           ; number of edges = &06 = 6
 EQUW 0                             ; bounty = 0
 EQUB &10                           ; number of faces = &10 / 4 = 4
 EQUB &08
 EQUB &11
 EQUB &08
 EQUB &00
 EQUB &00
 EQUB &03
 EQUB %00000000                     ; laser power = 0, missiles = 0

 EQUB &07, &00, &24, &9F, &12, &33  ; vertices data (4*6)
 EQUB &07, &0E, &0C, &FF, &02, &33
 EQUB &07, &0E, &0C, &BF, &01, &33
 EQUB &15, &00, &00, &1F, &01, &22

 EQUB &1F, &23, &00, &04            ; edges data (6*4)
 EQUB &1F, &03, &04, &08
 EQUB &1F, &01, &08, &0C
 EQUB &1F, &12, &0C, &00
 EQUB &1F, &13, &00, &08

 EQUB &1F, &02, &0C, &04

 EQUB &3F, &1A, &00, &3D            ; faces data (4*4)
 EQUB &1F, &13, &33, &0F
 EQUB &5F, &13, &33, &0F
 EQUB &9F, &38, &00, &00

\ ******************************************************************************
\ Save output/SHIPS.bin
\ ******************************************************************************

PRINT "SHIPS"
PRINT "Assembled at ", ~CODE_SHIPS%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_SHIPS%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_SHIPS%

PRINT "S.SHIPS ", ~CODE_B%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_SHIPS%
SAVE "output/SHIPS.bin", CODE_SHIPS%, P%, LOAD%

\ ******************************************************************************
\ Show free space
\ ******************************************************************************

PRINT "ELITE game code ", ~(&6000-P%), " bytes free"
PRINT "Ends at ", ~P%
