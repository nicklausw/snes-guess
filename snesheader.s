.include "global.i"

.segment "SNESHEADER"
 romname:
 .byte "I DUNNO" ; rom name
 
 ; make sure the rom name length is covered (thanks tepples)
 .assert * - romname <= 21, error, "ROM name too long"
  .if * - romname < 21
    .res romname + 21 - *, $20  ; space padding
  .endif
  
 .byte $30 ; lorom fastrom
 .byte $00 ; no battery ram
 .byte $08 ; 256K rom


.segment "VECTORS"
 .word 0, 0, 0, 0, 0, 0, 0, 0
 .word 0, 0, 0, 0, 0, 0, reset, 0
