BITS 16
ORG 0x0600          ; 第二階段程式載入到 0x0600 地址

start:
    mov si, welcome_msg       ; 加載歡迎訊息
    call print_string         ; 顯示歡迎訊息
    call newline              ; 顯示空行

    mov si, hint_msg          ; 加載提示訊息
    call print_string         ; 顯示提示訊息
    call newline              ; 顯示空行

main_loop:
    call newline              ; 提示符之前加入空行
    mov si, prompt_msg        ; 加載提示符
    call print_string         ; 顯示提示符

    call read_input           ; 讀取用戶輸入

    mov si, buffer
    mov di, cmd_help
    call strcmp
    jz cmd_help_action        ; 如果相等，執行 help 指令

    mov si, buffer
    mov di, cmd_clear
    call strcmp
    jz cmd_clear_action       ; 如果相等，執行 clear 指令

    mov si, buffer
    mov di, cmd_reboot
    call strcmp
    jz cmd_reboot_action      ; 如果相等，執行 reboot 指令

    mov si, buffer
    mov di, cmd_memory
    call strcmp
    jz cmd_memory_action      ; 如果相等，執行 memory 指令

    mov si, buffer
    mov di, cmd_read
    call strcmp
    jz cmd_read_action        ; 如果相等，執行 read 指令
    
    mov si, buffer
    mov di, cmd_write
    call strcmp
    jz cmd_write_action       ; 如果相等，執行 write 指令

    mov si, unknown_cmd_msg   ; 如果輸入指令未知，顯示錯誤訊息
    call print_string
    call newline
    jmp main_loop             ; 返回主迴圈

cmd_help_action:
    call newline
    mov si, help_msg          ; 加載指令列表訊息
    call print_string         ; 顯示訊息
    call newline
    jmp main_loop             ; 返回主迴圈

cmd_clear_action:
    mov ah, 0x00              ; BIOS 中斷功能：設定顯示模式
    mov al, 0x03              ; 模式：80x25 文本模式
    int 0x10                  ; 呼叫 BIOS
    call newline
    jmp main_loop             ; 返回主迴圈

cmd_reboot_action:
    mov ax, 0xFFFF            ; 設置地址寄存器
    mov ds, ax
    jmp 0xFFFF:0x0000         ; 跳轉到 BIOS，重啟系統

cmd_memory_action:
    call newline
    int 0x12                  ; BIOS 中斷：獲取可用基礎記憶體大小（KB）
    mov bx, ax                ; 將記憶體大小存入 BX
    call print_memory         ; 顯示記憶體大小
    call newline
    jmp main_loop             ; 返回主迴圈

cmd_read_action:
    call newline              ; 顯示空行
    mov ah, 0x02              ; BIOS 中斷功能號：讀取磁碟
    mov al, 1                 ; 讀取 1 個扇區
    mov ch, 0                 ; 磁柱 0
    mov cl, 5                 ; 讀取第 5 扇區
    mov dh, 0                 ; 磁頭 0
    mov dl, 0x80              ; 第一個硬碟
    mov bx, buffer            ; 將數據存入 buffer
    int 0x13                  ; 呼叫 BIOS 磁碟中斷
    jc disk_error             ; 如果失敗，跳轉到錯誤處理

    mov di, buffer
    add di, 511               ; 將指針移到緩衝區最後一位
    mov byte [di], 0          ; 加入 NULL 結尾，防止亂碼

    mov si, buffer
    call print_string         ; 顯示讀取的扇區內容
    call newline
    jmp main_loop             ; 返回主迴圈
    
cmd_write_action:
    call newline           ; 顯示空行
    mov si, write_prompt   ; 提示用戶輸入數據
    call print_string

    call read_input        ; 讀取用戶輸入的數據

    ; 將數據寫入第 3 扇區
    mov ah, 0x03           ; BIOS 中斷功能號：寫入磁碟
    mov al, 1              ; 寫入 1 個扇區
    mov ch, 0              ; 磁柱 0
    mov cl, 5              ; 扇區 5（目標扇區）
    mov dh, 0              ; 磁頭 0
    mov dl, 0x80           ; 第一個硬碟
    mov bx, buffer         ; 要寫入的數據來源
    int 0x13               ; 呼叫 BIOS 磁碟中斷
    jc write_error         ; 如果失敗，跳轉到錯誤處理

    ; 寫入成功提示
    call newline 
    mov si, write_success_msg
    call print_string
    call newline
    jmp main_loop          ; 返回主迴圈

write_error:
    mov si, write_error_msg
    call print_string
    call newline
    jmp main_loop          ; 返回主迴圈

disk_error:
    mov si, disk_error_msg    ; 加載錯誤訊息
    call print_string         ; 顯示錯誤訊息
    call newline
    jmp main_loop             ; 返回主迴圈

print_string:
    lodsb                     ; 從 SI 加載下一個字元到 AL
    or al, al                 ; 檢查是否為 NULL
    jz return                 ; 如果是 NULL，返回
    mov ah, 0x0E              ; BIOS 顯示字元功能
    int 0x10                  ; 顯示字元
    jmp print_string          ; 繼續處理下一個字元
return:
    ret

read_input:
    mov di, buffer            ; 指向 buffer
read_char:
    mov ah, 0x00              ; BIOS 等待按鍵輸入
    int 0x16
    cmp al, 0x0D              ; 檢查是否為 Enter 鍵
    je end_input              ; 如果是，結束輸入
    mov ah, 0x0E              ; 回顯輸入字元
    int 0x10
    stosb                     ; 存入 buffer
    jmp read_char             ; 繼續讀取
end_input:
    mov al, 0                 ; 加入 NULL 結尾
    stosb
    ret

newline:
    mov ah, 0x0E
    mov al, 0x0A              ; 換行符 LF
    int 0x10
    mov al, 0x0D              ; 回車符 CR
    int 0x10
    ret

print_memory:
    mov cx, 0
convert_digit:
    xor dx, dx                ; 清除 DX
    div bx                    ; 除以 10，結果在 AX，餘數在 DX
    push dx                   ; 保存餘數
    inc cx                    ; 增加位數計數
    cmp ax, 0                 ; 檢查是否還有數字
    jne convert_digit
print_digits:
    pop ax                    ; 取出數字
    add al, '0'               ; 將數字轉為 ASCII
    mov ah, 0x0E              ; BIOS 顯示字元功能
    int 0x10                  ; 顯示字元
    loop print_digits         ; 繼續顯示剩餘數字
    ret

strcmp:
    next_char:
        lodsb                 ; 加載 SI 指向的字元到 AL
        scasb                 ; 比較 AL 與 DI 指向的字元
        jne not_equal         ; 如果不相等，跳轉
        or al, al             ; 檢查是否為 NULL
        jnz next_char         ; 如果不是 NULL，繼續比較
        mov al, 1             ; 字串相等
        ret
    not_equal:
        mov al, 0             ; 字串不相等
        ret

welcome_msg db "Welcome to the command interface!", 0
hint_msg db "Type 'help' to get a list of available commands.", 0
prompt_msg db "> ", 0
unknown_cmd_msg db "Unknown command!", 0
help_msg db "Available commands: help, clear, reboot, memory, read, write", 0
disk_error_msg db "Disk read error!", 0
cmd_help db "help", 0
cmd_clear db "clear", 0
cmd_reboot db "reboot", 0
cmd_memory db "memory", 0
cmd_read db "read", 0
cmd_write db "write", 0
buffer db 512 dup(0)
write_prompt db "Enter data to write to sector 5:", 0
write_success_msg db "Data written successfully!", 0
write_error_msg db "Error: Failed to write data to disk.", 0


