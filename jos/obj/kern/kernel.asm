
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
f0100058:	e8 3f 30 00 00       	call   f010309c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 78 06 00 00       	call   f01006da <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 35 10 f0       	push   $0xf0103540
f010006f:	e8 84 25 00 00       	call   f01025f8 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 1a 24 00 00       	call   f0102493 <mem_init>
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
f01000b0:	68 7c 35 10 f0       	push   $0xf010357c
f01000b5:	e8 3e 25 00 00       	call   f01025f8 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 0e 25 00 00       	call   f01025d2 <vcprintf>
	cprintf("\n>>>\n");
f01000c4:	c7 04 24 5b 35 10 f0 	movl   $0xf010355b,(%esp)
f01000cb:	e8 28 25 00 00       	call   f01025f8 <cprintf>
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
f01000f2:	68 61 35 10 f0       	push   $0xf0103561
f01000f7:	e8 fc 24 00 00       	call   f01025f8 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 ca 24 00 00       	call   f01025d2 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 22 45 10 f0 	movl   $0xf0104522,(%esp)
f010010f:	e8 e4 24 00 00       	call   f01025f8 <cprintf>
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
f01003f7:	0f b6 80 00 37 10 f0 	movzbl -0xfefc900(%eax),%eax
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
f0100431:	0f b6 90 00 37 10 f0 	movzbl -0xfefc900(%eax),%edx
f0100438:	0b 15 00 73 11 f0    	or     0xf0117300,%edx
f010043e:	0f b6 88 00 36 10 f0 	movzbl -0xfefca00(%eax),%ecx
f0100445:	31 ca                	xor    %ecx,%edx
f0100447:	89 15 00 73 11 f0    	mov    %edx,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010044d:	89 d1                	mov    %edx,%ecx
f010044f:	83 e1 03             	and    $0x3,%ecx
f0100452:	8b 0c 8d e0 35 10 f0 	mov    -0xfefca20(,%ecx,4),%ecx
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
f0100492:	68 9c 35 10 f0       	push   $0xf010359c
f0100497:	e8 5c 21 00 00       	call   f01025f8 <cprintf>
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
f01005ce:	e8 17 2b 00 00       	call   f01030ea <memmove>
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
f01006f6:	68 a8 35 10 f0       	push   $0xf01035a8
f01006fb:	e8 f8 1e 00 00       	call   f01025f8 <cprintf>
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
f0100736:	68 00 38 10 f0       	push   $0xf0103800
f010073b:	68 1e 38 10 f0       	push   $0xf010381e
f0100740:	68 23 38 10 f0       	push   $0xf0103823
f0100745:	e8 ae 1e 00 00       	call   f01025f8 <cprintf>
f010074a:	83 c4 0c             	add    $0xc,%esp
f010074d:	68 c0 38 10 f0       	push   $0xf01038c0
f0100752:	68 2c 38 10 f0       	push   $0xf010382c
f0100757:	68 23 38 10 f0       	push   $0xf0103823
f010075c:	e8 97 1e 00 00       	call   f01025f8 <cprintf>
f0100761:	83 c4 0c             	add    $0xc,%esp
f0100764:	68 35 38 10 f0       	push   $0xf0103835
f0100769:	68 49 38 10 f0       	push   $0xf0103849
f010076e:	68 23 38 10 f0       	push   $0xf0103823
f0100773:	e8 80 1e 00 00       	call   f01025f8 <cprintf>
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
f0100785:	68 53 38 10 f0       	push   $0xf0103853
f010078a:	e8 69 1e 00 00       	call   f01025f8 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010078f:	83 c4 08             	add    $0x8,%esp
f0100792:	68 0c 00 10 00       	push   $0x10000c
f0100797:	68 e8 38 10 f0       	push   $0xf01038e8
f010079c:	e8 57 1e 00 00       	call   f01025f8 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	68 0c 00 10 00       	push   $0x10000c
f01007a9:	68 0c 00 10 f0       	push   $0xf010000c
f01007ae:	68 10 39 10 f0       	push   $0xf0103910
f01007b3:	e8 40 1e 00 00       	call   f01025f8 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007b8:	83 c4 0c             	add    $0xc,%esp
f01007bb:	68 21 35 10 00       	push   $0x103521
f01007c0:	68 21 35 10 f0       	push   $0xf0103521
f01007c5:	68 34 39 10 f0       	push   $0xf0103934
f01007ca:	e8 29 1e 00 00       	call   f01025f8 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cf:	83 c4 0c             	add    $0xc,%esp
f01007d2:	68 00 73 11 00       	push   $0x117300
f01007d7:	68 00 73 11 f0       	push   $0xf0117300
f01007dc:	68 58 39 10 f0       	push   $0xf0103958
f01007e1:	e8 12 1e 00 00       	call   f01025f8 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e6:	83 c4 0c             	add    $0xc,%esp
f01007e9:	68 50 79 11 00       	push   $0x117950
f01007ee:	68 50 79 11 f0       	push   $0xf0117950
f01007f3:	68 7c 39 10 f0       	push   $0xf010397c
f01007f8:	e8 fb 1d 00 00       	call   f01025f8 <cprintf>
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
f010081e:	68 a0 39 10 f0       	push   $0xf01039a0
f0100823:	e8 d0 1d 00 00       	call   f01025f8 <cprintf>
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
f0100853:	68 cc 39 10 f0       	push   $0xf01039cc
f0100858:	e8 9b 1d 00 00       	call   f01025f8 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f010085d:	83 c4 18             	add    $0x18,%esp
f0100860:	57                   	push   %edi
f0100861:	56                   	push   %esi
f0100862:	e8 9b 1e 00 00       	call   f0102702 <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100867:	83 c4 08             	add    $0x8,%esp
f010086a:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010086d:	56                   	push   %esi
f010086e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100871:	ff 75 dc             	pushl  -0x24(%ebp)
f0100874:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100877:	ff 75 d0             	pushl  -0x30(%ebp)
f010087a:	68 6c 38 10 f0       	push   $0xf010386c
f010087f:	e8 74 1d 00 00       	call   f01025f8 <cprintf>
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
f01008ce:	68 83 38 10 f0       	push   $0xf0103883
f01008d3:	e8 87 27 00 00       	call   f010305f <strchr>
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
f01008f0:	68 88 38 10 f0       	push   $0xf0103888
f01008f5:	e8 fe 1c 00 00       	call   f01025f8 <cprintf>
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
f0100921:	68 83 38 10 f0       	push   $0xf0103883
f0100926:	e8 34 27 00 00       	call   f010305f <strchr>
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
f0100950:	ff 34 85 60 3a 10 f0 	pushl  -0xfefc5a0(,%eax,4)
f0100957:	ff 75 a8             	pushl  -0x58(%ebp)
f010095a:	e8 a2 26 00 00       	call   f0103001 <strcmp>
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
f0100974:	ff 14 85 68 3a 10 f0 	call   *-0xfefc598(,%eax,4)
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
f010098e:	68 a5 38 10 f0       	push   $0xf01038a5
f0100993:	e8 60 1c 00 00       	call   f01025f8 <cprintf>
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
f01009b2:	68 00 3a 10 f0       	push   $0xf0103a00
f01009b7:	e8 3c 1c 00 00       	call   f01025f8 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009bc:	c7 04 24 24 3a 10 f0 	movl   $0xf0103a24,(%esp)
f01009c3:	e8 30 1c 00 00       	call   f01025f8 <cprintf>
f01009c8:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009cb:	83 ec 0c             	sub    $0xc,%esp
f01009ce:	68 bb 38 10 f0       	push   $0xf01038bb
f01009d3:	e8 6d 24 00 00       	call   f0102e45 <readline>
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
f0100a2b:	e8 4e 1b 00 00       	call   f010257e <mc146818_read>
f0100a30:	89 c6                	mov    %eax,%esi
f0100a32:	83 c3 01             	add    $0x1,%ebx
f0100a35:	89 1c 24             	mov    %ebx,(%esp)
f0100a38:	e8 41 1b 00 00       	call   f010257e <mc146818_read>
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
f0100a9b:	68 84 3a 10 f0       	push   $0xf0103a84
f0100aa0:	e8 53 1b 00 00       	call   f01025f8 <cprintf>
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
	if ((uint32_t)(nextfree-KERNBASE)>npages*PGSIZE) panic("not enough memory\n");
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
	if ((uint32_t)(nextfree-KERNBASE)>npages*PGSIZE) panic("not enough memory\n");
f0100b05:	68 04 42 10 f0       	push   $0xf0104204
f0100b0a:	6a 6d                	push   $0x6d
f0100b0c:	68 17 42 10 f0       	push   $0xf0104217
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
f0100b2e:	68 c0 3a 10 f0       	push   $0xf0103ac0
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
f0100b52:	ba 54 00 00 00       	mov    $0x54,%edx
f0100b57:	b8 23 42 10 f0       	mov    $0xf0104223,%eax
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
f0100b94:	ba aa 02 00 00       	mov    $0x2aa,%edx
f0100b99:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
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
f0100be2:	68 e4 3a 10 f0       	push   $0xf0103ae4
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
f0100c3c:	ba 7b 02 00 00       	mov    $0x27b,%edx
f0100c41:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
f0100c46:	e8 88 ff ff ff       	call   f0100bd3 <_paddr>
f0100c4b:	01 f0                	add    %esi,%eax
f0100c4d:	39 c7                	cmp    %eax,%edi
f0100c4f:	74 19                	je     f0100c6a <check_kern_pgdir+0x75>
f0100c51:	68 08 3b 10 f0       	push   $0xf0103b08
f0100c56:	68 31 42 10 f0       	push   $0xf0104231
f0100c5b:	68 7b 02 00 00       	push   $0x27b
f0100c60:	68 17 42 10 f0       	push   $0xf0104217
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
f0100c93:	68 3c 3b 10 f0       	push   $0xf0103b3c
f0100c98:	68 31 42 10 f0       	push   $0xf0104231
f0100c9d:	68 80 02 00 00       	push   $0x280
f0100ca2:	68 17 42 10 f0       	push   $0xf0104217
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
f0100ccf:	ba 84 02 00 00       	mov    $0x284,%edx
f0100cd4:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
f0100cd9:	e8 f5 fe ff ff       	call   f0100bd3 <_paddr>
f0100cde:	01 f0                	add    %esi,%eax
f0100ce0:	39 c7                	cmp    %eax,%edi
f0100ce2:	74 19                	je     f0100cfd <check_kern_pgdir+0x108>
f0100ce4:	68 64 3b 10 f0       	push   $0xf0103b64
f0100ce9:	68 31 42 10 f0       	push   $0xf0104231
f0100cee:	68 84 02 00 00       	push   $0x284
f0100cf3:	68 17 42 10 f0       	push   $0xf0104217
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
f0100d1c:	68 ac 3b 10 f0       	push   $0xf0103bac
f0100d21:	68 31 42 10 f0       	push   $0xf0104231
f0100d26:	68 85 02 00 00       	push   $0x285
f0100d2b:	68 17 42 10 f0       	push   $0xf0104217
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
f0100d54:	68 46 42 10 f0       	push   $0xf0104246
f0100d59:	68 31 42 10 f0       	push   $0xf0104231
f0100d5e:	68 8d 02 00 00       	push   $0x28d
f0100d63:	68 17 42 10 f0       	push   $0xf0104217
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
f0100d81:	68 46 42 10 f0       	push   $0xf0104246
f0100d86:	68 31 42 10 f0       	push   $0xf0104231
f0100d8b:	68 91 02 00 00       	push   $0x291
f0100d90:	68 17 42 10 f0       	push   $0xf0104217
f0100d95:	e8 f1 f2 ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0100d9a:	f6 c2 02             	test   $0x2,%dl
f0100d9d:	75 38                	jne    f0100dd7 <check_kern_pgdir+0x1e2>
f0100d9f:	68 57 42 10 f0       	push   $0xf0104257
f0100da4:	68 31 42 10 f0       	push   $0xf0104231
f0100da9:	68 92 02 00 00       	push   $0x292
f0100dae:	68 17 42 10 f0       	push   $0xf0104217
f0100db3:	e8 d3 f2 ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0100db8:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100dbc:	74 19                	je     f0100dd7 <check_kern_pgdir+0x1e2>
f0100dbe:	68 68 42 10 f0       	push   $0xf0104268
f0100dc3:	68 31 42 10 f0       	push   $0xf0104231
f0100dc8:	68 94 02 00 00       	push   $0x294
f0100dcd:	68 17 42 10 f0       	push   $0xf0104217
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
f0100de8:	68 dc 3b 10 f0       	push   $0xf0103bdc
f0100ded:	e8 06 18 00 00       	call   f01025f8 <cprintf>
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
f0100e16:	68 fc 3b 10 f0       	push   $0xf0103bfc
f0100e1b:	68 eb 01 00 00       	push   $0x1eb
f0100e20:	68 17 42 10 f0       	push   $0xf0104217
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
f0100ea1:	e8 f6 21 00 00       	call   f010309c <memset>
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
f0100eeb:	68 76 42 10 f0       	push   $0xf0104276
f0100ef0:	68 31 42 10 f0       	push   $0xf0104231
f0100ef5:	68 05 02 00 00       	push   $0x205
f0100efa:	68 17 42 10 f0       	push   $0xf0104217
f0100eff:	e8 87 f1 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100f04:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100f07:	72 19                	jb     f0100f22 <check_page_free_list+0x125>
f0100f09:	68 82 42 10 f0       	push   $0xf0104282
f0100f0e:	68 31 42 10 f0       	push   $0xf0104231
f0100f13:	68 06 02 00 00       	push   $0x206
f0100f18:	68 17 42 10 f0       	push   $0xf0104217
f0100f1d:	e8 69 f1 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f22:	89 d8                	mov    %ebx,%eax
f0100f24:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100f27:	a8 07                	test   $0x7,%al
f0100f29:	74 19                	je     f0100f44 <check_page_free_list+0x147>
f0100f2b:	68 20 3c 10 f0       	push   $0xf0103c20
f0100f30:	68 31 42 10 f0       	push   $0xf0104231
f0100f35:	68 07 02 00 00       	push   $0x207
f0100f3a:	68 17 42 10 f0       	push   $0xf0104217
f0100f3f:	e8 47 f1 ff ff       	call   f010008b <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100f44:	89 d8                	mov    %ebx,%eax
f0100f46:	e8 c4 fa ff ff       	call   f0100a0f <page2pa>
f0100f4b:	85 c0                	test   %eax,%eax
f0100f4d:	75 19                	jne    f0100f68 <check_page_free_list+0x16b>
f0100f4f:	68 96 42 10 f0       	push   $0xf0104296
f0100f54:	68 31 42 10 f0       	push   $0xf0104231
f0100f59:	68 0a 02 00 00       	push   $0x20a
f0100f5e:	68 17 42 10 f0       	push   $0xf0104217
f0100f63:	e8 23 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f68:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f6d:	75 19                	jne    f0100f88 <check_page_free_list+0x18b>
f0100f6f:	68 a7 42 10 f0       	push   $0xf01042a7
f0100f74:	68 31 42 10 f0       	push   $0xf0104231
f0100f79:	68 0b 02 00 00       	push   $0x20b
f0100f7e:	68 17 42 10 f0       	push   $0xf0104217
f0100f83:	e8 03 f1 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f88:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f8d:	75 19                	jne    f0100fa8 <check_page_free_list+0x1ab>
f0100f8f:	68 54 3c 10 f0       	push   $0xf0103c54
f0100f94:	68 31 42 10 f0       	push   $0xf0104231
f0100f99:	68 0c 02 00 00       	push   $0x20c
f0100f9e:	68 17 42 10 f0       	push   $0xf0104217
f0100fa3:	e8 e3 f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100fa8:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100fad:	75 19                	jne    f0100fc8 <check_page_free_list+0x1cb>
f0100faf:	68 c0 42 10 f0       	push   $0xf01042c0
f0100fb4:	68 31 42 10 f0       	push   $0xf0104231
f0100fb9:	68 0d 02 00 00       	push   $0x20d
f0100fbe:	68 17 42 10 f0       	push   $0xf0104217
f0100fc3:	e8 c3 f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fc8:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100fcd:	76 25                	jbe    f0100ff4 <check_page_free_list+0x1f7>
f0100fcf:	89 d8                	mov    %ebx,%eax
f0100fd1:	e8 6f fb ff ff       	call   f0100b45 <page2kva>
f0100fd6:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100fd9:	76 1e                	jbe    f0100ff9 <check_page_free_list+0x1fc>
f0100fdb:	68 78 3c 10 f0       	push   $0xf0103c78
f0100fe0:	68 31 42 10 f0       	push   $0xf0104231
f0100fe5:	68 0e 02 00 00       	push   $0x20e
f0100fea:	68 17 42 10 f0       	push   $0xf0104217
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
f010100b:	68 da 42 10 f0       	push   $0xf01042da
f0101010:	68 31 42 10 f0       	push   $0xf0104231
f0101015:	68 16 02 00 00       	push   $0x216
f010101a:	68 17 42 10 f0       	push   $0xf0104217
f010101f:	e8 67 f0 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0101024:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0101028:	7f 43                	jg     f010106d <check_page_free_list+0x270>
f010102a:	68 ec 42 10 f0       	push   $0xf01042ec
f010102f:	68 31 42 10 f0       	push   $0xf0104231
f0101034:	68 17 02 00 00       	push   $0x217
f0101039:	68 17 42 10 f0       	push   $0xf0104217
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
	if (PGNUM(pa) >= npages){
f0101075:	c1 e8 0c             	shr    $0xc,%eax
f0101078:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f010107e:	72 38                	jb     f01010b8 <pa2page+0x43>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f0101080:	55                   	push   %ebp
f0101081:	89 e5                	mov    %esp,%ebp
f0101083:	83 ec 10             	sub    $0x10,%esp
	if (PGNUM(pa) >= npages){
		cprintf("PGNUM: %d\n",PGNUM(pa));
f0101086:	50                   	push   %eax
f0101087:	68 fd 42 10 f0       	push   $0xf01042fd
f010108c:	e8 67 15 00 00       	call   f01025f8 <cprintf>
		cprintf("npages %d\n",npages);
f0101091:	83 c4 08             	add    $0x8,%esp
f0101094:	ff 35 44 79 11 f0    	pushl  0xf0117944
f010109a:	68 08 43 10 f0       	push   $0xf0104308
f010109f:	e8 54 15 00 00       	call   f01025f8 <cprintf>
		panic("pa2page called with invalid pa");}
f01010a4:	83 c4 0c             	add    $0xc,%esp
f01010a7:	68 c0 3c 10 f0       	push   $0xf0103cc0
f01010ac:	6a 4d                	push   $0x4d
f01010ae:	68 23 42 10 f0       	push   $0xf0104223
f01010b3:	e8 d3 ef ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f01010b8:	8b 15 4c 79 11 f0    	mov    0xf011794c,%edx
f01010be:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01010c1:	c3                   	ret    

f01010c2 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01010c2:	55                   	push   %ebp
f01010c3:	89 e5                	mov    %esp,%ebp
f01010c5:	56                   	push   %esi
f01010c6:	53                   	push   %ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f01010c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01010cc:	e8 de f9 ff ff       	call   f0100aaf <boot_alloc>
f01010d1:	89 c1                	mov    %eax,%ecx
f01010d3:	ba 06 01 00 00       	mov    $0x106,%edx
f01010d8:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
f01010dd:	e8 f1 fa ff ff       	call   f0100bd3 <_paddr>
f01010e2:	c1 e8 0c             	shr    $0xc,%eax
f01010e5:	8b 35 3c 75 11 f0    	mov    0xf011753c,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f01010eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010f0:	ba 01 00 00 00       	mov    $0x1,%edx
f01010f5:	eb 33                	jmp    f010112a <page_init+0x68>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f01010f7:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f01010fd:	76 04                	jbe    f0101103 <page_init+0x41>
f01010ff:	39 c2                	cmp    %eax,%edx
f0101101:	72 24                	jb     f0101127 <page_init+0x65>
		pages[i].pp_ref = 0;
f0101103:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f010110a:	89 cb                	mov    %ecx,%ebx
f010110c:	03 1d 4c 79 11 f0    	add    0xf011794c,%ebx
f0101112:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0101118:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f010111a:	89 ce                	mov    %ecx,%esi
f010111c:	03 35 4c 79 11 f0    	add    0xf011794c,%esi
f0101122:	b9 01 00 00 00       	mov    $0x1,%ecx
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101127:	83 c2 01             	add    $0x1,%edx
f010112a:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0101130:	72 c5                	jb     f01010f7 <page_init+0x35>
f0101132:	84 c9                	test   %cl,%cl
f0101134:	74 06                	je     f010113c <page_init+0x7a>
f0101136:	89 35 3c 75 11 f0    	mov    %esi,0xf011753c
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f010113c:	5b                   	pop    %ebx
f010113d:	5e                   	pop    %esi
f010113e:	5d                   	pop    %ebp
f010113f:	c3                   	ret    

f0101140 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f0101140:	55                   	push   %ebp
f0101141:	89 e5                	mov    %esp,%ebp
f0101143:	53                   	push   %ebx
f0101144:	83 ec 04             	sub    $0x4,%esp
f0101147:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f010114d:	85 db                	test   %ebx,%ebx
f010114f:	74 2d                	je     f010117e <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f0101151:	8b 03                	mov    (%ebx),%eax
f0101153:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	pag->pp_link = NULL;
f0101158:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f010115e:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101162:	74 1a                	je     f010117e <page_alloc+0x3e>
f0101164:	89 d8                	mov    %ebx,%eax
f0101166:	e8 da f9 ff ff       	call   f0100b45 <page2kva>
f010116b:	83 ec 04             	sub    $0x4,%esp
f010116e:	68 00 10 00 00       	push   $0x1000
f0101173:	6a 00                	push   $0x0
f0101175:	50                   	push   %eax
f0101176:	e8 21 1f 00 00       	call   f010309c <memset>
f010117b:	83 c4 10             	add    $0x10,%esp
	return pag;
}
f010117e:	89 d8                	mov    %ebx,%eax
f0101180:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101183:	c9                   	leave  
f0101184:	c3                   	ret    

f0101185 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101185:	55                   	push   %ebp
f0101186:	89 e5                	mov    %esp,%ebp
f0101188:	83 ec 08             	sub    $0x8,%esp
f010118b:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f010118e:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101193:	74 17                	je     f01011ac <page_free+0x27>
f0101195:	83 ec 04             	sub    $0x4,%esp
f0101198:	68 13 43 10 f0       	push   $0xf0104313
f010119d:	68 2f 01 00 00       	push   $0x12f
f01011a2:	68 17 42 10 f0       	push   $0xf0104217
f01011a7:	e8 df ee ff ff       	call   f010008b <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");//mejorar mensaje?
f01011ac:	83 38 00             	cmpl   $0x0,(%eax)
f01011af:	74 17                	je     f01011c8 <page_free+0x43>
f01011b1:	83 ec 04             	sub    $0x4,%esp
f01011b4:	68 e0 3c 10 f0       	push   $0xf0103ce0
f01011b9:	68 30 01 00 00       	push   $0x130
f01011be:	68 17 42 10 f0       	push   $0xf0104217
f01011c3:	e8 c3 ee ff ff       	call   f010008b <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f01011c8:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f01011ce:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f01011d0:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f01011d5:	c9                   	leave  
f01011d6:	c3                   	ret    

f01011d7 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f01011d7:	55                   	push   %ebp
f01011d8:	89 e5                	mov    %esp,%ebp
f01011da:	57                   	push   %edi
f01011db:	56                   	push   %esi
f01011dc:	53                   	push   %ebx
f01011dd:	83 ec 1c             	sub    $0x1c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011e0:	83 3d 4c 79 11 f0 00 	cmpl   $0x0,0xf011794c
f01011e7:	75 17                	jne    f0101200 <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f01011e9:	83 ec 04             	sub    $0x4,%esp
f01011ec:	68 27 43 10 f0       	push   $0xf0104327
f01011f1:	68 28 02 00 00       	push   $0x228
f01011f6:	68 17 42 10 f0       	push   $0xf0104217
f01011fb:	e8 8b ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101200:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101205:	be 00 00 00 00       	mov    $0x0,%esi
f010120a:	eb 05                	jmp    f0101211 <check_page_alloc+0x3a>
		++nfree;
f010120c:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010120f:	8b 00                	mov    (%eax),%eax
f0101211:	85 c0                	test   %eax,%eax
f0101213:	75 f7                	jne    f010120c <check_page_alloc+0x35>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101215:	83 ec 0c             	sub    $0xc,%esp
f0101218:	6a 00                	push   $0x0
f010121a:	e8 21 ff ff ff       	call   f0101140 <page_alloc>
f010121f:	89 c7                	mov    %eax,%edi
f0101221:	83 c4 10             	add    $0x10,%esp
f0101224:	85 c0                	test   %eax,%eax
f0101226:	75 19                	jne    f0101241 <check_page_alloc+0x6a>
f0101228:	68 42 43 10 f0       	push   $0xf0104342
f010122d:	68 31 42 10 f0       	push   $0xf0104231
f0101232:	68 30 02 00 00       	push   $0x230
f0101237:	68 17 42 10 f0       	push   $0xf0104217
f010123c:	e8 4a ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101241:	83 ec 0c             	sub    $0xc,%esp
f0101244:	6a 00                	push   $0x0
f0101246:	e8 f5 fe ff ff       	call   f0101140 <page_alloc>
f010124b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010124e:	83 c4 10             	add    $0x10,%esp
f0101251:	85 c0                	test   %eax,%eax
f0101253:	75 19                	jne    f010126e <check_page_alloc+0x97>
f0101255:	68 58 43 10 f0       	push   $0xf0104358
f010125a:	68 31 42 10 f0       	push   $0xf0104231
f010125f:	68 31 02 00 00       	push   $0x231
f0101264:	68 17 42 10 f0       	push   $0xf0104217
f0101269:	e8 1d ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010126e:	83 ec 0c             	sub    $0xc,%esp
f0101271:	6a 00                	push   $0x0
f0101273:	e8 c8 fe ff ff       	call   f0101140 <page_alloc>
f0101278:	89 c3                	mov    %eax,%ebx
f010127a:	83 c4 10             	add    $0x10,%esp
f010127d:	85 c0                	test   %eax,%eax
f010127f:	75 19                	jne    f010129a <check_page_alloc+0xc3>
f0101281:	68 6e 43 10 f0       	push   $0xf010436e
f0101286:	68 31 42 10 f0       	push   $0xf0104231
f010128b:	68 32 02 00 00       	push   $0x232
f0101290:	68 17 42 10 f0       	push   $0xf0104217
f0101295:	e8 f1 ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010129a:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f010129d:	75 19                	jne    f01012b8 <check_page_alloc+0xe1>
f010129f:	68 84 43 10 f0       	push   $0xf0104384
f01012a4:	68 31 42 10 f0       	push   $0xf0104231
f01012a9:	68 35 02 00 00       	push   $0x235
f01012ae:	68 17 42 10 f0       	push   $0xf0104217
f01012b3:	e8 d3 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012b8:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01012bb:	74 04                	je     f01012c1 <check_page_alloc+0xea>
f01012bd:	39 c7                	cmp    %eax,%edi
f01012bf:	75 19                	jne    f01012da <check_page_alloc+0x103>
f01012c1:	68 0c 3d 10 f0       	push   $0xf0103d0c
f01012c6:	68 31 42 10 f0       	push   $0xf0104231
f01012cb:	68 36 02 00 00       	push   $0x236
f01012d0:	68 17 42 10 f0       	push   $0xf0104217
f01012d5:	e8 b1 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01012da:	89 f8                	mov    %edi,%eax
f01012dc:	e8 2e f7 ff ff       	call   f0100a0f <page2pa>
f01012e1:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f01012e7:	c1 e1 0c             	shl    $0xc,%ecx
f01012ea:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01012ed:	39 c8                	cmp    %ecx,%eax
f01012ef:	72 19                	jb     f010130a <check_page_alloc+0x133>
f01012f1:	68 96 43 10 f0       	push   $0xf0104396
f01012f6:	68 31 42 10 f0       	push   $0xf0104231
f01012fb:	68 37 02 00 00       	push   $0x237
f0101300:	68 17 42 10 f0       	push   $0xf0104217
f0101305:	e8 81 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010130a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010130d:	e8 fd f6 ff ff       	call   f0100a0f <page2pa>
f0101312:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0101315:	77 19                	ja     f0101330 <check_page_alloc+0x159>
f0101317:	68 b3 43 10 f0       	push   $0xf01043b3
f010131c:	68 31 42 10 f0       	push   $0xf0104231
f0101321:	68 38 02 00 00       	push   $0x238
f0101326:	68 17 42 10 f0       	push   $0xf0104217
f010132b:	e8 5b ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101330:	89 d8                	mov    %ebx,%eax
f0101332:	e8 d8 f6 ff ff       	call   f0100a0f <page2pa>
f0101337:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010133a:	77 19                	ja     f0101355 <check_page_alloc+0x17e>
f010133c:	68 d0 43 10 f0       	push   $0xf01043d0
f0101341:	68 31 42 10 f0       	push   $0xf0104231
f0101346:	68 39 02 00 00       	push   $0x239
f010134b:	68 17 42 10 f0       	push   $0xf0104217
f0101350:	e8 36 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101355:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010135a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f010135d:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101364:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101367:	83 ec 0c             	sub    $0xc,%esp
f010136a:	6a 00                	push   $0x0
f010136c:	e8 cf fd ff ff       	call   f0101140 <page_alloc>
f0101371:	83 c4 10             	add    $0x10,%esp
f0101374:	85 c0                	test   %eax,%eax
f0101376:	74 19                	je     f0101391 <check_page_alloc+0x1ba>
f0101378:	68 ed 43 10 f0       	push   $0xf01043ed
f010137d:	68 31 42 10 f0       	push   $0xf0104231
f0101382:	68 40 02 00 00       	push   $0x240
f0101387:	68 17 42 10 f0       	push   $0xf0104217
f010138c:	e8 fa ec ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101391:	83 ec 0c             	sub    $0xc,%esp
f0101394:	57                   	push   %edi
f0101395:	e8 eb fd ff ff       	call   f0101185 <page_free>
	page_free(pp1);
f010139a:	83 c4 04             	add    $0x4,%esp
f010139d:	ff 75 e4             	pushl  -0x1c(%ebp)
f01013a0:	e8 e0 fd ff ff       	call   f0101185 <page_free>
	page_free(pp2);
f01013a5:	89 1c 24             	mov    %ebx,(%esp)
f01013a8:	e8 d8 fd ff ff       	call   f0101185 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013b4:	e8 87 fd ff ff       	call   f0101140 <page_alloc>
f01013b9:	89 c3                	mov    %eax,%ebx
f01013bb:	83 c4 10             	add    $0x10,%esp
f01013be:	85 c0                	test   %eax,%eax
f01013c0:	75 19                	jne    f01013db <check_page_alloc+0x204>
f01013c2:	68 42 43 10 f0       	push   $0xf0104342
f01013c7:	68 31 42 10 f0       	push   $0xf0104231
f01013cc:	68 47 02 00 00       	push   $0x247
f01013d1:	68 17 42 10 f0       	push   $0xf0104217
f01013d6:	e8 b0 ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013db:	83 ec 0c             	sub    $0xc,%esp
f01013de:	6a 00                	push   $0x0
f01013e0:	e8 5b fd ff ff       	call   f0101140 <page_alloc>
f01013e5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013e8:	83 c4 10             	add    $0x10,%esp
f01013eb:	85 c0                	test   %eax,%eax
f01013ed:	75 19                	jne    f0101408 <check_page_alloc+0x231>
f01013ef:	68 58 43 10 f0       	push   $0xf0104358
f01013f4:	68 31 42 10 f0       	push   $0xf0104231
f01013f9:	68 48 02 00 00       	push   $0x248
f01013fe:	68 17 42 10 f0       	push   $0xf0104217
f0101403:	e8 83 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101408:	83 ec 0c             	sub    $0xc,%esp
f010140b:	6a 00                	push   $0x0
f010140d:	e8 2e fd ff ff       	call   f0101140 <page_alloc>
f0101412:	89 c7                	mov    %eax,%edi
f0101414:	83 c4 10             	add    $0x10,%esp
f0101417:	85 c0                	test   %eax,%eax
f0101419:	75 19                	jne    f0101434 <check_page_alloc+0x25d>
f010141b:	68 6e 43 10 f0       	push   $0xf010436e
f0101420:	68 31 42 10 f0       	push   $0xf0104231
f0101425:	68 49 02 00 00       	push   $0x249
f010142a:	68 17 42 10 f0       	push   $0xf0104217
f010142f:	e8 57 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101434:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101437:	75 19                	jne    f0101452 <check_page_alloc+0x27b>
f0101439:	68 84 43 10 f0       	push   $0xf0104384
f010143e:	68 31 42 10 f0       	push   $0xf0104231
f0101443:	68 4b 02 00 00       	push   $0x24b
f0101448:	68 17 42 10 f0       	push   $0xf0104217
f010144d:	e8 39 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101452:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101455:	74 04                	je     f010145b <check_page_alloc+0x284>
f0101457:	39 c3                	cmp    %eax,%ebx
f0101459:	75 19                	jne    f0101474 <check_page_alloc+0x29d>
f010145b:	68 0c 3d 10 f0       	push   $0xf0103d0c
f0101460:	68 31 42 10 f0       	push   $0xf0104231
f0101465:	68 4c 02 00 00       	push   $0x24c
f010146a:	68 17 42 10 f0       	push   $0xf0104217
f010146f:	e8 17 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101474:	83 ec 0c             	sub    $0xc,%esp
f0101477:	6a 00                	push   $0x0
f0101479:	e8 c2 fc ff ff       	call   f0101140 <page_alloc>
f010147e:	83 c4 10             	add    $0x10,%esp
f0101481:	85 c0                	test   %eax,%eax
f0101483:	74 19                	je     f010149e <check_page_alloc+0x2c7>
f0101485:	68 ed 43 10 f0       	push   $0xf01043ed
f010148a:	68 31 42 10 f0       	push   $0xf0104231
f010148f:	68 4d 02 00 00       	push   $0x24d
f0101494:	68 17 42 10 f0       	push   $0xf0104217
f0101499:	e8 ed eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010149e:	89 d8                	mov    %ebx,%eax
f01014a0:	e8 a0 f6 ff ff       	call   f0100b45 <page2kva>
f01014a5:	83 ec 04             	sub    $0x4,%esp
f01014a8:	68 00 10 00 00       	push   $0x1000
f01014ad:	6a 01                	push   $0x1
f01014af:	50                   	push   %eax
f01014b0:	e8 e7 1b 00 00       	call   f010309c <memset>
	page_free(pp0);
f01014b5:	89 1c 24             	mov    %ebx,(%esp)
f01014b8:	e8 c8 fc ff ff       	call   f0101185 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014bd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014c4:	e8 77 fc ff ff       	call   f0101140 <page_alloc>
f01014c9:	83 c4 10             	add    $0x10,%esp
f01014cc:	85 c0                	test   %eax,%eax
f01014ce:	75 19                	jne    f01014e9 <check_page_alloc+0x312>
f01014d0:	68 fc 43 10 f0       	push   $0xf01043fc
f01014d5:	68 31 42 10 f0       	push   $0xf0104231
f01014da:	68 52 02 00 00       	push   $0x252
f01014df:	68 17 42 10 f0       	push   $0xf0104217
f01014e4:	e8 a2 eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014e9:	39 c3                	cmp    %eax,%ebx
f01014eb:	74 19                	je     f0101506 <check_page_alloc+0x32f>
f01014ed:	68 1a 44 10 f0       	push   $0xf010441a
f01014f2:	68 31 42 10 f0       	push   $0xf0104231
f01014f7:	68 53 02 00 00       	push   $0x253
f01014fc:	68 17 42 10 f0       	push   $0xf0104217
f0101501:	e8 85 eb ff ff       	call   f010008b <_panic>
	c = page2kva(pp);
f0101506:	89 d8                	mov    %ebx,%eax
f0101508:	e8 38 f6 ff ff       	call   f0100b45 <page2kva>
f010150d:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101513:	80 38 00             	cmpb   $0x0,(%eax)
f0101516:	74 19                	je     f0101531 <check_page_alloc+0x35a>
f0101518:	68 2a 44 10 f0       	push   $0xf010442a
f010151d:	68 31 42 10 f0       	push   $0xf0104231
f0101522:	68 56 02 00 00       	push   $0x256
f0101527:	68 17 42 10 f0       	push   $0xf0104217
f010152c:	e8 5a eb ff ff       	call   f010008b <_panic>
f0101531:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101534:	39 d0                	cmp    %edx,%eax
f0101536:	75 db                	jne    f0101513 <check_page_alloc+0x33c>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101538:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010153b:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101540:	83 ec 0c             	sub    $0xc,%esp
f0101543:	53                   	push   %ebx
f0101544:	e8 3c fc ff ff       	call   f0101185 <page_free>
	page_free(pp1);
f0101549:	83 c4 04             	add    $0x4,%esp
f010154c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010154f:	e8 31 fc ff ff       	call   f0101185 <page_free>
	page_free(pp2);
f0101554:	89 3c 24             	mov    %edi,(%esp)
f0101557:	e8 29 fc ff ff       	call   f0101185 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010155c:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101561:	83 c4 10             	add    $0x10,%esp
f0101564:	eb 05                	jmp    f010156b <check_page_alloc+0x394>
		--nfree;
f0101566:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101569:	8b 00                	mov    (%eax),%eax
f010156b:	85 c0                	test   %eax,%eax
f010156d:	75 f7                	jne    f0101566 <check_page_alloc+0x38f>
		--nfree;
	assert(nfree == 0);
f010156f:	85 f6                	test   %esi,%esi
f0101571:	74 19                	je     f010158c <check_page_alloc+0x3b5>
f0101573:	68 34 44 10 f0       	push   $0xf0104434
f0101578:	68 31 42 10 f0       	push   $0xf0104231
f010157d:	68 63 02 00 00       	push   $0x263
f0101582:	68 17 42 10 f0       	push   $0xf0104217
f0101587:	e8 ff ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010158c:	83 ec 0c             	sub    $0xc,%esp
f010158f:	68 2c 3d 10 f0       	push   $0xf0103d2c
f0101594:	e8 5f 10 00 00       	call   f01025f8 <cprintf>
}
f0101599:	83 c4 10             	add    $0x10,%esp
f010159c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010159f:	5b                   	pop    %ebx
f01015a0:	5e                   	pop    %esi
f01015a1:	5f                   	pop    %edi
f01015a2:	5d                   	pop    %ebp
f01015a3:	c3                   	ret    

f01015a4 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01015a4:	55                   	push   %ebp
f01015a5:	89 e5                	mov    %esp,%ebp
f01015a7:	83 ec 08             	sub    $0x8,%esp
f01015aa:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01015ad:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01015b1:	83 e8 01             	sub    $0x1,%eax
f01015b4:	66 89 42 04          	mov    %ax,0x4(%edx)
f01015b8:	66 85 c0             	test   %ax,%ax
f01015bb:	75 0c                	jne    f01015c9 <page_decref+0x25>
		page_free(pp);
f01015bd:	83 ec 0c             	sub    $0xc,%esp
f01015c0:	52                   	push   %edx
f01015c1:	e8 bf fb ff ff       	call   f0101185 <page_free>
f01015c6:	83 c4 10             	add    $0x10,%esp
}
f01015c9:	c9                   	leave  
f01015ca:	c3                   	ret    

f01015cb <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01015cb:	55                   	push   %ebp
f01015cc:	89 e5                	mov    %esp,%ebp
f01015ce:	57                   	push   %edi
f01015cf:	56                   	push   %esi
f01015d0:	53                   	push   %ebx
f01015d1:	83 ec 0c             	sub    $0xc,%esp
f01015d4:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t pde =  pgdir[PDX(va)]; //ojo que esto es P.Addr. !!
f01015d7:	89 f3                	mov    %esi,%ebx
f01015d9:	c1 eb 16             	shr    $0x16,%ebx
f01015dc:	c1 e3 02             	shl    $0x2,%ebx
f01015df:	03 5d 08             	add    0x8(%ebp),%ebx
f01015e2:	8b 3b                	mov    (%ebx),%edi
	pte_t* pte = (pte_t*) KADDR(PTE_ADDR(pde));
f01015e4:	89 f9                	mov    %edi,%ecx
f01015e6:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01015ec:	ba 5b 01 00 00       	mov    $0x15b,%edx
f01015f1:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
f01015f6:	e8 1e f5 ff ff       	call   f0100b19 <_kaddr>

	if (pde & PTE_P) return pte+PTX(va);
f01015fb:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0101601:	74 0d                	je     f0101610 <pgdir_walk+0x45>
f0101603:	c1 ee 0a             	shr    $0xa,%esi
f0101606:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010160c:	01 f0                	add    %esi,%eax
f010160e:	eb 52                	jmp    f0101662 <pgdir_walk+0x97>

	if (!create) return NULL;
f0101610:	b8 00 00 00 00       	mov    $0x0,%eax
f0101615:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101619:	74 47                	je     f0101662 <pgdir_walk+0x97>
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f010161b:	83 ec 0c             	sub    $0xc,%esp
f010161e:	6a 01                	push   $0x1
f0101620:	e8 1b fb ff ff       	call   f0101140 <page_alloc>
f0101625:	89 c7                	mov    %eax,%edi
	if (page==NULL) return NULL;
f0101627:	83 c4 10             	add    $0x10,%esp
f010162a:	85 c0                	test   %eax,%eax
f010162c:	74 2f                	je     f010165d <pgdir_walk+0x92>
	physaddr_t pt_start = page2pa(page);
f010162e:	e8 dc f3 ff ff       	call   f0100a0f <page2pa>
	page->pp_ref ++;
f0101633:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
f0101638:	89 c2                	mov    %eax,%edx
f010163a:	83 ca 07             	or     $0x7,%edx
f010163d:	89 13                	mov    %edx,(%ebx)
	return (pte_t*)KADDR(pt_start)+PTX(va);
f010163f:	89 c1                	mov    %eax,%ecx
f0101641:	ba 65 01 00 00       	mov    $0x165,%edx
f0101646:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
f010164b:	e8 c9 f4 ff ff       	call   f0100b19 <_kaddr>
f0101650:	c1 ee 0a             	shr    $0xa,%esi
f0101653:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101659:	01 f0                	add    %esi,%eax
f010165b:	eb 05                	jmp    f0101662 <pgdir_walk+0x97>

	if (pde & PTE_P) return pte+PTX(va);

	if (!create) return NULL;
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if (page==NULL) return NULL;
f010165d:	b8 00 00 00 00       	mov    $0x0,%eax
	physaddr_t pt_start = page2pa(page);
	page->pp_ref ++;
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
	return (pte_t*)KADDR(pt_start)+PTX(va);
}
f0101662:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101665:	5b                   	pop    %ebx
f0101666:	5e                   	pop    %esi
f0101667:	5f                   	pop    %edi
f0101668:	5d                   	pop    %ebp
f0101669:	c3                   	ret    

f010166a <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010166a:	55                   	push   %ebp
f010166b:	89 e5                	mov    %esp,%ebp
f010166d:	53                   	push   %ebx
f010166e:	83 ec 08             	sub    $0x8,%esp
f0101671:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
f0101674:	6a 00                	push   $0x0
f0101676:	ff 75 0c             	pushl  0xc(%ebp)
f0101679:	ff 75 08             	pushl  0x8(%ebp)
f010167c:	e8 4a ff ff ff       	call   f01015cb <pgdir_walk>
	if (pte_store) *pte_store = pte_addr;
f0101681:	83 c4 10             	add    $0x10,%esp
f0101684:	85 db                	test   %ebx,%ebx
f0101686:	74 02                	je     f010168a <page_lookup+0x20>
f0101688:	89 03                	mov    %eax,(%ebx)
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f010168a:	85 c0                	test   %eax,%eax
f010168c:	74 1a                	je     f01016a8 <page_lookup+0x3e>
	if (!(*pte_addr & PTE_P)) return NULL;
f010168e:	8b 10                	mov    (%eax),%edx
f0101690:	b8 00 00 00 00       	mov    $0x0,%eax
f0101695:	f6 c2 01             	test   $0x1,%dl
f0101698:	74 13                	je     f01016ad <page_lookup+0x43>
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
f010169a:	89 d0                	mov    %edx,%eax
f010169c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01016a1:	e8 cf f9 ff ff       	call   f0101075 <pa2page>
f01016a6:	eb 05                	jmp    f01016ad <page_lookup+0x43>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
	if (pte_store) *pte_store = pte_addr;
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f01016a8:	b8 00 00 00 00       	mov    $0x0,%eax
	if (!(*pte_addr & PTE_P)) return NULL;
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
}
f01016ad:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01016b0:	c9                   	leave  
f01016b1:	c3                   	ret    

f01016b2 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01016b2:	55                   	push   %ebp
f01016b3:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f01016b5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016b8:	e8 32 f3 ff ff       	call   f01009ef <invlpg>
}
f01016bd:	5d                   	pop    %ebp
f01016be:	c3                   	ret    

f01016bf <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01016bf:	55                   	push   %ebp
f01016c0:	89 e5                	mov    %esp,%ebp
f01016c2:	56                   	push   %esi
f01016c3:	53                   	push   %ebx
f01016c4:	83 ec 14             	sub    $0x14,%esp
f01016c7:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016ca:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte_addr;
	struct PageInfo* page_ptr = page_lookup(pgdir,va,&pte_addr);
f01016cd:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01016d0:	50                   	push   %eax
f01016d1:	56                   	push   %esi
f01016d2:	53                   	push   %ebx
f01016d3:	e8 92 ff ff ff       	call   f010166a <page_lookup>
	if (!page_ptr) return;
f01016d8:	83 c4 10             	add    $0x10,%esp
f01016db:	85 c0                	test   %eax,%eax
f01016dd:	74 1f                	je     f01016fe <page_remove+0x3f>
	page_decref(page_ptr);
f01016df:	83 ec 0c             	sub    $0xc,%esp
f01016e2:	50                   	push   %eax
f01016e3:	e8 bc fe ff ff       	call   f01015a4 <page_decref>
	*pte_addr = 0;
f01016e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016eb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);
f01016f1:	83 c4 08             	add    $0x8,%esp
f01016f4:	56                   	push   %esi
f01016f5:	53                   	push   %ebx
f01016f6:	e8 b7 ff ff ff       	call   f01016b2 <tlb_invalidate>
f01016fb:	83 c4 10             	add    $0x10,%esp
}
f01016fe:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101701:	5b                   	pop    %ebx
f0101702:	5e                   	pop    %esi
f0101703:	5d                   	pop    %ebp
f0101704:	c3                   	ret    

f0101705 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101705:	55                   	push   %ebp
f0101706:	89 e5                	mov    %esp,%ebp
f0101708:	57                   	push   %edi
f0101709:	56                   	push   %esi
f010170a:	53                   	push   %ebx
f010170b:	83 ec 10             	sub    $0x10,%esp
f010170e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101711:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
f0101714:	6a 01                	push   $0x1
f0101716:	57                   	push   %edi
f0101717:	ff 75 08             	pushl  0x8(%ebp)
f010171a:	e8 ac fe ff ff       	call   f01015cb <pgdir_walk>
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f010171f:	83 c4 10             	add    $0x10,%esp
f0101722:	85 c0                	test   %eax,%eax
f0101724:	74 33                	je     f0101759 <page_insert+0x54>
f0101726:	89 c6                	mov    %eax,%esi
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
f0101728:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
f010172d:	f6 00 01             	testb  $0x1,(%eax)
f0101730:	74 0f                	je     f0101741 <page_insert+0x3c>
f0101732:	83 ec 08             	sub    $0x8,%esp
f0101735:	57                   	push   %edi
f0101736:	ff 75 08             	pushl  0x8(%ebp)
f0101739:	e8 81 ff ff ff       	call   f01016bf <page_remove>
f010173e:	83 c4 10             	add    $0x10,%esp
	*pte_addr = page2pa(pp) | perm | PTE_P;
f0101741:	89 d8                	mov    %ebx,%eax
f0101743:	e8 c7 f2 ff ff       	call   f0100a0f <page2pa>
f0101748:	8b 55 14             	mov    0x14(%ebp),%edx
f010174b:	83 ca 01             	or     $0x1,%edx
f010174e:	09 d0                	or     %edx,%eax
f0101750:	89 06                	mov    %eax,(%esi)
	return 0;
f0101752:	b8 00 00 00 00       	mov    $0x0,%eax
f0101757:	eb 05                	jmp    f010175e <page_insert+0x59>
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101759:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
	*pte_addr = page2pa(pp) | perm | PTE_P;
	return 0;
}
f010175e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101761:	5b                   	pop    %ebx
f0101762:	5e                   	pop    %esi
f0101763:	5f                   	pop    %edi
f0101764:	5d                   	pop    %ebp
f0101765:	c3                   	ret    

f0101766 <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f0101766:	55                   	push   %ebp
f0101767:	89 e5                	mov    %esp,%ebp
f0101769:	57                   	push   %edi
f010176a:	56                   	push   %esi
f010176b:	53                   	push   %ebx
f010176c:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010176f:	6a 00                	push   $0x0
f0101771:	e8 ca f9 ff ff       	call   f0101140 <page_alloc>
f0101776:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101779:	83 c4 10             	add    $0x10,%esp
f010177c:	85 c0                	test   %eax,%eax
f010177e:	75 19                	jne    f0101799 <check_page+0x33>
f0101780:	68 42 43 10 f0       	push   $0xf0104342
f0101785:	68 31 42 10 f0       	push   $0xf0104231
f010178a:	68 be 02 00 00       	push   $0x2be
f010178f:	68 17 42 10 f0       	push   $0xf0104217
f0101794:	e8 f2 e8 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101799:	83 ec 0c             	sub    $0xc,%esp
f010179c:	6a 00                	push   $0x0
f010179e:	e8 9d f9 ff ff       	call   f0101140 <page_alloc>
f01017a3:	89 c6                	mov    %eax,%esi
f01017a5:	83 c4 10             	add    $0x10,%esp
f01017a8:	85 c0                	test   %eax,%eax
f01017aa:	75 19                	jne    f01017c5 <check_page+0x5f>
f01017ac:	68 58 43 10 f0       	push   $0xf0104358
f01017b1:	68 31 42 10 f0       	push   $0xf0104231
f01017b6:	68 bf 02 00 00       	push   $0x2bf
f01017bb:	68 17 42 10 f0       	push   $0xf0104217
f01017c0:	e8 c6 e8 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01017c5:	83 ec 0c             	sub    $0xc,%esp
f01017c8:	6a 00                	push   $0x0
f01017ca:	e8 71 f9 ff ff       	call   f0101140 <page_alloc>
f01017cf:	89 c3                	mov    %eax,%ebx
f01017d1:	83 c4 10             	add    $0x10,%esp
f01017d4:	85 c0                	test   %eax,%eax
f01017d6:	75 19                	jne    f01017f1 <check_page+0x8b>
f01017d8:	68 6e 43 10 f0       	push   $0xf010436e
f01017dd:	68 31 42 10 f0       	push   $0xf0104231
f01017e2:	68 c0 02 00 00       	push   $0x2c0
f01017e7:	68 17 42 10 f0       	push   $0xf0104217
f01017ec:	e8 9a e8 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017f1:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f01017f4:	75 19                	jne    f010180f <check_page+0xa9>
f01017f6:	68 84 43 10 f0       	push   $0xf0104384
f01017fb:	68 31 42 10 f0       	push   $0xf0104231
f0101800:	68 c3 02 00 00       	push   $0x2c3
f0101805:	68 17 42 10 f0       	push   $0xf0104217
f010180a:	e8 7c e8 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010180f:	39 c6                	cmp    %eax,%esi
f0101811:	74 05                	je     f0101818 <check_page+0xb2>
f0101813:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101816:	75 19                	jne    f0101831 <check_page+0xcb>
f0101818:	68 0c 3d 10 f0       	push   $0xf0103d0c
f010181d:	68 31 42 10 f0       	push   $0xf0104231
f0101822:	68 c4 02 00 00       	push   $0x2c4
f0101827:	68 17 42 10 f0       	push   $0xf0104217
f010182c:	e8 5a e8 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101831:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101836:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101839:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101840:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101843:	83 ec 0c             	sub    $0xc,%esp
f0101846:	6a 00                	push   $0x0
f0101848:	e8 f3 f8 ff ff       	call   f0101140 <page_alloc>
f010184d:	83 c4 10             	add    $0x10,%esp
f0101850:	85 c0                	test   %eax,%eax
f0101852:	74 19                	je     f010186d <check_page+0x107>
f0101854:	68 ed 43 10 f0       	push   $0xf01043ed
f0101859:	68 31 42 10 f0       	push   $0xf0104231
f010185e:	68 cb 02 00 00       	push   $0x2cb
f0101863:	68 17 42 10 f0       	push   $0xf0104217
f0101868:	e8 1e e8 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010186d:	83 ec 04             	sub    $0x4,%esp
f0101870:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101873:	50                   	push   %eax
f0101874:	6a 00                	push   $0x0
f0101876:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010187c:	e8 e9 fd ff ff       	call   f010166a <page_lookup>
f0101881:	83 c4 10             	add    $0x10,%esp
f0101884:	85 c0                	test   %eax,%eax
f0101886:	74 19                	je     f01018a1 <check_page+0x13b>
f0101888:	68 4c 3d 10 f0       	push   $0xf0103d4c
f010188d:	68 31 42 10 f0       	push   $0xf0104231
f0101892:	68 ce 02 00 00       	push   $0x2ce
f0101897:	68 17 42 10 f0       	push   $0xf0104217
f010189c:	e8 ea e7 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01018a1:	6a 02                	push   $0x2
f01018a3:	6a 00                	push   $0x0
f01018a5:	56                   	push   %esi
f01018a6:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018ac:	e8 54 fe ff ff       	call   f0101705 <page_insert>
f01018b1:	83 c4 10             	add    $0x10,%esp
f01018b4:	85 c0                	test   %eax,%eax
f01018b6:	78 19                	js     f01018d1 <check_page+0x16b>
f01018b8:	68 84 3d 10 f0       	push   $0xf0103d84
f01018bd:	68 31 42 10 f0       	push   $0xf0104231
f01018c2:	68 d1 02 00 00       	push   $0x2d1
f01018c7:	68 17 42 10 f0       	push   $0xf0104217
f01018cc:	e8 ba e7 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01018d1:	83 ec 0c             	sub    $0xc,%esp
f01018d4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018d7:	e8 a9 f8 ff ff       	call   f0101185 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01018dc:	6a 02                	push   $0x2
f01018de:	6a 00                	push   $0x0
f01018e0:	56                   	push   %esi
f01018e1:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018e7:	e8 19 fe ff ff       	call   f0101705 <page_insert>
f01018ec:	83 c4 20             	add    $0x20,%esp
f01018ef:	85 c0                	test   %eax,%eax
f01018f1:	74 19                	je     f010190c <check_page+0x1a6>
f01018f3:	68 b4 3d 10 f0       	push   $0xf0103db4
f01018f8:	68 31 42 10 f0       	push   $0xf0104231
f01018fd:	68 d5 02 00 00       	push   $0x2d5
f0101902:	68 17 42 10 f0       	push   $0xf0104217
f0101907:	e8 7f e7 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010190c:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101912:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101915:	e8 f5 f0 ff ff       	call   f0100a0f <page2pa>
f010191a:	8b 17                	mov    (%edi),%edx
f010191c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101922:	39 c2                	cmp    %eax,%edx
f0101924:	74 19                	je     f010193f <check_page+0x1d9>
f0101926:	68 e4 3d 10 f0       	push   $0xf0103de4
f010192b:	68 31 42 10 f0       	push   $0xf0104231
f0101930:	68 d6 02 00 00       	push   $0x2d6
f0101935:	68 17 42 10 f0       	push   $0xf0104217
f010193a:	e8 4c e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010193f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101944:	89 f8                	mov    %edi,%eax
f0101946:	e8 18 f2 ff ff       	call   f0100b63 <check_va2pa>
f010194b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010194e:	89 f0                	mov    %esi,%eax
f0101950:	e8 ba f0 ff ff       	call   f0100a0f <page2pa>
f0101955:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101958:	74 19                	je     f0101973 <check_page+0x20d>
f010195a:	68 0c 3e 10 f0       	push   $0xf0103e0c
f010195f:	68 31 42 10 f0       	push   $0xf0104231
f0101964:	68 d7 02 00 00       	push   $0x2d7
f0101969:	68 17 42 10 f0       	push   $0xf0104217
f010196e:	e8 18 e7 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101973:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101978:	74 19                	je     f0101993 <check_page+0x22d>
f010197a:	68 3f 44 10 f0       	push   $0xf010443f
f010197f:	68 31 42 10 f0       	push   $0xf0104231
f0101984:	68 d8 02 00 00       	push   $0x2d8
f0101989:	68 17 42 10 f0       	push   $0xf0104217
f010198e:	e8 f8 e6 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101993:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101996:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010199b:	74 19                	je     f01019b6 <check_page+0x250>
f010199d:	68 50 44 10 f0       	push   $0xf0104450
f01019a2:	68 31 42 10 f0       	push   $0xf0104231
f01019a7:	68 d9 02 00 00       	push   $0x2d9
f01019ac:	68 17 42 10 f0       	push   $0xf0104217
f01019b1:	e8 d5 e6 ff ff       	call   f010008b <_panic>
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019b6:	6a 02                	push   $0x2
f01019b8:	68 00 10 00 00       	push   $0x1000
f01019bd:	53                   	push   %ebx
f01019be:	57                   	push   %edi
f01019bf:	e8 41 fd ff ff       	call   f0101705 <page_insert>
f01019c4:	83 c4 10             	add    $0x10,%esp
f01019c7:	85 c0                	test   %eax,%eax
f01019c9:	74 19                	je     f01019e4 <check_page+0x27e>
f01019cb:	68 3c 3e 10 f0       	push   $0xf0103e3c
f01019d0:	68 31 42 10 f0       	push   $0xf0104231
f01019d5:	68 db 02 00 00       	push   $0x2db
f01019da:	68 17 42 10 f0       	push   $0xf0104217
f01019df:	e8 a7 e6 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019e4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019e9:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01019ee:	e8 70 f1 ff ff       	call   f0100b63 <check_va2pa>
f01019f3:	89 c7                	mov    %eax,%edi
f01019f5:	89 d8                	mov    %ebx,%eax
f01019f7:	e8 13 f0 ff ff       	call   f0100a0f <page2pa>
f01019fc:	39 c7                	cmp    %eax,%edi
f01019fe:	74 19                	je     f0101a19 <check_page+0x2b3>
f0101a00:	68 78 3e 10 f0       	push   $0xf0103e78
f0101a05:	68 31 42 10 f0       	push   $0xf0104231
f0101a0a:	68 dc 02 00 00       	push   $0x2dc
f0101a0f:	68 17 42 10 f0       	push   $0xf0104217
f0101a14:	e8 72 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101a19:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a1e:	74 19                	je     f0101a39 <check_page+0x2d3>
f0101a20:	68 61 44 10 f0       	push   $0xf0104461
f0101a25:	68 31 42 10 f0       	push   $0xf0104231
f0101a2a:	68 dd 02 00 00       	push   $0x2dd
f0101a2f:	68 17 42 10 f0       	push   $0xf0104217
f0101a34:	e8 52 e6 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101a39:	83 ec 0c             	sub    $0xc,%esp
f0101a3c:	6a 00                	push   $0x0
f0101a3e:	e8 fd f6 ff ff       	call   f0101140 <page_alloc>
f0101a43:	83 c4 10             	add    $0x10,%esp
f0101a46:	85 c0                	test   %eax,%eax
f0101a48:	74 19                	je     f0101a63 <check_page+0x2fd>
f0101a4a:	68 ed 43 10 f0       	push   $0xf01043ed
f0101a4f:	68 31 42 10 f0       	push   $0xf0104231
f0101a54:	68 e0 02 00 00       	push   $0x2e0
f0101a59:	68 17 42 10 f0       	push   $0xf0104217
f0101a5e:	e8 28 e6 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a63:	6a 02                	push   $0x2
f0101a65:	68 00 10 00 00       	push   $0x1000
f0101a6a:	53                   	push   %ebx
f0101a6b:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101a71:	e8 8f fc ff ff       	call   f0101705 <page_insert>
f0101a76:	83 c4 10             	add    $0x10,%esp
f0101a79:	85 c0                	test   %eax,%eax
f0101a7b:	74 19                	je     f0101a96 <check_page+0x330>
f0101a7d:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0101a82:	68 31 42 10 f0       	push   $0xf0104231
f0101a87:	68 e3 02 00 00       	push   $0x2e3
f0101a8c:	68 17 42 10 f0       	push   $0xf0104217
f0101a91:	e8 f5 e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a96:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a9b:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101aa0:	e8 be f0 ff ff       	call   f0100b63 <check_va2pa>
f0101aa5:	89 c7                	mov    %eax,%edi
f0101aa7:	89 d8                	mov    %ebx,%eax
f0101aa9:	e8 61 ef ff ff       	call   f0100a0f <page2pa>
f0101aae:	39 c7                	cmp    %eax,%edi
f0101ab0:	74 19                	je     f0101acb <check_page+0x365>
f0101ab2:	68 78 3e 10 f0       	push   $0xf0103e78
f0101ab7:	68 31 42 10 f0       	push   $0xf0104231
f0101abc:	68 e4 02 00 00       	push   $0x2e4
f0101ac1:	68 17 42 10 f0       	push   $0xf0104217
f0101ac6:	e8 c0 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101acb:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ad0:	74 19                	je     f0101aeb <check_page+0x385>
f0101ad2:	68 61 44 10 f0       	push   $0xf0104461
f0101ad7:	68 31 42 10 f0       	push   $0xf0104231
f0101adc:	68 e5 02 00 00       	push   $0x2e5
f0101ae1:	68 17 42 10 f0       	push   $0xf0104217
f0101ae6:	e8 a0 e5 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101aeb:	83 ec 0c             	sub    $0xc,%esp
f0101aee:	6a 00                	push   $0x0
f0101af0:	e8 4b f6 ff ff       	call   f0101140 <page_alloc>
f0101af5:	83 c4 10             	add    $0x10,%esp
f0101af8:	85 c0                	test   %eax,%eax
f0101afa:	74 19                	je     f0101b15 <check_page+0x3af>
f0101afc:	68 ed 43 10 f0       	push   $0xf01043ed
f0101b01:	68 31 42 10 f0       	push   $0xf0104231
f0101b06:	68 e9 02 00 00       	push   $0x2e9
f0101b0b:	68 17 42 10 f0       	push   $0xf0104217
f0101b10:	e8 76 e5 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b15:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101b1b:	8b 0f                	mov    (%edi),%ecx
f0101b1d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101b23:	ba ec 02 00 00       	mov    $0x2ec,%edx
f0101b28:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
f0101b2d:	e8 e7 ef ff ff       	call   f0100b19 <_kaddr>
f0101b32:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b35:	83 ec 04             	sub    $0x4,%esp
f0101b38:	6a 00                	push   $0x0
f0101b3a:	68 00 10 00 00       	push   $0x1000
f0101b3f:	57                   	push   %edi
f0101b40:	e8 86 fa ff ff       	call   f01015cb <pgdir_walk>
f0101b45:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b48:	8d 51 04             	lea    0x4(%ecx),%edx
f0101b4b:	83 c4 10             	add    $0x10,%esp
f0101b4e:	39 d0                	cmp    %edx,%eax
f0101b50:	74 19                	je     f0101b6b <check_page+0x405>
f0101b52:	68 a8 3e 10 f0       	push   $0xf0103ea8
f0101b57:	68 31 42 10 f0       	push   $0xf0104231
f0101b5c:	68 ed 02 00 00       	push   $0x2ed
f0101b61:	68 17 42 10 f0       	push   $0xf0104217
f0101b66:	e8 20 e5 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b6b:	6a 06                	push   $0x6
f0101b6d:	68 00 10 00 00       	push   $0x1000
f0101b72:	53                   	push   %ebx
f0101b73:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b79:	e8 87 fb ff ff       	call   f0101705 <page_insert>
f0101b7e:	83 c4 10             	add    $0x10,%esp
f0101b81:	85 c0                	test   %eax,%eax
f0101b83:	74 19                	je     f0101b9e <check_page+0x438>
f0101b85:	68 e8 3e 10 f0       	push   $0xf0103ee8
f0101b8a:	68 31 42 10 f0       	push   $0xf0104231
f0101b8f:	68 f0 02 00 00       	push   $0x2f0
f0101b94:	68 17 42 10 f0       	push   $0xf0104217
f0101b99:	e8 ed e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b9e:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101ba4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ba9:	89 f8                	mov    %edi,%eax
f0101bab:	e8 b3 ef ff ff       	call   f0100b63 <check_va2pa>
f0101bb0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101bb3:	89 d8                	mov    %ebx,%eax
f0101bb5:	e8 55 ee ff ff       	call   f0100a0f <page2pa>
f0101bba:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101bbd:	74 19                	je     f0101bd8 <check_page+0x472>
f0101bbf:	68 78 3e 10 f0       	push   $0xf0103e78
f0101bc4:	68 31 42 10 f0       	push   $0xf0104231
f0101bc9:	68 f1 02 00 00       	push   $0x2f1
f0101bce:	68 17 42 10 f0       	push   $0xf0104217
f0101bd3:	e8 b3 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101bd8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101bdd:	74 19                	je     f0101bf8 <check_page+0x492>
f0101bdf:	68 61 44 10 f0       	push   $0xf0104461
f0101be4:	68 31 42 10 f0       	push   $0xf0104231
f0101be9:	68 f2 02 00 00       	push   $0x2f2
f0101bee:	68 17 42 10 f0       	push   $0xf0104217
f0101bf3:	e8 93 e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bf8:	83 ec 04             	sub    $0x4,%esp
f0101bfb:	6a 00                	push   $0x0
f0101bfd:	68 00 10 00 00       	push   $0x1000
f0101c02:	57                   	push   %edi
f0101c03:	e8 c3 f9 ff ff       	call   f01015cb <pgdir_walk>
f0101c08:	83 c4 10             	add    $0x10,%esp
f0101c0b:	f6 00 04             	testb  $0x4,(%eax)
f0101c0e:	75 19                	jne    f0101c29 <check_page+0x4c3>
f0101c10:	68 28 3f 10 f0       	push   $0xf0103f28
f0101c15:	68 31 42 10 f0       	push   $0xf0104231
f0101c1a:	68 f3 02 00 00       	push   $0x2f3
f0101c1f:	68 17 42 10 f0       	push   $0xf0104217
f0101c24:	e8 62 e4 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101c29:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101c2e:	f6 00 04             	testb  $0x4,(%eax)
f0101c31:	75 19                	jne    f0101c4c <check_page+0x4e6>
f0101c33:	68 72 44 10 f0       	push   $0xf0104472
f0101c38:	68 31 42 10 f0       	push   $0xf0104231
f0101c3d:	68 f4 02 00 00       	push   $0x2f4
f0101c42:	68 17 42 10 f0       	push   $0xf0104217
f0101c47:	e8 3f e4 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c4c:	6a 02                	push   $0x2
f0101c4e:	68 00 10 00 00       	push   $0x1000
f0101c53:	53                   	push   %ebx
f0101c54:	50                   	push   %eax
f0101c55:	e8 ab fa ff ff       	call   f0101705 <page_insert>
f0101c5a:	83 c4 10             	add    $0x10,%esp
f0101c5d:	85 c0                	test   %eax,%eax
f0101c5f:	74 19                	je     f0101c7a <check_page+0x514>
f0101c61:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0101c66:	68 31 42 10 f0       	push   $0xf0104231
f0101c6b:	68 f7 02 00 00       	push   $0x2f7
f0101c70:	68 17 42 10 f0       	push   $0xf0104217
f0101c75:	e8 11 e4 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c7a:	83 ec 04             	sub    $0x4,%esp
f0101c7d:	6a 00                	push   $0x0
f0101c7f:	68 00 10 00 00       	push   $0x1000
f0101c84:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101c8a:	e8 3c f9 ff ff       	call   f01015cb <pgdir_walk>
f0101c8f:	83 c4 10             	add    $0x10,%esp
f0101c92:	f6 00 02             	testb  $0x2,(%eax)
f0101c95:	75 19                	jne    f0101cb0 <check_page+0x54a>
f0101c97:	68 5c 3f 10 f0       	push   $0xf0103f5c
f0101c9c:	68 31 42 10 f0       	push   $0xf0104231
f0101ca1:	68 f8 02 00 00       	push   $0x2f8
f0101ca6:	68 17 42 10 f0       	push   $0xf0104217
f0101cab:	e8 db e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cb0:	83 ec 04             	sub    $0x4,%esp
f0101cb3:	6a 00                	push   $0x0
f0101cb5:	68 00 10 00 00       	push   $0x1000
f0101cba:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101cc0:	e8 06 f9 ff ff       	call   f01015cb <pgdir_walk>
f0101cc5:	83 c4 10             	add    $0x10,%esp
f0101cc8:	f6 00 04             	testb  $0x4,(%eax)
f0101ccb:	74 19                	je     f0101ce6 <check_page+0x580>
f0101ccd:	68 90 3f 10 f0       	push   $0xf0103f90
f0101cd2:	68 31 42 10 f0       	push   $0xf0104231
f0101cd7:	68 f9 02 00 00       	push   $0x2f9
f0101cdc:	68 17 42 10 f0       	push   $0xf0104217
f0101ce1:	e8 a5 e3 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ce6:	6a 02                	push   $0x2
f0101ce8:	68 00 00 40 00       	push   $0x400000
f0101ced:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101cf0:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101cf6:	e8 0a fa ff ff       	call   f0101705 <page_insert>
f0101cfb:	83 c4 10             	add    $0x10,%esp
f0101cfe:	85 c0                	test   %eax,%eax
f0101d00:	78 19                	js     f0101d1b <check_page+0x5b5>
f0101d02:	68 c8 3f 10 f0       	push   $0xf0103fc8
f0101d07:	68 31 42 10 f0       	push   $0xf0104231
f0101d0c:	68 fc 02 00 00       	push   $0x2fc
f0101d11:	68 17 42 10 f0       	push   $0xf0104217
f0101d16:	e8 70 e3 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d1b:	6a 02                	push   $0x2
f0101d1d:	68 00 10 00 00       	push   $0x1000
f0101d22:	56                   	push   %esi
f0101d23:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d29:	e8 d7 f9 ff ff       	call   f0101705 <page_insert>
f0101d2e:	83 c4 10             	add    $0x10,%esp
f0101d31:	85 c0                	test   %eax,%eax
f0101d33:	74 19                	je     f0101d4e <check_page+0x5e8>
f0101d35:	68 00 40 10 f0       	push   $0xf0104000
f0101d3a:	68 31 42 10 f0       	push   $0xf0104231
f0101d3f:	68 ff 02 00 00       	push   $0x2ff
f0101d44:	68 17 42 10 f0       	push   $0xf0104217
f0101d49:	e8 3d e3 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d4e:	83 ec 04             	sub    $0x4,%esp
f0101d51:	6a 00                	push   $0x0
f0101d53:	68 00 10 00 00       	push   $0x1000
f0101d58:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d5e:	e8 68 f8 ff ff       	call   f01015cb <pgdir_walk>
f0101d63:	83 c4 10             	add    $0x10,%esp
f0101d66:	f6 00 04             	testb  $0x4,(%eax)
f0101d69:	74 19                	je     f0101d84 <check_page+0x61e>
f0101d6b:	68 90 3f 10 f0       	push   $0xf0103f90
f0101d70:	68 31 42 10 f0       	push   $0xf0104231
f0101d75:	68 00 03 00 00       	push   $0x300
f0101d7a:	68 17 42 10 f0       	push   $0xf0104217
f0101d7f:	e8 07 e3 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d84:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101d8a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d8f:	89 f8                	mov    %edi,%eax
f0101d91:	e8 cd ed ff ff       	call   f0100b63 <check_va2pa>
f0101d96:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101d99:	89 f0                	mov    %esi,%eax
f0101d9b:	e8 6f ec ff ff       	call   f0100a0f <page2pa>
f0101da0:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101da3:	74 19                	je     f0101dbe <check_page+0x658>
f0101da5:	68 3c 40 10 f0       	push   $0xf010403c
f0101daa:	68 31 42 10 f0       	push   $0xf0104231
f0101daf:	68 03 03 00 00       	push   $0x303
f0101db4:	68 17 42 10 f0       	push   $0xf0104217
f0101db9:	e8 cd e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101dbe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dc3:	89 f8                	mov    %edi,%eax
f0101dc5:	e8 99 ed ff ff       	call   f0100b63 <check_va2pa>
f0101dca:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101dcd:	74 19                	je     f0101de8 <check_page+0x682>
f0101dcf:	68 68 40 10 f0       	push   $0xf0104068
f0101dd4:	68 31 42 10 f0       	push   $0xf0104231
f0101dd9:	68 04 03 00 00       	push   $0x304
f0101dde:	68 17 42 10 f0       	push   $0xf0104217
f0101de3:	e8 a3 e2 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101de8:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101ded:	74 19                	je     f0101e08 <check_page+0x6a2>
f0101def:	68 88 44 10 f0       	push   $0xf0104488
f0101df4:	68 31 42 10 f0       	push   $0xf0104231
f0101df9:	68 06 03 00 00       	push   $0x306
f0101dfe:	68 17 42 10 f0       	push   $0xf0104217
f0101e03:	e8 83 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e08:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101e0d:	74 19                	je     f0101e28 <check_page+0x6c2>
f0101e0f:	68 99 44 10 f0       	push   $0xf0104499
f0101e14:	68 31 42 10 f0       	push   $0xf0104231
f0101e19:	68 07 03 00 00       	push   $0x307
f0101e1e:	68 17 42 10 f0       	push   $0xf0104217
f0101e23:	e8 63 e2 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e28:	83 ec 0c             	sub    $0xc,%esp
f0101e2b:	6a 00                	push   $0x0
f0101e2d:	e8 0e f3 ff ff       	call   f0101140 <page_alloc>
f0101e32:	83 c4 10             	add    $0x10,%esp
f0101e35:	39 c3                	cmp    %eax,%ebx
f0101e37:	75 04                	jne    f0101e3d <check_page+0x6d7>
f0101e39:	85 c0                	test   %eax,%eax
f0101e3b:	75 19                	jne    f0101e56 <check_page+0x6f0>
f0101e3d:	68 98 40 10 f0       	push   $0xf0104098
f0101e42:	68 31 42 10 f0       	push   $0xf0104231
f0101e47:	68 0a 03 00 00       	push   $0x30a
f0101e4c:	68 17 42 10 f0       	push   $0xf0104217
f0101e51:	e8 35 e2 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e56:	83 ec 08             	sub    $0x8,%esp
f0101e59:	6a 00                	push   $0x0
f0101e5b:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e61:	e8 59 f8 ff ff       	call   f01016bf <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e66:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101e6c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e71:	89 f8                	mov    %edi,%eax
f0101e73:	e8 eb ec ff ff       	call   f0100b63 <check_va2pa>
f0101e78:	83 c4 10             	add    $0x10,%esp
f0101e7b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e7e:	74 19                	je     f0101e99 <check_page+0x733>
f0101e80:	68 bc 40 10 f0       	push   $0xf01040bc
f0101e85:	68 31 42 10 f0       	push   $0xf0104231
f0101e8a:	68 0e 03 00 00       	push   $0x30e
f0101e8f:	68 17 42 10 f0       	push   $0xf0104217
f0101e94:	e8 f2 e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e99:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e9e:	89 f8                	mov    %edi,%eax
f0101ea0:	e8 be ec ff ff       	call   f0100b63 <check_va2pa>
f0101ea5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ea8:	89 f0                	mov    %esi,%eax
f0101eaa:	e8 60 eb ff ff       	call   f0100a0f <page2pa>
f0101eaf:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101eb2:	74 19                	je     f0101ecd <check_page+0x767>
f0101eb4:	68 68 40 10 f0       	push   $0xf0104068
f0101eb9:	68 31 42 10 f0       	push   $0xf0104231
f0101ebe:	68 0f 03 00 00       	push   $0x30f
f0101ec3:	68 17 42 10 f0       	push   $0xf0104217
f0101ec8:	e8 be e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101ecd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ed2:	74 19                	je     f0101eed <check_page+0x787>
f0101ed4:	68 3f 44 10 f0       	push   $0xf010443f
f0101ed9:	68 31 42 10 f0       	push   $0xf0104231
f0101ede:	68 10 03 00 00       	push   $0x310
f0101ee3:	68 17 42 10 f0       	push   $0xf0104217
f0101ee8:	e8 9e e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101eed:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ef2:	74 19                	je     f0101f0d <check_page+0x7a7>
f0101ef4:	68 99 44 10 f0       	push   $0xf0104499
f0101ef9:	68 31 42 10 f0       	push   $0xf0104231
f0101efe:	68 11 03 00 00       	push   $0x311
f0101f03:	68 17 42 10 f0       	push   $0xf0104217
f0101f08:	e8 7e e1 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f0d:	6a 00                	push   $0x0
f0101f0f:	68 00 10 00 00       	push   $0x1000
f0101f14:	56                   	push   %esi
f0101f15:	57                   	push   %edi
f0101f16:	e8 ea f7 ff ff       	call   f0101705 <page_insert>
f0101f1b:	83 c4 10             	add    $0x10,%esp
f0101f1e:	85 c0                	test   %eax,%eax
f0101f20:	74 19                	je     f0101f3b <check_page+0x7d5>
f0101f22:	68 e0 40 10 f0       	push   $0xf01040e0
f0101f27:	68 31 42 10 f0       	push   $0xf0104231
f0101f2c:	68 14 03 00 00       	push   $0x314
f0101f31:	68 17 42 10 f0       	push   $0xf0104217
f0101f36:	e8 50 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101f3b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f40:	75 19                	jne    f0101f5b <check_page+0x7f5>
f0101f42:	68 aa 44 10 f0       	push   $0xf01044aa
f0101f47:	68 31 42 10 f0       	push   $0xf0104231
f0101f4c:	68 15 03 00 00       	push   $0x315
f0101f51:	68 17 42 10 f0       	push   $0xf0104217
f0101f56:	e8 30 e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101f5b:	83 3e 00             	cmpl   $0x0,(%esi)
f0101f5e:	74 19                	je     f0101f79 <check_page+0x813>
f0101f60:	68 b6 44 10 f0       	push   $0xf01044b6
f0101f65:	68 31 42 10 f0       	push   $0xf0104231
f0101f6a:	68 16 03 00 00       	push   $0x316
f0101f6f:	68 17 42 10 f0       	push   $0xf0104217
f0101f74:	e8 12 e1 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f79:	83 ec 08             	sub    $0x8,%esp
f0101f7c:	68 00 10 00 00       	push   $0x1000
f0101f81:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101f87:	e8 33 f7 ff ff       	call   f01016bf <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f8c:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101f92:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f97:	89 f8                	mov    %edi,%eax
f0101f99:	e8 c5 eb ff ff       	call   f0100b63 <check_va2pa>
f0101f9e:	83 c4 10             	add    $0x10,%esp
f0101fa1:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fa4:	74 19                	je     f0101fbf <check_page+0x859>
f0101fa6:	68 bc 40 10 f0       	push   $0xf01040bc
f0101fab:	68 31 42 10 f0       	push   $0xf0104231
f0101fb0:	68 1a 03 00 00       	push   $0x31a
f0101fb5:	68 17 42 10 f0       	push   $0xf0104217
f0101fba:	e8 cc e0 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101fbf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fc4:	89 f8                	mov    %edi,%eax
f0101fc6:	e8 98 eb ff ff       	call   f0100b63 <check_va2pa>
f0101fcb:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fce:	74 19                	je     f0101fe9 <check_page+0x883>
f0101fd0:	68 18 41 10 f0       	push   $0xf0104118
f0101fd5:	68 31 42 10 f0       	push   $0xf0104231
f0101fda:	68 1b 03 00 00       	push   $0x31b
f0101fdf:	68 17 42 10 f0       	push   $0xf0104217
f0101fe4:	e8 a2 e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101fe9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fee:	74 19                	je     f0102009 <check_page+0x8a3>
f0101ff0:	68 cb 44 10 f0       	push   $0xf01044cb
f0101ff5:	68 31 42 10 f0       	push   $0xf0104231
f0101ffa:	68 1c 03 00 00       	push   $0x31c
f0101fff:	68 17 42 10 f0       	push   $0xf0104217
f0102004:	e8 82 e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0102009:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010200e:	74 19                	je     f0102029 <check_page+0x8c3>
f0102010:	68 99 44 10 f0       	push   $0xf0104499
f0102015:	68 31 42 10 f0       	push   $0xf0104231
f010201a:	68 1d 03 00 00       	push   $0x31d
f010201f:	68 17 42 10 f0       	push   $0xf0104217
f0102024:	e8 62 e0 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102029:	83 ec 0c             	sub    $0xc,%esp
f010202c:	6a 00                	push   $0x0
f010202e:	e8 0d f1 ff ff       	call   f0101140 <page_alloc>
f0102033:	83 c4 10             	add    $0x10,%esp
f0102036:	39 c6                	cmp    %eax,%esi
f0102038:	75 04                	jne    f010203e <check_page+0x8d8>
f010203a:	85 c0                	test   %eax,%eax
f010203c:	75 19                	jne    f0102057 <check_page+0x8f1>
f010203e:	68 40 41 10 f0       	push   $0xf0104140
f0102043:	68 31 42 10 f0       	push   $0xf0104231
f0102048:	68 20 03 00 00       	push   $0x320
f010204d:	68 17 42 10 f0       	push   $0xf0104217
f0102052:	e8 34 e0 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102057:	83 ec 0c             	sub    $0xc,%esp
f010205a:	6a 00                	push   $0x0
f010205c:	e8 df f0 ff ff       	call   f0101140 <page_alloc>
f0102061:	83 c4 10             	add    $0x10,%esp
f0102064:	85 c0                	test   %eax,%eax
f0102066:	74 19                	je     f0102081 <check_page+0x91b>
f0102068:	68 ed 43 10 f0       	push   $0xf01043ed
f010206d:	68 31 42 10 f0       	push   $0xf0104231
f0102072:	68 23 03 00 00       	push   $0x323
f0102077:	68 17 42 10 f0       	push   $0xf0104217
f010207c:	e8 0a e0 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102081:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0102087:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010208a:	e8 80 e9 ff ff       	call   f0100a0f <page2pa>
f010208f:	8b 17                	mov    (%edi),%edx
f0102091:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102097:	39 c2                	cmp    %eax,%edx
f0102099:	74 19                	je     f01020b4 <check_page+0x94e>
f010209b:	68 e4 3d 10 f0       	push   $0xf0103de4
f01020a0:	68 31 42 10 f0       	push   $0xf0104231
f01020a5:	68 26 03 00 00       	push   $0x326
f01020aa:	68 17 42 10 f0       	push   $0xf0104217
f01020af:	e8 d7 df ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01020b4:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	assert(pp0->pp_ref == 1);
f01020ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020bd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020c2:	74 19                	je     f01020dd <check_page+0x977>
f01020c4:	68 50 44 10 f0       	push   $0xf0104450
f01020c9:	68 31 42 10 f0       	push   $0xf0104231
f01020ce:	68 28 03 00 00       	push   $0x328
f01020d3:	68 17 42 10 f0       	push   $0xf0104217
f01020d8:	e8 ae df ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01020dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020e6:	83 ec 0c             	sub    $0xc,%esp
f01020e9:	50                   	push   %eax
f01020ea:	e8 96 f0 ff ff       	call   f0101185 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020ef:	83 c4 0c             	add    $0xc,%esp
f01020f2:	6a 01                	push   $0x1
f01020f4:	68 00 10 40 00       	push   $0x401000
f01020f9:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01020ff:	e8 c7 f4 ff ff       	call   f01015cb <pgdir_walk>
f0102104:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102107:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010210a:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0102110:	8b 4f 04             	mov    0x4(%edi),%ecx
f0102113:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102119:	ba 2f 03 00 00       	mov    $0x32f,%edx
f010211e:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
f0102123:	e8 f1 e9 ff ff       	call   f0100b19 <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f0102128:	83 c0 04             	add    $0x4,%eax
f010212b:	83 c4 10             	add    $0x10,%esp
f010212e:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102131:	74 19                	je     f010214c <check_page+0x9e6>
f0102133:	68 dc 44 10 f0       	push   $0xf01044dc
f0102138:	68 31 42 10 f0       	push   $0xf0104231
f010213d:	68 30 03 00 00       	push   $0x330
f0102142:	68 17 42 10 f0       	push   $0xf0104217
f0102147:	e8 3f df ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f010214c:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f0102153:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102156:	89 f8                	mov    %edi,%eax
f0102158:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010215e:	e8 e2 e9 ff ff       	call   f0100b45 <page2kva>
f0102163:	83 ec 04             	sub    $0x4,%esp
f0102166:	68 00 10 00 00       	push   $0x1000
f010216b:	68 ff 00 00 00       	push   $0xff
f0102170:	50                   	push   %eax
f0102171:	e8 26 0f 00 00       	call   f010309c <memset>
	page_free(pp0);
f0102176:	89 3c 24             	mov    %edi,(%esp)
f0102179:	e8 07 f0 ff ff       	call   f0101185 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010217e:	83 c4 0c             	add    $0xc,%esp
f0102181:	6a 01                	push   $0x1
f0102183:	6a 00                	push   $0x0
f0102185:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010218b:	e8 3b f4 ff ff       	call   f01015cb <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f0102190:	89 f8                	mov    %edi,%eax
f0102192:	e8 ae e9 ff ff       	call   f0100b45 <page2kva>
f0102197:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010219a:	89 c2                	mov    %eax,%edx
f010219c:	05 00 10 00 00       	add    $0x1000,%eax
f01021a1:	83 c4 10             	add    $0x10,%esp
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021a4:	f6 02 01             	testb  $0x1,(%edx)
f01021a7:	74 19                	je     f01021c2 <check_page+0xa5c>
f01021a9:	68 f4 44 10 f0       	push   $0xf01044f4
f01021ae:	68 31 42 10 f0       	push   $0xf0104231
f01021b3:	68 3a 03 00 00       	push   $0x33a
f01021b8:	68 17 42 10 f0       	push   $0xf0104217
f01021bd:	e8 c9 de ff ff       	call   f010008b <_panic>
f01021c2:	83 c2 04             	add    $0x4,%edx
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01021c5:	39 c2                	cmp    %eax,%edx
f01021c7:	75 db                	jne    f01021a4 <check_page+0xa3e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01021c9:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01021ce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021d4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021d7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01021dd:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01021e0:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f01021e6:	83 ec 0c             	sub    $0xc,%esp
f01021e9:	50                   	push   %eax
f01021ea:	e8 96 ef ff ff       	call   f0101185 <page_free>
	page_free(pp1);
f01021ef:	89 34 24             	mov    %esi,(%esp)
f01021f2:	e8 8e ef ff ff       	call   f0101185 <page_free>
	page_free(pp2);
f01021f7:	89 1c 24             	mov    %ebx,(%esp)
f01021fa:	e8 86 ef ff ff       	call   f0101185 <page_free>

	cprintf("check_page() succeeded!\n");
f01021ff:	c7 04 24 0b 45 10 f0 	movl   $0xf010450b,(%esp)
f0102206:	e8 ed 03 00 00       	call   f01025f8 <cprintf>
}
f010220b:	83 c4 10             	add    $0x10,%esp
f010220e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102211:	5b                   	pop    %ebx
f0102212:	5e                   	pop    %esi
f0102213:	5f                   	pop    %edi
f0102214:	5d                   	pop    %ebp
f0102215:	c3                   	ret    

f0102216 <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f0102216:	55                   	push   %ebp
f0102217:	89 e5                	mov    %esp,%ebp
f0102219:	57                   	push   %edi
f010221a:	56                   	push   %esi
f010221b:	53                   	push   %ebx
f010221c:	83 ec 18             	sub    $0x18,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010221f:	6a 00                	push   $0x0
f0102221:	e8 1a ef ff ff       	call   f0101140 <page_alloc>
f0102226:	83 c4 10             	add    $0x10,%esp
f0102229:	85 c0                	test   %eax,%eax
f010222b:	75 19                	jne    f0102246 <check_page_installed_pgdir+0x30>
f010222d:	68 42 43 10 f0       	push   $0xf0104342
f0102232:	68 31 42 10 f0       	push   $0xf0104231
f0102237:	68 55 03 00 00       	push   $0x355
f010223c:	68 17 42 10 f0       	push   $0xf0104217
f0102241:	e8 45 de ff ff       	call   f010008b <_panic>
f0102246:	89 c6                	mov    %eax,%esi
	assert((pp1 = page_alloc(0)));
f0102248:	83 ec 0c             	sub    $0xc,%esp
f010224b:	6a 00                	push   $0x0
f010224d:	e8 ee ee ff ff       	call   f0101140 <page_alloc>
f0102252:	89 c7                	mov    %eax,%edi
f0102254:	83 c4 10             	add    $0x10,%esp
f0102257:	85 c0                	test   %eax,%eax
f0102259:	75 19                	jne    f0102274 <check_page_installed_pgdir+0x5e>
f010225b:	68 58 43 10 f0       	push   $0xf0104358
f0102260:	68 31 42 10 f0       	push   $0xf0104231
f0102265:	68 56 03 00 00       	push   $0x356
f010226a:	68 17 42 10 f0       	push   $0xf0104217
f010226f:	e8 17 de ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0102274:	83 ec 0c             	sub    $0xc,%esp
f0102277:	6a 00                	push   $0x0
f0102279:	e8 c2 ee ff ff       	call   f0101140 <page_alloc>
f010227e:	89 c3                	mov    %eax,%ebx
f0102280:	83 c4 10             	add    $0x10,%esp
f0102283:	85 c0                	test   %eax,%eax
f0102285:	75 19                	jne    f01022a0 <check_page_installed_pgdir+0x8a>
f0102287:	68 6e 43 10 f0       	push   $0xf010436e
f010228c:	68 31 42 10 f0       	push   $0xf0104231
f0102291:	68 57 03 00 00       	push   $0x357
f0102296:	68 17 42 10 f0       	push   $0xf0104217
f010229b:	e8 eb dd ff ff       	call   f010008b <_panic>
	page_free(pp0);
f01022a0:	83 ec 0c             	sub    $0xc,%esp
f01022a3:	56                   	push   %esi
f01022a4:	e8 dc ee ff ff       	call   f0101185 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01022a9:	89 f8                	mov    %edi,%eax
f01022ab:	e8 95 e8 ff ff       	call   f0100b45 <page2kva>
f01022b0:	83 c4 0c             	add    $0xc,%esp
f01022b3:	68 00 10 00 00       	push   $0x1000
f01022b8:	6a 01                	push   $0x1
f01022ba:	50                   	push   %eax
f01022bb:	e8 dc 0d 00 00       	call   f010309c <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01022c0:	89 d8                	mov    %ebx,%eax
f01022c2:	e8 7e e8 ff ff       	call   f0100b45 <page2kva>
f01022c7:	83 c4 0c             	add    $0xc,%esp
f01022ca:	68 00 10 00 00       	push   $0x1000
f01022cf:	6a 02                	push   $0x2
f01022d1:	50                   	push   %eax
f01022d2:	e8 c5 0d 00 00       	call   f010309c <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01022d7:	6a 02                	push   $0x2
f01022d9:	68 00 10 00 00       	push   $0x1000
f01022de:	57                   	push   %edi
f01022df:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01022e5:	e8 1b f4 ff ff       	call   f0101705 <page_insert>
	assert(pp1->pp_ref == 1);
f01022ea:	83 c4 20             	add    $0x20,%esp
f01022ed:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01022f2:	74 19                	je     f010230d <check_page_installed_pgdir+0xf7>
f01022f4:	68 3f 44 10 f0       	push   $0xf010443f
f01022f9:	68 31 42 10 f0       	push   $0xf0104231
f01022fe:	68 5c 03 00 00       	push   $0x35c
f0102303:	68 17 42 10 f0       	push   $0xf0104217
f0102308:	e8 7e dd ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010230d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102314:	01 01 01 
f0102317:	74 19                	je     f0102332 <check_page_installed_pgdir+0x11c>
f0102319:	68 64 41 10 f0       	push   $0xf0104164
f010231e:	68 31 42 10 f0       	push   $0xf0104231
f0102323:	68 5d 03 00 00       	push   $0x35d
f0102328:	68 17 42 10 f0       	push   $0xf0104217
f010232d:	e8 59 dd ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102332:	6a 02                	push   $0x2
f0102334:	68 00 10 00 00       	push   $0x1000
f0102339:	53                   	push   %ebx
f010233a:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102340:	e8 c0 f3 ff ff       	call   f0101705 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102345:	83 c4 10             	add    $0x10,%esp
f0102348:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010234f:	02 02 02 
f0102352:	74 19                	je     f010236d <check_page_installed_pgdir+0x157>
f0102354:	68 88 41 10 f0       	push   $0xf0104188
f0102359:	68 31 42 10 f0       	push   $0xf0104231
f010235e:	68 5f 03 00 00       	push   $0x35f
f0102363:	68 17 42 10 f0       	push   $0xf0104217
f0102368:	e8 1e dd ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010236d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102372:	74 19                	je     f010238d <check_page_installed_pgdir+0x177>
f0102374:	68 61 44 10 f0       	push   $0xf0104461
f0102379:	68 31 42 10 f0       	push   $0xf0104231
f010237e:	68 60 03 00 00       	push   $0x360
f0102383:	68 17 42 10 f0       	push   $0xf0104217
f0102388:	e8 fe dc ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010238d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102392:	74 19                	je     f01023ad <check_page_installed_pgdir+0x197>
f0102394:	68 cb 44 10 f0       	push   $0xf01044cb
f0102399:	68 31 42 10 f0       	push   $0xf0104231
f010239e:	68 61 03 00 00       	push   $0x361
f01023a3:	68 17 42 10 f0       	push   $0xf0104217
f01023a8:	e8 de dc ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01023ad:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01023b4:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01023b7:	89 d8                	mov    %ebx,%eax
f01023b9:	e8 87 e7 ff ff       	call   f0100b45 <page2kva>
f01023be:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01023c4:	74 19                	je     f01023df <check_page_installed_pgdir+0x1c9>
f01023c6:	68 ac 41 10 f0       	push   $0xf01041ac
f01023cb:	68 31 42 10 f0       	push   $0xf0104231
f01023d0:	68 63 03 00 00       	push   $0x363
f01023d5:	68 17 42 10 f0       	push   $0xf0104217
f01023da:	e8 ac dc ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01023df:	83 ec 08             	sub    $0x8,%esp
f01023e2:	68 00 10 00 00       	push   $0x1000
f01023e7:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01023ed:	e8 cd f2 ff ff       	call   f01016bf <page_remove>
	assert(pp2->pp_ref == 0);
f01023f2:	83 c4 10             	add    $0x10,%esp
f01023f5:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01023fa:	74 19                	je     f0102415 <check_page_installed_pgdir+0x1ff>
f01023fc:	68 99 44 10 f0       	push   $0xf0104499
f0102401:	68 31 42 10 f0       	push   $0xf0104231
f0102406:	68 65 03 00 00       	push   $0x365
f010240b:	68 17 42 10 f0       	push   $0xf0104217
f0102410:	e8 76 dc ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102415:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f010241b:	89 f0                	mov    %esi,%eax
f010241d:	e8 ed e5 ff ff       	call   f0100a0f <page2pa>
f0102422:	8b 13                	mov    (%ebx),%edx
f0102424:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010242a:	39 c2                	cmp    %eax,%edx
f010242c:	74 19                	je     f0102447 <check_page_installed_pgdir+0x231>
f010242e:	68 e4 3d 10 f0       	push   $0xf0103de4
f0102433:	68 31 42 10 f0       	push   $0xf0104231
f0102438:	68 68 03 00 00       	push   $0x368
f010243d:	68 17 42 10 f0       	push   $0xf0104217
f0102442:	e8 44 dc ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102447:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f010244d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102452:	74 19                	je     f010246d <check_page_installed_pgdir+0x257>
f0102454:	68 50 44 10 f0       	push   $0xf0104450
f0102459:	68 31 42 10 f0       	push   $0xf0104231
f010245e:	68 6a 03 00 00       	push   $0x36a
f0102463:	68 17 42 10 f0       	push   $0xf0104217
f0102468:	e8 1e dc ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010246d:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102473:	83 ec 0c             	sub    $0xc,%esp
f0102476:	56                   	push   %esi
f0102477:	e8 09 ed ff ff       	call   f0101185 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010247c:	c7 04 24 d8 41 10 f0 	movl   $0xf01041d8,(%esp)
f0102483:	e8 70 01 00 00       	call   f01025f8 <cprintf>
}
f0102488:	83 c4 10             	add    $0x10,%esp
f010248b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010248e:	5b                   	pop    %ebx
f010248f:	5e                   	pop    %esi
f0102490:	5f                   	pop    %edi
f0102491:	5d                   	pop    %ebp
f0102492:	c3                   	ret    

f0102493 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0102493:	55                   	push   %ebp
f0102494:	89 e5                	mov    %esp,%ebp
f0102496:	53                   	push   %ebx
f0102497:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f010249a:	e8 aa e5 ff ff       	call   f0100a49 <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010249f:	b8 00 10 00 00       	mov    $0x1000,%eax
f01024a4:	e8 06 e6 ff ff       	call   f0100aaf <boot_alloc>
f01024a9:	a3 48 79 11 f0       	mov    %eax,0xf0117948
	memset(kern_pgdir, 0, PGSIZE);
f01024ae:	83 ec 04             	sub    $0x4,%esp
f01024b1:	68 00 10 00 00       	push   $0x1000
f01024b6:	6a 00                	push   $0x0
f01024b8:	50                   	push   %eax
f01024b9:	e8 de 0b 00 00       	call   f010309c <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01024be:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f01024c4:	89 d9                	mov    %ebx,%ecx
f01024c6:	ba 92 00 00 00       	mov    $0x92,%edx
f01024cb:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
f01024d0:	e8 fe e6 ff ff       	call   f0100bd3 <_paddr>
f01024d5:	83 c8 05             	or     $0x5,%eax
f01024d8:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages //[page]
f01024de:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f01024e3:	c1 e0 03             	shl    $0x3,%eax
f01024e6:	e8 c4 e5 ff ff       	call   f0100aaf <boot_alloc>
f01024eb:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
					 * sizeof(struct PageInfo));//[B/page]
	memset(pages,0,npages*sizeof(struct PageInfo));
f01024f0:	83 c4 0c             	add    $0xc,%esp
f01024f3:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f01024f9:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0102500:	52                   	push   %edx
f0102501:	6a 00                	push   $0x0
f0102503:	50                   	push   %eax
f0102504:	e8 93 0b 00 00       	call   f010309c <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0102509:	e8 b4 eb ff ff       	call   f01010c2 <page_init>

	check_page_free_list(1);
f010250e:	b8 01 00 00 00       	mov    $0x1,%eax
f0102513:	e8 e5 e8 ff ff       	call   f0100dfd <check_page_free_list>
	check_page_alloc();
f0102518:	e8 ba ec ff ff       	call   f01011d7 <check_page_alloc>
	check_page();
f010251d:	e8 44 f2 ff ff       	call   f0101766 <check_page>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f0102522:	e8 ce e6 ff ff       	call   f0100bf5 <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102527:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f010252d:	ba d4 00 00 00       	mov    $0xd4,%edx
f0102532:	b8 17 42 10 f0       	mov    $0xf0104217,%eax
f0102537:	e8 97 e6 ff ff       	call   f0100bd3 <_paddr>
f010253c:	e8 c6 e4 ff ff       	call   f0100a07 <lcr3>

	check_page_free_list(0);
f0102541:	b8 00 00 00 00       	mov    $0x0,%eax
f0102546:	e8 b2 e8 ff ff       	call   f0100dfd <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f010254b:	e8 af e4 ff ff       	call   f01009ff <rcr0>
f0102550:	83 e0 f3             	and    $0xfffffff3,%eax
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);
f0102553:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102558:	e8 9a e4 ff ff       	call   f01009f7 <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f010255d:	e8 b4 fc ff ff       	call   f0102216 <check_page_installed_pgdir>
}
f0102562:	83 c4 10             	add    $0x10,%esp
f0102565:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102568:	c9                   	leave  
f0102569:	c3                   	ret    

f010256a <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010256a:	55                   	push   %ebp
f010256b:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010256d:	89 c2                	mov    %eax,%edx
f010256f:	ec                   	in     (%dx),%al
	return data;
}
f0102570:	5d                   	pop    %ebp
f0102571:	c3                   	ret    

f0102572 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0102572:	55                   	push   %ebp
f0102573:	89 e5                	mov    %esp,%ebp
f0102575:	89 c1                	mov    %eax,%ecx
f0102577:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102579:	89 ca                	mov    %ecx,%edx
f010257b:	ee                   	out    %al,(%dx)
}
f010257c:	5d                   	pop    %ebp
f010257d:	c3                   	ret    

f010257e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010257e:	55                   	push   %ebp
f010257f:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102581:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102585:	b8 70 00 00 00       	mov    $0x70,%eax
f010258a:	e8 e3 ff ff ff       	call   f0102572 <outb>
	return inb(IO_RTC+1);
f010258f:	b8 71 00 00 00       	mov    $0x71,%eax
f0102594:	e8 d1 ff ff ff       	call   f010256a <inb>
f0102599:	0f b6 c0             	movzbl %al,%eax
}
f010259c:	5d                   	pop    %ebp
f010259d:	c3                   	ret    

f010259e <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010259e:	55                   	push   %ebp
f010259f:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f01025a1:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f01025a5:	b8 70 00 00 00       	mov    $0x70,%eax
f01025aa:	e8 c3 ff ff ff       	call   f0102572 <outb>
	outb(IO_RTC+1, datum);
f01025af:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f01025b3:	b8 71 00 00 00       	mov    $0x71,%eax
f01025b8:	e8 b5 ff ff ff       	call   f0102572 <outb>
}
f01025bd:	5d                   	pop    %ebp
f01025be:	c3                   	ret    

f01025bf <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01025bf:	55                   	push   %ebp
f01025c0:	89 e5                	mov    %esp,%ebp
f01025c2:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01025c5:	ff 75 08             	pushl  0x8(%ebp)
f01025c8:	e8 38 e1 ff ff       	call   f0100705 <cputchar>
	*cnt++;
}
f01025cd:	83 c4 10             	add    $0x10,%esp
f01025d0:	c9                   	leave  
f01025d1:	c3                   	ret    

f01025d2 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01025d2:	55                   	push   %ebp
f01025d3:	89 e5                	mov    %esp,%ebp
f01025d5:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01025d8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01025df:	ff 75 0c             	pushl  0xc(%ebp)
f01025e2:	ff 75 08             	pushl  0x8(%ebp)
f01025e5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01025e8:	50                   	push   %eax
f01025e9:	68 bf 25 10 f0       	push   $0xf01025bf
f01025ee:	e8 82 04 00 00       	call   f0102a75 <vprintfmt>
	return cnt;
}
f01025f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01025f6:	c9                   	leave  
f01025f7:	c3                   	ret    

f01025f8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01025f8:	55                   	push   %ebp
f01025f9:	89 e5                	mov    %esp,%ebp
f01025fb:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01025fe:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102601:	50                   	push   %eax
f0102602:	ff 75 08             	pushl  0x8(%ebp)
f0102605:	e8 c8 ff ff ff       	call   f01025d2 <vcprintf>
	va_end(ap);

	return cnt;
}
f010260a:	c9                   	leave  
f010260b:	c3                   	ret    

f010260c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010260c:	55                   	push   %ebp
f010260d:	89 e5                	mov    %esp,%ebp
f010260f:	57                   	push   %edi
f0102610:	56                   	push   %esi
f0102611:	53                   	push   %ebx
f0102612:	83 ec 14             	sub    $0x14,%esp
f0102615:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102618:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010261b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010261e:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102621:	8b 1a                	mov    (%edx),%ebx
f0102623:	8b 01                	mov    (%ecx),%eax
f0102625:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102628:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010262f:	eb 7f                	jmp    f01026b0 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0102631:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102634:	01 d8                	add    %ebx,%eax
f0102636:	89 c6                	mov    %eax,%esi
f0102638:	c1 ee 1f             	shr    $0x1f,%esi
f010263b:	01 c6                	add    %eax,%esi
f010263d:	d1 fe                	sar    %esi
f010263f:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0102642:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102645:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102648:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010264a:	eb 03                	jmp    f010264f <stab_binsearch+0x43>
			m--;
f010264c:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010264f:	39 c3                	cmp    %eax,%ebx
f0102651:	7f 0d                	jg     f0102660 <stab_binsearch+0x54>
f0102653:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102657:	83 ea 0c             	sub    $0xc,%edx
f010265a:	39 f9                	cmp    %edi,%ecx
f010265c:	75 ee                	jne    f010264c <stab_binsearch+0x40>
f010265e:	eb 05                	jmp    f0102665 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102660:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102663:	eb 4b                	jmp    f01026b0 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102665:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102668:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010266b:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010266f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102672:	76 11                	jbe    f0102685 <stab_binsearch+0x79>
			*region_left = m;
f0102674:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102677:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102679:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010267c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102683:	eb 2b                	jmp    f01026b0 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102685:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102688:	73 14                	jae    f010269e <stab_binsearch+0x92>
			*region_right = m - 1;
f010268a:	83 e8 01             	sub    $0x1,%eax
f010268d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102690:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102693:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102695:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010269c:	eb 12                	jmp    f01026b0 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010269e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026a1:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01026a3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01026a7:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01026a9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01026b0:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01026b3:	0f 8e 78 ff ff ff    	jle    f0102631 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01026b9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01026bd:	75 0f                	jne    f01026ce <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01026bf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01026c2:	8b 00                	mov    (%eax),%eax
f01026c4:	83 e8 01             	sub    $0x1,%eax
f01026c7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01026ca:	89 06                	mov    %eax,(%esi)
f01026cc:	eb 2c                	jmp    f01026fa <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01026ce:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01026d1:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01026d3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026d6:	8b 0e                	mov    (%esi),%ecx
f01026d8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01026db:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01026de:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01026e1:	eb 03                	jmp    f01026e6 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01026e3:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01026e6:	39 c8                	cmp    %ecx,%eax
f01026e8:	7e 0b                	jle    f01026f5 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01026ea:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01026ee:	83 ea 0c             	sub    $0xc,%edx
f01026f1:	39 df                	cmp    %ebx,%edi
f01026f3:	75 ee                	jne    f01026e3 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01026f5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01026f8:	89 06                	mov    %eax,(%esi)
	}
}
f01026fa:	83 c4 14             	add    $0x14,%esp
f01026fd:	5b                   	pop    %ebx
f01026fe:	5e                   	pop    %esi
f01026ff:	5f                   	pop    %edi
f0102700:	5d                   	pop    %ebp
f0102701:	c3                   	ret    

f0102702 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102702:	55                   	push   %ebp
f0102703:	89 e5                	mov    %esp,%ebp
f0102705:	57                   	push   %edi
f0102706:	56                   	push   %esi
f0102707:	53                   	push   %ebx
f0102708:	83 ec 3c             	sub    $0x3c,%esp
f010270b:	8b 75 08             	mov    0x8(%ebp),%esi
f010270e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102711:	c7 03 24 45 10 f0    	movl   $0xf0104524,(%ebx)
	info->eip_line = 0;
f0102717:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010271e:	c7 43 08 24 45 10 f0 	movl   $0xf0104524,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102725:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010272c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010272f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102736:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010273c:	76 11                	jbe    f010274f <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010273e:	b8 57 c3 10 f0       	mov    $0xf010c357,%eax
f0102743:	3d 5d a3 10 f0       	cmp    $0xf010a35d,%eax
f0102748:	77 19                	ja     f0102763 <debuginfo_eip+0x61>
f010274a:	e9 af 01 00 00       	jmp    f01028fe <debuginfo_eip+0x1fc>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010274f:	83 ec 04             	sub    $0x4,%esp
f0102752:	68 2e 45 10 f0       	push   $0xf010452e
f0102757:	6a 7f                	push   $0x7f
f0102759:	68 3b 45 10 f0       	push   $0xf010453b
f010275e:	e8 28 d9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102763:	80 3d 56 c3 10 f0 00 	cmpb   $0x0,0xf010c356
f010276a:	0f 85 95 01 00 00    	jne    f0102905 <debuginfo_eip+0x203>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102770:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102777:	b8 5c a3 10 f0       	mov    $0xf010a35c,%eax
f010277c:	2d 58 47 10 f0       	sub    $0xf0104758,%eax
f0102781:	c1 f8 02             	sar    $0x2,%eax
f0102784:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010278a:	83 e8 01             	sub    $0x1,%eax
f010278d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102790:	83 ec 08             	sub    $0x8,%esp
f0102793:	56                   	push   %esi
f0102794:	6a 64                	push   $0x64
f0102796:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102799:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010279c:	b8 58 47 10 f0       	mov    $0xf0104758,%eax
f01027a1:	e8 66 fe ff ff       	call   f010260c <stab_binsearch>
	if (lfile == 0)
f01027a6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027a9:	83 c4 10             	add    $0x10,%esp
f01027ac:	85 c0                	test   %eax,%eax
f01027ae:	0f 84 58 01 00 00    	je     f010290c <debuginfo_eip+0x20a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01027b4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01027b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027ba:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01027bd:	83 ec 08             	sub    $0x8,%esp
f01027c0:	56                   	push   %esi
f01027c1:	6a 24                	push   $0x24
f01027c3:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01027c6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01027c9:	b8 58 47 10 f0       	mov    $0xf0104758,%eax
f01027ce:	e8 39 fe ff ff       	call   f010260c <stab_binsearch>

	if (lfun <= rfun) {
f01027d3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01027d6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01027d9:	83 c4 10             	add    $0x10,%esp
f01027dc:	39 d0                	cmp    %edx,%eax
f01027de:	7f 40                	jg     f0102820 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01027e0:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01027e3:	c1 e1 02             	shl    $0x2,%ecx
f01027e6:	8d b9 58 47 10 f0    	lea    -0xfefb8a8(%ecx),%edi
f01027ec:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01027ef:	8b b9 58 47 10 f0    	mov    -0xfefb8a8(%ecx),%edi
f01027f5:	b9 57 c3 10 f0       	mov    $0xf010c357,%ecx
f01027fa:	81 e9 5d a3 10 f0    	sub    $0xf010a35d,%ecx
f0102800:	39 cf                	cmp    %ecx,%edi
f0102802:	73 09                	jae    f010280d <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102804:	81 c7 5d a3 10 f0    	add    $0xf010a35d,%edi
f010280a:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010280d:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102810:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102813:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102816:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102818:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010281b:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010281e:	eb 0f                	jmp    f010282f <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102820:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102823:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102826:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102829:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010282c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010282f:	83 ec 08             	sub    $0x8,%esp
f0102832:	6a 3a                	push   $0x3a
f0102834:	ff 73 08             	pushl  0x8(%ebx)
f0102837:	e8 44 08 00 00       	call   f0103080 <strfind>
f010283c:	2b 43 08             	sub    0x8(%ebx),%eax
f010283f:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102842:	83 c4 08             	add    $0x8,%esp
f0102845:	56                   	push   %esi
f0102846:	6a 44                	push   $0x44
f0102848:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010284b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010284e:	b8 58 47 10 f0       	mov    $0xf0104758,%eax
f0102853:	e8 b4 fd ff ff       	call   f010260c <stab_binsearch>
	if (lline <= rline) {
f0102858:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010285b:	83 c4 10             	add    $0x10,%esp
f010285e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0102861:	7f 0e                	jg     f0102871 <debuginfo_eip+0x16f>
		info->eip_line = stabs[lline].n_desc;
f0102863:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102866:	0f b7 14 95 5e 47 10 	movzwl -0xfefb8a2(,%edx,4),%edx
f010286d:	f0 
f010286e:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102871:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102874:	89 c2                	mov    %eax,%edx
f0102876:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102879:	8d 04 85 58 47 10 f0 	lea    -0xfefb8a8(,%eax,4),%eax
f0102880:	eb 06                	jmp    f0102888 <debuginfo_eip+0x186>
f0102882:	83 ea 01             	sub    $0x1,%edx
f0102885:	83 e8 0c             	sub    $0xc,%eax
f0102888:	39 d7                	cmp    %edx,%edi
f010288a:	7f 34                	jg     f01028c0 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f010288c:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102890:	80 f9 84             	cmp    $0x84,%cl
f0102893:	74 0b                	je     f01028a0 <debuginfo_eip+0x19e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102895:	80 f9 64             	cmp    $0x64,%cl
f0102898:	75 e8                	jne    f0102882 <debuginfo_eip+0x180>
f010289a:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010289e:	74 e2                	je     f0102882 <debuginfo_eip+0x180>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01028a0:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01028a3:	8b 14 85 58 47 10 f0 	mov    -0xfefb8a8(,%eax,4),%edx
f01028aa:	b8 57 c3 10 f0       	mov    $0xf010c357,%eax
f01028af:	2d 5d a3 10 f0       	sub    $0xf010a35d,%eax
f01028b4:	39 c2                	cmp    %eax,%edx
f01028b6:	73 08                	jae    f01028c0 <debuginfo_eip+0x1be>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01028b8:	81 c2 5d a3 10 f0    	add    $0xf010a35d,%edx
f01028be:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01028c0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01028c3:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01028c6:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01028cb:	39 f2                	cmp    %esi,%edx
f01028cd:	7d 49                	jge    f0102918 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
f01028cf:	83 c2 01             	add    $0x1,%edx
f01028d2:	89 d0                	mov    %edx,%eax
f01028d4:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01028d7:	8d 14 95 58 47 10 f0 	lea    -0xfefb8a8(,%edx,4),%edx
f01028de:	eb 04                	jmp    f01028e4 <debuginfo_eip+0x1e2>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01028e0:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01028e4:	39 c6                	cmp    %eax,%esi
f01028e6:	7e 2b                	jle    f0102913 <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01028e8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01028ec:	83 c0 01             	add    $0x1,%eax
f01028ef:	83 c2 0c             	add    $0xc,%edx
f01028f2:	80 f9 a0             	cmp    $0xa0,%cl
f01028f5:	74 e9                	je     f01028e0 <debuginfo_eip+0x1de>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01028f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01028fc:	eb 1a                	jmp    f0102918 <debuginfo_eip+0x216>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01028fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102903:	eb 13                	jmp    f0102918 <debuginfo_eip+0x216>
f0102905:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010290a:	eb 0c                	jmp    f0102918 <debuginfo_eip+0x216>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010290c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102911:	eb 05                	jmp    f0102918 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102913:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102918:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010291b:	5b                   	pop    %ebx
f010291c:	5e                   	pop    %esi
f010291d:	5f                   	pop    %edi
f010291e:	5d                   	pop    %ebp
f010291f:	c3                   	ret    

f0102920 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102920:	55                   	push   %ebp
f0102921:	89 e5                	mov    %esp,%ebp
f0102923:	57                   	push   %edi
f0102924:	56                   	push   %esi
f0102925:	53                   	push   %ebx
f0102926:	83 ec 1c             	sub    $0x1c,%esp
f0102929:	89 c7                	mov    %eax,%edi
f010292b:	89 d6                	mov    %edx,%esi
f010292d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102930:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102933:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102936:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102939:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010293c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102941:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102944:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102947:	39 d3                	cmp    %edx,%ebx
f0102949:	72 05                	jb     f0102950 <printnum+0x30>
f010294b:	39 45 10             	cmp    %eax,0x10(%ebp)
f010294e:	77 45                	ja     f0102995 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102950:	83 ec 0c             	sub    $0xc,%esp
f0102953:	ff 75 18             	pushl  0x18(%ebp)
f0102956:	8b 45 14             	mov    0x14(%ebp),%eax
f0102959:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010295c:	53                   	push   %ebx
f010295d:	ff 75 10             	pushl  0x10(%ebp)
f0102960:	83 ec 08             	sub    $0x8,%esp
f0102963:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102966:	ff 75 e0             	pushl  -0x20(%ebp)
f0102969:	ff 75 dc             	pushl  -0x24(%ebp)
f010296c:	ff 75 d8             	pushl  -0x28(%ebp)
f010296f:	e8 2c 09 00 00       	call   f01032a0 <__udivdi3>
f0102974:	83 c4 18             	add    $0x18,%esp
f0102977:	52                   	push   %edx
f0102978:	50                   	push   %eax
f0102979:	89 f2                	mov    %esi,%edx
f010297b:	89 f8                	mov    %edi,%eax
f010297d:	e8 9e ff ff ff       	call   f0102920 <printnum>
f0102982:	83 c4 20             	add    $0x20,%esp
f0102985:	eb 18                	jmp    f010299f <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102987:	83 ec 08             	sub    $0x8,%esp
f010298a:	56                   	push   %esi
f010298b:	ff 75 18             	pushl  0x18(%ebp)
f010298e:	ff d7                	call   *%edi
f0102990:	83 c4 10             	add    $0x10,%esp
f0102993:	eb 03                	jmp    f0102998 <printnum+0x78>
f0102995:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102998:	83 eb 01             	sub    $0x1,%ebx
f010299b:	85 db                	test   %ebx,%ebx
f010299d:	7f e8                	jg     f0102987 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010299f:	83 ec 08             	sub    $0x8,%esp
f01029a2:	56                   	push   %esi
f01029a3:	83 ec 04             	sub    $0x4,%esp
f01029a6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01029a9:	ff 75 e0             	pushl  -0x20(%ebp)
f01029ac:	ff 75 dc             	pushl  -0x24(%ebp)
f01029af:	ff 75 d8             	pushl  -0x28(%ebp)
f01029b2:	e8 19 0a 00 00       	call   f01033d0 <__umoddi3>
f01029b7:	83 c4 14             	add    $0x14,%esp
f01029ba:	0f be 80 49 45 10 f0 	movsbl -0xfefbab7(%eax),%eax
f01029c1:	50                   	push   %eax
f01029c2:	ff d7                	call   *%edi
}
f01029c4:	83 c4 10             	add    $0x10,%esp
f01029c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029ca:	5b                   	pop    %ebx
f01029cb:	5e                   	pop    %esi
f01029cc:	5f                   	pop    %edi
f01029cd:	5d                   	pop    %ebp
f01029ce:	c3                   	ret    

f01029cf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01029cf:	55                   	push   %ebp
f01029d0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01029d2:	83 fa 01             	cmp    $0x1,%edx
f01029d5:	7e 0e                	jle    f01029e5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01029d7:	8b 10                	mov    (%eax),%edx
f01029d9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01029dc:	89 08                	mov    %ecx,(%eax)
f01029de:	8b 02                	mov    (%edx),%eax
f01029e0:	8b 52 04             	mov    0x4(%edx),%edx
f01029e3:	eb 22                	jmp    f0102a07 <getuint+0x38>
	else if (lflag)
f01029e5:	85 d2                	test   %edx,%edx
f01029e7:	74 10                	je     f01029f9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01029e9:	8b 10                	mov    (%eax),%edx
f01029eb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01029ee:	89 08                	mov    %ecx,(%eax)
f01029f0:	8b 02                	mov    (%edx),%eax
f01029f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01029f7:	eb 0e                	jmp    f0102a07 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01029f9:	8b 10                	mov    (%eax),%edx
f01029fb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01029fe:	89 08                	mov    %ecx,(%eax)
f0102a00:	8b 02                	mov    (%edx),%eax
f0102a02:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102a07:	5d                   	pop    %ebp
f0102a08:	c3                   	ret    

f0102a09 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0102a09:	55                   	push   %ebp
f0102a0a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102a0c:	83 fa 01             	cmp    $0x1,%edx
f0102a0f:	7e 0e                	jle    f0102a1f <getint+0x16>
		return va_arg(*ap, long long);
f0102a11:	8b 10                	mov    (%eax),%edx
f0102a13:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102a16:	89 08                	mov    %ecx,(%eax)
f0102a18:	8b 02                	mov    (%edx),%eax
f0102a1a:	8b 52 04             	mov    0x4(%edx),%edx
f0102a1d:	eb 1a                	jmp    f0102a39 <getint+0x30>
	else if (lflag)
f0102a1f:	85 d2                	test   %edx,%edx
f0102a21:	74 0c                	je     f0102a2f <getint+0x26>
		return va_arg(*ap, long);
f0102a23:	8b 10                	mov    (%eax),%edx
f0102a25:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102a28:	89 08                	mov    %ecx,(%eax)
f0102a2a:	8b 02                	mov    (%edx),%eax
f0102a2c:	99                   	cltd   
f0102a2d:	eb 0a                	jmp    f0102a39 <getint+0x30>
	else
		return va_arg(*ap, int);
f0102a2f:	8b 10                	mov    (%eax),%edx
f0102a31:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102a34:	89 08                	mov    %ecx,(%eax)
f0102a36:	8b 02                	mov    (%edx),%eax
f0102a38:	99                   	cltd   
}
f0102a39:	5d                   	pop    %ebp
f0102a3a:	c3                   	ret    

f0102a3b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102a3b:	55                   	push   %ebp
f0102a3c:	89 e5                	mov    %esp,%ebp
f0102a3e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102a41:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102a45:	8b 10                	mov    (%eax),%edx
f0102a47:	3b 50 04             	cmp    0x4(%eax),%edx
f0102a4a:	73 0a                	jae    f0102a56 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102a4c:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102a4f:	89 08                	mov    %ecx,(%eax)
f0102a51:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a54:	88 02                	mov    %al,(%edx)
}
f0102a56:	5d                   	pop    %ebp
f0102a57:	c3                   	ret    

f0102a58 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102a58:	55                   	push   %ebp
f0102a59:	89 e5                	mov    %esp,%ebp
f0102a5b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102a5e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102a61:	50                   	push   %eax
f0102a62:	ff 75 10             	pushl  0x10(%ebp)
f0102a65:	ff 75 0c             	pushl  0xc(%ebp)
f0102a68:	ff 75 08             	pushl  0x8(%ebp)
f0102a6b:	e8 05 00 00 00       	call   f0102a75 <vprintfmt>
	va_end(ap);
}
f0102a70:	83 c4 10             	add    $0x10,%esp
f0102a73:	c9                   	leave  
f0102a74:	c3                   	ret    

f0102a75 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102a75:	55                   	push   %ebp
f0102a76:	89 e5                	mov    %esp,%ebp
f0102a78:	57                   	push   %edi
f0102a79:	56                   	push   %esi
f0102a7a:	53                   	push   %ebx
f0102a7b:	83 ec 2c             	sub    $0x2c,%esp
f0102a7e:	8b 75 08             	mov    0x8(%ebp),%esi
f0102a81:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102a84:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102a87:	eb 12                	jmp    f0102a9b <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102a89:	85 c0                	test   %eax,%eax
f0102a8b:	0f 84 44 03 00 00    	je     f0102dd5 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f0102a91:	83 ec 08             	sub    $0x8,%esp
f0102a94:	53                   	push   %ebx
f0102a95:	50                   	push   %eax
f0102a96:	ff d6                	call   *%esi
f0102a98:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102a9b:	83 c7 01             	add    $0x1,%edi
f0102a9e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102aa2:	83 f8 25             	cmp    $0x25,%eax
f0102aa5:	75 e2                	jne    f0102a89 <vprintfmt+0x14>
f0102aa7:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102aab:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102ab2:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102ab9:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102ac0:	ba 00 00 00 00       	mov    $0x0,%edx
f0102ac5:	eb 07                	jmp    f0102ace <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ac7:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102aca:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ace:	8d 47 01             	lea    0x1(%edi),%eax
f0102ad1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102ad4:	0f b6 07             	movzbl (%edi),%eax
f0102ad7:	0f b6 c8             	movzbl %al,%ecx
f0102ada:	83 e8 23             	sub    $0x23,%eax
f0102add:	3c 55                	cmp    $0x55,%al
f0102adf:	0f 87 d5 02 00 00    	ja     f0102dba <vprintfmt+0x345>
f0102ae5:	0f b6 c0             	movzbl %al,%eax
f0102ae8:	ff 24 85 d4 45 10 f0 	jmp    *-0xfefba2c(,%eax,4)
f0102aef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102af2:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102af6:	eb d6                	jmp    f0102ace <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102af8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102afb:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b00:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102b03:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102b06:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102b0a:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102b0d:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102b10:	83 fa 09             	cmp    $0x9,%edx
f0102b13:	77 39                	ja     f0102b4e <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102b15:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102b18:	eb e9                	jmp    f0102b03 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102b1a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b1d:	8d 48 04             	lea    0x4(%eax),%ecx
f0102b20:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102b23:	8b 00                	mov    (%eax),%eax
f0102b25:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b28:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102b2b:	eb 27                	jmp    f0102b54 <vprintfmt+0xdf>
f0102b2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b30:	85 c0                	test   %eax,%eax
f0102b32:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102b37:	0f 49 c8             	cmovns %eax,%ecx
f0102b3a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b40:	eb 8c                	jmp    f0102ace <vprintfmt+0x59>
f0102b42:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102b45:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102b4c:	eb 80                	jmp    f0102ace <vprintfmt+0x59>
f0102b4e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102b51:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102b54:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102b58:	0f 89 70 ff ff ff    	jns    f0102ace <vprintfmt+0x59>
				width = precision, precision = -1;
f0102b5e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b61:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102b64:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b6b:	e9 5e ff ff ff       	jmp    f0102ace <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102b70:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102b76:	e9 53 ff ff ff       	jmp    f0102ace <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102b7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b7e:	8d 50 04             	lea    0x4(%eax),%edx
f0102b81:	89 55 14             	mov    %edx,0x14(%ebp)
f0102b84:	83 ec 08             	sub    $0x8,%esp
f0102b87:	53                   	push   %ebx
f0102b88:	ff 30                	pushl  (%eax)
f0102b8a:	ff d6                	call   *%esi
			break;
f0102b8c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102b92:	e9 04 ff ff ff       	jmp    f0102a9b <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102b97:	8b 45 14             	mov    0x14(%ebp),%eax
f0102b9a:	8d 50 04             	lea    0x4(%eax),%edx
f0102b9d:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ba0:	8b 00                	mov    (%eax),%eax
f0102ba2:	99                   	cltd   
f0102ba3:	31 d0                	xor    %edx,%eax
f0102ba5:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102ba7:	83 f8 06             	cmp    $0x6,%eax
f0102baa:	7f 0b                	jg     f0102bb7 <vprintfmt+0x142>
f0102bac:	8b 14 85 2c 47 10 f0 	mov    -0xfefb8d4(,%eax,4),%edx
f0102bb3:	85 d2                	test   %edx,%edx
f0102bb5:	75 18                	jne    f0102bcf <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102bb7:	50                   	push   %eax
f0102bb8:	68 61 45 10 f0       	push   $0xf0104561
f0102bbd:	53                   	push   %ebx
f0102bbe:	56                   	push   %esi
f0102bbf:	e8 94 fe ff ff       	call   f0102a58 <printfmt>
f0102bc4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bc7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102bca:	e9 cc fe ff ff       	jmp    f0102a9b <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102bcf:	52                   	push   %edx
f0102bd0:	68 43 42 10 f0       	push   $0xf0104243
f0102bd5:	53                   	push   %ebx
f0102bd6:	56                   	push   %esi
f0102bd7:	e8 7c fe ff ff       	call   f0102a58 <printfmt>
f0102bdc:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bdf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102be2:	e9 b4 fe ff ff       	jmp    f0102a9b <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102be7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bea:	8d 50 04             	lea    0x4(%eax),%edx
f0102bed:	89 55 14             	mov    %edx,0x14(%ebp)
f0102bf0:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102bf2:	85 ff                	test   %edi,%edi
f0102bf4:	b8 5a 45 10 f0       	mov    $0xf010455a,%eax
f0102bf9:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102bfc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c00:	0f 8e 94 00 00 00    	jle    f0102c9a <vprintfmt+0x225>
f0102c06:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102c0a:	0f 84 98 00 00 00    	je     f0102ca8 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c10:	83 ec 08             	sub    $0x8,%esp
f0102c13:	ff 75 d0             	pushl  -0x30(%ebp)
f0102c16:	57                   	push   %edi
f0102c17:	e8 1a 03 00 00       	call   f0102f36 <strnlen>
f0102c1c:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102c1f:	29 c1                	sub    %eax,%ecx
f0102c21:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102c24:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102c27:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102c2b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c2e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102c31:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c33:	eb 0f                	jmp    f0102c44 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102c35:	83 ec 08             	sub    $0x8,%esp
f0102c38:	53                   	push   %ebx
f0102c39:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c3c:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102c3e:	83 ef 01             	sub    $0x1,%edi
f0102c41:	83 c4 10             	add    $0x10,%esp
f0102c44:	85 ff                	test   %edi,%edi
f0102c46:	7f ed                	jg     f0102c35 <vprintfmt+0x1c0>
f0102c48:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102c4b:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102c4e:	85 c9                	test   %ecx,%ecx
f0102c50:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c55:	0f 49 c1             	cmovns %ecx,%eax
f0102c58:	29 c1                	sub    %eax,%ecx
f0102c5a:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c5d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102c60:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102c63:	89 cb                	mov    %ecx,%ebx
f0102c65:	eb 4d                	jmp    f0102cb4 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102c67:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102c6b:	74 1b                	je     f0102c88 <vprintfmt+0x213>
f0102c6d:	0f be c0             	movsbl %al,%eax
f0102c70:	83 e8 20             	sub    $0x20,%eax
f0102c73:	83 f8 5e             	cmp    $0x5e,%eax
f0102c76:	76 10                	jbe    f0102c88 <vprintfmt+0x213>
					putch('?', putdat);
f0102c78:	83 ec 08             	sub    $0x8,%esp
f0102c7b:	ff 75 0c             	pushl  0xc(%ebp)
f0102c7e:	6a 3f                	push   $0x3f
f0102c80:	ff 55 08             	call   *0x8(%ebp)
f0102c83:	83 c4 10             	add    $0x10,%esp
f0102c86:	eb 0d                	jmp    f0102c95 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102c88:	83 ec 08             	sub    $0x8,%esp
f0102c8b:	ff 75 0c             	pushl  0xc(%ebp)
f0102c8e:	52                   	push   %edx
f0102c8f:	ff 55 08             	call   *0x8(%ebp)
f0102c92:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102c95:	83 eb 01             	sub    $0x1,%ebx
f0102c98:	eb 1a                	jmp    f0102cb4 <vprintfmt+0x23f>
f0102c9a:	89 75 08             	mov    %esi,0x8(%ebp)
f0102c9d:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102ca0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102ca3:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102ca6:	eb 0c                	jmp    f0102cb4 <vprintfmt+0x23f>
f0102ca8:	89 75 08             	mov    %esi,0x8(%ebp)
f0102cab:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102cae:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102cb1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102cb4:	83 c7 01             	add    $0x1,%edi
f0102cb7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102cbb:	0f be d0             	movsbl %al,%edx
f0102cbe:	85 d2                	test   %edx,%edx
f0102cc0:	74 23                	je     f0102ce5 <vprintfmt+0x270>
f0102cc2:	85 f6                	test   %esi,%esi
f0102cc4:	78 a1                	js     f0102c67 <vprintfmt+0x1f2>
f0102cc6:	83 ee 01             	sub    $0x1,%esi
f0102cc9:	79 9c                	jns    f0102c67 <vprintfmt+0x1f2>
f0102ccb:	89 df                	mov    %ebx,%edi
f0102ccd:	8b 75 08             	mov    0x8(%ebp),%esi
f0102cd0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102cd3:	eb 18                	jmp    f0102ced <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102cd5:	83 ec 08             	sub    $0x8,%esp
f0102cd8:	53                   	push   %ebx
f0102cd9:	6a 20                	push   $0x20
f0102cdb:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102cdd:	83 ef 01             	sub    $0x1,%edi
f0102ce0:	83 c4 10             	add    $0x10,%esp
f0102ce3:	eb 08                	jmp    f0102ced <vprintfmt+0x278>
f0102ce5:	89 df                	mov    %ebx,%edi
f0102ce7:	8b 75 08             	mov    0x8(%ebp),%esi
f0102cea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102ced:	85 ff                	test   %edi,%edi
f0102cef:	7f e4                	jg     f0102cd5 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cf1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cf4:	e9 a2 fd ff ff       	jmp    f0102a9b <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102cf9:	8d 45 14             	lea    0x14(%ebp),%eax
f0102cfc:	e8 08 fd ff ff       	call   f0102a09 <getint>
f0102d01:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102d04:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102d07:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102d0c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102d10:	79 74                	jns    f0102d86 <vprintfmt+0x311>
				putch('-', putdat);
f0102d12:	83 ec 08             	sub    $0x8,%esp
f0102d15:	53                   	push   %ebx
f0102d16:	6a 2d                	push   $0x2d
f0102d18:	ff d6                	call   *%esi
				num = -(long long) num;
f0102d1a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d1d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102d20:	f7 d8                	neg    %eax
f0102d22:	83 d2 00             	adc    $0x0,%edx
f0102d25:	f7 da                	neg    %edx
f0102d27:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102d2a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102d2f:	eb 55                	jmp    f0102d86 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102d31:	8d 45 14             	lea    0x14(%ebp),%eax
f0102d34:	e8 96 fc ff ff       	call   f01029cf <getuint>
			base = 10;
f0102d39:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102d3e:	eb 46                	jmp    f0102d86 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0102d40:	8d 45 14             	lea    0x14(%ebp),%eax
f0102d43:	e8 87 fc ff ff       	call   f01029cf <getuint>
			base = 8;
f0102d48:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102d4d:	eb 37                	jmp    f0102d86 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0102d4f:	83 ec 08             	sub    $0x8,%esp
f0102d52:	53                   	push   %ebx
f0102d53:	6a 30                	push   $0x30
f0102d55:	ff d6                	call   *%esi
			putch('x', putdat);
f0102d57:	83 c4 08             	add    $0x8,%esp
f0102d5a:	53                   	push   %ebx
f0102d5b:	6a 78                	push   $0x78
f0102d5d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102d5f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d62:	8d 50 04             	lea    0x4(%eax),%edx
f0102d65:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102d68:	8b 00                	mov    (%eax),%eax
f0102d6a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102d6f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102d72:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102d77:	eb 0d                	jmp    f0102d86 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102d79:	8d 45 14             	lea    0x14(%ebp),%eax
f0102d7c:	e8 4e fc ff ff       	call   f01029cf <getuint>
			base = 16;
f0102d81:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102d86:	83 ec 0c             	sub    $0xc,%esp
f0102d89:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102d8d:	57                   	push   %edi
f0102d8e:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d91:	51                   	push   %ecx
f0102d92:	52                   	push   %edx
f0102d93:	50                   	push   %eax
f0102d94:	89 da                	mov    %ebx,%edx
f0102d96:	89 f0                	mov    %esi,%eax
f0102d98:	e8 83 fb ff ff       	call   f0102920 <printnum>
			break;
f0102d9d:	83 c4 20             	add    $0x20,%esp
f0102da0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102da3:	e9 f3 fc ff ff       	jmp    f0102a9b <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102da8:	83 ec 08             	sub    $0x8,%esp
f0102dab:	53                   	push   %ebx
f0102dac:	51                   	push   %ecx
f0102dad:	ff d6                	call   *%esi
			break;
f0102daf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102db2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102db5:	e9 e1 fc ff ff       	jmp    f0102a9b <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102dba:	83 ec 08             	sub    $0x8,%esp
f0102dbd:	53                   	push   %ebx
f0102dbe:	6a 25                	push   $0x25
f0102dc0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102dc2:	83 c4 10             	add    $0x10,%esp
f0102dc5:	eb 03                	jmp    f0102dca <vprintfmt+0x355>
f0102dc7:	83 ef 01             	sub    $0x1,%edi
f0102dca:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102dce:	75 f7                	jne    f0102dc7 <vprintfmt+0x352>
f0102dd0:	e9 c6 fc ff ff       	jmp    f0102a9b <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102dd5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dd8:	5b                   	pop    %ebx
f0102dd9:	5e                   	pop    %esi
f0102dda:	5f                   	pop    %edi
f0102ddb:	5d                   	pop    %ebp
f0102ddc:	c3                   	ret    

f0102ddd <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102ddd:	55                   	push   %ebp
f0102dde:	89 e5                	mov    %esp,%ebp
f0102de0:	83 ec 18             	sub    $0x18,%esp
f0102de3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102de6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102de9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102dec:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102df0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102df3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102dfa:	85 c0                	test   %eax,%eax
f0102dfc:	74 26                	je     f0102e24 <vsnprintf+0x47>
f0102dfe:	85 d2                	test   %edx,%edx
f0102e00:	7e 22                	jle    f0102e24 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102e02:	ff 75 14             	pushl  0x14(%ebp)
f0102e05:	ff 75 10             	pushl  0x10(%ebp)
f0102e08:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102e0b:	50                   	push   %eax
f0102e0c:	68 3b 2a 10 f0       	push   $0xf0102a3b
f0102e11:	e8 5f fc ff ff       	call   f0102a75 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102e16:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102e19:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102e1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e1f:	83 c4 10             	add    $0x10,%esp
f0102e22:	eb 05                	jmp    f0102e29 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102e24:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102e29:	c9                   	leave  
f0102e2a:	c3                   	ret    

f0102e2b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102e2b:	55                   	push   %ebp
f0102e2c:	89 e5                	mov    %esp,%ebp
f0102e2e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102e31:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102e34:	50                   	push   %eax
f0102e35:	ff 75 10             	pushl  0x10(%ebp)
f0102e38:	ff 75 0c             	pushl  0xc(%ebp)
f0102e3b:	ff 75 08             	pushl  0x8(%ebp)
f0102e3e:	e8 9a ff ff ff       	call   f0102ddd <vsnprintf>
	va_end(ap);

	return rc;
}
f0102e43:	c9                   	leave  
f0102e44:	c3                   	ret    

f0102e45 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102e45:	55                   	push   %ebp
f0102e46:	89 e5                	mov    %esp,%ebp
f0102e48:	57                   	push   %edi
f0102e49:	56                   	push   %esi
f0102e4a:	53                   	push   %ebx
f0102e4b:	83 ec 0c             	sub    $0xc,%esp
f0102e4e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102e51:	85 c0                	test   %eax,%eax
f0102e53:	74 11                	je     f0102e66 <readline+0x21>
		cprintf("%s", prompt);
f0102e55:	83 ec 08             	sub    $0x8,%esp
f0102e58:	50                   	push   %eax
f0102e59:	68 43 42 10 f0       	push   $0xf0104243
f0102e5e:	e8 95 f7 ff ff       	call   f01025f8 <cprintf>
f0102e63:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102e66:	83 ec 0c             	sub    $0xc,%esp
f0102e69:	6a 00                	push   $0x0
f0102e6b:	e8 b6 d8 ff ff       	call   f0100726 <iscons>
f0102e70:	89 c7                	mov    %eax,%edi
f0102e72:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102e75:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102e7a:	e8 96 d8 ff ff       	call   f0100715 <getchar>
f0102e7f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102e81:	85 c0                	test   %eax,%eax
f0102e83:	79 18                	jns    f0102e9d <readline+0x58>
			cprintf("read error: %e\n", c);
f0102e85:	83 ec 08             	sub    $0x8,%esp
f0102e88:	50                   	push   %eax
f0102e89:	68 48 47 10 f0       	push   $0xf0104748
f0102e8e:	e8 65 f7 ff ff       	call   f01025f8 <cprintf>
			return NULL;
f0102e93:	83 c4 10             	add    $0x10,%esp
f0102e96:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e9b:	eb 79                	jmp    f0102f16 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102e9d:	83 f8 08             	cmp    $0x8,%eax
f0102ea0:	0f 94 c2             	sete   %dl
f0102ea3:	83 f8 7f             	cmp    $0x7f,%eax
f0102ea6:	0f 94 c0             	sete   %al
f0102ea9:	08 c2                	or     %al,%dl
f0102eab:	74 1a                	je     f0102ec7 <readline+0x82>
f0102ead:	85 f6                	test   %esi,%esi
f0102eaf:	7e 16                	jle    f0102ec7 <readline+0x82>
			if (echoing)
f0102eb1:	85 ff                	test   %edi,%edi
f0102eb3:	74 0d                	je     f0102ec2 <readline+0x7d>
				cputchar('\b');
f0102eb5:	83 ec 0c             	sub    $0xc,%esp
f0102eb8:	6a 08                	push   $0x8
f0102eba:	e8 46 d8 ff ff       	call   f0100705 <cputchar>
f0102ebf:	83 c4 10             	add    $0x10,%esp
			i--;
f0102ec2:	83 ee 01             	sub    $0x1,%esi
f0102ec5:	eb b3                	jmp    f0102e7a <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102ec7:	83 fb 1f             	cmp    $0x1f,%ebx
f0102eca:	7e 23                	jle    f0102eef <readline+0xaa>
f0102ecc:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102ed2:	7f 1b                	jg     f0102eef <readline+0xaa>
			if (echoing)
f0102ed4:	85 ff                	test   %edi,%edi
f0102ed6:	74 0c                	je     f0102ee4 <readline+0x9f>
				cputchar(c);
f0102ed8:	83 ec 0c             	sub    $0xc,%esp
f0102edb:	53                   	push   %ebx
f0102edc:	e8 24 d8 ff ff       	call   f0100705 <cputchar>
f0102ee1:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102ee4:	88 9e 40 75 11 f0    	mov    %bl,-0xfee8ac0(%esi)
f0102eea:	8d 76 01             	lea    0x1(%esi),%esi
f0102eed:	eb 8b                	jmp    f0102e7a <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102eef:	83 fb 0a             	cmp    $0xa,%ebx
f0102ef2:	74 05                	je     f0102ef9 <readline+0xb4>
f0102ef4:	83 fb 0d             	cmp    $0xd,%ebx
f0102ef7:	75 81                	jne    f0102e7a <readline+0x35>
			if (echoing)
f0102ef9:	85 ff                	test   %edi,%edi
f0102efb:	74 0d                	je     f0102f0a <readline+0xc5>
				cputchar('\n');
f0102efd:	83 ec 0c             	sub    $0xc,%esp
f0102f00:	6a 0a                	push   $0xa
f0102f02:	e8 fe d7 ff ff       	call   f0100705 <cputchar>
f0102f07:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0102f0a:	c6 86 40 75 11 f0 00 	movb   $0x0,-0xfee8ac0(%esi)
			return buf;
f0102f11:	b8 40 75 11 f0       	mov    $0xf0117540,%eax
		}
	}
}
f0102f16:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f19:	5b                   	pop    %ebx
f0102f1a:	5e                   	pop    %esi
f0102f1b:	5f                   	pop    %edi
f0102f1c:	5d                   	pop    %ebp
f0102f1d:	c3                   	ret    

f0102f1e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102f1e:	55                   	push   %ebp
f0102f1f:	89 e5                	mov    %esp,%ebp
f0102f21:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f24:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f29:	eb 03                	jmp    f0102f2e <strlen+0x10>
		n++;
f0102f2b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f2e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102f32:	75 f7                	jne    f0102f2b <strlen+0xd>
		n++;
	return n;
}
f0102f34:	5d                   	pop    %ebp
f0102f35:	c3                   	ret    

f0102f36 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102f36:	55                   	push   %ebp
f0102f37:	89 e5                	mov    %esp,%ebp
f0102f39:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102f3c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102f3f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102f44:	eb 03                	jmp    f0102f49 <strnlen+0x13>
		n++;
f0102f46:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102f49:	39 c2                	cmp    %eax,%edx
f0102f4b:	74 08                	je     f0102f55 <strnlen+0x1f>
f0102f4d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0102f51:	75 f3                	jne    f0102f46 <strnlen+0x10>
f0102f53:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0102f55:	5d                   	pop    %ebp
f0102f56:	c3                   	ret    

f0102f57 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102f57:	55                   	push   %ebp
f0102f58:	89 e5                	mov    %esp,%ebp
f0102f5a:	53                   	push   %ebx
f0102f5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f5e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102f61:	89 c2                	mov    %eax,%edx
f0102f63:	83 c2 01             	add    $0x1,%edx
f0102f66:	83 c1 01             	add    $0x1,%ecx
f0102f69:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0102f6d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0102f70:	84 db                	test   %bl,%bl
f0102f72:	75 ef                	jne    f0102f63 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0102f74:	5b                   	pop    %ebx
f0102f75:	5d                   	pop    %ebp
f0102f76:	c3                   	ret    

f0102f77 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0102f77:	55                   	push   %ebp
f0102f78:	89 e5                	mov    %esp,%ebp
f0102f7a:	53                   	push   %ebx
f0102f7b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0102f7e:	53                   	push   %ebx
f0102f7f:	e8 9a ff ff ff       	call   f0102f1e <strlen>
f0102f84:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102f87:	ff 75 0c             	pushl  0xc(%ebp)
f0102f8a:	01 d8                	add    %ebx,%eax
f0102f8c:	50                   	push   %eax
f0102f8d:	e8 c5 ff ff ff       	call   f0102f57 <strcpy>
	return dst;
}
f0102f92:	89 d8                	mov    %ebx,%eax
f0102f94:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f97:	c9                   	leave  
f0102f98:	c3                   	ret    

f0102f99 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102f99:	55                   	push   %ebp
f0102f9a:	89 e5                	mov    %esp,%ebp
f0102f9c:	56                   	push   %esi
f0102f9d:	53                   	push   %ebx
f0102f9e:	8b 75 08             	mov    0x8(%ebp),%esi
f0102fa1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102fa4:	89 f3                	mov    %esi,%ebx
f0102fa6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102fa9:	89 f2                	mov    %esi,%edx
f0102fab:	eb 0f                	jmp    f0102fbc <strncpy+0x23>
		*dst++ = *src;
f0102fad:	83 c2 01             	add    $0x1,%edx
f0102fb0:	0f b6 01             	movzbl (%ecx),%eax
f0102fb3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102fb6:	80 39 01             	cmpb   $0x1,(%ecx)
f0102fb9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102fbc:	39 da                	cmp    %ebx,%edx
f0102fbe:	75 ed                	jne    f0102fad <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0102fc0:	89 f0                	mov    %esi,%eax
f0102fc2:	5b                   	pop    %ebx
f0102fc3:	5e                   	pop    %esi
f0102fc4:	5d                   	pop    %ebp
f0102fc5:	c3                   	ret    

f0102fc6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0102fc6:	55                   	push   %ebp
f0102fc7:	89 e5                	mov    %esp,%ebp
f0102fc9:	56                   	push   %esi
f0102fca:	53                   	push   %ebx
f0102fcb:	8b 75 08             	mov    0x8(%ebp),%esi
f0102fce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102fd1:	8b 55 10             	mov    0x10(%ebp),%edx
f0102fd4:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102fd6:	85 d2                	test   %edx,%edx
f0102fd8:	74 21                	je     f0102ffb <strlcpy+0x35>
f0102fda:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0102fde:	89 f2                	mov    %esi,%edx
f0102fe0:	eb 09                	jmp    f0102feb <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102fe2:	83 c2 01             	add    $0x1,%edx
f0102fe5:	83 c1 01             	add    $0x1,%ecx
f0102fe8:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0102feb:	39 c2                	cmp    %eax,%edx
f0102fed:	74 09                	je     f0102ff8 <strlcpy+0x32>
f0102fef:	0f b6 19             	movzbl (%ecx),%ebx
f0102ff2:	84 db                	test   %bl,%bl
f0102ff4:	75 ec                	jne    f0102fe2 <strlcpy+0x1c>
f0102ff6:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0102ff8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0102ffb:	29 f0                	sub    %esi,%eax
}
f0102ffd:	5b                   	pop    %ebx
f0102ffe:	5e                   	pop    %esi
f0102fff:	5d                   	pop    %ebp
f0103000:	c3                   	ret    

f0103001 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103001:	55                   	push   %ebp
f0103002:	89 e5                	mov    %esp,%ebp
f0103004:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103007:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010300a:	eb 06                	jmp    f0103012 <strcmp+0x11>
		p++, q++;
f010300c:	83 c1 01             	add    $0x1,%ecx
f010300f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103012:	0f b6 01             	movzbl (%ecx),%eax
f0103015:	84 c0                	test   %al,%al
f0103017:	74 04                	je     f010301d <strcmp+0x1c>
f0103019:	3a 02                	cmp    (%edx),%al
f010301b:	74 ef                	je     f010300c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010301d:	0f b6 c0             	movzbl %al,%eax
f0103020:	0f b6 12             	movzbl (%edx),%edx
f0103023:	29 d0                	sub    %edx,%eax
}
f0103025:	5d                   	pop    %ebp
f0103026:	c3                   	ret    

f0103027 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103027:	55                   	push   %ebp
f0103028:	89 e5                	mov    %esp,%ebp
f010302a:	53                   	push   %ebx
f010302b:	8b 45 08             	mov    0x8(%ebp),%eax
f010302e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103031:	89 c3                	mov    %eax,%ebx
f0103033:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103036:	eb 06                	jmp    f010303e <strncmp+0x17>
		n--, p++, q++;
f0103038:	83 c0 01             	add    $0x1,%eax
f010303b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010303e:	39 d8                	cmp    %ebx,%eax
f0103040:	74 15                	je     f0103057 <strncmp+0x30>
f0103042:	0f b6 08             	movzbl (%eax),%ecx
f0103045:	84 c9                	test   %cl,%cl
f0103047:	74 04                	je     f010304d <strncmp+0x26>
f0103049:	3a 0a                	cmp    (%edx),%cl
f010304b:	74 eb                	je     f0103038 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010304d:	0f b6 00             	movzbl (%eax),%eax
f0103050:	0f b6 12             	movzbl (%edx),%edx
f0103053:	29 d0                	sub    %edx,%eax
f0103055:	eb 05                	jmp    f010305c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103057:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010305c:	5b                   	pop    %ebx
f010305d:	5d                   	pop    %ebp
f010305e:	c3                   	ret    

f010305f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010305f:	55                   	push   %ebp
f0103060:	89 e5                	mov    %esp,%ebp
f0103062:	8b 45 08             	mov    0x8(%ebp),%eax
f0103065:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103069:	eb 07                	jmp    f0103072 <strchr+0x13>
		if (*s == c)
f010306b:	38 ca                	cmp    %cl,%dl
f010306d:	74 0f                	je     f010307e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010306f:	83 c0 01             	add    $0x1,%eax
f0103072:	0f b6 10             	movzbl (%eax),%edx
f0103075:	84 d2                	test   %dl,%dl
f0103077:	75 f2                	jne    f010306b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103079:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010307e:	5d                   	pop    %ebp
f010307f:	c3                   	ret    

f0103080 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103080:	55                   	push   %ebp
f0103081:	89 e5                	mov    %esp,%ebp
f0103083:	8b 45 08             	mov    0x8(%ebp),%eax
f0103086:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010308a:	eb 03                	jmp    f010308f <strfind+0xf>
f010308c:	83 c0 01             	add    $0x1,%eax
f010308f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103092:	38 ca                	cmp    %cl,%dl
f0103094:	74 04                	je     f010309a <strfind+0x1a>
f0103096:	84 d2                	test   %dl,%dl
f0103098:	75 f2                	jne    f010308c <strfind+0xc>
			break;
	return (char *) s;
}
f010309a:	5d                   	pop    %ebp
f010309b:	c3                   	ret    

f010309c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010309c:	55                   	push   %ebp
f010309d:	89 e5                	mov    %esp,%ebp
f010309f:	57                   	push   %edi
f01030a0:	56                   	push   %esi
f01030a1:	53                   	push   %ebx
f01030a2:	8b 55 08             	mov    0x8(%ebp),%edx
f01030a5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f01030a8:	85 c9                	test   %ecx,%ecx
f01030aa:	74 37                	je     f01030e3 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01030ac:	f6 c2 03             	test   $0x3,%dl
f01030af:	75 2a                	jne    f01030db <memset+0x3f>
f01030b1:	f6 c1 03             	test   $0x3,%cl
f01030b4:	75 25                	jne    f01030db <memset+0x3f>
		c &= 0xFF;
f01030b6:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01030ba:	89 df                	mov    %ebx,%edi
f01030bc:	c1 e7 08             	shl    $0x8,%edi
f01030bf:	89 de                	mov    %ebx,%esi
f01030c1:	c1 e6 18             	shl    $0x18,%esi
f01030c4:	89 d8                	mov    %ebx,%eax
f01030c6:	c1 e0 10             	shl    $0x10,%eax
f01030c9:	09 f0                	or     %esi,%eax
f01030cb:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f01030cd:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01030d0:	89 f8                	mov    %edi,%eax
f01030d2:	09 d8                	or     %ebx,%eax
f01030d4:	89 d7                	mov    %edx,%edi
f01030d6:	fc                   	cld    
f01030d7:	f3 ab                	rep stos %eax,%es:(%edi)
f01030d9:	eb 08                	jmp    f01030e3 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01030db:	89 d7                	mov    %edx,%edi
f01030dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030e0:	fc                   	cld    
f01030e1:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f01030e3:	89 d0                	mov    %edx,%eax
f01030e5:	5b                   	pop    %ebx
f01030e6:	5e                   	pop    %esi
f01030e7:	5f                   	pop    %edi
f01030e8:	5d                   	pop    %ebp
f01030e9:	c3                   	ret    

f01030ea <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01030ea:	55                   	push   %ebp
f01030eb:	89 e5                	mov    %esp,%ebp
f01030ed:	57                   	push   %edi
f01030ee:	56                   	push   %esi
f01030ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01030f2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01030f5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01030f8:	39 c6                	cmp    %eax,%esi
f01030fa:	73 35                	jae    f0103131 <memmove+0x47>
f01030fc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01030ff:	39 d0                	cmp    %edx,%eax
f0103101:	73 2e                	jae    f0103131 <memmove+0x47>
		s += n;
		d += n;
f0103103:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103106:	89 d6                	mov    %edx,%esi
f0103108:	09 fe                	or     %edi,%esi
f010310a:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103110:	75 13                	jne    f0103125 <memmove+0x3b>
f0103112:	f6 c1 03             	test   $0x3,%cl
f0103115:	75 0e                	jne    f0103125 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103117:	83 ef 04             	sub    $0x4,%edi
f010311a:	8d 72 fc             	lea    -0x4(%edx),%esi
f010311d:	c1 e9 02             	shr    $0x2,%ecx
f0103120:	fd                   	std    
f0103121:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103123:	eb 09                	jmp    f010312e <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103125:	83 ef 01             	sub    $0x1,%edi
f0103128:	8d 72 ff             	lea    -0x1(%edx),%esi
f010312b:	fd                   	std    
f010312c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010312e:	fc                   	cld    
f010312f:	eb 1d                	jmp    f010314e <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103131:	89 f2                	mov    %esi,%edx
f0103133:	09 c2                	or     %eax,%edx
f0103135:	f6 c2 03             	test   $0x3,%dl
f0103138:	75 0f                	jne    f0103149 <memmove+0x5f>
f010313a:	f6 c1 03             	test   $0x3,%cl
f010313d:	75 0a                	jne    f0103149 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010313f:	c1 e9 02             	shr    $0x2,%ecx
f0103142:	89 c7                	mov    %eax,%edi
f0103144:	fc                   	cld    
f0103145:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103147:	eb 05                	jmp    f010314e <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103149:	89 c7                	mov    %eax,%edi
f010314b:	fc                   	cld    
f010314c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010314e:	5e                   	pop    %esi
f010314f:	5f                   	pop    %edi
f0103150:	5d                   	pop    %ebp
f0103151:	c3                   	ret    

f0103152 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103152:	55                   	push   %ebp
f0103153:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103155:	ff 75 10             	pushl  0x10(%ebp)
f0103158:	ff 75 0c             	pushl  0xc(%ebp)
f010315b:	ff 75 08             	pushl  0x8(%ebp)
f010315e:	e8 87 ff ff ff       	call   f01030ea <memmove>
}
f0103163:	c9                   	leave  
f0103164:	c3                   	ret    

f0103165 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103165:	55                   	push   %ebp
f0103166:	89 e5                	mov    %esp,%ebp
f0103168:	56                   	push   %esi
f0103169:	53                   	push   %ebx
f010316a:	8b 45 08             	mov    0x8(%ebp),%eax
f010316d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103170:	89 c6                	mov    %eax,%esi
f0103172:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103175:	eb 1a                	jmp    f0103191 <memcmp+0x2c>
		if (*s1 != *s2)
f0103177:	0f b6 08             	movzbl (%eax),%ecx
f010317a:	0f b6 1a             	movzbl (%edx),%ebx
f010317d:	38 d9                	cmp    %bl,%cl
f010317f:	74 0a                	je     f010318b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103181:	0f b6 c1             	movzbl %cl,%eax
f0103184:	0f b6 db             	movzbl %bl,%ebx
f0103187:	29 d8                	sub    %ebx,%eax
f0103189:	eb 0f                	jmp    f010319a <memcmp+0x35>
		s1++, s2++;
f010318b:	83 c0 01             	add    $0x1,%eax
f010318e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103191:	39 f0                	cmp    %esi,%eax
f0103193:	75 e2                	jne    f0103177 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103195:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010319a:	5b                   	pop    %ebx
f010319b:	5e                   	pop    %esi
f010319c:	5d                   	pop    %ebp
f010319d:	c3                   	ret    

f010319e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010319e:	55                   	push   %ebp
f010319f:	89 e5                	mov    %esp,%ebp
f01031a1:	53                   	push   %ebx
f01031a2:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01031a5:	89 c1                	mov    %eax,%ecx
f01031a7:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01031aa:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01031ae:	eb 0a                	jmp    f01031ba <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01031b0:	0f b6 10             	movzbl (%eax),%edx
f01031b3:	39 da                	cmp    %ebx,%edx
f01031b5:	74 07                	je     f01031be <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01031b7:	83 c0 01             	add    $0x1,%eax
f01031ba:	39 c8                	cmp    %ecx,%eax
f01031bc:	72 f2                	jb     f01031b0 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01031be:	5b                   	pop    %ebx
f01031bf:	5d                   	pop    %ebp
f01031c0:	c3                   	ret    

f01031c1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01031c1:	55                   	push   %ebp
f01031c2:	89 e5                	mov    %esp,%ebp
f01031c4:	57                   	push   %edi
f01031c5:	56                   	push   %esi
f01031c6:	53                   	push   %ebx
f01031c7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031ca:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01031cd:	eb 03                	jmp    f01031d2 <strtol+0x11>
		s++;
f01031cf:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01031d2:	0f b6 01             	movzbl (%ecx),%eax
f01031d5:	3c 20                	cmp    $0x20,%al
f01031d7:	74 f6                	je     f01031cf <strtol+0xe>
f01031d9:	3c 09                	cmp    $0x9,%al
f01031db:	74 f2                	je     f01031cf <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01031dd:	3c 2b                	cmp    $0x2b,%al
f01031df:	75 0a                	jne    f01031eb <strtol+0x2a>
		s++;
f01031e1:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01031e4:	bf 00 00 00 00       	mov    $0x0,%edi
f01031e9:	eb 11                	jmp    f01031fc <strtol+0x3b>
f01031eb:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01031f0:	3c 2d                	cmp    $0x2d,%al
f01031f2:	75 08                	jne    f01031fc <strtol+0x3b>
		s++, neg = 1;
f01031f4:	83 c1 01             	add    $0x1,%ecx
f01031f7:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01031fc:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103202:	75 15                	jne    f0103219 <strtol+0x58>
f0103204:	80 39 30             	cmpb   $0x30,(%ecx)
f0103207:	75 10                	jne    f0103219 <strtol+0x58>
f0103209:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010320d:	75 7c                	jne    f010328b <strtol+0xca>
		s += 2, base = 16;
f010320f:	83 c1 02             	add    $0x2,%ecx
f0103212:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103217:	eb 16                	jmp    f010322f <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103219:	85 db                	test   %ebx,%ebx
f010321b:	75 12                	jne    f010322f <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010321d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103222:	80 39 30             	cmpb   $0x30,(%ecx)
f0103225:	75 08                	jne    f010322f <strtol+0x6e>
		s++, base = 8;
f0103227:	83 c1 01             	add    $0x1,%ecx
f010322a:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010322f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103234:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103237:	0f b6 11             	movzbl (%ecx),%edx
f010323a:	8d 72 d0             	lea    -0x30(%edx),%esi
f010323d:	89 f3                	mov    %esi,%ebx
f010323f:	80 fb 09             	cmp    $0x9,%bl
f0103242:	77 08                	ja     f010324c <strtol+0x8b>
			dig = *s - '0';
f0103244:	0f be d2             	movsbl %dl,%edx
f0103247:	83 ea 30             	sub    $0x30,%edx
f010324a:	eb 22                	jmp    f010326e <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010324c:	8d 72 9f             	lea    -0x61(%edx),%esi
f010324f:	89 f3                	mov    %esi,%ebx
f0103251:	80 fb 19             	cmp    $0x19,%bl
f0103254:	77 08                	ja     f010325e <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103256:	0f be d2             	movsbl %dl,%edx
f0103259:	83 ea 57             	sub    $0x57,%edx
f010325c:	eb 10                	jmp    f010326e <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010325e:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103261:	89 f3                	mov    %esi,%ebx
f0103263:	80 fb 19             	cmp    $0x19,%bl
f0103266:	77 16                	ja     f010327e <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103268:	0f be d2             	movsbl %dl,%edx
f010326b:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010326e:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103271:	7d 0b                	jge    f010327e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103273:	83 c1 01             	add    $0x1,%ecx
f0103276:	0f af 45 10          	imul   0x10(%ebp),%eax
f010327a:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010327c:	eb b9                	jmp    f0103237 <strtol+0x76>

	if (endptr)
f010327e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103282:	74 0d                	je     f0103291 <strtol+0xd0>
		*endptr = (char *) s;
f0103284:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103287:	89 0e                	mov    %ecx,(%esi)
f0103289:	eb 06                	jmp    f0103291 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010328b:	85 db                	test   %ebx,%ebx
f010328d:	74 98                	je     f0103227 <strtol+0x66>
f010328f:	eb 9e                	jmp    f010322f <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103291:	89 c2                	mov    %eax,%edx
f0103293:	f7 da                	neg    %edx
f0103295:	85 ff                	test   %edi,%edi
f0103297:	0f 45 c2             	cmovne %edx,%eax
}
f010329a:	5b                   	pop    %ebx
f010329b:	5e                   	pop    %esi
f010329c:	5f                   	pop    %edi
f010329d:	5d                   	pop    %ebp
f010329e:	c3                   	ret    
f010329f:	90                   	nop

f01032a0 <__udivdi3>:
f01032a0:	55                   	push   %ebp
f01032a1:	57                   	push   %edi
f01032a2:	56                   	push   %esi
f01032a3:	53                   	push   %ebx
f01032a4:	83 ec 1c             	sub    $0x1c,%esp
f01032a7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01032ab:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01032af:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01032b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01032b7:	85 f6                	test   %esi,%esi
f01032b9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01032bd:	89 ca                	mov    %ecx,%edx
f01032bf:	89 f8                	mov    %edi,%eax
f01032c1:	75 3d                	jne    f0103300 <__udivdi3+0x60>
f01032c3:	39 cf                	cmp    %ecx,%edi
f01032c5:	0f 87 c5 00 00 00    	ja     f0103390 <__udivdi3+0xf0>
f01032cb:	85 ff                	test   %edi,%edi
f01032cd:	89 fd                	mov    %edi,%ebp
f01032cf:	75 0b                	jne    f01032dc <__udivdi3+0x3c>
f01032d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01032d6:	31 d2                	xor    %edx,%edx
f01032d8:	f7 f7                	div    %edi
f01032da:	89 c5                	mov    %eax,%ebp
f01032dc:	89 c8                	mov    %ecx,%eax
f01032de:	31 d2                	xor    %edx,%edx
f01032e0:	f7 f5                	div    %ebp
f01032e2:	89 c1                	mov    %eax,%ecx
f01032e4:	89 d8                	mov    %ebx,%eax
f01032e6:	89 cf                	mov    %ecx,%edi
f01032e8:	f7 f5                	div    %ebp
f01032ea:	89 c3                	mov    %eax,%ebx
f01032ec:	89 d8                	mov    %ebx,%eax
f01032ee:	89 fa                	mov    %edi,%edx
f01032f0:	83 c4 1c             	add    $0x1c,%esp
f01032f3:	5b                   	pop    %ebx
f01032f4:	5e                   	pop    %esi
f01032f5:	5f                   	pop    %edi
f01032f6:	5d                   	pop    %ebp
f01032f7:	c3                   	ret    
f01032f8:	90                   	nop
f01032f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103300:	39 ce                	cmp    %ecx,%esi
f0103302:	77 74                	ja     f0103378 <__udivdi3+0xd8>
f0103304:	0f bd fe             	bsr    %esi,%edi
f0103307:	83 f7 1f             	xor    $0x1f,%edi
f010330a:	0f 84 98 00 00 00    	je     f01033a8 <__udivdi3+0x108>
f0103310:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103315:	89 f9                	mov    %edi,%ecx
f0103317:	89 c5                	mov    %eax,%ebp
f0103319:	29 fb                	sub    %edi,%ebx
f010331b:	d3 e6                	shl    %cl,%esi
f010331d:	89 d9                	mov    %ebx,%ecx
f010331f:	d3 ed                	shr    %cl,%ebp
f0103321:	89 f9                	mov    %edi,%ecx
f0103323:	d3 e0                	shl    %cl,%eax
f0103325:	09 ee                	or     %ebp,%esi
f0103327:	89 d9                	mov    %ebx,%ecx
f0103329:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010332d:	89 d5                	mov    %edx,%ebp
f010332f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103333:	d3 ed                	shr    %cl,%ebp
f0103335:	89 f9                	mov    %edi,%ecx
f0103337:	d3 e2                	shl    %cl,%edx
f0103339:	89 d9                	mov    %ebx,%ecx
f010333b:	d3 e8                	shr    %cl,%eax
f010333d:	09 c2                	or     %eax,%edx
f010333f:	89 d0                	mov    %edx,%eax
f0103341:	89 ea                	mov    %ebp,%edx
f0103343:	f7 f6                	div    %esi
f0103345:	89 d5                	mov    %edx,%ebp
f0103347:	89 c3                	mov    %eax,%ebx
f0103349:	f7 64 24 0c          	mull   0xc(%esp)
f010334d:	39 d5                	cmp    %edx,%ebp
f010334f:	72 10                	jb     f0103361 <__udivdi3+0xc1>
f0103351:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103355:	89 f9                	mov    %edi,%ecx
f0103357:	d3 e6                	shl    %cl,%esi
f0103359:	39 c6                	cmp    %eax,%esi
f010335b:	73 07                	jae    f0103364 <__udivdi3+0xc4>
f010335d:	39 d5                	cmp    %edx,%ebp
f010335f:	75 03                	jne    f0103364 <__udivdi3+0xc4>
f0103361:	83 eb 01             	sub    $0x1,%ebx
f0103364:	31 ff                	xor    %edi,%edi
f0103366:	89 d8                	mov    %ebx,%eax
f0103368:	89 fa                	mov    %edi,%edx
f010336a:	83 c4 1c             	add    $0x1c,%esp
f010336d:	5b                   	pop    %ebx
f010336e:	5e                   	pop    %esi
f010336f:	5f                   	pop    %edi
f0103370:	5d                   	pop    %ebp
f0103371:	c3                   	ret    
f0103372:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103378:	31 ff                	xor    %edi,%edi
f010337a:	31 db                	xor    %ebx,%ebx
f010337c:	89 d8                	mov    %ebx,%eax
f010337e:	89 fa                	mov    %edi,%edx
f0103380:	83 c4 1c             	add    $0x1c,%esp
f0103383:	5b                   	pop    %ebx
f0103384:	5e                   	pop    %esi
f0103385:	5f                   	pop    %edi
f0103386:	5d                   	pop    %ebp
f0103387:	c3                   	ret    
f0103388:	90                   	nop
f0103389:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103390:	89 d8                	mov    %ebx,%eax
f0103392:	f7 f7                	div    %edi
f0103394:	31 ff                	xor    %edi,%edi
f0103396:	89 c3                	mov    %eax,%ebx
f0103398:	89 d8                	mov    %ebx,%eax
f010339a:	89 fa                	mov    %edi,%edx
f010339c:	83 c4 1c             	add    $0x1c,%esp
f010339f:	5b                   	pop    %ebx
f01033a0:	5e                   	pop    %esi
f01033a1:	5f                   	pop    %edi
f01033a2:	5d                   	pop    %ebp
f01033a3:	c3                   	ret    
f01033a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01033a8:	39 ce                	cmp    %ecx,%esi
f01033aa:	72 0c                	jb     f01033b8 <__udivdi3+0x118>
f01033ac:	31 db                	xor    %ebx,%ebx
f01033ae:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01033b2:	0f 87 34 ff ff ff    	ja     f01032ec <__udivdi3+0x4c>
f01033b8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01033bd:	e9 2a ff ff ff       	jmp    f01032ec <__udivdi3+0x4c>
f01033c2:	66 90                	xchg   %ax,%ax
f01033c4:	66 90                	xchg   %ax,%ax
f01033c6:	66 90                	xchg   %ax,%ax
f01033c8:	66 90                	xchg   %ax,%ax
f01033ca:	66 90                	xchg   %ax,%ax
f01033cc:	66 90                	xchg   %ax,%ax
f01033ce:	66 90                	xchg   %ax,%ax

f01033d0 <__umoddi3>:
f01033d0:	55                   	push   %ebp
f01033d1:	57                   	push   %edi
f01033d2:	56                   	push   %esi
f01033d3:	53                   	push   %ebx
f01033d4:	83 ec 1c             	sub    $0x1c,%esp
f01033d7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01033db:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01033df:	8b 74 24 34          	mov    0x34(%esp),%esi
f01033e3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033e7:	85 d2                	test   %edx,%edx
f01033e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01033ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01033f1:	89 f3                	mov    %esi,%ebx
f01033f3:	89 3c 24             	mov    %edi,(%esp)
f01033f6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01033fa:	75 1c                	jne    f0103418 <__umoddi3+0x48>
f01033fc:	39 f7                	cmp    %esi,%edi
f01033fe:	76 50                	jbe    f0103450 <__umoddi3+0x80>
f0103400:	89 c8                	mov    %ecx,%eax
f0103402:	89 f2                	mov    %esi,%edx
f0103404:	f7 f7                	div    %edi
f0103406:	89 d0                	mov    %edx,%eax
f0103408:	31 d2                	xor    %edx,%edx
f010340a:	83 c4 1c             	add    $0x1c,%esp
f010340d:	5b                   	pop    %ebx
f010340e:	5e                   	pop    %esi
f010340f:	5f                   	pop    %edi
f0103410:	5d                   	pop    %ebp
f0103411:	c3                   	ret    
f0103412:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103418:	39 f2                	cmp    %esi,%edx
f010341a:	89 d0                	mov    %edx,%eax
f010341c:	77 52                	ja     f0103470 <__umoddi3+0xa0>
f010341e:	0f bd ea             	bsr    %edx,%ebp
f0103421:	83 f5 1f             	xor    $0x1f,%ebp
f0103424:	75 5a                	jne    f0103480 <__umoddi3+0xb0>
f0103426:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010342a:	0f 82 e0 00 00 00    	jb     f0103510 <__umoddi3+0x140>
f0103430:	39 0c 24             	cmp    %ecx,(%esp)
f0103433:	0f 86 d7 00 00 00    	jbe    f0103510 <__umoddi3+0x140>
f0103439:	8b 44 24 08          	mov    0x8(%esp),%eax
f010343d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103441:	83 c4 1c             	add    $0x1c,%esp
f0103444:	5b                   	pop    %ebx
f0103445:	5e                   	pop    %esi
f0103446:	5f                   	pop    %edi
f0103447:	5d                   	pop    %ebp
f0103448:	c3                   	ret    
f0103449:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103450:	85 ff                	test   %edi,%edi
f0103452:	89 fd                	mov    %edi,%ebp
f0103454:	75 0b                	jne    f0103461 <__umoddi3+0x91>
f0103456:	b8 01 00 00 00       	mov    $0x1,%eax
f010345b:	31 d2                	xor    %edx,%edx
f010345d:	f7 f7                	div    %edi
f010345f:	89 c5                	mov    %eax,%ebp
f0103461:	89 f0                	mov    %esi,%eax
f0103463:	31 d2                	xor    %edx,%edx
f0103465:	f7 f5                	div    %ebp
f0103467:	89 c8                	mov    %ecx,%eax
f0103469:	f7 f5                	div    %ebp
f010346b:	89 d0                	mov    %edx,%eax
f010346d:	eb 99                	jmp    f0103408 <__umoddi3+0x38>
f010346f:	90                   	nop
f0103470:	89 c8                	mov    %ecx,%eax
f0103472:	89 f2                	mov    %esi,%edx
f0103474:	83 c4 1c             	add    $0x1c,%esp
f0103477:	5b                   	pop    %ebx
f0103478:	5e                   	pop    %esi
f0103479:	5f                   	pop    %edi
f010347a:	5d                   	pop    %ebp
f010347b:	c3                   	ret    
f010347c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103480:	8b 34 24             	mov    (%esp),%esi
f0103483:	bf 20 00 00 00       	mov    $0x20,%edi
f0103488:	89 e9                	mov    %ebp,%ecx
f010348a:	29 ef                	sub    %ebp,%edi
f010348c:	d3 e0                	shl    %cl,%eax
f010348e:	89 f9                	mov    %edi,%ecx
f0103490:	89 f2                	mov    %esi,%edx
f0103492:	d3 ea                	shr    %cl,%edx
f0103494:	89 e9                	mov    %ebp,%ecx
f0103496:	09 c2                	or     %eax,%edx
f0103498:	89 d8                	mov    %ebx,%eax
f010349a:	89 14 24             	mov    %edx,(%esp)
f010349d:	89 f2                	mov    %esi,%edx
f010349f:	d3 e2                	shl    %cl,%edx
f01034a1:	89 f9                	mov    %edi,%ecx
f01034a3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01034a7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01034ab:	d3 e8                	shr    %cl,%eax
f01034ad:	89 e9                	mov    %ebp,%ecx
f01034af:	89 c6                	mov    %eax,%esi
f01034b1:	d3 e3                	shl    %cl,%ebx
f01034b3:	89 f9                	mov    %edi,%ecx
f01034b5:	89 d0                	mov    %edx,%eax
f01034b7:	d3 e8                	shr    %cl,%eax
f01034b9:	89 e9                	mov    %ebp,%ecx
f01034bb:	09 d8                	or     %ebx,%eax
f01034bd:	89 d3                	mov    %edx,%ebx
f01034bf:	89 f2                	mov    %esi,%edx
f01034c1:	f7 34 24             	divl   (%esp)
f01034c4:	89 d6                	mov    %edx,%esi
f01034c6:	d3 e3                	shl    %cl,%ebx
f01034c8:	f7 64 24 04          	mull   0x4(%esp)
f01034cc:	39 d6                	cmp    %edx,%esi
f01034ce:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01034d2:	89 d1                	mov    %edx,%ecx
f01034d4:	89 c3                	mov    %eax,%ebx
f01034d6:	72 08                	jb     f01034e0 <__umoddi3+0x110>
f01034d8:	75 11                	jne    f01034eb <__umoddi3+0x11b>
f01034da:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01034de:	73 0b                	jae    f01034eb <__umoddi3+0x11b>
f01034e0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01034e4:	1b 14 24             	sbb    (%esp),%edx
f01034e7:	89 d1                	mov    %edx,%ecx
f01034e9:	89 c3                	mov    %eax,%ebx
f01034eb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01034ef:	29 da                	sub    %ebx,%edx
f01034f1:	19 ce                	sbb    %ecx,%esi
f01034f3:	89 f9                	mov    %edi,%ecx
f01034f5:	89 f0                	mov    %esi,%eax
f01034f7:	d3 e0                	shl    %cl,%eax
f01034f9:	89 e9                	mov    %ebp,%ecx
f01034fb:	d3 ea                	shr    %cl,%edx
f01034fd:	89 e9                	mov    %ebp,%ecx
f01034ff:	d3 ee                	shr    %cl,%esi
f0103501:	09 d0                	or     %edx,%eax
f0103503:	89 f2                	mov    %esi,%edx
f0103505:	83 c4 1c             	add    $0x1c,%esp
f0103508:	5b                   	pop    %ebx
f0103509:	5e                   	pop    %esi
f010350a:	5f                   	pop    %edi
f010350b:	5d                   	pop    %ebp
f010350c:	c3                   	ret    
f010350d:	8d 76 00             	lea    0x0(%esi),%esi
f0103510:	29 f9                	sub    %edi,%ecx
f0103512:	19 d6                	sbb    %edx,%esi
f0103514:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103518:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010351c:	e9 18 ff ff ff       	jmp    f0103439 <__umoddi3+0x69>
