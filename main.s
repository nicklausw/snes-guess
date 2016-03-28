.include "global.i"

.segment "HEADER"
 .byte "I DUNNO" ; rom name

.segment "ROMINFO"
 .byte $30 ; lorom fastrom
 .byte $00 ; no battery ram
 .byte $08 ; 256K rom


.segment "VECTORS"
 .word 0, 0, 0, 0, 0, 0, 0, 0
 .word 0, 0, 0, 0, 0, 0, reset, 0


; the code
.segment "CODE"

.proc reset
  InitializeSNES
  
  ; forced blank
  seta8
  lda #$8f
  sta PPUBRIGHT
  
  lda #$01
  sta BGMODE     ; mode 0 (four 2-bit BGs) with 8x8 tiles
  stz BGCHRADDR  ; bg planes 0-1 CHR at $0000
  lda #$4000 >> 13
  sta OBSEL      ; sprite CHR at $4000, sprites are 8x8 and 16x16
  lda #>$6000
  sta NTADDR+0   ; plane 0 nametable at $6000
  sta NTADDR+1   ; plane 1 nametable also at $6000
  
  
  
  ; Copy background palette to the S-PPU.
  ; We perform the copy using DMA (direct memory access), which has
  ; four steps:
  ; 1. Set the destination address in the desired area of memory,
  ;    be it CGRAM (palette), OAM (sprites), or VRAM (tile data and
  ;    background maps).
  ; 2. Tell the DMA controller which area of memory to copy to.
  ; 3. Tell the DMA controller the starting address to copy from.
  ; 4. Tell the DMA controller how big the data is in bytes.
  ; ppu_copy uses the current data bank as the source bank
  ; for the copy, so set the source bank.
  seta8
  stz CGADDR  ; Seek to the start of CGRAM
  setaxy16
  lda #DMAMODE_CGDATA
  ldx #palette & $FFFF
  ldy #palette_size-palette
  jsr ppu_copy
  
  ; Copy background tiles to PPU.
  ; PPU memory is also word addressed because the low and high bytes
  ; are actually on separate SRAM chips.
  ; In background mode 0, all background tiles are 2 bits per pixel,
  ; which take 16 bytes or 8 words per tile.
  setaxy16
  stz PPUADDR  ; we will start video memory at $0000
  lda #DMAMODE_PPUDATA
  ldy #font_size-font
  ldx #font & $FFFF
  jsr ppu_copy
  
  lda #$6000|NTXY(1,1)
  sta PPUADDR
  lda #'5'
  sta PPUDATA
  
  
  seta8
  
  lda #%00000001  ; enable sprites and plane 0
  sta BLENDMAIN
  
  lda #$0F
  sta PPUBRIGHT
  
?forever:
  jmp ?forever
.endproc

; we'll need this at some point ;3
zero_fill_byte:
  .byte $00

palette:
  bgr 0, 0, 0
  bgr 31, 31, 31
palette_size:

font:
  .incbin "font.chr"
font_size:

.proc ppu_copy
  php
  setaxy16
  sta DMAMODE
  stx DMAADDR
  sty DMALEN
  seta8
  phb
  pla
  sta DMAADDRBANK
  lda #%00000001
  sta COPYSTART
  plp
  rts
.endproc
