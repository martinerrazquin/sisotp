
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
	movl	%cr4,%eax
f010001d:	0f 20 e0             	mov    %cr4,%eax
	orl		$(CR4_PSE),%eax	#Prendo flag del cr4 para Page Size Extension
f0100020:	83 c8 10             	or     $0x10,%eax
	movl	%eax,%cr4	
f0100023:	0f 22 e0             	mov    %eax,%cr4
	# Turn on paging.
	movl	%cr0, %eax
f0100026:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100029:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f010002e:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100031:	b8 38 00 10 f0       	mov    $0xf0100038,%eax
	jmp	*%eax
f0100036:	ff e0                	jmp    *%eax

f0100038 <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f0100038:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f010003d:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100042:	e8 02 00 00 00       	call   f0100049 <i386_init>

f0100047 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f0100047:	eb fe                	jmp    f0100047 <spin>

f0100049 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100049:	55                   	push   %ebp
f010004a:	89 e5                	mov    %esp,%ebp
f010004c:	83 ec 0c             	sub    $0xc,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f010004f:	b8 50 79 11 f0       	mov    $0xf0117950,%eax
f0100054:	2d 00 63 11 f0       	sub    $0xf0116300,%eax
f0100059:	50                   	push   %eax
f010005a:	6a 00                	push   $0x0
f010005c:	68 00 63 11 f0       	push   $0xf0116300
f0100061:	e8 c3 31 00 00       	call   f0103229 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100066:	e8 78 06 00 00       	call   f01006e3 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006b:	83 c4 08             	add    $0x8,%esp
f010006e:	68 ac 1a 00 00       	push   $0x1aac
f0100073:	68 c0 36 10 f0       	push   $0xf01036c0
f0100078:	e8 08 27 00 00       	call   f0102785 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f010007d:	e8 1e 25 00 00       	call   f01025a0 <mem_init>
f0100082:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100085:	83 ec 0c             	sub    $0xc,%esp
f0100088:	6a 00                	push   $0x0
f010008a:	e8 22 09 00 00       	call   f01009b1 <monitor>
f010008f:	83 c4 10             	add    $0x10,%esp
f0100092:	eb f1                	jmp    f0100085 <i386_init+0x3c>

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
f0100099:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009c:	83 3d 40 79 11 f0 00 	cmpl   $0x0,0xf0117940
f01000a3:	75 37                	jne    f01000dc <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000a5:	89 35 40 79 11 f0    	mov    %esi,0xf0117940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ab:	fa                   	cli    
f01000ac:	fc                   	cld    

	va_start(ap, fmt);
f01000ad:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000b0:	83 ec 04             	sub    $0x4,%esp
f01000b3:	ff 75 0c             	pushl  0xc(%ebp)
f01000b6:	ff 75 08             	pushl  0x8(%ebp)
f01000b9:	68 fc 36 10 f0       	push   $0xf01036fc
f01000be:	e8 c2 26 00 00       	call   f0102785 <cprintf>
	vcprintf(fmt, ap);
f01000c3:	83 c4 08             	add    $0x8,%esp
f01000c6:	53                   	push   %ebx
f01000c7:	56                   	push   %esi
f01000c8:	e8 92 26 00 00       	call   f010275f <vcprintf>
	cprintf("\n>>>\n");
f01000cd:	c7 04 24 db 36 10 f0 	movl   $0xf01036db,(%esp)
f01000d4:	e8 ac 26 00 00       	call   f0102785 <cprintf>
	va_end(ap);
f01000d9:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000dc:	83 ec 0c             	sub    $0xc,%esp
f01000df:	6a 00                	push   $0x0
f01000e1:	e8 cb 08 00 00       	call   f01009b1 <monitor>
f01000e6:	83 c4 10             	add    $0x10,%esp
f01000e9:	eb f1                	jmp    f01000dc <_panic+0x48>

f01000eb <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000eb:	55                   	push   %ebp
f01000ec:	89 e5                	mov    %esp,%ebp
f01000ee:	53                   	push   %ebx
f01000ef:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000f2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000f5:	ff 75 0c             	pushl  0xc(%ebp)
f01000f8:	ff 75 08             	pushl  0x8(%ebp)
f01000fb:	68 e1 36 10 f0       	push   $0xf01036e1
f0100100:	e8 80 26 00 00       	call   f0102785 <cprintf>
	vcprintf(fmt, ap);
f0100105:	83 c4 08             	add    $0x8,%esp
f0100108:	53                   	push   %ebx
f0100109:	ff 75 10             	pushl  0x10(%ebp)
f010010c:	e8 4e 26 00 00       	call   f010275f <vcprintf>
	cprintf("\n");
f0100111:	c7 04 24 d7 46 10 f0 	movl   $0xf01046d7,(%esp)
f0100118:	e8 68 26 00 00       	call   f0102785 <cprintf>
	va_end(ap);
}
f010011d:	83 c4 10             	add    $0x10,%esp
f0100120:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100123:	c9                   	leave  
f0100124:	c3                   	ret    

f0100125 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0100125:	55                   	push   %ebp
f0100126:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100128:	89 c2                	mov    %eax,%edx
f010012a:	ec                   	in     (%dx),%al
	return data;
}
f010012b:	5d                   	pop    %ebp
f010012c:	c3                   	ret    

f010012d <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f010012d:	55                   	push   %ebp
f010012e:	89 e5                	mov    %esp,%ebp
f0100130:	89 c1                	mov    %eax,%ecx
f0100132:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100134:	89 ca                	mov    %ecx,%edx
f0100136:	ee                   	out    %al,(%dx)
}
f0100137:	5d                   	pop    %ebp
f0100138:	c3                   	ret    

f0100139 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100139:	55                   	push   %ebp
f010013a:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f010013c:	b8 84 00 00 00       	mov    $0x84,%eax
f0100141:	e8 df ff ff ff       	call   f0100125 <inb>
	inb(0x84);
f0100146:	b8 84 00 00 00       	mov    $0x84,%eax
f010014b:	e8 d5 ff ff ff       	call   f0100125 <inb>
	inb(0x84);
f0100150:	b8 84 00 00 00       	mov    $0x84,%eax
f0100155:	e8 cb ff ff ff       	call   f0100125 <inb>
	inb(0x84);
f010015a:	b8 84 00 00 00       	mov    $0x84,%eax
f010015f:	e8 c1 ff ff ff       	call   f0100125 <inb>
}
f0100164:	5d                   	pop    %ebp
f0100165:	c3                   	ret    

f0100166 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100166:	55                   	push   %ebp
f0100167:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100169:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f010016e:	e8 b2 ff ff ff       	call   f0100125 <inb>
f0100173:	a8 01                	test   $0x1,%al
f0100175:	74 0f                	je     f0100186 <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f0100177:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010017c:	e8 a4 ff ff ff       	call   f0100125 <inb>
f0100181:	0f b6 c0             	movzbl %al,%eax
f0100184:	eb 05                	jmp    f010018b <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100186:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010018b:	5d                   	pop    %ebp
f010018c:	c3                   	ret    

f010018d <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f010018d:	55                   	push   %ebp
f010018e:	89 e5                	mov    %esp,%ebp
f0100190:	56                   	push   %esi
f0100191:	53                   	push   %ebx
f0100192:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f0100194:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100199:	eb 08                	jmp    f01001a3 <serial_putc+0x16>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f010019b:	e8 99 ff ff ff       	call   f0100139 <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01001a0:	83 c3 01             	add    $0x1,%ebx
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001a3:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01001a8:	e8 78 ff ff ff       	call   f0100125 <inb>
f01001ad:	a8 20                	test   $0x20,%al
f01001af:	75 08                	jne    f01001b9 <serial_putc+0x2c>
f01001b1:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01001b7:	7e e2                	jle    f010019b <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001b9:	89 f0                	mov    %esi,%eax
f01001bb:	0f b6 d0             	movzbl %al,%edx
f01001be:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001c3:	e8 65 ff ff ff       	call   f010012d <outb>
}
f01001c8:	5b                   	pop    %ebx
f01001c9:	5e                   	pop    %esi
f01001ca:	5d                   	pop    %ebp
f01001cb:	c3                   	ret    

f01001cc <serial_init>:

static void
serial_init(void)
{
f01001cc:	55                   	push   %ebp
f01001cd:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f01001cf:	ba 00 00 00 00       	mov    $0x0,%edx
f01001d4:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01001d9:	e8 4f ff ff ff       	call   f010012d <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f01001de:	ba 80 00 00 00       	mov    $0x80,%edx
f01001e3:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01001e8:	e8 40 ff ff ff       	call   f010012d <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f01001ed:	ba 0c 00 00 00       	mov    $0xc,%edx
f01001f2:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001f7:	e8 31 ff ff ff       	call   f010012d <outb>
	outb(COM1+COM_DLM, 0);
f01001fc:	ba 00 00 00 00       	mov    $0x0,%edx
f0100201:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100206:	e8 22 ff ff ff       	call   f010012d <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f010020b:	ba 03 00 00 00       	mov    $0x3,%edx
f0100210:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f0100215:	e8 13 ff ff ff       	call   f010012d <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f010021a:	ba 00 00 00 00       	mov    $0x0,%edx
f010021f:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f0100224:	e8 04 ff ff ff       	call   f010012d <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f0100229:	ba 01 00 00 00       	mov    $0x1,%edx
f010022e:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100233:	e8 f5 fe ff ff       	call   f010012d <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100238:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f010023d:	e8 e3 fe ff ff       	call   f0100125 <inb>
f0100242:	3c ff                	cmp    $0xff,%al
f0100244:	0f 95 05 34 65 11 f0 	setne  0xf0116534
	(void) inb(COM1+COM_IIR);
f010024b:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100250:	e8 d0 fe ff ff       	call   f0100125 <inb>
	(void) inb(COM1+COM_RX);
f0100255:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010025a:	e8 c6 fe ff ff       	call   f0100125 <inb>

}
f010025f:	5d                   	pop    %ebp
f0100260:	c3                   	ret    

f0100261 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f0100261:	55                   	push   %ebp
f0100262:	89 e5                	mov    %esp,%ebp
f0100264:	56                   	push   %esi
f0100265:	53                   	push   %ebx
f0100266:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100268:	bb 00 00 00 00       	mov    $0x0,%ebx
f010026d:	eb 08                	jmp    f0100277 <lpt_putc+0x16>
		delay();
f010026f:	e8 c5 fe ff ff       	call   f0100139 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100274:	83 c3 01             	add    $0x1,%ebx
f0100277:	b8 79 03 00 00       	mov    $0x379,%eax
f010027c:	e8 a4 fe ff ff       	call   f0100125 <inb>
f0100281:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100287:	7f 04                	jg     f010028d <lpt_putc+0x2c>
f0100289:	84 c0                	test   %al,%al
f010028b:	79 e2                	jns    f010026f <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f010028d:	89 f0                	mov    %esi,%eax
f010028f:	0f b6 d0             	movzbl %al,%edx
f0100292:	b8 78 03 00 00       	mov    $0x378,%eax
f0100297:	e8 91 fe ff ff       	call   f010012d <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f010029c:	ba 0d 00 00 00       	mov    $0xd,%edx
f01002a1:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002a6:	e8 82 fe ff ff       	call   f010012d <outb>
	outb(0x378+2, 0x08);
f01002ab:	ba 08 00 00 00       	mov    $0x8,%edx
f01002b0:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002b5:	e8 73 fe ff ff       	call   f010012d <outb>
}
f01002ba:	5b                   	pop    %ebx
f01002bb:	5e                   	pop    %esi
f01002bc:	5d                   	pop    %ebp
f01002bd:	c3                   	ret    

f01002be <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002be:	55                   	push   %ebp
f01002bf:	89 e5                	mov    %esp,%ebp
f01002c1:	57                   	push   %edi
f01002c2:	56                   	push   %esi
f01002c3:	53                   	push   %ebx
f01002c4:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002c7:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002ce:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002d5:	5a a5 
	if (*cp != 0xA55A) {
f01002d7:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002de:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002e2:	74 13                	je     f01002f7 <cga_init+0x39>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002e4:	c7 05 30 65 11 f0 b4 	movl   $0x3b4,0xf0116530
f01002eb:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01002ee:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
f01002f5:	eb 18                	jmp    f010030f <cga_init+0x51>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01002f7:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01002fe:	c7 05 30 65 11 f0 d4 	movl   $0x3d4,0xf0116530
f0100305:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100308:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010030f:	8b 35 30 65 11 f0    	mov    0xf0116530,%esi
f0100315:	ba 0e 00 00 00       	mov    $0xe,%edx
f010031a:	89 f0                	mov    %esi,%eax
f010031c:	e8 0c fe ff ff       	call   f010012d <outb>
	pos = inb(addr_6845 + 1) << 8;
f0100321:	8d 7e 01             	lea    0x1(%esi),%edi
f0100324:	89 f8                	mov    %edi,%eax
f0100326:	e8 fa fd ff ff       	call   f0100125 <inb>
f010032b:	0f b6 d8             	movzbl %al,%ebx
f010032e:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f0100331:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100336:	89 f0                	mov    %esi,%eax
f0100338:	e8 f0 fd ff ff       	call   f010012d <outb>
	pos |= inb(addr_6845 + 1);
f010033d:	89 f8                	mov    %edi,%eax
f010033f:	e8 e1 fd ff ff       	call   f0100125 <inb>

	crt_buf = (uint16_t*) cp;
f0100344:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100347:	89 0d 2c 65 11 f0    	mov    %ecx,0xf011652c
	crt_pos = pos;
f010034d:	0f b6 c0             	movzbl %al,%eax
f0100350:	09 c3                	or     %eax,%ebx
f0100352:	66 89 1d 28 65 11 f0 	mov    %bx,0xf0116528
}
f0100359:	83 c4 04             	add    $0x4,%esp
f010035c:	5b                   	pop    %ebx
f010035d:	5e                   	pop    %esi
f010035e:	5f                   	pop    %edi
f010035f:	5d                   	pop    %ebp
f0100360:	c3                   	ret    

f0100361 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100361:	55                   	push   %ebp
f0100362:	89 e5                	mov    %esp,%ebp
f0100364:	53                   	push   %ebx
f0100365:	83 ec 04             	sub    $0x4,%esp
f0100368:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010036a:	eb 2b                	jmp    f0100397 <cons_intr+0x36>
		if (c == 0)
f010036c:	85 c0                	test   %eax,%eax
f010036e:	74 27                	je     f0100397 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100370:	8b 0d 24 65 11 f0    	mov    0xf0116524,%ecx
f0100376:	8d 51 01             	lea    0x1(%ecx),%edx
f0100379:	89 15 24 65 11 f0    	mov    %edx,0xf0116524
f010037f:	88 81 20 63 11 f0    	mov    %al,-0xfee9ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100385:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010038b:	75 0a                	jne    f0100397 <cons_intr+0x36>
			cons.wpos = 0;
f010038d:	c7 05 24 65 11 f0 00 	movl   $0x0,0xf0116524
f0100394:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100397:	ff d3                	call   *%ebx
f0100399:	83 f8 ff             	cmp    $0xffffffff,%eax
f010039c:	75 ce                	jne    f010036c <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010039e:	83 c4 04             	add    $0x4,%esp
f01003a1:	5b                   	pop    %ebx
f01003a2:	5d                   	pop    %ebp
f01003a3:	c3                   	ret    

f01003a4 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003a4:	55                   	push   %ebp
f01003a5:	89 e5                	mov    %esp,%ebp
f01003a7:	53                   	push   %ebx
f01003a8:	83 ec 04             	sub    $0x4,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f01003ab:	b8 64 00 00 00       	mov    $0x64,%eax
f01003b0:	e8 70 fd ff ff       	call   f0100125 <inb>
	if ((stat & KBS_DIB) == 0)
f01003b5:	a8 01                	test   $0x1,%al
f01003b7:	0f 84 fe 00 00 00    	je     f01004bb <kbd_proc_data+0x117>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003bd:	a8 20                	test   $0x20,%al
f01003bf:	0f 85 fd 00 00 00    	jne    f01004c2 <kbd_proc_data+0x11e>
		return -1;

	data = inb(KBDATAP);
f01003c5:	b8 60 00 00 00       	mov    $0x60,%eax
f01003ca:	e8 56 fd ff ff       	call   f0100125 <inb>

	if (data == 0xE0) {
f01003cf:	3c e0                	cmp    $0xe0,%al
f01003d1:	75 11                	jne    f01003e4 <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f01003d3:	83 0d 00 63 11 f0 40 	orl    $0x40,0xf0116300
		return 0;
f01003da:	b8 00 00 00 00       	mov    $0x0,%eax
f01003df:	e9 e7 00 00 00       	jmp    f01004cb <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f01003e4:	84 c0                	test   %al,%al
f01003e6:	79 38                	jns    f0100420 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003e8:	8b 0d 00 63 11 f0    	mov    0xf0116300,%ecx
f01003ee:	89 cb                	mov    %ecx,%ebx
f01003f0:	83 e3 40             	and    $0x40,%ebx
f01003f3:	89 c2                	mov    %eax,%edx
f01003f5:	83 e2 7f             	and    $0x7f,%edx
f01003f8:	85 db                	test   %ebx,%ebx
f01003fa:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f01003fd:	0f b6 c0             	movzbl %al,%eax
f0100400:	0f b6 80 80 38 10 f0 	movzbl -0xfefc780(%eax),%eax
f0100407:	83 c8 40             	or     $0x40,%eax
f010040a:	0f b6 c0             	movzbl %al,%eax
f010040d:	f7 d0                	not    %eax
f010040f:	21 c8                	and    %ecx,%eax
f0100411:	a3 00 63 11 f0       	mov    %eax,0xf0116300
		return 0;
f0100416:	b8 00 00 00 00       	mov    $0x0,%eax
f010041b:	e9 ab 00 00 00       	jmp    f01004cb <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100420:	8b 15 00 63 11 f0    	mov    0xf0116300,%edx
f0100426:	f6 c2 40             	test   $0x40,%dl
f0100429:	74 0c                	je     f0100437 <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010042b:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f010042e:	83 e2 bf             	and    $0xffffffbf,%edx
f0100431:	89 15 00 63 11 f0    	mov    %edx,0xf0116300
	}

	shift |= shiftcode[data];
f0100437:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010043a:	0f b6 90 80 38 10 f0 	movzbl -0xfefc780(%eax),%edx
f0100441:	0b 15 00 63 11 f0    	or     0xf0116300,%edx
f0100447:	0f b6 88 80 37 10 f0 	movzbl -0xfefc880(%eax),%ecx
f010044e:	31 ca                	xor    %ecx,%edx
f0100450:	89 15 00 63 11 f0    	mov    %edx,0xf0116300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100456:	89 d1                	mov    %edx,%ecx
f0100458:	83 e1 03             	and    $0x3,%ecx
f010045b:	8b 0c 8d 60 37 10 f0 	mov    -0xfefc8a0(,%ecx,4),%ecx
f0100462:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100466:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100469:	f6 c2 08             	test   $0x8,%dl
f010046c:	74 1b                	je     f0100489 <kbd_proc_data+0xe5>
		if ('a' <= c && c <= 'z')
f010046e:	89 d8                	mov    %ebx,%eax
f0100470:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100473:	83 f9 19             	cmp    $0x19,%ecx
f0100476:	77 05                	ja     f010047d <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f0100478:	83 eb 20             	sub    $0x20,%ebx
f010047b:	eb 0c                	jmp    f0100489 <kbd_proc_data+0xe5>
		else if ('A' <= c && c <= 'Z')
f010047d:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100480:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100483:	83 f8 19             	cmp    $0x19,%eax
f0100486:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100489:	f7 d2                	not    %edx
f010048b:	f6 c2 06             	test   $0x6,%dl
f010048e:	75 39                	jne    f01004c9 <kbd_proc_data+0x125>
f0100490:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100496:	75 31                	jne    f01004c9 <kbd_proc_data+0x125>
		cprintf("Rebooting!\n");
f0100498:	83 ec 0c             	sub    $0xc,%esp
f010049b:	68 1c 37 10 f0       	push   $0xf010371c
f01004a0:	e8 e0 22 00 00       	call   f0102785 <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f01004a5:	ba 03 00 00 00       	mov    $0x3,%edx
f01004aa:	b8 92 00 00 00       	mov    $0x92,%eax
f01004af:	e8 79 fc ff ff       	call   f010012d <outb>
f01004b4:	83 c4 10             	add    $0x10,%esp
	}

	return c;
f01004b7:	89 d8                	mov    %ebx,%eax
f01004b9:	eb 10                	jmp    f01004cb <kbd_proc_data+0x127>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004c0:	eb 09                	jmp    f01004cb <kbd_proc_data+0x127>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004c7:	eb 02                	jmp    f01004cb <kbd_proc_data+0x127>
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01004c9:	89 d8                	mov    %ebx,%eax
}
f01004cb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01004ce:	c9                   	leave  
f01004cf:	c3                   	ret    

f01004d0 <cga_putc>:



static void
cga_putc(int c)
{
f01004d0:	55                   	push   %ebp
f01004d1:	89 e5                	mov    %esp,%ebp
f01004d3:	57                   	push   %edi
f01004d4:	56                   	push   %esi
f01004d5:	53                   	push   %ebx
f01004d6:	83 ec 0c             	sub    $0xc,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004d9:	89 c1                	mov    %eax,%ecx
f01004db:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004e1:	89 c2                	mov    %eax,%edx
f01004e3:	80 ce 07             	or     $0x7,%dh
f01004e6:	85 c9                	test   %ecx,%ecx
f01004e8:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f01004eb:	0f b6 d0             	movzbl %al,%edx
f01004ee:	83 fa 09             	cmp    $0x9,%edx
f01004f1:	74 72                	je     f0100565 <cga_putc+0x95>
f01004f3:	83 fa 09             	cmp    $0x9,%edx
f01004f6:	7f 0a                	jg     f0100502 <cga_putc+0x32>
f01004f8:	83 fa 08             	cmp    $0x8,%edx
f01004fb:	74 14                	je     f0100511 <cga_putc+0x41>
f01004fd:	e9 97 00 00 00       	jmp    f0100599 <cga_putc+0xc9>
f0100502:	83 fa 0a             	cmp    $0xa,%edx
f0100505:	74 38                	je     f010053f <cga_putc+0x6f>
f0100507:	83 fa 0d             	cmp    $0xd,%edx
f010050a:	74 3b                	je     f0100547 <cga_putc+0x77>
f010050c:	e9 88 00 00 00       	jmp    f0100599 <cga_putc+0xc9>
	case '\b':
		if (crt_pos > 0) {
f0100511:	0f b7 15 28 65 11 f0 	movzwl 0xf0116528,%edx
f0100518:	66 85 d2             	test   %dx,%dx
f010051b:	0f 84 e4 00 00 00    	je     f0100605 <cga_putc+0x135>
			crt_pos--;
f0100521:	83 ea 01             	sub    $0x1,%edx
f0100524:	66 89 15 28 65 11 f0 	mov    %dx,0xf0116528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010052b:	0f b7 d2             	movzwl %dx,%edx
f010052e:	b0 00                	mov    $0x0,%al
f0100530:	83 c8 20             	or     $0x20,%eax
f0100533:	8b 0d 2c 65 11 f0    	mov    0xf011652c,%ecx
f0100539:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f010053d:	eb 78                	jmp    f01005b7 <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010053f:	66 83 05 28 65 11 f0 	addw   $0x50,0xf0116528
f0100546:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100547:	0f b7 05 28 65 11 f0 	movzwl 0xf0116528,%eax
f010054e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100554:	c1 e8 16             	shr    $0x16,%eax
f0100557:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010055a:	c1 e0 04             	shl    $0x4,%eax
f010055d:	66 a3 28 65 11 f0    	mov    %ax,0xf0116528
		break;
f0100563:	eb 52                	jmp    f01005b7 <cga_putc+0xe7>
	case '\t':
		cons_putc(' ');
f0100565:	b8 20 00 00 00       	mov    $0x20,%eax
f010056a:	e8 da 00 00 00       	call   f0100649 <cons_putc>
		cons_putc(' ');
f010056f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100574:	e8 d0 00 00 00       	call   f0100649 <cons_putc>
		cons_putc(' ');
f0100579:	b8 20 00 00 00       	mov    $0x20,%eax
f010057e:	e8 c6 00 00 00       	call   f0100649 <cons_putc>
		cons_putc(' ');
f0100583:	b8 20 00 00 00       	mov    $0x20,%eax
f0100588:	e8 bc 00 00 00       	call   f0100649 <cons_putc>
		cons_putc(' ');
f010058d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100592:	e8 b2 00 00 00       	call   f0100649 <cons_putc>
		break;
f0100597:	eb 1e                	jmp    f01005b7 <cga_putc+0xe7>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100599:	0f b7 15 28 65 11 f0 	movzwl 0xf0116528,%edx
f01005a0:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005a3:	66 89 0d 28 65 11 f0 	mov    %cx,0xf0116528
f01005aa:	0f b7 d2             	movzwl %dx,%edx
f01005ad:	8b 0d 2c 65 11 f0    	mov    0xf011652c,%ecx
f01005b3:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005b7:	66 81 3d 28 65 11 f0 	cmpw   $0x7cf,0xf0116528
f01005be:	cf 07 
f01005c0:	76 43                	jbe    f0100605 <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005c2:	a1 2c 65 11 f0       	mov    0xf011652c,%eax
f01005c7:	83 ec 04             	sub    $0x4,%esp
f01005ca:	68 00 0f 00 00       	push   $0xf00
f01005cf:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005d5:	52                   	push   %edx
f01005d6:	50                   	push   %eax
f01005d7:	e8 9b 2c 00 00       	call   f0103277 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005dc:	8b 15 2c 65 11 f0    	mov    0xf011652c,%edx
f01005e2:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005e8:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005ee:	83 c4 10             	add    $0x10,%esp
f01005f1:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005f6:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005f9:	39 d0                	cmp    %edx,%eax
f01005fb:	75 f4                	jne    f01005f1 <cga_putc+0x121>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005fd:	66 83 2d 28 65 11 f0 	subw   $0x50,0xf0116528
f0100604:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100605:	8b 3d 30 65 11 f0    	mov    0xf0116530,%edi
f010060b:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100610:	89 f8                	mov    %edi,%eax
f0100612:	e8 16 fb ff ff       	call   f010012d <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f0100617:	0f b7 1d 28 65 11 f0 	movzwl 0xf0116528,%ebx
f010061e:	8d 77 01             	lea    0x1(%edi),%esi
f0100621:	0f b6 d7             	movzbl %bh,%edx
f0100624:	89 f0                	mov    %esi,%eax
f0100626:	e8 02 fb ff ff       	call   f010012d <outb>
	outb(addr_6845, 15);
f010062b:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100630:	89 f8                	mov    %edi,%eax
f0100632:	e8 f6 fa ff ff       	call   f010012d <outb>
	outb(addr_6845 + 1, crt_pos);
f0100637:	0f b6 d3             	movzbl %bl,%edx
f010063a:	89 f0                	mov    %esi,%eax
f010063c:	e8 ec fa ff ff       	call   f010012d <outb>
}
f0100641:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100644:	5b                   	pop    %ebx
f0100645:	5e                   	pop    %esi
f0100646:	5f                   	pop    %edi
f0100647:	5d                   	pop    %ebp
f0100648:	c3                   	ret    

f0100649 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100649:	55                   	push   %ebp
f010064a:	89 e5                	mov    %esp,%ebp
f010064c:	53                   	push   %ebx
f010064d:	83 ec 04             	sub    $0x4,%esp
f0100650:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100652:	e8 36 fb ff ff       	call   f010018d <serial_putc>
	lpt_putc(c);
f0100657:	89 d8                	mov    %ebx,%eax
f0100659:	e8 03 fc ff ff       	call   f0100261 <lpt_putc>
	cga_putc(c);
f010065e:	89 d8                	mov    %ebx,%eax
f0100660:	e8 6b fe ff ff       	call   f01004d0 <cga_putc>
}
f0100665:	83 c4 04             	add    $0x4,%esp
f0100668:	5b                   	pop    %ebx
f0100669:	5d                   	pop    %ebp
f010066a:	c3                   	ret    

f010066b <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f010066b:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f0100672:	74 11                	je     f0100685 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100674:	55                   	push   %ebp
f0100675:	89 e5                	mov    %esp,%ebp
f0100677:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010067a:	b8 66 01 10 f0       	mov    $0xf0100166,%eax
f010067f:	e8 dd fc ff ff       	call   f0100361 <cons_intr>
}
f0100684:	c9                   	leave  
f0100685:	f3 c3                	repz ret 

f0100687 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100687:	55                   	push   %ebp
f0100688:	89 e5                	mov    %esp,%ebp
f010068a:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010068d:	b8 a4 03 10 f0       	mov    $0xf01003a4,%eax
f0100692:	e8 ca fc ff ff       	call   f0100361 <cons_intr>
}
f0100697:	c9                   	leave  
f0100698:	c3                   	ret    

f0100699 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100699:	55                   	push   %ebp
f010069a:	89 e5                	mov    %esp,%ebp
f010069c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010069f:	e8 c7 ff ff ff       	call   f010066b <serial_intr>
	kbd_intr();
f01006a4:	e8 de ff ff ff       	call   f0100687 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01006a9:	a1 20 65 11 f0       	mov    0xf0116520,%eax
f01006ae:	3b 05 24 65 11 f0    	cmp    0xf0116524,%eax
f01006b4:	74 26                	je     f01006dc <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006b6:	8d 50 01             	lea    0x1(%eax),%edx
f01006b9:	89 15 20 65 11 f0    	mov    %edx,0xf0116520
f01006bf:	0f b6 88 20 63 11 f0 	movzbl -0xfee9ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01006c6:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01006c8:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01006ce:	75 11                	jne    f01006e1 <cons_getc+0x48>
			cons.rpos = 0;
f01006d0:	c7 05 20 65 11 f0 00 	movl   $0x0,0xf0116520
f01006d7:	00 00 00 
f01006da:	eb 05                	jmp    f01006e1 <cons_getc+0x48>
		return c;
	}
	return 0;
f01006dc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01006e1:	c9                   	leave  
f01006e2:	c3                   	ret    

f01006e3 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01006e3:	55                   	push   %ebp
f01006e4:	89 e5                	mov    %esp,%ebp
f01006e6:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01006e9:	e8 d0 fb ff ff       	call   f01002be <cga_init>
	kbd_init();
	serial_init();
f01006ee:	e8 d9 fa ff ff       	call   f01001cc <serial_init>

	if (!serial_exists)
f01006f3:	80 3d 34 65 11 f0 00 	cmpb   $0x0,0xf0116534
f01006fa:	75 10                	jne    f010070c <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f01006fc:	83 ec 0c             	sub    $0xc,%esp
f01006ff:	68 28 37 10 f0       	push   $0xf0103728
f0100704:	e8 7c 20 00 00       	call   f0102785 <cprintf>
f0100709:	83 c4 10             	add    $0x10,%esp
}
f010070c:	c9                   	leave  
f010070d:	c3                   	ret    

f010070e <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010070e:	55                   	push   %ebp
f010070f:	89 e5                	mov    %esp,%ebp
f0100711:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100714:	8b 45 08             	mov    0x8(%ebp),%eax
f0100717:	e8 2d ff ff ff       	call   f0100649 <cons_putc>
}
f010071c:	c9                   	leave  
f010071d:	c3                   	ret    

f010071e <getchar>:

int
getchar(void)
{
f010071e:	55                   	push   %ebp
f010071f:	89 e5                	mov    %esp,%ebp
f0100721:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100724:	e8 70 ff ff ff       	call   f0100699 <cons_getc>
f0100729:	85 c0                	test   %eax,%eax
f010072b:	74 f7                	je     f0100724 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010072d:	c9                   	leave  
f010072e:	c3                   	ret    

f010072f <iscons>:

int
iscons(int fdnum)
{
f010072f:	55                   	push   %ebp
f0100730:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100732:	b8 01 00 00 00       	mov    $0x1,%eax
f0100737:	5d                   	pop    %ebp
f0100738:	c3                   	ret    

f0100739 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100739:	55                   	push   %ebp
f010073a:	89 e5                	mov    %esp,%ebp
f010073c:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010073f:	68 80 39 10 f0       	push   $0xf0103980
f0100744:	68 9e 39 10 f0       	push   $0xf010399e
f0100749:	68 a3 39 10 f0       	push   $0xf01039a3
f010074e:	e8 32 20 00 00       	call   f0102785 <cprintf>
f0100753:	83 c4 0c             	add    $0xc,%esp
f0100756:	68 40 3a 10 f0       	push   $0xf0103a40
f010075b:	68 ac 39 10 f0       	push   $0xf01039ac
f0100760:	68 a3 39 10 f0       	push   $0xf01039a3
f0100765:	e8 1b 20 00 00       	call   f0102785 <cprintf>
f010076a:	83 c4 0c             	add    $0xc,%esp
f010076d:	68 b5 39 10 f0       	push   $0xf01039b5
f0100772:	68 c9 39 10 f0       	push   $0xf01039c9
f0100777:	68 a3 39 10 f0       	push   $0xf01039a3
f010077c:	e8 04 20 00 00       	call   f0102785 <cprintf>
	return 0;
}
f0100781:	b8 00 00 00 00       	mov    $0x0,%eax
f0100786:	c9                   	leave  
f0100787:	c3                   	ret    

f0100788 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100788:	55                   	push   %ebp
f0100789:	89 e5                	mov    %esp,%ebp
f010078b:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010078e:	68 d3 39 10 f0       	push   $0xf01039d3
f0100793:	e8 ed 1f 00 00       	call   f0102785 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100798:	83 c4 08             	add    $0x8,%esp
f010079b:	68 0c 00 10 00       	push   $0x10000c
f01007a0:	68 68 3a 10 f0       	push   $0xf0103a68
f01007a5:	e8 db 1f 00 00       	call   f0102785 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007aa:	83 c4 0c             	add    $0xc,%esp
f01007ad:	68 0c 00 10 00       	push   $0x10000c
f01007b2:	68 0c 00 10 f0       	push   $0xf010000c
f01007b7:	68 90 3a 10 f0       	push   $0xf0103a90
f01007bc:	e8 c4 1f 00 00       	call   f0102785 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007c1:	83 c4 0c             	add    $0xc,%esp
f01007c4:	68 b1 36 10 00       	push   $0x1036b1
f01007c9:	68 b1 36 10 f0       	push   $0xf01036b1
f01007ce:	68 b4 3a 10 f0       	push   $0xf0103ab4
f01007d3:	e8 ad 1f 00 00       	call   f0102785 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007d8:	83 c4 0c             	add    $0xc,%esp
f01007db:	68 00 63 11 00       	push   $0x116300
f01007e0:	68 00 63 11 f0       	push   $0xf0116300
f01007e5:	68 d8 3a 10 f0       	push   $0xf0103ad8
f01007ea:	e8 96 1f 00 00       	call   f0102785 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007ef:	83 c4 0c             	add    $0xc,%esp
f01007f2:	68 50 79 11 00       	push   $0x117950
f01007f7:	68 50 79 11 f0       	push   $0xf0117950
f01007fc:	68 fc 3a 10 f0       	push   $0xf0103afc
f0100801:	e8 7f 1f 00 00       	call   f0102785 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100806:	b8 4f 7d 11 f0       	mov    $0xf0117d4f,%eax
f010080b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	83 c4 08             	add    $0x8,%esp
f0100813:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100818:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010081e:	85 c0                	test   %eax,%eax
f0100820:	0f 48 c2             	cmovs  %edx,%eax
f0100823:	c1 f8 0a             	sar    $0xa,%eax
f0100826:	50                   	push   %eax
f0100827:	68 20 3b 10 f0       	push   $0xf0103b20
f010082c:	e8 54 1f 00 00       	call   f0102785 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100831:	b8 00 00 00 00       	mov    $0x0,%eax
f0100836:	c9                   	leave  
f0100837:	c3                   	ret    

f0100838 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100838:	55                   	push   %ebp
f0100839:	89 e5                	mov    %esp,%ebp
f010083b:	57                   	push   %edi
f010083c:	56                   	push   %esi
f010083d:	53                   	push   %ebx
f010083e:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100841:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0x0){
	uint32_t eip=*(uint32_t *)(ebp+4);
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100843:	8d 7d d0             	lea    -0x30(%ebp),%edi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100846:	eb 4a                	jmp    f0100892 <mon_backtrace+0x5a>
	uint32_t eip=*(uint32_t *)(ebp+4);
f0100848:	8b 73 04             	mov    0x4(%ebx),%esi
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
f010084b:	ff 73 18             	pushl  0x18(%ebx)
f010084e:	ff 73 14             	pushl  0x14(%ebx)
f0100851:	ff 73 10             	pushl  0x10(%ebx)
f0100854:	ff 73 0c             	pushl  0xc(%ebx)
f0100857:	ff 73 08             	pushl  0x8(%ebx)
f010085a:	56                   	push   %esi
f010085b:	53                   	push   %ebx
f010085c:	68 4c 3b 10 f0       	push   $0xf0103b4c
f0100861:	e8 1f 1f 00 00       	call   f0102785 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100866:	83 c4 18             	add    $0x18,%esp
f0100869:	57                   	push   %edi
f010086a:	56                   	push   %esi
f010086b:	e8 1f 20 00 00       	call   f010288f <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100870:	83 c4 08             	add    $0x8,%esp
f0100873:	2b 75 e0             	sub    -0x20(%ebp),%esi
f0100876:	56                   	push   %esi
f0100877:	ff 75 d8             	pushl  -0x28(%ebp)
f010087a:	ff 75 dc             	pushl  -0x24(%ebp)
f010087d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100880:	ff 75 d0             	pushl  -0x30(%ebp)
f0100883:	68 ec 39 10 f0       	push   $0xf01039ec
f0100888:	e8 f8 1e 00 00       	call   f0102785 <cprintf>
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
f010088d:	8b 1b                	mov    (%ebx),%ebx
f010088f:	83 c4 20             	add    $0x20,%esp
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100892:	85 db                	test   %ebx,%ebx
f0100894:	75 b2                	jne    f0100848 <mon_backtrace+0x10>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
	}
	return 0;
}
f0100896:	b8 00 00 00 00       	mov    $0x0,%eax
f010089b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010089e:	5b                   	pop    %ebx
f010089f:	5e                   	pop    %esi
f01008a0:	5f                   	pop    %edi
f01008a1:	5d                   	pop    %ebp
f01008a2:	c3                   	ret    

f01008a3 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f01008a3:	55                   	push   %ebp
f01008a4:	89 e5                	mov    %esp,%ebp
f01008a6:	57                   	push   %edi
f01008a7:	56                   	push   %esi
f01008a8:	53                   	push   %ebx
f01008a9:	83 ec 5c             	sub    $0x5c,%esp
f01008ac:	89 c3                	mov    %eax,%ebx
f01008ae:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008b1:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008b8:	be 00 00 00 00       	mov    $0x0,%esi
f01008bd:	eb 0a                	jmp    f01008c9 <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008bf:	c6 03 00             	movb   $0x0,(%ebx)
f01008c2:	89 f7                	mov    %esi,%edi
f01008c4:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008c7:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008c9:	0f b6 03             	movzbl (%ebx),%eax
f01008cc:	84 c0                	test   %al,%al
f01008ce:	74 6d                	je     f010093d <runcmd+0x9a>
f01008d0:	83 ec 08             	sub    $0x8,%esp
f01008d3:	0f be c0             	movsbl %al,%eax
f01008d6:	50                   	push   %eax
f01008d7:	68 03 3a 10 f0       	push   $0xf0103a03
f01008dc:	e8 0b 29 00 00       	call   f01031ec <strchr>
f01008e1:	83 c4 10             	add    $0x10,%esp
f01008e4:	85 c0                	test   %eax,%eax
f01008e6:	75 d7                	jne    f01008bf <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f01008e8:	0f b6 03             	movzbl (%ebx),%eax
f01008eb:	84 c0                	test   %al,%al
f01008ed:	74 4e                	je     f010093d <runcmd+0x9a>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008ef:	83 fe 0f             	cmp    $0xf,%esi
f01008f2:	75 1c                	jne    f0100910 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008f4:	83 ec 08             	sub    $0x8,%esp
f01008f7:	6a 10                	push   $0x10
f01008f9:	68 08 3a 10 f0       	push   $0xf0103a08
f01008fe:	e8 82 1e 00 00       	call   f0102785 <cprintf>
			return 0;
f0100903:	83 c4 10             	add    $0x10,%esp
f0100906:	b8 00 00 00 00       	mov    $0x0,%eax
f010090b:	e9 99 00 00 00       	jmp    f01009a9 <runcmd+0x106>
		}
		argv[argc++] = buf;
f0100910:	8d 7e 01             	lea    0x1(%esi),%edi
f0100913:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100917:	eb 0a                	jmp    f0100923 <runcmd+0x80>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100919:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010091c:	0f b6 03             	movzbl (%ebx),%eax
f010091f:	84 c0                	test   %al,%al
f0100921:	74 a4                	je     f01008c7 <runcmd+0x24>
f0100923:	83 ec 08             	sub    $0x8,%esp
f0100926:	0f be c0             	movsbl %al,%eax
f0100929:	50                   	push   %eax
f010092a:	68 03 3a 10 f0       	push   $0xf0103a03
f010092f:	e8 b8 28 00 00       	call   f01031ec <strchr>
f0100934:	83 c4 10             	add    $0x10,%esp
f0100937:	85 c0                	test   %eax,%eax
f0100939:	74 de                	je     f0100919 <runcmd+0x76>
f010093b:	eb 8a                	jmp    f01008c7 <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f010093d:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100944:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f0100945:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f010094a:	85 f6                	test   %esi,%esi
f010094c:	74 5b                	je     f01009a9 <runcmd+0x106>
f010094e:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100953:	83 ec 08             	sub    $0x8,%esp
f0100956:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100959:	ff 34 85 e0 3b 10 f0 	pushl  -0xfefc420(,%eax,4)
f0100960:	ff 75 a8             	pushl  -0x58(%ebp)
f0100963:	e8 26 28 00 00       	call   f010318e <strcmp>
f0100968:	83 c4 10             	add    $0x10,%esp
f010096b:	85 c0                	test   %eax,%eax
f010096d:	75 1a                	jne    f0100989 <runcmd+0xe6>
			return commands[i].func(argc, argv, tf);
f010096f:	83 ec 04             	sub    $0x4,%esp
f0100972:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100975:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100978:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010097b:	52                   	push   %edx
f010097c:	56                   	push   %esi
f010097d:	ff 14 85 e8 3b 10 f0 	call   *-0xfefc418(,%eax,4)
f0100984:	83 c4 10             	add    $0x10,%esp
f0100987:	eb 20                	jmp    f01009a9 <runcmd+0x106>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100989:	83 c3 01             	add    $0x1,%ebx
f010098c:	83 fb 03             	cmp    $0x3,%ebx
f010098f:	75 c2                	jne    f0100953 <runcmd+0xb0>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100991:	83 ec 08             	sub    $0x8,%esp
f0100994:	ff 75 a8             	pushl  -0x58(%ebp)
f0100997:	68 25 3a 10 f0       	push   $0xf0103a25
f010099c:	e8 e4 1d 00 00       	call   f0102785 <cprintf>
	return 0;
f01009a1:	83 c4 10             	add    $0x10,%esp
f01009a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01009a9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009ac:	5b                   	pop    %ebx
f01009ad:	5e                   	pop    %esi
f01009ae:	5f                   	pop    %edi
f01009af:	5d                   	pop    %ebp
f01009b0:	c3                   	ret    

f01009b1 <monitor>:

void
monitor(struct Trapframe *tf)
{
f01009b1:	55                   	push   %ebp
f01009b2:	89 e5                	mov    %esp,%ebp
f01009b4:	53                   	push   %ebx
f01009b5:	83 ec 10             	sub    $0x10,%esp
f01009b8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009bb:	68 80 3b 10 f0       	push   $0xf0103b80
f01009c0:	e8 c0 1d 00 00       	call   f0102785 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009c5:	c7 04 24 a4 3b 10 f0 	movl   $0xf0103ba4,(%esp)
f01009cc:	e8 b4 1d 00 00       	call   f0102785 <cprintf>
f01009d1:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009d4:	83 ec 0c             	sub    $0xc,%esp
f01009d7:	68 3b 3a 10 f0       	push   $0xf0103a3b
f01009dc:	e8 f1 25 00 00       	call   f0102fd2 <readline>
		if (buf != NULL)
f01009e1:	83 c4 10             	add    $0x10,%esp
f01009e4:	85 c0                	test   %eax,%eax
f01009e6:	74 ec                	je     f01009d4 <monitor+0x23>
			if (runcmd(buf, tf) < 0)
f01009e8:	89 da                	mov    %ebx,%edx
f01009ea:	e8 b4 fe ff ff       	call   f01008a3 <runcmd>
f01009ef:	85 c0                	test   %eax,%eax
f01009f1:	79 e1                	jns    f01009d4 <monitor+0x23>
				break;
	}
}
f01009f3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009f6:	c9                   	leave  
f01009f7:	c3                   	ret    

f01009f8 <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f01009f8:	55                   	push   %ebp
f01009f9:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01009fb:	0f 01 38             	invlpg (%eax)
}
f01009fe:	5d                   	pop    %ebp
f01009ff:	c3                   	ret    

f0100a00 <lcr0>:
	asm volatile("ltr %0" : : "r" (sel));
}

static inline void
lcr0(uint32_t val)
{
f0100a00:	55                   	push   %ebp
f0100a01:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0100a03:	0f 22 c0             	mov    %eax,%cr0
}
f0100a06:	5d                   	pop    %ebp
f0100a07:	c3                   	ret    

f0100a08 <rcr0>:

static inline uint32_t
rcr0(void)
{
f0100a08:	55                   	push   %ebp
f0100a09:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0100a0b:	0f 20 c0             	mov    %cr0,%eax
	return val;
}
f0100a0e:	5d                   	pop    %ebp
f0100a0f:	c3                   	ret    

f0100a10 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0100a10:	55                   	push   %ebp
f0100a11:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100a13:	0f 22 d8             	mov    %eax,%cr3
}
f0100a16:	5d                   	pop    %ebp
f0100a17:	c3                   	ret    

f0100a18 <page2pa>:

void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0100a18:	55                   	push   %ebp
f0100a19:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0100a1b:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100a21:	c1 f8 03             	sar    $0x3,%eax
f0100a24:	c1 e0 0c             	shl    $0xc,%eax
}
f0100a27:	5d                   	pop    %ebp
f0100a28:	c3                   	ret    

f0100a29 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a29:	55                   	push   %ebp
f0100a2a:	89 e5                	mov    %esp,%ebp
f0100a2c:	56                   	push   %esi
f0100a2d:	53                   	push   %ebx
f0100a2e:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a30:	83 ec 0c             	sub    $0xc,%esp
f0100a33:	50                   	push   %eax
f0100a34:	e8 d2 1c 00 00       	call   f010270b <mc146818_read>
f0100a39:	89 c6                	mov    %eax,%esi
f0100a3b:	83 c3 01             	add    $0x1,%ebx
f0100a3e:	89 1c 24             	mov    %ebx,(%esp)
f0100a41:	e8 c5 1c 00 00       	call   f010270b <mc146818_read>
f0100a46:	c1 e0 08             	shl    $0x8,%eax
f0100a49:	09 f0                	or     %esi,%eax
}
f0100a4b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a4e:	5b                   	pop    %ebx
f0100a4f:	5e                   	pop    %esi
f0100a50:	5d                   	pop    %ebp
f0100a51:	c3                   	ret    

f0100a52 <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f0100a52:	55                   	push   %ebp
f0100a53:	89 e5                	mov    %esp,%ebp
f0100a55:	56                   	push   %esi
f0100a56:	53                   	push   %ebx
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100a57:	b8 15 00 00 00       	mov    $0x15,%eax
f0100a5c:	e8 c8 ff ff ff       	call   f0100a29 <nvram_read>
f0100a61:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100a63:	b8 17 00 00 00       	mov    $0x17,%eax
f0100a68:	e8 bc ff ff ff       	call   f0100a29 <nvram_read>
f0100a6d:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100a6f:	b8 34 00 00 00       	mov    $0x34,%eax
f0100a74:	e8 b0 ff ff ff       	call   f0100a29 <nvram_read>
f0100a79:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100a7c:	85 c0                	test   %eax,%eax
f0100a7e:	74 07                	je     f0100a87 <i386_detect_memory+0x35>
		totalmem = 16 * 1024 + ext16mem;
f0100a80:	05 00 40 00 00       	add    $0x4000,%eax
f0100a85:	eb 0b                	jmp    f0100a92 <i386_detect_memory+0x40>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100a87:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100a8d:	85 f6                	test   %esi,%esi
f0100a8f:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100a92:	89 c2                	mov    %eax,%edx
f0100a94:	c1 ea 02             	shr    $0x2,%edx
f0100a97:	89 15 44 79 11 f0    	mov    %edx,0xf0117944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100a9d:	89 c2                	mov    %eax,%edx
f0100a9f:	29 da                	sub    %ebx,%edx
f0100aa1:	52                   	push   %edx
f0100aa2:	53                   	push   %ebx
f0100aa3:	50                   	push   %eax
f0100aa4:	68 04 3c 10 f0       	push   $0xf0103c04
f0100aa9:	e8 d7 1c 00 00       	call   f0102785 <cprintf>
		totalmem, basemem, totalmem - basemem);
}
f0100aae:	83 c4 10             	add    $0x10,%esp
f0100ab1:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ab4:	5b                   	pop    %ebx
f0100ab5:	5e                   	pop    %esi
f0100ab6:	5d                   	pop    %ebp
f0100ab7:	c3                   	ret    

f0100ab8 <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100ab8:	55                   	push   %ebp
f0100ab9:	89 e5                	mov    %esp,%ebp
f0100abb:	53                   	push   %ebx
f0100abc:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0100abf:	89 cb                	mov    %ecx,%ebx
f0100ac1:	c1 eb 0c             	shr    $0xc,%ebx
f0100ac4:	3b 1d 44 79 11 f0    	cmp    0xf0117944,%ebx
f0100aca:	72 0d                	jb     f0100ad9 <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100acc:	51                   	push   %ecx
f0100acd:	68 40 3c 10 f0       	push   $0xf0103c40
f0100ad2:	52                   	push   %edx
f0100ad3:	50                   	push   %eax
f0100ad4:	e8 bb f5 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100ad9:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100adf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ae2:	c9                   	leave  
f0100ae3:	c3                   	ret    

f0100ae4 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100ae4:	55                   	push   %ebp
f0100ae5:	89 e5                	mov    %esp,%ebp
f0100ae7:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100aea:	e8 29 ff ff ff       	call   f0100a18 <page2pa>
f0100aef:	89 c1                	mov    %eax,%ecx
f0100af1:	ba 54 00 00 00       	mov    $0x54,%edx
f0100af6:	b8 84 43 10 f0       	mov    $0xf0104384,%eax
f0100afb:	e8 b8 ff ff ff       	call   f0100ab8 <_kaddr>
}
f0100b00:	c9                   	leave  
f0100b01:	c3                   	ret    

f0100b02 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100b02:	89 d1                	mov    %edx,%ecx
f0100b04:	c1 e9 16             	shr    $0x16,%ecx
f0100b07:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
f0100b0a:	f6 c1 01             	test   $0x1,%cl
f0100b0d:	74 57                	je     f0100b66 <check_va2pa+0x64>
		return ~0;
	if (*pgdir & PTE_PS)
f0100b0f:	f6 c1 80             	test   $0x80,%cl
f0100b12:	74 10                	je     f0100b24 <check_va2pa+0x22>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
f0100b14:	89 d0                	mov    %edx,%eax
f0100b16:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100b1b:	81 e1 00 00 c0 ff    	and    $0xffc00000,%ecx
f0100b21:	09 c8                	or     %ecx,%eax
f0100b23:	c3                   	ret    
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b24:	55                   	push   %ebp
f0100b25:	89 e5                	mov    %esp,%ebp
f0100b27:	53                   	push   %ebx
f0100b28:	83 ec 04             	sub    $0x4,%esp
f0100b2b:	89 d3                	mov    %edx,%ebx
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	if (*pgdir & PTE_PS)
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b2d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b33:	ba cd 02 00 00       	mov    $0x2cd,%edx
f0100b38:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0100b3d:	e8 76 ff ff ff       	call   f0100ab8 <_kaddr>
	if (!(p[PTX(va)] & PTE_P))
f0100b42:	c1 eb 0c             	shr    $0xc,%ebx
f0100b45:	89 da                	mov    %ebx,%edx
f0100b47:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b4d:	8b 04 90             	mov    (%eax,%edx,4),%eax
f0100b50:	89 c2                	mov    %eax,%edx
f0100b52:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b55:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b5a:	85 d2                	test   %edx,%edx
f0100b5c:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
f0100b61:	0f 44 c1             	cmove  %ecx,%eax
f0100b64:	eb 06                	jmp    f0100b6c <check_va2pa+0x6a>
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b6b:	c3                   	ret    
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b6c:	83 c4 04             	add    $0x4,%esp
f0100b6f:	5b                   	pop    %ebx
f0100b70:	5d                   	pop    %ebp
f0100b71:	c3                   	ret    

f0100b72 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b72:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100b78:	77 13                	ja     f0100b8d <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100b7a:	55                   	push   %ebp
f0100b7b:	89 e5                	mov    %esp,%ebp
f0100b7d:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b80:	51                   	push   %ecx
f0100b81:	68 64 3c 10 f0       	push   $0xf0103c64
f0100b86:	52                   	push   %edx
f0100b87:	50                   	push   %eax
f0100b88:	e8 07 f5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100b8d:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100b93:	c3                   	ret    

f0100b94 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b94:	83 3d 38 65 11 f0 00 	cmpl   $0x0,0xf0116538
f0100b9b:	75 11                	jne    f0100bae <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b9d:	ba 4f 89 11 f0       	mov    $0xf011894f,%edx
f0100ba2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ba8:	89 15 38 65 11 f0    	mov    %edx,0xf0116538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100bae:	85 c0                	test   %eax,%eax
f0100bb0:	75 06                	jne    f0100bb8 <boot_alloc+0x24>
f0100bb2:	a1 38 65 11 f0       	mov    0xf0116538,%eax
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
	return (void*) result;
}
f0100bb7:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100bb8:	55                   	push   %ebp
f0100bb9:	89 e5                	mov    %esp,%ebp
f0100bbb:	53                   	push   %ebx
f0100bbc:	83 ec 04             	sub    $0x4,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100bbf:	8b 1d 38 65 11 f0    	mov    0xf0116538,%ebx
	nextfree += ROUNDUP(n,PGSIZE);
f0100bc5:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f0100bcb:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100bd1:	01 d9                	add    %ebx,%ecx
f0100bd3:	89 0d 38 65 11 f0    	mov    %ecx,0xf0116538
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
f0100bd9:	ba 6d 00 00 00       	mov    $0x6d,%edx
f0100bde:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0100be3:	e8 8a ff ff ff       	call   f0100b72 <_paddr>
f0100be8:	8b 15 44 79 11 f0    	mov    0xf0117944,%edx
f0100bee:	c1 e2 0c             	shl    $0xc,%edx
f0100bf1:	39 d0                	cmp    %edx,%eax
f0100bf3:	76 14                	jbe    f0100c09 <boot_alloc+0x75>
f0100bf5:	83 ec 04             	sub    $0x4,%esp
f0100bf8:	68 9e 43 10 f0       	push   $0xf010439e
f0100bfd:	6a 6d                	push   $0x6d
f0100bff:	68 92 43 10 f0       	push   $0xf0104392
f0100c04:	e8 8b f4 ff ff       	call   f0100094 <_panic>
	return (void*) result;
f0100c09:	89 d8                	mov    %ebx,%eax
}
f0100c0b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100c0e:	c9                   	leave  
f0100c0f:	c3                   	ret    

f0100c10 <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100c10:	55                   	push   %ebp
f0100c11:	89 e5                	mov    %esp,%ebp
f0100c13:	57                   	push   %edi
f0100c14:	56                   	push   %esi
f0100c15:	53                   	push   %ebx
f0100c16:	83 ec 1c             	sub    $0x1c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100c19:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100c1f:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100c24:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c27:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100c2e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c33:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c36:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
f0100c3b:	89 45 e0             	mov    %eax,-0x20(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100c3e:	be 00 00 00 00       	mov    $0x0,%esi
f0100c43:	eb 46                	jmp    f0100c8b <check_kern_pgdir+0x7b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c45:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0100c4b:	89 d8                	mov    %ebx,%eax
f0100c4d:	e8 b0 fe ff ff       	call   f0100b02 <check_va2pa>
f0100c52:	89 c7                	mov    %eax,%edi
f0100c54:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100c57:	ba 9e 02 00 00       	mov    $0x29e,%edx
f0100c5c:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0100c61:	e8 0c ff ff ff       	call   f0100b72 <_paddr>
f0100c66:	01 f0                	add    %esi,%eax
f0100c68:	39 c7                	cmp    %eax,%edi
f0100c6a:	74 19                	je     f0100c85 <check_kern_pgdir+0x75>
f0100c6c:	68 88 3c 10 f0       	push   $0xf0103c88
f0100c71:	68 b1 43 10 f0       	push   $0xf01043b1
f0100c76:	68 9e 02 00 00       	push   $0x29e
f0100c7b:	68 92 43 10 f0       	push   $0xf0104392
f0100c80:	e8 0f f4 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100c85:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100c8b:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100c8e:	72 b5                	jb     f0100c45 <check_kern_pgdir+0x35>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100c90:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100c93:	c1 e7 0c             	shl    $0xc,%edi
f0100c96:	be 00 00 00 00       	mov    $0x0,%esi
f0100c9b:	eb 30                	jmp    f0100ccd <check_kern_pgdir+0xbd>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100c9d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0100ca3:	89 d8                	mov    %ebx,%eax
f0100ca5:	e8 58 fe ff ff       	call   f0100b02 <check_va2pa>
f0100caa:	39 c6                	cmp    %eax,%esi
f0100cac:	74 19                	je     f0100cc7 <check_kern_pgdir+0xb7>
f0100cae:	68 bc 3c 10 f0       	push   $0xf0103cbc
f0100cb3:	68 b1 43 10 f0       	push   $0xf01043b1
f0100cb8:	68 a3 02 00 00       	push   $0x2a3
f0100cbd:	68 92 43 10 f0       	push   $0xf0104392
f0100cc2:	e8 cd f3 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100cc7:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100ccd:	39 fe                	cmp    %edi,%esi
f0100ccf:	72 cc                	jb     f0100c9d <check_kern_pgdir+0x8d>
f0100cd1:	be 00 00 00 00       	mov    $0x0,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0100cd6:	8d 96 00 80 ff ef    	lea    -0x10008000(%esi),%edx
f0100cdc:	89 d8                	mov    %ebx,%eax
f0100cde:	e8 1f fe ff ff       	call   f0100b02 <check_va2pa>
f0100ce3:	89 c7                	mov    %eax,%edi
f0100ce5:	b9 00 d0 10 f0       	mov    $0xf010d000,%ecx
f0100cea:	ba a7 02 00 00       	mov    $0x2a7,%edx
f0100cef:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0100cf4:	e8 79 fe ff ff       	call   f0100b72 <_paddr>
f0100cf9:	01 f0                	add    %esi,%eax
f0100cfb:	39 c7                	cmp    %eax,%edi
f0100cfd:	74 19                	je     f0100d18 <check_kern_pgdir+0x108>
f0100cff:	68 e4 3c 10 f0       	push   $0xf0103ce4
f0100d04:	68 b1 43 10 f0       	push   $0xf01043b1
f0100d09:	68 a7 02 00 00       	push   $0x2a7
f0100d0e:	68 92 43 10 f0       	push   $0xf0104392
f0100d13:	e8 7c f3 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100d18:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d1e:	81 fe 00 80 00 00    	cmp    $0x8000,%esi
f0100d24:	75 b0                	jne    f0100cd6 <check_kern_pgdir+0xc6>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0100d26:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0100d2b:	89 d8                	mov    %ebx,%eax
f0100d2d:	e8 d0 fd ff ff       	call   f0100b02 <check_va2pa>
f0100d32:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100d35:	74 51                	je     f0100d88 <check_kern_pgdir+0x178>
f0100d37:	68 2c 3d 10 f0       	push   $0xf0103d2c
f0100d3c:	68 b1 43 10 f0       	push   $0xf01043b1
f0100d41:	68 a8 02 00 00       	push   $0x2a8
f0100d46:	68 92 43 10 f0       	push   $0xf0104392
f0100d4b:	e8 44 f3 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100d50:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0100d55:	72 36                	jb     f0100d8d <check_kern_pgdir+0x17d>
f0100d57:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0100d5c:	76 07                	jbe    f0100d65 <check_kern_pgdir+0x155>
f0100d5e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100d63:	75 28                	jne    f0100d8d <check_kern_pgdir+0x17d>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0100d65:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0100d69:	0f 85 83 00 00 00    	jne    f0100df2 <check_kern_pgdir+0x1e2>
f0100d6f:	68 c6 43 10 f0       	push   $0xf01043c6
f0100d74:	68 b1 43 10 f0       	push   $0xf01043b1
f0100d79:	68 b0 02 00 00       	push   $0x2b0
f0100d7e:	68 92 43 10 f0       	push   $0xf0104392
f0100d83:	e8 0c f3 ff ff       	call   f0100094 <_panic>
f0100d88:	b8 00 00 00 00       	mov    $0x0,%eax
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100d8d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100d92:	76 3f                	jbe    f0100dd3 <check_kern_pgdir+0x1c3>
				assert(pgdir[i] & PTE_P);
f0100d94:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0100d97:	f6 c2 01             	test   $0x1,%dl
f0100d9a:	75 19                	jne    f0100db5 <check_kern_pgdir+0x1a5>
f0100d9c:	68 c6 43 10 f0       	push   $0xf01043c6
f0100da1:	68 b1 43 10 f0       	push   $0xf01043b1
f0100da6:	68 b4 02 00 00       	push   $0x2b4
f0100dab:	68 92 43 10 f0       	push   $0xf0104392
f0100db0:	e8 df f2 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0100db5:	f6 c2 02             	test   $0x2,%dl
f0100db8:	75 38                	jne    f0100df2 <check_kern_pgdir+0x1e2>
f0100dba:	68 d7 43 10 f0       	push   $0xf01043d7
f0100dbf:	68 b1 43 10 f0       	push   $0xf01043b1
f0100dc4:	68 b5 02 00 00       	push   $0x2b5
f0100dc9:	68 92 43 10 f0       	push   $0xf0104392
f0100dce:	e8 c1 f2 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0100dd3:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100dd7:	74 19                	je     f0100df2 <check_kern_pgdir+0x1e2>
f0100dd9:	68 e8 43 10 f0       	push   $0xf01043e8
f0100dde:	68 b1 43 10 f0       	push   $0xf01043b1
f0100de3:	68 b7 02 00 00       	push   $0x2b7
f0100de8:	68 92 43 10 f0       	push   $0xf0104392
f0100ded:	e8 a2 f2 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0100df2:	83 c0 01             	add    $0x1,%eax
f0100df5:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0100dfa:	0f 86 50 ff ff ff    	jbe    f0100d50 <check_kern_pgdir+0x140>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0100e00:	83 ec 0c             	sub    $0xc,%esp
f0100e03:	68 5c 3d 10 f0       	push   $0xf0103d5c
f0100e08:	e8 78 19 00 00       	call   f0102785 <cprintf>
}
f0100e0d:	83 c4 10             	add    $0x10,%esp
f0100e10:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e13:	5b                   	pop    %ebx
f0100e14:	5e                   	pop    %esi
f0100e15:	5f                   	pop    %edi
f0100e16:	5d                   	pop    %ebp
f0100e17:	c3                   	ret    

f0100e18 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100e18:	55                   	push   %ebp
f0100e19:	89 e5                	mov    %esp,%ebp
f0100e1b:	57                   	push   %edi
f0100e1c:	56                   	push   %esi
f0100e1d:	53                   	push   %ebx
f0100e1e:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e21:	84 c0                	test   %al,%al
f0100e23:	0f 85 35 02 00 00    	jne    f010105e <check_page_free_list+0x246>
f0100e29:	e9 43 02 00 00       	jmp    f0101071 <check_page_free_list+0x259>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100e2e:	83 ec 04             	sub    $0x4,%esp
f0100e31:	68 7c 3d 10 f0       	push   $0xf0103d7c
f0100e36:	68 0e 02 00 00       	push   $0x20e
f0100e3b:	68 92 43 10 f0       	push   $0xf0104392
f0100e40:	e8 4f f2 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e45:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100e48:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e4b:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100e4e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e51:	89 d8                	mov    %ebx,%eax
f0100e53:	e8 c0 fb ff ff       	call   f0100a18 <page2pa>
f0100e58:	c1 e8 16             	shr    $0x16,%eax
f0100e5b:	85 c0                	test   %eax,%eax
f0100e5d:	0f 95 c0             	setne  %al
f0100e60:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100e63:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f0100e67:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100e69:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e6d:	8b 1b                	mov    (%ebx),%ebx
f0100e6f:	85 db                	test   %ebx,%ebx
f0100e71:	75 de                	jne    f0100e51 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100e73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e76:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e7c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e7f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e82:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100e84:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e87:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e8c:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e91:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0100e97:	eb 2d                	jmp    f0100ec6 <check_page_free_list+0xae>
		if (PDX(page2pa(pp)) < pdx_limit)
f0100e99:	89 d8                	mov    %ebx,%eax
f0100e9b:	e8 78 fb ff ff       	call   f0100a18 <page2pa>
f0100ea0:	c1 e8 16             	shr    $0x16,%eax
f0100ea3:	39 f0                	cmp    %esi,%eax
f0100ea5:	73 1d                	jae    f0100ec4 <check_page_free_list+0xac>
			memset(page2kva(pp), 0x97, 128);
f0100ea7:	89 d8                	mov    %ebx,%eax
f0100ea9:	e8 36 fc ff ff       	call   f0100ae4 <page2kva>
f0100eae:	83 ec 04             	sub    $0x4,%esp
f0100eb1:	68 80 00 00 00       	push   $0x80
f0100eb6:	68 97 00 00 00       	push   $0x97
f0100ebb:	50                   	push   %eax
f0100ebc:	e8 68 23 00 00       	call   f0103229 <memset>
f0100ec1:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ec4:	8b 1b                	mov    (%ebx),%ebx
f0100ec6:	85 db                	test   %ebx,%ebx
f0100ec8:	75 cf                	jne    f0100e99 <check_page_free_list+0x81>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100eca:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ecf:	e8 c0 fc ff ff       	call   f0100b94 <boot_alloc>
f0100ed4:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ed7:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100edd:	8b 35 4c 79 11 f0    	mov    0xf011794c,%esi
		assert(pp < pages + npages);
f0100ee3:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100ee8:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0100eeb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100eee:	89 75 d0             	mov    %esi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ef1:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100ef8:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100efd:	e9 18 01 00 00       	jmp    f010101a <check_page_free_list+0x202>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f02:	39 f3                	cmp    %esi,%ebx
f0100f04:	73 19                	jae    f0100f1f <check_page_free_list+0x107>
f0100f06:	68 f6 43 10 f0       	push   $0xf01043f6
f0100f0b:	68 b1 43 10 f0       	push   $0xf01043b1
f0100f10:	68 28 02 00 00       	push   $0x228
f0100f15:	68 92 43 10 f0       	push   $0xf0104392
f0100f1a:	e8 75 f1 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100f1f:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100f22:	72 19                	jb     f0100f3d <check_page_free_list+0x125>
f0100f24:	68 02 44 10 f0       	push   $0xf0104402
f0100f29:	68 b1 43 10 f0       	push   $0xf01043b1
f0100f2e:	68 29 02 00 00       	push   $0x229
f0100f33:	68 92 43 10 f0       	push   $0xf0104392
f0100f38:	e8 57 f1 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f3d:	89 d8                	mov    %ebx,%eax
f0100f3f:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100f42:	a8 07                	test   $0x7,%al
f0100f44:	74 19                	je     f0100f5f <check_page_free_list+0x147>
f0100f46:	68 a0 3d 10 f0       	push   $0xf0103da0
f0100f4b:	68 b1 43 10 f0       	push   $0xf01043b1
f0100f50:	68 2a 02 00 00       	push   $0x22a
f0100f55:	68 92 43 10 f0       	push   $0xf0104392
f0100f5a:	e8 35 f1 ff ff       	call   f0100094 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100f5f:	89 d8                	mov    %ebx,%eax
f0100f61:	e8 b2 fa ff ff       	call   f0100a18 <page2pa>
f0100f66:	85 c0                	test   %eax,%eax
f0100f68:	75 19                	jne    f0100f83 <check_page_free_list+0x16b>
f0100f6a:	68 16 44 10 f0       	push   $0xf0104416
f0100f6f:	68 b1 43 10 f0       	push   $0xf01043b1
f0100f74:	68 2d 02 00 00       	push   $0x22d
f0100f79:	68 92 43 10 f0       	push   $0xf0104392
f0100f7e:	e8 11 f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f83:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f88:	75 19                	jne    f0100fa3 <check_page_free_list+0x18b>
f0100f8a:	68 27 44 10 f0       	push   $0xf0104427
f0100f8f:	68 b1 43 10 f0       	push   $0xf01043b1
f0100f94:	68 2e 02 00 00       	push   $0x22e
f0100f99:	68 92 43 10 f0       	push   $0xf0104392
f0100f9e:	e8 f1 f0 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100fa3:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100fa8:	75 19                	jne    f0100fc3 <check_page_free_list+0x1ab>
f0100faa:	68 d4 3d 10 f0       	push   $0xf0103dd4
f0100faf:	68 b1 43 10 f0       	push   $0xf01043b1
f0100fb4:	68 2f 02 00 00       	push   $0x22f
f0100fb9:	68 92 43 10 f0       	push   $0xf0104392
f0100fbe:	e8 d1 f0 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100fc3:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100fc8:	75 19                	jne    f0100fe3 <check_page_free_list+0x1cb>
f0100fca:	68 40 44 10 f0       	push   $0xf0104440
f0100fcf:	68 b1 43 10 f0       	push   $0xf01043b1
f0100fd4:	68 30 02 00 00       	push   $0x230
f0100fd9:	68 92 43 10 f0       	push   $0xf0104392
f0100fde:	e8 b1 f0 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fe3:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100fe8:	76 25                	jbe    f010100f <check_page_free_list+0x1f7>
f0100fea:	89 d8                	mov    %ebx,%eax
f0100fec:	e8 f3 fa ff ff       	call   f0100ae4 <page2kva>
f0100ff1:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100ff4:	76 1e                	jbe    f0101014 <check_page_free_list+0x1fc>
f0100ff6:	68 f8 3d 10 f0       	push   $0xf0103df8
f0100ffb:	68 b1 43 10 f0       	push   $0xf01043b1
f0101000:	68 31 02 00 00       	push   $0x231
f0101005:	68 92 43 10 f0       	push   $0xf0104392
f010100a:	e8 85 f0 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f010100f:	83 c7 01             	add    $0x1,%edi
f0101012:	eb 04                	jmp    f0101018 <check_page_free_list+0x200>
		else
			++nfree_extmem;
f0101014:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101018:	8b 1b                	mov    (%ebx),%ebx
f010101a:	85 db                	test   %ebx,%ebx
f010101c:	0f 85 e0 fe ff ff    	jne    f0100f02 <check_page_free_list+0xea>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0101022:	85 ff                	test   %edi,%edi
f0101024:	7f 19                	jg     f010103f <check_page_free_list+0x227>
f0101026:	68 5a 44 10 f0       	push   $0xf010445a
f010102b:	68 b1 43 10 f0       	push   $0xf01043b1
f0101030:	68 39 02 00 00       	push   $0x239
f0101035:	68 92 43 10 f0       	push   $0xf0104392
f010103a:	e8 55 f0 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f010103f:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0101043:	7f 43                	jg     f0101088 <check_page_free_list+0x270>
f0101045:	68 6c 44 10 f0       	push   $0xf010446c
f010104a:	68 b1 43 10 f0       	push   $0xf01043b1
f010104f:	68 3a 02 00 00       	push   $0x23a
f0101054:	68 92 43 10 f0       	push   $0xf0104392
f0101059:	e8 36 f0 ff ff       	call   f0100094 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f010105e:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0101064:	85 db                	test   %ebx,%ebx
f0101066:	0f 85 d9 fd ff ff    	jne    f0100e45 <check_page_free_list+0x2d>
f010106c:	e9 bd fd ff ff       	jmp    f0100e2e <check_page_free_list+0x16>
f0101071:	83 3d 3c 65 11 f0 00 	cmpl   $0x0,0xf011653c
f0101078:	0f 84 b0 fd ff ff    	je     f0100e2e <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010107e:	be 00 04 00 00       	mov    $0x400,%esi
f0101083:	e9 09 fe ff ff       	jmp    f0100e91 <check_page_free_list+0x79>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0101088:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010108b:	5b                   	pop    %ebx
f010108c:	5e                   	pop    %esi
f010108d:	5f                   	pop    %edi
f010108e:	5d                   	pop    %ebp
f010108f:	c3                   	ret    

f0101090 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages){
f0101090:	c1 e8 0c             	shr    $0xc,%eax
f0101093:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f0101099:	72 38                	jb     f01010d3 <pa2page+0x43>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f010109b:	55                   	push   %ebp
f010109c:	89 e5                	mov    %esp,%ebp
f010109e:	83 ec 10             	sub    $0x10,%esp
	if (PGNUM(pa) >= npages){
		cprintf("PGNUM: %d\n",PGNUM(pa));
f01010a1:	50                   	push   %eax
f01010a2:	68 7d 44 10 f0       	push   $0xf010447d
f01010a7:	e8 d9 16 00 00       	call   f0102785 <cprintf>
		cprintf("npages %d\n",npages);
f01010ac:	83 c4 08             	add    $0x8,%esp
f01010af:	ff 35 44 79 11 f0    	pushl  0xf0117944
f01010b5:	68 88 44 10 f0       	push   $0xf0104488
f01010ba:	e8 c6 16 00 00       	call   f0102785 <cprintf>
		panic("pa2page called with invalid pa\n");}
f01010bf:	83 c4 0c             	add    $0xc,%esp
f01010c2:	68 40 3e 10 f0       	push   $0xf0103e40
f01010c7:	6a 4d                	push   $0x4d
f01010c9:	68 84 43 10 f0       	push   $0xf0104384
f01010ce:	e8 c1 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01010d3:	8b 15 4c 79 11 f0    	mov    0xf011794c,%edx
f01010d9:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01010dc:	c3                   	ret    

f01010dd <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01010dd:	55                   	push   %ebp
f01010de:	89 e5                	mov    %esp,%ebp
f01010e0:	56                   	push   %esi
f01010e1:	53                   	push   %ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f01010e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01010e7:	e8 a8 fa ff ff       	call   f0100b94 <boot_alloc>
f01010ec:	89 c1                	mov    %eax,%ecx
f01010ee:	ba 07 01 00 00       	mov    $0x107,%edx
f01010f3:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f01010f8:	e8 75 fa ff ff       	call   f0100b72 <_paddr>
f01010fd:	c1 e8 0c             	shr    $0xc,%eax
f0101100:	8b 35 3c 65 11 f0    	mov    0xf011653c,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101106:	b9 00 00 00 00       	mov    $0x0,%ecx
f010110b:	ba 01 00 00 00       	mov    $0x1,%edx
f0101110:	eb 33                	jmp    f0101145 <page_init+0x68>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f0101112:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0101118:	76 04                	jbe    f010111e <page_init+0x41>
f010111a:	39 c2                	cmp    %eax,%edx
f010111c:	72 24                	jb     f0101142 <page_init+0x65>
		pages[i].pp_ref = 0;
f010111e:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0101125:	89 cb                	mov    %ecx,%ebx
f0101127:	03 1d 4c 79 11 f0    	add    0xf011794c,%ebx
f010112d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0101133:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f0101135:	89 ce                	mov    %ecx,%esi
f0101137:	03 35 4c 79 11 f0    	add    0xf011794c,%esi
f010113d:	b9 01 00 00 00       	mov    $0x1,%ecx
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101142:	83 c2 01             	add    $0x1,%edx
f0101145:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f010114b:	72 c5                	jb     f0101112 <page_init+0x35>
f010114d:	84 c9                	test   %cl,%cl
f010114f:	74 06                	je     f0101157 <page_init+0x7a>
f0101151:	89 35 3c 65 11 f0    	mov    %esi,0xf011653c
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0101157:	5b                   	pop    %ebx
f0101158:	5e                   	pop    %esi
f0101159:	5d                   	pop    %ebp
f010115a:	c3                   	ret    

f010115b <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f010115b:	55                   	push   %ebp
f010115c:	89 e5                	mov    %esp,%ebp
f010115e:	53                   	push   %ebx
f010115f:	83 ec 04             	sub    $0x4,%esp
f0101162:	8b 1d 3c 65 11 f0    	mov    0xf011653c,%ebx
f0101168:	85 db                	test   %ebx,%ebx
f010116a:	74 2d                	je     f0101199 <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f010116c:	8b 03                	mov    (%ebx),%eax
f010116e:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
	pag->pp_link = NULL;
f0101173:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f0101179:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010117d:	74 1a                	je     f0101199 <page_alloc+0x3e>
f010117f:	89 d8                	mov    %ebx,%eax
f0101181:	e8 5e f9 ff ff       	call   f0100ae4 <page2kva>
f0101186:	83 ec 04             	sub    $0x4,%esp
f0101189:	68 00 10 00 00       	push   $0x1000
f010118e:	6a 00                	push   $0x0
f0101190:	50                   	push   %eax
f0101191:	e8 93 20 00 00       	call   f0103229 <memset>
f0101196:	83 c4 10             	add    $0x10,%esp
	return pag;
}
f0101199:	89 d8                	mov    %ebx,%eax
f010119b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010119e:	c9                   	leave  
f010119f:	c3                   	ret    

f01011a0 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01011a0:	55                   	push   %ebp
f01011a1:	89 e5                	mov    %esp,%ebp
f01011a3:	83 ec 08             	sub    $0x8,%esp
f01011a6:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f01011a9:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01011ae:	74 17                	je     f01011c7 <page_free+0x27>
f01011b0:	83 ec 04             	sub    $0x4,%esp
f01011b3:	68 93 44 10 f0       	push   $0xf0104493
f01011b8:	68 30 01 00 00       	push   $0x130
f01011bd:	68 92 43 10 f0       	push   $0xf0104392
f01011c2:	e8 cd ee ff ff       	call   f0100094 <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");
f01011c7:	83 38 00             	cmpl   $0x0,(%eax)
f01011ca:	74 17                	je     f01011e3 <page_free+0x43>
f01011cc:	83 ec 04             	sub    $0x4,%esp
f01011cf:	68 60 3e 10 f0       	push   $0xf0103e60
f01011d4:	68 31 01 00 00       	push   $0x131
f01011d9:	68 92 43 10 f0       	push   $0xf0104392
f01011de:	e8 b1 ee ff ff       	call   f0100094 <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f01011e3:	8b 15 3c 65 11 f0    	mov    0xf011653c,%edx
f01011e9:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f01011eb:	a3 3c 65 11 f0       	mov    %eax,0xf011653c
}
f01011f0:	c9                   	leave  
f01011f1:	c3                   	ret    

f01011f2 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f01011f2:	55                   	push   %ebp
f01011f3:	89 e5                	mov    %esp,%ebp
f01011f5:	57                   	push   %edi
f01011f6:	56                   	push   %esi
f01011f7:	53                   	push   %ebx
f01011f8:	83 ec 1c             	sub    $0x1c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01011fb:	83 3d 4c 79 11 f0 00 	cmpl   $0x0,0xf011794c
f0101202:	75 17                	jne    f010121b <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f0101204:	83 ec 04             	sub    $0x4,%esp
f0101207:	68 a7 44 10 f0       	push   $0xf01044a7
f010120c:	68 4b 02 00 00       	push   $0x24b
f0101211:	68 92 43 10 f0       	push   $0xf0104392
f0101216:	e8 79 ee ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010121b:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101220:	be 00 00 00 00       	mov    $0x0,%esi
f0101225:	eb 05                	jmp    f010122c <check_page_alloc+0x3a>
		++nfree;
f0101227:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010122a:	8b 00                	mov    (%eax),%eax
f010122c:	85 c0                	test   %eax,%eax
f010122e:	75 f7                	jne    f0101227 <check_page_alloc+0x35>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101230:	83 ec 0c             	sub    $0xc,%esp
f0101233:	6a 00                	push   $0x0
f0101235:	e8 21 ff ff ff       	call   f010115b <page_alloc>
f010123a:	89 c7                	mov    %eax,%edi
f010123c:	83 c4 10             	add    $0x10,%esp
f010123f:	85 c0                	test   %eax,%eax
f0101241:	75 19                	jne    f010125c <check_page_alloc+0x6a>
f0101243:	68 c2 44 10 f0       	push   $0xf01044c2
f0101248:	68 b1 43 10 f0       	push   $0xf01043b1
f010124d:	68 53 02 00 00       	push   $0x253
f0101252:	68 92 43 10 f0       	push   $0xf0104392
f0101257:	e8 38 ee ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010125c:	83 ec 0c             	sub    $0xc,%esp
f010125f:	6a 00                	push   $0x0
f0101261:	e8 f5 fe ff ff       	call   f010115b <page_alloc>
f0101266:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101269:	83 c4 10             	add    $0x10,%esp
f010126c:	85 c0                	test   %eax,%eax
f010126e:	75 19                	jne    f0101289 <check_page_alloc+0x97>
f0101270:	68 d8 44 10 f0       	push   $0xf01044d8
f0101275:	68 b1 43 10 f0       	push   $0xf01043b1
f010127a:	68 54 02 00 00       	push   $0x254
f010127f:	68 92 43 10 f0       	push   $0xf0104392
f0101284:	e8 0b ee ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101289:	83 ec 0c             	sub    $0xc,%esp
f010128c:	6a 00                	push   $0x0
f010128e:	e8 c8 fe ff ff       	call   f010115b <page_alloc>
f0101293:	89 c3                	mov    %eax,%ebx
f0101295:	83 c4 10             	add    $0x10,%esp
f0101298:	85 c0                	test   %eax,%eax
f010129a:	75 19                	jne    f01012b5 <check_page_alloc+0xc3>
f010129c:	68 ee 44 10 f0       	push   $0xf01044ee
f01012a1:	68 b1 43 10 f0       	push   $0xf01043b1
f01012a6:	68 55 02 00 00       	push   $0x255
f01012ab:	68 92 43 10 f0       	push   $0xf0104392
f01012b0:	e8 df ed ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012b5:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01012b8:	75 19                	jne    f01012d3 <check_page_alloc+0xe1>
f01012ba:	68 04 45 10 f0       	push   $0xf0104504
f01012bf:	68 b1 43 10 f0       	push   $0xf01043b1
f01012c4:	68 58 02 00 00       	push   $0x258
f01012c9:	68 92 43 10 f0       	push   $0xf0104392
f01012ce:	e8 c1 ed ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01012d3:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01012d6:	74 04                	je     f01012dc <check_page_alloc+0xea>
f01012d8:	39 c7                	cmp    %eax,%edi
f01012da:	75 19                	jne    f01012f5 <check_page_alloc+0x103>
f01012dc:	68 8c 3e 10 f0       	push   $0xf0103e8c
f01012e1:	68 b1 43 10 f0       	push   $0xf01043b1
f01012e6:	68 59 02 00 00       	push   $0x259
f01012eb:	68 92 43 10 f0       	push   $0xf0104392
f01012f0:	e8 9f ed ff ff       	call   f0100094 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01012f5:	89 f8                	mov    %edi,%eax
f01012f7:	e8 1c f7 ff ff       	call   f0100a18 <page2pa>
f01012fc:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f0101302:	c1 e1 0c             	shl    $0xc,%ecx
f0101305:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101308:	39 c8                	cmp    %ecx,%eax
f010130a:	72 19                	jb     f0101325 <check_page_alloc+0x133>
f010130c:	68 16 45 10 f0       	push   $0xf0104516
f0101311:	68 b1 43 10 f0       	push   $0xf01043b1
f0101316:	68 5a 02 00 00       	push   $0x25a
f010131b:	68 92 43 10 f0       	push   $0xf0104392
f0101320:	e8 6f ed ff ff       	call   f0100094 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101325:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101328:	e8 eb f6 ff ff       	call   f0100a18 <page2pa>
f010132d:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0101330:	77 19                	ja     f010134b <check_page_alloc+0x159>
f0101332:	68 33 45 10 f0       	push   $0xf0104533
f0101337:	68 b1 43 10 f0       	push   $0xf01043b1
f010133c:	68 5b 02 00 00       	push   $0x25b
f0101341:	68 92 43 10 f0       	push   $0xf0104392
f0101346:	e8 49 ed ff ff       	call   f0100094 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f010134b:	89 d8                	mov    %ebx,%eax
f010134d:	e8 c6 f6 ff ff       	call   f0100a18 <page2pa>
f0101352:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0101355:	77 19                	ja     f0101370 <check_page_alloc+0x17e>
f0101357:	68 50 45 10 f0       	push   $0xf0104550
f010135c:	68 b1 43 10 f0       	push   $0xf01043b1
f0101361:	68 5c 02 00 00       	push   $0x25c
f0101366:	68 92 43 10 f0       	push   $0xf0104392
f010136b:	e8 24 ed ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101370:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101375:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f0101378:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010137f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101382:	83 ec 0c             	sub    $0xc,%esp
f0101385:	6a 00                	push   $0x0
f0101387:	e8 cf fd ff ff       	call   f010115b <page_alloc>
f010138c:	83 c4 10             	add    $0x10,%esp
f010138f:	85 c0                	test   %eax,%eax
f0101391:	74 19                	je     f01013ac <check_page_alloc+0x1ba>
f0101393:	68 6d 45 10 f0       	push   $0xf010456d
f0101398:	68 b1 43 10 f0       	push   $0xf01043b1
f010139d:	68 63 02 00 00       	push   $0x263
f01013a2:	68 92 43 10 f0       	push   $0xf0104392
f01013a7:	e8 e8 ec ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01013ac:	83 ec 0c             	sub    $0xc,%esp
f01013af:	57                   	push   %edi
f01013b0:	e8 eb fd ff ff       	call   f01011a0 <page_free>
	page_free(pp1);
f01013b5:	83 c4 04             	add    $0x4,%esp
f01013b8:	ff 75 e4             	pushl  -0x1c(%ebp)
f01013bb:	e8 e0 fd ff ff       	call   f01011a0 <page_free>
	page_free(pp2);
f01013c0:	89 1c 24             	mov    %ebx,(%esp)
f01013c3:	e8 d8 fd ff ff       	call   f01011a0 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013cf:	e8 87 fd ff ff       	call   f010115b <page_alloc>
f01013d4:	89 c3                	mov    %eax,%ebx
f01013d6:	83 c4 10             	add    $0x10,%esp
f01013d9:	85 c0                	test   %eax,%eax
f01013db:	75 19                	jne    f01013f6 <check_page_alloc+0x204>
f01013dd:	68 c2 44 10 f0       	push   $0xf01044c2
f01013e2:	68 b1 43 10 f0       	push   $0xf01043b1
f01013e7:	68 6a 02 00 00       	push   $0x26a
f01013ec:	68 92 43 10 f0       	push   $0xf0104392
f01013f1:	e8 9e ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01013f6:	83 ec 0c             	sub    $0xc,%esp
f01013f9:	6a 00                	push   $0x0
f01013fb:	e8 5b fd ff ff       	call   f010115b <page_alloc>
f0101400:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101403:	83 c4 10             	add    $0x10,%esp
f0101406:	85 c0                	test   %eax,%eax
f0101408:	75 19                	jne    f0101423 <check_page_alloc+0x231>
f010140a:	68 d8 44 10 f0       	push   $0xf01044d8
f010140f:	68 b1 43 10 f0       	push   $0xf01043b1
f0101414:	68 6b 02 00 00       	push   $0x26b
f0101419:	68 92 43 10 f0       	push   $0xf0104392
f010141e:	e8 71 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101423:	83 ec 0c             	sub    $0xc,%esp
f0101426:	6a 00                	push   $0x0
f0101428:	e8 2e fd ff ff       	call   f010115b <page_alloc>
f010142d:	89 c7                	mov    %eax,%edi
f010142f:	83 c4 10             	add    $0x10,%esp
f0101432:	85 c0                	test   %eax,%eax
f0101434:	75 19                	jne    f010144f <check_page_alloc+0x25d>
f0101436:	68 ee 44 10 f0       	push   $0xf01044ee
f010143b:	68 b1 43 10 f0       	push   $0xf01043b1
f0101440:	68 6c 02 00 00       	push   $0x26c
f0101445:	68 92 43 10 f0       	push   $0xf0104392
f010144a:	e8 45 ec ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010144f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101452:	75 19                	jne    f010146d <check_page_alloc+0x27b>
f0101454:	68 04 45 10 f0       	push   $0xf0104504
f0101459:	68 b1 43 10 f0       	push   $0xf01043b1
f010145e:	68 6e 02 00 00       	push   $0x26e
f0101463:	68 92 43 10 f0       	push   $0xf0104392
f0101468:	e8 27 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010146d:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101470:	74 04                	je     f0101476 <check_page_alloc+0x284>
f0101472:	39 c3                	cmp    %eax,%ebx
f0101474:	75 19                	jne    f010148f <check_page_alloc+0x29d>
f0101476:	68 8c 3e 10 f0       	push   $0xf0103e8c
f010147b:	68 b1 43 10 f0       	push   $0xf01043b1
f0101480:	68 6f 02 00 00       	push   $0x26f
f0101485:	68 92 43 10 f0       	push   $0xf0104392
f010148a:	e8 05 ec ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f010148f:	83 ec 0c             	sub    $0xc,%esp
f0101492:	6a 00                	push   $0x0
f0101494:	e8 c2 fc ff ff       	call   f010115b <page_alloc>
f0101499:	83 c4 10             	add    $0x10,%esp
f010149c:	85 c0                	test   %eax,%eax
f010149e:	74 19                	je     f01014b9 <check_page_alloc+0x2c7>
f01014a0:	68 6d 45 10 f0       	push   $0xf010456d
f01014a5:	68 b1 43 10 f0       	push   $0xf01043b1
f01014aa:	68 70 02 00 00       	push   $0x270
f01014af:	68 92 43 10 f0       	push   $0xf0104392
f01014b4:	e8 db eb ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01014b9:	89 d8                	mov    %ebx,%eax
f01014bb:	e8 24 f6 ff ff       	call   f0100ae4 <page2kva>
f01014c0:	83 ec 04             	sub    $0x4,%esp
f01014c3:	68 00 10 00 00       	push   $0x1000
f01014c8:	6a 01                	push   $0x1
f01014ca:	50                   	push   %eax
f01014cb:	e8 59 1d 00 00       	call   f0103229 <memset>
	page_free(pp0);
f01014d0:	89 1c 24             	mov    %ebx,(%esp)
f01014d3:	e8 c8 fc ff ff       	call   f01011a0 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014d8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01014df:	e8 77 fc ff ff       	call   f010115b <page_alloc>
f01014e4:	83 c4 10             	add    $0x10,%esp
f01014e7:	85 c0                	test   %eax,%eax
f01014e9:	75 19                	jne    f0101504 <check_page_alloc+0x312>
f01014eb:	68 7c 45 10 f0       	push   $0xf010457c
f01014f0:	68 b1 43 10 f0       	push   $0xf01043b1
f01014f5:	68 75 02 00 00       	push   $0x275
f01014fa:	68 92 43 10 f0       	push   $0xf0104392
f01014ff:	e8 90 eb ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101504:	39 c3                	cmp    %eax,%ebx
f0101506:	74 19                	je     f0101521 <check_page_alloc+0x32f>
f0101508:	68 9a 45 10 f0       	push   $0xf010459a
f010150d:	68 b1 43 10 f0       	push   $0xf01043b1
f0101512:	68 76 02 00 00       	push   $0x276
f0101517:	68 92 43 10 f0       	push   $0xf0104392
f010151c:	e8 73 eb ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
f0101521:	89 d8                	mov    %ebx,%eax
f0101523:	e8 bc f5 ff ff       	call   f0100ae4 <page2kva>
f0101528:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010152e:	80 38 00             	cmpb   $0x0,(%eax)
f0101531:	74 19                	je     f010154c <check_page_alloc+0x35a>
f0101533:	68 aa 45 10 f0       	push   $0xf01045aa
f0101538:	68 b1 43 10 f0       	push   $0xf01043b1
f010153d:	68 79 02 00 00       	push   $0x279
f0101542:	68 92 43 10 f0       	push   $0xf0104392
f0101547:	e8 48 eb ff ff       	call   f0100094 <_panic>
f010154c:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010154f:	39 d0                	cmp    %edx,%eax
f0101551:	75 db                	jne    f010152e <check_page_alloc+0x33c>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101553:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101556:	a3 3c 65 11 f0       	mov    %eax,0xf011653c

	// free the pages we took
	page_free(pp0);
f010155b:	83 ec 0c             	sub    $0xc,%esp
f010155e:	53                   	push   %ebx
f010155f:	e8 3c fc ff ff       	call   f01011a0 <page_free>
	page_free(pp1);
f0101564:	83 c4 04             	add    $0x4,%esp
f0101567:	ff 75 e4             	pushl  -0x1c(%ebp)
f010156a:	e8 31 fc ff ff       	call   f01011a0 <page_free>
	page_free(pp2);
f010156f:	89 3c 24             	mov    %edi,(%esp)
f0101572:	e8 29 fc ff ff       	call   f01011a0 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101577:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f010157c:	83 c4 10             	add    $0x10,%esp
f010157f:	eb 05                	jmp    f0101586 <check_page_alloc+0x394>
		--nfree;
f0101581:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101584:	8b 00                	mov    (%eax),%eax
f0101586:	85 c0                	test   %eax,%eax
f0101588:	75 f7                	jne    f0101581 <check_page_alloc+0x38f>
		--nfree;
	assert(nfree == 0);
f010158a:	85 f6                	test   %esi,%esi
f010158c:	74 19                	je     f01015a7 <check_page_alloc+0x3b5>
f010158e:	68 b4 45 10 f0       	push   $0xf01045b4
f0101593:	68 b1 43 10 f0       	push   $0xf01043b1
f0101598:	68 86 02 00 00       	push   $0x286
f010159d:	68 92 43 10 f0       	push   $0xf0104392
f01015a2:	e8 ed ea ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01015a7:	83 ec 0c             	sub    $0xc,%esp
f01015aa:	68 ac 3e 10 f0       	push   $0xf0103eac
f01015af:	e8 d1 11 00 00       	call   f0102785 <cprintf>
}
f01015b4:	83 c4 10             	add    $0x10,%esp
f01015b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01015ba:	5b                   	pop    %ebx
f01015bb:	5e                   	pop    %esi
f01015bc:	5f                   	pop    %edi
f01015bd:	5d                   	pop    %ebp
f01015be:	c3                   	ret    

f01015bf <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01015bf:	55                   	push   %ebp
f01015c0:	89 e5                	mov    %esp,%ebp
f01015c2:	83 ec 08             	sub    $0x8,%esp
f01015c5:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01015c8:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01015cc:	83 e8 01             	sub    $0x1,%eax
f01015cf:	66 89 42 04          	mov    %ax,0x4(%edx)
f01015d3:	66 85 c0             	test   %ax,%ax
f01015d6:	75 0c                	jne    f01015e4 <page_decref+0x25>
		page_free(pp);
f01015d8:	83 ec 0c             	sub    $0xc,%esp
f01015db:	52                   	push   %edx
f01015dc:	e8 bf fb ff ff       	call   f01011a0 <page_free>
f01015e1:	83 c4 10             	add    $0x10,%esp
}
f01015e4:	c9                   	leave  
f01015e5:	c3                   	ret    

f01015e6 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01015e6:	55                   	push   %ebp
f01015e7:	89 e5                	mov    %esp,%ebp
f01015e9:	57                   	push   %edi
f01015ea:	56                   	push   %esi
f01015eb:	53                   	push   %ebx
f01015ec:	83 ec 0c             	sub    $0xc,%esp
f01015ef:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t pde =  pgdir[PDX(va)]; //ojo que esto es P.Addr. !!
f01015f2:	89 f3                	mov    %esi,%ebx
f01015f4:	c1 eb 16             	shr    $0x16,%ebx
f01015f7:	c1 e3 02             	shl    $0x2,%ebx
f01015fa:	03 5d 08             	add    0x8(%ebp),%ebx
f01015fd:	8b 3b                	mov    (%ebx),%edi
	pte_t* pte = (pte_t*) KADDR(PTE_ADDR(pde));
f01015ff:	89 f9                	mov    %edi,%ecx
f0101601:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101607:	ba 5c 01 00 00       	mov    $0x15c,%edx
f010160c:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0101611:	e8 a2 f4 ff ff       	call   f0100ab8 <_kaddr>

	if (pde & PTE_P) return pte+PTX(va);
f0101616:	f7 c7 01 00 00 00    	test   $0x1,%edi
f010161c:	74 0d                	je     f010162b <pgdir_walk+0x45>
f010161e:	c1 ee 0a             	shr    $0xa,%esi
f0101621:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101627:	01 f0                	add    %esi,%eax
f0101629:	eb 52                	jmp    f010167d <pgdir_walk+0x97>

	if (!create) return NULL;
f010162b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101630:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101634:	74 47                	je     f010167d <pgdir_walk+0x97>
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0101636:	83 ec 0c             	sub    $0xc,%esp
f0101639:	6a 01                	push   $0x1
f010163b:	e8 1b fb ff ff       	call   f010115b <page_alloc>
f0101640:	89 c7                	mov    %eax,%edi
	if (page==NULL) return NULL;
f0101642:	83 c4 10             	add    $0x10,%esp
f0101645:	85 c0                	test   %eax,%eax
f0101647:	74 2f                	je     f0101678 <pgdir_walk+0x92>
	physaddr_t pt_start = page2pa(page);
f0101649:	e8 ca f3 ff ff       	call   f0100a18 <page2pa>
	page->pp_ref ++;
f010164e:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
f0101653:	89 c2                	mov    %eax,%edx
f0101655:	83 ca 07             	or     $0x7,%edx
f0101658:	89 13                	mov    %edx,(%ebx)
	return (pte_t*)KADDR(pt_start)+PTX(va);
f010165a:	89 c1                	mov    %eax,%ecx
f010165c:	ba 66 01 00 00       	mov    $0x166,%edx
f0101661:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0101666:	e8 4d f4 ff ff       	call   f0100ab8 <_kaddr>
f010166b:	c1 ee 0a             	shr    $0xa,%esi
f010166e:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101674:	01 f0                	add    %esi,%eax
f0101676:	eb 05                	jmp    f010167d <pgdir_walk+0x97>

	if (pde & PTE_P) return pte+PTX(va);

	if (!create) return NULL;
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if (page==NULL) return NULL;
f0101678:	b8 00 00 00 00       	mov    $0x0,%eax
	physaddr_t pt_start = page2pa(page);
	page->pp_ref ++;
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
	return (pte_t*)KADDR(pt_start)+PTX(va);
}
f010167d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101680:	5b                   	pop    %ebx
f0101681:	5e                   	pop    %esi
f0101682:	5f                   	pop    %edi
f0101683:	5d                   	pop    %ebp
f0101684:	c3                   	ret    

f0101685 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk
#define TP1_PSE
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101685:	55                   	push   %ebp
f0101686:	89 e5                	mov    %esp,%ebp
f0101688:	57                   	push   %edi
f0101689:	56                   	push   %esi
f010168a:	53                   	push   %ebx
f010168b:	83 ec 1c             	sub    $0x1c,%esp
f010168e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101691:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101694:	8b 45 0c             	mov    0xc(%ebp),%eax
	assert(va % PGSIZE == 0);
f0101697:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010169d:	74 19                	je     f01016b8 <boot_map_region+0x33>
f010169f:	68 bf 45 10 f0       	push   $0xf01045bf
f01016a4:	68 b1 43 10 f0       	push   $0xf01043b1
f01016a9:	68 78 01 00 00       	push   $0x178
f01016ae:	68 92 43 10 f0       	push   $0xf0104392
f01016b3:	e8 dc e9 ff ff       	call   f0100094 <_panic>
f01016b8:	89 d7                	mov    %edx,%edi
f01016ba:	89 ce                	mov    %ecx,%esi
	assert(pa % PGSIZE == 0);
f01016bc:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
f01016c2:	74 19                	je     f01016dd <boot_map_region+0x58>
f01016c4:	68 d0 45 10 f0       	push   $0xf01045d0
f01016c9:	68 b1 43 10 f0       	push   $0xf01043b1
f01016ce:	68 79 01 00 00       	push   $0x179
f01016d3:	68 92 43 10 f0       	push   $0xf0104392
f01016d8:	e8 b7 e9 ff ff       	call   f0100094 <_panic>
	assert(size % PGSIZE == 0);	
f01016dd:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f01016e3:	74 79                	je     f010175e <boot_map_region+0xd9>
f01016e5:	68 e1 45 10 f0       	push   $0xf01045e1
f01016ea:	68 b1 43 10 f0       	push   $0xf01043b1
f01016ef:	68 7a 01 00 00       	push   $0x17a
f01016f4:	68 92 43 10 f0       	push   $0xf0104392
f01016f9:	e8 96 e9 ff ff       	call   f0100094 <_panic>
			va+=PGSIZE;
			pa+=PGSIZE;
		}
	#else
		while(size){
			if (!(pa % PTSIZE) && size>=PTSIZE) {
f01016fe:	f7 c3 ff ff 3f 00    	test   $0x3fffff,%ebx
f0101704:	75 2c                	jne    f0101732 <boot_map_region+0xad>
f0101706:	81 fe ff ff 3f 00    	cmp    $0x3fffff,%esi
f010170c:	76 24                	jbe    f0101732 <boot_map_region+0xad>
				*(pgdir+PDX(va)) = pa | perm | PTE_P | PTE_PS;
f010170e:	89 f8                	mov    %edi,%eax
f0101710:	c1 e8 16             	shr    $0x16,%eax
f0101713:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101716:	09 da                	or     %ebx,%edx
f0101718:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010171b:	89 14 81             	mov    %edx,(%ecx,%eax,4)
				size-=PTSIZE;		
f010171e:	81 ee 00 00 40 00    	sub    $0x400000,%esi
				//incremento
				va+=PTSIZE;
f0101724:	81 c7 00 00 40 00    	add    $0x400000,%edi
				pa+=PTSIZE;
f010172a:	81 c3 00 00 40 00    	add    $0x400000,%ebx
f0101730:	eb 39                	jmp    f010176b <boot_map_region+0xe6>
			}
			else{
				pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
f0101732:	83 ec 04             	sub    $0x4,%esp
f0101735:	6a 01                	push   $0x1
f0101737:	57                   	push   %edi
f0101738:	ff 75 e4             	pushl  -0x1c(%ebp)
f010173b:	e8 a6 fe ff ff       	call   f01015e6 <pgdir_walk>
				*pte_addr = pa | perm | PTE_P;
f0101740:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101743:	09 da                	or     %ebx,%edx
f0101745:	89 10                	mov    %edx,(%eax)
				size-=PGSIZE;		
f0101747:	81 ee 00 10 00 00    	sub    $0x1000,%esi
				//incremento
				va+=PGSIZE;
f010174d:	81 c7 00 10 00 00    	add    $0x1000,%edi
				pa+=PGSIZE;
f0101753:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101759:	83 c4 10             	add    $0x10,%esp
f010175c:	eb 0d                	jmp    f010176b <boot_map_region+0xe6>
				va+=PTSIZE;
				pa+=PTSIZE;
			}
			else{
				pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
				*pte_addr = pa | perm | PTE_P;
f010175e:	89 c1                	mov    %eax,%ecx
f0101760:	83 c9 01             	or     $0x1,%ecx
f0101763:	89 4d e0             	mov    %ecx,-0x20(%ebp)
			pa+=PGSIZE;
		}
	#else
		while(size){
			if (!(pa % PTSIZE) && size>=PTSIZE) {
				*(pgdir+PDX(va)) = pa | perm | PTE_P | PTE_PS;
f0101766:	0c 81                	or     $0x81,%al
f0101768:	89 45 dc             	mov    %eax,-0x24(%ebp)
			//incremento
			va+=PGSIZE;
			pa+=PGSIZE;
		}
	#else
		while(size){
f010176b:	85 f6                	test   %esi,%esi
f010176d:	75 8f                	jne    f01016fe <boot_map_region+0x79>
				va+=PGSIZE;
				pa+=PGSIZE;
			}
		}
	#endif
}
f010176f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101772:	5b                   	pop    %ebx
f0101773:	5e                   	pop    %esi
f0101774:	5f                   	pop    %edi
f0101775:	5d                   	pop    %ebp
f0101776:	c3                   	ret    

f0101777 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101777:	55                   	push   %ebp
f0101778:	89 e5                	mov    %esp,%ebp
f010177a:	53                   	push   %ebx
f010177b:	83 ec 08             	sub    $0x8,%esp
f010177e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
f0101781:	6a 00                	push   $0x0
f0101783:	ff 75 0c             	pushl  0xc(%ebp)
f0101786:	ff 75 08             	pushl  0x8(%ebp)
f0101789:	e8 58 fe ff ff       	call   f01015e6 <pgdir_walk>
	if (pte_store) *pte_store = pte_addr;
f010178e:	83 c4 10             	add    $0x10,%esp
f0101791:	85 db                	test   %ebx,%ebx
f0101793:	74 02                	je     f0101797 <page_lookup+0x20>
f0101795:	89 03                	mov    %eax,(%ebx)
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f0101797:	85 c0                	test   %eax,%eax
f0101799:	74 1a                	je     f01017b5 <page_lookup+0x3e>
	if (!(*pte_addr & PTE_P)) return NULL;
f010179b:	8b 10                	mov    (%eax),%edx
f010179d:	b8 00 00 00 00       	mov    $0x0,%eax
f01017a2:	f6 c2 01             	test   $0x1,%dl
f01017a5:	74 13                	je     f01017ba <page_lookup+0x43>
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
f01017a7:	89 d0                	mov    %edx,%eax
f01017a9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01017ae:	e8 dd f8 ff ff       	call   f0101090 <pa2page>
f01017b3:	eb 05                	jmp    f01017ba <page_lookup+0x43>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
	if (pte_store) *pte_store = pte_addr;
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f01017b5:	b8 00 00 00 00       	mov    $0x0,%eax
	if (!(*pte_addr & PTE_P)) return NULL;
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
}
f01017ba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01017bd:	c9                   	leave  
f01017be:	c3                   	ret    

f01017bf <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01017bf:	55                   	push   %ebp
f01017c0:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f01017c2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017c5:	e8 2e f2 ff ff       	call   f01009f8 <invlpg>
}
f01017ca:	5d                   	pop    %ebp
f01017cb:	c3                   	ret    

f01017cc <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01017cc:	55                   	push   %ebp
f01017cd:	89 e5                	mov    %esp,%ebp
f01017cf:	56                   	push   %esi
f01017d0:	53                   	push   %ebx
f01017d1:	83 ec 14             	sub    $0x14,%esp
f01017d4:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01017d7:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte_addr;
	struct PageInfo* page_ptr = page_lookup(pgdir,va,&pte_addr);
f01017da:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01017dd:	50                   	push   %eax
f01017de:	56                   	push   %esi
f01017df:	53                   	push   %ebx
f01017e0:	e8 92 ff ff ff       	call   f0101777 <page_lookup>
	if (!page_ptr) return;
f01017e5:	83 c4 10             	add    $0x10,%esp
f01017e8:	85 c0                	test   %eax,%eax
f01017ea:	74 1f                	je     f010180b <page_remove+0x3f>
	page_decref(page_ptr);
f01017ec:	83 ec 0c             	sub    $0xc,%esp
f01017ef:	50                   	push   %eax
f01017f0:	e8 ca fd ff ff       	call   f01015bf <page_decref>
	*pte_addr = 0;
f01017f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01017f8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);
f01017fe:	83 c4 08             	add    $0x8,%esp
f0101801:	56                   	push   %esi
f0101802:	53                   	push   %ebx
f0101803:	e8 b7 ff ff ff       	call   f01017bf <tlb_invalidate>
f0101808:	83 c4 10             	add    $0x10,%esp
}
f010180b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010180e:	5b                   	pop    %ebx
f010180f:	5e                   	pop    %esi
f0101810:	5d                   	pop    %ebp
f0101811:	c3                   	ret    

f0101812 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101812:	55                   	push   %ebp
f0101813:	89 e5                	mov    %esp,%ebp
f0101815:	57                   	push   %edi
f0101816:	56                   	push   %esi
f0101817:	53                   	push   %ebx
f0101818:	83 ec 10             	sub    $0x10,%esp
f010181b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010181e:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
f0101821:	6a 01                	push   $0x1
f0101823:	57                   	push   %edi
f0101824:	ff 75 08             	pushl  0x8(%ebp)
f0101827:	e8 ba fd ff ff       	call   f01015e6 <pgdir_walk>
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f010182c:	83 c4 10             	add    $0x10,%esp
f010182f:	85 c0                	test   %eax,%eax
f0101831:	74 33                	je     f0101866 <page_insert+0x54>
f0101833:	89 c6                	mov    %eax,%esi
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
f0101835:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
f010183a:	f6 00 01             	testb  $0x1,(%eax)
f010183d:	74 0f                	je     f010184e <page_insert+0x3c>
f010183f:	83 ec 08             	sub    $0x8,%esp
f0101842:	57                   	push   %edi
f0101843:	ff 75 08             	pushl  0x8(%ebp)
f0101846:	e8 81 ff ff ff       	call   f01017cc <page_remove>
f010184b:	83 c4 10             	add    $0x10,%esp
	*pte_addr = page2pa(pp) | perm | PTE_P;
f010184e:	89 d8                	mov    %ebx,%eax
f0101850:	e8 c3 f1 ff ff       	call   f0100a18 <page2pa>
f0101855:	8b 55 14             	mov    0x14(%ebp),%edx
f0101858:	83 ca 01             	or     $0x1,%edx
f010185b:	09 d0                	or     %edx,%eax
f010185d:	89 06                	mov    %eax,(%esi)
	return 0;
f010185f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101864:	eb 05                	jmp    f010186b <page_insert+0x59>
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101866:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
	*pte_addr = page2pa(pp) | perm | PTE_P;
	return 0;
}
f010186b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010186e:	5b                   	pop    %ebx
f010186f:	5e                   	pop    %esi
f0101870:	5f                   	pop    %edi
f0101871:	5d                   	pop    %ebp
f0101872:	c3                   	ret    

f0101873 <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f0101873:	55                   	push   %ebp
f0101874:	89 e5                	mov    %esp,%ebp
f0101876:	57                   	push   %edi
f0101877:	56                   	push   %esi
f0101878:	53                   	push   %ebx
f0101879:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010187c:	6a 00                	push   $0x0
f010187e:	e8 d8 f8 ff ff       	call   f010115b <page_alloc>
f0101883:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101886:	83 c4 10             	add    $0x10,%esp
f0101889:	85 c0                	test   %eax,%eax
f010188b:	75 19                	jne    f01018a6 <check_page+0x33>
f010188d:	68 c2 44 10 f0       	push   $0xf01044c2
f0101892:	68 b1 43 10 f0       	push   $0xf01043b1
f0101897:	68 e1 02 00 00       	push   $0x2e1
f010189c:	68 92 43 10 f0       	push   $0xf0104392
f01018a1:	e8 ee e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01018a6:	83 ec 0c             	sub    $0xc,%esp
f01018a9:	6a 00                	push   $0x0
f01018ab:	e8 ab f8 ff ff       	call   f010115b <page_alloc>
f01018b0:	89 c6                	mov    %eax,%esi
f01018b2:	83 c4 10             	add    $0x10,%esp
f01018b5:	85 c0                	test   %eax,%eax
f01018b7:	75 19                	jne    f01018d2 <check_page+0x5f>
f01018b9:	68 d8 44 10 f0       	push   $0xf01044d8
f01018be:	68 b1 43 10 f0       	push   $0xf01043b1
f01018c3:	68 e2 02 00 00       	push   $0x2e2
f01018c8:	68 92 43 10 f0       	push   $0xf0104392
f01018cd:	e8 c2 e7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01018d2:	83 ec 0c             	sub    $0xc,%esp
f01018d5:	6a 00                	push   $0x0
f01018d7:	e8 7f f8 ff ff       	call   f010115b <page_alloc>
f01018dc:	89 c3                	mov    %eax,%ebx
f01018de:	83 c4 10             	add    $0x10,%esp
f01018e1:	85 c0                	test   %eax,%eax
f01018e3:	75 19                	jne    f01018fe <check_page+0x8b>
f01018e5:	68 ee 44 10 f0       	push   $0xf01044ee
f01018ea:	68 b1 43 10 f0       	push   $0xf01043b1
f01018ef:	68 e3 02 00 00       	push   $0x2e3
f01018f4:	68 92 43 10 f0       	push   $0xf0104392
f01018f9:	e8 96 e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018fe:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0101901:	75 19                	jne    f010191c <check_page+0xa9>
f0101903:	68 04 45 10 f0       	push   $0xf0104504
f0101908:	68 b1 43 10 f0       	push   $0xf01043b1
f010190d:	68 e6 02 00 00       	push   $0x2e6
f0101912:	68 92 43 10 f0       	push   $0xf0104392
f0101917:	e8 78 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010191c:	39 c6                	cmp    %eax,%esi
f010191e:	74 05                	je     f0101925 <check_page+0xb2>
f0101920:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101923:	75 19                	jne    f010193e <check_page+0xcb>
f0101925:	68 8c 3e 10 f0       	push   $0xf0103e8c
f010192a:	68 b1 43 10 f0       	push   $0xf01043b1
f010192f:	68 e7 02 00 00       	push   $0x2e7
f0101934:	68 92 43 10 f0       	push   $0xf0104392
f0101939:	e8 56 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010193e:	a1 3c 65 11 f0       	mov    0xf011653c,%eax
f0101943:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101946:	c7 05 3c 65 11 f0 00 	movl   $0x0,0xf011653c
f010194d:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101950:	83 ec 0c             	sub    $0xc,%esp
f0101953:	6a 00                	push   $0x0
f0101955:	e8 01 f8 ff ff       	call   f010115b <page_alloc>
f010195a:	83 c4 10             	add    $0x10,%esp
f010195d:	85 c0                	test   %eax,%eax
f010195f:	74 19                	je     f010197a <check_page+0x107>
f0101961:	68 6d 45 10 f0       	push   $0xf010456d
f0101966:	68 b1 43 10 f0       	push   $0xf01043b1
f010196b:	68 ee 02 00 00       	push   $0x2ee
f0101970:	68 92 43 10 f0       	push   $0xf0104392
f0101975:	e8 1a e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010197a:	83 ec 04             	sub    $0x4,%esp
f010197d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101980:	50                   	push   %eax
f0101981:	6a 00                	push   $0x0
f0101983:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101989:	e8 e9 fd ff ff       	call   f0101777 <page_lookup>
f010198e:	83 c4 10             	add    $0x10,%esp
f0101991:	85 c0                	test   %eax,%eax
f0101993:	74 19                	je     f01019ae <check_page+0x13b>
f0101995:	68 cc 3e 10 f0       	push   $0xf0103ecc
f010199a:	68 b1 43 10 f0       	push   $0xf01043b1
f010199f:	68 f1 02 00 00       	push   $0x2f1
f01019a4:	68 92 43 10 f0       	push   $0xf0104392
f01019a9:	e8 e6 e6 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019ae:	6a 02                	push   $0x2
f01019b0:	6a 00                	push   $0x0
f01019b2:	56                   	push   %esi
f01019b3:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01019b9:	e8 54 fe ff ff       	call   f0101812 <page_insert>
f01019be:	83 c4 10             	add    $0x10,%esp
f01019c1:	85 c0                	test   %eax,%eax
f01019c3:	78 19                	js     f01019de <check_page+0x16b>
f01019c5:	68 04 3f 10 f0       	push   $0xf0103f04
f01019ca:	68 b1 43 10 f0       	push   $0xf01043b1
f01019cf:	68 f4 02 00 00       	push   $0x2f4
f01019d4:	68 92 43 10 f0       	push   $0xf0104392
f01019d9:	e8 b6 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019de:	83 ec 0c             	sub    $0xc,%esp
f01019e1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019e4:	e8 b7 f7 ff ff       	call   f01011a0 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019e9:	6a 02                	push   $0x2
f01019eb:	6a 00                	push   $0x0
f01019ed:	56                   	push   %esi
f01019ee:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01019f4:	e8 19 fe ff ff       	call   f0101812 <page_insert>
f01019f9:	83 c4 20             	add    $0x20,%esp
f01019fc:	85 c0                	test   %eax,%eax
f01019fe:	74 19                	je     f0101a19 <check_page+0x1a6>
f0101a00:	68 34 3f 10 f0       	push   $0xf0103f34
f0101a05:	68 b1 43 10 f0       	push   $0xf01043b1
f0101a0a:	68 f8 02 00 00       	push   $0x2f8
f0101a0f:	68 92 43 10 f0       	push   $0xf0104392
f0101a14:	e8 7b e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a19:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101a1f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a22:	e8 f1 ef ff ff       	call   f0100a18 <page2pa>
f0101a27:	8b 17                	mov    (%edi),%edx
f0101a29:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a2f:	39 c2                	cmp    %eax,%edx
f0101a31:	74 19                	je     f0101a4c <check_page+0x1d9>
f0101a33:	68 64 3f 10 f0       	push   $0xf0103f64
f0101a38:	68 b1 43 10 f0       	push   $0xf01043b1
f0101a3d:	68 f9 02 00 00       	push   $0x2f9
f0101a42:	68 92 43 10 f0       	push   $0xf0104392
f0101a47:	e8 48 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a4c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a51:	89 f8                	mov    %edi,%eax
f0101a53:	e8 aa f0 ff ff       	call   f0100b02 <check_va2pa>
f0101a58:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a5b:	89 f0                	mov    %esi,%eax
f0101a5d:	e8 b6 ef ff ff       	call   f0100a18 <page2pa>
f0101a62:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101a65:	74 19                	je     f0101a80 <check_page+0x20d>
f0101a67:	68 8c 3f 10 f0       	push   $0xf0103f8c
f0101a6c:	68 b1 43 10 f0       	push   $0xf01043b1
f0101a71:	68 fa 02 00 00       	push   $0x2fa
f0101a76:	68 92 43 10 f0       	push   $0xf0104392
f0101a7b:	e8 14 e6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101a80:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a85:	74 19                	je     f0101aa0 <check_page+0x22d>
f0101a87:	68 f4 45 10 f0       	push   $0xf01045f4
f0101a8c:	68 b1 43 10 f0       	push   $0xf01043b1
f0101a91:	68 fb 02 00 00       	push   $0x2fb
f0101a96:	68 92 43 10 f0       	push   $0xf0104392
f0101a9b:	e8 f4 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101aa0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101aa3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101aa8:	74 19                	je     f0101ac3 <check_page+0x250>
f0101aaa:	68 05 46 10 f0       	push   $0xf0104605
f0101aaf:	68 b1 43 10 f0       	push   $0xf01043b1
f0101ab4:	68 fc 02 00 00       	push   $0x2fc
f0101ab9:	68 92 43 10 f0       	push   $0xf0104392
f0101abe:	e8 d1 e5 ff ff       	call   f0100094 <_panic>
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ac3:	6a 02                	push   $0x2
f0101ac5:	68 00 10 00 00       	push   $0x1000
f0101aca:	53                   	push   %ebx
f0101acb:	57                   	push   %edi
f0101acc:	e8 41 fd ff ff       	call   f0101812 <page_insert>
f0101ad1:	83 c4 10             	add    $0x10,%esp
f0101ad4:	85 c0                	test   %eax,%eax
f0101ad6:	74 19                	je     f0101af1 <check_page+0x27e>
f0101ad8:	68 bc 3f 10 f0       	push   $0xf0103fbc
f0101add:	68 b1 43 10 f0       	push   $0xf01043b1
f0101ae2:	68 fe 02 00 00       	push   $0x2fe
f0101ae7:	68 92 43 10 f0       	push   $0xf0104392
f0101aec:	e8 a3 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101af1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101af6:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101afb:	e8 02 f0 ff ff       	call   f0100b02 <check_va2pa>
f0101b00:	89 c7                	mov    %eax,%edi
f0101b02:	89 d8                	mov    %ebx,%eax
f0101b04:	e8 0f ef ff ff       	call   f0100a18 <page2pa>
f0101b09:	39 c7                	cmp    %eax,%edi
f0101b0b:	74 19                	je     f0101b26 <check_page+0x2b3>
f0101b0d:	68 f8 3f 10 f0       	push   $0xf0103ff8
f0101b12:	68 b1 43 10 f0       	push   $0xf01043b1
f0101b17:	68 ff 02 00 00       	push   $0x2ff
f0101b1c:	68 92 43 10 f0       	push   $0xf0104392
f0101b21:	e8 6e e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b26:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b2b:	74 19                	je     f0101b46 <check_page+0x2d3>
f0101b2d:	68 16 46 10 f0       	push   $0xf0104616
f0101b32:	68 b1 43 10 f0       	push   $0xf01043b1
f0101b37:	68 00 03 00 00       	push   $0x300
f0101b3c:	68 92 43 10 f0       	push   $0xf0104392
f0101b41:	e8 4e e5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b46:	83 ec 0c             	sub    $0xc,%esp
f0101b49:	6a 00                	push   $0x0
f0101b4b:	e8 0b f6 ff ff       	call   f010115b <page_alloc>
f0101b50:	83 c4 10             	add    $0x10,%esp
f0101b53:	85 c0                	test   %eax,%eax
f0101b55:	74 19                	je     f0101b70 <check_page+0x2fd>
f0101b57:	68 6d 45 10 f0       	push   $0xf010456d
f0101b5c:	68 b1 43 10 f0       	push   $0xf01043b1
f0101b61:	68 03 03 00 00       	push   $0x303
f0101b66:	68 92 43 10 f0       	push   $0xf0104392
f0101b6b:	e8 24 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b70:	6a 02                	push   $0x2
f0101b72:	68 00 10 00 00       	push   $0x1000
f0101b77:	53                   	push   %ebx
f0101b78:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b7e:	e8 8f fc ff ff       	call   f0101812 <page_insert>
f0101b83:	83 c4 10             	add    $0x10,%esp
f0101b86:	85 c0                	test   %eax,%eax
f0101b88:	74 19                	je     f0101ba3 <check_page+0x330>
f0101b8a:	68 bc 3f 10 f0       	push   $0xf0103fbc
f0101b8f:	68 b1 43 10 f0       	push   $0xf01043b1
f0101b94:	68 06 03 00 00       	push   $0x306
f0101b99:	68 92 43 10 f0       	push   $0xf0104392
f0101b9e:	e8 f1 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ba3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ba8:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101bad:	e8 50 ef ff ff       	call   f0100b02 <check_va2pa>
f0101bb2:	89 c7                	mov    %eax,%edi
f0101bb4:	89 d8                	mov    %ebx,%eax
f0101bb6:	e8 5d ee ff ff       	call   f0100a18 <page2pa>
f0101bbb:	39 c7                	cmp    %eax,%edi
f0101bbd:	74 19                	je     f0101bd8 <check_page+0x365>
f0101bbf:	68 f8 3f 10 f0       	push   $0xf0103ff8
f0101bc4:	68 b1 43 10 f0       	push   $0xf01043b1
f0101bc9:	68 07 03 00 00       	push   $0x307
f0101bce:	68 92 43 10 f0       	push   $0xf0104392
f0101bd3:	e8 bc e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101bd8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101bdd:	74 19                	je     f0101bf8 <check_page+0x385>
f0101bdf:	68 16 46 10 f0       	push   $0xf0104616
f0101be4:	68 b1 43 10 f0       	push   $0xf01043b1
f0101be9:	68 08 03 00 00       	push   $0x308
f0101bee:	68 92 43 10 f0       	push   $0xf0104392
f0101bf3:	e8 9c e4 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101bf8:	83 ec 0c             	sub    $0xc,%esp
f0101bfb:	6a 00                	push   $0x0
f0101bfd:	e8 59 f5 ff ff       	call   f010115b <page_alloc>
f0101c02:	83 c4 10             	add    $0x10,%esp
f0101c05:	85 c0                	test   %eax,%eax
f0101c07:	74 19                	je     f0101c22 <check_page+0x3af>
f0101c09:	68 6d 45 10 f0       	push   $0xf010456d
f0101c0e:	68 b1 43 10 f0       	push   $0xf01043b1
f0101c13:	68 0c 03 00 00       	push   $0x30c
f0101c18:	68 92 43 10 f0       	push   $0xf0104392
f0101c1d:	e8 72 e4 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c22:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101c28:	8b 0f                	mov    (%edi),%ecx
f0101c2a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101c30:	ba 0f 03 00 00       	mov    $0x30f,%edx
f0101c35:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0101c3a:	e8 79 ee ff ff       	call   f0100ab8 <_kaddr>
f0101c3f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c42:	83 ec 04             	sub    $0x4,%esp
f0101c45:	6a 00                	push   $0x0
f0101c47:	68 00 10 00 00       	push   $0x1000
f0101c4c:	57                   	push   %edi
f0101c4d:	e8 94 f9 ff ff       	call   f01015e6 <pgdir_walk>
f0101c52:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c55:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c58:	83 c4 10             	add    $0x10,%esp
f0101c5b:	39 d0                	cmp    %edx,%eax
f0101c5d:	74 19                	je     f0101c78 <check_page+0x405>
f0101c5f:	68 28 40 10 f0       	push   $0xf0104028
f0101c64:	68 b1 43 10 f0       	push   $0xf01043b1
f0101c69:	68 10 03 00 00       	push   $0x310
f0101c6e:	68 92 43 10 f0       	push   $0xf0104392
f0101c73:	e8 1c e4 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c78:	6a 06                	push   $0x6
f0101c7a:	68 00 10 00 00       	push   $0x1000
f0101c7f:	53                   	push   %ebx
f0101c80:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101c86:	e8 87 fb ff ff       	call   f0101812 <page_insert>
f0101c8b:	83 c4 10             	add    $0x10,%esp
f0101c8e:	85 c0                	test   %eax,%eax
f0101c90:	74 19                	je     f0101cab <check_page+0x438>
f0101c92:	68 68 40 10 f0       	push   $0xf0104068
f0101c97:	68 b1 43 10 f0       	push   $0xf01043b1
f0101c9c:	68 13 03 00 00       	push   $0x313
f0101ca1:	68 92 43 10 f0       	push   $0xf0104392
f0101ca6:	e8 e9 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cab:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101cb1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cb6:	89 f8                	mov    %edi,%eax
f0101cb8:	e8 45 ee ff ff       	call   f0100b02 <check_va2pa>
f0101cbd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101cc0:	89 d8                	mov    %ebx,%eax
f0101cc2:	e8 51 ed ff ff       	call   f0100a18 <page2pa>
f0101cc7:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101cca:	74 19                	je     f0101ce5 <check_page+0x472>
f0101ccc:	68 f8 3f 10 f0       	push   $0xf0103ff8
f0101cd1:	68 b1 43 10 f0       	push   $0xf01043b1
f0101cd6:	68 14 03 00 00       	push   $0x314
f0101cdb:	68 92 43 10 f0       	push   $0xf0104392
f0101ce0:	e8 af e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ce5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cea:	74 19                	je     f0101d05 <check_page+0x492>
f0101cec:	68 16 46 10 f0       	push   $0xf0104616
f0101cf1:	68 b1 43 10 f0       	push   $0xf01043b1
f0101cf6:	68 15 03 00 00       	push   $0x315
f0101cfb:	68 92 43 10 f0       	push   $0xf0104392
f0101d00:	e8 8f e3 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d05:	83 ec 04             	sub    $0x4,%esp
f0101d08:	6a 00                	push   $0x0
f0101d0a:	68 00 10 00 00       	push   $0x1000
f0101d0f:	57                   	push   %edi
f0101d10:	e8 d1 f8 ff ff       	call   f01015e6 <pgdir_walk>
f0101d15:	83 c4 10             	add    $0x10,%esp
f0101d18:	f6 00 04             	testb  $0x4,(%eax)
f0101d1b:	75 19                	jne    f0101d36 <check_page+0x4c3>
f0101d1d:	68 a8 40 10 f0       	push   $0xf01040a8
f0101d22:	68 b1 43 10 f0       	push   $0xf01043b1
f0101d27:	68 16 03 00 00       	push   $0x316
f0101d2c:	68 92 43 10 f0       	push   $0xf0104392
f0101d31:	e8 5e e3 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d36:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101d3b:	f6 00 04             	testb  $0x4,(%eax)
f0101d3e:	75 19                	jne    f0101d59 <check_page+0x4e6>
f0101d40:	68 27 46 10 f0       	push   $0xf0104627
f0101d45:	68 b1 43 10 f0       	push   $0xf01043b1
f0101d4a:	68 17 03 00 00       	push   $0x317
f0101d4f:	68 92 43 10 f0       	push   $0xf0104392
f0101d54:	e8 3b e3 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d59:	6a 02                	push   $0x2
f0101d5b:	68 00 10 00 00       	push   $0x1000
f0101d60:	53                   	push   %ebx
f0101d61:	50                   	push   %eax
f0101d62:	e8 ab fa ff ff       	call   f0101812 <page_insert>
f0101d67:	83 c4 10             	add    $0x10,%esp
f0101d6a:	85 c0                	test   %eax,%eax
f0101d6c:	74 19                	je     f0101d87 <check_page+0x514>
f0101d6e:	68 bc 3f 10 f0       	push   $0xf0103fbc
f0101d73:	68 b1 43 10 f0       	push   $0xf01043b1
f0101d78:	68 1a 03 00 00       	push   $0x31a
f0101d7d:	68 92 43 10 f0       	push   $0xf0104392
f0101d82:	e8 0d e3 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d87:	83 ec 04             	sub    $0x4,%esp
f0101d8a:	6a 00                	push   $0x0
f0101d8c:	68 00 10 00 00       	push   $0x1000
f0101d91:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101d97:	e8 4a f8 ff ff       	call   f01015e6 <pgdir_walk>
f0101d9c:	83 c4 10             	add    $0x10,%esp
f0101d9f:	f6 00 02             	testb  $0x2,(%eax)
f0101da2:	75 19                	jne    f0101dbd <check_page+0x54a>
f0101da4:	68 dc 40 10 f0       	push   $0xf01040dc
f0101da9:	68 b1 43 10 f0       	push   $0xf01043b1
f0101dae:	68 1b 03 00 00       	push   $0x31b
f0101db3:	68 92 43 10 f0       	push   $0xf0104392
f0101db8:	e8 d7 e2 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101dbd:	83 ec 04             	sub    $0x4,%esp
f0101dc0:	6a 00                	push   $0x0
f0101dc2:	68 00 10 00 00       	push   $0x1000
f0101dc7:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101dcd:	e8 14 f8 ff ff       	call   f01015e6 <pgdir_walk>
f0101dd2:	83 c4 10             	add    $0x10,%esp
f0101dd5:	f6 00 04             	testb  $0x4,(%eax)
f0101dd8:	74 19                	je     f0101df3 <check_page+0x580>
f0101dda:	68 10 41 10 f0       	push   $0xf0104110
f0101ddf:	68 b1 43 10 f0       	push   $0xf01043b1
f0101de4:	68 1c 03 00 00       	push   $0x31c
f0101de9:	68 92 43 10 f0       	push   $0xf0104392
f0101dee:	e8 a1 e2 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101df3:	6a 02                	push   $0x2
f0101df5:	68 00 00 40 00       	push   $0x400000
f0101dfa:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101dfd:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e03:	e8 0a fa ff ff       	call   f0101812 <page_insert>
f0101e08:	83 c4 10             	add    $0x10,%esp
f0101e0b:	85 c0                	test   %eax,%eax
f0101e0d:	78 19                	js     f0101e28 <check_page+0x5b5>
f0101e0f:	68 48 41 10 f0       	push   $0xf0104148
f0101e14:	68 b1 43 10 f0       	push   $0xf01043b1
f0101e19:	68 1f 03 00 00       	push   $0x31f
f0101e1e:	68 92 43 10 f0       	push   $0xf0104392
f0101e23:	e8 6c e2 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e28:	6a 02                	push   $0x2
f0101e2a:	68 00 10 00 00       	push   $0x1000
f0101e2f:	56                   	push   %esi
f0101e30:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e36:	e8 d7 f9 ff ff       	call   f0101812 <page_insert>
f0101e3b:	83 c4 10             	add    $0x10,%esp
f0101e3e:	85 c0                	test   %eax,%eax
f0101e40:	74 19                	je     f0101e5b <check_page+0x5e8>
f0101e42:	68 80 41 10 f0       	push   $0xf0104180
f0101e47:	68 b1 43 10 f0       	push   $0xf01043b1
f0101e4c:	68 22 03 00 00       	push   $0x322
f0101e51:	68 92 43 10 f0       	push   $0xf0104392
f0101e56:	e8 39 e2 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e5b:	83 ec 04             	sub    $0x4,%esp
f0101e5e:	6a 00                	push   $0x0
f0101e60:	68 00 10 00 00       	push   $0x1000
f0101e65:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101e6b:	e8 76 f7 ff ff       	call   f01015e6 <pgdir_walk>
f0101e70:	83 c4 10             	add    $0x10,%esp
f0101e73:	f6 00 04             	testb  $0x4,(%eax)
f0101e76:	74 19                	je     f0101e91 <check_page+0x61e>
f0101e78:	68 10 41 10 f0       	push   $0xf0104110
f0101e7d:	68 b1 43 10 f0       	push   $0xf01043b1
f0101e82:	68 23 03 00 00       	push   $0x323
f0101e87:	68 92 43 10 f0       	push   $0xf0104392
f0101e8c:	e8 03 e2 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e91:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101e97:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e9c:	89 f8                	mov    %edi,%eax
f0101e9e:	e8 5f ec ff ff       	call   f0100b02 <check_va2pa>
f0101ea3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ea6:	89 f0                	mov    %esi,%eax
f0101ea8:	e8 6b eb ff ff       	call   f0100a18 <page2pa>
f0101ead:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101eb0:	74 19                	je     f0101ecb <check_page+0x658>
f0101eb2:	68 bc 41 10 f0       	push   $0xf01041bc
f0101eb7:	68 b1 43 10 f0       	push   $0xf01043b1
f0101ebc:	68 26 03 00 00       	push   $0x326
f0101ec1:	68 92 43 10 f0       	push   $0xf0104392
f0101ec6:	e8 c9 e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ecb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ed0:	89 f8                	mov    %edi,%eax
f0101ed2:	e8 2b ec ff ff       	call   f0100b02 <check_va2pa>
f0101ed7:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101eda:	74 19                	je     f0101ef5 <check_page+0x682>
f0101edc:	68 e8 41 10 f0       	push   $0xf01041e8
f0101ee1:	68 b1 43 10 f0       	push   $0xf01043b1
f0101ee6:	68 27 03 00 00       	push   $0x327
f0101eeb:	68 92 43 10 f0       	push   $0xf0104392
f0101ef0:	e8 9f e1 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ef5:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101efa:	74 19                	je     f0101f15 <check_page+0x6a2>
f0101efc:	68 3d 46 10 f0       	push   $0xf010463d
f0101f01:	68 b1 43 10 f0       	push   $0xf01043b1
f0101f06:	68 29 03 00 00       	push   $0x329
f0101f0b:	68 92 43 10 f0       	push   $0xf0104392
f0101f10:	e8 7f e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0101f15:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f1a:	74 19                	je     f0101f35 <check_page+0x6c2>
f0101f1c:	68 4e 46 10 f0       	push   $0xf010464e
f0101f21:	68 b1 43 10 f0       	push   $0xf01043b1
f0101f26:	68 2a 03 00 00       	push   $0x32a
f0101f2b:	68 92 43 10 f0       	push   $0xf0104392
f0101f30:	e8 5f e1 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f35:	83 ec 0c             	sub    $0xc,%esp
f0101f38:	6a 00                	push   $0x0
f0101f3a:	e8 1c f2 ff ff       	call   f010115b <page_alloc>
f0101f3f:	83 c4 10             	add    $0x10,%esp
f0101f42:	39 c3                	cmp    %eax,%ebx
f0101f44:	75 04                	jne    f0101f4a <check_page+0x6d7>
f0101f46:	85 c0                	test   %eax,%eax
f0101f48:	75 19                	jne    f0101f63 <check_page+0x6f0>
f0101f4a:	68 18 42 10 f0       	push   $0xf0104218
f0101f4f:	68 b1 43 10 f0       	push   $0xf01043b1
f0101f54:	68 2d 03 00 00       	push   $0x32d
f0101f59:	68 92 43 10 f0       	push   $0xf0104392
f0101f5e:	e8 31 e1 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f63:	83 ec 08             	sub    $0x8,%esp
f0101f66:	6a 00                	push   $0x0
f0101f68:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101f6e:	e8 59 f8 ff ff       	call   f01017cc <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f73:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0101f79:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f7e:	89 f8                	mov    %edi,%eax
f0101f80:	e8 7d eb ff ff       	call   f0100b02 <check_va2pa>
f0101f85:	83 c4 10             	add    $0x10,%esp
f0101f88:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f8b:	74 19                	je     f0101fa6 <check_page+0x733>
f0101f8d:	68 3c 42 10 f0       	push   $0xf010423c
f0101f92:	68 b1 43 10 f0       	push   $0xf01043b1
f0101f97:	68 31 03 00 00       	push   $0x331
f0101f9c:	68 92 43 10 f0       	push   $0xf0104392
f0101fa1:	e8 ee e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fa6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fab:	89 f8                	mov    %edi,%eax
f0101fad:	e8 50 eb ff ff       	call   f0100b02 <check_va2pa>
f0101fb2:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101fb5:	89 f0                	mov    %esi,%eax
f0101fb7:	e8 5c ea ff ff       	call   f0100a18 <page2pa>
f0101fbc:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101fbf:	74 19                	je     f0101fda <check_page+0x767>
f0101fc1:	68 e8 41 10 f0       	push   $0xf01041e8
f0101fc6:	68 b1 43 10 f0       	push   $0xf01043b1
f0101fcb:	68 32 03 00 00       	push   $0x332
f0101fd0:	68 92 43 10 f0       	push   $0xf0104392
f0101fd5:	e8 ba e0 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101fda:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fdf:	74 19                	je     f0101ffa <check_page+0x787>
f0101fe1:	68 f4 45 10 f0       	push   $0xf01045f4
f0101fe6:	68 b1 43 10 f0       	push   $0xf01043b1
f0101feb:	68 33 03 00 00       	push   $0x333
f0101ff0:	68 92 43 10 f0       	push   $0xf0104392
f0101ff5:	e8 9a e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0101ffa:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101fff:	74 19                	je     f010201a <check_page+0x7a7>
f0102001:	68 4e 46 10 f0       	push   $0xf010464e
f0102006:	68 b1 43 10 f0       	push   $0xf01043b1
f010200b:	68 34 03 00 00       	push   $0x334
f0102010:	68 92 43 10 f0       	push   $0xf0104392
f0102015:	e8 7a e0 ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010201a:	6a 00                	push   $0x0
f010201c:	68 00 10 00 00       	push   $0x1000
f0102021:	56                   	push   %esi
f0102022:	57                   	push   %edi
f0102023:	e8 ea f7 ff ff       	call   f0101812 <page_insert>
f0102028:	83 c4 10             	add    $0x10,%esp
f010202b:	85 c0                	test   %eax,%eax
f010202d:	74 19                	je     f0102048 <check_page+0x7d5>
f010202f:	68 60 42 10 f0       	push   $0xf0104260
f0102034:	68 b1 43 10 f0       	push   $0xf01043b1
f0102039:	68 37 03 00 00       	push   $0x337
f010203e:	68 92 43 10 f0       	push   $0xf0104392
f0102043:	e8 4c e0 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f0102048:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010204d:	75 19                	jne    f0102068 <check_page+0x7f5>
f010204f:	68 5f 46 10 f0       	push   $0xf010465f
f0102054:	68 b1 43 10 f0       	push   $0xf01043b1
f0102059:	68 38 03 00 00       	push   $0x338
f010205e:	68 92 43 10 f0       	push   $0xf0104392
f0102063:	e8 2c e0 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f0102068:	83 3e 00             	cmpl   $0x0,(%esi)
f010206b:	74 19                	je     f0102086 <check_page+0x813>
f010206d:	68 6b 46 10 f0       	push   $0xf010466b
f0102072:	68 b1 43 10 f0       	push   $0xf01043b1
f0102077:	68 39 03 00 00       	push   $0x339
f010207c:	68 92 43 10 f0       	push   $0xf0104392
f0102081:	e8 0e e0 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102086:	83 ec 08             	sub    $0x8,%esp
f0102089:	68 00 10 00 00       	push   $0x1000
f010208e:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102094:	e8 33 f7 ff ff       	call   f01017cc <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102099:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f010209f:	ba 00 00 00 00       	mov    $0x0,%edx
f01020a4:	89 f8                	mov    %edi,%eax
f01020a6:	e8 57 ea ff ff       	call   f0100b02 <check_va2pa>
f01020ab:	83 c4 10             	add    $0x10,%esp
f01020ae:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020b1:	74 19                	je     f01020cc <check_page+0x859>
f01020b3:	68 3c 42 10 f0       	push   $0xf010423c
f01020b8:	68 b1 43 10 f0       	push   $0xf01043b1
f01020bd:	68 3d 03 00 00       	push   $0x33d
f01020c2:	68 92 43 10 f0       	push   $0xf0104392
f01020c7:	e8 c8 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020cc:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020d1:	89 f8                	mov    %edi,%eax
f01020d3:	e8 2a ea ff ff       	call   f0100b02 <check_va2pa>
f01020d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020db:	74 19                	je     f01020f6 <check_page+0x883>
f01020dd:	68 98 42 10 f0       	push   $0xf0104298
f01020e2:	68 b1 43 10 f0       	push   $0xf01043b1
f01020e7:	68 3e 03 00 00       	push   $0x33e
f01020ec:	68 92 43 10 f0       	push   $0xf0104392
f01020f1:	e8 9e df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01020f6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020fb:	74 19                	je     f0102116 <check_page+0x8a3>
f01020fd:	68 80 46 10 f0       	push   $0xf0104680
f0102102:	68 b1 43 10 f0       	push   $0xf01043b1
f0102107:	68 3f 03 00 00       	push   $0x33f
f010210c:	68 92 43 10 f0       	push   $0xf0104392
f0102111:	e8 7e df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102116:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010211b:	74 19                	je     f0102136 <check_page+0x8c3>
f010211d:	68 4e 46 10 f0       	push   $0xf010464e
f0102122:	68 b1 43 10 f0       	push   $0xf01043b1
f0102127:	68 40 03 00 00       	push   $0x340
f010212c:	68 92 43 10 f0       	push   $0xf0104392
f0102131:	e8 5e df ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102136:	83 ec 0c             	sub    $0xc,%esp
f0102139:	6a 00                	push   $0x0
f010213b:	e8 1b f0 ff ff       	call   f010115b <page_alloc>
f0102140:	83 c4 10             	add    $0x10,%esp
f0102143:	39 c6                	cmp    %eax,%esi
f0102145:	75 04                	jne    f010214b <check_page+0x8d8>
f0102147:	85 c0                	test   %eax,%eax
f0102149:	75 19                	jne    f0102164 <check_page+0x8f1>
f010214b:	68 c0 42 10 f0       	push   $0xf01042c0
f0102150:	68 b1 43 10 f0       	push   $0xf01043b1
f0102155:	68 43 03 00 00       	push   $0x343
f010215a:	68 92 43 10 f0       	push   $0xf0104392
f010215f:	e8 30 df ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102164:	83 ec 0c             	sub    $0xc,%esp
f0102167:	6a 00                	push   $0x0
f0102169:	e8 ed ef ff ff       	call   f010115b <page_alloc>
f010216e:	83 c4 10             	add    $0x10,%esp
f0102171:	85 c0                	test   %eax,%eax
f0102173:	74 19                	je     f010218e <check_page+0x91b>
f0102175:	68 6d 45 10 f0       	push   $0xf010456d
f010217a:	68 b1 43 10 f0       	push   $0xf01043b1
f010217f:	68 46 03 00 00       	push   $0x346
f0102184:	68 92 43 10 f0       	push   $0xf0104392
f0102189:	e8 06 df ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010218e:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f0102194:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102197:	e8 7c e8 ff ff       	call   f0100a18 <page2pa>
f010219c:	8b 17                	mov    (%edi),%edx
f010219e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01021a4:	39 c2                	cmp    %eax,%edx
f01021a6:	74 19                	je     f01021c1 <check_page+0x94e>
f01021a8:	68 64 3f 10 f0       	push   $0xf0103f64
f01021ad:	68 b1 43 10 f0       	push   $0xf01043b1
f01021b2:	68 49 03 00 00       	push   $0x349
f01021b7:	68 92 43 10 f0       	push   $0xf0104392
f01021bc:	e8 d3 de ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01021c1:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	assert(pp0->pp_ref == 1);
f01021c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ca:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021cf:	74 19                	je     f01021ea <check_page+0x977>
f01021d1:	68 05 46 10 f0       	push   $0xf0104605
f01021d6:	68 b1 43 10 f0       	push   $0xf01043b1
f01021db:	68 4b 03 00 00       	push   $0x34b
f01021e0:	68 92 43 10 f0       	push   $0xf0104392
f01021e5:	e8 aa de ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01021ea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ed:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01021f3:	83 ec 0c             	sub    $0xc,%esp
f01021f6:	50                   	push   %eax
f01021f7:	e8 a4 ef ff ff       	call   f01011a0 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01021fc:	83 c4 0c             	add    $0xc,%esp
f01021ff:	6a 01                	push   $0x1
f0102201:	68 00 10 40 00       	push   $0x401000
f0102206:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010220c:	e8 d5 f3 ff ff       	call   f01015e6 <pgdir_walk>
f0102211:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102214:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102217:	8b 3d 48 79 11 f0    	mov    0xf0117948,%edi
f010221d:	8b 4f 04             	mov    0x4(%edi),%ecx
f0102220:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102226:	ba 52 03 00 00       	mov    $0x352,%edx
f010222b:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0102230:	e8 83 e8 ff ff       	call   f0100ab8 <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f0102235:	83 c0 04             	add    $0x4,%eax
f0102238:	83 c4 10             	add    $0x10,%esp
f010223b:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010223e:	74 19                	je     f0102259 <check_page+0x9e6>
f0102240:	68 91 46 10 f0       	push   $0xf0104691
f0102245:	68 b1 43 10 f0       	push   $0xf01043b1
f010224a:	68 53 03 00 00       	push   $0x353
f010224f:	68 92 43 10 f0       	push   $0xf0104392
f0102254:	e8 3b de ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102259:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f0102260:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102263:	89 f8                	mov    %edi,%eax
f0102265:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010226b:	e8 74 e8 ff ff       	call   f0100ae4 <page2kva>
f0102270:	83 ec 04             	sub    $0x4,%esp
f0102273:	68 00 10 00 00       	push   $0x1000
f0102278:	68 ff 00 00 00       	push   $0xff
f010227d:	50                   	push   %eax
f010227e:	e8 a6 0f 00 00       	call   f0103229 <memset>
	page_free(pp0);
f0102283:	89 3c 24             	mov    %edi,(%esp)
f0102286:	e8 15 ef ff ff       	call   f01011a0 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010228b:	83 c4 0c             	add    $0xc,%esp
f010228e:	6a 01                	push   $0x1
f0102290:	6a 00                	push   $0x0
f0102292:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0102298:	e8 49 f3 ff ff       	call   f01015e6 <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f010229d:	89 f8                	mov    %edi,%eax
f010229f:	e8 40 e8 ff ff       	call   f0100ae4 <page2kva>
f01022a4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022a7:	89 c2                	mov    %eax,%edx
f01022a9:	05 00 10 00 00       	add    $0x1000,%eax
f01022ae:	83 c4 10             	add    $0x10,%esp
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022b1:	f6 02 01             	testb  $0x1,(%edx)
f01022b4:	74 19                	je     f01022cf <check_page+0xa5c>
f01022b6:	68 a9 46 10 f0       	push   $0xf01046a9
f01022bb:	68 b1 43 10 f0       	push   $0xf01043b1
f01022c0:	68 5d 03 00 00       	push   $0x35d
f01022c5:	68 92 43 10 f0       	push   $0xf0104392
f01022ca:	e8 c5 dd ff ff       	call   f0100094 <_panic>
f01022cf:	83 c2 04             	add    $0x4,%edx
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022d2:	39 c2                	cmp    %eax,%edx
f01022d4:	75 db                	jne    f01022b1 <check_page+0xa3e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022d6:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01022db:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022e4:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022ea:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01022ed:	89 0d 3c 65 11 f0    	mov    %ecx,0xf011653c

	// free the pages we took
	page_free(pp0);
f01022f3:	83 ec 0c             	sub    $0xc,%esp
f01022f6:	50                   	push   %eax
f01022f7:	e8 a4 ee ff ff       	call   f01011a0 <page_free>
	page_free(pp1);
f01022fc:	89 34 24             	mov    %esi,(%esp)
f01022ff:	e8 9c ee ff ff       	call   f01011a0 <page_free>
	page_free(pp2);
f0102304:	89 1c 24             	mov    %ebx,(%esp)
f0102307:	e8 94 ee ff ff       	call   f01011a0 <page_free>

	cprintf("check_page() succeeded!\n");
f010230c:	c7 04 24 c0 46 10 f0 	movl   $0xf01046c0,(%esp)
f0102313:	e8 6d 04 00 00       	call   f0102785 <cprintf>
}
f0102318:	83 c4 10             	add    $0x10,%esp
f010231b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010231e:	5b                   	pop    %ebx
f010231f:	5e                   	pop    %esi
f0102320:	5f                   	pop    %edi
f0102321:	5d                   	pop    %ebp
f0102322:	c3                   	ret    

f0102323 <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f0102323:	55                   	push   %ebp
f0102324:	89 e5                	mov    %esp,%ebp
f0102326:	57                   	push   %edi
f0102327:	56                   	push   %esi
f0102328:	53                   	push   %ebx
f0102329:	83 ec 18             	sub    $0x18,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010232c:	6a 00                	push   $0x0
f010232e:	e8 28 ee ff ff       	call   f010115b <page_alloc>
f0102333:	83 c4 10             	add    $0x10,%esp
f0102336:	85 c0                	test   %eax,%eax
f0102338:	75 19                	jne    f0102353 <check_page_installed_pgdir+0x30>
f010233a:	68 c2 44 10 f0       	push   $0xf01044c2
f010233f:	68 b1 43 10 f0       	push   $0xf01043b1
f0102344:	68 78 03 00 00       	push   $0x378
f0102349:	68 92 43 10 f0       	push   $0xf0104392
f010234e:	e8 41 dd ff ff       	call   f0100094 <_panic>
f0102353:	89 c6                	mov    %eax,%esi
	assert((pp1 = page_alloc(0)));
f0102355:	83 ec 0c             	sub    $0xc,%esp
f0102358:	6a 00                	push   $0x0
f010235a:	e8 fc ed ff ff       	call   f010115b <page_alloc>
f010235f:	89 c7                	mov    %eax,%edi
f0102361:	83 c4 10             	add    $0x10,%esp
f0102364:	85 c0                	test   %eax,%eax
f0102366:	75 19                	jne    f0102381 <check_page_installed_pgdir+0x5e>
f0102368:	68 d8 44 10 f0       	push   $0xf01044d8
f010236d:	68 b1 43 10 f0       	push   $0xf01043b1
f0102372:	68 79 03 00 00       	push   $0x379
f0102377:	68 92 43 10 f0       	push   $0xf0104392
f010237c:	e8 13 dd ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102381:	83 ec 0c             	sub    $0xc,%esp
f0102384:	6a 00                	push   $0x0
f0102386:	e8 d0 ed ff ff       	call   f010115b <page_alloc>
f010238b:	89 c3                	mov    %eax,%ebx
f010238d:	83 c4 10             	add    $0x10,%esp
f0102390:	85 c0                	test   %eax,%eax
f0102392:	75 19                	jne    f01023ad <check_page_installed_pgdir+0x8a>
f0102394:	68 ee 44 10 f0       	push   $0xf01044ee
f0102399:	68 b1 43 10 f0       	push   $0xf01043b1
f010239e:	68 7a 03 00 00       	push   $0x37a
f01023a3:	68 92 43 10 f0       	push   $0xf0104392
f01023a8:	e8 e7 dc ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01023ad:	83 ec 0c             	sub    $0xc,%esp
f01023b0:	56                   	push   %esi
f01023b1:	e8 ea ed ff ff       	call   f01011a0 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01023b6:	89 f8                	mov    %edi,%eax
f01023b8:	e8 27 e7 ff ff       	call   f0100ae4 <page2kva>
f01023bd:	83 c4 0c             	add    $0xc,%esp
f01023c0:	68 00 10 00 00       	push   $0x1000
f01023c5:	6a 01                	push   $0x1
f01023c7:	50                   	push   %eax
f01023c8:	e8 5c 0e 00 00       	call   f0103229 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01023cd:	89 d8                	mov    %ebx,%eax
f01023cf:	e8 10 e7 ff ff       	call   f0100ae4 <page2kva>
f01023d4:	83 c4 0c             	add    $0xc,%esp
f01023d7:	68 00 10 00 00       	push   $0x1000
f01023dc:	6a 02                	push   $0x2
f01023de:	50                   	push   %eax
f01023df:	e8 45 0e 00 00       	call   f0103229 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01023e4:	6a 02                	push   $0x2
f01023e6:	68 00 10 00 00       	push   $0x1000
f01023eb:	57                   	push   %edi
f01023ec:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01023f2:	e8 1b f4 ff ff       	call   f0101812 <page_insert>
	assert(pp1->pp_ref == 1);
f01023f7:	83 c4 20             	add    $0x20,%esp
f01023fa:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01023ff:	74 19                	je     f010241a <check_page_installed_pgdir+0xf7>
f0102401:	68 f4 45 10 f0       	push   $0xf01045f4
f0102406:	68 b1 43 10 f0       	push   $0xf01043b1
f010240b:	68 7f 03 00 00       	push   $0x37f
f0102410:	68 92 43 10 f0       	push   $0xf0104392
f0102415:	e8 7a dc ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010241a:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102421:	01 01 01 
f0102424:	74 19                	je     f010243f <check_page_installed_pgdir+0x11c>
f0102426:	68 e4 42 10 f0       	push   $0xf01042e4
f010242b:	68 b1 43 10 f0       	push   $0xf01043b1
f0102430:	68 80 03 00 00       	push   $0x380
f0102435:	68 92 43 10 f0       	push   $0xf0104392
f010243a:	e8 55 dc ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010243f:	6a 02                	push   $0x2
f0102441:	68 00 10 00 00       	push   $0x1000
f0102446:	53                   	push   %ebx
f0102447:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010244d:	e8 c0 f3 ff ff       	call   f0101812 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102452:	83 c4 10             	add    $0x10,%esp
f0102455:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010245c:	02 02 02 
f010245f:	74 19                	je     f010247a <check_page_installed_pgdir+0x157>
f0102461:	68 08 43 10 f0       	push   $0xf0104308
f0102466:	68 b1 43 10 f0       	push   $0xf01043b1
f010246b:	68 82 03 00 00       	push   $0x382
f0102470:	68 92 43 10 f0       	push   $0xf0104392
f0102475:	e8 1a dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f010247a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010247f:	74 19                	je     f010249a <check_page_installed_pgdir+0x177>
f0102481:	68 16 46 10 f0       	push   $0xf0104616
f0102486:	68 b1 43 10 f0       	push   $0xf01043b1
f010248b:	68 83 03 00 00       	push   $0x383
f0102490:	68 92 43 10 f0       	push   $0xf0104392
f0102495:	e8 fa db ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010249a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010249f:	74 19                	je     f01024ba <check_page_installed_pgdir+0x197>
f01024a1:	68 80 46 10 f0       	push   $0xf0104680
f01024a6:	68 b1 43 10 f0       	push   $0xf01043b1
f01024ab:	68 84 03 00 00       	push   $0x384
f01024b0:	68 92 43 10 f0       	push   $0xf0104392
f01024b5:	e8 da db ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01024ba:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01024c1:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024c4:	89 d8                	mov    %ebx,%eax
f01024c6:	e8 19 e6 ff ff       	call   f0100ae4 <page2kva>
f01024cb:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01024d1:	74 19                	je     f01024ec <check_page_installed_pgdir+0x1c9>
f01024d3:	68 2c 43 10 f0       	push   $0xf010432c
f01024d8:	68 b1 43 10 f0       	push   $0xf01043b1
f01024dd:	68 86 03 00 00       	push   $0x386
f01024e2:	68 92 43 10 f0       	push   $0xf0104392
f01024e7:	e8 a8 db ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01024ec:	83 ec 08             	sub    $0x8,%esp
f01024ef:	68 00 10 00 00       	push   $0x1000
f01024f4:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01024fa:	e8 cd f2 ff ff       	call   f01017cc <page_remove>
	assert(pp2->pp_ref == 0);
f01024ff:	83 c4 10             	add    $0x10,%esp
f0102502:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102507:	74 19                	je     f0102522 <check_page_installed_pgdir+0x1ff>
f0102509:	68 4e 46 10 f0       	push   $0xf010464e
f010250e:	68 b1 43 10 f0       	push   $0xf01043b1
f0102513:	68 88 03 00 00       	push   $0x388
f0102518:	68 92 43 10 f0       	push   $0xf0104392
f010251d:	e8 72 db ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102522:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f0102528:	89 f0                	mov    %esi,%eax
f010252a:	e8 e9 e4 ff ff       	call   f0100a18 <page2pa>
f010252f:	8b 13                	mov    (%ebx),%edx
f0102531:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102537:	39 c2                	cmp    %eax,%edx
f0102539:	74 19                	je     f0102554 <check_page_installed_pgdir+0x231>
f010253b:	68 64 3f 10 f0       	push   $0xf0103f64
f0102540:	68 b1 43 10 f0       	push   $0xf01043b1
f0102545:	68 8b 03 00 00       	push   $0x38b
f010254a:	68 92 43 10 f0       	push   $0xf0104392
f010254f:	e8 40 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102554:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f010255a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010255f:	74 19                	je     f010257a <check_page_installed_pgdir+0x257>
f0102561:	68 05 46 10 f0       	push   $0xf0104605
f0102566:	68 b1 43 10 f0       	push   $0xf01043b1
f010256b:	68 8d 03 00 00       	push   $0x38d
f0102570:	68 92 43 10 f0       	push   $0xf0104392
f0102575:	e8 1a db ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f010257a:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102580:	83 ec 0c             	sub    $0xc,%esp
f0102583:	56                   	push   %esi
f0102584:	e8 17 ec ff ff       	call   f01011a0 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102589:	c7 04 24 58 43 10 f0 	movl   $0xf0104358,(%esp)
f0102590:	e8 f0 01 00 00       	call   f0102785 <cprintf>
}
f0102595:	83 c4 10             	add    $0x10,%esp
f0102598:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010259b:	5b                   	pop    %ebx
f010259c:	5e                   	pop    %esi
f010259d:	5f                   	pop    %edi
f010259e:	5d                   	pop    %ebp
f010259f:	c3                   	ret    

f01025a0 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01025a0:	55                   	push   %ebp
f01025a1:	89 e5                	mov    %esp,%ebp
f01025a3:	53                   	push   %ebx
f01025a4:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f01025a7:	e8 a6 e4 ff ff       	call   f0100a52 <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01025ac:	b8 00 10 00 00       	mov    $0x1000,%eax
f01025b1:	e8 de e5 ff ff       	call   f0100b94 <boot_alloc>
f01025b6:	a3 48 79 11 f0       	mov    %eax,0xf0117948
	memset(kern_pgdir, 0, PGSIZE);
f01025bb:	83 ec 04             	sub    $0x4,%esp
f01025be:	68 00 10 00 00       	push   $0x1000
f01025c3:	6a 00                	push   $0x0
f01025c5:	50                   	push   %eax
f01025c6:	e8 5e 0c 00 00       	call   f0103229 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01025cb:	8b 1d 48 79 11 f0    	mov    0xf0117948,%ebx
f01025d1:	89 d9                	mov    %ebx,%ecx
f01025d3:	ba 92 00 00 00       	mov    $0x92,%edx
f01025d8:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f01025dd:	e8 90 e5 ff ff       	call   f0100b72 <_paddr>
f01025e2:	83 c8 05             	or     $0x5,%eax
f01025e5:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages //[page]
f01025eb:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f01025f0:	c1 e0 03             	shl    $0x3,%eax
f01025f3:	e8 9c e5 ff ff       	call   f0100b94 <boot_alloc>
f01025f8:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
					 * sizeof(struct PageInfo));//[B/page]
	memset(pages,0,npages*sizeof(struct PageInfo));
f01025fd:	83 c4 0c             	add    $0xc,%esp
f0102600:	8b 1d 44 79 11 f0    	mov    0xf0117944,%ebx
f0102606:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
f010260d:	52                   	push   %edx
f010260e:	6a 00                	push   $0x0
f0102610:	50                   	push   %eax
f0102611:	e8 13 0c 00 00       	call   f0103229 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0102616:	e8 c2 ea ff ff       	call   f01010dd <page_init>

	check_page_free_list(1);
f010261b:	b8 01 00 00 00       	mov    $0x1,%eax
f0102620:	e8 f3 e7 ff ff       	call   f0100e18 <check_page_free_list>
	check_page_alloc();
f0102625:	e8 c8 eb ff ff       	call   f01011f2 <check_page_alloc>
	check_page();
f010262a:	e8 44 f2 ff ff       	call   f0101873 <check_page>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,npages*sizeof(struct PageInfo),PADDR(pages),PTE_U|PTE_P);
f010262f:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
f0102635:	ba b4 00 00 00       	mov    $0xb4,%edx
f010263a:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f010263f:	e8 2e e5 ff ff       	call   f0100b72 <_paddr>
f0102644:	8b 1d 44 79 11 f0    	mov    0xf0117944,%ebx
f010264a:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
f0102651:	83 c4 08             	add    $0x8,%esp
f0102654:	6a 05                	push   $0x5
f0102656:	50                   	push   %eax
f0102657:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010265c:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0102661:	e8 1f f0 ff ff       	call   f0101685 <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_P|PTE_W);
f0102666:	b9 00 d0 10 f0       	mov    $0xf010d000,%ecx
f010266b:	ba c0 00 00 00       	mov    $0xc0,%edx
f0102670:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f0102675:	e8 f8 e4 ff ff       	call   f0100b72 <_paddr>
f010267a:	83 c4 08             	add    $0x8,%esp
f010267d:	6a 03                	push   $0x3
f010267f:	50                   	push   %eax
f0102680:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102685:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010268a:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f010268f:	e8 f1 ef ff ff       	call   f0101685 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,~0x0-KERNBASE+1,0,PTE_P|PTE_W);
f0102694:	83 c4 08             	add    $0x8,%esp
f0102697:	6a 03                	push   $0x3
f0102699:	6a 00                	push   $0x0
f010269b:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01026a0:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01026a5:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01026aa:	e8 d6 ef ff ff       	call   f0101685 <boot_map_region>
	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f01026af:	e8 5c e5 ff ff       	call   f0100c10 <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01026b4:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f01026ba:	ba d5 00 00 00       	mov    $0xd5,%edx
f01026bf:	b8 92 43 10 f0       	mov    $0xf0104392,%eax
f01026c4:	e8 a9 e4 ff ff       	call   f0100b72 <_paddr>
f01026c9:	e8 42 e3 ff ff       	call   f0100a10 <lcr3>

	check_page_free_list(0);
f01026ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01026d3:	e8 40 e7 ff ff       	call   f0100e18 <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f01026d8:	e8 2b e3 ff ff       	call   f0100a08 <rcr0>
f01026dd:	83 e0 f3             	and    $0xfffffff3,%eax
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);
f01026e0:	0d 23 00 05 80       	or     $0x80050023,%eax
f01026e5:	e8 16 e3 ff ff       	call   f0100a00 <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f01026ea:	e8 34 fc ff ff       	call   f0102323 <check_page_installed_pgdir>
}
f01026ef:	83 c4 10             	add    $0x10,%esp
f01026f2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01026f5:	c9                   	leave  
f01026f6:	c3                   	ret    

f01026f7 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f01026f7:	55                   	push   %ebp
f01026f8:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01026fa:	89 c2                	mov    %eax,%edx
f01026fc:	ec                   	in     (%dx),%al
	return data;
}
f01026fd:	5d                   	pop    %ebp
f01026fe:	c3                   	ret    

f01026ff <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f01026ff:	55                   	push   %ebp
f0102700:	89 e5                	mov    %esp,%ebp
f0102702:	89 c1                	mov    %eax,%ecx
f0102704:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102706:	89 ca                	mov    %ecx,%edx
f0102708:	ee                   	out    %al,(%dx)
}
f0102709:	5d                   	pop    %ebp
f010270a:	c3                   	ret    

f010270b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010270b:	55                   	push   %ebp
f010270c:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f010270e:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102712:	b8 70 00 00 00       	mov    $0x70,%eax
f0102717:	e8 e3 ff ff ff       	call   f01026ff <outb>
	return inb(IO_RTC+1);
f010271c:	b8 71 00 00 00       	mov    $0x71,%eax
f0102721:	e8 d1 ff ff ff       	call   f01026f7 <inb>
f0102726:	0f b6 c0             	movzbl %al,%eax
}
f0102729:	5d                   	pop    %ebp
f010272a:	c3                   	ret    

f010272b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010272b:	55                   	push   %ebp
f010272c:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f010272e:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102732:	b8 70 00 00 00       	mov    $0x70,%eax
f0102737:	e8 c3 ff ff ff       	call   f01026ff <outb>
	outb(IO_RTC+1, datum);
f010273c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0102740:	b8 71 00 00 00       	mov    $0x71,%eax
f0102745:	e8 b5 ff ff ff       	call   f01026ff <outb>
}
f010274a:	5d                   	pop    %ebp
f010274b:	c3                   	ret    

f010274c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010274c:	55                   	push   %ebp
f010274d:	89 e5                	mov    %esp,%ebp
f010274f:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102752:	ff 75 08             	pushl  0x8(%ebp)
f0102755:	e8 b4 df ff ff       	call   f010070e <cputchar>
	*cnt++;
}
f010275a:	83 c4 10             	add    $0x10,%esp
f010275d:	c9                   	leave  
f010275e:	c3                   	ret    

f010275f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010275f:	55                   	push   %ebp
f0102760:	89 e5                	mov    %esp,%ebp
f0102762:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102765:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010276c:	ff 75 0c             	pushl  0xc(%ebp)
f010276f:	ff 75 08             	pushl  0x8(%ebp)
f0102772:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102775:	50                   	push   %eax
f0102776:	68 4c 27 10 f0       	push   $0xf010274c
f010277b:	e8 82 04 00 00       	call   f0102c02 <vprintfmt>
	return cnt;
}
f0102780:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102783:	c9                   	leave  
f0102784:	c3                   	ret    

f0102785 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102785:	55                   	push   %ebp
f0102786:	89 e5                	mov    %esp,%ebp
f0102788:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010278b:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010278e:	50                   	push   %eax
f010278f:	ff 75 08             	pushl  0x8(%ebp)
f0102792:	e8 c8 ff ff ff       	call   f010275f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102797:	c9                   	leave  
f0102798:	c3                   	ret    

f0102799 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102799:	55                   	push   %ebp
f010279a:	89 e5                	mov    %esp,%ebp
f010279c:	57                   	push   %edi
f010279d:	56                   	push   %esi
f010279e:	53                   	push   %ebx
f010279f:	83 ec 14             	sub    $0x14,%esp
f01027a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01027a5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01027a8:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01027ab:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01027ae:	8b 1a                	mov    (%edx),%ebx
f01027b0:	8b 01                	mov    (%ecx),%eax
f01027b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01027b5:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01027bc:	eb 7f                	jmp    f010283d <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01027be:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01027c1:	01 d8                	add    %ebx,%eax
f01027c3:	89 c6                	mov    %eax,%esi
f01027c5:	c1 ee 1f             	shr    $0x1f,%esi
f01027c8:	01 c6                	add    %eax,%esi
f01027ca:	d1 fe                	sar    %esi
f01027cc:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01027cf:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027d2:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01027d5:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027d7:	eb 03                	jmp    f01027dc <stab_binsearch+0x43>
			m--;
f01027d9:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01027dc:	39 c3                	cmp    %eax,%ebx
f01027de:	7f 0d                	jg     f01027ed <stab_binsearch+0x54>
f01027e0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01027e4:	83 ea 0c             	sub    $0xc,%edx
f01027e7:	39 f9                	cmp    %edi,%ecx
f01027e9:	75 ee                	jne    f01027d9 <stab_binsearch+0x40>
f01027eb:	eb 05                	jmp    f01027f2 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01027ed:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01027f0:	eb 4b                	jmp    f010283d <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01027f2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027f5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01027f8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01027fc:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01027ff:	76 11                	jbe    f0102812 <stab_binsearch+0x79>
			*region_left = m;
f0102801:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102804:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102806:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102809:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102810:	eb 2b                	jmp    f010283d <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102812:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102815:	73 14                	jae    f010282b <stab_binsearch+0x92>
			*region_right = m - 1;
f0102817:	83 e8 01             	sub    $0x1,%eax
f010281a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010281d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102820:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102822:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102829:	eb 12                	jmp    f010283d <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010282b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010282e:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102830:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102834:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102836:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010283d:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102840:	0f 8e 78 ff ff ff    	jle    f01027be <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102846:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010284a:	75 0f                	jne    f010285b <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010284c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010284f:	8b 00                	mov    (%eax),%eax
f0102851:	83 e8 01             	sub    $0x1,%eax
f0102854:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102857:	89 06                	mov    %eax,(%esi)
f0102859:	eb 2c                	jmp    f0102887 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010285b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010285e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102860:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102863:	8b 0e                	mov    (%esi),%ecx
f0102865:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102868:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010286b:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010286e:	eb 03                	jmp    f0102873 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102870:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102873:	39 c8                	cmp    %ecx,%eax
f0102875:	7e 0b                	jle    f0102882 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0102877:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010287b:	83 ea 0c             	sub    $0xc,%edx
f010287e:	39 df                	cmp    %ebx,%edi
f0102880:	75 ee                	jne    f0102870 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102882:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102885:	89 06                	mov    %eax,(%esi)
	}
}
f0102887:	83 c4 14             	add    $0x14,%esp
f010288a:	5b                   	pop    %ebx
f010288b:	5e                   	pop    %esi
f010288c:	5f                   	pop    %edi
f010288d:	5d                   	pop    %ebp
f010288e:	c3                   	ret    

f010288f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010288f:	55                   	push   %ebp
f0102890:	89 e5                	mov    %esp,%ebp
f0102892:	57                   	push   %edi
f0102893:	56                   	push   %esi
f0102894:	53                   	push   %ebx
f0102895:	83 ec 3c             	sub    $0x3c,%esp
f0102898:	8b 75 08             	mov    0x8(%ebp),%esi
f010289b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010289e:	c7 03 d9 46 10 f0    	movl   $0xf01046d9,(%ebx)
	info->eip_line = 0;
f01028a4:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01028ab:	c7 43 08 d9 46 10 f0 	movl   $0xf01046d9,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01028b2:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01028b9:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01028bc:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01028c3:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01028c9:	76 11                	jbe    f01028dc <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028cb:	b8 34 c7 10 f0       	mov    $0xf010c734,%eax
f01028d0:	3d e5 a6 10 f0       	cmp    $0xf010a6e5,%eax
f01028d5:	77 19                	ja     f01028f0 <debuginfo_eip+0x61>
f01028d7:	e9 af 01 00 00       	jmp    f0102a8b <debuginfo_eip+0x1fc>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01028dc:	83 ec 04             	sub    $0x4,%esp
f01028df:	68 e3 46 10 f0       	push   $0xf01046e3
f01028e4:	6a 7f                	push   $0x7f
f01028e6:	68 f0 46 10 f0       	push   $0xf01046f0
f01028eb:	e8 a4 d7 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01028f0:	80 3d 33 c7 10 f0 00 	cmpb   $0x0,0xf010c733
f01028f7:	0f 85 95 01 00 00    	jne    f0102a92 <debuginfo_eip+0x203>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01028fd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102904:	b8 e4 a6 10 f0       	mov    $0xf010a6e4,%eax
f0102909:	2d 0c 49 10 f0       	sub    $0xf010490c,%eax
f010290e:	c1 f8 02             	sar    $0x2,%eax
f0102911:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102917:	83 e8 01             	sub    $0x1,%eax
f010291a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010291d:	83 ec 08             	sub    $0x8,%esp
f0102920:	56                   	push   %esi
f0102921:	6a 64                	push   $0x64
f0102923:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102926:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102929:	b8 0c 49 10 f0       	mov    $0xf010490c,%eax
f010292e:	e8 66 fe ff ff       	call   f0102799 <stab_binsearch>
	if (lfile == 0)
f0102933:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102936:	83 c4 10             	add    $0x10,%esp
f0102939:	85 c0                	test   %eax,%eax
f010293b:	0f 84 58 01 00 00    	je     f0102a99 <debuginfo_eip+0x20a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102941:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102944:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102947:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010294a:	83 ec 08             	sub    $0x8,%esp
f010294d:	56                   	push   %esi
f010294e:	6a 24                	push   $0x24
f0102950:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102953:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102956:	b8 0c 49 10 f0       	mov    $0xf010490c,%eax
f010295b:	e8 39 fe ff ff       	call   f0102799 <stab_binsearch>

	if (lfun <= rfun) {
f0102960:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102963:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102966:	83 c4 10             	add    $0x10,%esp
f0102969:	39 d0                	cmp    %edx,%eax
f010296b:	7f 40                	jg     f01029ad <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010296d:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102970:	c1 e1 02             	shl    $0x2,%ecx
f0102973:	8d b9 0c 49 10 f0    	lea    -0xfefb6f4(%ecx),%edi
f0102979:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f010297c:	8b b9 0c 49 10 f0    	mov    -0xfefb6f4(%ecx),%edi
f0102982:	b9 34 c7 10 f0       	mov    $0xf010c734,%ecx
f0102987:	81 e9 e5 a6 10 f0    	sub    $0xf010a6e5,%ecx
f010298d:	39 cf                	cmp    %ecx,%edi
f010298f:	73 09                	jae    f010299a <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102991:	81 c7 e5 a6 10 f0    	add    $0xf010a6e5,%edi
f0102997:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010299a:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010299d:	8b 4f 08             	mov    0x8(%edi),%ecx
f01029a0:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01029a3:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01029a5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01029a8:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01029ab:	eb 0f                	jmp    f01029bc <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01029ad:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01029b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01029b6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029b9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01029bc:	83 ec 08             	sub    $0x8,%esp
f01029bf:	6a 3a                	push   $0x3a
f01029c1:	ff 73 08             	pushl  0x8(%ebx)
f01029c4:	e8 44 08 00 00       	call   f010320d <strfind>
f01029c9:	2b 43 08             	sub    0x8(%ebx),%eax
f01029cc:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01029cf:	83 c4 08             	add    $0x8,%esp
f01029d2:	56                   	push   %esi
f01029d3:	6a 44                	push   $0x44
f01029d5:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01029d8:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01029db:	b8 0c 49 10 f0       	mov    $0xf010490c,%eax
f01029e0:	e8 b4 fd ff ff       	call   f0102799 <stab_binsearch>
	if (lline <= rline) {
f01029e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029e8:	83 c4 10             	add    $0x10,%esp
f01029eb:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01029ee:	7f 0e                	jg     f01029fe <debuginfo_eip+0x16f>
		info->eip_line = stabs[lline].n_desc;
f01029f0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01029f3:	0f b7 14 95 12 49 10 	movzwl -0xfefb6ee(,%edx,4),%edx
f01029fa:	f0 
f01029fb:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01029fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102a01:	89 c2                	mov    %eax,%edx
f0102a03:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102a06:	8d 04 85 0c 49 10 f0 	lea    -0xfefb6f4(,%eax,4),%eax
f0102a0d:	eb 06                	jmp    f0102a15 <debuginfo_eip+0x186>
f0102a0f:	83 ea 01             	sub    $0x1,%edx
f0102a12:	83 e8 0c             	sub    $0xc,%eax
f0102a15:	39 d7                	cmp    %edx,%edi
f0102a17:	7f 34                	jg     f0102a4d <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0102a19:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102a1d:	80 f9 84             	cmp    $0x84,%cl
f0102a20:	74 0b                	je     f0102a2d <debuginfo_eip+0x19e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102a22:	80 f9 64             	cmp    $0x64,%cl
f0102a25:	75 e8                	jne    f0102a0f <debuginfo_eip+0x180>
f0102a27:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102a2b:	74 e2                	je     f0102a0f <debuginfo_eip+0x180>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102a2d:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102a30:	8b 14 85 0c 49 10 f0 	mov    -0xfefb6f4(,%eax,4),%edx
f0102a37:	b8 34 c7 10 f0       	mov    $0xf010c734,%eax
f0102a3c:	2d e5 a6 10 f0       	sub    $0xf010a6e5,%eax
f0102a41:	39 c2                	cmp    %eax,%edx
f0102a43:	73 08                	jae    f0102a4d <debuginfo_eip+0x1be>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102a45:	81 c2 e5 a6 10 f0    	add    $0xf010a6e5,%edx
f0102a4b:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a4d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102a50:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a53:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102a58:	39 f2                	cmp    %esi,%edx
f0102a5a:	7d 49                	jge    f0102aa5 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
f0102a5c:	83 c2 01             	add    $0x1,%edx
f0102a5f:	89 d0                	mov    %edx,%eax
f0102a61:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102a64:	8d 14 95 0c 49 10 f0 	lea    -0xfefb6f4(,%edx,4),%edx
f0102a6b:	eb 04                	jmp    f0102a71 <debuginfo_eip+0x1e2>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102a6d:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102a71:	39 c6                	cmp    %eax,%esi
f0102a73:	7e 2b                	jle    f0102aa0 <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102a75:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102a79:	83 c0 01             	add    $0x1,%eax
f0102a7c:	83 c2 0c             	add    $0xc,%edx
f0102a7f:	80 f9 a0             	cmp    $0xa0,%cl
f0102a82:	74 e9                	je     f0102a6d <debuginfo_eip+0x1de>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a84:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a89:	eb 1a                	jmp    f0102aa5 <debuginfo_eip+0x216>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102a8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a90:	eb 13                	jmp    f0102aa5 <debuginfo_eip+0x216>
f0102a92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a97:	eb 0c                	jmp    f0102aa5 <debuginfo_eip+0x216>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a9e:	eb 05                	jmp    f0102aa5 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102aa0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102aa5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102aa8:	5b                   	pop    %ebx
f0102aa9:	5e                   	pop    %esi
f0102aaa:	5f                   	pop    %edi
f0102aab:	5d                   	pop    %ebp
f0102aac:	c3                   	ret    

f0102aad <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102aad:	55                   	push   %ebp
f0102aae:	89 e5                	mov    %esp,%ebp
f0102ab0:	57                   	push   %edi
f0102ab1:	56                   	push   %esi
f0102ab2:	53                   	push   %ebx
f0102ab3:	83 ec 1c             	sub    $0x1c,%esp
f0102ab6:	89 c7                	mov    %eax,%edi
f0102ab8:	89 d6                	mov    %edx,%esi
f0102aba:	8b 45 08             	mov    0x8(%ebp),%eax
f0102abd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102ac0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ac3:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102ac6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102ac9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ace:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102ad1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102ad4:	39 d3                	cmp    %edx,%ebx
f0102ad6:	72 05                	jb     f0102add <printnum+0x30>
f0102ad8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102adb:	77 45                	ja     f0102b22 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102add:	83 ec 0c             	sub    $0xc,%esp
f0102ae0:	ff 75 18             	pushl  0x18(%ebp)
f0102ae3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ae6:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102ae9:	53                   	push   %ebx
f0102aea:	ff 75 10             	pushl  0x10(%ebp)
f0102aed:	83 ec 08             	sub    $0x8,%esp
f0102af0:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102af3:	ff 75 e0             	pushl  -0x20(%ebp)
f0102af6:	ff 75 dc             	pushl  -0x24(%ebp)
f0102af9:	ff 75 d8             	pushl  -0x28(%ebp)
f0102afc:	e8 2f 09 00 00       	call   f0103430 <__udivdi3>
f0102b01:	83 c4 18             	add    $0x18,%esp
f0102b04:	52                   	push   %edx
f0102b05:	50                   	push   %eax
f0102b06:	89 f2                	mov    %esi,%edx
f0102b08:	89 f8                	mov    %edi,%eax
f0102b0a:	e8 9e ff ff ff       	call   f0102aad <printnum>
f0102b0f:	83 c4 20             	add    $0x20,%esp
f0102b12:	eb 18                	jmp    f0102b2c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102b14:	83 ec 08             	sub    $0x8,%esp
f0102b17:	56                   	push   %esi
f0102b18:	ff 75 18             	pushl  0x18(%ebp)
f0102b1b:	ff d7                	call   *%edi
f0102b1d:	83 c4 10             	add    $0x10,%esp
f0102b20:	eb 03                	jmp    f0102b25 <printnum+0x78>
f0102b22:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102b25:	83 eb 01             	sub    $0x1,%ebx
f0102b28:	85 db                	test   %ebx,%ebx
f0102b2a:	7f e8                	jg     f0102b14 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102b2c:	83 ec 08             	sub    $0x8,%esp
f0102b2f:	56                   	push   %esi
f0102b30:	83 ec 04             	sub    $0x4,%esp
f0102b33:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102b36:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b39:	ff 75 dc             	pushl  -0x24(%ebp)
f0102b3c:	ff 75 d8             	pushl  -0x28(%ebp)
f0102b3f:	e8 1c 0a 00 00       	call   f0103560 <__umoddi3>
f0102b44:	83 c4 14             	add    $0x14,%esp
f0102b47:	0f be 80 fe 46 10 f0 	movsbl -0xfefb902(%eax),%eax
f0102b4e:	50                   	push   %eax
f0102b4f:	ff d7                	call   *%edi
}
f0102b51:	83 c4 10             	add    $0x10,%esp
f0102b54:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b57:	5b                   	pop    %ebx
f0102b58:	5e                   	pop    %esi
f0102b59:	5f                   	pop    %edi
f0102b5a:	5d                   	pop    %ebp
f0102b5b:	c3                   	ret    

f0102b5c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102b5c:	55                   	push   %ebp
f0102b5d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102b5f:	83 fa 01             	cmp    $0x1,%edx
f0102b62:	7e 0e                	jle    f0102b72 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102b64:	8b 10                	mov    (%eax),%edx
f0102b66:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102b69:	89 08                	mov    %ecx,(%eax)
f0102b6b:	8b 02                	mov    (%edx),%eax
f0102b6d:	8b 52 04             	mov    0x4(%edx),%edx
f0102b70:	eb 22                	jmp    f0102b94 <getuint+0x38>
	else if (lflag)
f0102b72:	85 d2                	test   %edx,%edx
f0102b74:	74 10                	je     f0102b86 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102b76:	8b 10                	mov    (%eax),%edx
f0102b78:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b7b:	89 08                	mov    %ecx,(%eax)
f0102b7d:	8b 02                	mov    (%edx),%eax
f0102b7f:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b84:	eb 0e                	jmp    f0102b94 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102b86:	8b 10                	mov    (%eax),%edx
f0102b88:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102b8b:	89 08                	mov    %ecx,(%eax)
f0102b8d:	8b 02                	mov    (%edx),%eax
f0102b8f:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b94:	5d                   	pop    %ebp
f0102b95:	c3                   	ret    

f0102b96 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0102b96:	55                   	push   %ebp
f0102b97:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102b99:	83 fa 01             	cmp    $0x1,%edx
f0102b9c:	7e 0e                	jle    f0102bac <getint+0x16>
		return va_arg(*ap, long long);
f0102b9e:	8b 10                	mov    (%eax),%edx
f0102ba0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102ba3:	89 08                	mov    %ecx,(%eax)
f0102ba5:	8b 02                	mov    (%edx),%eax
f0102ba7:	8b 52 04             	mov    0x4(%edx),%edx
f0102baa:	eb 1a                	jmp    f0102bc6 <getint+0x30>
	else if (lflag)
f0102bac:	85 d2                	test   %edx,%edx
f0102bae:	74 0c                	je     f0102bbc <getint+0x26>
		return va_arg(*ap, long);
f0102bb0:	8b 10                	mov    (%eax),%edx
f0102bb2:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102bb5:	89 08                	mov    %ecx,(%eax)
f0102bb7:	8b 02                	mov    (%edx),%eax
f0102bb9:	99                   	cltd   
f0102bba:	eb 0a                	jmp    f0102bc6 <getint+0x30>
	else
		return va_arg(*ap, int);
f0102bbc:	8b 10                	mov    (%eax),%edx
f0102bbe:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102bc1:	89 08                	mov    %ecx,(%eax)
f0102bc3:	8b 02                	mov    (%edx),%eax
f0102bc5:	99                   	cltd   
}
f0102bc6:	5d                   	pop    %ebp
f0102bc7:	c3                   	ret    

f0102bc8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102bc8:	55                   	push   %ebp
f0102bc9:	89 e5                	mov    %esp,%ebp
f0102bcb:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102bce:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102bd2:	8b 10                	mov    (%eax),%edx
f0102bd4:	3b 50 04             	cmp    0x4(%eax),%edx
f0102bd7:	73 0a                	jae    f0102be3 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102bd9:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102bdc:	89 08                	mov    %ecx,(%eax)
f0102bde:	8b 45 08             	mov    0x8(%ebp),%eax
f0102be1:	88 02                	mov    %al,(%edx)
}
f0102be3:	5d                   	pop    %ebp
f0102be4:	c3                   	ret    

f0102be5 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102be5:	55                   	push   %ebp
f0102be6:	89 e5                	mov    %esp,%ebp
f0102be8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102beb:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102bee:	50                   	push   %eax
f0102bef:	ff 75 10             	pushl  0x10(%ebp)
f0102bf2:	ff 75 0c             	pushl  0xc(%ebp)
f0102bf5:	ff 75 08             	pushl  0x8(%ebp)
f0102bf8:	e8 05 00 00 00       	call   f0102c02 <vprintfmt>
	va_end(ap);
}
f0102bfd:	83 c4 10             	add    $0x10,%esp
f0102c00:	c9                   	leave  
f0102c01:	c3                   	ret    

f0102c02 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102c02:	55                   	push   %ebp
f0102c03:	89 e5                	mov    %esp,%ebp
f0102c05:	57                   	push   %edi
f0102c06:	56                   	push   %esi
f0102c07:	53                   	push   %ebx
f0102c08:	83 ec 2c             	sub    $0x2c,%esp
f0102c0b:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c0e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c11:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102c14:	eb 12                	jmp    f0102c28 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102c16:	85 c0                	test   %eax,%eax
f0102c18:	0f 84 44 03 00 00    	je     f0102f62 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f0102c1e:	83 ec 08             	sub    $0x8,%esp
f0102c21:	53                   	push   %ebx
f0102c22:	50                   	push   %eax
f0102c23:	ff d6                	call   *%esi
f0102c25:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102c28:	83 c7 01             	add    $0x1,%edi
f0102c2b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102c2f:	83 f8 25             	cmp    $0x25,%eax
f0102c32:	75 e2                	jne    f0102c16 <vprintfmt+0x14>
f0102c34:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102c38:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102c3f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c46:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102c4d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c52:	eb 07                	jmp    f0102c5b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c54:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102c57:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c5b:	8d 47 01             	lea    0x1(%edi),%eax
f0102c5e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102c61:	0f b6 07             	movzbl (%edi),%eax
f0102c64:	0f b6 c8             	movzbl %al,%ecx
f0102c67:	83 e8 23             	sub    $0x23,%eax
f0102c6a:	3c 55                	cmp    $0x55,%al
f0102c6c:	0f 87 d5 02 00 00    	ja     f0102f47 <vprintfmt+0x345>
f0102c72:	0f b6 c0             	movzbl %al,%eax
f0102c75:	ff 24 85 88 47 10 f0 	jmp    *-0xfefb878(,%eax,4)
f0102c7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102c7f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102c83:	eb d6                	jmp    f0102c5b <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c85:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c88:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c8d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102c90:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102c93:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102c97:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102c9a:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102c9d:	83 fa 09             	cmp    $0x9,%edx
f0102ca0:	77 39                	ja     f0102cdb <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102ca2:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102ca5:	eb e9                	jmp    f0102c90 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102ca7:	8b 45 14             	mov    0x14(%ebp),%eax
f0102caa:	8d 48 04             	lea    0x4(%eax),%ecx
f0102cad:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102cb0:	8b 00                	mov    (%eax),%eax
f0102cb2:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cb5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102cb8:	eb 27                	jmp    f0102ce1 <vprintfmt+0xdf>
f0102cba:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cbd:	85 c0                	test   %eax,%eax
f0102cbf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102cc4:	0f 49 c8             	cmovns %eax,%ecx
f0102cc7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cca:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ccd:	eb 8c                	jmp    f0102c5b <vprintfmt+0x59>
f0102ccf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102cd2:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102cd9:	eb 80                	jmp    f0102c5b <vprintfmt+0x59>
f0102cdb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102cde:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102ce1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ce5:	0f 89 70 ff ff ff    	jns    f0102c5b <vprintfmt+0x59>
				width = precision, precision = -1;
f0102ceb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102cee:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102cf1:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102cf8:	e9 5e ff ff ff       	jmp    f0102c5b <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102cfd:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d00:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102d03:	e9 53 ff ff ff       	jmp    f0102c5b <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102d08:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d0b:	8d 50 04             	lea    0x4(%eax),%edx
f0102d0e:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d11:	83 ec 08             	sub    $0x8,%esp
f0102d14:	53                   	push   %ebx
f0102d15:	ff 30                	pushl  (%eax)
f0102d17:	ff d6                	call   *%esi
			break;
f0102d19:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d1c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102d1f:	e9 04 ff ff ff       	jmp    f0102c28 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d24:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d27:	8d 50 04             	lea    0x4(%eax),%edx
f0102d2a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d2d:	8b 00                	mov    (%eax),%eax
f0102d2f:	99                   	cltd   
f0102d30:	31 d0                	xor    %edx,%eax
f0102d32:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102d34:	83 f8 06             	cmp    $0x6,%eax
f0102d37:	7f 0b                	jg     f0102d44 <vprintfmt+0x142>
f0102d39:	8b 14 85 e0 48 10 f0 	mov    -0xfefb720(,%eax,4),%edx
f0102d40:	85 d2                	test   %edx,%edx
f0102d42:	75 18                	jne    f0102d5c <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102d44:	50                   	push   %eax
f0102d45:	68 16 47 10 f0       	push   $0xf0104716
f0102d4a:	53                   	push   %ebx
f0102d4b:	56                   	push   %esi
f0102d4c:	e8 94 fe ff ff       	call   f0102be5 <printfmt>
f0102d51:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d54:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102d57:	e9 cc fe ff ff       	jmp    f0102c28 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102d5c:	52                   	push   %edx
f0102d5d:	68 c3 43 10 f0       	push   $0xf01043c3
f0102d62:	53                   	push   %ebx
f0102d63:	56                   	push   %esi
f0102d64:	e8 7c fe ff ff       	call   f0102be5 <printfmt>
f0102d69:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d6f:	e9 b4 fe ff ff       	jmp    f0102c28 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102d74:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d77:	8d 50 04             	lea    0x4(%eax),%edx
f0102d7a:	89 55 14             	mov    %edx,0x14(%ebp)
f0102d7d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102d7f:	85 ff                	test   %edi,%edi
f0102d81:	b8 0f 47 10 f0       	mov    $0xf010470f,%eax
f0102d86:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102d89:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d8d:	0f 8e 94 00 00 00    	jle    f0102e27 <vprintfmt+0x225>
f0102d93:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102d97:	0f 84 98 00 00 00    	je     f0102e35 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d9d:	83 ec 08             	sub    $0x8,%esp
f0102da0:	ff 75 d0             	pushl  -0x30(%ebp)
f0102da3:	57                   	push   %edi
f0102da4:	e8 1a 03 00 00       	call   f01030c3 <strnlen>
f0102da9:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102dac:	29 c1                	sub    %eax,%ecx
f0102dae:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102db1:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102db4:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102db8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102dbb:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102dbe:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102dc0:	eb 0f                	jmp    f0102dd1 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102dc2:	83 ec 08             	sub    $0x8,%esp
f0102dc5:	53                   	push   %ebx
f0102dc6:	ff 75 e0             	pushl  -0x20(%ebp)
f0102dc9:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102dcb:	83 ef 01             	sub    $0x1,%edi
f0102dce:	83 c4 10             	add    $0x10,%esp
f0102dd1:	85 ff                	test   %edi,%edi
f0102dd3:	7f ed                	jg     f0102dc2 <vprintfmt+0x1c0>
f0102dd5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102dd8:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102ddb:	85 c9                	test   %ecx,%ecx
f0102ddd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102de2:	0f 49 c1             	cmovns %ecx,%eax
f0102de5:	29 c1                	sub    %eax,%ecx
f0102de7:	89 75 08             	mov    %esi,0x8(%ebp)
f0102dea:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102ded:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102df0:	89 cb                	mov    %ecx,%ebx
f0102df2:	eb 4d                	jmp    f0102e41 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102df4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102df8:	74 1b                	je     f0102e15 <vprintfmt+0x213>
f0102dfa:	0f be c0             	movsbl %al,%eax
f0102dfd:	83 e8 20             	sub    $0x20,%eax
f0102e00:	83 f8 5e             	cmp    $0x5e,%eax
f0102e03:	76 10                	jbe    f0102e15 <vprintfmt+0x213>
					putch('?', putdat);
f0102e05:	83 ec 08             	sub    $0x8,%esp
f0102e08:	ff 75 0c             	pushl  0xc(%ebp)
f0102e0b:	6a 3f                	push   $0x3f
f0102e0d:	ff 55 08             	call   *0x8(%ebp)
f0102e10:	83 c4 10             	add    $0x10,%esp
f0102e13:	eb 0d                	jmp    f0102e22 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102e15:	83 ec 08             	sub    $0x8,%esp
f0102e18:	ff 75 0c             	pushl  0xc(%ebp)
f0102e1b:	52                   	push   %edx
f0102e1c:	ff 55 08             	call   *0x8(%ebp)
f0102e1f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102e22:	83 eb 01             	sub    $0x1,%ebx
f0102e25:	eb 1a                	jmp    f0102e41 <vprintfmt+0x23f>
f0102e27:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e2a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e2d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e30:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e33:	eb 0c                	jmp    f0102e41 <vprintfmt+0x23f>
f0102e35:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e38:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e3b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102e3e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102e41:	83 c7 01             	add    $0x1,%edi
f0102e44:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102e48:	0f be d0             	movsbl %al,%edx
f0102e4b:	85 d2                	test   %edx,%edx
f0102e4d:	74 23                	je     f0102e72 <vprintfmt+0x270>
f0102e4f:	85 f6                	test   %esi,%esi
f0102e51:	78 a1                	js     f0102df4 <vprintfmt+0x1f2>
f0102e53:	83 ee 01             	sub    $0x1,%esi
f0102e56:	79 9c                	jns    f0102df4 <vprintfmt+0x1f2>
f0102e58:	89 df                	mov    %ebx,%edi
f0102e5a:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e5d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e60:	eb 18                	jmp    f0102e7a <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102e62:	83 ec 08             	sub    $0x8,%esp
f0102e65:	53                   	push   %ebx
f0102e66:	6a 20                	push   $0x20
f0102e68:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102e6a:	83 ef 01             	sub    $0x1,%edi
f0102e6d:	83 c4 10             	add    $0x10,%esp
f0102e70:	eb 08                	jmp    f0102e7a <vprintfmt+0x278>
f0102e72:	89 df                	mov    %ebx,%edi
f0102e74:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e77:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e7a:	85 ff                	test   %edi,%edi
f0102e7c:	7f e4                	jg     f0102e62 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102e7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e81:	e9 a2 fd ff ff       	jmp    f0102c28 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e86:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e89:	e8 08 fd ff ff       	call   f0102b96 <getint>
f0102e8e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e91:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e94:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e99:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e9d:	79 74                	jns    f0102f13 <vprintfmt+0x311>
				putch('-', putdat);
f0102e9f:	83 ec 08             	sub    $0x8,%esp
f0102ea2:	53                   	push   %ebx
f0102ea3:	6a 2d                	push   $0x2d
f0102ea5:	ff d6                	call   *%esi
				num = -(long long) num;
f0102ea7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102eaa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ead:	f7 d8                	neg    %eax
f0102eaf:	83 d2 00             	adc    $0x0,%edx
f0102eb2:	f7 da                	neg    %edx
f0102eb4:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102eb7:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102ebc:	eb 55                	jmp    f0102f13 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102ebe:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ec1:	e8 96 fc ff ff       	call   f0102b5c <getuint>
			base = 10;
f0102ec6:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102ecb:	eb 46                	jmp    f0102f13 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0102ecd:	8d 45 14             	lea    0x14(%ebp),%eax
f0102ed0:	e8 87 fc ff ff       	call   f0102b5c <getuint>
			base = 8;
f0102ed5:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0102eda:	eb 37                	jmp    f0102f13 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0102edc:	83 ec 08             	sub    $0x8,%esp
f0102edf:	53                   	push   %ebx
f0102ee0:	6a 30                	push   $0x30
f0102ee2:	ff d6                	call   *%esi
			putch('x', putdat);
f0102ee4:	83 c4 08             	add    $0x8,%esp
f0102ee7:	53                   	push   %ebx
f0102ee8:	6a 78                	push   $0x78
f0102eea:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102eec:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eef:	8d 50 04             	lea    0x4(%eax),%edx
f0102ef2:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102ef5:	8b 00                	mov    (%eax),%eax
f0102ef7:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102efc:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102eff:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102f04:	eb 0d                	jmp    f0102f13 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102f06:	8d 45 14             	lea    0x14(%ebp),%eax
f0102f09:	e8 4e fc ff ff       	call   f0102b5c <getuint>
			base = 16;
f0102f0e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102f13:	83 ec 0c             	sub    $0xc,%esp
f0102f16:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102f1a:	57                   	push   %edi
f0102f1b:	ff 75 e0             	pushl  -0x20(%ebp)
f0102f1e:	51                   	push   %ecx
f0102f1f:	52                   	push   %edx
f0102f20:	50                   	push   %eax
f0102f21:	89 da                	mov    %ebx,%edx
f0102f23:	89 f0                	mov    %esi,%eax
f0102f25:	e8 83 fb ff ff       	call   f0102aad <printnum>
			break;
f0102f2a:	83 c4 20             	add    $0x20,%esp
f0102f2d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f30:	e9 f3 fc ff ff       	jmp    f0102c28 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102f35:	83 ec 08             	sub    $0x8,%esp
f0102f38:	53                   	push   %ebx
f0102f39:	51                   	push   %ecx
f0102f3a:	ff d6                	call   *%esi
			break;
f0102f3c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102f3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102f42:	e9 e1 fc ff ff       	jmp    f0102c28 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102f47:	83 ec 08             	sub    $0x8,%esp
f0102f4a:	53                   	push   %ebx
f0102f4b:	6a 25                	push   $0x25
f0102f4d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102f4f:	83 c4 10             	add    $0x10,%esp
f0102f52:	eb 03                	jmp    f0102f57 <vprintfmt+0x355>
f0102f54:	83 ef 01             	sub    $0x1,%edi
f0102f57:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102f5b:	75 f7                	jne    f0102f54 <vprintfmt+0x352>
f0102f5d:	e9 c6 fc ff ff       	jmp    f0102c28 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102f62:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f65:	5b                   	pop    %ebx
f0102f66:	5e                   	pop    %esi
f0102f67:	5f                   	pop    %edi
f0102f68:	5d                   	pop    %ebp
f0102f69:	c3                   	ret    

f0102f6a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102f6a:	55                   	push   %ebp
f0102f6b:	89 e5                	mov    %esp,%ebp
f0102f6d:	83 ec 18             	sub    $0x18,%esp
f0102f70:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f73:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102f76:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102f79:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f7d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f80:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f87:	85 c0                	test   %eax,%eax
f0102f89:	74 26                	je     f0102fb1 <vsnprintf+0x47>
f0102f8b:	85 d2                	test   %edx,%edx
f0102f8d:	7e 22                	jle    f0102fb1 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f8f:	ff 75 14             	pushl  0x14(%ebp)
f0102f92:	ff 75 10             	pushl  0x10(%ebp)
f0102f95:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f98:	50                   	push   %eax
f0102f99:	68 c8 2b 10 f0       	push   $0xf0102bc8
f0102f9e:	e8 5f fc ff ff       	call   f0102c02 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102fa3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fa6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102fa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fac:	83 c4 10             	add    $0x10,%esp
f0102faf:	eb 05                	jmp    f0102fb6 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102fb1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102fb6:	c9                   	leave  
f0102fb7:	c3                   	ret    

f0102fb8 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102fb8:	55                   	push   %ebp
f0102fb9:	89 e5                	mov    %esp,%ebp
f0102fbb:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102fbe:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102fc1:	50                   	push   %eax
f0102fc2:	ff 75 10             	pushl  0x10(%ebp)
f0102fc5:	ff 75 0c             	pushl  0xc(%ebp)
f0102fc8:	ff 75 08             	pushl  0x8(%ebp)
f0102fcb:	e8 9a ff ff ff       	call   f0102f6a <vsnprintf>
	va_end(ap);

	return rc;
}
f0102fd0:	c9                   	leave  
f0102fd1:	c3                   	ret    

f0102fd2 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102fd2:	55                   	push   %ebp
f0102fd3:	89 e5                	mov    %esp,%ebp
f0102fd5:	57                   	push   %edi
f0102fd6:	56                   	push   %esi
f0102fd7:	53                   	push   %ebx
f0102fd8:	83 ec 0c             	sub    $0xc,%esp
f0102fdb:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102fde:	85 c0                	test   %eax,%eax
f0102fe0:	74 11                	je     f0102ff3 <readline+0x21>
		cprintf("%s", prompt);
f0102fe2:	83 ec 08             	sub    $0x8,%esp
f0102fe5:	50                   	push   %eax
f0102fe6:	68 c3 43 10 f0       	push   $0xf01043c3
f0102feb:	e8 95 f7 ff ff       	call   f0102785 <cprintf>
f0102ff0:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102ff3:	83 ec 0c             	sub    $0xc,%esp
f0102ff6:	6a 00                	push   $0x0
f0102ff8:	e8 32 d7 ff ff       	call   f010072f <iscons>
f0102ffd:	89 c7                	mov    %eax,%edi
f0102fff:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103002:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103007:	e8 12 d7 ff ff       	call   f010071e <getchar>
f010300c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010300e:	85 c0                	test   %eax,%eax
f0103010:	79 18                	jns    f010302a <readline+0x58>
			cprintf("read error: %e\n", c);
f0103012:	83 ec 08             	sub    $0x8,%esp
f0103015:	50                   	push   %eax
f0103016:	68 fc 48 10 f0       	push   $0xf01048fc
f010301b:	e8 65 f7 ff ff       	call   f0102785 <cprintf>
			return NULL;
f0103020:	83 c4 10             	add    $0x10,%esp
f0103023:	b8 00 00 00 00       	mov    $0x0,%eax
f0103028:	eb 79                	jmp    f01030a3 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010302a:	83 f8 08             	cmp    $0x8,%eax
f010302d:	0f 94 c2             	sete   %dl
f0103030:	83 f8 7f             	cmp    $0x7f,%eax
f0103033:	0f 94 c0             	sete   %al
f0103036:	08 c2                	or     %al,%dl
f0103038:	74 1a                	je     f0103054 <readline+0x82>
f010303a:	85 f6                	test   %esi,%esi
f010303c:	7e 16                	jle    f0103054 <readline+0x82>
			if (echoing)
f010303e:	85 ff                	test   %edi,%edi
f0103040:	74 0d                	je     f010304f <readline+0x7d>
				cputchar('\b');
f0103042:	83 ec 0c             	sub    $0xc,%esp
f0103045:	6a 08                	push   $0x8
f0103047:	e8 c2 d6 ff ff       	call   f010070e <cputchar>
f010304c:	83 c4 10             	add    $0x10,%esp
			i--;
f010304f:	83 ee 01             	sub    $0x1,%esi
f0103052:	eb b3                	jmp    f0103007 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103054:	83 fb 1f             	cmp    $0x1f,%ebx
f0103057:	7e 23                	jle    f010307c <readline+0xaa>
f0103059:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010305f:	7f 1b                	jg     f010307c <readline+0xaa>
			if (echoing)
f0103061:	85 ff                	test   %edi,%edi
f0103063:	74 0c                	je     f0103071 <readline+0x9f>
				cputchar(c);
f0103065:	83 ec 0c             	sub    $0xc,%esp
f0103068:	53                   	push   %ebx
f0103069:	e8 a0 d6 ff ff       	call   f010070e <cputchar>
f010306e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103071:	88 9e 40 65 11 f0    	mov    %bl,-0xfee9ac0(%esi)
f0103077:	8d 76 01             	lea    0x1(%esi),%esi
f010307a:	eb 8b                	jmp    f0103007 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010307c:	83 fb 0a             	cmp    $0xa,%ebx
f010307f:	74 05                	je     f0103086 <readline+0xb4>
f0103081:	83 fb 0d             	cmp    $0xd,%ebx
f0103084:	75 81                	jne    f0103007 <readline+0x35>
			if (echoing)
f0103086:	85 ff                	test   %edi,%edi
f0103088:	74 0d                	je     f0103097 <readline+0xc5>
				cputchar('\n');
f010308a:	83 ec 0c             	sub    $0xc,%esp
f010308d:	6a 0a                	push   $0xa
f010308f:	e8 7a d6 ff ff       	call   f010070e <cputchar>
f0103094:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103097:	c6 86 40 65 11 f0 00 	movb   $0x0,-0xfee9ac0(%esi)
			return buf;
f010309e:	b8 40 65 11 f0       	mov    $0xf0116540,%eax
		}
	}
}
f01030a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030a6:	5b                   	pop    %ebx
f01030a7:	5e                   	pop    %esi
f01030a8:	5f                   	pop    %edi
f01030a9:	5d                   	pop    %ebp
f01030aa:	c3                   	ret    

f01030ab <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01030ab:	55                   	push   %ebp
f01030ac:	89 e5                	mov    %esp,%ebp
f01030ae:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01030b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01030b6:	eb 03                	jmp    f01030bb <strlen+0x10>
		n++;
f01030b8:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01030bb:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01030bf:	75 f7                	jne    f01030b8 <strlen+0xd>
		n++;
	return n;
}
f01030c1:	5d                   	pop    %ebp
f01030c2:	c3                   	ret    

f01030c3 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01030c3:	55                   	push   %ebp
f01030c4:	89 e5                	mov    %esp,%ebp
f01030c6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030c9:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030cc:	ba 00 00 00 00       	mov    $0x0,%edx
f01030d1:	eb 03                	jmp    f01030d6 <strnlen+0x13>
		n++;
f01030d3:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01030d6:	39 c2                	cmp    %eax,%edx
f01030d8:	74 08                	je     f01030e2 <strnlen+0x1f>
f01030da:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01030de:	75 f3                	jne    f01030d3 <strnlen+0x10>
f01030e0:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01030e2:	5d                   	pop    %ebp
f01030e3:	c3                   	ret    

f01030e4 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01030e4:	55                   	push   %ebp
f01030e5:	89 e5                	mov    %esp,%ebp
f01030e7:	53                   	push   %ebx
f01030e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01030eb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01030ee:	89 c2                	mov    %eax,%edx
f01030f0:	83 c2 01             	add    $0x1,%edx
f01030f3:	83 c1 01             	add    $0x1,%ecx
f01030f6:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01030fa:	88 5a ff             	mov    %bl,-0x1(%edx)
f01030fd:	84 db                	test   %bl,%bl
f01030ff:	75 ef                	jne    f01030f0 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103101:	5b                   	pop    %ebx
f0103102:	5d                   	pop    %ebp
f0103103:	c3                   	ret    

f0103104 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103104:	55                   	push   %ebp
f0103105:	89 e5                	mov    %esp,%ebp
f0103107:	53                   	push   %ebx
f0103108:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010310b:	53                   	push   %ebx
f010310c:	e8 9a ff ff ff       	call   f01030ab <strlen>
f0103111:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103114:	ff 75 0c             	pushl  0xc(%ebp)
f0103117:	01 d8                	add    %ebx,%eax
f0103119:	50                   	push   %eax
f010311a:	e8 c5 ff ff ff       	call   f01030e4 <strcpy>
	return dst;
}
f010311f:	89 d8                	mov    %ebx,%eax
f0103121:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103124:	c9                   	leave  
f0103125:	c3                   	ret    

f0103126 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103126:	55                   	push   %ebp
f0103127:	89 e5                	mov    %esp,%ebp
f0103129:	56                   	push   %esi
f010312a:	53                   	push   %ebx
f010312b:	8b 75 08             	mov    0x8(%ebp),%esi
f010312e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103131:	89 f3                	mov    %esi,%ebx
f0103133:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103136:	89 f2                	mov    %esi,%edx
f0103138:	eb 0f                	jmp    f0103149 <strncpy+0x23>
		*dst++ = *src;
f010313a:	83 c2 01             	add    $0x1,%edx
f010313d:	0f b6 01             	movzbl (%ecx),%eax
f0103140:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103143:	80 39 01             	cmpb   $0x1,(%ecx)
f0103146:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103149:	39 da                	cmp    %ebx,%edx
f010314b:	75 ed                	jne    f010313a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010314d:	89 f0                	mov    %esi,%eax
f010314f:	5b                   	pop    %ebx
f0103150:	5e                   	pop    %esi
f0103151:	5d                   	pop    %ebp
f0103152:	c3                   	ret    

f0103153 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103153:	55                   	push   %ebp
f0103154:	89 e5                	mov    %esp,%ebp
f0103156:	56                   	push   %esi
f0103157:	53                   	push   %ebx
f0103158:	8b 75 08             	mov    0x8(%ebp),%esi
f010315b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010315e:	8b 55 10             	mov    0x10(%ebp),%edx
f0103161:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103163:	85 d2                	test   %edx,%edx
f0103165:	74 21                	je     f0103188 <strlcpy+0x35>
f0103167:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010316b:	89 f2                	mov    %esi,%edx
f010316d:	eb 09                	jmp    f0103178 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010316f:	83 c2 01             	add    $0x1,%edx
f0103172:	83 c1 01             	add    $0x1,%ecx
f0103175:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103178:	39 c2                	cmp    %eax,%edx
f010317a:	74 09                	je     f0103185 <strlcpy+0x32>
f010317c:	0f b6 19             	movzbl (%ecx),%ebx
f010317f:	84 db                	test   %bl,%bl
f0103181:	75 ec                	jne    f010316f <strlcpy+0x1c>
f0103183:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103185:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103188:	29 f0                	sub    %esi,%eax
}
f010318a:	5b                   	pop    %ebx
f010318b:	5e                   	pop    %esi
f010318c:	5d                   	pop    %ebp
f010318d:	c3                   	ret    

f010318e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010318e:	55                   	push   %ebp
f010318f:	89 e5                	mov    %esp,%ebp
f0103191:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103194:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103197:	eb 06                	jmp    f010319f <strcmp+0x11>
		p++, q++;
f0103199:	83 c1 01             	add    $0x1,%ecx
f010319c:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010319f:	0f b6 01             	movzbl (%ecx),%eax
f01031a2:	84 c0                	test   %al,%al
f01031a4:	74 04                	je     f01031aa <strcmp+0x1c>
f01031a6:	3a 02                	cmp    (%edx),%al
f01031a8:	74 ef                	je     f0103199 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01031aa:	0f b6 c0             	movzbl %al,%eax
f01031ad:	0f b6 12             	movzbl (%edx),%edx
f01031b0:	29 d0                	sub    %edx,%eax
}
f01031b2:	5d                   	pop    %ebp
f01031b3:	c3                   	ret    

f01031b4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01031b4:	55                   	push   %ebp
f01031b5:	89 e5                	mov    %esp,%ebp
f01031b7:	53                   	push   %ebx
f01031b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01031bb:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031be:	89 c3                	mov    %eax,%ebx
f01031c0:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01031c3:	eb 06                	jmp    f01031cb <strncmp+0x17>
		n--, p++, q++;
f01031c5:	83 c0 01             	add    $0x1,%eax
f01031c8:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01031cb:	39 d8                	cmp    %ebx,%eax
f01031cd:	74 15                	je     f01031e4 <strncmp+0x30>
f01031cf:	0f b6 08             	movzbl (%eax),%ecx
f01031d2:	84 c9                	test   %cl,%cl
f01031d4:	74 04                	je     f01031da <strncmp+0x26>
f01031d6:	3a 0a                	cmp    (%edx),%cl
f01031d8:	74 eb                	je     f01031c5 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01031da:	0f b6 00             	movzbl (%eax),%eax
f01031dd:	0f b6 12             	movzbl (%edx),%edx
f01031e0:	29 d0                	sub    %edx,%eax
f01031e2:	eb 05                	jmp    f01031e9 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01031e4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01031e9:	5b                   	pop    %ebx
f01031ea:	5d                   	pop    %ebp
f01031eb:	c3                   	ret    

f01031ec <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01031ec:	55                   	push   %ebp
f01031ed:	89 e5                	mov    %esp,%ebp
f01031ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01031f2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01031f6:	eb 07                	jmp    f01031ff <strchr+0x13>
		if (*s == c)
f01031f8:	38 ca                	cmp    %cl,%dl
f01031fa:	74 0f                	je     f010320b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01031fc:	83 c0 01             	add    $0x1,%eax
f01031ff:	0f b6 10             	movzbl (%eax),%edx
f0103202:	84 d2                	test   %dl,%dl
f0103204:	75 f2                	jne    f01031f8 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103206:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010320b:	5d                   	pop    %ebp
f010320c:	c3                   	ret    

f010320d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010320d:	55                   	push   %ebp
f010320e:	89 e5                	mov    %esp,%ebp
f0103210:	8b 45 08             	mov    0x8(%ebp),%eax
f0103213:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103217:	eb 03                	jmp    f010321c <strfind+0xf>
f0103219:	83 c0 01             	add    $0x1,%eax
f010321c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010321f:	38 ca                	cmp    %cl,%dl
f0103221:	74 04                	je     f0103227 <strfind+0x1a>
f0103223:	84 d2                	test   %dl,%dl
f0103225:	75 f2                	jne    f0103219 <strfind+0xc>
			break;
	return (char *) s;
}
f0103227:	5d                   	pop    %ebp
f0103228:	c3                   	ret    

f0103229 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103229:	55                   	push   %ebp
f010322a:	89 e5                	mov    %esp,%ebp
f010322c:	57                   	push   %edi
f010322d:	56                   	push   %esi
f010322e:	53                   	push   %ebx
f010322f:	8b 55 08             	mov    0x8(%ebp),%edx
f0103232:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f0103235:	85 c9                	test   %ecx,%ecx
f0103237:	74 37                	je     f0103270 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103239:	f6 c2 03             	test   $0x3,%dl
f010323c:	75 2a                	jne    f0103268 <memset+0x3f>
f010323e:	f6 c1 03             	test   $0x3,%cl
f0103241:	75 25                	jne    f0103268 <memset+0x3f>
		c &= 0xFF;
f0103243:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103247:	89 df                	mov    %ebx,%edi
f0103249:	c1 e7 08             	shl    $0x8,%edi
f010324c:	89 de                	mov    %ebx,%esi
f010324e:	c1 e6 18             	shl    $0x18,%esi
f0103251:	89 d8                	mov    %ebx,%eax
f0103253:	c1 e0 10             	shl    $0x10,%eax
f0103256:	09 f0                	or     %esi,%eax
f0103258:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f010325a:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010325d:	89 f8                	mov    %edi,%eax
f010325f:	09 d8                	or     %ebx,%eax
f0103261:	89 d7                	mov    %edx,%edi
f0103263:	fc                   	cld    
f0103264:	f3 ab                	rep stos %eax,%es:(%edi)
f0103266:	eb 08                	jmp    f0103270 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103268:	89 d7                	mov    %edx,%edi
f010326a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010326d:	fc                   	cld    
f010326e:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f0103270:	89 d0                	mov    %edx,%eax
f0103272:	5b                   	pop    %ebx
f0103273:	5e                   	pop    %esi
f0103274:	5f                   	pop    %edi
f0103275:	5d                   	pop    %ebp
f0103276:	c3                   	ret    

f0103277 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103277:	55                   	push   %ebp
f0103278:	89 e5                	mov    %esp,%ebp
f010327a:	57                   	push   %edi
f010327b:	56                   	push   %esi
f010327c:	8b 45 08             	mov    0x8(%ebp),%eax
f010327f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103282:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103285:	39 c6                	cmp    %eax,%esi
f0103287:	73 35                	jae    f01032be <memmove+0x47>
f0103289:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010328c:	39 d0                	cmp    %edx,%eax
f010328e:	73 2e                	jae    f01032be <memmove+0x47>
		s += n;
		d += n;
f0103290:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103293:	89 d6                	mov    %edx,%esi
f0103295:	09 fe                	or     %edi,%esi
f0103297:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010329d:	75 13                	jne    f01032b2 <memmove+0x3b>
f010329f:	f6 c1 03             	test   $0x3,%cl
f01032a2:	75 0e                	jne    f01032b2 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01032a4:	83 ef 04             	sub    $0x4,%edi
f01032a7:	8d 72 fc             	lea    -0x4(%edx),%esi
f01032aa:	c1 e9 02             	shr    $0x2,%ecx
f01032ad:	fd                   	std    
f01032ae:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032b0:	eb 09                	jmp    f01032bb <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01032b2:	83 ef 01             	sub    $0x1,%edi
f01032b5:	8d 72 ff             	lea    -0x1(%edx),%esi
f01032b8:	fd                   	std    
f01032b9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01032bb:	fc                   	cld    
f01032bc:	eb 1d                	jmp    f01032db <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01032be:	89 f2                	mov    %esi,%edx
f01032c0:	09 c2                	or     %eax,%edx
f01032c2:	f6 c2 03             	test   $0x3,%dl
f01032c5:	75 0f                	jne    f01032d6 <memmove+0x5f>
f01032c7:	f6 c1 03             	test   $0x3,%cl
f01032ca:	75 0a                	jne    f01032d6 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01032cc:	c1 e9 02             	shr    $0x2,%ecx
f01032cf:	89 c7                	mov    %eax,%edi
f01032d1:	fc                   	cld    
f01032d2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01032d4:	eb 05                	jmp    f01032db <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01032d6:	89 c7                	mov    %eax,%edi
f01032d8:	fc                   	cld    
f01032d9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01032db:	5e                   	pop    %esi
f01032dc:	5f                   	pop    %edi
f01032dd:	5d                   	pop    %ebp
f01032de:	c3                   	ret    

f01032df <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01032df:	55                   	push   %ebp
f01032e0:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01032e2:	ff 75 10             	pushl  0x10(%ebp)
f01032e5:	ff 75 0c             	pushl  0xc(%ebp)
f01032e8:	ff 75 08             	pushl  0x8(%ebp)
f01032eb:	e8 87 ff ff ff       	call   f0103277 <memmove>
}
f01032f0:	c9                   	leave  
f01032f1:	c3                   	ret    

f01032f2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01032f2:	55                   	push   %ebp
f01032f3:	89 e5                	mov    %esp,%ebp
f01032f5:	56                   	push   %esi
f01032f6:	53                   	push   %ebx
f01032f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01032fa:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032fd:	89 c6                	mov    %eax,%esi
f01032ff:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103302:	eb 1a                	jmp    f010331e <memcmp+0x2c>
		if (*s1 != *s2)
f0103304:	0f b6 08             	movzbl (%eax),%ecx
f0103307:	0f b6 1a             	movzbl (%edx),%ebx
f010330a:	38 d9                	cmp    %bl,%cl
f010330c:	74 0a                	je     f0103318 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010330e:	0f b6 c1             	movzbl %cl,%eax
f0103311:	0f b6 db             	movzbl %bl,%ebx
f0103314:	29 d8                	sub    %ebx,%eax
f0103316:	eb 0f                	jmp    f0103327 <memcmp+0x35>
		s1++, s2++;
f0103318:	83 c0 01             	add    $0x1,%eax
f010331b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010331e:	39 f0                	cmp    %esi,%eax
f0103320:	75 e2                	jne    f0103304 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103322:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103327:	5b                   	pop    %ebx
f0103328:	5e                   	pop    %esi
f0103329:	5d                   	pop    %ebp
f010332a:	c3                   	ret    

f010332b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010332b:	55                   	push   %ebp
f010332c:	89 e5                	mov    %esp,%ebp
f010332e:	53                   	push   %ebx
f010332f:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103332:	89 c1                	mov    %eax,%ecx
f0103334:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103337:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010333b:	eb 0a                	jmp    f0103347 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010333d:	0f b6 10             	movzbl (%eax),%edx
f0103340:	39 da                	cmp    %ebx,%edx
f0103342:	74 07                	je     f010334b <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103344:	83 c0 01             	add    $0x1,%eax
f0103347:	39 c8                	cmp    %ecx,%eax
f0103349:	72 f2                	jb     f010333d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010334b:	5b                   	pop    %ebx
f010334c:	5d                   	pop    %ebp
f010334d:	c3                   	ret    

f010334e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010334e:	55                   	push   %ebp
f010334f:	89 e5                	mov    %esp,%ebp
f0103351:	57                   	push   %edi
f0103352:	56                   	push   %esi
f0103353:	53                   	push   %ebx
f0103354:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103357:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010335a:	eb 03                	jmp    f010335f <strtol+0x11>
		s++;
f010335c:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010335f:	0f b6 01             	movzbl (%ecx),%eax
f0103362:	3c 20                	cmp    $0x20,%al
f0103364:	74 f6                	je     f010335c <strtol+0xe>
f0103366:	3c 09                	cmp    $0x9,%al
f0103368:	74 f2                	je     f010335c <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010336a:	3c 2b                	cmp    $0x2b,%al
f010336c:	75 0a                	jne    f0103378 <strtol+0x2a>
		s++;
f010336e:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103371:	bf 00 00 00 00       	mov    $0x0,%edi
f0103376:	eb 11                	jmp    f0103389 <strtol+0x3b>
f0103378:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010337d:	3c 2d                	cmp    $0x2d,%al
f010337f:	75 08                	jne    f0103389 <strtol+0x3b>
		s++, neg = 1;
f0103381:	83 c1 01             	add    $0x1,%ecx
f0103384:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103389:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010338f:	75 15                	jne    f01033a6 <strtol+0x58>
f0103391:	80 39 30             	cmpb   $0x30,(%ecx)
f0103394:	75 10                	jne    f01033a6 <strtol+0x58>
f0103396:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010339a:	75 7c                	jne    f0103418 <strtol+0xca>
		s += 2, base = 16;
f010339c:	83 c1 02             	add    $0x2,%ecx
f010339f:	bb 10 00 00 00       	mov    $0x10,%ebx
f01033a4:	eb 16                	jmp    f01033bc <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01033a6:	85 db                	test   %ebx,%ebx
f01033a8:	75 12                	jne    f01033bc <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01033aa:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01033af:	80 39 30             	cmpb   $0x30,(%ecx)
f01033b2:	75 08                	jne    f01033bc <strtol+0x6e>
		s++, base = 8;
f01033b4:	83 c1 01             	add    $0x1,%ecx
f01033b7:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01033bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01033c1:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01033c4:	0f b6 11             	movzbl (%ecx),%edx
f01033c7:	8d 72 d0             	lea    -0x30(%edx),%esi
f01033ca:	89 f3                	mov    %esi,%ebx
f01033cc:	80 fb 09             	cmp    $0x9,%bl
f01033cf:	77 08                	ja     f01033d9 <strtol+0x8b>
			dig = *s - '0';
f01033d1:	0f be d2             	movsbl %dl,%edx
f01033d4:	83 ea 30             	sub    $0x30,%edx
f01033d7:	eb 22                	jmp    f01033fb <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01033d9:	8d 72 9f             	lea    -0x61(%edx),%esi
f01033dc:	89 f3                	mov    %esi,%ebx
f01033de:	80 fb 19             	cmp    $0x19,%bl
f01033e1:	77 08                	ja     f01033eb <strtol+0x9d>
			dig = *s - 'a' + 10;
f01033e3:	0f be d2             	movsbl %dl,%edx
f01033e6:	83 ea 57             	sub    $0x57,%edx
f01033e9:	eb 10                	jmp    f01033fb <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01033eb:	8d 72 bf             	lea    -0x41(%edx),%esi
f01033ee:	89 f3                	mov    %esi,%ebx
f01033f0:	80 fb 19             	cmp    $0x19,%bl
f01033f3:	77 16                	ja     f010340b <strtol+0xbd>
			dig = *s - 'A' + 10;
f01033f5:	0f be d2             	movsbl %dl,%edx
f01033f8:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01033fb:	3b 55 10             	cmp    0x10(%ebp),%edx
f01033fe:	7d 0b                	jge    f010340b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103400:	83 c1 01             	add    $0x1,%ecx
f0103403:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103407:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0103409:	eb b9                	jmp    f01033c4 <strtol+0x76>

	if (endptr)
f010340b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010340f:	74 0d                	je     f010341e <strtol+0xd0>
		*endptr = (char *) s;
f0103411:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103414:	89 0e                	mov    %ecx,(%esi)
f0103416:	eb 06                	jmp    f010341e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103418:	85 db                	test   %ebx,%ebx
f010341a:	74 98                	je     f01033b4 <strtol+0x66>
f010341c:	eb 9e                	jmp    f01033bc <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010341e:	89 c2                	mov    %eax,%edx
f0103420:	f7 da                	neg    %edx
f0103422:	85 ff                	test   %edi,%edi
f0103424:	0f 45 c2             	cmovne %edx,%eax
}
f0103427:	5b                   	pop    %ebx
f0103428:	5e                   	pop    %esi
f0103429:	5f                   	pop    %edi
f010342a:	5d                   	pop    %ebp
f010342b:	c3                   	ret    
f010342c:	66 90                	xchg   %ax,%ax
f010342e:	66 90                	xchg   %ax,%ax

f0103430 <__udivdi3>:
f0103430:	55                   	push   %ebp
f0103431:	57                   	push   %edi
f0103432:	56                   	push   %esi
f0103433:	53                   	push   %ebx
f0103434:	83 ec 1c             	sub    $0x1c,%esp
f0103437:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010343b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010343f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0103443:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103447:	85 f6                	test   %esi,%esi
f0103449:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010344d:	89 ca                	mov    %ecx,%edx
f010344f:	89 f8                	mov    %edi,%eax
f0103451:	75 3d                	jne    f0103490 <__udivdi3+0x60>
f0103453:	39 cf                	cmp    %ecx,%edi
f0103455:	0f 87 c5 00 00 00    	ja     f0103520 <__udivdi3+0xf0>
f010345b:	85 ff                	test   %edi,%edi
f010345d:	89 fd                	mov    %edi,%ebp
f010345f:	75 0b                	jne    f010346c <__udivdi3+0x3c>
f0103461:	b8 01 00 00 00       	mov    $0x1,%eax
f0103466:	31 d2                	xor    %edx,%edx
f0103468:	f7 f7                	div    %edi
f010346a:	89 c5                	mov    %eax,%ebp
f010346c:	89 c8                	mov    %ecx,%eax
f010346e:	31 d2                	xor    %edx,%edx
f0103470:	f7 f5                	div    %ebp
f0103472:	89 c1                	mov    %eax,%ecx
f0103474:	89 d8                	mov    %ebx,%eax
f0103476:	89 cf                	mov    %ecx,%edi
f0103478:	f7 f5                	div    %ebp
f010347a:	89 c3                	mov    %eax,%ebx
f010347c:	89 d8                	mov    %ebx,%eax
f010347e:	89 fa                	mov    %edi,%edx
f0103480:	83 c4 1c             	add    $0x1c,%esp
f0103483:	5b                   	pop    %ebx
f0103484:	5e                   	pop    %esi
f0103485:	5f                   	pop    %edi
f0103486:	5d                   	pop    %ebp
f0103487:	c3                   	ret    
f0103488:	90                   	nop
f0103489:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103490:	39 ce                	cmp    %ecx,%esi
f0103492:	77 74                	ja     f0103508 <__udivdi3+0xd8>
f0103494:	0f bd fe             	bsr    %esi,%edi
f0103497:	83 f7 1f             	xor    $0x1f,%edi
f010349a:	0f 84 98 00 00 00    	je     f0103538 <__udivdi3+0x108>
f01034a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01034a5:	89 f9                	mov    %edi,%ecx
f01034a7:	89 c5                	mov    %eax,%ebp
f01034a9:	29 fb                	sub    %edi,%ebx
f01034ab:	d3 e6                	shl    %cl,%esi
f01034ad:	89 d9                	mov    %ebx,%ecx
f01034af:	d3 ed                	shr    %cl,%ebp
f01034b1:	89 f9                	mov    %edi,%ecx
f01034b3:	d3 e0                	shl    %cl,%eax
f01034b5:	09 ee                	or     %ebp,%esi
f01034b7:	89 d9                	mov    %ebx,%ecx
f01034b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034bd:	89 d5                	mov    %edx,%ebp
f01034bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01034c3:	d3 ed                	shr    %cl,%ebp
f01034c5:	89 f9                	mov    %edi,%ecx
f01034c7:	d3 e2                	shl    %cl,%edx
f01034c9:	89 d9                	mov    %ebx,%ecx
f01034cb:	d3 e8                	shr    %cl,%eax
f01034cd:	09 c2                	or     %eax,%edx
f01034cf:	89 d0                	mov    %edx,%eax
f01034d1:	89 ea                	mov    %ebp,%edx
f01034d3:	f7 f6                	div    %esi
f01034d5:	89 d5                	mov    %edx,%ebp
f01034d7:	89 c3                	mov    %eax,%ebx
f01034d9:	f7 64 24 0c          	mull   0xc(%esp)
f01034dd:	39 d5                	cmp    %edx,%ebp
f01034df:	72 10                	jb     f01034f1 <__udivdi3+0xc1>
f01034e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01034e5:	89 f9                	mov    %edi,%ecx
f01034e7:	d3 e6                	shl    %cl,%esi
f01034e9:	39 c6                	cmp    %eax,%esi
f01034eb:	73 07                	jae    f01034f4 <__udivdi3+0xc4>
f01034ed:	39 d5                	cmp    %edx,%ebp
f01034ef:	75 03                	jne    f01034f4 <__udivdi3+0xc4>
f01034f1:	83 eb 01             	sub    $0x1,%ebx
f01034f4:	31 ff                	xor    %edi,%edi
f01034f6:	89 d8                	mov    %ebx,%eax
f01034f8:	89 fa                	mov    %edi,%edx
f01034fa:	83 c4 1c             	add    $0x1c,%esp
f01034fd:	5b                   	pop    %ebx
f01034fe:	5e                   	pop    %esi
f01034ff:	5f                   	pop    %edi
f0103500:	5d                   	pop    %ebp
f0103501:	c3                   	ret    
f0103502:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103508:	31 ff                	xor    %edi,%edi
f010350a:	31 db                	xor    %ebx,%ebx
f010350c:	89 d8                	mov    %ebx,%eax
f010350e:	89 fa                	mov    %edi,%edx
f0103510:	83 c4 1c             	add    $0x1c,%esp
f0103513:	5b                   	pop    %ebx
f0103514:	5e                   	pop    %esi
f0103515:	5f                   	pop    %edi
f0103516:	5d                   	pop    %ebp
f0103517:	c3                   	ret    
f0103518:	90                   	nop
f0103519:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103520:	89 d8                	mov    %ebx,%eax
f0103522:	f7 f7                	div    %edi
f0103524:	31 ff                	xor    %edi,%edi
f0103526:	89 c3                	mov    %eax,%ebx
f0103528:	89 d8                	mov    %ebx,%eax
f010352a:	89 fa                	mov    %edi,%edx
f010352c:	83 c4 1c             	add    $0x1c,%esp
f010352f:	5b                   	pop    %ebx
f0103530:	5e                   	pop    %esi
f0103531:	5f                   	pop    %edi
f0103532:	5d                   	pop    %ebp
f0103533:	c3                   	ret    
f0103534:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103538:	39 ce                	cmp    %ecx,%esi
f010353a:	72 0c                	jb     f0103548 <__udivdi3+0x118>
f010353c:	31 db                	xor    %ebx,%ebx
f010353e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0103542:	0f 87 34 ff ff ff    	ja     f010347c <__udivdi3+0x4c>
f0103548:	bb 01 00 00 00       	mov    $0x1,%ebx
f010354d:	e9 2a ff ff ff       	jmp    f010347c <__udivdi3+0x4c>
f0103552:	66 90                	xchg   %ax,%ax
f0103554:	66 90                	xchg   %ax,%ax
f0103556:	66 90                	xchg   %ax,%ax
f0103558:	66 90                	xchg   %ax,%ax
f010355a:	66 90                	xchg   %ax,%ax
f010355c:	66 90                	xchg   %ax,%ax
f010355e:	66 90                	xchg   %ax,%ax

f0103560 <__umoddi3>:
f0103560:	55                   	push   %ebp
f0103561:	57                   	push   %edi
f0103562:	56                   	push   %esi
f0103563:	53                   	push   %ebx
f0103564:	83 ec 1c             	sub    $0x1c,%esp
f0103567:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010356b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010356f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103573:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103577:	85 d2                	test   %edx,%edx
f0103579:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010357d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103581:	89 f3                	mov    %esi,%ebx
f0103583:	89 3c 24             	mov    %edi,(%esp)
f0103586:	89 74 24 04          	mov    %esi,0x4(%esp)
f010358a:	75 1c                	jne    f01035a8 <__umoddi3+0x48>
f010358c:	39 f7                	cmp    %esi,%edi
f010358e:	76 50                	jbe    f01035e0 <__umoddi3+0x80>
f0103590:	89 c8                	mov    %ecx,%eax
f0103592:	89 f2                	mov    %esi,%edx
f0103594:	f7 f7                	div    %edi
f0103596:	89 d0                	mov    %edx,%eax
f0103598:	31 d2                	xor    %edx,%edx
f010359a:	83 c4 1c             	add    $0x1c,%esp
f010359d:	5b                   	pop    %ebx
f010359e:	5e                   	pop    %esi
f010359f:	5f                   	pop    %edi
f01035a0:	5d                   	pop    %ebp
f01035a1:	c3                   	ret    
f01035a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01035a8:	39 f2                	cmp    %esi,%edx
f01035aa:	89 d0                	mov    %edx,%eax
f01035ac:	77 52                	ja     f0103600 <__umoddi3+0xa0>
f01035ae:	0f bd ea             	bsr    %edx,%ebp
f01035b1:	83 f5 1f             	xor    $0x1f,%ebp
f01035b4:	75 5a                	jne    f0103610 <__umoddi3+0xb0>
f01035b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01035ba:	0f 82 e0 00 00 00    	jb     f01036a0 <__umoddi3+0x140>
f01035c0:	39 0c 24             	cmp    %ecx,(%esp)
f01035c3:	0f 86 d7 00 00 00    	jbe    f01036a0 <__umoddi3+0x140>
f01035c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01035cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01035d1:	83 c4 1c             	add    $0x1c,%esp
f01035d4:	5b                   	pop    %ebx
f01035d5:	5e                   	pop    %esi
f01035d6:	5f                   	pop    %edi
f01035d7:	5d                   	pop    %ebp
f01035d8:	c3                   	ret    
f01035d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01035e0:	85 ff                	test   %edi,%edi
f01035e2:	89 fd                	mov    %edi,%ebp
f01035e4:	75 0b                	jne    f01035f1 <__umoddi3+0x91>
f01035e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01035eb:	31 d2                	xor    %edx,%edx
f01035ed:	f7 f7                	div    %edi
f01035ef:	89 c5                	mov    %eax,%ebp
f01035f1:	89 f0                	mov    %esi,%eax
f01035f3:	31 d2                	xor    %edx,%edx
f01035f5:	f7 f5                	div    %ebp
f01035f7:	89 c8                	mov    %ecx,%eax
f01035f9:	f7 f5                	div    %ebp
f01035fb:	89 d0                	mov    %edx,%eax
f01035fd:	eb 99                	jmp    f0103598 <__umoddi3+0x38>
f01035ff:	90                   	nop
f0103600:	89 c8                	mov    %ecx,%eax
f0103602:	89 f2                	mov    %esi,%edx
f0103604:	83 c4 1c             	add    $0x1c,%esp
f0103607:	5b                   	pop    %ebx
f0103608:	5e                   	pop    %esi
f0103609:	5f                   	pop    %edi
f010360a:	5d                   	pop    %ebp
f010360b:	c3                   	ret    
f010360c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103610:	8b 34 24             	mov    (%esp),%esi
f0103613:	bf 20 00 00 00       	mov    $0x20,%edi
f0103618:	89 e9                	mov    %ebp,%ecx
f010361a:	29 ef                	sub    %ebp,%edi
f010361c:	d3 e0                	shl    %cl,%eax
f010361e:	89 f9                	mov    %edi,%ecx
f0103620:	89 f2                	mov    %esi,%edx
f0103622:	d3 ea                	shr    %cl,%edx
f0103624:	89 e9                	mov    %ebp,%ecx
f0103626:	09 c2                	or     %eax,%edx
f0103628:	89 d8                	mov    %ebx,%eax
f010362a:	89 14 24             	mov    %edx,(%esp)
f010362d:	89 f2                	mov    %esi,%edx
f010362f:	d3 e2                	shl    %cl,%edx
f0103631:	89 f9                	mov    %edi,%ecx
f0103633:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103637:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010363b:	d3 e8                	shr    %cl,%eax
f010363d:	89 e9                	mov    %ebp,%ecx
f010363f:	89 c6                	mov    %eax,%esi
f0103641:	d3 e3                	shl    %cl,%ebx
f0103643:	89 f9                	mov    %edi,%ecx
f0103645:	89 d0                	mov    %edx,%eax
f0103647:	d3 e8                	shr    %cl,%eax
f0103649:	89 e9                	mov    %ebp,%ecx
f010364b:	09 d8                	or     %ebx,%eax
f010364d:	89 d3                	mov    %edx,%ebx
f010364f:	89 f2                	mov    %esi,%edx
f0103651:	f7 34 24             	divl   (%esp)
f0103654:	89 d6                	mov    %edx,%esi
f0103656:	d3 e3                	shl    %cl,%ebx
f0103658:	f7 64 24 04          	mull   0x4(%esp)
f010365c:	39 d6                	cmp    %edx,%esi
f010365e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103662:	89 d1                	mov    %edx,%ecx
f0103664:	89 c3                	mov    %eax,%ebx
f0103666:	72 08                	jb     f0103670 <__umoddi3+0x110>
f0103668:	75 11                	jne    f010367b <__umoddi3+0x11b>
f010366a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010366e:	73 0b                	jae    f010367b <__umoddi3+0x11b>
f0103670:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103674:	1b 14 24             	sbb    (%esp),%edx
f0103677:	89 d1                	mov    %edx,%ecx
f0103679:	89 c3                	mov    %eax,%ebx
f010367b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010367f:	29 da                	sub    %ebx,%edx
f0103681:	19 ce                	sbb    %ecx,%esi
f0103683:	89 f9                	mov    %edi,%ecx
f0103685:	89 f0                	mov    %esi,%eax
f0103687:	d3 e0                	shl    %cl,%eax
f0103689:	89 e9                	mov    %ebp,%ecx
f010368b:	d3 ea                	shr    %cl,%edx
f010368d:	89 e9                	mov    %ebp,%ecx
f010368f:	d3 ee                	shr    %cl,%esi
f0103691:	09 d0                	or     %edx,%eax
f0103693:	89 f2                	mov    %esi,%edx
f0103695:	83 c4 1c             	add    $0x1c,%esp
f0103698:	5b                   	pop    %ebx
f0103699:	5e                   	pop    %esi
f010369a:	5f                   	pop    %edi
f010369b:	5d                   	pop    %ebp
f010369c:	c3                   	ret    
f010369d:	8d 76 00             	lea    0x0(%esi),%esi
f01036a0:	29 f9                	sub    %edi,%ecx
f01036a2:	19 d6                	sbb    %edx,%esi
f01036a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036ac:	e9 18 ff ff ff       	jmp    f01035c9 <__umoddi3+0x69>
