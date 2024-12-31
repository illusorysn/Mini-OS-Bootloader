BITS 16             ; 設定 16 位元模式
ORG 0x7C00          ; BIOS 載入 Bootloader 的地址

start:
    ; 清空螢幕
    mov ah, 0x0     ; BIOS 中斷 0x10 的功能號：設置顯示模式
    mov al, 0x03    ; 80x25 文字模式
    int 0x10        ; 呼叫 BIOS 顯示服務

    ; 顯示訊息
    mov si, msg     ; 將訊息地址存入 SI
print_msg:
    lodsb           ; 加載 SI 指向的字元到 AL
    or al, al       ; 檢查是否到字串結尾（NULL 字元）
    jz read_disk    ; 如果是，跳到讀取磁碟
    mov ah, 0x0E    ; BIOS 中斷 0x10 的功能號：顯示字元
    int 0x10        ; 呼叫 BIOS 顯示服務
    jmp print_msg   ; 繼續顯示下一個字元

read_disk:
    ; 顯示讀取磁碟訊息
    mov si, read_msg
    call print_string

    ; 從磁碟讀取 4 個扇區
    mov ah, 0x02    ; BIOS 中斷 0x13 的功能號：讀取磁碟
    mov al, 4       ; 讀取 4 個扇區
    mov ch, 0       ; 磁柱 0
    mov cl, 2       ; 從第二個扇區開始
    mov dh, 0       ; 磁頭 0
    mov dl, 0x80    ; 第一個硬碟
    mov bx, 0x0600  ; 將扇區數據存入地址 0x0600
    int 0x13        ; 呼叫 BIOS 磁碟服務

    ; 檢查是否讀取成功
    jc disk_error   ; 如果讀取失敗，跳到錯誤處理

    ; 顯示讀取成功訊息
    mov si, success_msg
    call print_string

    ; 跳轉到讀取到的程式碼
    jmp 0x0600

disk_error:
    ; 顯示讀取錯誤訊息
    mov si, error_msg
    call print_string

    ; 停止系統
    hlt

print_string:
    lodsb           ; 加載 SI 指向的字元到 AL
    or al, al       ; 檢查是否到字串結尾
    jz return       ; 如果是 NULL，返回
    mov ah, 0x0E    ; BIOS 顯示字元功能
    int 0x10        ; 顯示字元
    jmp print_string ; 繼續顯示下一個字元
return:
    ret

msg db "Bootloader is running...", 0
read_msg db "Reading disk sectors...", 0
success_msg db "Disk read successfully!", 0
error_msg db "Disk read error! Halting.", 0

times 510-($-$$) db 0  ; 填充到 510 位元組
dw 0xAA55              ; 引導扇區標誌

