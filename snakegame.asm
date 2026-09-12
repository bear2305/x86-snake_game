BITS 16
ORG 0x7e00

MOV sp,0x7c00
JMP start

save_ax:
        MOV bx,ax
        RET

right:
      INC al
      RET
left:
     DEC al
     RET
up:
   DEC ah
   RET
down:
     INC ah
     RET


set_body:
         MOV si,body
         RET

swap:
     PUSH cx
     XOR cx,cx
     MOV cx,bx
     MOV bh,[si]
     MOV bl,[si+1]
     MOV [si],ch
     MOV [si+1],cl
     POP cx
     JMP swap_body_loop


swap_body_loop:
               INC si
               INC si
               CMP BYTE [si],'$'
               JE exit
               JMP swap
exit:
     RET

dx_cls_t:
         PUSH ax
         PUSH bx
         PUSH cx
         PUSH dx
         XOR ax,ax
         XOR bx,bx
         MOV ah,0x0e
         MOV al,' '
         INT 10h
         POP dx
         POP cx
         POP bx
         POP ax
         RET


dx_update:
          MOV dx,bx
          RET

set_head_cursor:
                PUSH ax
                PUSH bx
                PUSH cx
                PUSH dx
                XOR bx,bx
                XOR cx,cx
                XOR dx,dx

                MOV ch,ah
                MOV cl,al
                XOR ax,ax

                MOV ah,0x02
                MOV bh,0
                MOV dh,ch
                MOV dl,cl
                INT 10h
                POP dx
                POP cx
                POP bx
                POP ax
                RET

set_tail_cursor:
                PUSH ax
                PUSH bx
                PUSH cx
                PUSH dx
                XOR ax,ax
                XOR bx,bx

                MOV ah,0x02
                MOV bh,0
                ;mov dx,dx
                INT 10h
                POP dx
                POP cx
                POP bx
                POP ax
                RET

set_body_cursor:
                PUSH si
                PUSH ax
                PUSH bx
                PUSH dx
                XOR ax,ax
                XOR bx,bx
                XOR dx,dx

                MOV ah,0x02
                MOV bh,0
                MOV dh,ch
                MOV dl,cl
                INT 10h
                POP dx
                POP bx
                POP ax
                POP si
                RET

print:
      PUSH si
      PUSH ax
      PUSH bx
      PUSH cx
      PUSH dx
      XOR ax,ax
      XOR bx,bx
      MOV ah,0x0e
      MOV al,'o'
      INT 10h
      POP dx
      POP cx
      POP bx
      POP ax
      POP si
      RET

body_loop_print:
                PUSH cx
                XOR cx,cx
                CALL set_body
                JMP cont
cont:
     MOV ch,[si]
     MOV cl,[si+1]
     CALL set_body_cursor
     CALL print

     JMP redo

redo:
     INC si
     INC si
     CMP BYTE [si],'$'
     JE endloop
     JMP cont

endloop:
        POP cx
        RET


init:
     MOV ah,0x01
     MOV al,0x0f
     MOV BYTE [body],0x01
     MOV BYTE [body+1],0x0c
     MOV BYTE [body+2],0x01
     MOV BYTE [body+3],0x0d
     MOV BYTE [body+4],0x01
     MOV BYTE [body+5],0x0e
     MOV BYTE [body+6],'$'
     MOV dh,0x01
     MOV dl,0x0b

     CALL print_whole_body

     RET


print_whole_body:
                  CALL set_tail_cursor
                  CALL print
                  CALL body_loop_print
                  CALL set_head_cursor
                  CALL print
                ;    CALL space_cursor
                  RET



update_and_ptbody:
                 CALL set_body
                 CALL swap
                 CALL set_tail_cursor
                 CALL dx_cls_t
                 CALL dx_update
                 CALL print_whole_body
                 RET


key:
    PUSH ax
    PUSH bx
    XOR ax,ax
    MOV ah,0x01
    INT 16h
    CMP ah,0x01
    JE checktwice
    CALL cls_key
    JMP exit_key


cls_key:
        MOV ah,0x0
        INT 16h
        RET

checktwice:
           CMP al,0x0
           JE skip_key
           CALL cls_key
           JMP exit_key

skip_key:
         MOV ah,0x0
         JMP exit_key

exit_key:
         CMP ah,0x0
         JE out_key
         MOV [onclick],ah
         POP bx
         POP ax
         RET

out_key:
        POP bx
        POP ax
        RET




time_interval:
              PUSH ax
              PUSH bx
              PUSH cx
              PUSH dx

              MOV ah,86h
              MOV cx,0x0001
              MOV dx,0xe848
              INT 15h

              POP dx
              POP cx
              POP bx
              POP ax
              RET

printax:
        PUSHA
        MOV cx,ax
        MOV ah,0x02
        XOR bx,bx
        XOR dx,dx
        INT 10h
        MOV ah,0xe
        MOV al,ch
        INT 10h
        MOV al,cl
        INT 10h
        POPA
        RET


start:
      CALL init
      ;need to [ON KEY PRESS] , (save_ax), /apply RLTD updates/ ,( update_and_ptbody )
      CALL printax
      JMP continue_start

continue_start:
               CALL printax
               CALL key
               CMP BYTE [onclick],0x4d
               JE rightaction
               CMP BYTE [onclick],0x4b
               JE leftaction
               CMP BYTE [onclick],0x48
               JE upaction
               CMP BYTE [onclick],0x50
               JE downaction
               JMP continue_start

rightaction:
            CALL save_ax
            CALL right
            CALL update_and_ptbody
            CALL time_interval
            JMP continue_start

leftaction:
           CALL save_ax
           CALL left
           CALL update_and_ptbody
           CALL time_interval
           JMP continue_start

upaction:
         CALL save_ax
         CALL up
         CALL update_and_ptbody
         CALL time_interval
         JMP continue_start

downaction:
           CALL save_ax
           CALL down
           CALL update_and_ptbody
        ;   CALL time_interval
           HLT
           HLT
           HLT
           JMP continue_start






body TIMES 8 DB 0
onclick DB 0
;TIMES 510-($-$$) DB 0
DW 0xaa55
;TIMES 1572352 DB 0
