arch snes.cpu; lorom

fillto $048000

incsrc "snes.i"
incsrc "header.s"
incsrc "data.s"

bank 0
org $8000

zero_fill_byte:
  db 0
  
reset:
  clc // 65816 mode
  xce
  
  rep #$30     // A=16, X/Y=16

  // Note: this should correlate with ZEROPAGE in snes.cfg
  lda.w #$0000
  tcd          // Set D = $0000 (direct page)

  // Note: this should correlate with the top of BSS in snes.cfg
  ldx #$1fff
  txs          // Set X = $1fff (stack pointer)


// Register initialisation values, per official Nintendo documentation

  sep #$20     // A=8
  lda.b #$80
  sta.w $2100
  stz.w $2101
  stz.w $2102
  stz.w $2103
  stz.w $2104
  stz.w $2105
  stz.w $2106
  stz.w $2107
  stz.w $2108
  stz.w $2109
  stz.w $210a
  stz.w $210b
  stz.w $210c
  stz.w $210d
  stz.w $210d
  stz.w $210e
  stz.w $210e
  stz.w $210f
  stz.w $210f
  stz.w $2110
  stz.w $2110
  stz.w $2111
  stz.w $2111
  stz.w $2112
  stz.w $2112
  stz.w $2113               
  stz.w $2113               
  stz.w $2114
  stz.w $2114
  lda.b #$80
  sta.w $2115
  stz.w $2116
  stz.w $2117
  stz.w $211a
  stz.w $211b
  lda.b #$01
  sta.w $211b
  stz.w $211c
  stz.w $211c
  stz.w $211d
  stz.w $211d
  stz.w $211e       
  lda.b #$01
  sta.w $211e
  stz.w $211f
  stz.w $211f
  stz.w $2120
  stz.w $2120
  stz.w $2121
  stz.w $2123
  stz.w $2124
  stz.w $2125
  stz.w $2126
  stz.w $2127
  stz.w $2128
  stz.w $2129
  stz.w $212a
  stz.w $212b
  stz.w $212c
  stz.w $212d
  stz.w $212e
  stz.w $212f
  stz.w $4200
  lda.b #$ff
  sta.w $4201
  stz.w $4202
  stz.w $4203
  stz.w $4204
  stz.w $4205
  stz.w $4206
  stz.w $4207
  stz.w $4208
  stz.w $4209
  stz.w $420a
  stz.w $420b
  stz.w $420c
  stz.w $420d

//ClearVram
  lda.b #$80
  sta.w $2115         //Set VRAM port to word access
  ldx #$1809
  stx.w $4300         //Set DMA mode to fixed source, WORD to $2118/9
  ldx.w #$0000
  stx.w $2116         //Set VRAM port address to $0000
  ldx.w #zero_fill_byte
  stx.w $4302         //Set source address to $xx:0000
  lda.b #$00
  sta.w $4304         //Set source bank
  ldx.w #$0000
  stx.w $4305         //Set transfer size to 65536 bytes
  lda.b #$01
  sta.w $420B         //Initiate transfer

//ClearPalette
  stz.w $2121
  ldx #$0100
ClearPaletteLoop:
  stz.w $2122
  stz.w $2122
  dex
  bne ClearPaletteLoop

  //**** clear Sprite tables ********

  stz.w $2102	//sprites initialized to be off the screen, palette 0, character 0
  stz.w $2103
  ldx.w #$0080
  lda #$F0

_Loop08:
  sta.w $2104	//set X = 240
  sta.w $2104	//set Y = 240
  stz.w $2104	//set character = $00
  stz.w $2104	//set priority=0, no flips
  dex
  bne _Loop08

  ldx #$0020

_Loop09:
  stz.w $2104		//set size bit=0, x MSB = 0
  dex
  bne _Loop09

  //**** clear SNES RAM ********

  stz.w $2181		//set WRAM address to $000000
  stz.w $2182
  stz.w $2183

  ldx #$8008
  stx.w $4300         //Set DMA mode to fixed source, BYTE to $2180
  ldx.w #zero_fill_byte
  stx.w $4302         //Set source offset
  lda #$00
  sta $4304         //Set source bank
  ldx #$0000
  stx.w $4305         //Set transfer size to 64KBytes (65536 bytes)
  lda #$01
  sta $420B         //Initiate transfer

  lda #$01          //now zero the next 64KB (i.e. 128KB total)
  sta $420B         //Initiate transfer
  
  
  // forced blank
  {seta8}
  lda #$8f
  sta.w {PPUBRIGHT}
  
  lda #$01
  sta.w {BGMODE}     // mode 0 (four 2-bit BGs) with 8x8 tiles
  stz.w {BGCHRADDR}  // bg planes 0-1 CHR at $0000
  lda #$4000 >> 13
  sta.w {OBSEL}      // sprite CHR at $4000, sprites are 8x8 and 16x16
  lda #$6000 >> 8
  sta.w {NTADDR}+0   // plane 0 nametable at $6000
  sta.w {NTADDR}+1   // plane 1 nametable also at $6000
  
  
  
  // Copy background palette to the S-PPU.
  // We perform the copy using DMA (direct memory access), which has
  // four steps:
  // 1. Set the destination address in the desired area of memory,
  //    be it CGRAM (palette), OAM (sprites), or VRAM (tile data and
  //    background maps).
  // 2. Tell the DMA controller which area of memory to copy to.
  // 3. Tell the DMA controller the starting address to copy from.
  // 4. Tell the DMA controller how big the data is in bytes.
  // ppu_copy uses the current data bank as the source bank
  // for the copy, so set the source bank.
  {seta8}
  stz.w {CGADDR}  // Seek to the start of CGRAM
  {setaxy16}
  lda.w #{DMAMODE_CGDATA}
  ldx.w #palette & $FFFF
  ldy.w #palette_size-palette
  jsr ppu_copy
  
  // Copy background tiles to PPU.
  // PPU memory is also word addressed because the low and high bytes
  // are actually on separate SRAM chips.
  // In background mode 0, all background tiles are 2 bits per pixel,
  // which take 16 bytes or 8 words per tile.
  {setaxy16}
  stz.w {PPUADDR}  // we will start video memory at $0000
  lda.w #{DMAMODE_PPUDATA}
  ldy.w #font_size-font
  ldx.w #font & $FFFF
  jsr ppu_copy
  
  lda #$6000|((1)|((2)<<5))
  sta.w {PPUADDR}
  lda #'5'
  sta.w {PPUDATA}
  
  
  {seta8}
  
  lda #%00000001  // enable sprites and plane 0
  sta.w {BLENDMAIN}
  
  lda #$0F
  sta.w {PPUBRIGHT}
  
forever:
  jmp forever

ppu_copy:
  php
  {setaxy16}
  sta.w {DMAMODE}
  stx.w {DMAADDR}
  sty.w {DMALEN}
  {seta8}
  phb
  pla
  sta {DMAADDRBANK}
  lda #%00000001
  sta {COPYSTART}
  plp
  rts


