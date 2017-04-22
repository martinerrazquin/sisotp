
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f0100046:	b8 70 89 11 f0       	mov    $0xf0118970,%eax
f010004b:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 83 11 f0 	movl   $0xf0118300,(%esp)
f0100063:	e8 45 39 00 00       	call   f01039ad <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 89 06 00 00       	call   f01006f6 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 3e 10 f0 	movl   $0xf0103e40,(%esp)
f010007c:	e8 88 2e 00 00       	call   f0102f09 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 6a 2b 00 00       	call   f0102bf0 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 32 09 00 00       	call   f01009c4 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 89 11 f0 00 	cmpl   $0x0,0xf0118960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 89 11 f0    	mov    %esi,0xf0118960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 7c 3e 10 f0 	movl   $0xf0103e7c,(%esp)
f01000c8:	e8 3c 2e 00 00       	call   f0102f09 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 0a 2e 00 00       	call   f0102ee3 <vcprintf>
	cprintf("\n>>>\n");
f01000d9:	c7 04 24 5b 3e 10 f0 	movl   $0xf0103e5b,(%esp)
f01000e0:	e8 24 2e 00 00       	call   f0102f09 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 d3 08 00 00       	call   f01009c4 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 61 3e 10 f0 	movl   $0xf0103e61,(%esp)
f0100112:	e8 f2 2d 00 00       	call   f0102f09 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 bd 2d 00 00       	call   f0102ee3 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 f4 51 10 f0 	movl   $0xf01051f4,(%esp)
f010012d:	e8 d7 2d 00 00       	call   f0102f09 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    

f0100138 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0100138:	55                   	push   %ebp
f0100139:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010013b:	89 c2                	mov    %eax,%edx
f010013d:	ec                   	in     (%dx),%al
	return data;
}
f010013e:	5d                   	pop    %ebp
f010013f:	c3                   	ret    

f0100140 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp
f0100143:	89 c1                	mov    %eax,%ecx
f0100145:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100147:	89 ca                	mov    %ecx,%edx
f0100149:	ee                   	out    %al,(%dx)
}
f010014a:	5d                   	pop    %ebp
f010014b:	c3                   	ret    

f010014c <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f010014c:	55                   	push   %ebp
f010014d:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f010014f:	b8 84 00 00 00       	mov    $0x84,%eax
f0100154:	e8 df ff ff ff       	call   f0100138 <inb>
	inb(0x84);
f0100159:	b8 84 00 00 00       	mov    $0x84,%eax
f010015e:	e8 d5 ff ff ff       	call   f0100138 <inb>
	inb(0x84);
f0100163:	b8 84 00 00 00       	mov    $0x84,%eax
f0100168:	e8 cb ff ff ff       	call   f0100138 <inb>
	inb(0x84);
f010016d:	b8 84 00 00 00       	mov    $0x84,%eax
f0100172:	e8 c1 ff ff ff       	call   f0100138 <inb>
}
f0100177:	5d                   	pop    %ebp
f0100178:	c3                   	ret    

f0100179 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100179:	55                   	push   %ebp
f010017a:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010017c:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100181:	e8 b2 ff ff ff       	call   f0100138 <inb>
f0100186:	a8 01                	test   $0x1,%al
f0100188:	74 0f                	je     f0100199 <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f010018a:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010018f:	e8 a4 ff ff ff       	call   f0100138 <inb>
f0100194:	0f b6 c0             	movzbl %al,%eax
f0100197:	eb 05                	jmp    f010019e <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100199:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp
f01001a3:	56                   	push   %esi
f01001a4:	53                   	push   %ebx
f01001a5:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f01001a7:	bb 00 00 00 00       	mov    $0x0,%ebx
f01001ac:	eb 08                	jmp    f01001b6 <serial_putc+0x16>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001ae:	e8 99 ff ff ff       	call   f010014c <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01001b3:	83 c3 01             	add    $0x1,%ebx
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001b6:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01001bb:	e8 78 ff ff ff       	call   f0100138 <inb>
f01001c0:	a8 20                	test   $0x20,%al
f01001c2:	75 08                	jne    f01001cc <serial_putc+0x2c>
f01001c4:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01001ca:	7e e2                	jle    f01001ae <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001cc:	89 f0                	mov    %esi,%eax
f01001ce:	0f b6 d0             	movzbl %al,%edx
f01001d1:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001d6:	e8 65 ff ff ff       	call   f0100140 <outb>
}
f01001db:	5b                   	pop    %ebx
f01001dc:	5e                   	pop    %esi
f01001dd:	5d                   	pop    %ebp
f01001de:	c3                   	ret    

f01001df <serial_init>:

static void
serial_init(void)
{
f01001df:	55                   	push   %ebp
f01001e0:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f01001e2:	ba 00 00 00 00       	mov    $0x0,%edx
f01001e7:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01001ec:	e8 4f ff ff ff       	call   f0100140 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f01001f1:	ba 80 00 00 00       	mov    $0x80,%edx
f01001f6:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01001fb:	e8 40 ff ff ff       	call   f0100140 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f0100200:	ba 0c 00 00 00       	mov    $0xc,%edx
f0100205:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010020a:	e8 31 ff ff ff       	call   f0100140 <outb>
	outb(COM1+COM_DLM, 0);
f010020f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100214:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100219:	e8 22 ff ff ff       	call   f0100140 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f010021e:	ba 03 00 00 00       	mov    $0x3,%edx
f0100223:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f0100228:	e8 13 ff ff ff       	call   f0100140 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f010022d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100232:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f0100237:	e8 04 ff ff ff       	call   f0100140 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f010023c:	ba 01 00 00 00       	mov    $0x1,%edx
f0100241:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100246:	e8 f5 fe ff ff       	call   f0100140 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010024b:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100250:	e8 e3 fe ff ff       	call   f0100138 <inb>
f0100255:	3c ff                	cmp    $0xff,%al
f0100257:	0f 95 05 34 85 11 f0 	setne  0xf0118534
	(void) inb(COM1+COM_IIR);
f010025e:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100263:	e8 d0 fe ff ff       	call   f0100138 <inb>
	(void) inb(COM1+COM_RX);
f0100268:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010026d:	e8 c6 fe ff ff       	call   f0100138 <inb>

}
f0100272:	5d                   	pop    %ebp
f0100273:	c3                   	ret    

f0100274 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f0100274:	55                   	push   %ebp
f0100275:	89 e5                	mov    %esp,%ebp
f0100277:	56                   	push   %esi
f0100278:	53                   	push   %ebx
f0100279:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010027b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100280:	eb 08                	jmp    f010028a <lpt_putc+0x16>
		delay();
f0100282:	e8 c5 fe ff ff       	call   f010014c <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100287:	83 c3 01             	add    $0x1,%ebx
f010028a:	b8 79 03 00 00       	mov    $0x379,%eax
f010028f:	e8 a4 fe ff ff       	call   f0100138 <inb>
f0100294:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010029a:	7f 04                	jg     f01002a0 <lpt_putc+0x2c>
f010029c:	84 c0                	test   %al,%al
f010029e:	79 e2                	jns    f0100282 <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f01002a0:	89 f0                	mov    %esi,%eax
f01002a2:	0f b6 d0             	movzbl %al,%edx
f01002a5:	b8 78 03 00 00       	mov    $0x378,%eax
f01002aa:	e8 91 fe ff ff       	call   f0100140 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f01002af:	ba 0d 00 00 00       	mov    $0xd,%edx
f01002b4:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002b9:	e8 82 fe ff ff       	call   f0100140 <outb>
	outb(0x378+2, 0x08);
f01002be:	ba 08 00 00 00       	mov    $0x8,%edx
f01002c3:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002c8:	e8 73 fe ff ff       	call   f0100140 <outb>
}
f01002cd:	5b                   	pop    %ebx
f01002ce:	5e                   	pop    %esi
f01002cf:	5d                   	pop    %ebp
f01002d0:	c3                   	ret    

f01002d1 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002d1:	55                   	push   %ebp
f01002d2:	89 e5                	mov    %esp,%ebp
f01002d4:	57                   	push   %edi
f01002d5:	56                   	push   %esi
f01002d6:	53                   	push   %ebx
f01002d7:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002da:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002e1:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002e8:	5a a5 
	if (*cp != 0xA55A) {
f01002ea:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002f1:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002f5:	74 13                	je     f010030a <cga_init+0x39>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002f7:	c7 05 30 85 11 f0 b4 	movl   $0x3b4,0xf0118530
f01002fe:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100301:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
f0100308:	eb 18                	jmp    f0100322 <cga_init+0x51>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010030a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100311:	c7 05 30 85 11 f0 d4 	movl   $0x3d4,0xf0118530
f0100318:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010031b:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100322:	8b 35 30 85 11 f0    	mov    0xf0118530,%esi
f0100328:	ba 0e 00 00 00       	mov    $0xe,%edx
f010032d:	89 f0                	mov    %esi,%eax
f010032f:	e8 0c fe ff ff       	call   f0100140 <outb>
	pos = inb(addr_6845 + 1) << 8;
f0100334:	8d 7e 01             	lea    0x1(%esi),%edi
f0100337:	89 f8                	mov    %edi,%eax
f0100339:	e8 fa fd ff ff       	call   f0100138 <inb>
f010033e:	0f b6 d8             	movzbl %al,%ebx
f0100341:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f0100344:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100349:	89 f0                	mov    %esi,%eax
f010034b:	e8 f0 fd ff ff       	call   f0100140 <outb>
	pos |= inb(addr_6845 + 1);
f0100350:	89 f8                	mov    %edi,%eax
f0100352:	e8 e1 fd ff ff       	call   f0100138 <inb>

	crt_buf = (uint16_t*) cp;
f0100357:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f010035a:	89 0d 2c 85 11 f0    	mov    %ecx,0xf011852c
	crt_pos = pos;
f0100360:	0f b6 c0             	movzbl %al,%eax
f0100363:	09 c3                	or     %eax,%ebx
f0100365:	66 89 1d 28 85 11 f0 	mov    %bx,0xf0118528
}
f010036c:	83 c4 04             	add    $0x4,%esp
f010036f:	5b                   	pop    %ebx
f0100370:	5e                   	pop    %esi
f0100371:	5f                   	pop    %edi
f0100372:	5d                   	pop    %ebp
f0100373:	c3                   	ret    

f0100374 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100374:	55                   	push   %ebp
f0100375:	89 e5                	mov    %esp,%ebp
f0100377:	53                   	push   %ebx
f0100378:	83 ec 04             	sub    $0x4,%esp
f010037b:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010037d:	eb 2b                	jmp    f01003aa <cons_intr+0x36>
		if (c == 0)
f010037f:	85 c0                	test   %eax,%eax
f0100381:	74 27                	je     f01003aa <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100383:	8b 0d 24 85 11 f0    	mov    0xf0118524,%ecx
f0100389:	8d 51 01             	lea    0x1(%ecx),%edx
f010038c:	89 15 24 85 11 f0    	mov    %edx,0xf0118524
f0100392:	88 81 20 83 11 f0    	mov    %al,-0xfee7ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100398:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010039e:	75 0a                	jne    f01003aa <cons_intr+0x36>
			cons.wpos = 0;
f01003a0:	c7 05 24 85 11 f0 00 	movl   $0x0,0xf0118524
f01003a7:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01003aa:	ff d3                	call   *%ebx
f01003ac:	83 f8 ff             	cmp    $0xffffffff,%eax
f01003af:	75 ce                	jne    f010037f <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01003b1:	83 c4 04             	add    $0x4,%esp
f01003b4:	5b                   	pop    %ebx
f01003b5:	5d                   	pop    %ebp
f01003b6:	c3                   	ret    

f01003b7 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003b7:	55                   	push   %ebp
f01003b8:	89 e5                	mov    %esp,%ebp
f01003ba:	53                   	push   %ebx
f01003bb:	83 ec 04             	sub    $0x4,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f01003be:	b8 64 00 00 00       	mov    $0x64,%eax
f01003c3:	e8 70 fd ff ff       	call   f0100138 <inb>
	if ((stat & KBS_DIB) == 0)
f01003c8:	a8 01                	test   $0x1,%al
f01003ca:	0f 84 fe 00 00 00    	je     f01004ce <kbd_proc_data+0x117>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003d0:	a8 20                	test   $0x20,%al
f01003d2:	0f 85 fd 00 00 00    	jne    f01004d5 <kbd_proc_data+0x11e>
		return -1;

	data = inb(KBDATAP);
f01003d8:	b8 60 00 00 00       	mov    $0x60,%eax
f01003dd:	e8 56 fd ff ff       	call   f0100138 <inb>

	if (data == 0xE0) {
f01003e2:	3c e0                	cmp    $0xe0,%al
f01003e4:	75 11                	jne    f01003f7 <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f01003e6:	83 0d 00 83 11 f0 40 	orl    $0x40,0xf0118300
		return 0;
f01003ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01003f2:	e9 e7 00 00 00       	jmp    f01004de <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f01003f7:	84 c0                	test   %al,%al
f01003f9:	79 38                	jns    f0100433 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003fb:	8b 0d 00 83 11 f0    	mov    0xf0118300,%ecx
f0100401:	89 cb                	mov    %ecx,%ebx
f0100403:	83 e3 40             	and    $0x40,%ebx
f0100406:	89 c2                	mov    %eax,%edx
f0100408:	83 e2 7f             	and    $0x7f,%edx
f010040b:	85 db                	test   %ebx,%ebx
f010040d:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f0100410:	0f b6 c0             	movzbl %al,%eax
f0100413:	0f b6 80 00 40 10 f0 	movzbl -0xfefc000(%eax),%eax
f010041a:	83 c8 40             	or     $0x40,%eax
f010041d:	0f b6 c0             	movzbl %al,%eax
f0100420:	f7 d0                	not    %eax
f0100422:	21 c8                	and    %ecx,%eax
f0100424:	a3 00 83 11 f0       	mov    %eax,0xf0118300
		return 0;
f0100429:	b8 00 00 00 00       	mov    $0x0,%eax
f010042e:	e9 ab 00 00 00       	jmp    f01004de <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100433:	8b 15 00 83 11 f0    	mov    0xf0118300,%edx
f0100439:	f6 c2 40             	test   $0x40,%dl
f010043c:	74 0c                	je     f010044a <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010043e:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100441:	83 e2 bf             	and    $0xffffffbf,%edx
f0100444:	89 15 00 83 11 f0    	mov    %edx,0xf0118300
	}

	shift |= shiftcode[data];
f010044a:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010044d:	0f b6 90 00 40 10 f0 	movzbl -0xfefc000(%eax),%edx
f0100454:	0b 15 00 83 11 f0    	or     0xf0118300,%edx
f010045a:	0f b6 88 00 3f 10 f0 	movzbl -0xfefc100(%eax),%ecx
f0100461:	31 ca                	xor    %ecx,%edx
f0100463:	89 15 00 83 11 f0    	mov    %edx,0xf0118300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100469:	89 d1                	mov    %edx,%ecx
f010046b:	83 e1 03             	and    $0x3,%ecx
f010046e:	8b 0c 8d e0 3e 10 f0 	mov    -0xfefc120(,%ecx,4),%ecx
f0100475:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100479:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f010047c:	f6 c2 08             	test   $0x8,%dl
f010047f:	74 1b                	je     f010049c <kbd_proc_data+0xe5>
		if ('a' <= c && c <= 'z')
f0100481:	89 d8                	mov    %ebx,%eax
f0100483:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100486:	83 f9 19             	cmp    $0x19,%ecx
f0100489:	77 05                	ja     f0100490 <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f010048b:	83 eb 20             	sub    $0x20,%ebx
f010048e:	eb 0c                	jmp    f010049c <kbd_proc_data+0xe5>
		else if ('A' <= c && c <= 'Z')
f0100490:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100493:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100496:	83 f8 19             	cmp    $0x19,%eax
f0100499:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010049c:	f7 d2                	not    %edx
f010049e:	f6 c2 06             	test   $0x6,%dl
f01004a1:	75 39                	jne    f01004dc <kbd_proc_data+0x125>
f01004a3:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004a9:	75 31                	jne    f01004dc <kbd_proc_data+0x125>
		cprintf("Rebooting!\n");
f01004ab:	83 ec 0c             	sub    $0xc,%esp
f01004ae:	68 9c 3e 10 f0       	push   $0xf0103e9c
f01004b3:	e8 51 2a 00 00       	call   f0102f09 <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f01004b8:	ba 03 00 00 00       	mov    $0x3,%edx
f01004bd:	b8 92 00 00 00       	mov    $0x92,%eax
f01004c2:	e8 79 fc ff ff       	call   f0100140 <outb>
f01004c7:	83 c4 10             	add    $0x10,%esp
	}

	return c;
f01004ca:	89 d8                	mov    %ebx,%eax
f01004cc:	eb 10                	jmp    f01004de <kbd_proc_data+0x127>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004ce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004d3:	eb 09                	jmp    f01004de <kbd_proc_data+0x127>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004da:	eb 02                	jmp    f01004de <kbd_proc_data+0x127>
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01004dc:	89 d8                	mov    %ebx,%eax
}
f01004de:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01004e1:	c9                   	leave  
f01004e2:	c3                   	ret    

f01004e3 <cga_putc>:



static void
cga_putc(int c)
{
f01004e3:	55                   	push   %ebp
f01004e4:	89 e5                	mov    %esp,%ebp
f01004e6:	57                   	push   %edi
f01004e7:	56                   	push   %esi
f01004e8:	53                   	push   %ebx
f01004e9:	83 ec 0c             	sub    $0xc,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004ec:	89 c1                	mov    %eax,%ecx
f01004ee:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004f4:	89 c2                	mov    %eax,%edx
f01004f6:	80 ce 07             	or     $0x7,%dh
f01004f9:	85 c9                	test   %ecx,%ecx
f01004fb:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f01004fe:	0f b6 d0             	movzbl %al,%edx
f0100501:	83 fa 09             	cmp    $0x9,%edx
f0100504:	74 72                	je     f0100578 <cga_putc+0x95>
f0100506:	83 fa 09             	cmp    $0x9,%edx
f0100509:	7f 0a                	jg     f0100515 <cga_putc+0x32>
f010050b:	83 fa 08             	cmp    $0x8,%edx
f010050e:	74 14                	je     f0100524 <cga_putc+0x41>
f0100510:	e9 97 00 00 00       	jmp    f01005ac <cga_putc+0xc9>
f0100515:	83 fa 0a             	cmp    $0xa,%edx
f0100518:	74 38                	je     f0100552 <cga_putc+0x6f>
f010051a:	83 fa 0d             	cmp    $0xd,%edx
f010051d:	74 3b                	je     f010055a <cga_putc+0x77>
f010051f:	e9 88 00 00 00       	jmp    f01005ac <cga_putc+0xc9>
	case '\b':
		if (crt_pos > 0) {
f0100524:	0f b7 15 28 85 11 f0 	movzwl 0xf0118528,%edx
f010052b:	66 85 d2             	test   %dx,%dx
f010052e:	0f 84 e4 00 00 00    	je     f0100618 <cga_putc+0x135>
			crt_pos--;
f0100534:	83 ea 01             	sub    $0x1,%edx
f0100537:	66 89 15 28 85 11 f0 	mov    %dx,0xf0118528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010053e:	0f b7 d2             	movzwl %dx,%edx
f0100541:	b0 00                	mov    $0x0,%al
f0100543:	83 c8 20             	or     $0x20,%eax
f0100546:	8b 0d 2c 85 11 f0    	mov    0xf011852c,%ecx
f010054c:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100550:	eb 78                	jmp    f01005ca <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100552:	66 83 05 28 85 11 f0 	addw   $0x50,0xf0118528
f0100559:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010055a:	0f b7 05 28 85 11 f0 	movzwl 0xf0118528,%eax
f0100561:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100567:	c1 e8 16             	shr    $0x16,%eax
f010056a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010056d:	c1 e0 04             	shl    $0x4,%eax
f0100570:	66 a3 28 85 11 f0    	mov    %ax,0xf0118528
		break;
f0100576:	eb 52                	jmp    f01005ca <cga_putc+0xe7>
	case '\t':
		cons_putc(' ');
f0100578:	b8 20 00 00 00       	mov    $0x20,%eax
f010057d:	e8 da 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f0100582:	b8 20 00 00 00       	mov    $0x20,%eax
f0100587:	e8 d0 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f010058c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100591:	e8 c6 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f0100596:	b8 20 00 00 00       	mov    $0x20,%eax
f010059b:	e8 bc 00 00 00       	call   f010065c <cons_putc>
		cons_putc(' ');
f01005a0:	b8 20 00 00 00       	mov    $0x20,%eax
f01005a5:	e8 b2 00 00 00       	call   f010065c <cons_putc>
		break;
f01005aa:	eb 1e                	jmp    f01005ca <cga_putc+0xe7>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005ac:	0f b7 15 28 85 11 f0 	movzwl 0xf0118528,%edx
f01005b3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005b6:	66 89 0d 28 85 11 f0 	mov    %cx,0xf0118528
f01005bd:	0f b7 d2             	movzwl %dx,%edx
f01005c0:	8b 0d 2c 85 11 f0    	mov    0xf011852c,%ecx
f01005c6:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005ca:	66 81 3d 28 85 11 f0 	cmpw   $0x7cf,0xf0118528
f01005d1:	cf 07 
f01005d3:	76 43                	jbe    f0100618 <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005d5:	a1 2c 85 11 f0       	mov    0xf011852c,%eax
f01005da:	83 ec 04             	sub    $0x4,%esp
f01005dd:	68 00 0f 00 00       	push   $0xf00
f01005e2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005e8:	52                   	push   %edx
f01005e9:	50                   	push   %eax
f01005ea:	e8 0c 34 00 00       	call   f01039fb <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005ef:	8b 15 2c 85 11 f0    	mov    0xf011852c,%edx
f01005f5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005fb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100601:	83 c4 10             	add    $0x10,%esp
f0100604:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100609:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010060c:	39 d0                	cmp    %edx,%eax
f010060e:	75 f4                	jne    f0100604 <cga_putc+0x121>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100610:	66 83 2d 28 85 11 f0 	subw   $0x50,0xf0118528
f0100617:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100618:	8b 3d 30 85 11 f0    	mov    0xf0118530,%edi
f010061e:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100623:	89 f8                	mov    %edi,%eax
f0100625:	e8 16 fb ff ff       	call   f0100140 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f010062a:	0f b7 1d 28 85 11 f0 	movzwl 0xf0118528,%ebx
f0100631:	8d 77 01             	lea    0x1(%edi),%esi
f0100634:	0f b6 d7             	movzbl %bh,%edx
f0100637:	89 f0                	mov    %esi,%eax
f0100639:	e8 02 fb ff ff       	call   f0100140 <outb>
	outb(addr_6845, 15);
f010063e:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100643:	89 f8                	mov    %edi,%eax
f0100645:	e8 f6 fa ff ff       	call   f0100140 <outb>
	outb(addr_6845 + 1, crt_pos);
f010064a:	0f b6 d3             	movzbl %bl,%edx
f010064d:	89 f0                	mov    %esi,%eax
f010064f:	e8 ec fa ff ff       	call   f0100140 <outb>
}
f0100654:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100657:	5b                   	pop    %ebx
f0100658:	5e                   	pop    %esi
f0100659:	5f                   	pop    %edi
f010065a:	5d                   	pop    %ebp
f010065b:	c3                   	ret    

f010065c <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
f010065f:	53                   	push   %ebx
f0100660:	83 ec 04             	sub    $0x4,%esp
f0100663:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100665:	e8 36 fb ff ff       	call   f01001a0 <serial_putc>
	lpt_putc(c);
f010066a:	89 d8                	mov    %ebx,%eax
f010066c:	e8 03 fc ff ff       	call   f0100274 <lpt_putc>
	cga_putc(c);
f0100671:	89 d8                	mov    %ebx,%eax
f0100673:	e8 6b fe ff ff       	call   f01004e3 <cga_putc>
}
f0100678:	83 c4 04             	add    $0x4,%esp
f010067b:	5b                   	pop    %ebx
f010067c:	5d                   	pop    %ebp
f010067d:	c3                   	ret    

f010067e <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f010067e:	80 3d 34 85 11 f0 00 	cmpb   $0x0,0xf0118534
f0100685:	74 11                	je     f0100698 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100687:	55                   	push   %ebp
f0100688:	89 e5                	mov    %esp,%ebp
f010068a:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010068d:	b8 79 01 10 f0       	mov    $0xf0100179,%eax
f0100692:	e8 dd fc ff ff       	call   f0100374 <cons_intr>
}
f0100697:	c9                   	leave  
f0100698:	f3 c3                	repz ret 

f010069a <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010069a:	55                   	push   %ebp
f010069b:	89 e5                	mov    %esp,%ebp
f010069d:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01006a0:	b8 b7 03 10 f0       	mov    $0xf01003b7,%eax
f01006a5:	e8 ca fc ff ff       	call   f0100374 <cons_intr>
}
f01006aa:	c9                   	leave  
f01006ab:	c3                   	ret    

f01006ac <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01006ac:	55                   	push   %ebp
f01006ad:	89 e5                	mov    %esp,%ebp
f01006af:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01006b2:	e8 c7 ff ff ff       	call   f010067e <serial_intr>
	kbd_intr();
f01006b7:	e8 de ff ff ff       	call   f010069a <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01006bc:	a1 20 85 11 f0       	mov    0xf0118520,%eax
f01006c1:	3b 05 24 85 11 f0    	cmp    0xf0118524,%eax
f01006c7:	74 26                	je     f01006ef <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006c9:	8d 50 01             	lea    0x1(%eax),%edx
f01006cc:	89 15 20 85 11 f0    	mov    %edx,0xf0118520
f01006d2:	0f b6 88 20 83 11 f0 	movzbl -0xfee7ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01006d9:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01006db:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01006e1:	75 11                	jne    f01006f4 <cons_getc+0x48>
			cons.rpos = 0;
f01006e3:	c7 05 20 85 11 f0 00 	movl   $0x0,0xf0118520
f01006ea:	00 00 00 
f01006ed:	eb 05                	jmp    f01006f4 <cons_getc+0x48>
		return c;
	}
	return 0;
f01006ef:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01006f4:	c9                   	leave  
f01006f5:	c3                   	ret    

f01006f6 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01006f6:	55                   	push   %ebp
f01006f7:	89 e5                	mov    %esp,%ebp
f01006f9:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01006fc:	e8 d0 fb ff ff       	call   f01002d1 <cga_init>
	kbd_init();
	serial_init();
f0100701:	e8 d9 fa ff ff       	call   f01001df <serial_init>

	if (!serial_exists)
f0100706:	80 3d 34 85 11 f0 00 	cmpb   $0x0,0xf0118534
f010070d:	75 10                	jne    f010071f <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f010070f:	83 ec 0c             	sub    $0xc,%esp
f0100712:	68 a8 3e 10 f0       	push   $0xf0103ea8
f0100717:	e8 ed 27 00 00       	call   f0102f09 <cprintf>
f010071c:	83 c4 10             	add    $0x10,%esp
}
f010071f:	c9                   	leave  
f0100720:	c3                   	ret    

f0100721 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100721:	55                   	push   %ebp
f0100722:	89 e5                	mov    %esp,%ebp
f0100724:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100727:	8b 45 08             	mov    0x8(%ebp),%eax
f010072a:	e8 2d ff ff ff       	call   f010065c <cons_putc>
}
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <getchar>:

int
getchar(void)
{
f0100731:	55                   	push   %ebp
f0100732:	89 e5                	mov    %esp,%ebp
f0100734:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100737:	e8 70 ff ff ff       	call   f01006ac <cons_getc>
f010073c:	85 c0                	test   %eax,%eax
f010073e:	74 f7                	je     f0100737 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100740:	c9                   	leave  
f0100741:	c3                   	ret    

f0100742 <iscons>:

int
iscons(int fdnum)
{
f0100742:	55                   	push   %ebp
f0100743:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100745:	b8 01 00 00 00       	mov    $0x1,%eax
f010074a:	5d                   	pop    %ebp
f010074b:	c3                   	ret    

f010074c <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010074c:	55                   	push   %ebp
f010074d:	89 e5                	mov    %esp,%ebp
f010074f:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100752:	68 00 41 10 f0       	push   $0xf0104100
f0100757:	68 1e 41 10 f0       	push   $0xf010411e
f010075c:	68 23 41 10 f0       	push   $0xf0104123
f0100761:	e8 a3 27 00 00       	call   f0102f09 <cprintf>
f0100766:	83 c4 0c             	add    $0xc,%esp
f0100769:	68 c0 41 10 f0       	push   $0xf01041c0
f010076e:	68 2c 41 10 f0       	push   $0xf010412c
f0100773:	68 23 41 10 f0       	push   $0xf0104123
f0100778:	e8 8c 27 00 00       	call   f0102f09 <cprintf>
f010077d:	83 c4 0c             	add    $0xc,%esp
f0100780:	68 35 41 10 f0       	push   $0xf0104135
f0100785:	68 49 41 10 f0       	push   $0xf0104149
f010078a:	68 23 41 10 f0       	push   $0xf0104123
f010078f:	e8 75 27 00 00       	call   f0102f09 <cprintf>
	return 0;
}
f0100794:	b8 00 00 00 00       	mov    $0x0,%eax
f0100799:	c9                   	leave  
f010079a:	c3                   	ret    

f010079b <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010079b:	55                   	push   %ebp
f010079c:	89 e5                	mov    %esp,%ebp
f010079e:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007a1:	68 53 41 10 f0       	push   $0xf0104153
f01007a6:	e8 5e 27 00 00       	call   f0102f09 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ab:	83 c4 08             	add    $0x8,%esp
f01007ae:	68 0c 00 10 00       	push   $0x10000c
f01007b3:	68 e8 41 10 f0       	push   $0xf01041e8
f01007b8:	e8 4c 27 00 00       	call   f0102f09 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007bd:	83 c4 0c             	add    $0xc,%esp
f01007c0:	68 0c 00 10 00       	push   $0x10000c
f01007c5:	68 0c 00 10 f0       	push   $0xf010000c
f01007ca:	68 10 42 10 f0       	push   $0xf0104210
f01007cf:	e8 35 27 00 00       	call   f0102f09 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007d4:	83 c4 0c             	add    $0xc,%esp
f01007d7:	68 37 3e 10 00       	push   $0x103e37
f01007dc:	68 37 3e 10 f0       	push   $0xf0103e37
f01007e1:	68 34 42 10 f0       	push   $0xf0104234
f01007e6:	e8 1e 27 00 00       	call   f0102f09 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007eb:	83 c4 0c             	add    $0xc,%esp
f01007ee:	68 00 83 11 00       	push   $0x118300
f01007f3:	68 00 83 11 f0       	push   $0xf0118300
f01007f8:	68 58 42 10 f0       	push   $0xf0104258
f01007fd:	e8 07 27 00 00       	call   f0102f09 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100802:	83 c4 0c             	add    $0xc,%esp
f0100805:	68 70 89 11 00       	push   $0x118970
f010080a:	68 70 89 11 f0       	push   $0xf0118970
f010080f:	68 7c 42 10 f0       	push   $0xf010427c
f0100814:	e8 f0 26 00 00       	call   f0102f09 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100819:	b8 6f 8d 11 f0       	mov    $0xf0118d6f,%eax
f010081e:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100823:	83 c4 08             	add    $0x8,%esp
f0100826:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010082b:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100831:	85 c0                	test   %eax,%eax
f0100833:	0f 48 c2             	cmovs  %edx,%eax
f0100836:	c1 f8 0a             	sar    $0xa,%eax
f0100839:	50                   	push   %eax
f010083a:	68 a0 42 10 f0       	push   $0xf01042a0
f010083f:	e8 c5 26 00 00       	call   f0102f09 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100844:	b8 00 00 00 00       	mov    $0x0,%eax
f0100849:	c9                   	leave  
f010084a:	c3                   	ret    

f010084b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010084b:	55                   	push   %ebp
f010084c:	89 e5                	mov    %esp,%ebp
f010084e:	57                   	push   %edi
f010084f:	56                   	push   %esi
f0100850:	53                   	push   %ebx
f0100851:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100854:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0x0){
	uint32_t eip=*(uint32_t *)(ebp+4);
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100856:	8d 7d d0             	lea    -0x30(%ebp),%edi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100859:	eb 4a                	jmp    f01008a5 <mon_backtrace+0x5a>
	uint32_t eip=*(uint32_t *)(ebp+4);
f010085b:	8b 73 04             	mov    0x4(%ebx),%esi
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
f010085e:	ff 73 18             	pushl  0x18(%ebx)
f0100861:	ff 73 14             	pushl  0x14(%ebx)
f0100864:	ff 73 10             	pushl  0x10(%ebx)
f0100867:	ff 73 0c             	pushl  0xc(%ebx)
f010086a:	ff 73 08             	pushl  0x8(%ebx)
f010086d:	56                   	push   %esi
f010086e:	53                   	push   %ebx
f010086f:	68 cc 42 10 f0       	push   $0xf01042cc
f0100874:	e8 90 26 00 00       	call   f0102f09 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100879:	83 c4 18             	add    $0x18,%esp
f010087c:	57                   	push   %edi
f010087d:	56                   	push   %esi
f010087e:	e8 90 27 00 00       	call   f0103013 <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100883:	83 c4 08             	add    $0x8,%esp
f0100886:	2b 75 e0             	sub    -0x20(%ebp),%esi
f0100889:	56                   	push   %esi
f010088a:	ff 75 d8             	pushl  -0x28(%ebp)
f010088d:	ff 75 dc             	pushl  -0x24(%ebp)
f0100890:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100893:	ff 75 d0             	pushl  -0x30(%ebp)
f0100896:	68 6c 41 10 f0       	push   $0xf010416c
f010089b:	e8 69 26 00 00       	call   f0102f09 <cprintf>
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
f01008a0:	8b 1b                	mov    (%ebx),%ebx
f01008a2:	83 c4 20             	add    $0x20,%esp
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f01008a5:	85 db                	test   %ebx,%ebx
f01008a7:	75 b2                	jne    f010085b <mon_backtrace+0x10>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
	}
	return 0;
}
f01008a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008b1:	5b                   	pop    %ebx
f01008b2:	5e                   	pop    %esi
f01008b3:	5f                   	pop    %edi
f01008b4:	5d                   	pop    %ebp
f01008b5:	c3                   	ret    

f01008b6 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f01008b6:	55                   	push   %ebp
f01008b7:	89 e5                	mov    %esp,%ebp
f01008b9:	57                   	push   %edi
f01008ba:	56                   	push   %esi
f01008bb:	53                   	push   %ebx
f01008bc:	83 ec 5c             	sub    $0x5c,%esp
f01008bf:	89 c3                	mov    %eax,%ebx
f01008c1:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008c4:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008cb:	be 00 00 00 00       	mov    $0x0,%esi
f01008d0:	eb 0a                	jmp    f01008dc <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008d2:	c6 03 00             	movb   $0x0,(%ebx)
f01008d5:	89 f7                	mov    %esi,%edi
f01008d7:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008da:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008dc:	0f b6 03             	movzbl (%ebx),%eax
f01008df:	84 c0                	test   %al,%al
f01008e1:	74 6d                	je     f0100950 <runcmd+0x9a>
f01008e3:	83 ec 08             	sub    $0x8,%esp
f01008e6:	0f be c0             	movsbl %al,%eax
f01008e9:	50                   	push   %eax
f01008ea:	68 83 41 10 f0       	push   $0xf0104183
f01008ef:	e8 7c 30 00 00       	call   f0103970 <strchr>
f01008f4:	83 c4 10             	add    $0x10,%esp
f01008f7:	85 c0                	test   %eax,%eax
f01008f9:	75 d7                	jne    f01008d2 <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f01008fb:	0f b6 03             	movzbl (%ebx),%eax
f01008fe:	84 c0                	test   %al,%al
f0100900:	74 4e                	je     f0100950 <runcmd+0x9a>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100902:	83 fe 0f             	cmp    $0xf,%esi
f0100905:	75 1c                	jne    f0100923 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100907:	83 ec 08             	sub    $0x8,%esp
f010090a:	6a 10                	push   $0x10
f010090c:	68 88 41 10 f0       	push   $0xf0104188
f0100911:	e8 f3 25 00 00       	call   f0102f09 <cprintf>
			return 0;
f0100916:	83 c4 10             	add    $0x10,%esp
f0100919:	b8 00 00 00 00       	mov    $0x0,%eax
f010091e:	e9 99 00 00 00       	jmp    f01009bc <runcmd+0x106>
		}
		argv[argc++] = buf;
f0100923:	8d 7e 01             	lea    0x1(%esi),%edi
f0100926:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010092a:	eb 0a                	jmp    f0100936 <runcmd+0x80>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010092c:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010092f:	0f b6 03             	movzbl (%ebx),%eax
f0100932:	84 c0                	test   %al,%al
f0100934:	74 a4                	je     f01008da <runcmd+0x24>
f0100936:	83 ec 08             	sub    $0x8,%esp
f0100939:	0f be c0             	movsbl %al,%eax
f010093c:	50                   	push   %eax
f010093d:	68 83 41 10 f0       	push   $0xf0104183
f0100942:	e8 29 30 00 00       	call   f0103970 <strchr>
f0100947:	83 c4 10             	add    $0x10,%esp
f010094a:	85 c0                	test   %eax,%eax
f010094c:	74 de                	je     f010092c <runcmd+0x76>
f010094e:	eb 8a                	jmp    f01008da <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f0100950:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100957:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f0100958:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f010095d:	85 f6                	test   %esi,%esi
f010095f:	74 5b                	je     f01009bc <runcmd+0x106>
f0100961:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100966:	83 ec 08             	sub    $0x8,%esp
f0100969:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010096c:	ff 34 85 60 43 10 f0 	pushl  -0xfefbca0(,%eax,4)
f0100973:	ff 75 a8             	pushl  -0x58(%ebp)
f0100976:	e8 97 2f 00 00       	call   f0103912 <strcmp>
f010097b:	83 c4 10             	add    $0x10,%esp
f010097e:	85 c0                	test   %eax,%eax
f0100980:	75 1a                	jne    f010099c <runcmd+0xe6>
			return commands[i].func(argc, argv, tf);
f0100982:	83 ec 04             	sub    $0x4,%esp
f0100985:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100988:	ff 75 a4             	pushl  -0x5c(%ebp)
f010098b:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010098e:	52                   	push   %edx
f010098f:	56                   	push   %esi
f0100990:	ff 14 85 68 43 10 f0 	call   *-0xfefbc98(,%eax,4)
f0100997:	83 c4 10             	add    $0x10,%esp
f010099a:	eb 20                	jmp    f01009bc <runcmd+0x106>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010099c:	83 c3 01             	add    $0x1,%ebx
f010099f:	83 fb 03             	cmp    $0x3,%ebx
f01009a2:	75 c2                	jne    f0100966 <runcmd+0xb0>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009a4:	83 ec 08             	sub    $0x8,%esp
f01009a7:	ff 75 a8             	pushl  -0x58(%ebp)
f01009aa:	68 a5 41 10 f0       	push   $0xf01041a5
f01009af:	e8 55 25 00 00       	call   f0102f09 <cprintf>
	return 0;
f01009b4:	83 c4 10             	add    $0x10,%esp
f01009b7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01009bc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009bf:	5b                   	pop    %ebx
f01009c0:	5e                   	pop    %esi
f01009c1:	5f                   	pop    %edi
f01009c2:	5d                   	pop    %ebp
f01009c3:	c3                   	ret    

f01009c4 <monitor>:

void
monitor(struct Trapframe *tf)
{
f01009c4:	55                   	push   %ebp
f01009c5:	89 e5                	mov    %esp,%ebp
f01009c7:	53                   	push   %ebx
f01009c8:	83 ec 10             	sub    $0x10,%esp
f01009cb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009ce:	68 00 43 10 f0       	push   $0xf0104300
f01009d3:	e8 31 25 00 00       	call   f0102f09 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009d8:	c7 04 24 24 43 10 f0 	movl   $0xf0104324,(%esp)
f01009df:	e8 25 25 00 00       	call   f0102f09 <cprintf>
f01009e4:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009e7:	83 ec 0c             	sub    $0xc,%esp
f01009ea:	68 bb 41 10 f0       	push   $0xf01041bb
f01009ef:	e8 62 2d 00 00       	call   f0103756 <readline>
		if (buf != NULL)
f01009f4:	83 c4 10             	add    $0x10,%esp
f01009f7:	85 c0                	test   %eax,%eax
f01009f9:	74 ec                	je     f01009e7 <monitor+0x23>
			if (runcmd(buf, tf) < 0)
f01009fb:	89 da                	mov    %ebx,%edx
f01009fd:	e8 b4 fe ff ff       	call   f01008b6 <runcmd>
f0100a02:	85 c0                	test   %eax,%eax
f0100a04:	79 e1                	jns    f01009e7 <monitor+0x23>
				break;
	}
}
f0100a06:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a09:	c9                   	leave  
f0100a0a:	c3                   	ret    
f0100a0b:	66 90                	xchg   %ax,%ax
f0100a0d:	66 90                	xchg   %ax,%ax
f0100a0f:	90                   	nop

f0100a10 <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f0100a10:	55                   	push   %ebp
f0100a11:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100a13:	0f 01 38             	invlpg (%eax)
}
f0100a16:	5d                   	pop    %ebp
f0100a17:	c3                   	ret    

f0100a18 <lcr0>:
	asm volatile("ltr %0" : : "r" (sel));
}

static inline void
lcr0(uint32_t val)
{
f0100a18:	55                   	push   %ebp
f0100a19:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0100a1b:	0f 22 c0             	mov    %eax,%cr0
}
f0100a1e:	5d                   	pop    %ebp
f0100a1f:	c3                   	ret    

f0100a20 <rcr0>:

static inline uint32_t
rcr0(void)
{
f0100a20:	55                   	push   %ebp
f0100a21:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0100a23:	0f 20 c0             	mov    %cr0,%eax
	return val;
}
f0100a26:	5d                   	pop    %ebp
f0100a27:	c3                   	ret    

f0100a28 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0100a28:	55                   	push   %ebp
f0100a29:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100a2b:	0f 22 d8             	mov    %eax,%cr3
}
f0100a2e:	5d                   	pop    %ebp
f0100a2f:	c3                   	ret    

f0100a30 <page2pa>:

void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0100a30:	55                   	push   %ebp
f0100a31:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0100a33:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100a39:	c1 f8 03             	sar    $0x3,%eax
f0100a3c:	c1 e0 0c             	shl    $0xc,%eax
}
f0100a3f:	5d                   	pop    %ebp
f0100a40:	c3                   	ret    

f0100a41 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a41:	55                   	push   %ebp
f0100a42:	89 e5                	mov    %esp,%ebp
f0100a44:	56                   	push   %esi
f0100a45:	53                   	push   %ebx
f0100a46:	83 ec 10             	sub    $0x10,%esp
f0100a49:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a4b:	89 04 24             	mov    %eax,(%esp)
f0100a4e:	e8 3c 24 00 00       	call   f0102e8f <mc146818_read>
f0100a53:	89 c6                	mov    %eax,%esi
f0100a55:	83 c3 01             	add    $0x1,%ebx
f0100a58:	89 1c 24             	mov    %ebx,(%esp)
f0100a5b:	e8 2f 24 00 00       	call   f0102e8f <mc146818_read>
f0100a60:	c1 e0 08             	shl    $0x8,%eax
f0100a63:	09 f0                	or     %esi,%eax
}
f0100a65:	83 c4 10             	add    $0x10,%esp
f0100a68:	5b                   	pop    %ebx
f0100a69:	5e                   	pop    %esi
f0100a6a:	5d                   	pop    %ebp
f0100a6b:	c3                   	ret    

f0100a6c <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f0100a6c:	55                   	push   %ebp
f0100a6d:	89 e5                	mov    %esp,%ebp
f0100a6f:	56                   	push   %esi
f0100a70:	53                   	push   %ebx
f0100a71:	83 ec 10             	sub    $0x10,%esp
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100a74:	b8 15 00 00 00       	mov    $0x15,%eax
f0100a79:	e8 c3 ff ff ff       	call   f0100a41 <nvram_read>
f0100a7e:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100a80:	b8 17 00 00 00       	mov    $0x17,%eax
f0100a85:	e8 b7 ff ff ff       	call   f0100a41 <nvram_read>
f0100a8a:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100a8c:	b8 34 00 00 00       	mov    $0x34,%eax
f0100a91:	e8 ab ff ff ff       	call   f0100a41 <nvram_read>
f0100a96:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100a99:	85 c0                	test   %eax,%eax
f0100a9b:	74 07                	je     f0100aa4 <i386_detect_memory+0x38>
		totalmem = 16 * 1024 + ext16mem;
f0100a9d:	05 00 40 00 00       	add    $0x4000,%eax
f0100aa2:	eb 0b                	jmp    f0100aaf <i386_detect_memory+0x43>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100aa4:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100aaa:	85 f6                	test   %esi,%esi
f0100aac:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100aaf:	89 c2                	mov    %eax,%edx
f0100ab1:	c1 ea 02             	shr    $0x2,%edx
f0100ab4:	89 15 64 89 11 f0    	mov    %edx,0xf0118964
	npages_basemem = basemem / (PGSIZE / 1024);
f0100aba:	89 da                	mov    %ebx,%edx
f0100abc:	c1 ea 02             	shr    $0x2,%edx
f0100abf:	89 15 40 85 11 f0    	mov    %edx,0xf0118540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100ac5:	89 c2                	mov    %eax,%edx
f0100ac7:	29 da                	sub    %ebx,%edx
f0100ac9:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100acd:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100ad1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad5:	c7 04 24 84 43 10 f0 	movl   $0xf0104384,(%esp)
f0100adc:	e8 28 24 00 00       	call   f0102f09 <cprintf>
		totalmem, basemem, totalmem - basemem);
}
f0100ae1:	83 c4 10             	add    $0x10,%esp
f0100ae4:	5b                   	pop    %ebx
f0100ae5:	5e                   	pop    %esi
f0100ae6:	5d                   	pop    %ebp
f0100ae7:	c3                   	ret    

f0100ae8 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ae8:	83 3d 38 85 11 f0 00 	cmpl   $0x0,0xf0118538
f0100aef:	75 11                	jne    f0100b02 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100af1:	ba 6f 99 11 f0       	mov    $0xf011996f,%edx
f0100af6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100afc:	89 15 38 85 11 f0    	mov    %edx,0xf0118538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100b02:	85 c0                	test   %eax,%eax
f0100b04:	75 06                	jne    f0100b0c <boot_alloc+0x24>
f0100b06:	a1 38 85 11 f0       	mov    0xf0118538,%eax
f0100b0b:	c3                   	ret    
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100b0c:	8b 0d 38 85 11 f0    	mov    0xf0118538,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100b12:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100b18:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b1e:	01 ca                	add    %ecx,%edx
f0100b20:	89 15 38 85 11 f0    	mov    %edx,0xf0118538
	if ((uint32_t)(nextfree-KERNBASE)>npages*PGSIZE) panic("not enough memory\n");//como chequeo esto? Uso nextfree vs npages*PGSIZE?
f0100b26:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100b2c:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0100b31:	c1 e0 0c             	shl    $0xc,%eax
f0100b34:	39 c2                	cmp    %eax,%edx
f0100b36:	76 22                	jbe    f0100b5a <boot_alloc+0x72>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b38:	55                   	push   %ebp
f0100b39:	89 e5                	mov    %esp,%ebp
f0100b3b:	83 ec 18             	sub    $0x18,%esp
	// LAB 2: Your code here.
	if (n==0) return nextfree;
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	if ((uint32_t)(nextfree-KERNBASE)>npages*PGSIZE) panic("not enough memory\n");//como chequeo esto? Uso nextfree vs npages*PGSIZE?
f0100b3e:	c7 44 24 08 b0 4c 10 	movl   $0xf0104cb0,0x8(%esp)
f0100b45:	f0 
f0100b46:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
f0100b4d:	00 
f0100b4e:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100b55:	e8 3a f5 ff ff       	call   f0100094 <_panic>
	return (void*) result;
f0100b5a:	89 c8                	mov    %ecx,%eax
}
f0100b5c:	c3                   	ret    

f0100b5d <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100b5d:	55                   	push   %ebp
f0100b5e:	89 e5                	mov    %esp,%ebp
f0100b60:	53                   	push   %ebx
f0100b61:	83 ec 14             	sub    $0x14,%esp
	if (PGNUM(pa) >= npages)
f0100b64:	89 cb                	mov    %ecx,%ebx
f0100b66:	c1 eb 0c             	shr    $0xc,%ebx
f0100b69:	3b 1d 64 89 11 f0    	cmp    0xf0118964,%ebx
f0100b6f:	72 18                	jb     f0100b89 <_kaddr+0x2c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b71:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100b75:	c7 44 24 08 c0 43 10 	movl   $0xf01043c0,0x8(%esp)
f0100b7c:	f0 
f0100b7d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100b81:	89 04 24             	mov    %eax,(%esp)
f0100b84:	e8 0b f5 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100b89:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100b8f:	83 c4 14             	add    $0x14,%esp
f0100b92:	5b                   	pop    %ebx
f0100b93:	5d                   	pop    %ebp
f0100b94:	c3                   	ret    

f0100b95 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100b95:	55                   	push   %ebp
f0100b96:	89 e5                	mov    %esp,%ebp
f0100b98:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100b9b:	e8 90 fe ff ff       	call   f0100a30 <page2pa>
f0100ba0:	89 c1                	mov    %eax,%ecx
f0100ba2:	ba 54 00 00 00       	mov    $0x54,%edx
f0100ba7:	b8 cf 4c 10 f0       	mov    $0xf0104ccf,%eax
f0100bac:	e8 ac ff ff ff       	call   f0100b5d <_kaddr>
}
f0100bb1:	c9                   	leave  
f0100bb2:	c3                   	ret    

f0100bb3 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100bb3:	55                   	push   %ebp
f0100bb4:	89 e5                	mov    %esp,%ebp
f0100bb6:	56                   	push   %esi
f0100bb7:	53                   	push   %ebx
f0100bb8:	83 ec 10             	sub    $0x10,%esp
f0100bbb:	89 d6                	mov    %edx,%esi
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100bbd:	c1 ea 16             	shr    $0x16,%edx
f0100bc0:	8d 1c 90             	lea    (%eax,%edx,4),%ebx
	if (!(*pgdir & PTE_P)){
f0100bc3:	8b 0b                	mov    (%ebx),%ecx
f0100bc5:	f6 c1 01             	test   $0x1,%cl
f0100bc8:	75 2d                	jne    f0100bf7 <check_va2pa+0x44>
		cprintf("	caso 1\n");//DEBUG2
f0100bca:	c7 04 24 dd 4c 10 f0 	movl   $0xf0104cdd,(%esp)
f0100bd1:	e8 33 23 00 00       	call   f0102f09 <cprintf>
		cprintf("	*pgdir es %p, PTE_P es %p\n",*pgdir,PTE_P);//DEBUG2
f0100bd6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100bdd:	00 
f0100bde:	8b 03                	mov    (%ebx),%eax
f0100be0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100be4:	c7 04 24 e6 4c 10 f0 	movl   $0xf0104ce6,(%esp)
f0100beb:	e8 19 23 00 00       	call   f0102f09 <cprintf>
		return ~0;}
f0100bf0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bf5:	eb 60                	jmp    f0100c57 <check_va2pa+0xa4>
	if (*pgdir & PTE_PS){
f0100bf7:	f6 c1 80             	test   $0x80,%cl
f0100bfa:	74 1d                	je     f0100c19 <check_va2pa+0x66>
		cprintf("	caso 2\n");//DEBUG2
f0100bfc:	c7 04 24 02 4d 10 f0 	movl   $0xf0104d02,(%esp)
f0100c03:	e8 01 23 00 00       	call   f0102f09 <cprintf>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));}
f0100c08:	81 e6 ff ff 3f 00    	and    $0x3fffff,%esi
f0100c0e:	8b 03                	mov    (%ebx),%eax
f0100c10:	25 00 00 c0 ff       	and    $0xffc00000,%eax
f0100c15:	09 f0                	or     %esi,%eax
f0100c17:	eb 3e                	jmp    f0100c57 <check_va2pa+0xa4>
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100c19:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100c1f:	ba f5 02 00 00       	mov    $0x2f5,%edx
f0100c24:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f0100c29:	e8 2f ff ff ff       	call   f0100b5d <_kaddr>
	if (!(p[PTX(va)] & PTE_P)){
f0100c2e:	c1 ee 0c             	shr    $0xc,%esi
f0100c31:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100c37:	8b 14 b0             	mov    (%eax,%esi,4),%edx
		cprintf("	caso 3\n");//DEBUG2
		return ~0;}
	return PTE_ADDR(p[PTX(va)]);
f0100c3a:	89 d0                	mov    %edx,%eax
f0100c3c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
		return ~0;}
	if (*pgdir & PTE_PS){
		cprintf("	caso 2\n");//DEBUG2
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));}
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P)){
f0100c41:	f6 c2 01             	test   $0x1,%dl
f0100c44:	75 11                	jne    f0100c57 <check_va2pa+0xa4>
		cprintf("	caso 3\n");//DEBUG2
f0100c46:	c7 04 24 0b 4d 10 f0 	movl   $0xf0104d0b,(%esp)
f0100c4d:	e8 b7 22 00 00       	call   f0102f09 <cprintf>
		return ~0;}
f0100c52:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return PTE_ADDR(p[PTX(va)]);
}
f0100c57:	83 c4 10             	add    $0x10,%esp
f0100c5a:	5b                   	pop    %ebx
f0100c5b:	5e                   	pop    %esi
f0100c5c:	5d                   	pop    %ebp
f0100c5d:	c3                   	ret    

f0100c5e <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c5e:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100c64:	77 1e                	ja     f0100c84 <_paddr+0x26>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100c66:	55                   	push   %ebp
f0100c67:	89 e5                	mov    %esp,%ebp
f0100c69:	83 ec 18             	sub    $0x18,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c6c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c70:	c7 44 24 08 e4 43 10 	movl   $0xf01043e4,0x8(%esp)
f0100c77:	f0 
f0100c78:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c7c:	89 04 24             	mov    %eax,(%esp)
f0100c7f:	e8 10 f4 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100c84:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100c8a:	c3                   	ret    

f0100c8b <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100c8b:	55                   	push   %ebp
f0100c8c:	89 e5                	mov    %esp,%ebp
f0100c8e:	57                   	push   %edi
f0100c8f:	56                   	push   %esi
f0100c90:	53                   	push   %ebx
f0100c91:	83 ec 2c             	sub    $0x2c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100c94:	8b 1d 68 89 11 f0    	mov    0xf0118968,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100c9a:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0100c9f:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100ca6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cab:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0100cae:	be 00 00 00 00       	mov    $0x0,%esi
f0100cb3:	eb 54                	jmp    f0100d09 <check_kern_pgdir+0x7e>
f0100cb5:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100cbb:	89 d8                	mov    %ebx,%eax
f0100cbd:	e8 f1 fe ff ff       	call   f0100bb3 <check_va2pa>
f0100cc2:	89 c7                	mov    %eax,%edi
f0100cc4:	8b 0d 6c 89 11 f0    	mov    0xf011896c,%ecx
f0100cca:	ba c3 02 00 00       	mov    $0x2c3,%edx
f0100ccf:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f0100cd4:	e8 85 ff ff ff       	call   f0100c5e <_paddr>
f0100cd9:	01 f0                	add    %esi,%eax
f0100cdb:	39 c7                	cmp    %eax,%edi
f0100cdd:	74 24                	je     f0100d03 <check_kern_pgdir+0x78>
f0100cdf:	c7 44 24 0c 08 44 10 	movl   $0xf0104408,0xc(%esp)
f0100ce6:	f0 
f0100ce7:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0100cee:	f0 
f0100cef:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0100cf6:	00 
f0100cf7:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100cfe:	e8 91 f3 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100d03:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d09:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100d0c:	72 a7                	jb     f0100cb5 <check_kern_pgdir+0x2a>
f0100d0e:	be 00 00 00 00       	mov    $0x0,%esi
f0100d13:	eb 3b                	jmp    f0100d50 <check_kern_pgdir+0xc5>
f0100d15:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100d1b:	89 d8                	mov    %ebx,%eax
f0100d1d:	e8 91 fe ff ff       	call   f0100bb3 <check_va2pa>
f0100d22:	39 f0                	cmp    %esi,%eax
f0100d24:	74 24                	je     f0100d4a <check_kern_pgdir+0xbf>
f0100d26:	c7 44 24 0c 3c 44 10 	movl   $0xf010443c,0xc(%esp)
f0100d2d:	f0 
f0100d2e:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0100d35:	f0 
f0100d36:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
f0100d3d:	00 
f0100d3e:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100d45:	e8 4a f3 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100d4a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d50:	8b 15 64 89 11 f0    	mov    0xf0118964,%edx
f0100d56:	c1 e2 0c             	shl    $0xc,%edx
f0100d59:	39 d6                	cmp    %edx,%esi
f0100d5b:	72 b8                	jb     f0100d15 <check_kern_pgdir+0x8a>
f0100d5d:	be 00 00 00 00       	mov    $0x0,%esi
f0100d62:	8d 96 00 80 ff ef    	lea    -0x10008000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0100d68:	89 d8                	mov    %ebx,%eax
f0100d6a:	e8 44 fe ff ff       	call   f0100bb3 <check_va2pa>
f0100d6f:	89 c7                	mov    %eax,%edi
f0100d71:	b9 00 e0 10 f0       	mov    $0xf010e000,%ecx
f0100d76:	ba cc 02 00 00       	mov    $0x2cc,%edx
f0100d7b:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f0100d80:	e8 d9 fe ff ff       	call   f0100c5e <_paddr>
f0100d85:	01 f0                	add    %esi,%eax
f0100d87:	39 c7                	cmp    %eax,%edi
f0100d89:	74 24                	je     f0100daf <check_kern_pgdir+0x124>
f0100d8b:	c7 44 24 0c 64 44 10 	movl   $0xf0104464,0xc(%esp)
f0100d92:	f0 
f0100d93:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0100d9a:	f0 
f0100d9b:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f0100da2:	00 
f0100da3:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100daa:	e8 e5 f2 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100daf:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100db5:	81 fe 00 80 00 00    	cmp    $0x8000,%esi
f0100dbb:	75 a5                	jne    f0100d62 <check_kern_pgdir+0xd7>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0100dbd:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0100dc2:	89 d8                	mov    %ebx,%eax
f0100dc4:	e8 ea fd ff ff       	call   f0100bb3 <check_va2pa>
f0100dc9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100dcc:	75 0a                	jne    f0100dd8 <check_kern_pgdir+0x14d>
f0100dce:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dd3:	e9 f0 00 00 00       	jmp    f0100ec8 <check_kern_pgdir+0x23d>
f0100dd8:	c7 44 24 0c ac 44 10 	movl   $0xf01044ac,0xc(%esp)
f0100ddf:	f0 
f0100de0:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0100de7:	f0 
f0100de8:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0100def:	00 
f0100df0:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100df7:	e8 98 f2 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100dfc:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0100e01:	72 3c                	jb     f0100e3f <check_kern_pgdir+0x1b4>
f0100e03:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0100e08:	76 07                	jbe    f0100e11 <check_kern_pgdir+0x186>
f0100e0a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100e0f:	75 2e                	jne    f0100e3f <check_kern_pgdir+0x1b4>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0100e11:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0100e15:	0f 85 aa 00 00 00    	jne    f0100ec5 <check_kern_pgdir+0x23a>
f0100e1b:	c7 44 24 0c 29 4d 10 	movl   $0xf0104d29,0xc(%esp)
f0100e22:	f0 
f0100e23:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0100e2a:	f0 
f0100e2b:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f0100e32:	00 
f0100e33:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100e3a:	e8 55 f2 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100e3f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100e44:	76 55                	jbe    f0100e9b <check_kern_pgdir+0x210>
				assert(pgdir[i] & PTE_P);
f0100e46:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0100e49:	f6 c2 01             	test   $0x1,%dl
f0100e4c:	75 24                	jne    f0100e72 <check_kern_pgdir+0x1e7>
f0100e4e:	c7 44 24 0c 29 4d 10 	movl   $0xf0104d29,0xc(%esp)
f0100e55:	f0 
f0100e56:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0100e5d:	f0 
f0100e5e:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f0100e65:	00 
f0100e66:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100e6d:	e8 22 f2 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0100e72:	f6 c2 02             	test   $0x2,%dl
f0100e75:	75 4e                	jne    f0100ec5 <check_kern_pgdir+0x23a>
f0100e77:	c7 44 24 0c 3a 4d 10 	movl   $0xf0104d3a,0xc(%esp)
f0100e7e:	f0 
f0100e7f:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0100e86:	f0 
f0100e87:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f0100e8e:	00 
f0100e8f:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100e96:	e8 f9 f1 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0100e9b:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100e9f:	74 24                	je     f0100ec5 <check_kern_pgdir+0x23a>
f0100ea1:	c7 44 24 0c 4b 4d 10 	movl   $0xf0104d4b,0xc(%esp)
f0100ea8:	f0 
f0100ea9:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0100eb0:	f0 
f0100eb1:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0100eb8:	00 
f0100eb9:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100ec0:	e8 cf f1 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0100ec5:	83 c0 01             	add    $0x1,%eax
f0100ec8:	3d 00 04 00 00       	cmp    $0x400,%eax
f0100ecd:	0f 85 29 ff ff ff    	jne    f0100dfc <check_kern_pgdir+0x171>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0100ed3:	c7 04 24 dc 44 10 f0 	movl   $0xf01044dc,(%esp)
f0100eda:	e8 2a 20 00 00       	call   f0102f09 <cprintf>
}
f0100edf:	83 c4 2c             	add    $0x2c,%esp
f0100ee2:	5b                   	pop    %ebx
f0100ee3:	5e                   	pop    %esi
f0100ee4:	5f                   	pop    %edi
f0100ee5:	5d                   	pop    %ebp
f0100ee6:	c3                   	ret    

f0100ee7 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100ee7:	55                   	push   %ebp
f0100ee8:	89 e5                	mov    %esp,%ebp
f0100eea:	57                   	push   %edi
f0100eeb:	56                   	push   %esi
f0100eec:	53                   	push   %ebx
f0100eed:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ef0:	84 c0                	test   %al,%al
f0100ef2:	0f 85 aa 02 00 00    	jne    f01011a2 <check_page_free_list+0x2bb>
f0100ef8:	e9 b8 02 00 00       	jmp    f01011b5 <check_page_free_list+0x2ce>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100efd:	c7 44 24 08 fc 44 10 	movl   $0xf01044fc,0x8(%esp)
f0100f04:	f0 
f0100f05:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0100f0c:	00 
f0100f0d:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100f14:	e8 7b f1 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100f19:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100f1c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f1f:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100f22:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100f25:	89 d8                	mov    %ebx,%eax
f0100f27:	e8 04 fb ff ff       	call   f0100a30 <page2pa>
f0100f2c:	c1 e8 16             	shr    $0x16,%eax
f0100f2f:	85 c0                	test   %eax,%eax
f0100f31:	0f 95 c0             	setne  %al
f0100f34:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100f37:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f0100f3b:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100f3d:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f41:	8b 1b                	mov    (%ebx),%ebx
f0100f43:	85 db                	test   %ebx,%ebx
f0100f45:	75 de                	jne    f0100f25 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100f47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f4a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100f50:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f53:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f56:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f58:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f5b:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f60:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f65:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f0100f6b:	eb 2f                	jmp    f0100f9c <check_page_free_list+0xb5>
		if (PDX(page2pa(pp)) < pdx_limit)
f0100f6d:	89 d8                	mov    %ebx,%eax
f0100f6f:	e8 bc fa ff ff       	call   f0100a30 <page2pa>
f0100f74:	c1 e8 16             	shr    $0x16,%eax
f0100f77:	39 f0                	cmp    %esi,%eax
f0100f79:	73 1f                	jae    f0100f9a <check_page_free_list+0xb3>
			memset(page2kva(pp), 0x97, 128);
f0100f7b:	89 d8                	mov    %ebx,%eax
f0100f7d:	e8 13 fc ff ff       	call   f0100b95 <page2kva>
f0100f82:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100f89:	00 
f0100f8a:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100f91:	00 
f0100f92:	89 04 24             	mov    %eax,(%esp)
f0100f95:	e8 13 2a 00 00       	call   f01039ad <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f9a:	8b 1b                	mov    (%ebx),%ebx
f0100f9c:	85 db                	test   %ebx,%ebx
f0100f9e:	75 cd                	jne    f0100f6d <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100fa0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fa5:	e8 3e fb ff ff       	call   f0100ae8 <boot_alloc>
f0100faa:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fad:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100fb3:	8b 35 6c 89 11 f0    	mov    0xf011896c,%esi
		assert(pp < pages + npages);
f0100fb9:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0100fbe:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0100fc1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100fc4:	89 75 d0             	mov    %esi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100fc7:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100fce:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fd3:	e9 70 01 00 00       	jmp    f0101148 <check_page_free_list+0x261>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100fd8:	39 f3                	cmp    %esi,%ebx
f0100fda:	73 24                	jae    f0101000 <check_page_free_list+0x119>
f0100fdc:	c7 44 24 0c 59 4d 10 	movl   $0xf0104d59,0xc(%esp)
f0100fe3:	f0 
f0100fe4:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0100feb:	f0 
f0100fec:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0100ff3:	00 
f0100ff4:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0100ffb:	e8 94 f0 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0101000:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0101003:	72 24                	jb     f0101029 <check_page_free_list+0x142>
f0101005:	c7 44 24 0c 65 4d 10 	movl   $0xf0104d65,0xc(%esp)
f010100c:	f0 
f010100d:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101014:	f0 
f0101015:	c7 44 24 04 4e 02 00 	movl   $0x24e,0x4(%esp)
f010101c:	00 
f010101d:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101024:	e8 6b f0 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101029:	89 d8                	mov    %ebx,%eax
f010102b:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010102e:	a8 07                	test   $0x7,%al
f0101030:	74 24                	je     f0101056 <check_page_free_list+0x16f>
f0101032:	c7 44 24 0c 20 45 10 	movl   $0xf0104520,0xc(%esp)
f0101039:	f0 
f010103a:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101041:	f0 
f0101042:	c7 44 24 04 4f 02 00 	movl   $0x24f,0x4(%esp)
f0101049:	00 
f010104a:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101051:	e8 3e f0 ff ff       	call   f0100094 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101056:	89 d8                	mov    %ebx,%eax
f0101058:	e8 d3 f9 ff ff       	call   f0100a30 <page2pa>
f010105d:	85 c0                	test   %eax,%eax
f010105f:	75 24                	jne    f0101085 <check_page_free_list+0x19e>
f0101061:	c7 44 24 0c 79 4d 10 	movl   $0xf0104d79,0xc(%esp)
f0101068:	f0 
f0101069:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101070:	f0 
f0101071:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0101078:	00 
f0101079:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101080:	e8 0f f0 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101085:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f010108a:	75 24                	jne    f01010b0 <check_page_free_list+0x1c9>
f010108c:	c7 44 24 0c 8a 4d 10 	movl   $0xf0104d8a,0xc(%esp)
f0101093:	f0 
f0101094:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010109b:	f0 
f010109c:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f01010a3:	00 
f01010a4:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01010ab:	e8 e4 ef ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01010b0:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f01010b5:	75 24                	jne    f01010db <check_page_free_list+0x1f4>
f01010b7:	c7 44 24 0c 54 45 10 	movl   $0xf0104554,0xc(%esp)
f01010be:	f0 
f01010bf:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01010c6:	f0 
f01010c7:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f01010ce:	00 
f01010cf:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01010d6:	e8 b9 ef ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01010db:	3d 00 00 10 00       	cmp    $0x100000,%eax
f01010e0:	75 24                	jne    f0101106 <check_page_free_list+0x21f>
f01010e2:	c7 44 24 0c a3 4d 10 	movl   $0xf0104da3,0xc(%esp)
f01010e9:	f0 
f01010ea:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01010f1:	f0 
f01010f2:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f01010f9:	00 
f01010fa:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101101:	e8 8e ef ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101106:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f010110b:	76 30                	jbe    f010113d <check_page_free_list+0x256>
f010110d:	89 d8                	mov    %ebx,%eax
f010110f:	e8 81 fa ff ff       	call   f0100b95 <page2kva>
f0101114:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101117:	76 29                	jbe    f0101142 <check_page_free_list+0x25b>
f0101119:	c7 44 24 0c 78 45 10 	movl   $0xf0104578,0xc(%esp)
f0101120:	f0 
f0101121:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101128:	f0 
f0101129:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0101130:	00 
f0101131:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101138:	e8 57 ef ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f010113d:	83 c7 01             	add    $0x1,%edi
f0101140:	eb 04                	jmp    f0101146 <check_page_free_list+0x25f>
		else
			++nfree_extmem;
f0101142:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101146:	8b 1b                	mov    (%ebx),%ebx
f0101148:	85 db                	test   %ebx,%ebx
f010114a:	0f 85 88 fe ff ff    	jne    f0100fd8 <check_page_free_list+0xf1>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0101150:	85 ff                	test   %edi,%edi
f0101152:	7f 24                	jg     f0101178 <check_page_free_list+0x291>
f0101154:	c7 44 24 0c bd 4d 10 	movl   $0xf0104dbd,0xc(%esp)
f010115b:	f0 
f010115c:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101163:	f0 
f0101164:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f010116b:	00 
f010116c:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101173:	e8 1c ef ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0101178:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010117c:	7f 4e                	jg     f01011cc <check_page_free_list+0x2e5>
f010117e:	c7 44 24 0c cf 4d 10 	movl   $0xf0104dcf,0xc(%esp)
f0101185:	f0 
f0101186:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010118d:	f0 
f010118e:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0101195:	00 
f0101196:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010119d:	e8 f2 ee ff ff       	call   f0100094 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01011a2:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f01011a8:	85 db                	test   %ebx,%ebx
f01011aa:	0f 85 69 fd ff ff    	jne    f0100f19 <check_page_free_list+0x32>
f01011b0:	e9 48 fd ff ff       	jmp    f0100efd <check_page_free_list+0x16>
f01011b5:	83 3d 3c 85 11 f0 00 	cmpl   $0x0,0xf011853c
f01011bc:	0f 84 3b fd ff ff    	je     f0100efd <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01011c2:	be 00 04 00 00       	mov    $0x400,%esi
f01011c7:	e9 99 fd ff ff       	jmp    f0100f65 <check_page_free_list+0x7e>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f01011cc:	83 c4 3c             	add    $0x3c,%esp
f01011cf:	5b                   	pop    %ebx
f01011d0:	5e                   	pop    %esi
f01011d1:	5f                   	pop    %edi
f01011d2:	5d                   	pop    %ebp
f01011d3:	c3                   	ret    

f01011d4 <pa2page>:
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f01011d4:	55                   	push   %ebp
f01011d5:	89 e5                	mov    %esp,%ebp
f01011d7:	83 ec 18             	sub    $0x18,%esp
	if (PGNUM(pa) >= npages)
f01011da:	c1 e8 0c             	shr    $0xc,%eax
f01011dd:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f01011e3:	72 10                	jb     f01011f5 <pa2page+0x21>
		cprintf("PGNUM: %d\n",PGNUM(pa));
f01011e5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011e9:	c7 04 24 e0 4d 10 f0 	movl   $0xf0104de0,(%esp)
f01011f0:	e8 14 1d 00 00       	call   f0102f09 <cprintf>
		cprintf("npages %d\n",npages);
f01011f5:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f01011fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011fe:	c7 04 24 eb 4d 10 f0 	movl   $0xf0104deb,(%esp)
f0101205:	e8 ff 1c 00 00       	call   f0102f09 <cprintf>
		panic("pa2page called with invalid pa");
f010120a:	c7 44 24 08 c0 45 10 	movl   $0xf01045c0,0x8(%esp)
f0101211:	f0 
f0101212:	c7 44 24 04 4d 00 00 	movl   $0x4d,0x4(%esp)
f0101219:	00 
f010121a:	c7 04 24 cf 4c 10 f0 	movl   $0xf0104ccf,(%esp)
f0101221:	e8 6e ee ff ff       	call   f0100094 <_panic>

f0101226 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0101226:	55                   	push   %ebp
f0101227:	89 e5                	mov    %esp,%ebp
f0101229:	56                   	push   %esi
f010122a:	53                   	push   %ebx
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}*/ //FOR ORIGINAL
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f010122b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101230:	e8 b3 f8 ff ff       	call   f0100ae8 <boot_alloc>
f0101235:	89 c1                	mov    %eax,%ecx
f0101237:	ba 2c 01 00 00       	mov    $0x12c,%edx
f010123c:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f0101241:	e8 18 fa ff ff       	call   f0100c5e <_paddr>
f0101246:	c1 e8 0c             	shr    $0xc,%eax
f0101249:	8b 35 3c 85 11 f0    	mov    0xf011853c,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f010124f:	ba 01 00 00 00       	mov    $0x1,%edx
f0101254:	eb 2e                	jmp    f0101284 <page_init+0x5e>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f0101256:	39 c2                	cmp    %eax,%edx
f0101258:	73 08                	jae    f0101262 <page_init+0x3c>
f010125a:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0101260:	77 1f                	ja     f0101281 <page_init+0x5b>
f0101262:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
		pages[i].pp_ref = 0;
f0101269:	89 cb                	mov    %ecx,%ebx
f010126b:	03 1d 6c 89 11 f0    	add    0xf011896c,%ebx
f0101271:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0101277:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f0101279:	89 ce                	mov    %ecx,%esi
f010127b:	03 35 6c 89 11 f0    	add    0xf011896c,%esi
		page_free_list = &pages[i];
	}*/ //FOR ORIGINAL
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101281:	83 c2 01             	add    $0x1,%edx
f0101284:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f010128a:	72 ca                	jb     f0101256 <page_init+0x30>
f010128c:	89 35 3c 85 11 f0    	mov    %esi,0xf011853c
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0101292:	5b                   	pop    %ebx
f0101293:	5e                   	pop    %esi
f0101294:	5d                   	pop    %ebp
f0101295:	c3                   	ret    

f0101296 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f0101296:	55                   	push   %ebp
f0101297:	89 e5                	mov    %esp,%ebp
f0101299:	53                   	push   %ebx
f010129a:	83 ec 14             	sub    $0x14,%esp
f010129d:	8b 1d 3c 85 11 f0    	mov    0xf011853c,%ebx
f01012a3:	85 db                	test   %ebx,%ebx
f01012a5:	74 36                	je     f01012dd <page_alloc+0x47>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f01012a7:	8b 03                	mov    (%ebx),%eax
f01012a9:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
	pag->pp_link = NULL;
f01012ae:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
	return pag;
f01012b4:	89 d8                	mov    %ebx,%eax
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
	pag->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f01012b6:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01012ba:	74 26                	je     f01012e2 <page_alloc+0x4c>
f01012bc:	e8 d4 f8 ff ff       	call   f0100b95 <page2kva>
f01012c1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01012c8:	00 
f01012c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012d0:	00 
f01012d1:	89 04 24             	mov    %eax,(%esp)
f01012d4:	e8 d4 26 00 00       	call   f01039ad <memset>
	return pag;
f01012d9:	89 d8                	mov    %ebx,%eax
f01012db:	eb 05                	jmp    f01012e2 <page_alloc+0x4c>
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f01012dd:	b8 00 00 00 00       	mov    $0x0,%eax
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
	pag->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
	return pag;
}
f01012e2:	83 c4 14             	add    $0x14,%esp
f01012e5:	5b                   	pop    %ebx
f01012e6:	5d                   	pop    %ebp
f01012e7:	c3                   	ret    

f01012e8 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01012e8:	55                   	push   %ebp
f01012e9:	89 e5                	mov    %esp,%ebp
f01012eb:	83 ec 18             	sub    $0x18,%esp
f01012ee:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f01012f1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01012f6:	74 1c                	je     f0101314 <page_free+0x2c>
f01012f8:	c7 44 24 08 f6 4d 10 	movl   $0xf0104df6,0x8(%esp)
f01012ff:	f0 
f0101300:	c7 44 24 04 55 01 00 	movl   $0x155,0x4(%esp)
f0101307:	00 
f0101308:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010130f:	e8 80 ed ff ff       	call   f0100094 <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");//mejorar mensaje?
f0101314:	83 38 00             	cmpl   $0x0,(%eax)
f0101317:	74 1c                	je     f0101335 <page_free+0x4d>
f0101319:	c7 44 24 08 e0 45 10 	movl   $0xf01045e0,0x8(%esp)
f0101320:	f0 
f0101321:	c7 44 24 04 56 01 00 	movl   $0x156,0x4(%esp)
f0101328:	00 
f0101329:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101330:	e8 5f ed ff ff       	call   f0100094 <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f0101335:	8b 15 3c 85 11 f0    	mov    0xf011853c,%edx
f010133b:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f010133d:	a3 3c 85 11 f0       	mov    %eax,0xf011853c
}
f0101342:	c9                   	leave  
f0101343:	c3                   	ret    

f0101344 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f0101344:	55                   	push   %ebp
f0101345:	89 e5                	mov    %esp,%ebp
f0101347:	57                   	push   %edi
f0101348:	56                   	push   %esi
f0101349:	53                   	push   %ebx
f010134a:	83 ec 2c             	sub    $0x2c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010134d:	83 3d 6c 89 11 f0 00 	cmpl   $0x0,0xf011896c
f0101354:	75 1c                	jne    f0101372 <check_page_alloc+0x2e>
		panic("'pages' is a null pointer!");
f0101356:	c7 44 24 08 0a 4e 10 	movl   $0xf0104e0a,0x8(%esp)
f010135d:	f0 
f010135e:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f0101365:	00 
f0101366:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010136d:	e8 22 ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101372:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101377:	be 00 00 00 00       	mov    $0x0,%esi
f010137c:	eb 05                	jmp    f0101383 <check_page_alloc+0x3f>
		++nfree;
f010137e:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101381:	8b 00                	mov    (%eax),%eax
f0101383:	85 c0                	test   %eax,%eax
f0101385:	75 f7                	jne    f010137e <check_page_alloc+0x3a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101387:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010138e:	e8 03 ff ff ff       	call   f0101296 <page_alloc>
f0101393:	89 c7                	mov    %eax,%edi
f0101395:	85 c0                	test   %eax,%eax
f0101397:	75 24                	jne    f01013bd <check_page_alloc+0x79>
f0101399:	c7 44 24 0c 25 4e 10 	movl   $0xf0104e25,0xc(%esp)
f01013a0:	f0 
f01013a1:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01013a8:	f0 
f01013a9:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f01013b0:	00 
f01013b1:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01013b8:	e8 d7 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013c4:	e8 cd fe ff ff       	call   f0101296 <page_alloc>
f01013c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013cc:	85 c0                	test   %eax,%eax
f01013ce:	75 24                	jne    f01013f4 <check_page_alloc+0xb0>
f01013d0:	c7 44 24 0c 3b 4e 10 	movl   $0xf0104e3b,0xc(%esp)
f01013d7:	f0 
f01013d8:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01013df:	f0 
f01013e0:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f01013e7:	00 
f01013e8:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01013ef:	e8 a0 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01013f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013fb:	e8 96 fe ff ff       	call   f0101296 <page_alloc>
f0101400:	89 c3                	mov    %eax,%ebx
f0101402:	85 c0                	test   %eax,%eax
f0101404:	75 24                	jne    f010142a <check_page_alloc+0xe6>
f0101406:	c7 44 24 0c 51 4e 10 	movl   $0xf0104e51,0xc(%esp)
f010140d:	f0 
f010140e:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101415:	f0 
f0101416:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f010141d:	00 
f010141e:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101425:	e8 6a ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010142a:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f010142d:	75 24                	jne    f0101453 <check_page_alloc+0x10f>
f010142f:	c7 44 24 0c 67 4e 10 	movl   $0xf0104e67,0xc(%esp)
f0101436:	f0 
f0101437:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010143e:	f0 
f010143f:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f0101446:	00 
f0101447:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010144e:	e8 41 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101453:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101456:	74 04                	je     f010145c <check_page_alloc+0x118>
f0101458:	39 f8                	cmp    %edi,%eax
f010145a:	75 24                	jne    f0101480 <check_page_alloc+0x13c>
f010145c:	c7 44 24 0c 0c 46 10 	movl   $0xf010460c,0xc(%esp)
f0101463:	f0 
f0101464:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010146b:	f0 
f010146c:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0101473:	00 
f0101474:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010147b:	e8 14 ec ff ff       	call   f0100094 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101480:	89 f8                	mov    %edi,%eax
f0101482:	e8 a9 f5 ff ff       	call   f0100a30 <page2pa>
f0101487:	8b 0d 64 89 11 f0    	mov    0xf0118964,%ecx
f010148d:	c1 e1 0c             	shl    $0xc,%ecx
f0101490:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101493:	39 c8                	cmp    %ecx,%eax
f0101495:	72 24                	jb     f01014bb <check_page_alloc+0x177>
f0101497:	c7 44 24 0c 79 4e 10 	movl   $0xf0104e79,0xc(%esp)
f010149e:	f0 
f010149f:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01014a6:	f0 
f01014a7:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f01014ae:	00 
f01014af:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01014b6:	e8 d9 eb ff ff       	call   f0100094 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01014bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01014be:	e8 6d f5 ff ff       	call   f0100a30 <page2pa>
f01014c3:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01014c6:	77 24                	ja     f01014ec <check_page_alloc+0x1a8>
f01014c8:	c7 44 24 0c 96 4e 10 	movl   $0xf0104e96,0xc(%esp)
f01014cf:	f0 
f01014d0:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01014d7:	f0 
f01014d8:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f01014df:	00 
f01014e0:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01014e7:	e8 a8 eb ff ff       	call   f0100094 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01014ec:	89 d8                	mov    %ebx,%eax
f01014ee:	e8 3d f5 ff ff       	call   f0100a30 <page2pa>
f01014f3:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01014f6:	77 24                	ja     f010151c <check_page_alloc+0x1d8>
f01014f8:	c7 44 24 0c b3 4e 10 	movl   $0xf0104eb3,0xc(%esp)
f01014ff:	f0 
f0101500:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101507:	f0 
f0101508:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f010150f:	00 
f0101510:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101517:	e8 78 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010151c:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101521:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0101524:	c7 05 3c 85 11 f0 00 	movl   $0x0,0xf011853c
f010152b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010152e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101535:	e8 5c fd ff ff       	call   f0101296 <page_alloc>
f010153a:	85 c0                	test   %eax,%eax
f010153c:	74 24                	je     f0101562 <check_page_alloc+0x21e>
f010153e:	c7 44 24 0c d0 4e 10 	movl   $0xf0104ed0,0xc(%esp)
f0101545:	f0 
f0101546:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010154d:	f0 
f010154e:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
f0101555:	00 
f0101556:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010155d:	e8 32 eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101562:	89 3c 24             	mov    %edi,(%esp)
f0101565:	e8 7e fd ff ff       	call   f01012e8 <page_free>
	page_free(pp1);
f010156a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010156d:	89 04 24             	mov    %eax,(%esp)
f0101570:	e8 73 fd ff ff       	call   f01012e8 <page_free>
	page_free(pp2);
f0101575:	89 1c 24             	mov    %ebx,(%esp)
f0101578:	e8 6b fd ff ff       	call   f01012e8 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010157d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101584:	e8 0d fd ff ff       	call   f0101296 <page_alloc>
f0101589:	89 c3                	mov    %eax,%ebx
f010158b:	85 c0                	test   %eax,%eax
f010158d:	75 24                	jne    f01015b3 <check_page_alloc+0x26f>
f010158f:	c7 44 24 0c 25 4e 10 	movl   $0xf0104e25,0xc(%esp)
f0101596:	f0 
f0101597:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010159e:	f0 
f010159f:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f01015a6:	00 
f01015a7:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01015ae:	e8 e1 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015ba:	e8 d7 fc ff ff       	call   f0101296 <page_alloc>
f01015bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01015c2:	85 c0                	test   %eax,%eax
f01015c4:	75 24                	jne    f01015ea <check_page_alloc+0x2a6>
f01015c6:	c7 44 24 0c 3b 4e 10 	movl   $0xf0104e3b,0xc(%esp)
f01015cd:	f0 
f01015ce:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01015d5:	f0 
f01015d6:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f01015dd:	00 
f01015de:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01015e5:	e8 aa ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f1:	e8 a0 fc ff ff       	call   f0101296 <page_alloc>
f01015f6:	89 c7                	mov    %eax,%edi
f01015f8:	85 c0                	test   %eax,%eax
f01015fa:	75 24                	jne    f0101620 <check_page_alloc+0x2dc>
f01015fc:	c7 44 24 0c 51 4e 10 	movl   $0xf0104e51,0xc(%esp)
f0101603:	f0 
f0101604:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010160b:	f0 
f010160c:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0101613:	00 
f0101614:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010161b:	e8 74 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101620:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101623:	75 24                	jne    f0101649 <check_page_alloc+0x305>
f0101625:	c7 44 24 0c 67 4e 10 	movl   $0xf0104e67,0xc(%esp)
f010162c:	f0 
f010162d:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101634:	f0 
f0101635:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f010163c:	00 
f010163d:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101644:	e8 4b ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101649:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010164c:	74 04                	je     f0101652 <check_page_alloc+0x30e>
f010164e:	39 d8                	cmp    %ebx,%eax
f0101650:	75 24                	jne    f0101676 <check_page_alloc+0x332>
f0101652:	c7 44 24 0c 0c 46 10 	movl   $0xf010460c,0xc(%esp)
f0101659:	f0 
f010165a:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101661:	f0 
f0101662:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0101669:	00 
f010166a:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101671:	e8 1e ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101676:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010167d:	e8 14 fc ff ff       	call   f0101296 <page_alloc>
f0101682:	85 c0                	test   %eax,%eax
f0101684:	74 24                	je     f01016aa <check_page_alloc+0x366>
f0101686:	c7 44 24 0c d0 4e 10 	movl   $0xf0104ed0,0xc(%esp)
f010168d:	f0 
f010168e:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101695:	f0 
f0101696:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f010169d:	00 
f010169e:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01016a5:	e8 ea e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016aa:	89 d8                	mov    %ebx,%eax
f01016ac:	e8 e4 f4 ff ff       	call   f0100b95 <page2kva>
f01016b1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016b8:	00 
f01016b9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016c0:	00 
f01016c1:	89 04 24             	mov    %eax,(%esp)
f01016c4:	e8 e4 22 00 00       	call   f01039ad <memset>
	page_free(pp0);
f01016c9:	89 1c 24             	mov    %ebx,(%esp)
f01016cc:	e8 17 fc ff ff       	call   f01012e8 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016d1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016d8:	e8 b9 fb ff ff       	call   f0101296 <page_alloc>
f01016dd:	85 c0                	test   %eax,%eax
f01016df:	75 24                	jne    f0101705 <check_page_alloc+0x3c1>
f01016e1:	c7 44 24 0c df 4e 10 	movl   $0xf0104edf,0xc(%esp)
f01016e8:	f0 
f01016e9:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01016f0:	f0 
f01016f1:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f01016f8:	00 
f01016f9:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101700:	e8 8f e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101705:	39 c3                	cmp    %eax,%ebx
f0101707:	74 24                	je     f010172d <check_page_alloc+0x3e9>
f0101709:	c7 44 24 0c fd 4e 10 	movl   $0xf0104efd,0xc(%esp)
f0101710:	f0 
f0101711:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101718:	f0 
f0101719:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0101720:	00 
f0101721:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101728:	e8 67 e9 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
f010172d:	89 d8                	mov    %ebx,%eax
f010172f:	e8 61 f4 ff ff       	call   f0100b95 <page2kva>
	for (i = 0; i < PGSIZE; i++)
f0101734:	ba 00 00 00 00       	mov    $0x0,%edx
		assert(c[i] == 0);
f0101739:	80 3c 10 00          	cmpb   $0x0,(%eax,%edx,1)
f010173d:	74 24                	je     f0101763 <check_page_alloc+0x41f>
f010173f:	c7 44 24 0c 0d 4f 10 	movl   $0xf0104f0d,0xc(%esp)
f0101746:	f0 
f0101747:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010174e:	f0 
f010174f:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f0101756:	00 
f0101757:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010175e:	e8 31 e9 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101763:	83 c2 01             	add    $0x1,%edx
f0101766:	81 fa 00 10 00 00    	cmp    $0x1000,%edx
f010176c:	75 cb                	jne    f0101739 <check_page_alloc+0x3f5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010176e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101771:	a3 3c 85 11 f0       	mov    %eax,0xf011853c

	// free the pages we took
	page_free(pp0);
f0101776:	89 1c 24             	mov    %ebx,(%esp)
f0101779:	e8 6a fb ff ff       	call   f01012e8 <page_free>
	page_free(pp1);
f010177e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101781:	89 04 24             	mov    %eax,(%esp)
f0101784:	e8 5f fb ff ff       	call   f01012e8 <page_free>
	page_free(pp2);
f0101789:	89 3c 24             	mov    %edi,(%esp)
f010178c:	e8 57 fb ff ff       	call   f01012e8 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101791:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101796:	eb 05                	jmp    f010179d <check_page_alloc+0x459>
		--nfree;
f0101798:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010179b:	8b 00                	mov    (%eax),%eax
f010179d:	85 c0                	test   %eax,%eax
f010179f:	75 f7                	jne    f0101798 <check_page_alloc+0x454>
		--nfree;
	assert(nfree == 0);
f01017a1:	85 f6                	test   %esi,%esi
f01017a3:	74 24                	je     f01017c9 <check_page_alloc+0x485>
f01017a5:	c7 44 24 0c 17 4f 10 	movl   $0xf0104f17,0xc(%esp)
f01017ac:	f0 
f01017ad:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01017b4:	f0 
f01017b5:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f01017bc:	00 
f01017bd:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01017c4:	e8 cb e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017c9:	c7 04 24 2c 46 10 f0 	movl   $0xf010462c,(%esp)
f01017d0:	e8 34 17 00 00       	call   f0102f09 <cprintf>
}
f01017d5:	83 c4 2c             	add    $0x2c,%esp
f01017d8:	5b                   	pop    %ebx
f01017d9:	5e                   	pop    %esi
f01017da:	5f                   	pop    %edi
f01017db:	5d                   	pop    %ebp
f01017dc:	c3                   	ret    

f01017dd <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01017dd:	55                   	push   %ebp
f01017de:	89 e5                	mov    %esp,%ebp
f01017e0:	83 ec 18             	sub    $0x18,%esp
f01017e3:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01017e6:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01017ea:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01017ed:	66 89 50 04          	mov    %dx,0x4(%eax)
f01017f1:	66 85 d2             	test   %dx,%dx
f01017f4:	75 08                	jne    f01017fe <page_decref+0x21>
		page_free(pp);
f01017f6:	89 04 24             	mov    %eax,(%esp)
f01017f9:	e8 ea fa ff ff       	call   f01012e8 <page_free>
}
f01017fe:	c9                   	leave  
f01017ff:	c3                   	ret    

f0101800 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//*
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101800:	55                   	push   %ebp
f0101801:	89 e5                	mov    %esp,%ebp
f0101803:	57                   	push   %edi
f0101804:	56                   	push   %esi
f0101805:	53                   	push   %ebx
f0101806:	83 ec 1c             	sub    $0x1c,%esp
f0101809:	8b 75 0c             	mov    0xc(%ebp),%esi
	
	pde_t pde =  pgdir[PDX(va)]; //ojo que esto es P.Addr. !!
f010180c:	89 f7                	mov    %esi,%edi
f010180e:	c1 ef 16             	shr    $0x16,%edi
f0101811:	c1 e7 02             	shl    $0x2,%edi
f0101814:	03 7d 08             	add    0x8(%ebp),%edi
f0101817:	8b 0f                	mov    (%edi),%ecx
	if (pde & PTE_P) return (pte_t*) KADDR(PTE_ADDR(pde)+PTX(va));
f0101819:	f6 c1 01             	test   $0x1,%cl
f010181c:	74 22                	je     f0101840 <pgdir_walk+0x40>
f010181e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101824:	c1 ee 0c             	shr    $0xc,%esi
f0101827:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f010182d:	01 f1                	add    %esi,%ecx
f010182f:	ba 82 01 00 00       	mov    $0x182,%edx
f0101834:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f0101839:	e8 1f f3 ff ff       	call   f0100b5d <_kaddr>
f010183e:	eb 51                	jmp    f0101891 <pgdir_walk+0x91>

	if (!create) return NULL;
f0101840:	b8 00 00 00 00       	mov    $0x0,%eax
f0101845:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101849:	74 46                	je     f0101891 <pgdir_walk+0x91>
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f010184b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101852:	e8 3f fa ff ff       	call   f0101296 <page_alloc>
f0101857:	89 c3                	mov    %eax,%ebx
	if (page==NULL) return NULL;
f0101859:	85 c0                	test   %eax,%eax
f010185b:	74 2f                	je     f010188c <pgdir_walk+0x8c>
	physaddr_t pt_start = page2pa(page);
f010185d:	e8 ce f1 ff ff       	call   f0100a30 <page2pa>
	page->pp_ref ++;
f0101862:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
f0101867:	89 c2                	mov    %eax,%edx
f0101869:	83 ca 07             	or     $0x7,%edx
f010186c:	89 17                	mov    %edx,(%edi)
	return (pte_t*) KADDR(pt_start+PTX(va));
f010186e:	c1 ee 0c             	shr    $0xc,%esi
f0101871:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0101877:	89 f1                	mov    %esi,%ecx
f0101879:	01 c1                	add    %eax,%ecx
f010187b:	ba 8a 01 00 00       	mov    $0x18a,%edx
f0101880:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f0101885:	e8 d3 f2 ff ff       	call   f0100b5d <_kaddr>
f010188a:	eb 05                	jmp    f0101891 <pgdir_walk+0x91>
	pde_t pde =  pgdir[PDX(va)]; //ojo que esto es P.Addr. !!
	if (pde & PTE_P) return (pte_t*) KADDR(PTE_ADDR(pde)+PTX(va));

	if (!create) return NULL;
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if (page==NULL) return NULL;
f010188c:	b8 00 00 00 00       	mov    $0x0,%eax
	physaddr_t pt_start = page2pa(page);
	page->pp_ref ++;
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
	return (pte_t*) KADDR(pt_start+PTX(va));
	
}
f0101891:	83 c4 1c             	add    $0x1c,%esp
f0101894:	5b                   	pop    %ebx
f0101895:	5e                   	pop    %esi
f0101896:	5f                   	pop    %edi
f0101897:	5d                   	pop    %ebp
f0101898:	c3                   	ret    

f0101899 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101899:	55                   	push   %ebp
f010189a:	89 e5                	mov    %esp,%ebp
f010189c:	57                   	push   %edi
f010189d:	56                   	push   %esi
f010189e:	53                   	push   %ebx
f010189f:	83 ec 1c             	sub    $0x1c,%esp
f01018a2:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *page_entry = pgdir_walk(pgdir, va, false);	//Busco la PTE
f01018a5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01018ac:	00 
f01018ad:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01018b4:	89 04 24             	mov    %eax,(%esp)
f01018b7:	e8 44 ff ff ff       	call   f0101800 <pgdir_walk>
f01018bc:	89 c3                	mov    %eax,%ebx
	if (page_entry == 0){
f01018be:	85 c0                	test   %eax,%eax
f01018c0:	74 5e                	je     f0101920 <page_lookup+0x87>
		return NULL;
	}
	physaddr_t physical_page = PTE_ADDR(*page_entry);	//consigo el addres
f01018c2:	8b 38                	mov    (%eax),%edi
f01018c4:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	cprintf("En lookup, la va es %p\n", va);
f01018ca:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018ce:	c7 04 24 22 4f 10 f0 	movl   $0xf0104f22,(%esp)
f01018d5:	e8 2f 16 00 00       	call   f0102f09 <cprintf>
	cprintf("En lookup, la PTE es %p\n", page_entry);
f01018da:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01018de:	c7 04 24 3a 4f 10 f0 	movl   $0xf0104f3a,(%esp)
f01018e5:	e8 1f 16 00 00       	call   f0102f09 <cprintf>
	physaddr_t physical_direction = physical_page | PGOFF(va);	//formo la direccion fisica conb lo anterir OR offset
f01018ea:	81 e6 ff 0f 00 00    	and    $0xfff,%esi
f01018f0:	09 fe                	or     %edi,%esi
	cprintf("En lookup, la pa es %p\n", physical_direction);
f01018f2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018f6:	c7 04 24 53 4f 10 f0 	movl   $0xf0104f53,(%esp)
f01018fd:	e8 07 16 00 00       	call   f0102f09 <cprintf>
	if (pte_store != NULL){
f0101902:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101906:	74 11                	je     f0101919 <page_lookup+0x80>
		cprintf("lookup con pte_store!=0, qcyo\n");//DEBUG2
f0101908:	c7 04 24 4c 46 10 f0 	movl   $0xf010464c,(%esp)
f010190f:	e8 f5 15 00 00       	call   f0102f09 <cprintf>
		*pte_store = page_entry;//DEBUG2 bien?
f0101914:	8b 45 10             	mov    0x10(%ebp),%eax
f0101917:	89 18                	mov    %ebx,(%eax)
	}
	return pa2page(physical_direction); 
f0101919:	89 f0                	mov    %esi,%eax
f010191b:	e8 b4 f8 ff ff       	call   f01011d4 <pa2page>
}	
f0101920:	b8 00 00 00 00       	mov    $0x0,%eax
f0101925:	83 c4 1c             	add    $0x1c,%esp
f0101928:	5b                   	pop    %ebx
f0101929:	5e                   	pop    %esi
f010192a:	5f                   	pop    %edi
f010192b:	5d                   	pop    %ebp
f010192c:	c3                   	ret    

f010192d <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010192d:	55                   	push   %ebp
f010192e:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f0101930:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101933:	e8 d8 f0 ff ff       	call   f0100a10 <invlpg>
}
f0101938:	5d                   	pop    %ebp
f0101939:	c3                   	ret    

f010193a <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010193a:	55                   	push   %ebp
f010193b:	89 e5                	mov    %esp,%ebp
f010193d:	57                   	push   %edi
f010193e:	56                   	push   %esi
f010193f:	53                   	push   %ebx
f0101940:	83 ec 2c             	sub    $0x2c,%esp
f0101943:	8b 75 08             	mov    0x8(%ebp),%esi
f0101946:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t* page_entry;
	struct PageInfo* page = page_lookup(pgdir, va, &page_entry);
f0101949:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010194c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101950:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101954:	89 34 24             	mov    %esi,(%esp)
f0101957:	e8 3d ff ff ff       	call   f0101899 <page_lookup>
f010195c:	89 c3                	mov    %eax,%ebx
	if(page == NULL){
f010195e:	85 c0                	test   %eax,%eax
f0101960:	75 16                	jne    f0101978 <page_remove+0x3e>
		cprintf("en remove, page es NULL\n",page);//DEBUG2
f0101962:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101969:	00 
f010196a:	c7 04 24 6b 4f 10 f0 	movl   $0xf0104f6b,(%esp)
f0101971:	e8 93 15 00 00       	call   f0102f09 <cprintf>
f0101976:	eb 2d                	jmp    f01019a5 <page_remove+0x6b>
		return;
	}
	cprintf("en remove page_lookup da %p\n",page);//DEBUG2
f0101978:	89 44 24 04          	mov    %eax,0x4(%esp)
f010197c:	c7 04 24 84 4f 10 f0 	movl   $0xf0104f84,(%esp)
f0101983:	e8 81 15 00 00       	call   f0102f09 <cprintf>
	*page_entry = 0;
f0101988:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010198b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	page_decref(page);
f0101991:	89 1c 24             	mov    %ebx,(%esp)
f0101994:	e8 44 fe ff ff       	call   f01017dd <page_decref>
	tlb_invalidate(pgdir,va);
f0101999:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010199d:	89 34 24             	mov    %esi,(%esp)
f01019a0:	e8 88 ff ff ff       	call   f010192d <tlb_invalidate>
}
f01019a5:	83 c4 2c             	add    $0x2c,%esp
f01019a8:	5b                   	pop    %ebx
f01019a9:	5e                   	pop    %esi
f01019aa:	5f                   	pop    %edi
f01019ab:	5d                   	pop    %ebp
f01019ac:	c3                   	ret    

f01019ad <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01019ad:	55                   	push   %ebp
f01019ae:	89 e5                	mov    %esp,%ebp
f01019b0:	57                   	push   %edi
f01019b1:	56                   	push   %esi
f01019b2:	53                   	push   %ebx
f01019b3:	83 ec 1c             	sub    $0x1c,%esp
f01019b6:	8b 5d 10             	mov    0x10(%ebp),%ebx

	physaddr_t page_PA = page2pa(pp);
f01019b9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01019bc:	e8 6f f0 ff ff       	call   f0100a30 <page2pa>
f01019c1:	89 c7                	mov    %eax,%edi
	cprintf("page_PA es %p\n",page_PA);
f01019c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019c7:	c7 04 24 a1 4f 10 f0 	movl   $0xf0104fa1,(%esp)
f01019ce:	e8 36 15 00 00       	call   f0102f09 <cprintf>
	pte_t *page_entry = pgdir_walk(pgdir, va, true);
f01019d3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01019da:	00 
f01019db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019df:	8b 45 08             	mov    0x8(%ebp),%eax
f01019e2:	89 04 24             	mov    %eax,(%esp)
f01019e5:	e8 16 fe ff ff       	call   f0101800 <pgdir_walk>
f01019ea:	89 c6                	mov    %eax,%esi
	if (page_entry == NULL){
f01019ec:	85 c0                	test   %eax,%eax
f01019ee:	0f 84 d9 00 00 00    	je     f0101acd <page_insert+0x120>
		return -E_NO_MEM;
	}
	if ((*page_entry&PTE_P) == PTE_P){			//DEBUG2: para que esta este if?
f01019f4:	8b 00                	mov    (%eax),%eax
f01019f6:	a8 01                	test   $0x1,%al
f01019f8:	74 53                	je     f0101a4d <page_insert+0xa0>
							cprintf("	En insert la PTE_ADDR(page_entry) es %p\n",PTE_ADDR(*page_entry));//DEBUG2
f01019fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01019ff:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a03:	c7 04 24 6c 46 10 f0 	movl   $0xf010466c,(%esp)
f0101a0a:	e8 fa 14 00 00       	call   f0102f09 <cprintf>
							cprintf("	En insert la page_entry es %p\n",page_entry);//DEBUG2
f0101a0f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101a13:	c7 04 24 98 46 10 f0 	movl   $0xf0104698,(%esp)
f0101a1a:	e8 ea 14 00 00       	call   f0102f09 <cprintf>
		page_remove(pgdir,va);
f0101a1f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a23:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a26:	89 04 24             	mov    %eax,(%esp)
f0101a29:	e8 0c ff ff ff       	call   f010193a <page_remove>
							//ATENCION: aca modifica el pgdir
							cprintf("	En insert antes *(pgdir+PDX(va)) = %p y va = %p\n",*(pgdir+PDX(va)),va);//DEBUG2
f0101a2e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101a32:	89 d8                	mov    %ebx,%eax
f0101a34:	c1 e8 16             	shr    $0x16,%eax
f0101a37:	8b 55 08             	mov    0x8(%ebp),%edx
f0101a3a:	8b 04 82             	mov    (%edx,%eax,4),%eax
f0101a3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a41:	c7 04 24 b8 46 10 f0 	movl   $0xf01046b8,(%esp)
f0101a48:	e8 bc 14 00 00       	call   f0102f09 <cprintf>
								*(pgdir+PDX(va)) &= 0xFFF;//maskeo los flags, borro el resto
								*(pgdir+PDX(va)) = (PADDR((void*) PTE_ADDR(page_entry)) | PTE_P | perm);
							*/
		}
		//cprintf("	y ahora tengo *(pgdir+PDX(va)) = %p\n", *(pgdir+PDX(va)));//DEBUG2
							cprintf("insert: page entry entry: %p\n",(page_PA & ~0xFFF) | (PTE_P|perm));
f0101a4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a50:	83 c8 01             	or     $0x1,%eax
f0101a53:	89 c1                	mov    %eax,%ecx
f0101a55:	89 f8                	mov    %edi,%eax
f0101a57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101a5c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101a5f:	09 c8                	or     %ecx,%eax
f0101a61:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a65:	c7 04 24 b0 4f 10 f0 	movl   $0xf0104fb0,(%esp)
f0101a6c:	e8 98 14 00 00       	call   f0102f09 <cprintf>
	*page_entry = (page_PA | PTE_P|perm);		// page_PA OR ~0xFFF me da los 20bits mas altos. 						
f0101a71:	0b 7d e4             	or     -0x1c(%ebp),%edi
f0101a74:	89 3e                	mov    %edi,(%esi)
											//El otro OR me genera los permisos.
											//El OR entre ambos me deja seteado el PTE.
	cprintf("En insert *page_entry es %p\n",*page_entry);
f0101a76:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101a7a:	c7 04 24 ce 4f 10 f0 	movl   $0xf0104fce,(%esp)
f0101a81:	e8 83 14 00 00       	call   f0102f09 <cprintf>
	cprintf("En insert va es %p",va);
f0101a86:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a8a:	c7 04 24 eb 4f 10 f0 	movl   $0xf0104feb,(%esp)
f0101a91:	e8 73 14 00 00       	call   f0102f09 <cprintf>
	cprintf("pgdir %p paddr %x", check_va2pa(pgdir, (uintptr_t) va), page2pa(pp));
f0101a96:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a99:	e8 92 ef ff ff       	call   f0100a30 <page2pa>
f0101a9e:	89 c6                	mov    %eax,%esi
f0101aa0:	89 da                	mov    %ebx,%edx
f0101aa2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101aa5:	e8 09 f1 ff ff       	call   f0100bb3 <check_va2pa>
f0101aaa:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101aae:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ab2:	c7 04 24 fe 4f 10 f0 	movl   $0xf0104ffe,(%esp)
f0101ab9:	e8 4b 14 00 00       	call   f0102f09 <cprintf>
	//cprintf("En insert va es %p",va);
	pp->pp_ref++;
f0101abe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101ac1:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return 0;
f0101ac6:	b8 00 00 00 00       	mov    $0x0,%eax
f0101acb:	eb 05                	jmp    f0101ad2 <page_insert+0x125>

	physaddr_t page_PA = page2pa(pp);
	cprintf("page_PA es %p\n",page_PA);
	pte_t *page_entry = pgdir_walk(pgdir, va, true);
	if (page_entry == NULL){
		return -E_NO_MEM;
f0101acd:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	cprintf("En insert va es %p",va);
	cprintf("pgdir %p paddr %x", check_va2pa(pgdir, (uintptr_t) va), page2pa(pp));
	//cprintf("En insert va es %p",va);
	pp->pp_ref++;
	return 0;
}
f0101ad2:	83 c4 1c             	add    $0x1c,%esp
f0101ad5:	5b                   	pop    %ebx
f0101ad6:	5e                   	pop    %esi
f0101ad7:	5f                   	pop    %edi
f0101ad8:	5d                   	pop    %ebp
f0101ad9:	c3                   	ret    

f0101ada <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f0101ada:	55                   	push   %ebp
f0101adb:	89 e5                	mov    %esp,%ebp
f0101add:	57                   	push   %edi
f0101ade:	56                   	push   %esi
f0101adf:	53                   	push   %ebx
f0101ae0:	83 ec 3c             	sub    $0x3c,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101ae3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101aea:	e8 a7 f7 ff ff       	call   f0101296 <page_alloc>
f0101aef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101af2:	85 c0                	test   %eax,%eax
f0101af4:	75 24                	jne    f0101b1a <check_page+0x40>
f0101af6:	c7 44 24 0c 25 4e 10 	movl   $0xf0104e25,0xc(%esp)
f0101afd:	f0 
f0101afe:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101b05:	f0 
f0101b06:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101b0d:	00 
f0101b0e:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101b15:	e8 7a e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b1a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b21:	e8 70 f7 ff ff       	call   f0101296 <page_alloc>
f0101b26:	89 c3                	mov    %eax,%ebx
f0101b28:	85 c0                	test   %eax,%eax
f0101b2a:	75 24                	jne    f0101b50 <check_page+0x76>
f0101b2c:	c7 44 24 0c 3b 4e 10 	movl   $0xf0104e3b,0xc(%esp)
f0101b33:	f0 
f0101b34:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101b3b:	f0 
f0101b3c:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101b43:	00 
f0101b44:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101b4b:	e8 44 e5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b50:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b57:	e8 3a f7 ff ff       	call   f0101296 <page_alloc>
f0101b5c:	89 c6                	mov    %eax,%esi
f0101b5e:	85 c0                	test   %eax,%eax
f0101b60:	75 24                	jne    f0101b86 <check_page+0xac>
f0101b62:	c7 44 24 0c 51 4e 10 	movl   $0xf0104e51,0xc(%esp)
f0101b69:	f0 
f0101b6a:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101b71:	f0 
f0101b72:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0101b79:	00 
f0101b7a:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101b81:	e8 0e e5 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b86:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101b89:	75 24                	jne    f0101baf <check_page+0xd5>
f0101b8b:	c7 44 24 0c 67 4e 10 	movl   $0xf0104e67,0xc(%esp)
f0101b92:	f0 
f0101b93:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101b9a:	f0 
f0101b9b:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101ba2:	00 
f0101ba3:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101baa:	e8 e5 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101baf:	39 c3                	cmp    %eax,%ebx
f0101bb1:	74 05                	je     f0101bb8 <check_page+0xde>
f0101bb3:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
f0101bb6:	75 24                	jne    f0101bdc <check_page+0x102>
f0101bb8:	c7 44 24 0c 0c 46 10 	movl   $0xf010460c,0xc(%esp)
f0101bbf:	f0 
f0101bc0:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101bc7:	f0 
f0101bc8:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101bcf:	00 
f0101bd0:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101bd7:	e8 b8 e4 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101bdc:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f0101be1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101be4:	c7 05 3c 85 11 f0 00 	movl   $0x0,0xf011853c
f0101beb:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101bee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bf5:	e8 9c f6 ff ff       	call   f0101296 <page_alloc>
f0101bfa:	85 c0                	test   %eax,%eax
f0101bfc:	74 24                	je     f0101c22 <check_page+0x148>
f0101bfe:	c7 44 24 0c d0 4e 10 	movl   $0xf0104ed0,0xc(%esp)
f0101c05:	f0 
f0101c06:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101c0d:	f0 
f0101c0e:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101c15:	00 
f0101c16:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101c1d:	e8 72 e4 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101c22:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101c25:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c29:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101c30:	00 
f0101c31:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101c36:	89 04 24             	mov    %eax,(%esp)
f0101c39:	e8 5b fc ff ff       	call   f0101899 <page_lookup>
f0101c3e:	85 c0                	test   %eax,%eax
f0101c40:	74 24                	je     f0101c66 <check_page+0x18c>
f0101c42:	c7 44 24 0c ec 46 10 	movl   $0xf01046ec,0xc(%esp)
f0101c49:	f0 
f0101c4a:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101c51:	f0 
f0101c52:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101c59:	00 
f0101c5a:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101c61:	e8 2e e4 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101c66:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c6d:	00 
f0101c6e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c75:	00 
f0101c76:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101c7a:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101c7f:	89 04 24             	mov    %eax,(%esp)
f0101c82:	e8 26 fd ff ff       	call   f01019ad <page_insert>
f0101c87:	85 c0                	test   %eax,%eax
f0101c89:	78 24                	js     f0101caf <check_page+0x1d5>
f0101c8b:	c7 44 24 0c 24 47 10 	movl   $0xf0104724,0xc(%esp)
f0101c92:	f0 
f0101c93:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101c9a:	f0 
f0101c9b:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101ca2:	00 
f0101ca3:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101caa:	e8 e5 e3 ff ff       	call   f0100094 <_panic>


	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101caf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cb2:	89 04 24             	mov    %eax,(%esp)
f0101cb5:	e8 2e f6 ff ff       	call   f01012e8 <page_free>
	cprintf("\nA PARTIR DE ACA IMPORTA\n");//DEBUG2
f0101cba:	c7 04 24 10 50 10 f0 	movl   $0xf0105010,(%esp)
f0101cc1:	e8 43 12 00 00       	call   f0102f09 <cprintf>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101cc6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ccd:	00 
f0101cce:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101cd5:	00 
f0101cd6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101cda:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101cdf:	89 04 24             	mov    %eax,(%esp)
f0101ce2:	e8 c6 fc ff ff       	call   f01019ad <page_insert>
f0101ce7:	85 c0                	test   %eax,%eax
f0101ce9:	74 24                	je     f0101d0f <check_page+0x235>
f0101ceb:	c7 44 24 0c 54 47 10 	movl   $0xf0104754,0xc(%esp)
f0101cf2:	f0 
f0101cf3:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101cfa:	f0 
f0101cfb:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101d02:	00 
f0101d03:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101d0a:	e8 85 e3 ff ff       	call   f0100094 <_panic>
//	cprintf("page2pa(pp0) es %p\n",page2pa(pp0));//DEBUG2
//	cprintf("pero PTE_ADDR(kern_pgdir[0]) es %p\n",PTE_ADDR(kern_pgdir[0]));//DEBUG2
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d0f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d12:	e8 19 ed ff ff       	call   f0100a30 <page2pa>
f0101d17:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0101d1d:	8b 12                	mov    (%edx),%edx
f0101d1f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d25:	39 c2                	cmp    %eax,%edx
f0101d27:	74 24                	je     f0101d4d <check_page+0x273>
f0101d29:	c7 44 24 0c 84 47 10 	movl   $0xf0104784,0xc(%esp)
f0101d30:	f0 
f0101d31:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101d38:	f0 
f0101d39:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101d40:	00 
f0101d41:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101d48:	e8 47 e3 ff ff       	call   f0100094 <_panic>
	cprintf("page2pa(pp1) es %p\n",page2pa(pp1));//DEBUG2
f0101d4d:	89 d8                	mov    %ebx,%eax
f0101d4f:	e8 dc ec ff ff       	call   f0100a30 <page2pa>
f0101d54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101d58:	c7 04 24 2a 50 10 f0 	movl   $0xf010502a,(%esp)
f0101d5f:	e8 a5 11 00 00       	call   f0102f09 <cprintf>
	cprintf("pero check_va2pa(kern_pgdir, 0x0) es %p\n",check_va2pa(kern_pgdir, 0x0));//DEBUG2
f0101d64:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d69:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101d6e:	e8 40 ee ff ff       	call   f0100bb3 <check_va2pa>
f0101d73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101d77:	c7 04 24 ac 47 10 f0 	movl   $0xf01047ac,(%esp)
f0101d7e:	e8 86 11 00 00       	call   f0102f09 <cprintf>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101d83:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d88:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101d8d:	e8 21 ee ff ff       	call   f0100bb3 <check_va2pa>
f0101d92:	89 c7                	mov    %eax,%edi
f0101d94:	89 d8                	mov    %ebx,%eax
f0101d96:	e8 95 ec ff ff       	call   f0100a30 <page2pa>
f0101d9b:	39 c7                	cmp    %eax,%edi
f0101d9d:	74 24                	je     f0101dc3 <check_page+0x2e9>
f0101d9f:	c7 44 24 0c d8 47 10 	movl   $0xf01047d8,0xc(%esp)
f0101da6:	f0 
f0101da7:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101dae:	f0 
f0101daf:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101db6:	00 
f0101db7:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101dbe:	e8 d1 e2 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101dc3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dc8:	74 24                	je     f0101dee <check_page+0x314>
f0101dca:	c7 44 24 0c 3e 50 10 	movl   $0xf010503e,0xc(%esp)
f0101dd1:	f0 
f0101dd2:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101dd9:	f0 
f0101dda:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101de1:	00 
f0101de2:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101de9:	e8 a6 e2 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101dee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101df1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101df6:	74 24                	je     f0101e1c <check_page+0x342>
f0101df8:	c7 44 24 0c 4f 50 10 	movl   $0xf010504f,0xc(%esp)
f0101dff:	f0 
f0101e00:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101e07:	f0 
f0101e08:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101e0f:	00 
f0101e10:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101e17:	e8 78 e2 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e1c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e23:	00 
f0101e24:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e2b:	00 
f0101e2c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e30:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101e35:	89 04 24             	mov    %eax,(%esp)
f0101e38:	e8 70 fb ff ff       	call   f01019ad <page_insert>
f0101e3d:	85 c0                	test   %eax,%eax
f0101e3f:	74 24                	je     f0101e65 <check_page+0x38b>
f0101e41:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f0101e48:	f0 
f0101e49:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101e50:	f0 
f0101e51:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101e58:	00 
f0101e59:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101e60:	e8 2f e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e65:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e6a:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101e6f:	e8 3f ed ff ff       	call   f0100bb3 <check_va2pa>
f0101e74:	89 c7                	mov    %eax,%edi
f0101e76:	89 f0                	mov    %esi,%eax
f0101e78:	e8 b3 eb ff ff       	call   f0100a30 <page2pa>
f0101e7d:	39 c7                	cmp    %eax,%edi
f0101e7f:	74 24                	je     f0101ea5 <check_page+0x3cb>
f0101e81:	c7 44 24 0c 44 48 10 	movl   $0xf0104844,0xc(%esp)
f0101e88:	f0 
f0101e89:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101e90:	f0 
f0101e91:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101e98:	00 
f0101e99:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101ea0:	e8 ef e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ea5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101eaa:	74 24                	je     f0101ed0 <check_page+0x3f6>
f0101eac:	c7 44 24 0c 60 50 10 	movl   $0xf0105060,0xc(%esp)
f0101eb3:	f0 
f0101eb4:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101ebb:	f0 
f0101ebc:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101ec3:	00 
f0101ec4:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101ecb:	e8 c4 e1 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ed0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ed7:	e8 ba f3 ff ff       	call   f0101296 <page_alloc>
f0101edc:	85 c0                	test   %eax,%eax
f0101ede:	74 24                	je     f0101f04 <check_page+0x42a>
f0101ee0:	c7 44 24 0c d0 4e 10 	movl   $0xf0104ed0,0xc(%esp)
f0101ee7:	f0 
f0101ee8:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101eef:	f0 
f0101ef0:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101ef7:	00 
f0101ef8:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101eff:	e8 90 e1 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f04:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f0b:	00 
f0101f0c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f13:	00 
f0101f14:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f18:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101f1d:	89 04 24             	mov    %eax,(%esp)
f0101f20:	e8 88 fa ff ff       	call   f01019ad <page_insert>
f0101f25:	85 c0                	test   %eax,%eax
f0101f27:	74 24                	je     f0101f4d <check_page+0x473>
f0101f29:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f0101f30:	f0 
f0101f31:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101f38:	f0 
f0101f39:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0101f40:	00 
f0101f41:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101f48:	e8 47 e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f4d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f52:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101f57:	e8 57 ec ff ff       	call   f0100bb3 <check_va2pa>
f0101f5c:	89 c7                	mov    %eax,%edi
f0101f5e:	89 f0                	mov    %esi,%eax
f0101f60:	e8 cb ea ff ff       	call   f0100a30 <page2pa>
f0101f65:	39 c7                	cmp    %eax,%edi
f0101f67:	74 24                	je     f0101f8d <check_page+0x4b3>
f0101f69:	c7 44 24 0c 44 48 10 	movl   $0xf0104844,0xc(%esp)
f0101f70:	f0 
f0101f71:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101f78:	f0 
f0101f79:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101f80:	00 
f0101f81:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101f88:	e8 07 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101f8d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f92:	74 24                	je     f0101fb8 <check_page+0x4de>
f0101f94:	c7 44 24 0c 60 50 10 	movl   $0xf0105060,0xc(%esp)
f0101f9b:	f0 
f0101f9c:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101fa3:	f0 
f0101fa4:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101fab:	00 
f0101fac:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101fb3:	e8 dc e0 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101fb8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fbf:	e8 d2 f2 ff ff       	call   f0101296 <page_alloc>
f0101fc4:	85 c0                	test   %eax,%eax
f0101fc6:	74 24                	je     f0101fec <check_page+0x512>
f0101fc8:	c7 44 24 0c d0 4e 10 	movl   $0xf0104ed0,0xc(%esp)
f0101fcf:	f0 
f0101fd0:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0101fd7:	f0 
f0101fd8:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101fdf:	00 
f0101fe0:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0101fe7:	e8 a8 e0 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101fec:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f0101ff2:	8b 0f                	mov    (%edi),%ecx
f0101ff4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101ffa:	ba 3f 03 00 00       	mov    $0x33f,%edx
f0101fff:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f0102004:	e8 54 eb ff ff       	call   f0100b5d <_kaddr>
f0102009:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010200c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102013:	00 
f0102014:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010201b:	00 
f010201c:	89 3c 24             	mov    %edi,(%esp)
f010201f:	e8 dc f7 ff ff       	call   f0101800 <pgdir_walk>
f0102024:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102027:	8d 51 04             	lea    0x4(%ecx),%edx
f010202a:	39 d0                	cmp    %edx,%eax
f010202c:	74 24                	je     f0102052 <check_page+0x578>
f010202e:	c7 44 24 0c 74 48 10 	movl   $0xf0104874,0xc(%esp)
f0102035:	f0 
f0102036:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010203d:	f0 
f010203e:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102045:	00 
f0102046:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010204d:	e8 42 e0 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102052:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102059:	00 
f010205a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102061:	00 
f0102062:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102066:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010206b:	89 04 24             	mov    %eax,(%esp)
f010206e:	e8 3a f9 ff ff       	call   f01019ad <page_insert>
f0102073:	85 c0                	test   %eax,%eax
f0102075:	74 24                	je     f010209b <check_page+0x5c1>
f0102077:	c7 44 24 0c b4 48 10 	movl   $0xf01048b4,0xc(%esp)
f010207e:	f0 
f010207f:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102086:	f0 
f0102087:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f010208e:	00 
f010208f:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102096:	e8 f9 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010209b:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020a0:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01020a5:	e8 09 eb ff ff       	call   f0100bb3 <check_va2pa>
f01020aa:	89 c7                	mov    %eax,%edi
f01020ac:	89 f0                	mov    %esi,%eax
f01020ae:	e8 7d e9 ff ff       	call   f0100a30 <page2pa>
f01020b3:	39 c7                	cmp    %eax,%edi
f01020b5:	74 24                	je     f01020db <check_page+0x601>
f01020b7:	c7 44 24 0c 44 48 10 	movl   $0xf0104844,0xc(%esp)
f01020be:	f0 
f01020bf:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01020c6:	f0 
f01020c7:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f01020ce:	00 
f01020cf:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01020d6:	e8 b9 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01020db:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020e0:	74 24                	je     f0102106 <check_page+0x62c>
f01020e2:	c7 44 24 0c 60 50 10 	movl   $0xf0105060,0xc(%esp)
f01020e9:	f0 
f01020ea:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01020f1:	f0 
f01020f2:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f01020f9:	00 
f01020fa:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102101:	e8 8e df ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102106:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010210d:	00 
f010210e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102115:	00 
f0102116:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010211b:	89 04 24             	mov    %eax,(%esp)
f010211e:	e8 dd f6 ff ff       	call   f0101800 <pgdir_walk>
f0102123:	f6 00 04             	testb  $0x4,(%eax)
f0102126:	75 24                	jne    f010214c <check_page+0x672>
f0102128:	c7 44 24 0c f4 48 10 	movl   $0xf01048f4,0xc(%esp)
f010212f:	f0 
f0102130:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102137:	f0 
f0102138:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f010213f:	00 
f0102140:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102147:	e8 48 df ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010214c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102151:	f6 00 04             	testb  $0x4,(%eax)
f0102154:	75 24                	jne    f010217a <check_page+0x6a0>
f0102156:	c7 44 24 0c 71 50 10 	movl   $0xf0105071,0xc(%esp)
f010215d:	f0 
f010215e:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102165:	f0 
f0102166:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f010216d:	00 
f010216e:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102175:	e8 1a df ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010217a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102181:	00 
f0102182:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102189:	00 
f010218a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010218e:	89 04 24             	mov    %eax,(%esp)
f0102191:	e8 17 f8 ff ff       	call   f01019ad <page_insert>
f0102196:	85 c0                	test   %eax,%eax
f0102198:	74 24                	je     f01021be <check_page+0x6e4>
f010219a:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f01021a1:	f0 
f01021a2:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01021a9:	f0 
f01021aa:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f01021b1:	00 
f01021b2:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01021b9:	e8 d6 de ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01021be:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021c5:	00 
f01021c6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021cd:	00 
f01021ce:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01021d3:	89 04 24             	mov    %eax,(%esp)
f01021d6:	e8 25 f6 ff ff       	call   f0101800 <pgdir_walk>
f01021db:	f6 00 02             	testb  $0x2,(%eax)
f01021de:	75 24                	jne    f0102204 <check_page+0x72a>
f01021e0:	c7 44 24 0c 28 49 10 	movl   $0xf0104928,0xc(%esp)
f01021e7:	f0 
f01021e8:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01021ef:	f0 
f01021f0:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f01021f7:	00 
f01021f8:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01021ff:	e8 90 de ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102204:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010220b:	00 
f010220c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102213:	00 
f0102214:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102219:	89 04 24             	mov    %eax,(%esp)
f010221c:	e8 df f5 ff ff       	call   f0101800 <pgdir_walk>
f0102221:	f6 00 04             	testb  $0x4,(%eax)
f0102224:	74 24                	je     f010224a <check_page+0x770>
f0102226:	c7 44 24 0c 5c 49 10 	movl   $0xf010495c,0xc(%esp)
f010222d:	f0 
f010222e:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102235:	f0 
f0102236:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f010223d:	00 
f010223e:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102245:	e8 4a de ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010224a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102251:	00 
f0102252:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102259:	00 
f010225a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010225d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102261:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102266:	89 04 24             	mov    %eax,(%esp)
f0102269:	e8 3f f7 ff ff       	call   f01019ad <page_insert>
f010226e:	85 c0                	test   %eax,%eax
f0102270:	78 24                	js     f0102296 <check_page+0x7bc>
f0102272:	c7 44 24 0c 94 49 10 	movl   $0xf0104994,0xc(%esp)
f0102279:	f0 
f010227a:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102281:	f0 
f0102282:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0102289:	00 
f010228a:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102291:	e8 fe dd ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102296:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010229d:	00 
f010229e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022a5:	00 
f01022a6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022aa:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01022af:	89 04 24             	mov    %eax,(%esp)
f01022b2:	e8 f6 f6 ff ff       	call   f01019ad <page_insert>
f01022b7:	85 c0                	test   %eax,%eax
f01022b9:	74 24                	je     f01022df <check_page+0x805>
f01022bb:	c7 44 24 0c cc 49 10 	movl   $0xf01049cc,0xc(%esp)
f01022c2:	f0 
f01022c3:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01022ca:	f0 
f01022cb:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f01022d2:	00 
f01022d3:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01022da:	e8 b5 dd ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01022df:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022e6:	00 
f01022e7:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022ee:	00 
f01022ef:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01022f4:	89 04 24             	mov    %eax,(%esp)
f01022f7:	e8 04 f5 ff ff       	call   f0101800 <pgdir_walk>
f01022fc:	f6 00 04             	testb  $0x4,(%eax)
f01022ff:	74 24                	je     f0102325 <check_page+0x84b>
f0102301:	c7 44 24 0c 5c 49 10 	movl   $0xf010495c,0xc(%esp)
f0102308:	f0 
f0102309:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102310:	f0 
f0102311:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0102318:	00 
f0102319:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102320:	e8 6f dd ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102325:	ba 00 00 00 00       	mov    $0x0,%edx
f010232a:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010232f:	e8 7f e8 ff ff       	call   f0100bb3 <check_va2pa>
f0102334:	89 c7                	mov    %eax,%edi
f0102336:	89 d8                	mov    %ebx,%eax
f0102338:	e8 f3 e6 ff ff       	call   f0100a30 <page2pa>
f010233d:	39 c7                	cmp    %eax,%edi
f010233f:	74 24                	je     f0102365 <check_page+0x88b>
f0102341:	c7 44 24 0c 08 4a 10 	movl   $0xf0104a08,0xc(%esp)
f0102348:	f0 
f0102349:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102350:	f0 
f0102351:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0102358:	00 
f0102359:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102360:	e8 2f dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102365:	ba 00 10 00 00       	mov    $0x1000,%edx
f010236a:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010236f:	e8 3f e8 ff ff       	call   f0100bb3 <check_va2pa>
f0102374:	89 c7                	mov    %eax,%edi
f0102376:	89 d8                	mov    %ebx,%eax
f0102378:	e8 b3 e6 ff ff       	call   f0100a30 <page2pa>
f010237d:	39 c7                	cmp    %eax,%edi
f010237f:	74 24                	je     f01023a5 <check_page+0x8cb>
f0102381:	c7 44 24 0c 34 4a 10 	movl   $0xf0104a34,0xc(%esp)
f0102388:	f0 
f0102389:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102390:	f0 
f0102391:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0102398:	00 
f0102399:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01023a0:	e8 ef dc ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01023a5:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01023aa:	74 24                	je     f01023d0 <check_page+0x8f6>
f01023ac:	c7 44 24 0c 87 50 10 	movl   $0xf0105087,0xc(%esp)
f01023b3:	f0 
f01023b4:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01023bb:	f0 
f01023bc:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f01023c3:	00 
f01023c4:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01023cb:	e8 c4 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01023d0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023d5:	74 24                	je     f01023fb <check_page+0x921>
f01023d7:	c7 44 24 0c 98 50 10 	movl   $0xf0105098,0xc(%esp)
f01023de:	f0 
f01023df:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01023e6:	f0 
f01023e7:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01023ee:	00 
f01023ef:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01023f6:	e8 99 dc ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01023fb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102402:	e8 8f ee ff ff       	call   f0101296 <page_alloc>
f0102407:	89 c7                	mov    %eax,%edi
f0102409:	85 c0                	test   %eax,%eax
f010240b:	74 04                	je     f0102411 <check_page+0x937>
f010240d:	39 f0                	cmp    %esi,%eax
f010240f:	74 24                	je     f0102435 <check_page+0x95b>
f0102411:	c7 44 24 0c 64 4a 10 	movl   $0xf0104a64,0xc(%esp)
f0102418:	f0 
f0102419:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102420:	f0 
f0102421:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102428:	00 
f0102429:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102430:	e8 5f dc ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102435:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010243c:	00 
f010243d:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102442:	89 04 24             	mov    %eax,(%esp)
f0102445:	e8 f0 f4 ff ff       	call   f010193a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010244a:	ba 00 00 00 00       	mov    $0x0,%edx
f010244f:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102454:	e8 5a e7 ff ff       	call   f0100bb3 <check_va2pa>
f0102459:	83 f8 ff             	cmp    $0xffffffff,%eax
f010245c:	74 24                	je     f0102482 <check_page+0x9a8>
f010245e:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f0102465:	f0 
f0102466:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010246d:	f0 
f010246e:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f0102475:	00 
f0102476:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010247d:	e8 12 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102482:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102487:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010248c:	e8 22 e7 ff ff       	call   f0100bb3 <check_va2pa>
f0102491:	89 c6                	mov    %eax,%esi
f0102493:	89 d8                	mov    %ebx,%eax
f0102495:	e8 96 e5 ff ff       	call   f0100a30 <page2pa>
f010249a:	39 c6                	cmp    %eax,%esi
f010249c:	74 24                	je     f01024c2 <check_page+0x9e8>
f010249e:	c7 44 24 0c 34 4a 10 	movl   $0xf0104a34,0xc(%esp)
f01024a5:	f0 
f01024a6:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01024ad:	f0 
f01024ae:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01024b5:	00 
f01024b6:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01024bd:	e8 d2 db ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01024c2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024c7:	74 24                	je     f01024ed <check_page+0xa13>
f01024c9:	c7 44 24 0c 3e 50 10 	movl   $0xf010503e,0xc(%esp)
f01024d0:	f0 
f01024d1:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01024d8:	f0 
f01024d9:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01024e0:	00 
f01024e1:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01024e8:	e8 a7 db ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01024ed:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024f2:	74 24                	je     f0102518 <check_page+0xa3e>
f01024f4:	c7 44 24 0c 98 50 10 	movl   $0xf0105098,0xc(%esp)
f01024fb:	f0 
f01024fc:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102503:	f0 
f0102504:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f010250b:	00 
f010250c:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102513:	e8 7c db ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102518:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010251f:	00 
f0102520:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102527:	00 
f0102528:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010252c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102531:	89 04 24             	mov    %eax,(%esp)
f0102534:	e8 74 f4 ff ff       	call   f01019ad <page_insert>
f0102539:	85 c0                	test   %eax,%eax
f010253b:	74 24                	je     f0102561 <check_page+0xa87>
f010253d:	c7 44 24 0c ac 4a 10 	movl   $0xf0104aac,0xc(%esp)
f0102544:	f0 
f0102545:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010254c:	f0 
f010254d:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0102554:	00 
f0102555:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010255c:	e8 33 db ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f0102561:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102566:	75 24                	jne    f010258c <check_page+0xab2>
f0102568:	c7 44 24 0c a9 50 10 	movl   $0xf01050a9,0xc(%esp)
f010256f:	f0 
f0102570:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102577:	f0 
f0102578:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f010257f:	00 
f0102580:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102587:	e8 08 db ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f010258c:	83 3b 00             	cmpl   $0x0,(%ebx)
f010258f:	74 24                	je     f01025b5 <check_page+0xadb>
f0102591:	c7 44 24 0c b5 50 10 	movl   $0xf01050b5,0xc(%esp)
f0102598:	f0 
f0102599:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01025a0:	f0 
f01025a1:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f01025a8:	00 
f01025a9:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01025b0:	e8 df da ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025b5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01025bc:	00 
f01025bd:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01025c2:	89 04 24             	mov    %eax,(%esp)
f01025c5:	e8 70 f3 ff ff       	call   f010193a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025ca:	ba 00 00 00 00       	mov    $0x0,%edx
f01025cf:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01025d4:	e8 da e5 ff ff       	call   f0100bb3 <check_va2pa>
f01025d9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025dc:	74 24                	je     f0102602 <check_page+0xb28>
f01025de:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f01025e5:	f0 
f01025e6:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01025ed:	f0 
f01025ee:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f01025f5:	00 
f01025f6:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01025fd:	e8 92 da ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102602:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102607:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010260c:	e8 a2 e5 ff ff       	call   f0100bb3 <check_va2pa>
f0102611:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102614:	74 24                	je     f010263a <check_page+0xb60>
f0102616:	c7 44 24 0c e4 4a 10 	movl   $0xf0104ae4,0xc(%esp)
f010261d:	f0 
f010261e:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102625:	f0 
f0102626:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f010262d:	00 
f010262e:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102635:	e8 5a da ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010263a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010263f:	74 24                	je     f0102665 <check_page+0xb8b>
f0102641:	c7 44 24 0c ca 50 10 	movl   $0xf01050ca,0xc(%esp)
f0102648:	f0 
f0102649:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102650:	f0 
f0102651:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0102658:	00 
f0102659:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102660:	e8 2f da ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102665:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010266a:	74 24                	je     f0102690 <check_page+0xbb6>
f010266c:	c7 44 24 0c 98 50 10 	movl   $0xf0105098,0xc(%esp)
f0102673:	f0 
f0102674:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010267b:	f0 
f010267c:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f0102683:	00 
f0102684:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010268b:	e8 04 da ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102690:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102697:	e8 fa eb ff ff       	call   f0101296 <page_alloc>
f010269c:	89 c6                	mov    %eax,%esi
f010269e:	85 c0                	test   %eax,%eax
f01026a0:	74 04                	je     f01026a6 <check_page+0xbcc>
f01026a2:	39 d8                	cmp    %ebx,%eax
f01026a4:	74 24                	je     f01026ca <check_page+0xbf0>
f01026a6:	c7 44 24 0c 0c 4b 10 	movl   $0xf0104b0c,0xc(%esp)
f01026ad:	f0 
f01026ae:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01026b5:	f0 
f01026b6:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f01026bd:	00 
f01026be:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01026c5:	e8 ca d9 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01026ca:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026d1:	e8 c0 eb ff ff       	call   f0101296 <page_alloc>
f01026d6:	85 c0                	test   %eax,%eax
f01026d8:	74 24                	je     f01026fe <check_page+0xc24>
f01026da:	c7 44 24 0c d0 4e 10 	movl   $0xf0104ed0,0xc(%esp)
f01026e1:	f0 
f01026e2:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01026e9:	f0 
f01026ea:	c7 44 24 04 76 03 00 	movl   $0x376,0x4(%esp)
f01026f1:	00 
f01026f2:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01026f9:	e8 96 d9 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026fe:	8b 1d 68 89 11 f0    	mov    0xf0118968,%ebx
f0102704:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102707:	e8 24 e3 ff ff       	call   f0100a30 <page2pa>
f010270c:	8b 13                	mov    (%ebx),%edx
f010270e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102714:	39 c2                	cmp    %eax,%edx
f0102716:	74 24                	je     f010273c <check_page+0xc62>
f0102718:	c7 44 24 0c 84 47 10 	movl   $0xf0104784,0xc(%esp)
f010271f:	f0 
f0102720:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102727:	f0 
f0102728:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f010272f:	00 
f0102730:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102737:	e8 58 d9 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010273c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102742:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102745:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010274a:	74 24                	je     f0102770 <check_page+0xc96>
f010274c:	c7 44 24 0c 4f 50 10 	movl   $0xf010504f,0xc(%esp)
f0102753:	f0 
f0102754:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010275b:	f0 
f010275c:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102763:	00 
f0102764:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010276b:	e8 24 d9 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102770:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102773:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102779:	89 04 24             	mov    %eax,(%esp)
f010277c:	e8 67 eb ff ff       	call   f01012e8 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102781:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102788:	00 
f0102789:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102790:	00 
f0102791:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102796:	89 04 24             	mov    %eax,(%esp)
f0102799:	e8 62 f0 ff ff       	call   f0101800 <pgdir_walk>
f010279e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01027a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01027a4:	8b 1d 68 89 11 f0    	mov    0xf0118968,%ebx
f01027aa:	8b 4b 04             	mov    0x4(%ebx),%ecx
f01027ad:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01027b3:	ba 82 03 00 00       	mov    $0x382,%edx
f01027b8:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f01027bd:	e8 9b e3 ff ff       	call   f0100b5d <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f01027c2:	83 c0 04             	add    $0x4,%eax
f01027c5:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01027c8:	74 24                	je     f01027ee <check_page+0xd14>
f01027ca:	c7 44 24 0c db 50 10 	movl   $0xf01050db,0xc(%esp)
f01027d1:	f0 
f01027d2:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01027d9:	f0 
f01027da:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f01027e1:	00 
f01027e2:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f01027e9:	e8 a6 d8 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01027ee:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f01027f5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027f8:	89 d8                	mov    %ebx,%eax
f01027fa:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102800:	e8 90 e3 ff ff       	call   f0100b95 <page2kva>
f0102805:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010280c:	00 
f010280d:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102814:	00 
f0102815:	89 04 24             	mov    %eax,(%esp)
f0102818:	e8 90 11 00 00       	call   f01039ad <memset>
	page_free(pp0);
f010281d:	89 1c 24             	mov    %ebx,(%esp)
f0102820:	e8 c3 ea ff ff       	call   f01012e8 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102825:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010282c:	00 
f010282d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102834:	00 
f0102835:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010283a:	89 04 24             	mov    %eax,(%esp)
f010283d:	e8 be ef ff ff       	call   f0101800 <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f0102842:	89 d8                	mov    %ebx,%eax
f0102844:	e8 4c e3 ff ff       	call   f0100b95 <page2kva>
f0102849:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
f010284c:	ba 00 00 00 00       	mov    $0x0,%edx
		assert((ptep[i] & PTE_P) == 0);
f0102851:	f6 04 90 01          	testb  $0x1,(%eax,%edx,4)
f0102855:	74 24                	je     f010287b <check_page+0xda1>
f0102857:	c7 44 24 0c f3 50 10 	movl   $0xf01050f3,0xc(%esp)
f010285e:	f0 
f010285f:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102866:	f0 
f0102867:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f010286e:	00 
f010286f:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102876:	e8 19 d8 ff ff       	call   f0100094 <_panic>
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010287b:	83 c2 01             	add    $0x1,%edx
f010287e:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f0102884:	75 cb                	jne    f0102851 <check_page+0xd77>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102886:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010288b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102891:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102894:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010289a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010289d:	89 0d 3c 85 11 f0    	mov    %ecx,0xf011853c

	// free the pages we took
	page_free(pp0);
f01028a3:	89 04 24             	mov    %eax,(%esp)
f01028a6:	e8 3d ea ff ff       	call   f01012e8 <page_free>
	page_free(pp1);
f01028ab:	89 34 24             	mov    %esi,(%esp)
f01028ae:	e8 35 ea ff ff       	call   f01012e8 <page_free>
	page_free(pp2);
f01028b3:	89 3c 24             	mov    %edi,(%esp)
f01028b6:	e8 2d ea ff ff       	call   f01012e8 <page_free>

	cprintf("check_page() succeeded!\n");
f01028bb:	c7 04 24 0a 51 10 f0 	movl   $0xf010510a,(%esp)
f01028c2:	e8 42 06 00 00       	call   f0102f09 <cprintf>
}
f01028c7:	83 c4 3c             	add    $0x3c,%esp
f01028ca:	5b                   	pop    %ebx
f01028cb:	5e                   	pop    %esi
f01028cc:	5f                   	pop    %edi
f01028cd:	5d                   	pop    %ebp
f01028ce:	c3                   	ret    

f01028cf <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f01028cf:	55                   	push   %ebp
f01028d0:	89 e5                	mov    %esp,%ebp
f01028d2:	57                   	push   %edi
f01028d3:	56                   	push   %esi
f01028d4:	53                   	push   %ebx
f01028d5:	83 ec 1c             	sub    $0x1c,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01028d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028df:	e8 b2 e9 ff ff       	call   f0101296 <page_alloc>
f01028e4:	89 c6                	mov    %eax,%esi
f01028e6:	85 c0                	test   %eax,%eax
f01028e8:	75 24                	jne    f010290e <check_page_installed_pgdir+0x3f>
f01028ea:	c7 44 24 0c 25 4e 10 	movl   $0xf0104e25,0xc(%esp)
f01028f1:	f0 
f01028f2:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01028f9:	f0 
f01028fa:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0102901:	00 
f0102902:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102909:	e8 86 d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010290e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102915:	e8 7c e9 ff ff       	call   f0101296 <page_alloc>
f010291a:	89 c7                	mov    %eax,%edi
f010291c:	85 c0                	test   %eax,%eax
f010291e:	75 24                	jne    f0102944 <check_page_installed_pgdir+0x75>
f0102920:	c7 44 24 0c 3b 4e 10 	movl   $0xf0104e3b,0xc(%esp)
f0102927:	f0 
f0102928:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f010292f:	f0 
f0102930:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0102937:	00 
f0102938:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f010293f:	e8 50 d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102944:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010294b:	e8 46 e9 ff ff       	call   f0101296 <page_alloc>
f0102950:	89 c3                	mov    %eax,%ebx
f0102952:	85 c0                	test   %eax,%eax
f0102954:	75 24                	jne    f010297a <check_page_installed_pgdir+0xab>
f0102956:	c7 44 24 0c 51 4e 10 	movl   $0xf0104e51,0xc(%esp)
f010295d:	f0 
f010295e:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102965:	f0 
f0102966:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f010296d:	00 
f010296e:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102975:	e8 1a d7 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f010297a:	89 34 24             	mov    %esi,(%esp)
f010297d:	e8 66 e9 ff ff       	call   f01012e8 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102982:	89 f8                	mov    %edi,%eax
f0102984:	e8 0c e2 ff ff       	call   f0100b95 <page2kva>
f0102989:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102990:	00 
f0102991:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102998:	00 
f0102999:	89 04 24             	mov    %eax,(%esp)
f010299c:	e8 0c 10 00 00       	call   f01039ad <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01029a1:	89 d8                	mov    %ebx,%eax
f01029a3:	e8 ed e1 ff ff       	call   f0100b95 <page2kva>
f01029a8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029af:	00 
f01029b0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01029b7:	00 
f01029b8:	89 04 24             	mov    %eax,(%esp)
f01029bb:	e8 ed 0f 00 00       	call   f01039ad <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01029c0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01029c7:	00 
f01029c8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029cf:	00 
f01029d0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01029d4:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01029d9:	89 04 24             	mov    %eax,(%esp)
f01029dc:	e8 cc ef ff ff       	call   f01019ad <page_insert>
	assert(pp1->pp_ref == 1);
f01029e1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01029e6:	74 24                	je     f0102a0c <check_page_installed_pgdir+0x13d>
f01029e8:	c7 44 24 0c 3e 50 10 	movl   $0xf010503e,0xc(%esp)
f01029ef:	f0 
f01029f0:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f01029f7:	f0 
f01029f8:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f01029ff:	00 
f0102a00:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102a07:	e8 88 d6 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a0c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a13:	01 01 01 
f0102a16:	74 24                	je     f0102a3c <check_page_installed_pgdir+0x16d>
f0102a18:	c7 44 24 0c 30 4b 10 	movl   $0xf0104b30,0xc(%esp)
f0102a1f:	f0 
f0102a20:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102a27:	f0 
f0102a28:	c7 44 24 04 b0 03 00 	movl   $0x3b0,0x4(%esp)
f0102a2f:	00 
f0102a30:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102a37:	e8 58 d6 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a3c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a43:	00 
f0102a44:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a4b:	00 
f0102a4c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102a50:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102a55:	89 04 24             	mov    %eax,(%esp)
f0102a58:	e8 50 ef ff ff       	call   f01019ad <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a5d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a64:	02 02 02 
f0102a67:	74 24                	je     f0102a8d <check_page_installed_pgdir+0x1be>
f0102a69:	c7 44 24 0c 54 4b 10 	movl   $0xf0104b54,0xc(%esp)
f0102a70:	f0 
f0102a71:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102a78:	f0 
f0102a79:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0102a80:	00 
f0102a81:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102a88:	e8 07 d6 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102a8d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102a92:	74 24                	je     f0102ab8 <check_page_installed_pgdir+0x1e9>
f0102a94:	c7 44 24 0c 60 50 10 	movl   $0xf0105060,0xc(%esp)
f0102a9b:	f0 
f0102a9c:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102aa3:	f0 
f0102aa4:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0102aab:	00 
f0102aac:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102ab3:	e8 dc d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102ab8:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102abd:	74 24                	je     f0102ae3 <check_page_installed_pgdir+0x214>
f0102abf:	c7 44 24 0c ca 50 10 	movl   $0xf01050ca,0xc(%esp)
f0102ac6:	f0 
f0102ac7:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102ace:	f0 
f0102acf:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0102ad6:	00 
f0102ad7:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102ade:	e8 b1 d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102ae3:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102aea:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102aed:	89 d8                	mov    %ebx,%eax
f0102aef:	e8 a1 e0 ff ff       	call   f0100b95 <page2kva>
f0102af4:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102afa:	74 24                	je     f0102b20 <check_page_installed_pgdir+0x251>
f0102afc:	c7 44 24 0c 78 4b 10 	movl   $0xf0104b78,0xc(%esp)
f0102b03:	f0 
f0102b04:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102b0b:	f0 
f0102b0c:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0102b13:	00 
f0102b14:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102b1b:	e8 74 d5 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b20:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102b27:	00 
f0102b28:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102b2d:	89 04 24             	mov    %eax,(%esp)
f0102b30:	e8 05 ee ff ff       	call   f010193a <page_remove>
	assert(pp2->pp_ref == 0);
f0102b35:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102b3a:	74 24                	je     f0102b60 <check_page_installed_pgdir+0x291>
f0102b3c:	c7 44 24 0c 98 50 10 	movl   $0xf0105098,0xc(%esp)
f0102b43:	f0 
f0102b44:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102b4b:	f0 
f0102b4c:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f0102b53:	00 
f0102b54:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102b5b:	e8 34 d5 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b60:	8b 1d 68 89 11 f0    	mov    0xf0118968,%ebx
f0102b66:	89 f0                	mov    %esi,%eax
f0102b68:	e8 c3 de ff ff       	call   f0100a30 <page2pa>
f0102b6d:	8b 13                	mov    (%ebx),%edx
f0102b6f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102b75:	39 c2                	cmp    %eax,%edx
f0102b77:	74 24                	je     f0102b9d <check_page_installed_pgdir+0x2ce>
f0102b79:	c7 44 24 0c 84 47 10 	movl   $0xf0104784,0xc(%esp)
f0102b80:	f0 
f0102b81:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102b88:	f0 
f0102b89:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f0102b90:	00 
f0102b91:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102b98:	e8 f7 d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102b9d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102ba3:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ba8:	74 24                	je     f0102bce <check_page_installed_pgdir+0x2ff>
f0102baa:	c7 44 24 0c 4f 50 10 	movl   $0xf010504f,0xc(%esp)
f0102bb1:	f0 
f0102bb2:	c7 44 24 08 14 4d 10 	movl   $0xf0104d14,0x8(%esp)
f0102bb9:	f0 
f0102bba:	c7 44 24 04 bd 03 00 	movl   $0x3bd,0x4(%esp)
f0102bc1:	00 
f0102bc2:	c7 04 24 c3 4c 10 f0 	movl   $0xf0104cc3,(%esp)
f0102bc9:	e8 c6 d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102bce:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102bd4:	89 34 24             	mov    %esi,(%esp)
f0102bd7:	e8 0c e7 ff ff       	call   f01012e8 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102bdc:	c7 04 24 a4 4b 10 f0 	movl   $0xf0104ba4,(%esp)
f0102be3:	e8 21 03 00 00       	call   f0102f09 <cprintf>
}
f0102be8:	83 c4 1c             	add    $0x1c,%esp
f0102beb:	5b                   	pop    %ebx
f0102bec:	5e                   	pop    %esi
f0102bed:	5f                   	pop    %edi
f0102bee:	5d                   	pop    %ebp
f0102bef:	c3                   	ret    

f0102bf0 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0102bf0:	55                   	push   %ebp
f0102bf1:	89 e5                	mov    %esp,%ebp
f0102bf3:	53                   	push   %ebx
f0102bf4:	83 ec 14             	sub    $0x14,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f0102bf7:	e8 70 de ff ff       	call   f0100a6c <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0102bfc:	b8 00 10 00 00       	mov    $0x1000,%eax
f0102c01:	e8 e2 de ff ff       	call   f0100ae8 <boot_alloc>
f0102c06:	a3 68 89 11 f0       	mov    %eax,0xf0118968
	memset(kern_pgdir, 0, PGSIZE);
f0102c0b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c12:	00 
f0102c13:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c1a:	00 
f0102c1b:	89 04 24             	mov    %eax,(%esp)
f0102c1e:	e8 8a 0d 00 00       	call   f01039ad <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0102c23:	8b 1d 68 89 11 f0    	mov    0xf0118968,%ebx
f0102c29:	89 d9                	mov    %ebx,%ecx
f0102c2b:	ba 92 00 00 00       	mov    $0x92,%edx
f0102c30:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f0102c35:	e8 24 e0 ff ff       	call   f0100c5e <_paddr>
f0102c3a:	83 c8 05             	or     $0x5,%eax
f0102c3d:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	//Un PageInfo tiene 4B del PageInfo* +4B del uint16_t = 8B de size

	pages=(struct PageInfo *) boot_alloc(npages //[page]
f0102c43:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0102c48:	c1 e0 03             	shl    $0x3,%eax
f0102c4b:	e8 98 de ff ff       	call   f0100ae8 <boot_alloc>
f0102c50:	a3 6c 89 11 f0       	mov    %eax,0xf011896c
										 * sizeof(struct PageInfo));//[B/page]

	memset(pages,0,npages*sizeof(struct PageInfo));
f0102c55:	8b 0d 64 89 11 f0    	mov    0xf0118964,%ecx
f0102c5b:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0102c62:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102c66:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c6d:	00 
f0102c6e:	89 04 24             	mov    %eax,(%esp)
f0102c71:	e8 37 0d 00 00       	call   f01039ad <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0102c76:	e8 ab e5 ff ff       	call   f0101226 <page_init>


	//parte de pruebas
	cprintf("\n***PRUEBAS DADA UN LINEAR ADDR***\n");
f0102c7b:	c7 04 24 d0 4b 10 f0 	movl   $0xf0104bd0,(%esp)
f0102c82:	e8 82 02 00 00       	call   f0102f09 <cprintf>
	pde_t* kpd = kern_pgdir;
f0102c87:	8b 1d 68 89 11 f0    	mov    0xf0118968,%ebx
	cprintf("	kern_pgdir es %p (32b)\n",kpd);
f0102c8d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c91:	c7 04 24 23 51 10 f0 	movl   $0xf0105123,(%esp)
f0102c98:	e8 6c 02 00 00       	call   f0102f09 <cprintf>
	cprintf("	PD index es %p (10b)\n",PDX(kpd));
f0102c9d:	89 d8                	mov    %ebx,%eax
f0102c9f:	c1 e8 16             	shr    $0x16,%eax
f0102ca2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ca6:	c7 04 24 3c 51 10 f0 	movl   $0xf010513c,(%esp)
f0102cad:	e8 57 02 00 00       	call   f0102f09 <cprintf>
	cprintf("	PT index es %p (10b)\n",PTX(kpd));
f0102cb2:	89 d8                	mov    %ebx,%eax
f0102cb4:	c1 e8 0c             	shr    $0xc,%eax
f0102cb7:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102cbc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cc0:	c7 04 24 53 51 10 f0 	movl   $0xf0105153,(%esp)
f0102cc7:	e8 3d 02 00 00       	call   f0102f09 <cprintf>
	cprintf("	PG offset es %p (12b)\n",PGOFF(kpd));
f0102ccc:	89 d8                	mov    %ebx,%eax
f0102cce:	25 ff 0f 00 00       	and    $0xfff,%eax
f0102cd3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cd7:	c7 04 24 6a 51 10 f0 	movl   $0xf010516a,(%esp)
f0102cde:	e8 26 02 00 00       	call   f0102f09 <cprintf>

	void* va1 = (void*) 0x7fe1b6a7;
	cprintf("\n***ACCEDIENDO A KERN_PGDIR con VA = %p***\n",va1);
f0102ce3:	c7 44 24 04 a7 b6 e1 	movl   $0x7fe1b6a7,0x4(%esp)
f0102cea:	7f 
f0102ceb:	c7 04 24 f4 4b 10 f0 	movl   $0xf0104bf4,(%esp)
f0102cf2:	e8 12 02 00 00       	call   f0102f09 <cprintf>
	cprintf("	PD index es %p (10b)\n",PDX(va1));
f0102cf7:	c7 44 24 04 ff 01 00 	movl   $0x1ff,0x4(%esp)
f0102cfe:	00 
f0102cff:	c7 04 24 3c 51 10 f0 	movl   $0xf010513c,(%esp)
f0102d06:	e8 fe 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	PT index es %p (10b)\n",PTX(va1));
f0102d0b:	c7 44 24 04 1b 02 00 	movl   $0x21b,0x4(%esp)
f0102d12:	00 
f0102d13:	c7 04 24 53 51 10 f0 	movl   $0xf0105153,(%esp)
f0102d1a:	e8 ea 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	PG offset es %p (12b)\n",PGOFF(va1));
f0102d1f:	c7 44 24 04 a7 06 00 	movl   $0x6a7,0x4(%esp)
f0102d26:	00 
f0102d27:	c7 04 24 6a 51 10 f0 	movl   $0xf010516a,(%esp)
f0102d2e:	e8 d6 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	kern_pgdir[PDX] es %p (32b)\n",kpd+PDX(va1));
f0102d33:	8d 83 fc 07 00 00    	lea    0x7fc(%ebx),%eax
f0102d39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d3d:	c7 04 24 82 51 10 f0 	movl   $0xf0105182,(%esp)
f0102d44:	e8 c0 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	y su contenido es %p (32b)\n",kpd[PDX(va1)]);
f0102d49:	8b 83 fc 07 00 00    	mov    0x7fc(%ebx),%eax
f0102d4f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d53:	c7 04 24 a0 51 10 f0 	movl   $0xf01051a0,(%esp)
f0102d5a:	e8 aa 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	o tambien es %p (32b)\n",*(kpd+PDX(va1)));
f0102d5f:	8b 83 fc 07 00 00    	mov    0x7fc(%ebx),%eax
f0102d65:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d69:	c7 04 24 bd 51 10 f0 	movl   $0xf01051bd,(%esp)
f0102d70:	e8 94 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	que maskeado es %p (32b, ultimos 10 en 0)\n",PTE_ADDR(kpd[PDX(va1)]));
f0102d75:	8b 83 fc 07 00 00    	mov    0x7fc(%ebx),%eax
f0102d7b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d80:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d84:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102d8b:	e8 79 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	kern_pgdir[PTX] es %p (32b)\n",kpd+PTX(va1));
f0102d90:	8d 83 6c 08 00 00    	lea    0x86c(%ebx),%eax
f0102d96:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d9a:	c7 04 24 d5 51 10 f0 	movl   $0xf01051d5,(%esp)
f0102da1:	e8 63 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	y su contenido es %p (32b)\n",kpd[PTX(va1)]);
f0102da6:	8b 83 6c 08 00 00    	mov    0x86c(%ebx),%eax
f0102dac:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102db0:	c7 04 24 a0 51 10 f0 	movl   $0xf01051a0,(%esp)
f0102db7:	e8 4d 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	o tambien es %p (32b)\n",*(kpd+PTX(va1)));
f0102dbc:	8b 83 6c 08 00 00    	mov    0x86c(%ebx),%eax
f0102dc2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102dc6:	c7 04 24 bd 51 10 f0 	movl   $0xf01051bd,(%esp)
f0102dcd:	e8 37 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	que maskeado es %p (32b, ultimos 10 en 0)\n",PTE_ADDR(kpd[PTX(va1)]));
f0102dd2:	8b 83 6c 08 00 00    	mov    0x86c(%ebx),%eax
f0102dd8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102ddd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102de1:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f0102de8:	e8 1c 01 00 00       	call   f0102f09 <cprintf>

	cprintf("\n***OPERACIONES DE MASKING con VA = %p***\n",va1);
f0102ded:	c7 44 24 04 a7 b6 e1 	movl   $0x7fe1b6a7,0x4(%esp)
f0102df4:	7f 
f0102df5:	c7 04 24 4c 4c 10 f0 	movl   $0xf0104c4c,(%esp)
f0102dfc:	e8 08 01 00 00       	call   f0102f09 <cprintf>
	cprintf("	maskeada con PTE_ADDR es %p (vuela los 12 de abajo)\n",PTE_ADDR(va1));
f0102e01:	c7 44 24 04 00 b0 e1 	movl   $0x7fe1b000,0x4(%esp)
f0102e08:	7f 
f0102e09:	c7 04 24 78 4c 10 f0 	movl   $0xf0104c78,(%esp)
f0102e10:	e8 f4 00 00 00       	call   f0102f09 <cprintf>
	cprintf("\n\n");
f0102e15:	c7 04 24 f3 51 10 f0 	movl   $0xf01051f3,(%esp)
f0102e1c:	e8 e8 00 00 00       	call   f0102f09 <cprintf>
	//end:parte pruebas

	check_page_free_list(1);
f0102e21:	b8 01 00 00 00       	mov    $0x1,%eax
f0102e26:	e8 bc e0 ff ff       	call   f0100ee7 <check_page_free_list>
	check_page_alloc();
f0102e2b:	e8 14 e5 ff ff       	call   f0101344 <check_page_alloc>
	check_page();
f0102e30:	e8 a5 ec ff ff       	call   f0101ada <check_page>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f0102e35:	e8 51 de ff ff       	call   f0100c8b <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102e3a:	8b 0d 68 89 11 f0    	mov    0xf0118968,%ecx
f0102e40:	ba f5 00 00 00       	mov    $0xf5,%edx
f0102e45:	b8 c3 4c 10 f0       	mov    $0xf0104cc3,%eax
f0102e4a:	e8 0f de ff ff       	call   f0100c5e <_paddr>
f0102e4f:	e8 d4 db ff ff       	call   f0100a28 <lcr3>

	check_page_free_list(0);
f0102e54:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e59:	e8 89 e0 ff ff       	call   f0100ee7 <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f0102e5e:	e8 bd db ff ff       	call   f0100a20 <rcr0>
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102e63:	83 e0 f3             	and    $0xfffffff3,%eax
f0102e66:	0d 23 00 05 80       	or     $0x80050023,%eax
	lcr0(cr0);
f0102e6b:	e8 a8 db ff ff       	call   f0100a18 <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f0102e70:	e8 5a fa ff ff       	call   f01028cf <check_page_installed_pgdir>
}
f0102e75:	83 c4 14             	add    $0x14,%esp
f0102e78:	5b                   	pop    %ebx
f0102e79:	5d                   	pop    %ebp
f0102e7a:	c3                   	ret    

f0102e7b <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0102e7b:	55                   	push   %ebp
f0102e7c:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e7e:	89 c2                	mov    %eax,%edx
f0102e80:	ec                   	in     (%dx),%al
	return data;
}
f0102e81:	5d                   	pop    %ebp
f0102e82:	c3                   	ret    

f0102e83 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0102e83:	55                   	push   %ebp
f0102e84:	89 e5                	mov    %esp,%ebp
f0102e86:	89 c1                	mov    %eax,%ecx
f0102e88:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e8a:	89 ca                	mov    %ecx,%edx
f0102e8c:	ee                   	out    %al,(%dx)
}
f0102e8d:	5d                   	pop    %ebp
f0102e8e:	c3                   	ret    

f0102e8f <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102e8f:	55                   	push   %ebp
f0102e90:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102e92:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102e96:	b8 70 00 00 00       	mov    $0x70,%eax
f0102e9b:	e8 e3 ff ff ff       	call   f0102e83 <outb>
	return inb(IO_RTC+1);
f0102ea0:	b8 71 00 00 00       	mov    $0x71,%eax
f0102ea5:	e8 d1 ff ff ff       	call   f0102e7b <inb>
f0102eaa:	0f b6 c0             	movzbl %al,%eax
}
f0102ead:	5d                   	pop    %ebp
f0102eae:	c3                   	ret    

f0102eaf <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102eaf:	55                   	push   %ebp
f0102eb0:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102eb2:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102eb6:	b8 70 00 00 00       	mov    $0x70,%eax
f0102ebb:	e8 c3 ff ff ff       	call   f0102e83 <outb>
	outb(IO_RTC+1, datum);
f0102ec0:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0102ec4:	b8 71 00 00 00       	mov    $0x71,%eax
f0102ec9:	e8 b5 ff ff ff       	call   f0102e83 <outb>
}
f0102ece:	5d                   	pop    %ebp
f0102ecf:	c3                   	ret    

f0102ed0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ed0:	55                   	push   %ebp
f0102ed1:	89 e5                	mov    %esp,%ebp
f0102ed3:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102ed6:	ff 75 08             	pushl  0x8(%ebp)
f0102ed9:	e8 43 d8 ff ff       	call   f0100721 <cputchar>
	*cnt++;
}
f0102ede:	83 c4 10             	add    $0x10,%esp
f0102ee1:	c9                   	leave  
f0102ee2:	c3                   	ret    

f0102ee3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102ee3:	55                   	push   %ebp
f0102ee4:	89 e5                	mov    %esp,%ebp
f0102ee6:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102ee9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102ef0:	ff 75 0c             	pushl  0xc(%ebp)
f0102ef3:	ff 75 08             	pushl  0x8(%ebp)
f0102ef6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102ef9:	50                   	push   %eax
f0102efa:	68 d0 2e 10 f0       	push   $0xf0102ed0
f0102eff:	e8 82 04 00 00       	call   f0103386 <vprintfmt>
	return cnt;
}
f0102f04:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f07:	c9                   	leave  
f0102f08:	c3                   	ret    

f0102f09 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f09:	55                   	push   %ebp
f0102f0a:	89 e5                	mov    %esp,%ebp
f0102f0c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f0f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f12:	50                   	push   %eax
f0102f13:	ff 75 08             	pushl  0x8(%ebp)
f0102f16:	e8 c8 ff ff ff       	call   f0102ee3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f1b:	c9                   	leave  
f0102f1c:	c3                   	ret    

f0102f1d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102f1d:	55                   	push   %ebp
f0102f1e:	89 e5                	mov    %esp,%ebp
f0102f20:	57                   	push   %edi
f0102f21:	56                   	push   %esi
f0102f22:	53                   	push   %ebx
f0102f23:	83 ec 14             	sub    $0x14,%esp
f0102f26:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f29:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102f2c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102f2f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102f32:	8b 1a                	mov    (%edx),%ebx
f0102f34:	8b 01                	mov    (%ecx),%eax
f0102f36:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102f39:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102f40:	eb 7f                	jmp    f0102fc1 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102f42:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102f45:	01 d8                	add    %ebx,%eax
f0102f47:	89 c6                	mov    %eax,%esi
f0102f49:	c1 ee 1f             	shr    $0x1f,%esi
f0102f4c:	01 c6                	add    %eax,%esi
f0102f4e:	d1 fe                	sar    %esi
f0102f50:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102f53:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102f56:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102f59:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f5b:	eb 03                	jmp    f0102f60 <stab_binsearch+0x43>
			m--;
f0102f5d:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f60:	39 c3                	cmp    %eax,%ebx
f0102f62:	7f 0d                	jg     f0102f71 <stab_binsearch+0x54>
f0102f64:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102f68:	83 ea 0c             	sub    $0xc,%edx
f0102f6b:	39 f9                	cmp    %edi,%ecx
f0102f6d:	75 ee                	jne    f0102f5d <stab_binsearch+0x40>
f0102f6f:	eb 05                	jmp    f0102f76 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102f71:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102f74:	eb 4b                	jmp    f0102fc1 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102f76:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102f79:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102f7c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102f80:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102f83:	76 11                	jbe    f0102f96 <stab_binsearch+0x79>
			*region_left = m;
f0102f85:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102f88:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102f8a:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102f8d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102f94:	eb 2b                	jmp    f0102fc1 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102f96:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102f99:	73 14                	jae    f0102faf <stab_binsearch+0x92>
			*region_right = m - 1;
f0102f9b:	83 e8 01             	sub    $0x1,%eax
f0102f9e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102fa1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102fa4:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fa6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102fad:	eb 12                	jmp    f0102fc1 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102faf:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102fb2:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102fb4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102fb8:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fba:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102fc1:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102fc4:	0f 8e 78 ff ff ff    	jle    f0102f42 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102fca:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102fce:	75 0f                	jne    f0102fdf <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102fd0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fd3:	8b 00                	mov    (%eax),%eax
f0102fd5:	83 e8 01             	sub    $0x1,%eax
f0102fd8:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102fdb:	89 06                	mov    %eax,(%esi)
f0102fdd:	eb 2c                	jmp    f010300b <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102fdf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fe2:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102fe4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102fe7:	8b 0e                	mov    (%esi),%ecx
f0102fe9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102fec:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102fef:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ff2:	eb 03                	jmp    f0102ff7 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102ff4:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ff7:	39 c8                	cmp    %ecx,%eax
f0102ff9:	7e 0b                	jle    f0103006 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102ffb:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0102fff:	83 ea 0c             	sub    $0xc,%edx
f0103002:	39 df                	cmp    %ebx,%edi
f0103004:	75 ee                	jne    f0102ff4 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103006:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103009:	89 06                	mov    %eax,(%esi)
	}
}
f010300b:	83 c4 14             	add    $0x14,%esp
f010300e:	5b                   	pop    %ebx
f010300f:	5e                   	pop    %esi
f0103010:	5f                   	pop    %edi
f0103011:	5d                   	pop    %ebp
f0103012:	c3                   	ret    

f0103013 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103013:	55                   	push   %ebp
f0103014:	89 e5                	mov    %esp,%ebp
f0103016:	57                   	push   %edi
f0103017:	56                   	push   %esi
f0103018:	53                   	push   %ebx
f0103019:	83 ec 3c             	sub    $0x3c,%esp
f010301c:	8b 75 08             	mov    0x8(%ebp),%esi
f010301f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103022:	c7 03 f6 51 10 f0    	movl   $0xf01051f6,(%ebx)
	info->eip_line = 0;
f0103028:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010302f:	c7 43 08 f6 51 10 f0 	movl   $0xf01051f6,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103036:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010303d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103040:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103047:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010304d:	76 11                	jbe    f0103060 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010304f:	b8 ad d7 10 f0       	mov    $0xf010d7ad,%eax
f0103054:	3d 15 b4 10 f0       	cmp    $0xf010b415,%eax
f0103059:	77 19                	ja     f0103074 <debuginfo_eip+0x61>
f010305b:	e9 af 01 00 00       	jmp    f010320f <debuginfo_eip+0x1fc>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0103060:	83 ec 04             	sub    $0x4,%esp
f0103063:	68 00 52 10 f0       	push   $0xf0105200
f0103068:	6a 7f                	push   $0x7f
f010306a:	68 0d 52 10 f0       	push   $0xf010520d
f010306f:	e8 20 d0 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103074:	80 3d ac d7 10 f0 00 	cmpb   $0x0,0xf010d7ac
f010307b:	0f 85 95 01 00 00    	jne    f0103216 <debuginfo_eip+0x203>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103081:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103088:	b8 14 b4 10 f0       	mov    $0xf010b414,%eax
f010308d:	2d 2c 54 10 f0       	sub    $0xf010542c,%eax
f0103092:	c1 f8 02             	sar    $0x2,%eax
f0103095:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010309b:	83 e8 01             	sub    $0x1,%eax
f010309e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01030a1:	83 ec 08             	sub    $0x8,%esp
f01030a4:	56                   	push   %esi
f01030a5:	6a 64                	push   $0x64
f01030a7:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01030aa:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01030ad:	b8 2c 54 10 f0       	mov    $0xf010542c,%eax
f01030b2:	e8 66 fe ff ff       	call   f0102f1d <stab_binsearch>
	if (lfile == 0)
f01030b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030ba:	83 c4 10             	add    $0x10,%esp
f01030bd:	85 c0                	test   %eax,%eax
f01030bf:	0f 84 58 01 00 00    	je     f010321d <debuginfo_eip+0x20a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01030c5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01030c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030cb:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01030ce:	83 ec 08             	sub    $0x8,%esp
f01030d1:	56                   	push   %esi
f01030d2:	6a 24                	push   $0x24
f01030d4:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01030d7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01030da:	b8 2c 54 10 f0       	mov    $0xf010542c,%eax
f01030df:	e8 39 fe ff ff       	call   f0102f1d <stab_binsearch>

	if (lfun <= rfun) {
f01030e4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030e7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01030ea:	83 c4 10             	add    $0x10,%esp
f01030ed:	39 d0                	cmp    %edx,%eax
f01030ef:	7f 40                	jg     f0103131 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01030f1:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01030f4:	c1 e1 02             	shl    $0x2,%ecx
f01030f7:	8d b9 2c 54 10 f0    	lea    -0xfefabd4(%ecx),%edi
f01030fd:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0103100:	8b b9 2c 54 10 f0    	mov    -0xfefabd4(%ecx),%edi
f0103106:	b9 ad d7 10 f0       	mov    $0xf010d7ad,%ecx
f010310b:	81 e9 15 b4 10 f0    	sub    $0xf010b415,%ecx
f0103111:	39 cf                	cmp    %ecx,%edi
f0103113:	73 09                	jae    f010311e <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103115:	81 c7 15 b4 10 f0    	add    $0xf010b415,%edi
f010311b:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010311e:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0103121:	8b 4f 08             	mov    0x8(%edi),%ecx
f0103124:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103127:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103129:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010312c:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010312f:	eb 0f                	jmp    f0103140 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103131:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103134:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103137:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010313a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010313d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103140:	83 ec 08             	sub    $0x8,%esp
f0103143:	6a 3a                	push   $0x3a
f0103145:	ff 73 08             	pushl  0x8(%ebx)
f0103148:	e8 44 08 00 00       	call   f0103991 <strfind>
f010314d:	2b 43 08             	sub    0x8(%ebx),%eax
f0103150:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103153:	83 c4 08             	add    $0x8,%esp
f0103156:	56                   	push   %esi
f0103157:	6a 44                	push   $0x44
f0103159:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010315c:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010315f:	b8 2c 54 10 f0       	mov    $0xf010542c,%eax
f0103164:	e8 b4 fd ff ff       	call   f0102f1d <stab_binsearch>
	if (lline <= rline) {
f0103169:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010316c:	83 c4 10             	add    $0x10,%esp
f010316f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103172:	7f 0e                	jg     f0103182 <debuginfo_eip+0x16f>
		info->eip_line = stabs[lline].n_desc;
f0103174:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103177:	0f b7 14 95 32 54 10 	movzwl -0xfefabce(,%edx,4),%edx
f010317e:	f0 
f010317f:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103182:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103185:	89 c2                	mov    %eax,%edx
f0103187:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010318a:	8d 04 85 2c 54 10 f0 	lea    -0xfefabd4(,%eax,4),%eax
f0103191:	eb 06                	jmp    f0103199 <debuginfo_eip+0x186>
f0103193:	83 ea 01             	sub    $0x1,%edx
f0103196:	83 e8 0c             	sub    $0xc,%eax
f0103199:	39 d7                	cmp    %edx,%edi
f010319b:	7f 34                	jg     f01031d1 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f010319d:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01031a1:	80 f9 84             	cmp    $0x84,%cl
f01031a4:	74 0b                	je     f01031b1 <debuginfo_eip+0x19e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01031a6:	80 f9 64             	cmp    $0x64,%cl
f01031a9:	75 e8                	jne    f0103193 <debuginfo_eip+0x180>
f01031ab:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01031af:	74 e2                	je     f0103193 <debuginfo_eip+0x180>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01031b1:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01031b4:	8b 14 85 2c 54 10 f0 	mov    -0xfefabd4(,%eax,4),%edx
f01031bb:	b8 ad d7 10 f0       	mov    $0xf010d7ad,%eax
f01031c0:	2d 15 b4 10 f0       	sub    $0xf010b415,%eax
f01031c5:	39 c2                	cmp    %eax,%edx
f01031c7:	73 08                	jae    f01031d1 <debuginfo_eip+0x1be>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01031c9:	81 c2 15 b4 10 f0    	add    $0xf010b415,%edx
f01031cf:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01031d1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01031d4:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01031d7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01031dc:	39 f2                	cmp    %esi,%edx
f01031de:	7d 49                	jge    f0103229 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
f01031e0:	83 c2 01             	add    $0x1,%edx
f01031e3:	89 d0                	mov    %edx,%eax
f01031e5:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01031e8:	8d 14 95 2c 54 10 f0 	lea    -0xfefabd4(,%edx,4),%edx
f01031ef:	eb 04                	jmp    f01031f5 <debuginfo_eip+0x1e2>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01031f1:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01031f5:	39 c6                	cmp    %eax,%esi
f01031f7:	7e 2b                	jle    f0103224 <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01031f9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01031fd:	83 c0 01             	add    $0x1,%eax
f0103200:	83 c2 0c             	add    $0xc,%edx
f0103203:	80 f9 a0             	cmp    $0xa0,%cl
f0103206:	74 e9                	je     f01031f1 <debuginfo_eip+0x1de>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103208:	b8 00 00 00 00       	mov    $0x0,%eax
f010320d:	eb 1a                	jmp    f0103229 <debuginfo_eip+0x216>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010320f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103214:	eb 13                	jmp    f0103229 <debuginfo_eip+0x216>
f0103216:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010321b:	eb 0c                	jmp    f0103229 <debuginfo_eip+0x216>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010321d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103222:	eb 05                	jmp    f0103229 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103224:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103229:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010322c:	5b                   	pop    %ebx
f010322d:	5e                   	pop    %esi
f010322e:	5f                   	pop    %edi
f010322f:	5d                   	pop    %ebp
f0103230:	c3                   	ret    

f0103231 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103231:	55                   	push   %ebp
f0103232:	89 e5                	mov    %esp,%ebp
f0103234:	57                   	push   %edi
f0103235:	56                   	push   %esi
f0103236:	53                   	push   %ebx
f0103237:	83 ec 1c             	sub    $0x1c,%esp
f010323a:	89 c7                	mov    %eax,%edi
f010323c:	89 d6                	mov    %edx,%esi
f010323e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103241:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103244:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103247:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010324a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010324d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103252:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103255:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103258:	39 d3                	cmp    %edx,%ebx
f010325a:	72 05                	jb     f0103261 <printnum+0x30>
f010325c:	39 45 10             	cmp    %eax,0x10(%ebp)
f010325f:	77 45                	ja     f01032a6 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103261:	83 ec 0c             	sub    $0xc,%esp
f0103264:	ff 75 18             	pushl  0x18(%ebp)
f0103267:	8b 45 14             	mov    0x14(%ebp),%eax
f010326a:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010326d:	53                   	push   %ebx
f010326e:	ff 75 10             	pushl  0x10(%ebp)
f0103271:	83 ec 08             	sub    $0x8,%esp
f0103274:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103277:	ff 75 e0             	pushl  -0x20(%ebp)
f010327a:	ff 75 dc             	pushl  -0x24(%ebp)
f010327d:	ff 75 d8             	pushl  -0x28(%ebp)
f0103280:	e8 2b 09 00 00       	call   f0103bb0 <__udivdi3>
f0103285:	83 c4 18             	add    $0x18,%esp
f0103288:	52                   	push   %edx
f0103289:	50                   	push   %eax
f010328a:	89 f2                	mov    %esi,%edx
f010328c:	89 f8                	mov    %edi,%eax
f010328e:	e8 9e ff ff ff       	call   f0103231 <printnum>
f0103293:	83 c4 20             	add    $0x20,%esp
f0103296:	eb 18                	jmp    f01032b0 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103298:	83 ec 08             	sub    $0x8,%esp
f010329b:	56                   	push   %esi
f010329c:	ff 75 18             	pushl  0x18(%ebp)
f010329f:	ff d7                	call   *%edi
f01032a1:	83 c4 10             	add    $0x10,%esp
f01032a4:	eb 03                	jmp    f01032a9 <printnum+0x78>
f01032a6:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01032a9:	83 eb 01             	sub    $0x1,%ebx
f01032ac:	85 db                	test   %ebx,%ebx
f01032ae:	7f e8                	jg     f0103298 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01032b0:	83 ec 08             	sub    $0x8,%esp
f01032b3:	56                   	push   %esi
f01032b4:	83 ec 04             	sub    $0x4,%esp
f01032b7:	ff 75 e4             	pushl  -0x1c(%ebp)
f01032ba:	ff 75 e0             	pushl  -0x20(%ebp)
f01032bd:	ff 75 dc             	pushl  -0x24(%ebp)
f01032c0:	ff 75 d8             	pushl  -0x28(%ebp)
f01032c3:	e8 18 0a 00 00       	call   f0103ce0 <__umoddi3>
f01032c8:	83 c4 14             	add    $0x14,%esp
f01032cb:	0f be 80 1b 52 10 f0 	movsbl -0xfefade5(%eax),%eax
f01032d2:	50                   	push   %eax
f01032d3:	ff d7                	call   *%edi
}
f01032d5:	83 c4 10             	add    $0x10,%esp
f01032d8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032db:	5b                   	pop    %ebx
f01032dc:	5e                   	pop    %esi
f01032dd:	5f                   	pop    %edi
f01032de:	5d                   	pop    %ebp
f01032df:	c3                   	ret    

f01032e0 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01032e0:	55                   	push   %ebp
f01032e1:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01032e3:	83 fa 01             	cmp    $0x1,%edx
f01032e6:	7e 0e                	jle    f01032f6 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01032e8:	8b 10                	mov    (%eax),%edx
f01032ea:	8d 4a 08             	lea    0x8(%edx),%ecx
f01032ed:	89 08                	mov    %ecx,(%eax)
f01032ef:	8b 02                	mov    (%edx),%eax
f01032f1:	8b 52 04             	mov    0x4(%edx),%edx
f01032f4:	eb 22                	jmp    f0103318 <getuint+0x38>
	else if (lflag)
f01032f6:	85 d2                	test   %edx,%edx
f01032f8:	74 10                	je     f010330a <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01032fa:	8b 10                	mov    (%eax),%edx
f01032fc:	8d 4a 04             	lea    0x4(%edx),%ecx
f01032ff:	89 08                	mov    %ecx,(%eax)
f0103301:	8b 02                	mov    (%edx),%eax
f0103303:	ba 00 00 00 00       	mov    $0x0,%edx
f0103308:	eb 0e                	jmp    f0103318 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010330a:	8b 10                	mov    (%eax),%edx
f010330c:	8d 4a 04             	lea    0x4(%edx),%ecx
f010330f:	89 08                	mov    %ecx,(%eax)
f0103311:	8b 02                	mov    (%edx),%eax
f0103313:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103318:	5d                   	pop    %ebp
f0103319:	c3                   	ret    

f010331a <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f010331a:	55                   	push   %ebp
f010331b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010331d:	83 fa 01             	cmp    $0x1,%edx
f0103320:	7e 0e                	jle    f0103330 <getint+0x16>
		return va_arg(*ap, long long);
f0103322:	8b 10                	mov    (%eax),%edx
f0103324:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103327:	89 08                	mov    %ecx,(%eax)
f0103329:	8b 02                	mov    (%edx),%eax
f010332b:	8b 52 04             	mov    0x4(%edx),%edx
f010332e:	eb 1a                	jmp    f010334a <getint+0x30>
	else if (lflag)
f0103330:	85 d2                	test   %edx,%edx
f0103332:	74 0c                	je     f0103340 <getint+0x26>
		return va_arg(*ap, long);
f0103334:	8b 10                	mov    (%eax),%edx
f0103336:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103339:	89 08                	mov    %ecx,(%eax)
f010333b:	8b 02                	mov    (%edx),%eax
f010333d:	99                   	cltd   
f010333e:	eb 0a                	jmp    f010334a <getint+0x30>
	else
		return va_arg(*ap, int);
f0103340:	8b 10                	mov    (%eax),%edx
f0103342:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103345:	89 08                	mov    %ecx,(%eax)
f0103347:	8b 02                	mov    (%edx),%eax
f0103349:	99                   	cltd   
}
f010334a:	5d                   	pop    %ebp
f010334b:	c3                   	ret    

f010334c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010334c:	55                   	push   %ebp
f010334d:	89 e5                	mov    %esp,%ebp
f010334f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103352:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103356:	8b 10                	mov    (%eax),%edx
f0103358:	3b 50 04             	cmp    0x4(%eax),%edx
f010335b:	73 0a                	jae    f0103367 <sprintputch+0x1b>
		*b->buf++ = ch;
f010335d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103360:	89 08                	mov    %ecx,(%eax)
f0103362:	8b 45 08             	mov    0x8(%ebp),%eax
f0103365:	88 02                	mov    %al,(%edx)
}
f0103367:	5d                   	pop    %ebp
f0103368:	c3                   	ret    

f0103369 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103369:	55                   	push   %ebp
f010336a:	89 e5                	mov    %esp,%ebp
f010336c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010336f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103372:	50                   	push   %eax
f0103373:	ff 75 10             	pushl  0x10(%ebp)
f0103376:	ff 75 0c             	pushl  0xc(%ebp)
f0103379:	ff 75 08             	pushl  0x8(%ebp)
f010337c:	e8 05 00 00 00       	call   f0103386 <vprintfmt>
	va_end(ap);
}
f0103381:	83 c4 10             	add    $0x10,%esp
f0103384:	c9                   	leave  
f0103385:	c3                   	ret    

f0103386 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103386:	55                   	push   %ebp
f0103387:	89 e5                	mov    %esp,%ebp
f0103389:	57                   	push   %edi
f010338a:	56                   	push   %esi
f010338b:	53                   	push   %ebx
f010338c:	83 ec 2c             	sub    $0x2c,%esp
f010338f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103392:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103395:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103398:	eb 12                	jmp    f01033ac <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010339a:	85 c0                	test   %eax,%eax
f010339c:	0f 84 44 03 00 00    	je     f01036e6 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f01033a2:	83 ec 08             	sub    $0x8,%esp
f01033a5:	53                   	push   %ebx
f01033a6:	50                   	push   %eax
f01033a7:	ff d6                	call   *%esi
f01033a9:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01033ac:	83 c7 01             	add    $0x1,%edi
f01033af:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01033b3:	83 f8 25             	cmp    $0x25,%eax
f01033b6:	75 e2                	jne    f010339a <vprintfmt+0x14>
f01033b8:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01033bc:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01033c3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01033ca:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01033d1:	ba 00 00 00 00       	mov    $0x0,%edx
f01033d6:	eb 07                	jmp    f01033df <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033d8:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01033db:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033df:	8d 47 01             	lea    0x1(%edi),%eax
f01033e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01033e5:	0f b6 07             	movzbl (%edi),%eax
f01033e8:	0f b6 c8             	movzbl %al,%ecx
f01033eb:	83 e8 23             	sub    $0x23,%eax
f01033ee:	3c 55                	cmp    $0x55,%al
f01033f0:	0f 87 d5 02 00 00    	ja     f01036cb <vprintfmt+0x345>
f01033f6:	0f b6 c0             	movzbl %al,%eax
f01033f9:	ff 24 85 a8 52 10 f0 	jmp    *-0xfefad58(,%eax,4)
f0103400:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103403:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103407:	eb d6                	jmp    f01033df <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103409:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010340c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103411:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103417:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f010341b:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f010341e:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103421:	83 fa 09             	cmp    $0x9,%edx
f0103424:	77 39                	ja     f010345f <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103426:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103429:	eb e9                	jmp    f0103414 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010342b:	8b 45 14             	mov    0x14(%ebp),%eax
f010342e:	8d 48 04             	lea    0x4(%eax),%ecx
f0103431:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103434:	8b 00                	mov    (%eax),%eax
f0103436:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103439:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010343c:	eb 27                	jmp    f0103465 <vprintfmt+0xdf>
f010343e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103441:	85 c0                	test   %eax,%eax
f0103443:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103448:	0f 49 c8             	cmovns %eax,%ecx
f010344b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010344e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103451:	eb 8c                	jmp    f01033df <vprintfmt+0x59>
f0103453:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103456:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010345d:	eb 80                	jmp    f01033df <vprintfmt+0x59>
f010345f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103462:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103465:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103469:	0f 89 70 ff ff ff    	jns    f01033df <vprintfmt+0x59>
				width = precision, precision = -1;
f010346f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103472:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103475:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f010347c:	e9 5e ff ff ff       	jmp    f01033df <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103481:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103484:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103487:	e9 53 ff ff ff       	jmp    f01033df <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010348c:	8b 45 14             	mov    0x14(%ebp),%eax
f010348f:	8d 50 04             	lea    0x4(%eax),%edx
f0103492:	89 55 14             	mov    %edx,0x14(%ebp)
f0103495:	83 ec 08             	sub    $0x8,%esp
f0103498:	53                   	push   %ebx
f0103499:	ff 30                	pushl  (%eax)
f010349b:	ff d6                	call   *%esi
			break;
f010349d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01034a3:	e9 04 ff ff ff       	jmp    f01033ac <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01034a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01034ab:	8d 50 04             	lea    0x4(%eax),%edx
f01034ae:	89 55 14             	mov    %edx,0x14(%ebp)
f01034b1:	8b 00                	mov    (%eax),%eax
f01034b3:	99                   	cltd   
f01034b4:	31 d0                	xor    %edx,%eax
f01034b6:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01034b8:	83 f8 06             	cmp    $0x6,%eax
f01034bb:	7f 0b                	jg     f01034c8 <vprintfmt+0x142>
f01034bd:	8b 14 85 00 54 10 f0 	mov    -0xfefac00(,%eax,4),%edx
f01034c4:	85 d2                	test   %edx,%edx
f01034c6:	75 18                	jne    f01034e0 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01034c8:	50                   	push   %eax
f01034c9:	68 33 52 10 f0       	push   $0xf0105233
f01034ce:	53                   	push   %ebx
f01034cf:	56                   	push   %esi
f01034d0:	e8 94 fe ff ff       	call   f0103369 <printfmt>
f01034d5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034d8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01034db:	e9 cc fe ff ff       	jmp    f01033ac <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01034e0:	52                   	push   %edx
f01034e1:	68 26 4d 10 f0       	push   $0xf0104d26
f01034e6:	53                   	push   %ebx
f01034e7:	56                   	push   %esi
f01034e8:	e8 7c fe ff ff       	call   f0103369 <printfmt>
f01034ed:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034f0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034f3:	e9 b4 fe ff ff       	jmp    f01033ac <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01034f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01034fb:	8d 50 04             	lea    0x4(%eax),%edx
f01034fe:	89 55 14             	mov    %edx,0x14(%ebp)
f0103501:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103503:	85 ff                	test   %edi,%edi
f0103505:	b8 2c 52 10 f0       	mov    $0xf010522c,%eax
f010350a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010350d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103511:	0f 8e 94 00 00 00    	jle    f01035ab <vprintfmt+0x225>
f0103517:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010351b:	0f 84 98 00 00 00    	je     f01035b9 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103521:	83 ec 08             	sub    $0x8,%esp
f0103524:	ff 75 d0             	pushl  -0x30(%ebp)
f0103527:	57                   	push   %edi
f0103528:	e8 1a 03 00 00       	call   f0103847 <strnlen>
f010352d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103530:	29 c1                	sub    %eax,%ecx
f0103532:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103535:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103538:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010353c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010353f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103542:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103544:	eb 0f                	jmp    f0103555 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103546:	83 ec 08             	sub    $0x8,%esp
f0103549:	53                   	push   %ebx
f010354a:	ff 75 e0             	pushl  -0x20(%ebp)
f010354d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010354f:	83 ef 01             	sub    $0x1,%edi
f0103552:	83 c4 10             	add    $0x10,%esp
f0103555:	85 ff                	test   %edi,%edi
f0103557:	7f ed                	jg     f0103546 <vprintfmt+0x1c0>
f0103559:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010355c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010355f:	85 c9                	test   %ecx,%ecx
f0103561:	b8 00 00 00 00       	mov    $0x0,%eax
f0103566:	0f 49 c1             	cmovns %ecx,%eax
f0103569:	29 c1                	sub    %eax,%ecx
f010356b:	89 75 08             	mov    %esi,0x8(%ebp)
f010356e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103571:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103574:	89 cb                	mov    %ecx,%ebx
f0103576:	eb 4d                	jmp    f01035c5 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103578:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010357c:	74 1b                	je     f0103599 <vprintfmt+0x213>
f010357e:	0f be c0             	movsbl %al,%eax
f0103581:	83 e8 20             	sub    $0x20,%eax
f0103584:	83 f8 5e             	cmp    $0x5e,%eax
f0103587:	76 10                	jbe    f0103599 <vprintfmt+0x213>
					putch('?', putdat);
f0103589:	83 ec 08             	sub    $0x8,%esp
f010358c:	ff 75 0c             	pushl  0xc(%ebp)
f010358f:	6a 3f                	push   $0x3f
f0103591:	ff 55 08             	call   *0x8(%ebp)
f0103594:	83 c4 10             	add    $0x10,%esp
f0103597:	eb 0d                	jmp    f01035a6 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103599:	83 ec 08             	sub    $0x8,%esp
f010359c:	ff 75 0c             	pushl  0xc(%ebp)
f010359f:	52                   	push   %edx
f01035a0:	ff 55 08             	call   *0x8(%ebp)
f01035a3:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01035a6:	83 eb 01             	sub    $0x1,%ebx
f01035a9:	eb 1a                	jmp    f01035c5 <vprintfmt+0x23f>
f01035ab:	89 75 08             	mov    %esi,0x8(%ebp)
f01035ae:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01035b1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01035b4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01035b7:	eb 0c                	jmp    f01035c5 <vprintfmt+0x23f>
f01035b9:	89 75 08             	mov    %esi,0x8(%ebp)
f01035bc:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01035bf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01035c2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01035c5:	83 c7 01             	add    $0x1,%edi
f01035c8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01035cc:	0f be d0             	movsbl %al,%edx
f01035cf:	85 d2                	test   %edx,%edx
f01035d1:	74 23                	je     f01035f6 <vprintfmt+0x270>
f01035d3:	85 f6                	test   %esi,%esi
f01035d5:	78 a1                	js     f0103578 <vprintfmt+0x1f2>
f01035d7:	83 ee 01             	sub    $0x1,%esi
f01035da:	79 9c                	jns    f0103578 <vprintfmt+0x1f2>
f01035dc:	89 df                	mov    %ebx,%edi
f01035de:	8b 75 08             	mov    0x8(%ebp),%esi
f01035e1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01035e4:	eb 18                	jmp    f01035fe <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01035e6:	83 ec 08             	sub    $0x8,%esp
f01035e9:	53                   	push   %ebx
f01035ea:	6a 20                	push   $0x20
f01035ec:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01035ee:	83 ef 01             	sub    $0x1,%edi
f01035f1:	83 c4 10             	add    $0x10,%esp
f01035f4:	eb 08                	jmp    f01035fe <vprintfmt+0x278>
f01035f6:	89 df                	mov    %ebx,%edi
f01035f8:	8b 75 08             	mov    0x8(%ebp),%esi
f01035fb:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01035fe:	85 ff                	test   %edi,%edi
f0103600:	7f e4                	jg     f01035e6 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103602:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103605:	e9 a2 fd ff ff       	jmp    f01033ac <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010360a:	8d 45 14             	lea    0x14(%ebp),%eax
f010360d:	e8 08 fd ff ff       	call   f010331a <getint>
f0103612:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103615:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103618:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010361d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103621:	79 74                	jns    f0103697 <vprintfmt+0x311>
				putch('-', putdat);
f0103623:	83 ec 08             	sub    $0x8,%esp
f0103626:	53                   	push   %ebx
f0103627:	6a 2d                	push   $0x2d
f0103629:	ff d6                	call   *%esi
				num = -(long long) num;
f010362b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010362e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103631:	f7 d8                	neg    %eax
f0103633:	83 d2 00             	adc    $0x0,%edx
f0103636:	f7 da                	neg    %edx
f0103638:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f010363b:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103640:	eb 55                	jmp    f0103697 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103642:	8d 45 14             	lea    0x14(%ebp),%eax
f0103645:	e8 96 fc ff ff       	call   f01032e0 <getuint>
			base = 10;
f010364a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010364f:	eb 46                	jmp    f0103697 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0103651:	8d 45 14             	lea    0x14(%ebp),%eax
f0103654:	e8 87 fc ff ff       	call   f01032e0 <getuint>
			base = 8;
f0103659:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010365e:	eb 37                	jmp    f0103697 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0103660:	83 ec 08             	sub    $0x8,%esp
f0103663:	53                   	push   %ebx
f0103664:	6a 30                	push   $0x30
f0103666:	ff d6                	call   *%esi
			putch('x', putdat);
f0103668:	83 c4 08             	add    $0x8,%esp
f010366b:	53                   	push   %ebx
f010366c:	6a 78                	push   $0x78
f010366e:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103670:	8b 45 14             	mov    0x14(%ebp),%eax
f0103673:	8d 50 04             	lea    0x4(%eax),%edx
f0103676:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103679:	8b 00                	mov    (%eax),%eax
f010367b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103680:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103683:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103688:	eb 0d                	jmp    f0103697 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010368a:	8d 45 14             	lea    0x14(%ebp),%eax
f010368d:	e8 4e fc ff ff       	call   f01032e0 <getuint>
			base = 16;
f0103692:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103697:	83 ec 0c             	sub    $0xc,%esp
f010369a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010369e:	57                   	push   %edi
f010369f:	ff 75 e0             	pushl  -0x20(%ebp)
f01036a2:	51                   	push   %ecx
f01036a3:	52                   	push   %edx
f01036a4:	50                   	push   %eax
f01036a5:	89 da                	mov    %ebx,%edx
f01036a7:	89 f0                	mov    %esi,%eax
f01036a9:	e8 83 fb ff ff       	call   f0103231 <printnum>
			break;
f01036ae:	83 c4 20             	add    $0x20,%esp
f01036b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01036b4:	e9 f3 fc ff ff       	jmp    f01033ac <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01036b9:	83 ec 08             	sub    $0x8,%esp
f01036bc:	53                   	push   %ebx
f01036bd:	51                   	push   %ecx
f01036be:	ff d6                	call   *%esi
			break;
f01036c0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01036c6:	e9 e1 fc ff ff       	jmp    f01033ac <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01036cb:	83 ec 08             	sub    $0x8,%esp
f01036ce:	53                   	push   %ebx
f01036cf:	6a 25                	push   $0x25
f01036d1:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01036d3:	83 c4 10             	add    $0x10,%esp
f01036d6:	eb 03                	jmp    f01036db <vprintfmt+0x355>
f01036d8:	83 ef 01             	sub    $0x1,%edi
f01036db:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01036df:	75 f7                	jne    f01036d8 <vprintfmt+0x352>
f01036e1:	e9 c6 fc ff ff       	jmp    f01033ac <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01036e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01036e9:	5b                   	pop    %ebx
f01036ea:	5e                   	pop    %esi
f01036eb:	5f                   	pop    %edi
f01036ec:	5d                   	pop    %ebp
f01036ed:	c3                   	ret    

f01036ee <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01036ee:	55                   	push   %ebp
f01036ef:	89 e5                	mov    %esp,%ebp
f01036f1:	83 ec 18             	sub    $0x18,%esp
f01036f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01036f7:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01036fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01036fd:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103701:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103704:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010370b:	85 c0                	test   %eax,%eax
f010370d:	74 26                	je     f0103735 <vsnprintf+0x47>
f010370f:	85 d2                	test   %edx,%edx
f0103711:	7e 22                	jle    f0103735 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103713:	ff 75 14             	pushl  0x14(%ebp)
f0103716:	ff 75 10             	pushl  0x10(%ebp)
f0103719:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010371c:	50                   	push   %eax
f010371d:	68 4c 33 10 f0       	push   $0xf010334c
f0103722:	e8 5f fc ff ff       	call   f0103386 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103727:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010372a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010372d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103730:	83 c4 10             	add    $0x10,%esp
f0103733:	eb 05                	jmp    f010373a <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103735:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010373a:	c9                   	leave  
f010373b:	c3                   	ret    

f010373c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010373c:	55                   	push   %ebp
f010373d:	89 e5                	mov    %esp,%ebp
f010373f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103742:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103745:	50                   	push   %eax
f0103746:	ff 75 10             	pushl  0x10(%ebp)
f0103749:	ff 75 0c             	pushl  0xc(%ebp)
f010374c:	ff 75 08             	pushl  0x8(%ebp)
f010374f:	e8 9a ff ff ff       	call   f01036ee <vsnprintf>
	va_end(ap);

	return rc;
}
f0103754:	c9                   	leave  
f0103755:	c3                   	ret    

f0103756 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103756:	55                   	push   %ebp
f0103757:	89 e5                	mov    %esp,%ebp
f0103759:	57                   	push   %edi
f010375a:	56                   	push   %esi
f010375b:	53                   	push   %ebx
f010375c:	83 ec 0c             	sub    $0xc,%esp
f010375f:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103762:	85 c0                	test   %eax,%eax
f0103764:	74 11                	je     f0103777 <readline+0x21>
		cprintf("%s", prompt);
f0103766:	83 ec 08             	sub    $0x8,%esp
f0103769:	50                   	push   %eax
f010376a:	68 26 4d 10 f0       	push   $0xf0104d26
f010376f:	e8 95 f7 ff ff       	call   f0102f09 <cprintf>
f0103774:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103777:	83 ec 0c             	sub    $0xc,%esp
f010377a:	6a 00                	push   $0x0
f010377c:	e8 c1 cf ff ff       	call   f0100742 <iscons>
f0103781:	89 c7                	mov    %eax,%edi
f0103783:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103786:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010378b:	e8 a1 cf ff ff       	call   f0100731 <getchar>
f0103790:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103792:	85 c0                	test   %eax,%eax
f0103794:	79 18                	jns    f01037ae <readline+0x58>
			cprintf("read error: %e\n", c);
f0103796:	83 ec 08             	sub    $0x8,%esp
f0103799:	50                   	push   %eax
f010379a:	68 1c 54 10 f0       	push   $0xf010541c
f010379f:	e8 65 f7 ff ff       	call   f0102f09 <cprintf>
			return NULL;
f01037a4:	83 c4 10             	add    $0x10,%esp
f01037a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01037ac:	eb 79                	jmp    f0103827 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01037ae:	83 f8 08             	cmp    $0x8,%eax
f01037b1:	0f 94 c2             	sete   %dl
f01037b4:	83 f8 7f             	cmp    $0x7f,%eax
f01037b7:	0f 94 c0             	sete   %al
f01037ba:	08 c2                	or     %al,%dl
f01037bc:	74 1a                	je     f01037d8 <readline+0x82>
f01037be:	85 f6                	test   %esi,%esi
f01037c0:	7e 16                	jle    f01037d8 <readline+0x82>
			if (echoing)
f01037c2:	85 ff                	test   %edi,%edi
f01037c4:	74 0d                	je     f01037d3 <readline+0x7d>
				cputchar('\b');
f01037c6:	83 ec 0c             	sub    $0xc,%esp
f01037c9:	6a 08                	push   $0x8
f01037cb:	e8 51 cf ff ff       	call   f0100721 <cputchar>
f01037d0:	83 c4 10             	add    $0x10,%esp
			i--;
f01037d3:	83 ee 01             	sub    $0x1,%esi
f01037d6:	eb b3                	jmp    f010378b <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01037d8:	83 fb 1f             	cmp    $0x1f,%ebx
f01037db:	7e 23                	jle    f0103800 <readline+0xaa>
f01037dd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01037e3:	7f 1b                	jg     f0103800 <readline+0xaa>
			if (echoing)
f01037e5:	85 ff                	test   %edi,%edi
f01037e7:	74 0c                	je     f01037f5 <readline+0x9f>
				cputchar(c);
f01037e9:	83 ec 0c             	sub    $0xc,%esp
f01037ec:	53                   	push   %ebx
f01037ed:	e8 2f cf ff ff       	call   f0100721 <cputchar>
f01037f2:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01037f5:	88 9e 60 85 11 f0    	mov    %bl,-0xfee7aa0(%esi)
f01037fb:	8d 76 01             	lea    0x1(%esi),%esi
f01037fe:	eb 8b                	jmp    f010378b <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103800:	83 fb 0a             	cmp    $0xa,%ebx
f0103803:	74 05                	je     f010380a <readline+0xb4>
f0103805:	83 fb 0d             	cmp    $0xd,%ebx
f0103808:	75 81                	jne    f010378b <readline+0x35>
			if (echoing)
f010380a:	85 ff                	test   %edi,%edi
f010380c:	74 0d                	je     f010381b <readline+0xc5>
				cputchar('\n');
f010380e:	83 ec 0c             	sub    $0xc,%esp
f0103811:	6a 0a                	push   $0xa
f0103813:	e8 09 cf ff ff       	call   f0100721 <cputchar>
f0103818:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010381b:	c6 86 60 85 11 f0 00 	movb   $0x0,-0xfee7aa0(%esi)
			return buf;
f0103822:	b8 60 85 11 f0       	mov    $0xf0118560,%eax
		}
	}
}
f0103827:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010382a:	5b                   	pop    %ebx
f010382b:	5e                   	pop    %esi
f010382c:	5f                   	pop    %edi
f010382d:	5d                   	pop    %ebp
f010382e:	c3                   	ret    

f010382f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010382f:	55                   	push   %ebp
f0103830:	89 e5                	mov    %esp,%ebp
f0103832:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103835:	b8 00 00 00 00       	mov    $0x0,%eax
f010383a:	eb 03                	jmp    f010383f <strlen+0x10>
		n++;
f010383c:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010383f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103843:	75 f7                	jne    f010383c <strlen+0xd>
		n++;
	return n;
}
f0103845:	5d                   	pop    %ebp
f0103846:	c3                   	ret    

f0103847 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103847:	55                   	push   %ebp
f0103848:	89 e5                	mov    %esp,%ebp
f010384a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010384d:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103850:	ba 00 00 00 00       	mov    $0x0,%edx
f0103855:	eb 03                	jmp    f010385a <strnlen+0x13>
		n++;
f0103857:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010385a:	39 c2                	cmp    %eax,%edx
f010385c:	74 08                	je     f0103866 <strnlen+0x1f>
f010385e:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103862:	75 f3                	jne    f0103857 <strnlen+0x10>
f0103864:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103866:	5d                   	pop    %ebp
f0103867:	c3                   	ret    

f0103868 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103868:	55                   	push   %ebp
f0103869:	89 e5                	mov    %esp,%ebp
f010386b:	53                   	push   %ebx
f010386c:	8b 45 08             	mov    0x8(%ebp),%eax
f010386f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103872:	89 c2                	mov    %eax,%edx
f0103874:	83 c2 01             	add    $0x1,%edx
f0103877:	83 c1 01             	add    $0x1,%ecx
f010387a:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010387e:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103881:	84 db                	test   %bl,%bl
f0103883:	75 ef                	jne    f0103874 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103885:	5b                   	pop    %ebx
f0103886:	5d                   	pop    %ebp
f0103887:	c3                   	ret    

f0103888 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103888:	55                   	push   %ebp
f0103889:	89 e5                	mov    %esp,%ebp
f010388b:	53                   	push   %ebx
f010388c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010388f:	53                   	push   %ebx
f0103890:	e8 9a ff ff ff       	call   f010382f <strlen>
f0103895:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103898:	ff 75 0c             	pushl  0xc(%ebp)
f010389b:	01 d8                	add    %ebx,%eax
f010389d:	50                   	push   %eax
f010389e:	e8 c5 ff ff ff       	call   f0103868 <strcpy>
	return dst;
}
f01038a3:	89 d8                	mov    %ebx,%eax
f01038a5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01038a8:	c9                   	leave  
f01038a9:	c3                   	ret    

f01038aa <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01038aa:	55                   	push   %ebp
f01038ab:	89 e5                	mov    %esp,%ebp
f01038ad:	56                   	push   %esi
f01038ae:	53                   	push   %ebx
f01038af:	8b 75 08             	mov    0x8(%ebp),%esi
f01038b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01038b5:	89 f3                	mov    %esi,%ebx
f01038b7:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01038ba:	89 f2                	mov    %esi,%edx
f01038bc:	eb 0f                	jmp    f01038cd <strncpy+0x23>
		*dst++ = *src;
f01038be:	83 c2 01             	add    $0x1,%edx
f01038c1:	0f b6 01             	movzbl (%ecx),%eax
f01038c4:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01038c7:	80 39 01             	cmpb   $0x1,(%ecx)
f01038ca:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01038cd:	39 da                	cmp    %ebx,%edx
f01038cf:	75 ed                	jne    f01038be <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01038d1:	89 f0                	mov    %esi,%eax
f01038d3:	5b                   	pop    %ebx
f01038d4:	5e                   	pop    %esi
f01038d5:	5d                   	pop    %ebp
f01038d6:	c3                   	ret    

f01038d7 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01038d7:	55                   	push   %ebp
f01038d8:	89 e5                	mov    %esp,%ebp
f01038da:	56                   	push   %esi
f01038db:	53                   	push   %ebx
f01038dc:	8b 75 08             	mov    0x8(%ebp),%esi
f01038df:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01038e2:	8b 55 10             	mov    0x10(%ebp),%edx
f01038e5:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01038e7:	85 d2                	test   %edx,%edx
f01038e9:	74 21                	je     f010390c <strlcpy+0x35>
f01038eb:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01038ef:	89 f2                	mov    %esi,%edx
f01038f1:	eb 09                	jmp    f01038fc <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01038f3:	83 c2 01             	add    $0x1,%edx
f01038f6:	83 c1 01             	add    $0x1,%ecx
f01038f9:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01038fc:	39 c2                	cmp    %eax,%edx
f01038fe:	74 09                	je     f0103909 <strlcpy+0x32>
f0103900:	0f b6 19             	movzbl (%ecx),%ebx
f0103903:	84 db                	test   %bl,%bl
f0103905:	75 ec                	jne    f01038f3 <strlcpy+0x1c>
f0103907:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103909:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010390c:	29 f0                	sub    %esi,%eax
}
f010390e:	5b                   	pop    %ebx
f010390f:	5e                   	pop    %esi
f0103910:	5d                   	pop    %ebp
f0103911:	c3                   	ret    

f0103912 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103912:	55                   	push   %ebp
f0103913:	89 e5                	mov    %esp,%ebp
f0103915:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103918:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010391b:	eb 06                	jmp    f0103923 <strcmp+0x11>
		p++, q++;
f010391d:	83 c1 01             	add    $0x1,%ecx
f0103920:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103923:	0f b6 01             	movzbl (%ecx),%eax
f0103926:	84 c0                	test   %al,%al
f0103928:	74 04                	je     f010392e <strcmp+0x1c>
f010392a:	3a 02                	cmp    (%edx),%al
f010392c:	74 ef                	je     f010391d <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010392e:	0f b6 c0             	movzbl %al,%eax
f0103931:	0f b6 12             	movzbl (%edx),%edx
f0103934:	29 d0                	sub    %edx,%eax
}
f0103936:	5d                   	pop    %ebp
f0103937:	c3                   	ret    

f0103938 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103938:	55                   	push   %ebp
f0103939:	89 e5                	mov    %esp,%ebp
f010393b:	53                   	push   %ebx
f010393c:	8b 45 08             	mov    0x8(%ebp),%eax
f010393f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103942:	89 c3                	mov    %eax,%ebx
f0103944:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103947:	eb 06                	jmp    f010394f <strncmp+0x17>
		n--, p++, q++;
f0103949:	83 c0 01             	add    $0x1,%eax
f010394c:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010394f:	39 d8                	cmp    %ebx,%eax
f0103951:	74 15                	je     f0103968 <strncmp+0x30>
f0103953:	0f b6 08             	movzbl (%eax),%ecx
f0103956:	84 c9                	test   %cl,%cl
f0103958:	74 04                	je     f010395e <strncmp+0x26>
f010395a:	3a 0a                	cmp    (%edx),%cl
f010395c:	74 eb                	je     f0103949 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010395e:	0f b6 00             	movzbl (%eax),%eax
f0103961:	0f b6 12             	movzbl (%edx),%edx
f0103964:	29 d0                	sub    %edx,%eax
f0103966:	eb 05                	jmp    f010396d <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103968:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010396d:	5b                   	pop    %ebx
f010396e:	5d                   	pop    %ebp
f010396f:	c3                   	ret    

f0103970 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103970:	55                   	push   %ebp
f0103971:	89 e5                	mov    %esp,%ebp
f0103973:	8b 45 08             	mov    0x8(%ebp),%eax
f0103976:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010397a:	eb 07                	jmp    f0103983 <strchr+0x13>
		if (*s == c)
f010397c:	38 ca                	cmp    %cl,%dl
f010397e:	74 0f                	je     f010398f <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103980:	83 c0 01             	add    $0x1,%eax
f0103983:	0f b6 10             	movzbl (%eax),%edx
f0103986:	84 d2                	test   %dl,%dl
f0103988:	75 f2                	jne    f010397c <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010398a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010398f:	5d                   	pop    %ebp
f0103990:	c3                   	ret    

f0103991 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103991:	55                   	push   %ebp
f0103992:	89 e5                	mov    %esp,%ebp
f0103994:	8b 45 08             	mov    0x8(%ebp),%eax
f0103997:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010399b:	eb 03                	jmp    f01039a0 <strfind+0xf>
f010399d:	83 c0 01             	add    $0x1,%eax
f01039a0:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01039a3:	38 ca                	cmp    %cl,%dl
f01039a5:	74 04                	je     f01039ab <strfind+0x1a>
f01039a7:	84 d2                	test   %dl,%dl
f01039a9:	75 f2                	jne    f010399d <strfind+0xc>
			break;
	return (char *) s;
}
f01039ab:	5d                   	pop    %ebp
f01039ac:	c3                   	ret    

f01039ad <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01039ad:	55                   	push   %ebp
f01039ae:	89 e5                	mov    %esp,%ebp
f01039b0:	57                   	push   %edi
f01039b1:	56                   	push   %esi
f01039b2:	53                   	push   %ebx
f01039b3:	8b 55 08             	mov    0x8(%ebp),%edx
f01039b6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f01039b9:	85 c9                	test   %ecx,%ecx
f01039bb:	74 37                	je     f01039f4 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01039bd:	f6 c2 03             	test   $0x3,%dl
f01039c0:	75 2a                	jne    f01039ec <memset+0x3f>
f01039c2:	f6 c1 03             	test   $0x3,%cl
f01039c5:	75 25                	jne    f01039ec <memset+0x3f>
		c &= 0xFF;
f01039c7:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01039cb:	89 df                	mov    %ebx,%edi
f01039cd:	c1 e7 08             	shl    $0x8,%edi
f01039d0:	89 de                	mov    %ebx,%esi
f01039d2:	c1 e6 18             	shl    $0x18,%esi
f01039d5:	89 d8                	mov    %ebx,%eax
f01039d7:	c1 e0 10             	shl    $0x10,%eax
f01039da:	09 f0                	or     %esi,%eax
f01039dc:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f01039de:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01039e1:	89 f8                	mov    %edi,%eax
f01039e3:	09 d8                	or     %ebx,%eax
f01039e5:	89 d7                	mov    %edx,%edi
f01039e7:	fc                   	cld    
f01039e8:	f3 ab                	rep stos %eax,%es:(%edi)
f01039ea:	eb 08                	jmp    f01039f4 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01039ec:	89 d7                	mov    %edx,%edi
f01039ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039f1:	fc                   	cld    
f01039f2:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f01039f4:	89 d0                	mov    %edx,%eax
f01039f6:	5b                   	pop    %ebx
f01039f7:	5e                   	pop    %esi
f01039f8:	5f                   	pop    %edi
f01039f9:	5d                   	pop    %ebp
f01039fa:	c3                   	ret    

f01039fb <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01039fb:	55                   	push   %ebp
f01039fc:	89 e5                	mov    %esp,%ebp
f01039fe:	57                   	push   %edi
f01039ff:	56                   	push   %esi
f0103a00:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a03:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a06:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103a09:	39 c6                	cmp    %eax,%esi
f0103a0b:	73 35                	jae    f0103a42 <memmove+0x47>
f0103a0d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103a10:	39 d0                	cmp    %edx,%eax
f0103a12:	73 2e                	jae    f0103a42 <memmove+0x47>
		s += n;
		d += n;
f0103a14:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a17:	89 d6                	mov    %edx,%esi
f0103a19:	09 fe                	or     %edi,%esi
f0103a1b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103a21:	75 13                	jne    f0103a36 <memmove+0x3b>
f0103a23:	f6 c1 03             	test   $0x3,%cl
f0103a26:	75 0e                	jne    f0103a36 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103a28:	83 ef 04             	sub    $0x4,%edi
f0103a2b:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103a2e:	c1 e9 02             	shr    $0x2,%ecx
f0103a31:	fd                   	std    
f0103a32:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a34:	eb 09                	jmp    f0103a3f <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103a36:	83 ef 01             	sub    $0x1,%edi
f0103a39:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103a3c:	fd                   	std    
f0103a3d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103a3f:	fc                   	cld    
f0103a40:	eb 1d                	jmp    f0103a5f <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a42:	89 f2                	mov    %esi,%edx
f0103a44:	09 c2                	or     %eax,%edx
f0103a46:	f6 c2 03             	test   $0x3,%dl
f0103a49:	75 0f                	jne    f0103a5a <memmove+0x5f>
f0103a4b:	f6 c1 03             	test   $0x3,%cl
f0103a4e:	75 0a                	jne    f0103a5a <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103a50:	c1 e9 02             	shr    $0x2,%ecx
f0103a53:	89 c7                	mov    %eax,%edi
f0103a55:	fc                   	cld    
f0103a56:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a58:	eb 05                	jmp    f0103a5f <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103a5a:	89 c7                	mov    %eax,%edi
f0103a5c:	fc                   	cld    
f0103a5d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103a5f:	5e                   	pop    %esi
f0103a60:	5f                   	pop    %edi
f0103a61:	5d                   	pop    %ebp
f0103a62:	c3                   	ret    

f0103a63 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103a63:	55                   	push   %ebp
f0103a64:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103a66:	ff 75 10             	pushl  0x10(%ebp)
f0103a69:	ff 75 0c             	pushl  0xc(%ebp)
f0103a6c:	ff 75 08             	pushl  0x8(%ebp)
f0103a6f:	e8 87 ff ff ff       	call   f01039fb <memmove>
}
f0103a74:	c9                   	leave  
f0103a75:	c3                   	ret    

f0103a76 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a76:	55                   	push   %ebp
f0103a77:	89 e5                	mov    %esp,%ebp
f0103a79:	56                   	push   %esi
f0103a7a:	53                   	push   %ebx
f0103a7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a7e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a81:	89 c6                	mov    %eax,%esi
f0103a83:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a86:	eb 1a                	jmp    f0103aa2 <memcmp+0x2c>
		if (*s1 != *s2)
f0103a88:	0f b6 08             	movzbl (%eax),%ecx
f0103a8b:	0f b6 1a             	movzbl (%edx),%ebx
f0103a8e:	38 d9                	cmp    %bl,%cl
f0103a90:	74 0a                	je     f0103a9c <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103a92:	0f b6 c1             	movzbl %cl,%eax
f0103a95:	0f b6 db             	movzbl %bl,%ebx
f0103a98:	29 d8                	sub    %ebx,%eax
f0103a9a:	eb 0f                	jmp    f0103aab <memcmp+0x35>
		s1++, s2++;
f0103a9c:	83 c0 01             	add    $0x1,%eax
f0103a9f:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103aa2:	39 f0                	cmp    %esi,%eax
f0103aa4:	75 e2                	jne    f0103a88 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103aa6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103aab:	5b                   	pop    %ebx
f0103aac:	5e                   	pop    %esi
f0103aad:	5d                   	pop    %ebp
f0103aae:	c3                   	ret    

f0103aaf <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103aaf:	55                   	push   %ebp
f0103ab0:	89 e5                	mov    %esp,%ebp
f0103ab2:	53                   	push   %ebx
f0103ab3:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103ab6:	89 c1                	mov    %eax,%ecx
f0103ab8:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103abb:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103abf:	eb 0a                	jmp    f0103acb <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103ac1:	0f b6 10             	movzbl (%eax),%edx
f0103ac4:	39 da                	cmp    %ebx,%edx
f0103ac6:	74 07                	je     f0103acf <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103ac8:	83 c0 01             	add    $0x1,%eax
f0103acb:	39 c8                	cmp    %ecx,%eax
f0103acd:	72 f2                	jb     f0103ac1 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103acf:	5b                   	pop    %ebx
f0103ad0:	5d                   	pop    %ebp
f0103ad1:	c3                   	ret    

f0103ad2 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103ad2:	55                   	push   %ebp
f0103ad3:	89 e5                	mov    %esp,%ebp
f0103ad5:	57                   	push   %edi
f0103ad6:	56                   	push   %esi
f0103ad7:	53                   	push   %ebx
f0103ad8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103adb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103ade:	eb 03                	jmp    f0103ae3 <strtol+0x11>
		s++;
f0103ae0:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103ae3:	0f b6 01             	movzbl (%ecx),%eax
f0103ae6:	3c 20                	cmp    $0x20,%al
f0103ae8:	74 f6                	je     f0103ae0 <strtol+0xe>
f0103aea:	3c 09                	cmp    $0x9,%al
f0103aec:	74 f2                	je     f0103ae0 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103aee:	3c 2b                	cmp    $0x2b,%al
f0103af0:	75 0a                	jne    f0103afc <strtol+0x2a>
		s++;
f0103af2:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103af5:	bf 00 00 00 00       	mov    $0x0,%edi
f0103afa:	eb 11                	jmp    f0103b0d <strtol+0x3b>
f0103afc:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103b01:	3c 2d                	cmp    $0x2d,%al
f0103b03:	75 08                	jne    f0103b0d <strtol+0x3b>
		s++, neg = 1;
f0103b05:	83 c1 01             	add    $0x1,%ecx
f0103b08:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103b0d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103b13:	75 15                	jne    f0103b2a <strtol+0x58>
f0103b15:	80 39 30             	cmpb   $0x30,(%ecx)
f0103b18:	75 10                	jne    f0103b2a <strtol+0x58>
f0103b1a:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103b1e:	75 7c                	jne    f0103b9c <strtol+0xca>
		s += 2, base = 16;
f0103b20:	83 c1 02             	add    $0x2,%ecx
f0103b23:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103b28:	eb 16                	jmp    f0103b40 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103b2a:	85 db                	test   %ebx,%ebx
f0103b2c:	75 12                	jne    f0103b40 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103b2e:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103b33:	80 39 30             	cmpb   $0x30,(%ecx)
f0103b36:	75 08                	jne    f0103b40 <strtol+0x6e>
		s++, base = 8;
f0103b38:	83 c1 01             	add    $0x1,%ecx
f0103b3b:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103b40:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b45:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103b48:	0f b6 11             	movzbl (%ecx),%edx
f0103b4b:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103b4e:	89 f3                	mov    %esi,%ebx
f0103b50:	80 fb 09             	cmp    $0x9,%bl
f0103b53:	77 08                	ja     f0103b5d <strtol+0x8b>
			dig = *s - '0';
f0103b55:	0f be d2             	movsbl %dl,%edx
f0103b58:	83 ea 30             	sub    $0x30,%edx
f0103b5b:	eb 22                	jmp    f0103b7f <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103b5d:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103b60:	89 f3                	mov    %esi,%ebx
f0103b62:	80 fb 19             	cmp    $0x19,%bl
f0103b65:	77 08                	ja     f0103b6f <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103b67:	0f be d2             	movsbl %dl,%edx
f0103b6a:	83 ea 57             	sub    $0x57,%edx
f0103b6d:	eb 10                	jmp    f0103b7f <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103b6f:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103b72:	89 f3                	mov    %esi,%ebx
f0103b74:	80 fb 19             	cmp    $0x19,%bl
f0103b77:	77 16                	ja     f0103b8f <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103b79:	0f be d2             	movsbl %dl,%edx
f0103b7c:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103b7f:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103b82:	7d 0b                	jge    f0103b8f <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103b84:	83 c1 01             	add    $0x1,%ecx
f0103b87:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103b8b:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103b8d:	eb b9                	jmp    f0103b48 <strtol+0x76>

	if (endptr)
f0103b8f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b93:	74 0d                	je     f0103ba2 <strtol+0xd0>
		*endptr = (char *) s;
f0103b95:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103b98:	89 0e                	mov    %ecx,(%esi)
f0103b9a:	eb 06                	jmp    f0103ba2 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103b9c:	85 db                	test   %ebx,%ebx
f0103b9e:	74 98                	je     f0103b38 <strtol+0x66>
f0103ba0:	eb 9e                	jmp    f0103b40 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103ba2:	89 c2                	mov    %eax,%edx
f0103ba4:	f7 da                	neg    %edx
f0103ba6:	85 ff                	test   %edi,%edi
f0103ba8:	0f 45 c2             	cmovne %edx,%eax
}
f0103bab:	5b                   	pop    %ebx
f0103bac:	5e                   	pop    %esi
f0103bad:	5f                   	pop    %edi
f0103bae:	5d                   	pop    %ebp
f0103baf:	c3                   	ret    

f0103bb0 <__udivdi3>:
f0103bb0:	55                   	push   %ebp
f0103bb1:	57                   	push   %edi
f0103bb2:	56                   	push   %esi
f0103bb3:	83 ec 0c             	sub    $0xc,%esp
f0103bb6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103bba:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103bbe:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103bc2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103bc6:	85 c0                	test   %eax,%eax
f0103bc8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103bcc:	89 ea                	mov    %ebp,%edx
f0103bce:	89 0c 24             	mov    %ecx,(%esp)
f0103bd1:	75 2d                	jne    f0103c00 <__udivdi3+0x50>
f0103bd3:	39 e9                	cmp    %ebp,%ecx
f0103bd5:	77 61                	ja     f0103c38 <__udivdi3+0x88>
f0103bd7:	85 c9                	test   %ecx,%ecx
f0103bd9:	89 ce                	mov    %ecx,%esi
f0103bdb:	75 0b                	jne    f0103be8 <__udivdi3+0x38>
f0103bdd:	b8 01 00 00 00       	mov    $0x1,%eax
f0103be2:	31 d2                	xor    %edx,%edx
f0103be4:	f7 f1                	div    %ecx
f0103be6:	89 c6                	mov    %eax,%esi
f0103be8:	31 d2                	xor    %edx,%edx
f0103bea:	89 e8                	mov    %ebp,%eax
f0103bec:	f7 f6                	div    %esi
f0103bee:	89 c5                	mov    %eax,%ebp
f0103bf0:	89 f8                	mov    %edi,%eax
f0103bf2:	f7 f6                	div    %esi
f0103bf4:	89 ea                	mov    %ebp,%edx
f0103bf6:	83 c4 0c             	add    $0xc,%esp
f0103bf9:	5e                   	pop    %esi
f0103bfa:	5f                   	pop    %edi
f0103bfb:	5d                   	pop    %ebp
f0103bfc:	c3                   	ret    
f0103bfd:	8d 76 00             	lea    0x0(%esi),%esi
f0103c00:	39 e8                	cmp    %ebp,%eax
f0103c02:	77 24                	ja     f0103c28 <__udivdi3+0x78>
f0103c04:	0f bd e8             	bsr    %eax,%ebp
f0103c07:	83 f5 1f             	xor    $0x1f,%ebp
f0103c0a:	75 3c                	jne    f0103c48 <__udivdi3+0x98>
f0103c0c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103c10:	39 34 24             	cmp    %esi,(%esp)
f0103c13:	0f 86 9f 00 00 00    	jbe    f0103cb8 <__udivdi3+0x108>
f0103c19:	39 d0                	cmp    %edx,%eax
f0103c1b:	0f 82 97 00 00 00    	jb     f0103cb8 <__udivdi3+0x108>
f0103c21:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103c28:	31 d2                	xor    %edx,%edx
f0103c2a:	31 c0                	xor    %eax,%eax
f0103c2c:	83 c4 0c             	add    $0xc,%esp
f0103c2f:	5e                   	pop    %esi
f0103c30:	5f                   	pop    %edi
f0103c31:	5d                   	pop    %ebp
f0103c32:	c3                   	ret    
f0103c33:	90                   	nop
f0103c34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c38:	89 f8                	mov    %edi,%eax
f0103c3a:	f7 f1                	div    %ecx
f0103c3c:	31 d2                	xor    %edx,%edx
f0103c3e:	83 c4 0c             	add    $0xc,%esp
f0103c41:	5e                   	pop    %esi
f0103c42:	5f                   	pop    %edi
f0103c43:	5d                   	pop    %ebp
f0103c44:	c3                   	ret    
f0103c45:	8d 76 00             	lea    0x0(%esi),%esi
f0103c48:	89 e9                	mov    %ebp,%ecx
f0103c4a:	8b 3c 24             	mov    (%esp),%edi
f0103c4d:	d3 e0                	shl    %cl,%eax
f0103c4f:	89 c6                	mov    %eax,%esi
f0103c51:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c56:	29 e8                	sub    %ebp,%eax
f0103c58:	89 c1                	mov    %eax,%ecx
f0103c5a:	d3 ef                	shr    %cl,%edi
f0103c5c:	89 e9                	mov    %ebp,%ecx
f0103c5e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103c62:	8b 3c 24             	mov    (%esp),%edi
f0103c65:	09 74 24 08          	or     %esi,0x8(%esp)
f0103c69:	89 d6                	mov    %edx,%esi
f0103c6b:	d3 e7                	shl    %cl,%edi
f0103c6d:	89 c1                	mov    %eax,%ecx
f0103c6f:	89 3c 24             	mov    %edi,(%esp)
f0103c72:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103c76:	d3 ee                	shr    %cl,%esi
f0103c78:	89 e9                	mov    %ebp,%ecx
f0103c7a:	d3 e2                	shl    %cl,%edx
f0103c7c:	89 c1                	mov    %eax,%ecx
f0103c7e:	d3 ef                	shr    %cl,%edi
f0103c80:	09 d7                	or     %edx,%edi
f0103c82:	89 f2                	mov    %esi,%edx
f0103c84:	89 f8                	mov    %edi,%eax
f0103c86:	f7 74 24 08          	divl   0x8(%esp)
f0103c8a:	89 d6                	mov    %edx,%esi
f0103c8c:	89 c7                	mov    %eax,%edi
f0103c8e:	f7 24 24             	mull   (%esp)
f0103c91:	39 d6                	cmp    %edx,%esi
f0103c93:	89 14 24             	mov    %edx,(%esp)
f0103c96:	72 30                	jb     f0103cc8 <__udivdi3+0x118>
f0103c98:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103c9c:	89 e9                	mov    %ebp,%ecx
f0103c9e:	d3 e2                	shl    %cl,%edx
f0103ca0:	39 c2                	cmp    %eax,%edx
f0103ca2:	73 05                	jae    f0103ca9 <__udivdi3+0xf9>
f0103ca4:	3b 34 24             	cmp    (%esp),%esi
f0103ca7:	74 1f                	je     f0103cc8 <__udivdi3+0x118>
f0103ca9:	89 f8                	mov    %edi,%eax
f0103cab:	31 d2                	xor    %edx,%edx
f0103cad:	e9 7a ff ff ff       	jmp    f0103c2c <__udivdi3+0x7c>
f0103cb2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103cb8:	31 d2                	xor    %edx,%edx
f0103cba:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cbf:	e9 68 ff ff ff       	jmp    f0103c2c <__udivdi3+0x7c>
f0103cc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cc8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103ccb:	31 d2                	xor    %edx,%edx
f0103ccd:	83 c4 0c             	add    $0xc,%esp
f0103cd0:	5e                   	pop    %esi
f0103cd1:	5f                   	pop    %edi
f0103cd2:	5d                   	pop    %ebp
f0103cd3:	c3                   	ret    
f0103cd4:	66 90                	xchg   %ax,%ax
f0103cd6:	66 90                	xchg   %ax,%ax
f0103cd8:	66 90                	xchg   %ax,%ax
f0103cda:	66 90                	xchg   %ax,%ax
f0103cdc:	66 90                	xchg   %ax,%ax
f0103cde:	66 90                	xchg   %ax,%ax

f0103ce0 <__umoddi3>:
f0103ce0:	55                   	push   %ebp
f0103ce1:	57                   	push   %edi
f0103ce2:	56                   	push   %esi
f0103ce3:	83 ec 14             	sub    $0x14,%esp
f0103ce6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103cea:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103cee:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103cf2:	89 c7                	mov    %eax,%edi
f0103cf4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cf8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103cfc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103d00:	89 34 24             	mov    %esi,(%esp)
f0103d03:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103d07:	85 c0                	test   %eax,%eax
f0103d09:	89 c2                	mov    %eax,%edx
f0103d0b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d0f:	75 17                	jne    f0103d28 <__umoddi3+0x48>
f0103d11:	39 fe                	cmp    %edi,%esi
f0103d13:	76 4b                	jbe    f0103d60 <__umoddi3+0x80>
f0103d15:	89 c8                	mov    %ecx,%eax
f0103d17:	89 fa                	mov    %edi,%edx
f0103d19:	f7 f6                	div    %esi
f0103d1b:	89 d0                	mov    %edx,%eax
f0103d1d:	31 d2                	xor    %edx,%edx
f0103d1f:	83 c4 14             	add    $0x14,%esp
f0103d22:	5e                   	pop    %esi
f0103d23:	5f                   	pop    %edi
f0103d24:	5d                   	pop    %ebp
f0103d25:	c3                   	ret    
f0103d26:	66 90                	xchg   %ax,%ax
f0103d28:	39 f8                	cmp    %edi,%eax
f0103d2a:	77 54                	ja     f0103d80 <__umoddi3+0xa0>
f0103d2c:	0f bd e8             	bsr    %eax,%ebp
f0103d2f:	83 f5 1f             	xor    $0x1f,%ebp
f0103d32:	75 5c                	jne    f0103d90 <__umoddi3+0xb0>
f0103d34:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103d38:	39 3c 24             	cmp    %edi,(%esp)
f0103d3b:	0f 87 e7 00 00 00    	ja     f0103e28 <__umoddi3+0x148>
f0103d41:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103d45:	29 f1                	sub    %esi,%ecx
f0103d47:	19 c7                	sbb    %eax,%edi
f0103d49:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103d4d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d51:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103d55:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103d59:	83 c4 14             	add    $0x14,%esp
f0103d5c:	5e                   	pop    %esi
f0103d5d:	5f                   	pop    %edi
f0103d5e:	5d                   	pop    %ebp
f0103d5f:	c3                   	ret    
f0103d60:	85 f6                	test   %esi,%esi
f0103d62:	89 f5                	mov    %esi,%ebp
f0103d64:	75 0b                	jne    f0103d71 <__umoddi3+0x91>
f0103d66:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d6b:	31 d2                	xor    %edx,%edx
f0103d6d:	f7 f6                	div    %esi
f0103d6f:	89 c5                	mov    %eax,%ebp
f0103d71:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103d75:	31 d2                	xor    %edx,%edx
f0103d77:	f7 f5                	div    %ebp
f0103d79:	89 c8                	mov    %ecx,%eax
f0103d7b:	f7 f5                	div    %ebp
f0103d7d:	eb 9c                	jmp    f0103d1b <__umoddi3+0x3b>
f0103d7f:	90                   	nop
f0103d80:	89 c8                	mov    %ecx,%eax
f0103d82:	89 fa                	mov    %edi,%edx
f0103d84:	83 c4 14             	add    $0x14,%esp
f0103d87:	5e                   	pop    %esi
f0103d88:	5f                   	pop    %edi
f0103d89:	5d                   	pop    %ebp
f0103d8a:	c3                   	ret    
f0103d8b:	90                   	nop
f0103d8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d90:	8b 04 24             	mov    (%esp),%eax
f0103d93:	be 20 00 00 00       	mov    $0x20,%esi
f0103d98:	89 e9                	mov    %ebp,%ecx
f0103d9a:	29 ee                	sub    %ebp,%esi
f0103d9c:	d3 e2                	shl    %cl,%edx
f0103d9e:	89 f1                	mov    %esi,%ecx
f0103da0:	d3 e8                	shr    %cl,%eax
f0103da2:	89 e9                	mov    %ebp,%ecx
f0103da4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103da8:	8b 04 24             	mov    (%esp),%eax
f0103dab:	09 54 24 04          	or     %edx,0x4(%esp)
f0103daf:	89 fa                	mov    %edi,%edx
f0103db1:	d3 e0                	shl    %cl,%eax
f0103db3:	89 f1                	mov    %esi,%ecx
f0103db5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103db9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103dbd:	d3 ea                	shr    %cl,%edx
f0103dbf:	89 e9                	mov    %ebp,%ecx
f0103dc1:	d3 e7                	shl    %cl,%edi
f0103dc3:	89 f1                	mov    %esi,%ecx
f0103dc5:	d3 e8                	shr    %cl,%eax
f0103dc7:	89 e9                	mov    %ebp,%ecx
f0103dc9:	09 f8                	or     %edi,%eax
f0103dcb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103dcf:	f7 74 24 04          	divl   0x4(%esp)
f0103dd3:	d3 e7                	shl    %cl,%edi
f0103dd5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103dd9:	89 d7                	mov    %edx,%edi
f0103ddb:	f7 64 24 08          	mull   0x8(%esp)
f0103ddf:	39 d7                	cmp    %edx,%edi
f0103de1:	89 c1                	mov    %eax,%ecx
f0103de3:	89 14 24             	mov    %edx,(%esp)
f0103de6:	72 2c                	jb     f0103e14 <__umoddi3+0x134>
f0103de8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103dec:	72 22                	jb     f0103e10 <__umoddi3+0x130>
f0103dee:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103df2:	29 c8                	sub    %ecx,%eax
f0103df4:	19 d7                	sbb    %edx,%edi
f0103df6:	89 e9                	mov    %ebp,%ecx
f0103df8:	89 fa                	mov    %edi,%edx
f0103dfa:	d3 e8                	shr    %cl,%eax
f0103dfc:	89 f1                	mov    %esi,%ecx
f0103dfe:	d3 e2                	shl    %cl,%edx
f0103e00:	89 e9                	mov    %ebp,%ecx
f0103e02:	d3 ef                	shr    %cl,%edi
f0103e04:	09 d0                	or     %edx,%eax
f0103e06:	89 fa                	mov    %edi,%edx
f0103e08:	83 c4 14             	add    $0x14,%esp
f0103e0b:	5e                   	pop    %esi
f0103e0c:	5f                   	pop    %edi
f0103e0d:	5d                   	pop    %ebp
f0103e0e:	c3                   	ret    
f0103e0f:	90                   	nop
f0103e10:	39 d7                	cmp    %edx,%edi
f0103e12:	75 da                	jne    f0103dee <__umoddi3+0x10e>
f0103e14:	8b 14 24             	mov    (%esp),%edx
f0103e17:	89 c1                	mov    %eax,%ecx
f0103e19:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103e1d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103e21:	eb cb                	jmp    f0103dee <__umoddi3+0x10e>
f0103e23:	90                   	nop
f0103e24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e28:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103e2c:	0f 82 0f ff ff ff    	jb     f0103d41 <__umoddi3+0x61>
f0103e32:	e9 1a ff ff ff       	jmp    f0103d51 <__umoddi3+0x71>
