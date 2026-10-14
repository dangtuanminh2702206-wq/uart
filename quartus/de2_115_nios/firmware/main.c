#include <stdint.h>
#define UART_BASE 0x00010000u
#define JTAG_BASE 0x00011000u
#define REG(off) (*(volatile uint32_t *)(UART_BASE+(off)))
#define JREG(off) (*(volatile uint32_t *)(JTAG_BASE+(off)))
enum {CTRL=0,BAUD=4,STATUS=8,TXDATA=12,RXDATA=16,IRQEN=20,IRQSTAT=24,
      LCD=32,LEDS=36,BRIDGE_ERROR=40};
static int jtag_get(void) {
 uint32_t d=JREG(0);return (d & 0x8000u)?(int)(d & 255u):-1;
}
static int wait_status(uint32_t mask) {
 for(uint32_t t=0;t<1000000u;t++)if(REG(STATUS)&mask)return 1;
 return 0;
}
static int jtag_put(uint8_t b) {
 for(uint32_t t=0;t<1000000u;t++)if(JREG(4)>>16){JREG(0)=b;return 1;}
 return 0;
}
int main(void) {
 REG(CTRL)=0;REG(BAUD)=434;REG(IRQEN)=0;REG(IRQSTAT)=31;
 REG(BRIDGE_ERROR)=1;REG(CTRL)=0x23;
 int jtag_mode=(REG(LEDS)&0x100u)!=0;
 uint32_t errors=0;
 REG(LEDS)=1;
 for(;;) {
  int c;
  if(jtag_mode) {
   c=jtag_get();if(c<0)continue;
   if(!wait_status(2)){errors++;REG(LEDS)=3;continue;}
   REG(TXDATA)=(uint8_t)c;
   if(!wait_status(4)){errors++;REG(LEDS)=3;continue;}
   uint8_t received=(uint8_t)REG(RXDATA);
   REG(LCD)=received;
   if(received!=(uint8_t)c)errors++;
   if(!jtag_put(received))errors++;
  } else {
   uint32_t status=REG(STATUS);
   if(status&0x70u){errors++;REG(IRQSTAT)=31;}
   if(!(status&4u)){REG(LEDS)=errors?3:1;continue;}
   c=(uint8_t)REG(RXDATA);REG(LCD)=(uint8_t)c;
   if(wait_status(2))REG(TXDATA)=(uint8_t)c;else errors++;
  }
  if(REG(BRIDGE_ERROR))errors++;
  REG(LEDS)=errors?3:1;
 }
}
