"""Execute compiled RV32I firmware with mocked MMIO; not an FPGA/CPU timing model."""
from pathlib import Path
from collections import deque
import struct
root=Path(__file__).resolve().parents[1]
image=(root/'firmware/nios_app.bin').read_bytes()
def signed(x,bits=32):return x-(1<<bits) if x&(1<<(bits-1)) else x
def run(jtag_mode):
 mem=bytearray(65536);mem[:len(image)]=image
 regs=[0]*32;pc=0;uart={};incoming=deque(range(256));rx=deque() if jtag_mode else deque(range(256))
 returned=[];display=[];tx=[];initial=[]
 def load(a,n):
  if a<65536:return int.from_bytes(mem[a:a+n],'little')
  if a==0x11000:return (incoming.popleft()|0x8000) if incoming else 0
  if a==0x11004:return 512<<16
  off=a-0x10000
  if off==8:return 2|(4 if rx else 0)
  if off==16:return rx.popleft() if rx else 0
  if off==36:return 256 if jtag_mode else 0
  if off==40:return 0
  return uart.get(off,0)
 def store(a,n,v):
  if a<65536:mem[a:a+n]=(v&((1<<(n*8))-1)).to_bytes(n,'little');return
  if a==0x11000:returned.append(v&255);return
  off=a-0x10000;uart[off]=v
  if off in [0,4,20,24]:initial.append((off,v))
  if off==12:
   tx.append(v&255)
   if jtag_mode:rx.append(v&255)
  if off==32:display.append(v&255)
 for step in range(200000):
  if len(display)==256 and (len(returned)==256 if jtag_mode else len(tx)==256):break
  ins=load(pc,4);op=ins&127;rd=(ins>>7)&31;f3=(ins>>12)&7;rs1=(ins>>15)&31;rs2=(ins>>20)&31;f7=ins>>25
  a,b=regs[rs1],regs[rs2];nxt=pc+4;v=None;imm=signed(ins>>20,12)
  if op==0x37:v=ins&0xfffff000
  elif op==0x17:v=pc+(ins&0xfffff000)
  elif op==0x6f:
   j=((ins>>31)<<20)|(((ins>>12)&255)<<12)|(((ins>>20)&1)<<11)|(((ins>>21)&1023)<<1)
   v=nxt;nxt=pc+signed(j,21)
  elif op==0x67:v=nxt;nxt=(a+imm)&~1
  elif op==0x63:
   j=((ins>>31)<<12)|(((ins>>7)&1)<<11)|(((ins>>25)&63)<<5)|(((ins>>8)&15)<<1)
   take={0:a==b,1:a!=b,4:signed(a)<signed(b),5:signed(a)>=signed(b),6:a<b,7:a>=b}[f3]
   if take:nxt=pc+signed(j,13)
  elif op==0x03:
   size={0:1,1:2,2:4,4:1,5:2}[f3];v=load((a+imm)&0xffffffff,size)
   if f3<4:v=signed(v,size*8)
  elif op==0x23:
   si=signed(((ins>>25)<<5)|((ins>>7)&31),12);store((a+si)&0xffffffff,{0:1,1:2,2:4}[f3],b)
  elif op==0x13:
   if f3==0:v=a+imm
   elif f3==1:v=a<<(rs2&31)
   elif f3==2:v=int(signed(a)<imm)
   elif f3==3:v=int(a<(imm&0xffffffff))
   elif f3==4:v=a^(imm&0xffffffff)
   elif f3==5:v=(signed(a) if f7==0x20 else a)>>(rs2&31)
   elif f3==6:v=a|(imm&0xffffffff)
   elif f3==7:v=a&(imm&0xffffffff)
  elif op==0x33:
   if f3==0:v=a-b if f7==0x20 else a+b
   elif f3==1:v=a<<(b&31)
   elif f3==2:v=int(signed(a)<signed(b))
   elif f3==3:v=int(a<b)
   elif f3==4:v=a^b
   elif f3==5:v=(signed(a) if f7==0x20 else a)>>(b&31)
   elif f3==6:v=a|b
   elif f3==7:v=a&b
  elif op==0x0f:pass
  else:raise RuntimeError(f'Unsupported instruction {ins:08x} at {pc:08x}')
  if rd and v is not None:regs[rd]=v&0xffffffff
  regs[0]=0;pc=nxt&0xffffffff
 else:raise RuntimeError('Firmware did not complete mocked I/O test')
 expected=list(range(256))
 assert display==expected and tx==expected
 if jtag_mode:assert returned==expected
 assert initial[:5]==[(0,0),(4,434),(20,0),(24,31),(0,35)]
 assert uart[36]==1
 print(f'PASS compiled RV32I firmware: {"JTAG via UART loopback" if jtag_mode else "RS232 echo"}, 256 ordered bytes; startup/MMIO initialization/LCD/TX checked, {step} instructions')
run(True);run(False)
# The 32-bit MIF words must reproduce every byte of the executable image.
mif=(root/'firmware.mif').read_text().splitlines()[5:-1]
words=bytearray()
for line in mif:words+=int(line.split(':')[1].strip(' ;'),16).to_bytes(4,'little')
assert words[:len(image)]==image
print('PASS MIF little-endian firmware content matches BIN')
