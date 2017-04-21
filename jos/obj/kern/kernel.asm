
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
f0100058:	e8 f3 32 00 00       	call   f0103350 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 78 06 00 00       	call   f01006da <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 00 38 10 f0       	push   $0xf0103800
f010006f:	e8 38 28 00 00       	call   f01028ac <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 50 25 00 00       	call   f01025c9 <mem_init>
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
f01000b0:	68 3c 38 10 f0       	push   $0xf010383c
f01000b5:	e8 f2 27 00 00       	call   f01028ac <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 c2 27 00 00       	call   f0102886 <vcprintf>
	cprintf("\n>>>\n");
f01000c4:	c7 04 24 1b 38 10 f0 	movl   $0xf010381b,(%esp)
f01000cb:	e8 dc 27 00 00       	call   f01028ac <cprintf>
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
f01000f2:	68 21 38 10 f0       	push   $0xf0103821
f01000f7:	e8 b0 27 00 00       	call   f01028ac <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 7e 27 00 00       	call   f0102886 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 3a 4b 10 f0 	movl   $0xf0104b3a,(%esp)
f010010f:	e8 98 27 00 00       	call   f01028ac <cprintf>
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
f01003f7:	0f b6 80 c0 39 10 f0 	movzbl -0xfefc640(%eax),%eax
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
f0100431:	0f b6 90 c0 39 10 f0 	movzbl -0xfefc640(%eax),%edx
f0100438:	0b 15 00 73 11 f0    	or     0xf0117300,%edx
f010043e:	0f b6 88 c0 38 10 f0 	movzbl -0xfefc740(%eax),%ecx
f0100445:	31 ca                	xor    %ecx,%edx
f0100447:	89 15 00 73 11 f0    	mov    %edx,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f010044d:	89 d1                	mov    %edx,%ecx
f010044f:	83 e1 03             	and    $0x3,%ecx
f0100452:	8b 0c 8d a0 38 10 f0 	mov    -0xfefc760(,%ecx,4),%ecx
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
f0100492:	68 5c 38 10 f0       	push   $0xf010385c
f0100497:	e8 10 24 00 00       	call   f01028ac <cprintf>
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
f01005ce:	e8 cb 2d 00 00       	call   f010339e <memmove>
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
f01006f6:	68 68 38 10 f0       	push   $0xf0103868
f01006fb:	e8 ac 21 00 00       	call   f01028ac <cprintf>
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
f0100736:	68 c0 3a 10 f0       	push   $0xf0103ac0
f010073b:	68 de 3a 10 f0       	push   $0xf0103ade
f0100740:	68 e3 3a 10 f0       	push   $0xf0103ae3
f0100745:	e8 62 21 00 00       	call   f01028ac <cprintf>
f010074a:	83 c4 0c             	add    $0xc,%esp
f010074d:	68 80 3b 10 f0       	push   $0xf0103b80
f0100752:	68 ec 3a 10 f0       	push   $0xf0103aec
f0100757:	68 e3 3a 10 f0       	push   $0xf0103ae3
f010075c:	e8 4b 21 00 00       	call   f01028ac <cprintf>
f0100761:	83 c4 0c             	add    $0xc,%esp
f0100764:	68 f5 3a 10 f0       	push   $0xf0103af5
f0100769:	68 09 3b 10 f0       	push   $0xf0103b09
f010076e:	68 e3 3a 10 f0       	push   $0xf0103ae3
f0100773:	e8 34 21 00 00       	call   f01028ac <cprintf>
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
f0100785:	68 13 3b 10 f0       	push   $0xf0103b13
f010078a:	e8 1d 21 00 00       	call   f01028ac <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010078f:	83 c4 08             	add    $0x8,%esp
f0100792:	68 0c 00 10 00       	push   $0x10000c
f0100797:	68 a8 3b 10 f0       	push   $0xf0103ba8
f010079c:	e8 0b 21 00 00       	call   f01028ac <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	68 0c 00 10 00       	push   $0x10000c
f01007a9:	68 0c 00 10 f0       	push   $0xf010000c
f01007ae:	68 d0 3b 10 f0       	push   $0xf0103bd0
f01007b3:	e8 f4 20 00 00       	call   f01028ac <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007b8:	83 c4 0c             	add    $0xc,%esp
f01007bb:	68 e1 37 10 00       	push   $0x1037e1
f01007c0:	68 e1 37 10 f0       	push   $0xf01037e1
f01007c5:	68 f4 3b 10 f0       	push   $0xf0103bf4
f01007ca:	e8 dd 20 00 00       	call   f01028ac <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cf:	83 c4 0c             	add    $0xc,%esp
f01007d2:	68 00 73 11 00       	push   $0x117300
f01007d7:	68 00 73 11 f0       	push   $0xf0117300
f01007dc:	68 18 3c 10 f0       	push   $0xf0103c18
f01007e1:	e8 c6 20 00 00       	call   f01028ac <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e6:	83 c4 0c             	add    $0xc,%esp
f01007e9:	68 50 79 11 00       	push   $0x117950
f01007ee:	68 50 79 11 f0       	push   $0xf0117950
f01007f3:	68 3c 3c 10 f0       	push   $0xf0103c3c
f01007f8:	e8 af 20 00 00       	call   f01028ac <cprintf>
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
f010081e:	68 60 3c 10 f0       	push   $0xf0103c60
f0100823:	e8 84 20 00 00       	call   f01028ac <cprintf>
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
f0100853:	68 8c 3c 10 f0       	push   $0xf0103c8c
f0100858:	e8 4f 20 00 00       	call   f01028ac <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f010085d:	83 c4 18             	add    $0x18,%esp
f0100860:	57                   	push   %edi
f0100861:	56                   	push   %esi
f0100862:	e8 4f 21 00 00       	call   f01029b6 <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100867:	83 c4 08             	add    $0x8,%esp
f010086a:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010086d:	56                   	push   %esi
f010086e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100871:	ff 75 dc             	pushl  -0x24(%ebp)
f0100874:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100877:	ff 75 d0             	pushl  -0x30(%ebp)
f010087a:	68 2c 3b 10 f0       	push   $0xf0103b2c
f010087f:	e8 28 20 00 00       	call   f01028ac <cprintf>
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
f01008ce:	68 43 3b 10 f0       	push   $0xf0103b43
f01008d3:	e8 3b 2a 00 00       	call   f0103313 <strchr>
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
f01008f0:	68 48 3b 10 f0       	push   $0xf0103b48
f01008f5:	e8 b2 1f 00 00       	call   f01028ac <cprintf>
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
f0100921:	68 43 3b 10 f0       	push   $0xf0103b43
f0100926:	e8 e8 29 00 00       	call   f0103313 <strchr>
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
f0100950:	ff 34 85 20 3d 10 f0 	pushl  -0xfefc2e0(,%eax,4)
f0100957:	ff 75 a8             	pushl  -0x58(%ebp)
f010095a:	e8 56 29 00 00       	call   f01032b5 <strcmp>
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
f0100974:	ff 14 85 28 3d 10 f0 	call   *-0xfefc2d8(,%eax,4)
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
f010098e:	68 65 3b 10 f0       	push   $0xf0103b65
f0100993:	e8 14 1f 00 00       	call   f01028ac <cprintf>
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
f01009b2:	68 c0 3c 10 f0       	push   $0xf0103cc0
f01009b7:	e8 f0 1e 00 00       	call   f01028ac <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009bc:	c7 04 24 e4 3c 10 f0 	movl   $0xf0103ce4,(%esp)
f01009c3:	e8 e4 1e 00 00       	call   f01028ac <cprintf>
f01009c8:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009cb:	83 ec 0c             	sub    $0xc,%esp
f01009ce:	68 7b 3b 10 f0       	push   $0xf0103b7b
f01009d3:	e8 21 27 00 00       	call   f01030f9 <readline>
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
f0100a2b:	e8 02 1e 00 00       	call   f0102832 <mc146818_read>
f0100a30:	89 c6                	mov    %eax,%esi
f0100a32:	83 c3 01             	add    $0x1,%ebx
f0100a35:	89 1c 24             	mov    %ebx,(%esp)
f0100a38:	e8 f5 1d 00 00       	call   f0102832 <mc146818_read>
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
f0100a9b:	68 44 3d 10 f0       	push   $0xf0103d44
f0100aa0:	e8 07 1e 00 00       	call   f01028ac <cprintf>
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
f0100b05:	68 c4 46 10 f0       	push   $0xf01046c4
f0100b0a:	6a 6d                	push   $0x6d
f0100b0c:	68 d7 46 10 f0       	push   $0xf01046d7
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
f0100b2e:	68 80 3d 10 f0       	push   $0xf0103d80
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
f0100b57:	b8 e3 46 10 f0       	mov    $0xf01046e3,%eax
f0100b5c:	e8 b8 ff ff ff       	call   f0100b19 <_kaddr>
}
f0100b61:	c9                   	leave  
f0100b62:	c3                   	ret    

f0100b63 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b63:	55                   	push   %ebp
f0100b64:	89 e5                	mov    %esp,%ebp
f0100b66:	56                   	push   %esi
f0100b67:	53                   	push   %ebx
f0100b68:	89 d3                	mov    %edx,%ebx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b6a:	c1 ea 16             	shr    $0x16,%edx
f0100b6d:	8d 34 90             	lea    (%eax,%edx,4),%esi
	if (!(*pgdir & PTE_P)){
f0100b70:	8b 0e                	mov    (%esi),%ecx
f0100b72:	f6 c1 01             	test   $0x1,%cl
f0100b75:	75 28                	jne    f0100b9f <check_va2pa+0x3c>
		cprintf("	caso 1\n");//DEBUG2
f0100b77:	83 ec 0c             	sub    $0xc,%esp
f0100b7a:	68 f1 46 10 f0       	push   $0xf01046f1
f0100b7f:	e8 28 1d 00 00       	call   f01028ac <cprintf>
		cprintf("	*pgdir es %p, PTE_P es %p\n",*pgdir,PTE_P);//DEBUG2
f0100b84:	83 c4 0c             	add    $0xc,%esp
f0100b87:	6a 01                	push   $0x1
f0100b89:	ff 36                	pushl  (%esi)
f0100b8b:	68 fa 46 10 f0       	push   $0xf01046fa
f0100b90:	e8 17 1d 00 00       	call   f01028ac <cprintf>
		return ~0;}
f0100b95:	83 c4 10             	add    $0x10,%esp
f0100b98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b9d:	eb 6a                	jmp    f0100c09 <check_va2pa+0xa6>
	if (*pgdir & PTE_PS){
f0100b9f:	f6 c1 80             	test   $0x80,%cl
f0100ba2:	74 23                	je     f0100bc7 <check_va2pa+0x64>
		cprintf("	caso 2\n");//DEBUG2
f0100ba4:	83 ec 0c             	sub    $0xc,%esp
f0100ba7:	68 16 47 10 f0       	push   $0xf0104716
f0100bac:	e8 fb 1c 00 00       	call   f01028ac <cprintf>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));}
f0100bb1:	89 d8                	mov    %ebx,%eax
f0100bb3:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100bb8:	8b 16                	mov    (%esi),%edx
f0100bba:	81 e2 00 00 c0 ff    	and    $0xffc00000,%edx
f0100bc0:	09 d0                	or     %edx,%eax
f0100bc2:	83 c4 10             	add    $0x10,%esp
f0100bc5:	eb 42                	jmp    f0100c09 <check_va2pa+0xa6>
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bc7:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100bcd:	ba f3 02 00 00       	mov    $0x2f3,%edx
f0100bd2:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f0100bd7:	e8 3d ff ff ff       	call   f0100b19 <_kaddr>
	if (!(p[PTX(va)] & PTE_P)){
f0100bdc:	c1 eb 0c             	shr    $0xc,%ebx
f0100bdf:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0100be5:	8b 14 98             	mov    (%eax,%ebx,4),%edx
		cprintf("	caso 3\n");//DEBUG2
		return ~0;}
	return PTE_ADDR(p[PTX(va)]);
f0100be8:	89 d0                	mov    %edx,%eax
f0100bea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
		return ~0;}
	if (*pgdir & PTE_PS){
		cprintf("	caso 2\n");//DEBUG2
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));}
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P)){
f0100bef:	f6 c2 01             	test   $0x1,%dl
f0100bf2:	75 15                	jne    f0100c09 <check_va2pa+0xa6>
		cprintf("	caso 3\n");//DEBUG2
f0100bf4:	83 ec 0c             	sub    $0xc,%esp
f0100bf7:	68 1f 47 10 f0       	push   $0xf010471f
f0100bfc:	e8 ab 1c 00 00       	call   f01028ac <cprintf>
		return ~0;}
f0100c01:	83 c4 10             	add    $0x10,%esp
f0100c04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return PTE_ADDR(p[PTX(va)]);
}
f0100c09:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100c0c:	5b                   	pop    %ebx
f0100c0d:	5e                   	pop    %esi
f0100c0e:	5d                   	pop    %ebp
f0100c0f:	c3                   	ret    

f0100c10 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c10:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100c16:	77 13                	ja     f0100c2b <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100c18:	55                   	push   %ebp
f0100c19:	89 e5                	mov    %esp,%ebp
f0100c1b:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c1e:	51                   	push   %ecx
f0100c1f:	68 a4 3d 10 f0       	push   $0xf0103da4
f0100c24:	52                   	push   %edx
f0100c25:	50                   	push   %eax
f0100c26:	e8 60 f4 ff ff       	call   f010008b <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100c2b:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100c31:	c3                   	ret    

f0100c32 <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100c32:	55                   	push   %ebp
f0100c33:	89 e5                	mov    %esp,%ebp
f0100c35:	57                   	push   %edi
f0100c36:	56                   	push   %esi
f0100c37:	53                   	push   %ebx
f0100c38:	83 ec 1c             	sub    $0x1c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100c3b:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100c41:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100c46:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100c4d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c52:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0100c55:	be 00 00 00 00       	mov    $0x0,%esi
f0100c5a:	eb 49                	jmp    f0100ca5 <check_kern_pgdir+0x73>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c5c:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0100c62:	89 d8                	mov    %ebx,%eax
f0100c64:	e8 fa fe ff ff       	call   f0100b63 <check_va2pa>
f0100c69:	89 c7                	mov    %eax,%edi
f0100c6b:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
f0100c71:	ba c1 02 00 00       	mov    $0x2c1,%edx
f0100c76:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f0100c7b:	e8 90 ff ff ff       	call   f0100c10 <_paddr>
f0100c80:	01 f0                	add    %esi,%eax
f0100c82:	39 c7                	cmp    %eax,%edi
f0100c84:	74 19                	je     f0100c9f <check_kern_pgdir+0x6d>
f0100c86:	68 c8 3d 10 f0       	push   $0xf0103dc8
f0100c8b:	68 28 47 10 f0       	push   $0xf0104728
f0100c90:	68 c1 02 00 00       	push   $0x2c1
f0100c95:	68 d7 46 10 f0       	push   $0xf01046d7
f0100c9a:	e8 ec f3 ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100c9f:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100ca5:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100ca8:	72 b2                	jb     f0100c5c <check_kern_pgdir+0x2a>
f0100caa:	be 00 00 00 00       	mov    $0x0,%esi
f0100caf:	eb 30                	jmp    f0100ce1 <check_kern_pgdir+0xaf>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100cb1:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0100cb7:	89 d8                	mov    %ebx,%eax
f0100cb9:	e8 a5 fe ff ff       	call   f0100b63 <check_va2pa>
f0100cbe:	39 c6                	cmp    %eax,%esi
f0100cc0:	74 19                	je     f0100cdb <check_kern_pgdir+0xa9>
f0100cc2:	68 fc 3d 10 f0       	push   $0xf0103dfc
f0100cc7:	68 28 47 10 f0       	push   $0xf0104728
f0100ccc:	68 c6 02 00 00       	push   $0x2c6
f0100cd1:	68 d7 46 10 f0       	push   $0xf01046d7
f0100cd6:	e8 b0 f3 ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100cdb:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100ce1:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100ce6:	c1 e0 0c             	shl    $0xc,%eax
f0100ce9:	39 c6                	cmp    %eax,%esi
f0100ceb:	72 c4                	jb     f0100cb1 <check_kern_pgdir+0x7f>
f0100ced:	be 00 00 00 00       	mov    $0x0,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0100cf2:	8d 96 00 80 ff ef    	lea    -0x10008000(%esi),%edx
f0100cf8:	89 d8                	mov    %ebx,%eax
f0100cfa:	e8 64 fe ff ff       	call   f0100b63 <check_va2pa>
f0100cff:	89 c7                	mov    %eax,%edi
f0100d01:	b9 00 d0 10 f0       	mov    $0xf010d000,%ecx
f0100d06:	ba ca 02 00 00       	mov    $0x2ca,%edx
f0100d0b:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f0100d10:	e8 fb fe ff ff       	call   f0100c10 <_paddr>
f0100d15:	01 f0                	add    %esi,%eax
f0100d17:	39 c7                	cmp    %eax,%edi
f0100d19:	74 19                	je     f0100d34 <check_kern_pgdir+0x102>
f0100d1b:	68 24 3e 10 f0       	push   $0xf0103e24
f0100d20:	68 28 47 10 f0       	push   $0xf0104728
f0100d25:	68 ca 02 00 00       	push   $0x2ca
f0100d2a:	68 d7 46 10 f0       	push   $0xf01046d7
f0100d2f:	e8 57 f3 ff ff       	call   f010008b <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100d34:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d3a:	81 fe 00 80 00 00    	cmp    $0x8000,%esi
f0100d40:	75 b0                	jne    f0100cf2 <check_kern_pgdir+0xc0>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0100d42:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0100d47:	89 d8                	mov    %ebx,%eax
f0100d49:	e8 15 fe ff ff       	call   f0100b63 <check_va2pa>
f0100d4e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100d51:	74 51                	je     f0100da4 <check_kern_pgdir+0x172>
f0100d53:	68 6c 3e 10 f0       	push   $0xf0103e6c
f0100d58:	68 28 47 10 f0       	push   $0xf0104728
f0100d5d:	68 cb 02 00 00       	push   $0x2cb
f0100d62:	68 d7 46 10 f0       	push   $0xf01046d7
f0100d67:	e8 1f f3 ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100d6c:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0100d71:	72 36                	jb     f0100da9 <check_kern_pgdir+0x177>
f0100d73:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0100d78:	76 07                	jbe    f0100d81 <check_kern_pgdir+0x14f>
f0100d7a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100d7f:	75 28                	jne    f0100da9 <check_kern_pgdir+0x177>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0100d81:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0100d85:	0f 85 83 00 00 00    	jne    f0100e0e <check_kern_pgdir+0x1dc>
f0100d8b:	68 3d 47 10 f0       	push   $0xf010473d
f0100d90:	68 28 47 10 f0       	push   $0xf0104728
f0100d95:	68 d3 02 00 00       	push   $0x2d3
f0100d9a:	68 d7 46 10 f0       	push   $0xf01046d7
f0100d9f:	e8 e7 f2 ff ff       	call   f010008b <_panic>
f0100da4:	b8 00 00 00 00       	mov    $0x0,%eax
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100da9:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100dae:	76 3f                	jbe    f0100def <check_kern_pgdir+0x1bd>
				assert(pgdir[i] & PTE_P);
f0100db0:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0100db3:	f6 c2 01             	test   $0x1,%dl
f0100db6:	75 19                	jne    f0100dd1 <check_kern_pgdir+0x19f>
f0100db8:	68 3d 47 10 f0       	push   $0xf010473d
f0100dbd:	68 28 47 10 f0       	push   $0xf0104728
f0100dc2:	68 d7 02 00 00       	push   $0x2d7
f0100dc7:	68 d7 46 10 f0       	push   $0xf01046d7
f0100dcc:	e8 ba f2 ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f0100dd1:	f6 c2 02             	test   $0x2,%dl
f0100dd4:	75 38                	jne    f0100e0e <check_kern_pgdir+0x1dc>
f0100dd6:	68 4e 47 10 f0       	push   $0xf010474e
f0100ddb:	68 28 47 10 f0       	push   $0xf0104728
f0100de0:	68 d8 02 00 00       	push   $0x2d8
f0100de5:	68 d7 46 10 f0       	push   $0xf01046d7
f0100dea:	e8 9c f2 ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f0100def:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100df3:	74 19                	je     f0100e0e <check_kern_pgdir+0x1dc>
f0100df5:	68 5f 47 10 f0       	push   $0xf010475f
f0100dfa:	68 28 47 10 f0       	push   $0xf0104728
f0100dff:	68 da 02 00 00       	push   $0x2da
f0100e04:	68 d7 46 10 f0       	push   $0xf01046d7
f0100e09:	e8 7d f2 ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0100e0e:	83 c0 01             	add    $0x1,%eax
f0100e11:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0100e16:	0f 86 50 ff ff ff    	jbe    f0100d6c <check_kern_pgdir+0x13a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0100e1c:	83 ec 0c             	sub    $0xc,%esp
f0100e1f:	68 9c 3e 10 f0       	push   $0xf0103e9c
f0100e24:	e8 83 1a 00 00       	call   f01028ac <cprintf>
}
f0100e29:	83 c4 10             	add    $0x10,%esp
f0100e2c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e2f:	5b                   	pop    %ebx
f0100e30:	5e                   	pop    %esi
f0100e31:	5f                   	pop    %edi
f0100e32:	5d                   	pop    %ebp
f0100e33:	c3                   	ret    

f0100e34 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100e34:	55                   	push   %ebp
f0100e35:	89 e5                	mov    %esp,%ebp
f0100e37:	57                   	push   %edi
f0100e38:	56                   	push   %esi
f0100e39:	53                   	push   %ebx
f0100e3a:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e3d:	84 c0                	test   %al,%al
f0100e3f:	0f 85 35 02 00 00    	jne    f010107a <check_page_free_list+0x246>
f0100e45:	e9 43 02 00 00       	jmp    f010108d <check_page_free_list+0x259>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100e4a:	83 ec 04             	sub    $0x4,%esp
f0100e4d:	68 bc 3e 10 f0       	push   $0xf0103ebc
f0100e52:	68 31 02 00 00       	push   $0x231
f0100e57:	68 d7 46 10 f0       	push   $0xf01046d7
f0100e5c:	e8 2a f2 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e61:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100e64:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e67:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100e6a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e6d:	89 d8                	mov    %ebx,%eax
f0100e6f:	e8 9b fb ff ff       	call   f0100a0f <page2pa>
f0100e74:	c1 e8 16             	shr    $0x16,%eax
f0100e77:	85 c0                	test   %eax,%eax
f0100e79:	0f 95 c0             	setne  %al
f0100e7c:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100e7f:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f0100e83:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100e85:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e89:	8b 1b                	mov    (%ebx),%ebx
f0100e8b:	85 db                	test   %ebx,%ebx
f0100e8d:	75 de                	jne    f0100e6d <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100e8f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e92:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e98:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e9b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e9e:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ea0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ea3:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ea8:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ead:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100eb3:	eb 2d                	jmp    f0100ee2 <check_page_free_list+0xae>
		if (PDX(page2pa(pp)) < pdx_limit)
f0100eb5:	89 d8                	mov    %ebx,%eax
f0100eb7:	e8 53 fb ff ff       	call   f0100a0f <page2pa>
f0100ebc:	c1 e8 16             	shr    $0x16,%eax
f0100ebf:	39 f0                	cmp    %esi,%eax
f0100ec1:	73 1d                	jae    f0100ee0 <check_page_free_list+0xac>
			memset(page2kva(pp), 0x97, 128);
f0100ec3:	89 d8                	mov    %ebx,%eax
f0100ec5:	e8 7b fc ff ff       	call   f0100b45 <page2kva>
f0100eca:	83 ec 04             	sub    $0x4,%esp
f0100ecd:	68 80 00 00 00       	push   $0x80
f0100ed2:	68 97 00 00 00       	push   $0x97
f0100ed7:	50                   	push   %eax
f0100ed8:	e8 73 24 00 00       	call   f0103350 <memset>
f0100edd:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ee0:	8b 1b                	mov    (%ebx),%ebx
f0100ee2:	85 db                	test   %ebx,%ebx
f0100ee4:	75 cf                	jne    f0100eb5 <check_page_free_list+0x81>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ee6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eeb:	e8 bf fb ff ff       	call   f0100aaf <boot_alloc>
f0100ef0:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ef3:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ef9:	8b 35 4c 79 11 f0    	mov    0xf011794c,%esi
		assert(pp < pages + npages);
f0100eff:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100f04:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0100f07:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f0a:	89 75 d0             	mov    %esi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100f0d:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100f14:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f19:	e9 18 01 00 00       	jmp    f0101036 <check_page_free_list+0x202>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f1e:	39 f3                	cmp    %esi,%ebx
f0100f20:	73 19                	jae    f0100f3b <check_page_free_list+0x107>
f0100f22:	68 6d 47 10 f0       	push   $0xf010476d
f0100f27:	68 28 47 10 f0       	push   $0xf0104728
f0100f2c:	68 4b 02 00 00       	push   $0x24b
f0100f31:	68 d7 46 10 f0       	push   $0xf01046d7
f0100f36:	e8 50 f1 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100f3b:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100f3e:	72 19                	jb     f0100f59 <check_page_free_list+0x125>
f0100f40:	68 79 47 10 f0       	push   $0xf0104779
f0100f45:	68 28 47 10 f0       	push   $0xf0104728
f0100f4a:	68 4c 02 00 00       	push   $0x24c
f0100f4f:	68 d7 46 10 f0       	push   $0xf01046d7
f0100f54:	e8 32 f1 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f59:	89 d8                	mov    %ebx,%eax
f0100f5b:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100f5e:	a8 07                	test   $0x7,%al
f0100f60:	74 19                	je     f0100f7b <check_page_free_list+0x147>
f0100f62:	68 e0 3e 10 f0       	push   $0xf0103ee0
f0100f67:	68 28 47 10 f0       	push   $0xf0104728
f0100f6c:	68 4d 02 00 00       	push   $0x24d
f0100f71:	68 d7 46 10 f0       	push   $0xf01046d7
f0100f76:	e8 10 f1 ff ff       	call   f010008b <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100f7b:	89 d8                	mov    %ebx,%eax
f0100f7d:	e8 8d fa ff ff       	call   f0100a0f <page2pa>
f0100f82:	85 c0                	test   %eax,%eax
f0100f84:	75 19                	jne    f0100f9f <check_page_free_list+0x16b>
f0100f86:	68 8d 47 10 f0       	push   $0xf010478d
f0100f8b:	68 28 47 10 f0       	push   $0xf0104728
f0100f90:	68 50 02 00 00       	push   $0x250
f0100f95:	68 d7 46 10 f0       	push   $0xf01046d7
f0100f9a:	e8 ec f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f9f:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100fa4:	75 19                	jne    f0100fbf <check_page_free_list+0x18b>
f0100fa6:	68 9e 47 10 f0       	push   $0xf010479e
f0100fab:	68 28 47 10 f0       	push   $0xf0104728
f0100fb0:	68 51 02 00 00       	push   $0x251
f0100fb5:	68 d7 46 10 f0       	push   $0xf01046d7
f0100fba:	e8 cc f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100fbf:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100fc4:	75 19                	jne    f0100fdf <check_page_free_list+0x1ab>
f0100fc6:	68 14 3f 10 f0       	push   $0xf0103f14
f0100fcb:	68 28 47 10 f0       	push   $0xf0104728
f0100fd0:	68 52 02 00 00       	push   $0x252
f0100fd5:	68 d7 46 10 f0       	push   $0xf01046d7
f0100fda:	e8 ac f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100fdf:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100fe4:	75 19                	jne    f0100fff <check_page_free_list+0x1cb>
f0100fe6:	68 b7 47 10 f0       	push   $0xf01047b7
f0100feb:	68 28 47 10 f0       	push   $0xf0104728
f0100ff0:	68 53 02 00 00       	push   $0x253
f0100ff5:	68 d7 46 10 f0       	push   $0xf01046d7
f0100ffa:	e8 8c f0 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fff:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101004:	76 25                	jbe    f010102b <check_page_free_list+0x1f7>
f0101006:	89 d8                	mov    %ebx,%eax
f0101008:	e8 38 fb ff ff       	call   f0100b45 <page2kva>
f010100d:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101010:	76 1e                	jbe    f0101030 <check_page_free_list+0x1fc>
f0101012:	68 38 3f 10 f0       	push   $0xf0103f38
f0101017:	68 28 47 10 f0       	push   $0xf0104728
f010101c:	68 54 02 00 00       	push   $0x254
f0101021:	68 d7 46 10 f0       	push   $0xf01046d7
f0101026:	e8 60 f0 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f010102b:	83 c7 01             	add    $0x1,%edi
f010102e:	eb 04                	jmp    f0101034 <check_page_free_list+0x200>
		else
			++nfree_extmem;
f0101030:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101034:	8b 1b                	mov    (%ebx),%ebx
f0101036:	85 db                	test   %ebx,%ebx
f0101038:	0f 85 e0 fe ff ff    	jne    f0100f1e <check_page_free_list+0xea>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f010103e:	85 ff                	test   %edi,%edi
f0101040:	7f 19                	jg     f010105b <check_page_free_list+0x227>
f0101042:	68 d1 47 10 f0       	push   $0xf01047d1
f0101047:	68 28 47 10 f0       	push   $0xf0104728
f010104c:	68 5c 02 00 00       	push   $0x25c
f0101051:	68 d7 46 10 f0       	push   $0xf01046d7
f0101056:	e8 30 f0 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f010105b:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010105f:	7f 43                	jg     f01010a4 <check_page_free_list+0x270>
f0101061:	68 e3 47 10 f0       	push   $0xf01047e3
f0101066:	68 28 47 10 f0       	push   $0xf0104728
f010106b:	68 5d 02 00 00       	push   $0x25d
f0101070:	68 d7 46 10 f0       	push   $0xf01046d7
f0101075:	e8 11 f0 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f010107a:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0101080:	85 db                	test   %ebx,%ebx
f0101082:	0f 85 d9 fd ff ff    	jne    f0100e61 <check_page_free_list+0x2d>
f0101088:	e9 bd fd ff ff       	jmp    f0100e4a <check_page_free_list+0x16>
f010108d:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0101094:	0f 84 b0 fd ff ff    	je     f0100e4a <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010109a:	be 00 04 00 00       	mov    $0x400,%esi
f010109f:	e9 09 fe ff ff       	jmp    f0100ead <check_page_free_list+0x79>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f01010a4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010a7:	5b                   	pop    %ebx
f01010a8:	5e                   	pop    %esi
f01010a9:	5f                   	pop    %edi
f01010aa:	5d                   	pop    %ebp
f01010ab:	c3                   	ret    

f01010ac <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010ac:	c1 e8 0c             	shr    $0xc,%eax
f01010af:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f01010b5:	72 17                	jb     f01010ce <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f01010b7:	55                   	push   %ebp
f01010b8:	89 e5                	mov    %esp,%ebp
f01010ba:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f01010bd:	68 80 3f 10 f0       	push   $0xf0103f80
f01010c2:	6a 4b                	push   $0x4b
f01010c4:	68 e3 46 10 f0       	push   $0xf01046e3
f01010c9:	e8 bd ef ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f01010ce:	8b 15 4c 79 11 f0    	mov    0xf011794c,%edx
f01010d4:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01010d7:	c3                   	ret    

f01010d8 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01010d8:	55                   	push   %ebp
f01010d9:	89 e5                	mov    %esp,%ebp
f01010db:	56                   	push   %esi
f01010dc:	53                   	push   %ebx
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}*/ //FOR ORIGINAL
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f01010dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01010e2:	e8 c8 f9 ff ff       	call   f0100aaf <boot_alloc>
f01010e7:	89 c1                	mov    %eax,%ecx
f01010e9:	ba 2c 01 00 00       	mov    $0x12c,%edx
f01010ee:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f01010f3:	e8 18 fb ff ff       	call   f0100c10 <_paddr>
f01010f8:	c1 e8 0c             	shr    $0xc,%eax
f01010fb:	8b 35 3c 75 11 f0    	mov    0xf011753c,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101101:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101106:	ba 01 00 00 00       	mov    $0x1,%edx
f010110b:	eb 33                	jmp    f0101140 <page_init+0x68>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f010110d:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0101113:	76 04                	jbe    f0101119 <page_init+0x41>
f0101115:	39 c2                	cmp    %eax,%edx
f0101117:	72 24                	jb     f010113d <page_init+0x65>
		pages[i].pp_ref = 0;
f0101119:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0101120:	89 cb                	mov    %ecx,%ebx
f0101122:	03 1d 4c 79 11 f0    	add    0xf011794c,%ebx
f0101128:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f010112e:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f0101130:	89 ce                	mov    %ecx,%esi
f0101132:	03 35 4c 79 11 f0    	add    0xf011794c,%esi
f0101138:	b9 01 00 00 00       	mov    $0x1,%ecx
		page_free_list = &pages[i];
	}*/ //FOR ORIGINAL
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f010113d:	83 c2 01             	add    $0x1,%edx
f0101140:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0101146:	72 c5                	jb     f010110d <page_init+0x35>
f0101148:	84 c9                	test   %cl,%cl
f010114a:	74 06                	je     f0101152 <page_init+0x7a>
f010114c:	89 35 3c 75 11 f0    	mov    %esi,0xf011753c
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0101152:	5b                   	pop    %ebx
f0101153:	5e                   	pop    %esi
f0101154:	5d                   	pop    %ebp
f0101155:	c3                   	ret    

f0101156 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f0101156:	55                   	push   %ebp
f0101157:	89 e5                	mov    %esp,%ebp
f0101159:	53                   	push   %ebx
f010115a:	83 ec 04             	sub    $0x4,%esp
f010115d:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0101163:	85 db                	test   %ebx,%ebx
f0101165:	74 2d                	je     f0101194 <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f0101167:	8b 03                	mov    (%ebx),%eax
f0101169:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	pag->pp_link = NULL;
f010116e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f0101174:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101178:	74 1a                	je     f0101194 <page_alloc+0x3e>
f010117a:	89 d8                	mov    %ebx,%eax
f010117c:	e8 c4 f9 ff ff       	call   f0100b45 <page2kva>
f0101181:	83 ec 04             	sub    $0x4,%esp
f0101184:	68 00 10 00 00       	push   $0x1000
f0101189:	6a 00                	push   $0x0
f010118b:	50                   	push   %eax
f010118c:	e8 bf 21 00 00       	call   f0103350 <memset>
f0101191:	83 c4 10             	add    $0x10,%esp
	return pag;
}
f0101194:	89 d8                	mov    %ebx,%eax
f0101196:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101199:	c9                   	leave  
f010119a:	c3                   	ret    

f010119b <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010119b:	55                   	push   %ebp
f010119c:	89 e5                	mov    %esp,%ebp
f010119e:	83 ec 08             	sub    $0x8,%esp
f01011a1:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f01011a4:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01011a9:	74 17                	je     f01011c2 <page_free+0x27>
f01011ab:	83 ec 04             	sub    $0x4,%esp
f01011ae:	68 f4 47 10 f0       	push   $0xf01047f4
f01011b3:	68 55 01 00 00       	push   $0x155
f01011b8:	68 d7 46 10 f0       	push   $0xf01046d7
f01011bd:	e8 c9 ee ff ff       	call   f010008b <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");//mejorar mensaje?
f01011c2:	83 38 00             	cmpl   $0x0,(%eax)
f01011c5:	74 17                	je     f01011de <page_free+0x43>
f01011c7:	83 ec 04             	sub    $0x4,%esp
f01011ca:	68 a0 3f 10 f0       	push   $0xf0103fa0
f01011cf:	68 56 01 00 00       	push   $0x156
f01011d4:	68 d7 46 10 f0       	push   $0xf01046d7
f01011d9:	e8 ad ee ff ff       	call   f010008b <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f01011de:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f01011e4:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f01011e6:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f01011eb:	c9                   	leave  
f01011ec:	c3                   	ret    

f01011ed <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f01011ed:	55                   	push   %ebp
f01011ee:	89 e5                	mov    %esp,%ebp
f01011f0:	57                   	push   %edi
f01011f1:	56                   	push   %esi
f01011f2:	53                   	push   %ebx
f01011f3:	83 ec 1c             	sub    $0x1c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011f6:	83 3d 4c 79 11 f0 00 	cmpl   $0x0,0xf011794c
f01011fd:	75 17                	jne    f0101216 <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f01011ff:	83 ec 04             	sub    $0x4,%esp
f0101202:	68 08 48 10 f0       	push   $0xf0104808
f0101207:	68 6e 02 00 00       	push   $0x26e
f010120c:	68 d7 46 10 f0       	push   $0xf01046d7
f0101211:	e8 75 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101216:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010121b:	be 00 00 00 00       	mov    $0x0,%esi
f0101220:	eb 05                	jmp    f0101227 <check_page_alloc+0x3a>
		++nfree;
f0101222:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101225:	8b 00                	mov    (%eax),%eax
f0101227:	85 c0                	test   %eax,%eax
f0101229:	75 f7                	jne    f0101222 <check_page_alloc+0x35>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010122b:	83 ec 0c             	sub    $0xc,%esp
f010122e:	6a 00                	push   $0x0
f0101230:	e8 21 ff ff ff       	call   f0101156 <page_alloc>
f0101235:	89 c7                	mov    %eax,%edi
f0101237:	83 c4 10             	add    $0x10,%esp
f010123a:	85 c0                	test   %eax,%eax
f010123c:	75 19                	jne    f0101257 <check_page_alloc+0x6a>
f010123e:	68 23 48 10 f0       	push   $0xf0104823
f0101243:	68 28 47 10 f0       	push   $0xf0104728
f0101248:	68 76 02 00 00       	push   $0x276
f010124d:	68 d7 46 10 f0       	push   $0xf01046d7
f0101252:	e8 34 ee ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101257:	83 ec 0c             	sub    $0xc,%esp
f010125a:	6a 00                	push   $0x0
f010125c:	e8 f5 fe ff ff       	call   f0101156 <page_alloc>
f0101261:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101264:	83 c4 10             	add    $0x10,%esp
f0101267:	85 c0                	test   %eax,%eax
f0101269:	75 19                	jne    f0101284 <check_page_alloc+0x97>
f010126b:	68 39 48 10 f0       	push   $0xf0104839
f0101270:	68 28 47 10 f0       	push   $0xf0104728
f0101275:	68 77 02 00 00       	push   $0x277
f010127a:	68 d7 46 10 f0       	push   $0xf01046d7
f010127f:	e8 07 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101284:	83 ec 0c             	sub    $0xc,%esp
f0101287:	6a 00                	push   $0x0
f0101289:	e8 c8 fe ff ff       	call   f0101156 <page_alloc>
f010128e:	89 c3                	mov    %eax,%ebx
f0101290:	83 c4 10             	add    $0x10,%esp
f0101293:	85 c0                	test   %eax,%eax
f0101295:	75 19                	jne    f01012b0 <check_page_alloc+0xc3>
f0101297:	68 4f 48 10 f0       	push   $0xf010484f
f010129c:	68 28 47 10 f0       	push   $0xf0104728
f01012a1:	68 78 02 00 00       	push   $0x278
f01012a6:	68 d7 46 10 f0       	push   $0xf01046d7
f01012ab:	e8 db ed ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012b0:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01012b3:	75 19                	jne    f01012ce <check_page_alloc+0xe1>
f01012b5:	68 65 48 10 f0       	push   $0xf0104865
f01012ba:	68 28 47 10 f0       	push   $0xf0104728
f01012bf:	68 7b 02 00 00       	push   $0x27b
f01012c4:	68 d7 46 10 f0       	push   $0xf01046d7
f01012c9:	e8 bd ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012ce:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01012d1:	74 04                	je     f01012d7 <check_page_alloc+0xea>
f01012d3:	39 c7                	cmp    %eax,%edi
f01012d5:	75 19                	jne    f01012f0 <check_page_alloc+0x103>
f01012d7:	68 cc 3f 10 f0       	push   $0xf0103fcc
f01012dc:	68 28 47 10 f0       	push   $0xf0104728
f01012e1:	68 7c 02 00 00       	push   $0x27c
f01012e6:	68 d7 46 10 f0       	push   $0xf01046d7
f01012eb:	e8 9b ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01012f0:	89 f8                	mov    %edi,%eax
f01012f2:	e8 18 f7 ff ff       	call   f0100a0f <page2pa>
f01012f7:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f01012fd:	c1 e1 0c             	shl    $0xc,%ecx
f0101300:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101303:	39 c8                	cmp    %ecx,%eax
f0101305:	72 19                	jb     f0101320 <check_page_alloc+0x133>
f0101307:	68 77 48 10 f0       	push   $0xf0104877
f010130c:	68 28 47 10 f0       	push   $0xf0104728
f0101311:	68 7d 02 00 00       	push   $0x27d
f0101316:	68 d7 46 10 f0       	push   $0xf01046d7
f010131b:	e8 6b ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101320:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101323:	e8 e7 f6 ff ff       	call   f0100a0f <page2pa>
f0101328:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010132b:	77 19                	ja     f0101346 <check_page_alloc+0x159>
f010132d:	68 94 48 10 f0       	push   $0xf0104894
f0101332:	68 28 47 10 f0       	push   $0xf0104728
f0101337:	68 7e 02 00 00       	push   $0x27e
f010133c:	68 d7 46 10 f0       	push   $0xf01046d7
f0101341:	e8 45 ed ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101346:	89 d8                	mov    %ebx,%eax
f0101348:	e8 c2 f6 ff ff       	call   f0100a0f <page2pa>
f010134d:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0101350:	77 19                	ja     f010136b <check_page_alloc+0x17e>
f0101352:	68 b1 48 10 f0       	push   $0xf01048b1
f0101357:	68 28 47 10 f0       	push   $0xf0104728
f010135c:	68 7f 02 00 00       	push   $0x27f
f0101361:	68 d7 46 10 f0       	push   $0xf01046d7
f0101366:	e8 20 ed ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010136b:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101370:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0101373:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010137a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010137d:	83 ec 0c             	sub    $0xc,%esp
f0101380:	6a 00                	push   $0x0
f0101382:	e8 cf fd ff ff       	call   f0101156 <page_alloc>
f0101387:	83 c4 10             	add    $0x10,%esp
f010138a:	85 c0                	test   %eax,%eax
f010138c:	74 19                	je     f01013a7 <check_page_alloc+0x1ba>
f010138e:	68 ce 48 10 f0       	push   $0xf01048ce
f0101393:	68 28 47 10 f0       	push   $0xf0104728
f0101398:	68 86 02 00 00       	push   $0x286
f010139d:	68 d7 46 10 f0       	push   $0xf01046d7
f01013a2:	e8 e4 ec ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01013a7:	83 ec 0c             	sub    $0xc,%esp
f01013aa:	57                   	push   %edi
f01013ab:	e8 eb fd ff ff       	call   f010119b <page_free>
	page_free(pp1);
f01013b0:	83 c4 04             	add    $0x4,%esp
f01013b3:	ff 75 e4             	pushl  -0x1c(%ebp)
f01013b6:	e8 e0 fd ff ff       	call   f010119b <page_free>
	page_free(pp2);
f01013bb:	89 1c 24             	mov    %ebx,(%esp)
f01013be:	e8 d8 fd ff ff       	call   f010119b <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013c3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013ca:	e8 87 fd ff ff       	call   f0101156 <page_alloc>
f01013cf:	89 c3                	mov    %eax,%ebx
f01013d1:	83 c4 10             	add    $0x10,%esp
f01013d4:	85 c0                	test   %eax,%eax
f01013d6:	75 19                	jne    f01013f1 <check_page_alloc+0x204>
f01013d8:	68 23 48 10 f0       	push   $0xf0104823
f01013dd:	68 28 47 10 f0       	push   $0xf0104728
f01013e2:	68 8d 02 00 00       	push   $0x28d
f01013e7:	68 d7 46 10 f0       	push   $0xf01046d7
f01013ec:	e8 9a ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01013f1:	83 ec 0c             	sub    $0xc,%esp
f01013f4:	6a 00                	push   $0x0
f01013f6:	e8 5b fd ff ff       	call   f0101156 <page_alloc>
f01013fb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013fe:	83 c4 10             	add    $0x10,%esp
f0101401:	85 c0                	test   %eax,%eax
f0101403:	75 19                	jne    f010141e <check_page_alloc+0x231>
f0101405:	68 39 48 10 f0       	push   $0xf0104839
f010140a:	68 28 47 10 f0       	push   $0xf0104728
f010140f:	68 8e 02 00 00       	push   $0x28e
f0101414:	68 d7 46 10 f0       	push   $0xf01046d7
f0101419:	e8 6d ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010141e:	83 ec 0c             	sub    $0xc,%esp
f0101421:	6a 00                	push   $0x0
f0101423:	e8 2e fd ff ff       	call   f0101156 <page_alloc>
f0101428:	89 c7                	mov    %eax,%edi
f010142a:	83 c4 10             	add    $0x10,%esp
f010142d:	85 c0                	test   %eax,%eax
f010142f:	75 19                	jne    f010144a <check_page_alloc+0x25d>
f0101431:	68 4f 48 10 f0       	push   $0xf010484f
f0101436:	68 28 47 10 f0       	push   $0xf0104728
f010143b:	68 8f 02 00 00       	push   $0x28f
f0101440:	68 d7 46 10 f0       	push   $0xf01046d7
f0101445:	e8 41 ec ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010144a:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f010144d:	75 19                	jne    f0101468 <check_page_alloc+0x27b>
f010144f:	68 65 48 10 f0       	push   $0xf0104865
f0101454:	68 28 47 10 f0       	push   $0xf0104728
f0101459:	68 91 02 00 00       	push   $0x291
f010145e:	68 d7 46 10 f0       	push   $0xf01046d7
f0101463:	e8 23 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101468:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010146b:	74 04                	je     f0101471 <check_page_alloc+0x284>
f010146d:	39 c3                	cmp    %eax,%ebx
f010146f:	75 19                	jne    f010148a <check_page_alloc+0x29d>
f0101471:	68 cc 3f 10 f0       	push   $0xf0103fcc
f0101476:	68 28 47 10 f0       	push   $0xf0104728
f010147b:	68 92 02 00 00       	push   $0x292
f0101480:	68 d7 46 10 f0       	push   $0xf01046d7
f0101485:	e8 01 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f010148a:	83 ec 0c             	sub    $0xc,%esp
f010148d:	6a 00                	push   $0x0
f010148f:	e8 c2 fc ff ff       	call   f0101156 <page_alloc>
f0101494:	83 c4 10             	add    $0x10,%esp
f0101497:	85 c0                	test   %eax,%eax
f0101499:	74 19                	je     f01014b4 <check_page_alloc+0x2c7>
f010149b:	68 ce 48 10 f0       	push   $0xf01048ce
f01014a0:	68 28 47 10 f0       	push   $0xf0104728
f01014a5:	68 93 02 00 00       	push   $0x293
f01014aa:	68 d7 46 10 f0       	push   $0xf01046d7
f01014af:	e8 d7 eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014b4:	89 d8                	mov    %ebx,%eax
f01014b6:	e8 8a f6 ff ff       	call   f0100b45 <page2kva>
f01014bb:	83 ec 04             	sub    $0x4,%esp
f01014be:	68 00 10 00 00       	push   $0x1000
f01014c3:	6a 01                	push   $0x1
f01014c5:	50                   	push   %eax
f01014c6:	e8 85 1e 00 00       	call   f0103350 <memset>
	page_free(pp0);
f01014cb:	89 1c 24             	mov    %ebx,(%esp)
f01014ce:	e8 c8 fc ff ff       	call   f010119b <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014d3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014da:	e8 77 fc ff ff       	call   f0101156 <page_alloc>
f01014df:	83 c4 10             	add    $0x10,%esp
f01014e2:	85 c0                	test   %eax,%eax
f01014e4:	75 19                	jne    f01014ff <check_page_alloc+0x312>
f01014e6:	68 dd 48 10 f0       	push   $0xf01048dd
f01014eb:	68 28 47 10 f0       	push   $0xf0104728
f01014f0:	68 98 02 00 00       	push   $0x298
f01014f5:	68 d7 46 10 f0       	push   $0xf01046d7
f01014fa:	e8 8c eb ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f01014ff:	39 c3                	cmp    %eax,%ebx
f0101501:	74 19                	je     f010151c <check_page_alloc+0x32f>
f0101503:	68 fb 48 10 f0       	push   $0xf01048fb
f0101508:	68 28 47 10 f0       	push   $0xf0104728
f010150d:	68 99 02 00 00       	push   $0x299
f0101512:	68 d7 46 10 f0       	push   $0xf01046d7
f0101517:	e8 6f eb ff ff       	call   f010008b <_panic>
	c = page2kva(pp);
f010151c:	89 d8                	mov    %ebx,%eax
f010151e:	e8 22 f6 ff ff       	call   f0100b45 <page2kva>
f0101523:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101529:	80 38 00             	cmpb   $0x0,(%eax)
f010152c:	74 19                	je     f0101547 <check_page_alloc+0x35a>
f010152e:	68 0b 49 10 f0       	push   $0xf010490b
f0101533:	68 28 47 10 f0       	push   $0xf0104728
f0101538:	68 9c 02 00 00       	push   $0x29c
f010153d:	68 d7 46 10 f0       	push   $0xf01046d7
f0101542:	e8 44 eb ff ff       	call   f010008b <_panic>
f0101547:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010154a:	39 d0                	cmp    %edx,%eax
f010154c:	75 db                	jne    f0101529 <check_page_alloc+0x33c>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010154e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101551:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101556:	83 ec 0c             	sub    $0xc,%esp
f0101559:	53                   	push   %ebx
f010155a:	e8 3c fc ff ff       	call   f010119b <page_free>
	page_free(pp1);
f010155f:	83 c4 04             	add    $0x4,%esp
f0101562:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101565:	e8 31 fc ff ff       	call   f010119b <page_free>
	page_free(pp2);
f010156a:	89 3c 24             	mov    %edi,(%esp)
f010156d:	e8 29 fc ff ff       	call   f010119b <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101572:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101577:	83 c4 10             	add    $0x10,%esp
f010157a:	eb 05                	jmp    f0101581 <check_page_alloc+0x394>
		--nfree;
f010157c:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010157f:	8b 00                	mov    (%eax),%eax
f0101581:	85 c0                	test   %eax,%eax
f0101583:	75 f7                	jne    f010157c <check_page_alloc+0x38f>
		--nfree;
	assert(nfree == 0);
f0101585:	85 f6                	test   %esi,%esi
f0101587:	74 19                	je     f01015a2 <check_page_alloc+0x3b5>
f0101589:	68 15 49 10 f0       	push   $0xf0104915
f010158e:	68 28 47 10 f0       	push   $0xf0104728
f0101593:	68 a9 02 00 00       	push   $0x2a9
f0101598:	68 d7 46 10 f0       	push   $0xf01046d7
f010159d:	e8 e9 ea ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015a2:	83 ec 0c             	sub    $0xc,%esp
f01015a5:	68 ec 3f 10 f0       	push   $0xf0103fec
f01015aa:	e8 fd 12 00 00       	call   f01028ac <cprintf>
}
f01015af:	83 c4 10             	add    $0x10,%esp
f01015b2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01015b5:	5b                   	pop    %ebx
f01015b6:	5e                   	pop    %esi
f01015b7:	5f                   	pop    %edi
f01015b8:	5d                   	pop    %ebp
f01015b9:	c3                   	ret    

f01015ba <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01015ba:	55                   	push   %ebp
f01015bb:	89 e5                	mov    %esp,%ebp
f01015bd:	83 ec 08             	sub    $0x8,%esp
f01015c0:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01015c3:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01015c7:	83 e8 01             	sub    $0x1,%eax
f01015ca:	66 89 42 04          	mov    %ax,0x4(%edx)
f01015ce:	66 85 c0             	test   %ax,%ax
f01015d1:	75 0c                	jne    f01015df <page_decref+0x25>
		page_free(pp);
f01015d3:	83 ec 0c             	sub    $0xc,%esp
f01015d6:	52                   	push   %edx
f01015d7:	e8 bf fb ff ff       	call   f010119b <page_free>
f01015dc:	83 c4 10             	add    $0x10,%esp
}
f01015df:	c9                   	leave  
f01015e0:	c3                   	ret    

f01015e1 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01015e1:	55                   	push   %ebp
f01015e2:	89 e5                	mov    %esp,%ebp
f01015e4:	56                   	push   %esi
f01015e5:	53                   	push   %ebx
f01015e6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uint32_t* aux =(uint32_t*) pgdir;	
	physaddr_t* ptdir = (physaddr_t*) aux[PDX(va)]; //ojo que esto es P.Addr. !!
f01015e9:	89 da                	mov    %ebx,%edx
f01015eb:	c1 ea 16             	shr    $0x16,%edx
f01015ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f1:	8b 34 90             	mov    (%eax,%edx,4),%esi

	if (ptdir == NULL){
f01015f4:	85 f6                	test   %esi,%esi
f01015f6:	75 57                	jne    f010164f <pgdir_walk+0x6e>
//		cprintf("\nse entro a walk y ptdir es NULL\n");//DEBUG2
		if (!create) return NULL;
f01015f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01015fd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101601:	74 7f                	je     f0101682 <pgdir_walk+0xa1>
		struct PageInfo *page = page_alloc(0);
f0101603:	83 ec 0c             	sub    $0xc,%esp
f0101606:	6a 00                	push   $0x0
f0101608:	e8 49 fb ff ff       	call   f0101156 <page_alloc>
f010160d:	89 c3                	mov    %eax,%ebx
		if (page == NULL) return NULL;
f010160f:	83 c4 10             	add    $0x10,%esp
f0101612:	85 c0                	test   %eax,%eax
f0101614:	74 67                	je     f010167d <pgdir_walk+0x9c>
//		cprintf("y ademas se pudo hacer un page_alloc\n");//DEBUG2
		page->pp_ref++;
f0101616:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		ptdir = (physaddr_t *) page2pa(page);
f010161b:	e8 ef f3 ff ff       	call   f0100a0f <page2pa>
f0101620:	89 c6                	mov    %eax,%esi
		memset(page2kva(page),0,PGSIZE);//limpiar pagina
f0101622:	89 d8                	mov    %ebx,%eax
f0101624:	e8 1c f5 ff ff       	call   f0100b45 <page2kva>
f0101629:	83 ec 04             	sub    $0x4,%esp
f010162c:	68 00 10 00 00       	push   $0x1000
f0101631:	6a 00                	push   $0x0
f0101633:	50                   	push   %eax
f0101634:	e8 17 1d 00 00       	call   f0103350 <memset>
		return (pte_t*) KADDR((physaddr_t) ptdir);
f0101639:	89 f1                	mov    %esi,%ecx
f010163b:	ba 8c 01 00 00       	mov    $0x18c,%edx
f0101640:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f0101645:	e8 cf f4 ff ff       	call   f0100b19 <_kaddr>
f010164a:	83 c4 10             	add    $0x10,%esp
f010164d:	eb 33                	jmp    f0101682 <pgdir_walk+0xa1>
	}
	cprintf("\nse entro a walk y ptdir es no null: %p\n",ptdir);//DEBUG2
f010164f:	83 ec 08             	sub    $0x8,%esp
f0101652:	56                   	push   %esi
f0101653:	68 0c 40 10 f0       	push   $0xf010400c
f0101658:	e8 4f 12 00 00       	call   f01028ac <cprintf>
	return (pte_t*) KADDR(((physaddr_t) ptdir)+PTX(va));//esto se pide?
f010165d:	c1 eb 0c             	shr    $0xc,%ebx
f0101660:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0101666:	8d 0c 33             	lea    (%ebx,%esi,1),%ecx
f0101669:	ba 8f 01 00 00       	mov    $0x18f,%edx
f010166e:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f0101673:	e8 a1 f4 ff ff       	call   f0100b19 <_kaddr>
f0101678:	83 c4 10             	add    $0x10,%esp
f010167b:	eb 05                	jmp    f0101682 <pgdir_walk+0xa1>

	if (ptdir == NULL){
//		cprintf("\nse entro a walk y ptdir es NULL\n");//DEBUG2
		if (!create) return NULL;
		struct PageInfo *page = page_alloc(0);
		if (page == NULL) return NULL;
f010167d:	b8 00 00 00 00       	mov    $0x0,%eax
		memset(page2kva(page),0,PGSIZE);//limpiar pagina
		return (pte_t*) KADDR((physaddr_t) ptdir);
	}
	cprintf("\nse entro a walk y ptdir es no null: %p\n",ptdir);//DEBUG2
	return (pte_t*) KADDR(((physaddr_t) ptdir)+PTX(va));//esto se pide?
}
f0101682:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101685:	5b                   	pop    %ebx
f0101686:	5e                   	pop    %esi
f0101687:	5d                   	pop    %ebp
f0101688:	c3                   	ret    

f0101689 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101689:	55                   	push   %ebp
f010168a:	89 e5                	mov    %esp,%ebp
f010168c:	57                   	push   %edi
f010168d:	56                   	push   %esi
f010168e:	53                   	push   %ebx
f010168f:	83 ec 10             	sub    $0x10,%esp
f0101692:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101695:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *page_entry = pgdir_walk(pgdir, va, false);	//Busco la PTE
f0101698:	6a 00                	push   $0x0
f010169a:	53                   	push   %ebx
f010169b:	ff 75 08             	pushl  0x8(%ebp)
f010169e:	e8 3e ff ff ff       	call   f01015e1 <pgdir_walk>
	if (page_entry == NULL){
f01016a3:	83 c4 10             	add    $0x10,%esp
f01016a6:	85 c0                	test   %eax,%eax
f01016a8:	74 2e                	je     f01016d8 <page_lookup+0x4f>
f01016aa:	89 c6                	mov    %eax,%esi
		return NULL;
	}
	physaddr_t physical_page = PTE_ADDR(page_entry);	//consigo el addres
	physaddr_t physical_direction = physical_page | PGOFF(va);	//formo la direccion fisica conb lo anterir OR offset
f01016ac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01016b1:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
f01016b7:	09 c3                	or     %eax,%ebx
	if (pte_store != NULL){
f01016b9:	85 ff                	test   %edi,%edi
f01016bb:	74 12                	je     f01016cf <page_lookup+0x46>
		cprintf("lookup con pte_store!=0, qcyo\n");//DEBUG2
f01016bd:	83 ec 0c             	sub    $0xc,%esp
f01016c0:	68 38 40 10 f0       	push   $0xf0104038
f01016c5:	e8 e2 11 00 00       	call   f01028ac <cprintf>
		*pte_store = page_entry;//DEBUG2 bien?
f01016ca:	89 37                	mov    %esi,(%edi)
f01016cc:	83 c4 10             	add    $0x10,%esp
	}
	return pa2page(physical_direction); 
f01016cf:	89 d8                	mov    %ebx,%eax
f01016d1:	e8 d6 f9 ff ff       	call   f01010ac <pa2page>
f01016d6:	eb 05                	jmp    f01016dd <page_lookup+0x54>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *page_entry = pgdir_walk(pgdir, va, false);	//Busco la PTE
	if (page_entry == NULL){
		return NULL;
f01016d8:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store != NULL){
		cprintf("lookup con pte_store!=0, qcyo\n");//DEBUG2
		*pte_store = page_entry;//DEBUG2 bien?
	}
	return pa2page(physical_direction); 
}	
f01016dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01016e0:	5b                   	pop    %ebx
f01016e1:	5e                   	pop    %esi
f01016e2:	5f                   	pop    %edi
f01016e3:	5d                   	pop    %ebp
f01016e4:	c3                   	ret    

f01016e5 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01016e5:	55                   	push   %ebp
f01016e6:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f01016e8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016eb:	e8 ff f2 ff ff       	call   f01009ef <invlpg>
}
f01016f0:	5d                   	pop    %ebp
f01016f1:	c3                   	ret    

f01016f2 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01016f2:	55                   	push   %ebp
f01016f3:	89 e5                	mov    %esp,%ebp
f01016f5:	57                   	push   %edi
f01016f6:	56                   	push   %esi
f01016f7:	53                   	push   %ebx
f01016f8:	83 ec 20             	sub    $0x20,%esp
f01016fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01016fe:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t* page_entry;
	struct PageInfo* page = page_lookup(pgdir, va, &page_entry);
f0101701:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101704:	50                   	push   %eax
f0101705:	57                   	push   %edi
f0101706:	56                   	push   %esi
f0101707:	e8 7d ff ff ff       	call   f0101689 <page_lookup>
	if(page == NULL){
f010170c:	83 c4 10             	add    $0x10,%esp
f010170f:	85 c0                	test   %eax,%eax
f0101711:	75 14                	jne    f0101727 <page_remove+0x35>
		cprintf("en remove, page es NULL\n",page);//DEBUG2
f0101713:	83 ec 08             	sub    $0x8,%esp
f0101716:	6a 00                	push   $0x0
f0101718:	68 20 49 10 f0       	push   $0xf0104920
f010171d:	e8 8a 11 00 00       	call   f01028ac <cprintf>
		return;
f0101722:	83 c4 10             	add    $0x10,%esp
f0101725:	eb 2e                	jmp    f0101755 <page_remove+0x63>
f0101727:	89 c3                	mov    %eax,%ebx
	}
	cprintf("en remove page_lookup da %p\n",page);//DEBUG2
f0101729:	83 ec 08             	sub    $0x8,%esp
f010172c:	50                   	push   %eax
f010172d:	68 39 49 10 f0       	push   $0xf0104939
f0101732:	e8 75 11 00 00       	call   f01028ac <cprintf>
	*page_entry = 0;
f0101737:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010173a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	page_decref(page);
f0101740:	89 1c 24             	mov    %ebx,(%esp)
f0101743:	e8 72 fe ff ff       	call   f01015ba <page_decref>
	tlb_invalidate(pgdir,va);
f0101748:	83 c4 08             	add    $0x8,%esp
f010174b:	57                   	push   %edi
f010174c:	56                   	push   %esi
f010174d:	e8 93 ff ff ff       	call   f01016e5 <tlb_invalidate>
f0101752:	83 c4 10             	add    $0x10,%esp
}
f0101755:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101758:	5b                   	pop    %ebx
f0101759:	5e                   	pop    %esi
f010175a:	5f                   	pop    %edi
f010175b:	5d                   	pop    %ebp
f010175c:	c3                   	ret    

f010175d <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010175d:	55                   	push   %ebp
f010175e:	89 e5                	mov    %esp,%ebp
f0101760:	57                   	push   %edi
f0101761:	56                   	push   %esi
f0101762:	53                   	push   %ebx
f0101763:	83 ec 1c             	sub    $0x1c,%esp
f0101766:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101769:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	physaddr_t page_PA = page2pa(pp);
f010176c:	89 f0                	mov    %esi,%eax
f010176e:	e8 9c f2 ff ff       	call   f0100a0f <page2pa>
f0101773:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t *page_entry = pgdir_walk(pgdir, va, true);
f0101776:	83 ec 04             	sub    $0x4,%esp
f0101779:	6a 01                	push   $0x1
f010177b:	ff 75 10             	pushl  0x10(%ebp)
f010177e:	57                   	push   %edi
f010177f:	e8 5d fe ff ff       	call   f01015e1 <pgdir_walk>
	if (page_entry == NULL){
f0101784:	83 c4 10             	add    $0x10,%esp
f0101787:	85 c0                	test   %eax,%eax
f0101789:	0f 84 b0 00 00 00    	je     f010183f <page_insert+0xe2>
f010178f:	89 c3                	mov    %eax,%ebx
		return -E_NO_MEM;
	}
	if (PTE_ADDR(page_entry) != 0x0){//DEBUG2: para que esta este if?
f0101791:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101796:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101799:	0f 84 81 00 00 00    	je     f0101820 <page_insert+0xc3>
		cprintf("	En insert la PTE_ADDR(page_entry) es %p\n",PTE_ADDR(page_entry));//DEBUG2
f010179f:	83 ec 08             	sub    $0x8,%esp
f01017a2:	50                   	push   %eax
f01017a3:	68 58 40 10 f0       	push   $0xf0104058
f01017a8:	e8 ff 10 00 00       	call   f01028ac <cprintf>
		cprintf("	En insert la page_entry es %p\n",page_entry);//DEBUG2
f01017ad:	83 c4 08             	add    $0x8,%esp
f01017b0:	53                   	push   %ebx
f01017b1:	68 84 40 10 f0       	push   $0xf0104084
f01017b6:	e8 f1 10 00 00       	call   f01028ac <cprintf>
		page_remove(pgdir,va);
f01017bb:	83 c4 08             	add    $0x8,%esp
f01017be:	ff 75 10             	pushl  0x10(%ebp)
f01017c1:	57                   	push   %edi
f01017c2:	e8 2b ff ff ff       	call   f01016f2 <page_remove>
		//ATENCION: aca modifica el pgdir
		cprintf("	En insert antes *(pgdir+PDX(va)) = %p y va = %p\n",*(pgdir+PDX(va)),va);//DEBUG2
f01017c7:	8b 45 10             	mov    0x10(%ebp),%eax
f01017ca:	c1 e8 16             	shr    $0x16,%eax
f01017cd:	8d 3c 87             	lea    (%edi,%eax,4),%edi
f01017d0:	83 c4 0c             	add    $0xc,%esp
f01017d3:	ff 75 10             	pushl  0x10(%ebp)
f01017d6:	ff 37                	pushl  (%edi)
f01017d8:	68 a4 40 10 f0       	push   $0xf01040a4
f01017dd:	e8 ca 10 00 00       	call   f01028ac <cprintf>
		if (!(*(pgdir+PDX(va)) & PTE_P)){ //si es la primera vez que se usa prender los flags
f01017e2:	8b 07                	mov    (%edi),%eax
f01017e4:	83 c4 10             	add    $0x10,%esp
f01017e7:	a8 01                	test   $0x1,%al
f01017e9:	75 23                	jne    f010180e <page_insert+0xb1>
			*(pgdir+PDX(va)) &= 0xFFF;//maskeo los flags, borro el resto
f01017eb:	25 ff 0f 00 00       	and    $0xfff,%eax
f01017f0:	89 07                	mov    %eax,(%edi)
			*(pgdir+PDX(va)) = (PADDR((void*) PTE_ADDR(page_entry)) | PTE_P | perm);
f01017f2:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01017f5:	ba cd 01 00 00       	mov    $0x1cd,%edx
f01017fa:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f01017ff:	e8 0c f4 ff ff       	call   f0100c10 <_paddr>
f0101804:	8b 55 14             	mov    0x14(%ebp),%edx
f0101807:	83 ca 01             	or     $0x1,%edx
f010180a:	09 d0                	or     %edx,%eax
f010180c:	89 07                	mov    %eax,(%edi)
		}
		cprintf("	y ahora tengo *(pgdir+PDX(va)) = %p\n", *(pgdir+PDX(va)));//DEBUG2
f010180e:	83 ec 08             	sub    $0x8,%esp
f0101811:	ff 37                	pushl  (%edi)
f0101813:	68 d8 40 10 f0       	push   $0xf01040d8
f0101818:	e8 8f 10 00 00       	call   f01028ac <cprintf>
f010181d:	83 c4 10             	add    $0x10,%esp
	}
	*page_entry = (page_PA & ~0xFFF) | (PTE_P|perm);		// page_PA OR ~0xFFF me da los 20bits mas altos. 						//DEBUG2: el & no es lo mismo que la macro PTE_ADDR?
f0101820:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101823:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101829:	8b 45 14             	mov    0x14(%ebp),%eax
f010182c:	83 c8 01             	or     $0x1,%eax
f010182f:	09 d0                	or     %edx,%eax
f0101831:	89 03                	mov    %eax,(%ebx)
															//El otro OR me genera los permisos.
													//El OR entre ambos me deja seteado el PTE.
//	cprintf("En insert *page_entry es %p\n",*page_entry);
//	cprintf("En insert page_PA es %08x y PTE_P|perm es %08x\n",page_PA, PTE_P|perm);

	pp->pp_ref++;
f0101833:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f0101838:	b8 00 00 00 00       	mov    $0x0,%eax
f010183d:	eb 05                	jmp    f0101844 <page_insert+0xe7>
{
	// Fill this function in
	physaddr_t page_PA = page2pa(pp);
	pte_t *page_entry = pgdir_walk(pgdir, va, true);
	if (page_entry == NULL){
		return -E_NO_MEM;
f010183f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
//	cprintf("En insert *page_entry es %p\n",*page_entry);
//	cprintf("En insert page_PA es %08x y PTE_P|perm es %08x\n",page_PA, PTE_P|perm);

	pp->pp_ref++;
	return 0;
}
f0101844:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101847:	5b                   	pop    %ebx
f0101848:	5e                   	pop    %esi
f0101849:	5f                   	pop    %edi
f010184a:	5d                   	pop    %ebp
f010184b:	c3                   	ret    

f010184c <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f010184c:	55                   	push   %ebp
f010184d:	89 e5                	mov    %esp,%ebp
f010184f:	57                   	push   %edi
f0101850:	56                   	push   %esi
f0101851:	53                   	push   %ebx
f0101852:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101855:	6a 00                	push   $0x0
f0101857:	e8 fa f8 ff ff       	call   f0101156 <page_alloc>
f010185c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010185f:	83 c4 10             	add    $0x10,%esp
f0101862:	85 c0                	test   %eax,%eax
f0101864:	75 19                	jne    f010187f <check_page+0x33>
f0101866:	68 23 48 10 f0       	push   $0xf0104823
f010186b:	68 28 47 10 f0       	push   $0xf0104728
f0101870:	68 08 03 00 00       	push   $0x308
f0101875:	68 d7 46 10 f0       	push   $0xf01046d7
f010187a:	e8 0c e8 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010187f:	83 ec 0c             	sub    $0xc,%esp
f0101882:	6a 00                	push   $0x0
f0101884:	e8 cd f8 ff ff       	call   f0101156 <page_alloc>
f0101889:	89 c3                	mov    %eax,%ebx
f010188b:	83 c4 10             	add    $0x10,%esp
f010188e:	85 c0                	test   %eax,%eax
f0101890:	75 19                	jne    f01018ab <check_page+0x5f>
f0101892:	68 39 48 10 f0       	push   $0xf0104839
f0101897:	68 28 47 10 f0       	push   $0xf0104728
f010189c:	68 09 03 00 00       	push   $0x309
f01018a1:	68 d7 46 10 f0       	push   $0xf01046d7
f01018a6:	e8 e0 e7 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01018ab:	83 ec 0c             	sub    $0xc,%esp
f01018ae:	6a 00                	push   $0x0
f01018b0:	e8 a1 f8 ff ff       	call   f0101156 <page_alloc>
f01018b5:	89 c6                	mov    %eax,%esi
f01018b7:	83 c4 10             	add    $0x10,%esp
f01018ba:	85 c0                	test   %eax,%eax
f01018bc:	75 19                	jne    f01018d7 <check_page+0x8b>
f01018be:	68 4f 48 10 f0       	push   $0xf010484f
f01018c3:	68 28 47 10 f0       	push   $0xf0104728
f01018c8:	68 0a 03 00 00       	push   $0x30a
f01018cd:	68 d7 46 10 f0       	push   $0xf01046d7
f01018d2:	e8 b4 e7 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018d7:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018da:	75 19                	jne    f01018f5 <check_page+0xa9>
f01018dc:	68 65 48 10 f0       	push   $0xf0104865
f01018e1:	68 28 47 10 f0       	push   $0xf0104728
f01018e6:	68 0d 03 00 00       	push   $0x30d
f01018eb:	68 d7 46 10 f0       	push   $0xf01046d7
f01018f0:	e8 96 e7 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018f5:	39 c3                	cmp    %eax,%ebx
f01018f7:	74 05                	je     f01018fe <check_page+0xb2>
f01018f9:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018fc:	75 19                	jne    f0101917 <check_page+0xcb>
f01018fe:	68 cc 3f 10 f0       	push   $0xf0103fcc
f0101903:	68 28 47 10 f0       	push   $0xf0104728
f0101908:	68 0e 03 00 00       	push   $0x30e
f010190d:	68 d7 46 10 f0       	push   $0xf01046d7
f0101912:	e8 74 e7 ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101917:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010191c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010191f:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101926:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101929:	83 ec 0c             	sub    $0xc,%esp
f010192c:	6a 00                	push   $0x0
f010192e:	e8 23 f8 ff ff       	call   f0101156 <page_alloc>
f0101933:	83 c4 10             	add    $0x10,%esp
f0101936:	85 c0                	test   %eax,%eax
f0101938:	74 19                	je     f0101953 <check_page+0x107>
f010193a:	68 ce 48 10 f0       	push   $0xf01048ce
f010193f:	68 28 47 10 f0       	push   $0xf0104728
f0101944:	68 15 03 00 00       	push   $0x315
f0101949:	68 d7 46 10 f0       	push   $0xf01046d7
f010194e:	e8 38 e7 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101953:	83 ec 04             	sub    $0x4,%esp
f0101956:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101959:	50                   	push   %eax
f010195a:	6a 00                	push   $0x0
f010195c:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101962:	e8 22 fd ff ff       	call   f0101689 <page_lookup>
f0101967:	83 c4 10             	add    $0x10,%esp
f010196a:	85 c0                	test   %eax,%eax
f010196c:	74 19                	je     f0101987 <check_page+0x13b>
f010196e:	68 00 41 10 f0       	push   $0xf0104100
f0101973:	68 28 47 10 f0       	push   $0xf0104728
f0101978:	68 18 03 00 00       	push   $0x318
f010197d:	68 d7 46 10 f0       	push   $0xf01046d7
f0101982:	e8 04 e7 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101987:	6a 02                	push   $0x2
f0101989:	6a 00                	push   $0x0
f010198b:	53                   	push   %ebx
f010198c:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101992:	e8 c6 fd ff ff       	call   f010175d <page_insert>
f0101997:	83 c4 10             	add    $0x10,%esp
f010199a:	85 c0                	test   %eax,%eax
f010199c:	78 19                	js     f01019b7 <check_page+0x16b>
f010199e:	68 38 41 10 f0       	push   $0xf0104138
f01019a3:	68 28 47 10 f0       	push   $0xf0104728
f01019a8:	68 1b 03 00 00       	push   $0x31b
f01019ad:	68 d7 46 10 f0       	push   $0xf01046d7
f01019b2:	e8 d4 e6 ff ff       	call   f010008b <_panic>


	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019b7:	83 ec 0c             	sub    $0xc,%esp
f01019ba:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019bd:	e8 d9 f7 ff ff       	call   f010119b <page_free>
	cprintf("\nA PARTIR DE ACA IMPORTA\n");//DEBUG2
f01019c2:	c7 04 24 56 49 10 f0 	movl   $0xf0104956,(%esp)
f01019c9:	e8 de 0e 00 00       	call   f01028ac <cprintf>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019ce:	6a 02                	push   $0x2
f01019d0:	6a 00                	push   $0x0
f01019d2:	53                   	push   %ebx
f01019d3:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01019d9:	e8 7f fd ff ff       	call   f010175d <page_insert>
f01019de:	83 c4 20             	add    $0x20,%esp
f01019e1:	85 c0                	test   %eax,%eax
f01019e3:	74 19                	je     f01019fe <check_page+0x1b2>
f01019e5:	68 68 41 10 f0       	push   $0xf0104168
f01019ea:	68 28 47 10 f0       	push   $0xf0104728
f01019ef:	68 21 03 00 00       	push   $0x321
f01019f4:	68 d7 46 10 f0       	push   $0xf01046d7
f01019f9:	e8 8d e6 ff ff       	call   f010008b <_panic>
//	cprintf("page2pa(pp0) es %p\n",page2pa(pp0));//DEBUG2
//	cprintf("pero PTE_ADDR(kern_pgdir[0]) es %p\n",PTE_ADDR(kern_pgdir[0]));//DEBUG2
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019fe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a01:	e8 09 f0 ff ff       	call   f0100a0f <page2pa>
f0101a06:	8b 15 48 79 11 f0    	mov    0xf0117948,%edx
f0101a0c:	8b 12                	mov    (%edx),%edx
f0101a0e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a14:	39 c2                	cmp    %eax,%edx
f0101a16:	74 19                	je     f0101a31 <check_page+0x1e5>
f0101a18:	68 98 41 10 f0       	push   $0xf0104198
f0101a1d:	68 28 47 10 f0       	push   $0xf0104728
f0101a22:	68 24 03 00 00       	push   $0x324
f0101a27:	68 d7 46 10 f0       	push   $0xf01046d7
f0101a2c:	e8 5a e6 ff ff       	call   f010008b <_panic>
	cprintf("page2pa(pp1) es %p\n",page2pa(pp1));//DEBUG2
f0101a31:	89 d8                	mov    %ebx,%eax
f0101a33:	e8 d7 ef ff ff       	call   f0100a0f <page2pa>
f0101a38:	83 ec 08             	sub    $0x8,%esp
f0101a3b:	50                   	push   %eax
f0101a3c:	68 70 49 10 f0       	push   $0xf0104970
f0101a41:	e8 66 0e 00 00       	call   f01028ac <cprintf>
	cprintf("pero check_va2pa(kern_pgdir, 0x0) es %p\n",check_va2pa(kern_pgdir, 0x0));//DEBUG2
f0101a46:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a4b:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101a50:	e8 0e f1 ff ff       	call   f0100b63 <check_va2pa>
f0101a55:	83 c4 08             	add    $0x8,%esp
f0101a58:	50                   	push   %eax
f0101a59:	68 c0 41 10 f0       	push   $0xf01041c0
f0101a5e:	e8 49 0e 00 00       	call   f01028ac <cprintf>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a63:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a68:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101a6d:	e8 f1 f0 ff ff       	call   f0100b63 <check_va2pa>
f0101a72:	89 c7                	mov    %eax,%edi
f0101a74:	89 d8                	mov    %ebx,%eax
f0101a76:	e8 94 ef ff ff       	call   f0100a0f <page2pa>
f0101a7b:	83 c4 10             	add    $0x10,%esp
f0101a7e:	39 c7                	cmp    %eax,%edi
f0101a80:	74 19                	je     f0101a9b <check_page+0x24f>
f0101a82:	68 ec 41 10 f0       	push   $0xf01041ec
f0101a87:	68 28 47 10 f0       	push   $0xf0104728
f0101a8c:	68 27 03 00 00       	push   $0x327
f0101a91:	68 d7 46 10 f0       	push   $0xf01046d7
f0101a96:	e8 f0 e5 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101a9b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101aa0:	74 19                	je     f0101abb <check_page+0x26f>
f0101aa2:	68 84 49 10 f0       	push   $0xf0104984
f0101aa7:	68 28 47 10 f0       	push   $0xf0104728
f0101aac:	68 28 03 00 00       	push   $0x328
f0101ab1:	68 d7 46 10 f0       	push   $0xf01046d7
f0101ab6:	e8 d0 e5 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101abb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101abe:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ac3:	74 19                	je     f0101ade <check_page+0x292>
f0101ac5:	68 95 49 10 f0       	push   $0xf0104995
f0101aca:	68 28 47 10 f0       	push   $0xf0104728
f0101acf:	68 29 03 00 00       	push   $0x329
f0101ad4:	68 d7 46 10 f0       	push   $0xf01046d7
f0101ad9:	e8 ad e5 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ade:	6a 02                	push   $0x2
f0101ae0:	68 00 10 00 00       	push   $0x1000
f0101ae5:	56                   	push   %esi
f0101ae6:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101aec:	e8 6c fc ff ff       	call   f010175d <page_insert>
f0101af1:	83 c4 10             	add    $0x10,%esp
f0101af4:	85 c0                	test   %eax,%eax
f0101af6:	74 19                	je     f0101b11 <check_page+0x2c5>
f0101af8:	68 1c 42 10 f0       	push   $0xf010421c
f0101afd:	68 28 47 10 f0       	push   $0xf0104728
f0101b02:	68 2c 03 00 00       	push   $0x32c
f0101b07:	68 d7 46 10 f0       	push   $0xf01046d7
f0101b0c:	e8 7a e5 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b11:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b16:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101b1b:	e8 43 f0 ff ff       	call   f0100b63 <check_va2pa>
f0101b20:	89 c7                	mov    %eax,%edi
f0101b22:	89 f0                	mov    %esi,%eax
f0101b24:	e8 e6 ee ff ff       	call   f0100a0f <page2pa>
f0101b29:	39 c7                	cmp    %eax,%edi
f0101b2b:	74 19                	je     f0101b46 <check_page+0x2fa>
f0101b2d:	68 58 42 10 f0       	push   $0xf0104258
f0101b32:	68 28 47 10 f0       	push   $0xf0104728
f0101b37:	68 2d 03 00 00       	push   $0x32d
f0101b3c:	68 d7 46 10 f0       	push   $0xf01046d7
f0101b41:	e8 45 e5 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101b46:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b4b:	74 19                	je     f0101b66 <check_page+0x31a>
f0101b4d:	68 a6 49 10 f0       	push   $0xf01049a6
f0101b52:	68 28 47 10 f0       	push   $0xf0104728
f0101b57:	68 2e 03 00 00       	push   $0x32e
f0101b5c:	68 d7 46 10 f0       	push   $0xf01046d7
f0101b61:	e8 25 e5 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b66:	83 ec 0c             	sub    $0xc,%esp
f0101b69:	6a 00                	push   $0x0
f0101b6b:	e8 e6 f5 ff ff       	call   f0101156 <page_alloc>
f0101b70:	83 c4 10             	add    $0x10,%esp
f0101b73:	85 c0                	test   %eax,%eax
f0101b75:	74 19                	je     f0101b90 <check_page+0x344>
f0101b77:	68 ce 48 10 f0       	push   $0xf01048ce
f0101b7c:	68 28 47 10 f0       	push   $0xf0104728
f0101b81:	68 31 03 00 00       	push   $0x331
f0101b86:	68 d7 46 10 f0       	push   $0xf01046d7
f0101b8b:	e8 fb e4 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b90:	6a 02                	push   $0x2
f0101b92:	68 00 10 00 00       	push   $0x1000
f0101b97:	56                   	push   %esi
f0101b98:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b9e:	e8 ba fb ff ff       	call   f010175d <page_insert>
f0101ba3:	83 c4 10             	add    $0x10,%esp
f0101ba6:	85 c0                	test   %eax,%eax
f0101ba8:	74 19                	je     f0101bc3 <check_page+0x377>
f0101baa:	68 1c 42 10 f0       	push   $0xf010421c
f0101baf:	68 28 47 10 f0       	push   $0xf0104728
f0101bb4:	68 34 03 00 00       	push   $0x334
f0101bb9:	68 d7 46 10 f0       	push   $0xf01046d7
f0101bbe:	e8 c8 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bc3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bc8:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101bcd:	e8 91 ef ff ff       	call   f0100b63 <check_va2pa>
f0101bd2:	89 c7                	mov    %eax,%edi
f0101bd4:	89 f0                	mov    %esi,%eax
f0101bd6:	e8 34 ee ff ff       	call   f0100a0f <page2pa>
f0101bdb:	39 c7                	cmp    %eax,%edi
f0101bdd:	74 19                	je     f0101bf8 <check_page+0x3ac>
f0101bdf:	68 58 42 10 f0       	push   $0xf0104258
f0101be4:	68 28 47 10 f0       	push   $0xf0104728
f0101be9:	68 35 03 00 00       	push   $0x335
f0101bee:	68 d7 46 10 f0       	push   $0xf01046d7
f0101bf3:	e8 93 e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101bf8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bfd:	74 19                	je     f0101c18 <check_page+0x3cc>
f0101bff:	68 a6 49 10 f0       	push   $0xf01049a6
f0101c04:	68 28 47 10 f0       	push   $0xf0104728
f0101c09:	68 36 03 00 00       	push   $0x336
f0101c0e:	68 d7 46 10 f0       	push   $0xf01046d7
f0101c13:	e8 73 e4 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c18:	83 ec 0c             	sub    $0xc,%esp
f0101c1b:	6a 00                	push   $0x0
f0101c1d:	e8 34 f5 ff ff       	call   f0101156 <page_alloc>
f0101c22:	83 c4 10             	add    $0x10,%esp
f0101c25:	85 c0                	test   %eax,%eax
f0101c27:	74 19                	je     f0101c42 <check_page+0x3f6>
f0101c29:	68 ce 48 10 f0       	push   $0xf01048ce
f0101c2e:	68 28 47 10 f0       	push   $0xf0104728
f0101c33:	68 3a 03 00 00       	push   $0x33a
f0101c38:	68 d7 46 10 f0       	push   $0xf01046d7
f0101c3d:	e8 49 e4 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c42:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101c48:	8b 0f                	mov    (%edi),%ecx
f0101c4a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101c50:	ba 3d 03 00 00       	mov    $0x33d,%edx
f0101c55:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f0101c5a:	e8 ba ee ff ff       	call   f0100b19 <_kaddr>
f0101c5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c62:	83 ec 04             	sub    $0x4,%esp
f0101c65:	6a 00                	push   $0x0
f0101c67:	68 00 10 00 00       	push   $0x1000
f0101c6c:	57                   	push   %edi
f0101c6d:	e8 6f f9 ff ff       	call   f01015e1 <pgdir_walk>
f0101c72:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c75:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c78:	83 c4 10             	add    $0x10,%esp
f0101c7b:	39 d0                	cmp    %edx,%eax
f0101c7d:	74 19                	je     f0101c98 <check_page+0x44c>
f0101c7f:	68 88 42 10 f0       	push   $0xf0104288
f0101c84:	68 28 47 10 f0       	push   $0xf0104728
f0101c89:	68 3e 03 00 00       	push   $0x33e
f0101c8e:	68 d7 46 10 f0       	push   $0xf01046d7
f0101c93:	e8 f3 e3 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c98:	6a 06                	push   $0x6
f0101c9a:	68 00 10 00 00       	push   $0x1000
f0101c9f:	56                   	push   %esi
f0101ca0:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101ca6:	e8 b2 fa ff ff       	call   f010175d <page_insert>
f0101cab:	83 c4 10             	add    $0x10,%esp
f0101cae:	85 c0                	test   %eax,%eax
f0101cb0:	74 19                	je     f0101ccb <check_page+0x47f>
f0101cb2:	68 c8 42 10 f0       	push   $0xf01042c8
f0101cb7:	68 28 47 10 f0       	push   $0xf0104728
f0101cbc:	68 41 03 00 00       	push   $0x341
f0101cc1:	68 d7 46 10 f0       	push   $0xf01046d7
f0101cc6:	e8 c0 e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ccb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cd0:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101cd5:	e8 89 ee ff ff       	call   f0100b63 <check_va2pa>
f0101cda:	89 c7                	mov    %eax,%edi
f0101cdc:	89 f0                	mov    %esi,%eax
f0101cde:	e8 2c ed ff ff       	call   f0100a0f <page2pa>
f0101ce3:	39 c7                	cmp    %eax,%edi
f0101ce5:	74 19                	je     f0101d00 <check_page+0x4b4>
f0101ce7:	68 58 42 10 f0       	push   $0xf0104258
f0101cec:	68 28 47 10 f0       	push   $0xf0104728
f0101cf1:	68 42 03 00 00       	push   $0x342
f0101cf6:	68 d7 46 10 f0       	push   $0xf01046d7
f0101cfb:	e8 8b e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101d00:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d05:	74 19                	je     f0101d20 <check_page+0x4d4>
f0101d07:	68 a6 49 10 f0       	push   $0xf01049a6
f0101d0c:	68 28 47 10 f0       	push   $0xf0104728
f0101d11:	68 43 03 00 00       	push   $0x343
f0101d16:	68 d7 46 10 f0       	push   $0xf01046d7
f0101d1b:	e8 6b e3 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d20:	83 ec 04             	sub    $0x4,%esp
f0101d23:	6a 00                	push   $0x0
f0101d25:	68 00 10 00 00       	push   $0x1000
f0101d2a:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d30:	e8 ac f8 ff ff       	call   f01015e1 <pgdir_walk>
f0101d35:	83 c4 10             	add    $0x10,%esp
f0101d38:	f6 00 04             	testb  $0x4,(%eax)
f0101d3b:	75 19                	jne    f0101d56 <check_page+0x50a>
f0101d3d:	68 08 43 10 f0       	push   $0xf0104308
f0101d42:	68 28 47 10 f0       	push   $0xf0104728
f0101d47:	68 44 03 00 00       	push   $0x344
f0101d4c:	68 d7 46 10 f0       	push   $0xf01046d7
f0101d51:	e8 35 e3 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d56:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101d5b:	f6 00 04             	testb  $0x4,(%eax)
f0101d5e:	75 19                	jne    f0101d79 <check_page+0x52d>
f0101d60:	68 b7 49 10 f0       	push   $0xf01049b7
f0101d65:	68 28 47 10 f0       	push   $0xf0104728
f0101d6a:	68 45 03 00 00       	push   $0x345
f0101d6f:	68 d7 46 10 f0       	push   $0xf01046d7
f0101d74:	e8 12 e3 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d79:	6a 02                	push   $0x2
f0101d7b:	68 00 10 00 00       	push   $0x1000
f0101d80:	56                   	push   %esi
f0101d81:	50                   	push   %eax
f0101d82:	e8 d6 f9 ff ff       	call   f010175d <page_insert>
f0101d87:	83 c4 10             	add    $0x10,%esp
f0101d8a:	85 c0                	test   %eax,%eax
f0101d8c:	74 19                	je     f0101da7 <check_page+0x55b>
f0101d8e:	68 1c 42 10 f0       	push   $0xf010421c
f0101d93:	68 28 47 10 f0       	push   $0xf0104728
f0101d98:	68 48 03 00 00       	push   $0x348
f0101d9d:	68 d7 46 10 f0       	push   $0xf01046d7
f0101da2:	e8 e4 e2 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101da7:	83 ec 04             	sub    $0x4,%esp
f0101daa:	6a 00                	push   $0x0
f0101dac:	68 00 10 00 00       	push   $0x1000
f0101db1:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101db7:	e8 25 f8 ff ff       	call   f01015e1 <pgdir_walk>
f0101dbc:	83 c4 10             	add    $0x10,%esp
f0101dbf:	f6 00 02             	testb  $0x2,(%eax)
f0101dc2:	75 19                	jne    f0101ddd <check_page+0x591>
f0101dc4:	68 3c 43 10 f0       	push   $0xf010433c
f0101dc9:	68 28 47 10 f0       	push   $0xf0104728
f0101dce:	68 49 03 00 00       	push   $0x349
f0101dd3:	68 d7 46 10 f0       	push   $0xf01046d7
f0101dd8:	e8 ae e2 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ddd:	83 ec 04             	sub    $0x4,%esp
f0101de0:	6a 00                	push   $0x0
f0101de2:	68 00 10 00 00       	push   $0x1000
f0101de7:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101ded:	e8 ef f7 ff ff       	call   f01015e1 <pgdir_walk>
f0101df2:	83 c4 10             	add    $0x10,%esp
f0101df5:	f6 00 04             	testb  $0x4,(%eax)
f0101df8:	74 19                	je     f0101e13 <check_page+0x5c7>
f0101dfa:	68 70 43 10 f0       	push   $0xf0104370
f0101dff:	68 28 47 10 f0       	push   $0xf0104728
f0101e04:	68 4a 03 00 00       	push   $0x34a
f0101e09:	68 d7 46 10 f0       	push   $0xf01046d7
f0101e0e:	e8 78 e2 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e13:	6a 02                	push   $0x2
f0101e15:	68 00 00 40 00       	push   $0x400000
f0101e1a:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e1d:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e23:	e8 35 f9 ff ff       	call   f010175d <page_insert>
f0101e28:	83 c4 10             	add    $0x10,%esp
f0101e2b:	85 c0                	test   %eax,%eax
f0101e2d:	78 19                	js     f0101e48 <check_page+0x5fc>
f0101e2f:	68 a8 43 10 f0       	push   $0xf01043a8
f0101e34:	68 28 47 10 f0       	push   $0xf0104728
f0101e39:	68 4d 03 00 00       	push   $0x34d
f0101e3e:	68 d7 46 10 f0       	push   $0xf01046d7
f0101e43:	e8 43 e2 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e48:	6a 02                	push   $0x2
f0101e4a:	68 00 10 00 00       	push   $0x1000
f0101e4f:	53                   	push   %ebx
f0101e50:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e56:	e8 02 f9 ff ff       	call   f010175d <page_insert>
f0101e5b:	83 c4 10             	add    $0x10,%esp
f0101e5e:	85 c0                	test   %eax,%eax
f0101e60:	74 19                	je     f0101e7b <check_page+0x62f>
f0101e62:	68 e0 43 10 f0       	push   $0xf01043e0
f0101e67:	68 28 47 10 f0       	push   $0xf0104728
f0101e6c:	68 50 03 00 00       	push   $0x350
f0101e71:	68 d7 46 10 f0       	push   $0xf01046d7
f0101e76:	e8 10 e2 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e7b:	83 ec 04             	sub    $0x4,%esp
f0101e7e:	6a 00                	push   $0x0
f0101e80:	68 00 10 00 00       	push   $0x1000
f0101e85:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e8b:	e8 51 f7 ff ff       	call   f01015e1 <pgdir_walk>
f0101e90:	83 c4 10             	add    $0x10,%esp
f0101e93:	f6 00 04             	testb  $0x4,(%eax)
f0101e96:	74 19                	je     f0101eb1 <check_page+0x665>
f0101e98:	68 70 43 10 f0       	push   $0xf0104370
f0101e9d:	68 28 47 10 f0       	push   $0xf0104728
f0101ea2:	68 51 03 00 00       	push   $0x351
f0101ea7:	68 d7 46 10 f0       	push   $0xf01046d7
f0101eac:	e8 da e1 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101eb1:	ba 00 00 00 00       	mov    $0x0,%edx
f0101eb6:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101ebb:	e8 a3 ec ff ff       	call   f0100b63 <check_va2pa>
f0101ec0:	89 c7                	mov    %eax,%edi
f0101ec2:	89 d8                	mov    %ebx,%eax
f0101ec4:	e8 46 eb ff ff       	call   f0100a0f <page2pa>
f0101ec9:	39 c7                	cmp    %eax,%edi
f0101ecb:	74 19                	je     f0101ee6 <check_page+0x69a>
f0101ecd:	68 1c 44 10 f0       	push   $0xf010441c
f0101ed2:	68 28 47 10 f0       	push   $0xf0104728
f0101ed7:	68 54 03 00 00       	push   $0x354
f0101edc:	68 d7 46 10 f0       	push   $0xf01046d7
f0101ee1:	e8 a5 e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ee6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eeb:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101ef0:	e8 6e ec ff ff       	call   f0100b63 <check_va2pa>
f0101ef5:	89 c7                	mov    %eax,%edi
f0101ef7:	89 d8                	mov    %ebx,%eax
f0101ef9:	e8 11 eb ff ff       	call   f0100a0f <page2pa>
f0101efe:	39 c7                	cmp    %eax,%edi
f0101f00:	74 19                	je     f0101f1b <check_page+0x6cf>
f0101f02:	68 48 44 10 f0       	push   $0xf0104448
f0101f07:	68 28 47 10 f0       	push   $0xf0104728
f0101f0c:	68 55 03 00 00       	push   $0x355
f0101f11:	68 d7 46 10 f0       	push   $0xf01046d7
f0101f16:	e8 70 e1 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f1b:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101f20:	74 19                	je     f0101f3b <check_page+0x6ef>
f0101f22:	68 cd 49 10 f0       	push   $0xf01049cd
f0101f27:	68 28 47 10 f0       	push   $0xf0104728
f0101f2c:	68 57 03 00 00       	push   $0x357
f0101f31:	68 d7 46 10 f0       	push   $0xf01046d7
f0101f36:	e8 50 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101f3b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f40:	74 19                	je     f0101f5b <check_page+0x70f>
f0101f42:	68 de 49 10 f0       	push   $0xf01049de
f0101f47:	68 28 47 10 f0       	push   $0xf0104728
f0101f4c:	68 58 03 00 00       	push   $0x358
f0101f51:	68 d7 46 10 f0       	push   $0xf01046d7
f0101f56:	e8 30 e1 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f5b:	83 ec 0c             	sub    $0xc,%esp
f0101f5e:	6a 00                	push   $0x0
f0101f60:	e8 f1 f1 ff ff       	call   f0101156 <page_alloc>
f0101f65:	83 c4 10             	add    $0x10,%esp
f0101f68:	39 c6                	cmp    %eax,%esi
f0101f6a:	75 04                	jne    f0101f70 <check_page+0x724>
f0101f6c:	85 c0                	test   %eax,%eax
f0101f6e:	75 19                	jne    f0101f89 <check_page+0x73d>
f0101f70:	68 78 44 10 f0       	push   $0xf0104478
f0101f75:	68 28 47 10 f0       	push   $0xf0104728
f0101f7a:	68 5b 03 00 00       	push   $0x35b
f0101f7f:	68 d7 46 10 f0       	push   $0xf01046d7
f0101f84:	e8 02 e1 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f89:	83 ec 08             	sub    $0x8,%esp
f0101f8c:	6a 00                	push   $0x0
f0101f8e:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101f94:	e8 59 f7 ff ff       	call   f01016f2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f99:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f9e:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101fa3:	e8 bb eb ff ff       	call   f0100b63 <check_va2pa>
f0101fa8:	83 c4 10             	add    $0x10,%esp
f0101fab:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fae:	74 19                	je     f0101fc9 <check_page+0x77d>
f0101fb0:	68 9c 44 10 f0       	push   $0xf010449c
f0101fb5:	68 28 47 10 f0       	push   $0xf0104728
f0101fba:	68 5f 03 00 00       	push   $0x35f
f0101fbf:	68 d7 46 10 f0       	push   $0xf01046d7
f0101fc4:	e8 c2 e0 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fc9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fce:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101fd3:	e8 8b eb ff ff       	call   f0100b63 <check_va2pa>
f0101fd8:	89 c7                	mov    %eax,%edi
f0101fda:	89 d8                	mov    %ebx,%eax
f0101fdc:	e8 2e ea ff ff       	call   f0100a0f <page2pa>
f0101fe1:	39 c7                	cmp    %eax,%edi
f0101fe3:	74 19                	je     f0101ffe <check_page+0x7b2>
f0101fe5:	68 48 44 10 f0       	push   $0xf0104448
f0101fea:	68 28 47 10 f0       	push   $0xf0104728
f0101fef:	68 60 03 00 00       	push   $0x360
f0101ff4:	68 d7 46 10 f0       	push   $0xf01046d7
f0101ff9:	e8 8d e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101ffe:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102003:	74 19                	je     f010201e <check_page+0x7d2>
f0102005:	68 84 49 10 f0       	push   $0xf0104984
f010200a:	68 28 47 10 f0       	push   $0xf0104728
f010200f:	68 61 03 00 00       	push   $0x361
f0102014:	68 d7 46 10 f0       	push   $0xf01046d7
f0102019:	e8 6d e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f010201e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102023:	74 19                	je     f010203e <check_page+0x7f2>
f0102025:	68 de 49 10 f0       	push   $0xf01049de
f010202a:	68 28 47 10 f0       	push   $0xf0104728
f010202f:	68 62 03 00 00       	push   $0x362
f0102034:	68 d7 46 10 f0       	push   $0xf01046d7
f0102039:	e8 4d e0 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010203e:	6a 00                	push   $0x0
f0102040:	68 00 10 00 00       	push   $0x1000
f0102045:	53                   	push   %ebx
f0102046:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010204c:	e8 0c f7 ff ff       	call   f010175d <page_insert>
f0102051:	83 c4 10             	add    $0x10,%esp
f0102054:	85 c0                	test   %eax,%eax
f0102056:	74 19                	je     f0102071 <check_page+0x825>
f0102058:	68 c0 44 10 f0       	push   $0xf01044c0
f010205d:	68 28 47 10 f0       	push   $0xf0104728
f0102062:	68 65 03 00 00       	push   $0x365
f0102067:	68 d7 46 10 f0       	push   $0xf01046d7
f010206c:	e8 1a e0 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0102071:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102076:	75 19                	jne    f0102091 <check_page+0x845>
f0102078:	68 ef 49 10 f0       	push   $0xf01049ef
f010207d:	68 28 47 10 f0       	push   $0xf0104728
f0102082:	68 66 03 00 00       	push   $0x366
f0102087:	68 d7 46 10 f0       	push   $0xf01046d7
f010208c:	e8 fa df ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0102091:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102094:	74 19                	je     f01020af <check_page+0x863>
f0102096:	68 fb 49 10 f0       	push   $0xf01049fb
f010209b:	68 28 47 10 f0       	push   $0xf0104728
f01020a0:	68 67 03 00 00       	push   $0x367
f01020a5:	68 d7 46 10 f0       	push   $0xf01046d7
f01020aa:	e8 dc df ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020af:	83 ec 08             	sub    $0x8,%esp
f01020b2:	68 00 10 00 00       	push   $0x1000
f01020b7:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01020bd:	e8 30 f6 ff ff       	call   f01016f2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01020c7:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01020cc:	e8 92 ea ff ff       	call   f0100b63 <check_va2pa>
f01020d1:	83 c4 10             	add    $0x10,%esp
f01020d4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020d7:	74 19                	je     f01020f2 <check_page+0x8a6>
f01020d9:	68 9c 44 10 f0       	push   $0xf010449c
f01020de:	68 28 47 10 f0       	push   $0xf0104728
f01020e3:	68 6b 03 00 00       	push   $0x36b
f01020e8:	68 d7 46 10 f0       	push   $0xf01046d7
f01020ed:	e8 99 df ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020f2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020f7:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01020fc:	e8 62 ea ff ff       	call   f0100b63 <check_va2pa>
f0102101:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102104:	74 19                	je     f010211f <check_page+0x8d3>
f0102106:	68 f8 44 10 f0       	push   $0xf01044f8
f010210b:	68 28 47 10 f0       	push   $0xf0104728
f0102110:	68 6c 03 00 00       	push   $0x36c
f0102115:	68 d7 46 10 f0       	push   $0xf01046d7
f010211a:	e8 6c df ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010211f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102124:	74 19                	je     f010213f <check_page+0x8f3>
f0102126:	68 10 4a 10 f0       	push   $0xf0104a10
f010212b:	68 28 47 10 f0       	push   $0xf0104728
f0102130:	68 6d 03 00 00       	push   $0x36d
f0102135:	68 d7 46 10 f0       	push   $0xf01046d7
f010213a:	e8 4c df ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f010213f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102144:	74 19                	je     f010215f <check_page+0x913>
f0102146:	68 de 49 10 f0       	push   $0xf01049de
f010214b:	68 28 47 10 f0       	push   $0xf0104728
f0102150:	68 6e 03 00 00       	push   $0x36e
f0102155:	68 d7 46 10 f0       	push   $0xf01046d7
f010215a:	e8 2c df ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010215f:	83 ec 0c             	sub    $0xc,%esp
f0102162:	6a 00                	push   $0x0
f0102164:	e8 ed ef ff ff       	call   f0101156 <page_alloc>
f0102169:	83 c4 10             	add    $0x10,%esp
f010216c:	39 c3                	cmp    %eax,%ebx
f010216e:	75 04                	jne    f0102174 <check_page+0x928>
f0102170:	85 c0                	test   %eax,%eax
f0102172:	75 19                	jne    f010218d <check_page+0x941>
f0102174:	68 20 45 10 f0       	push   $0xf0104520
f0102179:	68 28 47 10 f0       	push   $0xf0104728
f010217e:	68 71 03 00 00       	push   $0x371
f0102183:	68 d7 46 10 f0       	push   $0xf01046d7
f0102188:	e8 fe de ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010218d:	83 ec 0c             	sub    $0xc,%esp
f0102190:	6a 00                	push   $0x0
f0102192:	e8 bf ef ff ff       	call   f0101156 <page_alloc>
f0102197:	83 c4 10             	add    $0x10,%esp
f010219a:	85 c0                	test   %eax,%eax
f010219c:	74 19                	je     f01021b7 <check_page+0x96b>
f010219e:	68 ce 48 10 f0       	push   $0xf01048ce
f01021a3:	68 28 47 10 f0       	push   $0xf0104728
f01021a8:	68 74 03 00 00       	push   $0x374
f01021ad:	68 d7 46 10 f0       	push   $0xf01046d7
f01021b2:	e8 d4 de ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021b7:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f01021bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021c0:	e8 4a e8 ff ff       	call   f0100a0f <page2pa>
f01021c5:	8b 17                	mov    (%edi),%edx
f01021c7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01021cd:	39 c2                	cmp    %eax,%edx
f01021cf:	74 19                	je     f01021ea <check_page+0x99e>
f01021d1:	68 98 41 10 f0       	push   $0xf0104198
f01021d6:	68 28 47 10 f0       	push   $0xf0104728
f01021db:	68 77 03 00 00       	push   $0x377
f01021e0:	68 d7 46 10 f0       	push   $0xf01046d7
f01021e5:	e8 a1 de ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f01021ea:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	assert(pp0->pp_ref == 1);
f01021f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021f3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021f8:	74 19                	je     f0102213 <check_page+0x9c7>
f01021fa:	68 95 49 10 f0       	push   $0xf0104995
f01021ff:	68 28 47 10 f0       	push   $0xf0104728
f0102204:	68 79 03 00 00       	push   $0x379
f0102209:	68 d7 46 10 f0       	push   $0xf01046d7
f010220e:	e8 78 de ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0102213:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102216:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010221c:	83 ec 0c             	sub    $0xc,%esp
f010221f:	50                   	push   %eax
f0102220:	e8 76 ef ff ff       	call   f010119b <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102225:	83 c4 0c             	add    $0xc,%esp
f0102228:	6a 01                	push   $0x1
f010222a:	68 00 10 40 00       	push   $0x401000
f010222f:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102235:	e8 a7 f3 ff ff       	call   f01015e1 <pgdir_walk>
f010223a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010223d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102240:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0102246:	8b 4f 04             	mov    0x4(%edi),%ecx
f0102249:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010224f:	ba 80 03 00 00       	mov    $0x380,%edx
f0102254:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f0102259:	e8 bb e8 ff ff       	call   f0100b19 <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f010225e:	83 c0 04             	add    $0x4,%eax
f0102261:	83 c4 10             	add    $0x10,%esp
f0102264:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102267:	74 19                	je     f0102282 <check_page+0xa36>
f0102269:	68 21 4a 10 f0       	push   $0xf0104a21
f010226e:	68 28 47 10 f0       	push   $0xf0104728
f0102273:	68 81 03 00 00       	push   $0x381
f0102278:	68 d7 46 10 f0       	push   $0xf01046d7
f010227d:	e8 09 de ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102282:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f0102289:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010228c:	89 f8                	mov    %edi,%eax
f010228e:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102294:	e8 ac e8 ff ff       	call   f0100b45 <page2kva>
f0102299:	83 ec 04             	sub    $0x4,%esp
f010229c:	68 00 10 00 00       	push   $0x1000
f01022a1:	68 ff 00 00 00       	push   $0xff
f01022a6:	50                   	push   %eax
f01022a7:	e8 a4 10 00 00       	call   f0103350 <memset>
	page_free(pp0);
f01022ac:	89 3c 24             	mov    %edi,(%esp)
f01022af:	e8 e7 ee ff ff       	call   f010119b <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022b4:	83 c4 0c             	add    $0xc,%esp
f01022b7:	6a 01                	push   $0x1
f01022b9:	6a 00                	push   $0x0
f01022bb:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01022c1:	e8 1b f3 ff ff       	call   f01015e1 <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f01022c6:	89 f8                	mov    %edi,%eax
f01022c8:	e8 78 e8 ff ff       	call   f0100b45 <page2kva>
f01022cd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022d0:	89 c2                	mov    %eax,%edx
f01022d2:	05 00 10 00 00       	add    $0x1000,%eax
f01022d7:	83 c4 10             	add    $0x10,%esp
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022da:	f6 02 01             	testb  $0x1,(%edx)
f01022dd:	74 19                	je     f01022f8 <check_page+0xaac>
f01022df:	68 39 4a 10 f0       	push   $0xf0104a39
f01022e4:	68 28 47 10 f0       	push   $0xf0104728
f01022e9:	68 8b 03 00 00       	push   $0x38b
f01022ee:	68 d7 46 10 f0       	push   $0xf01046d7
f01022f3:	e8 93 dd ff ff       	call   f010008b <_panic>
f01022f8:	83 c2 04             	add    $0x4,%edx
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022fb:	39 c2                	cmp    %eax,%edx
f01022fd:	75 db                	jne    f01022da <check_page+0xa8e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022ff:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0102304:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010230a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010230d:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102313:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102316:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f010231c:	83 ec 0c             	sub    $0xc,%esp
f010231f:	50                   	push   %eax
f0102320:	e8 76 ee ff ff       	call   f010119b <page_free>
	page_free(pp1);
f0102325:	89 1c 24             	mov    %ebx,(%esp)
f0102328:	e8 6e ee ff ff       	call   f010119b <page_free>
	page_free(pp2);
f010232d:	89 34 24             	mov    %esi,(%esp)
f0102330:	e8 66 ee ff ff       	call   f010119b <page_free>

	cprintf("check_page() succeeded!\n");
f0102335:	c7 04 24 50 4a 10 f0 	movl   $0xf0104a50,(%esp)
f010233c:	e8 6b 05 00 00       	call   f01028ac <cprintf>
}
f0102341:	83 c4 10             	add    $0x10,%esp
f0102344:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102347:	5b                   	pop    %ebx
f0102348:	5e                   	pop    %esi
f0102349:	5f                   	pop    %edi
f010234a:	5d                   	pop    %ebp
f010234b:	c3                   	ret    

f010234c <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f010234c:	55                   	push   %ebp
f010234d:	89 e5                	mov    %esp,%ebp
f010234f:	57                   	push   %edi
f0102350:	56                   	push   %esi
f0102351:	53                   	push   %ebx
f0102352:	83 ec 18             	sub    $0x18,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102355:	6a 00                	push   $0x0
f0102357:	e8 fa ed ff ff       	call   f0101156 <page_alloc>
f010235c:	83 c4 10             	add    $0x10,%esp
f010235f:	85 c0                	test   %eax,%eax
f0102361:	75 19                	jne    f010237c <check_page_installed_pgdir+0x30>
f0102363:	68 23 48 10 f0       	push   $0xf0104823
f0102368:	68 28 47 10 f0       	push   $0xf0104728
f010236d:	68 a6 03 00 00       	push   $0x3a6
f0102372:	68 d7 46 10 f0       	push   $0xf01046d7
f0102377:	e8 0f dd ff ff       	call   f010008b <_panic>
f010237c:	89 c6                	mov    %eax,%esi
	assert((pp1 = page_alloc(0)));
f010237e:	83 ec 0c             	sub    $0xc,%esp
f0102381:	6a 00                	push   $0x0
f0102383:	e8 ce ed ff ff       	call   f0101156 <page_alloc>
f0102388:	89 c7                	mov    %eax,%edi
f010238a:	83 c4 10             	add    $0x10,%esp
f010238d:	85 c0                	test   %eax,%eax
f010238f:	75 19                	jne    f01023aa <check_page_installed_pgdir+0x5e>
f0102391:	68 39 48 10 f0       	push   $0xf0104839
f0102396:	68 28 47 10 f0       	push   $0xf0104728
f010239b:	68 a7 03 00 00       	push   $0x3a7
f01023a0:	68 d7 46 10 f0       	push   $0xf01046d7
f01023a5:	e8 e1 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023aa:	83 ec 0c             	sub    $0xc,%esp
f01023ad:	6a 00                	push   $0x0
f01023af:	e8 a2 ed ff ff       	call   f0101156 <page_alloc>
f01023b4:	89 c3                	mov    %eax,%ebx
f01023b6:	83 c4 10             	add    $0x10,%esp
f01023b9:	85 c0                	test   %eax,%eax
f01023bb:	75 19                	jne    f01023d6 <check_page_installed_pgdir+0x8a>
f01023bd:	68 4f 48 10 f0       	push   $0xf010484f
f01023c2:	68 28 47 10 f0       	push   $0xf0104728
f01023c7:	68 a8 03 00 00       	push   $0x3a8
f01023cc:	68 d7 46 10 f0       	push   $0xf01046d7
f01023d1:	e8 b5 dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f01023d6:	83 ec 0c             	sub    $0xc,%esp
f01023d9:	56                   	push   %esi
f01023da:	e8 bc ed ff ff       	call   f010119b <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01023df:	89 f8                	mov    %edi,%eax
f01023e1:	e8 5f e7 ff ff       	call   f0100b45 <page2kva>
f01023e6:	83 c4 0c             	add    $0xc,%esp
f01023e9:	68 00 10 00 00       	push   $0x1000
f01023ee:	6a 01                	push   $0x1
f01023f0:	50                   	push   %eax
f01023f1:	e8 5a 0f 00 00       	call   f0103350 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01023f6:	89 d8                	mov    %ebx,%eax
f01023f8:	e8 48 e7 ff ff       	call   f0100b45 <page2kva>
f01023fd:	83 c4 0c             	add    $0xc,%esp
f0102400:	68 00 10 00 00       	push   $0x1000
f0102405:	6a 02                	push   $0x2
f0102407:	50                   	push   %eax
f0102408:	e8 43 0f 00 00       	call   f0103350 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010240d:	6a 02                	push   $0x2
f010240f:	68 00 10 00 00       	push   $0x1000
f0102414:	57                   	push   %edi
f0102415:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010241b:	e8 3d f3 ff ff       	call   f010175d <page_insert>
	assert(pp1->pp_ref == 1);
f0102420:	83 c4 20             	add    $0x20,%esp
f0102423:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102428:	74 19                	je     f0102443 <check_page_installed_pgdir+0xf7>
f010242a:	68 84 49 10 f0       	push   $0xf0104984
f010242f:	68 28 47 10 f0       	push   $0xf0104728
f0102434:	68 ad 03 00 00       	push   $0x3ad
f0102439:	68 d7 46 10 f0       	push   $0xf01046d7
f010243e:	e8 48 dc ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102443:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010244a:	01 01 01 
f010244d:	74 19                	je     f0102468 <check_page_installed_pgdir+0x11c>
f010244f:	68 44 45 10 f0       	push   $0xf0104544
f0102454:	68 28 47 10 f0       	push   $0xf0104728
f0102459:	68 ae 03 00 00       	push   $0x3ae
f010245e:	68 d7 46 10 f0       	push   $0xf01046d7
f0102463:	e8 23 dc ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102468:	6a 02                	push   $0x2
f010246a:	68 00 10 00 00       	push   $0x1000
f010246f:	53                   	push   %ebx
f0102470:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102476:	e8 e2 f2 ff ff       	call   f010175d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010247b:	83 c4 10             	add    $0x10,%esp
f010247e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102485:	02 02 02 
f0102488:	74 19                	je     f01024a3 <check_page_installed_pgdir+0x157>
f010248a:	68 68 45 10 f0       	push   $0xf0104568
f010248f:	68 28 47 10 f0       	push   $0xf0104728
f0102494:	68 b0 03 00 00       	push   $0x3b0
f0102499:	68 d7 46 10 f0       	push   $0xf01046d7
f010249e:	e8 e8 db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01024a3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024a8:	74 19                	je     f01024c3 <check_page_installed_pgdir+0x177>
f01024aa:	68 a6 49 10 f0       	push   $0xf01049a6
f01024af:	68 28 47 10 f0       	push   $0xf0104728
f01024b4:	68 b1 03 00 00       	push   $0x3b1
f01024b9:	68 d7 46 10 f0       	push   $0xf01046d7
f01024be:	e8 c8 db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01024c3:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024c8:	74 19                	je     f01024e3 <check_page_installed_pgdir+0x197>
f01024ca:	68 10 4a 10 f0       	push   $0xf0104a10
f01024cf:	68 28 47 10 f0       	push   $0xf0104728
f01024d4:	68 b2 03 00 00       	push   $0x3b2
f01024d9:	68 d7 46 10 f0       	push   $0xf01046d7
f01024de:	e8 a8 db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01024e3:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01024ea:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024ed:	89 d8                	mov    %ebx,%eax
f01024ef:	e8 51 e6 ff ff       	call   f0100b45 <page2kva>
f01024f4:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01024fa:	74 19                	je     f0102515 <check_page_installed_pgdir+0x1c9>
f01024fc:	68 8c 45 10 f0       	push   $0xf010458c
f0102501:	68 28 47 10 f0       	push   $0xf0104728
f0102506:	68 b4 03 00 00       	push   $0x3b4
f010250b:	68 d7 46 10 f0       	push   $0xf01046d7
f0102510:	e8 76 db ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102515:	83 ec 08             	sub    $0x8,%esp
f0102518:	68 00 10 00 00       	push   $0x1000
f010251d:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102523:	e8 ca f1 ff ff       	call   f01016f2 <page_remove>
	assert(pp2->pp_ref == 0);
f0102528:	83 c4 10             	add    $0x10,%esp
f010252b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102530:	74 19                	je     f010254b <check_page_installed_pgdir+0x1ff>
f0102532:	68 de 49 10 f0       	push   $0xf01049de
f0102537:	68 28 47 10 f0       	push   $0xf0104728
f010253c:	68 b6 03 00 00       	push   $0x3b6
f0102541:	68 d7 46 10 f0       	push   $0xf01046d7
f0102546:	e8 40 db ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010254b:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f0102551:	89 f0                	mov    %esi,%eax
f0102553:	e8 b7 e4 ff ff       	call   f0100a0f <page2pa>
f0102558:	8b 13                	mov    (%ebx),%edx
f010255a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102560:	39 c2                	cmp    %eax,%edx
f0102562:	74 19                	je     f010257d <check_page_installed_pgdir+0x231>
f0102564:	68 98 41 10 f0       	push   $0xf0104198
f0102569:	68 28 47 10 f0       	push   $0xf0104728
f010256e:	68 b9 03 00 00       	push   $0x3b9
f0102573:	68 d7 46 10 f0       	push   $0xf01046d7
f0102578:	e8 0e db ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f010257d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102583:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102588:	74 19                	je     f01025a3 <check_page_installed_pgdir+0x257>
f010258a:	68 95 49 10 f0       	push   $0xf0104995
f010258f:	68 28 47 10 f0       	push   $0xf0104728
f0102594:	68 bb 03 00 00       	push   $0x3bb
f0102599:	68 d7 46 10 f0       	push   $0xf01046d7
f010259e:	e8 e8 da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f01025a3:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01025a9:	83 ec 0c             	sub    $0xc,%esp
f01025ac:	56                   	push   %esi
f01025ad:	e8 e9 eb ff ff       	call   f010119b <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01025b2:	c7 04 24 b8 45 10 f0 	movl   $0xf01045b8,(%esp)
f01025b9:	e8 ee 02 00 00       	call   f01028ac <cprintf>
}
f01025be:	83 c4 10             	add    $0x10,%esp
f01025c1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01025c4:	5b                   	pop    %ebx
f01025c5:	5e                   	pop    %esi
f01025c6:	5f                   	pop    %edi
f01025c7:	5d                   	pop    %ebp
f01025c8:	c3                   	ret    

f01025c9 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01025c9:	55                   	push   %ebp
f01025ca:	89 e5                	mov    %esp,%ebp
f01025cc:	53                   	push   %ebx
f01025cd:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f01025d0:	e8 74 e4 ff ff       	call   f0100a49 <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01025d5:	b8 00 10 00 00       	mov    $0x1000,%eax
f01025da:	e8 d0 e4 ff ff       	call   f0100aaf <boot_alloc>
f01025df:	a3 48 79 11 f0       	mov    %eax,0xf0117948
	memset(kern_pgdir, 0, PGSIZE);
f01025e4:	83 ec 04             	sub    $0x4,%esp
f01025e7:	68 00 10 00 00       	push   $0x1000
f01025ec:	6a 00                	push   $0x0
f01025ee:	50                   	push   %eax
f01025ef:	e8 5c 0d 00 00       	call   f0103350 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01025f4:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f01025fa:	89 d9                	mov    %ebx,%ecx
f01025fc:	ba 92 00 00 00       	mov    $0x92,%edx
f0102601:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f0102606:	e8 05 e6 ff ff       	call   f0100c10 <_paddr>
f010260b:	83 c8 05             	or     $0x5,%eax
f010260e:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:

	//Un PageInfo tiene 4B del PageInfo* +4B del uint16_t = 8B de size

	pages=(struct PageInfo *) boot_alloc(npages //[page]
f0102614:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0102619:	c1 e0 03             	shl    $0x3,%eax
f010261c:	e8 8e e4 ff ff       	call   f0100aaf <boot_alloc>
f0102621:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
										 * sizeof(struct PageInfo));//[B/page]

	memset(pages,0,npages*sizeof(struct PageInfo));
f0102626:	83 c4 0c             	add    $0xc,%esp
f0102629:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f010262f:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0102636:	52                   	push   %edx
f0102637:	6a 00                	push   $0x0
f0102639:	50                   	push   %eax
f010263a:	e8 11 0d 00 00       	call   f0103350 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010263f:	e8 94 ea ff ff       	call   f01010d8 <page_init>


	//parte de pruebas
	cprintf("\n***PRUEBAS DADA UN LINEAR ADDR***\n");
f0102644:	c7 04 24 e4 45 10 f0 	movl   $0xf01045e4,(%esp)
f010264b:	e8 5c 02 00 00       	call   f01028ac <cprintf>
	pde_t* kpd = kern_pgdir;
f0102650:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
	cprintf("	kern_pgdir es %p (32b)\n",kpd);
f0102656:	83 c4 08             	add    $0x8,%esp
f0102659:	53                   	push   %ebx
f010265a:	68 69 4a 10 f0       	push   $0xf0104a69
f010265f:	e8 48 02 00 00       	call   f01028ac <cprintf>
	cprintf("	PD index es %p (10b)\n",PDX(kpd));
f0102664:	83 c4 08             	add    $0x8,%esp
f0102667:	89 d8                	mov    %ebx,%eax
f0102669:	c1 e8 16             	shr    $0x16,%eax
f010266c:	50                   	push   %eax
f010266d:	68 82 4a 10 f0       	push   $0xf0104a82
f0102672:	e8 35 02 00 00       	call   f01028ac <cprintf>
	cprintf("	PT index es %p (10b)\n",PTX(kpd));
f0102677:	83 c4 08             	add    $0x8,%esp
f010267a:	89 d8                	mov    %ebx,%eax
f010267c:	c1 e8 0c             	shr    $0xc,%eax
f010267f:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102684:	50                   	push   %eax
f0102685:	68 99 4a 10 f0       	push   $0xf0104a99
f010268a:	e8 1d 02 00 00       	call   f01028ac <cprintf>
	cprintf("	PG offset es %p (12b)\n",PGOFF(kpd));
f010268f:	83 c4 08             	add    $0x8,%esp
f0102692:	89 d8                	mov    %ebx,%eax
f0102694:	25 ff 0f 00 00       	and    $0xfff,%eax
f0102699:	50                   	push   %eax
f010269a:	68 b0 4a 10 f0       	push   $0xf0104ab0
f010269f:	e8 08 02 00 00       	call   f01028ac <cprintf>

	void* va1 = (void*) 0x7fe1b6a7;
	cprintf("\n***ACCEDIENDO A KERN_PGDIR con VA = %p***\n",va1);
f01026a4:	83 c4 08             	add    $0x8,%esp
f01026a7:	68 a7 b6 e1 7f       	push   $0x7fe1b6a7
f01026ac:	68 08 46 10 f0       	push   $0xf0104608
f01026b1:	e8 f6 01 00 00       	call   f01028ac <cprintf>
	cprintf("	PD index es %p (10b)\n",PDX(va1));
f01026b6:	83 c4 08             	add    $0x8,%esp
f01026b9:	68 ff 01 00 00       	push   $0x1ff
f01026be:	68 82 4a 10 f0       	push   $0xf0104a82
f01026c3:	e8 e4 01 00 00       	call   f01028ac <cprintf>
	cprintf("	PT index es %p (10b)\n",PTX(va1));
f01026c8:	83 c4 08             	add    $0x8,%esp
f01026cb:	68 1b 02 00 00       	push   $0x21b
f01026d0:	68 99 4a 10 f0       	push   $0xf0104a99
f01026d5:	e8 d2 01 00 00       	call   f01028ac <cprintf>
	cprintf("	PG offset es %p (12b)\n",PGOFF(va1));
f01026da:	83 c4 08             	add    $0x8,%esp
f01026dd:	68 a7 06 00 00       	push   $0x6a7
f01026e2:	68 b0 4a 10 f0       	push   $0xf0104ab0
f01026e7:	e8 c0 01 00 00       	call   f01028ac <cprintf>
	cprintf("	kern_pgdir[PDX] es %p (32b)\n",kpd+PDX(va1));
f01026ec:	83 c4 08             	add    $0x8,%esp
f01026ef:	8d 83 fc 07 00 00    	lea    0x7fc(%ebx),%eax
f01026f5:	50                   	push   %eax
f01026f6:	68 c8 4a 10 f0       	push   $0xf0104ac8
f01026fb:	e8 ac 01 00 00       	call   f01028ac <cprintf>
	cprintf("	y su contenido es %p (32b)\n",kpd[PDX(va1)]);
f0102700:	83 c4 08             	add    $0x8,%esp
f0102703:	ff b3 fc 07 00 00    	pushl  0x7fc(%ebx)
f0102709:	68 e6 4a 10 f0       	push   $0xf0104ae6
f010270e:	e8 99 01 00 00       	call   f01028ac <cprintf>
	cprintf("	o tambien es %p (32b)\n",*(kpd+PDX(va1)));
f0102713:	83 c4 08             	add    $0x8,%esp
f0102716:	ff b3 fc 07 00 00    	pushl  0x7fc(%ebx)
f010271c:	68 03 4b 10 f0       	push   $0xf0104b03
f0102721:	e8 86 01 00 00       	call   f01028ac <cprintf>
	cprintf("	que maskeado es %p (32b, ultimos 10 en 0)\n",PTE_ADDR(kpd[PDX(va1)]));
f0102726:	83 c4 08             	add    $0x8,%esp
f0102729:	8b 83 fc 07 00 00    	mov    0x7fc(%ebx),%eax
f010272f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102734:	50                   	push   %eax
f0102735:	68 34 46 10 f0       	push   $0xf0104634
f010273a:	e8 6d 01 00 00       	call   f01028ac <cprintf>
	cprintf("	kern_pgdir[PTX] es %p (32b)\n",kpd+PTX(va1));
f010273f:	83 c4 08             	add    $0x8,%esp
f0102742:	8d 83 6c 08 00 00    	lea    0x86c(%ebx),%eax
f0102748:	50                   	push   %eax
f0102749:	68 1b 4b 10 f0       	push   $0xf0104b1b
f010274e:	e8 59 01 00 00       	call   f01028ac <cprintf>
	cprintf("	y su contenido es %p (32b)\n",kpd[PTX(va1)]);
f0102753:	83 c4 08             	add    $0x8,%esp
f0102756:	ff b3 6c 08 00 00    	pushl  0x86c(%ebx)
f010275c:	68 e6 4a 10 f0       	push   $0xf0104ae6
f0102761:	e8 46 01 00 00       	call   f01028ac <cprintf>
	cprintf("	o tambien es %p (32b)\n",*(kpd+PTX(va1)));
f0102766:	83 c4 08             	add    $0x8,%esp
f0102769:	ff b3 6c 08 00 00    	pushl  0x86c(%ebx)
f010276f:	68 03 4b 10 f0       	push   $0xf0104b03
f0102774:	e8 33 01 00 00       	call   f01028ac <cprintf>
	cprintf("	que maskeado es %p (32b, ultimos 10 en 0)\n",PTE_ADDR(kpd[PTX(va1)]));
f0102779:	83 c4 08             	add    $0x8,%esp
f010277c:	8b 83 6c 08 00 00    	mov    0x86c(%ebx),%eax
f0102782:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102787:	50                   	push   %eax
f0102788:	68 34 46 10 f0       	push   $0xf0104634
f010278d:	e8 1a 01 00 00       	call   f01028ac <cprintf>

	cprintf("\n***OPERACIONES DE MASKING con VA = %p***\n",va1);
f0102792:	83 c4 08             	add    $0x8,%esp
f0102795:	68 a7 b6 e1 7f       	push   $0x7fe1b6a7
f010279a:	68 60 46 10 f0       	push   $0xf0104660
f010279f:	e8 08 01 00 00       	call   f01028ac <cprintf>
	cprintf("	maskeada con PTE_ADDR es %p (vuela los 12 de abajo)\n",PTE_ADDR(va1));
f01027a4:	83 c4 08             	add    $0x8,%esp
f01027a7:	68 00 b0 e1 7f       	push   $0x7fe1b000
f01027ac:	68 8c 46 10 f0       	push   $0xf010468c
f01027b1:	e8 f6 00 00 00       	call   f01028ac <cprintf>
	cprintf("\n\n");
f01027b6:	c7 04 24 39 4b 10 f0 	movl   $0xf0104b39,(%esp)
f01027bd:	e8 ea 00 00 00       	call   f01028ac <cprintf>
	//end:parte pruebas

	check_page_free_list(1);
f01027c2:	b8 01 00 00 00       	mov    $0x1,%eax
f01027c7:	e8 68 e6 ff ff       	call   f0100e34 <check_page_free_list>
	check_page_alloc();
f01027cc:	e8 1c ea ff ff       	call   f01011ed <check_page_alloc>
	check_page();
f01027d1:	e8 76 f0 ff ff       	call   f010184c <check_page>
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f01027d6:	e8 57 e4 ff ff       	call   f0100c32 <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01027db:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f01027e1:	ba f5 00 00 00       	mov    $0xf5,%edx
f01027e6:	b8 d7 46 10 f0       	mov    $0xf01046d7,%eax
f01027eb:	e8 20 e4 ff ff       	call   f0100c10 <_paddr>
f01027f0:	e8 12 e2 ff ff       	call   f0100a07 <lcr3>

	check_page_free_list(0);
f01027f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01027fa:	e8 35 e6 ff ff       	call   f0100e34 <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f01027ff:	e8 fb e1 ff ff       	call   f01009ff <rcr0>
f0102804:	83 e0 f3             	and    $0xfffffff3,%eax
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);
f0102807:	0d 23 00 05 80       	or     $0x80050023,%eax
f010280c:	e8 e6 e1 ff ff       	call   f01009f7 <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f0102811:	e8 36 fb ff ff       	call   f010234c <check_page_installed_pgdir>
}
f0102816:	83 c4 10             	add    $0x10,%esp
f0102819:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010281c:	c9                   	leave  
f010281d:	c3                   	ret    

f010281e <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010281e:	55                   	push   %ebp
f010281f:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102821:	89 c2                	mov    %eax,%edx
f0102823:	ec                   	in     (%dx),%al
	return data;
}
f0102824:	5d                   	pop    %ebp
f0102825:	c3                   	ret    

f0102826 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0102826:	55                   	push   %ebp
f0102827:	89 e5                	mov    %esp,%ebp
f0102829:	89 c1                	mov    %eax,%ecx
f010282b:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010282d:	89 ca                	mov    %ecx,%edx
f010282f:	ee                   	out    %al,(%dx)
}
f0102830:	5d                   	pop    %ebp
f0102831:	c3                   	ret    

f0102832 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102832:	55                   	push   %ebp
f0102833:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102835:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102839:	b8 70 00 00 00       	mov    $0x70,%eax
f010283e:	e8 e3 ff ff ff       	call   f0102826 <outb>
	return inb(IO_RTC+1);
f0102843:	b8 71 00 00 00       	mov    $0x71,%eax
f0102848:	e8 d1 ff ff ff       	call   f010281e <inb>
f010284d:	0f b6 c0             	movzbl %al,%eax
}
f0102850:	5d                   	pop    %ebp
f0102851:	c3                   	ret    

f0102852 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102852:	55                   	push   %ebp
f0102853:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102855:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102859:	b8 70 00 00 00       	mov    $0x70,%eax
f010285e:	e8 c3 ff ff ff       	call   f0102826 <outb>
	outb(IO_RTC+1, datum);
f0102863:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0102867:	b8 71 00 00 00       	mov    $0x71,%eax
f010286c:	e8 b5 ff ff ff       	call   f0102826 <outb>
}
f0102871:	5d                   	pop    %ebp
f0102872:	c3                   	ret    

f0102873 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102873:	55                   	push   %ebp
f0102874:	89 e5                	mov    %esp,%ebp
f0102876:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102879:	ff 75 08             	pushl  0x8(%ebp)
f010287c:	e8 84 de ff ff       	call   f0100705 <cputchar>
	*cnt++;
}
f0102881:	83 c4 10             	add    $0x10,%esp
f0102884:	c9                   	leave  
f0102885:	c3                   	ret    

f0102886 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102886:	55                   	push   %ebp
f0102887:	89 e5                	mov    %esp,%ebp
f0102889:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010288c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102893:	ff 75 0c             	pushl  0xc(%ebp)
f0102896:	ff 75 08             	pushl  0x8(%ebp)
f0102899:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010289c:	50                   	push   %eax
f010289d:	68 73 28 10 f0       	push   $0xf0102873
f01028a2:	e8 82 04 00 00       	call   f0102d29 <vprintfmt>
	return cnt;
}
f01028a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01028aa:	c9                   	leave  
f01028ab:	c3                   	ret    

f01028ac <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01028ac:	55                   	push   %ebp
f01028ad:	89 e5                	mov    %esp,%ebp
f01028af:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01028b2:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01028b5:	50                   	push   %eax
f01028b6:	ff 75 08             	pushl  0x8(%ebp)
f01028b9:	e8 c8 ff ff ff       	call   f0102886 <vcprintf>
	va_end(ap);

	return cnt;
}
f01028be:	c9                   	leave  
f01028bf:	c3                   	ret    

f01028c0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01028c0:	55                   	push   %ebp
f01028c1:	89 e5                	mov    %esp,%ebp
f01028c3:	57                   	push   %edi
f01028c4:	56                   	push   %esi
f01028c5:	53                   	push   %ebx
f01028c6:	83 ec 14             	sub    $0x14,%esp
f01028c9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01028cc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01028cf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01028d2:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01028d5:	8b 1a                	mov    (%edx),%ebx
f01028d7:	8b 01                	mov    (%ecx),%eax
f01028d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01028dc:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01028e3:	eb 7f                	jmp    f0102964 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01028e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01028e8:	01 d8                	add    %ebx,%eax
f01028ea:	89 c6                	mov    %eax,%esi
f01028ec:	c1 ee 1f             	shr    $0x1f,%esi
f01028ef:	01 c6                	add    %eax,%esi
f01028f1:	d1 fe                	sar    %esi
f01028f3:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01028f6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01028f9:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01028fc:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01028fe:	eb 03                	jmp    f0102903 <stab_binsearch+0x43>
			m--;
f0102900:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102903:	39 c3                	cmp    %eax,%ebx
f0102905:	7f 0d                	jg     f0102914 <stab_binsearch+0x54>
f0102907:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010290b:	83 ea 0c             	sub    $0xc,%edx
f010290e:	39 f9                	cmp    %edi,%ecx
f0102910:	75 ee                	jne    f0102900 <stab_binsearch+0x40>
f0102912:	eb 05                	jmp    f0102919 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102914:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0102917:	eb 4b                	jmp    f0102964 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102919:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010291c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010291f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102923:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102926:	76 11                	jbe    f0102939 <stab_binsearch+0x79>
			*region_left = m;
f0102928:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010292b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010292d:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102930:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102937:	eb 2b                	jmp    f0102964 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102939:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010293c:	73 14                	jae    f0102952 <stab_binsearch+0x92>
			*region_right = m - 1;
f010293e:	83 e8 01             	sub    $0x1,%eax
f0102941:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102944:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102947:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102949:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102950:	eb 12                	jmp    f0102964 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102952:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102955:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102957:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010295b:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010295d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102964:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102967:	0f 8e 78 ff ff ff    	jle    f01028e5 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010296d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102971:	75 0f                	jne    f0102982 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0102973:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102976:	8b 00                	mov    (%eax),%eax
f0102978:	83 e8 01             	sub    $0x1,%eax
f010297b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010297e:	89 06                	mov    %eax,(%esi)
f0102980:	eb 2c                	jmp    f01029ae <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102982:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102985:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102987:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010298a:	8b 0e                	mov    (%esi),%ecx
f010298c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010298f:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102992:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102995:	eb 03                	jmp    f010299a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102997:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010299a:	39 c8                	cmp    %ecx,%eax
f010299c:	7e 0b                	jle    f01029a9 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010299e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01029a2:	83 ea 0c             	sub    $0xc,%edx
f01029a5:	39 df                	cmp    %ebx,%edi
f01029a7:	75 ee                	jne    f0102997 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01029a9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029ac:	89 06                	mov    %eax,(%esi)
	}
}
f01029ae:	83 c4 14             	add    $0x14,%esp
f01029b1:	5b                   	pop    %ebx
f01029b2:	5e                   	pop    %esi
f01029b3:	5f                   	pop    %edi
f01029b4:	5d                   	pop    %ebp
f01029b5:	c3                   	ret    

f01029b6 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01029b6:	55                   	push   %ebp
f01029b7:	89 e5                	mov    %esp,%ebp
f01029b9:	57                   	push   %edi
f01029ba:	56                   	push   %esi
f01029bb:	53                   	push   %ebx
f01029bc:	83 ec 3c             	sub    $0x3c,%esp
f01029bf:	8b 75 08             	mov    0x8(%ebp),%esi
f01029c2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01029c5:	c7 03 3c 4b 10 f0    	movl   $0xf0104b3c,(%ebx)
	info->eip_line = 0;
f01029cb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01029d2:	c7 43 08 3c 4b 10 f0 	movl   $0xf0104b3c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01029d9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01029e0:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01029e3:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01029ea:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01029f0:	76 11                	jbe    f0102a03 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01029f2:	b8 72 cb 10 f0       	mov    $0xf010cb72,%eax
f01029f7:	3d 85 ab 10 f0       	cmp    $0xf010ab85,%eax
f01029fc:	77 19                	ja     f0102a17 <debuginfo_eip+0x61>
f01029fe:	e9 af 01 00 00       	jmp    f0102bb2 <debuginfo_eip+0x1fc>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102a03:	83 ec 04             	sub    $0x4,%esp
f0102a06:	68 46 4b 10 f0       	push   $0xf0104b46
f0102a0b:	6a 7f                	push   $0x7f
f0102a0d:	68 53 4b 10 f0       	push   $0xf0104b53
f0102a12:	e8 74 d6 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102a17:	80 3d 71 cb 10 f0 00 	cmpb   $0x0,0xf010cb71
f0102a1e:	0f 85 95 01 00 00    	jne    f0102bb9 <debuginfo_eip+0x203>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102a24:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102a2b:	b8 84 ab 10 f0       	mov    $0xf010ab84,%eax
f0102a30:	2d 70 4d 10 f0       	sub    $0xf0104d70,%eax
f0102a35:	c1 f8 02             	sar    $0x2,%eax
f0102a38:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102a3e:	83 e8 01             	sub    $0x1,%eax
f0102a41:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102a44:	83 ec 08             	sub    $0x8,%esp
f0102a47:	56                   	push   %esi
f0102a48:	6a 64                	push   $0x64
f0102a4a:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102a4d:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102a50:	b8 70 4d 10 f0       	mov    $0xf0104d70,%eax
f0102a55:	e8 66 fe ff ff       	call   f01028c0 <stab_binsearch>
	if (lfile == 0)
f0102a5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a5d:	83 c4 10             	add    $0x10,%esp
f0102a60:	85 c0                	test   %eax,%eax
f0102a62:	0f 84 58 01 00 00    	je     f0102bc0 <debuginfo_eip+0x20a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102a68:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102a6b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a6e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102a71:	83 ec 08             	sub    $0x8,%esp
f0102a74:	56                   	push   %esi
f0102a75:	6a 24                	push   $0x24
f0102a77:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102a7a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102a7d:	b8 70 4d 10 f0       	mov    $0xf0104d70,%eax
f0102a82:	e8 39 fe ff ff       	call   f01028c0 <stab_binsearch>

	if (lfun <= rfun) {
f0102a87:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102a8a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102a8d:	83 c4 10             	add    $0x10,%esp
f0102a90:	39 d0                	cmp    %edx,%eax
f0102a92:	7f 40                	jg     f0102ad4 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102a94:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102a97:	c1 e1 02             	shl    $0x2,%ecx
f0102a9a:	8d b9 70 4d 10 f0    	lea    -0xfefb290(%ecx),%edi
f0102aa0:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102aa3:	8b b9 70 4d 10 f0    	mov    -0xfefb290(%ecx),%edi
f0102aa9:	b9 72 cb 10 f0       	mov    $0xf010cb72,%ecx
f0102aae:	81 e9 85 ab 10 f0    	sub    $0xf010ab85,%ecx
f0102ab4:	39 cf                	cmp    %ecx,%edi
f0102ab6:	73 09                	jae    f0102ac1 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102ab8:	81 c7 85 ab 10 f0    	add    $0xf010ab85,%edi
f0102abe:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102ac1:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102ac4:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102ac7:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102aca:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102acc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102acf:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102ad2:	eb 0f                	jmp    f0102ae3 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102ad4:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102ad7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ada:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102add:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ae0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102ae3:	83 ec 08             	sub    $0x8,%esp
f0102ae6:	6a 3a                	push   $0x3a
f0102ae8:	ff 73 08             	pushl  0x8(%ebx)
f0102aeb:	e8 44 08 00 00       	call   f0103334 <strfind>
f0102af0:	2b 43 08             	sub    0x8(%ebx),%eax
f0102af3:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102af6:	83 c4 08             	add    $0x8,%esp
f0102af9:	56                   	push   %esi
f0102afa:	6a 44                	push   $0x44
f0102afc:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102aff:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102b02:	b8 70 4d 10 f0       	mov    $0xf0104d70,%eax
f0102b07:	e8 b4 fd ff ff       	call   f01028c0 <stab_binsearch>
	if (lline <= rline) {
f0102b0c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b0f:	83 c4 10             	add    $0x10,%esp
f0102b12:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0102b15:	7f 0e                	jg     f0102b25 <debuginfo_eip+0x16f>
		info->eip_line = stabs[lline].n_desc;
f0102b17:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102b1a:	0f b7 14 95 76 4d 10 	movzwl -0xfefb28a(,%edx,4),%edx
f0102b21:	f0 
f0102b22:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102b25:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b28:	89 c2                	mov    %eax,%edx
f0102b2a:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102b2d:	8d 04 85 70 4d 10 f0 	lea    -0xfefb290(,%eax,4),%eax
f0102b34:	eb 06                	jmp    f0102b3c <debuginfo_eip+0x186>
f0102b36:	83 ea 01             	sub    $0x1,%edx
f0102b39:	83 e8 0c             	sub    $0xc,%eax
f0102b3c:	39 d7                	cmp    %edx,%edi
f0102b3e:	7f 34                	jg     f0102b74 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0102b40:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102b44:	80 f9 84             	cmp    $0x84,%cl
f0102b47:	74 0b                	je     f0102b54 <debuginfo_eip+0x19e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102b49:	80 f9 64             	cmp    $0x64,%cl
f0102b4c:	75 e8                	jne    f0102b36 <debuginfo_eip+0x180>
f0102b4e:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102b52:	74 e2                	je     f0102b36 <debuginfo_eip+0x180>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102b54:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102b57:	8b 14 85 70 4d 10 f0 	mov    -0xfefb290(,%eax,4),%edx
f0102b5e:	b8 72 cb 10 f0       	mov    $0xf010cb72,%eax
f0102b63:	2d 85 ab 10 f0       	sub    $0xf010ab85,%eax
f0102b68:	39 c2                	cmp    %eax,%edx
f0102b6a:	73 08                	jae    f0102b74 <debuginfo_eip+0x1be>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102b6c:	81 c2 85 ab 10 f0    	add    $0xf010ab85,%edx
f0102b72:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102b74:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b77:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b7a:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102b7f:	39 f2                	cmp    %esi,%edx
f0102b81:	7d 49                	jge    f0102bcc <debuginfo_eip+0x216>
		for (lline = lfun + 1;
f0102b83:	83 c2 01             	add    $0x1,%edx
f0102b86:	89 d0                	mov    %edx,%eax
f0102b88:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102b8b:	8d 14 95 70 4d 10 f0 	lea    -0xfefb290(,%edx,4),%edx
f0102b92:	eb 04                	jmp    f0102b98 <debuginfo_eip+0x1e2>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102b94:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102b98:	39 c6                	cmp    %eax,%esi
f0102b9a:	7e 2b                	jle    f0102bc7 <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102b9c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102ba0:	83 c0 01             	add    $0x1,%eax
f0102ba3:	83 c2 0c             	add    $0xc,%edx
f0102ba6:	80 f9 a0             	cmp    $0xa0,%cl
f0102ba9:	74 e9                	je     f0102b94 <debuginfo_eip+0x1de>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102bab:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb0:	eb 1a                	jmp    f0102bcc <debuginfo_eip+0x216>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102bb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102bb7:	eb 13                	jmp    f0102bcc <debuginfo_eip+0x216>
f0102bb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102bbe:	eb 0c                	jmp    f0102bcc <debuginfo_eip+0x216>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102bc0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102bc5:	eb 05                	jmp    f0102bcc <debuginfo_eip+0x216>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102bc7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102bcc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bcf:	5b                   	pop    %ebx
f0102bd0:	5e                   	pop    %esi
f0102bd1:	5f                   	pop    %edi
f0102bd2:	5d                   	pop    %ebp
f0102bd3:	c3                   	ret    

f0102bd4 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102bd4:	55                   	push   %ebp
f0102bd5:	89 e5                	mov    %esp,%ebp
f0102bd7:	57                   	push   %edi
f0102bd8:	56                   	push   %esi
f0102bd9:	53                   	push   %ebx
f0102bda:	83 ec 1c             	sub    $0x1c,%esp
f0102bdd:	89 c7                	mov    %eax,%edi
f0102bdf:	89 d6                	mov    %edx,%esi
f0102be1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102be4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102be7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102bea:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102bed:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102bf0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102bf5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102bf8:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102bfb:	39 d3                	cmp    %edx,%ebx
f0102bfd:	72 05                	jb     f0102c04 <printnum+0x30>
f0102bff:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102c02:	77 45                	ja     f0102c49 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102c04:	83 ec 0c             	sub    $0xc,%esp
f0102c07:	ff 75 18             	pushl  0x18(%ebp)
f0102c0a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c0d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102c10:	53                   	push   %ebx
f0102c11:	ff 75 10             	pushl  0x10(%ebp)
f0102c14:	83 ec 08             	sub    $0x8,%esp
f0102c17:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c1a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c1d:	ff 75 dc             	pushl  -0x24(%ebp)
f0102c20:	ff 75 d8             	pushl  -0x28(%ebp)
f0102c23:	e8 38 09 00 00       	call   f0103560 <__udivdi3>
f0102c28:	83 c4 18             	add    $0x18,%esp
f0102c2b:	52                   	push   %edx
f0102c2c:	50                   	push   %eax
f0102c2d:	89 f2                	mov    %esi,%edx
f0102c2f:	89 f8                	mov    %edi,%eax
f0102c31:	e8 9e ff ff ff       	call   f0102bd4 <printnum>
f0102c36:	83 c4 20             	add    $0x20,%esp
f0102c39:	eb 18                	jmp    f0102c53 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102c3b:	83 ec 08             	sub    $0x8,%esp
f0102c3e:	56                   	push   %esi
f0102c3f:	ff 75 18             	pushl  0x18(%ebp)
f0102c42:	ff d7                	call   *%edi
f0102c44:	83 c4 10             	add    $0x10,%esp
f0102c47:	eb 03                	jmp    f0102c4c <printnum+0x78>
f0102c49:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102c4c:	83 eb 01             	sub    $0x1,%ebx
f0102c4f:	85 db                	test   %ebx,%ebx
f0102c51:	7f e8                	jg     f0102c3b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102c53:	83 ec 08             	sub    $0x8,%esp
f0102c56:	56                   	push   %esi
f0102c57:	83 ec 04             	sub    $0x4,%esp
f0102c5a:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c5d:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c60:	ff 75 dc             	pushl  -0x24(%ebp)
f0102c63:	ff 75 d8             	pushl  -0x28(%ebp)
f0102c66:	e8 25 0a 00 00       	call   f0103690 <__umoddi3>
f0102c6b:	83 c4 14             	add    $0x14,%esp
f0102c6e:	0f be 80 61 4b 10 f0 	movsbl -0xfefb49f(%eax),%eax
f0102c75:	50                   	push   %eax
f0102c76:	ff d7                	call   *%edi
}
f0102c78:	83 c4 10             	add    $0x10,%esp
f0102c7b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c7e:	5b                   	pop    %ebx
f0102c7f:	5e                   	pop    %esi
f0102c80:	5f                   	pop    %edi
f0102c81:	5d                   	pop    %ebp
f0102c82:	c3                   	ret    

f0102c83 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102c83:	55                   	push   %ebp
f0102c84:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102c86:	83 fa 01             	cmp    $0x1,%edx
f0102c89:	7e 0e                	jle    f0102c99 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102c8b:	8b 10                	mov    (%eax),%edx
f0102c8d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102c90:	89 08                	mov    %ecx,(%eax)
f0102c92:	8b 02                	mov    (%edx),%eax
f0102c94:	8b 52 04             	mov    0x4(%edx),%edx
f0102c97:	eb 22                	jmp    f0102cbb <getuint+0x38>
	else if (lflag)
f0102c99:	85 d2                	test   %edx,%edx
f0102c9b:	74 10                	je     f0102cad <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102c9d:	8b 10                	mov    (%eax),%edx
f0102c9f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102ca2:	89 08                	mov    %ecx,(%eax)
f0102ca4:	8b 02                	mov    (%edx),%eax
f0102ca6:	ba 00 00 00 00       	mov    $0x0,%edx
f0102cab:	eb 0e                	jmp    f0102cbb <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102cad:	8b 10                	mov    (%eax),%edx
f0102caf:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102cb2:	89 08                	mov    %ecx,(%eax)
f0102cb4:	8b 02                	mov    (%edx),%eax
f0102cb6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102cbb:	5d                   	pop    %ebp
f0102cbc:	c3                   	ret    

f0102cbd <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0102cbd:	55                   	push   %ebp
f0102cbe:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102cc0:	83 fa 01             	cmp    $0x1,%edx
f0102cc3:	7e 0e                	jle    f0102cd3 <getint+0x16>
		return va_arg(*ap, long long);
f0102cc5:	8b 10                	mov    (%eax),%edx
f0102cc7:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102cca:	89 08                	mov    %ecx,(%eax)
f0102ccc:	8b 02                	mov    (%edx),%eax
f0102cce:	8b 52 04             	mov    0x4(%edx),%edx
f0102cd1:	eb 1a                	jmp    f0102ced <getint+0x30>
	else if (lflag)
f0102cd3:	85 d2                	test   %edx,%edx
f0102cd5:	74 0c                	je     f0102ce3 <getint+0x26>
		return va_arg(*ap, long);
f0102cd7:	8b 10                	mov    (%eax),%edx
f0102cd9:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102cdc:	89 08                	mov    %ecx,(%eax)
f0102cde:	8b 02                	mov    (%edx),%eax
f0102ce0:	99                   	cltd   
f0102ce1:	eb 0a                	jmp    f0102ced <getint+0x30>
	else
		return va_arg(*ap, int);
f0102ce3:	8b 10                	mov    (%eax),%edx
f0102ce5:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102ce8:	89 08                	mov    %ecx,(%eax)
f0102cea:	8b 02                	mov    (%edx),%eax
f0102cec:	99                   	cltd   
}
f0102ced:	5d                   	pop    %ebp
f0102cee:	c3                   	ret    

f0102cef <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102cef:	55                   	push   %ebp
f0102cf0:	89 e5                	mov    %esp,%ebp
f0102cf2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102cf5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102cf9:	8b 10                	mov    (%eax),%edx
f0102cfb:	3b 50 04             	cmp    0x4(%eax),%edx
f0102cfe:	73 0a                	jae    f0102d0a <sprintputch+0x1b>
		*b->buf++ = ch;
f0102d00:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102d03:	89 08                	mov    %ecx,(%eax)
f0102d05:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d08:	88 02                	mov    %al,(%edx)
}
f0102d0a:	5d                   	pop    %ebp
f0102d0b:	c3                   	ret    

f0102d0c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102d0c:	55                   	push   %ebp
f0102d0d:	89 e5                	mov    %esp,%ebp
f0102d0f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102d12:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102d15:	50                   	push   %eax
f0102d16:	ff 75 10             	pushl  0x10(%ebp)
f0102d19:	ff 75 0c             	pushl  0xc(%ebp)
f0102d1c:	ff 75 08             	pushl  0x8(%ebp)
f0102d1f:	e8 05 00 00 00       	call   f0102d29 <vprintfmt>
	va_end(ap);
}
f0102d24:	83 c4 10             	add    $0x10,%esp
f0102d27:	c9                   	leave  
f0102d28:	c3                   	ret    

f0102d29 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102d29:	55                   	push   %ebp
f0102d2a:	89 e5                	mov    %esp,%ebp
f0102d2c:	57                   	push   %edi
f0102d2d:	56                   	push   %esi
f0102d2e:	53                   	push   %ebx
f0102d2f:	83 ec 2c             	sub    $0x2c,%esp
f0102d32:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d35:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d38:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102d3b:	eb 12                	jmp    f0102d4f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102d3d:	85 c0                	test   %eax,%eax
f0102d3f:	0f 84 44 03 00 00    	je     f0103089 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f0102d45:	83 ec 08             	sub    $0x8,%esp
f0102d48:	53                   	push   %ebx
f0102d49:	50                   	push   %eax
f0102d4a:	ff d6                	call   *%esi
f0102d4c:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102d4f:	83 c7 01             	add    $0x1,%edi
f0102d52:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d56:	83 f8 25             	cmp    $0x25,%eax
f0102d59:	75 e2                	jne    f0102d3d <vprintfmt+0x14>
f0102d5b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102d5f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102d66:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102d6d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102d74:	ba 00 00 00 00       	mov    $0x0,%edx
f0102d79:	eb 07                	jmp    f0102d82 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d7b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102d7e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d82:	8d 47 01             	lea    0x1(%edi),%eax
f0102d85:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102d88:	0f b6 07             	movzbl (%edi),%eax
f0102d8b:	0f b6 c8             	movzbl %al,%ecx
f0102d8e:	83 e8 23             	sub    $0x23,%eax
f0102d91:	3c 55                	cmp    $0x55,%al
f0102d93:	0f 87 d5 02 00 00    	ja     f010306e <vprintfmt+0x345>
f0102d99:	0f b6 c0             	movzbl %al,%eax
f0102d9c:	ff 24 85 ec 4b 10 f0 	jmp    *-0xfefb414(,%eax,4)
f0102da3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102da6:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102daa:	eb d6                	jmp    f0102d82 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102daf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102db4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102db7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102dba:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102dbe:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102dc1:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102dc4:	83 fa 09             	cmp    $0x9,%edx
f0102dc7:	77 39                	ja     f0102e02 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102dc9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102dcc:	eb e9                	jmp    f0102db7 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102dce:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dd1:	8d 48 04             	lea    0x4(%eax),%ecx
f0102dd4:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102dd7:	8b 00                	mov    (%eax),%eax
f0102dd9:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ddc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102ddf:	eb 27                	jmp    f0102e08 <vprintfmt+0xdf>
f0102de1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102de4:	85 c0                	test   %eax,%eax
f0102de6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102deb:	0f 49 c8             	cmovns %eax,%ecx
f0102dee:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102df1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102df4:	eb 8c                	jmp    f0102d82 <vprintfmt+0x59>
f0102df6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102df9:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102e00:	eb 80                	jmp    f0102d82 <vprintfmt+0x59>
f0102e02:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102e05:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102e08:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102e0c:	0f 89 70 ff ff ff    	jns    f0102d82 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102e12:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102e15:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102e18:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102e1f:	e9 5e ff ff ff       	jmp    f0102d82 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102e24:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e27:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102e2a:	e9 53 ff ff ff       	jmp    f0102d82 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102e2f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e32:	8d 50 04             	lea    0x4(%eax),%edx
f0102e35:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e38:	83 ec 08             	sub    $0x8,%esp
f0102e3b:	53                   	push   %ebx
f0102e3c:	ff 30                	pushl  (%eax)
f0102e3e:	ff d6                	call   *%esi
			break;
f0102e40:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e43:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102e46:	e9 04 ff ff ff       	jmp    f0102d4f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102e4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e4e:	8d 50 04             	lea    0x4(%eax),%edx
f0102e51:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e54:	8b 00                	mov    (%eax),%eax
f0102e56:	99                   	cltd   
f0102e57:	31 d0                	xor    %edx,%eax
f0102e59:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102e5b:	83 f8 06             	cmp    $0x6,%eax
f0102e5e:	7f 0b                	jg     f0102e6b <vprintfmt+0x142>
f0102e60:	8b 14 85 44 4d 10 f0 	mov    -0xfefb2bc(,%eax,4),%edx
f0102e67:	85 d2                	test   %edx,%edx
f0102e69:	75 18                	jne    f0102e83 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102e6b:	50                   	push   %eax
f0102e6c:	68 79 4b 10 f0       	push   $0xf0104b79
f0102e71:	53                   	push   %ebx
f0102e72:	56                   	push   %esi
f0102e73:	e8 94 fe ff ff       	call   f0102d0c <printfmt>
f0102e78:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e7b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102e7e:	e9 cc fe ff ff       	jmp    f0102d4f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102e83:	52                   	push   %edx
f0102e84:	68 3a 47 10 f0       	push   $0xf010473a
f0102e89:	53                   	push   %ebx
f0102e8a:	56                   	push   %esi
f0102e8b:	e8 7c fe ff ff       	call   f0102d0c <printfmt>
f0102e90:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e93:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e96:	e9 b4 fe ff ff       	jmp    f0102d4f <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102e9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e9e:	8d 50 04             	lea    0x4(%eax),%edx
f0102ea1:	89 55 14             	mov    %edx,0x14(%ebp)
f0102ea4:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102ea6:	85 ff                	test   %edi,%edi
f0102ea8:	b8 72 4b 10 f0       	mov    $0xf0104b72,%eax
f0102ead:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102eb0:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102eb4:	0f 8e 94 00 00 00    	jle    f0102f4e <vprintfmt+0x225>
f0102eba:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102ebe:	0f 84 98 00 00 00    	je     f0102f5c <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ec4:	83 ec 08             	sub    $0x8,%esp
f0102ec7:	ff 75 d0             	pushl  -0x30(%ebp)
f0102eca:	57                   	push   %edi
f0102ecb:	e8 1a 03 00 00       	call   f01031ea <strnlen>
f0102ed0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102ed3:	29 c1                	sub    %eax,%ecx
f0102ed5:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102ed8:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102edb:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102edf:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ee2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102ee5:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ee7:	eb 0f                	jmp    f0102ef8 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102ee9:	83 ec 08             	sub    $0x8,%esp
f0102eec:	53                   	push   %ebx
f0102eed:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ef0:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ef2:	83 ef 01             	sub    $0x1,%edi
f0102ef5:	83 c4 10             	add    $0x10,%esp
f0102ef8:	85 ff                	test   %edi,%edi
f0102efa:	7f ed                	jg     f0102ee9 <vprintfmt+0x1c0>
f0102efc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102eff:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102f02:	85 c9                	test   %ecx,%ecx
f0102f04:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f09:	0f 49 c1             	cmovns %ecx,%eax
f0102f0c:	29 c1                	sub    %eax,%ecx
f0102f0e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102f11:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102f14:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102f17:	89 cb                	mov    %ecx,%ebx
f0102f19:	eb 4d                	jmp    f0102f68 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102f1b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102f1f:	74 1b                	je     f0102f3c <vprintfmt+0x213>
f0102f21:	0f be c0             	movsbl %al,%eax
f0102f24:	83 e8 20             	sub    $0x20,%eax
f0102f27:	83 f8 5e             	cmp    $0x5e,%eax
f0102f2a:	76 10                	jbe    f0102f3c <vprintfmt+0x213>
					putch('?', putdat);
f0102f2c:	83 ec 08             	sub    $0x8,%esp
f0102f2f:	ff 75 0c             	pushl  0xc(%ebp)
f0102f32:	6a 3f                	push   $0x3f
f0102f34:	ff 55 08             	call   *0x8(%ebp)
f0102f37:	83 c4 10             	add    $0x10,%esp
f0102f3a:	eb 0d                	jmp    f0102f49 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102f3c:	83 ec 08             	sub    $0x8,%esp
f0102f3f:	ff 75 0c             	pushl  0xc(%ebp)
f0102f42:	52                   	push   %edx
f0102f43:	ff 55 08             	call   *0x8(%ebp)
f0102f46:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102f49:	83 eb 01             	sub    $0x1,%ebx
f0102f4c:	eb 1a                	jmp    f0102f68 <vprintfmt+0x23f>
f0102f4e:	89 75 08             	mov    %esi,0x8(%ebp)
f0102f51:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102f54:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102f57:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102f5a:	eb 0c                	jmp    f0102f68 <vprintfmt+0x23f>
f0102f5c:	89 75 08             	mov    %esi,0x8(%ebp)
f0102f5f:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102f62:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102f65:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102f68:	83 c7 01             	add    $0x1,%edi
f0102f6b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102f6f:	0f be d0             	movsbl %al,%edx
f0102f72:	85 d2                	test   %edx,%edx
f0102f74:	74 23                	je     f0102f99 <vprintfmt+0x270>
f0102f76:	85 f6                	test   %esi,%esi
f0102f78:	78 a1                	js     f0102f1b <vprintfmt+0x1f2>
f0102f7a:	83 ee 01             	sub    $0x1,%esi
f0102f7d:	79 9c                	jns    f0102f1b <vprintfmt+0x1f2>
f0102f7f:	89 df                	mov    %ebx,%edi
f0102f81:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f84:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102f87:	eb 18                	jmp    f0102fa1 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102f89:	83 ec 08             	sub    $0x8,%esp
f0102f8c:	53                   	push   %ebx
f0102f8d:	6a 20                	push   $0x20
f0102f8f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102f91:	83 ef 01             	sub    $0x1,%edi
f0102f94:	83 c4 10             	add    $0x10,%esp
f0102f97:	eb 08                	jmp    f0102fa1 <vprintfmt+0x278>
f0102f99:	89 df                	mov    %ebx,%edi
f0102f9b:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f9e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102fa1:	85 ff                	test   %edi,%edi
f0102fa3:	7f e4                	jg     f0102f89 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102fa5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102fa8:	e9 a2 fd ff ff       	jmp    f0102d4f <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102fad:	8d 45 14             	lea    0x14(%ebp),%eax
f0102fb0:	e8 08 fd ff ff       	call   f0102cbd <getint>
f0102fb5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102fb8:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102fbb:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102fc0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102fc4:	79 74                	jns    f010303a <vprintfmt+0x311>
				putch('-', putdat);
f0102fc6:	83 ec 08             	sub    $0x8,%esp
f0102fc9:	53                   	push   %ebx
f0102fca:	6a 2d                	push   $0x2d
f0102fcc:	ff d6                	call   *%esi
				num = -(long long) num;
f0102fce:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102fd1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102fd4:	f7 d8                	neg    %eax
f0102fd6:	83 d2 00             	adc    $0x0,%edx
f0102fd9:	f7 da                	neg    %edx
f0102fdb:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102fde:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102fe3:	eb 55                	jmp    f010303a <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102fe5:	8d 45 14             	lea    0x14(%ebp),%eax
f0102fe8:	e8 96 fc ff ff       	call   f0102c83 <getuint>
			base = 10;
f0102fed:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102ff2:	eb 46                	jmp    f010303a <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0102ff4:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ff7:	e8 87 fc ff ff       	call   f0102c83 <getuint>
			base = 8;
f0102ffc:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103001:	eb 37                	jmp    f010303a <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0103003:	83 ec 08             	sub    $0x8,%esp
f0103006:	53                   	push   %ebx
f0103007:	6a 30                	push   $0x30
f0103009:	ff d6                	call   *%esi
			putch('x', putdat);
f010300b:	83 c4 08             	add    $0x8,%esp
f010300e:	53                   	push   %ebx
f010300f:	6a 78                	push   $0x78
f0103011:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103013:	8b 45 14             	mov    0x14(%ebp),%eax
f0103016:	8d 50 04             	lea    0x4(%eax),%edx
f0103019:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010301c:	8b 00                	mov    (%eax),%eax
f010301e:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103023:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103026:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010302b:	eb 0d                	jmp    f010303a <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010302d:	8d 45 14             	lea    0x14(%ebp),%eax
f0103030:	e8 4e fc ff ff       	call   f0102c83 <getuint>
			base = 16;
f0103035:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010303a:	83 ec 0c             	sub    $0xc,%esp
f010303d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103041:	57                   	push   %edi
f0103042:	ff 75 e0             	pushl  -0x20(%ebp)
f0103045:	51                   	push   %ecx
f0103046:	52                   	push   %edx
f0103047:	50                   	push   %eax
f0103048:	89 da                	mov    %ebx,%edx
f010304a:	89 f0                	mov    %esi,%eax
f010304c:	e8 83 fb ff ff       	call   f0102bd4 <printnum>
			break;
f0103051:	83 c4 20             	add    $0x20,%esp
f0103054:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103057:	e9 f3 fc ff ff       	jmp    f0102d4f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010305c:	83 ec 08             	sub    $0x8,%esp
f010305f:	53                   	push   %ebx
f0103060:	51                   	push   %ecx
f0103061:	ff d6                	call   *%esi
			break;
f0103063:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103066:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103069:	e9 e1 fc ff ff       	jmp    f0102d4f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010306e:	83 ec 08             	sub    $0x8,%esp
f0103071:	53                   	push   %ebx
f0103072:	6a 25                	push   $0x25
f0103074:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103076:	83 c4 10             	add    $0x10,%esp
f0103079:	eb 03                	jmp    f010307e <vprintfmt+0x355>
f010307b:	83 ef 01             	sub    $0x1,%edi
f010307e:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103082:	75 f7                	jne    f010307b <vprintfmt+0x352>
f0103084:	e9 c6 fc ff ff       	jmp    f0102d4f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103089:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010308c:	5b                   	pop    %ebx
f010308d:	5e                   	pop    %esi
f010308e:	5f                   	pop    %edi
f010308f:	5d                   	pop    %ebp
f0103090:	c3                   	ret    

f0103091 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103091:	55                   	push   %ebp
f0103092:	89 e5                	mov    %esp,%ebp
f0103094:	83 ec 18             	sub    $0x18,%esp
f0103097:	8b 45 08             	mov    0x8(%ebp),%eax
f010309a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010309d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01030a0:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01030a4:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01030a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01030ae:	85 c0                	test   %eax,%eax
f01030b0:	74 26                	je     f01030d8 <vsnprintf+0x47>
f01030b2:	85 d2                	test   %edx,%edx
f01030b4:	7e 22                	jle    f01030d8 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01030b6:	ff 75 14             	pushl  0x14(%ebp)
f01030b9:	ff 75 10             	pushl  0x10(%ebp)
f01030bc:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01030bf:	50                   	push   %eax
f01030c0:	68 ef 2c 10 f0       	push   $0xf0102cef
f01030c5:	e8 5f fc ff ff       	call   f0102d29 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01030ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01030cd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01030d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01030d3:	83 c4 10             	add    $0x10,%esp
f01030d6:	eb 05                	jmp    f01030dd <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01030d8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01030dd:	c9                   	leave  
f01030de:	c3                   	ret    

f01030df <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01030df:	55                   	push   %ebp
f01030e0:	89 e5                	mov    %esp,%ebp
f01030e2:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01030e5:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01030e8:	50                   	push   %eax
f01030e9:	ff 75 10             	pushl  0x10(%ebp)
f01030ec:	ff 75 0c             	pushl  0xc(%ebp)
f01030ef:	ff 75 08             	pushl  0x8(%ebp)
f01030f2:	e8 9a ff ff ff       	call   f0103091 <vsnprintf>
	va_end(ap);

	return rc;
}
f01030f7:	c9                   	leave  
f01030f8:	c3                   	ret    

f01030f9 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01030f9:	55                   	push   %ebp
f01030fa:	89 e5                	mov    %esp,%ebp
f01030fc:	57                   	push   %edi
f01030fd:	56                   	push   %esi
f01030fe:	53                   	push   %ebx
f01030ff:	83 ec 0c             	sub    $0xc,%esp
f0103102:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103105:	85 c0                	test   %eax,%eax
f0103107:	74 11                	je     f010311a <readline+0x21>
		cprintf("%s", prompt);
f0103109:	83 ec 08             	sub    $0x8,%esp
f010310c:	50                   	push   %eax
f010310d:	68 3a 47 10 f0       	push   $0xf010473a
f0103112:	e8 95 f7 ff ff       	call   f01028ac <cprintf>
f0103117:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010311a:	83 ec 0c             	sub    $0xc,%esp
f010311d:	6a 00                	push   $0x0
f010311f:	e8 02 d6 ff ff       	call   f0100726 <iscons>
f0103124:	89 c7                	mov    %eax,%edi
f0103126:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103129:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010312e:	e8 e2 d5 ff ff       	call   f0100715 <getchar>
f0103133:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103135:	85 c0                	test   %eax,%eax
f0103137:	79 18                	jns    f0103151 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103139:	83 ec 08             	sub    $0x8,%esp
f010313c:	50                   	push   %eax
f010313d:	68 60 4d 10 f0       	push   $0xf0104d60
f0103142:	e8 65 f7 ff ff       	call   f01028ac <cprintf>
			return NULL;
f0103147:	83 c4 10             	add    $0x10,%esp
f010314a:	b8 00 00 00 00       	mov    $0x0,%eax
f010314f:	eb 79                	jmp    f01031ca <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103151:	83 f8 08             	cmp    $0x8,%eax
f0103154:	0f 94 c2             	sete   %dl
f0103157:	83 f8 7f             	cmp    $0x7f,%eax
f010315a:	0f 94 c0             	sete   %al
f010315d:	08 c2                	or     %al,%dl
f010315f:	74 1a                	je     f010317b <readline+0x82>
f0103161:	85 f6                	test   %esi,%esi
f0103163:	7e 16                	jle    f010317b <readline+0x82>
			if (echoing)
f0103165:	85 ff                	test   %edi,%edi
f0103167:	74 0d                	je     f0103176 <readline+0x7d>
				cputchar('\b');
f0103169:	83 ec 0c             	sub    $0xc,%esp
f010316c:	6a 08                	push   $0x8
f010316e:	e8 92 d5 ff ff       	call   f0100705 <cputchar>
f0103173:	83 c4 10             	add    $0x10,%esp
			i--;
f0103176:	83 ee 01             	sub    $0x1,%esi
f0103179:	eb b3                	jmp    f010312e <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010317b:	83 fb 1f             	cmp    $0x1f,%ebx
f010317e:	7e 23                	jle    f01031a3 <readline+0xaa>
f0103180:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103186:	7f 1b                	jg     f01031a3 <readline+0xaa>
			if (echoing)
f0103188:	85 ff                	test   %edi,%edi
f010318a:	74 0c                	je     f0103198 <readline+0x9f>
				cputchar(c);
f010318c:	83 ec 0c             	sub    $0xc,%esp
f010318f:	53                   	push   %ebx
f0103190:	e8 70 d5 ff ff       	call   f0100705 <cputchar>
f0103195:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103198:	88 9e 40 75 11 f0    	mov    %bl,-0xfee8ac0(%esi)
f010319e:	8d 76 01             	lea    0x1(%esi),%esi
f01031a1:	eb 8b                	jmp    f010312e <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01031a3:	83 fb 0a             	cmp    $0xa,%ebx
f01031a6:	74 05                	je     f01031ad <readline+0xb4>
f01031a8:	83 fb 0d             	cmp    $0xd,%ebx
f01031ab:	75 81                	jne    f010312e <readline+0x35>
			if (echoing)
f01031ad:	85 ff                	test   %edi,%edi
f01031af:	74 0d                	je     f01031be <readline+0xc5>
				cputchar('\n');
f01031b1:	83 ec 0c             	sub    $0xc,%esp
f01031b4:	6a 0a                	push   $0xa
f01031b6:	e8 4a d5 ff ff       	call   f0100705 <cputchar>
f01031bb:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01031be:	c6 86 40 75 11 f0 00 	movb   $0x0,-0xfee8ac0(%esi)
			return buf;
f01031c5:	b8 40 75 11 f0       	mov    $0xf0117540,%eax
		}
	}
}
f01031ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01031cd:	5b                   	pop    %ebx
f01031ce:	5e                   	pop    %esi
f01031cf:	5f                   	pop    %edi
f01031d0:	5d                   	pop    %ebp
f01031d1:	c3                   	ret    

f01031d2 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01031d2:	55                   	push   %ebp
f01031d3:	89 e5                	mov    %esp,%ebp
f01031d5:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01031d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01031dd:	eb 03                	jmp    f01031e2 <strlen+0x10>
		n++;
f01031df:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01031e2:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01031e6:	75 f7                	jne    f01031df <strlen+0xd>
		n++;
	return n;
}
f01031e8:	5d                   	pop    %ebp
f01031e9:	c3                   	ret    

f01031ea <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01031ea:	55                   	push   %ebp
f01031eb:	89 e5                	mov    %esp,%ebp
f01031ed:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01031f0:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01031f3:	ba 00 00 00 00       	mov    $0x0,%edx
f01031f8:	eb 03                	jmp    f01031fd <strnlen+0x13>
		n++;
f01031fa:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01031fd:	39 c2                	cmp    %eax,%edx
f01031ff:	74 08                	je     f0103209 <strnlen+0x1f>
f0103201:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103205:	75 f3                	jne    f01031fa <strnlen+0x10>
f0103207:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103209:	5d                   	pop    %ebp
f010320a:	c3                   	ret    

f010320b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010320b:	55                   	push   %ebp
f010320c:	89 e5                	mov    %esp,%ebp
f010320e:	53                   	push   %ebx
f010320f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103212:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103215:	89 c2                	mov    %eax,%edx
f0103217:	83 c2 01             	add    $0x1,%edx
f010321a:	83 c1 01             	add    $0x1,%ecx
f010321d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103221:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103224:	84 db                	test   %bl,%bl
f0103226:	75 ef                	jne    f0103217 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103228:	5b                   	pop    %ebx
f0103229:	5d                   	pop    %ebp
f010322a:	c3                   	ret    

f010322b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010322b:	55                   	push   %ebp
f010322c:	89 e5                	mov    %esp,%ebp
f010322e:	53                   	push   %ebx
f010322f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103232:	53                   	push   %ebx
f0103233:	e8 9a ff ff ff       	call   f01031d2 <strlen>
f0103238:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010323b:	ff 75 0c             	pushl  0xc(%ebp)
f010323e:	01 d8                	add    %ebx,%eax
f0103240:	50                   	push   %eax
f0103241:	e8 c5 ff ff ff       	call   f010320b <strcpy>
	return dst;
}
f0103246:	89 d8                	mov    %ebx,%eax
f0103248:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010324b:	c9                   	leave  
f010324c:	c3                   	ret    

f010324d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010324d:	55                   	push   %ebp
f010324e:	89 e5                	mov    %esp,%ebp
f0103250:	56                   	push   %esi
f0103251:	53                   	push   %ebx
f0103252:	8b 75 08             	mov    0x8(%ebp),%esi
f0103255:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103258:	89 f3                	mov    %esi,%ebx
f010325a:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010325d:	89 f2                	mov    %esi,%edx
f010325f:	eb 0f                	jmp    f0103270 <strncpy+0x23>
		*dst++ = *src;
f0103261:	83 c2 01             	add    $0x1,%edx
f0103264:	0f b6 01             	movzbl (%ecx),%eax
f0103267:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010326a:	80 39 01             	cmpb   $0x1,(%ecx)
f010326d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103270:	39 da                	cmp    %ebx,%edx
f0103272:	75 ed                	jne    f0103261 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103274:	89 f0                	mov    %esi,%eax
f0103276:	5b                   	pop    %ebx
f0103277:	5e                   	pop    %esi
f0103278:	5d                   	pop    %ebp
f0103279:	c3                   	ret    

f010327a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010327a:	55                   	push   %ebp
f010327b:	89 e5                	mov    %esp,%ebp
f010327d:	56                   	push   %esi
f010327e:	53                   	push   %ebx
f010327f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103282:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103285:	8b 55 10             	mov    0x10(%ebp),%edx
f0103288:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010328a:	85 d2                	test   %edx,%edx
f010328c:	74 21                	je     f01032af <strlcpy+0x35>
f010328e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103292:	89 f2                	mov    %esi,%edx
f0103294:	eb 09                	jmp    f010329f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103296:	83 c2 01             	add    $0x1,%edx
f0103299:	83 c1 01             	add    $0x1,%ecx
f010329c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010329f:	39 c2                	cmp    %eax,%edx
f01032a1:	74 09                	je     f01032ac <strlcpy+0x32>
f01032a3:	0f b6 19             	movzbl (%ecx),%ebx
f01032a6:	84 db                	test   %bl,%bl
f01032a8:	75 ec                	jne    f0103296 <strlcpy+0x1c>
f01032aa:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01032ac:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01032af:	29 f0                	sub    %esi,%eax
}
f01032b1:	5b                   	pop    %ebx
f01032b2:	5e                   	pop    %esi
f01032b3:	5d                   	pop    %ebp
f01032b4:	c3                   	ret    

f01032b5 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01032b5:	55                   	push   %ebp
f01032b6:	89 e5                	mov    %esp,%ebp
f01032b8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032bb:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01032be:	eb 06                	jmp    f01032c6 <strcmp+0x11>
		p++, q++;
f01032c0:	83 c1 01             	add    $0x1,%ecx
f01032c3:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01032c6:	0f b6 01             	movzbl (%ecx),%eax
f01032c9:	84 c0                	test   %al,%al
f01032cb:	74 04                	je     f01032d1 <strcmp+0x1c>
f01032cd:	3a 02                	cmp    (%edx),%al
f01032cf:	74 ef                	je     f01032c0 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01032d1:	0f b6 c0             	movzbl %al,%eax
f01032d4:	0f b6 12             	movzbl (%edx),%edx
f01032d7:	29 d0                	sub    %edx,%eax
}
f01032d9:	5d                   	pop    %ebp
f01032da:	c3                   	ret    

f01032db <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01032db:	55                   	push   %ebp
f01032dc:	89 e5                	mov    %esp,%ebp
f01032de:	53                   	push   %ebx
f01032df:	8b 45 08             	mov    0x8(%ebp),%eax
f01032e2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032e5:	89 c3                	mov    %eax,%ebx
f01032e7:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01032ea:	eb 06                	jmp    f01032f2 <strncmp+0x17>
		n--, p++, q++;
f01032ec:	83 c0 01             	add    $0x1,%eax
f01032ef:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01032f2:	39 d8                	cmp    %ebx,%eax
f01032f4:	74 15                	je     f010330b <strncmp+0x30>
f01032f6:	0f b6 08             	movzbl (%eax),%ecx
f01032f9:	84 c9                	test   %cl,%cl
f01032fb:	74 04                	je     f0103301 <strncmp+0x26>
f01032fd:	3a 0a                	cmp    (%edx),%cl
f01032ff:	74 eb                	je     f01032ec <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103301:	0f b6 00             	movzbl (%eax),%eax
f0103304:	0f b6 12             	movzbl (%edx),%edx
f0103307:	29 d0                	sub    %edx,%eax
f0103309:	eb 05                	jmp    f0103310 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010330b:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103310:	5b                   	pop    %ebx
f0103311:	5d                   	pop    %ebp
f0103312:	c3                   	ret    

f0103313 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103313:	55                   	push   %ebp
f0103314:	89 e5                	mov    %esp,%ebp
f0103316:	8b 45 08             	mov    0x8(%ebp),%eax
f0103319:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010331d:	eb 07                	jmp    f0103326 <strchr+0x13>
		if (*s == c)
f010331f:	38 ca                	cmp    %cl,%dl
f0103321:	74 0f                	je     f0103332 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103323:	83 c0 01             	add    $0x1,%eax
f0103326:	0f b6 10             	movzbl (%eax),%edx
f0103329:	84 d2                	test   %dl,%dl
f010332b:	75 f2                	jne    f010331f <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010332d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103332:	5d                   	pop    %ebp
f0103333:	c3                   	ret    

f0103334 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103334:	55                   	push   %ebp
f0103335:	89 e5                	mov    %esp,%ebp
f0103337:	8b 45 08             	mov    0x8(%ebp),%eax
f010333a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010333e:	eb 03                	jmp    f0103343 <strfind+0xf>
f0103340:	83 c0 01             	add    $0x1,%eax
f0103343:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103346:	38 ca                	cmp    %cl,%dl
f0103348:	74 04                	je     f010334e <strfind+0x1a>
f010334a:	84 d2                	test   %dl,%dl
f010334c:	75 f2                	jne    f0103340 <strfind+0xc>
			break;
	return (char *) s;
}
f010334e:	5d                   	pop    %ebp
f010334f:	c3                   	ret    

f0103350 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103350:	55                   	push   %ebp
f0103351:	89 e5                	mov    %esp,%ebp
f0103353:	57                   	push   %edi
f0103354:	56                   	push   %esi
f0103355:	53                   	push   %ebx
f0103356:	8b 55 08             	mov    0x8(%ebp),%edx
f0103359:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f010335c:	85 c9                	test   %ecx,%ecx
f010335e:	74 37                	je     f0103397 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103360:	f6 c2 03             	test   $0x3,%dl
f0103363:	75 2a                	jne    f010338f <memset+0x3f>
f0103365:	f6 c1 03             	test   $0x3,%cl
f0103368:	75 25                	jne    f010338f <memset+0x3f>
		c &= 0xFF;
f010336a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010336e:	89 df                	mov    %ebx,%edi
f0103370:	c1 e7 08             	shl    $0x8,%edi
f0103373:	89 de                	mov    %ebx,%esi
f0103375:	c1 e6 18             	shl    $0x18,%esi
f0103378:	89 d8                	mov    %ebx,%eax
f010337a:	c1 e0 10             	shl    $0x10,%eax
f010337d:	09 f0                	or     %esi,%eax
f010337f:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f0103381:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103384:	89 f8                	mov    %edi,%eax
f0103386:	09 d8                	or     %ebx,%eax
f0103388:	89 d7                	mov    %edx,%edi
f010338a:	fc                   	cld    
f010338b:	f3 ab                	rep stos %eax,%es:(%edi)
f010338d:	eb 08                	jmp    f0103397 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010338f:	89 d7                	mov    %edx,%edi
f0103391:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103394:	fc                   	cld    
f0103395:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f0103397:	89 d0                	mov    %edx,%eax
f0103399:	5b                   	pop    %ebx
f010339a:	5e                   	pop    %esi
f010339b:	5f                   	pop    %edi
f010339c:	5d                   	pop    %ebp
f010339d:	c3                   	ret    

f010339e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010339e:	55                   	push   %ebp
f010339f:	89 e5                	mov    %esp,%ebp
f01033a1:	57                   	push   %edi
f01033a2:	56                   	push   %esi
f01033a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033a9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01033ac:	39 c6                	cmp    %eax,%esi
f01033ae:	73 35                	jae    f01033e5 <memmove+0x47>
f01033b0:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01033b3:	39 d0                	cmp    %edx,%eax
f01033b5:	73 2e                	jae    f01033e5 <memmove+0x47>
		s += n;
		d += n;
f01033b7:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01033ba:	89 d6                	mov    %edx,%esi
f01033bc:	09 fe                	or     %edi,%esi
f01033be:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01033c4:	75 13                	jne    f01033d9 <memmove+0x3b>
f01033c6:	f6 c1 03             	test   $0x3,%cl
f01033c9:	75 0e                	jne    f01033d9 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01033cb:	83 ef 04             	sub    $0x4,%edi
f01033ce:	8d 72 fc             	lea    -0x4(%edx),%esi
f01033d1:	c1 e9 02             	shr    $0x2,%ecx
f01033d4:	fd                   	std    
f01033d5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01033d7:	eb 09                	jmp    f01033e2 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01033d9:	83 ef 01             	sub    $0x1,%edi
f01033dc:	8d 72 ff             	lea    -0x1(%edx),%esi
f01033df:	fd                   	std    
f01033e0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01033e2:	fc                   	cld    
f01033e3:	eb 1d                	jmp    f0103402 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01033e5:	89 f2                	mov    %esi,%edx
f01033e7:	09 c2                	or     %eax,%edx
f01033e9:	f6 c2 03             	test   $0x3,%dl
f01033ec:	75 0f                	jne    f01033fd <memmove+0x5f>
f01033ee:	f6 c1 03             	test   $0x3,%cl
f01033f1:	75 0a                	jne    f01033fd <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01033f3:	c1 e9 02             	shr    $0x2,%ecx
f01033f6:	89 c7                	mov    %eax,%edi
f01033f8:	fc                   	cld    
f01033f9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01033fb:	eb 05                	jmp    f0103402 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01033fd:	89 c7                	mov    %eax,%edi
f01033ff:	fc                   	cld    
f0103400:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103402:	5e                   	pop    %esi
f0103403:	5f                   	pop    %edi
f0103404:	5d                   	pop    %ebp
f0103405:	c3                   	ret    

f0103406 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103406:	55                   	push   %ebp
f0103407:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103409:	ff 75 10             	pushl  0x10(%ebp)
f010340c:	ff 75 0c             	pushl  0xc(%ebp)
f010340f:	ff 75 08             	pushl  0x8(%ebp)
f0103412:	e8 87 ff ff ff       	call   f010339e <memmove>
}
f0103417:	c9                   	leave  
f0103418:	c3                   	ret    

f0103419 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103419:	55                   	push   %ebp
f010341a:	89 e5                	mov    %esp,%ebp
f010341c:	56                   	push   %esi
f010341d:	53                   	push   %ebx
f010341e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103421:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103424:	89 c6                	mov    %eax,%esi
f0103426:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103429:	eb 1a                	jmp    f0103445 <memcmp+0x2c>
		if (*s1 != *s2)
f010342b:	0f b6 08             	movzbl (%eax),%ecx
f010342e:	0f b6 1a             	movzbl (%edx),%ebx
f0103431:	38 d9                	cmp    %bl,%cl
f0103433:	74 0a                	je     f010343f <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103435:	0f b6 c1             	movzbl %cl,%eax
f0103438:	0f b6 db             	movzbl %bl,%ebx
f010343b:	29 d8                	sub    %ebx,%eax
f010343d:	eb 0f                	jmp    f010344e <memcmp+0x35>
		s1++, s2++;
f010343f:	83 c0 01             	add    $0x1,%eax
f0103442:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103445:	39 f0                	cmp    %esi,%eax
f0103447:	75 e2                	jne    f010342b <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103449:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010344e:	5b                   	pop    %ebx
f010344f:	5e                   	pop    %esi
f0103450:	5d                   	pop    %ebp
f0103451:	c3                   	ret    

f0103452 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103452:	55                   	push   %ebp
f0103453:	89 e5                	mov    %esp,%ebp
f0103455:	53                   	push   %ebx
f0103456:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103459:	89 c1                	mov    %eax,%ecx
f010345b:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010345e:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103462:	eb 0a                	jmp    f010346e <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103464:	0f b6 10             	movzbl (%eax),%edx
f0103467:	39 da                	cmp    %ebx,%edx
f0103469:	74 07                	je     f0103472 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010346b:	83 c0 01             	add    $0x1,%eax
f010346e:	39 c8                	cmp    %ecx,%eax
f0103470:	72 f2                	jb     f0103464 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103472:	5b                   	pop    %ebx
f0103473:	5d                   	pop    %ebp
f0103474:	c3                   	ret    

f0103475 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103475:	55                   	push   %ebp
f0103476:	89 e5                	mov    %esp,%ebp
f0103478:	57                   	push   %edi
f0103479:	56                   	push   %esi
f010347a:	53                   	push   %ebx
f010347b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010347e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103481:	eb 03                	jmp    f0103486 <strtol+0x11>
		s++;
f0103483:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103486:	0f b6 01             	movzbl (%ecx),%eax
f0103489:	3c 20                	cmp    $0x20,%al
f010348b:	74 f6                	je     f0103483 <strtol+0xe>
f010348d:	3c 09                	cmp    $0x9,%al
f010348f:	74 f2                	je     f0103483 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103491:	3c 2b                	cmp    $0x2b,%al
f0103493:	75 0a                	jne    f010349f <strtol+0x2a>
		s++;
f0103495:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103498:	bf 00 00 00 00       	mov    $0x0,%edi
f010349d:	eb 11                	jmp    f01034b0 <strtol+0x3b>
f010349f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01034a4:	3c 2d                	cmp    $0x2d,%al
f01034a6:	75 08                	jne    f01034b0 <strtol+0x3b>
		s++, neg = 1;
f01034a8:	83 c1 01             	add    $0x1,%ecx
f01034ab:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01034b0:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01034b6:	75 15                	jne    f01034cd <strtol+0x58>
f01034b8:	80 39 30             	cmpb   $0x30,(%ecx)
f01034bb:	75 10                	jne    f01034cd <strtol+0x58>
f01034bd:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01034c1:	75 7c                	jne    f010353f <strtol+0xca>
		s += 2, base = 16;
f01034c3:	83 c1 02             	add    $0x2,%ecx
f01034c6:	bb 10 00 00 00       	mov    $0x10,%ebx
f01034cb:	eb 16                	jmp    f01034e3 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01034cd:	85 db                	test   %ebx,%ebx
f01034cf:	75 12                	jne    f01034e3 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01034d1:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01034d6:	80 39 30             	cmpb   $0x30,(%ecx)
f01034d9:	75 08                	jne    f01034e3 <strtol+0x6e>
		s++, base = 8;
f01034db:	83 c1 01             	add    $0x1,%ecx
f01034de:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01034e3:	b8 00 00 00 00       	mov    $0x0,%eax
f01034e8:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01034eb:	0f b6 11             	movzbl (%ecx),%edx
f01034ee:	8d 72 d0             	lea    -0x30(%edx),%esi
f01034f1:	89 f3                	mov    %esi,%ebx
f01034f3:	80 fb 09             	cmp    $0x9,%bl
f01034f6:	77 08                	ja     f0103500 <strtol+0x8b>
			dig = *s - '0';
f01034f8:	0f be d2             	movsbl %dl,%edx
f01034fb:	83 ea 30             	sub    $0x30,%edx
f01034fe:	eb 22                	jmp    f0103522 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0103500:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103503:	89 f3                	mov    %esi,%ebx
f0103505:	80 fb 19             	cmp    $0x19,%bl
f0103508:	77 08                	ja     f0103512 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010350a:	0f be d2             	movsbl %dl,%edx
f010350d:	83 ea 57             	sub    $0x57,%edx
f0103510:	eb 10                	jmp    f0103522 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0103512:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103515:	89 f3                	mov    %esi,%ebx
f0103517:	80 fb 19             	cmp    $0x19,%bl
f010351a:	77 16                	ja     f0103532 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010351c:	0f be d2             	movsbl %dl,%edx
f010351f:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0103522:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103525:	7d 0b                	jge    f0103532 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103527:	83 c1 01             	add    $0x1,%ecx
f010352a:	0f af 45 10          	imul   0x10(%ebp),%eax
f010352e:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103530:	eb b9                	jmp    f01034eb <strtol+0x76>

	if (endptr)
f0103532:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103536:	74 0d                	je     f0103545 <strtol+0xd0>
		*endptr = (char *) s;
f0103538:	8b 75 0c             	mov    0xc(%ebp),%esi
f010353b:	89 0e                	mov    %ecx,(%esi)
f010353d:	eb 06                	jmp    f0103545 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010353f:	85 db                	test   %ebx,%ebx
f0103541:	74 98                	je     f01034db <strtol+0x66>
f0103543:	eb 9e                	jmp    f01034e3 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0103545:	89 c2                	mov    %eax,%edx
f0103547:	f7 da                	neg    %edx
f0103549:	85 ff                	test   %edi,%edi
f010354b:	0f 45 c2             	cmovne %edx,%eax
}
f010354e:	5b                   	pop    %ebx
f010354f:	5e                   	pop    %esi
f0103550:	5f                   	pop    %edi
f0103551:	5d                   	pop    %ebp
f0103552:	c3                   	ret    
f0103553:	66 90                	xchg   %ax,%ax
f0103555:	66 90                	xchg   %ax,%ax
f0103557:	66 90                	xchg   %ax,%ax
f0103559:	66 90                	xchg   %ax,%ax
f010355b:	66 90                	xchg   %ax,%ax
f010355d:	66 90                	xchg   %ax,%ax
f010355f:	90                   	nop

f0103560 <__udivdi3>:
f0103560:	55                   	push   %ebp
f0103561:	57                   	push   %edi
f0103562:	56                   	push   %esi
f0103563:	53                   	push   %ebx
f0103564:	83 ec 1c             	sub    $0x1c,%esp
f0103567:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010356b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010356f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103573:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103577:	85 f6                	test   %esi,%esi
f0103579:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010357d:	89 ca                	mov    %ecx,%edx
f010357f:	89 f8                	mov    %edi,%eax
f0103581:	75 3d                	jne    f01035c0 <__udivdi3+0x60>
f0103583:	39 cf                	cmp    %ecx,%edi
f0103585:	0f 87 c5 00 00 00    	ja     f0103650 <__udivdi3+0xf0>
f010358b:	85 ff                	test   %edi,%edi
f010358d:	89 fd                	mov    %edi,%ebp
f010358f:	75 0b                	jne    f010359c <__udivdi3+0x3c>
f0103591:	b8 01 00 00 00       	mov    $0x1,%eax
f0103596:	31 d2                	xor    %edx,%edx
f0103598:	f7 f7                	div    %edi
f010359a:	89 c5                	mov    %eax,%ebp
f010359c:	89 c8                	mov    %ecx,%eax
f010359e:	31 d2                	xor    %edx,%edx
f01035a0:	f7 f5                	div    %ebp
f01035a2:	89 c1                	mov    %eax,%ecx
f01035a4:	89 d8                	mov    %ebx,%eax
f01035a6:	89 cf                	mov    %ecx,%edi
f01035a8:	f7 f5                	div    %ebp
f01035aa:	89 c3                	mov    %eax,%ebx
f01035ac:	89 d8                	mov    %ebx,%eax
f01035ae:	89 fa                	mov    %edi,%edx
f01035b0:	83 c4 1c             	add    $0x1c,%esp
f01035b3:	5b                   	pop    %ebx
f01035b4:	5e                   	pop    %esi
f01035b5:	5f                   	pop    %edi
f01035b6:	5d                   	pop    %ebp
f01035b7:	c3                   	ret    
f01035b8:	90                   	nop
f01035b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035c0:	39 ce                	cmp    %ecx,%esi
f01035c2:	77 74                	ja     f0103638 <__udivdi3+0xd8>
f01035c4:	0f bd fe             	bsr    %esi,%edi
f01035c7:	83 f7 1f             	xor    $0x1f,%edi
f01035ca:	0f 84 98 00 00 00    	je     f0103668 <__udivdi3+0x108>
f01035d0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01035d5:	89 f9                	mov    %edi,%ecx
f01035d7:	89 c5                	mov    %eax,%ebp
f01035d9:	29 fb                	sub    %edi,%ebx
f01035db:	d3 e6                	shl    %cl,%esi
f01035dd:	89 d9                	mov    %ebx,%ecx
f01035df:	d3 ed                	shr    %cl,%ebp
f01035e1:	89 f9                	mov    %edi,%ecx
f01035e3:	d3 e0                	shl    %cl,%eax
f01035e5:	09 ee                	or     %ebp,%esi
f01035e7:	89 d9                	mov    %ebx,%ecx
f01035e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035ed:	89 d5                	mov    %edx,%ebp
f01035ef:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035f3:	d3 ed                	shr    %cl,%ebp
f01035f5:	89 f9                	mov    %edi,%ecx
f01035f7:	d3 e2                	shl    %cl,%edx
f01035f9:	89 d9                	mov    %ebx,%ecx
f01035fb:	d3 e8                	shr    %cl,%eax
f01035fd:	09 c2                	or     %eax,%edx
f01035ff:	89 d0                	mov    %edx,%eax
f0103601:	89 ea                	mov    %ebp,%edx
f0103603:	f7 f6                	div    %esi
f0103605:	89 d5                	mov    %edx,%ebp
f0103607:	89 c3                	mov    %eax,%ebx
f0103609:	f7 64 24 0c          	mull   0xc(%esp)
f010360d:	39 d5                	cmp    %edx,%ebp
f010360f:	72 10                	jb     f0103621 <__udivdi3+0xc1>
f0103611:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103615:	89 f9                	mov    %edi,%ecx
f0103617:	d3 e6                	shl    %cl,%esi
f0103619:	39 c6                	cmp    %eax,%esi
f010361b:	73 07                	jae    f0103624 <__udivdi3+0xc4>
f010361d:	39 d5                	cmp    %edx,%ebp
f010361f:	75 03                	jne    f0103624 <__udivdi3+0xc4>
f0103621:	83 eb 01             	sub    $0x1,%ebx
f0103624:	31 ff                	xor    %edi,%edi
f0103626:	89 d8                	mov    %ebx,%eax
f0103628:	89 fa                	mov    %edi,%edx
f010362a:	83 c4 1c             	add    $0x1c,%esp
f010362d:	5b                   	pop    %ebx
f010362e:	5e                   	pop    %esi
f010362f:	5f                   	pop    %edi
f0103630:	5d                   	pop    %ebp
f0103631:	c3                   	ret    
f0103632:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103638:	31 ff                	xor    %edi,%edi
f010363a:	31 db                	xor    %ebx,%ebx
f010363c:	89 d8                	mov    %ebx,%eax
f010363e:	89 fa                	mov    %edi,%edx
f0103640:	83 c4 1c             	add    $0x1c,%esp
f0103643:	5b                   	pop    %ebx
f0103644:	5e                   	pop    %esi
f0103645:	5f                   	pop    %edi
f0103646:	5d                   	pop    %ebp
f0103647:	c3                   	ret    
f0103648:	90                   	nop
f0103649:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103650:	89 d8                	mov    %ebx,%eax
f0103652:	f7 f7                	div    %edi
f0103654:	31 ff                	xor    %edi,%edi
f0103656:	89 c3                	mov    %eax,%ebx
f0103658:	89 d8                	mov    %ebx,%eax
f010365a:	89 fa                	mov    %edi,%edx
f010365c:	83 c4 1c             	add    $0x1c,%esp
f010365f:	5b                   	pop    %ebx
f0103660:	5e                   	pop    %esi
f0103661:	5f                   	pop    %edi
f0103662:	5d                   	pop    %ebp
f0103663:	c3                   	ret    
f0103664:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103668:	39 ce                	cmp    %ecx,%esi
f010366a:	72 0c                	jb     f0103678 <__udivdi3+0x118>
f010366c:	31 db                	xor    %ebx,%ebx
f010366e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103672:	0f 87 34 ff ff ff    	ja     f01035ac <__udivdi3+0x4c>
f0103678:	bb 01 00 00 00       	mov    $0x1,%ebx
f010367d:	e9 2a ff ff ff       	jmp    f01035ac <__udivdi3+0x4c>
f0103682:	66 90                	xchg   %ax,%ax
f0103684:	66 90                	xchg   %ax,%ax
f0103686:	66 90                	xchg   %ax,%ax
f0103688:	66 90                	xchg   %ax,%ax
f010368a:	66 90                	xchg   %ax,%ax
f010368c:	66 90                	xchg   %ax,%ax
f010368e:	66 90                	xchg   %ax,%ax

f0103690 <__umoddi3>:
f0103690:	55                   	push   %ebp
f0103691:	57                   	push   %edi
f0103692:	56                   	push   %esi
f0103693:	53                   	push   %ebx
f0103694:	83 ec 1c             	sub    $0x1c,%esp
f0103697:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010369b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010369f:	8b 74 24 34          	mov    0x34(%esp),%esi
f01036a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01036a7:	85 d2                	test   %edx,%edx
f01036a9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01036ad:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036b1:	89 f3                	mov    %esi,%ebx
f01036b3:	89 3c 24             	mov    %edi,(%esp)
f01036b6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036ba:	75 1c                	jne    f01036d8 <__umoddi3+0x48>
f01036bc:	39 f7                	cmp    %esi,%edi
f01036be:	76 50                	jbe    f0103710 <__umoddi3+0x80>
f01036c0:	89 c8                	mov    %ecx,%eax
f01036c2:	89 f2                	mov    %esi,%edx
f01036c4:	f7 f7                	div    %edi
f01036c6:	89 d0                	mov    %edx,%eax
f01036c8:	31 d2                	xor    %edx,%edx
f01036ca:	83 c4 1c             	add    $0x1c,%esp
f01036cd:	5b                   	pop    %ebx
f01036ce:	5e                   	pop    %esi
f01036cf:	5f                   	pop    %edi
f01036d0:	5d                   	pop    %ebp
f01036d1:	c3                   	ret    
f01036d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01036d8:	39 f2                	cmp    %esi,%edx
f01036da:	89 d0                	mov    %edx,%eax
f01036dc:	77 52                	ja     f0103730 <__umoddi3+0xa0>
f01036de:	0f bd ea             	bsr    %edx,%ebp
f01036e1:	83 f5 1f             	xor    $0x1f,%ebp
f01036e4:	75 5a                	jne    f0103740 <__umoddi3+0xb0>
f01036e6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01036ea:	0f 82 e0 00 00 00    	jb     f01037d0 <__umoddi3+0x140>
f01036f0:	39 0c 24             	cmp    %ecx,(%esp)
f01036f3:	0f 86 d7 00 00 00    	jbe    f01037d0 <__umoddi3+0x140>
f01036f9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01036fd:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103701:	83 c4 1c             	add    $0x1c,%esp
f0103704:	5b                   	pop    %ebx
f0103705:	5e                   	pop    %esi
f0103706:	5f                   	pop    %edi
f0103707:	5d                   	pop    %ebp
f0103708:	c3                   	ret    
f0103709:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103710:	85 ff                	test   %edi,%edi
f0103712:	89 fd                	mov    %edi,%ebp
f0103714:	75 0b                	jne    f0103721 <__umoddi3+0x91>
f0103716:	b8 01 00 00 00       	mov    $0x1,%eax
f010371b:	31 d2                	xor    %edx,%edx
f010371d:	f7 f7                	div    %edi
f010371f:	89 c5                	mov    %eax,%ebp
f0103721:	89 f0                	mov    %esi,%eax
f0103723:	31 d2                	xor    %edx,%edx
f0103725:	f7 f5                	div    %ebp
f0103727:	89 c8                	mov    %ecx,%eax
f0103729:	f7 f5                	div    %ebp
f010372b:	89 d0                	mov    %edx,%eax
f010372d:	eb 99                	jmp    f01036c8 <__umoddi3+0x38>
f010372f:	90                   	nop
f0103730:	89 c8                	mov    %ecx,%eax
f0103732:	89 f2                	mov    %esi,%edx
f0103734:	83 c4 1c             	add    $0x1c,%esp
f0103737:	5b                   	pop    %ebx
f0103738:	5e                   	pop    %esi
f0103739:	5f                   	pop    %edi
f010373a:	5d                   	pop    %ebp
f010373b:	c3                   	ret    
f010373c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103740:	8b 34 24             	mov    (%esp),%esi
f0103743:	bf 20 00 00 00       	mov    $0x20,%edi
f0103748:	89 e9                	mov    %ebp,%ecx
f010374a:	29 ef                	sub    %ebp,%edi
f010374c:	d3 e0                	shl    %cl,%eax
f010374e:	89 f9                	mov    %edi,%ecx
f0103750:	89 f2                	mov    %esi,%edx
f0103752:	d3 ea                	shr    %cl,%edx
f0103754:	89 e9                	mov    %ebp,%ecx
f0103756:	09 c2                	or     %eax,%edx
f0103758:	89 d8                	mov    %ebx,%eax
f010375a:	89 14 24             	mov    %edx,(%esp)
f010375d:	89 f2                	mov    %esi,%edx
f010375f:	d3 e2                	shl    %cl,%edx
f0103761:	89 f9                	mov    %edi,%ecx
f0103763:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103767:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010376b:	d3 e8                	shr    %cl,%eax
f010376d:	89 e9                	mov    %ebp,%ecx
f010376f:	89 c6                	mov    %eax,%esi
f0103771:	d3 e3                	shl    %cl,%ebx
f0103773:	89 f9                	mov    %edi,%ecx
f0103775:	89 d0                	mov    %edx,%eax
f0103777:	d3 e8                	shr    %cl,%eax
f0103779:	89 e9                	mov    %ebp,%ecx
f010377b:	09 d8                	or     %ebx,%eax
f010377d:	89 d3                	mov    %edx,%ebx
f010377f:	89 f2                	mov    %esi,%edx
f0103781:	f7 34 24             	divl   (%esp)
f0103784:	89 d6                	mov    %edx,%esi
f0103786:	d3 e3                	shl    %cl,%ebx
f0103788:	f7 64 24 04          	mull   0x4(%esp)
f010378c:	39 d6                	cmp    %edx,%esi
f010378e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103792:	89 d1                	mov    %edx,%ecx
f0103794:	89 c3                	mov    %eax,%ebx
f0103796:	72 08                	jb     f01037a0 <__umoddi3+0x110>
f0103798:	75 11                	jne    f01037ab <__umoddi3+0x11b>
f010379a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010379e:	73 0b                	jae    f01037ab <__umoddi3+0x11b>
f01037a0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01037a4:	1b 14 24             	sbb    (%esp),%edx
f01037a7:	89 d1                	mov    %edx,%ecx
f01037a9:	89 c3                	mov    %eax,%ebx
f01037ab:	8b 54 24 08          	mov    0x8(%esp),%edx
f01037af:	29 da                	sub    %ebx,%edx
f01037b1:	19 ce                	sbb    %ecx,%esi
f01037b3:	89 f9                	mov    %edi,%ecx
f01037b5:	89 f0                	mov    %esi,%eax
f01037b7:	d3 e0                	shl    %cl,%eax
f01037b9:	89 e9                	mov    %ebp,%ecx
f01037bb:	d3 ea                	shr    %cl,%edx
f01037bd:	89 e9                	mov    %ebp,%ecx
f01037bf:	d3 ee                	shr    %cl,%esi
f01037c1:	09 d0                	or     %edx,%eax
f01037c3:	89 f2                	mov    %esi,%edx
f01037c5:	83 c4 1c             	add    $0x1c,%esp
f01037c8:	5b                   	pop    %ebx
f01037c9:	5e                   	pop    %esi
f01037ca:	5f                   	pop    %edi
f01037cb:	5d                   	pop    %ebp
f01037cc:	c3                   	ret    
f01037cd:	8d 76 00             	lea    0x0(%esi),%esi
f01037d0:	29 f9                	sub    %edi,%ecx
f01037d2:	19 d6                	sbb    %edx,%esi
f01037d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01037d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01037dc:	e9 18 ff ff ff       	jmp    f01036f9 <__umoddi3+0x69>
