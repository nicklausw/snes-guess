//
// S-CPU and S-PPU MMIO port definitions for Super NES
// and useful 65816 macros
//
// Copyright 2014-2015 Damian Yerrick
//
// Copying and distribution of this file, with or without
// modification, are permitted in any medium without royalty provided
// the copyright notice and this notice are preserved in all source
// code copies.  This file is offered as-is, without any warranty.
//

//
// This header summarizes some of the Super NES MMIO ports.
// For more details, see these web pages:
// http://wiki.superfamicom.org/
// http://problemkaputt.de/fullsnes.htm
//
// Names of MMIO ports in this header file may differ from purported
// official names for two reasons: to avoid the appearance of
// misappropriation, and because sometimes these make more sense.
//

// S-PPU configuration //////////////////////////////////////////////////////////////////////////////////////////////

define PPUBRIGHT $2100
// 76543210
// |   ++++- brightness (F: max)
// +-------- 1: disable rendering
define FORCEBLANK $80

define PPURES $2133
// 76543210
// ||  |||+- Screen interlace
// ||  ||+-- Shrink sprites vertically during interlace
// ||  |+--- 0: show lines 1-224// 1: show lines 1-239
// ||  +---- Show subscreen in left half of each pixel
// ||        (modes 012347// forced on in modes 56)
// |+------- In mode 7, use bit 7 as priority
// +-------- External genlock, intended for SFC Titler. Use 0 on SNES.
define INTERLACE    $01
define INTERLACEOBJ $02
define BG_TALL      $04
define SUB_HIRES    $08
define M7_EXTBG     $40

define PPUSTATUS1 $213E
// 76543210  PPU address generator status
// ||  ++++- PPU1 version (always 1)
// |+------- 1: sprite overflow (>32 on a line) since the last vblank end
// +-------- 1: sliver overflow (>34 on a line) since the last vblank end
// this parallels bit 5 of $2002 on NES

define PPUSTATUS2 $213F
// 76543210  PPU compositor status
// || |++++- PPU2 version (1-3, not counting minor versions of 3)
// || +----- 1: PAL
// |+------- 1: GETXY has happened since last PPUSTATUS2 read
// +-------- Toggles every vblank

// S-PPU sprites //////////////////////////////////////////////////////////////////////////////////////////////////////////

define OBSEL $2101
// 76543210
// ||||| ++- Sprite main pattern table (0=$0000, 1=$2000, 2=$4000, 3=$6000)
// |||++---- Alt pattern table offset (0=$1000, 1=$2000, 2=$3000, 3=$4000)
// +++------ 0: 8/16// 1: 8/32// 2: 8/64// 3: 16/64// 4: 32/64// 5: 64/64
//           (all sprites are square and 2D-mapped)
define OBSIZE_8_16  $00
define OBSIZE_8_32  $20
define OBSIZE_8_64  $40
define OBSIZE_16_32 $60
define OBSIZE_16_64 $80
define OBSIZE_32_64 $A0

define OAMADDR $2102  // 16-bit, 128 sprites followed by high-X/size table
define OAMDATA $2104
define OAMDATARD $2138
// Parallels NES $2003, except apparently word-addressed.
// OAM random access is working here, unlike on NES.
// If bit 15 is set, value at start of frame apparently also
// controls which sprites are in front

// S-PPU background configuration ////////////////////////////////////////////////////////////////////////

define BGMODE $2105
// 76543210
// |||||+++- 0: 4 planes 2 bpp
// |||||     1: 2 planes 4 bpp, 1 plane 2 bpp
// |||||     2: 2 planes 4 bpp, OPT
// |||||     3: 1 plane 8 bpp, 1 plane 4 bpp
// |||||     4: 1 plane 8 bpp, 1 plane 2 bpp, OPT
// |||||     5: 1 plane 4 bpp, 1 plane 2 bpp, hires
// |||||     6: 1 plane 4 bpp, OPT, hires
// |||||     7: 1 plane rot/scale
// ||||+---- In mode 1, set plane 2 high-prio in front of all others
// |||+----- Plane 0 tile size (0: 8x8, 1: 16x16)
// ||+------ Plane 1 tile size (0: 8x8, 1: 16x16)
// |+------- Plane 2 tile size (0: 8x8, 1: 16x16)
// +-------- Plane 3 tile size (0: 8x8, 1: 16x16)
//           Modes 5 and 6 use 16x8 instead of 8x8
//           Mode 7 always uses 8x8

define MOSAIC $2106
// 76543210
// |||||||+- Apply mosaic to plane 0 (or mode 7 high-prio horizontal)
// ||||||+-- Apply mosaic to plane 1 (or mode 7 high-prio vertical)
// |||||+--- Apply mosaic to plane 2
// ||||+---- Apply mosaic to plane 3
// ++++----- Pixel size minus 1 (0=1x1, 15=16x16)

define NTADDR $2107  // through $210A
// 76543210
//  ||||||+- Nametable width (0: 1 screen, 1: 2 screens)
//  |||||+-- Nametable height (0: 1 screen, 1: 2 screens)
//  +++++--- Nametable base address in $400 units
// Each nametable in modes 0-6 is 32 rows, each 32 spaces long.
// .define NTXY(xc,yc) ((xc)|((yc)<<5))

define BGCHRADDR $210B
// FEDCBA98 76543210
//  ||| |||  ||| +++- Pattern table base address for plane 0
//  ||| |||  +++----- Same for plane 1
//  ||| +++---------- Same for plane 2
//  +++-------------- Same for plane 3

define M7SEL $211A
// 76543210
// ||    ||
// ||    |+- Flip screen horizontally
// ||    +-- Flip screen vertically
// ++------- 0: repeat entire mode 7 plane
//           2: transparent outside// 3: tile $00 repeating outside
define M7_HFLIP    $01
define M7_VFLIP    $02
define M7_WRAP     $00
define M7_NOWRAP   $80
define M7_BORDER00 $C0

// S-PPU scrolling //////////////////////////////////////////////////////////////////////////////////////////////////////

define BGSCROLLX $210D  // double write low then high (000-3FF m0-6, 000-7FF m7)
define BGSCROLLY $210E  // similar. reg 210F-2114 are same for other planes
// Hi-res scrolling in modes 5-6 moves by whole (sub+main) pixels in X
// but half scanlines in Y.
// The top visible line is the line below the value written here.
// For example, in 224-line mode, if 12 is written, lines 13 through
// 237 of the background are visible.  This differs from the NES.
//
// Mode 7 uses this value as the center of rotation.  This differs
// from the GBA, which fixes the center of rotation at the top left.

// 211B-2120 control mode 7 matrix// to be documented later

// S-PPU VRAM data port ////////////////////////////////////////////////////////////////////////////////////////////

define PPUCTRL $2115
// 76543210
// |   ||++- VRAM address increment (1, 32, 128, 128)
// |   ++--- Rotate low bits of address left by 3 (off, 8, 9, or 10)
// +-------- 0: Increment after low data port access// 1: after high
// Corresponds to bit 2 of $2000 on NES
define VRAM_DOWN   $01
define VRAM_M7DOWN $02
define INC_DATAHI  $80

define PPUADDR $2116  // Word address, not double-write anymore
define PPUDATA $2118
define PPUDATAHI $2119
define PPUDATARD $2139  // Same dummy read as on NES is needed
define PPUDATARDHI $213A

// S-PPU palette //////////////////////////////////////////////////////////////////////////////////////////////////////////

define CGADDR $2121
define CGDATA $2122  // 5-bit BGR, write twice, low byte first
define CGDATARD $213B  // 5-bit BGR, read twice, low byte first
// .define RGB(r,g,b) ((r)|((g)<<5)|((b)<<10))

// S-PPU window ////////////////////////////////////////////////////////////////////////////////////////////////////////////

define BG12WINDOW $2123
define BG34WINDOW $2124
define OBJWINDOW $2125
// 76543210
// ||||||++- 0: disable window 1 on BG1/BG3/OBJ// 2: enable// 3: enable outside
// ||||++--- 0: disable window 2 on BG1/BG3/OBJ// 2: enable// 3: enable outside
// ||++----- 0: disable window 1 on BG2/BG4// 2: enable// 3: enable outside
// ++------- 0: disable window 2 on BG2/BG4// 2: enable// 3: enable outside

define WINDOW1L $2126
define WINDOW1R $2127
define WINDOW2L $2128
define WINDOW2R $2129

define BGWINDOP $212A   // Window op is how windows are combined when both
define OBJWINDOP $212B  // windows 1 and 2 are enabled.
// 76543210
// ||||||++- Window op for plane 0 or sprites (0: or, 1: and, 2: xor, 3: xnor)
// ||||++--- Window op for plane 1 or color window
// ||++----- Window op for plane 2
// ++------- Window op for plane 3

// S-PPU blending (or "color math") ////////////////////////////////////////////////////////////////////

// The main layer enable reg, corresponding to PPUMASK on the NES,
// is BLENDMAIN.
define BLENDMAIN  $212C  // Layers enabled for main input of blending
define BLENDSUB   $212D  // Layers enabled for sub input of blending
define WINDOWMAIN $212E  // Windows enabled for main input of blending
define WINDOWSUB  $212F  // Windows enabled for sub input of blending
// 76543210
//    ||||+- plane 0
//    |||+-- plane 1
//    ||+--- plane 2
//    |+---- plane 3
//    +----- sprites
// BLENDMAIN roughly parallels NES $2001 bits 4-3,
// except that turning off both bits doesn't disable rendering.
// (Use PPUBRIGHT for that.)

// PPU1 appears to generate a stream of (main, sub) pairs, which
// PPU2 combines to form output colors.

// Blending parameters not documented yet.  Wait for a future demo.

// When BGMODE is 0-6 (or during vblank in mode 7), a fast 16x8
// signed multiply is available, finishing by the next CPU cycle.
define M7MCAND $211B    // write low then high
define M7MUL $211C      // 8-bit factor
define M7PRODLO $2134
define M7PRODHI $2135
define M7PRODBANK $2136

define GETXY $2137  // read while $4201 D7 is set: populate x and y coords
define XCOORD $213C  // used with light guns, read twice
define YCOORD $213D  // also read twice

// SPC700 communication ports ////////////////////////////////////////////////////////////////////////////////

define APU0 $2140
define APU1 $2141
define APU2 $2142
define APU3 $2143

// S-CPU interrupt control //////////////////////////////////////////////////////////////////////////////////////

define PPUNMI $4200
// 76543210
// | ||   +- Automatically read controllers in first 4 lines of vblank
// | ++----- 0: No IRQ// 1: IRQs at HTIME//
// |         2: one IRQ at (0, VTIME)// 3: one IRQ at (HTIME, VTIME)
// +-------- 1: Enable NMI at start of vblank
define VBLANK_NMI $80
define HTIME_IRQ  $10
define VTIME_IRQ  $20
define HVTIME_IRQ $30
define AUTOREAD   $01

define HTIME   $4207
define HTIMEHI $4208
define VTIME   $4209
define VTIMEHI $420A

define NMISTATUS $4210
// 76543210
// |   ||||
// |   ++++- DMA controller version (1, 2) where v1 has an HDMA glitch
// +-------- 1: Vblank has started since last read (like $2002.d7 on NES)

define TIMESTATUS $4211  // Acknowledge htime/vtime IRQ
define VBLSTATUS $4212
// 76543210
// ||     +- 0: Controller reading finished// 1: busy
// |+------- In hblank
// +-------- In vblank

define ROMSPEED $420D  // 0: slow ROM everywhere// 1: fast ROM in banks 80-FF
                  // (requires 120ns or faster PRG ROM)

// S-CPU controller I/O ////////////////////////////////////////////////////////////////////////////////////////////

// Manual controller reading behaves almost exactly as on Famicom.
// For games using up to 2 standard controllers, these aren't needed,
// as you can enable controller autoreading along with vblank NMIs.
// But for games using (multitap, mouse, etc.), you will need to
// read the extra bits separately after the autoreader finishes.
define JOY0 $4016
define JOY1 $4017

// In addition to the common strobe, each controller port has an
// additional output bit that can be used as, say, a chip select
// for SPI peripherals.
define JOYOUT $4201
// 76543210
// |+------- Controller 1 pin 6 output
// +-------- Controller 2 pin 6 output

// Results of the autoreader
define JOY1CUR $4218    // Bit 0: used by standard controllers
define JOY2CUR $421A
define JOY1B1CUR $421C  // Bit 1: used by multitap and a few oddball
define JOY2B1CUR $421E  // input devices
// FEDCBA98 76543210
// BYSRUDLR AXLRTTTT
// |||||||| ||||++++- controller type (0: controller, 1: mouse)
// |||||||| ||++----- shoulder buttons
// ++-------++------- right face buttons
//   ||++++---------- Control Pad
//   ++-------------- center face buttons
define KEY_B      $8000
define KEY_Y      $4000
define KEY_SELECT $2000
define KEY_START  $1000
define KEY_UP     $0800
define KEY_DOWN   $0400
define KEY_LEFT   $0200
define KEY_RIGHT  $0100
define KEY_A      $0080
define KEY_X      $0040
define KEY_L      $0020
define KEY_R      $0010

// S-CPU multiply and divide //////////////////////////////////////////////////////////////////////////////////

// Multiply unit.  Also good for shifting pixels when drawing
// text in a proportional font.
define CPUMCAND $4202  // unchanged by multiplications
define CPUMUL $4203    // write here to fill CPUPROD 8 cycles later
define CPUPROD $4216
define CPUPRODHI $4217

// Divide unit
define CPUNUM $4204
define CPUNUMHI $4205
define CPUDEN $4206    // write divisor to fill CPUQUOT/CPUREM 16 cycles later
define CPUQUOT $4214
define CPUQUOTHI $4215
define CPUREM {CPUPROD}
define CPUREMHI {CPUPRODHI}

// S-CPU DMA //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

define COPYSTART $420B  // writes of 1 << n start a DMA copy on channel n
define HDMASTART $420C  // writes of 1 << n start HDMA on channel n
// Don't run a DMA copy while HDMA is enabled, or you might run into
// a defect in revision 1 of the S-CPU that causes crashing.

// There are 8 DMA channels.
// Registers for channels 1-7 start at $4310, $4320, ...
define DMAMODE $4300
// 76543210
// || ||+++- PPU address offset pattern
// || ||     0: 0     1: 01    2: 00    3: 0011  4: 0123  5: 0101
// || ++---- Memcpy only: 0: increment// 1: fixed// 2: decrement
// |+------- HDMA only: 1: Table contains pointers
// +-------- Direction (0: read CPU write PPU// 1: read PPU write CPU)
define DMA_LINEAR   $00
define DMA_01       $01
define DMA_00       $02  // For HDMA to double write ports// copies can use linear
define DMA_0011     $03  // For HDMA to scroll positions and mode 7 matrices
define DMA_0123     $04  // For HDMA to window registers
define DMA_0101     $05  // Not sure how this would be useful for HDMA
define DMA_FORWARD  $00
define DMA_CONST    $08
define DMA_BACKWARD $10
define DMA_INDIRECT $40
define DMA_READPPU  $80

define DMAPPUREG $4301
define DMAADDR $4302
define DMAADDRHI $4303
define DMAADDRBANK $4304
define DMALEN $4305  // number of bytes, not number of transfers// 0 means 65536
define DMALENHI $4306

// A future demo that includes HDMA effects would include port definitions.
//HDMAINDBANK $4307
//HDMATABLELO $4308
//HDMATABLEHI $4309
//HDMALINE $430A

// composite values for use with 16-bit writes to DMAMODE
define DMAMODE_PPULOFILL "(({PPUDATA} & $FF) << 8)       | {DMA_LINEAR} | {DMA_CONST}"
define DMAMODE_PPUHIFILL "((({PPUDATA} + 1) & $FF) << 8) | {DMA_LINEAR} | {DMA_CONST}"
define DMAMODE_PPUFILL   "(({PPUDATA} & $FF) << 8)       | {DMA_01}     | {DMA_CONST}"
define DMAMODE_PPULODATA "(({PPUDATA} & $FF) << 8)       | {DMA_LINEAR} | {DMA_FORWARD}"
define DMAMODE_PPUHIDATA "((({PPUDATA} + 1) & $FF) << 8) | {DMA_LINEAR} | {DMA_FORWARD}"
define DMAMODE_PPUDATA   "(({PPUDATA} & $FF) << 8)       | {DMA_01}     | {DMA_FORWARD}"
define DMAMODE_CGDATA    "(({CGDATA} & $FF) << 8)        | {DMA_00}     | {DMA_FORWARD}"
define DMAMODE_OAMDATA   "(({OAMDATA} & $FF) << 8)       | {DMA_00}     | {DMA_FORWARD}"


// MACRO PACK ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Macros to change the accumulator and index width.
// For best results, use .smart which lets the assembler follow
// SEP/REP and generate appropriately wide immediate values.
define setxy8 "sep #$10"
define setxy16 "rep #$10"
define seta8 "sep #$20"
define seta16 "rep #$20"
define setaxy8 "sep #$30"
define setaxy16 "rep #$30"
