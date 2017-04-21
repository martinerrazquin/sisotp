
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

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
f0100046:	b8 50 79 11 f0       	mov    $0xf0117950,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 32 32 00 00       	call   f010328f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 78 06 00 00       	call   f01006da <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 37 10 f0       	push   $0xf0103740
f010006f:	e8 77 27 00 00       	call   f01027eb <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 8f 24 00 00       	call   f0102508 <mem_init>
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
f0100093:	83 3d 40 79 11 f0 00 	cmpl   $0x0,0xf0117940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 79 11 f0    	mov    %esi,0xf0117940

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
f01000b0:	68 7c 37 10 f0       	push   $0xf010377c
f01000b5:	e8 31 27 00 00       	call   f01027eb <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 01 27 00 00       	call   f01027c5 <vcprintf>
	cprintf("\n>>>\n");
f01000c4:	c7 04 24 5b 37 10 f0 	movl   $0xf010375b,(%esp)
f01000cb:	e8 1b 27 00 00       	call   f01027eb <cprintf>
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
f01000f2:	68 61 37 10 f0       	push   $0xf0103761
f01000f7:	e8 ef 26 00 00       	call   f01027eb <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 bd 26 00 00       	call   f01027c5 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 af 49 10 f0 	movl   $0xf01049af,(%esp)
f010010f:	e8 d7 26 00 00       	call   f01027eb <cprintf>
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
f010023b:	0f 95 05 34 75 11 f0 	setne  0xf0117534
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
f01002db:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
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
f01002f5:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
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
f0100306:	8b 35 30 75 11 f0    	mov    0xf0117530,%esi
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
f010033e:	89 0d 2c 75 11 f0    	mov    %ecx,0xf011752c
	crt_pos = pos;
f0100344:	0f b6 c0             	movzbl %al,%eax
f0100347:	09 c3                	or     %eax,%ebx
f0100349:	66 89 1d 28 75 11 f0 	mov    %bx,0xf0117528
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
f0100367:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f010036d:	8d 51 01             	lea    0x1(%ecx),%edx
f0100370:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100376:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010037c:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100382:	75 0a                	jne    f010038e <cons_intr+0x36>
			cons.wpos = 0;
f0100384:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
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
f01003ca:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01003d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01003d6:	e9 e7 00 00 00       	jmp    f01004c2 <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f01003db:	84 c0                	test   %al,%al
f01003dd:	79 38                	jns    f0100417 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003df:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01003e5:	89 cb                	mov    %ecx,%ebx
f01003e7:	83 e3 40             	and    $0x40,%ebx
f01003ea:	89 c2                	mov    %eax,%edx
f01003ec:	83 e2 7f             	and    $0x7f,%edx
f01003ef:	85 db                	test   %ebx,%ebx
f01003f1:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01003f4:	0f b6 c0             	movzbl %al,%eax
f01003f7:	0f b6 80 00 39 10 f0 	movzbl -0xfefc700(%eax),%eax
f01003fe:	83 c8 40             	or     $0x40,%eax
f0100401:	0f b6 c0             	movzbl %al,%eax
f0100404:	f7 d0                	not    %eax
f0100406:	21 c8                	and    %ecx,%eax
f0100408:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f010040d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100412:	e9 ab 00 00 00       	jmp    f01004c2 <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100417:	8b 15 00 73 11 f0    	mov    0xf0117300,%edx
f010041d:	f6 c2 40             	test   $0x40,%dl
f0100420:	74 0c                	je     f010042e <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100422:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100425:	83 e2 bf             	and    $0xffffffbf,%edx
f0100428:	89 15 00 73 11 f0    	mov    %edx,0xf0117300
	}

	shift |= shiftcode[data];
f010042e:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f0100431:	0f b6 90 00 39 10 f0 	movzbl -0xfefc700(%eax),%edx
f0100438:	0b 15 00 73 11 f0    	or     0xf0117300,%edx
f010043e:	0f b6 88 00 38 10 f0 	movzbl -0xfefc800(%eax),%ecx
f0100445:	31 ca                	xor    %ecx,%edx
f0100447:	89 15 00 73 11 f0    	mov    %edx,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010044d:	89 d1                	mov    %edx,%ecx
f010044f:	83 e1 03             	and    $0x3,%ecx
f0100452:	8b 0c 8d e0 37 10 f0 	mov    -0xfefc820(,%ecx,4),%ecx
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
f0100492:	68 9c 37 10 f0       	push   $0xf010379c
f0100497:	e8 4f 23 00 00       	call   f01027eb <cprintf>
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
f0100508:	0f b7 15 28 75 11 f0 	movzwl 0xf0117528,%edx
f010050f:	66 85 d2             	test   %dx,%dx
f0100512:	0f 84 e4 00 00 00    	je     f01005fc <cga_putc+0x135>
			crt_pos--;
f0100518:	83 ea 01             	sub    $0x1,%edx
f010051b:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100522:	0f b7 d2             	movzwl %dx,%edx
f0100525:	b0 00                	mov    $0x0,%al
f0100527:	83 c8 20             	or     $0x20,%eax
f010052a:	8b 0d 2c 75 11 f0    	mov    0xf011752c,%ecx
f0100530:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100534:	eb 78                	jmp    f01005ae <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100536:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010053d:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010053e:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100545:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010054b:	c1 e8 16             	shr    $0x16,%eax
f010054e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100551:	c1 e0 04             	shl    $0x4,%eax
f0100554:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
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
f0100590:	0f b7 15 28 75 11 f0 	movzwl 0xf0117528,%edx
f0100597:	8d 4a 01             	lea    0x1(%edx),%ecx
f010059a:	66 89 0d 28 75 11 f0 	mov    %cx,0xf0117528
f01005a1:	0f b7 d2             	movzwl %dx,%edx
f01005a4:	8b 0d 2c 75 11 f0    	mov    0xf011752c,%ecx
f01005aa:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005ae:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f01005b5:	cf 07 
f01005b7:	76 43                	jbe    f01005fc <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005b9:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f01005be:	83 ec 04             	sub    $0x4,%esp
f01005c1:	68 00 0f 00 00       	push   $0xf00
f01005c6:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005cc:	52                   	push   %edx
f01005cd:	50                   	push   %eax
f01005ce:	e8 0a 2d 00 00       	call   f01032dd <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005d3:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
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
f01005f4:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f01005fb:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005fc:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f0100602:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100607:	89 f8                	mov    %edi,%eax
f0100609:	e8 16 fb ff ff       	call   f0100124 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f010060e:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
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
f0100662:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
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
f01006a0:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01006a5:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01006ab:	74 26                	je     f01006d3 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006ad:	8d 50 01             	lea    0x1(%eax),%edx
f01006b0:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01006b6:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
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
f01006c7:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
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
f01006ea:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f01006f1:	75 10                	jne    f0100703 <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f01006f3:	83 ec 0c             	sub    $0xc,%esp
f01006f6:	68 a8 37 10 f0       	push   $0xf01037a8
f01006fb:	e8 eb 20 00 00       	call   f01027eb <cprintf>
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
f0100736:	68 00 3a 10 f0       	push   $0xf0103a00
f010073b:	68 1e 3a 10 f0       	push   $0xf0103a1e
f0100740:	68 23 3a 10 f0       	push   $0xf0103a23
f0100745:	e8 a1 20 00 00       	call   f01027eb <cprintf>
f010074a:	83 c4 0c             	add    $0xc,%esp
f010074d:	68 c0 3a 10 f0       	push   $0xf0103ac0
f0100752:	68 2c 3a 10 f0       	push   $0xf0103a2c
f0100757:	68 23 3a 10 f0       	push   $0xf0103a23
f010075c:	e8 8a 20 00 00       	call   f01027eb <cprintf>
f0100761:	83 c4 0c             	add    $0xc,%esp
f0100764:	68 35 3a 10 f0       	push   $0xf0103a35
f0100769:	68 49 3a 10 f0       	push   $0xf0103a49
f010076e:	68 23 3a 10 f0       	push   $0xf0103a23
f0100773:	e8 73 20 00 00       	call   f01027eb <cprintf>
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
f0100785:	68 53 3a 10 f0       	push   $0xf0103a53
f010078a:	e8 5c 20 00 00       	call   f01027eb <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010078f:	83 c4 08             	add    $0x8,%esp
f0100792:	68 0c 00 10 00       	push   $0x10000c
f0100797:	68 e8 3a 10 f0       	push   $0xf0103ae8
f010079c:	e8 4a 20 00 00       	call   f01027eb <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	68 0c 00 10 00       	push   $0x10000c
f01007a9:	68 0c 00 10 f0       	push   $0xf010000c
f01007ae:	68 10 3b 10 f0       	push   $0xf0103b10
f01007b3:	e8 33 20 00 00       	call   f01027eb <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007b8:	83 c4 0c             	add    $0xc,%esp
f01007bb:	68 21 37 10 00       	push   $0x103721
f01007c0:	68 21 37 10 f0       	push   $0xf0103721
f01007c5:	68 34 3b 10 f0       	push   $0xf0103b34
f01007ca:	e8 1c 20 00 00       	call   f01027eb <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cf:	83 c4 0c             	add    $0xc,%esp
f01007d2:	68 00 73 11 00       	push   $0x117300
f01007d7:	68 00 73 11 f0       	push   $0xf0117300
f01007dc:	68 58 3b 10 f0       	push   $0xf0103b58
f01007e1:	e8 05 20 00 00       	call   f01027eb <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e6:	83 c4 0c             	add    $0xc,%esp
f01007e9:	68 50 79 11 00       	push   $0x117950
f01007ee:	68 50 79 11 f0       	push   $0xf0117950
f01007f3:	68 7c 3b 10 f0       	push   $0xf0103b7c
f01007f8:	e8 ee 1f 00 00       	call   f01027eb <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01007fd:	b8 4f 7d 11 f0       	mov    $0xf0117d4f,%eax
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
f010081e:	68 a0 3b 10 f0       	push   $0xf0103ba0
f0100823:	e8 c3 1f 00 00       	call   f01027eb <cprintf>
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
f0100853:	68 cc 3b 10 f0       	push   $0xf0103bcc
f0100858:	e8 8e 1f 00 00       	call   f01027eb <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f010085d:	83 c4 18             	add    $0x18,%esp
f0100860:	57                   	push   %edi
f0100861:	56                   	push   %esi
f0100862:	e8 8e 20 00 00       	call   f01028f5 <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100867:	83 c4 08             	add    $0x8,%esp
f010086a:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010086d:	56                   	push   %esi
f010086e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100871:	ff 75 dc             	pushl  -0x24(%ebp)
f0100874:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100877:	ff 75 d0             	pushl  -0x30(%ebp)
f010087a:	68 6c 3a 10 f0       	push   $0xf0103a6c
f010087f:	e8 67 1f 00 00       	call   f01027eb <cprintf>
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
f01008ce:	68 83 3a 10 f0       	push   $0xf0103a83
f01008d3:	e8 7a 29 00 00       	call   f0103252 <strchr>
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
f01008f0:	68 88 3a 10 f0       	push   $0xf0103a88
f01008f5:	e8 f1 1e 00 00       	call   f01027eb <cprintf>
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
f0100921:	68 83 3a 10 f0       	push   $0xf0103a83
f0100926:	e8 27 29 00 00       	call   f0103252 <strchr>
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
f0100950:	ff 34 85 60 3c 10 f0 	pushl  -0xfefc3a0(,%eax,4)
f0100957:	ff 75 a8             	pushl  -0x58(%ebp)
f010095a:	e8 95 28 00 00       	call   f01031f4 <strcmp>
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
f0100974:	ff 14 85 68 3c 10 f0 	call   *-0xfefc398(,%eax,4)
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
f010098e:	68 a5 3a 10 f0       	push   $0xf0103aa5
f0100993:	e8 53 1e 00 00       	call   f01027eb <cprintf>
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
f01009b2:	68 00 3c 10 f0       	push   $0xf0103c00
f01009b7:	e8 2f 1e 00 00       	call   f01027eb <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009bc:	c7 04 24 24 3c 10 f0 	movl   $0xf0103c24,(%esp)
f01009c3:	e8 23 1e 00 00       	call   f01027eb <cprintf>
f01009c8:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009cb:	83 ec 0c             	sub    $0xc,%esp
f01009ce:	68 bb 3a 10 f0       	push   $0xf0103abb
f01009d3:	e8 60 26 00 00       	call   f0103038 <readline>
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
f0100a12:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
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
f0100a2b:	e8 41 1d 00 00       	call   f0102771 <mc146818_read>
f0100a30:	89 c6                	mov    %eax,%esi
f0100a32:	83 c3 01             	add    $0x1,%ebx
f0100a35:	89 1c 24             	mov    %ebx,(%esp)
f0100a38:	e8 34 1d 00 00       	call   f0102771 <mc146818_read>
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
f0100a8e:	89 15 44 79 11 f0    	mov    %edx,0xf0117944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a94:	89 c2                	mov    %eax,%edx
f0100a96:	29 da                	sub    %ebx,%edx
f0100a98:	52                   	push   %edx
f0100a99:	53                   	push   %ebx
f0100a9a:	50                   	push   %eax
f0100a9b:	68 84 3c 10 f0       	push   $0xf0103c84
f0100aa0:	e8 46 1d 00 00       	call   f01027eb <cprintf>
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
f0100aaf:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100ab6:	75 11                	jne    f0100ac9 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100ab8:	ba 4f 89 11 f0       	mov    $0xf011894f,%edx
f0100abd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ac3:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100ac9:	85 c0                	test   %eax,%eax
f0100acb:	75 06                	jne    f0100ad3 <boot_alloc+0x24>
f0100acd:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f0100ad2:	c3                   	ret    
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100ad3:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100ad9:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100adf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ae5:	01 ca                	add    %ecx,%edx
f0100ae7:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	if ((uint32_t)(nextfree-KERNBASE)>npages*PGSIZE) panic("not enough memory\n");//como chequeo esto? Uso nextfree vs npages*PGSIZE?
f0100aed:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100af3:	a1 44 79 11 f0       	mov    0xf0117944,%eax
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
f0100b05:	68 c0 45 10 f0       	push   $0xf01045c0
f0100b0a:	6a 6d                	push   $0x6d
f0100b0c:	68 d3 45 10 f0       	push   $0xf01045d3
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
f0100b25:	3b 1d 44 79 11 f0    	cmp    0xf0117944,%ebx
f0100b2b:	72 0d                	jb     f0100b3a <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b2d:	51                   	push   %ecx
f0100b2e:	68 c0 3c 10 f0       	push   $0xf0103cc0
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
f0100b57:	b8 df 45 10 f0       	mov    $0xf01045df,%eax
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
f0100b94:	ba e8 02 00 00       	mov    $0x2e8,%edx
f0100b99:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
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
f0100be2:	68 e4 3c 10 f0       	push   $0xf0103ce4
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
f0100bfe:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100c04:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100c09:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c0c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100c13:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c18:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c1b:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
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
f0100c3c:	ba b9 02 00 00       	mov    $0x2b9,%edx
f0100c41:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
f0100c46:	e8 88 ff ff ff       	call   f0100bd3 <_paddr>
f0100c4b:	01 f0                	add    %esi,%eax
f0100c4d:	39 c7                	cmp    %eax,%edi
f0100c4f:	74 19                	je     f0100c6a <check_kern_pgdir+0x75>
f0100c51:	68 08 3d 10 f0       	push   $0xf0103d08
f0100c56:	68 ed 45 10 f0       	push   $0xf01045ed
f0100c5b:	68 b9 02 00 00       	push   $0x2b9
f0100c60:	68 d3 45 10 f0       	push   $0xf01045d3
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
f0100c93:	68 3c 3d 10 f0       	push   $0xf0103d3c
f0100c98:	68 ed 45 10 f0       	push   $0xf01045ed
f0100c9d:	68 be 02 00 00       	push   $0x2be
f0100ca2:	68 d3 45 10 f0       	push   $0xf01045d3
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
f0100cca:	b9 00 d0 10 f0       	mov    $0xf010d000,%ecx
f0100ccf:	ba c2 02 00 00       	mov    $0x2c2,%edx
f0100cd4:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
f0100cd9:	e8 f5 fe ff ff       	call   f0100bd3 <_paddr>
f0100cde:	01 f0                	add    %esi,%eax
f0100ce0:	39 c7                	cmp    %eax,%edi
f0100ce2:	74 19                	je     f0100cfd <check_kern_pgdir+0x108>
f0100ce4:	68 64 3d 10 f0       	push   $0xf0103d64
f0100ce9:	68 ed 45 10 f0       	push   $0xf01045ed
f0100cee:	68 c2 02 00 00       	push   $0x2c2
f0100cf3:	68 d3 45 10 f0       	push   $0xf01045d3
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
f0100d1c:	68 ac 3d 10 f0       	push   $0xf0103dac
f0100d21:	68 ed 45 10 f0       	push   $0xf01045ed
f0100d26:	68 c3 02 00 00       	push   $0x2c3
f0100d2b:	68 d3 45 10 f0       	push   $0xf01045d3
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
f0100d54:	68 02 46 10 f0       	push   $0xf0104602
f0100d59:	68 ed 45 10 f0       	push   $0xf01045ed
f0100d5e:	68 cb 02 00 00       	push   $0x2cb
f0100d63:	68 d3 45 10 f0       	push   $0xf01045d3
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
f0100d81:	68 02 46 10 f0       	push   $0xf0104602
f0100d86:	68 ed 45 10 f0       	push   $0xf01045ed
f0100d8b:	68 cf 02 00 00       	push   $0x2cf
f0100d90:	68 d3 45 10 f0       	push   $0xf01045d3
f0100d95:	e8 f1 f2 ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0100d9a:	f6 c2 02             	test   $0x2,%dl
f0100d9d:	75 38                	jne    f0100dd7 <check_kern_pgdir+0x1e2>
f0100d9f:	68 13 46 10 f0       	push   $0xf0104613
f0100da4:	68 ed 45 10 f0       	push   $0xf01045ed
f0100da9:	68 d0 02 00 00       	push   $0x2d0
f0100dae:	68 d3 45 10 f0       	push   $0xf01045d3
f0100db3:	e8 d3 f2 ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0100db8:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100dbc:	74 19                	je     f0100dd7 <check_kern_pgdir+0x1e2>
f0100dbe:	68 24 46 10 f0       	push   $0xf0104624
f0100dc3:	68 ed 45 10 f0       	push   $0xf01045ed
f0100dc8:	68 d2 02 00 00       	push   $0x2d2
f0100dcd:	68 d3 45 10 f0       	push   $0xf01045d3
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
f0100de8:	68 dc 3d 10 f0       	push   $0xf0103ddc
f0100ded:	e8 f9 19 00 00       	call   f01027eb <cprintf>
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
f0100e16:	68 fc 3d 10 f0       	push   $0xf0103dfc
f0100e1b:	68 29 02 00 00       	push   $0x229
f0100e20:	68 d3 45 10 f0       	push   $0xf01045d3
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
f0100e6c:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
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
f0100e76:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
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
f0100ea1:	e8 e9 23 00 00       	call   f010328f <memset>
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
f0100ebc:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ec2:	8b 35 4c 79 11 f0    	mov    0xf011794c,%esi
		assert(pp < pages + npages);
f0100ec8:	a1 44 79 11 f0       	mov    0xf0117944,%eax
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
f0100eeb:	68 32 46 10 f0       	push   $0xf0104632
f0100ef0:	68 ed 45 10 f0       	push   $0xf01045ed
f0100ef5:	68 43 02 00 00       	push   $0x243
f0100efa:	68 d3 45 10 f0       	push   $0xf01045d3
f0100eff:	e8 87 f1 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100f04:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100f07:	72 19                	jb     f0100f22 <check_page_free_list+0x125>
f0100f09:	68 3e 46 10 f0       	push   $0xf010463e
f0100f0e:	68 ed 45 10 f0       	push   $0xf01045ed
f0100f13:	68 44 02 00 00       	push   $0x244
f0100f18:	68 d3 45 10 f0       	push   $0xf01045d3
f0100f1d:	e8 69 f1 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f22:	89 d8                	mov    %ebx,%eax
f0100f24:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100f27:	a8 07                	test   $0x7,%al
f0100f29:	74 19                	je     f0100f44 <check_page_free_list+0x147>
f0100f2b:	68 20 3e 10 f0       	push   $0xf0103e20
f0100f30:	68 ed 45 10 f0       	push   $0xf01045ed
f0100f35:	68 45 02 00 00       	push   $0x245
f0100f3a:	68 d3 45 10 f0       	push   $0xf01045d3
f0100f3f:	e8 47 f1 ff ff       	call   f010008b <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100f44:	89 d8                	mov    %ebx,%eax
f0100f46:	e8 c4 fa ff ff       	call   f0100a0f <page2pa>
f0100f4b:	85 c0                	test   %eax,%eax
f0100f4d:	75 19                	jne    f0100f68 <check_page_free_list+0x16b>
f0100f4f:	68 52 46 10 f0       	push   $0xf0104652
f0100f54:	68 ed 45 10 f0       	push   $0xf01045ed
f0100f59:	68 48 02 00 00       	push   $0x248
f0100f5e:	68 d3 45 10 f0       	push   $0xf01045d3
f0100f63:	e8 23 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f68:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f6d:	75 19                	jne    f0100f88 <check_page_free_list+0x18b>
f0100f6f:	68 63 46 10 f0       	push   $0xf0104663
f0100f74:	68 ed 45 10 f0       	push   $0xf01045ed
f0100f79:	68 49 02 00 00       	push   $0x249
f0100f7e:	68 d3 45 10 f0       	push   $0xf01045d3
f0100f83:	e8 03 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f88:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f8d:	75 19                	jne    f0100fa8 <check_page_free_list+0x1ab>
f0100f8f:	68 54 3e 10 f0       	push   $0xf0103e54
f0100f94:	68 ed 45 10 f0       	push   $0xf01045ed
f0100f99:	68 4a 02 00 00       	push   $0x24a
f0100f9e:	68 d3 45 10 f0       	push   $0xf01045d3
f0100fa3:	e8 e3 f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100fa8:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100fad:	75 19                	jne    f0100fc8 <check_page_free_list+0x1cb>
f0100faf:	68 7c 46 10 f0       	push   $0xf010467c
f0100fb4:	68 ed 45 10 f0       	push   $0xf01045ed
f0100fb9:	68 4b 02 00 00       	push   $0x24b
f0100fbe:	68 d3 45 10 f0       	push   $0xf01045d3
f0100fc3:	e8 c3 f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fc8:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100fcd:	76 25                	jbe    f0100ff4 <check_page_free_list+0x1f7>
f0100fcf:	89 d8                	mov    %ebx,%eax
f0100fd1:	e8 6f fb ff ff       	call   f0100b45 <page2kva>
f0100fd6:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100fd9:	76 1e                	jbe    f0100ff9 <check_page_free_list+0x1fc>
f0100fdb:	68 78 3e 10 f0       	push   $0xf0103e78
f0100fe0:	68 ed 45 10 f0       	push   $0xf01045ed
f0100fe5:	68 4c 02 00 00       	push   $0x24c
f0100fea:	68 d3 45 10 f0       	push   $0xf01045d3
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
f010100b:	68 96 46 10 f0       	push   $0xf0104696
f0101010:	68 ed 45 10 f0       	push   $0xf01045ed
f0101015:	68 54 02 00 00       	push   $0x254
f010101a:	68 d3 45 10 f0       	push   $0xf01045d3
f010101f:	e8 67 f0 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0101024:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0101028:	7f 43                	jg     f010106d <check_page_free_list+0x270>
f010102a:	68 a8 46 10 f0       	push   $0xf01046a8
f010102f:	68 ed 45 10 f0       	push   $0xf01045ed
f0101034:	68 55 02 00 00       	push   $0x255
f0101039:	68 d3 45 10 f0       	push   $0xf01045d3
f010103e:	e8 48 f0 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101043:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0101049:	85 db                	test   %ebx,%ebx
f010104b:	0f 85 d9 fd ff ff    	jne    f0100e2a <check_page_free_list+0x2d>
f0101051:	e9 bd fd ff ff       	jmp    f0100e13 <check_page_free_list+0x16>
f0101056:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
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

f0101075 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101075:	c1 e8 0c             	shr    $0xc,%eax
f0101078:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f010107e:	72 17                	jb     f0101097 <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f0101080:	55                   	push   %ebp
f0101081:	89 e5                	mov    %esp,%ebp
f0101083:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0101086:	68 c0 3e 10 f0       	push   $0xf0103ec0
f010108b:	6a 4b                	push   $0x4b
f010108d:	68 df 45 10 f0       	push   $0xf01045df
f0101092:	e8 f4 ef ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0101097:	8b 15 4c 79 11 f0    	mov    0xf011794c,%edx
f010109d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01010a0:	c3                   	ret    

f01010a1 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01010a1:	55                   	push   %ebp
f01010a2:	89 e5                	mov    %esp,%ebp
f01010a4:	56                   	push   %esi
f01010a5:	53                   	push   %ebx
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}*/ //FOR ORIGINAL
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f01010a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ab:	e8 ff f9 ff ff       	call   f0100aaf <boot_alloc>
f01010b0:	89 c1                	mov    %eax,%ecx
f01010b2:	ba 2c 01 00 00       	mov    $0x12c,%edx
f01010b7:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
f01010bc:	e8 12 fb ff ff       	call   f0100bd3 <_paddr>
f01010c1:	c1 e8 0c             	shr    $0xc,%eax
f01010c4:	8b 35 3c 75 11 f0    	mov    0xf011753c,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f01010ca:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010cf:	ba 01 00 00 00       	mov    $0x1,%edx
f01010d4:	eb 33                	jmp    f0101109 <page_init+0x68>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f01010d6:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f01010dc:	76 04                	jbe    f01010e2 <page_init+0x41>
f01010de:	39 c2                	cmp    %eax,%edx
f01010e0:	72 24                	jb     f0101106 <page_init+0x65>
		pages[i].pp_ref = 0;
f01010e2:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01010e9:	89 cb                	mov    %ecx,%ebx
f01010eb:	03 1d 4c 79 11 f0    	add    0xf011794c,%ebx
f01010f1:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f01010f7:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f01010f9:	89 ce                	mov    %ecx,%esi
f01010fb:	03 35 4c 79 11 f0    	add    0xf011794c,%esi
f0101101:	b9 01 00 00 00       	mov    $0x1,%ecx
		page_free_list = &pages[i];
	}*/ //FOR ORIGINAL
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101106:	83 c2 01             	add    $0x1,%edx
f0101109:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f010110f:	72 c5                	jb     f01010d6 <page_init+0x35>
f0101111:	84 c9                	test   %cl,%cl
f0101113:	74 06                	je     f010111b <page_init+0x7a>
f0101115:	89 35 3c 75 11 f0    	mov    %esi,0xf011753c
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f010111b:	5b                   	pop    %ebx
f010111c:	5e                   	pop    %esi
f010111d:	5d                   	pop    %ebp
f010111e:	c3                   	ret    

f010111f <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f010111f:	55                   	push   %ebp
f0101120:	89 e5                	mov    %esp,%ebp
f0101122:	53                   	push   %ebx
f0101123:	83 ec 04             	sub    $0x4,%esp
f0101126:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f010112c:	85 db                	test   %ebx,%ebx
f010112e:	74 2d                	je     f010115d <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f0101130:	8b 03                	mov    (%ebx),%eax
f0101132:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	pag->pp_link = NULL;
f0101137:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f010113d:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101141:	74 1a                	je     f010115d <page_alloc+0x3e>
f0101143:	89 d8                	mov    %ebx,%eax
f0101145:	e8 fb f9 ff ff       	call   f0100b45 <page2kva>
f010114a:	83 ec 04             	sub    $0x4,%esp
f010114d:	68 00 10 00 00       	push   $0x1000
f0101152:	6a 00                	push   $0x0
f0101154:	50                   	push   %eax
f0101155:	e8 35 21 00 00       	call   f010328f <memset>
f010115a:	83 c4 10             	add    $0x10,%esp
	return pag;
}
f010115d:	89 d8                	mov    %ebx,%eax
f010115f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101162:	c9                   	leave  
f0101163:	c3                   	ret    

f0101164 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101164:	55                   	push   %ebp
f0101165:	89 e5                	mov    %esp,%ebp
f0101167:	83 ec 08             	sub    $0x8,%esp
f010116a:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f010116d:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101172:	74 17                	je     f010118b <page_free+0x27>
f0101174:	83 ec 04             	sub    $0x4,%esp
f0101177:	68 b9 46 10 f0       	push   $0xf01046b9
f010117c:	68 55 01 00 00       	push   $0x155
f0101181:	68 d3 45 10 f0       	push   $0xf01045d3
f0101186:	e8 00 ef ff ff       	call   f010008b <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");//mejorar mensaje?
f010118b:	83 38 00             	cmpl   $0x0,(%eax)
f010118e:	74 17                	je     f01011a7 <page_free+0x43>
f0101190:	83 ec 04             	sub    $0x4,%esp
f0101193:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0101198:	68 56 01 00 00       	push   $0x156
f010119d:	68 d3 45 10 f0       	push   $0xf01045d3
f01011a2:	e8 e4 ee ff ff       	call   f010008b <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f01011a7:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f01011ad:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f01011af:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f01011b4:	c9                   	leave  
f01011b5:	c3                   	ret    

f01011b6 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f01011b6:	55                   	push   %ebp
f01011b7:	89 e5                	mov    %esp,%ebp
f01011b9:	57                   	push   %edi
f01011ba:	56                   	push   %esi
f01011bb:	53                   	push   %ebx
f01011bc:	83 ec 1c             	sub    $0x1c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011bf:	83 3d 4c 79 11 f0 00 	cmpl   $0x0,0xf011794c
f01011c6:	75 17                	jne    f01011df <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f01011c8:	83 ec 04             	sub    $0x4,%esp
f01011cb:	68 cd 46 10 f0       	push   $0xf01046cd
f01011d0:	68 66 02 00 00       	push   $0x266
f01011d5:	68 d3 45 10 f0       	push   $0xf01045d3
f01011da:	e8 ac ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011df:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01011e4:	be 00 00 00 00       	mov    $0x0,%esi
f01011e9:	eb 05                	jmp    f01011f0 <check_page_alloc+0x3a>
		++nfree;
f01011eb:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011ee:	8b 00                	mov    (%eax),%eax
f01011f0:	85 c0                	test   %eax,%eax
f01011f2:	75 f7                	jne    f01011eb <check_page_alloc+0x35>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011f4:	83 ec 0c             	sub    $0xc,%esp
f01011f7:	6a 00                	push   $0x0
f01011f9:	e8 21 ff ff ff       	call   f010111f <page_alloc>
f01011fe:	89 c7                	mov    %eax,%edi
f0101200:	83 c4 10             	add    $0x10,%esp
f0101203:	85 c0                	test   %eax,%eax
f0101205:	75 19                	jne    f0101220 <check_page_alloc+0x6a>
f0101207:	68 e8 46 10 f0       	push   $0xf01046e8
f010120c:	68 ed 45 10 f0       	push   $0xf01045ed
f0101211:	68 6e 02 00 00       	push   $0x26e
f0101216:	68 d3 45 10 f0       	push   $0xf01045d3
f010121b:	e8 6b ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101220:	83 ec 0c             	sub    $0xc,%esp
f0101223:	6a 00                	push   $0x0
f0101225:	e8 f5 fe ff ff       	call   f010111f <page_alloc>
f010122a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010122d:	83 c4 10             	add    $0x10,%esp
f0101230:	85 c0                	test   %eax,%eax
f0101232:	75 19                	jne    f010124d <check_page_alloc+0x97>
f0101234:	68 fe 46 10 f0       	push   $0xf01046fe
f0101239:	68 ed 45 10 f0       	push   $0xf01045ed
f010123e:	68 6f 02 00 00       	push   $0x26f
f0101243:	68 d3 45 10 f0       	push   $0xf01045d3
f0101248:	e8 3e ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010124d:	83 ec 0c             	sub    $0xc,%esp
f0101250:	6a 00                	push   $0x0
f0101252:	e8 c8 fe ff ff       	call   f010111f <page_alloc>
f0101257:	89 c3                	mov    %eax,%ebx
f0101259:	83 c4 10             	add    $0x10,%esp
f010125c:	85 c0                	test   %eax,%eax
f010125e:	75 19                	jne    f0101279 <check_page_alloc+0xc3>
f0101260:	68 14 47 10 f0       	push   $0xf0104714
f0101265:	68 ed 45 10 f0       	push   $0xf01045ed
f010126a:	68 70 02 00 00       	push   $0x270
f010126f:	68 d3 45 10 f0       	push   $0xf01045d3
f0101274:	e8 12 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101279:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f010127c:	75 19                	jne    f0101297 <check_page_alloc+0xe1>
f010127e:	68 2a 47 10 f0       	push   $0xf010472a
f0101283:	68 ed 45 10 f0       	push   $0xf01045ed
f0101288:	68 73 02 00 00       	push   $0x273
f010128d:	68 d3 45 10 f0       	push   $0xf01045d3
f0101292:	e8 f4 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101297:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010129a:	74 04                	je     f01012a0 <check_page_alloc+0xea>
f010129c:	39 c7                	cmp    %eax,%edi
f010129e:	75 19                	jne    f01012b9 <check_page_alloc+0x103>
f01012a0:	68 0c 3f 10 f0       	push   $0xf0103f0c
f01012a5:	68 ed 45 10 f0       	push   $0xf01045ed
f01012aa:	68 74 02 00 00       	push   $0x274
f01012af:	68 d3 45 10 f0       	push   $0xf01045d3
f01012b4:	e8 d2 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01012b9:	89 f8                	mov    %edi,%eax
f01012bb:	e8 4f f7 ff ff       	call   f0100a0f <page2pa>
f01012c0:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f01012c6:	c1 e1 0c             	shl    $0xc,%ecx
f01012c9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01012cc:	39 c8                	cmp    %ecx,%eax
f01012ce:	72 19                	jb     f01012e9 <check_page_alloc+0x133>
f01012d0:	68 3c 47 10 f0       	push   $0xf010473c
f01012d5:	68 ed 45 10 f0       	push   $0xf01045ed
f01012da:	68 75 02 00 00       	push   $0x275
f01012df:	68 d3 45 10 f0       	push   $0xf01045d3
f01012e4:	e8 a2 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01012e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012ec:	e8 1e f7 ff ff       	call   f0100a0f <page2pa>
f01012f1:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01012f4:	77 19                	ja     f010130f <check_page_alloc+0x159>
f01012f6:	68 59 47 10 f0       	push   $0xf0104759
f01012fb:	68 ed 45 10 f0       	push   $0xf01045ed
f0101300:	68 76 02 00 00       	push   $0x276
f0101305:	68 d3 45 10 f0       	push   $0xf01045d3
f010130a:	e8 7c ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010130f:	89 d8                	mov    %ebx,%eax
f0101311:	e8 f9 f6 ff ff       	call   f0100a0f <page2pa>
f0101316:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0101319:	77 19                	ja     f0101334 <check_page_alloc+0x17e>
f010131b:	68 76 47 10 f0       	push   $0xf0104776
f0101320:	68 ed 45 10 f0       	push   $0xf01045ed
f0101325:	68 77 02 00 00       	push   $0x277
f010132a:	68 d3 45 10 f0       	push   $0xf01045d3
f010132f:	e8 57 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101334:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101339:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f010133c:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101343:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101346:	83 ec 0c             	sub    $0xc,%esp
f0101349:	6a 00                	push   $0x0
f010134b:	e8 cf fd ff ff       	call   f010111f <page_alloc>
f0101350:	83 c4 10             	add    $0x10,%esp
f0101353:	85 c0                	test   %eax,%eax
f0101355:	74 19                	je     f0101370 <check_page_alloc+0x1ba>
f0101357:	68 93 47 10 f0       	push   $0xf0104793
f010135c:	68 ed 45 10 f0       	push   $0xf01045ed
f0101361:	68 7e 02 00 00       	push   $0x27e
f0101366:	68 d3 45 10 f0       	push   $0xf01045d3
f010136b:	e8 1b ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101370:	83 ec 0c             	sub    $0xc,%esp
f0101373:	57                   	push   %edi
f0101374:	e8 eb fd ff ff       	call   f0101164 <page_free>
	page_free(pp1);
f0101379:	83 c4 04             	add    $0x4,%esp
f010137c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010137f:	e8 e0 fd ff ff       	call   f0101164 <page_free>
	page_free(pp2);
f0101384:	89 1c 24             	mov    %ebx,(%esp)
f0101387:	e8 d8 fd ff ff       	call   f0101164 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010138c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101393:	e8 87 fd ff ff       	call   f010111f <page_alloc>
f0101398:	89 c3                	mov    %eax,%ebx
f010139a:	83 c4 10             	add    $0x10,%esp
f010139d:	85 c0                	test   %eax,%eax
f010139f:	75 19                	jne    f01013ba <check_page_alloc+0x204>
f01013a1:	68 e8 46 10 f0       	push   $0xf01046e8
f01013a6:	68 ed 45 10 f0       	push   $0xf01045ed
f01013ab:	68 85 02 00 00       	push   $0x285
f01013b0:	68 d3 45 10 f0       	push   $0xf01045d3
f01013b5:	e8 d1 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013ba:	83 ec 0c             	sub    $0xc,%esp
f01013bd:	6a 00                	push   $0x0
f01013bf:	e8 5b fd ff ff       	call   f010111f <page_alloc>
f01013c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013c7:	83 c4 10             	add    $0x10,%esp
f01013ca:	85 c0                	test   %eax,%eax
f01013cc:	75 19                	jne    f01013e7 <check_page_alloc+0x231>
f01013ce:	68 fe 46 10 f0       	push   $0xf01046fe
f01013d3:	68 ed 45 10 f0       	push   $0xf01045ed
f01013d8:	68 86 02 00 00       	push   $0x286
f01013dd:	68 d3 45 10 f0       	push   $0xf01045d3
f01013e2:	e8 a4 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013e7:	83 ec 0c             	sub    $0xc,%esp
f01013ea:	6a 00                	push   $0x0
f01013ec:	e8 2e fd ff ff       	call   f010111f <page_alloc>
f01013f1:	89 c7                	mov    %eax,%edi
f01013f3:	83 c4 10             	add    $0x10,%esp
f01013f6:	85 c0                	test   %eax,%eax
f01013f8:	75 19                	jne    f0101413 <check_page_alloc+0x25d>
f01013fa:	68 14 47 10 f0       	push   $0xf0104714
f01013ff:	68 ed 45 10 f0       	push   $0xf01045ed
f0101404:	68 87 02 00 00       	push   $0x287
f0101409:	68 d3 45 10 f0       	push   $0xf01045d3
f010140e:	e8 78 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101413:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101416:	75 19                	jne    f0101431 <check_page_alloc+0x27b>
f0101418:	68 2a 47 10 f0       	push   $0xf010472a
f010141d:	68 ed 45 10 f0       	push   $0xf01045ed
f0101422:	68 89 02 00 00       	push   $0x289
f0101427:	68 d3 45 10 f0       	push   $0xf01045d3
f010142c:	e8 5a ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101431:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101434:	74 04                	je     f010143a <check_page_alloc+0x284>
f0101436:	39 c3                	cmp    %eax,%ebx
f0101438:	75 19                	jne    f0101453 <check_page_alloc+0x29d>
f010143a:	68 0c 3f 10 f0       	push   $0xf0103f0c
f010143f:	68 ed 45 10 f0       	push   $0xf01045ed
f0101444:	68 8a 02 00 00       	push   $0x28a
f0101449:	68 d3 45 10 f0       	push   $0xf01045d3
f010144e:	e8 38 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101453:	83 ec 0c             	sub    $0xc,%esp
f0101456:	6a 00                	push   $0x0
f0101458:	e8 c2 fc ff ff       	call   f010111f <page_alloc>
f010145d:	83 c4 10             	add    $0x10,%esp
f0101460:	85 c0                	test   %eax,%eax
f0101462:	74 19                	je     f010147d <check_page_alloc+0x2c7>
f0101464:	68 93 47 10 f0       	push   $0xf0104793
f0101469:	68 ed 45 10 f0       	push   $0xf01045ed
f010146e:	68 8b 02 00 00       	push   $0x28b
f0101473:	68 d3 45 10 f0       	push   $0xf01045d3
f0101478:	e8 0e ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010147d:	89 d8                	mov    %ebx,%eax
f010147f:	e8 c1 f6 ff ff       	call   f0100b45 <page2kva>
f0101484:	83 ec 04             	sub    $0x4,%esp
f0101487:	68 00 10 00 00       	push   $0x1000
f010148c:	6a 01                	push   $0x1
f010148e:	50                   	push   %eax
f010148f:	e8 fb 1d 00 00       	call   f010328f <memset>
	page_free(pp0);
f0101494:	89 1c 24             	mov    %ebx,(%esp)
f0101497:	e8 c8 fc ff ff       	call   f0101164 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010149c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014a3:	e8 77 fc ff ff       	call   f010111f <page_alloc>
f01014a8:	83 c4 10             	add    $0x10,%esp
f01014ab:	85 c0                	test   %eax,%eax
f01014ad:	75 19                	jne    f01014c8 <check_page_alloc+0x312>
f01014af:	68 a2 47 10 f0       	push   $0xf01047a2
f01014b4:	68 ed 45 10 f0       	push   $0xf01045ed
f01014b9:	68 90 02 00 00       	push   $0x290
f01014be:	68 d3 45 10 f0       	push   $0xf01045d3
f01014c3:	e8 c3 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014c8:	39 c3                	cmp    %eax,%ebx
f01014ca:	74 19                	je     f01014e5 <check_page_alloc+0x32f>
f01014cc:	68 c0 47 10 f0       	push   $0xf01047c0
f01014d1:	68 ed 45 10 f0       	push   $0xf01045ed
f01014d6:	68 91 02 00 00       	push   $0x291
f01014db:	68 d3 45 10 f0       	push   $0xf01045d3
f01014e0:	e8 a6 eb ff ff       	call   f010008b <_panic>
	c = page2kva(pp);
f01014e5:	89 d8                	mov    %ebx,%eax
f01014e7:	e8 59 f6 ff ff       	call   f0100b45 <page2kva>
f01014ec:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014f2:	80 38 00             	cmpb   $0x0,(%eax)
f01014f5:	74 19                	je     f0101510 <check_page_alloc+0x35a>
f01014f7:	68 d0 47 10 f0       	push   $0xf01047d0
f01014fc:	68 ed 45 10 f0       	push   $0xf01045ed
f0101501:	68 94 02 00 00       	push   $0x294
f0101506:	68 d3 45 10 f0       	push   $0xf01045d3
f010150b:	e8 7b eb ff ff       	call   f010008b <_panic>
f0101510:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101513:	39 d0                	cmp    %edx,%eax
f0101515:	75 db                	jne    f01014f2 <check_page_alloc+0x33c>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101517:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010151a:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f010151f:	83 ec 0c             	sub    $0xc,%esp
f0101522:	53                   	push   %ebx
f0101523:	e8 3c fc ff ff       	call   f0101164 <page_free>
	page_free(pp1);
f0101528:	83 c4 04             	add    $0x4,%esp
f010152b:	ff 75 e4             	pushl  -0x1c(%ebp)
f010152e:	e8 31 fc ff ff       	call   f0101164 <page_free>
	page_free(pp2);
f0101533:	89 3c 24             	mov    %edi,(%esp)
f0101536:	e8 29 fc ff ff       	call   f0101164 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010153b:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101540:	83 c4 10             	add    $0x10,%esp
f0101543:	eb 05                	jmp    f010154a <check_page_alloc+0x394>
		--nfree;
f0101545:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101548:	8b 00                	mov    (%eax),%eax
f010154a:	85 c0                	test   %eax,%eax
f010154c:	75 f7                	jne    f0101545 <check_page_alloc+0x38f>
		--nfree;
	assert(nfree == 0);
f010154e:	85 f6                	test   %esi,%esi
f0101550:	74 19                	je     f010156b <check_page_alloc+0x3b5>
f0101552:	68 da 47 10 f0       	push   $0xf01047da
f0101557:	68 ed 45 10 f0       	push   $0xf01045ed
f010155c:	68 a1 02 00 00       	push   $0x2a1
f0101561:	68 d3 45 10 f0       	push   $0xf01045d3
f0101566:	e8 20 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010156b:	83 ec 0c             	sub    $0xc,%esp
f010156e:	68 2c 3f 10 f0       	push   $0xf0103f2c
f0101573:	e8 73 12 00 00       	call   f01027eb <cprintf>
}
f0101578:	83 c4 10             	add    $0x10,%esp
f010157b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010157e:	5b                   	pop    %ebx
f010157f:	5e                   	pop    %esi
f0101580:	5f                   	pop    %edi
f0101581:	5d                   	pop    %ebp
f0101582:	c3                   	ret    

f0101583 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101583:	55                   	push   %ebp
f0101584:	89 e5                	mov    %esp,%ebp
f0101586:	83 ec 08             	sub    $0x8,%esp
f0101589:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010158c:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101590:	83 e8 01             	sub    $0x1,%eax
f0101593:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101597:	66 85 c0             	test   %ax,%ax
f010159a:	75 0c                	jne    f01015a8 <page_decref+0x25>
		page_free(pp);
f010159c:	83 ec 0c             	sub    $0xc,%esp
f010159f:	52                   	push   %edx
f01015a0:	e8 bf fb ff ff       	call   f0101164 <page_free>
f01015a5:	83 c4 10             	add    $0x10,%esp
}
f01015a8:	c9                   	leave  
f01015a9:	c3                   	ret    

f01015aa <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01015aa:	55                   	push   %ebp
f01015ab:	89 e5                	mov    %esp,%ebp
f01015ad:	56                   	push   %esi
f01015ae:	53                   	push   %ebx
f01015af:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uint32_t* aux =(uint32_t*) pgdir;	
	physaddr_t* ptdir = (physaddr_t*) aux[PDX(va)]; //ojo que esto es P.Addr. !!
f01015b2:	89 da                	mov    %ebx,%edx
f01015b4:	c1 ea 16             	shr    $0x16,%edx
f01015b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ba:	8b 34 90             	mov    (%eax,%edx,4),%esi

	if (ptdir == NULL){
f01015bd:	85 f6                	test   %esi,%esi
f01015bf:	75 7a                	jne    f010163b <pgdir_walk+0x91>
		cprintf("\nse entro a walk y ptdir es NULL\n");//DEBUG2
f01015c1:	83 ec 0c             	sub    $0xc,%esp
f01015c4:	68 4c 3f 10 f0       	push   $0xf0103f4c
f01015c9:	e8 1d 12 00 00       	call   f01027eb <cprintf>
		if (!create) return NULL;
f01015ce:	83 c4 10             	add    $0x10,%esp
f01015d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01015d6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01015da:	0f 84 8e 00 00 00    	je     f010166e <pgdir_walk+0xc4>
		struct PageInfo *page = page_alloc(0);
f01015e0:	83 ec 0c             	sub    $0xc,%esp
f01015e3:	6a 00                	push   $0x0
f01015e5:	e8 35 fb ff ff       	call   f010111f <page_alloc>
f01015ea:	89 c3                	mov    %eax,%ebx
		if (page == NULL) return NULL;
f01015ec:	83 c4 10             	add    $0x10,%esp
f01015ef:	85 c0                	test   %eax,%eax
f01015f1:	74 76                	je     f0101669 <pgdir_walk+0xbf>
		cprintf("y ademas se pudo hacer un page_alloc\n");//DEBUG2
f01015f3:	83 ec 0c             	sub    $0xc,%esp
f01015f6:	68 70 3f 10 f0       	push   $0xf0103f70
f01015fb:	e8 eb 11 00 00       	call   f01027eb <cprintf>
		page->pp_ref++;
f0101600:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
		ptdir = (physaddr_t *) page2pa(page);
f0101605:	89 d8                	mov    %ebx,%eax
f0101607:	e8 03 f4 ff ff       	call   f0100a0f <page2pa>
f010160c:	89 c6                	mov    %eax,%esi
		memset(page2kva(page),0,PGSIZE);//limpiar pagina
f010160e:	89 d8                	mov    %ebx,%eax
f0101610:	e8 30 f5 ff ff       	call   f0100b45 <page2kva>
f0101615:	83 c4 0c             	add    $0xc,%esp
f0101618:	68 00 10 00 00       	push   $0x1000
f010161d:	6a 00                	push   $0x0
f010161f:	50                   	push   %eax
f0101620:	e8 6a 1c 00 00       	call   f010328f <memset>
		return (pte_t*) KADDR((physaddr_t) ptdir);
f0101625:	89 f1                	mov    %esi,%ecx
f0101627:	ba 8c 01 00 00       	mov    $0x18c,%edx
f010162c:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
f0101631:	e8 e3 f4 ff ff       	call   f0100b19 <_kaddr>
f0101636:	83 c4 10             	add    $0x10,%esp
f0101639:	eb 33                	jmp    f010166e <pgdir_walk+0xc4>
	}
	cprintf("\nse entro a walk y ptdir es %p\n",ptdir);//DEBUG2
f010163b:	83 ec 08             	sub    $0x8,%esp
f010163e:	56                   	push   %esi
f010163f:	68 98 3f 10 f0       	push   $0xf0103f98
f0101644:	e8 a2 11 00 00       	call   f01027eb <cprintf>
	aux = (uint32_t*) ptdir;	//hago esto porque se enoja el compilador, y el casteo adentro deja..
								//..horrible el codigo
	physaddr_t pte = (physaddr_t) aux[PTX(va)];  //misma atencion, esto tmb es P.Addr.
f0101649:	c1 eb 0c             	shr    $0xc,%ebx
f010164c:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
	return (pte_t*) KADDR(pte);//esto se pide?
f0101652:	8b 0c 9e             	mov    (%esi,%ebx,4),%ecx
f0101655:	ba 92 01 00 00       	mov    $0x192,%edx
f010165a:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
f010165f:	e8 b5 f4 ff ff       	call   f0100b19 <_kaddr>
f0101664:	83 c4 10             	add    $0x10,%esp
f0101667:	eb 05                	jmp    f010166e <pgdir_walk+0xc4>

	if (ptdir == NULL){
		cprintf("\nse entro a walk y ptdir es NULL\n");//DEBUG2
		if (!create) return NULL;
		struct PageInfo *page = page_alloc(0);
		if (page == NULL) return NULL;
f0101669:	b8 00 00 00 00       	mov    $0x0,%eax
	cprintf("\nse entro a walk y ptdir es %p\n",ptdir);//DEBUG2
	aux = (uint32_t*) ptdir;	//hago esto porque se enoja el compilador, y el casteo adentro deja..
								//..horrible el codigo
	physaddr_t pte = (physaddr_t) aux[PTX(va)];  //misma atencion, esto tmb es P.Addr.
	return (pte_t*) KADDR(pte);//esto se pide?
}
f010166e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101671:	5b                   	pop    %ebx
f0101672:	5e                   	pop    %esi
f0101673:	5d                   	pop    %ebp
f0101674:	c3                   	ret    

f0101675 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101675:	55                   	push   %ebp
f0101676:	89 e5                	mov    %esp,%ebp
f0101678:	53                   	push   %ebx
f0101679:	83 ec 08             	sub    $0x8,%esp
f010167c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *page_entry = pgdir_walk(pgdir, va, false);	//Busco la PTE
f010167f:	6a 00                	push   $0x0
f0101681:	53                   	push   %ebx
f0101682:	ff 75 08             	pushl  0x8(%ebp)
f0101685:	e8 20 ff ff ff       	call   f01015aa <pgdir_walk>
	if (page_entry == NULL){
f010168a:	83 c4 10             	add    $0x10,%esp
f010168d:	85 c0                	test   %eax,%eax
f010168f:	74 31                	je     f01016c2 <page_lookup+0x4d>
		return NULL;
	}
	physaddr_t physical_page = PTE_ADDR(page_entry);	//consigo el addres
	physaddr_t physical_direction = physical_page | PGOFF(va);	//formo la direccion fisica conb lo anterir OR offset
	if (pte_store != NULL){
f0101691:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101695:	74 17                	je     f01016ae <page_lookup+0x39>
		cprintf("lookup con pte_store!=0, qcyo\n");//DEBUG2
f0101697:	83 ec 0c             	sub    $0xc,%esp
f010169a:	68 b8 3f 10 f0       	push   $0xf0103fb8
f010169f:	e8 47 11 00 00       	call   f01027eb <cprintf>
		return NULL; //No estoy seguro que hacer aca
f01016a4:	83 c4 10             	add    $0x10,%esp
f01016a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01016ac:	eb 19                	jmp    f01016c7 <page_lookup+0x52>
		//TODO corregir esto
	}
	return pa2page(physical_direction); 
f01016ae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01016b3:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
f01016b9:	09 d8                	or     %ebx,%eax
f01016bb:	e8 b5 f9 ff ff       	call   f0101075 <pa2page>
f01016c0:	eb 05                	jmp    f01016c7 <page_lookup+0x52>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *page_entry = pgdir_walk(pgdir, va, false);	//Busco la PTE
	if (page_entry == NULL){
		return NULL;
f01016c2:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("lookup con pte_store!=0, qcyo\n");//DEBUG2
		return NULL; //No estoy seguro que hacer aca
		//TODO corregir esto
	}
	return pa2page(physical_direction); 
}	
f01016c7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01016ca:	c9                   	leave  
f01016cb:	c3                   	ret    

f01016cc <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01016cc:	55                   	push   %ebp
f01016cd:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f01016cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016d2:	e8 18 f3 ff ff       	call   f01009ef <invlpg>
}
f01016d7:	5d                   	pop    %ebp
f01016d8:	c3                   	ret    

f01016d9 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01016d9:	55                   	push   %ebp
f01016da:	89 e5                	mov    %esp,%ebp
f01016dc:	57                   	push   %edi
f01016dd:	56                   	push   %esi
f01016de:	53                   	push   %ebx
f01016df:	83 ec 10             	sub    $0x10,%esp
f01016e2:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016e5:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *page_entry = pgdir_walk(pgdir,va,false);
f01016e8:	6a 00                	push   $0x0
f01016ea:	56                   	push   %esi
f01016eb:	53                   	push   %ebx
f01016ec:	e8 b9 fe ff ff       	call   f01015aa <pgdir_walk>
	if(page_entry == NULL){
f01016f1:	83 c4 10             	add    $0x10,%esp
f01016f4:	85 c0                	test   %eax,%eax
f01016f6:	74 29                	je     f0101721 <page_remove+0x48>
f01016f8:	89 c7                	mov    %eax,%edi
		return;
	}
	struct PageInfo* page = page_lookup(pgdir, va, 0);
f01016fa:	83 ec 04             	sub    $0x4,%esp
f01016fd:	6a 00                	push   $0x0
f01016ff:	56                   	push   %esi
f0101700:	53                   	push   %ebx
f0101701:	e8 6f ff ff ff       	call   f0101675 <page_lookup>
	page_decref(page);
f0101706:	89 04 24             	mov    %eax,(%esp)
f0101709:	e8 75 fe ff ff       	call   f0101583 <page_decref>
	tlb_invalidate(pgdir,va);
f010170e:	83 c4 08             	add    $0x8,%esp
f0101711:	56                   	push   %esi
f0101712:	53                   	push   %ebx
f0101713:	e8 b4 ff ff ff       	call   f01016cc <tlb_invalidate>
	*page_entry = 0x0;
f0101718:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
f010171e:	83 c4 10             	add    $0x10,%esp

}
f0101721:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101724:	5b                   	pop    %ebx
f0101725:	5e                   	pop    %esi
f0101726:	5f                   	pop    %edi
f0101727:	5d                   	pop    %ebp
f0101728:	c3                   	ret    

f0101729 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101729:	55                   	push   %ebp
f010172a:	89 e5                	mov    %esp,%ebp
f010172c:	57                   	push   %edi
f010172d:	56                   	push   %esi
f010172e:	53                   	push   %ebx
f010172f:	83 ec 0c             	sub    $0xc,%esp
f0101732:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	physaddr_t page_PA = page2pa(pp);
f0101735:	89 f0                	mov    %esi,%eax
f0101737:	e8 d3 f2 ff ff       	call   f0100a0f <page2pa>
f010173c:	89 c7                	mov    %eax,%edi
	pte_t *page_entry = pgdir_walk(pgdir, va, true);
f010173e:	83 ec 04             	sub    $0x4,%esp
f0101741:	6a 01                	push   $0x1
f0101743:	ff 75 10             	pushl  0x10(%ebp)
f0101746:	ff 75 08             	pushl  0x8(%ebp)
f0101749:	e8 5c fe ff ff       	call   f01015aa <pgdir_walk>
	if (page_entry == NULL){
f010174e:	83 c4 10             	add    $0x10,%esp
f0101751:	85 c0                	test   %eax,%eax
f0101753:	74 46                	je     f010179b <page_insert+0x72>
f0101755:	89 c3                	mov    %eax,%ebx
		return -E_NO_MEM;	//DEBUG2: esto parece andar bien
	}
	if (PTE_ADDR(page_entry) != 0x0){
f0101757:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010175c:	74 1f                	je     f010177d <page_insert+0x54>
		cprintf("En insert la PTE_ADDR(page_entry) es %p\n",PTE_ADDR(page_entry));//DEBUG2
f010175e:	83 ec 08             	sub    $0x8,%esp
f0101761:	50                   	push   %eax
f0101762:	68 d8 3f 10 f0       	push   $0xf0103fd8
f0101767:	e8 7f 10 00 00       	call   f01027eb <cprintf>
		page_remove(pgdir,va);
f010176c:	83 c4 08             	add    $0x8,%esp
f010176f:	ff 75 10             	pushl  0x10(%ebp)
f0101772:	ff 75 08             	pushl  0x8(%ebp)
f0101775:	e8 5f ff ff ff       	call   f01016d9 <page_remove>
f010177a:	83 c4 10             	add    $0x10,%esp
	}
	*page_entry = (page_PA & ~0xFFF) | (PTE_P|perm);		// page_PA OR ~0xFFF me da los 20bits mas altos. 						//DEBUG2: el & no es lo mismo que la macro PTE_ADDR?
f010177d:	89 fa                	mov    %edi,%edx
f010177f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101785:	8b 45 14             	mov    0x14(%ebp),%eax
f0101788:	83 c8 01             	or     $0x1,%eax
f010178b:	09 d0                	or     %edx,%eax
f010178d:	89 03                	mov    %eax,(%ebx)
															//El otro OR me genera los permisos.
							 								//El OR entre ambos me deja seteado el PTE.
	pp->pp_ref++;
f010178f:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f0101794:	b8 00 00 00 00       	mov    $0x0,%eax
f0101799:	eb 05                	jmp    f01017a0 <page_insert+0x77>
{
	// Fill this function in
	physaddr_t page_PA = page2pa(pp);
	pte_t *page_entry = pgdir_walk(pgdir, va, true);
	if (page_entry == NULL){
		return -E_NO_MEM;	//DEBUG2: esto parece andar bien
f010179b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*page_entry = (page_PA & ~0xFFF) | (PTE_P|perm);		// page_PA OR ~0xFFF me da los 20bits mas altos. 						//DEBUG2: el & no es lo mismo que la macro PTE_ADDR?
															//El otro OR me genera los permisos.
							 								//El OR entre ambos me deja seteado el PTE.
	pp->pp_ref++;
	return 0;
}
f01017a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01017a3:	5b                   	pop    %ebx
f01017a4:	5e                   	pop    %esi
f01017a5:	5f                   	pop    %edi
f01017a6:	5d                   	pop    %ebp
f01017a7:	c3                   	ret    

f01017a8 <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f01017a8:	55                   	push   %ebp
f01017a9:	89 e5                	mov    %esp,%ebp
f01017ab:	57                   	push   %edi
f01017ac:	56                   	push   %esi
f01017ad:	53                   	push   %ebx
f01017ae:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017b1:	6a 00                	push   $0x0
f01017b3:	e8 67 f9 ff ff       	call   f010111f <page_alloc>
f01017b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017bb:	83 c4 10             	add    $0x10,%esp
f01017be:	85 c0                	test   %eax,%eax
f01017c0:	75 19                	jne    f01017db <check_page+0x33>
f01017c2:	68 e8 46 10 f0       	push   $0xf01046e8
f01017c7:	68 ed 45 10 f0       	push   $0xf01045ed
f01017cc:	68 fc 02 00 00       	push   $0x2fc
f01017d1:	68 d3 45 10 f0       	push   $0xf01045d3
f01017d6:	e8 b0 e8 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01017db:	83 ec 0c             	sub    $0xc,%esp
f01017de:	6a 00                	push   $0x0
f01017e0:	e8 3a f9 ff ff       	call   f010111f <page_alloc>
f01017e5:	89 c6                	mov    %eax,%esi
f01017e7:	83 c4 10             	add    $0x10,%esp
f01017ea:	85 c0                	test   %eax,%eax
f01017ec:	75 19                	jne    f0101807 <check_page+0x5f>
f01017ee:	68 fe 46 10 f0       	push   $0xf01046fe
f01017f3:	68 ed 45 10 f0       	push   $0xf01045ed
f01017f8:	68 fd 02 00 00       	push   $0x2fd
f01017fd:	68 d3 45 10 f0       	push   $0xf01045d3
f0101802:	e8 84 e8 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101807:	83 ec 0c             	sub    $0xc,%esp
f010180a:	6a 00                	push   $0x0
f010180c:	e8 0e f9 ff ff       	call   f010111f <page_alloc>
f0101811:	89 c3                	mov    %eax,%ebx
f0101813:	83 c4 10             	add    $0x10,%esp
f0101816:	85 c0                	test   %eax,%eax
f0101818:	75 19                	jne    f0101833 <check_page+0x8b>
f010181a:	68 14 47 10 f0       	push   $0xf0104714
f010181f:	68 ed 45 10 f0       	push   $0xf01045ed
f0101824:	68 fe 02 00 00       	push   $0x2fe
f0101829:	68 d3 45 10 f0       	push   $0xf01045d3
f010182e:	e8 58 e8 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101833:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0101836:	75 19                	jne    f0101851 <check_page+0xa9>
f0101838:	68 2a 47 10 f0       	push   $0xf010472a
f010183d:	68 ed 45 10 f0       	push   $0xf01045ed
f0101842:	68 01 03 00 00       	push   $0x301
f0101847:	68 d3 45 10 f0       	push   $0xf01045d3
f010184c:	e8 3a e8 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101851:	39 c6                	cmp    %eax,%esi
f0101853:	74 05                	je     f010185a <check_page+0xb2>
f0101855:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101858:	75 19                	jne    f0101873 <check_page+0xcb>
f010185a:	68 0c 3f 10 f0       	push   $0xf0103f0c
f010185f:	68 ed 45 10 f0       	push   $0xf01045ed
f0101864:	68 02 03 00 00       	push   $0x302
f0101869:	68 d3 45 10 f0       	push   $0xf01045d3
f010186e:	e8 18 e8 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101873:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101878:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010187b:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101882:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101885:	83 ec 0c             	sub    $0xc,%esp
f0101888:	6a 00                	push   $0x0
f010188a:	e8 90 f8 ff ff       	call   f010111f <page_alloc>
f010188f:	83 c4 10             	add    $0x10,%esp
f0101892:	85 c0                	test   %eax,%eax
f0101894:	74 19                	je     f01018af <check_page+0x107>
f0101896:	68 93 47 10 f0       	push   $0xf0104793
f010189b:	68 ed 45 10 f0       	push   $0xf01045ed
f01018a0:	68 09 03 00 00       	push   $0x309
f01018a5:	68 d3 45 10 f0       	push   $0xf01045d3
f01018aa:	e8 dc e7 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01018af:	83 ec 04             	sub    $0x4,%esp
f01018b2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01018b5:	50                   	push   %eax
f01018b6:	6a 00                	push   $0x0
f01018b8:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018be:	e8 b2 fd ff ff       	call   f0101675 <page_lookup>
f01018c3:	83 c4 10             	add    $0x10,%esp
f01018c6:	85 c0                	test   %eax,%eax
f01018c8:	74 19                	je     f01018e3 <check_page+0x13b>
f01018ca:	68 04 40 10 f0       	push   $0xf0104004
f01018cf:	68 ed 45 10 f0       	push   $0xf01045ed
f01018d4:	68 0c 03 00 00       	push   $0x30c
f01018d9:	68 d3 45 10 f0       	push   $0xf01045d3
f01018de:	e8 a8 e7 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01018e3:	6a 02                	push   $0x2
f01018e5:	6a 00                	push   $0x0
f01018e7:	56                   	push   %esi
f01018e8:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018ee:	e8 36 fe ff ff       	call   f0101729 <page_insert>
f01018f3:	83 c4 10             	add    $0x10,%esp
f01018f6:	85 c0                	test   %eax,%eax
f01018f8:	78 19                	js     f0101913 <check_page+0x16b>
f01018fa:	68 3c 40 10 f0       	push   $0xf010403c
f01018ff:	68 ed 45 10 f0       	push   $0xf01045ed
f0101904:	68 0f 03 00 00       	push   $0x30f
f0101909:	68 d3 45 10 f0       	push   $0xf01045d3
f010190e:	e8 78 e7 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101913:	83 ec 0c             	sub    $0xc,%esp
f0101916:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101919:	e8 46 f8 ff ff       	call   f0101164 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010191e:	6a 02                	push   $0x2
f0101920:	6a 00                	push   $0x0
f0101922:	56                   	push   %esi
f0101923:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101929:	e8 fb fd ff ff       	call   f0101729 <page_insert>
f010192e:	83 c4 20             	add    $0x20,%esp
f0101931:	85 c0                	test   %eax,%eax
f0101933:	74 19                	je     f010194e <check_page+0x1a6>
f0101935:	68 6c 40 10 f0       	push   $0xf010406c
f010193a:	68 ed 45 10 f0       	push   $0xf01045ed
f010193f:	68 13 03 00 00       	push   $0x313
f0101944:	68 d3 45 10 f0       	push   $0xf01045d3
f0101949:	e8 3d e7 ff ff       	call   f010008b <_panic>
	cprintf("page2pa(pp0) es %p\n",page2pa(pp0));//DEBUG2
f010194e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101951:	e8 b9 f0 ff ff       	call   f0100a0f <page2pa>
f0101956:	83 ec 08             	sub    $0x8,%esp
f0101959:	50                   	push   %eax
f010195a:	68 e5 47 10 f0       	push   $0xf01047e5
f010195f:	e8 87 0e 00 00       	call   f01027eb <cprintf>
	cprintf("pero PTE_ADDR(kern_pgdir[0]) es %p\n",PTE_ADDR(kern_pgdir[0]));//DEBUG2
f0101964:	83 c4 08             	add    $0x8,%esp
f0101967:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f010196c:	8b 00                	mov    (%eax),%eax
f010196e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101973:	50                   	push   %eax
f0101974:	68 9c 40 10 f0       	push   $0xf010409c
f0101979:	e8 6d 0e 00 00       	call   f01027eb <cprintf>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010197e:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101984:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101987:	e8 83 f0 ff ff       	call   f0100a0f <page2pa>
f010198c:	8b 17                	mov    (%edi),%edx
f010198e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101994:	83 c4 10             	add    $0x10,%esp
f0101997:	39 c2                	cmp    %eax,%edx
f0101999:	74 19                	je     f01019b4 <check_page+0x20c>
f010199b:	68 c0 40 10 f0       	push   $0xf01040c0
f01019a0:	68 ed 45 10 f0       	push   $0xf01045ed
f01019a5:	68 16 03 00 00       	push   $0x316
f01019aa:	68 d3 45 10 f0       	push   $0xf01045d3
f01019af:	e8 d7 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019b4:	ba 00 00 00 00       	mov    $0x0,%edx
f01019b9:	89 f8                	mov    %edi,%eax
f01019bb:	e8 a3 f1 ff ff       	call   f0100b63 <check_va2pa>
f01019c0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019c3:	89 f0                	mov    %esi,%eax
f01019c5:	e8 45 f0 ff ff       	call   f0100a0f <page2pa>
f01019ca:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01019cd:	74 19                	je     f01019e8 <check_page+0x240>
f01019cf:	68 e8 40 10 f0       	push   $0xf01040e8
f01019d4:	68 ed 45 10 f0       	push   $0xf01045ed
f01019d9:	68 17 03 00 00       	push   $0x317
f01019de:	68 d3 45 10 f0       	push   $0xf01045d3
f01019e3:	e8 a3 e6 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f01019e8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019ed:	74 19                	je     f0101a08 <check_page+0x260>
f01019ef:	68 f9 47 10 f0       	push   $0xf01047f9
f01019f4:	68 ed 45 10 f0       	push   $0xf01045ed
f01019f9:	68 18 03 00 00       	push   $0x318
f01019fe:	68 d3 45 10 f0       	push   $0xf01045d3
f0101a03:	e8 83 e6 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101a08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a0b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a10:	74 19                	je     f0101a2b <check_page+0x283>
f0101a12:	68 0a 48 10 f0       	push   $0xf010480a
f0101a17:	68 ed 45 10 f0       	push   $0xf01045ed
f0101a1c:	68 19 03 00 00       	push   $0x319
f0101a21:	68 d3 45 10 f0       	push   $0xf01045d3
f0101a26:	e8 60 e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a2b:	6a 02                	push   $0x2
f0101a2d:	68 00 10 00 00       	push   $0x1000
f0101a32:	53                   	push   %ebx
f0101a33:	57                   	push   %edi
f0101a34:	e8 f0 fc ff ff       	call   f0101729 <page_insert>
f0101a39:	83 c4 10             	add    $0x10,%esp
f0101a3c:	85 c0                	test   %eax,%eax
f0101a3e:	74 19                	je     f0101a59 <check_page+0x2b1>
f0101a40:	68 18 41 10 f0       	push   $0xf0104118
f0101a45:	68 ed 45 10 f0       	push   $0xf01045ed
f0101a4a:	68 1c 03 00 00       	push   $0x31c
f0101a4f:	68 d3 45 10 f0       	push   $0xf01045d3
f0101a54:	e8 32 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a59:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a5e:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101a63:	e8 fb f0 ff ff       	call   f0100b63 <check_va2pa>
f0101a68:	89 c7                	mov    %eax,%edi
f0101a6a:	89 d8                	mov    %ebx,%eax
f0101a6c:	e8 9e ef ff ff       	call   f0100a0f <page2pa>
f0101a71:	39 c7                	cmp    %eax,%edi
f0101a73:	74 19                	je     f0101a8e <check_page+0x2e6>
f0101a75:	68 54 41 10 f0       	push   $0xf0104154
f0101a7a:	68 ed 45 10 f0       	push   $0xf01045ed
f0101a7f:	68 1d 03 00 00       	push   $0x31d
f0101a84:	68 d3 45 10 f0       	push   $0xf01045d3
f0101a89:	e8 fd e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a8e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a93:	74 19                	je     f0101aae <check_page+0x306>
f0101a95:	68 1b 48 10 f0       	push   $0xf010481b
f0101a9a:	68 ed 45 10 f0       	push   $0xf01045ed
f0101a9f:	68 1e 03 00 00       	push   $0x31e
f0101aa4:	68 d3 45 10 f0       	push   $0xf01045d3
f0101aa9:	e8 dd e5 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101aae:	83 ec 0c             	sub    $0xc,%esp
f0101ab1:	6a 00                	push   $0x0
f0101ab3:	e8 67 f6 ff ff       	call   f010111f <page_alloc>
f0101ab8:	83 c4 10             	add    $0x10,%esp
f0101abb:	85 c0                	test   %eax,%eax
f0101abd:	74 19                	je     f0101ad8 <check_page+0x330>
f0101abf:	68 93 47 10 f0       	push   $0xf0104793
f0101ac4:	68 ed 45 10 f0       	push   $0xf01045ed
f0101ac9:	68 21 03 00 00       	push   $0x321
f0101ace:	68 d3 45 10 f0       	push   $0xf01045d3
f0101ad3:	e8 b3 e5 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad8:	6a 02                	push   $0x2
f0101ada:	68 00 10 00 00       	push   $0x1000
f0101adf:	53                   	push   %ebx
f0101ae0:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101ae6:	e8 3e fc ff ff       	call   f0101729 <page_insert>
f0101aeb:	83 c4 10             	add    $0x10,%esp
f0101aee:	85 c0                	test   %eax,%eax
f0101af0:	74 19                	je     f0101b0b <check_page+0x363>
f0101af2:	68 18 41 10 f0       	push   $0xf0104118
f0101af7:	68 ed 45 10 f0       	push   $0xf01045ed
f0101afc:	68 24 03 00 00       	push   $0x324
f0101b01:	68 d3 45 10 f0       	push   $0xf01045d3
f0101b06:	e8 80 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b0b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b10:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101b15:	e8 49 f0 ff ff       	call   f0100b63 <check_va2pa>
f0101b1a:	89 c7                	mov    %eax,%edi
f0101b1c:	89 d8                	mov    %ebx,%eax
f0101b1e:	e8 ec ee ff ff       	call   f0100a0f <page2pa>
f0101b23:	39 c7                	cmp    %eax,%edi
f0101b25:	74 19                	je     f0101b40 <check_page+0x398>
f0101b27:	68 54 41 10 f0       	push   $0xf0104154
f0101b2c:	68 ed 45 10 f0       	push   $0xf01045ed
f0101b31:	68 25 03 00 00       	push   $0x325
f0101b36:	68 d3 45 10 f0       	push   $0xf01045d3
f0101b3b:	e8 4b e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101b40:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b45:	74 19                	je     f0101b60 <check_page+0x3b8>
f0101b47:	68 1b 48 10 f0       	push   $0xf010481b
f0101b4c:	68 ed 45 10 f0       	push   $0xf01045ed
f0101b51:	68 26 03 00 00       	push   $0x326
f0101b56:	68 d3 45 10 f0       	push   $0xf01045d3
f0101b5b:	e8 2b e5 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b60:	83 ec 0c             	sub    $0xc,%esp
f0101b63:	6a 00                	push   $0x0
f0101b65:	e8 b5 f5 ff ff       	call   f010111f <page_alloc>
f0101b6a:	83 c4 10             	add    $0x10,%esp
f0101b6d:	85 c0                	test   %eax,%eax
f0101b6f:	74 19                	je     f0101b8a <check_page+0x3e2>
f0101b71:	68 93 47 10 f0       	push   $0xf0104793
f0101b76:	68 ed 45 10 f0       	push   $0xf01045ed
f0101b7b:	68 2a 03 00 00       	push   $0x32a
f0101b80:	68 d3 45 10 f0       	push   $0xf01045d3
f0101b85:	e8 01 e5 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b8a:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101b90:	8b 0f                	mov    (%edi),%ecx
f0101b92:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101b98:	ba 2d 03 00 00       	mov    $0x32d,%edx
f0101b9d:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
f0101ba2:	e8 72 ef ff ff       	call   f0100b19 <_kaddr>
f0101ba7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101baa:	83 ec 04             	sub    $0x4,%esp
f0101bad:	6a 00                	push   $0x0
f0101baf:	68 00 10 00 00       	push   $0x1000
f0101bb4:	57                   	push   %edi
f0101bb5:	e8 f0 f9 ff ff       	call   f01015aa <pgdir_walk>
f0101bba:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101bbd:	8d 51 04             	lea    0x4(%ecx),%edx
f0101bc0:	83 c4 10             	add    $0x10,%esp
f0101bc3:	39 d0                	cmp    %edx,%eax
f0101bc5:	74 19                	je     f0101be0 <check_page+0x438>
f0101bc7:	68 84 41 10 f0       	push   $0xf0104184
f0101bcc:	68 ed 45 10 f0       	push   $0xf01045ed
f0101bd1:	68 2e 03 00 00       	push   $0x32e
f0101bd6:	68 d3 45 10 f0       	push   $0xf01045d3
f0101bdb:	e8 ab e4 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101be0:	6a 06                	push   $0x6
f0101be2:	68 00 10 00 00       	push   $0x1000
f0101be7:	53                   	push   %ebx
f0101be8:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101bee:	e8 36 fb ff ff       	call   f0101729 <page_insert>
f0101bf3:	83 c4 10             	add    $0x10,%esp
f0101bf6:	85 c0                	test   %eax,%eax
f0101bf8:	74 19                	je     f0101c13 <check_page+0x46b>
f0101bfa:	68 c4 41 10 f0       	push   $0xf01041c4
f0101bff:	68 ed 45 10 f0       	push   $0xf01045ed
f0101c04:	68 31 03 00 00       	push   $0x331
f0101c09:	68 d3 45 10 f0       	push   $0xf01045d3
f0101c0e:	e8 78 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c13:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101c19:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c1e:	89 f8                	mov    %edi,%eax
f0101c20:	e8 3e ef ff ff       	call   f0100b63 <check_va2pa>
f0101c25:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c28:	89 d8                	mov    %ebx,%eax
f0101c2a:	e8 e0 ed ff ff       	call   f0100a0f <page2pa>
f0101c2f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101c32:	74 19                	je     f0101c4d <check_page+0x4a5>
f0101c34:	68 54 41 10 f0       	push   $0xf0104154
f0101c39:	68 ed 45 10 f0       	push   $0xf01045ed
f0101c3e:	68 32 03 00 00       	push   $0x332
f0101c43:	68 d3 45 10 f0       	push   $0xf01045d3
f0101c48:	e8 3e e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101c4d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c52:	74 19                	je     f0101c6d <check_page+0x4c5>
f0101c54:	68 1b 48 10 f0       	push   $0xf010481b
f0101c59:	68 ed 45 10 f0       	push   $0xf01045ed
f0101c5e:	68 33 03 00 00       	push   $0x333
f0101c63:	68 d3 45 10 f0       	push   $0xf01045d3
f0101c68:	e8 1e e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c6d:	83 ec 04             	sub    $0x4,%esp
f0101c70:	6a 00                	push   $0x0
f0101c72:	68 00 10 00 00       	push   $0x1000
f0101c77:	57                   	push   %edi
f0101c78:	e8 2d f9 ff ff       	call   f01015aa <pgdir_walk>
f0101c7d:	83 c4 10             	add    $0x10,%esp
f0101c80:	f6 00 04             	testb  $0x4,(%eax)
f0101c83:	75 19                	jne    f0101c9e <check_page+0x4f6>
f0101c85:	68 04 42 10 f0       	push   $0xf0104204
f0101c8a:	68 ed 45 10 f0       	push   $0xf01045ed
f0101c8f:	68 34 03 00 00       	push   $0x334
f0101c94:	68 d3 45 10 f0       	push   $0xf01045d3
f0101c99:	e8 ed e3 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c9e:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101ca3:	f6 00 04             	testb  $0x4,(%eax)
f0101ca6:	75 19                	jne    f0101cc1 <check_page+0x519>
f0101ca8:	68 2c 48 10 f0       	push   $0xf010482c
f0101cad:	68 ed 45 10 f0       	push   $0xf01045ed
f0101cb2:	68 35 03 00 00       	push   $0x335
f0101cb7:	68 d3 45 10 f0       	push   $0xf01045d3
f0101cbc:	e8 ca e3 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cc1:	6a 02                	push   $0x2
f0101cc3:	68 00 10 00 00       	push   $0x1000
f0101cc8:	53                   	push   %ebx
f0101cc9:	50                   	push   %eax
f0101cca:	e8 5a fa ff ff       	call   f0101729 <page_insert>
f0101ccf:	83 c4 10             	add    $0x10,%esp
f0101cd2:	85 c0                	test   %eax,%eax
f0101cd4:	74 19                	je     f0101cef <check_page+0x547>
f0101cd6:	68 18 41 10 f0       	push   $0xf0104118
f0101cdb:	68 ed 45 10 f0       	push   $0xf01045ed
f0101ce0:	68 38 03 00 00       	push   $0x338
f0101ce5:	68 d3 45 10 f0       	push   $0xf01045d3
f0101cea:	e8 9c e3 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101cef:	83 ec 04             	sub    $0x4,%esp
f0101cf2:	6a 00                	push   $0x0
f0101cf4:	68 00 10 00 00       	push   $0x1000
f0101cf9:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101cff:	e8 a6 f8 ff ff       	call   f01015aa <pgdir_walk>
f0101d04:	83 c4 10             	add    $0x10,%esp
f0101d07:	f6 00 02             	testb  $0x2,(%eax)
f0101d0a:	75 19                	jne    f0101d25 <check_page+0x57d>
f0101d0c:	68 38 42 10 f0       	push   $0xf0104238
f0101d11:	68 ed 45 10 f0       	push   $0xf01045ed
f0101d16:	68 39 03 00 00       	push   $0x339
f0101d1b:	68 d3 45 10 f0       	push   $0xf01045d3
f0101d20:	e8 66 e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d25:	83 ec 04             	sub    $0x4,%esp
f0101d28:	6a 00                	push   $0x0
f0101d2a:	68 00 10 00 00       	push   $0x1000
f0101d2f:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d35:	e8 70 f8 ff ff       	call   f01015aa <pgdir_walk>
f0101d3a:	83 c4 10             	add    $0x10,%esp
f0101d3d:	f6 00 04             	testb  $0x4,(%eax)
f0101d40:	74 19                	je     f0101d5b <check_page+0x5b3>
f0101d42:	68 6c 42 10 f0       	push   $0xf010426c
f0101d47:	68 ed 45 10 f0       	push   $0xf01045ed
f0101d4c:	68 3a 03 00 00       	push   $0x33a
f0101d51:	68 d3 45 10 f0       	push   $0xf01045d3
f0101d56:	e8 30 e3 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101d5b:	6a 02                	push   $0x2
f0101d5d:	68 00 00 40 00       	push   $0x400000
f0101d62:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101d65:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d6b:	e8 b9 f9 ff ff       	call   f0101729 <page_insert>
f0101d70:	83 c4 10             	add    $0x10,%esp
f0101d73:	85 c0                	test   %eax,%eax
f0101d75:	78 19                	js     f0101d90 <check_page+0x5e8>
f0101d77:	68 a4 42 10 f0       	push   $0xf01042a4
f0101d7c:	68 ed 45 10 f0       	push   $0xf01045ed
f0101d81:	68 3d 03 00 00       	push   $0x33d
f0101d86:	68 d3 45 10 f0       	push   $0xf01045d3
f0101d8b:	e8 fb e2 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d90:	6a 02                	push   $0x2
f0101d92:	68 00 10 00 00       	push   $0x1000
f0101d97:	56                   	push   %esi
f0101d98:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d9e:	e8 86 f9 ff ff       	call   f0101729 <page_insert>
f0101da3:	83 c4 10             	add    $0x10,%esp
f0101da6:	85 c0                	test   %eax,%eax
f0101da8:	74 19                	je     f0101dc3 <check_page+0x61b>
f0101daa:	68 dc 42 10 f0       	push   $0xf01042dc
f0101daf:	68 ed 45 10 f0       	push   $0xf01045ed
f0101db4:	68 40 03 00 00       	push   $0x340
f0101db9:	68 d3 45 10 f0       	push   $0xf01045d3
f0101dbe:	e8 c8 e2 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dc3:	83 ec 04             	sub    $0x4,%esp
f0101dc6:	6a 00                	push   $0x0
f0101dc8:	68 00 10 00 00       	push   $0x1000
f0101dcd:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101dd3:	e8 d2 f7 ff ff       	call   f01015aa <pgdir_walk>
f0101dd8:	83 c4 10             	add    $0x10,%esp
f0101ddb:	f6 00 04             	testb  $0x4,(%eax)
f0101dde:	74 19                	je     f0101df9 <check_page+0x651>
f0101de0:	68 6c 42 10 f0       	push   $0xf010426c
f0101de5:	68 ed 45 10 f0       	push   $0xf01045ed
f0101dea:	68 41 03 00 00       	push   $0x341
f0101def:	68 d3 45 10 f0       	push   $0xf01045d3
f0101df4:	e8 92 e2 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101df9:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101dff:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e04:	89 f8                	mov    %edi,%eax
f0101e06:	e8 58 ed ff ff       	call   f0100b63 <check_va2pa>
f0101e0b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101e0e:	89 f0                	mov    %esi,%eax
f0101e10:	e8 fa eb ff ff       	call   f0100a0f <page2pa>
f0101e15:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101e18:	74 19                	je     f0101e33 <check_page+0x68b>
f0101e1a:	68 18 43 10 f0       	push   $0xf0104318
f0101e1f:	68 ed 45 10 f0       	push   $0xf01045ed
f0101e24:	68 44 03 00 00       	push   $0x344
f0101e29:	68 d3 45 10 f0       	push   $0xf01045d3
f0101e2e:	e8 58 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e33:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e38:	89 f8                	mov    %edi,%eax
f0101e3a:	e8 24 ed ff ff       	call   f0100b63 <check_va2pa>
f0101e3f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101e42:	74 19                	je     f0101e5d <check_page+0x6b5>
f0101e44:	68 44 43 10 f0       	push   $0xf0104344
f0101e49:	68 ed 45 10 f0       	push   $0xf01045ed
f0101e4e:	68 45 03 00 00       	push   $0x345
f0101e53:	68 d3 45 10 f0       	push   $0xf01045d3
f0101e58:	e8 2e e2 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e5d:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101e62:	74 19                	je     f0101e7d <check_page+0x6d5>
f0101e64:	68 42 48 10 f0       	push   $0xf0104842
f0101e69:	68 ed 45 10 f0       	push   $0xf01045ed
f0101e6e:	68 47 03 00 00       	push   $0x347
f0101e73:	68 d3 45 10 f0       	push   $0xf01045d3
f0101e78:	e8 0e e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e7d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e82:	74 19                	je     f0101e9d <check_page+0x6f5>
f0101e84:	68 53 48 10 f0       	push   $0xf0104853
f0101e89:	68 ed 45 10 f0       	push   $0xf01045ed
f0101e8e:	68 48 03 00 00       	push   $0x348
f0101e93:	68 d3 45 10 f0       	push   $0xf01045d3
f0101e98:	e8 ee e1 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e9d:	83 ec 0c             	sub    $0xc,%esp
f0101ea0:	6a 00                	push   $0x0
f0101ea2:	e8 78 f2 ff ff       	call   f010111f <page_alloc>
f0101ea7:	83 c4 10             	add    $0x10,%esp
f0101eaa:	39 c3                	cmp    %eax,%ebx
f0101eac:	75 04                	jne    f0101eb2 <check_page+0x70a>
f0101eae:	85 c0                	test   %eax,%eax
f0101eb0:	75 19                	jne    f0101ecb <check_page+0x723>
f0101eb2:	68 74 43 10 f0       	push   $0xf0104374
f0101eb7:	68 ed 45 10 f0       	push   $0xf01045ed
f0101ebc:	68 4b 03 00 00       	push   $0x34b
f0101ec1:	68 d3 45 10 f0       	push   $0xf01045d3
f0101ec6:	e8 c0 e1 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101ecb:	83 ec 08             	sub    $0x8,%esp
f0101ece:	6a 00                	push   $0x0
f0101ed0:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101ed6:	e8 fe f7 ff ff       	call   f01016d9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101edb:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101ee1:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ee6:	89 f8                	mov    %edi,%eax
f0101ee8:	e8 76 ec ff ff       	call   f0100b63 <check_va2pa>
f0101eed:	83 c4 10             	add    $0x10,%esp
f0101ef0:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ef3:	74 19                	je     f0101f0e <check_page+0x766>
f0101ef5:	68 98 43 10 f0       	push   $0xf0104398
f0101efa:	68 ed 45 10 f0       	push   $0xf01045ed
f0101eff:	68 4f 03 00 00       	push   $0x34f
f0101f04:	68 d3 45 10 f0       	push   $0xf01045d3
f0101f09:	e8 7d e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f0e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f13:	89 f8                	mov    %edi,%eax
f0101f15:	e8 49 ec ff ff       	call   f0100b63 <check_va2pa>
f0101f1a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101f1d:	89 f0                	mov    %esi,%eax
f0101f1f:	e8 eb ea ff ff       	call   f0100a0f <page2pa>
f0101f24:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101f27:	74 19                	je     f0101f42 <check_page+0x79a>
f0101f29:	68 44 43 10 f0       	push   $0xf0104344
f0101f2e:	68 ed 45 10 f0       	push   $0xf01045ed
f0101f33:	68 50 03 00 00       	push   $0x350
f0101f38:	68 d3 45 10 f0       	push   $0xf01045d3
f0101f3d:	e8 49 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101f42:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f47:	74 19                	je     f0101f62 <check_page+0x7ba>
f0101f49:	68 f9 47 10 f0       	push   $0xf01047f9
f0101f4e:	68 ed 45 10 f0       	push   $0xf01045ed
f0101f53:	68 51 03 00 00       	push   $0x351
f0101f58:	68 d3 45 10 f0       	push   $0xf01045d3
f0101f5d:	e8 29 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101f62:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f67:	74 19                	je     f0101f82 <check_page+0x7da>
f0101f69:	68 53 48 10 f0       	push   $0xf0104853
f0101f6e:	68 ed 45 10 f0       	push   $0xf01045ed
f0101f73:	68 52 03 00 00       	push   $0x352
f0101f78:	68 d3 45 10 f0       	push   $0xf01045d3
f0101f7d:	e8 09 e1 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f82:	6a 00                	push   $0x0
f0101f84:	68 00 10 00 00       	push   $0x1000
f0101f89:	56                   	push   %esi
f0101f8a:	57                   	push   %edi
f0101f8b:	e8 99 f7 ff ff       	call   f0101729 <page_insert>
f0101f90:	83 c4 10             	add    $0x10,%esp
f0101f93:	85 c0                	test   %eax,%eax
f0101f95:	74 19                	je     f0101fb0 <check_page+0x808>
f0101f97:	68 bc 43 10 f0       	push   $0xf01043bc
f0101f9c:	68 ed 45 10 f0       	push   $0xf01045ed
f0101fa1:	68 55 03 00 00       	push   $0x355
f0101fa6:	68 d3 45 10 f0       	push   $0xf01045d3
f0101fab:	e8 db e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101fb0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fb5:	75 19                	jne    f0101fd0 <check_page+0x828>
f0101fb7:	68 64 48 10 f0       	push   $0xf0104864
f0101fbc:	68 ed 45 10 f0       	push   $0xf01045ed
f0101fc1:	68 56 03 00 00       	push   $0x356
f0101fc6:	68 d3 45 10 f0       	push   $0xf01045d3
f0101fcb:	e8 bb e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101fd0:	83 3e 00             	cmpl   $0x0,(%esi)
f0101fd3:	74 19                	je     f0101fee <check_page+0x846>
f0101fd5:	68 70 48 10 f0       	push   $0xf0104870
f0101fda:	68 ed 45 10 f0       	push   $0xf01045ed
f0101fdf:	68 57 03 00 00       	push   $0x357
f0101fe4:	68 d3 45 10 f0       	push   $0xf01045d3
f0101fe9:	e8 9d e0 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101fee:	83 ec 08             	sub    $0x8,%esp
f0101ff1:	68 00 10 00 00       	push   $0x1000
f0101ff6:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101ffc:	e8 d8 f6 ff ff       	call   f01016d9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102001:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0102007:	ba 00 00 00 00       	mov    $0x0,%edx
f010200c:	89 f8                	mov    %edi,%eax
f010200e:	e8 50 eb ff ff       	call   f0100b63 <check_va2pa>
f0102013:	83 c4 10             	add    $0x10,%esp
f0102016:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102019:	74 19                	je     f0102034 <check_page+0x88c>
f010201b:	68 98 43 10 f0       	push   $0xf0104398
f0102020:	68 ed 45 10 f0       	push   $0xf01045ed
f0102025:	68 5b 03 00 00       	push   $0x35b
f010202a:	68 d3 45 10 f0       	push   $0xf01045d3
f010202f:	e8 57 e0 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102034:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102039:	89 f8                	mov    %edi,%eax
f010203b:	e8 23 eb ff ff       	call   f0100b63 <check_va2pa>
f0102040:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102043:	74 19                	je     f010205e <check_page+0x8b6>
f0102045:	68 f4 43 10 f0       	push   $0xf01043f4
f010204a:	68 ed 45 10 f0       	push   $0xf01045ed
f010204f:	68 5c 03 00 00       	push   $0x35c
f0102054:	68 d3 45 10 f0       	push   $0xf01045d3
f0102059:	e8 2d e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010205e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102063:	74 19                	je     f010207e <check_page+0x8d6>
f0102065:	68 85 48 10 f0       	push   $0xf0104885
f010206a:	68 ed 45 10 f0       	push   $0xf01045ed
f010206f:	68 5d 03 00 00       	push   $0x35d
f0102074:	68 d3 45 10 f0       	push   $0xf01045d3
f0102079:	e8 0d e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f010207e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102083:	74 19                	je     f010209e <check_page+0x8f6>
f0102085:	68 53 48 10 f0       	push   $0xf0104853
f010208a:	68 ed 45 10 f0       	push   $0xf01045ed
f010208f:	68 5e 03 00 00       	push   $0x35e
f0102094:	68 d3 45 10 f0       	push   $0xf01045d3
f0102099:	e8 ed df ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010209e:	83 ec 0c             	sub    $0xc,%esp
f01020a1:	6a 00                	push   $0x0
f01020a3:	e8 77 f0 ff ff       	call   f010111f <page_alloc>
f01020a8:	83 c4 10             	add    $0x10,%esp
f01020ab:	39 c6                	cmp    %eax,%esi
f01020ad:	75 04                	jne    f01020b3 <check_page+0x90b>
f01020af:	85 c0                	test   %eax,%eax
f01020b1:	75 19                	jne    f01020cc <check_page+0x924>
f01020b3:	68 1c 44 10 f0       	push   $0xf010441c
f01020b8:	68 ed 45 10 f0       	push   $0xf01045ed
f01020bd:	68 61 03 00 00       	push   $0x361
f01020c2:	68 d3 45 10 f0       	push   $0xf01045d3
f01020c7:	e8 bf df ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01020cc:	83 ec 0c             	sub    $0xc,%esp
f01020cf:	6a 00                	push   $0x0
f01020d1:	e8 49 f0 ff ff       	call   f010111f <page_alloc>
f01020d6:	83 c4 10             	add    $0x10,%esp
f01020d9:	85 c0                	test   %eax,%eax
f01020db:	74 19                	je     f01020f6 <check_page+0x94e>
f01020dd:	68 93 47 10 f0       	push   $0xf0104793
f01020e2:	68 ed 45 10 f0       	push   $0xf01045ed
f01020e7:	68 64 03 00 00       	push   $0x364
f01020ec:	68 d3 45 10 f0       	push   $0xf01045d3
f01020f1:	e8 95 df ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01020f6:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f01020fc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020ff:	e8 0b e9 ff ff       	call   f0100a0f <page2pa>
f0102104:	8b 17                	mov    (%edi),%edx
f0102106:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010210c:	39 c2                	cmp    %eax,%edx
f010210e:	74 19                	je     f0102129 <check_page+0x981>
f0102110:	68 c0 40 10 f0       	push   $0xf01040c0
f0102115:	68 ed 45 10 f0       	push   $0xf01045ed
f010211a:	68 67 03 00 00       	push   $0x367
f010211f:	68 d3 45 10 f0       	push   $0xf01045d3
f0102124:	e8 62 df ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102129:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	assert(pp0->pp_ref == 1);
f010212f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102132:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102137:	74 19                	je     f0102152 <check_page+0x9aa>
f0102139:	68 0a 48 10 f0       	push   $0xf010480a
f010213e:	68 ed 45 10 f0       	push   $0xf01045ed
f0102143:	68 69 03 00 00       	push   $0x369
f0102148:	68 d3 45 10 f0       	push   $0xf01045d3
f010214d:	e8 39 df ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102152:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102155:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010215b:	83 ec 0c             	sub    $0xc,%esp
f010215e:	50                   	push   %eax
f010215f:	e8 00 f0 ff ff       	call   f0101164 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102164:	83 c4 0c             	add    $0xc,%esp
f0102167:	6a 01                	push   $0x1
f0102169:	68 00 10 40 00       	push   $0x401000
f010216e:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102174:	e8 31 f4 ff ff       	call   f01015aa <pgdir_walk>
f0102179:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010217c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010217f:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0102185:	8b 4f 04             	mov    0x4(%edi),%ecx
f0102188:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010218e:	ba 70 03 00 00       	mov    $0x370,%edx
f0102193:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
f0102198:	e8 7c e9 ff ff       	call   f0100b19 <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f010219d:	83 c0 04             	add    $0x4,%eax
f01021a0:	83 c4 10             	add    $0x10,%esp
f01021a3:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01021a6:	74 19                	je     f01021c1 <check_page+0xa19>
f01021a8:	68 96 48 10 f0       	push   $0xf0104896
f01021ad:	68 ed 45 10 f0       	push   $0xf01045ed
f01021b2:	68 71 03 00 00       	push   $0x371
f01021b7:	68 d3 45 10 f0       	push   $0xf01045d3
f01021bc:	e8 ca de ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f01021c1:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f01021c8:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01021cb:	89 f8                	mov    %edi,%eax
f01021cd:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01021d3:	e8 6d e9 ff ff       	call   f0100b45 <page2kva>
f01021d8:	83 ec 04             	sub    $0x4,%esp
f01021db:	68 00 10 00 00       	push   $0x1000
f01021e0:	68 ff 00 00 00       	push   $0xff
f01021e5:	50                   	push   %eax
f01021e6:	e8 a4 10 00 00       	call   f010328f <memset>
	page_free(pp0);
f01021eb:	89 3c 24             	mov    %edi,(%esp)
f01021ee:	e8 71 ef ff ff       	call   f0101164 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01021f3:	83 c4 0c             	add    $0xc,%esp
f01021f6:	6a 01                	push   $0x1
f01021f8:	6a 00                	push   $0x0
f01021fa:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102200:	e8 a5 f3 ff ff       	call   f01015aa <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f0102205:	89 f8                	mov    %edi,%eax
f0102207:	e8 39 e9 ff ff       	call   f0100b45 <page2kva>
f010220c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010220f:	89 c2                	mov    %eax,%edx
f0102211:	05 00 10 00 00       	add    $0x1000,%eax
f0102216:	83 c4 10             	add    $0x10,%esp
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102219:	f6 02 01             	testb  $0x1,(%edx)
f010221c:	74 19                	je     f0102237 <check_page+0xa8f>
f010221e:	68 ae 48 10 f0       	push   $0xf01048ae
f0102223:	68 ed 45 10 f0       	push   $0xf01045ed
f0102228:	68 7b 03 00 00       	push   $0x37b
f010222d:	68 d3 45 10 f0       	push   $0xf01045d3
f0102232:	e8 54 de ff ff       	call   f010008b <_panic>
f0102237:	83 c2 04             	add    $0x4,%edx
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010223a:	39 c2                	cmp    %eax,%edx
f010223c:	75 db                	jne    f0102219 <check_page+0xa71>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010223e:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0102243:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102249:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010224c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102252:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102255:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010225b:	83 ec 0c             	sub    $0xc,%esp
f010225e:	50                   	push   %eax
f010225f:	e8 00 ef ff ff       	call   f0101164 <page_free>
	page_free(pp1);
f0102264:	89 34 24             	mov    %esi,(%esp)
f0102267:	e8 f8 ee ff ff       	call   f0101164 <page_free>
	page_free(pp2);
f010226c:	89 1c 24             	mov    %ebx,(%esp)
f010226f:	e8 f0 ee ff ff       	call   f0101164 <page_free>

	cprintf("check_page() succeeded!\n");
f0102274:	c7 04 24 c5 48 10 f0 	movl   $0xf01048c5,(%esp)
f010227b:	e8 6b 05 00 00       	call   f01027eb <cprintf>
}
f0102280:	83 c4 10             	add    $0x10,%esp
f0102283:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102286:	5b                   	pop    %ebx
f0102287:	5e                   	pop    %esi
f0102288:	5f                   	pop    %edi
f0102289:	5d                   	pop    %ebp
f010228a:	c3                   	ret    

f010228b <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f010228b:	55                   	push   %ebp
f010228c:	89 e5                	mov    %esp,%ebp
f010228e:	57                   	push   %edi
f010228f:	56                   	push   %esi
f0102290:	53                   	push   %ebx
f0102291:	83 ec 18             	sub    $0x18,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102294:	6a 00                	push   $0x0
f0102296:	e8 84 ee ff ff       	call   f010111f <page_alloc>
f010229b:	83 c4 10             	add    $0x10,%esp
f010229e:	85 c0                	test   %eax,%eax
f01022a0:	75 19                	jne    f01022bb <check_page_installed_pgdir+0x30>
f01022a2:	68 e8 46 10 f0       	push   $0xf01046e8
f01022a7:	68 ed 45 10 f0       	push   $0xf01045ed
f01022ac:	68 96 03 00 00       	push   $0x396
f01022b1:	68 d3 45 10 f0       	push   $0xf01045d3
f01022b6:	e8 d0 dd ff ff       	call   f010008b <_panic>
f01022bb:	89 c6                	mov    %eax,%esi
	assert((pp1 = page_alloc(0)));
f01022bd:	83 ec 0c             	sub    $0xc,%esp
f01022c0:	6a 00                	push   $0x0
f01022c2:	e8 58 ee ff ff       	call   f010111f <page_alloc>
f01022c7:	89 c7                	mov    %eax,%edi
f01022c9:	83 c4 10             	add    $0x10,%esp
f01022cc:	85 c0                	test   %eax,%eax
f01022ce:	75 19                	jne    f01022e9 <check_page_installed_pgdir+0x5e>
f01022d0:	68 fe 46 10 f0       	push   $0xf01046fe
f01022d5:	68 ed 45 10 f0       	push   $0xf01045ed
f01022da:	68 97 03 00 00       	push   $0x397
f01022df:	68 d3 45 10 f0       	push   $0xf01045d3
f01022e4:	e8 a2 dd ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01022e9:	83 ec 0c             	sub    $0xc,%esp
f01022ec:	6a 00                	push   $0x0
f01022ee:	e8 2c ee ff ff       	call   f010111f <page_alloc>
f01022f3:	89 c3                	mov    %eax,%ebx
f01022f5:	83 c4 10             	add    $0x10,%esp
f01022f8:	85 c0                	test   %eax,%eax
f01022fa:	75 19                	jne    f0102315 <check_page_installed_pgdir+0x8a>
f01022fc:	68 14 47 10 f0       	push   $0xf0104714
f0102301:	68 ed 45 10 f0       	push   $0xf01045ed
f0102306:	68 98 03 00 00       	push   $0x398
f010230b:	68 d3 45 10 f0       	push   $0xf01045d3
f0102310:	e8 76 dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102315:	83 ec 0c             	sub    $0xc,%esp
f0102318:	56                   	push   %esi
f0102319:	e8 46 ee ff ff       	call   f0101164 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f010231e:	89 f8                	mov    %edi,%eax
f0102320:	e8 20 e8 ff ff       	call   f0100b45 <page2kva>
f0102325:	83 c4 0c             	add    $0xc,%esp
f0102328:	68 00 10 00 00       	push   $0x1000
f010232d:	6a 01                	push   $0x1
f010232f:	50                   	push   %eax
f0102330:	e8 5a 0f 00 00       	call   f010328f <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102335:	89 d8                	mov    %ebx,%eax
f0102337:	e8 09 e8 ff ff       	call   f0100b45 <page2kva>
f010233c:	83 c4 0c             	add    $0xc,%esp
f010233f:	68 00 10 00 00       	push   $0x1000
f0102344:	6a 02                	push   $0x2
f0102346:	50                   	push   %eax
f0102347:	e8 43 0f 00 00       	call   f010328f <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010234c:	6a 02                	push   $0x2
f010234e:	68 00 10 00 00       	push   $0x1000
f0102353:	57                   	push   %edi
f0102354:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010235a:	e8 ca f3 ff ff       	call   f0101729 <page_insert>
	assert(pp1->pp_ref == 1);
f010235f:	83 c4 20             	add    $0x20,%esp
f0102362:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102367:	74 19                	je     f0102382 <check_page_installed_pgdir+0xf7>
f0102369:	68 f9 47 10 f0       	push   $0xf01047f9
f010236e:	68 ed 45 10 f0       	push   $0xf01045ed
f0102373:	68 9d 03 00 00       	push   $0x39d
f0102378:	68 d3 45 10 f0       	push   $0xf01045d3
f010237d:	e8 09 dd ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102382:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102389:	01 01 01 
f010238c:	74 19                	je     f01023a7 <check_page_installed_pgdir+0x11c>
f010238e:	68 40 44 10 f0       	push   $0xf0104440
f0102393:	68 ed 45 10 f0       	push   $0xf01045ed
f0102398:	68 9e 03 00 00       	push   $0x39e
f010239d:	68 d3 45 10 f0       	push   $0xf01045d3
f01023a2:	e8 e4 dc ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01023a7:	6a 02                	push   $0x2
f01023a9:	68 00 10 00 00       	push   $0x1000
f01023ae:	53                   	push   %ebx
f01023af:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01023b5:	e8 6f f3 ff ff       	call   f0101729 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01023ba:	83 c4 10             	add    $0x10,%esp
f01023bd:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01023c4:	02 02 02 
f01023c7:	74 19                	je     f01023e2 <check_page_installed_pgdir+0x157>
f01023c9:	68 64 44 10 f0       	push   $0xf0104464
f01023ce:	68 ed 45 10 f0       	push   $0xf01045ed
f01023d3:	68 a0 03 00 00       	push   $0x3a0
f01023d8:	68 d3 45 10 f0       	push   $0xf01045d3
f01023dd:	e8 a9 dc ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01023e2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01023e7:	74 19                	je     f0102402 <check_page_installed_pgdir+0x177>
f01023e9:	68 1b 48 10 f0       	push   $0xf010481b
f01023ee:	68 ed 45 10 f0       	push   $0xf01045ed
f01023f3:	68 a1 03 00 00       	push   $0x3a1
f01023f8:	68 d3 45 10 f0       	push   $0xf01045d3
f01023fd:	e8 89 dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102402:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102407:	74 19                	je     f0102422 <check_page_installed_pgdir+0x197>
f0102409:	68 85 48 10 f0       	push   $0xf0104885
f010240e:	68 ed 45 10 f0       	push   $0xf01045ed
f0102413:	68 a2 03 00 00       	push   $0x3a2
f0102418:	68 d3 45 10 f0       	push   $0xf01045d3
f010241d:	e8 69 dc ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102422:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102429:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010242c:	89 d8                	mov    %ebx,%eax
f010242e:	e8 12 e7 ff ff       	call   f0100b45 <page2kva>
f0102433:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102439:	74 19                	je     f0102454 <check_page_installed_pgdir+0x1c9>
f010243b:	68 88 44 10 f0       	push   $0xf0104488
f0102440:	68 ed 45 10 f0       	push   $0xf01045ed
f0102445:	68 a4 03 00 00       	push   $0x3a4
f010244a:	68 d3 45 10 f0       	push   $0xf01045d3
f010244f:	e8 37 dc ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102454:	83 ec 08             	sub    $0x8,%esp
f0102457:	68 00 10 00 00       	push   $0x1000
f010245c:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102462:	e8 72 f2 ff ff       	call   f01016d9 <page_remove>
	assert(pp2->pp_ref == 0);
f0102467:	83 c4 10             	add    $0x10,%esp
f010246a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010246f:	74 19                	je     f010248a <check_page_installed_pgdir+0x1ff>
f0102471:	68 53 48 10 f0       	push   $0xf0104853
f0102476:	68 ed 45 10 f0       	push   $0xf01045ed
f010247b:	68 a6 03 00 00       	push   $0x3a6
f0102480:	68 d3 45 10 f0       	push   $0xf01045d3
f0102485:	e8 01 dc ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010248a:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f0102490:	89 f0                	mov    %esi,%eax
f0102492:	e8 78 e5 ff ff       	call   f0100a0f <page2pa>
f0102497:	8b 13                	mov    (%ebx),%edx
f0102499:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010249f:	39 c2                	cmp    %eax,%edx
f01024a1:	74 19                	je     f01024bc <check_page_installed_pgdir+0x231>
f01024a3:	68 c0 40 10 f0       	push   $0xf01040c0
f01024a8:	68 ed 45 10 f0       	push   $0xf01045ed
f01024ad:	68 a9 03 00 00       	push   $0x3a9
f01024b2:	68 d3 45 10 f0       	push   $0xf01045d3
f01024b7:	e8 cf db ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01024bc:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f01024c2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01024c7:	74 19                	je     f01024e2 <check_page_installed_pgdir+0x257>
f01024c9:	68 0a 48 10 f0       	push   $0xf010480a
f01024ce:	68 ed 45 10 f0       	push   $0xf01045ed
f01024d3:	68 ab 03 00 00       	push   $0x3ab
f01024d8:	68 d3 45 10 f0       	push   $0xf01045d3
f01024dd:	e8 a9 db ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01024e2:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01024e8:	83 ec 0c             	sub    $0xc,%esp
f01024eb:	56                   	push   %esi
f01024ec:	e8 73 ec ff ff       	call   f0101164 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01024f1:	c7 04 24 b4 44 10 f0 	movl   $0xf01044b4,(%esp)
f01024f8:	e8 ee 02 00 00       	call   f01027eb <cprintf>
}
f01024fd:	83 c4 10             	add    $0x10,%esp
f0102500:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102503:	5b                   	pop    %ebx
f0102504:	5e                   	pop    %esi
f0102505:	5f                   	pop    %edi
f0102506:	5d                   	pop    %ebp
f0102507:	c3                   	ret    

f0102508 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0102508:	55                   	push   %ebp
f0102509:	89 e5                	mov    %esp,%ebp
f010250b:	53                   	push   %ebx
f010250c:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f010250f:	e8 35 e5 ff ff       	call   f0100a49 <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0102514:	b8 00 10 00 00       	mov    $0x1000,%eax
f0102519:	e8 91 e5 ff ff       	call   f0100aaf <boot_alloc>
f010251e:	a3 48 79 11 f0       	mov    %eax,0xf0117948
	memset(kern_pgdir, 0, PGSIZE);
f0102523:	83 ec 04             	sub    $0x4,%esp
f0102526:	68 00 10 00 00       	push   $0x1000
f010252b:	6a 00                	push   $0x0
f010252d:	50                   	push   %eax
f010252e:	e8 5c 0d 00 00       	call   f010328f <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0102533:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f0102539:	89 d9                	mov    %ebx,%ecx
f010253b:	ba 92 00 00 00       	mov    $0x92,%edx
f0102540:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
f0102545:	e8 89 e6 ff ff       	call   f0100bd3 <_paddr>
f010254a:	83 c8 05             	or     $0x5,%eax
f010254d:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	//Un PageInfo tiene 4B del PageInfo* +4B del uint16_t = 8B de size

	pages=(struct PageInfo *) boot_alloc(npages //[page]
f0102553:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0102558:	c1 e0 03             	shl    $0x3,%eax
f010255b:	e8 4f e5 ff ff       	call   f0100aaf <boot_alloc>
f0102560:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
										 * sizeof(struct PageInfo));//[B/page]

	memset(pages,0,npages*sizeof(struct PageInfo));
f0102565:	83 c4 0c             	add    $0xc,%esp
f0102568:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f010256e:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0102575:	52                   	push   %edx
f0102576:	6a 00                	push   $0x0
f0102578:	50                   	push   %eax
f0102579:	e8 11 0d 00 00       	call   f010328f <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010257e:	e8 1e eb ff ff       	call   f01010a1 <page_init>


	//parte de pruebas
	cprintf("\n***PRUEBAS DADA UN LINEAR ADDR***\n");
f0102583:	c7 04 24 e0 44 10 f0 	movl   $0xf01044e0,(%esp)
f010258a:	e8 5c 02 00 00       	call   f01027eb <cprintf>
	pde_t* kpd = kern_pgdir;
f010258f:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
	cprintf("	kern_pgdir es %p (32b)\n",kpd);
f0102595:	83 c4 08             	add    $0x8,%esp
f0102598:	53                   	push   %ebx
f0102599:	68 de 48 10 f0       	push   $0xf01048de
f010259e:	e8 48 02 00 00       	call   f01027eb <cprintf>
	cprintf("	PD index es %p (10b)\n",PDX(kpd));
f01025a3:	83 c4 08             	add    $0x8,%esp
f01025a6:	89 d8                	mov    %ebx,%eax
f01025a8:	c1 e8 16             	shr    $0x16,%eax
f01025ab:	50                   	push   %eax
f01025ac:	68 f7 48 10 f0       	push   $0xf01048f7
f01025b1:	e8 35 02 00 00       	call   f01027eb <cprintf>
	cprintf("	PT index es %p (10b)\n",PTX(kpd));
f01025b6:	83 c4 08             	add    $0x8,%esp
f01025b9:	89 d8                	mov    %ebx,%eax
f01025bb:	c1 e8 0c             	shr    $0xc,%eax
f01025be:	25 ff 03 00 00       	and    $0x3ff,%eax
f01025c3:	50                   	push   %eax
f01025c4:	68 0e 49 10 f0       	push   $0xf010490e
f01025c9:	e8 1d 02 00 00       	call   f01027eb <cprintf>
	cprintf("	PG offset es %p (12b)\n",PGOFF(kpd));
f01025ce:	83 c4 08             	add    $0x8,%esp
f01025d1:	89 d8                	mov    %ebx,%eax
f01025d3:	25 ff 0f 00 00       	and    $0xfff,%eax
f01025d8:	50                   	push   %eax
f01025d9:	68 25 49 10 f0       	push   $0xf0104925
f01025de:	e8 08 02 00 00       	call   f01027eb <cprintf>

	void* va1 = (void*) 0x7fe1b6a7;
	cprintf("\n***ACCEDIENDO A KERN_PGDIR con VA = %p***\n",va1);
f01025e3:	83 c4 08             	add    $0x8,%esp
f01025e6:	68 a7 b6 e1 7f       	push   $0x7fe1b6a7
f01025eb:	68 04 45 10 f0       	push   $0xf0104504
f01025f0:	e8 f6 01 00 00       	call   f01027eb <cprintf>
	cprintf("	PD index es %p (10b)\n",PDX(va1));
f01025f5:	83 c4 08             	add    $0x8,%esp
f01025f8:	68 ff 01 00 00       	push   $0x1ff
f01025fd:	68 f7 48 10 f0       	push   $0xf01048f7
f0102602:	e8 e4 01 00 00       	call   f01027eb <cprintf>
	cprintf("	PT index es %p (10b)\n",PTX(va1));
f0102607:	83 c4 08             	add    $0x8,%esp
f010260a:	68 1b 02 00 00       	push   $0x21b
f010260f:	68 0e 49 10 f0       	push   $0xf010490e
f0102614:	e8 d2 01 00 00       	call   f01027eb <cprintf>
	cprintf("	PG offset es %p (12b)\n",PGOFF(va1));
f0102619:	83 c4 08             	add    $0x8,%esp
f010261c:	68 a7 06 00 00       	push   $0x6a7
f0102621:	68 25 49 10 f0       	push   $0xf0104925
f0102626:	e8 c0 01 00 00       	call   f01027eb <cprintf>
	cprintf("	kern_pgdir[PDX] es %p (32b)\n",kpd+PDX(va1));
f010262b:	83 c4 08             	add    $0x8,%esp
f010262e:	8d 83 fc 07 00 00    	lea    0x7fc(%ebx),%eax
f0102634:	50                   	push   %eax
f0102635:	68 3d 49 10 f0       	push   $0xf010493d
f010263a:	e8 ac 01 00 00       	call   f01027eb <cprintf>
	cprintf("	y su contenido es %p (32b)\n",kpd[PDX(va1)]);
f010263f:	83 c4 08             	add    $0x8,%esp
f0102642:	ff b3 fc 07 00 00    	pushl  0x7fc(%ebx)
f0102648:	68 5b 49 10 f0       	push   $0xf010495b
f010264d:	e8 99 01 00 00       	call   f01027eb <cprintf>
	cprintf("	o tambien es %p (32b)\n",*(kpd+PDX(va1)));
f0102652:	83 c4 08             	add    $0x8,%esp
f0102655:	ff b3 fc 07 00 00    	pushl  0x7fc(%ebx)
f010265b:	68 78 49 10 f0       	push   $0xf0104978
f0102660:	e8 86 01 00 00       	call   f01027eb <cprintf>
	cprintf("	que maskeado es %p (32b, ultimos 10 en 0)\n",PTE_ADDR(kpd[PDX(va1)]));
f0102665:	83 c4 08             	add    $0x8,%esp
f0102668:	8b 83 fc 07 00 00    	mov    0x7fc(%ebx),%eax
f010266e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102673:	50                   	push   %eax
f0102674:	68 30 45 10 f0       	push   $0xf0104530
f0102679:	e8 6d 01 00 00       	call   f01027eb <cprintf>
	cprintf("	kern_pgdir[PTX] es %p (32b)\n",kpd+PTX(va1));
f010267e:	83 c4 08             	add    $0x8,%esp
f0102681:	8d 83 6c 08 00 00    	lea    0x86c(%ebx),%eax
f0102687:	50                   	push   %eax
f0102688:	68 90 49 10 f0       	push   $0xf0104990
f010268d:	e8 59 01 00 00       	call   f01027eb <cprintf>
	cprintf("	y su contenido es %p (32b)\n",kpd[PTX(va1)]);
f0102692:	83 c4 08             	add    $0x8,%esp
f0102695:	ff b3 6c 08 00 00    	pushl  0x86c(%ebx)
f010269b:	68 5b 49 10 f0       	push   $0xf010495b
f01026a0:	e8 46 01 00 00       	call   f01027eb <cprintf>
	cprintf("	o tambien es %p (32b)\n",*(kpd+PTX(va1)));
f01026a5:	83 c4 08             	add    $0x8,%esp
f01026a8:	ff b3 6c 08 00 00    	pushl  0x86c(%ebx)
f01026ae:	68 78 49 10 f0       	push   $0xf0104978
f01026b3:	e8 33 01 00 00       	call   f01027eb <cprintf>
	cprintf("	que maskeado es %p (32b, ultimos 10 en 0)\n",PTE_ADDR(kpd[PTX(va1)]));
f01026b8:	83 c4 08             	add    $0x8,%esp
f01026bb:	8b 83 6c 08 00 00    	mov    0x86c(%ebx),%eax
f01026c1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026c6:	50                   	push   %eax
f01026c7:	68 30 45 10 f0       	push   $0xf0104530
f01026cc:	e8 1a 01 00 00       	call   f01027eb <cprintf>

	cprintf("\n***OPERACIONES DE MASKING con VA = %p***\n",va1);
f01026d1:	83 c4 08             	add    $0x8,%esp
f01026d4:	68 a7 b6 e1 7f       	push   $0x7fe1b6a7
f01026d9:	68 5c 45 10 f0       	push   $0xf010455c
f01026de:	e8 08 01 00 00       	call   f01027eb <cprintf>
	cprintf("	maskeada con PTE_ADDR es %p (vuela los 12 de abajo)\n",PTE_ADDR(va1));
f01026e3:	83 c4 08             	add    $0x8,%esp
f01026e6:	68 00 b0 e1 7f       	push   $0x7fe1b000
f01026eb:	68 88 45 10 f0       	push   $0xf0104588
f01026f0:	e8 f6 00 00 00       	call   f01027eb <cprintf>
	cprintf("\n\n");
f01026f5:	c7 04 24 ae 49 10 f0 	movl   $0xf01049ae,(%esp)
f01026fc:	e8 ea 00 00 00       	call   f01027eb <cprintf>
	//end:parte pruebas

	check_page_free_list(1);
f0102701:	b8 01 00 00 00       	mov    $0x1,%eax
f0102706:	e8 f2 e6 ff ff       	call   f0100dfd <check_page_free_list>
	check_page_alloc();
f010270b:	e8 a6 ea ff ff       	call   f01011b6 <check_page_alloc>
	check_page();
f0102710:	e8 93 f0 ff ff       	call   f01017a8 <check_page>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f0102715:	e8 db e4 ff ff       	call   f0100bf5 <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010271a:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f0102720:	ba f5 00 00 00       	mov    $0xf5,%edx
f0102725:	b8 d3 45 10 f0       	mov    $0xf01045d3,%eax
f010272a:	e8 a4 e4 ff ff       	call   f0100bd3 <_paddr>
f010272f:	e8 d3 e2 ff ff       	call   f0100a07 <lcr3>

	check_page_free_list(0);
f0102734:	b8 00 00 00 00       	mov    $0x0,%eax
f0102739:	e8 bf e6 ff ff       	call   f0100dfd <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f010273e:	e8 bc e2 ff ff       	call   f01009ff <rcr0>
f0102743:	83 e0 f3             	and    $0xfffffff3,%eax
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);
f0102746:	0d 23 00 05 80       	or     $0x80050023,%eax
f010274b:	e8 a7 e2 ff ff       	call   f01009f7 <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f0102750:	e8 36 fb ff ff       	call   f010228b <check_page_installed_pgdir>
}
f0102755:	83 c4 10             	add    $0x10,%esp
f0102758:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010275b:	c9                   	leave  
f010275c:	c3                   	ret    

f010275d <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010275d:	55                   	push   %ebp
f010275e:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102760:	89 c2                	mov    %eax,%edx
f0102762:	ec                   	in     (%dx),%al
	return data;
}
f0102763:	5d                   	pop    %ebp
f0102764:	c3                   	ret    

f0102765 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0102765:	55                   	push   %ebp
f0102766:	89 e5                	mov    %esp,%ebp
f0102768:	89 c1                	mov    %eax,%ecx
f010276a:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010276c:	89 ca                	mov    %ecx,%edx
f010276e:	ee                   	out    %al,(%dx)
}
f010276f:	5d                   	pop    %ebp
f0102770:	c3                   	ret    

f0102771 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102771:	55                   	push   %ebp
f0102772:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102774:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102778:	b8 70 00 00 00       	mov    $0x70,%eax
f010277d:	e8 e3 ff ff ff       	call   f0102765 <outb>
	return inb(IO_RTC+1);
f0102782:	b8 71 00 00 00       	mov    $0x71,%eax
f0102787:	e8 d1 ff ff ff       	call   f010275d <inb>
f010278c:	0f b6 c0             	movzbl %al,%eax
}
f010278f:	5d                   	pop    %ebp
f0102790:	c3                   	ret    

f0102791 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102791:	55                   	push   %ebp
f0102792:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102794:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102798:	b8 70 00 00 00       	mov    $0x70,%eax
f010279d:	e8 c3 ff ff ff       	call   f0102765 <outb>
	outb(IO_RTC+1, datum);
f01027a2:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f01027a6:	b8 71 00 00 00       	mov    $0x71,%eax
f01027ab:	e8 b5 ff ff ff       	call   f0102765 <outb>
}
f01027b0:	5d                   	pop    %ebp
f01027b1:	c3                   	ret    

f01027b2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01027b2:	55                   	push   %ebp
f01027b3:	89 e5                	mov    %esp,%ebp
f01027b5:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01027b8:	ff 75 08             	pushl  0x8(%ebp)
f01027bb:	e8 45 df ff ff       	call   f0100705 <cputchar>
	*cnt++;
}
f01027c0:	83 c4 10             	add    $0x10,%esp
f01027c3:	c9                   	leave  
f01027c4:	c3                   	ret    

f01027c5 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01027c5:	55                   	push   %ebp
f01027c6:	89 e5                	mov    %esp,%ebp
f01027c8:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01027cb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01027d2:	ff 75 0c             	pushl  0xc(%ebp)
f01027d5:	ff 75 08             	pushl  0x8(%ebp)
f01027d8:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01027db:	50                   	push   %eax
f01027dc:	68 b2 27 10 f0       	push   $0xf01027b2
f01027e1:	e8 82 04 00 00       	call   f0102c68 <vprintfmt>
	return cnt;
}
f01027e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01027e9:	c9                   	leave  
f01027ea:	c3                   	ret    

f01027eb <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01027eb:	55                   	push   %ebp
f01027ec:	89 e5                	mov    %esp,%ebp
f01027ee:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01027f1:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01027f4:	50                   	push   %eax
f01027f5:	ff 75 08             	pushl  0x8(%ebp)
f01027f8:	e8 c8 ff ff ff       	call   f01027c5 <vcprintf>
	va_end(ap);

	return cnt;
}
f01027fd:	c9                   	leave  
f01027fe:	c3                   	ret    

f01027ff <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01027ff:	55                   	push   %ebp
f0102800:	89 e5                	mov    %esp,%ebp
f0102802:	57                   	push   %edi
f0102803:	56                   	push   %esi
f0102804:	53                   	push   %ebx
f0102805:	83 ec 14             	sub    $0x14,%esp
f0102808:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010280b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010280e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102811:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102814:	8b 1a                	mov    (%edx),%ebx
f0102816:	8b 01                	mov    (%ecx),%eax
f0102818:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010281b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102822:	eb 7f                	jmp    f01028a3 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102824:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102827:	01 d8                	add    %ebx,%eax
f0102829:	89 c6                	mov    %eax,%esi
f010282b:	c1 ee 1f             	shr    $0x1f,%esi
f010282e:	01 c6                	add    %eax,%esi
f0102830:	d1 fe                	sar    %esi
f0102832:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102835:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102838:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010283b:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010283d:	eb 03                	jmp    f0102842 <stab_binsearch+0x43>
			m--;
f010283f:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102842:	39 c3                	cmp    %eax,%ebx
f0102844:	7f 0d                	jg     f0102853 <stab_binsearch+0x54>
f0102846:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010284a:	83 ea 0c             	sub    $0xc,%edx
f010284d:	39 f9                	cmp    %edi,%ecx
f010284f:	75 ee                	jne    f010283f <stab_binsearch+0x40>
f0102851:	eb 05                	jmp    f0102858 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102853:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102856:	eb 4b                	jmp    f01028a3 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102858:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010285b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010285e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102862:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102865:	76 11                	jbe    f0102878 <stab_binsearch+0x79>
			*region_left = m;
f0102867:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010286a:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010286c:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010286f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102876:	eb 2b                	jmp    f01028a3 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102878:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010287b:	73 14                	jae    f0102891 <stab_binsearch+0x92>
			*region_right = m - 1;
f010287d:	83 e8 01             	sub    $0x1,%eax
f0102880:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102883:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102886:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102888:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010288f:	eb 12                	jmp    f01028a3 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102891:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102894:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102896:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010289a:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010289c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01028a3:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01028a6:	0f 8e 78 ff ff ff    	jle    f0102824 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01028ac:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01028b0:	75 0f                	jne    f01028c1 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01028b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028b5:	8b 00                	mov    (%eax),%eax
f01028b7:	83 e8 01             	sub    $0x1,%eax
f01028ba:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01028bd:	89 06                	mov    %eax,(%esi)
f01028bf:	eb 2c                	jmp    f01028ed <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01028c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028c4:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01028c6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028c9:	8b 0e                	mov    (%esi),%ecx
f01028cb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01028ce:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01028d1:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01028d4:	eb 03                	jmp    f01028d9 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01028d6:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01028d9:	39 c8                	cmp    %ecx,%eax
f01028db:	7e 0b                	jle    f01028e8 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01028dd:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01028e1:	83 ea 0c             	sub    $0xc,%edx
f01028e4:	39 df                	cmp    %ebx,%edi
f01028e6:	75 ee                	jne    f01028d6 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01028e8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028eb:	89 06                	mov    %eax,(%esi)
	}
}
f01028ed:	83 c4 14             	add    $0x14,%esp
f01028f0:	5b                   	pop    %ebx
f01028f1:	5e                   	pop    %esi
f01028f2:	5f                   	pop    %edi
f01028f3:	5d                   	pop    %ebp
f01028f4:	c3                   	ret    

f01028f5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01028f5:	55                   	push   %ebp
f01028f6:	89 e5                	mov    %esp,%ebp
f01028f8:	57                   	push   %edi
f01028f9:	56                   	push   %esi
f01028fa:	53                   	push   %ebx
f01028fb:	83 ec 3c             	sub    $0x3c,%esp
f01028fe:	8b 75 08             	mov    0x8(%ebp),%esi
f0102901:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102904:	c7 03 b1 49 10 f0    	movl   $0xf01049b1,(%ebx)
	info->eip_line = 0;
f010290a:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102911:	c7 43 08 b1 49 10 f0 	movl   $0xf01049b1,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102918:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010291f:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102922:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102929:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010292f:	76 11                	jbe    f0102942 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102931:	b8 52 c9 10 f0       	mov    $0xf010c952,%eax
f0102936:	3d 81 a9 10 f0       	cmp    $0xf010a981,%eax
f010293b:	77 19                	ja     f0102956 <debuginfo_eip+0x61>
f010293d:	e9 af 01 00 00       	jmp    f0102af1 <debuginfo_eip+0x1fc>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102942:	83 ec 04             	sub    $0x4,%esp
f0102945:	68 bb 49 10 f0       	push   $0xf01049bb
f010294a:	6a 7f                	push   $0x7f
f010294c:	68 c8 49 10 f0       	push   $0xf01049c8
f0102951:	e8 35 d7 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102956:	80 3d 51 c9 10 f0 00 	cmpb   $0x0,0xf010c951
f010295d:	0f 85 95 01 00 00    	jne    f0102af8 <debuginfo_eip+0x203>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102963:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010296a:	b8 80 a9 10 f0       	mov    $0xf010a980,%eax
f010296f:	2d e4 4b 10 f0       	sub    $0xf0104be4,%eax
f0102974:	c1 f8 02             	sar    $0x2,%eax
f0102977:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010297d:	83 e8 01             	sub    $0x1,%eax
f0102980:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102983:	83 ec 08             	sub    $0x8,%esp
f0102986:	56                   	push   %esi
f0102987:	6a 64                	push   $0x64
f0102989:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010298c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010298f:	b8 e4 4b 10 f0       	mov    $0xf0104be4,%eax
f0102994:	e8 66 fe ff ff       	call   f01027ff <stab_binsearch>
	if (lfile == 0)
f0102999:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010299c:	83 c4 10             	add    $0x10,%esp
f010299f:	85 c0                	test   %eax,%eax
f01029a1:	0f 84 58 01 00 00    	je     f0102aff <debuginfo_eip+0x20a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01029a7:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01029aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029ad:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01029b0:	83 ec 08             	sub    $0x8,%esp
f01029b3:	56                   	push   %esi
f01029b4:	6a 24                	push   $0x24
f01029b6:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01029b9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01029bc:	b8 e4 4b 10 f0       	mov    $0xf0104be4,%eax
f01029c1:	e8 39 fe ff ff       	call   f01027ff <stab_binsearch>

	if (lfun <= rfun) {
f01029c6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01029c9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01029cc:	83 c4 10             	add    $0x10,%esp
f01029cf:	39 d0                	cmp    %edx,%eax
f01029d1:	7f 40                	jg     f0102a13 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01029d3:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01029d6:	c1 e1 02             	shl    $0x2,%ecx
f01029d9:	8d b9 e4 4b 10 f0    	lea    -0xfefb41c(%ecx),%edi
f01029df:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01029e2:	8b b9 e4 4b 10 f0    	mov    -0xfefb41c(%ecx),%edi
f01029e8:	b9 52 c9 10 f0       	mov    $0xf010c952,%ecx
f01029ed:	81 e9 81 a9 10 f0    	sub    $0xf010a981,%ecx
f01029f3:	39 cf                	cmp    %ecx,%edi
f01029f5:	73 09                	jae    f0102a00 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01029f7:	81 c7 81 a9 10 f0    	add    $0xf010a981,%edi
f01029fd:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102a00:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102a03:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102a06:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102a09:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102a0b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102a0e:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102a11:	eb 0f                	jmp    f0102a22 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102a13:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102a16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a19:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102a1c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a1f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102a22:	83 ec 08             	sub    $0x8,%esp
f0102a25:	6a 3a                	push   $0x3a
f0102a27:	ff 73 08             	pushl  0x8(%ebx)
f0102a2a:	e8 44 08 00 00       	call   f0103273 <strfind>
f0102a2f:	2b 43 08             	sub    0x8(%ebx),%eax
f0102a32:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102a35:	83 c4 08             	add    $0x8,%esp
f0102a38:	56                   	push   %esi
f0102a39:	6a 44                	push   $0x44
f0102a3b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102a3e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102a41:	b8 e4 4b 10 f0       	mov    $0xf0104be4,%eax
f0102a46:	e8 b4 fd ff ff       	call   f01027ff <stab_binsearch>
	if (lline <= rline) {
f0102a4b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a4e:	83 c4 10             	add    $0x10,%esp
f0102a51:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0102a54:	7f 0e                	jg     f0102a64 <debuginfo_eip+0x16f>
		info->eip_line = stabs[lline].n_desc;
f0102a56:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102a59:	0f b7 14 95 ea 4b 10 	movzwl -0xfefb416(,%edx,4),%edx
f0102a60:	f0 
f0102a61:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102a64:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a67:	89 c2                	mov    %eax,%edx
f0102a69:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102a6c:	8d 04 85 e4 4b 10 f0 	lea    -0xfefb41c(,%eax,4),%eax
f0102a73:	eb 06                	jmp    f0102a7b <debuginfo_eip+0x186>
f0102a75:	83 ea 01             	sub    $0x1,%edx
f0102a78:	83 e8 0c             	sub    $0xc,%eax
f0102a7b:	39 d7                	cmp    %edx,%edi
f0102a7d:	7f 34                	jg     f0102ab3 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0102a7f:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102a83:	80 f9 84             	cmp    $0x84,%cl
f0102a86:	74 0b                	je     f0102a93 <debuginfo_eip+0x19e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102a88:	80 f9 64             	cmp    $0x64,%cl
f0102a8b:	75 e8                	jne    f0102a75 <debuginfo_eip+0x180>
f0102a8d:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a91:	74 e2                	je     f0102a75 <debuginfo_eip+0x180>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a93:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a96:	8b 14 85 e4 4b 10 f0 	mov    -0xfefb41c(,%eax,4),%edx
f0102a9d:	b8 52 c9 10 f0       	mov    $0xf010c952,%eax
f0102aa2:	2d 81 a9 10 f0       	sub    $0xf010a981,%eax
f0102aa7:	39 c2                	cmp    %eax,%edx
f0102aa9:	73 08                	jae    f0102ab3 <debuginfo_eip+0x1be>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102aab:	81 c2 81 a9 10 f0    	add    $0xf010a981,%edx
f0102ab1:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102ab3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ab6:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102ab9:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102abe:	39 f2                	cmp    %esi,%edx
f0102ac0:	7d 49                	jge    f0102b0b <debuginfo_eip+0x216>
		for (lline = lfun + 1;
f0102ac2:	83 c2 01             	add    $0x1,%edx
f0102ac5:	89 d0                	mov    %edx,%eax
f0102ac7:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102aca:	8d 14 95 e4 4b 10 f0 	lea    -0xfefb41c(,%edx,4),%edx
f0102ad1:	eb 04                	jmp    f0102ad7 <debuginfo_eip+0x1e2>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102ad3:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102ad7:	39 c6                	cmp    %eax,%esi
f0102ad9:	7e 2b                	jle    f0102b06 <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102adb:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102adf:	83 c0 01             	add    $0x1,%eax
f0102ae2:	83 c2 0c             	add    $0xc,%edx
f0102ae5:	80 f9 a0             	cmp    $0xa0,%cl
f0102ae8:	74 e9                	je     f0102ad3 <debuginfo_eip+0x1de>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102aea:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aef:	eb 1a                	jmp    f0102b0b <debuginfo_eip+0x216>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102af1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102af6:	eb 13                	jmp    f0102b0b <debuginfo_eip+0x216>
f0102af8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102afd:	eb 0c                	jmp    f0102b0b <debuginfo_eip+0x216>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102aff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b04:	eb 05                	jmp    f0102b0b <debuginfo_eip+0x216>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b06:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b0b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b0e:	5b                   	pop    %ebx
f0102b0f:	5e                   	pop    %esi
f0102b10:	5f                   	pop    %edi
f0102b11:	5d                   	pop    %ebp
f0102b12:	c3                   	ret    

f0102b13 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102b13:	55                   	push   %ebp
f0102b14:	89 e5                	mov    %esp,%ebp
f0102b16:	57                   	push   %edi
f0102b17:	56                   	push   %esi
f0102b18:	53                   	push   %ebx
f0102b19:	83 ec 1c             	sub    $0x1c,%esp
f0102b1c:	89 c7                	mov    %eax,%edi
f0102b1e:	89 d6                	mov    %edx,%esi
f0102b20:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b23:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102b26:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102b29:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102b2c:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102b2f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102b34:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102b37:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102b3a:	39 d3                	cmp    %edx,%ebx
f0102b3c:	72 05                	jb     f0102b43 <printnum+0x30>
f0102b3e:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102b41:	77 45                	ja     f0102b88 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102b43:	83 ec 0c             	sub    $0xc,%esp
f0102b46:	ff 75 18             	pushl  0x18(%ebp)
f0102b49:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b4c:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102b4f:	53                   	push   %ebx
f0102b50:	ff 75 10             	pushl  0x10(%ebp)
f0102b53:	83 ec 08             	sub    $0x8,%esp
f0102b56:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b59:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b5c:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b5f:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b62:	e8 39 09 00 00       	call   f01034a0 <__udivdi3>
f0102b67:	83 c4 18             	add    $0x18,%esp
f0102b6a:	52                   	push   %edx
f0102b6b:	50                   	push   %eax
f0102b6c:	89 f2                	mov    %esi,%edx
f0102b6e:	89 f8                	mov    %edi,%eax
f0102b70:	e8 9e ff ff ff       	call   f0102b13 <printnum>
f0102b75:	83 c4 20             	add    $0x20,%esp
f0102b78:	eb 18                	jmp    f0102b92 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102b7a:	83 ec 08             	sub    $0x8,%esp
f0102b7d:	56                   	push   %esi
f0102b7e:	ff 75 18             	pushl  0x18(%ebp)
f0102b81:	ff d7                	call   *%edi
f0102b83:	83 c4 10             	add    $0x10,%esp
f0102b86:	eb 03                	jmp    f0102b8b <printnum+0x78>
f0102b88:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b8b:	83 eb 01             	sub    $0x1,%ebx
f0102b8e:	85 db                	test   %ebx,%ebx
f0102b90:	7f e8                	jg     f0102b7a <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b92:	83 ec 08             	sub    $0x8,%esp
f0102b95:	56                   	push   %esi
f0102b96:	83 ec 04             	sub    $0x4,%esp
f0102b99:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b9c:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b9f:	ff 75 dc             	pushl  -0x24(%ebp)
f0102ba2:	ff 75 d8             	pushl  -0x28(%ebp)
f0102ba5:	e8 26 0a 00 00       	call   f01035d0 <__umoddi3>
f0102baa:	83 c4 14             	add    $0x14,%esp
f0102bad:	0f be 80 d6 49 10 f0 	movsbl -0xfefb62a(%eax),%eax
f0102bb4:	50                   	push   %eax
f0102bb5:	ff d7                	call   *%edi
}
f0102bb7:	83 c4 10             	add    $0x10,%esp
f0102bba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bbd:	5b                   	pop    %ebx
f0102bbe:	5e                   	pop    %esi
f0102bbf:	5f                   	pop    %edi
f0102bc0:	5d                   	pop    %ebp
f0102bc1:	c3                   	ret    

f0102bc2 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102bc2:	55                   	push   %ebp
f0102bc3:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102bc5:	83 fa 01             	cmp    $0x1,%edx
f0102bc8:	7e 0e                	jle    f0102bd8 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102bca:	8b 10                	mov    (%eax),%edx
f0102bcc:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102bcf:	89 08                	mov    %ecx,(%eax)
f0102bd1:	8b 02                	mov    (%edx),%eax
f0102bd3:	8b 52 04             	mov    0x4(%edx),%edx
f0102bd6:	eb 22                	jmp    f0102bfa <getuint+0x38>
	else if (lflag)
f0102bd8:	85 d2                	test   %edx,%edx
f0102bda:	74 10                	je     f0102bec <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102bdc:	8b 10                	mov    (%eax),%edx
f0102bde:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102be1:	89 08                	mov    %ecx,(%eax)
f0102be3:	8b 02                	mov    (%edx),%eax
f0102be5:	ba 00 00 00 00       	mov    $0x0,%edx
f0102bea:	eb 0e                	jmp    f0102bfa <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102bec:	8b 10                	mov    (%eax),%edx
f0102bee:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102bf1:	89 08                	mov    %ecx,(%eax)
f0102bf3:	8b 02                	mov    (%edx),%eax
f0102bf5:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102bfa:	5d                   	pop    %ebp
f0102bfb:	c3                   	ret    

f0102bfc <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0102bfc:	55                   	push   %ebp
f0102bfd:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102bff:	83 fa 01             	cmp    $0x1,%edx
f0102c02:	7e 0e                	jle    f0102c12 <getint+0x16>
		return va_arg(*ap, long long);
f0102c04:	8b 10                	mov    (%eax),%edx
f0102c06:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102c09:	89 08                	mov    %ecx,(%eax)
f0102c0b:	8b 02                	mov    (%edx),%eax
f0102c0d:	8b 52 04             	mov    0x4(%edx),%edx
f0102c10:	eb 1a                	jmp    f0102c2c <getint+0x30>
	else if (lflag)
f0102c12:	85 d2                	test   %edx,%edx
f0102c14:	74 0c                	je     f0102c22 <getint+0x26>
		return va_arg(*ap, long);
f0102c16:	8b 10                	mov    (%eax),%edx
f0102c18:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102c1b:	89 08                	mov    %ecx,(%eax)
f0102c1d:	8b 02                	mov    (%edx),%eax
f0102c1f:	99                   	cltd   
f0102c20:	eb 0a                	jmp    f0102c2c <getint+0x30>
	else
		return va_arg(*ap, int);
f0102c22:	8b 10                	mov    (%eax),%edx
f0102c24:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102c27:	89 08                	mov    %ecx,(%eax)
f0102c29:	8b 02                	mov    (%edx),%eax
f0102c2b:	99                   	cltd   
}
f0102c2c:	5d                   	pop    %ebp
f0102c2d:	c3                   	ret    

f0102c2e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102c2e:	55                   	push   %ebp
f0102c2f:	89 e5                	mov    %esp,%ebp
f0102c31:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102c34:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102c38:	8b 10                	mov    (%eax),%edx
f0102c3a:	3b 50 04             	cmp    0x4(%eax),%edx
f0102c3d:	73 0a                	jae    f0102c49 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102c3f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102c42:	89 08                	mov    %ecx,(%eax)
f0102c44:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c47:	88 02                	mov    %al,(%edx)
}
f0102c49:	5d                   	pop    %ebp
f0102c4a:	c3                   	ret    

f0102c4b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102c4b:	55                   	push   %ebp
f0102c4c:	89 e5                	mov    %esp,%ebp
f0102c4e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102c51:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102c54:	50                   	push   %eax
f0102c55:	ff 75 10             	pushl  0x10(%ebp)
f0102c58:	ff 75 0c             	pushl  0xc(%ebp)
f0102c5b:	ff 75 08             	pushl  0x8(%ebp)
f0102c5e:	e8 05 00 00 00       	call   f0102c68 <vprintfmt>
	va_end(ap);
}
f0102c63:	83 c4 10             	add    $0x10,%esp
f0102c66:	c9                   	leave  
f0102c67:	c3                   	ret    

f0102c68 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102c68:	55                   	push   %ebp
f0102c69:	89 e5                	mov    %esp,%ebp
f0102c6b:	57                   	push   %edi
f0102c6c:	56                   	push   %esi
f0102c6d:	53                   	push   %ebx
f0102c6e:	83 ec 2c             	sub    $0x2c,%esp
f0102c71:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c74:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c77:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102c7a:	eb 12                	jmp    f0102c8e <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102c7c:	85 c0                	test   %eax,%eax
f0102c7e:	0f 84 44 03 00 00    	je     f0102fc8 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f0102c84:	83 ec 08             	sub    $0x8,%esp
f0102c87:	53                   	push   %ebx
f0102c88:	50                   	push   %eax
f0102c89:	ff d6                	call   *%esi
f0102c8b:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102c8e:	83 c7 01             	add    $0x1,%edi
f0102c91:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c95:	83 f8 25             	cmp    $0x25,%eax
f0102c98:	75 e2                	jne    f0102c7c <vprintfmt+0x14>
f0102c9a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102c9e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102ca5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102cac:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102cb3:	ba 00 00 00 00       	mov    $0x0,%edx
f0102cb8:	eb 07                	jmp    f0102cc1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cba:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102cbd:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cc1:	8d 47 01             	lea    0x1(%edi),%eax
f0102cc4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102cc7:	0f b6 07             	movzbl (%edi),%eax
f0102cca:	0f b6 c8             	movzbl %al,%ecx
f0102ccd:	83 e8 23             	sub    $0x23,%eax
f0102cd0:	3c 55                	cmp    $0x55,%al
f0102cd2:	0f 87 d5 02 00 00    	ja     f0102fad <vprintfmt+0x345>
f0102cd8:	0f b6 c0             	movzbl %al,%eax
f0102cdb:	ff 24 85 60 4a 10 f0 	jmp    *-0xfefb5a0(,%eax,4)
f0102ce2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102ce5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102ce9:	eb d6                	jmp    f0102cc1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ceb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cee:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cf3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102cf6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102cf9:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102cfd:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102d00:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102d03:	83 fa 09             	cmp    $0x9,%edx
f0102d06:	77 39                	ja     f0102d41 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102d08:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102d0b:	eb e9                	jmp    f0102cf6 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102d0d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d10:	8d 48 04             	lea    0x4(%eax),%ecx
f0102d13:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102d16:	8b 00                	mov    (%eax),%eax
f0102d18:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102d1e:	eb 27                	jmp    f0102d47 <vprintfmt+0xdf>
f0102d20:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102d23:	85 c0                	test   %eax,%eax
f0102d25:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102d2a:	0f 49 c8             	cmovns %eax,%ecx
f0102d2d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d30:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d33:	eb 8c                	jmp    f0102cc1 <vprintfmt+0x59>
f0102d35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102d38:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102d3f:	eb 80                	jmp    f0102cc1 <vprintfmt+0x59>
f0102d41:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102d44:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102d47:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d4b:	0f 89 70 ff ff ff    	jns    f0102cc1 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102d51:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d54:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d57:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102d5e:	e9 5e ff ff ff       	jmp    f0102cc1 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102d63:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d66:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102d69:	e9 53 ff ff ff       	jmp    f0102cc1 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102d6e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d71:	8d 50 04             	lea    0x4(%eax),%edx
f0102d74:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d77:	83 ec 08             	sub    $0x8,%esp
f0102d7a:	53                   	push   %ebx
f0102d7b:	ff 30                	pushl  (%eax)
f0102d7d:	ff d6                	call   *%esi
			break;
f0102d7f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d82:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102d85:	e9 04 ff ff ff       	jmp    f0102c8e <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d8d:	8d 50 04             	lea    0x4(%eax),%edx
f0102d90:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d93:	8b 00                	mov    (%eax),%eax
f0102d95:	99                   	cltd   
f0102d96:	31 d0                	xor    %edx,%eax
f0102d98:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102d9a:	83 f8 06             	cmp    $0x6,%eax
f0102d9d:	7f 0b                	jg     f0102daa <vprintfmt+0x142>
f0102d9f:	8b 14 85 b8 4b 10 f0 	mov    -0xfefb448(,%eax,4),%edx
f0102da6:	85 d2                	test   %edx,%edx
f0102da8:	75 18                	jne    f0102dc2 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102daa:	50                   	push   %eax
f0102dab:	68 ee 49 10 f0       	push   $0xf01049ee
f0102db0:	53                   	push   %ebx
f0102db1:	56                   	push   %esi
f0102db2:	e8 94 fe ff ff       	call   f0102c4b <printfmt>
f0102db7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102dbd:	e9 cc fe ff ff       	jmp    f0102c8e <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102dc2:	52                   	push   %edx
f0102dc3:	68 ff 45 10 f0       	push   $0xf01045ff
f0102dc8:	53                   	push   %ebx
f0102dc9:	56                   	push   %esi
f0102dca:	e8 7c fe ff ff       	call   f0102c4b <printfmt>
f0102dcf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dd2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dd5:	e9 b4 fe ff ff       	jmp    f0102c8e <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102dda:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ddd:	8d 50 04             	lea    0x4(%eax),%edx
f0102de0:	89 55 14             	mov    %edx,0x14(%ebp)
f0102de3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102de5:	85 ff                	test   %edi,%edi
f0102de7:	b8 e7 49 10 f0       	mov    $0xf01049e7,%eax
f0102dec:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102def:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102df3:	0f 8e 94 00 00 00    	jle    f0102e8d <vprintfmt+0x225>
f0102df9:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102dfd:	0f 84 98 00 00 00    	je     f0102e9b <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e03:	83 ec 08             	sub    $0x8,%esp
f0102e06:	ff 75 d0             	pushl  -0x30(%ebp)
f0102e09:	57                   	push   %edi
f0102e0a:	e8 1a 03 00 00       	call   f0103129 <strnlen>
f0102e0f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102e12:	29 c1                	sub    %eax,%ecx
f0102e14:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102e17:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102e1a:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102e1e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102e21:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102e24:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e26:	eb 0f                	jmp    f0102e37 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102e28:	83 ec 08             	sub    $0x8,%esp
f0102e2b:	53                   	push   %ebx
f0102e2c:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e2f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e31:	83 ef 01             	sub    $0x1,%edi
f0102e34:	83 c4 10             	add    $0x10,%esp
f0102e37:	85 ff                	test   %edi,%edi
f0102e39:	7f ed                	jg     f0102e28 <vprintfmt+0x1c0>
f0102e3b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e3e:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102e41:	85 c9                	test   %ecx,%ecx
f0102e43:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e48:	0f 49 c1             	cmovns %ecx,%eax
f0102e4b:	29 c1                	sub    %eax,%ecx
f0102e4d:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e50:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e53:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e56:	89 cb                	mov    %ecx,%ebx
f0102e58:	eb 4d                	jmp    f0102ea7 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102e5a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102e5e:	74 1b                	je     f0102e7b <vprintfmt+0x213>
f0102e60:	0f be c0             	movsbl %al,%eax
f0102e63:	83 e8 20             	sub    $0x20,%eax
f0102e66:	83 f8 5e             	cmp    $0x5e,%eax
f0102e69:	76 10                	jbe    f0102e7b <vprintfmt+0x213>
					putch('?', putdat);
f0102e6b:	83 ec 08             	sub    $0x8,%esp
f0102e6e:	ff 75 0c             	pushl  0xc(%ebp)
f0102e71:	6a 3f                	push   $0x3f
f0102e73:	ff 55 08             	call   *0x8(%ebp)
f0102e76:	83 c4 10             	add    $0x10,%esp
f0102e79:	eb 0d                	jmp    f0102e88 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102e7b:	83 ec 08             	sub    $0x8,%esp
f0102e7e:	ff 75 0c             	pushl  0xc(%ebp)
f0102e81:	52                   	push   %edx
f0102e82:	ff 55 08             	call   *0x8(%ebp)
f0102e85:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102e88:	83 eb 01             	sub    $0x1,%ebx
f0102e8b:	eb 1a                	jmp    f0102ea7 <vprintfmt+0x23f>
f0102e8d:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e90:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e93:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e96:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e99:	eb 0c                	jmp    f0102ea7 <vprintfmt+0x23f>
f0102e9b:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e9e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102ea1:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102ea4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102ea7:	83 c7 01             	add    $0x1,%edi
f0102eaa:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102eae:	0f be d0             	movsbl %al,%edx
f0102eb1:	85 d2                	test   %edx,%edx
f0102eb3:	74 23                	je     f0102ed8 <vprintfmt+0x270>
f0102eb5:	85 f6                	test   %esi,%esi
f0102eb7:	78 a1                	js     f0102e5a <vprintfmt+0x1f2>
f0102eb9:	83 ee 01             	sub    $0x1,%esi
f0102ebc:	79 9c                	jns    f0102e5a <vprintfmt+0x1f2>
f0102ebe:	89 df                	mov    %ebx,%edi
f0102ec0:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ec3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ec6:	eb 18                	jmp    f0102ee0 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102ec8:	83 ec 08             	sub    $0x8,%esp
f0102ecb:	53                   	push   %ebx
f0102ecc:	6a 20                	push   $0x20
f0102ece:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102ed0:	83 ef 01             	sub    $0x1,%edi
f0102ed3:	83 c4 10             	add    $0x10,%esp
f0102ed6:	eb 08                	jmp    f0102ee0 <vprintfmt+0x278>
f0102ed8:	89 df                	mov    %ebx,%edi
f0102eda:	8b 75 08             	mov    0x8(%ebp),%esi
f0102edd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ee0:	85 ff                	test   %edi,%edi
f0102ee2:	7f e4                	jg     f0102ec8 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ee4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ee7:	e9 a2 fd ff ff       	jmp    f0102c8e <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102eec:	8d 45 14             	lea    0x14(%ebp),%eax
f0102eef:	e8 08 fd ff ff       	call   f0102bfc <getint>
f0102ef4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ef7:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102efa:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102eff:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102f03:	79 74                	jns    f0102f79 <vprintfmt+0x311>
				putch('-', putdat);
f0102f05:	83 ec 08             	sub    $0x8,%esp
f0102f08:	53                   	push   %ebx
f0102f09:	6a 2d                	push   $0x2d
f0102f0b:	ff d6                	call   *%esi
				num = -(long long) num;
f0102f0d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102f10:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102f13:	f7 d8                	neg    %eax
f0102f15:	83 d2 00             	adc    $0x0,%edx
f0102f18:	f7 da                	neg    %edx
f0102f1a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102f1d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102f22:	eb 55                	jmp    f0102f79 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102f24:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f27:	e8 96 fc ff ff       	call   f0102bc2 <getuint>
			base = 10;
f0102f2c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102f31:	eb 46                	jmp    f0102f79 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0102f33:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f36:	e8 87 fc ff ff       	call   f0102bc2 <getuint>
			base = 8;
f0102f3b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102f40:	eb 37                	jmp    f0102f79 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0102f42:	83 ec 08             	sub    $0x8,%esp
f0102f45:	53                   	push   %ebx
f0102f46:	6a 30                	push   $0x30
f0102f48:	ff d6                	call   *%esi
			putch('x', putdat);
f0102f4a:	83 c4 08             	add    $0x8,%esp
f0102f4d:	53                   	push   %ebx
f0102f4e:	6a 78                	push   $0x78
f0102f50:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102f52:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f55:	8d 50 04             	lea    0x4(%eax),%edx
f0102f58:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102f5b:	8b 00                	mov    (%eax),%eax
f0102f5d:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102f62:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102f65:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102f6a:	eb 0d                	jmp    f0102f79 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102f6c:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f6f:	e8 4e fc ff ff       	call   f0102bc2 <getuint>
			base = 16;
f0102f74:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f79:	83 ec 0c             	sub    $0xc,%esp
f0102f7c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f80:	57                   	push   %edi
f0102f81:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f84:	51                   	push   %ecx
f0102f85:	52                   	push   %edx
f0102f86:	50                   	push   %eax
f0102f87:	89 da                	mov    %ebx,%edx
f0102f89:	89 f0                	mov    %esi,%eax
f0102f8b:	e8 83 fb ff ff       	call   f0102b13 <printnum>
			break;
f0102f90:	83 c4 20             	add    $0x20,%esp
f0102f93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f96:	e9 f3 fc ff ff       	jmp    f0102c8e <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f9b:	83 ec 08             	sub    $0x8,%esp
f0102f9e:	53                   	push   %ebx
f0102f9f:	51                   	push   %ecx
f0102fa0:	ff d6                	call   *%esi
			break;
f0102fa2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fa5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102fa8:	e9 e1 fc ff ff       	jmp    f0102c8e <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102fad:	83 ec 08             	sub    $0x8,%esp
f0102fb0:	53                   	push   %ebx
f0102fb1:	6a 25                	push   $0x25
f0102fb3:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102fb5:	83 c4 10             	add    $0x10,%esp
f0102fb8:	eb 03                	jmp    f0102fbd <vprintfmt+0x355>
f0102fba:	83 ef 01             	sub    $0x1,%edi
f0102fbd:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102fc1:	75 f7                	jne    f0102fba <vprintfmt+0x352>
f0102fc3:	e9 c6 fc ff ff       	jmp    f0102c8e <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102fc8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fcb:	5b                   	pop    %ebx
f0102fcc:	5e                   	pop    %esi
f0102fcd:	5f                   	pop    %edi
f0102fce:	5d                   	pop    %ebp
f0102fcf:	c3                   	ret    

f0102fd0 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102fd0:	55                   	push   %ebp
f0102fd1:	89 e5                	mov    %esp,%ebp
f0102fd3:	83 ec 18             	sub    $0x18,%esp
f0102fd6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fd9:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102fdc:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102fdf:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102fe3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102fe6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102fed:	85 c0                	test   %eax,%eax
f0102fef:	74 26                	je     f0103017 <vsnprintf+0x47>
f0102ff1:	85 d2                	test   %edx,%edx
f0102ff3:	7e 22                	jle    f0103017 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102ff5:	ff 75 14             	pushl  0x14(%ebp)
f0102ff8:	ff 75 10             	pushl  0x10(%ebp)
f0102ffb:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102ffe:	50                   	push   %eax
f0102fff:	68 2e 2c 10 f0       	push   $0xf0102c2e
f0103004:	e8 5f fc ff ff       	call   f0102c68 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103009:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010300c:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010300f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103012:	83 c4 10             	add    $0x10,%esp
f0103015:	eb 05                	jmp    f010301c <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103017:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010301c:	c9                   	leave  
f010301d:	c3                   	ret    

f010301e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010301e:	55                   	push   %ebp
f010301f:	89 e5                	mov    %esp,%ebp
f0103021:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103024:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103027:	50                   	push   %eax
f0103028:	ff 75 10             	pushl  0x10(%ebp)
f010302b:	ff 75 0c             	pushl  0xc(%ebp)
f010302e:	ff 75 08             	pushl  0x8(%ebp)
f0103031:	e8 9a ff ff ff       	call   f0102fd0 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103036:	c9                   	leave  
f0103037:	c3                   	ret    

f0103038 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103038:	55                   	push   %ebp
f0103039:	89 e5                	mov    %esp,%ebp
f010303b:	57                   	push   %edi
f010303c:	56                   	push   %esi
f010303d:	53                   	push   %ebx
f010303e:	83 ec 0c             	sub    $0xc,%esp
f0103041:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103044:	85 c0                	test   %eax,%eax
f0103046:	74 11                	je     f0103059 <readline+0x21>
		cprintf("%s", prompt);
f0103048:	83 ec 08             	sub    $0x8,%esp
f010304b:	50                   	push   %eax
f010304c:	68 ff 45 10 f0       	push   $0xf01045ff
f0103051:	e8 95 f7 ff ff       	call   f01027eb <cprintf>
f0103056:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103059:	83 ec 0c             	sub    $0xc,%esp
f010305c:	6a 00                	push   $0x0
f010305e:	e8 c3 d6 ff ff       	call   f0100726 <iscons>
f0103063:	89 c7                	mov    %eax,%edi
f0103065:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103068:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010306d:	e8 a3 d6 ff ff       	call   f0100715 <getchar>
f0103072:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103074:	85 c0                	test   %eax,%eax
f0103076:	79 18                	jns    f0103090 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103078:	83 ec 08             	sub    $0x8,%esp
f010307b:	50                   	push   %eax
f010307c:	68 d4 4b 10 f0       	push   $0xf0104bd4
f0103081:	e8 65 f7 ff ff       	call   f01027eb <cprintf>
			return NULL;
f0103086:	83 c4 10             	add    $0x10,%esp
f0103089:	b8 00 00 00 00       	mov    $0x0,%eax
f010308e:	eb 79                	jmp    f0103109 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103090:	83 f8 08             	cmp    $0x8,%eax
f0103093:	0f 94 c2             	sete   %dl
f0103096:	83 f8 7f             	cmp    $0x7f,%eax
f0103099:	0f 94 c0             	sete   %al
f010309c:	08 c2                	or     %al,%dl
f010309e:	74 1a                	je     f01030ba <readline+0x82>
f01030a0:	85 f6                	test   %esi,%esi
f01030a2:	7e 16                	jle    f01030ba <readline+0x82>
			if (echoing)
f01030a4:	85 ff                	test   %edi,%edi
f01030a6:	74 0d                	je     f01030b5 <readline+0x7d>
				cputchar('\b');
f01030a8:	83 ec 0c             	sub    $0xc,%esp
f01030ab:	6a 08                	push   $0x8
f01030ad:	e8 53 d6 ff ff       	call   f0100705 <cputchar>
f01030b2:	83 c4 10             	add    $0x10,%esp
			i--;
f01030b5:	83 ee 01             	sub    $0x1,%esi
f01030b8:	eb b3                	jmp    f010306d <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01030ba:	83 fb 1f             	cmp    $0x1f,%ebx
f01030bd:	7e 23                	jle    f01030e2 <readline+0xaa>
f01030bf:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01030c5:	7f 1b                	jg     f01030e2 <readline+0xaa>
			if (echoing)
f01030c7:	85 ff                	test   %edi,%edi
f01030c9:	74 0c                	je     f01030d7 <readline+0x9f>
				cputchar(c);
f01030cb:	83 ec 0c             	sub    $0xc,%esp
f01030ce:	53                   	push   %ebx
f01030cf:	e8 31 d6 ff ff       	call   f0100705 <cputchar>
f01030d4:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01030d7:	88 9e 40 75 11 f0    	mov    %bl,-0xfee8ac0(%esi)
f01030dd:	8d 76 01             	lea    0x1(%esi),%esi
f01030e0:	eb 8b                	jmp    f010306d <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01030e2:	83 fb 0a             	cmp    $0xa,%ebx
f01030e5:	74 05                	je     f01030ec <readline+0xb4>
f01030e7:	83 fb 0d             	cmp    $0xd,%ebx
f01030ea:	75 81                	jne    f010306d <readline+0x35>
			if (echoing)
f01030ec:	85 ff                	test   %edi,%edi
f01030ee:	74 0d                	je     f01030fd <readline+0xc5>
				cputchar('\n');
f01030f0:	83 ec 0c             	sub    $0xc,%esp
f01030f3:	6a 0a                	push   $0xa
f01030f5:	e8 0b d6 ff ff       	call   f0100705 <cputchar>
f01030fa:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01030fd:	c6 86 40 75 11 f0 00 	movb   $0x0,-0xfee8ac0(%esi)
			return buf;
f0103104:	b8 40 75 11 f0       	mov    $0xf0117540,%eax
		}
	}
}
f0103109:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010310c:	5b                   	pop    %ebx
f010310d:	5e                   	pop    %esi
f010310e:	5f                   	pop    %edi
f010310f:	5d                   	pop    %ebp
f0103110:	c3                   	ret    

f0103111 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103111:	55                   	push   %ebp
f0103112:	89 e5                	mov    %esp,%ebp
f0103114:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103117:	b8 00 00 00 00       	mov    $0x0,%eax
f010311c:	eb 03                	jmp    f0103121 <strlen+0x10>
		n++;
f010311e:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103121:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103125:	75 f7                	jne    f010311e <strlen+0xd>
		n++;
	return n;
}
f0103127:	5d                   	pop    %ebp
f0103128:	c3                   	ret    

f0103129 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103129:	55                   	push   %ebp
f010312a:	89 e5                	mov    %esp,%ebp
f010312c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010312f:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103132:	ba 00 00 00 00       	mov    $0x0,%edx
f0103137:	eb 03                	jmp    f010313c <strnlen+0x13>
		n++;
f0103139:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010313c:	39 c2                	cmp    %eax,%edx
f010313e:	74 08                	je     f0103148 <strnlen+0x1f>
f0103140:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103144:	75 f3                	jne    f0103139 <strnlen+0x10>
f0103146:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103148:	5d                   	pop    %ebp
f0103149:	c3                   	ret    

f010314a <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010314a:	55                   	push   %ebp
f010314b:	89 e5                	mov    %esp,%ebp
f010314d:	53                   	push   %ebx
f010314e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103151:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103154:	89 c2                	mov    %eax,%edx
f0103156:	83 c2 01             	add    $0x1,%edx
f0103159:	83 c1 01             	add    $0x1,%ecx
f010315c:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103160:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103163:	84 db                	test   %bl,%bl
f0103165:	75 ef                	jne    f0103156 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103167:	5b                   	pop    %ebx
f0103168:	5d                   	pop    %ebp
f0103169:	c3                   	ret    

f010316a <strcat>:

char *
strcat(char *dst, const char *src)
{
f010316a:	55                   	push   %ebp
f010316b:	89 e5                	mov    %esp,%ebp
f010316d:	53                   	push   %ebx
f010316e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103171:	53                   	push   %ebx
f0103172:	e8 9a ff ff ff       	call   f0103111 <strlen>
f0103177:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010317a:	ff 75 0c             	pushl  0xc(%ebp)
f010317d:	01 d8                	add    %ebx,%eax
f010317f:	50                   	push   %eax
f0103180:	e8 c5 ff ff ff       	call   f010314a <strcpy>
	return dst;
}
f0103185:	89 d8                	mov    %ebx,%eax
f0103187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010318a:	c9                   	leave  
f010318b:	c3                   	ret    

f010318c <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010318c:	55                   	push   %ebp
f010318d:	89 e5                	mov    %esp,%ebp
f010318f:	56                   	push   %esi
f0103190:	53                   	push   %ebx
f0103191:	8b 75 08             	mov    0x8(%ebp),%esi
f0103194:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103197:	89 f3                	mov    %esi,%ebx
f0103199:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010319c:	89 f2                	mov    %esi,%edx
f010319e:	eb 0f                	jmp    f01031af <strncpy+0x23>
		*dst++ = *src;
f01031a0:	83 c2 01             	add    $0x1,%edx
f01031a3:	0f b6 01             	movzbl (%ecx),%eax
f01031a6:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01031a9:	80 39 01             	cmpb   $0x1,(%ecx)
f01031ac:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01031af:	39 da                	cmp    %ebx,%edx
f01031b1:	75 ed                	jne    f01031a0 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01031b3:	89 f0                	mov    %esi,%eax
f01031b5:	5b                   	pop    %ebx
f01031b6:	5e                   	pop    %esi
f01031b7:	5d                   	pop    %ebp
f01031b8:	c3                   	ret    

f01031b9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01031b9:	55                   	push   %ebp
f01031ba:	89 e5                	mov    %esp,%ebp
f01031bc:	56                   	push   %esi
f01031bd:	53                   	push   %ebx
f01031be:	8b 75 08             	mov    0x8(%ebp),%esi
f01031c1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01031c4:	8b 55 10             	mov    0x10(%ebp),%edx
f01031c7:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01031c9:	85 d2                	test   %edx,%edx
f01031cb:	74 21                	je     f01031ee <strlcpy+0x35>
f01031cd:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01031d1:	89 f2                	mov    %esi,%edx
f01031d3:	eb 09                	jmp    f01031de <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01031d5:	83 c2 01             	add    $0x1,%edx
f01031d8:	83 c1 01             	add    $0x1,%ecx
f01031db:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01031de:	39 c2                	cmp    %eax,%edx
f01031e0:	74 09                	je     f01031eb <strlcpy+0x32>
f01031e2:	0f b6 19             	movzbl (%ecx),%ebx
f01031e5:	84 db                	test   %bl,%bl
f01031e7:	75 ec                	jne    f01031d5 <strlcpy+0x1c>
f01031e9:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01031eb:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01031ee:	29 f0                	sub    %esi,%eax
}
f01031f0:	5b                   	pop    %ebx
f01031f1:	5e                   	pop    %esi
f01031f2:	5d                   	pop    %ebp
f01031f3:	c3                   	ret    

f01031f4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01031f4:	55                   	push   %ebp
f01031f5:	89 e5                	mov    %esp,%ebp
f01031f7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031fa:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01031fd:	eb 06                	jmp    f0103205 <strcmp+0x11>
		p++, q++;
f01031ff:	83 c1 01             	add    $0x1,%ecx
f0103202:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103205:	0f b6 01             	movzbl (%ecx),%eax
f0103208:	84 c0                	test   %al,%al
f010320a:	74 04                	je     f0103210 <strcmp+0x1c>
f010320c:	3a 02                	cmp    (%edx),%al
f010320e:	74 ef                	je     f01031ff <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103210:	0f b6 c0             	movzbl %al,%eax
f0103213:	0f b6 12             	movzbl (%edx),%edx
f0103216:	29 d0                	sub    %edx,%eax
}
f0103218:	5d                   	pop    %ebp
f0103219:	c3                   	ret    

f010321a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010321a:	55                   	push   %ebp
f010321b:	89 e5                	mov    %esp,%ebp
f010321d:	53                   	push   %ebx
f010321e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103221:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103224:	89 c3                	mov    %eax,%ebx
f0103226:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103229:	eb 06                	jmp    f0103231 <strncmp+0x17>
		n--, p++, q++;
f010322b:	83 c0 01             	add    $0x1,%eax
f010322e:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103231:	39 d8                	cmp    %ebx,%eax
f0103233:	74 15                	je     f010324a <strncmp+0x30>
f0103235:	0f b6 08             	movzbl (%eax),%ecx
f0103238:	84 c9                	test   %cl,%cl
f010323a:	74 04                	je     f0103240 <strncmp+0x26>
f010323c:	3a 0a                	cmp    (%edx),%cl
f010323e:	74 eb                	je     f010322b <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103240:	0f b6 00             	movzbl (%eax),%eax
f0103243:	0f b6 12             	movzbl (%edx),%edx
f0103246:	29 d0                	sub    %edx,%eax
f0103248:	eb 05                	jmp    f010324f <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010324a:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010324f:	5b                   	pop    %ebx
f0103250:	5d                   	pop    %ebp
f0103251:	c3                   	ret    

f0103252 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103252:	55                   	push   %ebp
f0103253:	89 e5                	mov    %esp,%ebp
f0103255:	8b 45 08             	mov    0x8(%ebp),%eax
f0103258:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010325c:	eb 07                	jmp    f0103265 <strchr+0x13>
		if (*s == c)
f010325e:	38 ca                	cmp    %cl,%dl
f0103260:	74 0f                	je     f0103271 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103262:	83 c0 01             	add    $0x1,%eax
f0103265:	0f b6 10             	movzbl (%eax),%edx
f0103268:	84 d2                	test   %dl,%dl
f010326a:	75 f2                	jne    f010325e <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010326c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103271:	5d                   	pop    %ebp
f0103272:	c3                   	ret    

f0103273 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103273:	55                   	push   %ebp
f0103274:	89 e5                	mov    %esp,%ebp
f0103276:	8b 45 08             	mov    0x8(%ebp),%eax
f0103279:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010327d:	eb 03                	jmp    f0103282 <strfind+0xf>
f010327f:	83 c0 01             	add    $0x1,%eax
f0103282:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103285:	38 ca                	cmp    %cl,%dl
f0103287:	74 04                	je     f010328d <strfind+0x1a>
f0103289:	84 d2                	test   %dl,%dl
f010328b:	75 f2                	jne    f010327f <strfind+0xc>
			break;
	return (char *) s;
}
f010328d:	5d                   	pop    %ebp
f010328e:	c3                   	ret    

f010328f <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010328f:	55                   	push   %ebp
f0103290:	89 e5                	mov    %esp,%ebp
f0103292:	57                   	push   %edi
f0103293:	56                   	push   %esi
f0103294:	53                   	push   %ebx
f0103295:	8b 55 08             	mov    0x8(%ebp),%edx
f0103298:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f010329b:	85 c9                	test   %ecx,%ecx
f010329d:	74 37                	je     f01032d6 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010329f:	f6 c2 03             	test   $0x3,%dl
f01032a2:	75 2a                	jne    f01032ce <memset+0x3f>
f01032a4:	f6 c1 03             	test   $0x3,%cl
f01032a7:	75 25                	jne    f01032ce <memset+0x3f>
		c &= 0xFF;
f01032a9:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01032ad:	89 df                	mov    %ebx,%edi
f01032af:	c1 e7 08             	shl    $0x8,%edi
f01032b2:	89 de                	mov    %ebx,%esi
f01032b4:	c1 e6 18             	shl    $0x18,%esi
f01032b7:	89 d8                	mov    %ebx,%eax
f01032b9:	c1 e0 10             	shl    $0x10,%eax
f01032bc:	09 f0                	or     %esi,%eax
f01032be:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f01032c0:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01032c3:	89 f8                	mov    %edi,%eax
f01032c5:	09 d8                	or     %ebx,%eax
f01032c7:	89 d7                	mov    %edx,%edi
f01032c9:	fc                   	cld    
f01032ca:	f3 ab                	rep stos %eax,%es:(%edi)
f01032cc:	eb 08                	jmp    f01032d6 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01032ce:	89 d7                	mov    %edx,%edi
f01032d0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032d3:	fc                   	cld    
f01032d4:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f01032d6:	89 d0                	mov    %edx,%eax
f01032d8:	5b                   	pop    %ebx
f01032d9:	5e                   	pop    %esi
f01032da:	5f                   	pop    %edi
f01032db:	5d                   	pop    %ebp
f01032dc:	c3                   	ret    

f01032dd <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01032dd:	55                   	push   %ebp
f01032de:	89 e5                	mov    %esp,%ebp
f01032e0:	57                   	push   %edi
f01032e1:	56                   	push   %esi
f01032e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01032e5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032e8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01032eb:	39 c6                	cmp    %eax,%esi
f01032ed:	73 35                	jae    f0103324 <memmove+0x47>
f01032ef:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01032f2:	39 d0                	cmp    %edx,%eax
f01032f4:	73 2e                	jae    f0103324 <memmove+0x47>
		s += n;
		d += n;
f01032f6:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032f9:	89 d6                	mov    %edx,%esi
f01032fb:	09 fe                	or     %edi,%esi
f01032fd:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103303:	75 13                	jne    f0103318 <memmove+0x3b>
f0103305:	f6 c1 03             	test   $0x3,%cl
f0103308:	75 0e                	jne    f0103318 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f010330a:	83 ef 04             	sub    $0x4,%edi
f010330d:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103310:	c1 e9 02             	shr    $0x2,%ecx
f0103313:	fd                   	std    
f0103314:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103316:	eb 09                	jmp    f0103321 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103318:	83 ef 01             	sub    $0x1,%edi
f010331b:	8d 72 ff             	lea    -0x1(%edx),%esi
f010331e:	fd                   	std    
f010331f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103321:	fc                   	cld    
f0103322:	eb 1d                	jmp    f0103341 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103324:	89 f2                	mov    %esi,%edx
f0103326:	09 c2                	or     %eax,%edx
f0103328:	f6 c2 03             	test   $0x3,%dl
f010332b:	75 0f                	jne    f010333c <memmove+0x5f>
f010332d:	f6 c1 03             	test   $0x3,%cl
f0103330:	75 0a                	jne    f010333c <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103332:	c1 e9 02             	shr    $0x2,%ecx
f0103335:	89 c7                	mov    %eax,%edi
f0103337:	fc                   	cld    
f0103338:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010333a:	eb 05                	jmp    f0103341 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010333c:	89 c7                	mov    %eax,%edi
f010333e:	fc                   	cld    
f010333f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103341:	5e                   	pop    %esi
f0103342:	5f                   	pop    %edi
f0103343:	5d                   	pop    %ebp
f0103344:	c3                   	ret    

f0103345 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103345:	55                   	push   %ebp
f0103346:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103348:	ff 75 10             	pushl  0x10(%ebp)
f010334b:	ff 75 0c             	pushl  0xc(%ebp)
f010334e:	ff 75 08             	pushl  0x8(%ebp)
f0103351:	e8 87 ff ff ff       	call   f01032dd <memmove>
}
f0103356:	c9                   	leave  
f0103357:	c3                   	ret    

f0103358 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103358:	55                   	push   %ebp
f0103359:	89 e5                	mov    %esp,%ebp
f010335b:	56                   	push   %esi
f010335c:	53                   	push   %ebx
f010335d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103360:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103363:	89 c6                	mov    %eax,%esi
f0103365:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103368:	eb 1a                	jmp    f0103384 <memcmp+0x2c>
		if (*s1 != *s2)
f010336a:	0f b6 08             	movzbl (%eax),%ecx
f010336d:	0f b6 1a             	movzbl (%edx),%ebx
f0103370:	38 d9                	cmp    %bl,%cl
f0103372:	74 0a                	je     f010337e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103374:	0f b6 c1             	movzbl %cl,%eax
f0103377:	0f b6 db             	movzbl %bl,%ebx
f010337a:	29 d8                	sub    %ebx,%eax
f010337c:	eb 0f                	jmp    f010338d <memcmp+0x35>
		s1++, s2++;
f010337e:	83 c0 01             	add    $0x1,%eax
f0103381:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103384:	39 f0                	cmp    %esi,%eax
f0103386:	75 e2                	jne    f010336a <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103388:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010338d:	5b                   	pop    %ebx
f010338e:	5e                   	pop    %esi
f010338f:	5d                   	pop    %ebp
f0103390:	c3                   	ret    

f0103391 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103391:	55                   	push   %ebp
f0103392:	89 e5                	mov    %esp,%ebp
f0103394:	53                   	push   %ebx
f0103395:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103398:	89 c1                	mov    %eax,%ecx
f010339a:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010339d:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033a1:	eb 0a                	jmp    f01033ad <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01033a3:	0f b6 10             	movzbl (%eax),%edx
f01033a6:	39 da                	cmp    %ebx,%edx
f01033a8:	74 07                	je     f01033b1 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01033aa:	83 c0 01             	add    $0x1,%eax
f01033ad:	39 c8                	cmp    %ecx,%eax
f01033af:	72 f2                	jb     f01033a3 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01033b1:	5b                   	pop    %ebx
f01033b2:	5d                   	pop    %ebp
f01033b3:	c3                   	ret    

f01033b4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01033b4:	55                   	push   %ebp
f01033b5:	89 e5                	mov    %esp,%ebp
f01033b7:	57                   	push   %edi
f01033b8:	56                   	push   %esi
f01033b9:	53                   	push   %ebx
f01033ba:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01033bd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033c0:	eb 03                	jmp    f01033c5 <strtol+0x11>
		s++;
f01033c2:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01033c5:	0f b6 01             	movzbl (%ecx),%eax
f01033c8:	3c 20                	cmp    $0x20,%al
f01033ca:	74 f6                	je     f01033c2 <strtol+0xe>
f01033cc:	3c 09                	cmp    $0x9,%al
f01033ce:	74 f2                	je     f01033c2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01033d0:	3c 2b                	cmp    $0x2b,%al
f01033d2:	75 0a                	jne    f01033de <strtol+0x2a>
		s++;
f01033d4:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01033d7:	bf 00 00 00 00       	mov    $0x0,%edi
f01033dc:	eb 11                	jmp    f01033ef <strtol+0x3b>
f01033de:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01033e3:	3c 2d                	cmp    $0x2d,%al
f01033e5:	75 08                	jne    f01033ef <strtol+0x3b>
		s++, neg = 1;
f01033e7:	83 c1 01             	add    $0x1,%ecx
f01033ea:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01033ef:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01033f5:	75 15                	jne    f010340c <strtol+0x58>
f01033f7:	80 39 30             	cmpb   $0x30,(%ecx)
f01033fa:	75 10                	jne    f010340c <strtol+0x58>
f01033fc:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103400:	75 7c                	jne    f010347e <strtol+0xca>
		s += 2, base = 16;
f0103402:	83 c1 02             	add    $0x2,%ecx
f0103405:	bb 10 00 00 00       	mov    $0x10,%ebx
f010340a:	eb 16                	jmp    f0103422 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010340c:	85 db                	test   %ebx,%ebx
f010340e:	75 12                	jne    f0103422 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103410:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103415:	80 39 30             	cmpb   $0x30,(%ecx)
f0103418:	75 08                	jne    f0103422 <strtol+0x6e>
		s++, base = 8;
f010341a:	83 c1 01             	add    $0x1,%ecx
f010341d:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0103422:	b8 00 00 00 00       	mov    $0x0,%eax
f0103427:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010342a:	0f b6 11             	movzbl (%ecx),%edx
f010342d:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103430:	89 f3                	mov    %esi,%ebx
f0103432:	80 fb 09             	cmp    $0x9,%bl
f0103435:	77 08                	ja     f010343f <strtol+0x8b>
			dig = *s - '0';
f0103437:	0f be d2             	movsbl %dl,%edx
f010343a:	83 ea 30             	sub    $0x30,%edx
f010343d:	eb 22                	jmp    f0103461 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010343f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103442:	89 f3                	mov    %esi,%ebx
f0103444:	80 fb 19             	cmp    $0x19,%bl
f0103447:	77 08                	ja     f0103451 <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103449:	0f be d2             	movsbl %dl,%edx
f010344c:	83 ea 57             	sub    $0x57,%edx
f010344f:	eb 10                	jmp    f0103461 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103451:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103454:	89 f3                	mov    %esi,%ebx
f0103456:	80 fb 19             	cmp    $0x19,%bl
f0103459:	77 16                	ja     f0103471 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010345b:	0f be d2             	movsbl %dl,%edx
f010345e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103461:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103464:	7d 0b                	jge    f0103471 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103466:	83 c1 01             	add    $0x1,%ecx
f0103469:	0f af 45 10          	imul   0x10(%ebp),%eax
f010346d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010346f:	eb b9                	jmp    f010342a <strtol+0x76>

	if (endptr)
f0103471:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103475:	74 0d                	je     f0103484 <strtol+0xd0>
		*endptr = (char *) s;
f0103477:	8b 75 0c             	mov    0xc(%ebp),%esi
f010347a:	89 0e                	mov    %ecx,(%esi)
f010347c:	eb 06                	jmp    f0103484 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010347e:	85 db                	test   %ebx,%ebx
f0103480:	74 98                	je     f010341a <strtol+0x66>
f0103482:	eb 9e                	jmp    f0103422 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103484:	89 c2                	mov    %eax,%edx
f0103486:	f7 da                	neg    %edx
f0103488:	85 ff                	test   %edi,%edi
f010348a:	0f 45 c2             	cmovne %edx,%eax
}
f010348d:	5b                   	pop    %ebx
f010348e:	5e                   	pop    %esi
f010348f:	5f                   	pop    %edi
f0103490:	5d                   	pop    %ebp
f0103491:	c3                   	ret    
f0103492:	66 90                	xchg   %ax,%ax
f0103494:	66 90                	xchg   %ax,%ax
f0103496:	66 90                	xchg   %ax,%ax
f0103498:	66 90                	xchg   %ax,%ax
f010349a:	66 90                	xchg   %ax,%ax
f010349c:	66 90                	xchg   %ax,%ax
f010349e:	66 90                	xchg   %ax,%ax

f01034a0 <__udivdi3>:
f01034a0:	55                   	push   %ebp
f01034a1:	57                   	push   %edi
f01034a2:	56                   	push   %esi
f01034a3:	53                   	push   %ebx
f01034a4:	83 ec 1c             	sub    $0x1c,%esp
f01034a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01034ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01034af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01034b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034b7:	85 f6                	test   %esi,%esi
f01034b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01034bd:	89 ca                	mov    %ecx,%edx
f01034bf:	89 f8                	mov    %edi,%eax
f01034c1:	75 3d                	jne    f0103500 <__udivdi3+0x60>
f01034c3:	39 cf                	cmp    %ecx,%edi
f01034c5:	0f 87 c5 00 00 00    	ja     f0103590 <__udivdi3+0xf0>
f01034cb:	85 ff                	test   %edi,%edi
f01034cd:	89 fd                	mov    %edi,%ebp
f01034cf:	75 0b                	jne    f01034dc <__udivdi3+0x3c>
f01034d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01034d6:	31 d2                	xor    %edx,%edx
f01034d8:	f7 f7                	div    %edi
f01034da:	89 c5                	mov    %eax,%ebp
f01034dc:	89 c8                	mov    %ecx,%eax
f01034de:	31 d2                	xor    %edx,%edx
f01034e0:	f7 f5                	div    %ebp
f01034e2:	89 c1                	mov    %eax,%ecx
f01034e4:	89 d8                	mov    %ebx,%eax
f01034e6:	89 cf                	mov    %ecx,%edi
f01034e8:	f7 f5                	div    %ebp
f01034ea:	89 c3                	mov    %eax,%ebx
f01034ec:	89 d8                	mov    %ebx,%eax
f01034ee:	89 fa                	mov    %edi,%edx
f01034f0:	83 c4 1c             	add    $0x1c,%esp
f01034f3:	5b                   	pop    %ebx
f01034f4:	5e                   	pop    %esi
f01034f5:	5f                   	pop    %edi
f01034f6:	5d                   	pop    %ebp
f01034f7:	c3                   	ret    
f01034f8:	90                   	nop
f01034f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103500:	39 ce                	cmp    %ecx,%esi
f0103502:	77 74                	ja     f0103578 <__udivdi3+0xd8>
f0103504:	0f bd fe             	bsr    %esi,%edi
f0103507:	83 f7 1f             	xor    $0x1f,%edi
f010350a:	0f 84 98 00 00 00    	je     f01035a8 <__udivdi3+0x108>
f0103510:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103515:	89 f9                	mov    %edi,%ecx
f0103517:	89 c5                	mov    %eax,%ebp
f0103519:	29 fb                	sub    %edi,%ebx
f010351b:	d3 e6                	shl    %cl,%esi
f010351d:	89 d9                	mov    %ebx,%ecx
f010351f:	d3 ed                	shr    %cl,%ebp
f0103521:	89 f9                	mov    %edi,%ecx
f0103523:	d3 e0                	shl    %cl,%eax
f0103525:	09 ee                	or     %ebp,%esi
f0103527:	89 d9                	mov    %ebx,%ecx
f0103529:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010352d:	89 d5                	mov    %edx,%ebp
f010352f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103533:	d3 ed                	shr    %cl,%ebp
f0103535:	89 f9                	mov    %edi,%ecx
f0103537:	d3 e2                	shl    %cl,%edx
f0103539:	89 d9                	mov    %ebx,%ecx
f010353b:	d3 e8                	shr    %cl,%eax
f010353d:	09 c2                	or     %eax,%edx
f010353f:	89 d0                	mov    %edx,%eax
f0103541:	89 ea                	mov    %ebp,%edx
f0103543:	f7 f6                	div    %esi
f0103545:	89 d5                	mov    %edx,%ebp
f0103547:	89 c3                	mov    %eax,%ebx
f0103549:	f7 64 24 0c          	mull   0xc(%esp)
f010354d:	39 d5                	cmp    %edx,%ebp
f010354f:	72 10                	jb     f0103561 <__udivdi3+0xc1>
f0103551:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103555:	89 f9                	mov    %edi,%ecx
f0103557:	d3 e6                	shl    %cl,%esi
f0103559:	39 c6                	cmp    %eax,%esi
f010355b:	73 07                	jae    f0103564 <__udivdi3+0xc4>
f010355d:	39 d5                	cmp    %edx,%ebp
f010355f:	75 03                	jne    f0103564 <__udivdi3+0xc4>
f0103561:	83 eb 01             	sub    $0x1,%ebx
f0103564:	31 ff                	xor    %edi,%edi
f0103566:	89 d8                	mov    %ebx,%eax
f0103568:	89 fa                	mov    %edi,%edx
f010356a:	83 c4 1c             	add    $0x1c,%esp
f010356d:	5b                   	pop    %ebx
f010356e:	5e                   	pop    %esi
f010356f:	5f                   	pop    %edi
f0103570:	5d                   	pop    %ebp
f0103571:	c3                   	ret    
f0103572:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103578:	31 ff                	xor    %edi,%edi
f010357a:	31 db                	xor    %ebx,%ebx
f010357c:	89 d8                	mov    %ebx,%eax
f010357e:	89 fa                	mov    %edi,%edx
f0103580:	83 c4 1c             	add    $0x1c,%esp
f0103583:	5b                   	pop    %ebx
f0103584:	5e                   	pop    %esi
f0103585:	5f                   	pop    %edi
f0103586:	5d                   	pop    %ebp
f0103587:	c3                   	ret    
f0103588:	90                   	nop
f0103589:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103590:	89 d8                	mov    %ebx,%eax
f0103592:	f7 f7                	div    %edi
f0103594:	31 ff                	xor    %edi,%edi
f0103596:	89 c3                	mov    %eax,%ebx
f0103598:	89 d8                	mov    %ebx,%eax
f010359a:	89 fa                	mov    %edi,%edx
f010359c:	83 c4 1c             	add    $0x1c,%esp
f010359f:	5b                   	pop    %ebx
f01035a0:	5e                   	pop    %esi
f01035a1:	5f                   	pop    %edi
f01035a2:	5d                   	pop    %ebp
f01035a3:	c3                   	ret    
f01035a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035a8:	39 ce                	cmp    %ecx,%esi
f01035aa:	72 0c                	jb     f01035b8 <__udivdi3+0x118>
f01035ac:	31 db                	xor    %ebx,%ebx
f01035ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01035b2:	0f 87 34 ff ff ff    	ja     f01034ec <__udivdi3+0x4c>
f01035b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01035bd:	e9 2a ff ff ff       	jmp    f01034ec <__udivdi3+0x4c>
f01035c2:	66 90                	xchg   %ax,%ax
f01035c4:	66 90                	xchg   %ax,%ax
f01035c6:	66 90                	xchg   %ax,%ax
f01035c8:	66 90                	xchg   %ax,%ax
f01035ca:	66 90                	xchg   %ax,%ax
f01035cc:	66 90                	xchg   %ax,%ax
f01035ce:	66 90                	xchg   %ax,%ax

f01035d0 <__umoddi3>:
f01035d0:	55                   	push   %ebp
f01035d1:	57                   	push   %edi
f01035d2:	56                   	push   %esi
f01035d3:	53                   	push   %ebx
f01035d4:	83 ec 1c             	sub    $0x1c,%esp
f01035d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01035db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01035df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01035e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01035e7:	85 d2                	test   %edx,%edx
f01035e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01035ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035f1:	89 f3                	mov    %esi,%ebx
f01035f3:	89 3c 24             	mov    %edi,(%esp)
f01035f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035fa:	75 1c                	jne    f0103618 <__umoddi3+0x48>
f01035fc:	39 f7                	cmp    %esi,%edi
f01035fe:	76 50                	jbe    f0103650 <__umoddi3+0x80>
f0103600:	89 c8                	mov    %ecx,%eax
f0103602:	89 f2                	mov    %esi,%edx
f0103604:	f7 f7                	div    %edi
f0103606:	89 d0                	mov    %edx,%eax
f0103608:	31 d2                	xor    %edx,%edx
f010360a:	83 c4 1c             	add    $0x1c,%esp
f010360d:	5b                   	pop    %ebx
f010360e:	5e                   	pop    %esi
f010360f:	5f                   	pop    %edi
f0103610:	5d                   	pop    %ebp
f0103611:	c3                   	ret    
f0103612:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103618:	39 f2                	cmp    %esi,%edx
f010361a:	89 d0                	mov    %edx,%eax
f010361c:	77 52                	ja     f0103670 <__umoddi3+0xa0>
f010361e:	0f bd ea             	bsr    %edx,%ebp
f0103621:	83 f5 1f             	xor    $0x1f,%ebp
f0103624:	75 5a                	jne    f0103680 <__umoddi3+0xb0>
f0103626:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010362a:	0f 82 e0 00 00 00    	jb     f0103710 <__umoddi3+0x140>
f0103630:	39 0c 24             	cmp    %ecx,(%esp)
f0103633:	0f 86 d7 00 00 00    	jbe    f0103710 <__umoddi3+0x140>
f0103639:	8b 44 24 08          	mov    0x8(%esp),%eax
f010363d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103641:	83 c4 1c             	add    $0x1c,%esp
f0103644:	5b                   	pop    %ebx
f0103645:	5e                   	pop    %esi
f0103646:	5f                   	pop    %edi
f0103647:	5d                   	pop    %ebp
f0103648:	c3                   	ret    
f0103649:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103650:	85 ff                	test   %edi,%edi
f0103652:	89 fd                	mov    %edi,%ebp
f0103654:	75 0b                	jne    f0103661 <__umoddi3+0x91>
f0103656:	b8 01 00 00 00       	mov    $0x1,%eax
f010365b:	31 d2                	xor    %edx,%edx
f010365d:	f7 f7                	div    %edi
f010365f:	89 c5                	mov    %eax,%ebp
f0103661:	89 f0                	mov    %esi,%eax
f0103663:	31 d2                	xor    %edx,%edx
f0103665:	f7 f5                	div    %ebp
f0103667:	89 c8                	mov    %ecx,%eax
f0103669:	f7 f5                	div    %ebp
f010366b:	89 d0                	mov    %edx,%eax
f010366d:	eb 99                	jmp    f0103608 <__umoddi3+0x38>
f010366f:	90                   	nop
f0103670:	89 c8                	mov    %ecx,%eax
f0103672:	89 f2                	mov    %esi,%edx
f0103674:	83 c4 1c             	add    $0x1c,%esp
f0103677:	5b                   	pop    %ebx
f0103678:	5e                   	pop    %esi
f0103679:	5f                   	pop    %edi
f010367a:	5d                   	pop    %ebp
f010367b:	c3                   	ret    
f010367c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103680:	8b 34 24             	mov    (%esp),%esi
f0103683:	bf 20 00 00 00       	mov    $0x20,%edi
f0103688:	89 e9                	mov    %ebp,%ecx
f010368a:	29 ef                	sub    %ebp,%edi
f010368c:	d3 e0                	shl    %cl,%eax
f010368e:	89 f9                	mov    %edi,%ecx
f0103690:	89 f2                	mov    %esi,%edx
f0103692:	d3 ea                	shr    %cl,%edx
f0103694:	89 e9                	mov    %ebp,%ecx
f0103696:	09 c2                	or     %eax,%edx
f0103698:	89 d8                	mov    %ebx,%eax
f010369a:	89 14 24             	mov    %edx,(%esp)
f010369d:	89 f2                	mov    %esi,%edx
f010369f:	d3 e2                	shl    %cl,%edx
f01036a1:	89 f9                	mov    %edi,%ecx
f01036a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01036ab:	d3 e8                	shr    %cl,%eax
f01036ad:	89 e9                	mov    %ebp,%ecx
f01036af:	89 c6                	mov    %eax,%esi
f01036b1:	d3 e3                	shl    %cl,%ebx
f01036b3:	89 f9                	mov    %edi,%ecx
f01036b5:	89 d0                	mov    %edx,%eax
f01036b7:	d3 e8                	shr    %cl,%eax
f01036b9:	89 e9                	mov    %ebp,%ecx
f01036bb:	09 d8                	or     %ebx,%eax
f01036bd:	89 d3                	mov    %edx,%ebx
f01036bf:	89 f2                	mov    %esi,%edx
f01036c1:	f7 34 24             	divl   (%esp)
f01036c4:	89 d6                	mov    %edx,%esi
f01036c6:	d3 e3                	shl    %cl,%ebx
f01036c8:	f7 64 24 04          	mull   0x4(%esp)
f01036cc:	39 d6                	cmp    %edx,%esi
f01036ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036d2:	89 d1                	mov    %edx,%ecx
f01036d4:	89 c3                	mov    %eax,%ebx
f01036d6:	72 08                	jb     f01036e0 <__umoddi3+0x110>
f01036d8:	75 11                	jne    f01036eb <__umoddi3+0x11b>
f01036da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01036de:	73 0b                	jae    f01036eb <__umoddi3+0x11b>
f01036e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01036e4:	1b 14 24             	sbb    (%esp),%edx
f01036e7:	89 d1                	mov    %edx,%ecx
f01036e9:	89 c3                	mov    %eax,%ebx
f01036eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01036ef:	29 da                	sub    %ebx,%edx
f01036f1:	19 ce                	sbb    %ecx,%esi
f01036f3:	89 f9                	mov    %edi,%ecx
f01036f5:	89 f0                	mov    %esi,%eax
f01036f7:	d3 e0                	shl    %cl,%eax
f01036f9:	89 e9                	mov    %ebp,%ecx
f01036fb:	d3 ea                	shr    %cl,%edx
f01036fd:	89 e9                	mov    %ebp,%ecx
f01036ff:	d3 ee                	shr    %cl,%esi
f0103701:	09 d0                	or     %edx,%eax
f0103703:	89 f2                	mov    %esi,%edx
f0103705:	83 c4 1c             	add    $0x1c,%esp
f0103708:	5b                   	pop    %ebx
f0103709:	5e                   	pop    %esi
f010370a:	5f                   	pop    %edi
f010370b:	5d                   	pop    %ebp
f010370c:	c3                   	ret    
f010370d:	8d 76 00             	lea    0x0(%esi),%esi
f0103710:	29 f9                	sub    %edi,%ecx
f0103712:	19 d6                	sbb    %edx,%esi
f0103714:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103718:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010371c:	e9 18 ff ff ff       	jmp    f0103639 <__umoddi3+0x69>
