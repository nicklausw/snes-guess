org $ffc0
 db "THIS IS 21 CHARACTERS" // rom name

 db $30 // lorom fastrom
 db $00 // no battery ram
 db $08 // 256K rom


org $ffe0 // vectors
 dw 0, 0, 0, 0, 0, 0, 0, 0
 dw 0, 0, 0, 0, 0, 0, reset, 0
 