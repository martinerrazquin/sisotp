
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
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 30 11 00       	mov    $0x113000,%eax
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
f0100034:	bc 00 30 11 f0       	mov    $0xf0113000,%esp

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
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f0100046:	b8 50 59 11 f0       	mov    $0xf0115950,%eax
f010004b:	2d 00 53 11 f0       	sub    $0xf0115300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 53 11 f0       	push   $0xf0115300
f0100058:	e8 5b 27 00 00       	call   f01027b8 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 78 06 00 00       	call   f01006da <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 60 2c 10 f0       	push   $0xf0102c60
f010006f:	e8 a0 1c 00 00       	call   f0101d14 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 6c 1b 00 00       	call   f0101be5 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 22 09 00 00       	call   f01009a8 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 40 59 11 f0 00 	cmpl   $0x0,0xf0115940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 59 11 f0    	mov    %esi,0xf0115940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 9c 2c 10 f0       	push   $0xf0102c9c
f01000b5:	e8 5a 1c 00 00       	call   f0101d14 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 2a 1c 00 00       	call   f0101cee <vcprintf>
	cprintf("\n>>>\n");
f01000c4:	c7 04 24 7b 2c 10 f0 	movl   $0xf0102c7b,(%esp)
f01000cb:	e8 44 1c 00 00       	call   f0101d14 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 cb 08 00 00       	call   f01009a8 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 81 2c 10 f0       	push   $0xf0102c81
f01000f7:	e8 18 1c 00 00       	call   f0101d14 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 e6 1b 00 00       	call   f0101cee <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 1b 38 10 f0 	movl   $0xf010381b,(%esp)
f010010f:	e8 00 1c 00 00       	call   f0101d14 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	89 c2                	mov    %eax,%edx
f0100121:	ec                   	in     (%dx),%al
	return data;
}
f0100122:	5d                   	pop    %ebp
f0100123:	c3                   	ret    

f0100124 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0100124:	55                   	push   %ebp
f0100125:	89 e5                	mov    %esp,%ebp
f0100127:	89 c1                	mov    %eax,%ecx
f0100129:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010012b:	89 ca                	mov    %ecx,%edx
f010012d:	ee                   	out    %al,(%dx)
}
f010012e:	5d                   	pop    %ebp
f010012f:	c3                   	ret    

f0100130 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100130:	55                   	push   %ebp
f0100131:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f0100133:	b8 84 00 00 00       	mov    $0x84,%eax
f0100138:	e8 df ff ff ff       	call   f010011c <inb>
	inb(0x84);
f010013d:	b8 84 00 00 00       	mov    $0x84,%eax
f0100142:	e8 d5 ff ff ff       	call   f010011c <inb>
	inb(0x84);
f0100147:	b8 84 00 00 00       	mov    $0x84,%eax
f010014c:	e8 cb ff ff ff       	call   f010011c <inb>
	inb(0x84);
f0100151:	b8 84 00 00 00       	mov    $0x84,%eax
f0100156:	e8 c1 ff ff ff       	call   f010011c <inb>
}
f010015b:	5d                   	pop    %ebp
f010015c:	c3                   	ret    

f010015d <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010015d:	55                   	push   %ebp
f010015e:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100160:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100165:	e8 b2 ff ff ff       	call   f010011c <inb>
f010016a:	a8 01                	test   $0x1,%al
f010016c:	74 0f                	je     f010017d <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f010016e:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100173:	e8 a4 ff ff ff       	call   f010011c <inb>
f0100178:	0f b6 c0             	movzbl %al,%eax
f010017b:	eb 05                	jmp    f0100182 <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010017d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100182:	5d                   	pop    %ebp
f0100183:	c3                   	ret    

f0100184 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f0100184:	55                   	push   %ebp
f0100185:	89 e5                	mov    %esp,%ebp
f0100187:	56                   	push   %esi
f0100188:	53                   	push   %ebx
f0100189:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f010018b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100190:	eb 08                	jmp    f010019a <serial_putc+0x16>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100192:	e8 99 ff ff ff       	call   f0100130 <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100197:	83 c3 01             	add    $0x1,%ebx
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010019a:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f010019f:	e8 78 ff ff ff       	call   f010011c <inb>
f01001a4:	a8 20                	test   $0x20,%al
f01001a6:	75 08                	jne    f01001b0 <serial_putc+0x2c>
f01001a8:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01001ae:	7e e2                	jle    f0100192 <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001b0:	89 f0                	mov    %esi,%eax
f01001b2:	0f b6 d0             	movzbl %al,%edx
f01001b5:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001ba:	e8 65 ff ff ff       	call   f0100124 <outb>
}
f01001bf:	5b                   	pop    %ebx
f01001c0:	5e                   	pop    %esi
f01001c1:	5d                   	pop    %ebp
f01001c2:	c3                   	ret    

f01001c3 <serial_init>:

static void
serial_init(void)
{
f01001c3:	55                   	push   %ebp
f01001c4:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f01001c6:	ba 00 00 00 00       	mov    $0x0,%edx
f01001cb:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01001d0:	e8 4f ff ff ff       	call   f0100124 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f01001d5:	ba 80 00 00 00       	mov    $0x80,%edx
f01001da:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01001df:	e8 40 ff ff ff       	call   f0100124 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f01001e4:	ba 0c 00 00 00       	mov    $0xc,%edx
f01001e9:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001ee:	e8 31 ff ff ff       	call   f0100124 <outb>
	outb(COM1+COM_DLM, 0);
f01001f3:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f8:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f01001fd:	e8 22 ff ff ff       	call   f0100124 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f0100202:	ba 03 00 00 00       	mov    $0x3,%edx
f0100207:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010020c:	e8 13 ff ff ff       	call   f0100124 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f0100211:	ba 00 00 00 00       	mov    $0x0,%edx
f0100216:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f010021b:	e8 04 ff ff ff       	call   f0100124 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f0100220:	ba 01 00 00 00       	mov    $0x1,%edx
f0100225:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f010022a:	e8 f5 fe ff ff       	call   f0100124 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010022f:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100234:	e8 e3 fe ff ff       	call   f010011c <inb>
f0100239:	3c ff                	cmp    $0xff,%al
f010023b:	0f 95 05 34 55 11 f0 	setne  0xf0115534
	(void) inb(COM1+COM_IIR);
f0100242:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100247:	e8 d0 fe ff ff       	call   f010011c <inb>
	(void) inb(COM1+COM_RX);
f010024c:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100251:	e8 c6 fe ff ff       	call   f010011c <inb>

}
f0100256:	5d                   	pop    %ebp
f0100257:	c3                   	ret    

f0100258 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f0100258:	55                   	push   %ebp
f0100259:	89 e5                	mov    %esp,%ebp
f010025b:	56                   	push   %esi
f010025c:	53                   	push   %ebx
f010025d:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010025f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100264:	eb 08                	jmp    f010026e <lpt_putc+0x16>
		delay();
f0100266:	e8 c5 fe ff ff       	call   f0100130 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010026b:	83 c3 01             	add    $0x1,%ebx
f010026e:	b8 79 03 00 00       	mov    $0x379,%eax
f0100273:	e8 a4 fe ff ff       	call   f010011c <inb>
f0100278:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010027e:	7f 04                	jg     f0100284 <lpt_putc+0x2c>
f0100280:	84 c0                	test   %al,%al
f0100282:	79 e2                	jns    f0100266 <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f0100284:	89 f0                	mov    %esi,%eax
f0100286:	0f b6 d0             	movzbl %al,%edx
f0100289:	b8 78 03 00 00       	mov    $0x378,%eax
f010028e:	e8 91 fe ff ff       	call   f0100124 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f0100293:	ba 0d 00 00 00       	mov    $0xd,%edx
f0100298:	b8 7a 03 00 00       	mov    $0x37a,%eax
f010029d:	e8 82 fe ff ff       	call   f0100124 <outb>
	outb(0x378+2, 0x08);
f01002a2:	ba 08 00 00 00       	mov    $0x8,%edx
f01002a7:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002ac:	e8 73 fe ff ff       	call   f0100124 <outb>
}
f01002b1:	5b                   	pop    %ebx
f01002b2:	5e                   	pop    %esi
f01002b3:	5d                   	pop    %ebp
f01002b4:	c3                   	ret    

f01002b5 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002b5:	55                   	push   %ebp
f01002b6:	89 e5                	mov    %esp,%ebp
f01002b8:	57                   	push   %edi
f01002b9:	56                   	push   %esi
f01002ba:	53                   	push   %ebx
f01002bb:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002be:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002c5:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002cc:	5a a5 
	if (*cp != 0xA55A) {
f01002ce:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002d5:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002d9:	74 13                	je     f01002ee <cga_init+0x39>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002db:	c7 05 30 55 11 f0 b4 	movl   $0x3b4,0xf0115530
f01002e2:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01002e5:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
f01002ec:	eb 18                	jmp    f0100306 <cga_init+0x51>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01002ee:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01002f5:	c7 05 30 55 11 f0 d4 	movl   $0x3d4,0xf0115530
f01002fc:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01002ff:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100306:	8b 35 30 55 11 f0    	mov    0xf0115530,%esi
f010030c:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100311:	89 f0                	mov    %esi,%eax
f0100313:	e8 0c fe ff ff       	call   f0100124 <outb>
	pos = inb(addr_6845 + 1) << 8;
f0100318:	8d 7e 01             	lea    0x1(%esi),%edi
f010031b:	89 f8                	mov    %edi,%eax
f010031d:	e8 fa fd ff ff       	call   f010011c <inb>
f0100322:	0f b6 d8             	movzbl %al,%ebx
f0100325:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f0100328:	ba 0f 00 00 00       	mov    $0xf,%edx
f010032d:	89 f0                	mov    %esi,%eax
f010032f:	e8 f0 fd ff ff       	call   f0100124 <outb>
	pos |= inb(addr_6845 + 1);
f0100334:	89 f8                	mov    %edi,%eax
f0100336:	e8 e1 fd ff ff       	call   f010011c <inb>

	crt_buf = (uint16_t*) cp;
f010033b:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f010033e:	89 0d 2c 55 11 f0    	mov    %ecx,0xf011552c
	crt_pos = pos;
f0100344:	0f b6 c0             	movzbl %al,%eax
f0100347:	09 c3                	or     %eax,%ebx
f0100349:	66 89 1d 28 55 11 f0 	mov    %bx,0xf0115528
}
f0100350:	83 c4 04             	add    $0x4,%esp
f0100353:	5b                   	pop    %ebx
f0100354:	5e                   	pop    %esi
f0100355:	5f                   	pop    %edi
f0100356:	5d                   	pop    %ebp
f0100357:	c3                   	ret    

f0100358 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100358:	55                   	push   %ebp
f0100359:	89 e5                	mov    %esp,%ebp
f010035b:	53                   	push   %ebx
f010035c:	83 ec 04             	sub    $0x4,%esp
f010035f:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100361:	eb 2b                	jmp    f010038e <cons_intr+0x36>
		if (c == 0)
f0100363:	85 c0                	test   %eax,%eax
f0100365:	74 27                	je     f010038e <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100367:	8b 0d 24 55 11 f0    	mov    0xf0115524,%ecx
f010036d:	8d 51 01             	lea    0x1(%ecx),%edx
f0100370:	89 15 24 55 11 f0    	mov    %edx,0xf0115524
f0100376:	88 81 20 53 11 f0    	mov    %al,-0xfeeace0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010037c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100382:	75 0a                	jne    f010038e <cons_intr+0x36>
			cons.wpos = 0;
f0100384:	c7 05 24 55 11 f0 00 	movl   $0x0,0xf0115524
f010038b:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010038e:	ff d3                	call   *%ebx
f0100390:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100393:	75 ce                	jne    f0100363 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100395:	83 c4 04             	add    $0x4,%esp
f0100398:	5b                   	pop    %ebx
f0100399:	5d                   	pop    %ebp
f010039a:	c3                   	ret    

f010039b <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010039b:	55                   	push   %ebp
f010039c:	89 e5                	mov    %esp,%ebp
f010039e:	53                   	push   %ebx
f010039f:	83 ec 04             	sub    $0x4,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f01003a2:	b8 64 00 00 00       	mov    $0x64,%eax
f01003a7:	e8 70 fd ff ff       	call   f010011c <inb>
	if ((stat & KBS_DIB) == 0)
f01003ac:	a8 01                	test   $0x1,%al
f01003ae:	0f 84 fe 00 00 00    	je     f01004b2 <kbd_proc_data+0x117>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003b4:	a8 20                	test   $0x20,%al
f01003b6:	0f 85 fd 00 00 00    	jne    f01004b9 <kbd_proc_data+0x11e>
		return -1;

	data = inb(KBDATAP);
f01003bc:	b8 60 00 00 00       	mov    $0x60,%eax
f01003c1:	e8 56 fd ff ff       	call   f010011c <inb>

	if (data == 0xE0) {
f01003c6:	3c e0                	cmp    $0xe0,%al
f01003c8:	75 11                	jne    f01003db <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f01003ca:	83 0d 00 53 11 f0 40 	orl    $0x40,0xf0115300
		return 0;
f01003d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01003d6:	e9 e7 00 00 00       	jmp    f01004c2 <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f01003db:	84 c0                	test   %al,%al
f01003dd:	79 38                	jns    f0100417 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003df:	8b 0d 00 53 11 f0    	mov    0xf0115300,%ecx
f01003e5:	89 cb                	mov    %ecx,%ebx
f01003e7:	83 e3 40             	and    $0x40,%ebx
f01003ea:	89 c2                	mov    %eax,%edx
f01003ec:	83 e2 7f             	and    $0x7f,%edx
f01003ef:	85 db                	test   %ebx,%ebx
f01003f1:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01003f4:	0f b6 c0             	movzbl %al,%eax
f01003f7:	0f b6 80 20 2e 10 f0 	movzbl -0xfefd1e0(%eax),%eax
f01003fe:	83 c8 40             	or     $0x40,%eax
f0100401:	0f b6 c0             	movzbl %al,%eax
f0100404:	f7 d0                	not    %eax
f0100406:	21 c8                	and    %ecx,%eax
f0100408:	a3 00 53 11 f0       	mov    %eax,0xf0115300
		return 0;
f010040d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100412:	e9 ab 00 00 00       	jmp    f01004c2 <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100417:	8b 15 00 53 11 f0    	mov    0xf0115300,%edx
f010041d:	f6 c2 40             	test   $0x40,%dl
f0100420:	74 0c                	je     f010042e <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100422:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100425:	83 e2 bf             	and    $0xffffffbf,%edx
f0100428:	89 15 00 53 11 f0    	mov    %edx,0xf0115300
	}

	shift |= shiftcode[data];
f010042e:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f0100431:	0f b6 90 20 2e 10 f0 	movzbl -0xfefd1e0(%eax),%edx
f0100438:	0b 15 00 53 11 f0    	or     0xf0115300,%edx
f010043e:	0f b6 88 20 2d 10 f0 	movzbl -0xfefd2e0(%eax),%ecx
f0100445:	31 ca                	xor    %ecx,%edx
f0100447:	89 15 00 53 11 f0    	mov    %edx,0xf0115300

	c = charcode[shift & (CTL | SHIFT)][data];
f010044d:	89 d1                	mov    %edx,%ecx
f010044f:	83 e1 03             	and    $0x3,%ecx
f0100452:	8b 0c 8d 00 2d 10 f0 	mov    -0xfefd300(,%ecx,4),%ecx
f0100459:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010045d:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100460:	f6 c2 08             	test   $0x8,%dl
f0100463:	74 1b                	je     f0100480 <kbd_proc_data+0xe5>
		if ('a' <= c && c <= 'z')
f0100465:	89 d8                	mov    %ebx,%eax
f0100467:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010046a:	83 f9 19             	cmp    $0x19,%ecx
f010046d:	77 05                	ja     f0100474 <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f010046f:	83 eb 20             	sub    $0x20,%ebx
f0100472:	eb 0c                	jmp    f0100480 <kbd_proc_data+0xe5>
		else if ('A' <= c && c <= 'Z')
f0100474:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100477:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010047a:	83 f8 19             	cmp    $0x19,%eax
f010047d:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100480:	f7 d2                	not    %edx
f0100482:	f6 c2 06             	test   $0x6,%dl
f0100485:	75 39                	jne    f01004c0 <kbd_proc_data+0x125>
f0100487:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010048d:	75 31                	jne    f01004c0 <kbd_proc_data+0x125>
		cprintf("Rebooting!\n");
f010048f:	83 ec 0c             	sub    $0xc,%esp
f0100492:	68 bc 2c 10 f0       	push   $0xf0102cbc
f0100497:	e8 78 18 00 00       	call   f0101d14 <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f010049c:	ba 03 00 00 00       	mov    $0x3,%edx
f01004a1:	b8 92 00 00 00       	mov    $0x92,%eax
f01004a6:	e8 79 fc ff ff       	call   f0100124 <outb>
f01004ab:	83 c4 10             	add    $0x10,%esp
	}

	return c;
f01004ae:	89 d8                	mov    %ebx,%eax
f01004b0:	eb 10                	jmp    f01004c2 <kbd_proc_data+0x127>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004b7:	eb 09                	jmp    f01004c2 <kbd_proc_data+0x127>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004be:	eb 02                	jmp    f01004c2 <kbd_proc_data+0x127>
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01004c0:	89 d8                	mov    %ebx,%eax
}
f01004c2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01004c5:	c9                   	leave  
f01004c6:	c3                   	ret    

f01004c7 <cga_putc>:



static void
cga_putc(int c)
{
f01004c7:	55                   	push   %ebp
f01004c8:	89 e5                	mov    %esp,%ebp
f01004ca:	57                   	push   %edi
f01004cb:	56                   	push   %esi
f01004cc:	53                   	push   %ebx
f01004cd:	83 ec 0c             	sub    $0xc,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004d0:	89 c1                	mov    %eax,%ecx
f01004d2:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004d8:	89 c2                	mov    %eax,%edx
f01004da:	80 ce 07             	or     $0x7,%dh
f01004dd:	85 c9                	test   %ecx,%ecx
f01004df:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f01004e2:	0f b6 d0             	movzbl %al,%edx
f01004e5:	83 fa 09             	cmp    $0x9,%edx
f01004e8:	74 72                	je     f010055c <cga_putc+0x95>
f01004ea:	83 fa 09             	cmp    $0x9,%edx
f01004ed:	7f 0a                	jg     f01004f9 <cga_putc+0x32>
f01004ef:	83 fa 08             	cmp    $0x8,%edx
f01004f2:	74 14                	je     f0100508 <cga_putc+0x41>
f01004f4:	e9 97 00 00 00       	jmp    f0100590 <cga_putc+0xc9>
f01004f9:	83 fa 0a             	cmp    $0xa,%edx
f01004fc:	74 38                	je     f0100536 <cga_putc+0x6f>
f01004fe:	83 fa 0d             	cmp    $0xd,%edx
f0100501:	74 3b                	je     f010053e <cga_putc+0x77>
f0100503:	e9 88 00 00 00       	jmp    f0100590 <cga_putc+0xc9>
	case '\b':
		if (crt_pos > 0) {
f0100508:	0f b7 15 28 55 11 f0 	movzwl 0xf0115528,%edx
f010050f:	66 85 d2             	test   %dx,%dx
f0100512:	0f 84 e4 00 00 00    	je     f01005fc <cga_putc+0x135>
			crt_pos--;
f0100518:	83 ea 01             	sub    $0x1,%edx
f010051b:	66 89 15 28 55 11 f0 	mov    %dx,0xf0115528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100522:	0f b7 d2             	movzwl %dx,%edx
f0100525:	b0 00                	mov    $0x0,%al
f0100527:	83 c8 20             	or     $0x20,%eax
f010052a:	8b 0d 2c 55 11 f0    	mov    0xf011552c,%ecx
f0100530:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100534:	eb 78                	jmp    f01005ae <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100536:	66 83 05 28 55 11 f0 	addw   $0x50,0xf0115528
f010053d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010053e:	0f b7 05 28 55 11 f0 	movzwl 0xf0115528,%eax
f0100545:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010054b:	c1 e8 16             	shr    $0x16,%eax
f010054e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100551:	c1 e0 04             	shl    $0x4,%eax
f0100554:	66 a3 28 55 11 f0    	mov    %ax,0xf0115528
		break;
f010055a:	eb 52                	jmp    f01005ae <cga_putc+0xe7>
	case '\t':
		cons_putc(' ');
f010055c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100561:	e8 da 00 00 00       	call   f0100640 <cons_putc>
		cons_putc(' ');
f0100566:	b8 20 00 00 00       	mov    $0x20,%eax
f010056b:	e8 d0 00 00 00       	call   f0100640 <cons_putc>
		cons_putc(' ');
f0100570:	b8 20 00 00 00       	mov    $0x20,%eax
f0100575:	e8 c6 00 00 00       	call   f0100640 <cons_putc>
		cons_putc(' ');
f010057a:	b8 20 00 00 00       	mov    $0x20,%eax
f010057f:	e8 bc 00 00 00       	call   f0100640 <cons_putc>
		cons_putc(' ');
f0100584:	b8 20 00 00 00       	mov    $0x20,%eax
f0100589:	e8 b2 00 00 00       	call   f0100640 <cons_putc>
		break;
f010058e:	eb 1e                	jmp    f01005ae <cga_putc+0xe7>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100590:	0f b7 15 28 55 11 f0 	movzwl 0xf0115528,%edx
f0100597:	8d 4a 01             	lea    0x1(%edx),%ecx
f010059a:	66 89 0d 28 55 11 f0 	mov    %cx,0xf0115528
f01005a1:	0f b7 d2             	movzwl %dx,%edx
f01005a4:	8b 0d 2c 55 11 f0    	mov    0xf011552c,%ecx
f01005aa:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005ae:	66 81 3d 28 55 11 f0 	cmpw   $0x7cf,0xf0115528
f01005b5:	cf 07 
f01005b7:	76 43                	jbe    f01005fc <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005b9:	a1 2c 55 11 f0       	mov    0xf011552c,%eax
f01005be:	83 ec 04             	sub    $0x4,%esp
f01005c1:	68 00 0f 00 00       	push   $0xf00
f01005c6:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005cc:	52                   	push   %edx
f01005cd:	50                   	push   %eax
f01005ce:	e8 33 22 00 00       	call   f0102806 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005d3:	8b 15 2c 55 11 f0    	mov    0xf011552c,%edx
f01005d9:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005df:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005e5:	83 c4 10             	add    $0x10,%esp
f01005e8:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005ed:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005f0:	39 d0                	cmp    %edx,%eax
f01005f2:	75 f4                	jne    f01005e8 <cga_putc+0x121>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005f4:	66 83 2d 28 55 11 f0 	subw   $0x50,0xf0115528
f01005fb:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005fc:	8b 3d 30 55 11 f0    	mov    0xf0115530,%edi
f0100602:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100607:	89 f8                	mov    %edi,%eax
f0100609:	e8 16 fb ff ff       	call   f0100124 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f010060e:	0f b7 1d 28 55 11 f0 	movzwl 0xf0115528,%ebx
f0100615:	8d 77 01             	lea    0x1(%edi),%esi
f0100618:	0f b6 d7             	movzbl %bh,%edx
f010061b:	89 f0                	mov    %esi,%eax
f010061d:	e8 02 fb ff ff       	call   f0100124 <outb>
	outb(addr_6845, 15);
f0100622:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100627:	89 f8                	mov    %edi,%eax
f0100629:	e8 f6 fa ff ff       	call   f0100124 <outb>
	outb(addr_6845 + 1, crt_pos);
f010062e:	0f b6 d3             	movzbl %bl,%edx
f0100631:	89 f0                	mov    %esi,%eax
f0100633:	e8 ec fa ff ff       	call   f0100124 <outb>
}
f0100638:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010063b:	5b                   	pop    %ebx
f010063c:	5e                   	pop    %esi
f010063d:	5f                   	pop    %edi
f010063e:	5d                   	pop    %ebp
f010063f:	c3                   	ret    

f0100640 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	53                   	push   %ebx
f0100644:	83 ec 04             	sub    $0x4,%esp
f0100647:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100649:	e8 36 fb ff ff       	call   f0100184 <serial_putc>
	lpt_putc(c);
f010064e:	89 d8                	mov    %ebx,%eax
f0100650:	e8 03 fc ff ff       	call   f0100258 <lpt_putc>
	cga_putc(c);
f0100655:	89 d8                	mov    %ebx,%eax
f0100657:	e8 6b fe ff ff       	call   f01004c7 <cga_putc>
}
f010065c:	83 c4 04             	add    $0x4,%esp
f010065f:	5b                   	pop    %ebx
f0100660:	5d                   	pop    %ebp
f0100661:	c3                   	ret    

f0100662 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100662:	80 3d 34 55 11 f0 00 	cmpb   $0x0,0xf0115534
f0100669:	74 11                	je     f010067c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100671:	b8 5d 01 10 f0       	mov    $0xf010015d,%eax
f0100676:	e8 dd fc ff ff       	call   f0100358 <cons_intr>
}
f010067b:	c9                   	leave  
f010067c:	f3 c3                	repz ret 

f010067e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010067e:	55                   	push   %ebp
f010067f:	89 e5                	mov    %esp,%ebp
f0100681:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100684:	b8 9b 03 10 f0       	mov    $0xf010039b,%eax
f0100689:	e8 ca fc ff ff       	call   f0100358 <cons_intr>
}
f010068e:	c9                   	leave  
f010068f:	c3                   	ret    

f0100690 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100696:	e8 c7 ff ff ff       	call   f0100662 <serial_intr>
	kbd_intr();
f010069b:	e8 de ff ff ff       	call   f010067e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01006a0:	a1 20 55 11 f0       	mov    0xf0115520,%eax
f01006a5:	3b 05 24 55 11 f0    	cmp    0xf0115524,%eax
f01006ab:	74 26                	je     f01006d3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006ad:	8d 50 01             	lea    0x1(%eax),%edx
f01006b0:	89 15 20 55 11 f0    	mov    %edx,0xf0115520
f01006b6:	0f b6 88 20 53 11 f0 	movzbl -0xfeeace0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01006bd:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01006bf:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01006c5:	75 11                	jne    f01006d8 <cons_getc+0x48>
			cons.rpos = 0;
f01006c7:	c7 05 20 55 11 f0 00 	movl   $0x0,0xf0115520
f01006ce:	00 00 00 
f01006d1:	eb 05                	jmp    f01006d8 <cons_getc+0x48>
		return c;
	}
	return 0;
f01006d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01006d8:	c9                   	leave  
f01006d9:	c3                   	ret    

f01006da <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01006da:	55                   	push   %ebp
f01006db:	89 e5                	mov    %esp,%ebp
f01006dd:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01006e0:	e8 d0 fb ff ff       	call   f01002b5 <cga_init>
	kbd_init();
	serial_init();
f01006e5:	e8 d9 fa ff ff       	call   f01001c3 <serial_init>

	if (!serial_exists)
f01006ea:	80 3d 34 55 11 f0 00 	cmpb   $0x0,0xf0115534
f01006f1:	75 10                	jne    f0100703 <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f01006f3:	83 ec 0c             	sub    $0xc,%esp
f01006f6:	68 c8 2c 10 f0       	push   $0xf0102cc8
f01006fb:	e8 14 16 00 00       	call   f0101d14 <cprintf>
f0100700:	83 c4 10             	add    $0x10,%esp
}
f0100703:	c9                   	leave  
f0100704:	c3                   	ret    

f0100705 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100705:	55                   	push   %ebp
f0100706:	89 e5                	mov    %esp,%ebp
f0100708:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010070b:	8b 45 08             	mov    0x8(%ebp),%eax
f010070e:	e8 2d ff ff ff       	call   f0100640 <cons_putc>
}
f0100713:	c9                   	leave  
f0100714:	c3                   	ret    

f0100715 <getchar>:

int
getchar(void)
{
f0100715:	55                   	push   %ebp
f0100716:	89 e5                	mov    %esp,%ebp
f0100718:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010071b:	e8 70 ff ff ff       	call   f0100690 <cons_getc>
f0100720:	85 c0                	test   %eax,%eax
f0100722:	74 f7                	je     f010071b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100724:	c9                   	leave  
f0100725:	c3                   	ret    

f0100726 <iscons>:

int
iscons(int fdnum)
{
f0100726:	55                   	push   %ebp
f0100727:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100729:	b8 01 00 00 00       	mov    $0x1,%eax
f010072e:	5d                   	pop    %ebp
f010072f:	c3                   	ret    

f0100730 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100730:	55                   	push   %ebp
f0100731:	89 e5                	mov    %esp,%ebp
f0100733:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100736:	68 20 2f 10 f0       	push   $0xf0102f20
f010073b:	68 3e 2f 10 f0       	push   $0xf0102f3e
f0100740:	68 43 2f 10 f0       	push   $0xf0102f43
f0100745:	e8 ca 15 00 00       	call   f0101d14 <cprintf>
f010074a:	83 c4 0c             	add    $0xc,%esp
f010074d:	68 e0 2f 10 f0       	push   $0xf0102fe0
f0100752:	68 4c 2f 10 f0       	push   $0xf0102f4c
f0100757:	68 43 2f 10 f0       	push   $0xf0102f43
f010075c:	e8 b3 15 00 00       	call   f0101d14 <cprintf>
f0100761:	83 c4 0c             	add    $0xc,%esp
f0100764:	68 55 2f 10 f0       	push   $0xf0102f55
f0100769:	68 69 2f 10 f0       	push   $0xf0102f69
f010076e:	68 43 2f 10 f0       	push   $0xf0102f43
f0100773:	e8 9c 15 00 00       	call   f0101d14 <cprintf>
	return 0;
}
f0100778:	b8 00 00 00 00       	mov    $0x0,%eax
f010077d:	c9                   	leave  
f010077e:	c3                   	ret    

f010077f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010077f:	55                   	push   %ebp
f0100780:	89 e5                	mov    %esp,%ebp
f0100782:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100785:	68 73 2f 10 f0       	push   $0xf0102f73
f010078a:	e8 85 15 00 00       	call   f0101d14 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010078f:	83 c4 08             	add    $0x8,%esp
f0100792:	68 0c 00 10 00       	push   $0x10000c
f0100797:	68 08 30 10 f0       	push   $0xf0103008
f010079c:	e8 73 15 00 00       	call   f0101d14 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	68 0c 00 10 00       	push   $0x10000c
f01007a9:	68 0c 00 10 f0       	push   $0xf010000c
f01007ae:	68 30 30 10 f0       	push   $0xf0103030
f01007b3:	e8 5c 15 00 00       	call   f0101d14 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007b8:	83 c4 0c             	add    $0xc,%esp
f01007bb:	68 41 2c 10 00       	push   $0x102c41
f01007c0:	68 41 2c 10 f0       	push   $0xf0102c41
f01007c5:	68 54 30 10 f0       	push   $0xf0103054
f01007ca:	e8 45 15 00 00       	call   f0101d14 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cf:	83 c4 0c             	add    $0xc,%esp
f01007d2:	68 00 53 11 00       	push   $0x115300
f01007d7:	68 00 53 11 f0       	push   $0xf0115300
f01007dc:	68 78 30 10 f0       	push   $0xf0103078
f01007e1:	e8 2e 15 00 00       	call   f0101d14 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e6:	83 c4 0c             	add    $0xc,%esp
f01007e9:	68 50 59 11 00       	push   $0x115950
f01007ee:	68 50 59 11 f0       	push   $0xf0115950
f01007f3:	68 9c 30 10 f0       	push   $0xf010309c
f01007f8:	e8 17 15 00 00       	call   f0101d14 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007fd:	b8 4f 5d 11 f0       	mov    $0xf0115d4f,%eax
f0100802:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100807:	83 c4 08             	add    $0x8,%esp
f010080a:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010080f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100815:	85 c0                	test   %eax,%eax
f0100817:	0f 48 c2             	cmovs  %edx,%eax
f010081a:	c1 f8 0a             	sar    $0xa,%eax
f010081d:	50                   	push   %eax
f010081e:	68 c0 30 10 f0       	push   $0xf01030c0
f0100823:	e8 ec 14 00 00       	call   f0101d14 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100828:	b8 00 00 00 00       	mov    $0x0,%eax
f010082d:	c9                   	leave  
f010082e:	c3                   	ret    

f010082f <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010082f:	55                   	push   %ebp
f0100830:	89 e5                	mov    %esp,%ebp
f0100832:	57                   	push   %edi
f0100833:	56                   	push   %esi
f0100834:	53                   	push   %ebx
f0100835:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100838:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0x0){
	uint32_t eip=*(uint32_t *)(ebp+4);
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f010083a:	8d 7d d0             	lea    -0x30(%ebp),%edi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f010083d:	eb 4a                	jmp    f0100889 <mon_backtrace+0x5a>
	uint32_t eip=*(uint32_t *)(ebp+4);
f010083f:	8b 73 04             	mov    0x4(%ebx),%esi
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
f0100842:	ff 73 18             	pushl  0x18(%ebx)
f0100845:	ff 73 14             	pushl  0x14(%ebx)
f0100848:	ff 73 10             	pushl  0x10(%ebx)
f010084b:	ff 73 0c             	pushl  0xc(%ebx)
f010084e:	ff 73 08             	pushl  0x8(%ebx)
f0100851:	56                   	push   %esi
f0100852:	53                   	push   %ebx
f0100853:	68 ec 30 10 f0       	push   $0xf01030ec
f0100858:	e8 b7 14 00 00       	call   f0101d14 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f010085d:	83 c4 18             	add    $0x18,%esp
f0100860:	57                   	push   %edi
f0100861:	56                   	push   %esi
f0100862:	e8 b7 15 00 00       	call   f0101e1e <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100867:	83 c4 08             	add    $0x8,%esp
f010086a:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010086d:	56                   	push   %esi
f010086e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100871:	ff 75 dc             	pushl  -0x24(%ebp)
f0100874:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100877:	ff 75 d0             	pushl  -0x30(%ebp)
f010087a:	68 8c 2f 10 f0       	push   $0xf0102f8c
f010087f:	e8 90 14 00 00       	call   f0101d14 <cprintf>
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
f0100884:	8b 1b                	mov    (%ebx),%ebx
f0100886:	83 c4 20             	add    $0x20,%esp
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100889:	85 db                	test   %ebx,%ebx
f010088b:	75 b2                	jne    f010083f <mon_backtrace+0x10>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
	}
	return 0;
}
f010088d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100892:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100895:	5b                   	pop    %ebx
f0100896:	5e                   	pop    %esi
f0100897:	5f                   	pop    %edi
f0100898:	5d                   	pop    %ebp
f0100899:	c3                   	ret    

f010089a <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f010089a:	55                   	push   %ebp
f010089b:	89 e5                	mov    %esp,%ebp
f010089d:	57                   	push   %edi
f010089e:	56                   	push   %esi
f010089f:	53                   	push   %ebx
f01008a0:	83 ec 5c             	sub    $0x5c,%esp
f01008a3:	89 c3                	mov    %eax,%ebx
f01008a5:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008a8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008af:	be 00 00 00 00       	mov    $0x0,%esi
f01008b4:	eb 0a                	jmp    f01008c0 <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008b6:	c6 03 00             	movb   $0x0,(%ebx)
f01008b9:	89 f7                	mov    %esi,%edi
f01008bb:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008be:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008c0:	0f b6 03             	movzbl (%ebx),%eax
f01008c3:	84 c0                	test   %al,%al
f01008c5:	74 6d                	je     f0100934 <runcmd+0x9a>
f01008c7:	83 ec 08             	sub    $0x8,%esp
f01008ca:	0f be c0             	movsbl %al,%eax
f01008cd:	50                   	push   %eax
f01008ce:	68 a3 2f 10 f0       	push   $0xf0102fa3
f01008d3:	e8 a3 1e 00 00       	call   f010277b <strchr>
f01008d8:	83 c4 10             	add    $0x10,%esp
f01008db:	85 c0                	test   %eax,%eax
f01008dd:	75 d7                	jne    f01008b6 <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f01008df:	0f b6 03             	movzbl (%ebx),%eax
f01008e2:	84 c0                	test   %al,%al
f01008e4:	74 4e                	je     f0100934 <runcmd+0x9a>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008e6:	83 fe 0f             	cmp    $0xf,%esi
f01008e9:	75 1c                	jne    f0100907 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008eb:	83 ec 08             	sub    $0x8,%esp
f01008ee:	6a 10                	push   $0x10
f01008f0:	68 a8 2f 10 f0       	push   $0xf0102fa8
f01008f5:	e8 1a 14 00 00       	call   f0101d14 <cprintf>
			return 0;
f01008fa:	83 c4 10             	add    $0x10,%esp
f01008fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100902:	e9 99 00 00 00       	jmp    f01009a0 <runcmd+0x106>
		}
		argv[argc++] = buf;
f0100907:	8d 7e 01             	lea    0x1(%esi),%edi
f010090a:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010090e:	eb 0a                	jmp    f010091a <runcmd+0x80>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100910:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100913:	0f b6 03             	movzbl (%ebx),%eax
f0100916:	84 c0                	test   %al,%al
f0100918:	74 a4                	je     f01008be <runcmd+0x24>
f010091a:	83 ec 08             	sub    $0x8,%esp
f010091d:	0f be c0             	movsbl %al,%eax
f0100920:	50                   	push   %eax
f0100921:	68 a3 2f 10 f0       	push   $0xf0102fa3
f0100926:	e8 50 1e 00 00       	call   f010277b <strchr>
f010092b:	83 c4 10             	add    $0x10,%esp
f010092e:	85 c0                	test   %eax,%eax
f0100930:	74 de                	je     f0100910 <runcmd+0x76>
f0100932:	eb 8a                	jmp    f01008be <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f0100934:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010093b:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f010093c:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f0100941:	85 f6                	test   %esi,%esi
f0100943:	74 5b                	je     f01009a0 <runcmd+0x106>
f0100945:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010094a:	83 ec 08             	sub    $0x8,%esp
f010094d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100950:	ff 34 85 80 31 10 f0 	pushl  -0xfefce80(,%eax,4)
f0100957:	ff 75 a8             	pushl  -0x58(%ebp)
f010095a:	e8 be 1d 00 00       	call   f010271d <strcmp>
f010095f:	83 c4 10             	add    $0x10,%esp
f0100962:	85 c0                	test   %eax,%eax
f0100964:	75 1a                	jne    f0100980 <runcmd+0xe6>
			return commands[i].func(argc, argv, tf);
f0100966:	83 ec 04             	sub    $0x4,%esp
f0100969:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010096c:	ff 75 a4             	pushl  -0x5c(%ebp)
f010096f:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100972:	52                   	push   %edx
f0100973:	56                   	push   %esi
f0100974:	ff 14 85 88 31 10 f0 	call   *-0xfefce78(,%eax,4)
f010097b:	83 c4 10             	add    $0x10,%esp
f010097e:	eb 20                	jmp    f01009a0 <runcmd+0x106>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100980:	83 c3 01             	add    $0x1,%ebx
f0100983:	83 fb 03             	cmp    $0x3,%ebx
f0100986:	75 c2                	jne    f010094a <runcmd+0xb0>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100988:	83 ec 08             	sub    $0x8,%esp
f010098b:	ff 75 a8             	pushl  -0x58(%ebp)
f010098e:	68 c5 2f 10 f0       	push   $0xf0102fc5
f0100993:	e8 7c 13 00 00       	call   f0101d14 <cprintf>
	return 0;
f0100998:	83 c4 10             	add    $0x10,%esp
f010099b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01009a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009a3:	5b                   	pop    %ebx
f01009a4:	5e                   	pop    %esi
f01009a5:	5f                   	pop    %edi
f01009a6:	5d                   	pop    %ebp
f01009a7:	c3                   	ret    

f01009a8 <monitor>:

void
monitor(struct Trapframe *tf)
{
f01009a8:	55                   	push   %ebp
f01009a9:	89 e5                	mov    %esp,%ebp
f01009ab:	53                   	push   %ebx
f01009ac:	83 ec 10             	sub    $0x10,%esp
f01009af:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009b2:	68 20 31 10 f0       	push   $0xf0103120
f01009b7:	e8 58 13 00 00       	call   f0101d14 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009bc:	c7 04 24 44 31 10 f0 	movl   $0xf0103144,(%esp)
f01009c3:	e8 4c 13 00 00       	call   f0101d14 <cprintf>
f01009c8:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009cb:	83 ec 0c             	sub    $0xc,%esp
f01009ce:	68 db 2f 10 f0       	push   $0xf0102fdb
f01009d3:	e8 89 1b 00 00       	call   f0102561 <readline>
		if (buf != NULL)
f01009d8:	83 c4 10             	add    $0x10,%esp
f01009db:	85 c0                	test   %eax,%eax
f01009dd:	74 ec                	je     f01009cb <monitor+0x23>
			if (runcmd(buf, tf) < 0)
f01009df:	89 da                	mov    %ebx,%edx
f01009e1:	e8 b4 fe ff ff       	call   f010089a <runcmd>
f01009e6:	85 c0                	test   %eax,%eax
f01009e8:	79 e1                	jns    f01009cb <monitor+0x23>
				break;
	}
}
f01009ea:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009ed:	c9                   	leave  
f01009ee:	c3                   	ret    

f01009ef <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f01009ef:	55                   	push   %ebp
f01009f0:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01009f2:	0f 01 38             	invlpg (%eax)
}
f01009f5:	5d                   	pop    %ebp
f01009f6:	c3                   	ret    

f01009f7 <lcr0>:
	asm volatile("ltr %0" : : "r" (sel));
}

static inline void
lcr0(uint32_t val)
{
f01009f7:	55                   	push   %ebp
f01009f8:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01009fa:	0f 22 c0             	mov    %eax,%cr0
}
f01009fd:	5d                   	pop    %ebp
f01009fe:	c3                   	ret    

f01009ff <rcr0>:

static inline uint32_t
rcr0(void)
{
f01009ff:	55                   	push   %ebp
f0100a00:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0100a02:	0f 20 c0             	mov    %cr0,%eax
	return val;
}
f0100a05:	5d                   	pop    %ebp
f0100a06:	c3                   	ret    

f0100a07 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0100a07:	55                   	push   %ebp
f0100a08:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100a0a:	0f 22 d8             	mov    %eax,%cr3
}
f0100a0d:	5d                   	pop    %ebp
f0100a0e:	c3                   	ret    

f0100a0f <page2pa>:

void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0100a0f:	55                   	push   %ebp
f0100a10:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0100a12:	2b 05 4c 59 11 f0    	sub    0xf011594c,%eax
f0100a18:	c1 f8 03             	sar    $0x3,%eax
f0100a1b:	c1 e0 0c             	shl    $0xc,%eax
}
f0100a1e:	5d                   	pop    %ebp
f0100a1f:	c3                   	ret    

f0100a20 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a20:	55                   	push   %ebp
f0100a21:	89 e5                	mov    %esp,%ebp
f0100a23:	56                   	push   %esi
f0100a24:	53                   	push   %ebx
f0100a25:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a27:	83 ec 0c             	sub    $0xc,%esp
f0100a2a:	50                   	push   %eax
f0100a2b:	e8 6a 12 00 00       	call   f0101c9a <mc146818_read>
f0100a30:	89 c6                	mov    %eax,%esi
f0100a32:	83 c3 01             	add    $0x1,%ebx
f0100a35:	89 1c 24             	mov    %ebx,(%esp)
f0100a38:	e8 5d 12 00 00       	call   f0101c9a <mc146818_read>
f0100a3d:	c1 e0 08             	shl    $0x8,%eax
f0100a40:	09 f0                	or     %esi,%eax
}
f0100a42:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a45:	5b                   	pop    %ebx
f0100a46:	5e                   	pop    %esi
f0100a47:	5d                   	pop    %ebp
f0100a48:	c3                   	ret    

f0100a49 <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f0100a49:	55                   	push   %ebp
f0100a4a:	89 e5                	mov    %esp,%ebp
f0100a4c:	56                   	push   %esi
f0100a4d:	53                   	push   %ebx
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100a4e:	b8 15 00 00 00       	mov    $0x15,%eax
f0100a53:	e8 c8 ff ff ff       	call   f0100a20 <nvram_read>
f0100a58:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100a5a:	b8 17 00 00 00       	mov    $0x17,%eax
f0100a5f:	e8 bc ff ff ff       	call   f0100a20 <nvram_read>
f0100a64:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100a66:	b8 34 00 00 00       	mov    $0x34,%eax
f0100a6b:	e8 b0 ff ff ff       	call   f0100a20 <nvram_read>
f0100a70:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100a73:	85 c0                	test   %eax,%eax
f0100a75:	74 07                	je     f0100a7e <i386_detect_memory+0x35>
		totalmem = 16 * 1024 + ext16mem;
f0100a77:	05 00 40 00 00       	add    $0x4000,%eax
f0100a7c:	eb 0b                	jmp    f0100a89 <i386_detect_memory+0x40>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100a7e:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100a84:	85 f6                	test   %esi,%esi
f0100a86:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100a89:	89 c2                	mov    %eax,%edx
f0100a8b:	c1 ea 02             	shr    $0x2,%edx
f0100a8e:	89 15 44 59 11 f0    	mov    %edx,0xf0115944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a94:	89 c2                	mov    %eax,%edx
f0100a96:	29 da                	sub    %ebx,%edx
f0100a98:	52                   	push   %edx
f0100a99:	53                   	push   %ebx
f0100a9a:	50                   	push   %eax
f0100a9b:	68 a4 31 10 f0       	push   $0xf01031a4
f0100aa0:	e8 6f 12 00 00       	call   f0101d14 <cprintf>
		totalmem, basemem, totalmem - basemem);
}
f0100aa5:	83 c4 10             	add    $0x10,%esp
f0100aa8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100aab:	5b                   	pop    %ebx
f0100aac:	5e                   	pop    %esi
f0100aad:	5d                   	pop    %ebp
f0100aae:	c3                   	ret    

f0100aaf <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100aaf:	83 3d 38 55 11 f0 00 	cmpl   $0x0,0xf0115538
f0100ab6:	75 11                	jne    f0100ac9 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ab8:	ba 4f 69 11 f0       	mov    $0xf011694f,%edx
f0100abd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ac3:	89 15 38 55 11 f0    	mov    %edx,0xf0115538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100ac9:	85 c0                	test   %eax,%eax
f0100acb:	75 06                	jne    f0100ad3 <boot_alloc+0x24>
f0100acd:	a1 38 55 11 f0       	mov    0xf0115538,%eax
f0100ad2:	c3                   	ret    
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100ad3:	8b 0d 38 55 11 f0    	mov    0xf0115538,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100ad9:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100adf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ae5:	01 ca                	add    %ecx,%edx
f0100ae7:	89 15 38 55 11 f0    	mov    %edx,0xf0115538
	if ((uint32_t)(nextfree-KERNBASE)>npages*PGSIZE) panic("not enough memory\n");//como chequeo esto? Uso nextfree vs npages*PGSIZE?
f0100aed:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100af3:	a1 44 59 11 f0       	mov    0xf0115944,%eax
f0100af8:	c1 e0 0c             	shl    $0xc,%eax
f0100afb:	39 c2                	cmp    %eax,%edx
f0100afd:	76 17                	jbe    f0100b16 <boot_alloc+0x67>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100aff:	55                   	push   %ebp
f0100b00:	89 e5                	mov    %esp,%ebp
f0100b02:	83 ec 0c             	sub    $0xc,%esp
	// LAB 2: Your code here.
	if (n==0) return nextfree;
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	if ((uint32_t)(nextfree-KERNBASE)>npages*PGSIZE) panic("not enough memory\n");//como chequeo esto? Uso nextfree vs npages*PGSIZE?
f0100b05:	68 10 37 10 f0       	push   $0xf0103710
f0100b0a:	6a 6d                	push   $0x6d
f0100b0c:	68 23 37 10 f0       	push   $0xf0103723
f0100b11:	e8 75 f5 ff ff       	call   f010008b <_panic>
	return (void*) result;
f0100b16:	89 c8                	mov    %ecx,%eax
}
f0100b18:	c3                   	ret    

f0100b19 <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100b19:	55                   	push   %ebp
f0100b1a:	89 e5                	mov    %esp,%ebp
f0100b1c:	53                   	push   %ebx
f0100b1d:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0100b20:	89 cb                	mov    %ecx,%ebx
f0100b22:	c1 eb 0c             	shr    $0xc,%ebx
f0100b25:	3b 1d 44 59 11 f0    	cmp    0xf0115944,%ebx
f0100b2b:	72 0d                	jb     f0100b3a <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b2d:	51                   	push   %ecx
f0100b2e:	68 e0 31 10 f0       	push   $0xf01031e0
f0100b33:	52                   	push   %edx
f0100b34:	50                   	push   %eax
f0100b35:	e8 51 f5 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0100b3a:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100b40:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b43:	c9                   	leave  
f0100b44:	c3                   	ret    

f0100b45 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100b45:	55                   	push   %ebp
f0100b46:	89 e5                	mov    %esp,%ebp
f0100b48:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100b4b:	e8 bf fe ff ff       	call   f0100a0f <page2pa>
f0100b50:	89 c1                	mov    %eax,%ecx
f0100b52:	ba 52 00 00 00       	mov    $0x52,%edx
f0100b57:	b8 2f 37 10 f0       	mov    $0xf010372f,%eax
f0100b5c:	e8 b8 ff ff ff       	call   f0100b19 <_kaddr>
}
f0100b61:	c9                   	leave  
f0100b62:	c3                   	ret    

f0100b63 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100b63:	89 d1                	mov    %edx,%ecx
f0100b65:	c1 e9 16             	shr    $0x16,%ecx
f0100b68:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
f0100b6b:	f6 c1 01             	test   $0x1,%cl
f0100b6e:	74 57                	je     f0100bc7 <check_va2pa+0x64>
		return ~0;
	if (*pgdir & PTE_PS)
f0100b70:	f6 c1 80             	test   $0x80,%cl
f0100b73:	74 10                	je     f0100b85 <check_va2pa+0x22>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
f0100b75:	89 d0                	mov    %edx,%eax
f0100b77:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100b7c:	81 e1 00 00 c0 ff    	and    $0xffc00000,%ecx
f0100b82:	09 c8                	or     %ecx,%eax
f0100b84:	c3                   	ret    
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b85:	55                   	push   %ebp
f0100b86:	89 e5                	mov    %esp,%ebp
f0100b88:	53                   	push   %ebx
f0100b89:	83 ec 04             	sub    $0x4,%esp
f0100b8c:	89 d3                	mov    %edx,%ebx
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	if (*pgdir & PTE_PS)
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b8e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b94:	ba 9c 02 00 00       	mov    $0x29c,%edx
f0100b99:	b8 23 37 10 f0       	mov    $0xf0103723,%eax
f0100b9e:	e8 76 ff ff ff       	call   f0100b19 <_kaddr>
	if (!(p[PTX(va)] & PTE_P))
f0100ba3:	c1 eb 0c             	shr    $0xc,%ebx
f0100ba6:	89 da                	mov    %ebx,%edx
f0100ba8:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100bae:	8b 04 90             	mov    (%eax,%edx,4),%eax
f0100bb1:	89 c2                	mov    %eax,%edx
f0100bb3:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100bb6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bbb:	85 d2                	test   %edx,%edx
f0100bbd:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
f0100bc2:	0f 44 c1             	cmove  %ecx,%eax
f0100bc5:	eb 06                	jmp    f0100bcd <check_va2pa+0x6a>
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100bc7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bcc:	c3                   	ret    
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100bcd:	83 c4 04             	add    $0x4,%esp
f0100bd0:	5b                   	pop    %ebx
f0100bd1:	5d                   	pop    %ebp
f0100bd2:	c3                   	ret    

f0100bd3 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bd3:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100bd9:	77 13                	ja     f0100bee <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100bdb:	55                   	push   %ebp
f0100bdc:	89 e5                	mov    %esp,%ebp
f0100bde:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100be1:	51                   	push   %ecx
f0100be2:	68 04 32 10 f0       	push   $0xf0103204
f0100be7:	52                   	push   %edx
f0100be8:	50                   	push   %eax
f0100be9:	e8 9d f4 ff ff       	call   f010008b <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100bee:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100bf4:	c3                   	ret    

f0100bf5 <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100bf5:	55                   	push   %ebp
f0100bf6:	89 e5                	mov    %esp,%ebp
f0100bf8:	57                   	push   %edi
f0100bf9:	56                   	push   %esi
f0100bfa:	53                   	push   %ebx
f0100bfb:	83 ec 1c             	sub    $0x1c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100bfe:	8b 1d 48 59 11 f0    	mov    0xf0115948,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100c04:	a1 44 59 11 f0       	mov    0xf0115944,%eax
f0100c09:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c0c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100c13:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c18:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c1b:	a1 4c 59 11 f0       	mov    0xf011594c,%eax
f0100c20:	89 45 e0             	mov    %eax,-0x20(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100c23:	be 00 00 00 00       	mov    $0x0,%esi
f0100c28:	eb 46                	jmp    f0100c70 <check_kern_pgdir+0x7b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c2a:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0100c30:	89 d8                	mov    %ebx,%eax
f0100c32:	e8 2c ff ff ff       	call   f0100b63 <check_va2pa>
f0100c37:	89 c7                	mov    %eax,%edi
f0100c39:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100c3c:	ba 6d 02 00 00       	mov    $0x26d,%edx
f0100c41:	b8 23 37 10 f0       	mov    $0xf0103723,%eax
f0100c46:	e8 88 ff ff ff       	call   f0100bd3 <_paddr>
f0100c4b:	01 f0                	add    %esi,%eax
f0100c4d:	39 c7                	cmp    %eax,%edi
f0100c4f:	74 19                	je     f0100c6a <check_kern_pgdir+0x75>
f0100c51:	68 28 32 10 f0       	push   $0xf0103228
f0100c56:	68 3d 37 10 f0       	push   $0xf010373d
f0100c5b:	68 6d 02 00 00       	push   $0x26d
f0100c60:	68 23 37 10 f0       	push   $0xf0103723
f0100c65:	e8 21 f4 ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100c6a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100c70:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100c73:	72 b5                	jb     f0100c2a <check_kern_pgdir+0x35>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100c75:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100c78:	c1 e7 0c             	shl    $0xc,%edi
f0100c7b:	be 00 00 00 00       	mov    $0x0,%esi
f0100c80:	eb 30                	jmp    f0100cb2 <check_kern_pgdir+0xbd>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100c82:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0100c88:	89 d8                	mov    %ebx,%eax
f0100c8a:	e8 d4 fe ff ff       	call   f0100b63 <check_va2pa>
f0100c8f:	39 c6                	cmp    %eax,%esi
f0100c91:	74 19                	je     f0100cac <check_kern_pgdir+0xb7>
f0100c93:	68 5c 32 10 f0       	push   $0xf010325c
f0100c98:	68 3d 37 10 f0       	push   $0xf010373d
f0100c9d:	68 72 02 00 00       	push   $0x272
f0100ca2:	68 23 37 10 f0       	push   $0xf0103723
f0100ca7:	e8 df f3 ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100cac:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100cb2:	39 fe                	cmp    %edi,%esi
f0100cb4:	72 cc                	jb     f0100c82 <check_kern_pgdir+0x8d>
f0100cb6:	be 00 00 00 00       	mov    $0x0,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0100cbb:	8d 96 00 80 ff ef    	lea    -0x10008000(%esi),%edx
f0100cc1:	89 d8                	mov    %ebx,%eax
f0100cc3:	e8 9b fe ff ff       	call   f0100b63 <check_va2pa>
f0100cc8:	89 c7                	mov    %eax,%edi
f0100cca:	b9 00 b0 10 f0       	mov    $0xf010b000,%ecx
f0100ccf:	ba 76 02 00 00       	mov    $0x276,%edx
f0100cd4:	b8 23 37 10 f0       	mov    $0xf0103723,%eax
f0100cd9:	e8 f5 fe ff ff       	call   f0100bd3 <_paddr>
f0100cde:	01 f0                	add    %esi,%eax
f0100ce0:	39 c7                	cmp    %eax,%edi
f0100ce2:	74 19                	je     f0100cfd <check_kern_pgdir+0x108>
f0100ce4:	68 84 32 10 f0       	push   $0xf0103284
f0100ce9:	68 3d 37 10 f0       	push   $0xf010373d
f0100cee:	68 76 02 00 00       	push   $0x276
f0100cf3:	68 23 37 10 f0       	push   $0xf0103723
f0100cf8:	e8 8e f3 ff ff       	call   f010008b <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100cfd:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d03:	81 fe 00 80 00 00    	cmp    $0x8000,%esi
f0100d09:	75 b0                	jne    f0100cbb <check_kern_pgdir+0xc6>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0100d0b:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0100d10:	89 d8                	mov    %ebx,%eax
f0100d12:	e8 4c fe ff ff       	call   f0100b63 <check_va2pa>
f0100d17:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100d1a:	74 51                	je     f0100d6d <check_kern_pgdir+0x178>
f0100d1c:	68 cc 32 10 f0       	push   $0xf01032cc
f0100d21:	68 3d 37 10 f0       	push   $0xf010373d
f0100d26:	68 77 02 00 00       	push   $0x277
f0100d2b:	68 23 37 10 f0       	push   $0xf0103723
f0100d30:	e8 56 f3 ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100d35:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0100d3a:	72 36                	jb     f0100d72 <check_kern_pgdir+0x17d>
f0100d3c:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0100d41:	76 07                	jbe    f0100d4a <check_kern_pgdir+0x155>
f0100d43:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100d48:	75 28                	jne    f0100d72 <check_kern_pgdir+0x17d>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0100d4a:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0100d4e:	0f 85 83 00 00 00    	jne    f0100dd7 <check_kern_pgdir+0x1e2>
f0100d54:	68 52 37 10 f0       	push   $0xf0103752
f0100d59:	68 3d 37 10 f0       	push   $0xf010373d
f0100d5e:	68 7f 02 00 00       	push   $0x27f
f0100d63:	68 23 37 10 f0       	push   $0xf0103723
f0100d68:	e8 1e f3 ff ff       	call   f010008b <_panic>
f0100d6d:	b8 00 00 00 00       	mov    $0x0,%eax
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100d72:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100d77:	76 3f                	jbe    f0100db8 <check_kern_pgdir+0x1c3>
				assert(pgdir[i] & PTE_P);
f0100d79:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0100d7c:	f6 c2 01             	test   $0x1,%dl
f0100d7f:	75 19                	jne    f0100d9a <check_kern_pgdir+0x1a5>
f0100d81:	68 52 37 10 f0       	push   $0xf0103752
f0100d86:	68 3d 37 10 f0       	push   $0xf010373d
f0100d8b:	68 83 02 00 00       	push   $0x283
f0100d90:	68 23 37 10 f0       	push   $0xf0103723
f0100d95:	e8 f1 f2 ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0100d9a:	f6 c2 02             	test   $0x2,%dl
f0100d9d:	75 38                	jne    f0100dd7 <check_kern_pgdir+0x1e2>
f0100d9f:	68 63 37 10 f0       	push   $0xf0103763
f0100da4:	68 3d 37 10 f0       	push   $0xf010373d
f0100da9:	68 84 02 00 00       	push   $0x284
f0100dae:	68 23 37 10 f0       	push   $0xf0103723
f0100db3:	e8 d3 f2 ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0100db8:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100dbc:	74 19                	je     f0100dd7 <check_kern_pgdir+0x1e2>
f0100dbe:	68 74 37 10 f0       	push   $0xf0103774
f0100dc3:	68 3d 37 10 f0       	push   $0xf010373d
f0100dc8:	68 86 02 00 00       	push   $0x286
f0100dcd:	68 23 37 10 f0       	push   $0xf0103723
f0100dd2:	e8 b4 f2 ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0100dd7:	83 c0 01             	add    $0x1,%eax
f0100dda:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0100ddf:	0f 86 50 ff ff ff    	jbe    f0100d35 <check_kern_pgdir+0x140>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0100de5:	83 ec 0c             	sub    $0xc,%esp
f0100de8:	68 fc 32 10 f0       	push   $0xf01032fc
f0100ded:	e8 22 0f 00 00       	call   f0101d14 <cprintf>
}
f0100df2:	83 c4 10             	add    $0x10,%esp
f0100df5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100df8:	5b                   	pop    %ebx
f0100df9:	5e                   	pop    %esi
f0100dfa:	5f                   	pop    %edi
f0100dfb:	5d                   	pop    %ebp
f0100dfc:	c3                   	ret    

f0100dfd <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100dfd:	55                   	push   %ebp
f0100dfe:	89 e5                	mov    %esp,%ebp
f0100e00:	57                   	push   %edi
f0100e01:	56                   	push   %esi
f0100e02:	53                   	push   %ebx
f0100e03:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e06:	84 c0                	test   %al,%al
f0100e08:	0f 85 35 02 00 00    	jne    f0101043 <check_page_free_list+0x246>
f0100e0e:	e9 43 02 00 00       	jmp    f0101056 <check_page_free_list+0x259>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100e13:	83 ec 04             	sub    $0x4,%esp
f0100e16:	68 1c 33 10 f0       	push   $0xf010331c
f0100e1b:	68 dd 01 00 00       	push   $0x1dd
f0100e20:	68 23 37 10 f0       	push   $0xf0103723
f0100e25:	e8 61 f2 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e2a:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100e2d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e30:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100e33:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e36:	89 d8                	mov    %ebx,%eax
f0100e38:	e8 d2 fb ff ff       	call   f0100a0f <page2pa>
f0100e3d:	c1 e8 16             	shr    $0x16,%eax
f0100e40:	85 c0                	test   %eax,%eax
f0100e42:	0f 95 c0             	setne  %al
f0100e45:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100e48:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f0100e4c:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100e4e:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e52:	8b 1b                	mov    (%ebx),%ebx
f0100e54:	85 db                	test   %ebx,%ebx
f0100e56:	75 de                	jne    f0100e36 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100e58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e5b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e61:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e64:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e67:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100e69:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e6c:	a3 3c 55 11 f0       	mov    %eax,0xf011553c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e71:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e76:	8b 1d 3c 55 11 f0    	mov    0xf011553c,%ebx
f0100e7c:	eb 2d                	jmp    f0100eab <check_page_free_list+0xae>
		if (PDX(page2pa(pp)) < pdx_limit)
f0100e7e:	89 d8                	mov    %ebx,%eax
f0100e80:	e8 8a fb ff ff       	call   f0100a0f <page2pa>
f0100e85:	c1 e8 16             	shr    $0x16,%eax
f0100e88:	39 f0                	cmp    %esi,%eax
f0100e8a:	73 1d                	jae    f0100ea9 <check_page_free_list+0xac>
			memset(page2kva(pp), 0x97, 128);
f0100e8c:	89 d8                	mov    %ebx,%eax
f0100e8e:	e8 b2 fc ff ff       	call   f0100b45 <page2kva>
f0100e93:	83 ec 04             	sub    $0x4,%esp
f0100e96:	68 80 00 00 00       	push   $0x80
f0100e9b:	68 97 00 00 00       	push   $0x97
f0100ea0:	50                   	push   %eax
f0100ea1:	e8 12 19 00 00       	call   f01027b8 <memset>
f0100ea6:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ea9:	8b 1b                	mov    (%ebx),%ebx
f0100eab:	85 db                	test   %ebx,%ebx
f0100ead:	75 cf                	jne    f0100e7e <check_page_free_list+0x81>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100eaf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eb4:	e8 f6 fb ff ff       	call   f0100aaf <boot_alloc>
f0100eb9:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ebc:	8b 1d 3c 55 11 f0    	mov    0xf011553c,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ec2:	8b 35 4c 59 11 f0    	mov    0xf011594c,%esi
		assert(pp < pages + npages);
f0100ec8:	a1 44 59 11 f0       	mov    0xf0115944,%eax
f0100ecd:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0100ed0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ed3:	89 75 d0             	mov    %esi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ed6:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100edd:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ee2:	e9 18 01 00 00       	jmp    f0100fff <check_page_free_list+0x202>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ee7:	39 f3                	cmp    %esi,%ebx
f0100ee9:	73 19                	jae    f0100f04 <check_page_free_list+0x107>
f0100eeb:	68 82 37 10 f0       	push   $0xf0103782
f0100ef0:	68 3d 37 10 f0       	push   $0xf010373d
f0100ef5:	68 f7 01 00 00       	push   $0x1f7
f0100efa:	68 23 37 10 f0       	push   $0xf0103723
f0100eff:	e8 87 f1 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100f04:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100f07:	72 19                	jb     f0100f22 <check_page_free_list+0x125>
f0100f09:	68 8e 37 10 f0       	push   $0xf010378e
f0100f0e:	68 3d 37 10 f0       	push   $0xf010373d
f0100f13:	68 f8 01 00 00       	push   $0x1f8
f0100f18:	68 23 37 10 f0       	push   $0xf0103723
f0100f1d:	e8 69 f1 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f22:	89 d8                	mov    %ebx,%eax
f0100f24:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100f27:	a8 07                	test   $0x7,%al
f0100f29:	74 19                	je     f0100f44 <check_page_free_list+0x147>
f0100f2b:	68 40 33 10 f0       	push   $0xf0103340
f0100f30:	68 3d 37 10 f0       	push   $0xf010373d
f0100f35:	68 f9 01 00 00       	push   $0x1f9
f0100f3a:	68 23 37 10 f0       	push   $0xf0103723
f0100f3f:	e8 47 f1 ff ff       	call   f010008b <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100f44:	89 d8                	mov    %ebx,%eax
f0100f46:	e8 c4 fa ff ff       	call   f0100a0f <page2pa>
f0100f4b:	85 c0                	test   %eax,%eax
f0100f4d:	75 19                	jne    f0100f68 <check_page_free_list+0x16b>
f0100f4f:	68 a2 37 10 f0       	push   $0xf01037a2
f0100f54:	68 3d 37 10 f0       	push   $0xf010373d
f0100f59:	68 fc 01 00 00       	push   $0x1fc
f0100f5e:	68 23 37 10 f0       	push   $0xf0103723
f0100f63:	e8 23 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f68:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f6d:	75 19                	jne    f0100f88 <check_page_free_list+0x18b>
f0100f6f:	68 b3 37 10 f0       	push   $0xf01037b3
f0100f74:	68 3d 37 10 f0       	push   $0xf010373d
f0100f79:	68 fd 01 00 00       	push   $0x1fd
f0100f7e:	68 23 37 10 f0       	push   $0xf0103723
f0100f83:	e8 03 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f88:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f8d:	75 19                	jne    f0100fa8 <check_page_free_list+0x1ab>
f0100f8f:	68 74 33 10 f0       	push   $0xf0103374
f0100f94:	68 3d 37 10 f0       	push   $0xf010373d
f0100f99:	68 fe 01 00 00       	push   $0x1fe
f0100f9e:	68 23 37 10 f0       	push   $0xf0103723
f0100fa3:	e8 e3 f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100fa8:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100fad:	75 19                	jne    f0100fc8 <check_page_free_list+0x1cb>
f0100faf:	68 cc 37 10 f0       	push   $0xf01037cc
f0100fb4:	68 3d 37 10 f0       	push   $0xf010373d
f0100fb9:	68 ff 01 00 00       	push   $0x1ff
f0100fbe:	68 23 37 10 f0       	push   $0xf0103723
f0100fc3:	e8 c3 f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fc8:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100fcd:	76 25                	jbe    f0100ff4 <check_page_free_list+0x1f7>
f0100fcf:	89 d8                	mov    %ebx,%eax
f0100fd1:	e8 6f fb ff ff       	call   f0100b45 <page2kva>
f0100fd6:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100fd9:	76 1e                	jbe    f0100ff9 <check_page_free_list+0x1fc>
f0100fdb:	68 98 33 10 f0       	push   $0xf0103398
f0100fe0:	68 3d 37 10 f0       	push   $0xf010373d
f0100fe5:	68 00 02 00 00       	push   $0x200
f0100fea:	68 23 37 10 f0       	push   $0xf0103723
f0100fef:	e8 97 f0 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100ff4:	83 c7 01             	add    $0x1,%edi
f0100ff7:	eb 04                	jmp    f0100ffd <check_page_free_list+0x200>
		else
			++nfree_extmem;
f0100ff9:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ffd:	8b 1b                	mov    (%ebx),%ebx
f0100fff:	85 db                	test   %ebx,%ebx
f0101001:	0f 85 e0 fe ff ff    	jne    f0100ee7 <check_page_free_list+0xea>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0101007:	85 ff                	test   %edi,%edi
f0101009:	7f 19                	jg     f0101024 <check_page_free_list+0x227>
f010100b:	68 e6 37 10 f0       	push   $0xf01037e6
f0101010:	68 3d 37 10 f0       	push   $0xf010373d
f0101015:	68 08 02 00 00       	push   $0x208
f010101a:	68 23 37 10 f0       	push   $0xf0103723
f010101f:	e8 67 f0 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0101024:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0101028:	7f 43                	jg     f010106d <check_page_free_list+0x270>
f010102a:	68 f8 37 10 f0       	push   $0xf01037f8
f010102f:	68 3d 37 10 f0       	push   $0xf010373d
f0101034:	68 09 02 00 00       	push   $0x209
f0101039:	68 23 37 10 f0       	push   $0xf0103723
f010103e:	e8 48 f0 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101043:	8b 1d 3c 55 11 f0    	mov    0xf011553c,%ebx
f0101049:	85 db                	test   %ebx,%ebx
f010104b:	0f 85 d9 fd ff ff    	jne    f0100e2a <check_page_free_list+0x2d>
f0101051:	e9 bd fd ff ff       	jmp    f0100e13 <check_page_free_list+0x16>
f0101056:	83 3d 3c 55 11 f0 00 	cmpl   $0x0,0xf011553c
f010105d:	0f 84 b0 fd ff ff    	je     f0100e13 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101063:	be 00 04 00 00       	mov    $0x400,%esi
f0101068:	e9 09 fe ff ff       	jmp    f0100e76 <check_page_free_list+0x79>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f010106d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101070:	5b                   	pop    %ebx
f0101071:	5e                   	pop    %esi
f0101072:	5f                   	pop    %edi
f0101073:	5d                   	pop    %ebp
f0101074:	c3                   	ret    

f0101075 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0101075:	55                   	push   %ebp
f0101076:	89 e5                	mov    %esp,%ebp
f0101078:	56                   	push   %esi
f0101079:	53                   	push   %ebx
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}*/ //FOR ORIGINAL
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f010107a:	b8 00 00 00 00       	mov    $0x0,%eax
f010107f:	e8 2b fa ff ff       	call   f0100aaf <boot_alloc>
f0101084:	89 c1                	mov    %eax,%ecx
f0101086:	ba 10 01 00 00       	mov    $0x110,%edx
f010108b:	b8 23 37 10 f0       	mov    $0xf0103723,%eax
f0101090:	e8 3e fb ff ff       	call   f0100bd3 <_paddr>
f0101095:	c1 e8 0c             	shr    $0xc,%eax
f0101098:	8b 35 3c 55 11 f0    	mov    0xf011553c,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f010109e:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010a3:	ba 01 00 00 00       	mov    $0x1,%edx
f01010a8:	eb 33                	jmp    f01010dd <page_init+0x68>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f01010aa:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f01010b0:	76 04                	jbe    f01010b6 <page_init+0x41>
f01010b2:	39 c2                	cmp    %eax,%edx
f01010b4:	72 24                	jb     f01010da <page_init+0x65>
		pages[i].pp_ref = 0;
f01010b6:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01010bd:	89 cb                	mov    %ecx,%ebx
f01010bf:	03 1d 4c 59 11 f0    	add    0xf011594c,%ebx
f01010c5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f01010cb:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f01010cd:	89 ce                	mov    %ecx,%esi
f01010cf:	03 35 4c 59 11 f0    	add    0xf011594c,%esi
f01010d5:	b9 01 00 00 00       	mov    $0x1,%ecx
		page_free_list = &pages[i];
	}*/ //FOR ORIGINAL
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f01010da:	83 c2 01             	add    $0x1,%edx
f01010dd:	3b 15 44 59 11 f0    	cmp    0xf0115944,%edx
f01010e3:	72 c5                	jb     f01010aa <page_init+0x35>
f01010e5:	84 c9                	test   %cl,%cl
f01010e7:	74 06                	je     f01010ef <page_init+0x7a>
f01010e9:	89 35 3c 55 11 f0    	mov    %esi,0xf011553c
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01010ef:	5b                   	pop    %ebx
f01010f0:	5e                   	pop    %esi
f01010f1:	5d                   	pop    %ebp
f01010f2:	c3                   	ret    

f01010f3 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f01010f3:	55                   	push   %ebp
f01010f4:	89 e5                	mov    %esp,%ebp
f01010f6:	53                   	push   %ebx
f01010f7:	83 ec 04             	sub    $0x4,%esp
f01010fa:	8b 1d 3c 55 11 f0    	mov    0xf011553c,%ebx
f0101100:	85 db                	test   %ebx,%ebx
f0101102:	74 2d                	je     f0101131 <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f0101104:	8b 03                	mov    (%ebx),%eax
f0101106:	a3 3c 55 11 f0       	mov    %eax,0xf011553c
	pag->pp_link = NULL;
f010110b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f0101111:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101115:	74 1a                	je     f0101131 <page_alloc+0x3e>
f0101117:	89 d8                	mov    %ebx,%eax
f0101119:	e8 27 fa ff ff       	call   f0100b45 <page2kva>
f010111e:	83 ec 04             	sub    $0x4,%esp
f0101121:	68 00 10 00 00       	push   $0x1000
f0101126:	6a 00                	push   $0x0
f0101128:	50                   	push   %eax
f0101129:	e8 8a 16 00 00       	call   f01027b8 <memset>
f010112e:	83 c4 10             	add    $0x10,%esp
	return pag;
}
f0101131:	89 d8                	mov    %ebx,%eax
f0101133:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101136:	c9                   	leave  
f0101137:	c3                   	ret    

f0101138 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101138:	55                   	push   %ebp
f0101139:	89 e5                	mov    %esp,%ebp
f010113b:	83 ec 08             	sub    $0x8,%esp
f010113e:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f0101141:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101146:	74 17                	je     f010115f <page_free+0x27>
f0101148:	83 ec 04             	sub    $0x4,%esp
f010114b:	68 09 38 10 f0       	push   $0xf0103809
f0101150:	68 39 01 00 00       	push   $0x139
f0101155:	68 23 37 10 f0       	push   $0xf0103723
f010115a:	e8 2c ef ff ff       	call   f010008b <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");//mejorar mensaje?
f010115f:	83 38 00             	cmpl   $0x0,(%eax)
f0101162:	74 17                	je     f010117b <page_free+0x43>
f0101164:	83 ec 04             	sub    $0x4,%esp
f0101167:	68 e0 33 10 f0       	push   $0xf01033e0
f010116c:	68 3a 01 00 00       	push   $0x13a
f0101171:	68 23 37 10 f0       	push   $0xf0103723
f0101176:	e8 10 ef ff ff       	call   f010008b <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f010117b:	8b 15 3c 55 11 f0    	mov    0xf011553c,%edx
f0101181:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f0101183:	a3 3c 55 11 f0       	mov    %eax,0xf011553c
}
f0101188:	c9                   	leave  
f0101189:	c3                   	ret    

f010118a <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f010118a:	55                   	push   %ebp
f010118b:	89 e5                	mov    %esp,%ebp
f010118d:	57                   	push   %edi
f010118e:	56                   	push   %esi
f010118f:	53                   	push   %ebx
f0101190:	83 ec 1c             	sub    $0x1c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101193:	83 3d 4c 59 11 f0 00 	cmpl   $0x0,0xf011594c
f010119a:	75 17                	jne    f01011b3 <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f010119c:	83 ec 04             	sub    $0x4,%esp
f010119f:	68 1d 38 10 f0       	push   $0xf010381d
f01011a4:	68 1a 02 00 00       	push   $0x21a
f01011a9:	68 23 37 10 f0       	push   $0xf0103723
f01011ae:	e8 d8 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011b3:	a1 3c 55 11 f0       	mov    0xf011553c,%eax
f01011b8:	be 00 00 00 00       	mov    $0x0,%esi
f01011bd:	eb 05                	jmp    f01011c4 <check_page_alloc+0x3a>
		++nfree;
f01011bf:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011c2:	8b 00                	mov    (%eax),%eax
f01011c4:	85 c0                	test   %eax,%eax
f01011c6:	75 f7                	jne    f01011bf <check_page_alloc+0x35>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011c8:	83 ec 0c             	sub    $0xc,%esp
f01011cb:	6a 00                	push   $0x0
f01011cd:	e8 21 ff ff ff       	call   f01010f3 <page_alloc>
f01011d2:	89 c7                	mov    %eax,%edi
f01011d4:	83 c4 10             	add    $0x10,%esp
f01011d7:	85 c0                	test   %eax,%eax
f01011d9:	75 19                	jne    f01011f4 <check_page_alloc+0x6a>
f01011db:	68 38 38 10 f0       	push   $0xf0103838
f01011e0:	68 3d 37 10 f0       	push   $0xf010373d
f01011e5:	68 22 02 00 00       	push   $0x222
f01011ea:	68 23 37 10 f0       	push   $0xf0103723
f01011ef:	e8 97 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011f4:	83 ec 0c             	sub    $0xc,%esp
f01011f7:	6a 00                	push   $0x0
f01011f9:	e8 f5 fe ff ff       	call   f01010f3 <page_alloc>
f01011fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101201:	83 c4 10             	add    $0x10,%esp
f0101204:	85 c0                	test   %eax,%eax
f0101206:	75 19                	jne    f0101221 <check_page_alloc+0x97>
f0101208:	68 4e 38 10 f0       	push   $0xf010384e
f010120d:	68 3d 37 10 f0       	push   $0xf010373d
f0101212:	68 23 02 00 00       	push   $0x223
f0101217:	68 23 37 10 f0       	push   $0xf0103723
f010121c:	e8 6a ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101221:	83 ec 0c             	sub    $0xc,%esp
f0101224:	6a 00                	push   $0x0
f0101226:	e8 c8 fe ff ff       	call   f01010f3 <page_alloc>
f010122b:	89 c3                	mov    %eax,%ebx
f010122d:	83 c4 10             	add    $0x10,%esp
f0101230:	85 c0                	test   %eax,%eax
f0101232:	75 19                	jne    f010124d <check_page_alloc+0xc3>
f0101234:	68 64 38 10 f0       	push   $0xf0103864
f0101239:	68 3d 37 10 f0       	push   $0xf010373d
f010123e:	68 24 02 00 00       	push   $0x224
f0101243:	68 23 37 10 f0       	push   $0xf0103723
f0101248:	e8 3e ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010124d:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0101250:	75 19                	jne    f010126b <check_page_alloc+0xe1>
f0101252:	68 7a 38 10 f0       	push   $0xf010387a
f0101257:	68 3d 37 10 f0       	push   $0xf010373d
f010125c:	68 27 02 00 00       	push   $0x227
f0101261:	68 23 37 10 f0       	push   $0xf0103723
f0101266:	e8 20 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010126b:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010126e:	74 04                	je     f0101274 <check_page_alloc+0xea>
f0101270:	39 c7                	cmp    %eax,%edi
f0101272:	75 19                	jne    f010128d <check_page_alloc+0x103>
f0101274:	68 0c 34 10 f0       	push   $0xf010340c
f0101279:	68 3d 37 10 f0       	push   $0xf010373d
f010127e:	68 28 02 00 00       	push   $0x228
f0101283:	68 23 37 10 f0       	push   $0xf0103723
f0101288:	e8 fe ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f010128d:	89 f8                	mov    %edi,%eax
f010128f:	e8 7b f7 ff ff       	call   f0100a0f <page2pa>
f0101294:	8b 0d 44 59 11 f0    	mov    0xf0115944,%ecx
f010129a:	c1 e1 0c             	shl    $0xc,%ecx
f010129d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01012a0:	39 c8                	cmp    %ecx,%eax
f01012a2:	72 19                	jb     f01012bd <check_page_alloc+0x133>
f01012a4:	68 8c 38 10 f0       	push   $0xf010388c
f01012a9:	68 3d 37 10 f0       	push   $0xf010373d
f01012ae:	68 29 02 00 00       	push   $0x229
f01012b3:	68 23 37 10 f0       	push   $0xf0103723
f01012b8:	e8 ce ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012c0:	e8 4a f7 ff ff       	call   f0100a0f <page2pa>
f01012c5:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01012c8:	77 19                	ja     f01012e3 <check_page_alloc+0x159>
f01012ca:	68 a9 38 10 f0       	push   $0xf01038a9
f01012cf:	68 3d 37 10 f0       	push   $0xf010373d
f01012d4:	68 2a 02 00 00       	push   $0x22a
f01012d9:	68 23 37 10 f0       	push   $0xf0103723
f01012de:	e8 a8 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012e3:	89 d8                	mov    %ebx,%eax
f01012e5:	e8 25 f7 ff ff       	call   f0100a0f <page2pa>
f01012ea:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01012ed:	77 19                	ja     f0101308 <check_page_alloc+0x17e>
f01012ef:	68 c6 38 10 f0       	push   $0xf01038c6
f01012f4:	68 3d 37 10 f0       	push   $0xf010373d
f01012f9:	68 2b 02 00 00       	push   $0x22b
f01012fe:	68 23 37 10 f0       	push   $0xf0103723
f0101303:	e8 83 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101308:	a1 3c 55 11 f0       	mov    0xf011553c,%eax
f010130d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0101310:	c7 05 3c 55 11 f0 00 	movl   $0x0,0xf011553c
f0101317:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010131a:	83 ec 0c             	sub    $0xc,%esp
f010131d:	6a 00                	push   $0x0
f010131f:	e8 cf fd ff ff       	call   f01010f3 <page_alloc>
f0101324:	83 c4 10             	add    $0x10,%esp
f0101327:	85 c0                	test   %eax,%eax
f0101329:	74 19                	je     f0101344 <check_page_alloc+0x1ba>
f010132b:	68 e3 38 10 f0       	push   $0xf01038e3
f0101330:	68 3d 37 10 f0       	push   $0xf010373d
f0101335:	68 32 02 00 00       	push   $0x232
f010133a:	68 23 37 10 f0       	push   $0xf0103723
f010133f:	e8 47 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101344:	83 ec 0c             	sub    $0xc,%esp
f0101347:	57                   	push   %edi
f0101348:	e8 eb fd ff ff       	call   f0101138 <page_free>
	page_free(pp1);
f010134d:	83 c4 04             	add    $0x4,%esp
f0101350:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101353:	e8 e0 fd ff ff       	call   f0101138 <page_free>
	page_free(pp2);
f0101358:	89 1c 24             	mov    %ebx,(%esp)
f010135b:	e8 d8 fd ff ff       	call   f0101138 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101360:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101367:	e8 87 fd ff ff       	call   f01010f3 <page_alloc>
f010136c:	89 c3                	mov    %eax,%ebx
f010136e:	83 c4 10             	add    $0x10,%esp
f0101371:	85 c0                	test   %eax,%eax
f0101373:	75 19                	jne    f010138e <check_page_alloc+0x204>
f0101375:	68 38 38 10 f0       	push   $0xf0103838
f010137a:	68 3d 37 10 f0       	push   $0xf010373d
f010137f:	68 39 02 00 00       	push   $0x239
f0101384:	68 23 37 10 f0       	push   $0xf0103723
f0101389:	e8 fd ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010138e:	83 ec 0c             	sub    $0xc,%esp
f0101391:	6a 00                	push   $0x0
f0101393:	e8 5b fd ff ff       	call   f01010f3 <page_alloc>
f0101398:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010139b:	83 c4 10             	add    $0x10,%esp
f010139e:	85 c0                	test   %eax,%eax
f01013a0:	75 19                	jne    f01013bb <check_page_alloc+0x231>
f01013a2:	68 4e 38 10 f0       	push   $0xf010384e
f01013a7:	68 3d 37 10 f0       	push   $0xf010373d
f01013ac:	68 3a 02 00 00       	push   $0x23a
f01013b1:	68 23 37 10 f0       	push   $0xf0103723
f01013b6:	e8 d0 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013bb:	83 ec 0c             	sub    $0xc,%esp
f01013be:	6a 00                	push   $0x0
f01013c0:	e8 2e fd ff ff       	call   f01010f3 <page_alloc>
f01013c5:	89 c7                	mov    %eax,%edi
f01013c7:	83 c4 10             	add    $0x10,%esp
f01013ca:	85 c0                	test   %eax,%eax
f01013cc:	75 19                	jne    f01013e7 <check_page_alloc+0x25d>
f01013ce:	68 64 38 10 f0       	push   $0xf0103864
f01013d3:	68 3d 37 10 f0       	push   $0xf010373d
f01013d8:	68 3b 02 00 00       	push   $0x23b
f01013dd:	68 23 37 10 f0       	push   $0xf0103723
f01013e2:	e8 a4 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013e7:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01013ea:	75 19                	jne    f0101405 <check_page_alloc+0x27b>
f01013ec:	68 7a 38 10 f0       	push   $0xf010387a
f01013f1:	68 3d 37 10 f0       	push   $0xf010373d
f01013f6:	68 3d 02 00 00       	push   $0x23d
f01013fb:	68 23 37 10 f0       	push   $0xf0103723
f0101400:	e8 86 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101405:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101408:	74 04                	je     f010140e <check_page_alloc+0x284>
f010140a:	39 c3                	cmp    %eax,%ebx
f010140c:	75 19                	jne    f0101427 <check_page_alloc+0x29d>
f010140e:	68 0c 34 10 f0       	push   $0xf010340c
f0101413:	68 3d 37 10 f0       	push   $0xf010373d
f0101418:	68 3e 02 00 00       	push   $0x23e
f010141d:	68 23 37 10 f0       	push   $0xf0103723
f0101422:	e8 64 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101427:	83 ec 0c             	sub    $0xc,%esp
f010142a:	6a 00                	push   $0x0
f010142c:	e8 c2 fc ff ff       	call   f01010f3 <page_alloc>
f0101431:	83 c4 10             	add    $0x10,%esp
f0101434:	85 c0                	test   %eax,%eax
f0101436:	74 19                	je     f0101451 <check_page_alloc+0x2c7>
f0101438:	68 e3 38 10 f0       	push   $0xf01038e3
f010143d:	68 3d 37 10 f0       	push   $0xf010373d
f0101442:	68 3f 02 00 00       	push   $0x23f
f0101447:	68 23 37 10 f0       	push   $0xf0103723
f010144c:	e8 3a ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101451:	89 d8                	mov    %ebx,%eax
f0101453:	e8 ed f6 ff ff       	call   f0100b45 <page2kva>
f0101458:	83 ec 04             	sub    $0x4,%esp
f010145b:	68 00 10 00 00       	push   $0x1000
f0101460:	6a 01                	push   $0x1
f0101462:	50                   	push   %eax
f0101463:	e8 50 13 00 00       	call   f01027b8 <memset>
	page_free(pp0);
f0101468:	89 1c 24             	mov    %ebx,(%esp)
f010146b:	e8 c8 fc ff ff       	call   f0101138 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101470:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101477:	e8 77 fc ff ff       	call   f01010f3 <page_alloc>
f010147c:	83 c4 10             	add    $0x10,%esp
f010147f:	85 c0                	test   %eax,%eax
f0101481:	75 19                	jne    f010149c <check_page_alloc+0x312>
f0101483:	68 f2 38 10 f0       	push   $0xf01038f2
f0101488:	68 3d 37 10 f0       	push   $0xf010373d
f010148d:	68 44 02 00 00       	push   $0x244
f0101492:	68 23 37 10 f0       	push   $0xf0103723
f0101497:	e8 ef eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010149c:	39 c3                	cmp    %eax,%ebx
f010149e:	74 19                	je     f01014b9 <check_page_alloc+0x32f>
f01014a0:	68 10 39 10 f0       	push   $0xf0103910
f01014a5:	68 3d 37 10 f0       	push   $0xf010373d
f01014aa:	68 45 02 00 00       	push   $0x245
f01014af:	68 23 37 10 f0       	push   $0xf0103723
f01014b4:	e8 d2 eb ff ff       	call   f010008b <_panic>
	c = page2kva(pp);
f01014b9:	89 d8                	mov    %ebx,%eax
f01014bb:	e8 85 f6 ff ff       	call   f0100b45 <page2kva>
f01014c0:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014c6:	80 38 00             	cmpb   $0x0,(%eax)
f01014c9:	74 19                	je     f01014e4 <check_page_alloc+0x35a>
f01014cb:	68 20 39 10 f0       	push   $0xf0103920
f01014d0:	68 3d 37 10 f0       	push   $0xf010373d
f01014d5:	68 48 02 00 00       	push   $0x248
f01014da:	68 23 37 10 f0       	push   $0xf0103723
f01014df:	e8 a7 eb ff ff       	call   f010008b <_panic>
f01014e4:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014e7:	39 d0                	cmp    %edx,%eax
f01014e9:	75 db                	jne    f01014c6 <check_page_alloc+0x33c>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01014ee:	a3 3c 55 11 f0       	mov    %eax,0xf011553c

	// free the pages we took
	page_free(pp0);
f01014f3:	83 ec 0c             	sub    $0xc,%esp
f01014f6:	53                   	push   %ebx
f01014f7:	e8 3c fc ff ff       	call   f0101138 <page_free>
	page_free(pp1);
f01014fc:	83 c4 04             	add    $0x4,%esp
f01014ff:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101502:	e8 31 fc ff ff       	call   f0101138 <page_free>
	page_free(pp2);
f0101507:	89 3c 24             	mov    %edi,(%esp)
f010150a:	e8 29 fc ff ff       	call   f0101138 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010150f:	a1 3c 55 11 f0       	mov    0xf011553c,%eax
f0101514:	83 c4 10             	add    $0x10,%esp
f0101517:	eb 05                	jmp    f010151e <check_page_alloc+0x394>
		--nfree;
f0101519:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010151c:	8b 00                	mov    (%eax),%eax
f010151e:	85 c0                	test   %eax,%eax
f0101520:	75 f7                	jne    f0101519 <check_page_alloc+0x38f>
		--nfree;
	assert(nfree == 0);
f0101522:	85 f6                	test   %esi,%esi
f0101524:	74 19                	je     f010153f <check_page_alloc+0x3b5>
f0101526:	68 2a 39 10 f0       	push   $0xf010392a
f010152b:	68 3d 37 10 f0       	push   $0xf010373d
f0101530:	68 55 02 00 00       	push   $0x255
f0101535:	68 23 37 10 f0       	push   $0xf0103723
f010153a:	e8 4c eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010153f:	83 ec 0c             	sub    $0xc,%esp
f0101542:	68 2c 34 10 f0       	push   $0xf010342c
f0101547:	e8 c8 07 00 00       	call   f0101d14 <cprintf>
}
f010154c:	83 c4 10             	add    $0x10,%esp
f010154f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101552:	5b                   	pop    %ebx
f0101553:	5e                   	pop    %esi
f0101554:	5f                   	pop    %edi
f0101555:	5d                   	pop    %ebp
f0101556:	c3                   	ret    

f0101557 <check_page_installed_pgdir>:
}

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f0101557:	55                   	push   %ebp
f0101558:	89 e5                	mov    %esp,%ebp
f010155a:	57                   	push   %edi
f010155b:	56                   	push   %esi
f010155c:	53                   	push   %ebx
f010155d:	83 ec 18             	sub    $0x18,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101560:	6a 00                	push   $0x0
f0101562:	e8 8c fb ff ff       	call   f01010f3 <page_alloc>
f0101567:	83 c4 10             	add    $0x10,%esp
f010156a:	85 c0                	test   %eax,%eax
f010156c:	75 19                	jne    f0101587 <check_page_installed_pgdir+0x30>
f010156e:	68 38 38 10 f0       	push   $0xf0103838
f0101573:	68 3d 37 10 f0       	push   $0xf010373d
f0101578:	68 48 03 00 00       	push   $0x348
f010157d:	68 23 37 10 f0       	push   $0xf0103723
f0101582:	e8 04 eb ff ff       	call   f010008b <_panic>
f0101587:	89 c6                	mov    %eax,%esi
	assert((pp1 = page_alloc(0)));
f0101589:	83 ec 0c             	sub    $0xc,%esp
f010158c:	6a 00                	push   $0x0
f010158e:	e8 60 fb ff ff       	call   f01010f3 <page_alloc>
f0101593:	89 c3                	mov    %eax,%ebx
f0101595:	83 c4 10             	add    $0x10,%esp
f0101598:	85 c0                	test   %eax,%eax
f010159a:	75 19                	jne    f01015b5 <check_page_installed_pgdir+0x5e>
f010159c:	68 4e 38 10 f0       	push   $0xf010384e
f01015a1:	68 3d 37 10 f0       	push   $0xf010373d
f01015a6:	68 49 03 00 00       	push   $0x349
f01015ab:	68 23 37 10 f0       	push   $0xf0103723
f01015b0:	e8 d6 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015b5:	83 ec 0c             	sub    $0xc,%esp
f01015b8:	6a 00                	push   $0x0
f01015ba:	e8 34 fb ff ff       	call   f01010f3 <page_alloc>
f01015bf:	89 c7                	mov    %eax,%edi
f01015c1:	83 c4 10             	add    $0x10,%esp
f01015c4:	85 c0                	test   %eax,%eax
f01015c6:	75 19                	jne    f01015e1 <check_page_installed_pgdir+0x8a>
f01015c8:	68 64 38 10 f0       	push   $0xf0103864
f01015cd:	68 3d 37 10 f0       	push   $0xf010373d
f01015d2:	68 4a 03 00 00       	push   $0x34a
f01015d7:	68 23 37 10 f0       	push   $0xf0103723
f01015dc:	e8 aa ea ff ff       	call   f010008b <_panic>
	page_free(pp0);
f01015e1:	83 ec 0c             	sub    $0xc,%esp
f01015e4:	56                   	push   %esi
f01015e5:	e8 4e fb ff ff       	call   f0101138 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01015ea:	89 d8                	mov    %ebx,%eax
f01015ec:	e8 54 f5 ff ff       	call   f0100b45 <page2kva>
f01015f1:	83 c4 0c             	add    $0xc,%esp
f01015f4:	68 00 10 00 00       	push   $0x1000
f01015f9:	6a 01                	push   $0x1
f01015fb:	50                   	push   %eax
f01015fc:	e8 b7 11 00 00       	call   f01027b8 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0101601:	89 f8                	mov    %edi,%eax
f0101603:	e8 3d f5 ff ff       	call   f0100b45 <page2kva>
f0101608:	83 c4 0c             	add    $0xc,%esp
f010160b:	68 00 10 00 00       	push   $0x1000
f0101610:	6a 02                	push   $0x2
f0101612:	50                   	push   %eax
f0101613:	e8 a0 11 00 00       	call   f01027b8 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
	assert(pp1->pp_ref == 1);
f0101618:	83 c4 10             	add    $0x10,%esp
f010161b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101620:	74 19                	je     f010163b <check_page_installed_pgdir+0xe4>
f0101622:	68 35 39 10 f0       	push   $0xf0103935
f0101627:	68 3d 37 10 f0       	push   $0xf010373d
f010162c:	68 4f 03 00 00       	push   $0x34f
f0101631:	68 23 37 10 f0       	push   $0xf0103723
f0101636:	e8 50 ea ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010163b:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0101642:	01 01 01 
f0101645:	74 19                	je     f0101660 <check_page_installed_pgdir+0x109>
f0101647:	68 4c 34 10 f0       	push   $0xf010344c
f010164c:	68 3d 37 10 f0       	push   $0xf010373d
f0101651:	68 50 03 00 00       	push   $0x350
f0101656:	68 23 37 10 f0       	push   $0xf0103723
f010165b:	e8 2b ea ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0101660:	68 70 34 10 f0       	push   $0xf0103470
f0101665:	68 3d 37 10 f0       	push   $0xf010373d
f010166a:	68 52 03 00 00       	push   $0x352
f010166f:	68 23 37 10 f0       	push   $0xf0103723
f0101674:	e8 12 ea ff ff       	call   f010008b <_panic>

f0101679 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101679:	55                   	push   %ebp
f010167a:	89 e5                	mov    %esp,%ebp
f010167c:	83 ec 08             	sub    $0x8,%esp
f010167f:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101682:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101686:	83 e8 01             	sub    $0x1,%eax
f0101689:	66 89 42 04          	mov    %ax,0x4(%edx)
f010168d:	66 85 c0             	test   %ax,%ax
f0101690:	75 0c                	jne    f010169e <page_decref+0x25>
		page_free(pp);
f0101692:	83 ec 0c             	sub    $0xc,%esp
f0101695:	52                   	push   %edx
f0101696:	e8 9d fa ff ff       	call   f0101138 <page_free>
f010169b:	83 c4 10             	add    $0x10,%esp
}
f010169e:	c9                   	leave  
f010169f:	c3                   	ret    

f01016a0 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01016a0:	55                   	push   %ebp
f01016a1:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01016a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01016a8:	5d                   	pop    %ebp
f01016a9:	c3                   	ret    

f01016aa <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01016aa:	55                   	push   %ebp
f01016ab:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01016ad:	b8 00 00 00 00       	mov    $0x0,%eax
f01016b2:	5d                   	pop    %ebp
f01016b3:	c3                   	ret    

f01016b4 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01016b4:	55                   	push   %ebp
f01016b5:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01016b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01016bc:	5d                   	pop    %ebp
f01016bd:	c3                   	ret    

f01016be <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f01016be:	55                   	push   %ebp
f01016bf:	89 e5                	mov    %esp,%ebp
f01016c1:	57                   	push   %edi
f01016c2:	56                   	push   %esi
f01016c3:	53                   	push   %ebx
f01016c4:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016c7:	6a 00                	push   $0x0
f01016c9:	e8 25 fa ff ff       	call   f01010f3 <page_alloc>
f01016ce:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016d1:	83 c4 10             	add    $0x10,%esp
f01016d4:	85 c0                	test   %eax,%eax
f01016d6:	75 19                	jne    f01016f1 <check_page+0x33>
f01016d8:	68 38 38 10 f0       	push   $0xf0103838
f01016dd:	68 3d 37 10 f0       	push   $0xf010373d
f01016e2:	68 b0 02 00 00       	push   $0x2b0
f01016e7:	68 23 37 10 f0       	push   $0xf0103723
f01016ec:	e8 9a e9 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01016f1:	83 ec 0c             	sub    $0xc,%esp
f01016f4:	6a 00                	push   $0x0
f01016f6:	e8 f8 f9 ff ff       	call   f01010f3 <page_alloc>
f01016fb:	89 c6                	mov    %eax,%esi
f01016fd:	83 c4 10             	add    $0x10,%esp
f0101700:	85 c0                	test   %eax,%eax
f0101702:	75 19                	jne    f010171d <check_page+0x5f>
f0101704:	68 4e 38 10 f0       	push   $0xf010384e
f0101709:	68 3d 37 10 f0       	push   $0xf010373d
f010170e:	68 b1 02 00 00       	push   $0x2b1
f0101713:	68 23 37 10 f0       	push   $0xf0103723
f0101718:	e8 6e e9 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010171d:	83 ec 0c             	sub    $0xc,%esp
f0101720:	6a 00                	push   $0x0
f0101722:	e8 cc f9 ff ff       	call   f01010f3 <page_alloc>
f0101727:	89 c3                	mov    %eax,%ebx
f0101729:	83 c4 10             	add    $0x10,%esp
f010172c:	85 c0                	test   %eax,%eax
f010172e:	75 19                	jne    f0101749 <check_page+0x8b>
f0101730:	68 64 38 10 f0       	push   $0xf0103864
f0101735:	68 3d 37 10 f0       	push   $0xf010373d
f010173a:	68 b2 02 00 00       	push   $0x2b2
f010173f:	68 23 37 10 f0       	push   $0xf0103723
f0101744:	e8 42 e9 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101749:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010174c:	75 19                	jne    f0101767 <check_page+0xa9>
f010174e:	68 7a 38 10 f0       	push   $0xf010387a
f0101753:	68 3d 37 10 f0       	push   $0xf010373d
f0101758:	68 b5 02 00 00       	push   $0x2b5
f010175d:	68 23 37 10 f0       	push   $0xf0103723
f0101762:	e8 24 e9 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101767:	39 c6                	cmp    %eax,%esi
f0101769:	74 05                	je     f0101770 <check_page+0xb2>
f010176b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010176e:	75 19                	jne    f0101789 <check_page+0xcb>
f0101770:	68 0c 34 10 f0       	push   $0xf010340c
f0101775:	68 3d 37 10 f0       	push   $0xf010373d
f010177a:	68 b6 02 00 00       	push   $0x2b6
f010177f:	68 23 37 10 f0       	push   $0xf0103723
f0101784:	e8 02 e9 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101789:	c7 05 3c 55 11 f0 00 	movl   $0x0,0xf011553c
f0101790:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101793:	83 ec 0c             	sub    $0xc,%esp
f0101796:	6a 00                	push   $0x0
f0101798:	e8 56 f9 ff ff       	call   f01010f3 <page_alloc>
f010179d:	83 c4 10             	add    $0x10,%esp
f01017a0:	85 c0                	test   %eax,%eax
f01017a2:	74 19                	je     f01017bd <check_page+0xff>
f01017a4:	68 e3 38 10 f0       	push   $0xf01038e3
f01017a9:	68 3d 37 10 f0       	push   $0xf010373d
f01017ae:	68 bd 02 00 00       	push   $0x2bd
f01017b3:	68 23 37 10 f0       	push   $0xf0103723
f01017b8:	e8 ce e8 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01017bd:	8b 3d 48 59 11 f0    	mov    0xf0115948,%edi
f01017c3:	83 ec 04             	sub    $0x4,%esp
f01017c6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01017c9:	50                   	push   %eax
f01017ca:	6a 00                	push   $0x0
f01017cc:	57                   	push   %edi
f01017cd:	e8 e2 fe ff ff       	call   f01016b4 <page_lookup>
f01017d2:	83 c4 10             	add    $0x10,%esp
f01017d5:	85 c0                	test   %eax,%eax
f01017d7:	74 19                	je     f01017f2 <check_page+0x134>
f01017d9:	68 94 34 10 f0       	push   $0xf0103494
f01017de:	68 3d 37 10 f0       	push   $0xf010373d
f01017e3:	68 c0 02 00 00       	push   $0x2c0
f01017e8:	68 23 37 10 f0       	push   $0xf0103723
f01017ed:	e8 99 e8 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01017f2:	6a 02                	push   $0x2
f01017f4:	6a 00                	push   $0x0
f01017f6:	56                   	push   %esi
f01017f7:	57                   	push   %edi
f01017f8:	e8 ad fe ff ff       	call   f01016aa <page_insert>
f01017fd:	83 c4 10             	add    $0x10,%esp
f0101800:	85 c0                	test   %eax,%eax
f0101802:	78 19                	js     f010181d <check_page+0x15f>
f0101804:	68 cc 34 10 f0       	push   $0xf01034cc
f0101809:	68 3d 37 10 f0       	push   $0xf010373d
f010180e:	68 c3 02 00 00       	push   $0x2c3
f0101813:	68 23 37 10 f0       	push   $0xf0103723
f0101818:	e8 6e e8 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010181d:	83 ec 0c             	sub    $0xc,%esp
f0101820:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101823:	e8 10 f9 ff ff       	call   f0101138 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101828:	8b 3d 48 59 11 f0    	mov    0xf0115948,%edi
f010182e:	6a 02                	push   $0x2
f0101830:	6a 00                	push   $0x0
f0101832:	56                   	push   %esi
f0101833:	57                   	push   %edi
f0101834:	e8 71 fe ff ff       	call   f01016aa <page_insert>
f0101839:	83 c4 20             	add    $0x20,%esp
f010183c:	85 c0                	test   %eax,%eax
f010183e:	74 19                	je     f0101859 <check_page+0x19b>
f0101840:	68 fc 34 10 f0       	push   $0xf01034fc
f0101845:	68 3d 37 10 f0       	push   $0xf010373d
f010184a:	68 c7 02 00 00       	push   $0x2c7
f010184f:	68 23 37 10 f0       	push   $0xf0103723
f0101854:	e8 32 e8 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101859:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010185c:	e8 ae f1 ff ff       	call   f0100a0f <page2pa>
f0101861:	8b 17                	mov    (%edi),%edx
f0101863:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101869:	39 c2                	cmp    %eax,%edx
f010186b:	74 19                	je     f0101886 <check_page+0x1c8>
f010186d:	68 2c 35 10 f0       	push   $0xf010352c
f0101872:	68 3d 37 10 f0       	push   $0xf010373d
f0101877:	68 c8 02 00 00       	push   $0x2c8
f010187c:	68 23 37 10 f0       	push   $0xf0103723
f0101881:	e8 05 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101886:	ba 00 00 00 00       	mov    $0x0,%edx
f010188b:	89 f8                	mov    %edi,%eax
f010188d:	e8 d1 f2 ff ff       	call   f0100b63 <check_va2pa>
f0101892:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101895:	89 f0                	mov    %esi,%eax
f0101897:	e8 73 f1 ff ff       	call   f0100a0f <page2pa>
f010189c:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010189f:	74 19                	je     f01018ba <check_page+0x1fc>
f01018a1:	68 54 35 10 f0       	push   $0xf0103554
f01018a6:	68 3d 37 10 f0       	push   $0xf010373d
f01018ab:	68 c9 02 00 00       	push   $0x2c9
f01018b0:	68 23 37 10 f0       	push   $0xf0103723
f01018b5:	e8 d1 e7 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01018ba:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018bf:	74 19                	je     f01018da <check_page+0x21c>
f01018c1:	68 35 39 10 f0       	push   $0xf0103935
f01018c6:	68 3d 37 10 f0       	push   $0xf010373d
f01018cb:	68 ca 02 00 00       	push   $0x2ca
f01018d0:	68 23 37 10 f0       	push   $0xf0103723
f01018d5:	e8 b1 e7 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01018da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018dd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01018e2:	74 19                	je     f01018fd <check_page+0x23f>
f01018e4:	68 46 39 10 f0       	push   $0xf0103946
f01018e9:	68 3d 37 10 f0       	push   $0xf010373d
f01018ee:	68 cb 02 00 00       	push   $0x2cb
f01018f3:	68 23 37 10 f0       	push   $0xf0103723
f01018f8:	e8 8e e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018fd:	6a 02                	push   $0x2
f01018ff:	68 00 10 00 00       	push   $0x1000
f0101904:	53                   	push   %ebx
f0101905:	57                   	push   %edi
f0101906:	e8 9f fd ff ff       	call   f01016aa <page_insert>
f010190b:	83 c4 10             	add    $0x10,%esp
f010190e:	85 c0                	test   %eax,%eax
f0101910:	74 19                	je     f010192b <check_page+0x26d>
f0101912:	68 84 35 10 f0       	push   $0xf0103584
f0101917:	68 3d 37 10 f0       	push   $0xf010373d
f010191c:	68 ce 02 00 00       	push   $0x2ce
f0101921:	68 23 37 10 f0       	push   $0xf0103723
f0101926:	e8 60 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010192b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101930:	89 f8                	mov    %edi,%eax
f0101932:	e8 2c f2 ff ff       	call   f0100b63 <check_va2pa>
f0101937:	89 c6                	mov    %eax,%esi
f0101939:	89 d8                	mov    %ebx,%eax
f010193b:	e8 cf f0 ff ff       	call   f0100a0f <page2pa>
f0101940:	39 c6                	cmp    %eax,%esi
f0101942:	74 19                	je     f010195d <check_page+0x29f>
f0101944:	68 c0 35 10 f0       	push   $0xf01035c0
f0101949:	68 3d 37 10 f0       	push   $0xf010373d
f010194e:	68 cf 02 00 00       	push   $0x2cf
f0101953:	68 23 37 10 f0       	push   $0xf0103723
f0101958:	e8 2e e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010195d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101962:	74 19                	je     f010197d <check_page+0x2bf>
f0101964:	68 57 39 10 f0       	push   $0xf0103957
f0101969:	68 3d 37 10 f0       	push   $0xf010373d
f010196e:	68 d0 02 00 00       	push   $0x2d0
f0101973:	68 23 37 10 f0       	push   $0xf0103723
f0101978:	e8 0e e7 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010197d:	83 ec 0c             	sub    $0xc,%esp
f0101980:	6a 00                	push   $0x0
f0101982:	e8 6c f7 ff ff       	call   f01010f3 <page_alloc>
f0101987:	83 c4 10             	add    $0x10,%esp
f010198a:	85 c0                	test   %eax,%eax
f010198c:	74 19                	je     f01019a7 <check_page+0x2e9>
f010198e:	68 e3 38 10 f0       	push   $0xf01038e3
f0101993:	68 3d 37 10 f0       	push   $0xf010373d
f0101998:	68 d3 02 00 00       	push   $0x2d3
f010199d:	68 23 37 10 f0       	push   $0xf0103723
f01019a2:	e8 e4 e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019a7:	8b 35 48 59 11 f0    	mov    0xf0115948,%esi
f01019ad:	6a 02                	push   $0x2
f01019af:	68 00 10 00 00       	push   $0x1000
f01019b4:	53                   	push   %ebx
f01019b5:	56                   	push   %esi
f01019b6:	e8 ef fc ff ff       	call   f01016aa <page_insert>
f01019bb:	83 c4 10             	add    $0x10,%esp
f01019be:	85 c0                	test   %eax,%eax
f01019c0:	74 19                	je     f01019db <check_page+0x31d>
f01019c2:	68 84 35 10 f0       	push   $0xf0103584
f01019c7:	68 3d 37 10 f0       	push   $0xf010373d
f01019cc:	68 d6 02 00 00       	push   $0x2d6
f01019d1:	68 23 37 10 f0       	push   $0xf0103723
f01019d6:	e8 b0 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019db:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019e0:	89 f0                	mov    %esi,%eax
f01019e2:	e8 7c f1 ff ff       	call   f0100b63 <check_va2pa>
f01019e7:	89 c6                	mov    %eax,%esi
f01019e9:	89 d8                	mov    %ebx,%eax
f01019eb:	e8 1f f0 ff ff       	call   f0100a0f <page2pa>
f01019f0:	39 c6                	cmp    %eax,%esi
f01019f2:	74 19                	je     f0101a0d <check_page+0x34f>
f01019f4:	68 c0 35 10 f0       	push   $0xf01035c0
f01019f9:	68 3d 37 10 f0       	push   $0xf010373d
f01019fe:	68 d7 02 00 00       	push   $0x2d7
f0101a03:	68 23 37 10 f0       	push   $0xf0103723
f0101a08:	e8 7e e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a0d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a12:	74 19                	je     f0101a2d <check_page+0x36f>
f0101a14:	68 57 39 10 f0       	push   $0xf0103957
f0101a19:	68 3d 37 10 f0       	push   $0xf010373d
f0101a1e:	68 d8 02 00 00       	push   $0x2d8
f0101a23:	68 23 37 10 f0       	push   $0xf0103723
f0101a28:	e8 5e e6 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a2d:	83 ec 0c             	sub    $0xc,%esp
f0101a30:	6a 00                	push   $0x0
f0101a32:	e8 bc f6 ff ff       	call   f01010f3 <page_alloc>
f0101a37:	83 c4 10             	add    $0x10,%esp
f0101a3a:	85 c0                	test   %eax,%eax
f0101a3c:	74 19                	je     f0101a57 <check_page+0x399>
f0101a3e:	68 e3 38 10 f0       	push   $0xf01038e3
f0101a43:	68 3d 37 10 f0       	push   $0xf010373d
f0101a48:	68 dc 02 00 00       	push   $0x2dc
f0101a4d:	68 23 37 10 f0       	push   $0xf0103723
f0101a52:	e8 34 e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101a57:	8b 35 48 59 11 f0    	mov    0xf0115948,%esi
f0101a5d:	8b 3e                	mov    (%esi),%edi
f0101a5f:	89 f9                	mov    %edi,%ecx
f0101a61:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101a67:	ba df 02 00 00       	mov    $0x2df,%edx
f0101a6c:	b8 23 37 10 f0       	mov    $0xf0103723,%eax
f0101a71:	e8 a3 f0 ff ff       	call   f0100b19 <_kaddr>
f0101a76:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a7c:	83 ec 04             	sub    $0x4,%esp
f0101a7f:	6a 00                	push   $0x0
f0101a81:	68 00 10 00 00       	push   $0x1000
f0101a86:	56                   	push   %esi
f0101a87:	e8 14 fc ff ff       	call   f01016a0 <pgdir_walk>
f0101a8c:	83 c4 10             	add    $0x10,%esp
f0101a8f:	89 c2                	mov    %eax,%edx
f0101a91:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a94:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a97:	8d 41 04             	lea    0x4(%ecx),%eax
f0101a9a:	39 c2                	cmp    %eax,%edx
f0101a9c:	74 19                	je     f0101ab7 <check_page+0x3f9>
f0101a9e:	68 f0 35 10 f0       	push   $0xf01035f0
f0101aa3:	68 3d 37 10 f0       	push   $0xf010373d
f0101aa8:	68 e0 02 00 00       	push   $0x2e0
f0101aad:	68 23 37 10 f0       	push   $0xf0103723
f0101ab2:	e8 d4 e5 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101ab7:	6a 06                	push   $0x6
f0101ab9:	68 00 10 00 00       	push   $0x1000
f0101abe:	53                   	push   %ebx
f0101abf:	56                   	push   %esi
f0101ac0:	e8 e5 fb ff ff       	call   f01016aa <page_insert>
f0101ac5:	83 c4 10             	add    $0x10,%esp
f0101ac8:	85 c0                	test   %eax,%eax
f0101aca:	74 19                	je     f0101ae5 <check_page+0x427>
f0101acc:	68 30 36 10 f0       	push   $0xf0103630
f0101ad1:	68 3d 37 10 f0       	push   $0xf010373d
f0101ad6:	68 e3 02 00 00       	push   $0x2e3
f0101adb:	68 23 37 10 f0       	push   $0xf0103723
f0101ae0:	e8 a6 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ae5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101aea:	89 f0                	mov    %esi,%eax
f0101aec:	e8 72 f0 ff ff       	call   f0100b63 <check_va2pa>
f0101af1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101af4:	89 d8                	mov    %ebx,%eax
f0101af6:	e8 14 ef ff ff       	call   f0100a0f <page2pa>
f0101afb:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101afe:	74 19                	je     f0101b19 <check_page+0x45b>
f0101b00:	68 c0 35 10 f0       	push   $0xf01035c0
f0101b05:	68 3d 37 10 f0       	push   $0xf010373d
f0101b0a:	68 e4 02 00 00       	push   $0x2e4
f0101b0f:	68 23 37 10 f0       	push   $0xf0103723
f0101b14:	e8 72 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101b19:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b1e:	74 19                	je     f0101b39 <check_page+0x47b>
f0101b20:	68 57 39 10 f0       	push   $0xf0103957
f0101b25:	68 3d 37 10 f0       	push   $0xf010373d
f0101b2a:	68 e5 02 00 00       	push   $0x2e5
f0101b2f:	68 23 37 10 f0       	push   $0xf0103723
f0101b34:	e8 52 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b39:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b3c:	8b 00                	mov    (%eax),%eax
f0101b3e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b41:	a8 04                	test   $0x4,%al
f0101b43:	75 19                	jne    f0101b5e <check_page+0x4a0>
f0101b45:	68 70 36 10 f0       	push   $0xf0103670
f0101b4a:	68 3d 37 10 f0       	push   $0xf010373d
f0101b4f:	68 e6 02 00 00       	push   $0x2e6
f0101b54:	68 23 37 10 f0       	push   $0xf0103723
f0101b59:	e8 2d e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b5e:	f7 c7 04 00 00 00    	test   $0x4,%edi
f0101b64:	75 19                	jne    f0101b7f <check_page+0x4c1>
f0101b66:	68 68 39 10 f0       	push   $0xf0103968
f0101b6b:	68 3d 37 10 f0       	push   $0xf010373d
f0101b70:	68 e7 02 00 00       	push   $0x2e7
f0101b75:	68 23 37 10 f0       	push   $0xf0103723
f0101b7a:	e8 0c e5 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b7f:	6a 02                	push   $0x2
f0101b81:	68 00 10 00 00       	push   $0x1000
f0101b86:	53                   	push   %ebx
f0101b87:	56                   	push   %esi
f0101b88:	e8 1d fb ff ff       	call   f01016aa <page_insert>
f0101b8d:	83 c4 10             	add    $0x10,%esp
f0101b90:	85 c0                	test   %eax,%eax
f0101b92:	74 19                	je     f0101bad <check_page+0x4ef>
f0101b94:	68 84 35 10 f0       	push   $0xf0103584
f0101b99:	68 3d 37 10 f0       	push   $0xf010373d
f0101b9e:	68 ea 02 00 00       	push   $0x2ea
f0101ba3:	68 23 37 10 f0       	push   $0xf0103723
f0101ba8:	e8 de e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101bad:	f6 45 d4 02          	testb  $0x2,-0x2c(%ebp)
f0101bb1:	75 19                	jne    f0101bcc <check_page+0x50e>
f0101bb3:	68 a4 36 10 f0       	push   $0xf01036a4
f0101bb8:	68 3d 37 10 f0       	push   $0xf010373d
f0101bbd:	68 eb 02 00 00       	push   $0x2eb
f0101bc2:	68 23 37 10 f0       	push   $0xf0103723
f0101bc7:	e8 bf e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bcc:	68 d8 36 10 f0       	push   $0xf01036d8
f0101bd1:	68 3d 37 10 f0       	push   $0xf010373d
f0101bd6:	68 ec 02 00 00       	push   $0x2ec
f0101bdb:	68 23 37 10 f0       	push   $0xf0103723
f0101be0:	e8 a6 e4 ff ff       	call   f010008b <_panic>

f0101be5 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101be5:	55                   	push   %ebp
f0101be6:	89 e5                	mov    %esp,%ebp
f0101be8:	53                   	push   %ebx
f0101be9:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f0101bec:	e8 58 ee ff ff       	call   f0100a49 <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101bf1:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101bf6:	e8 b4 ee ff ff       	call   f0100aaf <boot_alloc>
f0101bfb:	a3 48 59 11 f0       	mov    %eax,0xf0115948
	memset(kern_pgdir, 0, PGSIZE);
f0101c00:	83 ec 04             	sub    $0x4,%esp
f0101c03:	68 00 10 00 00       	push   $0x1000
f0101c08:	6a 00                	push   $0x0
f0101c0a:	50                   	push   %eax
f0101c0b:	e8 a8 0b 00 00       	call   f01027b8 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101c10:	8b 1d 48 59 11 f0    	mov    0xf0115948,%ebx
f0101c16:	89 d9                	mov    %ebx,%ecx
f0101c18:	ba 92 00 00 00       	mov    $0x92,%edx
f0101c1d:	b8 23 37 10 f0       	mov    $0xf0103723,%eax
f0101c22:	e8 ac ef ff ff       	call   f0100bd3 <_paddr>
f0101c27:	83 c8 05             	or     $0x5,%eax
f0101c2a:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	//Un PageInfo tiene 4B del PageInfo* +4B del uint16_t = 8B de size

	pages=(struct PageInfo *) boot_alloc(npages //[page]
f0101c30:	a1 44 59 11 f0       	mov    0xf0115944,%eax
f0101c35:	c1 e0 03             	shl    $0x3,%eax
f0101c38:	e8 72 ee ff ff       	call   f0100aaf <boot_alloc>
f0101c3d:	a3 4c 59 11 f0       	mov    %eax,0xf011594c
										 * sizeof(struct PageInfo));//[B/page]

	memset(pages,0,npages*sizeof(struct PageInfo));
f0101c42:	83 c4 0c             	add    $0xc,%esp
f0101c45:	8b 0d 44 59 11 f0    	mov    0xf0115944,%ecx
f0101c4b:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101c52:	52                   	push   %edx
f0101c53:	6a 00                	push   $0x0
f0101c55:	50                   	push   %eax
f0101c56:	e8 5d 0b 00 00       	call   f01027b8 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101c5b:	e8 15 f4 ff ff       	call   f0101075 <page_init>

	check_page_free_list(1);
f0101c60:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c65:	e8 93 f1 ff ff       	call   f0100dfd <check_page_free_list>
	check_page_alloc();
f0101c6a:	e8 1b f5 ff ff       	call   f010118a <check_page_alloc>
	check_page();
f0101c6f:	e8 4a fa ff ff       	call   f01016be <check_page>

f0101c74 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101c74:	55                   	push   %ebp
f0101c75:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0101c77:	5d                   	pop    %ebp
f0101c78:	c3                   	ret    

f0101c79 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101c79:	55                   	push   %ebp
f0101c7a:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f0101c7c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c7f:	e8 6b ed ff ff       	call   f01009ef <invlpg>
}
f0101c84:	5d                   	pop    %ebp
f0101c85:	c3                   	ret    

f0101c86 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0101c86:	55                   	push   %ebp
f0101c87:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0101c89:	89 c2                	mov    %eax,%edx
f0101c8b:	ec                   	in     (%dx),%al
	return data;
}
f0101c8c:	5d                   	pop    %ebp
f0101c8d:	c3                   	ret    

f0101c8e <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0101c8e:	55                   	push   %ebp
f0101c8f:	89 e5                	mov    %esp,%ebp
f0101c91:	89 c1                	mov    %eax,%ecx
f0101c93:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101c95:	89 ca                	mov    %ecx,%edx
f0101c97:	ee                   	out    %al,(%dx)
}
f0101c98:	5d                   	pop    %ebp
f0101c99:	c3                   	ret    

f0101c9a <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0101c9a:	55                   	push   %ebp
f0101c9b:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0101c9d:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0101ca1:	b8 70 00 00 00       	mov    $0x70,%eax
f0101ca6:	e8 e3 ff ff ff       	call   f0101c8e <outb>
	return inb(IO_RTC+1);
f0101cab:	b8 71 00 00 00       	mov    $0x71,%eax
f0101cb0:	e8 d1 ff ff ff       	call   f0101c86 <inb>
f0101cb5:	0f b6 c0             	movzbl %al,%eax
}
f0101cb8:	5d                   	pop    %ebp
f0101cb9:	c3                   	ret    

f0101cba <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101cba:	55                   	push   %ebp
f0101cbb:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0101cbd:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0101cc1:	b8 70 00 00 00       	mov    $0x70,%eax
f0101cc6:	e8 c3 ff ff ff       	call   f0101c8e <outb>
	outb(IO_RTC+1, datum);
f0101ccb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0101ccf:	b8 71 00 00 00       	mov    $0x71,%eax
f0101cd4:	e8 b5 ff ff ff       	call   f0101c8e <outb>
}
f0101cd9:	5d                   	pop    %ebp
f0101cda:	c3                   	ret    

f0101cdb <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101cdb:	55                   	push   %ebp
f0101cdc:	89 e5                	mov    %esp,%ebp
f0101cde:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0101ce1:	ff 75 08             	pushl  0x8(%ebp)
f0101ce4:	e8 1c ea ff ff       	call   f0100705 <cputchar>
	*cnt++;
}
f0101ce9:	83 c4 10             	add    $0x10,%esp
f0101cec:	c9                   	leave  
f0101ced:	c3                   	ret    

f0101cee <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101cee:	55                   	push   %ebp
f0101cef:	89 e5                	mov    %esp,%ebp
f0101cf1:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0101cf4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101cfb:	ff 75 0c             	pushl  0xc(%ebp)
f0101cfe:	ff 75 08             	pushl  0x8(%ebp)
f0101d01:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101d04:	50                   	push   %eax
f0101d05:	68 db 1c 10 f0       	push   $0xf0101cdb
f0101d0a:	e8 82 04 00 00       	call   f0102191 <vprintfmt>
	return cnt;
}
f0101d0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d12:	c9                   	leave  
f0101d13:	c3                   	ret    

f0101d14 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101d14:	55                   	push   %ebp
f0101d15:	89 e5                	mov    %esp,%ebp
f0101d17:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101d1a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101d1d:	50                   	push   %eax
f0101d1e:	ff 75 08             	pushl  0x8(%ebp)
f0101d21:	e8 c8 ff ff ff       	call   f0101cee <vcprintf>
	va_end(ap);

	return cnt;
}
f0101d26:	c9                   	leave  
f0101d27:	c3                   	ret    

f0101d28 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101d28:	55                   	push   %ebp
f0101d29:	89 e5                	mov    %esp,%ebp
f0101d2b:	57                   	push   %edi
f0101d2c:	56                   	push   %esi
f0101d2d:	53                   	push   %ebx
f0101d2e:	83 ec 14             	sub    $0x14,%esp
f0101d31:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101d34:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101d37:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101d3a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101d3d:	8b 1a                	mov    (%edx),%ebx
f0101d3f:	8b 01                	mov    (%ecx),%eax
f0101d41:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101d44:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101d4b:	eb 7f                	jmp    f0101dcc <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0101d4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101d50:	01 d8                	add    %ebx,%eax
f0101d52:	89 c6                	mov    %eax,%esi
f0101d54:	c1 ee 1f             	shr    $0x1f,%esi
f0101d57:	01 c6                	add    %eax,%esi
f0101d59:	d1 fe                	sar    %esi
f0101d5b:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101d5e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101d61:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0101d64:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101d66:	eb 03                	jmp    f0101d6b <stab_binsearch+0x43>
			m--;
f0101d68:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101d6b:	39 c3                	cmp    %eax,%ebx
f0101d6d:	7f 0d                	jg     f0101d7c <stab_binsearch+0x54>
f0101d6f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101d73:	83 ea 0c             	sub    $0xc,%edx
f0101d76:	39 f9                	cmp    %edi,%ecx
f0101d78:	75 ee                	jne    f0101d68 <stab_binsearch+0x40>
f0101d7a:	eb 05                	jmp    f0101d81 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0101d7c:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0101d7f:	eb 4b                	jmp    f0101dcc <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101d81:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101d84:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101d87:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0101d8b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101d8e:	76 11                	jbe    f0101da1 <stab_binsearch+0x79>
			*region_left = m;
f0101d90:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101d93:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0101d95:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101d98:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101d9f:	eb 2b                	jmp    f0101dcc <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0101da1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101da4:	73 14                	jae    f0101dba <stab_binsearch+0x92>
			*region_right = m - 1;
f0101da6:	83 e8 01             	sub    $0x1,%eax
f0101da9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101dac:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101daf:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101db1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101db8:	eb 12                	jmp    f0101dcc <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101dba:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101dbd:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0101dbf:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0101dc3:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101dc5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0101dcc:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0101dcf:	0f 8e 78 ff ff ff    	jle    f0101d4d <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101dd5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101dd9:	75 0f                	jne    f0101dea <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0101ddb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101dde:	8b 00                	mov    (%eax),%eax
f0101de0:	83 e8 01             	sub    $0x1,%eax
f0101de3:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101de6:	89 06                	mov    %eax,(%esi)
f0101de8:	eb 2c                	jmp    f0101e16 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101dea:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ded:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101def:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101df2:	8b 0e                	mov    (%esi),%ecx
f0101df4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101df7:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101dfa:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101dfd:	eb 03                	jmp    f0101e02 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101dff:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101e02:	39 c8                	cmp    %ecx,%eax
f0101e04:	7e 0b                	jle    f0101e11 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0101e06:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0101e0a:	83 ea 0c             	sub    $0xc,%edx
f0101e0d:	39 df                	cmp    %ebx,%edi
f0101e0f:	75 ee                	jne    f0101dff <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101e11:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101e14:	89 06                	mov    %eax,(%esi)
	}
}
f0101e16:	83 c4 14             	add    $0x14,%esp
f0101e19:	5b                   	pop    %ebx
f0101e1a:	5e                   	pop    %esi
f0101e1b:	5f                   	pop    %edi
f0101e1c:	5d                   	pop    %ebp
f0101e1d:	c3                   	ret    

f0101e1e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101e1e:	55                   	push   %ebp
f0101e1f:	89 e5                	mov    %esp,%ebp
f0101e21:	57                   	push   %edi
f0101e22:	56                   	push   %esi
f0101e23:	53                   	push   %ebx
f0101e24:	83 ec 3c             	sub    $0x3c,%esp
f0101e27:	8b 75 08             	mov    0x8(%ebp),%esi
f0101e2a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101e2d:	c7 03 7e 39 10 f0    	movl   $0xf010397e,(%ebx)
	info->eip_line = 0;
f0101e33:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0101e3a:	c7 43 08 7e 39 10 f0 	movl   $0xf010397e,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101e41:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0101e48:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101e4b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101e52:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101e58:	76 11                	jbe    f0101e6b <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101e5a:	b8 11 af 10 f0       	mov    $0xf010af11,%eax
f0101e5f:	3d c1 8f 10 f0       	cmp    $0xf0108fc1,%eax
f0101e64:	77 19                	ja     f0101e7f <debuginfo_eip+0x61>
f0101e66:	e9 af 01 00 00       	jmp    f010201a <debuginfo_eip+0x1fc>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101e6b:	83 ec 04             	sub    $0x4,%esp
f0101e6e:	68 88 39 10 f0       	push   $0xf0103988
f0101e73:	6a 7f                	push   $0x7f
f0101e75:	68 95 39 10 f0       	push   $0xf0103995
f0101e7a:	e8 0c e2 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101e7f:	80 3d 10 af 10 f0 00 	cmpb   $0x0,0xf010af10
f0101e86:	0f 85 95 01 00 00    	jne    f0102021 <debuginfo_eip+0x203>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0101e8c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101e93:	b8 c0 8f 10 f0       	mov    $0xf0108fc0,%eax
f0101e98:	2d b4 3b 10 f0       	sub    $0xf0103bb4,%eax
f0101e9d:	c1 f8 02             	sar    $0x2,%eax
f0101ea0:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0101ea6:	83 e8 01             	sub    $0x1,%eax
f0101ea9:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101eac:	83 ec 08             	sub    $0x8,%esp
f0101eaf:	56                   	push   %esi
f0101eb0:	6a 64                	push   $0x64
f0101eb2:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101eb5:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101eb8:	b8 b4 3b 10 f0       	mov    $0xf0103bb4,%eax
f0101ebd:	e8 66 fe ff ff       	call   f0101d28 <stab_binsearch>
	if (lfile == 0)
f0101ec2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101ec5:	83 c4 10             	add    $0x10,%esp
f0101ec8:	85 c0                	test   %eax,%eax
f0101eca:	0f 84 58 01 00 00    	je     f0102028 <debuginfo_eip+0x20a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101ed0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101ed3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101ed6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101ed9:	83 ec 08             	sub    $0x8,%esp
f0101edc:	56                   	push   %esi
f0101edd:	6a 24                	push   $0x24
f0101edf:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101ee2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101ee5:	b8 b4 3b 10 f0       	mov    $0xf0103bb4,%eax
f0101eea:	e8 39 fe ff ff       	call   f0101d28 <stab_binsearch>

	if (lfun <= rfun) {
f0101eef:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101ef2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101ef5:	83 c4 10             	add    $0x10,%esp
f0101ef8:	39 d0                	cmp    %edx,%eax
f0101efa:	7f 40                	jg     f0101f3c <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101efc:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0101eff:	c1 e1 02             	shl    $0x2,%ecx
f0101f02:	8d b9 b4 3b 10 f0    	lea    -0xfefc44c(%ecx),%edi
f0101f08:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0101f0b:	8b b9 b4 3b 10 f0    	mov    -0xfefc44c(%ecx),%edi
f0101f11:	b9 11 af 10 f0       	mov    $0xf010af11,%ecx
f0101f16:	81 e9 c1 8f 10 f0    	sub    $0xf0108fc1,%ecx
f0101f1c:	39 cf                	cmp    %ecx,%edi
f0101f1e:	73 09                	jae    f0101f29 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101f20:	81 c7 c1 8f 10 f0    	add    $0xf0108fc1,%edi
f0101f26:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101f29:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0101f2c:	8b 4f 08             	mov    0x8(%edi),%ecx
f0101f2f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0101f32:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0101f34:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0101f37:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101f3a:	eb 0f                	jmp    f0101f4b <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101f3c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101f3f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101f42:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0101f45:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101f48:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101f4b:	83 ec 08             	sub    $0x8,%esp
f0101f4e:	6a 3a                	push   $0x3a
f0101f50:	ff 73 08             	pushl  0x8(%ebx)
f0101f53:	e8 44 08 00 00       	call   f010279c <strfind>
f0101f58:	2b 43 08             	sub    0x8(%ebx),%eax
f0101f5b:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101f5e:	83 c4 08             	add    $0x8,%esp
f0101f61:	56                   	push   %esi
f0101f62:	6a 44                	push   $0x44
f0101f64:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101f67:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101f6a:	b8 b4 3b 10 f0       	mov    $0xf0103bb4,%eax
f0101f6f:	e8 b4 fd ff ff       	call   f0101d28 <stab_binsearch>
	if (lline <= rline) {
f0101f74:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f77:	83 c4 10             	add    $0x10,%esp
f0101f7a:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0101f7d:	7f 0e                	jg     f0101f8d <debuginfo_eip+0x16f>
		info->eip_line = stabs[lline].n_desc;
f0101f7f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101f82:	0f b7 14 95 ba 3b 10 	movzwl -0xfefc446(,%edx,4),%edx
f0101f89:	f0 
f0101f8a:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101f8d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101f90:	89 c2                	mov    %eax,%edx
f0101f92:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0101f95:	8d 04 85 b4 3b 10 f0 	lea    -0xfefc44c(,%eax,4),%eax
f0101f9c:	eb 06                	jmp    f0101fa4 <debuginfo_eip+0x186>
f0101f9e:	83 ea 01             	sub    $0x1,%edx
f0101fa1:	83 e8 0c             	sub    $0xc,%eax
f0101fa4:	39 d7                	cmp    %edx,%edi
f0101fa6:	7f 34                	jg     f0101fdc <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0101fa8:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0101fac:	80 f9 84             	cmp    $0x84,%cl
f0101faf:	74 0b                	je     f0101fbc <debuginfo_eip+0x19e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101fb1:	80 f9 64             	cmp    $0x64,%cl
f0101fb4:	75 e8                	jne    f0101f9e <debuginfo_eip+0x180>
f0101fb6:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0101fba:	74 e2                	je     f0101f9e <debuginfo_eip+0x180>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101fbc:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0101fbf:	8b 14 85 b4 3b 10 f0 	mov    -0xfefc44c(,%eax,4),%edx
f0101fc6:	b8 11 af 10 f0       	mov    $0xf010af11,%eax
f0101fcb:	2d c1 8f 10 f0       	sub    $0xf0108fc1,%eax
f0101fd0:	39 c2                	cmp    %eax,%edx
f0101fd2:	73 08                	jae    f0101fdc <debuginfo_eip+0x1be>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101fd4:	81 c2 c1 8f 10 f0    	add    $0xf0108fc1,%edx
f0101fda:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101fdc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101fdf:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101fe2:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101fe7:	39 f2                	cmp    %esi,%edx
f0101fe9:	7d 49                	jge    f0102034 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
f0101feb:	83 c2 01             	add    $0x1,%edx
f0101fee:	89 d0                	mov    %edx,%eax
f0101ff0:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0101ff3:	8d 14 95 b4 3b 10 f0 	lea    -0xfefc44c(,%edx,4),%edx
f0101ffa:	eb 04                	jmp    f0102000 <debuginfo_eip+0x1e2>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0101ffc:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102000:	39 c6                	cmp    %eax,%esi
f0102002:	7e 2b                	jle    f010202f <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102004:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102008:	83 c0 01             	add    $0x1,%eax
f010200b:	83 c2 0c             	add    $0xc,%edx
f010200e:	80 f9 a0             	cmp    $0xa0,%cl
f0102011:	74 e9                	je     f0101ffc <debuginfo_eip+0x1de>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102013:	b8 00 00 00 00       	mov    $0x0,%eax
f0102018:	eb 1a                	jmp    f0102034 <debuginfo_eip+0x216>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010201a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010201f:	eb 13                	jmp    f0102034 <debuginfo_eip+0x216>
f0102021:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102026:	eb 0c                	jmp    f0102034 <debuginfo_eip+0x216>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102028:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010202d:	eb 05                	jmp    f0102034 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010202f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102034:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102037:	5b                   	pop    %ebx
f0102038:	5e                   	pop    %esi
f0102039:	5f                   	pop    %edi
f010203a:	5d                   	pop    %ebp
f010203b:	c3                   	ret    

f010203c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010203c:	55                   	push   %ebp
f010203d:	89 e5                	mov    %esp,%ebp
f010203f:	57                   	push   %edi
f0102040:	56                   	push   %esi
f0102041:	53                   	push   %ebx
f0102042:	83 ec 1c             	sub    $0x1c,%esp
f0102045:	89 c7                	mov    %eax,%edi
f0102047:	89 d6                	mov    %edx,%esi
f0102049:	8b 45 08             	mov    0x8(%ebp),%eax
f010204c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010204f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102052:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102055:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102058:	bb 00 00 00 00       	mov    $0x0,%ebx
f010205d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102060:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102063:	39 d3                	cmp    %edx,%ebx
f0102065:	72 05                	jb     f010206c <printnum+0x30>
f0102067:	39 45 10             	cmp    %eax,0x10(%ebp)
f010206a:	77 45                	ja     f01020b1 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010206c:	83 ec 0c             	sub    $0xc,%esp
f010206f:	ff 75 18             	pushl  0x18(%ebp)
f0102072:	8b 45 14             	mov    0x14(%ebp),%eax
f0102075:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102078:	53                   	push   %ebx
f0102079:	ff 75 10             	pushl  0x10(%ebp)
f010207c:	83 ec 08             	sub    $0x8,%esp
f010207f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102082:	ff 75 e0             	pushl  -0x20(%ebp)
f0102085:	ff 75 dc             	pushl  -0x24(%ebp)
f0102088:	ff 75 d8             	pushl  -0x28(%ebp)
f010208b:	e8 30 09 00 00       	call   f01029c0 <__udivdi3>
f0102090:	83 c4 18             	add    $0x18,%esp
f0102093:	52                   	push   %edx
f0102094:	50                   	push   %eax
f0102095:	89 f2                	mov    %esi,%edx
f0102097:	89 f8                	mov    %edi,%eax
f0102099:	e8 9e ff ff ff       	call   f010203c <printnum>
f010209e:	83 c4 20             	add    $0x20,%esp
f01020a1:	eb 18                	jmp    f01020bb <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01020a3:	83 ec 08             	sub    $0x8,%esp
f01020a6:	56                   	push   %esi
f01020a7:	ff 75 18             	pushl  0x18(%ebp)
f01020aa:	ff d7                	call   *%edi
f01020ac:	83 c4 10             	add    $0x10,%esp
f01020af:	eb 03                	jmp    f01020b4 <printnum+0x78>
f01020b1:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01020b4:	83 eb 01             	sub    $0x1,%ebx
f01020b7:	85 db                	test   %ebx,%ebx
f01020b9:	7f e8                	jg     f01020a3 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01020bb:	83 ec 08             	sub    $0x8,%esp
f01020be:	56                   	push   %esi
f01020bf:	83 ec 04             	sub    $0x4,%esp
f01020c2:	ff 75 e4             	pushl  -0x1c(%ebp)
f01020c5:	ff 75 e0             	pushl  -0x20(%ebp)
f01020c8:	ff 75 dc             	pushl  -0x24(%ebp)
f01020cb:	ff 75 d8             	pushl  -0x28(%ebp)
f01020ce:	e8 1d 0a 00 00       	call   f0102af0 <__umoddi3>
f01020d3:	83 c4 14             	add    $0x14,%esp
f01020d6:	0f be 80 a3 39 10 f0 	movsbl -0xfefc65d(%eax),%eax
f01020dd:	50                   	push   %eax
f01020de:	ff d7                	call   *%edi
}
f01020e0:	83 c4 10             	add    $0x10,%esp
f01020e3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01020e6:	5b                   	pop    %ebx
f01020e7:	5e                   	pop    %esi
f01020e8:	5f                   	pop    %edi
f01020e9:	5d                   	pop    %ebp
f01020ea:	c3                   	ret    

f01020eb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01020eb:	55                   	push   %ebp
f01020ec:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01020ee:	83 fa 01             	cmp    $0x1,%edx
f01020f1:	7e 0e                	jle    f0102101 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01020f3:	8b 10                	mov    (%eax),%edx
f01020f5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01020f8:	89 08                	mov    %ecx,(%eax)
f01020fa:	8b 02                	mov    (%edx),%eax
f01020fc:	8b 52 04             	mov    0x4(%edx),%edx
f01020ff:	eb 22                	jmp    f0102123 <getuint+0x38>
	else if (lflag)
f0102101:	85 d2                	test   %edx,%edx
f0102103:	74 10                	je     f0102115 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102105:	8b 10                	mov    (%eax),%edx
f0102107:	8d 4a 04             	lea    0x4(%edx),%ecx
f010210a:	89 08                	mov    %ecx,(%eax)
f010210c:	8b 02                	mov    (%edx),%eax
f010210e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102113:	eb 0e                	jmp    f0102123 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102115:	8b 10                	mov    (%eax),%edx
f0102117:	8d 4a 04             	lea    0x4(%edx),%ecx
f010211a:	89 08                	mov    %ecx,(%eax)
f010211c:	8b 02                	mov    (%edx),%eax
f010211e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102123:	5d                   	pop    %ebp
f0102124:	c3                   	ret    

f0102125 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0102125:	55                   	push   %ebp
f0102126:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102128:	83 fa 01             	cmp    $0x1,%edx
f010212b:	7e 0e                	jle    f010213b <getint+0x16>
		return va_arg(*ap, long long);
f010212d:	8b 10                	mov    (%eax),%edx
f010212f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102132:	89 08                	mov    %ecx,(%eax)
f0102134:	8b 02                	mov    (%edx),%eax
f0102136:	8b 52 04             	mov    0x4(%edx),%edx
f0102139:	eb 1a                	jmp    f0102155 <getint+0x30>
	else if (lflag)
f010213b:	85 d2                	test   %edx,%edx
f010213d:	74 0c                	je     f010214b <getint+0x26>
		return va_arg(*ap, long);
f010213f:	8b 10                	mov    (%eax),%edx
f0102141:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102144:	89 08                	mov    %ecx,(%eax)
f0102146:	8b 02                	mov    (%edx),%eax
f0102148:	99                   	cltd   
f0102149:	eb 0a                	jmp    f0102155 <getint+0x30>
	else
		return va_arg(*ap, int);
f010214b:	8b 10                	mov    (%eax),%edx
f010214d:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102150:	89 08                	mov    %ecx,(%eax)
f0102152:	8b 02                	mov    (%edx),%eax
f0102154:	99                   	cltd   
}
f0102155:	5d                   	pop    %ebp
f0102156:	c3                   	ret    

f0102157 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102157:	55                   	push   %ebp
f0102158:	89 e5                	mov    %esp,%ebp
f010215a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010215d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102161:	8b 10                	mov    (%eax),%edx
f0102163:	3b 50 04             	cmp    0x4(%eax),%edx
f0102166:	73 0a                	jae    f0102172 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102168:	8d 4a 01             	lea    0x1(%edx),%ecx
f010216b:	89 08                	mov    %ecx,(%eax)
f010216d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102170:	88 02                	mov    %al,(%edx)
}
f0102172:	5d                   	pop    %ebp
f0102173:	c3                   	ret    

f0102174 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102174:	55                   	push   %ebp
f0102175:	89 e5                	mov    %esp,%ebp
f0102177:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010217a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010217d:	50                   	push   %eax
f010217e:	ff 75 10             	pushl  0x10(%ebp)
f0102181:	ff 75 0c             	pushl  0xc(%ebp)
f0102184:	ff 75 08             	pushl  0x8(%ebp)
f0102187:	e8 05 00 00 00       	call   f0102191 <vprintfmt>
	va_end(ap);
}
f010218c:	83 c4 10             	add    $0x10,%esp
f010218f:	c9                   	leave  
f0102190:	c3                   	ret    

f0102191 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102191:	55                   	push   %ebp
f0102192:	89 e5                	mov    %esp,%ebp
f0102194:	57                   	push   %edi
f0102195:	56                   	push   %esi
f0102196:	53                   	push   %ebx
f0102197:	83 ec 2c             	sub    $0x2c,%esp
f010219a:	8b 75 08             	mov    0x8(%ebp),%esi
f010219d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01021a0:	8b 7d 10             	mov    0x10(%ebp),%edi
f01021a3:	eb 12                	jmp    f01021b7 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01021a5:	85 c0                	test   %eax,%eax
f01021a7:	0f 84 44 03 00 00    	je     f01024f1 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f01021ad:	83 ec 08             	sub    $0x8,%esp
f01021b0:	53                   	push   %ebx
f01021b1:	50                   	push   %eax
f01021b2:	ff d6                	call   *%esi
f01021b4:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01021b7:	83 c7 01             	add    $0x1,%edi
f01021ba:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01021be:	83 f8 25             	cmp    $0x25,%eax
f01021c1:	75 e2                	jne    f01021a5 <vprintfmt+0x14>
f01021c3:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01021c7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01021ce:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01021d5:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01021dc:	ba 00 00 00 00       	mov    $0x0,%edx
f01021e1:	eb 07                	jmp    f01021ea <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01021e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01021e6:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01021ea:	8d 47 01             	lea    0x1(%edi),%eax
f01021ed:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01021f0:	0f b6 07             	movzbl (%edi),%eax
f01021f3:	0f b6 c8             	movzbl %al,%ecx
f01021f6:	83 e8 23             	sub    $0x23,%eax
f01021f9:	3c 55                	cmp    $0x55,%al
f01021fb:	0f 87 d5 02 00 00    	ja     f01024d6 <vprintfmt+0x345>
f0102201:	0f b6 c0             	movzbl %al,%eax
f0102204:	ff 24 85 30 3a 10 f0 	jmp    *-0xfefc5d0(,%eax,4)
f010220b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010220e:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102212:	eb d6                	jmp    f01021ea <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102214:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102217:	b8 00 00 00 00       	mov    $0x0,%eax
f010221c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f010221f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102222:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102226:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102229:	8d 51 d0             	lea    -0x30(%ecx),%edx
f010222c:	83 fa 09             	cmp    $0x9,%edx
f010222f:	77 39                	ja     f010226a <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102231:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102234:	eb e9                	jmp    f010221f <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102236:	8b 45 14             	mov    0x14(%ebp),%eax
f0102239:	8d 48 04             	lea    0x4(%eax),%ecx
f010223c:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010223f:	8b 00                	mov    (%eax),%eax
f0102241:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102244:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102247:	eb 27                	jmp    f0102270 <vprintfmt+0xdf>
f0102249:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010224c:	85 c0                	test   %eax,%eax
f010224e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102253:	0f 49 c8             	cmovns %eax,%ecx
f0102256:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102259:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010225c:	eb 8c                	jmp    f01021ea <vprintfmt+0x59>
f010225e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102261:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102268:	eb 80                	jmp    f01021ea <vprintfmt+0x59>
f010226a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010226d:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102270:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102274:	0f 89 70 ff ff ff    	jns    f01021ea <vprintfmt+0x59>
				width = precision, precision = -1;
f010227a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010227d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102280:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102287:	e9 5e ff ff ff       	jmp    f01021ea <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010228c:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010228f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102292:	e9 53 ff ff ff       	jmp    f01021ea <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102297:	8b 45 14             	mov    0x14(%ebp),%eax
f010229a:	8d 50 04             	lea    0x4(%eax),%edx
f010229d:	89 55 14             	mov    %edx,0x14(%ebp)
f01022a0:	83 ec 08             	sub    $0x8,%esp
f01022a3:	53                   	push   %ebx
f01022a4:	ff 30                	pushl  (%eax)
f01022a6:	ff d6                	call   *%esi
			break;
f01022a8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01022ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01022ae:	e9 04 ff ff ff       	jmp    f01021b7 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01022b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01022b6:	8d 50 04             	lea    0x4(%eax),%edx
f01022b9:	89 55 14             	mov    %edx,0x14(%ebp)
f01022bc:	8b 00                	mov    (%eax),%eax
f01022be:	99                   	cltd   
f01022bf:	31 d0                	xor    %edx,%eax
f01022c1:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01022c3:	83 f8 06             	cmp    $0x6,%eax
f01022c6:	7f 0b                	jg     f01022d3 <vprintfmt+0x142>
f01022c8:	8b 14 85 88 3b 10 f0 	mov    -0xfefc478(,%eax,4),%edx
f01022cf:	85 d2                	test   %edx,%edx
f01022d1:	75 18                	jne    f01022eb <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f01022d3:	50                   	push   %eax
f01022d4:	68 bb 39 10 f0       	push   $0xf01039bb
f01022d9:	53                   	push   %ebx
f01022da:	56                   	push   %esi
f01022db:	e8 94 fe ff ff       	call   f0102174 <printfmt>
f01022e0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01022e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01022e6:	e9 cc fe ff ff       	jmp    f01021b7 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01022eb:	52                   	push   %edx
f01022ec:	68 4f 37 10 f0       	push   $0xf010374f
f01022f1:	53                   	push   %ebx
f01022f2:	56                   	push   %esi
f01022f3:	e8 7c fe ff ff       	call   f0102174 <printfmt>
f01022f8:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01022fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01022fe:	e9 b4 fe ff ff       	jmp    f01021b7 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102303:	8b 45 14             	mov    0x14(%ebp),%eax
f0102306:	8d 50 04             	lea    0x4(%eax),%edx
f0102309:	89 55 14             	mov    %edx,0x14(%ebp)
f010230c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010230e:	85 ff                	test   %edi,%edi
f0102310:	b8 b4 39 10 f0       	mov    $0xf01039b4,%eax
f0102315:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102318:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010231c:	0f 8e 94 00 00 00    	jle    f01023b6 <vprintfmt+0x225>
f0102322:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102326:	0f 84 98 00 00 00    	je     f01023c4 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f010232c:	83 ec 08             	sub    $0x8,%esp
f010232f:	ff 75 d0             	pushl  -0x30(%ebp)
f0102332:	57                   	push   %edi
f0102333:	e8 1a 03 00 00       	call   f0102652 <strnlen>
f0102338:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010233b:	29 c1                	sub    %eax,%ecx
f010233d:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102340:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102343:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102347:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010234a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010234d:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010234f:	eb 0f                	jmp    f0102360 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102351:	83 ec 08             	sub    $0x8,%esp
f0102354:	53                   	push   %ebx
f0102355:	ff 75 e0             	pushl  -0x20(%ebp)
f0102358:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010235a:	83 ef 01             	sub    $0x1,%edi
f010235d:	83 c4 10             	add    $0x10,%esp
f0102360:	85 ff                	test   %edi,%edi
f0102362:	7f ed                	jg     f0102351 <vprintfmt+0x1c0>
f0102364:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102367:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010236a:	85 c9                	test   %ecx,%ecx
f010236c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102371:	0f 49 c1             	cmovns %ecx,%eax
f0102374:	29 c1                	sub    %eax,%ecx
f0102376:	89 75 08             	mov    %esi,0x8(%ebp)
f0102379:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010237c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010237f:	89 cb                	mov    %ecx,%ebx
f0102381:	eb 4d                	jmp    f01023d0 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102383:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102387:	74 1b                	je     f01023a4 <vprintfmt+0x213>
f0102389:	0f be c0             	movsbl %al,%eax
f010238c:	83 e8 20             	sub    $0x20,%eax
f010238f:	83 f8 5e             	cmp    $0x5e,%eax
f0102392:	76 10                	jbe    f01023a4 <vprintfmt+0x213>
					putch('?', putdat);
f0102394:	83 ec 08             	sub    $0x8,%esp
f0102397:	ff 75 0c             	pushl  0xc(%ebp)
f010239a:	6a 3f                	push   $0x3f
f010239c:	ff 55 08             	call   *0x8(%ebp)
f010239f:	83 c4 10             	add    $0x10,%esp
f01023a2:	eb 0d                	jmp    f01023b1 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f01023a4:	83 ec 08             	sub    $0x8,%esp
f01023a7:	ff 75 0c             	pushl  0xc(%ebp)
f01023aa:	52                   	push   %edx
f01023ab:	ff 55 08             	call   *0x8(%ebp)
f01023ae:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01023b1:	83 eb 01             	sub    $0x1,%ebx
f01023b4:	eb 1a                	jmp    f01023d0 <vprintfmt+0x23f>
f01023b6:	89 75 08             	mov    %esi,0x8(%ebp)
f01023b9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01023bc:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01023bf:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01023c2:	eb 0c                	jmp    f01023d0 <vprintfmt+0x23f>
f01023c4:	89 75 08             	mov    %esi,0x8(%ebp)
f01023c7:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01023ca:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01023cd:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01023d0:	83 c7 01             	add    $0x1,%edi
f01023d3:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01023d7:	0f be d0             	movsbl %al,%edx
f01023da:	85 d2                	test   %edx,%edx
f01023dc:	74 23                	je     f0102401 <vprintfmt+0x270>
f01023de:	85 f6                	test   %esi,%esi
f01023e0:	78 a1                	js     f0102383 <vprintfmt+0x1f2>
f01023e2:	83 ee 01             	sub    $0x1,%esi
f01023e5:	79 9c                	jns    f0102383 <vprintfmt+0x1f2>
f01023e7:	89 df                	mov    %ebx,%edi
f01023e9:	8b 75 08             	mov    0x8(%ebp),%esi
f01023ec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01023ef:	eb 18                	jmp    f0102409 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01023f1:	83 ec 08             	sub    $0x8,%esp
f01023f4:	53                   	push   %ebx
f01023f5:	6a 20                	push   $0x20
f01023f7:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01023f9:	83 ef 01             	sub    $0x1,%edi
f01023fc:	83 c4 10             	add    $0x10,%esp
f01023ff:	eb 08                	jmp    f0102409 <vprintfmt+0x278>
f0102401:	89 df                	mov    %ebx,%edi
f0102403:	8b 75 08             	mov    0x8(%ebp),%esi
f0102406:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102409:	85 ff                	test   %edi,%edi
f010240b:	7f e4                	jg     f01023f1 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010240d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102410:	e9 a2 fd ff ff       	jmp    f01021b7 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102415:	8d 45 14             	lea    0x14(%ebp),%eax
f0102418:	e8 08 fd ff ff       	call   f0102125 <getint>
f010241d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102420:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102423:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102428:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010242c:	79 74                	jns    f01024a2 <vprintfmt+0x311>
				putch('-', putdat);
f010242e:	83 ec 08             	sub    $0x8,%esp
f0102431:	53                   	push   %ebx
f0102432:	6a 2d                	push   $0x2d
f0102434:	ff d6                	call   *%esi
				num = -(long long) num;
f0102436:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102439:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010243c:	f7 d8                	neg    %eax
f010243e:	83 d2 00             	adc    $0x0,%edx
f0102441:	f7 da                	neg    %edx
f0102443:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102446:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010244b:	eb 55                	jmp    f01024a2 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010244d:	8d 45 14             	lea    0x14(%ebp),%eax
f0102450:	e8 96 fc ff ff       	call   f01020eb <getuint>
			base = 10;
f0102455:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010245a:	eb 46                	jmp    f01024a2 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f010245c:	8d 45 14             	lea    0x14(%ebp),%eax
f010245f:	e8 87 fc ff ff       	call   f01020eb <getuint>
			base = 8;
f0102464:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102469:	eb 37                	jmp    f01024a2 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f010246b:	83 ec 08             	sub    $0x8,%esp
f010246e:	53                   	push   %ebx
f010246f:	6a 30                	push   $0x30
f0102471:	ff d6                	call   *%esi
			putch('x', putdat);
f0102473:	83 c4 08             	add    $0x8,%esp
f0102476:	53                   	push   %ebx
f0102477:	6a 78                	push   $0x78
f0102479:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010247b:	8b 45 14             	mov    0x14(%ebp),%eax
f010247e:	8d 50 04             	lea    0x4(%eax),%edx
f0102481:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102484:	8b 00                	mov    (%eax),%eax
f0102486:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010248b:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010248e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102493:	eb 0d                	jmp    f01024a2 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102495:	8d 45 14             	lea    0x14(%ebp),%eax
f0102498:	e8 4e fc ff ff       	call   f01020eb <getuint>
			base = 16;
f010249d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01024a2:	83 ec 0c             	sub    $0xc,%esp
f01024a5:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01024a9:	57                   	push   %edi
f01024aa:	ff 75 e0             	pushl  -0x20(%ebp)
f01024ad:	51                   	push   %ecx
f01024ae:	52                   	push   %edx
f01024af:	50                   	push   %eax
f01024b0:	89 da                	mov    %ebx,%edx
f01024b2:	89 f0                	mov    %esi,%eax
f01024b4:	e8 83 fb ff ff       	call   f010203c <printnum>
			break;
f01024b9:	83 c4 20             	add    $0x20,%esp
f01024bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01024bf:	e9 f3 fc ff ff       	jmp    f01021b7 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01024c4:	83 ec 08             	sub    $0x8,%esp
f01024c7:	53                   	push   %ebx
f01024c8:	51                   	push   %ecx
f01024c9:	ff d6                	call   *%esi
			break;
f01024cb:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01024ce:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01024d1:	e9 e1 fc ff ff       	jmp    f01021b7 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01024d6:	83 ec 08             	sub    $0x8,%esp
f01024d9:	53                   	push   %ebx
f01024da:	6a 25                	push   $0x25
f01024dc:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01024de:	83 c4 10             	add    $0x10,%esp
f01024e1:	eb 03                	jmp    f01024e6 <vprintfmt+0x355>
f01024e3:	83 ef 01             	sub    $0x1,%edi
f01024e6:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01024ea:	75 f7                	jne    f01024e3 <vprintfmt+0x352>
f01024ec:	e9 c6 fc ff ff       	jmp    f01021b7 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01024f1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01024f4:	5b                   	pop    %ebx
f01024f5:	5e                   	pop    %esi
f01024f6:	5f                   	pop    %edi
f01024f7:	5d                   	pop    %ebp
f01024f8:	c3                   	ret    

f01024f9 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01024f9:	55                   	push   %ebp
f01024fa:	89 e5                	mov    %esp,%ebp
f01024fc:	83 ec 18             	sub    $0x18,%esp
f01024ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0102502:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102505:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102508:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010250c:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010250f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102516:	85 c0                	test   %eax,%eax
f0102518:	74 26                	je     f0102540 <vsnprintf+0x47>
f010251a:	85 d2                	test   %edx,%edx
f010251c:	7e 22                	jle    f0102540 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010251e:	ff 75 14             	pushl  0x14(%ebp)
f0102521:	ff 75 10             	pushl  0x10(%ebp)
f0102524:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102527:	50                   	push   %eax
f0102528:	68 57 21 10 f0       	push   $0xf0102157
f010252d:	e8 5f fc ff ff       	call   f0102191 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102532:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102535:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102538:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010253b:	83 c4 10             	add    $0x10,%esp
f010253e:	eb 05                	jmp    f0102545 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102540:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102545:	c9                   	leave  
f0102546:	c3                   	ret    

f0102547 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102547:	55                   	push   %ebp
f0102548:	89 e5                	mov    %esp,%ebp
f010254a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010254d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102550:	50                   	push   %eax
f0102551:	ff 75 10             	pushl  0x10(%ebp)
f0102554:	ff 75 0c             	pushl  0xc(%ebp)
f0102557:	ff 75 08             	pushl  0x8(%ebp)
f010255a:	e8 9a ff ff ff       	call   f01024f9 <vsnprintf>
	va_end(ap);

	return rc;
}
f010255f:	c9                   	leave  
f0102560:	c3                   	ret    

f0102561 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102561:	55                   	push   %ebp
f0102562:	89 e5                	mov    %esp,%ebp
f0102564:	57                   	push   %edi
f0102565:	56                   	push   %esi
f0102566:	53                   	push   %ebx
f0102567:	83 ec 0c             	sub    $0xc,%esp
f010256a:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010256d:	85 c0                	test   %eax,%eax
f010256f:	74 11                	je     f0102582 <readline+0x21>
		cprintf("%s", prompt);
f0102571:	83 ec 08             	sub    $0x8,%esp
f0102574:	50                   	push   %eax
f0102575:	68 4f 37 10 f0       	push   $0xf010374f
f010257a:	e8 95 f7 ff ff       	call   f0101d14 <cprintf>
f010257f:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102582:	83 ec 0c             	sub    $0xc,%esp
f0102585:	6a 00                	push   $0x0
f0102587:	e8 9a e1 ff ff       	call   f0100726 <iscons>
f010258c:	89 c7                	mov    %eax,%edi
f010258e:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102591:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102596:	e8 7a e1 ff ff       	call   f0100715 <getchar>
f010259b:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010259d:	85 c0                	test   %eax,%eax
f010259f:	79 18                	jns    f01025b9 <readline+0x58>
			cprintf("read error: %e\n", c);
f01025a1:	83 ec 08             	sub    $0x8,%esp
f01025a4:	50                   	push   %eax
f01025a5:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01025aa:	e8 65 f7 ff ff       	call   f0101d14 <cprintf>
			return NULL;
f01025af:	83 c4 10             	add    $0x10,%esp
f01025b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01025b7:	eb 79                	jmp    f0102632 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01025b9:	83 f8 08             	cmp    $0x8,%eax
f01025bc:	0f 94 c2             	sete   %dl
f01025bf:	83 f8 7f             	cmp    $0x7f,%eax
f01025c2:	0f 94 c0             	sete   %al
f01025c5:	08 c2                	or     %al,%dl
f01025c7:	74 1a                	je     f01025e3 <readline+0x82>
f01025c9:	85 f6                	test   %esi,%esi
f01025cb:	7e 16                	jle    f01025e3 <readline+0x82>
			if (echoing)
f01025cd:	85 ff                	test   %edi,%edi
f01025cf:	74 0d                	je     f01025de <readline+0x7d>
				cputchar('\b');
f01025d1:	83 ec 0c             	sub    $0xc,%esp
f01025d4:	6a 08                	push   $0x8
f01025d6:	e8 2a e1 ff ff       	call   f0100705 <cputchar>
f01025db:	83 c4 10             	add    $0x10,%esp
			i--;
f01025de:	83 ee 01             	sub    $0x1,%esi
f01025e1:	eb b3                	jmp    f0102596 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01025e3:	83 fb 1f             	cmp    $0x1f,%ebx
f01025e6:	7e 23                	jle    f010260b <readline+0xaa>
f01025e8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01025ee:	7f 1b                	jg     f010260b <readline+0xaa>
			if (echoing)
f01025f0:	85 ff                	test   %edi,%edi
f01025f2:	74 0c                	je     f0102600 <readline+0x9f>
				cputchar(c);
f01025f4:	83 ec 0c             	sub    $0xc,%esp
f01025f7:	53                   	push   %ebx
f01025f8:	e8 08 e1 ff ff       	call   f0100705 <cputchar>
f01025fd:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102600:	88 9e 40 55 11 f0    	mov    %bl,-0xfeeaac0(%esi)
f0102606:	8d 76 01             	lea    0x1(%esi),%esi
f0102609:	eb 8b                	jmp    f0102596 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010260b:	83 fb 0a             	cmp    $0xa,%ebx
f010260e:	74 05                	je     f0102615 <readline+0xb4>
f0102610:	83 fb 0d             	cmp    $0xd,%ebx
f0102613:	75 81                	jne    f0102596 <readline+0x35>
			if (echoing)
f0102615:	85 ff                	test   %edi,%edi
f0102617:	74 0d                	je     f0102626 <readline+0xc5>
				cputchar('\n');
f0102619:	83 ec 0c             	sub    $0xc,%esp
f010261c:	6a 0a                	push   $0xa
f010261e:	e8 e2 e0 ff ff       	call   f0100705 <cputchar>
f0102623:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102626:	c6 86 40 55 11 f0 00 	movb   $0x0,-0xfeeaac0(%esi)
			return buf;
f010262d:	b8 40 55 11 f0       	mov    $0xf0115540,%eax
		}
	}
}
f0102632:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102635:	5b                   	pop    %ebx
f0102636:	5e                   	pop    %esi
f0102637:	5f                   	pop    %edi
f0102638:	5d                   	pop    %ebp
f0102639:	c3                   	ret    

f010263a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010263a:	55                   	push   %ebp
f010263b:	89 e5                	mov    %esp,%ebp
f010263d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102640:	b8 00 00 00 00       	mov    $0x0,%eax
f0102645:	eb 03                	jmp    f010264a <strlen+0x10>
		n++;
f0102647:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010264a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010264e:	75 f7                	jne    f0102647 <strlen+0xd>
		n++;
	return n;
}
f0102650:	5d                   	pop    %ebp
f0102651:	c3                   	ret    

f0102652 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102652:	55                   	push   %ebp
f0102653:	89 e5                	mov    %esp,%ebp
f0102655:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102658:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010265b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102660:	eb 03                	jmp    f0102665 <strnlen+0x13>
		n++;
f0102662:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102665:	39 c2                	cmp    %eax,%edx
f0102667:	74 08                	je     f0102671 <strnlen+0x1f>
f0102669:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010266d:	75 f3                	jne    f0102662 <strnlen+0x10>
f010266f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0102671:	5d                   	pop    %ebp
f0102672:	c3                   	ret    

f0102673 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102673:	55                   	push   %ebp
f0102674:	89 e5                	mov    %esp,%ebp
f0102676:	53                   	push   %ebx
f0102677:	8b 45 08             	mov    0x8(%ebp),%eax
f010267a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010267d:	89 c2                	mov    %eax,%edx
f010267f:	83 c2 01             	add    $0x1,%edx
f0102682:	83 c1 01             	add    $0x1,%ecx
f0102685:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102689:	88 5a ff             	mov    %bl,-0x1(%edx)
f010268c:	84 db                	test   %bl,%bl
f010268e:	75 ef                	jne    f010267f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102690:	5b                   	pop    %ebx
f0102691:	5d                   	pop    %ebp
f0102692:	c3                   	ret    

f0102693 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102693:	55                   	push   %ebp
f0102694:	89 e5                	mov    %esp,%ebp
f0102696:	53                   	push   %ebx
f0102697:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010269a:	53                   	push   %ebx
f010269b:	e8 9a ff ff ff       	call   f010263a <strlen>
f01026a0:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01026a3:	ff 75 0c             	pushl  0xc(%ebp)
f01026a6:	01 d8                	add    %ebx,%eax
f01026a8:	50                   	push   %eax
f01026a9:	e8 c5 ff ff ff       	call   f0102673 <strcpy>
	return dst;
}
f01026ae:	89 d8                	mov    %ebx,%eax
f01026b0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01026b3:	c9                   	leave  
f01026b4:	c3                   	ret    

f01026b5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01026b5:	55                   	push   %ebp
f01026b6:	89 e5                	mov    %esp,%ebp
f01026b8:	56                   	push   %esi
f01026b9:	53                   	push   %ebx
f01026ba:	8b 75 08             	mov    0x8(%ebp),%esi
f01026bd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01026c0:	89 f3                	mov    %esi,%ebx
f01026c2:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01026c5:	89 f2                	mov    %esi,%edx
f01026c7:	eb 0f                	jmp    f01026d8 <strncpy+0x23>
		*dst++ = *src;
f01026c9:	83 c2 01             	add    $0x1,%edx
f01026cc:	0f b6 01             	movzbl (%ecx),%eax
f01026cf:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01026d2:	80 39 01             	cmpb   $0x1,(%ecx)
f01026d5:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01026d8:	39 da                	cmp    %ebx,%edx
f01026da:	75 ed                	jne    f01026c9 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01026dc:	89 f0                	mov    %esi,%eax
f01026de:	5b                   	pop    %ebx
f01026df:	5e                   	pop    %esi
f01026e0:	5d                   	pop    %ebp
f01026e1:	c3                   	ret    

f01026e2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01026e2:	55                   	push   %ebp
f01026e3:	89 e5                	mov    %esp,%ebp
f01026e5:	56                   	push   %esi
f01026e6:	53                   	push   %ebx
f01026e7:	8b 75 08             	mov    0x8(%ebp),%esi
f01026ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01026ed:	8b 55 10             	mov    0x10(%ebp),%edx
f01026f0:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01026f2:	85 d2                	test   %edx,%edx
f01026f4:	74 21                	je     f0102717 <strlcpy+0x35>
f01026f6:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01026fa:	89 f2                	mov    %esi,%edx
f01026fc:	eb 09                	jmp    f0102707 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01026fe:	83 c2 01             	add    $0x1,%edx
f0102701:	83 c1 01             	add    $0x1,%ecx
f0102704:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0102707:	39 c2                	cmp    %eax,%edx
f0102709:	74 09                	je     f0102714 <strlcpy+0x32>
f010270b:	0f b6 19             	movzbl (%ecx),%ebx
f010270e:	84 db                	test   %bl,%bl
f0102710:	75 ec                	jne    f01026fe <strlcpy+0x1c>
f0102712:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0102714:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0102717:	29 f0                	sub    %esi,%eax
}
f0102719:	5b                   	pop    %ebx
f010271a:	5e                   	pop    %esi
f010271b:	5d                   	pop    %ebp
f010271c:	c3                   	ret    

f010271d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010271d:	55                   	push   %ebp
f010271e:	89 e5                	mov    %esp,%ebp
f0102720:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102723:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102726:	eb 06                	jmp    f010272e <strcmp+0x11>
		p++, q++;
f0102728:	83 c1 01             	add    $0x1,%ecx
f010272b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010272e:	0f b6 01             	movzbl (%ecx),%eax
f0102731:	84 c0                	test   %al,%al
f0102733:	74 04                	je     f0102739 <strcmp+0x1c>
f0102735:	3a 02                	cmp    (%edx),%al
f0102737:	74 ef                	je     f0102728 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102739:	0f b6 c0             	movzbl %al,%eax
f010273c:	0f b6 12             	movzbl (%edx),%edx
f010273f:	29 d0                	sub    %edx,%eax
}
f0102741:	5d                   	pop    %ebp
f0102742:	c3                   	ret    

f0102743 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0102743:	55                   	push   %ebp
f0102744:	89 e5                	mov    %esp,%ebp
f0102746:	53                   	push   %ebx
f0102747:	8b 45 08             	mov    0x8(%ebp),%eax
f010274a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010274d:	89 c3                	mov    %eax,%ebx
f010274f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0102752:	eb 06                	jmp    f010275a <strncmp+0x17>
		n--, p++, q++;
f0102754:	83 c0 01             	add    $0x1,%eax
f0102757:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010275a:	39 d8                	cmp    %ebx,%eax
f010275c:	74 15                	je     f0102773 <strncmp+0x30>
f010275e:	0f b6 08             	movzbl (%eax),%ecx
f0102761:	84 c9                	test   %cl,%cl
f0102763:	74 04                	je     f0102769 <strncmp+0x26>
f0102765:	3a 0a                	cmp    (%edx),%cl
f0102767:	74 eb                	je     f0102754 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102769:	0f b6 00             	movzbl (%eax),%eax
f010276c:	0f b6 12             	movzbl (%edx),%edx
f010276f:	29 d0                	sub    %edx,%eax
f0102771:	eb 05                	jmp    f0102778 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0102773:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0102778:	5b                   	pop    %ebx
f0102779:	5d                   	pop    %ebp
f010277a:	c3                   	ret    

f010277b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010277b:	55                   	push   %ebp
f010277c:	89 e5                	mov    %esp,%ebp
f010277e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102781:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102785:	eb 07                	jmp    f010278e <strchr+0x13>
		if (*s == c)
f0102787:	38 ca                	cmp    %cl,%dl
f0102789:	74 0f                	je     f010279a <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010278b:	83 c0 01             	add    $0x1,%eax
f010278e:	0f b6 10             	movzbl (%eax),%edx
f0102791:	84 d2                	test   %dl,%dl
f0102793:	75 f2                	jne    f0102787 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0102795:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010279a:	5d                   	pop    %ebp
f010279b:	c3                   	ret    

f010279c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010279c:	55                   	push   %ebp
f010279d:	89 e5                	mov    %esp,%ebp
f010279f:	8b 45 08             	mov    0x8(%ebp),%eax
f01027a2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01027a6:	eb 03                	jmp    f01027ab <strfind+0xf>
f01027a8:	83 c0 01             	add    $0x1,%eax
f01027ab:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01027ae:	38 ca                	cmp    %cl,%dl
f01027b0:	74 04                	je     f01027b6 <strfind+0x1a>
f01027b2:	84 d2                	test   %dl,%dl
f01027b4:	75 f2                	jne    f01027a8 <strfind+0xc>
			break;
	return (char *) s;
}
f01027b6:	5d                   	pop    %ebp
f01027b7:	c3                   	ret    

f01027b8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01027b8:	55                   	push   %ebp
f01027b9:	89 e5                	mov    %esp,%ebp
f01027bb:	57                   	push   %edi
f01027bc:	56                   	push   %esi
f01027bd:	53                   	push   %ebx
f01027be:	8b 55 08             	mov    0x8(%ebp),%edx
f01027c1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f01027c4:	85 c9                	test   %ecx,%ecx
f01027c6:	74 37                	je     f01027ff <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01027c8:	f6 c2 03             	test   $0x3,%dl
f01027cb:	75 2a                	jne    f01027f7 <memset+0x3f>
f01027cd:	f6 c1 03             	test   $0x3,%cl
f01027d0:	75 25                	jne    f01027f7 <memset+0x3f>
		c &= 0xFF;
f01027d2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01027d6:	89 df                	mov    %ebx,%edi
f01027d8:	c1 e7 08             	shl    $0x8,%edi
f01027db:	89 de                	mov    %ebx,%esi
f01027dd:	c1 e6 18             	shl    $0x18,%esi
f01027e0:	89 d8                	mov    %ebx,%eax
f01027e2:	c1 e0 10             	shl    $0x10,%eax
f01027e5:	09 f0                	or     %esi,%eax
f01027e7:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f01027e9:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01027ec:	89 f8                	mov    %edi,%eax
f01027ee:	09 d8                	or     %ebx,%eax
f01027f0:	89 d7                	mov    %edx,%edi
f01027f2:	fc                   	cld    
f01027f3:	f3 ab                	rep stos %eax,%es:(%edi)
f01027f5:	eb 08                	jmp    f01027ff <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01027f7:	89 d7                	mov    %edx,%edi
f01027f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027fc:	fc                   	cld    
f01027fd:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f01027ff:	89 d0                	mov    %edx,%eax
f0102801:	5b                   	pop    %ebx
f0102802:	5e                   	pop    %esi
f0102803:	5f                   	pop    %edi
f0102804:	5d                   	pop    %ebp
f0102805:	c3                   	ret    

f0102806 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102806:	55                   	push   %ebp
f0102807:	89 e5                	mov    %esp,%ebp
f0102809:	57                   	push   %edi
f010280a:	56                   	push   %esi
f010280b:	8b 45 08             	mov    0x8(%ebp),%eax
f010280e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102811:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102814:	39 c6                	cmp    %eax,%esi
f0102816:	73 35                	jae    f010284d <memmove+0x47>
f0102818:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010281b:	39 d0                	cmp    %edx,%eax
f010281d:	73 2e                	jae    f010284d <memmove+0x47>
		s += n;
		d += n;
f010281f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102822:	89 d6                	mov    %edx,%esi
f0102824:	09 fe                	or     %edi,%esi
f0102826:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010282c:	75 13                	jne    f0102841 <memmove+0x3b>
f010282e:	f6 c1 03             	test   $0x3,%cl
f0102831:	75 0e                	jne    f0102841 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0102833:	83 ef 04             	sub    $0x4,%edi
f0102836:	8d 72 fc             	lea    -0x4(%edx),%esi
f0102839:	c1 e9 02             	shr    $0x2,%ecx
f010283c:	fd                   	std    
f010283d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010283f:	eb 09                	jmp    f010284a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0102841:	83 ef 01             	sub    $0x1,%edi
f0102844:	8d 72 ff             	lea    -0x1(%edx),%esi
f0102847:	fd                   	std    
f0102848:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010284a:	fc                   	cld    
f010284b:	eb 1d                	jmp    f010286a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010284d:	89 f2                	mov    %esi,%edx
f010284f:	09 c2                	or     %eax,%edx
f0102851:	f6 c2 03             	test   $0x3,%dl
f0102854:	75 0f                	jne    f0102865 <memmove+0x5f>
f0102856:	f6 c1 03             	test   $0x3,%cl
f0102859:	75 0a                	jne    f0102865 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010285b:	c1 e9 02             	shr    $0x2,%ecx
f010285e:	89 c7                	mov    %eax,%edi
f0102860:	fc                   	cld    
f0102861:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102863:	eb 05                	jmp    f010286a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102865:	89 c7                	mov    %eax,%edi
f0102867:	fc                   	cld    
f0102868:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010286a:	5e                   	pop    %esi
f010286b:	5f                   	pop    %edi
f010286c:	5d                   	pop    %ebp
f010286d:	c3                   	ret    

f010286e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010286e:	55                   	push   %ebp
f010286f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102871:	ff 75 10             	pushl  0x10(%ebp)
f0102874:	ff 75 0c             	pushl  0xc(%ebp)
f0102877:	ff 75 08             	pushl  0x8(%ebp)
f010287a:	e8 87 ff ff ff       	call   f0102806 <memmove>
}
f010287f:	c9                   	leave  
f0102880:	c3                   	ret    

f0102881 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102881:	55                   	push   %ebp
f0102882:	89 e5                	mov    %esp,%ebp
f0102884:	56                   	push   %esi
f0102885:	53                   	push   %ebx
f0102886:	8b 45 08             	mov    0x8(%ebp),%eax
f0102889:	8b 55 0c             	mov    0xc(%ebp),%edx
f010288c:	89 c6                	mov    %eax,%esi
f010288e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102891:	eb 1a                	jmp    f01028ad <memcmp+0x2c>
		if (*s1 != *s2)
f0102893:	0f b6 08             	movzbl (%eax),%ecx
f0102896:	0f b6 1a             	movzbl (%edx),%ebx
f0102899:	38 d9                	cmp    %bl,%cl
f010289b:	74 0a                	je     f01028a7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010289d:	0f b6 c1             	movzbl %cl,%eax
f01028a0:	0f b6 db             	movzbl %bl,%ebx
f01028a3:	29 d8                	sub    %ebx,%eax
f01028a5:	eb 0f                	jmp    f01028b6 <memcmp+0x35>
		s1++, s2++;
f01028a7:	83 c0 01             	add    $0x1,%eax
f01028aa:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01028ad:	39 f0                	cmp    %esi,%eax
f01028af:	75 e2                	jne    f0102893 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01028b1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01028b6:	5b                   	pop    %ebx
f01028b7:	5e                   	pop    %esi
f01028b8:	5d                   	pop    %ebp
f01028b9:	c3                   	ret    

f01028ba <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01028ba:	55                   	push   %ebp
f01028bb:	89 e5                	mov    %esp,%ebp
f01028bd:	53                   	push   %ebx
f01028be:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01028c1:	89 c1                	mov    %eax,%ecx
f01028c3:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01028c6:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01028ca:	eb 0a                	jmp    f01028d6 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01028cc:	0f b6 10             	movzbl (%eax),%edx
f01028cf:	39 da                	cmp    %ebx,%edx
f01028d1:	74 07                	je     f01028da <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01028d3:	83 c0 01             	add    $0x1,%eax
f01028d6:	39 c8                	cmp    %ecx,%eax
f01028d8:	72 f2                	jb     f01028cc <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01028da:	5b                   	pop    %ebx
f01028db:	5d                   	pop    %ebp
f01028dc:	c3                   	ret    

f01028dd <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01028dd:	55                   	push   %ebp
f01028de:	89 e5                	mov    %esp,%ebp
f01028e0:	57                   	push   %edi
f01028e1:	56                   	push   %esi
f01028e2:	53                   	push   %ebx
f01028e3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01028e6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01028e9:	eb 03                	jmp    f01028ee <strtol+0x11>
		s++;
f01028eb:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01028ee:	0f b6 01             	movzbl (%ecx),%eax
f01028f1:	3c 20                	cmp    $0x20,%al
f01028f3:	74 f6                	je     f01028eb <strtol+0xe>
f01028f5:	3c 09                	cmp    $0x9,%al
f01028f7:	74 f2                	je     f01028eb <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01028f9:	3c 2b                	cmp    $0x2b,%al
f01028fb:	75 0a                	jne    f0102907 <strtol+0x2a>
		s++;
f01028fd:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102900:	bf 00 00 00 00       	mov    $0x0,%edi
f0102905:	eb 11                	jmp    f0102918 <strtol+0x3b>
f0102907:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010290c:	3c 2d                	cmp    $0x2d,%al
f010290e:	75 08                	jne    f0102918 <strtol+0x3b>
		s++, neg = 1;
f0102910:	83 c1 01             	add    $0x1,%ecx
f0102913:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102918:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010291e:	75 15                	jne    f0102935 <strtol+0x58>
f0102920:	80 39 30             	cmpb   $0x30,(%ecx)
f0102923:	75 10                	jne    f0102935 <strtol+0x58>
f0102925:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0102929:	75 7c                	jne    f01029a7 <strtol+0xca>
		s += 2, base = 16;
f010292b:	83 c1 02             	add    $0x2,%ecx
f010292e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102933:	eb 16                	jmp    f010294b <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0102935:	85 db                	test   %ebx,%ebx
f0102937:	75 12                	jne    f010294b <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102939:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010293e:	80 39 30             	cmpb   $0x30,(%ecx)
f0102941:	75 08                	jne    f010294b <strtol+0x6e>
		s++, base = 8;
f0102943:	83 c1 01             	add    $0x1,%ecx
f0102946:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010294b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102950:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102953:	0f b6 11             	movzbl (%ecx),%edx
f0102956:	8d 72 d0             	lea    -0x30(%edx),%esi
f0102959:	89 f3                	mov    %esi,%ebx
f010295b:	80 fb 09             	cmp    $0x9,%bl
f010295e:	77 08                	ja     f0102968 <strtol+0x8b>
			dig = *s - '0';
f0102960:	0f be d2             	movsbl %dl,%edx
f0102963:	83 ea 30             	sub    $0x30,%edx
f0102966:	eb 22                	jmp    f010298a <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0102968:	8d 72 9f             	lea    -0x61(%edx),%esi
f010296b:	89 f3                	mov    %esi,%ebx
f010296d:	80 fb 19             	cmp    $0x19,%bl
f0102970:	77 08                	ja     f010297a <strtol+0x9d>
			dig = *s - 'a' + 10;
f0102972:	0f be d2             	movsbl %dl,%edx
f0102975:	83 ea 57             	sub    $0x57,%edx
f0102978:	eb 10                	jmp    f010298a <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010297a:	8d 72 bf             	lea    -0x41(%edx),%esi
f010297d:	89 f3                	mov    %esi,%ebx
f010297f:	80 fb 19             	cmp    $0x19,%bl
f0102982:	77 16                	ja     f010299a <strtol+0xbd>
			dig = *s - 'A' + 10;
f0102984:	0f be d2             	movsbl %dl,%edx
f0102987:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010298a:	3b 55 10             	cmp    0x10(%ebp),%edx
f010298d:	7d 0b                	jge    f010299a <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010298f:	83 c1 01             	add    $0x1,%ecx
f0102992:	0f af 45 10          	imul   0x10(%ebp),%eax
f0102996:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0102998:	eb b9                	jmp    f0102953 <strtol+0x76>

	if (endptr)
f010299a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010299e:	74 0d                	je     f01029ad <strtol+0xd0>
		*endptr = (char *) s;
f01029a0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01029a3:	89 0e                	mov    %ecx,(%esi)
f01029a5:	eb 06                	jmp    f01029ad <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01029a7:	85 db                	test   %ebx,%ebx
f01029a9:	74 98                	je     f0102943 <strtol+0x66>
f01029ab:	eb 9e                	jmp    f010294b <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01029ad:	89 c2                	mov    %eax,%edx
f01029af:	f7 da                	neg    %edx
f01029b1:	85 ff                	test   %edi,%edi
f01029b3:	0f 45 c2             	cmovne %edx,%eax
}
f01029b6:	5b                   	pop    %ebx
f01029b7:	5e                   	pop    %esi
f01029b8:	5f                   	pop    %edi
f01029b9:	5d                   	pop    %ebp
f01029ba:	c3                   	ret    
f01029bb:	66 90                	xchg   %ax,%ax
f01029bd:	66 90                	xchg   %ax,%ax
f01029bf:	90                   	nop

f01029c0 <__udivdi3>:
f01029c0:	55                   	push   %ebp
f01029c1:	57                   	push   %edi
f01029c2:	56                   	push   %esi
f01029c3:	53                   	push   %ebx
f01029c4:	83 ec 1c             	sub    $0x1c,%esp
f01029c7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01029cb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01029cf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01029d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01029d7:	85 f6                	test   %esi,%esi
f01029d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01029dd:	89 ca                	mov    %ecx,%edx
f01029df:	89 f8                	mov    %edi,%eax
f01029e1:	75 3d                	jne    f0102a20 <__udivdi3+0x60>
f01029e3:	39 cf                	cmp    %ecx,%edi
f01029e5:	0f 87 c5 00 00 00    	ja     f0102ab0 <__udivdi3+0xf0>
f01029eb:	85 ff                	test   %edi,%edi
f01029ed:	89 fd                	mov    %edi,%ebp
f01029ef:	75 0b                	jne    f01029fc <__udivdi3+0x3c>
f01029f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01029f6:	31 d2                	xor    %edx,%edx
f01029f8:	f7 f7                	div    %edi
f01029fa:	89 c5                	mov    %eax,%ebp
f01029fc:	89 c8                	mov    %ecx,%eax
f01029fe:	31 d2                	xor    %edx,%edx
f0102a00:	f7 f5                	div    %ebp
f0102a02:	89 c1                	mov    %eax,%ecx
f0102a04:	89 d8                	mov    %ebx,%eax
f0102a06:	89 cf                	mov    %ecx,%edi
f0102a08:	f7 f5                	div    %ebp
f0102a0a:	89 c3                	mov    %eax,%ebx
f0102a0c:	89 d8                	mov    %ebx,%eax
f0102a0e:	89 fa                	mov    %edi,%edx
f0102a10:	83 c4 1c             	add    $0x1c,%esp
f0102a13:	5b                   	pop    %ebx
f0102a14:	5e                   	pop    %esi
f0102a15:	5f                   	pop    %edi
f0102a16:	5d                   	pop    %ebp
f0102a17:	c3                   	ret    
f0102a18:	90                   	nop
f0102a19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102a20:	39 ce                	cmp    %ecx,%esi
f0102a22:	77 74                	ja     f0102a98 <__udivdi3+0xd8>
f0102a24:	0f bd fe             	bsr    %esi,%edi
f0102a27:	83 f7 1f             	xor    $0x1f,%edi
f0102a2a:	0f 84 98 00 00 00    	je     f0102ac8 <__udivdi3+0x108>
f0102a30:	bb 20 00 00 00       	mov    $0x20,%ebx
f0102a35:	89 f9                	mov    %edi,%ecx
f0102a37:	89 c5                	mov    %eax,%ebp
f0102a39:	29 fb                	sub    %edi,%ebx
f0102a3b:	d3 e6                	shl    %cl,%esi
f0102a3d:	89 d9                	mov    %ebx,%ecx
f0102a3f:	d3 ed                	shr    %cl,%ebp
f0102a41:	89 f9                	mov    %edi,%ecx
f0102a43:	d3 e0                	shl    %cl,%eax
f0102a45:	09 ee                	or     %ebp,%esi
f0102a47:	89 d9                	mov    %ebx,%ecx
f0102a49:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a4d:	89 d5                	mov    %edx,%ebp
f0102a4f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102a53:	d3 ed                	shr    %cl,%ebp
f0102a55:	89 f9                	mov    %edi,%ecx
f0102a57:	d3 e2                	shl    %cl,%edx
f0102a59:	89 d9                	mov    %ebx,%ecx
f0102a5b:	d3 e8                	shr    %cl,%eax
f0102a5d:	09 c2                	or     %eax,%edx
f0102a5f:	89 d0                	mov    %edx,%eax
f0102a61:	89 ea                	mov    %ebp,%edx
f0102a63:	f7 f6                	div    %esi
f0102a65:	89 d5                	mov    %edx,%ebp
f0102a67:	89 c3                	mov    %eax,%ebx
f0102a69:	f7 64 24 0c          	mull   0xc(%esp)
f0102a6d:	39 d5                	cmp    %edx,%ebp
f0102a6f:	72 10                	jb     f0102a81 <__udivdi3+0xc1>
f0102a71:	8b 74 24 08          	mov    0x8(%esp),%esi
f0102a75:	89 f9                	mov    %edi,%ecx
f0102a77:	d3 e6                	shl    %cl,%esi
f0102a79:	39 c6                	cmp    %eax,%esi
f0102a7b:	73 07                	jae    f0102a84 <__udivdi3+0xc4>
f0102a7d:	39 d5                	cmp    %edx,%ebp
f0102a7f:	75 03                	jne    f0102a84 <__udivdi3+0xc4>
f0102a81:	83 eb 01             	sub    $0x1,%ebx
f0102a84:	31 ff                	xor    %edi,%edi
f0102a86:	89 d8                	mov    %ebx,%eax
f0102a88:	89 fa                	mov    %edi,%edx
f0102a8a:	83 c4 1c             	add    $0x1c,%esp
f0102a8d:	5b                   	pop    %ebx
f0102a8e:	5e                   	pop    %esi
f0102a8f:	5f                   	pop    %edi
f0102a90:	5d                   	pop    %ebp
f0102a91:	c3                   	ret    
f0102a92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102a98:	31 ff                	xor    %edi,%edi
f0102a9a:	31 db                	xor    %ebx,%ebx
f0102a9c:	89 d8                	mov    %ebx,%eax
f0102a9e:	89 fa                	mov    %edi,%edx
f0102aa0:	83 c4 1c             	add    $0x1c,%esp
f0102aa3:	5b                   	pop    %ebx
f0102aa4:	5e                   	pop    %esi
f0102aa5:	5f                   	pop    %edi
f0102aa6:	5d                   	pop    %ebp
f0102aa7:	c3                   	ret    
f0102aa8:	90                   	nop
f0102aa9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102ab0:	89 d8                	mov    %ebx,%eax
f0102ab2:	f7 f7                	div    %edi
f0102ab4:	31 ff                	xor    %edi,%edi
f0102ab6:	89 c3                	mov    %eax,%ebx
f0102ab8:	89 d8                	mov    %ebx,%eax
f0102aba:	89 fa                	mov    %edi,%edx
f0102abc:	83 c4 1c             	add    $0x1c,%esp
f0102abf:	5b                   	pop    %ebx
f0102ac0:	5e                   	pop    %esi
f0102ac1:	5f                   	pop    %edi
f0102ac2:	5d                   	pop    %ebp
f0102ac3:	c3                   	ret    
f0102ac4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102ac8:	39 ce                	cmp    %ecx,%esi
f0102aca:	72 0c                	jb     f0102ad8 <__udivdi3+0x118>
f0102acc:	31 db                	xor    %ebx,%ebx
f0102ace:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0102ad2:	0f 87 34 ff ff ff    	ja     f0102a0c <__udivdi3+0x4c>
f0102ad8:	bb 01 00 00 00       	mov    $0x1,%ebx
f0102add:	e9 2a ff ff ff       	jmp    f0102a0c <__udivdi3+0x4c>
f0102ae2:	66 90                	xchg   %ax,%ax
f0102ae4:	66 90                	xchg   %ax,%ax
f0102ae6:	66 90                	xchg   %ax,%ax
f0102ae8:	66 90                	xchg   %ax,%ax
f0102aea:	66 90                	xchg   %ax,%ax
f0102aec:	66 90                	xchg   %ax,%ax
f0102aee:	66 90                	xchg   %ax,%ax

f0102af0 <__umoddi3>:
f0102af0:	55                   	push   %ebp
f0102af1:	57                   	push   %edi
f0102af2:	56                   	push   %esi
f0102af3:	53                   	push   %ebx
f0102af4:	83 ec 1c             	sub    $0x1c,%esp
f0102af7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0102afb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0102aff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102b03:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102b07:	85 d2                	test   %edx,%edx
f0102b09:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102b0d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102b11:	89 f3                	mov    %esi,%ebx
f0102b13:	89 3c 24             	mov    %edi,(%esp)
f0102b16:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102b1a:	75 1c                	jne    f0102b38 <__umoddi3+0x48>
f0102b1c:	39 f7                	cmp    %esi,%edi
f0102b1e:	76 50                	jbe    f0102b70 <__umoddi3+0x80>
f0102b20:	89 c8                	mov    %ecx,%eax
f0102b22:	89 f2                	mov    %esi,%edx
f0102b24:	f7 f7                	div    %edi
f0102b26:	89 d0                	mov    %edx,%eax
f0102b28:	31 d2                	xor    %edx,%edx
f0102b2a:	83 c4 1c             	add    $0x1c,%esp
f0102b2d:	5b                   	pop    %ebx
f0102b2e:	5e                   	pop    %esi
f0102b2f:	5f                   	pop    %edi
f0102b30:	5d                   	pop    %ebp
f0102b31:	c3                   	ret    
f0102b32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102b38:	39 f2                	cmp    %esi,%edx
f0102b3a:	89 d0                	mov    %edx,%eax
f0102b3c:	77 52                	ja     f0102b90 <__umoddi3+0xa0>
f0102b3e:	0f bd ea             	bsr    %edx,%ebp
f0102b41:	83 f5 1f             	xor    $0x1f,%ebp
f0102b44:	75 5a                	jne    f0102ba0 <__umoddi3+0xb0>
f0102b46:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0102b4a:	0f 82 e0 00 00 00    	jb     f0102c30 <__umoddi3+0x140>
f0102b50:	39 0c 24             	cmp    %ecx,(%esp)
f0102b53:	0f 86 d7 00 00 00    	jbe    f0102c30 <__umoddi3+0x140>
f0102b59:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102b5d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0102b61:	83 c4 1c             	add    $0x1c,%esp
f0102b64:	5b                   	pop    %ebx
f0102b65:	5e                   	pop    %esi
f0102b66:	5f                   	pop    %edi
f0102b67:	5d                   	pop    %ebp
f0102b68:	c3                   	ret    
f0102b69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102b70:	85 ff                	test   %edi,%edi
f0102b72:	89 fd                	mov    %edi,%ebp
f0102b74:	75 0b                	jne    f0102b81 <__umoddi3+0x91>
f0102b76:	b8 01 00 00 00       	mov    $0x1,%eax
f0102b7b:	31 d2                	xor    %edx,%edx
f0102b7d:	f7 f7                	div    %edi
f0102b7f:	89 c5                	mov    %eax,%ebp
f0102b81:	89 f0                	mov    %esi,%eax
f0102b83:	31 d2                	xor    %edx,%edx
f0102b85:	f7 f5                	div    %ebp
f0102b87:	89 c8                	mov    %ecx,%eax
f0102b89:	f7 f5                	div    %ebp
f0102b8b:	89 d0                	mov    %edx,%eax
f0102b8d:	eb 99                	jmp    f0102b28 <__umoddi3+0x38>
f0102b8f:	90                   	nop
f0102b90:	89 c8                	mov    %ecx,%eax
f0102b92:	89 f2                	mov    %esi,%edx
f0102b94:	83 c4 1c             	add    $0x1c,%esp
f0102b97:	5b                   	pop    %ebx
f0102b98:	5e                   	pop    %esi
f0102b99:	5f                   	pop    %edi
f0102b9a:	5d                   	pop    %ebp
f0102b9b:	c3                   	ret    
f0102b9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102ba0:	8b 34 24             	mov    (%esp),%esi
f0102ba3:	bf 20 00 00 00       	mov    $0x20,%edi
f0102ba8:	89 e9                	mov    %ebp,%ecx
f0102baa:	29 ef                	sub    %ebp,%edi
f0102bac:	d3 e0                	shl    %cl,%eax
f0102bae:	89 f9                	mov    %edi,%ecx
f0102bb0:	89 f2                	mov    %esi,%edx
f0102bb2:	d3 ea                	shr    %cl,%edx
f0102bb4:	89 e9                	mov    %ebp,%ecx
f0102bb6:	09 c2                	or     %eax,%edx
f0102bb8:	89 d8                	mov    %ebx,%eax
f0102bba:	89 14 24             	mov    %edx,(%esp)
f0102bbd:	89 f2                	mov    %esi,%edx
f0102bbf:	d3 e2                	shl    %cl,%edx
f0102bc1:	89 f9                	mov    %edi,%ecx
f0102bc3:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102bc7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0102bcb:	d3 e8                	shr    %cl,%eax
f0102bcd:	89 e9                	mov    %ebp,%ecx
f0102bcf:	89 c6                	mov    %eax,%esi
f0102bd1:	d3 e3                	shl    %cl,%ebx
f0102bd3:	89 f9                	mov    %edi,%ecx
f0102bd5:	89 d0                	mov    %edx,%eax
f0102bd7:	d3 e8                	shr    %cl,%eax
f0102bd9:	89 e9                	mov    %ebp,%ecx
f0102bdb:	09 d8                	or     %ebx,%eax
f0102bdd:	89 d3                	mov    %edx,%ebx
f0102bdf:	89 f2                	mov    %esi,%edx
f0102be1:	f7 34 24             	divl   (%esp)
f0102be4:	89 d6                	mov    %edx,%esi
f0102be6:	d3 e3                	shl    %cl,%ebx
f0102be8:	f7 64 24 04          	mull   0x4(%esp)
f0102bec:	39 d6                	cmp    %edx,%esi
f0102bee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102bf2:	89 d1                	mov    %edx,%ecx
f0102bf4:	89 c3                	mov    %eax,%ebx
f0102bf6:	72 08                	jb     f0102c00 <__umoddi3+0x110>
f0102bf8:	75 11                	jne    f0102c0b <__umoddi3+0x11b>
f0102bfa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0102bfe:	73 0b                	jae    f0102c0b <__umoddi3+0x11b>
f0102c00:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102c04:	1b 14 24             	sbb    (%esp),%edx
f0102c07:	89 d1                	mov    %edx,%ecx
f0102c09:	89 c3                	mov    %eax,%ebx
f0102c0b:	8b 54 24 08          	mov    0x8(%esp),%edx
f0102c0f:	29 da                	sub    %ebx,%edx
f0102c11:	19 ce                	sbb    %ecx,%esi
f0102c13:	89 f9                	mov    %edi,%ecx
f0102c15:	89 f0                	mov    %esi,%eax
f0102c17:	d3 e0                	shl    %cl,%eax
f0102c19:	89 e9                	mov    %ebp,%ecx
f0102c1b:	d3 ea                	shr    %cl,%edx
f0102c1d:	89 e9                	mov    %ebp,%ecx
f0102c1f:	d3 ee                	shr    %cl,%esi
f0102c21:	09 d0                	or     %edx,%eax
f0102c23:	89 f2                	mov    %esi,%edx
f0102c25:	83 c4 1c             	add    $0x1c,%esp
f0102c28:	5b                   	pop    %ebx
f0102c29:	5e                   	pop    %esi
f0102c2a:	5f                   	pop    %edi
f0102c2b:	5d                   	pop    %ebp
f0102c2c:	c3                   	ret    
f0102c2d:	8d 76 00             	lea    0x0(%esi),%esi
f0102c30:	29 f9                	sub    %edi,%ecx
f0102c32:	19 d6                	sbb    %edx,%esi
f0102c34:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102c38:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102c3c:	e9 18 ff ff ff       	jmp    f0102b59 <__umoddi3+0x69>
