from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[1]
tools=Path('C:/altera_lite/25.1std/riscfree/toolchain/riscv32-unknown-elf/bin')
out=root/'firmware'
args=[str(tools/'riscv32-unknown-elf-gcc.exe'),'-march=rv32i','-mabi=ilp32',
 '-Os','-Wall','-Wextra','-Werror','-ffreestanding','-fno-builtin','-msmall-data-limit=0',
 '-nostdlib','-Wl,--no-relax','-Wl,-Map='+str(out/'nios_app.map'),'-T',str(out/'linker.ld'),
 str(out/'start.S'),str(out/'main.c'),'-o',str(out/'nios_app.elf')]
subprocess.run(args,check=True)
subprocess.run([str(tools/'riscv32-unknown-elf-objcopy.exe'),'-O','binary',str(out/'nios_app.elf'),str(out/'nios_app.bin')],check=True)
subprocess.run([str(tools/'riscv32-unknown-elf-size.exe'),str(out/'nios_app.elf')],check=True)
data=(out/'nios_app.bin').read_bytes()
if len(data)>=65536-4096:raise RuntimeError('Firmware does not leave room for stack')
data=data.ljust(65536,b'\0')
with (root/'firmware.mif').open('w') as f:
 f.write('WIDTH=32;\nDEPTH=16384;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n')
 for addr in range(16384):f.write(f'{addr:04X} : {int.from_bytes(data[addr*4:addr*4+4],"little"):08X};\n')
 f.write('END;\n')
print('PASS firmware ELF/BIN/MIF generated; ISA RV32I, RAM 64KB')
