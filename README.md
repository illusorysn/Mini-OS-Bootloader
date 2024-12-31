# Mini-OS-Bootloader

Execution steps:  
nasm -f bin bootloader.asm -o bootloader.bin  
nasm -f bin stage2.asm -o stage2.bin  
  
//Create a blank disk image  
dd if=/dev/zero of=disk.img bs=512 count=100  
  
//Writing the Bootloader  
dd if=bootloader.bin of=disk.img bs=512 count=1 conv=notrunc  
  
//Writing the second stage code  
dd if=stage2.bin of=disk.img bs=512 seek=1 conv=notrunc  

//Testing with QEMU  
qemu-system-x86_64 -drive format=raw,file=disk.img  
  
![image](https://github.com/user-attachments/assets/95140a68-0e66-4f2e-b947-b9c96b4fc74f)
  
Basic Commands:  
Help: Display command instructions  
Clear: Clear the current screen  
Reboot: Reboot the system  
Memory: Displays the remaining memory  
Read: Read system data  
Write: Write system data  
