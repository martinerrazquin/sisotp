
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

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
f0100046:	b8 50 69 11 f0       	mov    $0xf0116950,%eax
f010004b:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 63 11 f0       	push   $0xf0116300
f0100058:	e8 f8 28 00 00       	call   f0102955 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 78 06 00 00       	call   f01006da <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 2e 10 f0       	push   $0xf0102e00
f010006f:	e8 3d 1e 00 00       	call   f0101eb1 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 8b 1b 00 00       	call   f0101c04 <mem_init>
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
f0100093:	83 3d 40 69 11 f0 00 	cmpl   $0x0,0xf0116940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 69 11 f0    	mov    %esi,0xf0116940

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
f01000b0:	68 3c 2e 10 f0       	push   $0xf0102e3c
f01000b5:	e8 f7 1d 00 00       	call   f0101eb1 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 c7 1d 00 00       	call   f0101e8b <vcprintf>
	cprintf("\n>>>\n");
f01000c4:	c7 04 24 1b 2e 10 f0 	movl   $0xf0102e1b,(%esp)
f01000cb:	e8 e1 1d 00 00       	call   f0101eb1 <cprintf>
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
f01000f2:	68 21 2e 10 f0       	push   $0xf0102e21
f01000f7:	e8 b5 1d 00 00       	call   f0101eb1 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 83 1d 00 00       	call   f0101e8b <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 cf 3c 10 f0 	movl   $0xf0103ccf,(%esp)
f010010f:	e8 9d 1d 00 00       	call   f0101eb1 <cprintf>
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
f010023b:	0f 95 05 34 65 11 f0 	setne  0xf0116534
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
f01002db:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
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
f01002f5:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
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
f0100306:	8b 35 30 65 11 f0    	mov    0xf0116530,%esi
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
f010033e:	89 0d 2c 65 11 f0    	mov    %ecx,0xf011652c
	crt_pos = pos;
f0100344:	0f b6 c0             	movzbl %al,%eax
f0100347:	09 c3                	or     %eax,%ebx
f0100349:	66 89 1d 28 65 11 f0 	mov    %bx,0xf0116528
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
f0100367:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f010036d:	8d 51 01             	lea    0x1(%ecx),%edx
f0100370:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f0100376:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010037c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100382:	75 0a                	jne    f010038e <cons_intr+0x36>
			cons.wpos = 0;
f0100384:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
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
f01003ca:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f01003d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01003d6:	e9 e7 00 00 00       	jmp    f01004c2 <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f01003db:	84 c0                	test   %al,%al
f01003dd:	79 38                	jns    f0100417 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003df:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01003e5:	89 cb                	mov    %ecx,%ebx
f01003e7:	83 e3 40             	and    $0x40,%ebx
f01003ea:	89 c2                	mov    %eax,%edx
f01003ec:	83 e2 7f             	and    $0x7f,%edx
f01003ef:	85 db                	test   %ebx,%ebx
f01003f1:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01003f4:	0f b6 c0             	movzbl %al,%eax
f01003f7:	0f b6 80 c0 2f 10 f0 	movzbl -0xfefd040(%eax),%eax
f01003fe:	83 c8 40             	or     $0x40,%eax
f0100401:	0f b6 c0             	movzbl %al,%eax
f0100404:	f7 d0                	not    %eax
f0100406:	21 c8                	and    %ecx,%eax
f0100408:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f010040d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100412:	e9 ab 00 00 00       	jmp    f01004c2 <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100417:	8b 15 00 63 11 f0    	mov    0xf0116300,%edx
f010041d:	f6 c2 40             	test   $0x40,%dl
f0100420:	74 0c                	je     f010042e <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100422:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100425:	83 e2 bf             	and    $0xffffffbf,%edx
f0100428:	89 15 00 63 11 f0    	mov    %edx,0xf0116300
	}

	shift |= shiftcode[data];
f010042e:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f0100431:	0f b6 90 c0 2f 10 f0 	movzbl -0xfefd040(%eax),%edx
f0100438:	0b 15 00 63 11 f0    	or     0xf0116300,%edx
f010043e:	0f b6 88 c0 2e 10 f0 	movzbl -0xfefd140(%eax),%ecx
f0100445:	31 ca                	xor    %ecx,%edx
f0100447:	89 15 00 63 11 f0    	mov    %edx,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f010044d:	89 d1                	mov    %edx,%ecx
f010044f:	83 e1 03             	and    $0x3,%ecx
f0100452:	8b 0c 8d a0 2e 10 f0 	mov    -0xfefd160(,%ecx,4),%ecx
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
f0100492:	68 5c 2e 10 f0       	push   $0xf0102e5c
f0100497:	e8 15 1a 00 00       	call   f0101eb1 <cprintf>
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
f0100508:	0f b7 15 28 65 11 f0 	movzwl 0xf0116528,%edx
f010050f:	66 85 d2             	test   %dx,%dx
f0100512:	0f 84 e4 00 00 00    	je     f01005fc <cga_putc+0x135>
			crt_pos--;
f0100518:	83 ea 01             	sub    $0x1,%edx
f010051b:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100522:	0f b7 d2             	movzwl %dx,%edx
f0100525:	b0 00                	mov    $0x0,%al
f0100527:	83 c8 20             	or     $0x20,%eax
f010052a:	8b 0d 2c 65 11 f0    	mov    0xf011652c,%ecx
f0100530:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100534:	eb 78                	jmp    f01005ae <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100536:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f010053d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010053e:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f0100545:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010054b:	c1 e8 16             	shr    $0x16,%eax
f010054e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100551:	c1 e0 04             	shl    $0x4,%eax
f0100554:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
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
f0100590:	0f b7 15 28 65 11 f0 	movzwl 0xf0116528,%edx
f0100597:	8d 4a 01             	lea    0x1(%edx),%ecx
f010059a:	66 89 0d 28 65 11 f0 	mov    %cx,0xf0116528
f01005a1:	0f b7 d2             	movzwl %dx,%edx
f01005a4:	8b 0d 2c 65 11 f0    	mov    0xf011652c,%ecx
f01005aa:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005ae:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f01005b5:	cf 07 
f01005b7:	76 43                	jbe    f01005fc <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005b9:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f01005be:	83 ec 04             	sub    $0x4,%esp
f01005c1:	68 00 0f 00 00       	push   $0xf00
f01005c6:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005cc:	52                   	push   %edx
f01005cd:	50                   	push   %eax
f01005ce:	e8 d0 23 00 00       	call   f01029a3 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005d3:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
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
f01005f4:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f01005fb:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005fc:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f0100602:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100607:	89 f8                	mov    %edi,%eax
f0100609:	e8 16 fb ff ff       	call   f0100124 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f010060e:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
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
f0100662:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
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
f01006a0:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01006a5:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01006ab:	74 26                	je     f01006d3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006ad:	8d 50 01             	lea    0x1(%eax),%edx
f01006b0:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01006b6:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
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
f01006c7:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
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
f01006ea:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f01006f1:	75 10                	jne    f0100703 <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f01006f3:	83 ec 0c             	sub    $0xc,%esp
f01006f6:	68 68 2e 10 f0       	push   $0xf0102e68
f01006fb:	e8 b1 17 00 00       	call   f0101eb1 <cprintf>
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
f0100736:	68 c0 30 10 f0       	push   $0xf01030c0
f010073b:	68 de 30 10 f0       	push   $0xf01030de
f0100740:	68 e3 30 10 f0       	push   $0xf01030e3
f0100745:	e8 67 17 00 00       	call   f0101eb1 <cprintf>
f010074a:	83 c4 0c             	add    $0xc,%esp
f010074d:	68 80 31 10 f0       	push   $0xf0103180
f0100752:	68 ec 30 10 f0       	push   $0xf01030ec
f0100757:	68 e3 30 10 f0       	push   $0xf01030e3
f010075c:	e8 50 17 00 00       	call   f0101eb1 <cprintf>
f0100761:	83 c4 0c             	add    $0xc,%esp
f0100764:	68 f5 30 10 f0       	push   $0xf01030f5
f0100769:	68 09 31 10 f0       	push   $0xf0103109
f010076e:	68 e3 30 10 f0       	push   $0xf01030e3
f0100773:	e8 39 17 00 00       	call   f0101eb1 <cprintf>
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
f0100785:	68 13 31 10 f0       	push   $0xf0103113
f010078a:	e8 22 17 00 00       	call   f0101eb1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010078f:	83 c4 08             	add    $0x8,%esp
f0100792:	68 0c 00 10 00       	push   $0x10000c
f0100797:	68 a8 31 10 f0       	push   $0xf01031a8
f010079c:	e8 10 17 00 00       	call   f0101eb1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	68 0c 00 10 00       	push   $0x10000c
f01007a9:	68 0c 00 10 f0       	push   $0xf010000c
f01007ae:	68 d0 31 10 f0       	push   $0xf01031d0
f01007b3:	e8 f9 16 00 00       	call   f0101eb1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007b8:	83 c4 0c             	add    $0xc,%esp
f01007bb:	68 e1 2d 10 00       	push   $0x102de1
f01007c0:	68 e1 2d 10 f0       	push   $0xf0102de1
f01007c5:	68 f4 31 10 f0       	push   $0xf01031f4
f01007ca:	e8 e2 16 00 00       	call   f0101eb1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cf:	83 c4 0c             	add    $0xc,%esp
f01007d2:	68 00 63 11 00       	push   $0x116300
f01007d7:	68 00 63 11 f0       	push   $0xf0116300
f01007dc:	68 18 32 10 f0       	push   $0xf0103218
f01007e1:	e8 cb 16 00 00       	call   f0101eb1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e6:	83 c4 0c             	add    $0xc,%esp
f01007e9:	68 50 69 11 00       	push   $0x116950
f01007ee:	68 50 69 11 f0       	push   $0xf0116950
f01007f3:	68 3c 32 10 f0       	push   $0xf010323c
f01007f8:	e8 b4 16 00 00       	call   f0101eb1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007fd:	b8 4f 6d 11 f0       	mov    $0xf0116d4f,%eax
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
f010081e:	68 60 32 10 f0       	push   $0xf0103260
f0100823:	e8 89 16 00 00       	call   f0101eb1 <cprintf>
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
f0100853:	68 8c 32 10 f0       	push   $0xf010328c
f0100858:	e8 54 16 00 00       	call   f0101eb1 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f010085d:	83 c4 18             	add    $0x18,%esp
f0100860:	57                   	push   %edi
f0100861:	56                   	push   %esi
f0100862:	e8 54 17 00 00       	call   f0101fbb <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100867:	83 c4 08             	add    $0x8,%esp
f010086a:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010086d:	56                   	push   %esi
f010086e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100871:	ff 75 dc             	pushl  -0x24(%ebp)
f0100874:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100877:	ff 75 d0             	pushl  -0x30(%ebp)
f010087a:	68 2c 31 10 f0       	push   $0xf010312c
f010087f:	e8 2d 16 00 00       	call   f0101eb1 <cprintf>
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
f01008ce:	68 43 31 10 f0       	push   $0xf0103143
f01008d3:	e8 40 20 00 00       	call   f0102918 <strchr>
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
f01008f0:	68 48 31 10 f0       	push   $0xf0103148
f01008f5:	e8 b7 15 00 00       	call   f0101eb1 <cprintf>
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
f0100921:	68 43 31 10 f0       	push   $0xf0103143
f0100926:	e8 ed 1f 00 00       	call   f0102918 <strchr>
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
f0100950:	ff 34 85 20 33 10 f0 	pushl  -0xfefcce0(,%eax,4)
f0100957:	ff 75 a8             	pushl  -0x58(%ebp)
f010095a:	e8 5b 1f 00 00       	call   f01028ba <strcmp>
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
f0100974:	ff 14 85 28 33 10 f0 	call   *-0xfefccd8(,%eax,4)
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
f010098e:	68 65 31 10 f0       	push   $0xf0103165
f0100993:	e8 19 15 00 00       	call   f0101eb1 <cprintf>
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
f01009b2:	68 c0 32 10 f0       	push   $0xf01032c0
f01009b7:	e8 f5 14 00 00       	call   f0101eb1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009bc:	c7 04 24 e4 32 10 f0 	movl   $0xf01032e4,(%esp)
f01009c3:	e8 e9 14 00 00       	call   f0101eb1 <cprintf>
f01009c8:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009cb:	83 ec 0c             	sub    $0xc,%esp
f01009ce:	68 7b 31 10 f0       	push   $0xf010317b
f01009d3:	e8 26 1d 00 00       	call   f01026fe <readline>
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
f0100a12:	2b 05 4c 69 11 f0    	sub    0xf011694c,%eax
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
f0100a2b:	e8 07 14 00 00       	call   f0101e37 <mc146818_read>
f0100a30:	89 c6                	mov    %eax,%esi
f0100a32:	83 c3 01             	add    $0x1,%ebx
f0100a35:	89 1c 24             	mov    %ebx,(%esp)
f0100a38:	e8 fa 13 00 00       	call   f0101e37 <mc146818_read>
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
f0100a8e:	89 15 44 69 11 f0    	mov    %edx,0xf0116944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a94:	89 c2                	mov    %eax,%edx
f0100a96:	29 da                	sub    %ebx,%edx
f0100a98:	52                   	push   %edx
f0100a99:	53                   	push   %ebx
f0100a9a:	50                   	push   %eax
f0100a9b:	68 44 33 10 f0       	push   $0xf0103344
f0100aa0:	e8 0c 14 00 00       	call   f0101eb1 <cprintf>
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
f0100aaf:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f0100ab6:	75 11                	jne    f0100ac9 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ab8:	ba 4f 79 11 f0       	mov    $0xf011794f,%edx
f0100abd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ac3:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100ac9:	85 c0                	test   %eax,%eax
f0100acb:	75 06                	jne    f0100ad3 <boot_alloc+0x24>
f0100acd:	a1 38 65 11 f0       	mov    0xf0116538,%eax
f0100ad2:	c3                   	ret    
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100ad3:	8b 0d 38 65 11 f0    	mov    0xf0116538,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100ad9:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100adf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ae5:	01 ca                	add    %ecx,%edx
f0100ae7:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	if ((uint32_t)(nextfree-KERNBASE)>npages*PGSIZE) panic("not enough memory\n");//como chequeo esto? Uso nextfree vs npages*PGSIZE?
f0100aed:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100af3:	a1 44 69 11 f0       	mov    0xf0116944,%eax
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
f0100b05:	68 90 39 10 f0       	push   $0xf0103990
f0100b0a:	6a 6d                	push   $0x6d
f0100b0c:	68 a3 39 10 f0       	push   $0xf01039a3
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
f0100b25:	3b 1d 44 69 11 f0    	cmp    0xf0116944,%ebx
f0100b2b:	72 0d                	jb     f0100b3a <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b2d:	51                   	push   %ecx
f0100b2e:	68 80 33 10 f0       	push   $0xf0103380
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
f0100b57:	b8 af 39 10 f0       	mov    $0xf01039af,%eax
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
f0100b94:	ba bd 02 00 00       	mov    $0x2bd,%edx
f0100b99:	b8 a3 39 10 f0       	mov    $0xf01039a3,%eax
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
f0100be2:	68 a4 33 10 f0       	push   $0xf01033a4
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
f0100bfe:	8b 1d 48 69 11 f0    	mov    0xf0116948,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100c04:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0100c09:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c0c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100c13:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c18:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c1b:	a1 4c 69 11 f0       	mov    0xf011694c,%eax
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
f0100c3c:	ba 8e 02 00 00       	mov    $0x28e,%edx
f0100c41:	b8 a3 39 10 f0       	mov    $0xf01039a3,%eax
f0100c46:	e8 88 ff ff ff       	call   f0100bd3 <_paddr>
f0100c4b:	01 f0                	add    %esi,%eax
f0100c4d:	39 c7                	cmp    %eax,%edi
f0100c4f:	74 19                	je     f0100c6a <check_kern_pgdir+0x75>
f0100c51:	68 c8 33 10 f0       	push   $0xf01033c8
f0100c56:	68 bd 39 10 f0       	push   $0xf01039bd
f0100c5b:	68 8e 02 00 00       	push   $0x28e
f0100c60:	68 a3 39 10 f0       	push   $0xf01039a3
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
f0100c93:	68 fc 33 10 f0       	push   $0xf01033fc
f0100c98:	68 bd 39 10 f0       	push   $0xf01039bd
f0100c9d:	68 93 02 00 00       	push   $0x293
f0100ca2:	68 a3 39 10 f0       	push   $0xf01039a3
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
f0100cca:	b9 00 c0 10 f0       	mov    $0xf010c000,%ecx
f0100ccf:	ba 97 02 00 00       	mov    $0x297,%edx
f0100cd4:	b8 a3 39 10 f0       	mov    $0xf01039a3,%eax
f0100cd9:	e8 f5 fe ff ff       	call   f0100bd3 <_paddr>
f0100cde:	01 f0                	add    %esi,%eax
f0100ce0:	39 c7                	cmp    %eax,%edi
f0100ce2:	74 19                	je     f0100cfd <check_kern_pgdir+0x108>
f0100ce4:	68 24 34 10 f0       	push   $0xf0103424
f0100ce9:	68 bd 39 10 f0       	push   $0xf01039bd
f0100cee:	68 97 02 00 00       	push   $0x297
f0100cf3:	68 a3 39 10 f0       	push   $0xf01039a3
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
f0100d1c:	68 6c 34 10 f0       	push   $0xf010346c
f0100d21:	68 bd 39 10 f0       	push   $0xf01039bd
f0100d26:	68 98 02 00 00       	push   $0x298
f0100d2b:	68 a3 39 10 f0       	push   $0xf01039a3
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
f0100d54:	68 d2 39 10 f0       	push   $0xf01039d2
f0100d59:	68 bd 39 10 f0       	push   $0xf01039bd
f0100d5e:	68 a0 02 00 00       	push   $0x2a0
f0100d63:	68 a3 39 10 f0       	push   $0xf01039a3
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
f0100d81:	68 d2 39 10 f0       	push   $0xf01039d2
f0100d86:	68 bd 39 10 f0       	push   $0xf01039bd
f0100d8b:	68 a4 02 00 00       	push   $0x2a4
f0100d90:	68 a3 39 10 f0       	push   $0xf01039a3
f0100d95:	e8 f1 f2 ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0100d9a:	f6 c2 02             	test   $0x2,%dl
f0100d9d:	75 38                	jne    f0100dd7 <check_kern_pgdir+0x1e2>
f0100d9f:	68 e3 39 10 f0       	push   $0xf01039e3
f0100da4:	68 bd 39 10 f0       	push   $0xf01039bd
f0100da9:	68 a5 02 00 00       	push   $0x2a5
f0100dae:	68 a3 39 10 f0       	push   $0xf01039a3
f0100db3:	e8 d3 f2 ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0100db8:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100dbc:	74 19                	je     f0100dd7 <check_kern_pgdir+0x1e2>
f0100dbe:	68 f4 39 10 f0       	push   $0xf01039f4
f0100dc3:	68 bd 39 10 f0       	push   $0xf01039bd
f0100dc8:	68 a7 02 00 00       	push   $0x2a7
f0100dcd:	68 a3 39 10 f0       	push   $0xf01039a3
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
f0100de8:	68 9c 34 10 f0       	push   $0xf010349c
f0100ded:	e8 bf 10 00 00       	call   f0101eb1 <cprintf>
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
f0100e16:	68 bc 34 10 f0       	push   $0xf01034bc
f0100e1b:	68 fe 01 00 00       	push   $0x1fe
f0100e20:	68 a3 39 10 f0       	push   $0xf01039a3
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
f0100e6c:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
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
f0100e76:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
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
f0100ea1:	e8 af 1a 00 00       	call   f0102955 <memset>
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
f0100ebc:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ec2:	8b 35 4c 69 11 f0    	mov    0xf011694c,%esi
		assert(pp < pages + npages);
f0100ec8:	a1 44 69 11 f0       	mov    0xf0116944,%eax
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
f0100eeb:	68 02 3a 10 f0       	push   $0xf0103a02
f0100ef0:	68 bd 39 10 f0       	push   $0xf01039bd
f0100ef5:	68 18 02 00 00       	push   $0x218
f0100efa:	68 a3 39 10 f0       	push   $0xf01039a3
f0100eff:	e8 87 f1 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100f04:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100f07:	72 19                	jb     f0100f22 <check_page_free_list+0x125>
f0100f09:	68 0e 3a 10 f0       	push   $0xf0103a0e
f0100f0e:	68 bd 39 10 f0       	push   $0xf01039bd
f0100f13:	68 19 02 00 00       	push   $0x219
f0100f18:	68 a3 39 10 f0       	push   $0xf01039a3
f0100f1d:	e8 69 f1 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f22:	89 d8                	mov    %ebx,%eax
f0100f24:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100f27:	a8 07                	test   $0x7,%al
f0100f29:	74 19                	je     f0100f44 <check_page_free_list+0x147>
f0100f2b:	68 e0 34 10 f0       	push   $0xf01034e0
f0100f30:	68 bd 39 10 f0       	push   $0xf01039bd
f0100f35:	68 1a 02 00 00       	push   $0x21a
f0100f3a:	68 a3 39 10 f0       	push   $0xf01039a3
f0100f3f:	e8 47 f1 ff ff       	call   f010008b <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100f44:	89 d8                	mov    %ebx,%eax
f0100f46:	e8 c4 fa ff ff       	call   f0100a0f <page2pa>
f0100f4b:	85 c0                	test   %eax,%eax
f0100f4d:	75 19                	jne    f0100f68 <check_page_free_list+0x16b>
f0100f4f:	68 22 3a 10 f0       	push   $0xf0103a22
f0100f54:	68 bd 39 10 f0       	push   $0xf01039bd
f0100f59:	68 1d 02 00 00       	push   $0x21d
f0100f5e:	68 a3 39 10 f0       	push   $0xf01039a3
f0100f63:	e8 23 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f68:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f6d:	75 19                	jne    f0100f88 <check_page_free_list+0x18b>
f0100f6f:	68 33 3a 10 f0       	push   $0xf0103a33
f0100f74:	68 bd 39 10 f0       	push   $0xf01039bd
f0100f79:	68 1e 02 00 00       	push   $0x21e
f0100f7e:	68 a3 39 10 f0       	push   $0xf01039a3
f0100f83:	e8 03 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f88:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f8d:	75 19                	jne    f0100fa8 <check_page_free_list+0x1ab>
f0100f8f:	68 14 35 10 f0       	push   $0xf0103514
f0100f94:	68 bd 39 10 f0       	push   $0xf01039bd
f0100f99:	68 1f 02 00 00       	push   $0x21f
f0100f9e:	68 a3 39 10 f0       	push   $0xf01039a3
f0100fa3:	e8 e3 f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100fa8:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100fad:	75 19                	jne    f0100fc8 <check_page_free_list+0x1cb>
f0100faf:	68 4c 3a 10 f0       	push   $0xf0103a4c
f0100fb4:	68 bd 39 10 f0       	push   $0xf01039bd
f0100fb9:	68 20 02 00 00       	push   $0x220
f0100fbe:	68 a3 39 10 f0       	push   $0xf01039a3
f0100fc3:	e8 c3 f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fc8:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100fcd:	76 25                	jbe    f0100ff4 <check_page_free_list+0x1f7>
f0100fcf:	89 d8                	mov    %ebx,%eax
f0100fd1:	e8 6f fb ff ff       	call   f0100b45 <page2kva>
f0100fd6:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100fd9:	76 1e                	jbe    f0100ff9 <check_page_free_list+0x1fc>
f0100fdb:	68 38 35 10 f0       	push   $0xf0103538
f0100fe0:	68 bd 39 10 f0       	push   $0xf01039bd
f0100fe5:	68 21 02 00 00       	push   $0x221
f0100fea:	68 a3 39 10 f0       	push   $0xf01039a3
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
f010100b:	68 66 3a 10 f0       	push   $0xf0103a66
f0101010:	68 bd 39 10 f0       	push   $0xf01039bd
f0101015:	68 29 02 00 00       	push   $0x229
f010101a:	68 a3 39 10 f0       	push   $0xf01039a3
f010101f:	e8 67 f0 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0101024:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0101028:	7f 43                	jg     f010106d <check_page_free_list+0x270>
f010102a:	68 78 3a 10 f0       	push   $0xf0103a78
f010102f:	68 bd 39 10 f0       	push   $0xf01039bd
f0101034:	68 2a 02 00 00       	push   $0x22a
f0101039:	68 a3 39 10 f0       	push   $0xf01039a3
f010103e:	e8 48 f0 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101043:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0101049:	85 db                	test   %ebx,%ebx
f010104b:	0f 85 d9 fd ff ff    	jne    f0100e2a <check_page_free_list+0x2d>
f0101051:	e9 bd fd ff ff       	jmp    f0100e13 <check_page_free_list+0x16>
f0101056:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
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
f0101086:	ba 2c 01 00 00       	mov    $0x12c,%edx
f010108b:	b8 a3 39 10 f0       	mov    $0xf01039a3,%eax
f0101090:	e8 3e fb ff ff       	call   f0100bd3 <_paddr>
f0101095:	c1 e8 0c             	shr    $0xc,%eax
f0101098:	8b 35 3c 65 11 f0    	mov    0xf011653c,%esi
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
f01010bf:	03 1d 4c 69 11 f0    	add    0xf011694c,%ebx
f01010c5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f01010cb:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f01010cd:	89 ce                	mov    %ecx,%esi
f01010cf:	03 35 4c 69 11 f0    	add    0xf011694c,%esi
f01010d5:	b9 01 00 00 00       	mov    $0x1,%ecx
		page_free_list = &pages[i];
	}*/ //FOR ORIGINAL
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f01010da:	83 c2 01             	add    $0x1,%edx
f01010dd:	3b 15 44 69 11 f0    	cmp    0xf0116944,%edx
f01010e3:	72 c5                	jb     f01010aa <page_init+0x35>
f01010e5:	84 c9                	test   %cl,%cl
f01010e7:	74 06                	je     f01010ef <page_init+0x7a>
f01010e9:	89 35 3c 65 11 f0    	mov    %esi,0xf011653c
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
f01010fa:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0101100:	85 db                	test   %ebx,%ebx
f0101102:	74 2d                	je     f0101131 <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f0101104:	8b 03                	mov    (%ebx),%eax
f0101106:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
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
f0101129:	e8 27 18 00 00       	call   f0102955 <memset>
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
f010114b:	68 89 3a 10 f0       	push   $0xf0103a89
f0101150:	68 55 01 00 00       	push   $0x155
f0101155:	68 a3 39 10 f0       	push   $0xf01039a3
f010115a:	e8 2c ef ff ff       	call   f010008b <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");//mejorar mensaje?
f010115f:	83 38 00             	cmpl   $0x0,(%eax)
f0101162:	74 17                	je     f010117b <page_free+0x43>
f0101164:	83 ec 04             	sub    $0x4,%esp
f0101167:	68 80 35 10 f0       	push   $0xf0103580
f010116c:	68 56 01 00 00       	push   $0x156
f0101171:	68 a3 39 10 f0       	push   $0xf01039a3
f0101176:	e8 10 ef ff ff       	call   f010008b <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f010117b:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f0101181:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f0101183:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
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
f0101193:	83 3d 4c 69 11 f0 00 	cmpl   $0x0,0xf011694c
f010119a:	75 17                	jne    f01011b3 <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f010119c:	83 ec 04             	sub    $0x4,%esp
f010119f:	68 9d 3a 10 f0       	push   $0xf0103a9d
f01011a4:	68 3b 02 00 00       	push   $0x23b
f01011a9:	68 a3 39 10 f0       	push   $0xf01039a3
f01011ae:	e8 d8 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011b3:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
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
f01011db:	68 b8 3a 10 f0       	push   $0xf0103ab8
f01011e0:	68 bd 39 10 f0       	push   $0xf01039bd
f01011e5:	68 43 02 00 00       	push   $0x243
f01011ea:	68 a3 39 10 f0       	push   $0xf01039a3
f01011ef:	e8 97 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01011f4:	83 ec 0c             	sub    $0xc,%esp
f01011f7:	6a 00                	push   $0x0
f01011f9:	e8 f5 fe ff ff       	call   f01010f3 <page_alloc>
f01011fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101201:	83 c4 10             	add    $0x10,%esp
f0101204:	85 c0                	test   %eax,%eax
f0101206:	75 19                	jne    f0101221 <check_page_alloc+0x97>
f0101208:	68 ce 3a 10 f0       	push   $0xf0103ace
f010120d:	68 bd 39 10 f0       	push   $0xf01039bd
f0101212:	68 44 02 00 00       	push   $0x244
f0101217:	68 a3 39 10 f0       	push   $0xf01039a3
f010121c:	e8 6a ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101221:	83 ec 0c             	sub    $0xc,%esp
f0101224:	6a 00                	push   $0x0
f0101226:	e8 c8 fe ff ff       	call   f01010f3 <page_alloc>
f010122b:	89 c3                	mov    %eax,%ebx
f010122d:	83 c4 10             	add    $0x10,%esp
f0101230:	85 c0                	test   %eax,%eax
f0101232:	75 19                	jne    f010124d <check_page_alloc+0xc3>
f0101234:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0101239:	68 bd 39 10 f0       	push   $0xf01039bd
f010123e:	68 45 02 00 00       	push   $0x245
f0101243:	68 a3 39 10 f0       	push   $0xf01039a3
f0101248:	e8 3e ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010124d:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0101250:	75 19                	jne    f010126b <check_page_alloc+0xe1>
f0101252:	68 fa 3a 10 f0       	push   $0xf0103afa
f0101257:	68 bd 39 10 f0       	push   $0xf01039bd
f010125c:	68 48 02 00 00       	push   $0x248
f0101261:	68 a3 39 10 f0       	push   $0xf01039a3
f0101266:	e8 20 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010126b:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010126e:	74 04                	je     f0101274 <check_page_alloc+0xea>
f0101270:	39 c7                	cmp    %eax,%edi
f0101272:	75 19                	jne    f010128d <check_page_alloc+0x103>
f0101274:	68 ac 35 10 f0       	push   $0xf01035ac
f0101279:	68 bd 39 10 f0       	push   $0xf01039bd
f010127e:	68 49 02 00 00       	push   $0x249
f0101283:	68 a3 39 10 f0       	push   $0xf01039a3
f0101288:	e8 fe ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f010128d:	89 f8                	mov    %edi,%eax
f010128f:	e8 7b f7 ff ff       	call   f0100a0f <page2pa>
f0101294:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f010129a:	c1 e1 0c             	shl    $0xc,%ecx
f010129d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01012a0:	39 c8                	cmp    %ecx,%eax
f01012a2:	72 19                	jb     f01012bd <check_page_alloc+0x133>
f01012a4:	68 0c 3b 10 f0       	push   $0xf0103b0c
f01012a9:	68 bd 39 10 f0       	push   $0xf01039bd
f01012ae:	68 4a 02 00 00       	push   $0x24a
f01012b3:	68 a3 39 10 f0       	push   $0xf01039a3
f01012b8:	e8 ce ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012c0:	e8 4a f7 ff ff       	call   f0100a0f <page2pa>
f01012c5:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01012c8:	77 19                	ja     f01012e3 <check_page_alloc+0x159>
f01012ca:	68 29 3b 10 f0       	push   $0xf0103b29
f01012cf:	68 bd 39 10 f0       	push   $0xf01039bd
f01012d4:	68 4b 02 00 00       	push   $0x24b
f01012d9:	68 a3 39 10 f0       	push   $0xf01039a3
f01012de:	e8 a8 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01012e3:	89 d8                	mov    %ebx,%eax
f01012e5:	e8 25 f7 ff ff       	call   f0100a0f <page2pa>
f01012ea:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01012ed:	77 19                	ja     f0101308 <check_page_alloc+0x17e>
f01012ef:	68 46 3b 10 f0       	push   $0xf0103b46
f01012f4:	68 bd 39 10 f0       	push   $0xf01039bd
f01012f9:	68 4c 02 00 00       	push   $0x24c
f01012fe:	68 a3 39 10 f0       	push   $0xf01039a3
f0101303:	e8 83 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101308:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010130d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0101310:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f0101317:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010131a:	83 ec 0c             	sub    $0xc,%esp
f010131d:	6a 00                	push   $0x0
f010131f:	e8 cf fd ff ff       	call   f01010f3 <page_alloc>
f0101324:	83 c4 10             	add    $0x10,%esp
f0101327:	85 c0                	test   %eax,%eax
f0101329:	74 19                	je     f0101344 <check_page_alloc+0x1ba>
f010132b:	68 63 3b 10 f0       	push   $0xf0103b63
f0101330:	68 bd 39 10 f0       	push   $0xf01039bd
f0101335:	68 53 02 00 00       	push   $0x253
f010133a:	68 a3 39 10 f0       	push   $0xf01039a3
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
f0101375:	68 b8 3a 10 f0       	push   $0xf0103ab8
f010137a:	68 bd 39 10 f0       	push   $0xf01039bd
f010137f:	68 5a 02 00 00       	push   $0x25a
f0101384:	68 a3 39 10 f0       	push   $0xf01039a3
f0101389:	e8 fd ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010138e:	83 ec 0c             	sub    $0xc,%esp
f0101391:	6a 00                	push   $0x0
f0101393:	e8 5b fd ff ff       	call   f01010f3 <page_alloc>
f0101398:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010139b:	83 c4 10             	add    $0x10,%esp
f010139e:	85 c0                	test   %eax,%eax
f01013a0:	75 19                	jne    f01013bb <check_page_alloc+0x231>
f01013a2:	68 ce 3a 10 f0       	push   $0xf0103ace
f01013a7:	68 bd 39 10 f0       	push   $0xf01039bd
f01013ac:	68 5b 02 00 00       	push   $0x25b
f01013b1:	68 a3 39 10 f0       	push   $0xf01039a3
f01013b6:	e8 d0 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013bb:	83 ec 0c             	sub    $0xc,%esp
f01013be:	6a 00                	push   $0x0
f01013c0:	e8 2e fd ff ff       	call   f01010f3 <page_alloc>
f01013c5:	89 c7                	mov    %eax,%edi
f01013c7:	83 c4 10             	add    $0x10,%esp
f01013ca:	85 c0                	test   %eax,%eax
f01013cc:	75 19                	jne    f01013e7 <check_page_alloc+0x25d>
f01013ce:	68 e4 3a 10 f0       	push   $0xf0103ae4
f01013d3:	68 bd 39 10 f0       	push   $0xf01039bd
f01013d8:	68 5c 02 00 00       	push   $0x25c
f01013dd:	68 a3 39 10 f0       	push   $0xf01039a3
f01013e2:	e8 a4 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013e7:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01013ea:	75 19                	jne    f0101405 <check_page_alloc+0x27b>
f01013ec:	68 fa 3a 10 f0       	push   $0xf0103afa
f01013f1:	68 bd 39 10 f0       	push   $0xf01039bd
f01013f6:	68 5e 02 00 00       	push   $0x25e
f01013fb:	68 a3 39 10 f0       	push   $0xf01039a3
f0101400:	e8 86 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101405:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101408:	74 04                	je     f010140e <check_page_alloc+0x284>
f010140a:	39 c3                	cmp    %eax,%ebx
f010140c:	75 19                	jne    f0101427 <check_page_alloc+0x29d>
f010140e:	68 ac 35 10 f0       	push   $0xf01035ac
f0101413:	68 bd 39 10 f0       	push   $0xf01039bd
f0101418:	68 5f 02 00 00       	push   $0x25f
f010141d:	68 a3 39 10 f0       	push   $0xf01039a3
f0101422:	e8 64 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101427:	83 ec 0c             	sub    $0xc,%esp
f010142a:	6a 00                	push   $0x0
f010142c:	e8 c2 fc ff ff       	call   f01010f3 <page_alloc>
f0101431:	83 c4 10             	add    $0x10,%esp
f0101434:	85 c0                	test   %eax,%eax
f0101436:	74 19                	je     f0101451 <check_page_alloc+0x2c7>
f0101438:	68 63 3b 10 f0       	push   $0xf0103b63
f010143d:	68 bd 39 10 f0       	push   $0xf01039bd
f0101442:	68 60 02 00 00       	push   $0x260
f0101447:	68 a3 39 10 f0       	push   $0xf01039a3
f010144c:	e8 3a ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101451:	89 d8                	mov    %ebx,%eax
f0101453:	e8 ed f6 ff ff       	call   f0100b45 <page2kva>
f0101458:	83 ec 04             	sub    $0x4,%esp
f010145b:	68 00 10 00 00       	push   $0x1000
f0101460:	6a 01                	push   $0x1
f0101462:	50                   	push   %eax
f0101463:	e8 ed 14 00 00       	call   f0102955 <memset>
	page_free(pp0);
f0101468:	89 1c 24             	mov    %ebx,(%esp)
f010146b:	e8 c8 fc ff ff       	call   f0101138 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101470:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101477:	e8 77 fc ff ff       	call   f01010f3 <page_alloc>
f010147c:	83 c4 10             	add    $0x10,%esp
f010147f:	85 c0                	test   %eax,%eax
f0101481:	75 19                	jne    f010149c <check_page_alloc+0x312>
f0101483:	68 72 3b 10 f0       	push   $0xf0103b72
f0101488:	68 bd 39 10 f0       	push   $0xf01039bd
f010148d:	68 65 02 00 00       	push   $0x265
f0101492:	68 a3 39 10 f0       	push   $0xf01039a3
f0101497:	e8 ef eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010149c:	39 c3                	cmp    %eax,%ebx
f010149e:	74 19                	je     f01014b9 <check_page_alloc+0x32f>
f01014a0:	68 90 3b 10 f0       	push   $0xf0103b90
f01014a5:	68 bd 39 10 f0       	push   $0xf01039bd
f01014aa:	68 66 02 00 00       	push   $0x266
f01014af:	68 a3 39 10 f0       	push   $0xf01039a3
f01014b4:	e8 d2 eb ff ff       	call   f010008b <_panic>
	c = page2kva(pp);
f01014b9:	89 d8                	mov    %ebx,%eax
f01014bb:	e8 85 f6 ff ff       	call   f0100b45 <page2kva>
f01014c0:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014c6:	80 38 00             	cmpb   $0x0,(%eax)
f01014c9:	74 19                	je     f01014e4 <check_page_alloc+0x35a>
f01014cb:	68 a0 3b 10 f0       	push   $0xf0103ba0
f01014d0:	68 bd 39 10 f0       	push   $0xf01039bd
f01014d5:	68 69 02 00 00       	push   $0x269
f01014da:	68 a3 39 10 f0       	push   $0xf01039a3
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
f01014ee:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

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
f010150f:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
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
f0101526:	68 aa 3b 10 f0       	push   $0xf0103baa
f010152b:	68 bd 39 10 f0       	push   $0xf01039bd
f0101530:	68 76 02 00 00       	push   $0x276
f0101535:	68 a3 39 10 f0       	push   $0xf01039a3
f010153a:	e8 4c eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010153f:	83 ec 0c             	sub    $0xc,%esp
f0101542:	68 cc 35 10 f0       	push   $0xf01035cc
f0101547:	e8 65 09 00 00       	call   f0101eb1 <cprintf>
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
f010156e:	68 b8 3a 10 f0       	push   $0xf0103ab8
f0101573:	68 bd 39 10 f0       	push   $0xf01039bd
f0101578:	68 69 03 00 00       	push   $0x369
f010157d:	68 a3 39 10 f0       	push   $0xf01039a3
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
f010159c:	68 ce 3a 10 f0       	push   $0xf0103ace
f01015a1:	68 bd 39 10 f0       	push   $0xf01039bd
f01015a6:	68 6a 03 00 00       	push   $0x36a
f01015ab:	68 a3 39 10 f0       	push   $0xf01039a3
f01015b0:	e8 d6 ea ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01015b5:	83 ec 0c             	sub    $0xc,%esp
f01015b8:	6a 00                	push   $0x0
f01015ba:	e8 34 fb ff ff       	call   f01010f3 <page_alloc>
f01015bf:	89 c7                	mov    %eax,%edi
f01015c1:	83 c4 10             	add    $0x10,%esp
f01015c4:	85 c0                	test   %eax,%eax
f01015c6:	75 19                	jne    f01015e1 <check_page_installed_pgdir+0x8a>
f01015c8:	68 e4 3a 10 f0       	push   $0xf0103ae4
f01015cd:	68 bd 39 10 f0       	push   $0xf01039bd
f01015d2:	68 6b 03 00 00       	push   $0x36b
f01015d7:	68 a3 39 10 f0       	push   $0xf01039a3
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
f01015fc:	e8 54 13 00 00       	call   f0102955 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0101601:	89 f8                	mov    %edi,%eax
f0101603:	e8 3d f5 ff ff       	call   f0100b45 <page2kva>
f0101608:	83 c4 0c             	add    $0xc,%esp
f010160b:	68 00 10 00 00       	push   $0x1000
f0101610:	6a 02                	push   $0x2
f0101612:	50                   	push   %eax
f0101613:	e8 3d 13 00 00       	call   f0102955 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
	assert(pp1->pp_ref == 1);
f0101618:	83 c4 10             	add    $0x10,%esp
f010161b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101620:	74 19                	je     f010163b <check_page_installed_pgdir+0xe4>
f0101622:	68 b5 3b 10 f0       	push   $0xf0103bb5
f0101627:	68 bd 39 10 f0       	push   $0xf01039bd
f010162c:	68 70 03 00 00       	push   $0x370
f0101631:	68 a3 39 10 f0       	push   $0xf01039a3
f0101636:	e8 50 ea ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010163b:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0101642:	01 01 01 
f0101645:	74 19                	je     f0101660 <check_page_installed_pgdir+0x109>
f0101647:	68 ec 35 10 f0       	push   $0xf01035ec
f010164c:	68 bd 39 10 f0       	push   $0xf01039bd
f0101651:	68 71 03 00 00       	push   $0x371
f0101656:	68 a3 39 10 f0       	push   $0xf01039a3
f010165b:	e8 2b ea ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0101660:	68 10 36 10 f0       	push   $0xf0103610
f0101665:	68 bd 39 10 f0       	push   $0xf01039bd
f010166a:	68 73 03 00 00       	push   $0x373
f010166f:	68 a3 39 10 f0       	push   $0xf01039a3
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
f01016a3:	8b 45 0c             	mov    0xc(%ebp),%eax
	//primero asumo que esta todo creado, falta si no existe la PT
	uint32_t* aux =(uint32_t*) pgdir;	
	physaddr_t* ptdir = (physaddr_t*) PTE_ADDR(aux[PDX(va)]); //ojo que esto es P.Addr. !!
f01016a6:	89 c1                	mov    %eax,%ecx
f01016a8:	c1 e9 16             	shr    $0x16,%ecx
	aux = (uint32_t*) ptdir;	//hago esto porque se enoja el compilador, y el casteo adentro deja..
								//..horrible el codigo
	physaddr_t* pte = (physaddr_t*) PTE_ADDR(aux[PTX(va)]);  //misma atencion, esto tmb es P.Addr.
f01016ab:	8b 55 08             	mov    0x8(%ebp),%edx
f01016ae:	8b 14 8a             	mov    (%edx,%ecx,4),%edx
f01016b1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01016b7:	c1 e8 0c             	shr    $0xc,%eax
f01016ba:	25 ff 03 00 00       	and    $0x3ff,%eax
	return (pte_t*)pte;//esto se pide?
f01016bf:	8b 04 82             	mov    (%edx,%eax,4),%eax
f01016c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
f01016c7:	5d                   	pop    %ebp
f01016c8:	c3                   	ret    

f01016c9 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01016c9:	55                   	push   %ebp
f01016ca:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01016cc:	b8 00 00 00 00       	mov    $0x0,%eax
f01016d1:	5d                   	pop    %ebp
f01016d2:	c3                   	ret    

f01016d3 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01016d3:	55                   	push   %ebp
f01016d4:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01016d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01016db:	5d                   	pop    %ebp
f01016dc:	c3                   	ret    

f01016dd <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f01016dd:	55                   	push   %ebp
f01016de:	89 e5                	mov    %esp,%ebp
f01016e0:	57                   	push   %edi
f01016e1:	56                   	push   %esi
f01016e2:	53                   	push   %ebx
f01016e3:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016e6:	6a 00                	push   $0x0
f01016e8:	e8 06 fa ff ff       	call   f01010f3 <page_alloc>
f01016ed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016f0:	83 c4 10             	add    $0x10,%esp
f01016f3:	85 c0                	test   %eax,%eax
f01016f5:	75 19                	jne    f0101710 <check_page+0x33>
f01016f7:	68 b8 3a 10 f0       	push   $0xf0103ab8
f01016fc:	68 bd 39 10 f0       	push   $0xf01039bd
f0101701:	68 d1 02 00 00       	push   $0x2d1
f0101706:	68 a3 39 10 f0       	push   $0xf01039a3
f010170b:	e8 7b e9 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101710:	83 ec 0c             	sub    $0xc,%esp
f0101713:	6a 00                	push   $0x0
f0101715:	e8 d9 f9 ff ff       	call   f01010f3 <page_alloc>
f010171a:	89 c6                	mov    %eax,%esi
f010171c:	83 c4 10             	add    $0x10,%esp
f010171f:	85 c0                	test   %eax,%eax
f0101721:	75 19                	jne    f010173c <check_page+0x5f>
f0101723:	68 ce 3a 10 f0       	push   $0xf0103ace
f0101728:	68 bd 39 10 f0       	push   $0xf01039bd
f010172d:	68 d2 02 00 00       	push   $0x2d2
f0101732:	68 a3 39 10 f0       	push   $0xf01039a3
f0101737:	e8 4f e9 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010173c:	83 ec 0c             	sub    $0xc,%esp
f010173f:	6a 00                	push   $0x0
f0101741:	e8 ad f9 ff ff       	call   f01010f3 <page_alloc>
f0101746:	89 c3                	mov    %eax,%ebx
f0101748:	83 c4 10             	add    $0x10,%esp
f010174b:	85 c0                	test   %eax,%eax
f010174d:	75 19                	jne    f0101768 <check_page+0x8b>
f010174f:	68 e4 3a 10 f0       	push   $0xf0103ae4
f0101754:	68 bd 39 10 f0       	push   $0xf01039bd
f0101759:	68 d3 02 00 00       	push   $0x2d3
f010175e:	68 a3 39 10 f0       	push   $0xf01039a3
f0101763:	e8 23 e9 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101768:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f010176b:	75 19                	jne    f0101786 <check_page+0xa9>
f010176d:	68 fa 3a 10 f0       	push   $0xf0103afa
f0101772:	68 bd 39 10 f0       	push   $0xf01039bd
f0101777:	68 d6 02 00 00       	push   $0x2d6
f010177c:	68 a3 39 10 f0       	push   $0xf01039a3
f0101781:	e8 05 e9 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101786:	39 c6                	cmp    %eax,%esi
f0101788:	74 05                	je     f010178f <check_page+0xb2>
f010178a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010178d:	75 19                	jne    f01017a8 <check_page+0xcb>
f010178f:	68 ac 35 10 f0       	push   $0xf01035ac
f0101794:	68 bd 39 10 f0       	push   $0xf01039bd
f0101799:	68 d7 02 00 00       	push   $0x2d7
f010179e:	68 a3 39 10 f0       	push   $0xf01039a3
f01017a3:	e8 e3 e8 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f01017a8:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f01017af:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01017b2:	83 ec 0c             	sub    $0xc,%esp
f01017b5:	6a 00                	push   $0x0
f01017b7:	e8 37 f9 ff ff       	call   f01010f3 <page_alloc>
f01017bc:	83 c4 10             	add    $0x10,%esp
f01017bf:	85 c0                	test   %eax,%eax
f01017c1:	74 19                	je     f01017dc <check_page+0xff>
f01017c3:	68 63 3b 10 f0       	push   $0xf0103b63
f01017c8:	68 bd 39 10 f0       	push   $0xf01039bd
f01017cd:	68 de 02 00 00       	push   $0x2de
f01017d2:	68 a3 39 10 f0       	push   $0xf01039a3
f01017d7:	e8 af e8 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01017dc:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f01017e2:	83 ec 04             	sub    $0x4,%esp
f01017e5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01017e8:	50                   	push   %eax
f01017e9:	6a 00                	push   $0x0
f01017eb:	57                   	push   %edi
f01017ec:	e8 e2 fe ff ff       	call   f01016d3 <page_lookup>
f01017f1:	83 c4 10             	add    $0x10,%esp
f01017f4:	85 c0                	test   %eax,%eax
f01017f6:	74 19                	je     f0101811 <check_page+0x134>
f01017f8:	68 34 36 10 f0       	push   $0xf0103634
f01017fd:	68 bd 39 10 f0       	push   $0xf01039bd
f0101802:	68 e1 02 00 00       	push   $0x2e1
f0101807:	68 a3 39 10 f0       	push   $0xf01039a3
f010180c:	e8 7a e8 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101811:	6a 02                	push   $0x2
f0101813:	6a 00                	push   $0x0
f0101815:	56                   	push   %esi
f0101816:	57                   	push   %edi
f0101817:	e8 ad fe ff ff       	call   f01016c9 <page_insert>
f010181c:	83 c4 10             	add    $0x10,%esp
f010181f:	85 c0                	test   %eax,%eax
f0101821:	78 19                	js     f010183c <check_page+0x15f>
f0101823:	68 6c 36 10 f0       	push   $0xf010366c
f0101828:	68 bd 39 10 f0       	push   $0xf01039bd
f010182d:	68 e4 02 00 00       	push   $0x2e4
f0101832:	68 a3 39 10 f0       	push   $0xf01039a3
f0101837:	e8 4f e8 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010183c:	83 ec 0c             	sub    $0xc,%esp
f010183f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101842:	e8 f1 f8 ff ff       	call   f0101138 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101847:	8b 3d 48 69 11 f0    	mov    0xf0116948,%edi
f010184d:	6a 02                	push   $0x2
f010184f:	6a 00                	push   $0x0
f0101851:	56                   	push   %esi
f0101852:	57                   	push   %edi
f0101853:	e8 71 fe ff ff       	call   f01016c9 <page_insert>
f0101858:	83 c4 20             	add    $0x20,%esp
f010185b:	85 c0                	test   %eax,%eax
f010185d:	74 19                	je     f0101878 <check_page+0x19b>
f010185f:	68 9c 36 10 f0       	push   $0xf010369c
f0101864:	68 bd 39 10 f0       	push   $0xf01039bd
f0101869:	68 e8 02 00 00       	push   $0x2e8
f010186e:	68 a3 39 10 f0       	push   $0xf01039a3
f0101873:	e8 13 e8 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101878:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010187b:	e8 8f f1 ff ff       	call   f0100a0f <page2pa>
f0101880:	8b 17                	mov    (%edi),%edx
f0101882:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101888:	39 c2                	cmp    %eax,%edx
f010188a:	74 19                	je     f01018a5 <check_page+0x1c8>
f010188c:	68 cc 36 10 f0       	push   $0xf01036cc
f0101891:	68 bd 39 10 f0       	push   $0xf01039bd
f0101896:	68 e9 02 00 00       	push   $0x2e9
f010189b:	68 a3 39 10 f0       	push   $0xf01039a3
f01018a0:	e8 e6 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01018a5:	ba 00 00 00 00       	mov    $0x0,%edx
f01018aa:	89 f8                	mov    %edi,%eax
f01018ac:	e8 b2 f2 ff ff       	call   f0100b63 <check_va2pa>
f01018b1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01018b4:	89 f0                	mov    %esi,%eax
f01018b6:	e8 54 f1 ff ff       	call   f0100a0f <page2pa>
f01018bb:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01018be:	74 19                	je     f01018d9 <check_page+0x1fc>
f01018c0:	68 f4 36 10 f0       	push   $0xf01036f4
f01018c5:	68 bd 39 10 f0       	push   $0xf01039bd
f01018ca:	68 ea 02 00 00       	push   $0x2ea
f01018cf:	68 a3 39 10 f0       	push   $0xf01039a3
f01018d4:	e8 b2 e7 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01018d9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018de:	74 19                	je     f01018f9 <check_page+0x21c>
f01018e0:	68 b5 3b 10 f0       	push   $0xf0103bb5
f01018e5:	68 bd 39 10 f0       	push   $0xf01039bd
f01018ea:	68 eb 02 00 00       	push   $0x2eb
f01018ef:	68 a3 39 10 f0       	push   $0xf01039a3
f01018f4:	e8 92 e7 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f01018f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018fc:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101901:	74 19                	je     f010191c <check_page+0x23f>
f0101903:	68 c6 3b 10 f0       	push   $0xf0103bc6
f0101908:	68 bd 39 10 f0       	push   $0xf01039bd
f010190d:	68 ec 02 00 00       	push   $0x2ec
f0101912:	68 a3 39 10 f0       	push   $0xf01039a3
f0101917:	e8 6f e7 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010191c:	6a 02                	push   $0x2
f010191e:	68 00 10 00 00       	push   $0x1000
f0101923:	53                   	push   %ebx
f0101924:	57                   	push   %edi
f0101925:	e8 9f fd ff ff       	call   f01016c9 <page_insert>
f010192a:	83 c4 10             	add    $0x10,%esp
f010192d:	85 c0                	test   %eax,%eax
f010192f:	74 19                	je     f010194a <check_page+0x26d>
f0101931:	68 24 37 10 f0       	push   $0xf0103724
f0101936:	68 bd 39 10 f0       	push   $0xf01039bd
f010193b:	68 ef 02 00 00       	push   $0x2ef
f0101940:	68 a3 39 10 f0       	push   $0xf01039a3
f0101945:	e8 41 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010194a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010194f:	89 f8                	mov    %edi,%eax
f0101951:	e8 0d f2 ff ff       	call   f0100b63 <check_va2pa>
f0101956:	89 c6                	mov    %eax,%esi
f0101958:	89 d8                	mov    %ebx,%eax
f010195a:	e8 b0 f0 ff ff       	call   f0100a0f <page2pa>
f010195f:	39 c6                	cmp    %eax,%esi
f0101961:	74 19                	je     f010197c <check_page+0x29f>
f0101963:	68 60 37 10 f0       	push   $0xf0103760
f0101968:	68 bd 39 10 f0       	push   $0xf01039bd
f010196d:	68 f0 02 00 00       	push   $0x2f0
f0101972:	68 a3 39 10 f0       	push   $0xf01039a3
f0101977:	e8 0f e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010197c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101981:	74 19                	je     f010199c <check_page+0x2bf>
f0101983:	68 d7 3b 10 f0       	push   $0xf0103bd7
f0101988:	68 bd 39 10 f0       	push   $0xf01039bd
f010198d:	68 f1 02 00 00       	push   $0x2f1
f0101992:	68 a3 39 10 f0       	push   $0xf01039a3
f0101997:	e8 ef e6 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010199c:	83 ec 0c             	sub    $0xc,%esp
f010199f:	6a 00                	push   $0x0
f01019a1:	e8 4d f7 ff ff       	call   f01010f3 <page_alloc>
f01019a6:	83 c4 10             	add    $0x10,%esp
f01019a9:	85 c0                	test   %eax,%eax
f01019ab:	74 19                	je     f01019c6 <check_page+0x2e9>
f01019ad:	68 63 3b 10 f0       	push   $0xf0103b63
f01019b2:	68 bd 39 10 f0       	push   $0xf01039bd
f01019b7:	68 f4 02 00 00       	push   $0x2f4
f01019bc:	68 a3 39 10 f0       	push   $0xf01039a3
f01019c1:	e8 c5 e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019c6:	8b 35 48 69 11 f0    	mov    0xf0116948,%esi
f01019cc:	6a 02                	push   $0x2
f01019ce:	68 00 10 00 00       	push   $0x1000
f01019d3:	53                   	push   %ebx
f01019d4:	56                   	push   %esi
f01019d5:	e8 ef fc ff ff       	call   f01016c9 <page_insert>
f01019da:	83 c4 10             	add    $0x10,%esp
f01019dd:	85 c0                	test   %eax,%eax
f01019df:	74 19                	je     f01019fa <check_page+0x31d>
f01019e1:	68 24 37 10 f0       	push   $0xf0103724
f01019e6:	68 bd 39 10 f0       	push   $0xf01039bd
f01019eb:	68 f7 02 00 00       	push   $0x2f7
f01019f0:	68 a3 39 10 f0       	push   $0xf01039a3
f01019f5:	e8 91 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019fa:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019ff:	89 f0                	mov    %esi,%eax
f0101a01:	e8 5d f1 ff ff       	call   f0100b63 <check_va2pa>
f0101a06:	89 c6                	mov    %eax,%esi
f0101a08:	89 d8                	mov    %ebx,%eax
f0101a0a:	e8 00 f0 ff ff       	call   f0100a0f <page2pa>
f0101a0f:	39 c6                	cmp    %eax,%esi
f0101a11:	74 19                	je     f0101a2c <check_page+0x34f>
f0101a13:	68 60 37 10 f0       	push   $0xf0103760
f0101a18:	68 bd 39 10 f0       	push   $0xf01039bd
f0101a1d:	68 f8 02 00 00       	push   $0x2f8
f0101a22:	68 a3 39 10 f0       	push   $0xf01039a3
f0101a27:	e8 5f e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a2c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a31:	74 19                	je     f0101a4c <check_page+0x36f>
f0101a33:	68 d7 3b 10 f0       	push   $0xf0103bd7
f0101a38:	68 bd 39 10 f0       	push   $0xf01039bd
f0101a3d:	68 f9 02 00 00       	push   $0x2f9
f0101a42:	68 a3 39 10 f0       	push   $0xf01039a3
f0101a47:	e8 3f e6 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101a4c:	83 ec 0c             	sub    $0xc,%esp
f0101a4f:	6a 00                	push   $0x0
f0101a51:	e8 9d f6 ff ff       	call   f01010f3 <page_alloc>
f0101a56:	83 c4 10             	add    $0x10,%esp
f0101a59:	85 c0                	test   %eax,%eax
f0101a5b:	74 19                	je     f0101a76 <check_page+0x399>
f0101a5d:	68 63 3b 10 f0       	push   $0xf0103b63
f0101a62:	68 bd 39 10 f0       	push   $0xf01039bd
f0101a67:	68 fd 02 00 00       	push   $0x2fd
f0101a6c:	68 a3 39 10 f0       	push   $0xf01039a3
f0101a71:	e8 15 e6 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101a76:	8b 35 48 69 11 f0    	mov    0xf0116948,%esi
f0101a7c:	8b 3e                	mov    (%esi),%edi
f0101a7e:	89 f9                	mov    %edi,%ecx
f0101a80:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101a86:	ba 00 03 00 00       	mov    $0x300,%edx
f0101a8b:	b8 a3 39 10 f0       	mov    $0xf01039a3,%eax
f0101a90:	e8 84 f0 ff ff       	call   f0100b19 <_kaddr>
f0101a95:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a98:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101a9b:	83 ec 04             	sub    $0x4,%esp
f0101a9e:	6a 00                	push   $0x0
f0101aa0:	68 00 10 00 00       	push   $0x1000
f0101aa5:	56                   	push   %esi
f0101aa6:	e8 f5 fb ff ff       	call   f01016a0 <pgdir_walk>
f0101aab:	83 c4 10             	add    $0x10,%esp
f0101aae:	89 c2                	mov    %eax,%edx
f0101ab0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ab3:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ab6:	8d 41 04             	lea    0x4(%ecx),%eax
f0101ab9:	39 c2                	cmp    %eax,%edx
f0101abb:	74 19                	je     f0101ad6 <check_page+0x3f9>
f0101abd:	68 90 37 10 f0       	push   $0xf0103790
f0101ac2:	68 bd 39 10 f0       	push   $0xf01039bd
f0101ac7:	68 01 03 00 00       	push   $0x301
f0101acc:	68 a3 39 10 f0       	push   $0xf01039a3
f0101ad1:	e8 b5 e5 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101ad6:	6a 06                	push   $0x6
f0101ad8:	68 00 10 00 00       	push   $0x1000
f0101add:	53                   	push   %ebx
f0101ade:	56                   	push   %esi
f0101adf:	e8 e5 fb ff ff       	call   f01016c9 <page_insert>
f0101ae4:	83 c4 10             	add    $0x10,%esp
f0101ae7:	85 c0                	test   %eax,%eax
f0101ae9:	74 19                	je     f0101b04 <check_page+0x427>
f0101aeb:	68 d0 37 10 f0       	push   $0xf01037d0
f0101af0:	68 bd 39 10 f0       	push   $0xf01039bd
f0101af5:	68 04 03 00 00       	push   $0x304
f0101afa:	68 a3 39 10 f0       	push   $0xf01039a3
f0101aff:	e8 87 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b04:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b09:	89 f0                	mov    %esi,%eax
f0101b0b:	e8 53 f0 ff ff       	call   f0100b63 <check_va2pa>
f0101b10:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b13:	89 d8                	mov    %ebx,%eax
f0101b15:	e8 f5 ee ff ff       	call   f0100a0f <page2pa>
f0101b1a:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101b1d:	74 19                	je     f0101b38 <check_page+0x45b>
f0101b1f:	68 60 37 10 f0       	push   $0xf0103760
f0101b24:	68 bd 39 10 f0       	push   $0xf01039bd
f0101b29:	68 05 03 00 00       	push   $0x305
f0101b2e:	68 a3 39 10 f0       	push   $0xf01039a3
f0101b33:	e8 53 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101b38:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b3d:	74 19                	je     f0101b58 <check_page+0x47b>
f0101b3f:	68 d7 3b 10 f0       	push   $0xf0103bd7
f0101b44:	68 bd 39 10 f0       	push   $0xf01039bd
f0101b49:	68 06 03 00 00       	push   $0x306
f0101b4e:	68 a3 39 10 f0       	push   $0xf01039a3
f0101b53:	e8 33 e5 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b58:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b5b:	8b 00                	mov    (%eax),%eax
f0101b5d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b60:	a8 04                	test   $0x4,%al
f0101b62:	75 19                	jne    f0101b7d <check_page+0x4a0>
f0101b64:	68 10 38 10 f0       	push   $0xf0103810
f0101b69:	68 bd 39 10 f0       	push   $0xf01039bd
f0101b6e:	68 07 03 00 00       	push   $0x307
f0101b73:	68 a3 39 10 f0       	push   $0xf01039a3
f0101b78:	e8 0e e5 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101b7d:	f7 c7 04 00 00 00    	test   $0x4,%edi
f0101b83:	75 19                	jne    f0101b9e <check_page+0x4c1>
f0101b85:	68 e8 3b 10 f0       	push   $0xf0103be8
f0101b8a:	68 bd 39 10 f0       	push   $0xf01039bd
f0101b8f:	68 08 03 00 00       	push   $0x308
f0101b94:	68 a3 39 10 f0       	push   $0xf01039a3
f0101b99:	e8 ed e4 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b9e:	6a 02                	push   $0x2
f0101ba0:	68 00 10 00 00       	push   $0x1000
f0101ba5:	53                   	push   %ebx
f0101ba6:	56                   	push   %esi
f0101ba7:	e8 1d fb ff ff       	call   f01016c9 <page_insert>
f0101bac:	83 c4 10             	add    $0x10,%esp
f0101baf:	85 c0                	test   %eax,%eax
f0101bb1:	74 19                	je     f0101bcc <check_page+0x4ef>
f0101bb3:	68 24 37 10 f0       	push   $0xf0103724
f0101bb8:	68 bd 39 10 f0       	push   $0xf01039bd
f0101bbd:	68 0b 03 00 00       	push   $0x30b
f0101bc2:	68 a3 39 10 f0       	push   $0xf01039a3
f0101bc7:	e8 bf e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101bcc:	f6 45 d4 02          	testb  $0x2,-0x2c(%ebp)
f0101bd0:	75 19                	jne    f0101beb <check_page+0x50e>
f0101bd2:	68 44 38 10 f0       	push   $0xf0103844
f0101bd7:	68 bd 39 10 f0       	push   $0xf01039bd
f0101bdc:	68 0c 03 00 00       	push   $0x30c
f0101be1:	68 a3 39 10 f0       	push   $0xf01039a3
f0101be6:	e8 a0 e4 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101beb:	68 78 38 10 f0       	push   $0xf0103878
f0101bf0:	68 bd 39 10 f0       	push   $0xf01039bd
f0101bf5:	68 0d 03 00 00       	push   $0x30d
f0101bfa:	68 a3 39 10 f0       	push   $0xf01039a3
f0101bff:	e8 87 e4 ff ff       	call   f010008b <_panic>

f0101c04 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101c04:	55                   	push   %ebp
f0101c05:	89 e5                	mov    %esp,%ebp
f0101c07:	53                   	push   %ebx
f0101c08:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f0101c0b:	e8 39 ee ff ff       	call   f0100a49 <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101c10:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101c15:	e8 95 ee ff ff       	call   f0100aaf <boot_alloc>
f0101c1a:	a3 48 69 11 f0       	mov    %eax,0xf0116948
	memset(kern_pgdir, 0, PGSIZE);
f0101c1f:	83 ec 04             	sub    $0x4,%esp
f0101c22:	68 00 10 00 00       	push   $0x1000
f0101c27:	6a 00                	push   $0x0
f0101c29:	50                   	push   %eax
f0101c2a:	e8 26 0d 00 00       	call   f0102955 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101c2f:	8b 1d 48 69 11 f0    	mov    0xf0116948,%ebx
f0101c35:	89 d9                	mov    %ebx,%ecx
f0101c37:	ba 92 00 00 00       	mov    $0x92,%edx
f0101c3c:	b8 a3 39 10 f0       	mov    $0xf01039a3,%eax
f0101c41:	e8 8d ef ff ff       	call   f0100bd3 <_paddr>
f0101c46:	83 c8 05             	or     $0x5,%eax
f0101c49:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	//Un PageInfo tiene 4B del PageInfo* +4B del uint16_t = 8B de size

	pages=(struct PageInfo *) boot_alloc(npages //[page]
f0101c4f:	a1 44 69 11 f0       	mov    0xf0116944,%eax
f0101c54:	c1 e0 03             	shl    $0x3,%eax
f0101c57:	e8 53 ee ff ff       	call   f0100aaf <boot_alloc>
f0101c5c:	a3 4c 69 11 f0       	mov    %eax,0xf011694c
										 * sizeof(struct PageInfo));//[B/page]

	memset(pages,0,npages*sizeof(struct PageInfo));
f0101c61:	83 c4 0c             	add    $0xc,%esp
f0101c64:	8b 0d 44 69 11 f0    	mov    0xf0116944,%ecx
f0101c6a:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101c71:	52                   	push   %edx
f0101c72:	6a 00                	push   $0x0
f0101c74:	50                   	push   %eax
f0101c75:	e8 db 0c 00 00       	call   f0102955 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101c7a:	e8 f6 f3 ff ff       	call   f0101075 <page_init>


	//parte de pruebas
	cprintf("\n***PRUEBAS DADA UN LINEAR ADDR***\n");
f0101c7f:	c7 04 24 b0 38 10 f0 	movl   $0xf01038b0,(%esp)
f0101c86:	e8 26 02 00 00       	call   f0101eb1 <cprintf>
	pde_t* kpd = kern_pgdir;
f0101c8b:	8b 1d 48 69 11 f0    	mov    0xf0116948,%ebx
	cprintf("	kern_pgdir es %p (32b)\n",kpd);
f0101c91:	83 c4 08             	add    $0x8,%esp
f0101c94:	53                   	push   %ebx
f0101c95:	68 fe 3b 10 f0       	push   $0xf0103bfe
f0101c9a:	e8 12 02 00 00       	call   f0101eb1 <cprintf>
	cprintf("	PD index es %p (10b)\n",PDX(kpd));
f0101c9f:	83 c4 08             	add    $0x8,%esp
f0101ca2:	89 d8                	mov    %ebx,%eax
f0101ca4:	c1 e8 16             	shr    $0x16,%eax
f0101ca7:	50                   	push   %eax
f0101ca8:	68 17 3c 10 f0       	push   $0xf0103c17
f0101cad:	e8 ff 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	PT index es %p (10b)\n",PTX(kpd));
f0101cb2:	83 c4 08             	add    $0x8,%esp
f0101cb5:	89 d8                	mov    %ebx,%eax
f0101cb7:	c1 e8 0c             	shr    $0xc,%eax
f0101cba:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101cbf:	50                   	push   %eax
f0101cc0:	68 2e 3c 10 f0       	push   $0xf0103c2e
f0101cc5:	e8 e7 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	PG offset es %p (12b)\n",PGOFF(kpd));
f0101cca:	83 c4 08             	add    $0x8,%esp
f0101ccd:	89 d8                	mov    %ebx,%eax
f0101ccf:	25 ff 0f 00 00       	and    $0xfff,%eax
f0101cd4:	50                   	push   %eax
f0101cd5:	68 45 3c 10 f0       	push   $0xf0103c45
f0101cda:	e8 d2 01 00 00       	call   f0101eb1 <cprintf>

	void* va1 = (void*) 0x7fe1b6a7;
	cprintf("\n***ACCEDIENDO A KERN_PGDIR con VA = %p***\n",va1);
f0101cdf:	83 c4 08             	add    $0x8,%esp
f0101ce2:	68 a7 b6 e1 7f       	push   $0x7fe1b6a7
f0101ce7:	68 d4 38 10 f0       	push   $0xf01038d4
f0101cec:	e8 c0 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	PD index es %p (10b)\n",PDX(va1));
f0101cf1:	83 c4 08             	add    $0x8,%esp
f0101cf4:	68 ff 01 00 00       	push   $0x1ff
f0101cf9:	68 17 3c 10 f0       	push   $0xf0103c17
f0101cfe:	e8 ae 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	PT index es %p (10b)\n",PTX(va1));
f0101d03:	83 c4 08             	add    $0x8,%esp
f0101d06:	68 1b 02 00 00       	push   $0x21b
f0101d0b:	68 2e 3c 10 f0       	push   $0xf0103c2e
f0101d10:	e8 9c 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	PG offset es %p (12b)\n",PGOFF(va1));
f0101d15:	83 c4 08             	add    $0x8,%esp
f0101d18:	68 a7 06 00 00       	push   $0x6a7
f0101d1d:	68 45 3c 10 f0       	push   $0xf0103c45
f0101d22:	e8 8a 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	kern_pgdir[PDX] es %p (32b)\n",kpd+PDX(va1));
f0101d27:	83 c4 08             	add    $0x8,%esp
f0101d2a:	8d 83 fc 07 00 00    	lea    0x7fc(%ebx),%eax
f0101d30:	50                   	push   %eax
f0101d31:	68 5d 3c 10 f0       	push   $0xf0103c5d
f0101d36:	e8 76 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	y su contenido es %p (32b)\n",kpd[PDX(va1)]);
f0101d3b:	83 c4 08             	add    $0x8,%esp
f0101d3e:	ff b3 fc 07 00 00    	pushl  0x7fc(%ebx)
f0101d44:	68 7b 3c 10 f0       	push   $0xf0103c7b
f0101d49:	e8 63 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	o tambien es %p (32b)\n",*(kpd+PDX(va1)));
f0101d4e:	83 c4 08             	add    $0x8,%esp
f0101d51:	ff b3 fc 07 00 00    	pushl  0x7fc(%ebx)
f0101d57:	68 98 3c 10 f0       	push   $0xf0103c98
f0101d5c:	e8 50 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	que maskeado es %p (32b, ultimos 10 en 0)\n",PTE_ADDR(kpd[PDX(va1)]));
f0101d61:	83 c4 08             	add    $0x8,%esp
f0101d64:	8b 83 fc 07 00 00    	mov    0x7fc(%ebx),%eax
f0101d6a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101d6f:	50                   	push   %eax
f0101d70:	68 00 39 10 f0       	push   $0xf0103900
f0101d75:	e8 37 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	kern_pgdir[PTX] es %p (32b)\n",kpd+PTX(va1));
f0101d7a:	83 c4 08             	add    $0x8,%esp
f0101d7d:	8d 83 6c 08 00 00    	lea    0x86c(%ebx),%eax
f0101d83:	50                   	push   %eax
f0101d84:	68 b0 3c 10 f0       	push   $0xf0103cb0
f0101d89:	e8 23 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	y su contenido es %p (32b)\n",kpd[PTX(va1)]);
f0101d8e:	83 c4 08             	add    $0x8,%esp
f0101d91:	ff b3 6c 08 00 00    	pushl  0x86c(%ebx)
f0101d97:	68 7b 3c 10 f0       	push   $0xf0103c7b
f0101d9c:	e8 10 01 00 00       	call   f0101eb1 <cprintf>
	cprintf("	o tambien es %p (32b)\n",*(kpd+PTX(va1)));
f0101da1:	83 c4 08             	add    $0x8,%esp
f0101da4:	ff b3 6c 08 00 00    	pushl  0x86c(%ebx)
f0101daa:	68 98 3c 10 f0       	push   $0xf0103c98
f0101daf:	e8 fd 00 00 00       	call   f0101eb1 <cprintf>
	cprintf("	que maskeado es %p (32b, ultimos 10 en 0)\n",PTE_ADDR(kpd[PTX(va1)]));
f0101db4:	83 c4 08             	add    $0x8,%esp
f0101db7:	8b 83 6c 08 00 00    	mov    0x86c(%ebx),%eax
f0101dbd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101dc2:	50                   	push   %eax
f0101dc3:	68 00 39 10 f0       	push   $0xf0103900
f0101dc8:	e8 e4 00 00 00       	call   f0101eb1 <cprintf>

	cprintf("\n***OPERACIONES DE MASKING con VA = %p***\n",va1);
f0101dcd:	83 c4 08             	add    $0x8,%esp
f0101dd0:	68 a7 b6 e1 7f       	push   $0x7fe1b6a7
f0101dd5:	68 2c 39 10 f0       	push   $0xf010392c
f0101dda:	e8 d2 00 00 00       	call   f0101eb1 <cprintf>
	cprintf("	maskeada con PTE_ADDR es %p (vuela los 12 de abajo)\n",PTE_ADDR(va1));
f0101ddf:	83 c4 08             	add    $0x8,%esp
f0101de2:	68 00 b0 e1 7f       	push   $0x7fe1b000
f0101de7:	68 58 39 10 f0       	push   $0xf0103958
f0101dec:	e8 c0 00 00 00       	call   f0101eb1 <cprintf>
	cprintf("\n\n");
f0101df1:	c7 04 24 ce 3c 10 f0 	movl   $0xf0103cce,(%esp)
f0101df8:	e8 b4 00 00 00       	call   f0101eb1 <cprintf>
	//end:parte pruebas

	check_page_free_list(1);
f0101dfd:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e02:	e8 f6 ef ff ff       	call   f0100dfd <check_page_free_list>
	check_page_alloc();
f0101e07:	e8 7e f3 ff ff       	call   f010118a <check_page_alloc>
	check_page();
f0101e0c:	e8 cc f8 ff ff       	call   f01016dd <check_page>

f0101e11 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101e11:	55                   	push   %ebp
f0101e12:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0101e14:	5d                   	pop    %ebp
f0101e15:	c3                   	ret    

f0101e16 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101e16:	55                   	push   %ebp
f0101e17:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f0101e19:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101e1c:	e8 ce eb ff ff       	call   f01009ef <invlpg>
}
f0101e21:	5d                   	pop    %ebp
f0101e22:	c3                   	ret    

f0101e23 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0101e23:	55                   	push   %ebp
f0101e24:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0101e26:	89 c2                	mov    %eax,%edx
f0101e28:	ec                   	in     (%dx),%al
	return data;
}
f0101e29:	5d                   	pop    %ebp
f0101e2a:	c3                   	ret    

f0101e2b <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0101e2b:	55                   	push   %ebp
f0101e2c:	89 e5                	mov    %esp,%ebp
f0101e2e:	89 c1                	mov    %eax,%ecx
f0101e30:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101e32:	89 ca                	mov    %ecx,%edx
f0101e34:	ee                   	out    %al,(%dx)
}
f0101e35:	5d                   	pop    %ebp
f0101e36:	c3                   	ret    

f0101e37 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0101e37:	55                   	push   %ebp
f0101e38:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0101e3a:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0101e3e:	b8 70 00 00 00       	mov    $0x70,%eax
f0101e43:	e8 e3 ff ff ff       	call   f0101e2b <outb>
	return inb(IO_RTC+1);
f0101e48:	b8 71 00 00 00       	mov    $0x71,%eax
f0101e4d:	e8 d1 ff ff ff       	call   f0101e23 <inb>
f0101e52:	0f b6 c0             	movzbl %al,%eax
}
f0101e55:	5d                   	pop    %ebp
f0101e56:	c3                   	ret    

f0101e57 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101e57:	55                   	push   %ebp
f0101e58:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0101e5a:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0101e5e:	b8 70 00 00 00       	mov    $0x70,%eax
f0101e63:	e8 c3 ff ff ff       	call   f0101e2b <outb>
	outb(IO_RTC+1, datum);
f0101e68:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0101e6c:	b8 71 00 00 00       	mov    $0x71,%eax
f0101e71:	e8 b5 ff ff ff       	call   f0101e2b <outb>
}
f0101e76:	5d                   	pop    %ebp
f0101e77:	c3                   	ret    

f0101e78 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101e78:	55                   	push   %ebp
f0101e79:	89 e5                	mov    %esp,%ebp
f0101e7b:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0101e7e:	ff 75 08             	pushl  0x8(%ebp)
f0101e81:	e8 7f e8 ff ff       	call   f0100705 <cputchar>
	*cnt++;
}
f0101e86:	83 c4 10             	add    $0x10,%esp
f0101e89:	c9                   	leave  
f0101e8a:	c3                   	ret    

f0101e8b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101e8b:	55                   	push   %ebp
f0101e8c:	89 e5                	mov    %esp,%ebp
f0101e8e:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0101e91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101e98:	ff 75 0c             	pushl  0xc(%ebp)
f0101e9b:	ff 75 08             	pushl  0x8(%ebp)
f0101e9e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101ea1:	50                   	push   %eax
f0101ea2:	68 78 1e 10 f0       	push   $0xf0101e78
f0101ea7:	e8 82 04 00 00       	call   f010232e <vprintfmt>
	return cnt;
}
f0101eac:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101eaf:	c9                   	leave  
f0101eb0:	c3                   	ret    

f0101eb1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101eb1:	55                   	push   %ebp
f0101eb2:	89 e5                	mov    %esp,%ebp
f0101eb4:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101eb7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101eba:	50                   	push   %eax
f0101ebb:	ff 75 08             	pushl  0x8(%ebp)
f0101ebe:	e8 c8 ff ff ff       	call   f0101e8b <vcprintf>
	va_end(ap);

	return cnt;
}
f0101ec3:	c9                   	leave  
f0101ec4:	c3                   	ret    

f0101ec5 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101ec5:	55                   	push   %ebp
f0101ec6:	89 e5                	mov    %esp,%ebp
f0101ec8:	57                   	push   %edi
f0101ec9:	56                   	push   %esi
f0101eca:	53                   	push   %ebx
f0101ecb:	83 ec 14             	sub    $0x14,%esp
f0101ece:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101ed1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101ed4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101ed7:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101eda:	8b 1a                	mov    (%edx),%ebx
f0101edc:	8b 01                	mov    (%ecx),%eax
f0101ede:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101ee1:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101ee8:	eb 7f                	jmp    f0101f69 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0101eea:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101eed:	01 d8                	add    %ebx,%eax
f0101eef:	89 c6                	mov    %eax,%esi
f0101ef1:	c1 ee 1f             	shr    $0x1f,%esi
f0101ef4:	01 c6                	add    %eax,%esi
f0101ef6:	d1 fe                	sar    %esi
f0101ef8:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101efb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101efe:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0101f01:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101f03:	eb 03                	jmp    f0101f08 <stab_binsearch+0x43>
			m--;
f0101f05:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101f08:	39 c3                	cmp    %eax,%ebx
f0101f0a:	7f 0d                	jg     f0101f19 <stab_binsearch+0x54>
f0101f0c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0101f10:	83 ea 0c             	sub    $0xc,%edx
f0101f13:	39 f9                	cmp    %edi,%ecx
f0101f15:	75 ee                	jne    f0101f05 <stab_binsearch+0x40>
f0101f17:	eb 05                	jmp    f0101f1e <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0101f19:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0101f1c:	eb 4b                	jmp    f0101f69 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101f1e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101f21:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101f24:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0101f28:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101f2b:	76 11                	jbe    f0101f3e <stab_binsearch+0x79>
			*region_left = m;
f0101f2d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101f30:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0101f32:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101f35:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101f3c:	eb 2b                	jmp    f0101f69 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0101f3e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0101f41:	73 14                	jae    f0101f57 <stab_binsearch+0x92>
			*region_right = m - 1;
f0101f43:	83 e8 01             	sub    $0x1,%eax
f0101f46:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101f49:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101f4c:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101f4e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101f55:	eb 12                	jmp    f0101f69 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101f57:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101f5a:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0101f5c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0101f60:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101f62:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0101f69:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0101f6c:	0f 8e 78 ff ff ff    	jle    f0101eea <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0101f72:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101f76:	75 0f                	jne    f0101f87 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0101f78:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101f7b:	8b 00                	mov    (%eax),%eax
f0101f7d:	83 e8 01             	sub    $0x1,%eax
f0101f80:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101f83:	89 06                	mov    %eax,(%esi)
f0101f85:	eb 2c                	jmp    f0101fb3 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101f87:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101f8a:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101f8c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101f8f:	8b 0e                	mov    (%esi),%ecx
f0101f91:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101f94:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101f97:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101f9a:	eb 03                	jmp    f0101f9f <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101f9c:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101f9f:	39 c8                	cmp    %ecx,%eax
f0101fa1:	7e 0b                	jle    f0101fae <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0101fa3:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0101fa7:	83 ea 0c             	sub    $0xc,%edx
f0101faa:	39 df                	cmp    %ebx,%edi
f0101fac:	75 ee                	jne    f0101f9c <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101fae:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101fb1:	89 06                	mov    %eax,(%esi)
	}
}
f0101fb3:	83 c4 14             	add    $0x14,%esp
f0101fb6:	5b                   	pop    %ebx
f0101fb7:	5e                   	pop    %esi
f0101fb8:	5f                   	pop    %edi
f0101fb9:	5d                   	pop    %ebp
f0101fba:	c3                   	ret    

f0101fbb <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101fbb:	55                   	push   %ebp
f0101fbc:	89 e5                	mov    %esp,%ebp
f0101fbe:	57                   	push   %edi
f0101fbf:	56                   	push   %esi
f0101fc0:	53                   	push   %ebx
f0101fc1:	83 ec 3c             	sub    $0x3c,%esp
f0101fc4:	8b 75 08             	mov    0x8(%ebp),%esi
f0101fc7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101fca:	c7 03 d1 3c 10 f0    	movl   $0xf0103cd1,(%ebx)
	info->eip_line = 0;
f0101fd0:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0101fd7:	c7 43 08 d1 3c 10 f0 	movl   $0xf0103cd1,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101fde:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0101fe5:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101fe8:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101fef:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101ff5:	76 11                	jbe    f0102008 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101ff7:	b8 d4 b3 10 f0       	mov    $0xf010b3d4,%eax
f0101ffc:	3d 6d 94 10 f0       	cmp    $0xf010946d,%eax
f0102001:	77 19                	ja     f010201c <debuginfo_eip+0x61>
f0102003:	e9 af 01 00 00       	jmp    f01021b7 <debuginfo_eip+0x1fc>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102008:	83 ec 04             	sub    $0x4,%esp
f010200b:	68 db 3c 10 f0       	push   $0xf0103cdb
f0102010:	6a 7f                	push   $0x7f
f0102012:	68 e8 3c 10 f0       	push   $0xf0103ce8
f0102017:	e8 6f e0 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010201c:	80 3d d3 b3 10 f0 00 	cmpb   $0x0,0xf010b3d3
f0102023:	0f 85 95 01 00 00    	jne    f01021be <debuginfo_eip+0x203>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102029:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102030:	b8 6c 94 10 f0       	mov    $0xf010946c,%eax
f0102035:	2d 04 3f 10 f0       	sub    $0xf0103f04,%eax
f010203a:	c1 f8 02             	sar    $0x2,%eax
f010203d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102043:	83 e8 01             	sub    $0x1,%eax
f0102046:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102049:	83 ec 08             	sub    $0x8,%esp
f010204c:	56                   	push   %esi
f010204d:	6a 64                	push   $0x64
f010204f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102052:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102055:	b8 04 3f 10 f0       	mov    $0xf0103f04,%eax
f010205a:	e8 66 fe ff ff       	call   f0101ec5 <stab_binsearch>
	if (lfile == 0)
f010205f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102062:	83 c4 10             	add    $0x10,%esp
f0102065:	85 c0                	test   %eax,%eax
f0102067:	0f 84 58 01 00 00    	je     f01021c5 <debuginfo_eip+0x20a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010206d:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102070:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102073:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102076:	83 ec 08             	sub    $0x8,%esp
f0102079:	56                   	push   %esi
f010207a:	6a 24                	push   $0x24
f010207c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010207f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102082:	b8 04 3f 10 f0       	mov    $0xf0103f04,%eax
f0102087:	e8 39 fe ff ff       	call   f0101ec5 <stab_binsearch>

	if (lfun <= rfun) {
f010208c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010208f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102092:	83 c4 10             	add    $0x10,%esp
f0102095:	39 d0                	cmp    %edx,%eax
f0102097:	7f 40                	jg     f01020d9 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102099:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f010209c:	c1 e1 02             	shl    $0x2,%ecx
f010209f:	8d b9 04 3f 10 f0    	lea    -0xfefc0fc(%ecx),%edi
f01020a5:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01020a8:	8b b9 04 3f 10 f0    	mov    -0xfefc0fc(%ecx),%edi
f01020ae:	b9 d4 b3 10 f0       	mov    $0xf010b3d4,%ecx
f01020b3:	81 e9 6d 94 10 f0    	sub    $0xf010946d,%ecx
f01020b9:	39 cf                	cmp    %ecx,%edi
f01020bb:	73 09                	jae    f01020c6 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01020bd:	81 c7 6d 94 10 f0    	add    $0xf010946d,%edi
f01020c3:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01020c6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01020c9:	8b 4f 08             	mov    0x8(%edi),%ecx
f01020cc:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01020cf:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01020d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01020d4:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01020d7:	eb 0f                	jmp    f01020e8 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01020d9:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01020dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01020df:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01020e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01020e5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01020e8:	83 ec 08             	sub    $0x8,%esp
f01020eb:	6a 3a                	push   $0x3a
f01020ed:	ff 73 08             	pushl  0x8(%ebx)
f01020f0:	e8 44 08 00 00       	call   f0102939 <strfind>
f01020f5:	2b 43 08             	sub    0x8(%ebx),%eax
f01020f8:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01020fb:	83 c4 08             	add    $0x8,%esp
f01020fe:	56                   	push   %esi
f01020ff:	6a 44                	push   $0x44
f0102101:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102104:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102107:	b8 04 3f 10 f0       	mov    $0xf0103f04,%eax
f010210c:	e8 b4 fd ff ff       	call   f0101ec5 <stab_binsearch>
	if (lline <= rline) {
f0102111:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102114:	83 c4 10             	add    $0x10,%esp
f0102117:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f010211a:	7f 0e                	jg     f010212a <debuginfo_eip+0x16f>
		info->eip_line = stabs[lline].n_desc;
f010211c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010211f:	0f b7 14 95 0a 3f 10 	movzwl -0xfefc0f6(,%edx,4),%edx
f0102126:	f0 
f0102127:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010212a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010212d:	89 c2                	mov    %eax,%edx
f010212f:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102132:	8d 04 85 04 3f 10 f0 	lea    -0xfefc0fc(,%eax,4),%eax
f0102139:	eb 06                	jmp    f0102141 <debuginfo_eip+0x186>
f010213b:	83 ea 01             	sub    $0x1,%edx
f010213e:	83 e8 0c             	sub    $0xc,%eax
f0102141:	39 d7                	cmp    %edx,%edi
f0102143:	7f 34                	jg     f0102179 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0102145:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102149:	80 f9 84             	cmp    $0x84,%cl
f010214c:	74 0b                	je     f0102159 <debuginfo_eip+0x19e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010214e:	80 f9 64             	cmp    $0x64,%cl
f0102151:	75 e8                	jne    f010213b <debuginfo_eip+0x180>
f0102153:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102157:	74 e2                	je     f010213b <debuginfo_eip+0x180>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102159:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010215c:	8b 14 85 04 3f 10 f0 	mov    -0xfefc0fc(,%eax,4),%edx
f0102163:	b8 d4 b3 10 f0       	mov    $0xf010b3d4,%eax
f0102168:	2d 6d 94 10 f0       	sub    $0xf010946d,%eax
f010216d:	39 c2                	cmp    %eax,%edx
f010216f:	73 08                	jae    f0102179 <debuginfo_eip+0x1be>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102171:	81 c2 6d 94 10 f0    	add    $0xf010946d,%edx
f0102177:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102179:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010217c:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010217f:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102184:	39 f2                	cmp    %esi,%edx
f0102186:	7d 49                	jge    f01021d1 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
f0102188:	83 c2 01             	add    $0x1,%edx
f010218b:	89 d0                	mov    %edx,%eax
f010218d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102190:	8d 14 95 04 3f 10 f0 	lea    -0xfefc0fc(,%edx,4),%edx
f0102197:	eb 04                	jmp    f010219d <debuginfo_eip+0x1e2>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102199:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010219d:	39 c6                	cmp    %eax,%esi
f010219f:	7e 2b                	jle    f01021cc <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01021a1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01021a5:	83 c0 01             	add    $0x1,%eax
f01021a8:	83 c2 0c             	add    $0xc,%edx
f01021ab:	80 f9 a0             	cmp    $0xa0,%cl
f01021ae:	74 e9                	je     f0102199 <debuginfo_eip+0x1de>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01021b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01021b5:	eb 1a                	jmp    f01021d1 <debuginfo_eip+0x216>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01021b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01021bc:	eb 13                	jmp    f01021d1 <debuginfo_eip+0x216>
f01021be:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01021c3:	eb 0c                	jmp    f01021d1 <debuginfo_eip+0x216>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01021c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01021ca:	eb 05                	jmp    f01021d1 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01021cc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01021d1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01021d4:	5b                   	pop    %ebx
f01021d5:	5e                   	pop    %esi
f01021d6:	5f                   	pop    %edi
f01021d7:	5d                   	pop    %ebp
f01021d8:	c3                   	ret    

f01021d9 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01021d9:	55                   	push   %ebp
f01021da:	89 e5                	mov    %esp,%ebp
f01021dc:	57                   	push   %edi
f01021dd:	56                   	push   %esi
f01021de:	53                   	push   %ebx
f01021df:	83 ec 1c             	sub    $0x1c,%esp
f01021e2:	89 c7                	mov    %eax,%edi
f01021e4:	89 d6                	mov    %edx,%esi
f01021e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01021e9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01021ec:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01021ef:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01021f2:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01021f5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021fa:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01021fd:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102200:	39 d3                	cmp    %edx,%ebx
f0102202:	72 05                	jb     f0102209 <printnum+0x30>
f0102204:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102207:	77 45                	ja     f010224e <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102209:	83 ec 0c             	sub    $0xc,%esp
f010220c:	ff 75 18             	pushl  0x18(%ebp)
f010220f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102212:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102215:	53                   	push   %ebx
f0102216:	ff 75 10             	pushl  0x10(%ebp)
f0102219:	83 ec 08             	sub    $0x8,%esp
f010221c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010221f:	ff 75 e0             	pushl  -0x20(%ebp)
f0102222:	ff 75 dc             	pushl  -0x24(%ebp)
f0102225:	ff 75 d8             	pushl  -0x28(%ebp)
f0102228:	e8 33 09 00 00       	call   f0102b60 <__udivdi3>
f010222d:	83 c4 18             	add    $0x18,%esp
f0102230:	52                   	push   %edx
f0102231:	50                   	push   %eax
f0102232:	89 f2                	mov    %esi,%edx
f0102234:	89 f8                	mov    %edi,%eax
f0102236:	e8 9e ff ff ff       	call   f01021d9 <printnum>
f010223b:	83 c4 20             	add    $0x20,%esp
f010223e:	eb 18                	jmp    f0102258 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102240:	83 ec 08             	sub    $0x8,%esp
f0102243:	56                   	push   %esi
f0102244:	ff 75 18             	pushl  0x18(%ebp)
f0102247:	ff d7                	call   *%edi
f0102249:	83 c4 10             	add    $0x10,%esp
f010224c:	eb 03                	jmp    f0102251 <printnum+0x78>
f010224e:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102251:	83 eb 01             	sub    $0x1,%ebx
f0102254:	85 db                	test   %ebx,%ebx
f0102256:	7f e8                	jg     f0102240 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102258:	83 ec 08             	sub    $0x8,%esp
f010225b:	56                   	push   %esi
f010225c:	83 ec 04             	sub    $0x4,%esp
f010225f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102262:	ff 75 e0             	pushl  -0x20(%ebp)
f0102265:	ff 75 dc             	pushl  -0x24(%ebp)
f0102268:	ff 75 d8             	pushl  -0x28(%ebp)
f010226b:	e8 20 0a 00 00       	call   f0102c90 <__umoddi3>
f0102270:	83 c4 14             	add    $0x14,%esp
f0102273:	0f be 80 f6 3c 10 f0 	movsbl -0xfefc30a(%eax),%eax
f010227a:	50                   	push   %eax
f010227b:	ff d7                	call   *%edi
}
f010227d:	83 c4 10             	add    $0x10,%esp
f0102280:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102283:	5b                   	pop    %ebx
f0102284:	5e                   	pop    %esi
f0102285:	5f                   	pop    %edi
f0102286:	5d                   	pop    %ebp
f0102287:	c3                   	ret    

f0102288 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102288:	55                   	push   %ebp
f0102289:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010228b:	83 fa 01             	cmp    $0x1,%edx
f010228e:	7e 0e                	jle    f010229e <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102290:	8b 10                	mov    (%eax),%edx
f0102292:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102295:	89 08                	mov    %ecx,(%eax)
f0102297:	8b 02                	mov    (%edx),%eax
f0102299:	8b 52 04             	mov    0x4(%edx),%edx
f010229c:	eb 22                	jmp    f01022c0 <getuint+0x38>
	else if (lflag)
f010229e:	85 d2                	test   %edx,%edx
f01022a0:	74 10                	je     f01022b2 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01022a2:	8b 10                	mov    (%eax),%edx
f01022a4:	8d 4a 04             	lea    0x4(%edx),%ecx
f01022a7:	89 08                	mov    %ecx,(%eax)
f01022a9:	8b 02                	mov    (%edx),%eax
f01022ab:	ba 00 00 00 00       	mov    $0x0,%edx
f01022b0:	eb 0e                	jmp    f01022c0 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01022b2:	8b 10                	mov    (%eax),%edx
f01022b4:	8d 4a 04             	lea    0x4(%edx),%ecx
f01022b7:	89 08                	mov    %ecx,(%eax)
f01022b9:	8b 02                	mov    (%edx),%eax
f01022bb:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01022c0:	5d                   	pop    %ebp
f01022c1:	c3                   	ret    

f01022c2 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f01022c2:	55                   	push   %ebp
f01022c3:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01022c5:	83 fa 01             	cmp    $0x1,%edx
f01022c8:	7e 0e                	jle    f01022d8 <getint+0x16>
		return va_arg(*ap, long long);
f01022ca:	8b 10                	mov    (%eax),%edx
f01022cc:	8d 4a 08             	lea    0x8(%edx),%ecx
f01022cf:	89 08                	mov    %ecx,(%eax)
f01022d1:	8b 02                	mov    (%edx),%eax
f01022d3:	8b 52 04             	mov    0x4(%edx),%edx
f01022d6:	eb 1a                	jmp    f01022f2 <getint+0x30>
	else if (lflag)
f01022d8:	85 d2                	test   %edx,%edx
f01022da:	74 0c                	je     f01022e8 <getint+0x26>
		return va_arg(*ap, long);
f01022dc:	8b 10                	mov    (%eax),%edx
f01022de:	8d 4a 04             	lea    0x4(%edx),%ecx
f01022e1:	89 08                	mov    %ecx,(%eax)
f01022e3:	8b 02                	mov    (%edx),%eax
f01022e5:	99                   	cltd   
f01022e6:	eb 0a                	jmp    f01022f2 <getint+0x30>
	else
		return va_arg(*ap, int);
f01022e8:	8b 10                	mov    (%eax),%edx
f01022ea:	8d 4a 04             	lea    0x4(%edx),%ecx
f01022ed:	89 08                	mov    %ecx,(%eax)
f01022ef:	8b 02                	mov    (%edx),%eax
f01022f1:	99                   	cltd   
}
f01022f2:	5d                   	pop    %ebp
f01022f3:	c3                   	ret    

f01022f4 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01022f4:	55                   	push   %ebp
f01022f5:	89 e5                	mov    %esp,%ebp
f01022f7:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01022fa:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01022fe:	8b 10                	mov    (%eax),%edx
f0102300:	3b 50 04             	cmp    0x4(%eax),%edx
f0102303:	73 0a                	jae    f010230f <sprintputch+0x1b>
		*b->buf++ = ch;
f0102305:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102308:	89 08                	mov    %ecx,(%eax)
f010230a:	8b 45 08             	mov    0x8(%ebp),%eax
f010230d:	88 02                	mov    %al,(%edx)
}
f010230f:	5d                   	pop    %ebp
f0102310:	c3                   	ret    

f0102311 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102311:	55                   	push   %ebp
f0102312:	89 e5                	mov    %esp,%ebp
f0102314:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102317:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010231a:	50                   	push   %eax
f010231b:	ff 75 10             	pushl  0x10(%ebp)
f010231e:	ff 75 0c             	pushl  0xc(%ebp)
f0102321:	ff 75 08             	pushl  0x8(%ebp)
f0102324:	e8 05 00 00 00       	call   f010232e <vprintfmt>
	va_end(ap);
}
f0102329:	83 c4 10             	add    $0x10,%esp
f010232c:	c9                   	leave  
f010232d:	c3                   	ret    

f010232e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010232e:	55                   	push   %ebp
f010232f:	89 e5                	mov    %esp,%ebp
f0102331:	57                   	push   %edi
f0102332:	56                   	push   %esi
f0102333:	53                   	push   %ebx
f0102334:	83 ec 2c             	sub    $0x2c,%esp
f0102337:	8b 75 08             	mov    0x8(%ebp),%esi
f010233a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010233d:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102340:	eb 12                	jmp    f0102354 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102342:	85 c0                	test   %eax,%eax
f0102344:	0f 84 44 03 00 00    	je     f010268e <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f010234a:	83 ec 08             	sub    $0x8,%esp
f010234d:	53                   	push   %ebx
f010234e:	50                   	push   %eax
f010234f:	ff d6                	call   *%esi
f0102351:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102354:	83 c7 01             	add    $0x1,%edi
f0102357:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010235b:	83 f8 25             	cmp    $0x25,%eax
f010235e:	75 e2                	jne    f0102342 <vprintfmt+0x14>
f0102360:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102364:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010236b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102372:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102379:	ba 00 00 00 00       	mov    $0x0,%edx
f010237e:	eb 07                	jmp    f0102387 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102380:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102383:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102387:	8d 47 01             	lea    0x1(%edi),%eax
f010238a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010238d:	0f b6 07             	movzbl (%edi),%eax
f0102390:	0f b6 c8             	movzbl %al,%ecx
f0102393:	83 e8 23             	sub    $0x23,%eax
f0102396:	3c 55                	cmp    $0x55,%al
f0102398:	0f 87 d5 02 00 00    	ja     f0102673 <vprintfmt+0x345>
f010239e:	0f b6 c0             	movzbl %al,%eax
f01023a1:	ff 24 85 80 3d 10 f0 	jmp    *-0xfefc280(,%eax,4)
f01023a8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01023ab:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01023af:	eb d6                	jmp    f0102387 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01023b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01023b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01023b9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01023bc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01023bf:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01023c3:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01023c6:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01023c9:	83 fa 09             	cmp    $0x9,%edx
f01023cc:	77 39                	ja     f0102407 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01023ce:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01023d1:	eb e9                	jmp    f01023bc <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01023d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01023d6:	8d 48 04             	lea    0x4(%eax),%ecx
f01023d9:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01023dc:	8b 00                	mov    (%eax),%eax
f01023de:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01023e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01023e4:	eb 27                	jmp    f010240d <vprintfmt+0xdf>
f01023e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01023e9:	85 c0                	test   %eax,%eax
f01023eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01023f0:	0f 49 c8             	cmovns %eax,%ecx
f01023f3:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01023f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01023f9:	eb 8c                	jmp    f0102387 <vprintfmt+0x59>
f01023fb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01023fe:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102405:	eb 80                	jmp    f0102387 <vprintfmt+0x59>
f0102407:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010240a:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f010240d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102411:	0f 89 70 ff ff ff    	jns    f0102387 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102417:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010241a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010241d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102424:	e9 5e ff ff ff       	jmp    f0102387 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102429:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010242c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010242f:	e9 53 ff ff ff       	jmp    f0102387 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102434:	8b 45 14             	mov    0x14(%ebp),%eax
f0102437:	8d 50 04             	lea    0x4(%eax),%edx
f010243a:	89 55 14             	mov    %edx,0x14(%ebp)
f010243d:	83 ec 08             	sub    $0x8,%esp
f0102440:	53                   	push   %ebx
f0102441:	ff 30                	pushl  (%eax)
f0102443:	ff d6                	call   *%esi
			break;
f0102445:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102448:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010244b:	e9 04 ff ff ff       	jmp    f0102354 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102450:	8b 45 14             	mov    0x14(%ebp),%eax
f0102453:	8d 50 04             	lea    0x4(%eax),%edx
f0102456:	89 55 14             	mov    %edx,0x14(%ebp)
f0102459:	8b 00                	mov    (%eax),%eax
f010245b:	99                   	cltd   
f010245c:	31 d0                	xor    %edx,%eax
f010245e:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102460:	83 f8 06             	cmp    $0x6,%eax
f0102463:	7f 0b                	jg     f0102470 <vprintfmt+0x142>
f0102465:	8b 14 85 d8 3e 10 f0 	mov    -0xfefc128(,%eax,4),%edx
f010246c:	85 d2                	test   %edx,%edx
f010246e:	75 18                	jne    f0102488 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102470:	50                   	push   %eax
f0102471:	68 0e 3d 10 f0       	push   $0xf0103d0e
f0102476:	53                   	push   %ebx
f0102477:	56                   	push   %esi
f0102478:	e8 94 fe ff ff       	call   f0102311 <printfmt>
f010247d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102480:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102483:	e9 cc fe ff ff       	jmp    f0102354 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102488:	52                   	push   %edx
f0102489:	68 cf 39 10 f0       	push   $0xf01039cf
f010248e:	53                   	push   %ebx
f010248f:	56                   	push   %esi
f0102490:	e8 7c fe ff ff       	call   f0102311 <printfmt>
f0102495:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102498:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010249b:	e9 b4 fe ff ff       	jmp    f0102354 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01024a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01024a3:	8d 50 04             	lea    0x4(%eax),%edx
f01024a6:	89 55 14             	mov    %edx,0x14(%ebp)
f01024a9:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01024ab:	85 ff                	test   %edi,%edi
f01024ad:	b8 07 3d 10 f0       	mov    $0xf0103d07,%eax
f01024b2:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01024b5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01024b9:	0f 8e 94 00 00 00    	jle    f0102553 <vprintfmt+0x225>
f01024bf:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01024c3:	0f 84 98 00 00 00    	je     f0102561 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01024c9:	83 ec 08             	sub    $0x8,%esp
f01024cc:	ff 75 d0             	pushl  -0x30(%ebp)
f01024cf:	57                   	push   %edi
f01024d0:	e8 1a 03 00 00       	call   f01027ef <strnlen>
f01024d5:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01024d8:	29 c1                	sub    %eax,%ecx
f01024da:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01024dd:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01024e0:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01024e4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01024e7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01024ea:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01024ec:	eb 0f                	jmp    f01024fd <vprintfmt+0x1cf>
					putch(padc, putdat);
f01024ee:	83 ec 08             	sub    $0x8,%esp
f01024f1:	53                   	push   %ebx
f01024f2:	ff 75 e0             	pushl  -0x20(%ebp)
f01024f5:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01024f7:	83 ef 01             	sub    $0x1,%edi
f01024fa:	83 c4 10             	add    $0x10,%esp
f01024fd:	85 ff                	test   %edi,%edi
f01024ff:	7f ed                	jg     f01024ee <vprintfmt+0x1c0>
f0102501:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102504:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102507:	85 c9                	test   %ecx,%ecx
f0102509:	b8 00 00 00 00       	mov    $0x0,%eax
f010250e:	0f 49 c1             	cmovns %ecx,%eax
f0102511:	29 c1                	sub    %eax,%ecx
f0102513:	89 75 08             	mov    %esi,0x8(%ebp)
f0102516:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102519:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010251c:	89 cb                	mov    %ecx,%ebx
f010251e:	eb 4d                	jmp    f010256d <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102520:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102524:	74 1b                	je     f0102541 <vprintfmt+0x213>
f0102526:	0f be c0             	movsbl %al,%eax
f0102529:	83 e8 20             	sub    $0x20,%eax
f010252c:	83 f8 5e             	cmp    $0x5e,%eax
f010252f:	76 10                	jbe    f0102541 <vprintfmt+0x213>
					putch('?', putdat);
f0102531:	83 ec 08             	sub    $0x8,%esp
f0102534:	ff 75 0c             	pushl  0xc(%ebp)
f0102537:	6a 3f                	push   $0x3f
f0102539:	ff 55 08             	call   *0x8(%ebp)
f010253c:	83 c4 10             	add    $0x10,%esp
f010253f:	eb 0d                	jmp    f010254e <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102541:	83 ec 08             	sub    $0x8,%esp
f0102544:	ff 75 0c             	pushl  0xc(%ebp)
f0102547:	52                   	push   %edx
f0102548:	ff 55 08             	call   *0x8(%ebp)
f010254b:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010254e:	83 eb 01             	sub    $0x1,%ebx
f0102551:	eb 1a                	jmp    f010256d <vprintfmt+0x23f>
f0102553:	89 75 08             	mov    %esi,0x8(%ebp)
f0102556:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102559:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010255c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010255f:	eb 0c                	jmp    f010256d <vprintfmt+0x23f>
f0102561:	89 75 08             	mov    %esi,0x8(%ebp)
f0102564:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102567:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010256a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010256d:	83 c7 01             	add    $0x1,%edi
f0102570:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102574:	0f be d0             	movsbl %al,%edx
f0102577:	85 d2                	test   %edx,%edx
f0102579:	74 23                	je     f010259e <vprintfmt+0x270>
f010257b:	85 f6                	test   %esi,%esi
f010257d:	78 a1                	js     f0102520 <vprintfmt+0x1f2>
f010257f:	83 ee 01             	sub    $0x1,%esi
f0102582:	79 9c                	jns    f0102520 <vprintfmt+0x1f2>
f0102584:	89 df                	mov    %ebx,%edi
f0102586:	8b 75 08             	mov    0x8(%ebp),%esi
f0102589:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010258c:	eb 18                	jmp    f01025a6 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010258e:	83 ec 08             	sub    $0x8,%esp
f0102591:	53                   	push   %ebx
f0102592:	6a 20                	push   $0x20
f0102594:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102596:	83 ef 01             	sub    $0x1,%edi
f0102599:	83 c4 10             	add    $0x10,%esp
f010259c:	eb 08                	jmp    f01025a6 <vprintfmt+0x278>
f010259e:	89 df                	mov    %ebx,%edi
f01025a0:	8b 75 08             	mov    0x8(%ebp),%esi
f01025a3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01025a6:	85 ff                	test   %edi,%edi
f01025a8:	7f e4                	jg     f010258e <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01025aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01025ad:	e9 a2 fd ff ff       	jmp    f0102354 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01025b2:	8d 45 14             	lea    0x14(%ebp),%eax
f01025b5:	e8 08 fd ff ff       	call   f01022c2 <getint>
f01025ba:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01025bd:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01025c0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01025c5:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01025c9:	79 74                	jns    f010263f <vprintfmt+0x311>
				putch('-', putdat);
f01025cb:	83 ec 08             	sub    $0x8,%esp
f01025ce:	53                   	push   %ebx
f01025cf:	6a 2d                	push   $0x2d
f01025d1:	ff d6                	call   *%esi
				num = -(long long) num;
f01025d3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01025d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01025d9:	f7 d8                	neg    %eax
f01025db:	83 d2 00             	adc    $0x0,%edx
f01025de:	f7 da                	neg    %edx
f01025e0:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01025e3:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01025e8:	eb 55                	jmp    f010263f <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01025ea:	8d 45 14             	lea    0x14(%ebp),%eax
f01025ed:	e8 96 fc ff ff       	call   f0102288 <getuint>
			base = 10;
f01025f2:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01025f7:	eb 46                	jmp    f010263f <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f01025f9:	8d 45 14             	lea    0x14(%ebp),%eax
f01025fc:	e8 87 fc ff ff       	call   f0102288 <getuint>
			base = 8;
f0102601:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102606:	eb 37                	jmp    f010263f <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0102608:	83 ec 08             	sub    $0x8,%esp
f010260b:	53                   	push   %ebx
f010260c:	6a 30                	push   $0x30
f010260e:	ff d6                	call   *%esi
			putch('x', putdat);
f0102610:	83 c4 08             	add    $0x8,%esp
f0102613:	53                   	push   %ebx
f0102614:	6a 78                	push   $0x78
f0102616:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102618:	8b 45 14             	mov    0x14(%ebp),%eax
f010261b:	8d 50 04             	lea    0x4(%eax),%edx
f010261e:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102621:	8b 00                	mov    (%eax),%eax
f0102623:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102628:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010262b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102630:	eb 0d                	jmp    f010263f <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102632:	8d 45 14             	lea    0x14(%ebp),%eax
f0102635:	e8 4e fc ff ff       	call   f0102288 <getuint>
			base = 16;
f010263a:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010263f:	83 ec 0c             	sub    $0xc,%esp
f0102642:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102646:	57                   	push   %edi
f0102647:	ff 75 e0             	pushl  -0x20(%ebp)
f010264a:	51                   	push   %ecx
f010264b:	52                   	push   %edx
f010264c:	50                   	push   %eax
f010264d:	89 da                	mov    %ebx,%edx
f010264f:	89 f0                	mov    %esi,%eax
f0102651:	e8 83 fb ff ff       	call   f01021d9 <printnum>
			break;
f0102656:	83 c4 20             	add    $0x20,%esp
f0102659:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010265c:	e9 f3 fc ff ff       	jmp    f0102354 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102661:	83 ec 08             	sub    $0x8,%esp
f0102664:	53                   	push   %ebx
f0102665:	51                   	push   %ecx
f0102666:	ff d6                	call   *%esi
			break;
f0102668:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010266b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010266e:	e9 e1 fc ff ff       	jmp    f0102354 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102673:	83 ec 08             	sub    $0x8,%esp
f0102676:	53                   	push   %ebx
f0102677:	6a 25                	push   $0x25
f0102679:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010267b:	83 c4 10             	add    $0x10,%esp
f010267e:	eb 03                	jmp    f0102683 <vprintfmt+0x355>
f0102680:	83 ef 01             	sub    $0x1,%edi
f0102683:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102687:	75 f7                	jne    f0102680 <vprintfmt+0x352>
f0102689:	e9 c6 fc ff ff       	jmp    f0102354 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010268e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102691:	5b                   	pop    %ebx
f0102692:	5e                   	pop    %esi
f0102693:	5f                   	pop    %edi
f0102694:	5d                   	pop    %ebp
f0102695:	c3                   	ret    

f0102696 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102696:	55                   	push   %ebp
f0102697:	89 e5                	mov    %esp,%ebp
f0102699:	83 ec 18             	sub    $0x18,%esp
f010269c:	8b 45 08             	mov    0x8(%ebp),%eax
f010269f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01026a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01026a5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01026a9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01026ac:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01026b3:	85 c0                	test   %eax,%eax
f01026b5:	74 26                	je     f01026dd <vsnprintf+0x47>
f01026b7:	85 d2                	test   %edx,%edx
f01026b9:	7e 22                	jle    f01026dd <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01026bb:	ff 75 14             	pushl  0x14(%ebp)
f01026be:	ff 75 10             	pushl  0x10(%ebp)
f01026c1:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01026c4:	50                   	push   %eax
f01026c5:	68 f4 22 10 f0       	push   $0xf01022f4
f01026ca:	e8 5f fc ff ff       	call   f010232e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01026cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01026d2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01026d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01026d8:	83 c4 10             	add    $0x10,%esp
f01026db:	eb 05                	jmp    f01026e2 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01026dd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01026e2:	c9                   	leave  
f01026e3:	c3                   	ret    

f01026e4 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01026e4:	55                   	push   %ebp
f01026e5:	89 e5                	mov    %esp,%ebp
f01026e7:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01026ea:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01026ed:	50                   	push   %eax
f01026ee:	ff 75 10             	pushl  0x10(%ebp)
f01026f1:	ff 75 0c             	pushl  0xc(%ebp)
f01026f4:	ff 75 08             	pushl  0x8(%ebp)
f01026f7:	e8 9a ff ff ff       	call   f0102696 <vsnprintf>
	va_end(ap);

	return rc;
}
f01026fc:	c9                   	leave  
f01026fd:	c3                   	ret    

f01026fe <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01026fe:	55                   	push   %ebp
f01026ff:	89 e5                	mov    %esp,%ebp
f0102701:	57                   	push   %edi
f0102702:	56                   	push   %esi
f0102703:	53                   	push   %ebx
f0102704:	83 ec 0c             	sub    $0xc,%esp
f0102707:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010270a:	85 c0                	test   %eax,%eax
f010270c:	74 11                	je     f010271f <readline+0x21>
		cprintf("%s", prompt);
f010270e:	83 ec 08             	sub    $0x8,%esp
f0102711:	50                   	push   %eax
f0102712:	68 cf 39 10 f0       	push   $0xf01039cf
f0102717:	e8 95 f7 ff ff       	call   f0101eb1 <cprintf>
f010271c:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010271f:	83 ec 0c             	sub    $0xc,%esp
f0102722:	6a 00                	push   $0x0
f0102724:	e8 fd df ff ff       	call   f0100726 <iscons>
f0102729:	89 c7                	mov    %eax,%edi
f010272b:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010272e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102733:	e8 dd df ff ff       	call   f0100715 <getchar>
f0102738:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010273a:	85 c0                	test   %eax,%eax
f010273c:	79 18                	jns    f0102756 <readline+0x58>
			cprintf("read error: %e\n", c);
f010273e:	83 ec 08             	sub    $0x8,%esp
f0102741:	50                   	push   %eax
f0102742:	68 f4 3e 10 f0       	push   $0xf0103ef4
f0102747:	e8 65 f7 ff ff       	call   f0101eb1 <cprintf>
			return NULL;
f010274c:	83 c4 10             	add    $0x10,%esp
f010274f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102754:	eb 79                	jmp    f01027cf <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102756:	83 f8 08             	cmp    $0x8,%eax
f0102759:	0f 94 c2             	sete   %dl
f010275c:	83 f8 7f             	cmp    $0x7f,%eax
f010275f:	0f 94 c0             	sete   %al
f0102762:	08 c2                	or     %al,%dl
f0102764:	74 1a                	je     f0102780 <readline+0x82>
f0102766:	85 f6                	test   %esi,%esi
f0102768:	7e 16                	jle    f0102780 <readline+0x82>
			if (echoing)
f010276a:	85 ff                	test   %edi,%edi
f010276c:	74 0d                	je     f010277b <readline+0x7d>
				cputchar('\b');
f010276e:	83 ec 0c             	sub    $0xc,%esp
f0102771:	6a 08                	push   $0x8
f0102773:	e8 8d df ff ff       	call   f0100705 <cputchar>
f0102778:	83 c4 10             	add    $0x10,%esp
			i--;
f010277b:	83 ee 01             	sub    $0x1,%esi
f010277e:	eb b3                	jmp    f0102733 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102780:	83 fb 1f             	cmp    $0x1f,%ebx
f0102783:	7e 23                	jle    f01027a8 <readline+0xaa>
f0102785:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010278b:	7f 1b                	jg     f01027a8 <readline+0xaa>
			if (echoing)
f010278d:	85 ff                	test   %edi,%edi
f010278f:	74 0c                	je     f010279d <readline+0x9f>
				cputchar(c);
f0102791:	83 ec 0c             	sub    $0xc,%esp
f0102794:	53                   	push   %ebx
f0102795:	e8 6b df ff ff       	call   f0100705 <cputchar>
f010279a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010279d:	88 9e 40 65 11 f0    	mov    %bl,-0xfee9ac0(%esi)
f01027a3:	8d 76 01             	lea    0x1(%esi),%esi
f01027a6:	eb 8b                	jmp    f0102733 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01027a8:	83 fb 0a             	cmp    $0xa,%ebx
f01027ab:	74 05                	je     f01027b2 <readline+0xb4>
f01027ad:	83 fb 0d             	cmp    $0xd,%ebx
f01027b0:	75 81                	jne    f0102733 <readline+0x35>
			if (echoing)
f01027b2:	85 ff                	test   %edi,%edi
f01027b4:	74 0d                	je     f01027c3 <readline+0xc5>
				cputchar('\n');
f01027b6:	83 ec 0c             	sub    $0xc,%esp
f01027b9:	6a 0a                	push   $0xa
f01027bb:	e8 45 df ff ff       	call   f0100705 <cputchar>
f01027c0:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01027c3:	c6 86 40 65 11 f0 00 	movb   $0x0,-0xfee9ac0(%esi)
			return buf;
f01027ca:	b8 40 65 11 f0       	mov    $0xf0116540,%eax
		}
	}
}
f01027cf:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01027d2:	5b                   	pop    %ebx
f01027d3:	5e                   	pop    %esi
f01027d4:	5f                   	pop    %edi
f01027d5:	5d                   	pop    %ebp
f01027d6:	c3                   	ret    

f01027d7 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01027d7:	55                   	push   %ebp
f01027d8:	89 e5                	mov    %esp,%ebp
f01027da:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01027dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01027e2:	eb 03                	jmp    f01027e7 <strlen+0x10>
		n++;
f01027e4:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01027e7:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01027eb:	75 f7                	jne    f01027e4 <strlen+0xd>
		n++;
	return n;
}
f01027ed:	5d                   	pop    %ebp
f01027ee:	c3                   	ret    

f01027ef <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01027ef:	55                   	push   %ebp
f01027f0:	89 e5                	mov    %esp,%ebp
f01027f2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01027f5:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01027f8:	ba 00 00 00 00       	mov    $0x0,%edx
f01027fd:	eb 03                	jmp    f0102802 <strnlen+0x13>
		n++;
f01027ff:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102802:	39 c2                	cmp    %eax,%edx
f0102804:	74 08                	je     f010280e <strnlen+0x1f>
f0102806:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010280a:	75 f3                	jne    f01027ff <strnlen+0x10>
f010280c:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010280e:	5d                   	pop    %ebp
f010280f:	c3                   	ret    

f0102810 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102810:	55                   	push   %ebp
f0102811:	89 e5                	mov    %esp,%ebp
f0102813:	53                   	push   %ebx
f0102814:	8b 45 08             	mov    0x8(%ebp),%eax
f0102817:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010281a:	89 c2                	mov    %eax,%edx
f010281c:	83 c2 01             	add    $0x1,%edx
f010281f:	83 c1 01             	add    $0x1,%ecx
f0102822:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102826:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102829:	84 db                	test   %bl,%bl
f010282b:	75 ef                	jne    f010281c <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010282d:	5b                   	pop    %ebx
f010282e:	5d                   	pop    %ebp
f010282f:	c3                   	ret    

f0102830 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102830:	55                   	push   %ebp
f0102831:	89 e5                	mov    %esp,%ebp
f0102833:	53                   	push   %ebx
f0102834:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0102837:	53                   	push   %ebx
f0102838:	e8 9a ff ff ff       	call   f01027d7 <strlen>
f010283d:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102840:	ff 75 0c             	pushl  0xc(%ebp)
f0102843:	01 d8                	add    %ebx,%eax
f0102845:	50                   	push   %eax
f0102846:	e8 c5 ff ff ff       	call   f0102810 <strcpy>
	return dst;
}
f010284b:	89 d8                	mov    %ebx,%eax
f010284d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102850:	c9                   	leave  
f0102851:	c3                   	ret    

f0102852 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102852:	55                   	push   %ebp
f0102853:	89 e5                	mov    %esp,%ebp
f0102855:	56                   	push   %esi
f0102856:	53                   	push   %ebx
f0102857:	8b 75 08             	mov    0x8(%ebp),%esi
f010285a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010285d:	89 f3                	mov    %esi,%ebx
f010285f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102862:	89 f2                	mov    %esi,%edx
f0102864:	eb 0f                	jmp    f0102875 <strncpy+0x23>
		*dst++ = *src;
f0102866:	83 c2 01             	add    $0x1,%edx
f0102869:	0f b6 01             	movzbl (%ecx),%eax
f010286c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010286f:	80 39 01             	cmpb   $0x1,(%ecx)
f0102872:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102875:	39 da                	cmp    %ebx,%edx
f0102877:	75 ed                	jne    f0102866 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0102879:	89 f0                	mov    %esi,%eax
f010287b:	5b                   	pop    %ebx
f010287c:	5e                   	pop    %esi
f010287d:	5d                   	pop    %ebp
f010287e:	c3                   	ret    

f010287f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010287f:	55                   	push   %ebp
f0102880:	89 e5                	mov    %esp,%ebp
f0102882:	56                   	push   %esi
f0102883:	53                   	push   %ebx
f0102884:	8b 75 08             	mov    0x8(%ebp),%esi
f0102887:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010288a:	8b 55 10             	mov    0x10(%ebp),%edx
f010288d:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010288f:	85 d2                	test   %edx,%edx
f0102891:	74 21                	je     f01028b4 <strlcpy+0x35>
f0102893:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0102897:	89 f2                	mov    %esi,%edx
f0102899:	eb 09                	jmp    f01028a4 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010289b:	83 c2 01             	add    $0x1,%edx
f010289e:	83 c1 01             	add    $0x1,%ecx
f01028a1:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01028a4:	39 c2                	cmp    %eax,%edx
f01028a6:	74 09                	je     f01028b1 <strlcpy+0x32>
f01028a8:	0f b6 19             	movzbl (%ecx),%ebx
f01028ab:	84 db                	test   %bl,%bl
f01028ad:	75 ec                	jne    f010289b <strlcpy+0x1c>
f01028af:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01028b1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01028b4:	29 f0                	sub    %esi,%eax
}
f01028b6:	5b                   	pop    %ebx
f01028b7:	5e                   	pop    %esi
f01028b8:	5d                   	pop    %ebp
f01028b9:	c3                   	ret    

f01028ba <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01028ba:	55                   	push   %ebp
f01028bb:	89 e5                	mov    %esp,%ebp
f01028bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01028c0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01028c3:	eb 06                	jmp    f01028cb <strcmp+0x11>
		p++, q++;
f01028c5:	83 c1 01             	add    $0x1,%ecx
f01028c8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01028cb:	0f b6 01             	movzbl (%ecx),%eax
f01028ce:	84 c0                	test   %al,%al
f01028d0:	74 04                	je     f01028d6 <strcmp+0x1c>
f01028d2:	3a 02                	cmp    (%edx),%al
f01028d4:	74 ef                	je     f01028c5 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01028d6:	0f b6 c0             	movzbl %al,%eax
f01028d9:	0f b6 12             	movzbl (%edx),%edx
f01028dc:	29 d0                	sub    %edx,%eax
}
f01028de:	5d                   	pop    %ebp
f01028df:	c3                   	ret    

f01028e0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01028e0:	55                   	push   %ebp
f01028e1:	89 e5                	mov    %esp,%ebp
f01028e3:	53                   	push   %ebx
f01028e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01028e7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01028ea:	89 c3                	mov    %eax,%ebx
f01028ec:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01028ef:	eb 06                	jmp    f01028f7 <strncmp+0x17>
		n--, p++, q++;
f01028f1:	83 c0 01             	add    $0x1,%eax
f01028f4:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01028f7:	39 d8                	cmp    %ebx,%eax
f01028f9:	74 15                	je     f0102910 <strncmp+0x30>
f01028fb:	0f b6 08             	movzbl (%eax),%ecx
f01028fe:	84 c9                	test   %cl,%cl
f0102900:	74 04                	je     f0102906 <strncmp+0x26>
f0102902:	3a 0a                	cmp    (%edx),%cl
f0102904:	74 eb                	je     f01028f1 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102906:	0f b6 00             	movzbl (%eax),%eax
f0102909:	0f b6 12             	movzbl (%edx),%edx
f010290c:	29 d0                	sub    %edx,%eax
f010290e:	eb 05                	jmp    f0102915 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0102910:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0102915:	5b                   	pop    %ebx
f0102916:	5d                   	pop    %ebp
f0102917:	c3                   	ret    

f0102918 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0102918:	55                   	push   %ebp
f0102919:	89 e5                	mov    %esp,%ebp
f010291b:	8b 45 08             	mov    0x8(%ebp),%eax
f010291e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102922:	eb 07                	jmp    f010292b <strchr+0x13>
		if (*s == c)
f0102924:	38 ca                	cmp    %cl,%dl
f0102926:	74 0f                	je     f0102937 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0102928:	83 c0 01             	add    $0x1,%eax
f010292b:	0f b6 10             	movzbl (%eax),%edx
f010292e:	84 d2                	test   %dl,%dl
f0102930:	75 f2                	jne    f0102924 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0102932:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102937:	5d                   	pop    %ebp
f0102938:	c3                   	ret    

f0102939 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0102939:	55                   	push   %ebp
f010293a:	89 e5                	mov    %esp,%ebp
f010293c:	8b 45 08             	mov    0x8(%ebp),%eax
f010293f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102943:	eb 03                	jmp    f0102948 <strfind+0xf>
f0102945:	83 c0 01             	add    $0x1,%eax
f0102948:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010294b:	38 ca                	cmp    %cl,%dl
f010294d:	74 04                	je     f0102953 <strfind+0x1a>
f010294f:	84 d2                	test   %dl,%dl
f0102951:	75 f2                	jne    f0102945 <strfind+0xc>
			break;
	return (char *) s;
}
f0102953:	5d                   	pop    %ebp
f0102954:	c3                   	ret    

f0102955 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0102955:	55                   	push   %ebp
f0102956:	89 e5                	mov    %esp,%ebp
f0102958:	57                   	push   %edi
f0102959:	56                   	push   %esi
f010295a:	53                   	push   %ebx
f010295b:	8b 55 08             	mov    0x8(%ebp),%edx
f010295e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f0102961:	85 c9                	test   %ecx,%ecx
f0102963:	74 37                	je     f010299c <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0102965:	f6 c2 03             	test   $0x3,%dl
f0102968:	75 2a                	jne    f0102994 <memset+0x3f>
f010296a:	f6 c1 03             	test   $0x3,%cl
f010296d:	75 25                	jne    f0102994 <memset+0x3f>
		c &= 0xFF;
f010296f:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102973:	89 df                	mov    %ebx,%edi
f0102975:	c1 e7 08             	shl    $0x8,%edi
f0102978:	89 de                	mov    %ebx,%esi
f010297a:	c1 e6 18             	shl    $0x18,%esi
f010297d:	89 d8                	mov    %ebx,%eax
f010297f:	c1 e0 10             	shl    $0x10,%eax
f0102982:	09 f0                	or     %esi,%eax
f0102984:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f0102986:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0102989:	89 f8                	mov    %edi,%eax
f010298b:	09 d8                	or     %ebx,%eax
f010298d:	89 d7                	mov    %edx,%edi
f010298f:	fc                   	cld    
f0102990:	f3 ab                	rep stos %eax,%es:(%edi)
f0102992:	eb 08                	jmp    f010299c <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0102994:	89 d7                	mov    %edx,%edi
f0102996:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102999:	fc                   	cld    
f010299a:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f010299c:	89 d0                	mov    %edx,%eax
f010299e:	5b                   	pop    %ebx
f010299f:	5e                   	pop    %esi
f01029a0:	5f                   	pop    %edi
f01029a1:	5d                   	pop    %ebp
f01029a2:	c3                   	ret    

f01029a3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01029a3:	55                   	push   %ebp
f01029a4:	89 e5                	mov    %esp,%ebp
f01029a6:	57                   	push   %edi
f01029a7:	56                   	push   %esi
f01029a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01029ab:	8b 75 0c             	mov    0xc(%ebp),%esi
f01029ae:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01029b1:	39 c6                	cmp    %eax,%esi
f01029b3:	73 35                	jae    f01029ea <memmove+0x47>
f01029b5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01029b8:	39 d0                	cmp    %edx,%eax
f01029ba:	73 2e                	jae    f01029ea <memmove+0x47>
		s += n;
		d += n;
f01029bc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01029bf:	89 d6                	mov    %edx,%esi
f01029c1:	09 fe                	or     %edi,%esi
f01029c3:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01029c9:	75 13                	jne    f01029de <memmove+0x3b>
f01029cb:	f6 c1 03             	test   $0x3,%cl
f01029ce:	75 0e                	jne    f01029de <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01029d0:	83 ef 04             	sub    $0x4,%edi
f01029d3:	8d 72 fc             	lea    -0x4(%edx),%esi
f01029d6:	c1 e9 02             	shr    $0x2,%ecx
f01029d9:	fd                   	std    
f01029da:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01029dc:	eb 09                	jmp    f01029e7 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01029de:	83 ef 01             	sub    $0x1,%edi
f01029e1:	8d 72 ff             	lea    -0x1(%edx),%esi
f01029e4:	fd                   	std    
f01029e5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01029e7:	fc                   	cld    
f01029e8:	eb 1d                	jmp    f0102a07 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01029ea:	89 f2                	mov    %esi,%edx
f01029ec:	09 c2                	or     %eax,%edx
f01029ee:	f6 c2 03             	test   $0x3,%dl
f01029f1:	75 0f                	jne    f0102a02 <memmove+0x5f>
f01029f3:	f6 c1 03             	test   $0x3,%cl
f01029f6:	75 0a                	jne    f0102a02 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01029f8:	c1 e9 02             	shr    $0x2,%ecx
f01029fb:	89 c7                	mov    %eax,%edi
f01029fd:	fc                   	cld    
f01029fe:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102a00:	eb 05                	jmp    f0102a07 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102a02:	89 c7                	mov    %eax,%edi
f0102a04:	fc                   	cld    
f0102a05:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102a07:	5e                   	pop    %esi
f0102a08:	5f                   	pop    %edi
f0102a09:	5d                   	pop    %ebp
f0102a0a:	c3                   	ret    

f0102a0b <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102a0b:	55                   	push   %ebp
f0102a0c:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0102a0e:	ff 75 10             	pushl  0x10(%ebp)
f0102a11:	ff 75 0c             	pushl  0xc(%ebp)
f0102a14:	ff 75 08             	pushl  0x8(%ebp)
f0102a17:	e8 87 ff ff ff       	call   f01029a3 <memmove>
}
f0102a1c:	c9                   	leave  
f0102a1d:	c3                   	ret    

f0102a1e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102a1e:	55                   	push   %ebp
f0102a1f:	89 e5                	mov    %esp,%ebp
f0102a21:	56                   	push   %esi
f0102a22:	53                   	push   %ebx
f0102a23:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a26:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a29:	89 c6                	mov    %eax,%esi
f0102a2b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102a2e:	eb 1a                	jmp    f0102a4a <memcmp+0x2c>
		if (*s1 != *s2)
f0102a30:	0f b6 08             	movzbl (%eax),%ecx
f0102a33:	0f b6 1a             	movzbl (%edx),%ebx
f0102a36:	38 d9                	cmp    %bl,%cl
f0102a38:	74 0a                	je     f0102a44 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0102a3a:	0f b6 c1             	movzbl %cl,%eax
f0102a3d:	0f b6 db             	movzbl %bl,%ebx
f0102a40:	29 d8                	sub    %ebx,%eax
f0102a42:	eb 0f                	jmp    f0102a53 <memcmp+0x35>
		s1++, s2++;
f0102a44:	83 c0 01             	add    $0x1,%eax
f0102a47:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102a4a:	39 f0                	cmp    %esi,%eax
f0102a4c:	75 e2                	jne    f0102a30 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0102a4e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a53:	5b                   	pop    %ebx
f0102a54:	5e                   	pop    %esi
f0102a55:	5d                   	pop    %ebp
f0102a56:	c3                   	ret    

f0102a57 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102a57:	55                   	push   %ebp
f0102a58:	89 e5                	mov    %esp,%ebp
f0102a5a:	53                   	push   %ebx
f0102a5b:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0102a5e:	89 c1                	mov    %eax,%ecx
f0102a60:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0102a63:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0102a67:	eb 0a                	jmp    f0102a73 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102a69:	0f b6 10             	movzbl (%eax),%edx
f0102a6c:	39 da                	cmp    %ebx,%edx
f0102a6e:	74 07                	je     f0102a77 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0102a70:	83 c0 01             	add    $0x1,%eax
f0102a73:	39 c8                	cmp    %ecx,%eax
f0102a75:	72 f2                	jb     f0102a69 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0102a77:	5b                   	pop    %ebx
f0102a78:	5d                   	pop    %ebp
f0102a79:	c3                   	ret    

f0102a7a <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102a7a:	55                   	push   %ebp
f0102a7b:	89 e5                	mov    %esp,%ebp
f0102a7d:	57                   	push   %edi
f0102a7e:	56                   	push   %esi
f0102a7f:	53                   	push   %ebx
f0102a80:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102a83:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102a86:	eb 03                	jmp    f0102a8b <strtol+0x11>
		s++;
f0102a88:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102a8b:	0f b6 01             	movzbl (%ecx),%eax
f0102a8e:	3c 20                	cmp    $0x20,%al
f0102a90:	74 f6                	je     f0102a88 <strtol+0xe>
f0102a92:	3c 09                	cmp    $0x9,%al
f0102a94:	74 f2                	je     f0102a88 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0102a96:	3c 2b                	cmp    $0x2b,%al
f0102a98:	75 0a                	jne    f0102aa4 <strtol+0x2a>
		s++;
f0102a9a:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102a9d:	bf 00 00 00 00       	mov    $0x0,%edi
f0102aa2:	eb 11                	jmp    f0102ab5 <strtol+0x3b>
f0102aa4:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0102aa9:	3c 2d                	cmp    $0x2d,%al
f0102aab:	75 08                	jne    f0102ab5 <strtol+0x3b>
		s++, neg = 1;
f0102aad:	83 c1 01             	add    $0x1,%ecx
f0102ab0:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102ab5:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102abb:	75 15                	jne    f0102ad2 <strtol+0x58>
f0102abd:	80 39 30             	cmpb   $0x30,(%ecx)
f0102ac0:	75 10                	jne    f0102ad2 <strtol+0x58>
f0102ac2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0102ac6:	75 7c                	jne    f0102b44 <strtol+0xca>
		s += 2, base = 16;
f0102ac8:	83 c1 02             	add    $0x2,%ecx
f0102acb:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102ad0:	eb 16                	jmp    f0102ae8 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0102ad2:	85 db                	test   %ebx,%ebx
f0102ad4:	75 12                	jne    f0102ae8 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102ad6:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102adb:	80 39 30             	cmpb   $0x30,(%ecx)
f0102ade:	75 08                	jne    f0102ae8 <strtol+0x6e>
		s++, base = 8;
f0102ae0:	83 c1 01             	add    $0x1,%ecx
f0102ae3:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0102ae8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aed:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102af0:	0f b6 11             	movzbl (%ecx),%edx
f0102af3:	8d 72 d0             	lea    -0x30(%edx),%esi
f0102af6:	89 f3                	mov    %esi,%ebx
f0102af8:	80 fb 09             	cmp    $0x9,%bl
f0102afb:	77 08                	ja     f0102b05 <strtol+0x8b>
			dig = *s - '0';
f0102afd:	0f be d2             	movsbl %dl,%edx
f0102b00:	83 ea 30             	sub    $0x30,%edx
f0102b03:	eb 22                	jmp    f0102b27 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0102b05:	8d 72 9f             	lea    -0x61(%edx),%esi
f0102b08:	89 f3                	mov    %esi,%ebx
f0102b0a:	80 fb 19             	cmp    $0x19,%bl
f0102b0d:	77 08                	ja     f0102b17 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0102b0f:	0f be d2             	movsbl %dl,%edx
f0102b12:	83 ea 57             	sub    $0x57,%edx
f0102b15:	eb 10                	jmp    f0102b27 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0102b17:	8d 72 bf             	lea    -0x41(%edx),%esi
f0102b1a:	89 f3                	mov    %esi,%ebx
f0102b1c:	80 fb 19             	cmp    $0x19,%bl
f0102b1f:	77 16                	ja     f0102b37 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0102b21:	0f be d2             	movsbl %dl,%edx
f0102b24:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0102b27:	3b 55 10             	cmp    0x10(%ebp),%edx
f0102b2a:	7d 0b                	jge    f0102b37 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0102b2c:	83 c1 01             	add    $0x1,%ecx
f0102b2f:	0f af 45 10          	imul   0x10(%ebp),%eax
f0102b33:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0102b35:	eb b9                	jmp    f0102af0 <strtol+0x76>

	if (endptr)
f0102b37:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102b3b:	74 0d                	je     f0102b4a <strtol+0xd0>
		*endptr = (char *) s;
f0102b3d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102b40:	89 0e                	mov    %ecx,(%esi)
f0102b42:	eb 06                	jmp    f0102b4a <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102b44:	85 db                	test   %ebx,%ebx
f0102b46:	74 98                	je     f0102ae0 <strtol+0x66>
f0102b48:	eb 9e                	jmp    f0102ae8 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0102b4a:	89 c2                	mov    %eax,%edx
f0102b4c:	f7 da                	neg    %edx
f0102b4e:	85 ff                	test   %edi,%edi
f0102b50:	0f 45 c2             	cmovne %edx,%eax
}
f0102b53:	5b                   	pop    %ebx
f0102b54:	5e                   	pop    %esi
f0102b55:	5f                   	pop    %edi
f0102b56:	5d                   	pop    %ebp
f0102b57:	c3                   	ret    
f0102b58:	66 90                	xchg   %ax,%ax
f0102b5a:	66 90                	xchg   %ax,%ax
f0102b5c:	66 90                	xchg   %ax,%ax
f0102b5e:	66 90                	xchg   %ax,%ax

f0102b60 <__udivdi3>:
f0102b60:	55                   	push   %ebp
f0102b61:	57                   	push   %edi
f0102b62:	56                   	push   %esi
f0102b63:	53                   	push   %ebx
f0102b64:	83 ec 1c             	sub    $0x1c,%esp
f0102b67:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f0102b6b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0102b6f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0102b73:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102b77:	85 f6                	test   %esi,%esi
f0102b79:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102b7d:	89 ca                	mov    %ecx,%edx
f0102b7f:	89 f8                	mov    %edi,%eax
f0102b81:	75 3d                	jne    f0102bc0 <__udivdi3+0x60>
f0102b83:	39 cf                	cmp    %ecx,%edi
f0102b85:	0f 87 c5 00 00 00    	ja     f0102c50 <__udivdi3+0xf0>
f0102b8b:	85 ff                	test   %edi,%edi
f0102b8d:	89 fd                	mov    %edi,%ebp
f0102b8f:	75 0b                	jne    f0102b9c <__udivdi3+0x3c>
f0102b91:	b8 01 00 00 00       	mov    $0x1,%eax
f0102b96:	31 d2                	xor    %edx,%edx
f0102b98:	f7 f7                	div    %edi
f0102b9a:	89 c5                	mov    %eax,%ebp
f0102b9c:	89 c8                	mov    %ecx,%eax
f0102b9e:	31 d2                	xor    %edx,%edx
f0102ba0:	f7 f5                	div    %ebp
f0102ba2:	89 c1                	mov    %eax,%ecx
f0102ba4:	89 d8                	mov    %ebx,%eax
f0102ba6:	89 cf                	mov    %ecx,%edi
f0102ba8:	f7 f5                	div    %ebp
f0102baa:	89 c3                	mov    %eax,%ebx
f0102bac:	89 d8                	mov    %ebx,%eax
f0102bae:	89 fa                	mov    %edi,%edx
f0102bb0:	83 c4 1c             	add    $0x1c,%esp
f0102bb3:	5b                   	pop    %ebx
f0102bb4:	5e                   	pop    %esi
f0102bb5:	5f                   	pop    %edi
f0102bb6:	5d                   	pop    %ebp
f0102bb7:	c3                   	ret    
f0102bb8:	90                   	nop
f0102bb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102bc0:	39 ce                	cmp    %ecx,%esi
f0102bc2:	77 74                	ja     f0102c38 <__udivdi3+0xd8>
f0102bc4:	0f bd fe             	bsr    %esi,%edi
f0102bc7:	83 f7 1f             	xor    $0x1f,%edi
f0102bca:	0f 84 98 00 00 00    	je     f0102c68 <__udivdi3+0x108>
f0102bd0:	bb 20 00 00 00       	mov    $0x20,%ebx
f0102bd5:	89 f9                	mov    %edi,%ecx
f0102bd7:	89 c5                	mov    %eax,%ebp
f0102bd9:	29 fb                	sub    %edi,%ebx
f0102bdb:	d3 e6                	shl    %cl,%esi
f0102bdd:	89 d9                	mov    %ebx,%ecx
f0102bdf:	d3 ed                	shr    %cl,%ebp
f0102be1:	89 f9                	mov    %edi,%ecx
f0102be3:	d3 e0                	shl    %cl,%eax
f0102be5:	09 ee                	or     %ebp,%esi
f0102be7:	89 d9                	mov    %ebx,%ecx
f0102be9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bed:	89 d5                	mov    %edx,%ebp
f0102bef:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102bf3:	d3 ed                	shr    %cl,%ebp
f0102bf5:	89 f9                	mov    %edi,%ecx
f0102bf7:	d3 e2                	shl    %cl,%edx
f0102bf9:	89 d9                	mov    %ebx,%ecx
f0102bfb:	d3 e8                	shr    %cl,%eax
f0102bfd:	09 c2                	or     %eax,%edx
f0102bff:	89 d0                	mov    %edx,%eax
f0102c01:	89 ea                	mov    %ebp,%edx
f0102c03:	f7 f6                	div    %esi
f0102c05:	89 d5                	mov    %edx,%ebp
f0102c07:	89 c3                	mov    %eax,%ebx
f0102c09:	f7 64 24 0c          	mull   0xc(%esp)
f0102c0d:	39 d5                	cmp    %edx,%ebp
f0102c0f:	72 10                	jb     f0102c21 <__udivdi3+0xc1>
f0102c11:	8b 74 24 08          	mov    0x8(%esp),%esi
f0102c15:	89 f9                	mov    %edi,%ecx
f0102c17:	d3 e6                	shl    %cl,%esi
f0102c19:	39 c6                	cmp    %eax,%esi
f0102c1b:	73 07                	jae    f0102c24 <__udivdi3+0xc4>
f0102c1d:	39 d5                	cmp    %edx,%ebp
f0102c1f:	75 03                	jne    f0102c24 <__udivdi3+0xc4>
f0102c21:	83 eb 01             	sub    $0x1,%ebx
f0102c24:	31 ff                	xor    %edi,%edi
f0102c26:	89 d8                	mov    %ebx,%eax
f0102c28:	89 fa                	mov    %edi,%edx
f0102c2a:	83 c4 1c             	add    $0x1c,%esp
f0102c2d:	5b                   	pop    %ebx
f0102c2e:	5e                   	pop    %esi
f0102c2f:	5f                   	pop    %edi
f0102c30:	5d                   	pop    %ebp
f0102c31:	c3                   	ret    
f0102c32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102c38:	31 ff                	xor    %edi,%edi
f0102c3a:	31 db                	xor    %ebx,%ebx
f0102c3c:	89 d8                	mov    %ebx,%eax
f0102c3e:	89 fa                	mov    %edi,%edx
f0102c40:	83 c4 1c             	add    $0x1c,%esp
f0102c43:	5b                   	pop    %ebx
f0102c44:	5e                   	pop    %esi
f0102c45:	5f                   	pop    %edi
f0102c46:	5d                   	pop    %ebp
f0102c47:	c3                   	ret    
f0102c48:	90                   	nop
f0102c49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102c50:	89 d8                	mov    %ebx,%eax
f0102c52:	f7 f7                	div    %edi
f0102c54:	31 ff                	xor    %edi,%edi
f0102c56:	89 c3                	mov    %eax,%ebx
f0102c58:	89 d8                	mov    %ebx,%eax
f0102c5a:	89 fa                	mov    %edi,%edx
f0102c5c:	83 c4 1c             	add    $0x1c,%esp
f0102c5f:	5b                   	pop    %ebx
f0102c60:	5e                   	pop    %esi
f0102c61:	5f                   	pop    %edi
f0102c62:	5d                   	pop    %ebp
f0102c63:	c3                   	ret    
f0102c64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102c68:	39 ce                	cmp    %ecx,%esi
f0102c6a:	72 0c                	jb     f0102c78 <__udivdi3+0x118>
f0102c6c:	31 db                	xor    %ebx,%ebx
f0102c6e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0102c72:	0f 87 34 ff ff ff    	ja     f0102bac <__udivdi3+0x4c>
f0102c78:	bb 01 00 00 00       	mov    $0x1,%ebx
f0102c7d:	e9 2a ff ff ff       	jmp    f0102bac <__udivdi3+0x4c>
f0102c82:	66 90                	xchg   %ax,%ax
f0102c84:	66 90                	xchg   %ax,%ax
f0102c86:	66 90                	xchg   %ax,%ax
f0102c88:	66 90                	xchg   %ax,%ax
f0102c8a:	66 90                	xchg   %ax,%ax
f0102c8c:	66 90                	xchg   %ax,%ax
f0102c8e:	66 90                	xchg   %ax,%ax

f0102c90 <__umoddi3>:
f0102c90:	55                   	push   %ebp
f0102c91:	57                   	push   %edi
f0102c92:	56                   	push   %esi
f0102c93:	53                   	push   %ebx
f0102c94:	83 ec 1c             	sub    $0x1c,%esp
f0102c97:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0102c9b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0102c9f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102ca3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102ca7:	85 d2                	test   %edx,%edx
f0102ca9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102cad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102cb1:	89 f3                	mov    %esi,%ebx
f0102cb3:	89 3c 24             	mov    %edi,(%esp)
f0102cb6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102cba:	75 1c                	jne    f0102cd8 <__umoddi3+0x48>
f0102cbc:	39 f7                	cmp    %esi,%edi
f0102cbe:	76 50                	jbe    f0102d10 <__umoddi3+0x80>
f0102cc0:	89 c8                	mov    %ecx,%eax
f0102cc2:	89 f2                	mov    %esi,%edx
f0102cc4:	f7 f7                	div    %edi
f0102cc6:	89 d0                	mov    %edx,%eax
f0102cc8:	31 d2                	xor    %edx,%edx
f0102cca:	83 c4 1c             	add    $0x1c,%esp
f0102ccd:	5b                   	pop    %ebx
f0102cce:	5e                   	pop    %esi
f0102ccf:	5f                   	pop    %edi
f0102cd0:	5d                   	pop    %ebp
f0102cd1:	c3                   	ret    
f0102cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102cd8:	39 f2                	cmp    %esi,%edx
f0102cda:	89 d0                	mov    %edx,%eax
f0102cdc:	77 52                	ja     f0102d30 <__umoddi3+0xa0>
f0102cde:	0f bd ea             	bsr    %edx,%ebp
f0102ce1:	83 f5 1f             	xor    $0x1f,%ebp
f0102ce4:	75 5a                	jne    f0102d40 <__umoddi3+0xb0>
f0102ce6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f0102cea:	0f 82 e0 00 00 00    	jb     f0102dd0 <__umoddi3+0x140>
f0102cf0:	39 0c 24             	cmp    %ecx,(%esp)
f0102cf3:	0f 86 d7 00 00 00    	jbe    f0102dd0 <__umoddi3+0x140>
f0102cf9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102cfd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0102d01:	83 c4 1c             	add    $0x1c,%esp
f0102d04:	5b                   	pop    %ebx
f0102d05:	5e                   	pop    %esi
f0102d06:	5f                   	pop    %edi
f0102d07:	5d                   	pop    %ebp
f0102d08:	c3                   	ret    
f0102d09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102d10:	85 ff                	test   %edi,%edi
f0102d12:	89 fd                	mov    %edi,%ebp
f0102d14:	75 0b                	jne    f0102d21 <__umoddi3+0x91>
f0102d16:	b8 01 00 00 00       	mov    $0x1,%eax
f0102d1b:	31 d2                	xor    %edx,%edx
f0102d1d:	f7 f7                	div    %edi
f0102d1f:	89 c5                	mov    %eax,%ebp
f0102d21:	89 f0                	mov    %esi,%eax
f0102d23:	31 d2                	xor    %edx,%edx
f0102d25:	f7 f5                	div    %ebp
f0102d27:	89 c8                	mov    %ecx,%eax
f0102d29:	f7 f5                	div    %ebp
f0102d2b:	89 d0                	mov    %edx,%eax
f0102d2d:	eb 99                	jmp    f0102cc8 <__umoddi3+0x38>
f0102d2f:	90                   	nop
f0102d30:	89 c8                	mov    %ecx,%eax
f0102d32:	89 f2                	mov    %esi,%edx
f0102d34:	83 c4 1c             	add    $0x1c,%esp
f0102d37:	5b                   	pop    %ebx
f0102d38:	5e                   	pop    %esi
f0102d39:	5f                   	pop    %edi
f0102d3a:	5d                   	pop    %ebp
f0102d3b:	c3                   	ret    
f0102d3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102d40:	8b 34 24             	mov    (%esp),%esi
f0102d43:	bf 20 00 00 00       	mov    $0x20,%edi
f0102d48:	89 e9                	mov    %ebp,%ecx
f0102d4a:	29 ef                	sub    %ebp,%edi
f0102d4c:	d3 e0                	shl    %cl,%eax
f0102d4e:	89 f9                	mov    %edi,%ecx
f0102d50:	89 f2                	mov    %esi,%edx
f0102d52:	d3 ea                	shr    %cl,%edx
f0102d54:	89 e9                	mov    %ebp,%ecx
f0102d56:	09 c2                	or     %eax,%edx
f0102d58:	89 d8                	mov    %ebx,%eax
f0102d5a:	89 14 24             	mov    %edx,(%esp)
f0102d5d:	89 f2                	mov    %esi,%edx
f0102d5f:	d3 e2                	shl    %cl,%edx
f0102d61:	89 f9                	mov    %edi,%ecx
f0102d63:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102d67:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0102d6b:	d3 e8                	shr    %cl,%eax
f0102d6d:	89 e9                	mov    %ebp,%ecx
f0102d6f:	89 c6                	mov    %eax,%esi
f0102d71:	d3 e3                	shl    %cl,%ebx
f0102d73:	89 f9                	mov    %edi,%ecx
f0102d75:	89 d0                	mov    %edx,%eax
f0102d77:	d3 e8                	shr    %cl,%eax
f0102d79:	89 e9                	mov    %ebp,%ecx
f0102d7b:	09 d8                	or     %ebx,%eax
f0102d7d:	89 d3                	mov    %edx,%ebx
f0102d7f:	89 f2                	mov    %esi,%edx
f0102d81:	f7 34 24             	divl   (%esp)
f0102d84:	89 d6                	mov    %edx,%esi
f0102d86:	d3 e3                	shl    %cl,%ebx
f0102d88:	f7 64 24 04          	mull   0x4(%esp)
f0102d8c:	39 d6                	cmp    %edx,%esi
f0102d8e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102d92:	89 d1                	mov    %edx,%ecx
f0102d94:	89 c3                	mov    %eax,%ebx
f0102d96:	72 08                	jb     f0102da0 <__umoddi3+0x110>
f0102d98:	75 11                	jne    f0102dab <__umoddi3+0x11b>
f0102d9a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0102d9e:	73 0b                	jae    f0102dab <__umoddi3+0x11b>
f0102da0:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102da4:	1b 14 24             	sbb    (%esp),%edx
f0102da7:	89 d1                	mov    %edx,%ecx
f0102da9:	89 c3                	mov    %eax,%ebx
f0102dab:	8b 54 24 08          	mov    0x8(%esp),%edx
f0102daf:	29 da                	sub    %ebx,%edx
f0102db1:	19 ce                	sbb    %ecx,%esi
f0102db3:	89 f9                	mov    %edi,%ecx
f0102db5:	89 f0                	mov    %esi,%eax
f0102db7:	d3 e0                	shl    %cl,%eax
f0102db9:	89 e9                	mov    %ebp,%ecx
f0102dbb:	d3 ea                	shr    %cl,%edx
f0102dbd:	89 e9                	mov    %ebp,%ecx
f0102dbf:	d3 ee                	shr    %cl,%esi
f0102dc1:	09 d0                	or     %edx,%eax
f0102dc3:	89 f2                	mov    %esi,%edx
f0102dc5:	83 c4 1c             	add    $0x1c,%esp
f0102dc8:	5b                   	pop    %ebx
f0102dc9:	5e                   	pop    %esi
f0102dca:	5f                   	pop    %edi
f0102dcb:	5d                   	pop    %ebp
f0102dcc:	c3                   	ret    
f0102dcd:	8d 76 00             	lea    0x0(%esi),%esi
f0102dd0:	29 f9                	sub    %edi,%ecx
f0102dd2:	19 d6                	sbb    %edx,%esi
f0102dd4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102dd8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102ddc:	e9 18 ff ff ff       	jmp    f0102cf9 <__umoddi3+0x69>
